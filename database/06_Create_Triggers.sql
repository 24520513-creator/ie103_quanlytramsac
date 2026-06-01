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
    WHERE ISNULL(i.PointStatus, N'') <> ISNULL(d.PointStatus, N'');

    INSERT INTO Audit.AuditLog (SchemaName, TableName, RecordID, ActionType, OldValues, NewValues)
    SELECT N'Infrastructure', N'ChargingPoint', CAST(i.PointID AS NVARCHAR(100)), N'UPDATE',
           d.PointStatus, i.PointStatus
    FROM inserted i
    JOIN deleted d ON d.PointID = i.PointID
    WHERE ISNULL(i.PointStatus, N'') <> ISNULL(d.PointStatus, N'');
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
    WHERE d.SessionID IS NULL OR ISNULL(i.SessionStatus, N'') <> ISNULL(d.SessionStatus, N'');
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
    WHERE d.TransactionID IS NULL OR ISNULL(i.TransactionStatus, N'') <> ISNULL(d.TransactionStatus, N'');
END;
GO

CREATE OR ALTER TRIGGER [Identity].trg_UserAccount_Audit
ON [Identity].UserAccount
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Audit.AuditLog
    (
        SchemaName,
        TableName,
        RecordID,
        ActionType,
        OldValues,
        NewValues
    )
    SELECT
        N'Identity',
        N'UserAccount',
        CAST(i.UserID AS NVARCHAR(100)),
        CASE
            WHEN d.UserID IS NULL THEN N'INSERT'
            WHEN ISNULL(i.Email, N'') <> ISNULL(d.Email, N'')
              OR ISNULL(i.Phone, N'') <> ISNULL(d.Phone, N'')
              OR ISNULL(i.PasswordHash, N'') <> ISNULL(d.PasswordHash, N'')
            THEN N'SECURITY'
            ELSE N'UPDATE'
        END,
        d.AccountStatus,
        i.AccountStatus
    FROM inserted i
    LEFT JOIN deleted d ON d.UserID = i.UserID
    WHERE d.UserID IS NULL
       OR ISNULL(i.AccountStatus, N'') <> ISNULL(d.AccountStatus, N'')
       OR ISNULL(i.Email, N'') <> ISNULL(d.Email, N'')
       OR ISNULL(i.Phone, N'') <> ISNULL(d.Phone, N'')
       OR ISNULL(i.PasswordHash, N'') <> ISNULL(d.PasswordHash, N'');
END;
GO

CREATE OR ALTER TRIGGER [Identity].trg_UserRole_Audit
ON [Identity].UserRole
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN [Identity].UserAccount ua ON ua.UserID = i.UserID
        WHERE i.AssignedAt < ua.CreatedAt
    )
    BEGIN
        THROW 56004, N'UserRole: AssignedAt cannot be earlier than UserAccount.CreatedAt.', 1;
    END;

    INSERT INTO Audit.AuditLog
    (
        SchemaName,
        TableName,
        RecordID,
        ActionType,
        OldValues,
        NewValues
    )
    SELECT
        N'Identity',
        N'UserRole',
        CAST(i.UserID AS NVARCHAR(50)) + N'|' + CAST(i.RoleID AS NVARCHAR(50)),
        N'INSERT',
        NULL,
        CAST(i.RoleID AS NVARCHAR(50))
    FROM inserted i;
END;
GO

CREATE OR ALTER TRIGGER Franchise.trg_FranchisePartner_Audit
ON Franchise.FranchisePartner
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Audit.AuditLog
    (
        SchemaName,
        TableName,
        RecordID,
        ActionType,
        OldValues,
        NewValues
    )
    SELECT
        N'Franchise',
        N'FranchisePartner',
        CAST(i.FranchiseID AS NVARCHAR(100)),
        CASE WHEN d.FranchiseID IS NULL THEN N'INSERT' ELSE N'UPDATE' END,
        d.PartnerStatus,
        i.PartnerStatus
    FROM inserted i
    LEFT JOIN deleted d ON d.FranchiseID = i.FranchiseID
    WHERE d.FranchiseID IS NULL
       OR ISNULL(i.PartnerStatus, N'') <> ISNULL(d.PartnerStatus, N'');
END;
GO

CREATE OR ALTER TRIGGER Franchise.trg_FranchiseContract_Audit
ON Franchise.FranchiseContract
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM inserted WHERE SignedAt < CreatedAt)
        THROW 56010, N'FranchiseContract: SignedAt cannot be earlier than CreatedAt.', 1;

    IF EXISTS (SELECT 1 FROM inserted WHERE EndDate <= StartDate)
        THROW 56011, N'FranchiseContract: EndDate must be later than StartDate.', 1;

    INSERT INTO Audit.AuditLog
    (
        SchemaName,
        TableName,
        RecordID,
        ActionType,
        OldValues,
        NewValues
    )
    SELECT
        N'Franchise',
        N'FranchiseContract',
        CAST(i.ContractID AS NVARCHAR(100)),
        CASE WHEN d.ContractID IS NULL THEN N'INSERT' ELSE N'UPDATE' END,
        d.ContractStatus,
        i.ContractStatus
    FROM inserted i
    LEFT JOIN deleted d ON d.ContractID = i.ContractID
    WHERE d.ContractID IS NULL
       OR ISNULL(i.ContractStatus, N'') <> ISNULL(d.ContractStatus, N'');
END;
GO

CREATE OR ALTER TRIGGER Franchise.trg_RevenueSharePolicy_Audit
ON Franchise.RevenueSharePolicy
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN Franchise.FranchiseContract fc ON fc.ContractID = i.ContractID
        WHERE i.AppliedFrom < fc.StartDate
    )
    BEGIN
        THROW 56012, N'RevenueSharePolicy: AppliedFrom cannot be earlier than Contract.StartDate.', 1;
    END;

    INSERT INTO Audit.AuditLog
    (
        SchemaName,
        TableName,
        RecordID,
        ActionType,
        OldValues,
        NewValues
    )
    SELECT
        N'Franchise',
        N'RevenueSharePolicy',
        CAST(i.RevenueSharePolicyID AS NVARCHAR(100)),
        CASE WHEN d.RevenueSharePolicyID IS NULL THEN N'INSERT' ELSE N'UPDATE' END,
        CAST(d.PartnerShareRate AS NVARCHAR(50)),
        CAST(i.PartnerShareRate AS NVARCHAR(50))
    FROM inserted i
    LEFT JOIN deleted d ON d.RevenueSharePolicyID = i.RevenueSharePolicyID
    WHERE d.RevenueSharePolicyID IS NULL
       OR i.PartnerShareRate <> d.PartnerShareRate;
END;
GO

CREATE OR ALTER TRIGGER Franchise.trg_RevenueShareSettlement_Audit
ON Franchise.RevenueShareSettlement
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM inserted WHERE PeriodEnd < PeriodStart)
        THROW 56013, N'RevenueShareSettlement: PeriodEnd cannot be earlier than PeriodStart.', 1;

    INSERT INTO Audit.AuditLog
    (
        SchemaName,
        TableName,
        RecordID,
        ActionType,
        OldValues,
        NewValues
    )
    SELECT
        N'Franchise',
        N'RevenueShareSettlement',
        CAST(i.SettlementID AS NVARCHAR(100)),
        CASE WHEN d.SettlementID IS NULL THEN N'INSERT' ELSE N'UPDATE' END,
        d.SettlementStatus,
        i.SettlementStatus
    FROM inserted i
    LEFT JOIN deleted d ON d.SettlementID = i.SettlementID
    WHERE d.SettlementID IS NULL
       OR ISNULL(i.SettlementStatus, N'') <> ISNULL(d.SettlementStatus, N'');
END;
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
          ON b.PointID = i.PointID
         AND b.BookingID <> i.BookingID
         AND b.BookingStatus NOT IN (N'Cancelled', N'Completed', N'Expired')
        WHERE i.BookedFrom < b.BookedTo
          AND b.BookedFrom < i.BookedTo
          AND i.BookingStatus NOT IN (N'Cancelled', N'Completed', N'Expired')
    )
    BEGIN
        THROW 56020, N'Booking overlaps with an existing active booking on the same charging point.', 1;
    END;
END;
GO

CREATE OR ALTER TRIGGER Operations.trg_ChargingSession_SyncPointStatus
ON Operations.ChargingSession
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT (UPDATE(SessionStatus) OR UPDATE(PointID))
        RETURN;

    UPDATE cp
    SET cp.PointStatus = N'Charging',
        cp.UpdatedAt = SYSDATETIME()
    FROM Infrastructure.ChargingPoint cp
    JOIN inserted i ON i.PointID = cp.PointID
    LEFT JOIN deleted d ON d.SessionID = i.SessionID
    WHERE i.SessionStatus = N'Charging'
      AND (d.SessionID IS NULL OR d.SessionStatus <> N'Charging' OR d.PointID <> i.PointID);

    UPDATE cp
    SET cp.PointStatus = N'Available',
        cp.UpdatedAt = SYSDATETIME()
    FROM Infrastructure.ChargingPoint cp
    JOIN inserted i ON i.PointID = cp.PointID
    LEFT JOIN deleted d ON d.SessionID = i.SessionID
    WHERE i.SessionStatus IN (N'Completed', N'Failed', N'Cancelled', N'EmergencyStopped')
      AND (d.SessionID IS NULL OR d.SessionStatus NOT IN (N'Completed', N'Failed', N'Cancelled', N'EmergencyStopped'))
      AND NOT EXISTS (
          SELECT 1
          FROM Operations.ChargingSession cs
          WHERE cs.PointID = cp.PointID
            AND cs.SessionStatus = N'Charging'
            AND cs.SessionID <> i.SessionID
      );
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
            WHEN i.Priority = N'Critical' THEN N'Critical'
            WHEN i.Priority = N'High' THEN N'Warning'
            ELSE cp.HealthStatus
        END,
        cp.UpdatedAt = SYSDATETIME()
    FROM Infrastructure.ChargingPoint cp
    JOIN inserted i ON i.PointID = cp.PointID
    WHERE i.TicketStatus IN (N'Open', N'Assigned', N'InProgress')
      AND i.Priority IN (N'Critical', N'High');

    UPDATE cp
    SET cp.HealthStatus = CASE
            WHEN EXISTS (
                SELECT 1
                FROM Maintenance.MaintenanceTicket t
                WHERE t.PointID = cp.PointID
                  AND t.TicketStatus IN (N'Open', N'Assigned', N'InProgress')
                  AND t.Priority = N'Critical'
            ) THEN N'Critical'
            WHEN EXISTS (
                SELECT 1
                FROM Maintenance.MaintenanceTicket t
                WHERE t.PointID = cp.PointID
                  AND t.TicketStatus IN (N'Open', N'Assigned', N'InProgress')
                  AND t.Priority = N'High'
            ) THEN N'Warning'
            ELSE N'Normal'
        END,
        cp.UpdatedAt = SYSDATETIME()
    FROM Infrastructure.ChargingPoint cp
    JOIN inserted i ON i.PointID = cp.PointID
    WHERE i.TicketStatus IN (N'Closed', N'Cancelled', N'Resolved');
END;
GO

CREATE OR ALTER TRIGGER Payments.trg_PaymentTransaction_UpdateInvoice
ON Payments.PaymentTransaction
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT UPDATE(TransactionStatus)
        RETURN;

    UPDATE inv
    SET inv.InvoiceStatus = N'Paid'
    FROM Payments.Invoice inv
    JOIN inserted i ON i.TransactionID = inv.TransactionID
    LEFT JOIN deleted d ON d.TransactionID = i.TransactionID
    WHERE i.TransactionStatus = N'Completed'
      AND (d.TransactionID IS NULL OR d.TransactionStatus <> N'Completed');

    UPDATE inv
    SET inv.InvoiceStatus = N'Refunded'
    FROM Payments.Invoice inv
    JOIN inserted i ON i.TransactionID = inv.TransactionID
    LEFT JOIN deleted d ON d.TransactionID = i.TransactionID
    WHERE i.TransactionStatus = N'Refunded'
      AND (d.TransactionID IS NULL OR d.TransactionStatus <> N'Refunded');
END;
GO

CREATE OR ALTER TRIGGER Audit.trg_AuditLog_BlockDelete
ON Audit.AuditLog
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;
    THROW 56001, N'Audit log cannot be deleted.', 1;
END;
GO

CREATE OR ALTER TRIGGER Audit.trg_AuditLog_BlockUpdate
ON Audit.AuditLog
INSTEAD OF UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    THROW 56002, N'Audit log cannot be modified.', 1;
END;
GO

PRINT N'06 - Triggers created.';
GO
