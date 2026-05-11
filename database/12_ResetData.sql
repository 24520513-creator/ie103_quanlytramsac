USE EV_Charging_System;
GO

PRINT N'============================================================';
PRINT N' Phase 1: Safe Database Reset';
PRINT N' Preserves schema, SPs, triggers, views, indexes, policies';
PRINT N'============================================================';
GO

BEGIN TRY
    BEGIN TRANSACTION;

    PRINT N'Disabling foreign key constraints...';

    DECLARE @sql NVARCHAR(MAX) = N'';
    SELECT @sql = @sql +
        'ALTER TABLE ' + QUOTENAME(SCHEMA_NAME(schema_id)) + '.' + QUOTENAME(name) + ' NOCHECK CONSTRAINT ALL;' + CHAR(13)
    FROM sys.foreign_keys;
    EXEC sp_executesql @sql;

    PRINT N'Deleting data in FK-safe order...';

    DELETE FROM dbo.RealtimeEvent;
    DELETE FROM Reporting.KPISnapshotDaily;
    DELETE FROM Reporting.KPISnapshotHourly;
    DELETE FROM Payments.WalletTransaction;
    DELETE FROM Payments.[Transaction];
    DELETE FROM Payments.Wallet;
    DELETE FROM Operations.StationReview;
    DELETE FROM Operations.MaintenanceSchedule;
    DELETE FROM Operations.ChargingSession;
    DELETE FROM Operations.Booking;
    DELETE FROM Infrastructure.PointStatusLog;
    DELETE FROM Infrastructure.ErrorLog;
    DELETE FROM Users.Notification;
    DELETE FROM Users.Vehicle;
    DELETE FROM Users.[User];
    DELETE FROM Infrastructure.ChargingPoint;
    DELETE FROM Infrastructure.ChargingStation;
    DELETE FROM Infrastructure.ElectricitySupplier;
    DELETE FROM Infrastructure.Franchise;
    DELETE FROM Infrastructure.Address;
    DELETE FROM Infrastructure.Region;
    DELETE FROM Infrastructure.Country;

    PRINT N'Re-enabling foreign key constraints...';

    SET @sql = N'';
    SELECT @sql = @sql +
        'ALTER TABLE ' + QUOTENAME(SCHEMA_NAME(schema_id)) + '.' + QUOTENAME(name) + ' WITH CHECK CHECK CONSTRAINT ALL;' + CHAR(13)
    FROM sys.foreign_keys;
    EXEC sp_executesql @sql;

    PRINT N'Resetting identity seeds...';

    DBCC CHECKIDENT ('Infrastructure.Country', RESEED, 0);
    DBCC CHECKIDENT ('Infrastructure.Region', RESEED, 0);
    DBCC CHECKIDENT ('Infrastructure.Address', RESEED, 0);
    DBCC CHECKIDENT ('Infrastructure.Franchise', RESEED, 0);
    DBCC CHECKIDENT ('Infrastructure.ElectricitySupplier', RESEED, 0);
    DBCC CHECKIDENT ('Infrastructure.ChargingStation', RESEED, 0);
    DBCC CHECKIDENT ('Infrastructure.ChargingPoint', RESEED, 0);
    DBCC CHECKIDENT ('Infrastructure.PointStatusLog', RESEED, 0);
    DBCC CHECKIDENT ('Infrastructure.ErrorLog', RESEED, 0);
    DBCC CHECKIDENT ('Users.[User]', RESEED, 0);
    DBCC CHECKIDENT ('Users.Vehicle', RESEED, 0);
    DBCC CHECKIDENT ('Users.Notification', RESEED, 0);
    DBCC CHECKIDENT ('Operations.PricingPolicy', RESEED, 0);
    DBCC CHECKIDENT ('Operations.Booking', RESEED, 0);
    DBCC CHECKIDENT ('Operations.ChargingSession', RESEED, 0);
    DBCC CHECKIDENT ('Operations.MaintenanceSchedule', RESEED, 0);
    DBCC CHECKIDENT ('Operations.StationReview', RESEED, 0);
    DBCC CHECKIDENT ('Payments.Wallet', RESEED, 0);
    DBCC CHECKIDENT ('Payments.[Transaction]', RESEED, 0);
    DBCC CHECKIDENT ('Payments.WalletTransaction', RESEED, 0);
    DBCC CHECKIDENT ('dbo.RealtimeEvent', RESEED, 0);
    DBCC CHECKIDENT ('Reporting.KPISnapshotHourly', RESEED, 0);
    DBCC CHECKIDENT ('Reporting.KPISnapshotDaily', RESEED, 0);

    COMMIT TRANSACTION;

    PRINT N'';
    PRINT N'============================================================';
    PRINT N' Reset completed successfully!';
    PRINT N' All data deleted, identity seeds reset.';
    PRINT N' Schema, SPs, triggers, views, indexes preserved.';
    PRINT N'============================================================';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
    DECLARE @ErrorState INT = ERROR_STATE();

    PRINT N'';
    PRINT N'============================================================';
    PRINT N' RESET FAILED!';
    PRINT N' Error: ' + @ErrorMessage;
    PRINT N' All changes rolled back.';
    PRINT N'============================================================';

    THROW;
END CATCH;
GO
