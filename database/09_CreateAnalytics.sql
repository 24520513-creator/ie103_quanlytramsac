USE EV_Charging_System;
GO

-- ============================================================
-- Indexed Views for Performance Analytics
-- ============================================================

-- vw_DailyStationUsage: Daily usage summary per station
CREATE OR ALTER VIEW Reporting.vw_DailyStationUsage WITH SCHEMABINDING
AS
SELECT
    s.StationID, s.StationCode, s.StationName,
    CAST(cs.StartTime AS DATE) AS UsageDate,
    COUNT_BIG(*) AS TotalSessions,
    COUNT_BIG(CASE WHEN cs.SessionStatus = 'Completed' THEN 1 END) AS CompletedSessions,
    ISNULL(SUM(cs.TotalKWh), 0) AS TotalKWh,
    ISNULL(SUM(cs.CostTotal), 0) AS TotalRevenue,
    ISNULL(AVG(cs.ChargingDurationMinutes), 0) AS AvgDurationMinutes,
    ISNULL(AVG(cs.TotalKWh), 0) AS AvgKWhPerSession
FROM [Operations].[ChargingSession] cs
JOIN [Infrastructure].[ChargingStation] s ON cs.StationID = s.StationID
WHERE cs.StartTime >= DATEADD(YEAR, -1, SYSDATETIME())
GROUP BY s.StationID, s.StationCode, s.StationName, CAST(cs.StartTime AS DATE);
GO

-- vw_RevenueByFranchise: Revenue breakdown by franchise/month
CREATE OR ALTER VIEW Reporting.vw_RevenueByFranchise WITH SCHEMABINDING
AS
SELECT
    f.FranchiseID, f.FranchiseCode, f.FranchiseName,
    YEAR(cs.StartTime) AS Year, MONTH(cs.StartTime) AS Month,
    COUNT_BIG(*) AS TotalSessions,
    ISNULL(SUM(cs.TotalKWh), 0) AS TotalKWh,
    ISNULL(SUM(cs.CostTotal), 0) AS TotalRevenue,
    COUNT_BIG(DISTINCT cs.UserID) AS UniqueCustomers
FROM [Operations].[ChargingSession] cs
JOIN [Infrastructure].[ChargingStation] s ON cs.StationID = s.StationID
JOIN [Infrastructure].[Franchise] f ON s.FranchiseID = f.FranchiseID
WHERE cs.SessionStatus = 'Completed'
GROUP BY f.FranchiseID, f.FranchiseCode, f.FranchiseName, YEAR(cs.StartTime), MONTH(cs.StartTime);
GO

-- vw_PointPerformance: Charging point performance metrics
CREATE OR ALTER VIEW Reporting.vw_PointPerformance WITH SCHEMABINDING
AS
SELECT
    p.PointID, p.PointCode, p.PowerKW, p.ConnectorType, p.PointStatus,
    s.StationID, s.StationCode, s.StationName,
    COUNT_BIG(cs.SessionID) AS TotalSessions,
    ISNULL(SUM(cs.TotalKWh), 0) AS TotalKWh,
    ISNULL(SUM(cs.CostTotal), 0) AS TotalRevenue,
    ISNULL(AVG(cs.ChargingDurationMinutes), 0) AS AvgDurationMinutes,
    MAX(cs.StartTime) AS LastSessionAt
FROM [Infrastructure].[ChargingPoint] p
JOIN [Infrastructure].[ChargingStation] s ON p.StationID = s.StationID
LEFT JOIN [Operations].[ChargingSession] cs ON p.PointID = cs.PointID AND cs.SessionStatus = 'Completed'
GROUP BY p.PointID, p.PointCode, p.PowerKW, p.ConnectorType, p.PointStatus,
         s.StationID, s.StationCode, s.StationName;
GO

PRINT N'Indexed analytics views created.';
GO

-- ============================================================
-- Analytics Stored Procedures
-- ============================================================

-- sp_GetStationUtilization: Utilization metrics per station
CREATE OR ALTER PROCEDURE Reporting.sp_GetStationUtilization
    @FranchiseID INT = NULL,
    @Days INT = 30,
    @Top INT = 20
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (@Top)
        s.StationID, s.StationCode, s.StationName,
        COUNT(cs.SessionID) AS TotalSessions,
        ISNULL(SUM(cs.TotalKWh), 0) AS TotalKWh,
        ISNULL(SUM(cs.CostTotal), 0) AS TotalRevenue,
        ISNULL(AVG(cs.ChargingDurationMinutes), 0) AS AvgDurationMinutes,
        DATEDIFF(HOUR, MIN(cs.StartTime), MAX(cs.StartTime)) AS ActiveWindowHours,
        COUNT(DISTINCT CAST(cs.StartTime AS DATE)) AS ActiveDays,
        COUNT(DISTINCT cs.UserID) AS UniqueUsers,
        (SELECT COUNT(*) FROM [Infrastructure].[ChargingPoint]
         WHERE StationID = s.StationID AND IsActive = 1) AS TotalPoints,
        (SELECT COUNT(*) FROM [Infrastructure].[ChargingPoint]
         WHERE StationID = s.StationID AND PointStatus = 'Available' AND IsActive = 1) AS AvailablePoints
    FROM [Operations].[ChargingSession] cs
    JOIN [Infrastructure].[ChargingStation] s ON cs.StationID = s.StationID
    WHERE cs.StartTime >= DATEADD(DAY, -@Days, SYSDATETIME())
      AND cs.SessionStatus = 'Completed'
      AND (@FranchiseID IS NULL OR s.FranchiseID = @FranchiseID)
    GROUP BY s.StationID, s.StationCode, s.StationName
    ORDER BY TotalRevenue DESC;
END;
GO

-- sp_GetPeakUsageTimes: Peak hour analysis
CREATE OR ALTER PROCEDURE Reporting.sp_GetPeakUsageTimes
    @StationID INT = NULL,
    @Days INT = 30
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        DATEPART(HOUR, cs.StartTime) AS HourOfDay,
        COUNT(*) AS SessionCount,
        ISNULL(SUM(cs.TotalKWh), 0) AS TotalKWh,
        ISNULL(SUM(cs.CostTotal), 0) AS TotalRevenue
    FROM [Operations].[ChargingSession] cs
    WHERE cs.StartTime >= DATEADD(DAY, -@Days, SYSDATETIME())
      AND cs.SessionStatus = 'Completed'
      AND (@StationID IS NULL OR cs.StationID = @StationID)
    GROUP BY DATEPART(HOUR, cs.StartTime)
    ORDER BY HourOfDay;

    SELECT
        DATENAME(WEEKDAY, cs.StartTime) AS Weekday,
        DATEPART(WEEKDAY, cs.StartTime) AS WeekdayNum,
        COUNT(*) AS SessionCount,
        ISNULL(SUM(cs.TotalKWh), 0) AS TotalKWh
    FROM [Operations].[ChargingSession] cs
    WHERE cs.StartTime >= DATEADD(DAY, -@Days, SYSDATETIME())
      AND cs.SessionStatus = 'Completed'
      AND (@StationID IS NULL OR cs.StationID = @StationID)
    GROUP BY DATENAME(WEEKDAY, cs.StartTime), DATEPART(WEEKDAY, cs.StartTime)
    ORDER BY WeekdayNum;
END;
GO

-- sp_GetCustomerAnalytics: Customer behavior analysis
CREATE OR ALTER PROCEDURE Reporting.sp_GetCustomerAnalytics
    @Days INT = 90,
    @Top INT = 20
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (@Top)
        u.UserID, u.Username, u.FullName, u.Email,
        COUNT(cs.SessionID) AS TotalSessions,
        ISNULL(SUM(cs.TotalKWh), 0) AS TotalKWh,
        ISNULL(SUM(cs.CostTotal), 0) AS TotalSpend,
        ISNULL(AVG(cs.ChargingDurationMinutes), 0) AS AvgDurationMinutes,
        MAX(cs.StartTime) AS LastSessionAt,
        DATEDIFF(DAY, MAX(cs.StartTime), SYSDATETIME()) AS DaysSinceLastSession,
        COUNT(DISTINCT cs.StationID) AS UniqueStationsUsed
    FROM [Users].[User] u
    JOIN [Operations].[ChargingSession] cs ON u.UserID = cs.UserID
    WHERE u.Role = 'Customer'
      AND cs.StartTime >= DATEADD(DAY, -@Days, SYSDATETIME())
      AND cs.SessionStatus = 'Completed'
    GROUP BY u.UserID, u.Username, u.FullName, u.Email
    ORDER BY TotalSpend DESC;

    -- At-risk customers (no session in last 30 days, previously active)
    SELECT
        u.UserID, u.Username, u.FullName, u.Email,
        COUNT(cs.SessionID) AS HistoricalSessions,
        MAX(cs.StartTime) AS LastSessionAt,
        DATEDIFF(DAY, MAX(cs.StartTime), SYSDATETIME()) AS DaysSinceLastSession
    FROM [Users].[User] u
    JOIN [Operations].[ChargingSession] cs ON u.UserID = cs.UserID
    WHERE u.Role = 'Customer' AND cs.SessionStatus = 'Completed'
    GROUP BY u.UserID, u.Username, u.FullName, u.Email
    HAVING MAX(cs.StartTime) < DATEADD(DAY, -30, SYSDATETIME())
       AND COUNT(cs.SessionID) >= 3
    ORDER BY DaysSinceLastSession DESC;
END;
GO

-- sp_GetRevenueForecast: Simple revenue forecast
CREATE OR ALTER PROCEDURE Reporting.sp_GetRevenueForecast
    @Months INT = 3
AS
BEGIN
    SET NOCOUNT ON;

    -- Monthly revenue trend with moving average
    SELECT
        YEAR(cs.StartTime) AS Year,
        MONTH(cs.StartTime) AS Month,
        COUNT(*) AS SessionCount,
        ISNULL(SUM(cs.CostTotal), 0) AS MonthlyRevenue
    FROM [Operations].[ChargingSession] cs
    WHERE cs.SessionStatus = 'Completed'
      AND cs.StartTime >= DATEADD(MONTH, -@Months, SYSDATETIME())
    GROUP BY YEAR(cs.StartTime), MONTH(cs.StartTime)
    ORDER BY Year DESC, Month DESC;
END;
GO

-- sp_GetTopUsersByRevenue: Top spending customers
CREATE OR ALTER PROCEDURE Reporting.sp_GetTopUsersByRevenue
    @Top INT = 10,
    @Days INT = 90
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (@Top)
        u.UserID, u.Username, u.FullName, u.Email,
        COUNT(cs.SessionID) AS Sessions,
        ISNULL(SUM(cs.CostTotal), 0) AS TotalSpend,
        ISNULL(SUM(cs.TotalKWh), 0) AS TotalKWh,
        AVG(cs.CostTotal) AS AvgSpendPerSession
    FROM [Users].[User] u
    JOIN [Operations].[ChargingSession] cs ON u.UserID = cs.UserID
    WHERE cs.SessionStatus = 'Completed'
      AND cs.StartTime >= DATEADD(DAY, -@Days, SYSDATETIME())
    GROUP BY u.UserID, u.Username, u.FullName, u.Email
    ORDER BY TotalSpend DESC;
END;
GO

-- sp_GetSystemHealthSummary: Overall system health
CREATE OR ALTER PROCEDURE Reporting.sp_GetSystemHealthSummary
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        (SELECT COUNT(*) FROM [Infrastructure].[ChargingStation] WHERE IsActive = 1) AS TotalStations,
        (SELECT COUNT(*) FROM [Infrastructure].[ChargingStation] WHERE StationStatus = 'Active' AND IsActive = 1) AS ActiveStations,
        (SELECT COUNT(*) FROM [Infrastructure].[ChargingPoint] WHERE IsActive = 1) AS TotalPoints,
        (SELECT COUNT(*) FROM [Infrastructure].[ChargingPoint] WHERE PointStatus = 'Available' AND IsActive = 1) AS AvailablePoints,
        (SELECT COUNT(*) FROM [Infrastructure].[ChargingPoint] WHERE PointStatus = 'Busy' AND IsActive = 1) AS BusyPoints,
        (SELECT COUNT(*) FROM [Infrastructure].[ChargingPoint] WHERE PointStatus = 'Offline' AND IsActive = 1) AS OfflinePoints,
        (SELECT COUNT(*) FROM [Infrastructure].[ChargingPoint] WHERE PointStatus = 'Maintenance' AND IsActive = 1) AS MaintenancePoints,
        (SELECT COUNT(*) FROM [Operations].[ChargingSession] WHERE SessionStatus = 'Charging') AS ActiveSessions,
        (SELECT COUNT(*) FROM [Operations].[ChargingSession] WHERE SessionStatus = 'Completed' AND StartTime >= DATEADD(DAY, -1, SYSDATETIME())) AS SessionsLast24h,
        (SELECT COUNT(*) FROM [Infrastructure].[ErrorLog] WHERE IsActive = 1 AND ResolvedAt IS NULL) AS UnresolvedErrors,
        (SELECT COUNT(*) FROM [Operations].[MaintenanceSchedule] WHERE Status IN ('Scheduled', 'InProgress')) AS PendingMaintenance,
        (SELECT COUNT(*) FROM [Users].[Notification] WHERE IsRead = 0) AS UnreadNotifications;
END;
GO

-- sp_GetFranchiseComparison: Cross-franchise metrics
CREATE OR ALTER PROCEDURE Reporting.sp_GetFranchiseComparison
    @Days INT = 30
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        f.FranchiseID, f.FranchiseCode, f.FranchiseName,
        COUNT(DISTINCT s.StationID) AS StationCount,
        COUNT(DISTINCT cs.SessionID) AS TotalSessions,
        ISNULL(SUM(cs.TotalKWh), 0) AS TotalKWh,
        ISNULL(SUM(cs.CostTotal), 0) AS TotalRevenue,
        ISNULL(AVG(cs.ChargingDurationMinutes), 0) AS AvgDurationMinutes,
        COUNT(DISTINCT cs.UserID) AS UniqueCustomers,
        ISNULL(SUM(cs.TotalKWh), 0) / NULLIF(COUNT(DISTINCT s.StationID), 0) AS KWhPerStation
    FROM [Infrastructure].[Franchise] f
    LEFT JOIN [Infrastructure].[ChargingStation] s ON f.FranchiseID = s.FranchiseID AND s.IsActive = 1
    LEFT JOIN [Operations].[ChargingSession] cs ON s.StationID = cs.StationID
        AND cs.SessionStatus = 'Completed'
        AND cs.StartTime >= DATEADD(DAY, -@Days, SYSDATETIME())
    GROUP BY f.FranchiseID, f.FranchiseCode, f.FranchiseName
    ORDER BY TotalRevenue DESC;
END;
GO

-- sp_GetErrorAnalytics: Error trend analysis
CREATE OR ALTER PROCEDURE Reporting.sp_GetErrorAnalytics
    @Days INT = 30
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        CAST(OccurredAt AS DATE) AS ErrorDate,
        Severity,
        COUNT(*) AS ErrorCount
    FROM [Infrastructure].[ErrorLog]
    WHERE OccurredAt >= DATEADD(DAY, -@Days, SYSDATETIME())
    GROUP BY CAST(OccurredAt AS DATE), Severity
    ORDER BY ErrorDate DESC;

    SELECT
        Severity,
        COUNT(*) AS TotalErrors,
        COUNT(CASE WHEN ResolvedAt IS NOT NULL THEN 1 END) AS ResolvedErrors,
        AVG(DATEDIFF(HOUR, OccurredAt, ISNULL(ResolvedAt, SYSDATETIME()))) AS AvgResolutionHours
    FROM [Infrastructure].[ErrorLog]
    WHERE OccurredAt >= DATEADD(DAY, -@Days, SYSDATETIME())
    GROUP BY Severity;
END;
GO

PRINT N'Analytics stored procedures created.';
GO
