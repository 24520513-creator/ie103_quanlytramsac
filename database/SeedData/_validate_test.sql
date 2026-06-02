/* Kiem thu co lap: nap CSV vao DB tam EV_SeedTest roi kiem tra. */
SET NOCOUNT ON;
SET XACT_ABORT ON;
IF DB_ID('EV_SeedTest') IS NOT NULL
BEGIN
    ALTER DATABASE EV_SeedTest SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE EV_SeedTest;
END
CREATE DATABASE EV_SeedTest;
ALTER DATABASE EV_SeedTest SET RECOVERY SIMPLE;
GO
USE EV_SeedTest;
GO
CREATE SCHEMA Core;
GO
CREATE SCHEMA [Identity];
GO
CREATE SCHEMA Infrastructure;
GO

CREATE TABLE Core.Region (
    RegionID INT IDENTITY PRIMARY KEY, RegionCode NVARCHAR(20), RegionName NVARCHAR(100),
    TimeZone NVARCHAR(60), IsActive BIT);
CREATE TABLE [Identity].UserAccount (
    UserID INT IDENTITY PRIMARY KEY, Username NVARCHAR(50), Email NVARCHAR(120), Phone NVARCHAR(20) NULL,
    PasswordHash NVARCHAR(256), FullName NVARCHAR(120), AccountStatus NVARCHAR(20),
    LastLoginAt DATETIME2 NULL, CreatedAt DATETIME2, UpdatedAt DATETIME2 NULL);
CREATE TABLE Core.Address (
    AddressID INT IDENTITY PRIMARY KEY, RegionID INT, StreetAddress NVARCHAR(255),
    Ward NVARCHAR(100) NULL, District NVARCHAR(100) NULL, Latitude DECIMAL(10,7) NULL, Longitude DECIMAL(10,7) NULL,
    FullAddress AS ((COALESCE(StreetAddress+N', ',N'')+COALESCE(Ward+N', ',N''))+COALESCE(District,N'')),
    CreatedAt DATETIME2);
CREATE TABLE Infrastructure.PointTelemetry (
    TelemetryID BIGINT IDENTITY PRIMARY KEY, PointID INT, Voltage DECIMAL(8,2) NULL, CurrentAmp DECIMAL(8,2) NULL,
    TemperatureC DECIMAL(5,2) NULL, PowerKW DECIMAL(8,2) NULL, HealthStatus NVARCHAR(20), RecordedAt DATETIME2);
GO

DECLARE @D NVARCHAR(4000) = N'C:\Users\hocvi\OneDrive\Documents\Study\IE103_QuanLyThongTin\SourceCode\database\SeedData';
DECLARE @sql NVARCHAR(MAX);

-- Region (truc tiep, identity)
SET @sql = N'BULK INSERT Core.Region FROM ''' + @D + N'\Core.Region.csv'' WITH (FORMAT=''CSV'',FIRSTROW=2,FIELDQUOTE=''"'',FIELDTERMINATOR='','',ROWTERMINATOR=''0x0d0a'',CODEPAGE=''65001'',KEEPNULLS,TABLOCK,KEEPIDENTITY);';
EXEC sp_executesql @sql;

-- UserAccount (tieng Viet + NULL datetime)
SET @sql = N'BULK INSERT [Identity].UserAccount FROM ''' + @D + N'\Identity.UserAccount.csv'' WITH (FORMAT=''CSV'',FIRSTROW=2,FIELDQUOTE=''"'',FIELDTERMINATOR='','',ROWTERMINATOR=''0x0d0a'',CODEPAGE=''65001'',KEEPNULLS,TABLOCK,KEEPIDENTITY);';
EXEC sp_executesql @sql;

-- Address (co cot computed -> staging)
CREATE TABLE #stg_Address ([AddressID] int,[RegionID] int,[StreetAddress] nvarchar(255),[Ward] nvarchar(100),[District] nvarchar(100),[Latitude] decimal(10,7),[Longitude] decimal(10,7),[CreatedAt] datetime2(7));
SET @sql = N'BULK INSERT #stg_Address FROM ''' + @D + N'\Core.Address.csv'' WITH (FORMAT=''CSV'',FIRSTROW=2,FIELDQUOTE=''"'',FIELDTERMINATOR='','',ROWTERMINATOR=''0x0d0a'',CODEPAGE=''65001'',KEEPNULLS,TABLOCK);';
EXEC sp_executesql @sql;
SET IDENTITY_INSERT Core.Address ON;
INSERT INTO Core.Address (AddressID,RegionID,StreetAddress,Ward,District,Latitude,Longitude,CreatedAt)
SELECT AddressID,RegionID,StreetAddress,Ward,District,Latitude,Longitude,CreatedAt FROM #stg_Address;
SET IDENTITY_INSERT Core.Address OFF;
DROP TABLE #stg_Address;

-- PointTelemetry (lon 300k, bigint identity, decimals + NULL)
SET @sql = N'BULK INSERT Infrastructure.PointTelemetry FROM ''' + @D + N'\Infrastructure.PointTelemetry.csv'' WITH (FORMAT=''CSV'',FIRSTROW=2,FIELDQUOTE=''"'',FIELDTERMINATOR='','',ROWTERMINATOR=''0x0d0a'',CODEPAGE=''65001'',KEEPNULLS,TABLOCK,KEEPIDENTITY);';
EXEC sp_executesql @sql;
GO

PRINT '--- KET QUA ---';
SELECT 'Region' tbl, COUNT(*) rows FROM Core.Region
UNION ALL SELECT 'UserAccount', COUNT(*) FROM [Identity].UserAccount
UNION ALL SELECT 'Address', COUNT(*) FROM Core.Address
UNION ALL SELECT 'PointTelemetry', COUNT(*) FROM Infrastructure.PointTelemetry;

PRINT '--- Kiem tra tieng Viet + NULL + datetime ---';
SELECT UserID, Username, FullName, Phone, LastLoginAt FROM [Identity].UserAccount WHERE UserID IN (1,2);
PRINT '--- Computed FullAddress tu cot da nap ---';
SELECT TOP 2 AddressID, StreetAddress, District, FullAddress FROM Core.Address ORDER BY AddressID;
PRINT '--- Max identity (kiem tra KEEPIDENTITY) ---';
SELECT MAX(TelemetryID) AS MaxTelemetryID, MIN(RecordedAt) AS MinTime, MAX(RecordedAt) AS MaxTime FROM Infrastructure.PointTelemetry;
GO
USE master;
GO
ALTER DATABASE EV_SeedTest SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
DROP DATABASE EV_SeedTest;
GO
PRINT '>>> Test DB da xoa.';
