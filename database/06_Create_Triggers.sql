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


CREATE OR ALTER TRIGGER Operations.trg_Booking_PreventOverlap
ON Operations.Booking
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
 
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN Operations.Booking b
          ON  b.PointID      =  i.PointID
          AND b.BookingID   <>  i.BookingID
          AND b.BookingStatus NOT IN ('Cancelled', 'Completed', 'Expired')
        WHERE i.BookedFrom < b.BookedTo
          AND b.BookedFrom < i.BookedTo
          AND i.BookingStatus NOT IN ('Cancelled', 'Completed', 'Expired')
    )
    BEGIN
        RAISERROR(
            'Booking trung gio voi booking dang ton tai tren cung cong sac.',
            16, 1
        );
        ROLLBACK TRANSACTION;
    END
END;
GO

CREATE OR ALTER TRIGGER Operations.trg_ChargingSession_SyncPointStatus
ON Operations.ChargingSession
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
 
    IF NOT UPDATE(SessionStatus)
        RETURN;
 
    UPDATE cp
    SET cp.PointStatus = 'Charging'
    FROM Infrastructure.ChargingPoint cp
    JOIN inserted i ON i.PointID   = cp.PointID
    JOIN deleted  d ON d.SessionID = i.SessionID
    WHERE i.SessionStatus = 'Active'
      AND d.SessionStatus <> 'Active';
 
    UPDATE cp
    SET cp.PointStatus = 'Available'
    FROM Infrastructure.ChargingPoint cp
    JOIN inserted i ON i.PointID   = cp.PointID
    JOIN deleted  d ON d.SessionID = i.SessionID
    WHERE i.SessionStatus IN ('Completed', 'Failed', 'Cancelled')
      AND d.SessionStatus NOT IN ('Completed', 'Failed', 'Cancelled');
END;
GO

CREATE OR ALTER TRIGGER Maintenance.trg_Ticket_UpdatePointHealth
ON Maintenance.MaintenanceTicket
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
 
    UPDATE cp
    SET cp.HealthStatus = CASE
        WHEN i.Priority = 'Critical' THEN 'Critical'
        WHEN i.Priority = 'High'     THEN 'Warning'
        ELSE cp.HealthStatus
    END
    FROM Infrastructure.ChargingPoint cp
    JOIN inserted i ON i.PointID = cp.PointID
    WHERE i.TicketStatus <> 'Closed'
      AND i.Priority IN ('Critical', 'High');
 
    UPDATE cp
    SET cp.HealthStatus = CASE
        WHEN EXISTS (
            SELECT 1 FROM Maintenance.MaintenanceTicket t
            WHERE t.PointID      =  cp.PointID
              AND t.TicketID    <>  i.TicketID
              AND t.TicketStatus <> 'Closed'
              AND t.Priority     =  'Critical'
        ) THEN 'Critical'
        WHEN EXISTS (
            SELECT 1 FROM Maintenance.MaintenanceTicket t
            WHERE t.PointID      =  cp.PointID
              AND t.TicketID    <>  i.TicketID
              AND t.TicketStatus <> 'Closed'
              AND t.Priority     =  'High'
        ) THEN 'Warning'
        ELSE 'Normal'
    END
    FROM Infrastructure.ChargingPoint cp
    JOIN inserted i ON i.PointID = cp.PointID
    WHERE i.TicketStatus = 'Closed';
END;
GO

CREATE OR ALTER TRIGGER Payments.trg_PaymentTransaction_UpdateInvoice
ON Payments.PaymentTransaction
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
 
    IF NOT UPDATE(TransactionStatus)
        RETURN;

    UPDATE inv
    SET inv.InvoiceStatus = 'Paid'
    FROM Payments.Invoice inv
    JOIN inserted i ON i.TransactionID = inv.TransactionID
    JOIN deleted  d ON d.TransactionID = i.TransactionID
    WHERE i.TransactionStatus = 'Completed'
      AND d.TransactionStatus <> 'Completed';
 
    UPDATE inv
    SET inv.InvoiceStatus = 'Refunded'
    FROM Payments.Invoice inv
    JOIN inserted i ON i.TransactionID = inv.TransactionID
    JOIN deleted  d ON d.TransactionID = i.TransactionID
    WHERE i.TransactionStatus = 'Refunded'
      AND d.TransactionStatus <> 'Refunded';
END;
GO