USE EV_Charging_System;
GO

CREATE OR ALTER TRIGGER Infrastructure.trg_ChargingPoint_StatusHistory
ON Infrastructure.ChargingPoint
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Infrastructure.PointStatusHistory (PointID, OldStatus, NewStatus, ChangedAt)
    SELECT i.PointID, d.PointStatus, i.PointStatus, SYSDATETIME()
    FROM inserted i
    JOIN deleted d ON d.PointID = i.PointID
    WHERE i.PointStatus <> d.PointStatus;

    INSERT INTO Audit.AuditLog (SchemaName, TableName, RecordID, ActionType, OldValues, NewValues)
    SELECT N'Infrastructure', N'ChargingPoint', CAST(i.PointID AS NVARCHAR(100)), N'UPDATE',
           d.PointStatus, i.PointStatus
    FROM inserted i
    JOIN deleted d ON d.PointID = i.PointID
    WHERE i.PointStatus <> d.PointStatus;
END;
GO

CREATE OR ALTER TRIGGER Operations.trg_ChargingSession_Audit
ON Operations.ChargingSession
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Audit.AuditLog (SchemaName, TableName, RecordID, ActionType, OldValues, NewValues)
    SELECT N'Operations', N'ChargingSession', CAST(i.SessionID AS NVARCHAR(100)),
           CASE WHEN d.SessionID IS NULL THEN N'INSERT' ELSE N'UPDATE' END,
           d.SessionStatus,
           i.SessionStatus
    FROM inserted i
    LEFT JOIN deleted d ON d.SessionID = i.SessionID
    WHERE d.SessionID IS NULL OR i.SessionStatus <> d.SessionStatus;
END;
GO

CREATE OR ALTER TRIGGER Payments.trg_PaymentTransaction_Audit
ON Payments.PaymentTransaction
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Audit.AuditLog (SchemaName, TableName, RecordID, ActionType, OldValues, NewValues)
    SELECT N'Payments', N'PaymentTransaction', CAST(i.TransactionID AS NVARCHAR(100)),
           CASE WHEN d.TransactionID IS NULL THEN N'INSERT' ELSE N'PAYMENT' END,
           d.TransactionStatus,
           i.TransactionStatus
    FROM inserted i
    LEFT JOIN deleted d ON d.TransactionID = i.TransactionID
    WHERE d.TransactionID IS NULL OR i.TransactionStatus <> d.TransactionStatus;
END;
GO

CREATE OR ALTER TRIGGER Audit.trg_AuditLog_BlockDelete
ON Audit.AuditLog
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;
    THROW 56001, 'Audit log cannot be deleted.', 1;
END;
GO

PRINT N'06 - Triggers created.';
GO
