USE EV_Charging_System;
GO

PRINT N'============================================================';
PRINT N' Seed Data Validation Report';
PRINT N'============================================================';
PRINT N'';

-- ============================================================
-- 1. Infrastructure
-- ============================================================
PRINT N'--- INFRASTRUCTURE ---';
SELECT COUNT(*) AS CountryCount FROM Infrastructure.Country;
SELECT COUNT(*) AS RegionCount FROM Infrastructure.Region;
SELECT COUNT(*) AS AddressCount FROM Infrastructure.Address;
SELECT COUNT(*) AS FranchiseCount FROM Infrastructure.Franchise;
SELECT COUNT(*) AS SupplierCount FROM Infrastructure.ElectricitySupplier;
SELECT COUNT(*) AS StationCount FROM Infrastructure.ChargingStation;
SELECT COUNT(*) AS PointCount FROM Infrastructure.ChargingPoint;
SELECT COUNT(*) AS ErrorLogCount FROM Infrastructure.ErrorLog;
GO

-- ============================================================
-- 2. Users
-- ============================================================
PRINT N'--- USERS ---';
SELECT Role, COUNT(*) AS Count FROM Users.[User] GROUP BY Role ORDER BY Role;
SELECT COUNT(*) AS VehicleCount FROM Users.Vehicle;
SELECT COUNT(*) AS NotificationCount FROM Users.Notification;
GO

-- ============================================================
-- 3. Operations
-- ============================================================
PRINT N'--- OPERATIONS ---';
SELECT COUNT(*) AS PolicyCount FROM Operations.PricingPolicy;
SELECT COUNT(*) AS BookingCount FROM Operations.Booking;
SELECT Status, COUNT(*) AS Count FROM Operations.Booking GROUP BY Status;
SELECT COUNT(*) AS SessionCount FROM Operations.ChargingSession;
SELECT SessionStatus, COUNT(*) AS Count FROM Operations.ChargingSession GROUP BY SessionStatus;
SELECT COUNT(*) AS MaintenanceCount FROM Operations.MaintenanceSchedule;
SELECT COUNT(*) AS ReviewCount FROM Operations.StationReview;
GO

-- ============================================================
-- 4. Payments
-- ============================================================
PRINT N'--- PAYMENTS ---';
SELECT COUNT(*) AS WalletCount FROM Payments.Wallet;
SELECT COUNT(*) AS TransactionCount FROM Payments.[Transaction];
SELECT TransactionStatus, COUNT(*) AS Count FROM Payments.[Transaction] GROUP BY TransactionStatus;
SELECT COUNT(*) AS WalletTxnCount FROM Payments.WalletTransaction;
GO

-- ============================================================
-- 5. Analytics
-- ============================================================
PRINT N'--- ANALYTICS ---';
SELECT COUNT(*) AS KPIHourlyCount FROM Reporting.KPISnapshotHourly;
SELECT COUNT(*) AS KPIDailyCount FROM Reporting.KPISnapshotDaily;
SELECT COUNT(*) AS RealtimeEventCount FROM dbo.RealtimeEvent;
GO

-- ============================================================
-- 6. Vietnamese Unicode Check
-- ============================================================
PRINT N'--- UNICODE VERIFICATION ---';
SELECT FULL NAME VIOLATIONS (should have no rows):
SELECT AddressID, StreetAddress, FullAddress FROM Infrastructure.Address
WHERE StreetAddress LIKE '%?%' OR FullAddress LIKE '%?%';

SELECT UserID, FullName FROM Users.[User]
WHERE FullName LIKE '%?%';
GO

-- ============================================================
-- 7. Relationship Integrity
-- ============================================================
PRINT N'--- INTEGRITY CHECKS ---';
PRINT N'Orphaned ChargingSessions (no user):';
SELECT COUNT(*) FROM Operations.ChargingSession cs
WHERE NOT EXISTS (SELECT 1 FROM Users.[User] u WHERE u.UserID = cs.UserID);

PRINT N'Orphaned Transactions (no user):';
SELECT COUNT(*) FROM Payments.[Transaction] t
WHERE NOT EXISTS (SELECT 1 FROM Users.[User] u WHERE u.UserID = t.UserID);

PRINT N'Orphaned Vehicles (no user):';
SELECT COUNT(*) FROM Users.Vehicle v
WHERE NOT EXISTS (SELECT 1 FROM Users.[User] u WHERE u.UserID = v.UserID);

PRINT N'Orphaned Wallets (no user):';
SELECT COUNT(*) FROM Payments.Wallet w
WHERE NOT EXISTS (SELECT 1 FROM Users.[User] u WHERE u.UserID = w.UserID);
GO

-- ============================================================
-- 8. Dashboard-Relevant Metrics
-- ============================================================
PRINT N'--- DASHBOARD METRICS ---';
PRINT N'Total revenue to date:';
SELECT ISNULL(SUM(CostTotal), 0) AS TotalRevenue FROM Operations.ChargingSession WHERE SessionStatus = 'Completed';

PRINT N'Total kWh delivered:';
SELECT ISNULL(SUM(TotalKWh), 0) AS TotalKWh FROM Operations.ChargingSession WHERE SessionStatus = 'Completed';

PRINT N'Sessions by hour (peak analysis):';
SELECT DATEPART(HOUR, StartTime) AS Hour, COUNT(*) AS Sessions, ISNULL(SUM(TotalKWh), 0) AS KWh
FROM Operations.ChargingSession WHERE SessionStatus = 'Completed'
GROUP BY DATEPART(HOUR, StartTime) ORDER BY Hour;

PRINT N'Revenue by franchise:';
SELECT f.FranchiseName, ISNULL(SUM(cs.CostTotal), 0) AS Revenue
FROM Infrastructure.Franchise f
LEFT JOIN Infrastructure.ChargingStation s ON f.FranchiseID = s.FranchiseID
LEFT JOIN Operations.ChargingSession cs ON s.StationID = cs.StationID AND cs.SessionStatus = 'Completed'
GROUP BY f.FranchiseName ORDER BY Revenue DESC;

PRINT N'Top 5 stations by revenue:';
SELECT TOP 5 s.StationCode, s.StationName, ISNULL(SUM(cs.CostTotal), 0) AS Revenue
FROM Infrastructure.ChargingStation s
LEFT JOIN Operations.ChargingSession cs ON s.StationID = cs.StationID AND cs.SessionStatus = 'Completed'
GROUP BY s.StationID, s.StationCode, s.StationName
ORDER BY Revenue DESC;

PRINT N'System health summary:';
EXEC Reporting.sp_GetSystemHealthSummary;
GO

PRINT N'';
PRINT N'============================================================';
PRINT N' Validation complete!';
PRINT N'============================================================';
GO
