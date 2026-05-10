USE EV_Charging_System;
GO

-- ============================================================
-- sp_StartChargingSession
-- ============================================================
CREATE OR ALTER PROCEDURE Operations.sp_StartChargingSession
    @UserID        INT,
    @VehicleID     INT = NULL,
    @PointID       INT,
    @StartBatteryPercent DECIMAL(5,2) = NULL,
    @MeterStart    DECIMAL(13,4) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Validate point exists and is available
        DECLARE @PointStatus NVARCHAR(20), @StationID INT, @ConnectorType NVARCHAR(30);
        SELECT @PointStatus = PointStatus, @StationID = StationID, @ConnectorType = ConnectorType
        FROM Infrastructure.ChargingPoint WHERE PointID = @PointID AND IsActive = 1;

        IF @PointStatus IS NULL
            THROW 50001, 'Charging point not found', 1;
        IF @PointStatus != 'Available'
            THROW 50002, 'Charging point is not available', 1;

        -- Validate user is active
        IF NOT EXISTS (SELECT 1 FROM Users.[User] WHERE UserID = @UserID AND AccountStatus = 'Active')
            THROW 50003, 'User account is not active', 1;

        -- Validate station is active
        IF NOT EXISTS (SELECT 1 FROM Infrastructure.ChargingStation WHERE StationID = @StationID AND StationStatus = 'Active' AND IsActive = 1)
            THROW 50004, 'Station is not active', 1;

        -- Get active pricing policy
        DECLARE @PolicyID INT;
        SELECT TOP 1 @PolicyID = PolicyID
        FROM Operations.PricingPolicy
        WHERE IsActive = 1 AND AppliedFrom <= SYSDATETIME() AND (AppliedTo IS NULL OR AppliedTo >= SYSDATETIME())
        ORDER BY PolicyID;

        IF @PolicyID IS NULL
            THROW 50005, 'No active pricing policy', 1;

        -- Generate session code
        DECLARE @SessionCode NVARCHAR(30) = 'SES-' + FORMAT(SYSDATETIME(), 'yyyyMMdd') + '-' + LEFT(CAST(NEWID() AS NVARCHAR(36)), 6);

        -- Create session
        DECLARE @SessionID BIGINT;
        INSERT INTO Operations.ChargingSession (SessionCode, UserID, VehicleID, PointID, StationID, PolicyID,
            StartTime, StartBatteryPercent, MeterStart, SessionStatus)
        VALUES (@SessionCode, @UserID, @VehicleID, @PointID, @StationID, @PolicyID,
            SYSDATETIME(), @StartBatteryPercent, @MeterStart, 'Charging');

        SET @SessionID = SCOPE_IDENTITY();

        -- Update point status
        UPDATE Infrastructure.ChargingPoint SET PointStatus = 'Busy', UpdatedAt = SYSDATETIME() WHERE PointID = @PointID;

        COMMIT TRANSACTION;

        -- Return created session
        SELECT * FROM Operations.ChargingSession WHERE SessionID = @SessionID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- ============================================================
-- sp_EndChargingSession
-- ============================================================
CREATE OR ALTER PROCEDURE Operations.sp_EndChargingSession
    @SessionID            BIGINT,
    @EndBatteryPercent    DECIMAL(5,2) = NULL,
    @MeterEnd             DECIMAL(13,4) = NULL,
    @TotalKWh             DECIMAL(13,4) = NULL,
    @StopReason           NVARCHAR(50) = 'Completed'
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @CurrentStatus NVARCHAR(20), @PointID INT, @PolicyID INT, @StartTime DATETIME2;

        SELECT @CurrentStatus = SessionStatus, @PointID = PointID, @PolicyID = PolicyID, @StartTime = StartTime
        FROM Operations.ChargingSession WHERE SessionID = @SessionID;

        IF @CurrentStatus IS NULL
            THROW 50010, 'Session not found', 1;
        IF @CurrentStatus != 'Charging'
            THROW 50011, 'Session is not in Charging status', 1;

        DECLARE @DurationMinutes INT = DATEDIFF(MINUTE, @StartTime, SYSDATETIME());

        -- Calculate cost using function
        DECLARE @CalculatedCost MONEY;
        IF @TotalKWh IS NOT NULL AND @TotalKWh > 0
        SET @CalculatedCost = dbo.fn_CalculateChargingCost(@TotalKWh, @PolicyID, @StartTime);
    ELSE IF @MeterEnd IS NOT NULL
        BEGIN
            DECLARE @MeterStart DECIMAL(13,4);
            SELECT @MeterStart = MeterStart FROM Operations.ChargingSession WHERE SessionID = @SessionID;
            IF @MeterStart IS NOT NULL
            BEGIN
                SET @TotalKWh = @MeterEnd - @MeterStart;
                SET @CalculatedCost = dbo.fn_CalculateChargingCost(@TotalKWh, @PolicyID, @StartTime);
            END;
        END;

        -- Update session
        UPDATE Operations.ChargingSession SET
            EndTime = SYSDATETIME(),
            EndBatteryPercent = @EndBatteryPercent,
            MeterEnd = @MeterEnd,
            TotalKWh = @TotalKWh,
            ChargingDurationMinutes = @DurationMinutes,
            CostTotal = @CalculatedCost,
            StopReason = @StopReason,
            SessionStatus = 'Completed',
            UpdatedAt = SYSDATETIME()
        WHERE SessionID = @SessionID;

        -- Free up the point
        UPDATE Infrastructure.ChargingPoint SET PointStatus = 'Available', UpdatedAt = SYSDATETIME() WHERE PointID = @PointID;

        COMMIT TRANSACTION;

        SELECT * FROM Operations.ChargingSession WHERE SessionID = @SessionID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- ============================================================
-- sp_CreatePayment
-- ============================================================
CREATE OR ALTER PROCEDURE Payments.sp_CreatePayment
    @UserID         INT,
    @SessionID      BIGINT,
    @PaymentMethod  NVARCHAR(30) = 'Wallet'
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Validate session
        DECLARE @SessionStatus NVARCHAR(20), @CostTotal MONEY, @SessionUserID INT;
        SELECT @SessionStatus = SessionStatus, @CostTotal = CostTotal, @SessionUserID = UserID
        FROM Operations.ChargingSession WHERE SessionID = @SessionID;

        IF @SessionStatus IS NULL
            THROW 50020, 'Session not found', 1;
        IF @SessionStatus != 'Completed'
            THROW 50021, 'Session must be completed before payment', 1;
        IF @SessionUserID != @UserID
            THROW 50022, 'Session does not belong to user', 1;
        IF @CostTotal IS NULL OR @CostTotal <= 0
            THROW 50023, 'Invalid payment amount', 1;

        -- Check duplicate payment
        IF EXISTS (SELECT 1 FROM Payments.[Transaction] WHERE SessionID = @SessionID AND TransactionStatus = 'Completed')
            THROW 50024, 'Payment already completed for this session', 1;

        -- Generate transaction code
        DECLARE @TxnCode NVARCHAR(30) = 'TXN-' + FORMAT(SYSDATETIME(), 'yyyyMMdd') + '-' + LEFT(CAST(NEWID() AS NVARCHAR(36)), 6);

        -- Create transaction
        DECLARE @TxnID BIGINT;
        INSERT INTO Payments.[Transaction] (TransactionCode, UserID, SessionID, TransactionType, Direction, Amount, TransactionStatus, PaymentMethod)
        VALUES (@TxnCode, @UserID, @SessionID, 'ChargingPayment', 'D', @CostTotal, 'Pending', @PaymentMethod);

        SET @TxnID = SCOPE_IDENTITY();

        -- Process wallet payment
        IF @PaymentMethod = 'Wallet'
        BEGIN
            DECLARE @WalletID INT, @Balance MONEY;
            SELECT @WalletID = WalletID, @Balance = Balance
            FROM Payments.Wallet WHERE UserID = @UserID AND IsActive = 1;

            IF @WalletID IS NULL
                THROW 50025, 'No active wallet found', 1;
            IF @Balance < @CostTotal
            BEGIN
                UPDATE Payments.[Transaction] SET TransactionStatus = 'Failed' WHERE TransactionID = @TxnID;
                THROW 50026, 'Insufficient wallet balance', 1;
            END;

            -- Deduct balance
            UPDATE Payments.Wallet SET Balance = Balance - @CostTotal, LastTransactionAt = SYSDATETIME() WHERE WalletID = @WalletID;

            -- Log wallet transaction
            INSERT INTO Payments.WalletTransaction (WalletID, TransactionID, Amount, BalanceBefore, Direction, TransactionType)
            VALUES (@WalletID, @TxnID, -@CostTotal, @Balance, 'D', 'ChargingPayment');

            -- Mark transaction completed
            UPDATE Payments.[Transaction] SET TransactionStatus = 'Completed', SettledAt = SYSDATETIME() WHERE TransactionID = @TxnID;
        END;

        COMMIT TRANSACTION;

        SELECT * FROM Payments.[Transaction] WHERE TransactionID = @TxnID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- ============================================================
-- sp_GetDashboardData: Unified dashboard data per role
-- ============================================================
CREATE OR ALTER PROCEDURE Reporting.sp_GetDashboardData
    @UserID INT,
    @Role   NVARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;

    IF @Role = 'Admin'
    BEGIN
        SELECT 'counts' AS [Key],
            (SELECT COUNT(*) FROM Users.[User] WHERE AccountStatus = 'Active') AS TotalUsers,
            (SELECT COUNT(*) FROM Infrastructure.ChargingStation WHERE IsActive = 1) AS TotalStations,
            (SELECT COUNT(*) FROM Infrastructure.Franchise WHERE IsActive = 1) AS TotalFranchises,
            (SELECT COUNT(*) FROM Operations.ChargingSession WHERE SessionStatus = 'Completed') AS TotalSessions,
            (SELECT COUNT(*) FROM Operations.ChargingSession WHERE SessionStatus = 'Charging') AS ActiveSessions,
            (SELECT ISNULL(SUM(TotalKWh), 0) FROM Operations.ChargingSession WHERE SessionStatus = 'Completed') AS TotalKWh,
            (SELECT ISNULL(SUM(CostTotal), 0) FROM Operations.ChargingSession WHERE SessionStatus = 'Completed') AS TotalRevenue;

        SELECT 'revenueByDay' AS [Key], CAST(StartTime AS DATE) AS Date, ISNULL(SUM(CostTotal), 0) AS Revenue, ISNULL(SUM(TotalKWh), 0) AS KWh
        FROM Operations.ChargingSession WHERE SessionStatus = 'Completed' AND StartTime >= DATEADD(DAY, -30, SYSDATETIME())
        GROUP BY CAST(StartTime AS DATE) ORDER BY Date;

        SELECT 'topStations' AS [Key], s.StationCode, s.StationName, COUNT(cs.SessionID) AS Sessions,
            ISNULL(SUM(cs.TotalKWh), 0) AS KWh, ISNULL(SUM(cs.CostTotal), 0) AS Revenue
        FROM Operations.ChargingSession cs JOIN Infrastructure.ChargingStation s ON cs.StationID = s.StationID
        WHERE cs.SessionStatus = 'Completed' GROUP BY s.StationCode, s.StationName ORDER BY Revenue DESC;
    END;

    IF @Role IN ('Manager', 'Admin')
    BEGIN
        DECLARE @FranchiseID INT;
        SELECT @FranchiseID = FranchiseID FROM Users.[User] WHERE UserID = @UserID;

        SELECT 'franchiseKPIs' AS [Key],
            (SELECT COUNT(*) FROM Infrastructure.ChargingStation WHERE FranchiseID = @FranchiseID AND IsActive = 1) AS TotalStations,
            (SELECT ISNULL(SUM(CostTotal), 0) FROM Operations.ChargingSession cs
                JOIN Infrastructure.ChargingStation s ON cs.StationID = s.StationID WHERE s.FranchiseID = @FranchiseID AND cs.SessionStatus = 'Completed') AS TotalRevenue,
            (SELECT COUNT(*) FROM Operations.ChargingSession cs
                JOIN Infrastructure.ChargingStation s ON cs.StationID = s.StationID WHERE s.FranchiseID = @FranchiseID AND cs.SessionStatus = 'Charging') AS ActiveSessions;
    END;

    -- Customer dashboard data
    IF @Role = 'Customer'
    BEGIN
        SELECT 'myStats' AS [Key],
            (SELECT COUNT(*) FROM Operations.ChargingSession WHERE UserID = @UserID AND SessionStatus = 'Completed') AS TotalSessions,
            (SELECT ISNULL(SUM(TotalKWh), 0) FROM Operations.ChargingSession WHERE UserID = @UserID AND SessionStatus = 'Completed') AS TotalKWh,
            (SELECT ISNULL(SUM(CostTotal), 0) FROM Operations.ChargingSession WHERE UserID = @UserID AND SessionStatus = 'Completed') AS TotalSpent,
            (SELECT ISNULL(Balance, 0) FROM Payments.Wallet WHERE UserID = @UserID) AS WalletBalance;

        SELECT 'mySessions' AS [Key], cs.*, s.StationName, p.PointCode, v.PlateNumber
        FROM Operations.ChargingSession cs
        JOIN Infrastructure.ChargingStation s ON cs.StationID = s.StationID
        JOIN Infrastructure.ChargingPoint p ON cs.PointID = p.PointID
        LEFT JOIN Users.Vehicle v ON cs.VehicleID = v.VehicleID
        WHERE cs.UserID = @UserID ORDER BY cs.StartTime DESC;
    END;
END;
GO

PRINT N'Stored procedures created.';
GO
