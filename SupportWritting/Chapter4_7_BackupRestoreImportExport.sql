==============================================================================
-- 4.7  BACKUP, RESTORE, IMPORT & EXPORT DU LIEU
-- (Gom day du source code that tu cac file trong database/)
==============================================================================

==============================================================================
-- 4.7.1  Vai tro Backup/Restore -- nen tang: RECOVERY SIMPLE
==============================================================================
-- Nguon: database/00_Drop_And_Create_Database.sql
USE master;
GO

IF DB_ID(N'EV_Charging_System') IS NOT NULL
BEGIN
    ALTER DATABASE EV_Charging_System SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE EV_Charging_System;
END;
GO

CREATE DATABASE EV_Charging_System;
GO

ALTER DATABASE EV_Charging_System SET RECOVERY SIMPLE;
GO

USE EV_Charging_System;
GO

PRINT N'00 - Database EV_Charging_System created.';
GO

==============================================================================
-- 4.7.2 & 4.7.3  Script Backup & Restore Database
==============================================================================
-- Nguon: database/12_Backup_Restore.sql
USE master;
GO

/*
Create C:\Backup first, or change the path below for the demo machine.

BACKUP DATABASE EV_Charging_System
TO DISK = 'C:\Backup\EV_Charging_System.bak'
WITH INIT, FORMAT, STATS = 10;

Safe restore example:
1. Backup the existing database first.
2. Close active connections.
3. Adjust MOVE file paths for the SQL Server machine.

RESTORE DATABASE EV_Charging_System_RestoreDemo
FROM DISK = 'C:\Backup\EV_Charging_System.bak'
WITH FILE = 1,
     MOVE 'EV_Charging_System' TO 'C:\Backup\EV_Charging_System_RestoreDemo.mdf',
     MOVE 'EV_Charging_System_log' TO 'C:\Backup\EV_Charging_System_RestoreDemo_log.ldf',
     STATS = 10;
*/

PRINT N'12 - Backup/restore demo script. Read comments before running.';
GO

-- Nguon (demo hien thi lenh qua result set):
-- database/features/system_admin/07_backup_restore_demo.sql
USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: hien thi cau lenh mau backup/restore.
- Can sua duong dan file .bak theo may truoc khi chay backup/restore that.
- Tac dong du lieu: file nay CHI HIEN THI LENH MAU, khong backup/restore that.
*/

PRINT N'Chuẩn bị backup và restore: quản trị viên xem câu lệnh mẫu để sao lưu và phục hồi database.';
PRINT N'Chuẩn bị backup và restore: quản trị viên xem câu lệnh mẫu để sao lưu và phục hồi database.';

SELECT
    DB_NAME() AS DatabaseName,
    N'BACKUP DATABASE EV_Charging_System TO DISK = N''C:\Temp\EV_Charging_System.bak'' WITH INIT, COMPRESSION, STATS = 5;' AS BackupCommand,
    N'RESTORE DATABASE EV_Charging_System_RestoreDemo FROM DISK = N''C:\Temp\EV_Charging_System.bak'' WITH MOVE ... , RECOVERY, STATS = 5;' AS RestoreCommand;
GO

==============================================================================
-- 4.7.4  Import du lieu vao he thong (BULK INSERT tu CSV)
==============================================================================
-- Nguon: database/09_Seed_Demo_Data.sql
USE EV_Charging_System;
GO
/* =====================================================================
   09_Seed_Demo_Data.sql  -- PHIEN BAN NAP TU CSV (BULK INSERT)
   ---------------------------------------------------------------------
   - Thay cho ban sinh du lieu bang code (nhe, nhanh, khong gay crash).
   - Nguon du lieu: thu muc database\SeedData\*.csv (29 bang).
   - Chay SAU 00 -> 08 (DB moi, dang trong), TRUOC 10 -> 13.
   - Yeu cau: SQL Server 2016+ (ho tro FORMAT='CSV', CODEPAGE='65001').
   - File CSV doc theo ngu canh Windows cua nguoi dang dang nhap (local).
     Neu loi 'Cannot bulk load / Access denied': cap quyen Read thu muc
     SeedData cho tai khoan dich vu SQL Server, hoac doi @DataDir sang
     thu muc ma SQL Server doc duoc.
   ===================================================================== */
SET NOCOUNT ON;
SET XACT_ABORT ON;

-- >>> SUA DUONG DAN NAY CHO DUNG MAY CUA BAN <<<
DECLARE @DataDir NVARCHAR(4000) = N'C:\Users\hocvi\OneDrive\Documents\Study\IE103_QuanLyThongTin\SourceCode\database\SeedData';
DECLARE @sql NVARCHAR(MAX);

IF EXISTS (SELECT 1 FROM Operations.ChargingSession)
    THROW 60000, N'Cac bang da co du lieu. Hay chay tren DB moi (sau khi chay 00 -> 08).', 1;

PRINT N'Nap Core.Region ...';
SET @sql = N'BULK INSERT [Core].[Region] FROM ''' + @DataDir + N'\Core.Region.csv'' WITH (FORMAT=''CSV'',FIRSTROW=2,FIELDQUOTE=''"'',FIELDTERMINATOR='','',ROWTERMINATOR=''0x0d0a'',CODEPAGE=''65001'',KEEPNULLS,TABLOCK,KEEPIDENTITY);';
EXEC sp_executesql @sql;

PRINT N'Nap Identity.Role ...';
SET @sql = N'BULK INSERT [Identity].[Role] FROM ''' + @DataDir + N'\Identity.Role.csv'' WITH (FORMAT=''CSV'',FIRSTROW=2,FIELDQUOTE=''"'',FIELDTERMINATOR='','',ROWTERMINATOR=''0x0d0a'',CODEPAGE=''65001'',KEEPNULLS,TABLOCK,KEEPIDENTITY);';
EXEC sp_executesql @sql;

PRINT N'Nap Identity.UserAccount ...';
SET @sql = N'BULK INSERT [Identity].[UserAccount] FROM ''' + @DataDir + N'\Identity.UserAccount.csv'' WITH (FORMAT=''CSV'',FIRSTROW=2,FIELDQUOTE=''"'',FIELDTERMINATOR='','',ROWTERMINATOR=''0x0d0a'',CODEPAGE=''65001'',KEEPNULLS,TABLOCK,KEEPIDENTITY);';
EXEC sp_executesql @sql;

PRINT N'Nap Infrastructure.ConnectorType ...';
SET @sql = N'BULK INSERT [Infrastructure].[ConnectorType] FROM ''' + @DataDir + N'\Infrastructure.ConnectorType.csv'' WITH (FORMAT=''CSV'',FIRSTROW=2,FIELDQUOTE=''"'',FIELDTERMINATOR='','',ROWTERMINATOR=''0x0d0a'',CODEPAGE=''65001'',KEEPNULLS,TABLOCK,KEEPIDENTITY);';
EXEC sp_executesql @sql;

PRINT N'Nap Operations.PricingPolicy ...';
SET @sql = N'BULK INSERT [Operations].[PricingPolicy] FROM ''' + @DataDir + N'\Operations.PricingPolicy.csv'' WITH (FORMAT=''CSV'',FIRSTROW=2,FIELDQUOTE=''"'',FIELDTERMINATOR='','',ROWTERMINATOR=''0x0d0a'',CODEPAGE=''65001'',KEEPNULLS,TABLOCK,KEEPIDENTITY);';
EXEC sp_executesql @sql;

PRINT N'Nap Audit.AuditLog ...';
SET @sql = N'BULK INSERT [Audit].[AuditLog] FROM ''' + @DataDir + N'\Audit.AuditLog.csv'' WITH (FORMAT=''CSV'',FIRSTROW=2,FIELDQUOTE=''"'',FIELDTERMINATOR='','',ROWTERMINATOR=''0x0d0a'',CODEPAGE=''65001'',KEEPNULLS,TABLOCK,KEEPIDENTITY);';
EXEC sp_executesql @sql;

PRINT N'Nap Core.Address ...';
CREATE TABLE #stg_Address ([AddressID] int, [RegionID] int, [StreetAddress] nvarchar(255), [Ward] nvarchar(100), [District] nvarchar(100), [Latitude] decimal(10,7), [Longitude] decimal(10,7), [CreatedAt] datetime2(7));
SET @sql = N'BULK INSERT #stg_Address FROM ''' + @DataDir + N'\Core.Address.csv'' WITH (FORMAT=''CSV'',FIRSTROW=2,FIELDQUOTE=''"'',FIELDTERMINATOR='','',ROWTERMINATOR=''0x0d0a'',CODEPAGE=''65001'',KEEPNULLS,TABLOCK);';
EXEC sp_executesql @sql;
SET IDENTITY_INSERT [Core].[Address] ON;
INSERT INTO [Core].[Address] ([AddressID],[RegionID],[StreetAddress],[Ward],[District],[Latitude],[Longitude],[CreatedAt]) SELECT [AddressID],[RegionID],[StreetAddress],[Ward],[District],[Latitude],[Longitude],[CreatedAt] FROM #stg_Address;
SET IDENTITY_INSERT [Core].[Address] OFF;
DROP TABLE #stg_Address;

PRINT N'Nap Infrastructure.ElectricitySupplier ...';
SET @sql = N'BULK INSERT [Infrastructure].[ElectricitySupplier] FROM ''' + @DataDir + N'\Infrastructure.ElectricitySupplier.csv'' WITH (FORMAT=''CSV'',FIRSTROW=2,FIELDQUOTE=''"'',FIELDTERMINATOR='','',ROWTERMINATOR=''0x0d0a'',CODEPAGE=''65001'',KEEPNULLS,TABLOCK,KEEPIDENTITY);';
EXEC sp_executesql @sql;

PRINT N'Nap Identity.UserRole ...';
SET @sql = N'BULK INSERT [Identity].[UserRole] FROM ''' + @DataDir + N'\Identity.UserRole.csv'' WITH (FORMAT=''CSV'',FIRSTROW=2,FIELDQUOTE=''"'',FIELDTERMINATOR='','',ROWTERMINATOR=''0x0d0a'',CODEPAGE=''65001'',KEEPNULLS,TABLOCK);';
EXEC sp_executesql @sql;

PRINT N'Nap Identity.AuthEvent ...';
SET @sql = N'BULK INSERT [Identity].[AuthEvent] FROM ''' + @DataDir + N'\Identity.AuthEvent.csv'' WITH (FORMAT=''CSV'',FIRSTROW=2,FIELDQUOTE=''"'',FIELDTERMINATOR='','',ROWTERMINATOR=''0x0d0a'',CODEPAGE=''65001'',KEEPNULLS,TABLOCK,KEEPIDENTITY);';
EXEC sp_executesql @sql;

PRINT N'Nap Identity.AuthToken ...';
SET @sql = N'BULK INSERT [Identity].[AuthToken] FROM ''' + @DataDir + N'\Identity.AuthToken.csv'' WITH (FORMAT=''CSV'',FIRSTROW=2,FIELDQUOTE=''"'',FIELDTERMINATOR='','',ROWTERMINATOR=''0x0d0a'',CODEPAGE=''65001'',KEEPNULLS,TABLOCK,KEEPIDENTITY);';
EXEC sp_executesql @sql;

PRINT N'Nap Franchise.FranchisePartner ...';
SET @sql = N'BULK INSERT [Franchise].[FranchisePartner] FROM ''' + @DataDir + N'\Franchise.FranchisePartner.csv'' WITH (FORMAT=''CSV'',FIRSTROW=2,FIELDQUOTE=''"'',FIELDTERMINATOR='','',ROWTERMINATOR=''0x0d0a'',CODEPAGE=''65001'',KEEPNULLS,TABLOCK,KEEPIDENTITY);';
EXEC sp_executesql @sql;

PRINT N'Nap Franchise.FranchiseContract ...';
SET @sql = N'BULK INSERT [Franchise].[FranchiseContract] FROM ''' + @DataDir + N'\Franchise.FranchiseContract.csv'' WITH (FORMAT=''CSV'',FIRSTROW=2,FIELDQUOTE=''"'',FIELDTERMINATOR='','',ROWTERMINATOR=''0x0d0a'',CODEPAGE=''65001'',KEEPNULLS,TABLOCK,KEEPIDENTITY);';
EXEC sp_executesql @sql;

PRINT N'Nap Franchise.RevenueSharePolicy ...';
CREATE TABLE #stg_RevenueSharePolicy ([RevenueSharePolicyID] int, [ContractID] int, [PolicyCode] nvarchar(40), [PartnerShareRate] decimal(5,2), [AppliedFrom] date, [AppliedTo] date, [IsActive] bit);
SET @sql = N'BULK INSERT #stg_RevenueSharePolicy FROM ''' + @DataDir + N'\Franchise.RevenueSharePolicy.csv'' WITH (FORMAT=''CSV'',FIRSTROW=2,FIELDQUOTE=''"'',FIELDTERMINATOR='','',ROWTERMINATOR=''0x0d0a'',CODEPAGE=''65001'',KEEPNULLS,TABLOCK);';
EXEC sp_executesql @sql;
SET IDENTITY_INSERT [Franchise].[RevenueSharePolicy] ON;
INSERT INTO [Franchise].[RevenueSharePolicy] ([RevenueSharePolicyID],[ContractID],[PolicyCode],[PartnerShareRate],[AppliedFrom],[AppliedTo],[IsActive]) SELECT [RevenueSharePolicyID],[ContractID],[PolicyCode],[PartnerShareRate],[AppliedFrom],[AppliedTo],[IsActive] FROM #stg_RevenueSharePolicy;
SET IDENTITY_INSERT [Franchise].[RevenueSharePolicy] OFF;
DROP TABLE #stg_RevenueSharePolicy;

PRINT N'Nap Infrastructure.ChargingStation ...';
SET @sql = N'BULK INSERT [Infrastructure].[ChargingStation] FROM ''' + @DataDir + N'\Infrastructure.ChargingStation.csv'' WITH (FORMAT=''CSV'',FIRSTROW=2,FIELDQUOTE=''"'',FIELDTERMINATOR='','',ROWTERMINATOR=''0x0d0a'',CODEPAGE=''65001'',KEEPNULLS,TABLOCK,KEEPIDENTITY);';
EXEC sp_executesql @sql;

PRINT N'Nap Franchise.FranchiseStation ...';
SET @sql = N'BULK INSERT [Franchise].[FranchiseStation] FROM ''' + @DataDir + N'\Franchise.FranchiseStation.csv'' WITH (FORMAT=''CSV'',FIRSTROW=2,FIELDQUOTE=''"'',FIELDTERMINATOR='','',ROWTERMINATOR=''0x0d0a'',CODEPAGE=''65001'',KEEPNULLS,TABLOCK);';
EXEC sp_executesql @sql;

PRINT N'Nap Franchise.RevenueShareSettlement ...';
SET @sql = N'BULK INSERT [Franchise].[RevenueShareSettlement] FROM ''' + @DataDir + N'\Franchise.RevenueShareSettlement.csv'' WITH (FORMAT=''CSV'',FIRSTROW=2,FIELDQUOTE=''"'',FIELDTERMINATOR='','',ROWTERMINATOR=''0x0d0a'',CODEPAGE=''65001'',KEEPNULLS,TABLOCK,KEEPIDENTITY);';
EXEC sp_executesql @sql;

PRINT N'Nap Infrastructure.ChargingPoint ...';
SET @sql = N'BULK INSERT [Infrastructure].[ChargingPoint] FROM ''' + @DataDir + N'\Infrastructure.ChargingPoint.csv'' WITH (FORMAT=''CSV'',FIRSTROW=2,FIELDQUOTE=''"'',FIELDTERMINATOR='','',ROWTERMINATOR=''0x0d0a'',CODEPAGE=''65001'',KEEPNULLS,TABLOCK,KEEPIDENTITY);';
EXEC sp_executesql @sql;

PRINT N'Nap Infrastructure.StationConnectorType ...';
SET @sql = N'BULK INSERT [Infrastructure].[StationConnectorType] FROM ''' + @DataDir + N'\Infrastructure.StationConnectorType.csv'' WITH (FORMAT=''CSV'',FIRSTROW=2,FIELDQUOTE=''"'',FIELDTERMINATOR='','',ROWTERMINATOR=''0x0d0a'',CODEPAGE=''65001'',KEEPNULLS,TABLOCK);';
EXEC sp_executesql @sql;

PRINT N'Nap Operations.Vehicle ...';
SET @sql = N'BULK INSERT [Operations].[Vehicle] FROM ''' + @DataDir + N'\Operations.Vehicle.csv'' WITH (FORMAT=''CSV'',FIRSTROW=2,FIELDQUOTE=''"'',FIELDTERMINATOR='','',ROWTERMINATOR=''0x0d0a'',CODEPAGE=''65001'',KEEPNULLS,TABLOCK,KEEPIDENTITY);';
EXEC sp_executesql @sql;

PRINT N'Nap Infrastructure.PointStatusHistory ...';
SET @sql = N'BULK INSERT [Infrastructure].[PointStatusHistory] FROM ''' + @DataDir + N'\Infrastructure.PointStatusHistory.csv'' WITH (FORMAT=''CSV'',FIRSTROW=2,FIELDQUOTE=''"'',FIELDTERMINATOR='','',ROWTERMINATOR=''0x0d0a'',CODEPAGE=''65001'',KEEPNULLS,TABLOCK,KEEPIDENTITY);';
EXEC sp_executesql @sql;

PRINT N'Nap Infrastructure.PointTelemetry ...';
SET @sql = N'BULK INSERT [Infrastructure].[PointTelemetry] FROM ''' + @DataDir + N'\Infrastructure.PointTelemetry.csv'' WITH (FORMAT=''CSV'',FIRSTROW=2,FIELDQUOTE=''"'',FIELDTERMINATOR='','',ROWTERMINATOR=''0x0d0a'',CODEPAGE=''65001'',KEEPNULLS,TABLOCK,KEEPIDENTITY);';
EXEC sp_executesql @sql;

PRINT N'Nap Maintenance.ErrorLog ...';
SET @sql = N'BULK INSERT [Maintenance].[ErrorLog] FROM ''' + @DataDir + N'\Maintenance.ErrorLog.csv'' WITH (FORMAT=''CSV'',FIRSTROW=2,FIELDQUOTE=''"'',FIELDTERMINATOR='','',ROWTERMINATOR=''0x0d0a'',CODEPAGE=''65001'',KEEPNULLS,TABLOCK,KEEPIDENTITY);';
EXEC sp_executesql @sql;

PRINT N'Nap Maintenance.MaintenanceTicket ...';
SET @sql = N'BULK INSERT [Maintenance].[MaintenanceTicket] FROM ''' + @DataDir + N'\Maintenance.MaintenanceTicket.csv'' WITH (FORMAT=''CSV'',FIRSTROW=2,FIELDQUOTE=''"'',FIELDTERMINATOR='','',ROWTERMINATOR=''0x0d0a'',CODEPAGE=''65001'',KEEPNULLS,TABLOCK,KEEPIDENTITY);';
EXEC sp_executesql @sql;

PRINT N'Nap Operations.Booking ...';
SET @sql = N'BULK INSERT [Operations].[Booking] FROM ''' + @DataDir + N'\Operations.Booking.csv'' WITH (FORMAT=''CSV'',FIRSTROW=2,FIELDQUOTE=''"'',FIELDTERMINATOR='','',ROWTERMINATOR=''0x0d0a'',CODEPAGE=''65001'',KEEPNULLS,TABLOCK,KEEPIDENTITY);';
EXEC sp_executesql @sql;

PRINT N'Nap Operations.ChargingSession ...';
SET @sql = N'BULK INSERT [Operations].[ChargingSession] FROM ''' + @DataDir + N'\Operations.ChargingSession.csv'' WITH (FORMAT=''CSV'',FIRSTROW=2,FIELDQUOTE=''"'',FIELDTERMINATOR='','',ROWTERMINATOR=''0x0d0a'',CODEPAGE=''65001'',KEEPNULLS,TABLOCK,KEEPIDENTITY);';
EXEC sp_executesql @sql;

PRINT N'Nap Operations.SessionEvent ...';
SET @sql = N'BULK INSERT [Operations].[SessionEvent] FROM ''' + @DataDir + N'\Operations.SessionEvent.csv'' WITH (FORMAT=''CSV'',FIRSTROW=2,FIELDQUOTE=''"'',FIELDTERMINATOR='','',ROWTERMINATOR=''0x0d0a'',CODEPAGE=''65001'',KEEPNULLS,TABLOCK,KEEPIDENTITY);';
EXEC sp_executesql @sql;

PRINT N'Nap Payments.PaymentTransaction ...';
SET @sql = N'BULK INSERT [Payments].[PaymentTransaction] FROM ''' + @DataDir + N'\Payments.PaymentTransaction.csv'' WITH (FORMAT=''CSV'',FIRSTROW=2,FIELDQUOTE=''"'',FIELDTERMINATOR='','',ROWTERMINATOR=''0x0d0a'',CODEPAGE=''65001'',KEEPNULLS,TABLOCK,KEEPIDENTITY);';
EXEC sp_executesql @sql;

PRINT N'Nap Payments.Invoice ...';
SET @sql = N'BULK INSERT [Payments].[Invoice] FROM ''' + @DataDir + N'\Payments.Invoice.csv'' WITH (FORMAT=''CSV'',FIRSTROW=2,FIELDQUOTE=''"'',FIELDTERMINATOR='','',ROWTERMINATOR=''0x0d0a'',CODEPAGE=''65001'',KEEPNULLS,TABLOCK,KEEPIDENTITY);';
EXEC sp_executesql @sql;

-- Dat lai bo dem IDENTITY ve gia tri lon nhat hien co
IF EXISTS (SELECT 1 FROM [Core].[Region]) DBCC CHECKIDENT (N'[Core].[Region]', RESEED);
IF EXISTS (SELECT 1 FROM [Identity].[Role]) DBCC CHECKIDENT (N'[Identity].[Role]', RESEED);
IF EXISTS (SELECT 1 FROM [Identity].[UserAccount]) DBCC CHECKIDENT (N'[Identity].[UserAccount]', RESEED);
IF EXISTS (SELECT 1 FROM [Infrastructure].[ConnectorType]) DBCC CHECKIDENT (N'[Infrastructure].[ConnectorType]', RESEED);
IF EXISTS (SELECT 1 FROM [Operations].[PricingPolicy]) DBCC CHECKIDENT (N'[Operations].[PricingPolicy]', RESEED);
IF EXISTS (SELECT 1 FROM [Audit].[AuditLog]) DBCC CHECKIDENT (N'[Audit].[AuditLog]', RESEED);
IF EXISTS (SELECT 1 FROM [Core].[Address]) DBCC CHECKIDENT (N'[Core].[Address]', RESEED);
IF EXISTS (SELECT 1 FROM [Infrastructure].[ElectricitySupplier]) DBCC CHECKIDENT (N'[Infrastructure].[ElectricitySupplier]', RESEED);
IF EXISTS (SELECT 1 FROM [Identity].[AuthEvent]) DBCC CHECKIDENT (N'[Identity].[AuthEvent]', RESEED);
IF EXISTS (SELECT 1 FROM [Identity].[AuthToken]) DBCC CHECKIDENT (N'[Identity].[AuthToken]', RESEED);
IF EXISTS (SELECT 1 FROM [Franchise].[FranchisePartner]) DBCC CHECKIDENT (N'[Franchise].[FranchisePartner]', RESEED);
IF EXISTS (SELECT 1 FROM [Franchise].[FranchiseContract]) DBCC CHECKIDENT (N'[Franchise].[FranchiseContract]', RESEED);
IF EXISTS (SELECT 1 FROM [Franchise].[RevenueSharePolicy]) DBCC CHECKIDENT (N'[Franchise].[RevenueSharePolicy]', RESEED);
IF EXISTS (SELECT 1 FROM [Infrastructure].[ChargingStation]) DBCC CHECKIDENT (N'[Infrastructure].[ChargingStation]', RESEED);
IF EXISTS (SELECT 1 FROM [Franchise].[RevenueShareSettlement]) DBCC CHECKIDENT (N'[Franchise].[RevenueShareSettlement]', RESEED);
IF EXISTS (SELECT 1 FROM [Infrastructure].[ChargingPoint]) DBCC CHECKIDENT (N'[Infrastructure].[ChargingPoint]', RESEED);
IF EXISTS (SELECT 1 FROM [Operations].[Vehicle]) DBCC CHECKIDENT (N'[Operations].[Vehicle]', RESEED);
IF EXISTS (SELECT 1 FROM [Infrastructure].[PointStatusHistory]) DBCC CHECKIDENT (N'[Infrastructure].[PointStatusHistory]', RESEED);
IF EXISTS (SELECT 1 FROM [Infrastructure].[PointTelemetry]) DBCC CHECKIDENT (N'[Infrastructure].[PointTelemetry]', RESEED);
IF EXISTS (SELECT 1 FROM [Maintenance].[ErrorLog]) DBCC CHECKIDENT (N'[Maintenance].[ErrorLog]', RESEED);
IF EXISTS (SELECT 1 FROM [Maintenance].[MaintenanceTicket]) DBCC CHECKIDENT (N'[Maintenance].[MaintenanceTicket]', RESEED);
IF EXISTS (SELECT 1 FROM [Operations].[Booking]) DBCC CHECKIDENT (N'[Operations].[Booking]', RESEED);
IF EXISTS (SELECT 1 FROM [Operations].[ChargingSession]) DBCC CHECKIDENT (N'[Operations].[ChargingSession]', RESEED);
IF EXISTS (SELECT 1 FROM [Operations].[SessionEvent]) DBCC CHECKIDENT (N'[Operations].[SessionEvent]', RESEED);
IF EXISTS (SELECT 1 FROM [Payments].[PaymentTransaction]) DBCC CHECKIDENT (N'[Payments].[PaymentTransaction]', RESEED);
IF EXISTS (SELECT 1 FROM [Payments].[Invoice]) DBCC CHECKIDENT (N'[Payments].[Invoice]', RESEED);

-- (Tuy chon) Xac thuc lai khoa ngoai de giu trang thai 'trusted'.
-- Co the bo comment neu may yeu va khong can.
DECLARE @recheck NVARCHAR(MAX) = N'';
SELECT @recheck += N'ALTER TABLE ' + QUOTENAME(OBJECT_SCHEMA_NAME(parent_object_id)) + N'.'
                + QUOTENAME(OBJECT_NAME(parent_object_id)) + N' WITH CHECK CHECK CONSTRAINT ALL;' + CHAR(10)
FROM sys.foreign_keys;
EXEC sp_executesql @recheck;

PRINT N'>>> Seed tu CSV hoan tat.';

==============================================================================
-- 4.7.5  Export du lieu bao cao (Reporting Views + Procedures)
==============================================================================
-- Nguon: database/07_Create_AppViews.sql
-- (a) Cac VIEW bao cao nen tang:

-- View: AppView.vw_CustomerChargingHistory
CREATE OR ALTER VIEW AppView.vw_CustomerChargingHistory
AS
SELECT
    u.UserID,
    u.Username,
    u.FullName,
    v.PlateNumber,
    cs.SessionID,
    cs.SessionCode,
    s.StationCode,
    s.StationName,
    p.PointCode,
    ct.ConnectorCode,
    cs.StartTime,
    cs.EndTime,
    cs.TotalKWh,
    cs.CostTotal,
    cs.SessionStatus
FROM Operations.ChargingSession cs
JOIN [Identity].UserAccount u ON u.UserID = cs.UserID
LEFT JOIN Operations.Vehicle v ON v.VehicleID = cs.VehicleID
JOIN Infrastructure.ChargingStation s ON s.StationID = cs.StationID
JOIN Infrastructure.ChargingPoint p ON p.PointID = cs.PointID
JOIN Infrastructure.ConnectorType ct ON ct.ConnectorTypeID = p.ConnectorTypeID
WHERE NOT (COALESCE(CAST(SESSION_CONTEXT(N'RoleCode') AS NVARCHAR(40)), N'') = N'Customer' OR IS_ROLEMEMBER(N'db_ev_customer') = 1)
   OR cs.UserID = TRY_CONVERT(INT, SESSION_CONTEXT(N'UserID'));
GO

-- View: AppView.vw_StationRevenueDaily
CREATE OR ALTER VIEW AppView.vw_StationRevenueDaily
AS
SELECT
    CAST(cs.StartTime AS DATE) AS RevenueDate,
    s.StationID,
    s.StationCode,
    s.StationName,
    f.FranchiseCode,
    f.FranchiseName,
    COUNT(cs.SessionID) AS CompletedSessions,
    SUM(ISNULL(cs.TotalKWh, 0)) AS TotalKWh,
    SUM(ISNULL(cs.CostBeforeTax, 0)) AS RevenueBeforeTax,
    SUM(ISNULL(cs.TaxAmount, 0)) AS TaxAmount,
    SUM(ISNULL(cs.CostTotal, 0)) AS RevenueTotal
FROM Operations.ChargingSession cs
JOIN Infrastructure.ChargingStation s ON s.StationID = cs.StationID
JOIN Franchise.FranchisePartner f ON f.FranchiseID = s.FranchiseID
WHERE cs.SessionStatus = N'Completed'
GROUP BY CAST(cs.StartTime AS DATE), s.StationID, s.StationCode, s.StationName, f.FranchiseCode, f.FranchiseName;
GO

-- View: AppView.vw_ProfitSharing
CREATE OR ALTER VIEW AppView.vw_ProfitSharing
AS
SELECT
    rs.SettlementCode,
    f.FranchiseCode,
    f.FranchiseName,
    fc.ContractCode,
    rs.PeriodStart,
    rs.PeriodEnd,
    rs.GrossRevenue,
    rs.PartnerShareAmount,
    rs.PlatformShareAmount,
    rs.SettlementStatus
FROM Franchise.RevenueShareSettlement rs
JOIN Franchise.FranchisePartner f ON f.FranchiseID = rs.FranchiseID
JOIN Franchise.FranchiseContract fc ON fc.ContractID = rs.ContractID;
GO

-- View: AppView.vw_MaintenanceKPI
CREATE OR ALTER VIEW AppView.vw_MaintenanceKPI
AS
SELECT
    s.StationCode,
    s.StationName,
    COUNT(DISTINCT mt.TicketID) AS TicketCount,
    COUNT(DISTINCT CASE WHEN mt.TicketStatus IN (N'Open', N'Assigned', N'InProgress') THEN mt.TicketID END) AS OpenTicketCount,
    COUNT(DISTINCT el.ErrorID) AS ErrorCount,
    COUNT(DISTINCT CASE WHEN el.IsActive = 1 THEN el.ErrorID END) AS ActiveErrorCount,
    AVG(CASE WHEN mt.ClosedAt IS NOT NULL THEN DATEDIFF(HOUR, mt.OpenedAt, mt.ClosedAt) END) AS AvgResolveHours
FROM Infrastructure.ChargingStation s
LEFT JOIN Maintenance.MaintenanceTicket mt ON mt.StationID = s.StationID
LEFT JOIN Maintenance.ErrorLog el ON el.StationID = s.StationID
GROUP BY s.StationCode, s.StationName;
GO

-- View: AppView.vw_PaymentSummary
CREATE OR ALTER VIEW AppView.vw_PaymentSummary
AS
SELECT
    pt.PaymentMethod,
    pt.TransactionStatus,
    COUNT(*) AS TransactionCount,
    SUM(pt.Amount) AS TotalAmount
FROM Payments.PaymentTransaction pt
GROUP BY pt.PaymentMethod, pt.TransactionStatus;
GO

-- (b) Cac REPORTING PROCEDURE (giao dien export bao cao):

-- Procedure: AppView.sp_GetStationRevenue
CREATE OR ALTER PROCEDURE AppView.sp_GetStationRevenue
    @FromDate DATE = NULL,
    @ToDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT StationCode, StationName, FranchiseName,
           SUM(CompletedSessions) AS CompletedSessions,
           SUM(TotalKWh) AS TotalKWh,
           SUM(RevenueTotal) AS RevenueTotal
    FROM AppView.vw_StationRevenueDaily
    WHERE (@FromDate IS NULL OR RevenueDate >= @FromDate)
      AND (@ToDate IS NULL OR RevenueDate <= @ToDate)
    GROUP BY StationCode, StationName, FranchiseName
    ORDER BY RevenueTotal DESC;
END;
GO

-- Procedure: AppView.sp_GetFranchiseProfitSharing
CREATE OR ALTER PROCEDURE AppView.sp_GetFranchiseProfitSharing
AS
BEGIN
    SET NOCOUNT ON;
    SELECT SettlementCode, FranchiseCode, FranchiseName, PeriodStart, PeriodEnd,
           GrossRevenue, PartnerShareAmount, PlatformShareAmount, SettlementStatus
    FROM AppView.vw_ProfitSharing
    ORDER BY PeriodEnd DESC, GrossRevenue DESC;
END;
GO

-- Procedure: AppView.sp_GetOperationalKPI
CREATE OR ALTER PROCEDURE AppView.sp_GetOperationalKPI
AS
BEGIN
    SET NOCOUNT ON;
    SELECT StationCode, StationName, TicketCount, OpenTicketCount, ErrorCount, ActiveErrorCount, AvgResolveHours
    FROM AppView.vw_MaintenanceKPI
    ORDER BY ActiveErrorCount DESC, OpenTicketCount DESC, StationCode;
END;
GO

-- Procedure: AppView.sp_GetPaymentSummary
CREATE OR ALTER PROCEDURE AppView.sp_GetPaymentSummary
AS
BEGIN
    SET NOCOUNT ON;
    SELECT PaymentMethod, TransactionStatus, TransactionCount, TotalAmount
    FROM AppView.vw_PaymentSummary
    ORDER BY TransactionStatus, PaymentMethod;
END;
GO

-- Procedure: AppView.sp_GetCustomerUsage
CREATE OR ALTER PROCEDURE AppView.sp_GetCustomerUsage
    @Top INT = 10
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP (@Top) Username, FullName,
           COUNT(SessionID) AS CompletedSessions,
           SUM(ISNULL(TotalKWh, 0)) AS TotalKWh,
           SUM(ISNULL(CostTotal, 0)) AS TotalSpend
    FROM AppView.vw_CustomerChargingHistory
    WHERE SessionStatus = N'Completed'
    GROUP BY Username, FullName
    ORDER BY TotalSpend DESC, CompletedSessions DESC;
END;
GO

-- Procedure: AppView.sp_GetTelemetryHealth
CREATE OR ALTER PROCEDURE AppView.sp_GetTelemetryHealth
AS
BEGIN
    SET NOCOUNT ON;
    SELECT s.StationCode, p.PointCode, ct.ConnectorCode,
           MAX(t.RecordedAt) AS LastRecordedAt,
           MAX(t.TemperatureC) AS MaxTemperatureC,
           SUM(CASE WHEN t.HealthStatus IN (N'Warning', N'Critical', N'Offline') THEN 1 ELSE 0 END) AS IssueSamples
    FROM Infrastructure.PointTelemetry t
    JOIN Infrastructure.ChargingPoint p ON p.PointID = t.PointID
    JOIN Infrastructure.ChargingStation s ON s.StationID = p.StationID
    JOIN Infrastructure.ConnectorType ct ON ct.ConnectorTypeID = p.ConnectorTypeID
    GROUP BY s.StationCode, p.PointCode, ct.ConnectorCode
    HAVING SUM(CASE WHEN t.HealthStatus IN (N'Warning', N'Critical', N'Offline') THEN 1 ELSE 0 END) > 0
    ORDER BY IssueSamples DESC, StationCode, PointCode;
END;
GO
