-- ============================================================
-- Migration: Add CancelledByUser to CK_ChargingSession_StopReason
-- ============================================================
USE EV_Charging_System;
GO

ALTER TABLE Operations.ChargingSession DROP CONSTRAINT CK_ChargingSession_StopReason;
GO

ALTER TABLE Operations.ChargingSession ADD CONSTRAINT CK_ChargingSession_StopReason
    CHECK (StopReason IS NULL OR StopReason IN ('Completed', 'UserStopped', 'PaymentFailed', 'Error', 'Timeout', 'EmergencyStop', 'Maintenance', 'CancelledByUser', 'Other'));
GO

PRINT 'CK_ChargingSession_StopReason updated successfully.';
GO
