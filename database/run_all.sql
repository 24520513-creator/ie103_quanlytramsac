/*=============================================================================
  EV_Charging_System - MASTER RUNNER SCRIPT
  Executes all scripts in the correct dependency order.
  =============================================================================*/

PRINT N'============================================================';
PRINT N'  EV_Charging_System - Database Deployment';
PRINT N'============================================================';
GO

-- Step 1: Create Database + Schemas
PRINT N'[1/11] Creating database and schemas...';
:r .\schema\01_CreateDatabase.sql

-- Step 2: Create Tables
PRINT N'[2/11] Creating tables...';
:r .\schema\02_CreateTables.sql

-- Step 3: Create Indexes
PRINT N'[3/11] Creating indexes...';
:r .\indexes\03_CreateIndexes.sql

-- Step 4: Seed Data
PRINT N'[4/11] Inserting seed data...';
:r .\seed\04_SeedData.sql

-- Step 5: Create Functions
PRINT N'[5/11] Creating functions...';
:r .\functions\05_CreateFunctions.sql

-- Step 6: Create Stored Procedures
PRINT N'[6/11] Creating stored procedures...';
:r .\stored_procedures\06_CreateStoredProcedures.sql

-- Step 7: Create Triggers
PRINT N'[7/11] Creating triggers...';
:r .\triggers\07_CreateTriggers.sql

-- Step 8: Create Views
PRINT N'[8/11] Creating views...';
:r .\views\08_CreateViews.sql

-- Step 9: Security Setup
PRINT N'[9/11] Configuring security...';
:r .\security\09_SecuritySetup.sql

-- Step 10: Run Report Queries
PRINT N'[10/11] Running report queries...';
:r .\reports\10_ReportQueries.sql

-- Step 11: Backup Scripts
PRINT N'[11/11] Running backup scripts...';
:r .\backup\11_BackupRestore.sql

PRINT N'============================================================';
PRINT N'  EV_Charging_System deployment completed successfully!';
PRINT N'============================================================';
GO
