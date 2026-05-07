/*=============================================================================
  EV_Charging_System - BACKUP & RESTORE SCRIPTS
  =============================================================================*/

USE EV_Charging_System;
GO

-- ========================================
-- Ensure backup directory exists
-- ========================================
EXEC sys.xp_create_subdir N'C:\Backup';

-- ========================================
-- Ensure database is in FULL recovery model for log backups
-- ========================================
ALTER DATABASE EV_Charging_System SET RECOVERY FULL;
GO

-- ========================================
-- Full Database Backup
-- ========================================
BACKUP DATABASE EV_Charging_System
TO DISK = N'C:\Backup\EV_Charging_System_Full.bak'
WITH
    NAME = N'EV_Charging_System - Full Backup',
    DESCRIPTION = N'Full database backup of EV Charging System',
    INIT,
    STATS = 10;
GO

-- ========================================
-- Differential Backup
-- ========================================
BACKUP DATABASE EV_Charging_System
TO DISK = N'C:\Backup\EV_Charging_System_Diff.bak'
WITH
    DIFFERENTIAL,
    NAME = N'EV_Charging_System - Differential Backup',
    DESCRIPTION = N'Differential backup (changes since last full backup)',
    INIT,
    STATS = 10;
GO

-- ========================================
-- Transaction Log Backup
-- ========================================
BACKUP LOG EV_Charging_System
TO DISK = N'C:\Backup\EV_Charging_System_Log.trn'
WITH
    NAME = N'EV_Charging_System - Transaction Log Backup',
    DESCRIPTION = N'Transaction log backup',
    INIT,
    STATS = 10;
GO

-- ========================================
-- RESTORE SCRIPTS (commented for safety)
-- ========================================

/*
-- === Restore from Full Backup Only ===
-- NOTE: Replace data/log paths with your SQL Server instance paths.
-- Find paths with: EXEC sys.sp_helpfile;
RESTORE DATABASE EV_Charging_System
FROM DISK = N'C:\Backup\EV_Charging_System_Full.bak'
WITH
    FILE = 1,
    MOVE N'EV_Charging_System' TO N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\EV_Charging_System.mdf',
    MOVE N'EV_Charging_System_log' TO N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\EV_Charging_System_log.ldf',
    REPLACE,
    STATS = 10;
*/

/*
-- === Restore with Differential + Log (point-in-time) ===
RESTORE DATABASE EV_Charging_System
FROM DISK = N'C:\Backup\EV_Charging_System_Full.bak'
WITH NORECOVERY, STATS = 10;

RESTORE DATABASE EV_Charging_System
FROM DISK = N'C:\Backup\EV_Charging_System_Diff.bak'
WITH NORECOVERY, STATS = 10;

RESTORE LOG EV_Charging_System
FROM DISK = N'C:\Backup\EV_Charging_System_Log.trn'
WITH RECOVERY, STATS = 10;
*/

PRINT N'Backup scripts completed.';
GO
