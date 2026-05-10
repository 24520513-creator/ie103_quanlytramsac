USE EV_Charging_System;
GO

-- ============================================================
-- vw_ActiveSessions: Real-time active charging sessions
-- ============================================================
CREATE OR ALTER VIEW Reporting.vw_ActiveSessions
AS
SELECT cs.SessionID, cs.SessionCode, cs.UserID, u.FullName AS UserName, u.Username,
       cs.VehicleID, v.PlateNumber,
       cs.PointID, p.PointCode, p.ConnectorType,
       cs.StationID, s.StationName, s.StationCode,
       cs.StartTime, cs.StartBatteryPercent, cs.MeterStart,
       DATEDIFF(MINUTE, cs.StartTime, SYSDATETIME()) AS DurationMinutes,
       cs.SessionStatus
FROM Operations.ChargingSession cs
JOIN Users.[User] u ON cs.UserID = u.UserID
JOIN Infrastructure.ChargingStation s ON cs.StationID = s.StationID
JOIN Infrastructure.ChargingPoint p ON cs.PointID = p.PointID
LEFT JOIN Users.Vehicle v ON cs.VehicleID = v.VehicleID
WHERE cs.SessionStatus = 'Charging';
GO

-- ============================================================
-- vw_StationAvailability: Station capacity & availability
-- ============================================================
CREATE OR ALTER VIEW Reporting.vw_StationAvailability
AS
SELECT s.StationID, s.StationCode, s.StationName, s.FranchiseID, s.StationStatus,
       COUNT(p.PointID) AS TotalPoints,
       SUM(CASE WHEN p.PointStatus = 'Available' THEN 1 ELSE 0 END) AS AvailablePoints,
       SUM(CASE WHEN p.PointStatus = 'Busy' THEN 1 ELSE 0 END) AS BusyPoints,
       CASE WHEN COUNT(p.PointID) > 0
           THEN CAST(SUM(CASE WHEN p.PointStatus = 'Available' THEN 1 ELSE 0 END) AS DECIMAL(5,2)) / COUNT(p.PointID) * 100
           ELSE 0
       END AS AvailabilityPct
FROM Infrastructure.ChargingStation s
LEFT JOIN Infrastructure.ChargingPoint p ON s.StationID = p.StationID AND p.IsActive = 1
WHERE s.IsActive = 1
GROUP BY s.StationID, s.StationCode, s.StationName, s.FranchiseID, s.StationStatus;
GO

-- ============================================================
-- vw_CustomerSummary: Per-customer lifetime metrics
-- ============================================================
CREATE OR ALTER VIEW Reporting.vw_CustomerSummary
AS
SELECT u.UserID, u.Username, u.FullName, u.Email, u.Phone, u.CreatedAt AS RegisteredAt,
       COUNT(cs.SessionID) AS TotalSessions,
       ISNULL(SUM(cs.TotalKWh), 0) AS TotalKWh,
       ISNULL(SUM(cs.CostTotal), 0) AS TotalSpent,
       ISNULL(w.Balance, 0) AS WalletBalance,
       COUNT(v.VehicleID) AS TotalVehicles
FROM Users.[User] u
LEFT JOIN Operations.ChargingSession cs ON u.UserID = cs.UserID AND cs.SessionStatus = 'Completed'
LEFT JOIN Payments.Wallet w ON u.UserID = w.UserID
LEFT JOIN Users.Vehicle v ON u.UserID = v.UserID AND v.IsActive = 1
WHERE u.Role = 'Customer'
GROUP BY u.UserID, u.Username, u.FullName, u.Email, u.Phone, u.CreatedAt, w.Balance;
GO

-- ============================================================
-- vw_StationPerformance: Revenue & usage KPIs per station
-- ============================================================
CREATE OR ALTER VIEW Reporting.vw_StationPerformance
AS
SELECT s.StationID, s.StationCode, s.StationName, s.FranchiseID, s.StationStatus,
       COUNT(cs.SessionID) AS TotalSessions,
       ISNULL(SUM(cs.TotalKWh), 0) AS TotalKWh,
       ISNULL(SUM(cs.CostTotal), 0) AS TotalRevenue,
       ISNULL(AVG(cs.ChargingDurationMinutes), 0) AS AvgDurationMinutes,
       ISNULL(AVG(cs.TotalKWh), 0) AS AvgKWhPerSession,
       MAX(cs.StartTime) AS LastSessionAt
FROM Infrastructure.ChargingStation s
LEFT JOIN Operations.ChargingSession cs ON s.StationID = cs.StationID AND cs.SessionStatus = 'Completed'
GROUP BY s.StationID, s.StationCode, s.StationName, s.FranchiseID, s.StationStatus;
GO

-- ============================================================
-- vw_RevenueTrend: Daily revenue for time-series charts
-- ============================================================
CREATE OR ALTER VIEW Reporting.vw_RevenueTrend
AS
SELECT CAST(StartTime AS DATE) AS Date,
       COUNT(SessionID) AS Sessions,
       ISNULL(SUM(TotalKWh), 0) AS KWh,
       ISNULL(SUM(CostTotal), 0) AS Revenue
FROM Operations.ChargingSession
WHERE SessionStatus = 'Completed' AND StartTime >= DATEADD(DAY, -90, SYSDATETIME())
GROUP BY CAST(StartTime AS DATE);
GO

PRINT N'Views created.';
GO
