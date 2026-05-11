USE EV_Charging_System;
GO

-- ============================================================
-- Migration tracking table
-- ============================================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'SchemaMigration' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.SchemaMigration (
        MigrationID      INT IDENTITY(1,1) PRIMARY KEY,
        MigrationName    NVARCHAR(200) NOT NULL,
        ScriptName       NVARCHAR(200) NOT NULL,
        AppliedBy        NVARCHAR(100) NOT NULL DEFAULT SYSTEM_USER,
        AppliedAt        DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
        Checksum         NVARCHAR(64),
        ExecutionTimeMs  INT,
        Status           NVARCHAR(20) NOT NULL DEFAULT 'Success',
        ErrorMessage     NVARCHAR(MAX) NULL,

        CONSTRAINT UQ_MigrationName UNIQUE (MigrationName)
    );

    INSERT INTO dbo.SchemaMigration (MigrationName, ScriptName, Checksum, Status)
    VALUES ('Baseline - Initial Schema', '02_CreateTables.sql', NULL, 'Success'),
           ('Baseline - Stored Procedures', '05_CreateStoredProcedures.sql', NULL, 'Success'),
           ('Baseline - Views', '07_CreateViews.sql', NULL, 'Success'),
           ('Baseline - Analytics', '09_CreateAnalytics.sql', NULL, 'Success');

    PRINT N'SchemaMigration table created with baseline entries.';
END
ELSE
BEGIN
    PRINT N'SchemaMigration table already exists.';
END
GO

-- ============================================================
-- sp_ApplyMigration: Record a new migration
-- ============================================================
CREATE OR ALTER PROCEDURE dbo.sp_ApplyMigration
    @MigrationName NVARCHAR(200),
    @ScriptName    NVARCHAR(200),
    @Checksum      NVARCHAR(64) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM dbo.SchemaMigration WHERE MigrationName = @MigrationName)
    BEGIN
        PRINT N'Migration "' + @MigrationName + '" has already been applied. Skipping.';
        RETURN;
    END

    INSERT INTO dbo.SchemaMigration (MigrationName, ScriptName, Checksum, AppliedAt, Status)
    VALUES (@MigrationName, @ScriptName, @Checksum, SYSDATETIME(), 'Success');

    PRINT N'Migration "' + @MigrationName + '" applied successfully.';
END;
GO

-- ============================================================
-- sp_GetMigrationStatus: View migration history
-- ============================================================
CREATE OR ALTER PROCEDURE dbo.sp_GetMigrationStatus
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        MigrationID, MigrationName, ScriptName,
        AppliedBy, AppliedAt, Status,
        CASE WHEN Status = 'Success' THEN 1 ELSE 0 END AS IsApplied
    FROM dbo.SchemaMigration
    ORDER BY MigrationID;
END;
GO

PRINT N'Migration system initialized.';
GO
