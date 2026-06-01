/*
  BonusSQL - Web pricing policy actions
  Purpose:
    - Add a web-only activation procedure for inactive pricing policies.
    - Keep the original database scripts unchanged.
  Adds:
    - AppView.sp_ActivatePricingPolicy
    - EXECUTE grant for db_ev_business_manager
*/

USE EV_Charging_System;
GO

CREATE OR ALTER PROCEDURE AppView.sp_ActivatePricingPolicy
    @PolicyID INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRAN;

        IF NOT EXISTS (
            SELECT 1
            FROM Operations.PricingPolicy
            WHERE PolicyID = @PolicyID
        )
            THROW 57001, 'Pricing policy does not exist.', 1;

        IF NOT EXISTS (
            SELECT 1
            FROM Operations.PricingPolicy
            WHERE PolicyID = @PolicyID
              AND IsActive = 0
        )
            THROW 57002, 'Pricing policy is already active.', 1;

        UPDATE Operations.PricingPolicy
        SET IsActive = 1
        WHERE PolicyID = @PolicyID;

        INSERT INTO Audit.AuditLog (SchemaName, TableName, RecordID, ActionType, NewValues)
        VALUES (N'Operations', N'PricingPolicy', CAST(@PolicyID AS NVARCHAR(100)), N'UPDATE', N'Active');

        COMMIT;

        SELECT PolicyID, PolicyCode, PolicyName, IsActive
        FROM Operations.PricingPolicy
        WHERE PolicyID = @PolicyID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END;
GO

GRANT EXECUTE ON OBJECT::AppView.sp_ActivatePricingPolicy TO db_ev_business_manager;
GO
