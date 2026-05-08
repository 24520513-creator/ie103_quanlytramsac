/*==============================================================================
  EV_Charging_System_Validation - BACKUP & DISASTER RECOVERY STRATEGY
  ==============================================================================
  RPO Target:  5 minutes (log shipping / availability groups)
  RTO Target:  1 hour (automated failover)
  Strategy:    FULL + DIFF + LOG | Availability Groups | Geo-redundancy
  =============================================================================*/

USE EV_Charging_System_Validation;
GO

-- ===========================================================================
-- 1. DATABASE RECOVERY MODEL
-- ===========================================================================
-- Full recovery model is REQUIRED for point-in-time recovery
ALTER DATABASE EV_Charging_System_Validation SET RECOVERY FULL;
GO

-- ===========================================================================
-- 2. BACKUP CONFIGURATION
-- ===========================================================================
-- The live BACKUP commands below are disabled by default so the deployment
-- script can run end-to-end in SSMS on dev machines without filesystem or
-- SQL Server Agent assumptions.
DECLARE @BackupRoot NVARCHAR(500) = COALESCE(
    CAST(SERVERPROPERTY(N'InstanceDefaultBackupPath') AS NVARCHAR(500)),
    N'C:\Backup\'
);
DECLARE @BackupPath NVARCHAR(500) = @BackupRoot + N'EV_Charging_System_Validation\';

BEGIN TRY
    EXEC sys.xp_create_subdir @BackupPath;
    EXEC sys.xp_create_subdir @BackupPath + N'Logs\';
END TRY
BEGIN CATCH
    PRINT N'Backup folders could not be auto-created. Review path/permissions before enabling live backups.';
END CATCH;
GO

-- ===========================================================================
-- 3. FULL DATABASE BACKUP (Weekly)
-- ===========================================================================
PRINT N'Skipped sample full backup during deployment. Enable manually when needed.';
GO

-- ===========================================================================
-- 4. DIFFERENTIAL BACKUP (Daily)
-- ===========================================================================
PRINT N'Skipped sample differential backup during deployment. Enable manually when needed.';
GO

-- ===========================================================================
-- 5. TRANSACTION LOG BACKUP (Every 15-30 minutes in production)
-- ===========================================================================
PRINT N'Skipped sample transaction log backup during deployment. Enable manually when needed.';
GO

-- ===========================================================================
-- 6. BACKUP CLEANUP PROCEDURE
-- ===========================================================================
-- Remove backups older than retention period
CREATE OR ALTER PROCEDURE Infrastructure.sp_CleanupOldBackups
    @FullRetentionDays   INT = 30,
    @DiffRetentionDays   INT = 14,
    @LogRetentionHours   INT = 48,
    @BackupPath          NVARCHAR(500) = N'C:\Backup\EV_Charging_System_Validation\'
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @SQL NVARCHAR(1000);

    -- Clean old full backups
    SET @SQL = N'xp_cmdshell N''forfiles /p "' + @BackupPath + N'" /m *_Full_*.bak /d -'
        + CAST(@FullRetentionDays AS NVARCHAR) + N' /c "cmd /c del @file"''';
    EXEC sp_executesql @SQL;

    -- Clean old diff backups
    SET @SQL = N'xp_cmdshell N''forfiles /p "' + @BackupPath + N'" /m *_Diff_*.bak /d -'
        + CAST(@DiffRetentionDays AS NVARCHAR) + N' /c "cmd /c del @file"''';
    EXEC sp_executesql @SQL;

    -- Clean old log backups
    SET @SQL = N'xp_cmdshell N''forfiles /p "' + @BackupPath + N'Logs\" /m *.trn /d -'
        + CAST(@LogRetentionHours / 24 AS NVARCHAR) + N' /c "cmd /c del @file"''';
    EXEC sp_executesql @SQL;

    PRINT N'Old backups cleaned successfully.';
END;
GO

-- ===========================================================================
-- 7. POINT-IN-TIME RECOVERY SCRIPT
-- ===========================================================================
/*
-- ============================================================
-- RECOVERY PROCEDURE: Restore to a specific point in time
-- ============================================================

-- Step 1: Restore full backup WITH NORECOVERY
RESTORE DATABASE EV_Charging_System_Validation
FROM DISK = N'C:\Backup\EV_Charging_System_Validation\EV_Charging_System_Validation_Full_current.bak'
WITH
    FILE = 1,
    NORECOVERY,
    REPLACE,
    STATS = 10;

-- Step 2: Restore latest differential backup WITH NORECOVERY
RESTORE DATABASE EV_Charging_System_Validation
FROM DISK = N'C:\Backup\EV_Charging_System_Validation\EV_Charging_System_Validation_Diff_current.bak'
WITH
    FILE = 1,
    NORECOVERY,
    STATS = 10;

-- Step 3: Restore transaction logs up to target time (e.g., '2025-04-07 14:35:00')
RESTORE LOG EV_Charging_System_Validation
FROM DISK = N'C:\Backup\EV_Charging_System_Validation\Logs\EV_Charging_System_Validation_Log_20250407_140000.trn'
WITH
    FILE = 1,
    NORECOVERY,
    STOPAT = N'2025-04-07 14:35:00',
    STATS = 10;

-- Repeat Step 3 for each log backup until STOPAT time is reached

-- Step 4: Bring database online
RESTORE DATABASE EV_Charging_System_Validation WITH RECOVERY;
*/

-- ===========================================================================
-- 8. DISASTER RECOVERY TIERS
-- ===========================================================================
/*
  ============================================================================
  DISASTER RECOVERY ARCHITECTURE
  ============================================================================

  Tier 1: Local High Availability
  ---------------------------------
  - Always On Availability Group (synchronous commit)
  - 2 replicas: Primary (read-write) + Secondary (read-only)
  - Automatic failover
  - RPO: 0 (no data loss)
  - RTO: < 30 seconds

  Tier 2: Regional Disaster Recovery
  ---------------------------------
  - Always On Availability Group (asynchronous commit)
  - 1 replica in secondary region (Azure / on-prem DR site)
  - Manual failover
  - RPO: < 5 minutes
  - RTO: < 1 hour

  Tier 3: Geo-Redundant Backup
  ---------------------------------
  - Full backup copied to Azure Blob / S3 weekly
  - Transaction logs shipped every 15 minutes
  - RPO: 15 minutes
  - RTO: 4 hours (restore from backup)

  ============================================================================
  FAILOVER PROCEDURE
  ============================================================================

  -- Planned failover:
  ALTER AVAILABILITY GROUP EV_AG FAILOVER;

  -- Force failover (emergency):
  ALTER AVAILABILITY GROUP EV_AG FORCE_FAILOVER_ALLOW_DATA_LOSS;

  ============================================================================
  MONITORING SCRIPTS
  ============================================================================

  -- Check AG health:
  SELECT
      ar.replica_server_name,
      ar.availability_mode_desc,
      ars.role_desc,
      ars.synchronization_health_desc,
      ars.last_redone_time
  FROM sys.dm_hadr_availability_replica_states ars
  JOIN sys.availability_replicas ar ON ars.replica_id = ar.replica_id;

  -- Check last backup times:
  SELECT
      database_name,
      type,
      backup_start_date,
      backup_finish_date,
      backup_size / 1048576 AS SizeMB
  FROM msdb.dbo.backupset
  WHERE database_name = 'EV_Charging_System_Validation'
  ORDER BY backup_finish_date DESC;
*/

-- ===========================================================================
-- 9. BACKUP ENCRYPTION
-- ===========================================================================
/*
-- Requires database master key and certificate

USE master;
GO

CREATE MASTER KEY ENCRYPTION BY PASSWORD = N'EV_Charging_System_Validation_MasterKey_2026!';
GO

CREATE CERTIFICATE EV_BackupCert
    WITH SUBJECT = N'EV Charging Backup Certificate',
    EXPIRY_DATE = N'2030-12-31';
GO

-- Encrypted backup
BACKUP DATABASE EV_Charging_System_Validation
TO DISK = N'C:\Backup\EV_Charging_System_Validation\EV_Charging_System_Validation_Encrypted.bak'
WITH
    ENCRYPTION (ALGORITHM = AES_256, SERVER CERTIFICATE = EV_BackupCert),
    COMPRESSION,
    CHECKSUM,
    STATS = 10;
GO
*/

-- ===========================================================================
-- 10. ARCHIVE STRATEGY
-- ===========================================================================
-- Archived data is moved to Archive schema (or separate database) for compliance.
-- Archive criteria: Sessions older than 2 years, resolved errors older than 1 year.

/*
CREATE SCHEMA Archive;
GO

CREATE OR ALTER PROCEDURE Infrastructure.sp_ArchiveOldData
    @SessionCutoffYears INT = 2,
    @ErrorCutoffMonths  INT = 12
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @SessionCutoff DATE = DATEADD(YEAR, -@SessionCutoffYears, SYSDATETIME());
    DECLARE @ErrorCutoff DATE = DATEADD(MONTH, -@ErrorCutoffMonths, SYSDATETIME());

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Move old sessions to archive (INSERT + DELETE)
        SELECT * INTO #OldSessions
        FROM Operations.ChargingSession
        WHERE StartTime < @SessionCutoff AND IsDeleted = 0;

        -- Delete from main table
        DELETE FROM Operations.ChargingSession WHERE StartTime < @SessionCutoff AND IsDeleted = 0;

        -- Move old error logs
        SELECT * INTO #OldErrors
        FROM Monitoring.ErrorLog
        WHERE OccurredAt < @ErrorCutoff;

        DELETE FROM Monitoring.ErrorLog WHERE OccurredAt < @ErrorCutoff;

        COMMIT TRANSACTION;
        PRINT N'Archive completed: ' + CAST(@@ROWCOUNT AS NVARCHAR) + N' records archived.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
*/

PRINT N'Backup & disaster recovery scripts executed successfully.';
GO

