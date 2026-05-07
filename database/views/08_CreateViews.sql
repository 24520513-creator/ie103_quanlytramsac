/*=============================================================================
  EV_Charging_System - VIEWS
  =============================================================================*/

USE EV_Charging_System;
GO

-- ========================================
-- vw_MonthlyRevenue
-- Monthly revenue summary by franchise and station.
-- ========================================
CREATE OR ALTER VIEW Reports.vw_MonthlyRevenue
AS
SELECT
    YEAR(t.[Timestamp])              AS RevenueYear,
    MONTH(t.[Timestamp])             AS RevenueMonth,
    RIGHT(N'0' + CAST(MONTH(t.[Timestamp]) AS VARCHAR(2)), 2)
        + N'-' + CAST(YEAR(t.[Timestamp]) AS VARCHAR(4)) AS MonthLabel,
    f.FranchiseeID,
    f.FranchiseeName,
    s.StationID,
    s.StationName,
    COUNT(DISTINCT t.TransactionID)   AS TransactionCount,
    COUNT(DISTINCT t.UserID)         AS UniqueCustomers,
    ISNULL(SUM(t.Amount), 0)         AS TotalRevenue,
    ISNULL(AVG(t.Amount), 0)         AS AvgTransactionValue
FROM Operations.Transactions t
JOIN Operations.ChargingSession cs ON t.SessionID = cs.SessionID
JOIN Infrastructure.ChargingPoint p ON cs.PointID = p.PointID
JOIN Infrastructure.ChargingStation s ON p.StationID = s.StationID
JOIN Infrastructure.Franchisee f ON s.FranchiseeID = f.FranchiseeID
GROUP BY
    YEAR(t.[Timestamp]),
    MONTH(t.[Timestamp]),
    f.FranchiseeID,
    f.FranchiseeName,
    s.StationID,
    s.StationName;
GO

-- ========================================
-- vw_StationPerformance
-- KPIs for each charging station.
-- ========================================
CREATE OR ALTER VIEW Reports.vw_StationPerformance
AS
SELECT
    s.StationID,
    s.StationName,
    s.StationStatus,
    f.FranchiseeName,
    COUNT(DISTINCT p.PointID)       AS TotalPoints,
    SUM(CASE WHEN p.PointStatus = N'Khả dụng' THEN 1 ELSE 0 END) AS AvailablePoints,
    SUM(CASE WHEN p.PointStatus = N'Đang bận' THEN 1 ELSE 0 END) AS BusyPoints,
    SUM(CASE WHEN p.PointStatus = N'Đang lỗi' THEN 1 ELSE 0 END) AS ErrorPoints,
    COUNT(DISTINCT ses.SessionID)   AS TotalSessions,
    ISNULL(SUM(ses.Total_kWh), 0)   AS TotalEnergy_kWh,
    ISNULL(SUM(ses.CostTotal), 0)   AS TotalRevenue,
    CASE
        WHEN COUNT(DISTINCT ses.SessionID) > 0
        THEN ISNULL(SUM(ses.CostTotal), 0) / COUNT(DISTINCT ses.SessionID)
        ELSE 0
    END                             AS RevenuePerSession
FROM Infrastructure.ChargingStation s
JOIN Infrastructure.Franchisee f ON s.FranchiseeID = f.FranchiseeID
LEFT JOIN Infrastructure.ChargingPoint p ON s.StationID = p.StationID
LEFT JOIN Operations.ChargingSession ses ON p.PointID = ses.PointID AND ses.Status = N'Đã sạc xong'
GROUP BY s.StationID, s.StationName, s.StationStatus, f.FranchiseeName;
GO

-- ========================================
-- vw_ActiveChargingSessions
-- Displays all currently active charging sessions.
-- ========================================
CREATE OR ALTER VIEW Reports.vw_ActiveChargingSessions
AS
SELECT
    ses.SessionID,
    c.FullName             AS CustomerName,
    c.Phone                AS CustomerPhone,
    v.PlateNumber          AS VehiclePlate,
    s.StationName,
    p.PointID,
    p.ConnectorType,
    p.Power_kW,
    pol.PolicyName,
    pol.BasePrice_kWh,
    ses.StartTime,
    DATEDIFF(MINUTE, ses.StartTime, SYSDATETIME()) AS DurationMinutes,
    ses.Status
FROM Operations.ChargingSession ses
JOIN Users.Customers c ON ses.UserID = c.UserID
    OUTER APPLY (SELECT TOP 1 PlateNumber FROM Users.Vehicles WHERE UserID = c.UserID) v
JOIN Infrastructure.ChargingPoint p ON ses.PointID = p.PointID
JOIN Infrastructure.ChargingStation s ON p.StationID = s.StationID
JOIN Operations.PricingPolicy pol ON ses.PolicyID = pol.PolicyID
WHERE ses.Status = N'Đang sạc';
GO

PRINT N'Views created successfully.';
GO
