/*==============================================================================
  EV_Charging_System - ENTERPRISE REPORTING QUERIES
  ==============================================================================
  Categories:  Financial | Operational | Customer | Infrastructure | Compliance
  =============================================================================*/

USE EV_Charging_System;
GO

-- ===========================================================================
-- REPORT 1: Executive Dashboard - Key Metrics Summary
-- ===========================================================================
PRINT N'===== EXECUTIVE DASHBOARD =====';
SELECT
    (SELECT COUNT(DISTINCT StationID) FROM Infrastructure.ChargingStation WHERE IsDeleted = 0) AS TotalStations,
    (SELECT COUNT(DISTINCT PointID) FROM Infrastructure.ChargingPoint WHERE IsDeleted = 0) AS TotalPoints,
    (SELECT COUNT(DISTINCT UserID) FROM Users.[User] WHERE IsDeleted = 0 AND AccountStatus = N'Active') AS ActiveUsers,
    (SELECT COUNT(DISTINCT FranchiseID) FROM Infrastructure.Franchise WHERE IsDeleted = 0) AS TotalFranchises,
    (SELECT ISNULL(SUM(CostTotal), 0) FROM Operations.ChargingSession WHERE SessionStatus = N'Completed' AND IsDeleted = 0 AND StartTime >= DATEADD(MONTH, -1, SYSDATETIME())) AS LastMonthRevenue,
    (SELECT ISNULL(SUM(CostTotal), 0) FROM Operations.ChargingSession WHERE SessionStatus = N'Completed' AND IsDeleted = 0) AS LifetimeRevenue,
    (SELECT ISNULL(SUM(TotalKWh), 0) FROM Operations.ChargingSession WHERE SessionStatus = N'Completed' AND IsDeleted = 0) AS LifetimeKWh,
    (SELECT COUNT(DISTINCT SessionID) FROM Operations.ChargingSession WHERE SessionStatus = N'Completed' AND IsDeleted = 0) AS TotalSessionsCompleted,
    (SELECT COUNT(DISTINCT SessionID) FROM Operations.ChargingSession WHERE SessionStatus = N'Charging') AS ActiveSessionsNow;
GO

-- ===========================================================================
-- REPORT 2: Monthly Revenue by Franchise
-- ===========================================================================
PRINT N'===== MONTHLY REVENUE BY FRANCHISE =====';
SELECT
    FORMAT(cs.StartTime, N'yyyy-MM') AS Month,
    f.FranchiseName,
    COUNT(DISTINCT cs.SessionID) AS TotalSessions,
    COUNT(DISTINCT cs.UserID) AS UniqueCustomers,
    ISNULL(SUM(cs.TotalKWh), 0) AS TotalKWh,
    ISNULL(SUM(cs.CostTotal), 0) AS TotalRevenue,
    ISNULL(SUM(cs.CostTotal * f.RevenueShareRate / 100), 0) AS Commission,
    ISNULL(SUM(cs.CostTotal) - SUM(cs.CostTotal * f.RevenueShareRate / 100), 0) AS NetRevenue
FROM Operations.ChargingSession cs
JOIN Infrastructure.ChargingStation s ON cs.StationID = s.StationID
JOIN Infrastructure.Franchise f ON s.FranchiseID = f.FranchiseID
WHERE cs.SessionStatus = N'Completed'
  AND cs.IsDeleted = 0
  AND cs.StartTime >= DATEADD(MONTH, -12, SYSDATETIME())
GROUP BY FORMAT(cs.StartTime, N'yyyy-MM'), f.FranchiseName
ORDER BY Month DESC, TotalRevenue DESC;
GO

-- ===========================================================================
-- REPORT 3: Station Performance Ranking
-- ===========================================================================
PRINT N'===== TOP 10 STATIONS BY REVENUE =====';
SELECT TOP 10
    s.StationCode,
    s.StationName,
    f.FranchiseName,
    s.StationStatus,
    s.NetworkStatus,
    COUNT(DISTINCT p.PointID) AS TotalPoints,
    COUNT(DISTINCT cs.SessionID) AS TotalSessions,
    ISNULL(SUM(cs.TotalKWh), 0) AS TotalKWh,
    ISNULL(SUM(cs.CostTotal), 0) AS TotalRevenue,
    ISNULL(AVG(cs.CostTotal), 0) AS AvgRevenuePerSession,
    CASE WHEN COUNT(DISTINCT cs.SessionID) > 0
         THEN ISNULL(SUM(cs.CostTotal), 0) / COUNT(DISTINCT cs.SessionID) ELSE 0 END AS RevenuePerSession,
    COUNT(DISTINCT CASE WHEN el.Severity = N'Critical' THEN el.ErrorID END) AS CriticalErrors
FROM Infrastructure.ChargingStation s
JOIN Infrastructure.Franchise f ON s.FranchiseID = f.FranchiseID
LEFT JOIN Infrastructure.ChargingPoint p ON s.StationID = p.StationID AND p.IsDeleted = 0
LEFT JOIN Operations.ChargingSession cs ON s.StationID = cs.StationID
    AND cs.SessionStatus = N'Completed' AND cs.IsDeleted = 0
    AND cs.StartTime >= DATEADD(MONTH, -3, SYSDATETIME())
LEFT JOIN Monitoring.ErrorLog el ON s.StationID = el.StationID
WHERE s.IsDeleted = 0
GROUP BY s.StationCode, s.StationName, f.FranchiseName, s.StationStatus, s.NetworkStatus
ORDER BY TotalRevenue DESC;
GO

-- ===========================================================================
-- REPORT 4: Peak Hour Analysis
-- ===========================================================================
PRINT N'===== PEAK HOUR ANALYSIS (LAST 6 MONTHS) =====';
SELECT
    DATEPART(HOUR, StartTime) AS HourOfDay,
    COUNT(SessionID) AS SessionCount,
    ISNULL(SUM(TotalKWh), 0) AS TotalKWh,
    ISNULL(SUM(CostTotal), 0) AS TotalRevenue,
    ISNULL(AVG(TotalKWh), 0) AS AvgKWh,
    ISNULL(AVG(ChargingDurationMinutes), 0) AS AvgDurationMinutes,
    ISNULL(AVG(AveragePowerKW), 0) AS AvgPowerKW,
    COUNT(DISTINCT UserID) AS UniqueUsers
FROM Operations.ChargingSession
WHERE SessionStatus = N'Completed'
  AND IsDeleted = 0
  AND StartTime >= DATEADD(MONTH, -6, SYSDATETIME())
GROUP BY DATEPART(HOUR, StartTime)
ORDER BY HourOfDay;
GO

-- ===========================================================================
-- REPORT 5: Customer Segmentation (RFM-style)
-- ===========================================================================
PRINT N'===== CUSTOMER SEGMENTATION =====';
WITH CustomerMetrics AS (
    SELECT
        u.UserID,
        up.FullName,
        u.Email,
        COUNT(DISTINCT cs.SessionID) AS Frequency,
        ISNULL(SUM(cs.CostTotal), 0) AS Monetary,
        MAX(cs.StartTime) AS LastPurchase,
        DATEDIFF(DAY, MAX(cs.StartTime), SYSDATETIME()) AS Recency,
        ISNULL(SUM(cs.TotalKWh), 0) AS TotalEnergy
    FROM Users.[User] u
    JOIN Users.UserProfile up ON u.UserID = up.UserID
    LEFT JOIN Operations.ChargingSession cs ON u.UserID = cs.UserID
        AND cs.SessionStatus = N'Completed' AND cs.IsDeleted = 0
    WHERE u.IsDeleted = 0
    GROUP BY u.UserID, up.FullName, u.Email
)
SELECT
    FullName,
    Email,
    Frequency,
    Monetary,
    Recency,
    TotalEnergy,
    CASE
        WHEN Recency <= 30 AND Frequency >= 10 THEN N'VIP'
        WHEN Recency <= 30 AND Frequency >= 5 THEN N'Active'
        WHEN Recency <= 90 THEN N'Occasional'
        WHEN Recency <= 180 THEN N'At Risk'
        ELSE N'Churned'
    END AS Segment
FROM CustomerMetrics
ORDER BY Monetary DESC;
GO

-- ===========================================================================
-- REPORT 6: Charging Efficiency Analysis
-- ===========================================================================
PRINT N'===== CHARGING EFFICIENCY =====';
SELECT
    p.ConnectorType,
    COUNT(DISTINCT cs.SessionID) AS SessionCount,
    ISNULL(AVG(cs.AveragePowerKW), 0) AS AvgPowerKW,
    ISNULL(AVG(cs.ChargingDurationMinutes), 0) AS AvgDurationMinutes,
    ISNULL(AVG(cs.TotalKWh), 0) AS AvgEnergyDelivered,
    ISNULL(SUM(cs.TotalKWh), 0) AS TotalEnergy,
    ISNULL(AVG(cs.TotalKWh / NULLIF(cs.ChargingDurationMinutes, 0) * 60), 0) AS AvgEffectivePowerKW,
    ISNULL(AVG(cs.StartBatteryPercent), 0) AS AvgStartPercent,
    ISNULL(AVG(cs.EndBatteryPercent), 0) AS AvgEndPercent,
    ISNULL(AVG(cs.EndBatteryPercent - cs.StartBatteryPercent), 0) AS AvgChargePercent
FROM Operations.ChargingSession cs
JOIN Infrastructure.ChargingPoint p ON cs.PointID = p.PointID
WHERE cs.SessionStatus = N'Completed'
  AND cs.IsDeleted = 0
  AND cs.StartTime >= DATEADD(MONTH, -6, SYSDATETIME())
GROUP BY p.ConnectorType
ORDER BY AvgPowerKW DESC;
GO

-- ===========================================================================
-- REPORT 7: Station Availability / Uptime Report
-- ===========================================================================
PRINT N'===== STATION AVAILABILITY REPORT =====';
SELECT
    s.StationCode,
    s.StationName,
    s.StationStatus,
    s.NetworkStatus,
    COUNT(DISTINCT p.PointID) AS TotalPoints,
    SUM(CASE WHEN p.PointStatus = N'Available' THEN 1 ELSE 0 END) AS Available,
    SUM(CASE WHEN p.PointStatus = N'Busy' THEN 1 ELSE 0 END) AS Busy,
    SUM(CASE WHEN p.PointStatus = N'Error' THEN 1 ELSE 0 END) AS Error,
    SUM(CASE WHEN p.PointStatus = N'Offline' THEN 1 ELSE 0 END) AS Offline,
    SUM(CASE WHEN p.PointStatus = N'Maintenance' THEN 1 ELSE 0 END) AS Maintenance,
    CASE WHEN COUNT(DISTINCT p.PointID) > 0
         THEN CAST(SUM(CASE WHEN p.PointStatus = N'Available' THEN 1 ELSE 0 END) * 100
              / COUNT(DISTINCT p.PointID) AS DECIMAL(5,2)) ELSE 0 END AS AvailabilityPct
FROM Infrastructure.ChargingStation s
LEFT JOIN Infrastructure.ChargingPoint p ON s.StationID = p.StationID AND p.IsDeleted = 0
WHERE s.IsDeleted = 0
GROUP BY s.StationCode, s.StationName, s.StationStatus, s.NetworkStatus
ORDER BY AvailabilityPct ASC;
GO

-- ===========================================================================
-- REPORT 8: Error Trend Analysis
-- ===========================================================================
PRINT N'===== ERROR TREND ANALYSIS =====';
SELECT
    CAST(OccurredAt AS DATE) AS ErrorDate,
    ErrorCategory,
    ErrorCode,
    Severity,
    COUNT(ErrorID) AS ErrorCount,
    COUNT(DISTINCT PointID) AS AffectedPoints,
    COUNT(DISTINCT StationID) AS AffectedStations
FROM Monitoring.ErrorLog
WHERE OccurredAt >= DATEADD(MONTH, -3, SYSDATETIME())
GROUP BY CAST(OccurredAt AS DATE), ErrorCategory, ErrorCode, Severity
ORDER BY ErrorDate DESC, ErrorCount DESC;
GO

-- ===========================================================================
-- REPORT 9: Franchise Commission Report
-- ===========================================================================
PRINT N'===== FRANCHISE COMMISSION REPORT =====';
SELECT
    f.FranchiseCode,
    f.FranchiseName,
    f.FranchiseTier,
    f.RevenueShareRate,
    COUNT(DISTINCT s.StationID) AS Stations,
    COUNT(DISTINCT cs.SessionID) AS TotalSessions,
    ISNULL(SUM(cs.TotalKWh), 0) AS TotalKWh,
    ISNULL(SUM(cs.CostTotal), 0) AS GrossRevenue,
    ISNULL(SUM(cs.CostTotal * f.RevenueShareRate / 100), 0) AS Commission,
    ISNULL(SUM(cs.CostTotal) - SUM(cs.CostTotal * f.RevenueShareRate / 100), 0) AS PlatformRevenue,
    AVG(cs.CostTotal) AS AvgRevenuePerSession
FROM Infrastructure.Franchise f
LEFT JOIN Infrastructure.ChargingStation s ON f.FranchiseID = s.FranchiseID AND s.IsDeleted = 0
LEFT JOIN Operations.ChargingSession cs ON s.StationID = cs.StationID
    AND cs.SessionStatus = N'Completed' AND cs.IsDeleted = 0
    AND cs.StartTime >= DATEADD(MONTH, -1, SYSDATETIME())
WHERE f.IsDeleted = 0
GROUP BY f.FranchiseCode, f.FranchiseName, f.FranchiseTier, f.RevenueShareRate
ORDER BY Commission DESC;
GO

-- ===========================================================================
-- REPORT 10: Session Completion Analysis
-- ===========================================================================
PRINT N'===== SESSION COMPLETION ANALYSIS =====';
SELECT
    StopReason,
    COUNT(SessionID) AS SessionCount,
    ISNULL(AVG(TotalKWh), 0) AS AvgKWh,
    ISNULL(AVG(ChargingDurationMinutes), 0) AS AvgDurationMinutes,
    ISNULL(AVG(CostTotal), 0) AS AvgCost,
    ISNULL(SUM(CostTotal), 0) AS TotalRevenue
FROM Operations.ChargingSession
WHERE SessionStatus IN (N'Completed', N'Failed', N'Cancelled', N'Interrupted')
  AND IsDeleted = 0
  AND StartTime >= DATEADD(MONTH, -3, SYSDATETIME())
GROUP BY StopReason
ORDER BY SessionCount DESC;
GO

PRINT N'All enterprise reports executed successfully.';
GO
