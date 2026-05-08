/*==============================================================================
  EV_Charging_System_Validation - ENTERPRISE TRIGGERS
  ==============================================================================
  Patterns:  Audit logging | Status history | Immutable validation | Auto-update
  =============================================================================*/

USE EV_Charging_System_Validation;
GO

-- ===========================================================================
-- trg_ChargingPoint_StatusChange - Auto-update point status + audit
-- ===========================================================================
CREATE OR ALTER TRIGGER Infrastructure.trg_ChargingPoint_StatusChange
ON Infrastructure.ChargingPoint
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Log status changes
    INSERT INTO Audit.PointStatusHistory (PointID, PreviousStatus, NewStatus, ChangeReason, ChangedAt)
    SELECT
        i.PointID,
        d.PointStatus,
        i.PointStatus,
        N'Status changed by system trigger',
        SYSDATETIME()
    FROM inserted i
    INNER JOIN deleted d ON i.PointID = d.PointID
    WHERE i.PointStatus != d.PointStatus;

    -- Auto-create error log when point enters Error status
    INSERT INTO Monitoring.ErrorLog (PointID, StationID, ErrorCode, ErrorCategory, Severity, Title, Description, OccurredAt)
    SELECT
        i.PointID,
        s.StationID,
        N'AUTO_ERR',
        N'Hardware',
        N'Medium',
        N'Charging point entered error state',
        N'Charging point ' + i.PointCode + N' at station ' + s.StationName + N' reported an error.',
        SYSDATETIME()
    FROM inserted i
    INNER JOIN deleted d ON i.PointID = d.PointID
    JOIN Infrastructure.ChargingStation s ON i.StationID = s.StationID
    WHERE i.PointStatus = N'Error' AND d.PointStatus != N'Error';
END;
GO

-- ===========================================================================
-- trg_ChargingStation_StatusChange - Station status audit
-- ===========================================================================
CREATE OR ALTER TRIGGER Infrastructure.trg_ChargingStation_StatusChange
ON Infrastructure.ChargingStation
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Audit.StationStatusHistory (StationID, PreviousStatus, NewStatus, ChangeReason, ChangedAt)
    SELECT
        i.StationID,
        d.StationStatus,
        i.StationStatus,
        N'Status changed by system',
        SYSDATETIME()
    FROM inserted i
    INNER JOIN deleted d ON i.StationID = d.StationID
    WHERE i.StationStatus != d.StationStatus;
END;
GO

-- ===========================================================================
-- trg_ChargingSession_StatusChange - Session status audit
-- ===========================================================================
CREATE OR ALTER TRIGGER Operations.trg_ChargingSession_StatusChange
ON Operations.ChargingSession
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Audit.SessionStatusHistory (SessionID, PreviousStatus, NewStatus, ChangeReason, ChangedAt)
    SELECT
        i.SessionID,
        d.SessionStatus,
        i.SessionStatus,
        ISNULL(i.StopReason, N'Status changed'),
        SYSDATETIME()
    FROM inserted i
    INNER JOIN deleted d ON i.SessionID = d.SessionID
    WHERE i.SessionStatus != d.SessionStatus;
END;
GO

-- ===========================================================================
-- trg_Transaction_Immutable - Prevent updates to completed transactions
-- ===========================================================================
CREATE OR ALTER TRIGGER Payments.trg_Transaction_Immutable
ON Payments.[Transaction]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1 FROM inserted i
        JOIN deleted d ON i.TransactionID = d.TransactionID
        WHERE d.TransactionStatus IN (N'Completed', N'Refunded')
          AND (i.Amount != d.Amount OR i.TransactionStatus != d.TransactionStatus)
    )
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 51001, N'Cannot modify completed or refunded transactions.', 16;
    END;
END;
GO

-- ===========================================================================
-- trg_ChargingSession_PointSync - Auto-update point status on session change
-- ===========================================================================
CREATE OR ALTER TRIGGER Operations.trg_ChargingSession_PointSync
ON Operations.ChargingSession
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- When session starts (Charging), set point to Busy
    UPDATE p
    SET p.PointStatus = N'Busy', p.UpdatedAt = SYSDATETIME()
    FROM Infrastructure.ChargingPoint p
    INNER JOIN inserted i ON p.PointID = i.PointID
    WHERE i.SessionStatus = N'Charging' AND p.PointStatus = N'Available';

    -- When session completes, set point to Available
    UPDATE p
    SET p.PointStatus = N'Available', p.UpdatedAt = SYSDATETIME()
    FROM Infrastructure.ChargingPoint p
    INNER JOIN inserted i ON p.PointID = i.PointID
    INNER JOIN deleted d ON i.SessionID = d.SessionID
    WHERE i.SessionStatus IN (N'Completed', N'Cancelled', N'Failed')
      AND d.SessionStatus = N'Charging'
      AND p.PointStatus = N'Busy';
END;
GO

-- ===========================================================================
-- trg_AuditLog_Immutable - Audit logs cannot be modified
-- ===========================================================================
CREATE OR ALTER TRIGGER Audit.trg_AuditLog_Immutable
ON Audit.AuditLog
INSTEAD OF DELETE, UPDATE
AS
BEGIN
    THROW 51002, N'Audit log entries are immutable and cannot be modified or deleted.', 16;
END;
GO

-- ===========================================================================
-- trg_User_SoftDelete - Cascade soft-delete to related user data
-- ===========================================================================
CREATE OR ALTER TRIGGER Users.trg_User_SoftDelete
ON Users.[User]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- When user is soft-deleted, cascade to sessions, profiles, etc
    UPDATE Operations.ChargingSession
    SET IsDeleted = 1, DeletedAt = SYSDATETIME()
    FROM Operations.ChargingSession cs
    INNER JOIN inserted i ON cs.UserID = i.UserID
    WHERE i.IsDeleted = 1 AND cs.IsDeleted = 0;

    UPDATE Users.Vehicle
    SET IsDeleted = 1, DeletedAt = SYSDATETIME()
    FROM Users.Vehicle v
    INNER JOIN inserted i ON v.UserID = i.UserID
    WHERE i.IsDeleted = 1 AND v.IsDeleted = 0;
END;
GO

-- ===========================================================================
-- trg_SchemaChangeLog - Record DDL changes
-- ===========================================================================
CREATE OR ALTER TRIGGER Audit.trg_SchemaChangeLog_Audit
ON Audit.SchemaChangeLog
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @ChangeDescription NVARCHAR(500);

    SELECT TOP (1) @ChangeDescription = ChangeDescription
    FROM inserted;

    PRINT N'Schema change recorded: ' + ISNULL(@ChangeDescription, N'(no description)');
END;
GO

PRINT N'Enterprise triggers created successfully.';
GO

