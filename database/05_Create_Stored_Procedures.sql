USE EV_Charging_System;
GO

CREATE OR ALTER PROCEDURE [Identity].sp_CreateUser
    @Username NVARCHAR(50),
    @Email NVARCHAR(120),
    @Phone NVARCHAR(20) = NULL,
    @PasswordHash NVARCHAR(256),
    @FullName NVARCHAR(120),
    @RoleCode NVARCHAR(40)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @RoleID INT = (SELECT RoleID FROM [Identity].Role WHERE RoleCode = @RoleCode);
        IF @RoleID IS NULL
            THROW 51001, 'Role does not exist.', 1;

        INSERT INTO [Identity].UserAccount (Username, Email, Phone, PasswordHash, FullName)
        VALUES (@Username, @Email, @Phone, @PasswordHash, @FullName);

        DECLARE @UserID INT = SCOPE_IDENTITY();
        INSERT INTO [Identity].UserRole (UserID, RoleID) VALUES (@UserID, @RoleID);

        IF @RoleCode = N'Customer'
        BEGIN
            INSERT INTO [Identity].CustomerProfile (UserID) VALUES (@UserID);
            INSERT INTO Payments.Wallet (UserID, WalletCode, Balance)
            VALUES (@UserID, N'WAL-' + @Username, 0);
        END;

        INSERT INTO Audit.AuditLog (SchemaName, TableName, RecordID, ActionType, NewValues)
        VALUES (N'Identity', N'UserAccount', CAST(@UserID AS NVARCHAR(100)), N'INSERT', @Username);

        COMMIT TRANSACTION;

        SELECT UserID, Username, Email, FullName, AccountStatus
        FROM [Identity].UserAccount
        WHERE UserID = @UserID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE Infrastructure.sp_CreateChargingStation
    @StationCode NVARCHAR(30),
    @StationName NVARCHAR(200),
    @FranchiseID INT,
    @AddressID INT,
    @SupplierID INT = NULL,
    @StationOperatorID INT = NULL,
    @MaxPowerKW DECIMAL(8,2)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO Infrastructure.ChargingStation
            (StationCode, StationName, FranchiseID, AddressID, SupplierID, StationOperatorID, MaxPowerKW, StationStatus, OpenedAt)
        VALUES
            (@StationCode, @StationName, @FranchiseID, @AddressID, @SupplierID, @StationOperatorID, @MaxPowerKW, N'Active', CAST(SYSDATETIME() AS DATE));

        DECLARE @StationID INT = SCOPE_IDENTITY();

        INSERT INTO Audit.AuditLog (SchemaName, TableName, RecordID, ActionType, NewValues)
        VALUES (N'Infrastructure', N'ChargingStation', CAST(@StationID AS NVARCHAR(100)), N'INSERT', @StationCode);

        COMMIT TRANSACTION;

        SELECT StationID, StationCode, StationName, StationStatus
        FROM Infrastructure.ChargingStation
        WHERE StationID = @StationID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE Infrastructure.sp_CreateChargingPoint
    @PointCode NVARCHAR(40),
    @StationID INT,
    @ConnectorTypeID INT,
    @PowerKW DECIMAL(8,2),
    @SerialNumber NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO Infrastructure.ChargingPoint
            (PointCode, StationID, ConnectorTypeID, PowerKW, SerialNumber, PointStatus)
        VALUES
            (@PointCode, @StationID, @ConnectorTypeID, @PowerKW, @SerialNumber, N'Available');

        DECLARE @PointID INT = SCOPE_IDENTITY();

        IF NOT EXISTS (
            SELECT 1 FROM Infrastructure.StationConnectorType
            WHERE StationID = @StationID AND ConnectorTypeID = @ConnectorTypeID
        )
        BEGIN
            INSERT INTO Infrastructure.StationConnectorType (StationID, ConnectorTypeID)
            VALUES (@StationID, @ConnectorTypeID);
        END;

        INSERT INTO Audit.AuditLog (SchemaName, TableName, RecordID, ActionType, NewValues)
        VALUES (N'Infrastructure', N'ChargingPoint', CAST(@PointID AS NVARCHAR(100)), N'INSERT', @PointCode);

        COMMIT TRANSACTION;

        SELECT PointID, PointCode, StationID, ConnectorTypeID, PowerKW, PointStatus
        FROM Infrastructure.ChargingPoint
        WHERE PointID = @PointID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE Operations.sp_StartChargingSession
    @UserID INT,
    @VehicleID INT = NULL,
    @PointID INT,
    @MeterStart DECIMAL(14,4) = NULL,
    @BookingID BIGINT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @PointStatus NVARCHAR(30), @StationID INT;
        SELECT @PointStatus = PointStatus, @StationID = StationID
        FROM Infrastructure.ChargingPoint
        WHERE PointID = @PointID;

        IF @PointStatus IS NULL
            THROW 52001, 'Charging point does not exist.', 1;
        IF @PointStatus <> N'Available'
            THROW 52002, 'Charging point is not available.', 1;

        IF NOT EXISTS (SELECT 1 FROM [Identity].UserAccount WHERE UserID = @UserID AND AccountStatus = N'Active')
            THROW 52003, 'User account is not active.', 1;

        DECLARE @PolicyID INT;
        SELECT TOP 1 @PolicyID = PolicyID
        FROM Operations.PricingPolicy
        WHERE IsActive = 1
          AND AppliedFrom <= SYSDATETIME()
          AND (AppliedTo IS NULL OR AppliedTo >= SYSDATETIME())
        ORDER BY AppliedFrom DESC;

        IF @PolicyID IS NULL
            THROW 52004, 'No active pricing policy.', 1;

        DECLARE @SessionID BIGINT;
        INSERT INTO Operations.ChargingSession
            (SessionCode, UserID, VehicleID, StationID, PointID, PolicyID, BookingID, MeterStart, SessionStatus)
        VALUES
            (N'SES-' + FORMAT(SYSDATETIME(), 'yyyyMMddHHmmss') + N'-' + RIGHT(CONVERT(NVARCHAR(36), NEWID()), 6),
             @UserID, @VehicleID, @StationID, @PointID, @PolicyID, @BookingID, @MeterStart, N'Charging');

        SET @SessionID = SCOPE_IDENTITY();

        UPDATE Infrastructure.ChargingPoint
        SET PointStatus = N'Charging', UpdatedAt = SYSDATETIME()
        WHERE PointID = @PointID;

        IF @BookingID IS NOT NULL
            UPDATE Operations.Booking SET BookingStatus = N'Active', UpdatedAt = SYSDATETIME() WHERE BookingID = @BookingID;

        INSERT INTO Operations.SessionEvent (SessionID, EventType, EventPayload)
        VALUES (@SessionID, N'Started', N'Charging session started');

        COMMIT TRANSACTION;

        SELECT SessionID, SessionCode, UserID, StationID, PointID, SessionStatus, StartTime
        FROM Operations.ChargingSession
        WHERE SessionID = @SessionID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE Operations.sp_EndChargingSession
    @SessionID BIGINT,
    @MeterEnd DECIMAL(14,4) = NULL,
    @TotalKWh DECIMAL(14,4) = NULL,
    @StopReason NVARCHAR(60) = N'Completed'
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @PointID INT, @PolicyID INT, @StartTime DATETIME2, @MeterStart DECIMAL(14,4), @Status NVARCHAR(30);
        SELECT @PointID = PointID, @PolicyID = PolicyID, @StartTime = StartTime, @MeterStart = MeterStart, @Status = SessionStatus
        FROM Operations.ChargingSession
        WHERE SessionID = @SessionID;

        IF @Status IS NULL
            THROW 52010, 'Charging session does not exist.', 1;
        IF @Status <> N'Charging'
            THROW 52011, 'Charging session is not in Charging status.', 1;

        IF @TotalKWh IS NULL AND @MeterEnd IS NOT NULL AND @MeterStart IS NOT NULL
            SET @TotalKWh = @MeterEnd - @MeterStart;
        IF @TotalKWh IS NULL OR @TotalKWh <= 0
            THROW 52012, 'Total kWh must be positive.', 1;

        DECLARE @CostBeforeTax DECIMAL(19,4) = Operations.fn_CalculateChargingCost(@TotalKWh, @PolicyID, @StartTime);
        DECLARE @TaxAmount DECIMAL(19,4) = ROUND(@CostBeforeTax * 0.08, 4);

        UPDATE Operations.ChargingSession
        SET EndTime = SYSDATETIME(),
            MeterEnd = @MeterEnd,
            TotalKWh = @TotalKWh,
            DurationMinutes = DATEDIFF(MINUTE, @StartTime, SYSDATETIME()),
            CostBeforeTax = @CostBeforeTax,
            TaxAmount = @TaxAmount,
            CostTotal = @CostBeforeTax + @TaxAmount,
            StopReason = @StopReason,
            SessionStatus = N'Completed',
            UpdatedAt = SYSDATETIME()
        WHERE SessionID = @SessionID;

        UPDATE Infrastructure.ChargingPoint
        SET PointStatus = N'Available', UpdatedAt = SYSDATETIME()
        WHERE PointID = @PointID;

        INSERT INTO Operations.SessionEvent (SessionID, EventType, EventPayload)
        VALUES (@SessionID, N'Completed', N'Charging session completed');

        COMMIT TRANSACTION;

        SELECT SessionID, SessionCode, TotalKWh, CostBeforeTax, TaxAmount, CostTotal, SessionStatus
        FROM Operations.ChargingSession
        WHERE SessionID = @SessionID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE Payments.sp_TopUpWallet
    @UserID INT,
    @Amount DECIMAL(19,4),
    @PaymentMethodCode NVARCHAR(30) = N'QR'
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF @Amount <= 0
            THROW 53001, 'Top-up amount must be positive.', 1;

        DECLARE @WalletID BIGINT, @Balance DECIMAL(19,4), @MethodID INT;
        SELECT @WalletID = WalletID, @Balance = Balance FROM Payments.Wallet WHERE UserID = @UserID AND IsActive = 1;
        SELECT @MethodID = PaymentMethodID FROM Payments.PaymentMethod WHERE MethodCode = @PaymentMethodCode;

        IF @WalletID IS NULL
            THROW 53002, 'Wallet does not exist.', 1;
        IF @MethodID IS NULL
            THROW 53003, 'Payment method does not exist.', 1;

        INSERT INTO Payments.PaymentTransaction
            (TransactionCode, UserID, PaymentMethodID, TransactionType, Direction, Amount, TransactionStatus, Description, SettledAt)
        VALUES
            (N'TXN-' + FORMAT(SYSDATETIME(), 'yyyyMMddHHmmss') + N'-' + RIGHT(CONVERT(NVARCHAR(36), NEWID()), 6),
             @UserID, @MethodID, N'WalletTopUp', N'C', @Amount, N'Completed', N'Wallet top-up', SYSDATETIME());

        DECLARE @TransactionID BIGINT = SCOPE_IDENTITY();

        UPDATE Payments.Wallet
        SET Balance = Balance + @Amount, LastTransactionAt = SYSDATETIME()
        WHERE WalletID = @WalletID;

        INSERT INTO Payments.WalletTransaction (WalletID, TransactionID, Amount, BalanceBefore, Direction, Description)
        VALUES (@WalletID, @TransactionID, @Amount, @Balance, N'C', N'Wallet top-up');

        COMMIT TRANSACTION;

        SELECT WalletID, UserID, Balance FROM Payments.Wallet WHERE WalletID = @WalletID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE Payments.sp_CreatePayment
    @UserID INT,
    @SessionID BIGINT,
    @PaymentMethodCode NVARCHAR(30) = N'WALLET'
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @Amount DECIMAL(19,4), @SessionUserID INT, @Status NVARCHAR(30), @MethodID INT;
        SELECT @Amount = CostTotal, @SessionUserID = UserID, @Status = SessionStatus
        FROM Operations.ChargingSession
        WHERE SessionID = @SessionID;
        SELECT @MethodID = PaymentMethodID FROM Payments.PaymentMethod WHERE MethodCode = @PaymentMethodCode;

        IF @Status <> N'Completed'
            THROW 53010, 'Session must be completed before payment.', 1;
        IF @SessionUserID <> @UserID
            THROW 53011, 'Session does not belong to user.', 1;
        IF @Amount IS NULL OR @Amount <= 0
            THROW 53012, 'Invalid payment amount.', 1;
        IF @MethodID IS NULL
            THROW 53013, 'Payment method does not exist.', 1;
        IF EXISTS (SELECT 1 FROM Payments.PaymentTransaction WHERE SessionID = @SessionID AND TransactionType = N'ChargingPayment' AND TransactionStatus = N'Completed')
            THROW 53014, 'Session has already been paid.', 1;

        DECLARE @WalletID BIGINT, @Balance DECIMAL(19,4);
        IF @PaymentMethodCode = N'WALLET'
        BEGIN
            SELECT @WalletID = WalletID, @Balance = Balance
            FROM Payments.Wallet
            WHERE UserID = @UserID AND IsActive = 1;

            IF @WalletID IS NULL OR @Balance < @Amount
                THROW 53015, 'Insufficient wallet balance.', 1;
        END;

        INSERT INTO Payments.PaymentTransaction
            (TransactionCode, UserID, SessionID, PaymentMethodID, TransactionType, Direction, Amount, TransactionStatus, SettledAt)
        VALUES
            (N'TXN-' + FORMAT(SYSDATETIME(), 'yyyyMMddHHmmss') + N'-' + RIGHT(CONVERT(NVARCHAR(36), NEWID()), 6),
             @UserID, @SessionID, @MethodID, N'ChargingPayment', N'D', @Amount, N'Completed', SYSDATETIME());

        DECLARE @TransactionID BIGINT = SCOPE_IDENTITY();

        IF @PaymentMethodCode = N'WALLET'
        BEGIN
            UPDATE Payments.Wallet
            SET Balance = Balance - @Amount, LastTransactionAt = SYSDATETIME()
            WHERE WalletID = @WalletID;

            INSERT INTO Payments.WalletTransaction (WalletID, TransactionID, Amount, BalanceBefore, Direction, Description)
            VALUES (@WalletID, @TransactionID, -@Amount, @Balance, N'D', N'Charging payment');
        END;

        INSERT INTO Audit.AuditLog (SchemaName, TableName, RecordID, ActionType, NewValues)
        VALUES (N'Payments', N'PaymentTransaction', CAST(@TransactionID AS NVARCHAR(100)), N'PAYMENT', CAST(@Amount AS NVARCHAR(50)));

        COMMIT TRANSACTION;

        SELECT TransactionID, TransactionCode, UserID, SessionID, Amount, TransactionStatus
        FROM Payments.PaymentTransaction
        WHERE TransactionID = @TransactionID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE Payments.sp_CreateInvoice
    @SessionID BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF EXISTS (SELECT 1 FROM Payments.Invoice WHERE SessionID = @SessionID)
            THROW 53020, 'Invoice already exists.', 1;

        DECLARE @UserID INT, @Subtotal DECIMAL(19,4), @Tax DECIMAL(19,4), @Total DECIMAL(19,4), @TransactionID BIGINT;

        SELECT @UserID = UserID, @Subtotal = CostBeforeTax, @Tax = TaxAmount, @Total = CostTotal
        FROM Operations.ChargingSession
        WHERE SessionID = @SessionID AND SessionStatus = N'Completed';

        SELECT TOP 1 @TransactionID = TransactionID
        FROM Payments.PaymentTransaction
        WHERE SessionID = @SessionID
          AND TransactionType = N'ChargingPayment'
          AND TransactionStatus = N'Completed';

        IF @UserID IS NULL OR @Total IS NULL
            THROW 53021, 'Cannot create invoice for incomplete session.', 1;

        INSERT INTO Payments.Invoice
            (InvoiceCode, UserID, SessionID, TransactionID, Subtotal, TaxAmount, TotalAmount, InvoiceStatus)
        VALUES
            (N'INV-' + FORMAT(SYSDATETIME(), 'yyyyMMddHHmmss') + N'-' + RIGHT(CONVERT(NVARCHAR(36), NEWID()), 6),
             @UserID, @SessionID, @TransactionID, @Subtotal, @Tax, @Total,
             CASE WHEN @TransactionID IS NULL THEN N'Issued' ELSE N'Paid' END);

        DECLARE @InvoiceID BIGINT = SCOPE_IDENTITY();

        COMMIT TRANSACTION;

        SELECT InvoiceID, InvoiceCode, UserID, SessionID, TotalAmount, InvoiceStatus
        FROM Payments.Invoice
        WHERE InvoiceID = @InvoiceID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE Payments.sp_ProcessRefund
    @OriginalTransactionID BIGINT,
    @Amount DECIMAL(19,4),
    @Reason NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @UserID INT, @WalletID BIGINT, @Balance DECIMAL(19,4), @MethodID INT;
        DECLARE @Refundable DECIMAL(19,4) = Payments.fn_RefundableAmount(@OriginalTransactionID);

        SELECT @UserID = UserID
        FROM Payments.PaymentTransaction
        WHERE TransactionID = @OriginalTransactionID;

        SELECT @WalletID = WalletID, @Balance = Balance FROM Payments.Wallet WHERE UserID = @UserID;
        SELECT @MethodID = PaymentMethodID FROM Payments.PaymentMethod WHERE MethodCode = N'WALLET';

        IF @UserID IS NULL OR @WalletID IS NULL
            THROW 53030, 'Original transaction or wallet not found.', 1;
        IF @Amount <= 0 OR @Amount > @Refundable
            THROW 53031, 'Refund amount exceeds refundable amount.', 1;

        INSERT INTO Payments.PaymentTransaction
            (TransactionCode, UserID, PaymentMethodID, TransactionType, Direction, Amount, TransactionStatus, Description, SettledAt)
        VALUES
            (N'RFN-TXN-' + FORMAT(SYSDATETIME(), 'yyyyMMddHHmmss') + N'-' + RIGHT(CONVERT(NVARCHAR(36), NEWID()), 6),
             @UserID, @MethodID, N'Refund', N'C', @Amount, N'Completed', @Reason, SYSDATETIME());

        DECLARE @RefundTxnID BIGINT = SCOPE_IDENTITY();

        UPDATE Payments.Wallet
        SET Balance = Balance + @Amount, LastTransactionAt = SYSDATETIME()
        WHERE WalletID = @WalletID;

        INSERT INTO Payments.WalletTransaction (WalletID, TransactionID, Amount, BalanceBefore, Direction, Description)
        VALUES (@WalletID, @RefundTxnID, @Amount, @Balance, N'C', N'Refund');

        INSERT INTO Payments.Refund
            (RefundCode, OriginalTransactionID, RefundTransactionID, UserID, Amount, Reason, RefundStatus, ProcessedAt)
        VALUES
            (N'RFN-' + FORMAT(SYSDATETIME(), 'yyyyMMddHHmmss') + N'-' + RIGHT(CONVERT(NVARCHAR(36), NEWID()), 6),
             @OriginalTransactionID, @RefundTxnID, @UserID, @Amount, @Reason, N'Completed', SYSDATETIME());

        DECLARE @RefundID BIGINT = SCOPE_IDENTITY();

        IF Payments.fn_RefundableAmount(@OriginalTransactionID) = 0
            UPDATE Payments.PaymentTransaction SET TransactionStatus = N'Refunded' WHERE TransactionID = @OriginalTransactionID;

        INSERT INTO Audit.AuditLog (SchemaName, TableName, RecordID, ActionType, NewValues)
        VALUES (N'Payments', N'Refund', CAST(@RefundID AS NVARCHAR(100)), N'REFUND', CAST(@Amount AS NVARCHAR(50)));

        COMMIT TRANSACTION;

        SELECT RefundID, RefundCode, OriginalTransactionID, RefundTransactionID, Amount, RefundStatus
        FROM Payments.Refund
        WHERE RefundID = @RefundID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE Maintenance.sp_ReportError
    @ErrorCode NVARCHAR(30),
    @StationID INT = NULL,
    @PointID INT = NULL,
    @Description NVARCHAR(500),
    @CreatedBy INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @Severity NVARCHAR(20) = (SELECT DefaultSeverity FROM Maintenance.ErrorCatalog WHERE ErrorCode = @ErrorCode);
        IF @Severity IS NULL
            THROW 54001, 'Error code does not exist.', 1;

        INSERT INTO Maintenance.ErrorLog (ErrorCode, StationID, PointID, Severity, Description)
        VALUES (@ErrorCode, @StationID, @PointID, @Severity, @Description);

        DECLARE @ErrorID BIGINT = SCOPE_IDENTITY();

        INSERT INTO Maintenance.MaintenanceTicket
            (TicketCode, StationID, PointID, ErrorID, CreatedBy, Priority, TicketStatus, Title, Description)
        VALUES
            (N'MT-' + FORMAT(SYSDATETIME(), 'yyyyMMddHHmmss') + N'-' + RIGHT(CONVERT(NVARCHAR(36), NEWID()), 6),
             @StationID, @PointID, @ErrorID, @CreatedBy, @Severity, N'Open', N'Auto ticket from error log', @Description);

        IF @PointID IS NOT NULL
            UPDATE Infrastructure.ChargingPoint SET PointStatus = N'Error', HealthStatus = N'Critical', UpdatedAt = SYSDATETIME()
            WHERE PointID = @PointID;

        COMMIT TRANSACTION;

        SELECT ErrorID, ErrorCode, StationID, PointID, Severity, IsActive
        FROM Maintenance.ErrorLog
        WHERE ErrorID = @ErrorID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE Maintenance.sp_AssignTicket
    @TicketID BIGINT,
    @TechnicianUserID INT,
    @AssignedBy INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE Maintenance.MaintenanceTicket
        SET TicketStatus = N'Assigned'
        WHERE TicketID = @TicketID AND TicketStatus IN (N'Open', N'Assigned');

        IF @@ROWCOUNT = 0
            THROW 54010, 'Ticket cannot be assigned.', 1;

        INSERT INTO Maintenance.MaintenanceAssignment (TicketID, TechnicianUserID, AssignedBy)
        VALUES (@TicketID, @TechnicianUserID, @AssignedBy);

        INSERT INTO Maintenance.MaintenanceHistory (TicketID, OldStatus, NewStatus, Notes, ChangedBy)
        VALUES (@TicketID, N'Open', N'Assigned', N'Ticket assigned to technician', @AssignedBy);

        COMMIT TRANSACTION;

        SELECT TicketID, TicketStatus FROM Maintenance.MaintenanceTicket WHERE TicketID = @TicketID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE Maintenance.sp_CloseTicket
    @TicketID BIGINT,
    @ClosedBy INT,
    @Notes NVARCHAR(1000) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @PointID INT, @ErrorID BIGINT, @OldStatus NVARCHAR(20);
        SELECT @PointID = PointID, @ErrorID = ErrorID, @OldStatus = TicketStatus
        FROM Maintenance.MaintenanceTicket
        WHERE TicketID = @TicketID;

        IF @OldStatus IS NULL OR @OldStatus IN (N'Closed', N'Cancelled')
            THROW 54020, 'Ticket cannot be closed.', 1;

        UPDATE Maintenance.MaintenanceTicket
        SET TicketStatus = N'Closed', ClosedAt = SYSDATETIME()
        WHERE TicketID = @TicketID;

        IF @ErrorID IS NOT NULL
            UPDATE Maintenance.ErrorLog
            SET IsActive = 0, ResolvedAt = SYSDATETIME(), ResolvedBy = @ClosedBy
            WHERE ErrorID = @ErrorID;

        IF @PointID IS NOT NULL
            UPDATE Infrastructure.ChargingPoint
            SET PointStatus = N'Available', HealthStatus = N'Normal', UpdatedAt = SYSDATETIME()
            WHERE PointID = @PointID;

        INSERT INTO Maintenance.MaintenanceHistory (TicketID, OldStatus, NewStatus, Notes, ChangedBy)
        VALUES (@TicketID, @OldStatus, N'Closed', @Notes, @ClosedBy);

        COMMIT TRANSACTION;

        SELECT TicketID, TicketStatus, ClosedAt FROM Maintenance.MaintenanceTicket WHERE TicketID = @TicketID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE Franchise.sp_CreateRevenueSettlement
    @FranchiseID INT,
    @PeriodStart DATE,
    @PeriodEnd DATE
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @ContractID INT, @PartnerRate DECIMAL(5,2);
        SELECT TOP 1 @ContractID = fc.ContractID, @PartnerRate = rsp.PartnerShareRate
        FROM Franchise.FranchiseContract fc
        JOIN Franchise.RevenueSharePolicy rsp ON rsp.ContractID = fc.ContractID AND rsp.IsActive = 1
        WHERE fc.FranchiseID = @FranchiseID
          AND fc.ContractStatus = N'Active'
          AND @PeriodStart BETWEEN fc.StartDate AND fc.EndDate
        ORDER BY fc.StartDate DESC;

        IF @ContractID IS NULL
            THROW 55001, 'Active franchise contract not found.', 1;

        DECLARE @GrossRevenue DECIMAL(19,4);
        SELECT @GrossRevenue = SUM(cs.CostBeforeTax)
        FROM Operations.ChargingSession cs
        JOIN Infrastructure.ChargingStation s ON s.StationID = cs.StationID
        WHERE s.FranchiseID = @FranchiseID
          AND cs.SessionStatus = N'Completed'
          AND CAST(cs.StartTime AS DATE) BETWEEN @PeriodStart AND @PeriodEnd;

        SET @GrossRevenue = ISNULL(@GrossRevenue, 0);

        DECLARE @PartnerShare DECIMAL(19,4) = Franchise.fn_CalculatePartnerShare(@GrossRevenue, @PartnerRate);
        DECLARE @PlatformShare DECIMAL(19,4) = @GrossRevenue - @PartnerShare;

        INSERT INTO Franchise.RevenueShareSettlement
            (SettlementCode, FranchiseID, ContractID, PeriodStart, PeriodEnd, GrossRevenue, PartnerShareAmount, PlatformShareAmount, SettlementStatus)
        VALUES
            (N'SET-' + FORMAT(SYSDATETIME(), 'yyyyMMddHHmmss') + N'-' + RIGHT(CONVERT(NVARCHAR(36), NEWID()), 6),
             @FranchiseID, @ContractID, @PeriodStart, @PeriodEnd, @GrossRevenue, @PartnerShare, @PlatformShare, N'Approved');

        DECLARE @SettlementID BIGINT = SCOPE_IDENTITY();

        INSERT INTO Audit.AuditLog (SchemaName, TableName, RecordID, ActionType, NewValues)
        VALUES (N'Franchise', N'RevenueShareSettlement', CAST(@SettlementID AS NVARCHAR(100)), N'SETTLEMENT', CAST(@GrossRevenue AS NVARCHAR(50)));

        COMMIT TRANSACTION;

        SELECT SettlementID, SettlementCode, GrossRevenue, PartnerShareAmount, PlatformShareAmount, SettlementStatus
        FROM Franchise.RevenueShareSettlement
        WHERE SettlementID = @SettlementID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

PRINT N'05 - Stored procedures created.';
GO
