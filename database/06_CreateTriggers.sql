USE EV_Charging_System;
GO

-- ============================================================
-- trg_ChargingPoint_StatusChange: Log point status changes
-- ============================================================
CREATE OR ALTER TRIGGER Infrastructure.trg_ChargingPoint_StatusChange
ON Infrastructure.ChargingPoint
AFTER UPDATE
AS
IF UPDATE(PointStatus)
BEGIN
    SET NOCOUNT ON;
    INSERT INTO Infrastructure.PointStatusLog (PointID, OldStatus, NewStatus, ChangedAt)
    SELECT d.PointID, d.PointStatus, i.PointStatus, SYSDATETIME()
    FROM deleted d JOIN inserted i ON d.PointID = i.PointID
    WHERE d.PointStatus != i.PointStatus;
END;
GO

-- Create log table for point status changes
CREATE TABLE Infrastructure.PointStatusLog
(
    LogID      BIGINT IDENTITY(1,1) PRIMARY KEY,
    PointID    INT NOT NULL FOREIGN KEY REFERENCES Infrastructure.ChargingPoint(PointID),
    OldStatus  NVARCHAR(20) NOT NULL,
    NewStatus  NVARCHAR(20) NOT NULL,
    ChangedAt  DATETIME2 NOT NULL DEFAULT SYSDATETIME()
);
GO

PRINT N'Triggers created.';
GO
