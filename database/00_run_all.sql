:setvar SqlCmdErrorIgnoreErrors

PRINT N'============================================';
PRINT N' EV_Charging_System - Database Installation';
PRINT N'============================================';

:r .\01_CreateDatabase.sql
:r .\02_CreateTables.sql
:r .\03_SeedData.sql
:r .\04_CreateFunctions.sql
:r .\05_CreateStoredProcedures.sql
:r .\06_CreateTriggers.sql
:r .\07_CreateViews.sql

PRINT N'';
PRINT N'============================================';
PRINT N' Installation completed successfully!';
PRINT N'============================================';
GO
