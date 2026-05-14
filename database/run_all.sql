:ON ERROR EXIT
:Error STDOUT
SET NOCOUNT ON;
GO

PRINT N'============================================================';
PRINT N' EV_Charging_System independent database setup';
PRINT N' Run in SSMS with SQLCMD Mode enabled';
PRINT N'============================================================';
GO

:r .\00_Drop_And_Create_Database.sql
:r .\01_Create_Schemas.sql
:r .\02_Create_Tables.sql
:r .\03_Create_Constraints_Indexes.sql
:r .\04_Create_Functions.sql
:r .\05_Create_Stored_Procedures.sql
:r .\06_Create_Triggers.sql
:r .\07_Create_Reporting.sql
:r .\08_Create_Security.sql
:r .\09_Seed_Demo_Data.sql
:r .\10_Demo_Queries.sql
:r .\11_Test_Roles.sql

PRINT N'============================================================';
PRINT N' EV_Charging_System setup completed successfully.';
PRINT N'============================================================';
GO
