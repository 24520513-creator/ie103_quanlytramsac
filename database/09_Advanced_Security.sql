USE EV_Charging_System;
GO

/*
Advanced SQL Server security demo.

Run after database/08_Create_Security.sql if you want to demonstrate features
beyond the core DCL/RBAC requirements of the course.

Core security is kept in 08_Create_Security.sql:
- CREATE USER
- CREATE ROLE
- GRANT
- DENY
- role membership

This script currently enables Dynamic Data Masking for sensitive identity data.
Row-Level Security, audit-log protection, and SQL Authentication login demos are
kept as separate feature scripts under database/features/security.
*/

IF NOT EXISTS (
    SELECT 1
    FROM sys.masked_columns
    WHERE object_id = OBJECT_ID(N'Identity.UserAccount')
      AND name = N'Email'
      AND is_masked = 1
)
BEGIN
    ALTER TABLE [Identity].UserAccount ALTER COLUMN Email ADD MASKED WITH (FUNCTION = 'email()');
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.masked_columns
    WHERE object_id = OBJECT_ID(N'Identity.UserAccount')
      AND name = N'Phone'
      AND is_masked = 1
)
BEGIN
    ALTER TABLE [Identity].UserAccount ALTER COLUMN Phone ADD MASKED WITH (FUNCTION = 'partial(0,"XXXX",4)');
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.masked_columns
    WHERE object_id = OBJECT_ID(N'Identity.UserAccount')
      AND name = N'PasswordHash'
      AND is_masked = 1
)
BEGIN
    ALTER TABLE [Identity].UserAccount ALTER COLUMN PasswordHash ADD MASKED WITH (FUNCTION = 'default()');
END;
GO

GRANT UNMASK TO db_ev_system_admin;
GO

PRINT N'09 - Advanced security features created: Dynamic Data Masking.';
GO
