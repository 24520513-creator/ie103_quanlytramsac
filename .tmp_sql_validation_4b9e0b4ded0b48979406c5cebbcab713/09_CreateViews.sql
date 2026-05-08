/*==============================================================================
  EV_Charging_System_Validation - ENTERPRISE VIEWS
  ==============================================================================
  Purpose:    Abstract complexity, provide business-ready data, optimize reporting
  =============================================================================*/

USE EV_Charging_System_Validation;
GO

-- ===========================================================================
-- vw_ActiveChargingSessions - Real-time active charging view
-- ===========================================================================
CREATE OR ALTER VIEW Reporting.vw_ActiveChargingSessions
AS
SELECT
    cs.SessionID,
    cs.SessionCode,
    u.UserID,
    up.FullName                              AS CustomerName,
    u.Phone                                  AS CustomerPhone,
    v.PlateNumber                            AS VehiclePlate,
    v.Brand + N' ' + v.Model                 AS VehicleName,
    s.StationName,
    s.StationCode,
    p.PointCode,
    p.ConnectorType,
    p.PowerKW,
    pp.PolicyName,
    pp.BasePricePerKWh,
    cs.StartTime,
    DATEDIFF(MINUTE, cs.StartTime, SYSDATETIME()) AS DurationMinutes,
    cs.StartBatteryPercent,
    cs.SessionSource,
    cs.SessionType,
    cs.SessionStatus
FROM Operations.ChargingSession cs
JOIN Users.[User] u ON cs.UserID = u.UserID
JOIN Users.UserProfile up ON u.UserID = up.UserID
LEFT JOIN Users.Vehicle v ON cs.VehicleID = v.VehicleID
JOIN Infrastructure.ChargingPoint p ON cs.PointID = p.PointID
JOIN Infrastructure.ChargingStation s ON cs.StationID = s.StationID
JOIN Operations.PricingPolicy pp ON cs.PolicyID = pp.PolicyID
WHERE cs.SessionStatus = N'Charging' AND cs.IsDeleted = 0;
GO

-- ===========================================================================
-- vw_StationAvailability - Real-time station capacity/availability
-- ===========================================================================
CREATE OR ALTER VIEW Reporting.vw_StationAvailability
AS
SELECT
    s.StationID,
    s.StationCode,
    s.StationName,
    s.StationStatus,
    s.NetworkStatus,
    a.FullAddress AS Address,
    s.Latitude,
    s.Longitude,
    f.FranchiseName,
    COUNT(p.PointID)                                          AS TotalPoints,
    SUM(CASE WHEN p.PointStatus = N'Available' THEN 1 ELSE 0 END) AS AvailablePoints,
    SUM(CASE WHEN p.PointStatus = N'Busy' THEN 1 ELSE 0 END)      AS BusyPoints,
    SUM(CASE WHEN p.PointStatus IN (N'Error', N'Offline', N'Maintenance') THEN 1 ELSE 0 END) AS OfflinePoints,
    CASE WHEN COUNT(p.PointID) > 0
         THEN CAST(SUM(CASE WHEN p.PointStatus = N'Available' THEN 1 ELSE 0 END) * 100
              / COUNT(p.PointID) AS DECIMAL(5,2)) ELSE 0 END  AS AvailabilityPercent,
    s.MaxCapacityKW,
    s.HasGenerator,
    s.HasSolarPanels,
    s.ParkingSpots
FROM Infrastructure.ChargingStation s
JOIN Infrastructure.Address a ON s.AddressID = a.AddressID
JOIN Infrastructure.Franchise f ON s.FranchiseID = f.FranchiseID
LEFT JOIN Infrastructure.ChargingPoint p ON s.StationID = p.StationID AND p.IsDeleted = 0
WHERE s.IsDeleted = 0
GROUP BY s.StationID, s.StationCode, s.StationName, s.StationStatus, s.NetworkStatus,
         a.FullAddress, s.Latitude, s.Longitude, f.FranchiseName, s.MaxCapacityKW,
         s.HasGenerator, s.HasSolarPanels, s.ParkingSpots;
GO

-- ===========================================================================
-- vw_CustomerChargingSummary - Per-customer lifetime metrics
-- ===========================================================================
CREATE OR ALTER VIEW Reporting.vw_CustomerChargingSummary
AS
SELECT
    u.UserID,
    u.Username,
    up.FullName,
    u.Email,
    u.Phone,
    u.AccountStatus,
    u.AccountTier,
    COUNT(DISTINCT cs.SessionID)                        AS TotalSessions,
    COUNT(DISTINCT v.VehicleID)                         AS TotalVehicles,
    ISNULL(SUM(cs.TotalKWh), 0)                         AS LifetimeKWh,
    ISNULL(SUM(cs.CostTotal), 0)                        AS LifetimeSpend,
    ISNULL(AVG(cs.CostTotal), 0)                        AS AvgSpendPerSession,
    ISNULL(AVG(cs.TotalKWh), 0)                         AS AvgKWhPerSession,
    MAX(cs.StartTime)                                   AS LastChargingDate,
    DATEDIFF(DAY, MAX(cs.StartTime), SYSDATETIME())     AS DaysSinceLastCharge
FROM Users.[User] u
JOIN Users.UserProfile up ON u.UserID = up.UserID
LEFT JOIN Users.Vehicle v ON u.UserID = v.UserID AND v.IsDeleted = 0
LEFT JOIN Operations.ChargingSession cs ON u.UserID = cs.UserID
    AND cs.SessionStatus = N'Completed' AND cs.IsDeleted = 0
WHERE u.IsDeleted = 0
GROUP BY u.UserID, u.Username, up.FullName, u.Email, u.Phone,
         u.AccountStatus, u.AccountTier;
GO

-- ===========================================================================
-- vw_FranchisePerformanceSummary - Franchise-level KPIs
-- ===========================================================================
CREATE OR ALTER VIEW Reporting.vw_FranchisePerformanceSummary
AS
SELECT
    f.FranchiseID,
    f.FranchiseCode,
    f.FranchiseName,
    f.FranchiseTier,
    f.RevenueShareRate,
    f.ContractSignedDate,
    COUNT(DISTINCT s.StationID)                 AS TotalStations,
    COUNT(DISTINCT p.PointID)                   AS TotalPoints,
    COUNT(DISTINCT CASE WHEN s.StationStatus = N'Active' THEN s.StationID END) AS ActiveStations,
    COUNT(DISTINCT cs.SessionID)                AS TotalSessions,
    ISNULL(SUM(cs.TotalKWh), 0)                 AS TotalEnergyKWh,
    ISNULL(SUM(cs.CostTotal), 0)                AS TotalRevenue,
    ISNULL(SUM(cs.CostTotal * f.RevenueShareRate / 100), 0) AS TotalCommission,
    CASE WHEN COUNT(DISTINCT cs.SessionID) > 0
         THEN ISNULL(SUM(cs.CostTotal), 0) / COUNT(DISTINCT cs.SessionID) ELSE 0 END AS RevenuePerSession,
    ISNULL(AVG(cs.ChargingDurationMinutes), 0)  AS AvgChargingMinutes
FROM Infrastructure.Franchise f
LEFT JOIN Infrastructure.ChargingStation s ON f.FranchiseID = s.FranchiseID AND s.IsDeleted = 0
LEFT JOIN Infrastructure.ChargingPoint p ON s.StationID = p.StationID AND p.IsDeleted = 0
LEFT JOIN Operations.ChargingSession cs ON s.StationID = cs.StationID
    AND cs.SessionStatus = N'Completed' AND cs.IsDeleted = 0
WHERE f.IsDeleted = 0
GROUP BY f.FranchiseID, f.FranchiseCode, f.FranchiseName, f.FranchiseTier,
         f.RevenueShareRate, f.ContractSignedDate;
GO

-- ===========================================================================
-- vw_DailyRevenueTrend - Daily revenue for time-series dashboards
-- ===========================================================================
CREATE OR ALTER VIEW Reporting.vw_DailyRevenueTrend
AS
SELECT
    CAST(cs.StartTime AS DATE)                  AS RevenueDate,
    s.StationID,
    s.StationName,
    f.FranchiseID,
    f.FranchiseName,
    COUNT(DISTINCT cs.SessionID)                AS SessionCount,
    COUNT(DISTINCT cs.UserID)                   AS UniqueUsers,
    ISNULL(SUM(cs.TotalKWh), 0)                 AS TotalKWh,
    ISNULL(SUM(cs.CostTotal), 0)                AS TotalRevenue
FROM Operations.ChargingSession cs
JOIN Infrastructure.ChargingStation s ON cs.StationID = s.StationID
JOIN Infrastructure.Franchise f ON s.FranchiseID = f.FranchiseID
WHERE cs.SessionStatus = N'Completed' AND cs.IsDeleted = 0
GROUP BY CAST(cs.StartTime AS DATE), s.StationID, s.StationName,
         f.FranchiseID, f.FranchiseName;
GO

-- ===========================================================================
-- vw_PeakHourAnalysis - Hourly charging patterns
-- ===========================================================================
CREATE OR ALTER VIEW Reporting.vw_PeakHourAnalysis
AS
SELECT
    DATEPART(HOUR, cs.StartTime)    AS HourOfDay,
    DATENAME(WEEKDAY, cs.StartTime) AS DayOfWeek,
    DATEPART(WEEKDAY, cs.StartTime) AS DayOfWeekNumber,
    COUNT(DISTINCT cs.SessionID)    AS SessionCount,
    ISNULL(SUM(cs.TotalKWh), 0)     AS TotalKWh,
    ISNULL(SUM(cs.CostTotal), 0)    AS TotalRevenue,
    ISNULL(AVG(cs.TotalKWh), 0)     AS AvgKWh,
    ISNULL(AVG(cs.ChargingDurationMinutes), 0) AS AvgDurationMinutes
FROM Operations.ChargingSession cs
WHERE cs.SessionStatus = N'Completed' AND cs.IsDeleted = 0
  AND cs.StartTime >= DATEADD(MONTH, -6, SYSDATETIME())
GROUP BY DATEPART(HOUR, cs.StartTime), DATENAME(WEEKDAY, cs.StartTime),
         DATEPART(WEEKDAY, cs.StartTime);
GO

-- ===========================================================================
-- vw_EnergyCostAnalysis - Energy consumed vs cost analysis
-- ===========================================================================
CREATE OR ALTER VIEW Reporting.vw_EnergyCostAnalysis
AS
SELECT
    YEAR(cs.StartTime)                          AS Year,
    MONTH(cs.StartTime)                         AS Month,
    s.StationID,
    s.StationName,
    es.SupplierName,
    sec.UnitPricePerKWh                         AS ElectricityUnitPrice,
    ISNULL(SUM(cs.TotalKWh), 0)                 AS TotalKWhDelivered,
    ISNULL(SUM(cs.TotalKWh * sec.UnitPricePerKWh), 0) AS TotalElectricityCost,
    ISNULL(SUM(cs.CostTotal), 0)                AS TotalRevenue,
    ISNULL(SUM(cs.CostTotal), 0) - ISNULL(SUM(cs.TotalKWh * sec.UnitPricePerKWh), 0) AS GrossMargin
FROM Operations.ChargingSession cs
JOIN Infrastructure.ChargingStation s ON cs.StationID = s.StationID
JOIN Infrastructure.StationElectricityContract sec ON s.StationID = sec.StationID AND sec.IsActive = 1
JOIN Infrastructure.ElectricitySupplier es ON sec.SupplierID = es.SupplierID
WHERE cs.SessionStatus = N'Completed' AND cs.IsDeleted = 0
GROUP BY YEAR(cs.StartTime), MONTH(cs.StartTime), s.StationID, s.StationName,
         es.SupplierName, sec.UnitPricePerKWh;
GO

-- ===========================================================================
-- vw_StationUptimeAnalysis - Station reliability metrics
-- ===========================================================================
CREATE OR ALTER VIEW Reporting.vw_StationUptimeAnalysis
AS
SELECT
    s.StationID,
    s.StationCode,
    s.StationName,
    s.StationStatus,
    s.NetworkStatus,
    COUNT(DISTINCT CASE WHEN p.PointStatus = N'Available' THEN p.PointID END) AS AvailablePoints,
    COUNT(DISTINCT CASE WHEN p.PointStatus IN (N'Error', N'Offline') THEN p.PointID END) AS FaultedPoints,
    COUNT(DISTINCT el.ErrorID)                  AS TotalErrors,
    COUNT(DISTINCT CASE WHEN el.Severity = N'Critical' THEN el.ErrorID END) AS CriticalErrors,
    MAX(el.OccurredAt)                          AS LastErrorDate,
    COUNT(DISTINCT CASE WHEN el.ResolvedAt IS NULL AND el.ErrorID IS NOT NULL THEN el.ErrorID END) AS OpenErrors
FROM Infrastructure.ChargingStation s
LEFT JOIN Infrastructure.ChargingPoint p ON s.StationID = p.StationID AND p.IsDeleted = 0
LEFT JOIN Monitoring.ErrorLog el ON s.StationID = el.StationID
WHERE s.IsDeleted = 0
GROUP BY s.StationID, s.StationCode, s.StationName, s.StationStatus, s.NetworkStatus;
GO

-- ===========================================================================
-- vw_AuditTrailSummary - Consolidated event timeline
-- ===========================================================================
CREATE OR ALTER VIEW Reporting.vw_AuditTrailSummary
AS
SELECT
    N'Station' AS EntityType,
    CAST(ssh.StationID AS NVARCHAR(50)) AS EntityID,
    s.StationName AS EntityName,
    ssh.PreviousStatus,
    ssh.NewStatus,
    ssh.ChangeReason,
    ssh.ChangedAt AS EventTime
FROM Audit.StationStatusHistory ssh
JOIN Infrastructure.ChargingStation s ON ssh.StationID = s.StationID
UNION ALL
SELECT
    N'Point',
    CAST(psh.PointID AS NVARCHAR(50)),
    p.PointCode,
    psh.PreviousStatus,
    psh.NewStatus,
    psh.ChangeReason,
    psh.ChangedAt
FROM Audit.PointStatusHistory psh
JOIN Infrastructure.ChargingPoint p ON psh.PointID = p.PointID
UNION ALL
SELECT
    N'Session',
    CAST(ssesh.SessionID AS NVARCHAR(50)),
    cs.SessionCode,
    ssesh.PreviousStatus,
    ssesh.NewStatus,
    ssesh.ChangeReason,
    ssesh.ChangedAt
FROM Audit.SessionStatusHistory ssesh
JOIN Operations.ChargingSession cs ON ssesh.SessionID = cs.SessionID;
GO

PRINT N'Enterprise views created successfully.';
GO

