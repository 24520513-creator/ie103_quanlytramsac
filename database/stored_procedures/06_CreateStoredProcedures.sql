/*=============================================================================
  EV_Charging_System - STORED PROCEDURES
  =============================================================================*/

USE EV_Charging_System;
GO

-- ========================================
-- sp_StartChargingSession
-- Initiates a new charging session and sets the charging point to busy.
-- ========================================
CREATE OR ALTER PROCEDURE Operations.sp_StartChargingSession
    @UserID   INT,
    @PointID  INT,
    @PolicyID INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NewSessionID BIGINT;

    -- Validate customer
    IF NOT EXISTS (SELECT 1 FROM Users.Customers WHERE UserID = @UserID AND AccountStatus = N'Đang mở')
    BEGIN
        RAISERROR(N'Tài khoản khách hàng không hợp lệ hoặc đang bị khóa.', 16, 1);
        RETURN -1;
    END;

    -- Validate point availability
    IF NOT EXISTS (SELECT 1 FROM Infrastructure.ChargingPoint WHERE PointID = @PointID AND PointStatus = N'Khả dụng')
    BEGIN
        RAISERROR(N'Điểm sạc không khả dụng.', 16, 1);
        RETURN -2;
    END;

    -- Validate pricing policy
    IF NOT EXISTS (SELECT 1 FROM Operations.PricingPolicy WHERE PolicyID = @PolicyID AND GETDATE() BETWEEN AppliedFrom AND ISNULL(AppliedTo, '9999-12-31'))
    BEGIN
        RAISERROR(N'Chính sách giá không hợp lệ hoặc đã hết hạn.', 16, 1);
        RETURN -3;
    END;

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO Operations.ChargingSession (UserID, PointID, PolicyID, StartTime, Status)
        VALUES (@UserID, @PointID, @PolicyID, SYSDATETIME(), N'Đang sạc');

        SET @NewSessionID = SCOPE_IDENTITY();
        -- Point status update is handled by trg_ChargingPoint_AutoUpdateStatus

        COMMIT TRANSACTION;

        SELECT @NewSessionID AS SessionID, N'Phiên sạc đã được khởi tạo thành công.' AS Message;
        RETURN 0;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- ========================================
-- sp_EndChargingSession
-- Completes a session, calculates cost, and frees the charging point.
-- ========================================
CREATE OR ALTER PROCEDURE Operations.sp_EndChargingSession
    @SessionID BIGINT,
    @Total_kWh DECIMAL(13,4)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @PointID       INT,
            @PolicyID      INT,
            @BasePrice     DECIMAL(19,4),
            @Multiplier    DECIMAL(3,2),
            @CalculatedCost MONEY,
            @UserID        INT;

    SELECT @PointID = PointID, @PolicyID = PolicyID, @UserID = UserID
    FROM Operations.ChargingSession
    WHERE SessionID = @SessionID AND Status = N'Đang sạc';

    IF @PointID IS NULL
    BEGIN
        RAISERROR(N'Phiên sạc không tồn tại hoặc đã kết thúc.', 16, 1);
        RETURN -1;
    END;

    SELECT @BasePrice = BasePrice_kWh, @Multiplier = PeakHourMultiplier
    FROM Operations.PricingPolicy
    WHERE PolicyID = @PolicyID;

    IF @BasePrice IS NULL OR @Multiplier IS NULL
    BEGIN
        RAISERROR(N'Chính sách giá không còn hiệu lực hoặc đã bị xóa.', 16, 1);
        RETURN -2;
    END;

    SET @CalculatedCost = Operations.fn_CalculateChargingCost(@Total_kWh, @BasePrice, @Multiplier);

    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE Operations.ChargingSession
        SET EndTime = SYSDATETIME(),
            Total_kWh = @Total_kWh,
            CostTotal = @CalculatedCost,
            Status = N'Đã sạc xong'
        WHERE SessionID = @SessionID;
        -- Point status update is handled by trg_ChargingPoint_AutoUpdateStatus

        COMMIT TRANSACTION;

        SELECT @SessionID AS SessionID, @Total_kWh AS Total_kWh, @CalculatedCost AS CostTotal,
               N'Phiên sạc đã kết thúc thành công.' AS Message;
        RETURN 0;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- ========================================
-- sp_CreateTransaction
-- Records payment and deducts from customer wallet.
-- ========================================
CREATE OR ALTER PROCEDURE Operations.sp_CreateTransaction
    @UserID          INT,
    @SessionID       BIGINT,
    @Amount          MONEY,
    @TransactionType NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Operations.ChargingSession WHERE SessionID = @SessionID AND Status = N'Đã sạc xong')
    BEGIN
        RAISERROR(N'Phiên sạc chưa kết thúc hoặc không tồn tại.', 16, 1);
        RETURN -1;
    END;

    IF NOT EXISTS (SELECT 1 FROM Users.Customers WHERE UserID = @UserID AND AccountStatus = N'Đang mở')
    BEGIN
        RAISERROR(N'Tài khoản khách hàng không hợp lệ.', 16, 1);
        RETURN -2;
    END;

    IF @Amount <> (SELECT CostTotal FROM Operations.ChargingSession WHERE SessionID = @SessionID)
    BEGIN
        RAISERROR(N'Số tiền không khớp với chi phí phiên sạc.', 16, 1);
        RETURN -3;
    END;

    IF (SELECT WalletBalance FROM Users.Customers WHERE UserID = @UserID) < @Amount
    BEGIN
        RAISERROR(N'Số dư ví không đủ để thực hiện giao dịch.', 16, 1);
        RETURN -4;
    END;

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO Operations.Transactions (UserID, SessionID, Amount, TransactionType, [Timestamp])
        VALUES (@UserID, @SessionID, @Amount, @TransactionType, SYSDATETIME());

        UPDATE Users.Customers
        SET WalletBalance = WalletBalance - @Amount
        WHERE UserID = @UserID;

        COMMIT TRANSACTION;

        SELECT SCOPE_IDENTITY() AS TransactionID, N'Giao dịch đã được tạo thành công.' AS Message;
        RETURN 0;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- ========================================
-- sp_GetMonthlyRevenue
-- Aggregates total revenue by month for a given year.
-- ========================================
CREATE OR ALTER PROCEDURE Reports.sp_GetMonthlyRevenue
    @Year INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Year IS NULL SET @Year = YEAR(SYSDATETIME());

    SELECT
        YEAR(t.[Timestamp])   AS RevenueYear,
        MONTH(t.[Timestamp])  AS RevenueMonth,
        RIGHT(N'0' + CAST(MONTH(t.[Timestamp]) AS NVARCHAR(2)), 2)
            + N'-' + CAST(YEAR(t.[Timestamp]) AS NVARCHAR(4)) AS MonthLabel,
        COUNT(DISTINCT t.TransactionID)   AS TransactionCount,
        SUM(t.Amount)                     AS TotalRevenue,
        AVG(t.Amount)                     AS AverageTransactionValue
    FROM Operations.Transactions t
    WHERE YEAR(t.[Timestamp]) = @Year
    GROUP BY YEAR(t.[Timestamp]), MONTH(t.[Timestamp])
    ORDER BY RevenueYear, RevenueMonth;
END;
GO

-- ========================================
-- sp_GetTopStations
-- Returns top stations by revenue or session count.
-- ========================================
CREATE OR ALTER PROCEDURE Reports.sp_GetTopStations
    @TopCount INT = 10,
    @OrderBy  NVARCHAR(20) = N'Doanh thu'
AS
BEGIN
    SET NOCOUNT ON;

    IF LOWER(@OrderBy) = LOWER(N'Doanh thu')
    BEGIN
        SELECT TOP (@TopCount)
            s.StationID, s.StationName, f.FranchiseeName,
            COUNT(ses.SessionID)          AS TotalSessions,
            ISNULL(SUM(ses.CostTotal), 0) AS TotalRevenue,
            AVG(ses.Total_kWh)            AS Avg_kWh_PerSession
        FROM Infrastructure.ChargingStation s
        JOIN Infrastructure.Franchisee f ON s.FranchiseeID = f.FranchiseeID
        LEFT JOIN Infrastructure.ChargingPoint p ON s.StationID = p.StationID
        LEFT JOIN Operations.ChargingSession ses ON p.PointID = ses.PointID AND ses.Status = N'Đã sạc xong'
        GROUP BY s.StationID, s.StationName, f.FranchiseeName
        ORDER BY TotalRevenue DESC;
    END
    ELSE
    BEGIN
        SELECT TOP (@TopCount)
            s.StationID, s.StationName, f.FranchiseeName,
            COUNT(ses.SessionID)          AS TotalSessions,
            ISNULL(SUM(ses.CostTotal), 0) AS TotalRevenue,
            AVG(ses.Total_kWh)            AS Avg_kWh_PerSession
        FROM Infrastructure.ChargingStation s
        JOIN Infrastructure.Franchisee f ON s.FranchiseeID = f.FranchiseeID
        LEFT JOIN Infrastructure.ChargingPoint p ON s.StationID = p.StationID
        LEFT JOIN Operations.ChargingSession ses ON p.PointID = ses.PointID AND ses.Status = N'Đã sạc xong'
        GROUP BY s.StationID, s.StationName, f.FranchiseeName
        ORDER BY TotalSessions DESC;
    END;
END;
GO

PRINT N'Stored procedures created successfully.';
GO
