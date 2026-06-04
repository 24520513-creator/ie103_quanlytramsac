==============================================================================
-- 4.2.7 Nhom Stored Procedure thanh toan va hoa don
==============================================================================


==============================================================================
-- Payments.sp_CreatePayment
==============================================================================

--database/05_Create_Stored_Procedures.sql
CREATE OR ALTER PROCEDURE Payments.sp_CreatePayment
    @UserID INT,
    @SessionID BIGINT,
    @PaymentMethod NVARCHAR(30) = N'CASH'
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF (COALESCE(CAST(SESSION_CONTEXT(N'RoleCode') AS NVARCHAR(40)), N'') = N'Customer' OR IS_ROLEMEMBER(N'db_ev_customer') = 1)
           AND ISNULL(@UserID, -1) <> ISNULL(TRY_CONVERT(INT, SESSION_CONTEXT(N'UserID')), -2147483648)
            THROW 53015, 'Customer can only create payment for current session user.', 1;

        DECLARE @Amount DECIMAL(19,4), @SessionUserID INT, @Status NVARCHAR(30);
        SELECT @Amount = CostTotal, @SessionUserID = UserID, @Status = SessionStatus
        FROM Operations.ChargingSession
        WHERE SessionID = @SessionID;

        IF @Status <> N'Completed'
            THROW 53010, 'Session must be completed before payment.', 1;
        IF @SessionUserID <> @UserID
            THROW 53011, 'Session does not belong to user.', 1;
        IF @Amount IS NULL OR @Amount <= 0
            THROW 53012, 'Invalid payment amount.', 1;
        IF @PaymentMethod NOT IN (N'CASH', N'QR', N'BANK_TRANSFER')
            THROW 53013, 'Invalid payment method.', 1;
        IF EXISTS (SELECT 1 FROM Payments.PaymentTransaction WHERE SessionID = @SessionID AND TransactionStatus = N'Completed')
            THROW 53014, 'Session has already been paid.', 1;

        INSERT INTO Payments.PaymentTransaction
            (TransactionCode, UserID, SessionID, PaymentMethod, Amount, TransactionStatus, PaidAt)
        VALUES
            (N'TXN-' + FORMAT(SYSDATETIME(), 'yyyyMMddHHmmss') + N'-' + RIGHT(CONVERT(NVARCHAR(36), NEWID()), 6),
             @UserID, @SessionID, @PaymentMethod, @Amount, N'Completed', SYSDATETIME());

        DECLARE @TransactionID BIGINT = SCOPE_IDENTITY();

        INSERT INTO Audit.AuditLog (SchemaName, TableName, RecordID, ActionType, NewValues)
        VALUES (N'Payments', N'PaymentTransaction', CAST(@TransactionID AS NVARCHAR(100)), N'PAYMENT', CAST(@Amount AS NVARCHAR(50)));

        COMMIT TRANSACTION;

        SELECT TransactionID, TransactionCode, UserID, SessionID, PaymentMethod, Amount, TransactionStatus
        FROM Payments.PaymentTransaction
        WHERE TransactionID = @TransactionID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- >>> TEST: source kiem thu tinh nang
-- (Trich tu database/features/customer/09_create_payment_invoice.sql)
USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: tao phien sac moi, thanh toan va lap hoa don.
- Tham so co the sua: @UserID, @VehicleID, @PointID, @PaymentMethod.
- @PaymentMethod hop le: N''CASH'', N''QR'', N''BANK_TRANSFER''.
- Tac dong du lieu: THEM THAT ChargingSession, PaymentTransaction va Invoice.
*/

PRINT N'Thanh toán và lập hóa đơn: khách hàng thanh toán phiên sạc đã hoàn tất và tạo hóa đơn tương ứng.';

DECLARE @UserID INT = (SELECT UserID FROM [Identity].UserAccount WHERE Username = N'customer01');
DECLARE @VehicleID INT = (SELECT TOP 1 VehicleID FROM Operations.Vehicle WHERE UserID = @UserID AND IsActive = 1 ORDER BY VehicleID DESC);
DECLARE @PointID INT = (SELECT TOP 1 PointID FROM AppView.vw_AvailableChargingPoints ORDER BY PointID);
DECLARE @Started TABLE (SessionID BIGINT, SessionCode NVARCHAR(40), UserID INT, StationID INT, PointID INT, SessionStatus NVARCHAR(30), StartTime DATETIME2);
DECLARE @SessionID BIGINT;

INSERT INTO @Started
EXEC Operations.sp_StartChargingSession @UserID = @UserID, @VehicleID = @VehicleID, @PointID = @PointID, @MeterStart = 2000.00;

SELECT @SessionID = SessionID FROM @Started;
EXEC Operations.sp_EndChargingSession @SessionID = @SessionID, @MeterEnd = 2018.25;

SELECT SessionID, SessionCode, CostTotal, SessionStatus
FROM Operations.ChargingSession
WHERE SessionID = @SessionID;

EXEC Payments.sp_CreatePayment
    @UserID = @UserID,
    @SessionID = @SessionID,
    @PaymentMethod = N'QR';

EXEC Payments.sp_CreateInvoice
    @SessionID = @SessionID;

SELECT *
FROM AppView.vw_InvoiceDetail
WHERE SessionCode IN (SELECT SessionCode FROM Operations.ChargingSession WHERE SessionID = @SessionID);
GO



==============================================================================
-- Payments.sp_RefundPayment
==============================================================================

--database/05_Create_Stored_Procedures.sql
CREATE OR ALTER PROCEDURE Payments.sp_RefundPayment
    @TransactionID BIGINT,
    @Reason NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @Status NVARCHAR(20), @SessionID BIGINT;
        SELECT @Status = TransactionStatus, @SessionID = SessionID
        FROM Payments.PaymentTransaction
        WHERE TransactionID = @TransactionID;

        IF @Status IS NULL
            THROW 53040, 'Payment transaction does not exist.', 1;
        IF @Status <> N'Completed'
            THROW 53041, 'Only completed payments can be refunded.', 1;

        UPDATE Payments.PaymentTransaction
        SET TransactionStatus = N'Refunded',
            Description = COALESCE(@Reason, Description)
        WHERE TransactionID = @TransactionID;

        UPDATE Payments.Invoice
        SET InvoiceStatus = N'Refunded'
        WHERE TransactionID = @TransactionID;

        INSERT INTO Audit.AuditLog (SchemaName, TableName, RecordID, ActionType, OldValues, NewValues)
        VALUES (N'Payments', N'PaymentTransaction', CAST(@TransactionID AS NVARCHAR(100)), N'PAYMENT', N'Completed', N'Refunded');

        COMMIT TRANSACTION;

        SELECT TransactionID, SessionID, PaymentMethod, Amount, TransactionStatus, Description
        FROM Payments.PaymentTransaction
        WHERE TransactionID = @TransactionID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- >>> TEST: source kiem thu tinh nang
-- (Trich tu database/features/business_manager/11_refund_payment.sql)
USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: hoan tien co ban cho giao dich da thanh toan.
- Tham so co the sua: @TransactionID, @Reason.
- Chi giao dich Completed moi duoc chuyen sang Refunded.
- Tac dong du lieu: KHONG TAO BANG REFUND; chi cap nhat PaymentTransaction va Invoice sang Refunded.
*/

PRINT N'Hoàn tiền cơ bản: quản lý kinh doanh đổi trạng thái giao dịch và hóa đơn sang Refunded mà không tạo bảng refund riêng.';

DECLARE @TransactionID BIGINT = (
    SELECT TOP 1 TransactionID
    FROM Payments.PaymentTransaction
    WHERE TransactionStatus = N'Completed'
    ORDER BY TransactionID DESC
);

SELECT TransactionID, TransactionCode, PaymentMethod, Amount, TransactionStatus
FROM Payments.PaymentTransaction
WHERE TransactionID = @TransactionID;

EXEC Payments.sp_RefundPayment
    @TransactionID = @TransactionID,
    @Reason = N'FEATURE-DEMO refund approved by business manager.';

SELECT TransactionID, TransactionCode, PaymentMethod, Amount, TransactionStatus, Description
FROM Payments.PaymentTransaction
WHERE TransactionID = @TransactionID;

SELECT InvoiceID, InvoiceCode, TransactionID, InvoiceStatus
FROM Payments.Invoice
WHERE TransactionID = @TransactionID;
GO



==============================================================================
-- Payments.sp_CreateInvoice
==============================================================================

--database/05_Create_Stored_Procedures.sql
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

        IF (COALESCE(CAST(SESSION_CONTEXT(N'RoleCode') AS NVARCHAR(40)), N'') = N'Customer' OR IS_ROLEMEMBER(N'db_ev_customer') = 1)
           AND ISNULL(@UserID, -1) <> ISNULL(TRY_CONVERT(INT, SESSION_CONTEXT(N'UserID')), -2147483648)
            THROW 53022, 'Customer can only create invoice for own charging session.', 1;

        SELECT TOP 1 @TransactionID = TransactionID
        FROM Payments.PaymentTransaction
        WHERE SessionID = @SessionID
          AND TransactionStatus = N'Completed'
        ORDER BY CreatedAt DESC;

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

-- >>> TEST: source kiem thu tinh nang
-- (Trich tu database/features/customer/09_create_payment_invoice.sql)
USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: tao phien sac moi, thanh toan va lap hoa don.
- Tham so co the sua: @UserID, @VehicleID, @PointID, @PaymentMethod.
- @PaymentMethod hop le: N''CASH'', N''QR'', N''BANK_TRANSFER''.
- Tac dong du lieu: THEM THAT ChargingSession, PaymentTransaction va Invoice.
*/

PRINT N'Thanh toán và lập hóa đơn: khách hàng thanh toán phiên sạc đã hoàn tất và tạo hóa đơn tương ứng.';

DECLARE @UserID INT = (SELECT UserID FROM [Identity].UserAccount WHERE Username = N'customer01');
DECLARE @VehicleID INT = (SELECT TOP 1 VehicleID FROM Operations.Vehicle WHERE UserID = @UserID AND IsActive = 1 ORDER BY VehicleID DESC);
DECLARE @PointID INT = (SELECT TOP 1 PointID FROM AppView.vw_AvailableChargingPoints ORDER BY PointID);
DECLARE @Started TABLE (SessionID BIGINT, SessionCode NVARCHAR(40), UserID INT, StationID INT, PointID INT, SessionStatus NVARCHAR(30), StartTime DATETIME2);
DECLARE @SessionID BIGINT;

INSERT INTO @Started
EXEC Operations.sp_StartChargingSession @UserID = @UserID, @VehicleID = @VehicleID, @PointID = @PointID, @MeterStart = 2000.00;

SELECT @SessionID = SessionID FROM @Started;
EXEC Operations.sp_EndChargingSession @SessionID = @SessionID, @MeterEnd = 2018.25;

SELECT SessionID, SessionCode, CostTotal, SessionStatus
FROM Operations.ChargingSession
WHERE SessionID = @SessionID;

EXEC Payments.sp_CreatePayment
    @UserID = @UserID,
    @SessionID = @SessionID,
    @PaymentMethod = N'QR';

EXEC Payments.sp_CreateInvoice
    @SessionID = @SessionID;

SELECT *
FROM AppView.vw_InvoiceDetail
WHERE SessionCode IN (SELECT SessionCode FROM Operations.ChargingSession WHERE SessionID = @SessionID);
GO
