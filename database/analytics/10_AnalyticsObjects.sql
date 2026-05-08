/*==============================================================================
  EV_Charging_System - ANALYTICS & BI OBJECTS
  ==============================================================================
  Components:  Analytics views | ETL procedures | KPI calculations | BI helpers
  =============================================================================*/

USE EV_Charging_System;
GO

-- ===========================================================================
-- 1. ANALYTICS VIEWS
-- ===========================================================================
-- Keep these as regular views so the script runs consistently in SSMS/dev
-- environments without indexed-view restrictions.

-- ---------------------------------------------------------------------------
-- ivw_MonthlyRevenueSummary - Pre-aggregated monthly revenue
-- ---------------------------------------------------------------------------
CREATE OR ALTER VIEW Analytics.ivw_MonthlyRevenueSummary
AS
SELECT
    YEAR(cs.StartTime)                                      AS RevenueYear,
    MONTH(cs.StartTime)                                     AS RevenueMonth,
    cs.StationID,
    COUNT(DISTINCT cs.SessionID)                            AS SessionCount,
    COUNT(DISTINCT cs.UserID)                               AS UniqueUserCount,
    ISNULL(SUM(cs.TotalKWh), 0)                             AS TotalKWh,
    ISNULL(SUM(cs.CostTotal), 0)                            AS TotalRevenue,
    ISNULL(SUM(cs.ChargingDurationMinutes), 0)              AS TotalMinutes
FROM Operations.ChargingSession cs
WHERE cs.SessionStatus = N'Completed' AND cs.IsDeleted = 0
GROUP BY YEAR(cs.StartTime), MONTH(cs.StartTime), cs.StationID;
GO

-- ---------------------------------------------------------------------------
-- ivw_DailyStationAvailability - Daily availability snapshot
-- ---------------------------------------------------------------------------
CREATE OR ALTER VIEW Analytics.ivw_DailyStationAvailability
AS
SELECT
    s.StationID,
    COUNT(DISTINCT p.PointID)                               AS TotalPoints,
    SUM(CASE WHEN p.PointStatus = N'Available' THEN 1 ELSE 0 END) AS AvailableCount,
    SUM(CASE WHEN p.PointStatus = N'Busy' THEN 1 ELSE 0 END)     AS BusyCount,
    SUM(CASE WHEN p.PointStatus IN (N'Error', N'Offline', N'Maintenance') THEN 1 ELSE 0 END) AS FaultCount,
    COUNT(DISTINCT cs.SessionID)                            AS DailySessionCount
FROM Infrastructure.ChargingStation s
JOIN Infrastructure.ChargingPoint p ON s.StationID = p.StationID AND p.IsDeleted = 0
LEFT JOIN Operations.ChargingSession cs ON s.StationID = cs.StationID
    AND CAST(cs.StartTime AS DATE) = CAST(SYSDATETIME() AS DATE)
    AND cs.IsDeleted = 0
WHERE s.IsDeleted = 0
GROUP BY s.StationID;
GO

-- ===========================================================================
-- 2. KPI EXTRACTION PROCEDURES
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- sp_CalculateStationKPIs - Calculate real-time KPI for a station
-- ---------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Analytics.sp_CalculateStationKPIs
    @StationID INT,
    @FromDate  DATE = NULL,
    @ToDate    DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @FromDate IS NULL SET @FromDate = DATEADD(DAY, -30, SYSDATETIME());
    IF @ToDate IS NULL SET @ToDate = CAST(SYSDATETIME() AS DATE);

    SELECT
        @StationID                                          AS StationID,
        COUNT(DISTINCT cs.SessionID)                        AS TotalSessions,
        COUNT(DISTINCT cs.UserID)                           AS UniqueUsers,
        ISNULL(SUM(cs.TotalKWh), 0)                         AS TotalKWh,
        ISNULL(SUM(cs.CostTotal), 0)                        AS TotalRevenue,
        ISNULL(AVG(cs.TotalKWh), 0)                         AS AvgKWhPerSession,
        ISNULL(AVG(cs.CostTotal), 0)                        AS AvgRevenuePerSession,
        ISNULL(AVG(cs.ChargingDurationMinutes), 0)          AS AvgDurationMinutes,
        ISNULL(AVG(cs.AveragePowerKW), 0)                   AS AvgPowerKW,
        ISNULL(SUM(cs.ChargingDurationMinutes), 0)          AS TotalChargingMinutes,
        CASE WHEN COUNT(DISTINCT cs.SessionID) > 0
             THEN ISNULL(SUM(cs.CostTotal), 0) / NULLIF(SUM(cs.TotalKWh), 0) ELSE 0 END AS RevenuePerKWh,
        CASE WHEN DATEDIFF(DAY, @FromDate, @ToDate) > 0
             THEN CAST(COUNT(DISTINCT cs.SessionID) AS DECIMAL(10,2))
                  / DATEDIFF(DAY, @FromDate, @ToDate) ELSE 0 END AS SessionsPerDay,
        Reporting.fn_GetStationUtilizationRate(@StationID, @FromDate, @ToDate) AS UtilizationPercent
    FROM Operations.ChargingSession cs
    WHERE cs.StationID = @StationID
      AND cs.SessionStatus = N'Completed'
      AND cs.StartTime >= @FromDate
      AND cs.StartTime < DATEADD(DAY, 1, @ToDate)
      AND cs.IsDeleted = 0;
END;
GO

-- ---------------------------------------------------------------------------
-- sp_CalculateRevenueAnalytics - Revenue breakdown analytics
-- ---------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Analytics.sp_CalculateRevenueAnalytics
    @Year INT = NULL,
    @FranchiseID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Year IS NULL SET @Year = YEAR(SYSDATETIME());

    -- Revenue by hour (peak hour analysis)
    SELECT
        DATEPART(HOUR, cs.StartTime) AS HourOfDay,
        COUNT(DISTINCT cs.SessionID) AS SessionCount,
        ISNULL(SUM(cs.TotalKWh), 0) AS TotalKWh,
        ISNULL(SUM(cs.CostTotal), 0) AS TotalRevenue
    FROM Operations.ChargingSession cs
    JOIN Infrastructure.ChargingStation s ON cs.StationID = s.StationID
    WHERE YEAR(cs.StartTime) = @Year
      AND cs.SessionStatus = N'Completed'
      AND cs.IsDeleted = 0
      AND (@FranchiseID IS NULL OR s.FranchiseID = @FranchiseID)
    GROUP BY DATEPART(HOUR, cs.StartTime)
    ORDER BY HourOfDay;

    -- Revenue by connector type
    SELECT
        p.ConnectorType,
        COUNT(DISTINCT cs.SessionID) AS SessionCount,
        ISNULL(SUM(cs.TotalKWh), 0) AS TotalKWh,
        ISNULL(SUM(cs.CostTotal), 0) AS TotalRevenue,
        AVG(cs.AveragePowerKW) AS AvgPowerKW
    FROM Operations.ChargingSession cs
    JOIN Infrastructure.ChargingPoint p ON cs.PointID = p.PointID
    JOIN Infrastructure.ChargingStation s ON cs.StationID = s.StationID
    WHERE YEAR(cs.StartTime) = @Year
      AND cs.SessionStatus = N'Completed'
      AND cs.IsDeleted = 0
      AND (@FranchiseID IS NULL OR s.FranchiseID = @FranchiseID)
    GROUP BY p.ConnectorType;

    -- Revenue by day of week
    SELECT
        DATENAME(WEEKDAY, cs.StartTime) AS DayOfWeek,
        DATEPART(WEEKDAY, cs.StartTime) AS DayNumber,
        COUNT(DISTINCT cs.SessionID) AS SessionCount,
        ISNULL(SUM(cs.TotalKWh), 0) AS TotalKWh,
        ISNULL(SUM(cs.CostTotal), 0) AS TotalRevenue
    FROM Operations.ChargingSession cs
    JOIN Infrastructure.ChargingStation s ON cs.StationID = s.StationID
    WHERE YEAR(cs.StartTime) = @Year
      AND cs.SessionStatus = N'Completed'
      AND cs.IsDeleted = 0
      AND (@FranchiseID IS NULL OR s.FranchiseID = @FranchiseID)
    GROUP BY DATENAME(WEEKDAY, cs.StartTime), DATEPART(WEEKDAY, cs.StartTime)
    ORDER BY DayNumber;

    -- Top stations by revenue
    SELECT TOP 10
        s.StationID,
        s.StationCode,
        s.StationName,
        f.FranchiseName,
        COUNT(DISTINCT cs.SessionID) AS SessionCount,
        ISNULL(SUM(cs.TotalKWh), 0) AS TotalKWh,
        ISNULL(SUM(cs.CostTotal), 0) AS TotalRevenue,
        ISNULL(AVG(cs.ChargingDurationMinutes), 0) AS AvgDuration
    FROM Operations.ChargingSession cs
    JOIN Infrastructure.ChargingStation s ON cs.StationID = s.StationID
    JOIN Infrastructure.Franchise f ON s.FranchiseID = f.FranchiseID
    WHERE YEAR(cs.StartTime) = @Year
      AND cs.SessionStatus = N'Completed'
      AND cs.IsDeleted = 0
      AND (@FranchiseID IS NULL OR s.FranchiseID = @FranchiseID)
    GROUP BY s.StationID, s.StationCode, s.StationName, f.FranchiseName
    ORDER BY TotalRevenue DESC;

    -- Charging efficiency analytics
    SELECT
        CASE
            WHEN cs.TotalKWh <= 10 THEN N'0-10 kWh'
            WHEN cs.TotalKWh <= 30 THEN N'10-30 kWh'
            WHEN cs.TotalKWh <= 60 THEN N'30-60 kWh'
            ELSE N'60+ kWh'
        END AS EnergyBucket,
        COUNT(DISTINCT cs.SessionID) AS SessionCount,
        ISNULL(AVG(cs.AveragePowerKW), 0) AS AvgPowerKW,
        ISNULL(AVG(cs.ChargingDurationMinutes), 0) AS AvgDurationMinutes,
        ISNULL(AVG(cs.CostTotal), 0) AS AvgCost
    FROM Operations.ChargingSession cs
    JOIN Infrastructure.ChargingStation s ON cs.StationID = s.StationID
    WHERE YEAR(cs.StartTime) = @Year
      AND cs.SessionStatus = N'Completed'
      AND cs.IsDeleted = 0
      AND (@FranchiseID IS NULL OR s.FranchiseID = @FranchiseID)
    GROUP BY CASE
        WHEN cs.TotalKWh <= 10 THEN N'0-10 kWh'
        WHEN cs.TotalKWh <= 30 THEN N'10-30 kWh'
        WHEN cs.TotalKWh <= 60 THEN N'30-60 kWh'
        ELSE N'60+ kWh'
    END;
END;
GO

-- ===========================================================================
-- 3. BI-READY QUERY HELPERS
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- fn_GenerateDateDimension - Date dimension for BI tools
-- ---------------------------------------------------------------------------
CREATE OR ALTER FUNCTION Analytics.fn_GenerateDateDimension
(
    @FromDate DATE,
    @ToDate   DATE
)
RETURNS TABLE
AS
RETURN
    WITH DateSequence AS (
        SELECT @FromDate AS DateValue
        UNION ALL
        SELECT DATEADD(DAY, 1, DateValue)
        FROM DateSequence
        WHERE DateValue < @ToDate
    )
    SELECT
        DateValue,
        YEAR(DateValue)         AS Year,
        MONTH(DateValue)        AS Month,
        DAY(DateValue)          AS Day,
        DATEPART(QUARTER, DateValue) AS Quarter,
        DATENAME(MONTH, DateValue)  AS MonthName,
        DATENAME(WEEKDAY, DateValue) AS DayName,
        DATEPART(WEEKDAY, DateValue) AS DayOfWeek,
        CASE WHEN DATEPART(WEEKDAY, DateValue) IN (1, 7) THEN 1 ELSE 0 END AS IsWeekend,
        CASE WHEN MONTH(DateValue) IN (1, 4, 5, 9) AND DAY(DateValue) IN (1, 30, 1, 2) THEN 1 ELSE 0 END AS IsHoliday
    FROM DateSequence;
GO

PRINT N'Analytics objects created successfully.';
GO
