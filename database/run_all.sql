/*==============================================================================
  EV_Charging_System - MASTER DEPLOYMENT ORCHESTRATOR
  ==============================================================================
  Version:    2.0.0 (Enterprise Redesign)
  Execution:  Requires SQLCMD Mode in SSMS because it uses :r includes.
  Warning:    This will DROP existing EV_Charging_System if it exists.
  =============================================================================*/

PRINT N'============================================================';
PRINT N'  EV_Charging_System - Enterprise Database Deployment';
PRINT N'  Version 2.0.0 - 48 Tables | 9 Schemas | RBAC | Analytics';
PRINT N'============================================================';
GO

-- Step 1: Create Database + Schemas
PRINT N'[01/12] Creating database and domain schemas...';
:r .\schema\01_CreateDatabase.sql

-- Step 2: Create All Tables
PRINT N'[02/12] Creating 48 enterprise tables...';
:r .\schema\02_CreateTables.sql

-- Step 3: Create Indexes
PRINT N'[03/12] Creating indexes and partitioning strategy...';
:r .\indexes\03_CreateIndexes.sql

-- Step 4: RBAC & Security
PRINT N'[04/12] Deploying RBAC, permissions, and security...';
:r .\security\04_RBAC_And_Security.sql

-- Step 5: Seed Data
PRINT N'[05/12] Inserting seed and reference data...';
:r .\seed\05_SeedData.sql

-- Step 6: Functions
PRINT N'[06/12] Creating business logic functions...';
:r .\functions\06_CreateFunctions.sql

-- Step 7: Stored Procedures
PRINT N'[07/12] Creating enterprise stored procedures...';
:r .\procedures\07_CreateStoredProcedures.sql

-- Step 8: Triggers
PRINT N'[08/12] Creating audit and automation triggers...';
:r .\triggers\08_CreateTriggers.sql

-- Step 9: Views
PRINT N'[09/12] Creating reporting and analytics views...';
:r .\views\09_CreateViews.sql

-- Step 10: Analytics Objects
PRINT N'[10/12] Creating materialized views and KPI procedures...';
:r .\analytics\10_AnalyticsObjects.sql

-- Step 11: Report Queries
PRINT N'[11/12] Running enterprise report queries (validation)...';
:r .\reporting\11_ReportQueries.sql

-- Step 12: Backup & DR
PRINT N'[12/12] Configuring backup and disaster recovery...';
:r .\backup\12_BackupAndDR.sql

PRINT N'============================================================';
PRINT N'  EV_Charging_System DEPLOYMENT COMPLETED SUCCESSFULLY!';
PRINT N'============================================================';
PRINT N'  Schemas:     9';
PRINT N'  Tables:      48';
PRINT N'  Indexes:     40+';
PRINT N'  Roles:       7';
PRINT N'  Permissions: 40+';
PRINT N'  Views:       10+';
PRINT N'  Procedures:  10+';
PRINT N'  Triggers:    8+';
PRINT N'============================================================';
GO
