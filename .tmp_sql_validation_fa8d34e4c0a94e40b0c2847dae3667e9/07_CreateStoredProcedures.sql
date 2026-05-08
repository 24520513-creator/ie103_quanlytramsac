/*==============================================================================
  EV_Charging_System_Validation - ENTERPRISE STORED PROCEDURES
  ==============================================================================
  Patterns:  Transaction-safe | Error handling | Audit logging | Pagination
  =============================================================================*/

USE EV_Charging_System_Validation;
GO

-- ===========================================================================
-- sp_StartChargingSession - Initiate charging with full validation
-- ===========================================================================
CREATE OR ALTER PROCEDURE Operations.sp_StartChargingSession
    @UserID      INT,
    @VehicleID   INT = NULL,
    @PointID     INT,
    @Source      NVARCHAR(30) = N'MobileApp'
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @NewSessionID BIGINT;
    DECLARE @StationID INT;
    DECLARE @PolicyID INT;
    DECLARE @UserStatus NVARCHAR(20);
    DECLARE @PointStatus NVARCHAR(20);
    DECLARE @UserTierID INT;

    -- Validate user
    SELECT @UserStatus = AccountStatus FROM Users.[User] WHERE UserID = @UserID;
    IF @UserStatus IS NULL
        THROW 50001, N'User not found.', 1;
    IF @UserStatus != N'Active'
        THROW 50002, N'Account is not active. Check status or contact support.', 1;

    -- Validate point
    SELECT @PointStatus = PointStatus, @StationID = StationID
    FROM Infrastructure.ChargingPoint WHERE PointID = @PointID AND IsDeleted = 0;
    IF @PointStatus IS NULL
        THROW 50003, N'Charging point not found.', 1;
    IF @PointStatus != N'Available'
        THROW 50004, N'Charging point is not available.', 1;

    -- Resolve pricing policy
    SELECT TOP 1 @PolicyID = PolicyID
    FROM Operations.PricingPolicy
    WHERE IsActive = 1
      AND SYSDATETIME() BETWEEN AppliedFrom AND ISNULL(AppliedTo, '9999-12-31')
    ORDER BY Priority ASC;

    -- Get active membership tier
    SELECT @UserTierID = MembershipTierID
    FROM Operations.UserMembership
    WHERE UserID = @UserID AND IsActive = 1
      AND (ExpiresAt IS NULL OR ExpiresAt > SYSDATETIME());

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO Operations.ChargingSession
            (SessionCode, UserID, VehicleID, PointID, StationID, PolicyID,
             MembershipTierID, StartTime, SessionSource, SessionStatus)
        VALUES
            (N'SES-' + FORMAT(SYSDATETIME(), N'yyyyMMdd-HHmmss-') + RIGHT('0000' + CAST(@PointID AS NVARCHAR), 4),
             @UserID, @VehicleID, @PointID, @StationID, @PolicyID,
             @UserTierID, SYSDATETIME(), @Source, N'Charging');

        SET @NewSessionID = SCOPE_IDENTITY();

        -- Update point to busy
        UPDATE Infrastructure.ChargingPoint
        SET PointStatus = N'Busy', UpdatedAt = SYSDATETIME()
        WHERE PointID = @PointID;

        -- Audit log
        INSERT INTO Audit.SessionStatusHistory (SessionID, PreviousStatus, NewStatus, ChangeReason)
        VALUES (@NewSessionID, NULL, N'Charging', N'Session started');

        COMMIT TRANSACTION;

        SELECT
            @NewSessionID AS SessionID,
            N'Session started successfully' AS Message,
            @PolicyID AS AppliedPolicyID;
        RETURN 0;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- ===========================================================================
-- sp_EndChargingSession - Complete session with cost calculation
-- ===========================================================================
CREATE OR ALTER PROCEDURE Operations.sp_EndChargingSession
    @SessionID        BIGINT,
    @MeterEnd         DECIMAL(13,4),
    @EndBatteryPercent DECIMAL(5,2) = NULL,
    @StopReason       NVARCHAR(50) = N'Completed'
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @PointID INT;
    DECLARE @PolicyID INT;
    DECLARE @MeterStart DECIMAL(13,4);
    DECLARE @StartTime DATETIME2;
    DECLARE @TotalKWh DECIMAL(13,4);
    DECLARE @DurationMinutes INT;
    DECLARE @AvgPower DECIMAL(7,2);
    DECLARE @BasePrice DECIMAL(19,4);
    DECLARE @Discount DECIMAL(5,2);
    DECLARE @Cost MONEY;
    DECLARE @EndTime DATETIME2 = SYSDATETIME();
    DECLARE @UserID INT;
    DECLARE @MembershipTierID INT;

    -- Validate session
    SELECT @PointID = PointID, @PolicyID = PolicyID, @MeterStart = MeterStart,
           @StartTime = StartTime, @UserID = UserID, @MembershipTierID = MembershipTierID
    FROM Operations.ChargingSession
    WHERE SessionID = @SessionID AND SessionStatus = N'Charging' AND IsDeleted = 0;

    IF @PointID IS NULL
        THROW 50010, N'Session not found or already completed.', 1;

    -- Calculate metrics
    SET @TotalKWh = @MeterEnd - ISNULL(@MeterStart, 0);
    SET @DurationMinutes = DATEDIFF(MINUTE, @StartTime, @EndTime);
    SET @AvgPower = CASE WHEN @DurationMinutes > 0
        THEN CAST(@TotalKWh / (@DurationMinutes / 60.0) AS DECIMAL(7,2)) ELSE 0 END;

    -- Get pricing
    SELECT @BasePrice = BasePricePerKWh
    FROM Operations.PricingPolicy WHERE PolicyID = @PolicyID;

    -- Get membership discount
    SELECT @Discount = DiscountPercent
    FROM Operations.MembershipTier WHERE MembershipTierID = @MembershipTierID;

    -- Calculate cost using pricing engine
    SET @Cost = Operations.fn_CalculateChargingCost(@TotalKWh, @BasePrice, ISNULL(@Discount, 0), @StartTime);

    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE Operations.ChargingSession
        SET EndTime = @EndTime,
            EndBatteryPercent = @EndBatteryPercent,
            MeterEnd = @MeterEnd,
            TotalKWh = @TotalKWh,
            ChargingDurationMinutes = @DurationMinutes,
            AveragePowerKW = @AvgPower,
            CostBeforeDiscount = CAST(@TotalKWh * @BasePrice AS MONEY),
            DiscountAmount = CAST((@TotalKWh * @BasePrice) - @Cost AS MONEY),
            CostTotal = @Cost,
            StopReason = @StopReason,
            SessionStatus = N'Completed',
            UpdatedAt = @EndTime
        WHERE SessionID = @SessionID;

        -- Free charging point
        UPDATE Infrastructure.ChargingPoint
        SET PointStatus = N'Available', UpdatedAt = @EndTime
        WHERE PointID = @PointID;

        -- Status history
        INSERT INTO Audit.SessionStatusHistory (SessionID, PreviousStatus, NewStatus, ChangeReason)
        VALUES (@SessionID, N'Charging', N'Completed', @StopReason);

        COMMIT TRANSACTION;

        SELECT
            @SessionID AS SessionID,
            @TotalKWh AS TotalKWh,
            @DurationMinutes AS DurationMinutes,
            @Cost AS CostTotal,
            N'Session completed' AS Message;
        RETURN 0;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- ===========================================================================
-- sp_CreatePayment - Full payment flow with wallet dedup + gateway call
-- ===========================================================================
CREATE OR ALTER PROCEDURE Payments.sp_CreatePayment
    @UserID        INT,
    @SessionID     BIGINT,
    @PaymentMethod NVARCHAR(30) = N'Wallet',
    @GatewayID     INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Amount MONEY;
    DECLARE @WalletBalance MONEY;
    DECLARE @WalletID INT;
    DECLARE @TransactionID BIGINT;

    -- Get session cost
    SELECT @Amount = CostTotal
    FROM Operations.ChargingSession
    WHERE SessionID = @SessionID AND SessionStatus = N'Completed' AND IsDeleted = 0;

    IF @Amount IS NULL
        THROW 50020, N'Session not found, not completed, or has no cost.', 1;

    -- Check for duplicate payment
    IF EXISTS (SELECT 1 FROM Payments.[Transaction]
               WHERE SessionID = @SessionID AND TransactionStatus = N'Completed')
        THROW 50021, N'This session already has a completed payment.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Create transaction
        INSERT INTO Payments.[Transaction]
            (TransactionCode, UserID, SessionID, GatewayID, TransactionType,
             Direction, Amount, PaymentMethod, TransactionStatus)
        VALUES
            (N'TXN-' + FORMAT(SYSDATETIME(), N'yyyyMMdd-HHmmss-') + RIGHT('0000' + CAST(@SessionID AS NVARCHAR), 4),
             @UserID, @SessionID, @GatewayID, N'ChargingPayment', N'D',
             @Amount, @PaymentMethod, N'Completed');

        SET @TransactionID = SCOPE_IDENTITY();

        -- If wallet payment, deduct balance
        IF @PaymentMethod = N'Wallet'
        BEGIN
            SELECT @WalletID = WalletID, @WalletBalance = Balance
            FROM Payments.Wallet WHERE UserID = @UserID AND IsActive = 1;

            IF @WalletBalance < @Amount
                THROW 50022, N'Insufficient wallet balance.', 1;

            UPDATE Payments.Wallet
            SET Balance = Balance - @Amount,
                PendingBalance = PendingBalance,
                LastTransactionAt = SYSDATETIME(),
                UpdatedAt = SYSDATETIME()
            WHERE WalletID = @WalletID;

            INSERT INTO Payments.WalletTransaction
                (WalletID, TransactionID, Amount, BalanceBefore, Direction, TransactionType, Description)
            VALUES
                (@WalletID, @TransactionID, -@Amount, @WalletBalance, N'D',
                 N'ChargingPayment', N'Payment for session ' + CAST(@SessionID AS NVARCHAR));
        END;

        -- Transaction status history
        INSERT INTO Payments.TransactionStatusHistory
            (TransactionID, PreviousStatus, NewStatus, Reason)
        VALUES (@TransactionID, NULL, N'Completed', N'Payment processed');

        COMMIT TRANSACTION;

        SELECT @TransactionID AS TransactionID, @Amount AS Amount, N'Payment successful' AS Message;
        RETURN 0;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- ===========================================================================
-- sp_ProcessRefund - Full refund flow with approval
-- ===========================================================================
CREATE OR ALTER PROCEDURE Payments.sp_ProcessRefund
    @OriginalTransactionID BIGINT,
    @RefundAmount          MONEY,
    @RefundReason          NVARCHAR(500),
    @ApprovedBy            INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @OriginalAmount MONEY;
    DECLARE @AlreadyRefunded MONEY;
    DECLARE @RefundID BIGINT;
    DECLARE @UserID INT;

    SELECT @OriginalAmount = Amount, @UserID = UserID
    FROM Payments.[Transaction]
    WHERE TransactionID = @OriginalTransactionID AND TransactionStatus = N'Completed';

    IF @OriginalAmount IS NULL
        THROW 50030, N'Original transaction not found or not completed.', 1;

    SELECT @AlreadyRefunded = ISNULL(SUM(RefundAmount), 0)
    FROM Payments.RefundTransaction
    WHERE OriginalTransactionID = @OriginalTransactionID AND RefundStatus = N'Completed';

    IF (@AlreadyRefunded + @RefundAmount) > @OriginalAmount
        THROW 50031, N'Refund amount exceeds remaining balance.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO Payments.RefundTransaction
            (OriginalTransactionID, RefundCode, RefundAmount, RefundReason,
             RefundType, RefundStatus, ApprovedBy, ApprovedAt)
        VALUES
            (@OriginalTransactionID,
             N'RFND-' + FORMAT(SYSDATETIME(), N'yyyyMMdd-HHmmss'),
             @RefundAmount, @RefundReason,
             CASE WHEN @RefundAmount = @OriginalAmount THEN N'Full' ELSE N'Partial' END,
             N'Approved', @ApprovedBy, SYSDATETIME());

        SET @RefundID = SCOPE_IDENTITY();

        -- Update original transaction status
        UPDATE Payments.[Transaction]
        SET TransactionStatus = CASE
            WHEN @RefundAmount = @OriginalAmount THEN N'Refunded'
            ELSE N'PartiallyRefunded'
        END, UpdatedAt = SYSDATETIME()
        WHERE TransactionID = @OriginalTransactionID;

        COMMIT TRANSACTION;

        SELECT @RefundID AS RefundID, N'Refund processed successfully' AS Message;
        RETURN 0;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- ===========================================================================
-- sp_GetMonthlyRevenueReport - Paginated monthly revenue report
-- ===========================================================================
CREATE OR ALTER PROCEDURE Reporting.sp_GetMonthlyRevenueReport
    @Year       INT = NULL,
    @FranchiseID INT = NULL,
    @PageNumber INT = 1,
    @PageSize   INT = 50
AS
BEGIN
    SET NOCOUNT ON;

    IF @Year IS NULL SET @Year = YEAR(SYSDATETIME());

    DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;

    SELECT
        YEAR(cs.StartTime)                                  AS RevenueYear,
        MONTH(cs.StartTime)                                 AS RevenueMonth,
        FORMAT(cs.StartTime, N'MM-yyyy')                    AS MonthLabel,
        ISNULL(f.FranchiseID, 0)                            AS FranchiseID,
        ISNULL(f.FranchiseName, N'All')                     AS FranchiseName,
        COUNT(DISTINCT cs.SessionID)                        AS TransactionCount,
        COUNT(DISTINCT cs.UserID)                           AS UniqueCustomers,
        ISNULL(SUM(cs.TotalKWh), 0)                         AS TotalKWh,
        ISNULL(SUM(cs.CostTotal), 0)                        AS TotalRevenue,
        ISNULL(AVG(cs.CostTotal), 0)                        AS AvgTransactionValue,
        ISNULL(SUM(cs.CostTotal * f.RevenueShareRate / 100), 0) AS TotalCommission,
        COUNT(DISTINCT s.StationID)                         AS ActiveStations
    FROM Operations.ChargingSession cs
    JOIN Infrastructure.ChargingStation s ON cs.StationID = s.StationID
    LEFT JOIN Infrastructure.Franchise f ON s.FranchiseID = f.FranchiseID
    WHERE cs.SessionStatus = N'Completed'
      AND YEAR(cs.StartTime) = @Year
      AND (@FranchiseID IS NULL OR s.FranchiseID = @FranchiseID)
      AND cs.IsDeleted = 0
    GROUP BY YEAR(cs.StartTime), MONTH(cs.StartTime), FORMAT(cs.StartTime, N'MM-yyyy'),
             f.FranchiseID, f.FranchiseName
    ORDER BY RevenueYear DESC, RevenueMonth DESC
    OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;

    -- Return total count for pagination
    SELECT COUNT(*) AS TotalRecords
    FROM (
        SELECT 1 AS C
        FROM Operations.ChargingSession cs
        JOIN Infrastructure.ChargingStation s ON cs.StationID = s.StationID
        LEFT JOIN Infrastructure.Franchise f ON s.FranchiseID = f.FranchiseID
        WHERE cs.SessionStatus = N'Completed'
          AND YEAR(cs.StartTime) = @Year
          AND (@FranchiseID IS NULL OR s.FranchiseID = @FranchiseID)
          AND cs.IsDeleted = 0
        GROUP BY YEAR(cs.StartTime), MONTH(cs.StartTime), f.FranchiseID, f.FranchiseName
    ) AS CountQuery;
END;
GO

-- ===========================================================================
-- sp_GetStationPerformance - Station KPI dashboard data
-- ===========================================================================
CREATE OR ALTER PROCEDURE Reporting.sp_GetStationPerformance
    @FranchiseID INT = NULL,
    @TopCount    INT = 20
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (@TopCount)
        s.StationID,
        s.StationCode,
        s.StationName,
        f.FranchiseName,
        s.StationStatus,
        s.NetworkStatus,
        s.Latitude,
        s.Longitude,
        COUNT(DISTINCT p.PointID)                   AS TotalPoints,
        SUM(CASE WHEN p.PointStatus = N'Available' THEN 1 ELSE 0 END) AS AvailablePoints,
        SUM(CASE WHEN p.PointStatus = N'Busy' THEN 1 ELSE 0 END)      AS BusyPoints,
        SUM(CASE WHEN p.PointStatus IN (N'Error', N'Offline') THEN 1 ELSE 0 END) AS FaultedPoints,
        COUNT(DISTINCT cs.SessionID)                AS TotalSessions,
        ISNULL(SUM(cs.TotalKWh), 0)                 AS TotalEnergyKWh,
        ISNULL(SUM(cs.CostTotal), 0)                AS TotalRevenue,
        ISNULL(SUM(cs.ChargingDurationMinutes), 0)  AS TotalMinutes,
        CASE WHEN COUNT(DISTINCT cs.SessionID) > 0
            THEN ISNULL(SUM(cs.CostTotal), 0) / COUNT(DISTINCT cs.SessionID) ELSE 0 END AS RevenuePerSession,
        CASE WHEN COUNT(DISTINCT cs.SessionID) > 0
            THEN ISNULL(SUM(cs.TotalKWh), 0) / COUNT(DISTINCT cs.SessionID) ELSE 0 END AS KWhPerSession
    FROM Infrastructure.ChargingStation s
    JOIN Infrastructure.Franchise f ON s.FranchiseID = f.FranchiseID
    LEFT JOIN Infrastructure.ChargingPoint p ON s.StationID = p.StationID AND p.IsDeleted = 0
    LEFT JOIN Operations.ChargingSession cs ON s.StationID = cs.StationID
        AND cs.SessionStatus = N'Completed' AND cs.IsDeleted = 0
    WHERE s.IsDeleted = 0
      AND (@FranchiseID IS NULL OR s.FranchiseID = @FranchiseID)
    GROUP BY s.StationID, s.StationCode, s.StationName, f.FranchiseName,
             s.StationStatus, s.NetworkStatus, s.Latitude, s.Longitude
    ORDER BY TotalRevenue DESC;
END;
GO

-- ===========================================================================
-- sp_GetCustomerChargingHistory - Paginated customer history
-- ===========================================================================
CREATE OR ALTER PROCEDURE Reporting.sp_GetCustomerChargingHistory
    @UserID     INT,
    @PageNumber INT = 1,
    @PageSize   INT = 20
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;

    SELECT
        cs.SessionID,
        cs.SessionCode,
        s.StationName,
        p.PointCode,
        p.ConnectorType,
        p.PowerKW,
        cs.StartTime,
        cs.EndTime,
        cs.StartBatteryPercent,
        cs.EndBatteryPercent,
        cs.TotalKWh,
        cs.ChargingDurationMinutes,
        cs.AveragePowerKW,
        cs.CostBeforeDiscount,
        cs.DiscountAmount,
        cs.CostTotal,
        cs.SessionStatus,
        cs.StopReason,
        cs.SessionType,
        v.PlateNumber,
        v.Brand + N' ' + v.Model AS VehicleName
    FROM Operations.ChargingSession cs
    JOIN Infrastructure.ChargingStation s ON cs.StationID = s.StationID
    JOIN Infrastructure.ChargingPoint p ON cs.PointID = p.PointID
    LEFT JOIN Users.Vehicle v ON cs.VehicleID = v.VehicleID
    WHERE cs.UserID = @UserID AND cs.IsDeleted = 0
    ORDER BY cs.StartTime DESC
    OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;

    SELECT COUNT(*) AS TotalRecords
    FROM Operations.ChargingSession
    WHERE UserID = @UserID AND IsDeleted = 0;
END;
GO

-- ===========================================================================
-- sp_DailyKPIAggregation - ETL procedure to populate daily KPI tables
-- ===========================================================================
CREATE OR ALTER PROCEDURE Analytics.sp_DailyKPIAggregation
    @AggDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @AggDate IS NULL SET @AggDate = CAST(DATEADD(DAY, -1, SYSDATETIME()) AS DATE);

    -- Station daily KPI
    MERGE Analytics.DailyStationKPI AS target
    USING (
        SELECT
            s.StationID,
            @AggDate AS KpiDate,
            COUNT(DISTINCT cs.SessionID)                        AS TotalSessions,
            ISNULL(SUM(cs.TotalKWh), 0)                         AS TotalKWh,
            ISNULL(SUM(cs.CostTotal), 0)                        AS TotalRevenue,
            ISNULL(AVG(cs.AveragePowerKW), 0)                   AS AvgPowerKW,
            ISNULL(AVG(cs.ChargingDurationMinutes), 0)          AS AvgChargingMinutes,
            ISNULL(MAX(daily.MaxConcurrent), 0)                 AS PeakConcurrentSessions,
            COUNT(DISTINCT cs.UserID)                           AS UniqueUsers,
            ISNULL((SELECT COUNT(*) FROM Monitoring.ErrorLog e
                    WHERE e.StationID = s.StationID
                    AND CAST(e.OccurredAt AS DATE) = @AggDate), 0) AS ErrorCount
        FROM Infrastructure.ChargingStation s
        LEFT JOIN Operations.ChargingSession cs ON s.StationID = cs.StationID
            AND CAST(cs.StartTime AS DATE) = @AggDate
            AND cs.SessionStatus = N'Completed'
            AND cs.IsDeleted = 0
        LEFT JOIN (
            SELECT StationID, MAX(HourlyCount) AS MaxConcurrent FROM (
                SELECT StationID, DATEPART(HOUR, StartTime) AS HourBucket,
                       COUNT(DISTINCT SessionID) AS HourlyCount
                FROM Operations.ChargingSession
                WHERE CAST(StartTime AS DATE) = @AggDate AND IsDeleted = 0
                GROUP BY StationID, DATEPART(HOUR, StartTime)
            ) h GROUP BY StationID
        ) daily ON s.StationID = daily.StationID
        WHERE s.IsDeleted = 0
        GROUP BY s.StationID
    ) AS source
    ON (target.StationID = source.StationID AND target.KpiDate = source.KpiDate)
    WHEN MATCHED THEN
        UPDATE SET
            TotalSessions = source.TotalSessions,
            TotalKWh = source.TotalKWh,
            TotalRevenue = source.TotalRevenue,
            AvgPowerKW = source.AvgPowerKW,
            AvgChargingMinutes = source.AvgChargingMinutes,
            PeakConcurrentSessions = source.PeakConcurrentSessions,
            UniqueUsers = source.UniqueUsers,
            ErrorCount = source.ErrorCount
    WHEN NOT MATCHED THEN
        INSERT (StationID, KpiDate, TotalSessions, TotalKWh, TotalRevenue, AvgPowerKW,
                AvgChargingMinutes, PeakConcurrentSessions, UniqueUsers, ErrorCount)
        VALUES (source.StationID, source.KpiDate, source.TotalSessions, source.TotalKWh,
                source.TotalRevenue, source.AvgPowerKW, source.AvgChargingMinutes,
                source.PeakConcurrentSessions, source.UniqueUsers, source.ErrorCount);

    -- Franchise daily KPI
    MERGE Analytics.DailyFranchiseKPI AS target
    USING (
        SELECT
            f.FranchiseID,
            @AggDate AS KpiDate,
            ISNULL(SUM(dk.TotalSessions), 0)    AS TotalSessions,
            ISNULL(SUM(dk.TotalKWh), 0)         AS TotalKWh,
            ISNULL(SUM(dk.TotalRevenue), 0)     AS TotalRevenue,
            ISNULL(SUM(dk.TotalRevenue * f.RevenueShareRate / 100), 0) AS CommissionAmount,
            COUNT(DISTINCT s.StationID)         AS ActiveStations,
            ISNULL(SUM(dk.ErrorCount), 0)       AS TotalErrors,
            ISNULL(SUM(dk.UniqueUsers), 0)      AS UniqueUsers
        FROM Infrastructure.Franchise f
        JOIN Infrastructure.ChargingStation s ON f.FranchiseID = s.FranchiseID AND s.IsDeleted = 0
        LEFT JOIN Analytics.DailyStationKPI dk ON s.StationID = dk.StationID AND dk.KpiDate = @AggDate
        WHERE f.IsDeleted = 0
        GROUP BY f.FranchiseID, f.RevenueShareRate
    ) AS source
    ON (target.FranchiseID = source.FranchiseID AND target.KpiDate = source.KpiDate)
    WHEN MATCHED THEN
        UPDATE SET
            TotalSessions = source.TotalSessions,
            TotalKWh = source.TotalKWh,
            TotalRevenue = source.TotalRevenue,
            CommissionAmount = source.CommissionAmount,
            ActiveStations = source.ActiveStations,
            TotalErrors = source.TotalErrors,
            UniqueUsers = source.UniqueUsers
    WHEN NOT MATCHED THEN
        INSERT (FranchiseID, KpiDate, TotalSessions, TotalKWh, TotalRevenue, CommissionAmount,
                ActiveStations, TotalErrors, UniqueUsers)
        VALUES (source.FranchiseID, source.KpiDate, source.TotalSessions, source.TotalKWh,
                source.TotalRevenue, source.CommissionAmount, source.ActiveStations,
                source.TotalErrors, source.UniqueUsers);

    -- Hourly aggregation
    MERGE Analytics.HourlySessionAgg AS target
    USING (
        SELECT
            cs.StationID,
            @AggDate AS AggDate,
            DATEPART(HOUR, cs.StartTime) AS AggHour,
            COUNT(DISTINCT cs.SessionID)    AS TotalSessions,
            ISNULL(SUM(cs.TotalKWh), 0)     AS TotalKWh,
            ISNULL(SUM(cs.CostTotal), 0)    AS TotalRevenue,
            ISNULL(AVG(cs.ChargingDurationMinutes), 0) AS AvgDurationMin
        FROM Operations.ChargingSession cs
        WHERE CAST(cs.StartTime AS DATE) = @AggDate
          AND cs.SessionStatus = N'Completed'
          AND cs.IsDeleted = 0
        GROUP BY cs.StationID, DATEPART(HOUR, cs.StartTime)
    ) AS source
    ON (target.StationID = source.StationID
        AND target.AggDate = source.AggDate
        AND target.AggHour = source.AggHour)
    WHEN MATCHED THEN
        UPDATE SET
            TotalSessions = source.TotalSessions,
            TotalKWh = source.TotalKWh,
            TotalRevenue = source.TotalRevenue,
            AvgDurationMin = source.AvgDurationMin
    WHEN NOT MATCHED THEN
        INSERT (StationID, AggDate, AggHour, TotalSessions, TotalKWh, TotalRevenue, AvgDurationMin)
        VALUES (source.StationID, source.AggDate, source.AggHour, source.TotalSessions,
                source.TotalKWh, source.TotalRevenue, source.AvgDurationMin);

    PRINT N'Daily KPI aggregation completed for ' + CAST(@AggDate AS NVARCHAR(20));
END;
GO

PRINT N'Enterprise stored procedures created successfully.';
GO

