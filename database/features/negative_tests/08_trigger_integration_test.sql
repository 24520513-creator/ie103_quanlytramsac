USE EV_Charging_System;
GO

/*
Integration checks for database/06_Create_Triggers.sql.
Run after applying 06_Create_Triggers.sql. The script uses transactions and rolls
back every data change.
*/

SET NOCOUNT ON;

PRINT N'Check 1: required triggers exist and are enabled.';
SELECT
    SCHEMA_NAME(o.schema_id) AS SchemaName,
    o.name AS TriggerName,
    OBJECT_NAME(t.parent_id) AS ParentObject,
    t.is_disabled AS IsDisabled
FROM sys.triggers t
JOIN sys.objects o ON o.object_id = t.object_id
WHERE o.name IN
(
    N'trg_Booking_PreventOverlap',
    N'trg_ChargingSession_SyncPointStatus',
    N'trg_Ticket_UpdatePointHealth',
    N'trg_PaymentTransaction_UpdateInvoice',
    N'trg_AuditLog_BlockUpdate'
)
ORDER BY SchemaName, TriggerName;
GO

PRINT N'Check 2: booking overlap trigger rejects conflicting active bookings.';
BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @PointID INT, @StationID INT, @UserID INT;
    SELECT TOP 1 @PointID = PointID, @StationID = StationID
    FROM Infrastructure.ChargingPoint
    ORDER BY PointID;

    SELECT TOP 1 @UserID = UserID
    FROM [Identity].UserAccount
    WHERE Username LIKE N'customer%'
    ORDER BY UserID;

    DECLARE @From DATETIME2 = DATEADD(DAY, 60, SYSDATETIME());
    DECLARE @To DATETIME2 = DATEADD(HOUR, 1, @From);

    INSERT INTO Operations.Booking
        (BookingCode, UserID, StationID, PointID, BookedFrom, BookedTo, BookingStatus)
    VALUES
        (N'TRIG-BOOK-A-' + RIGHT(CONVERT(NVARCHAR(36), NEWID()), 8), @UserID, @StationID, @PointID, @From, @To, N'Confirmed');

    INSERT INTO Operations.Booking
        (BookingCode, UserID, StationID, PointID, BookedFrom, BookedTo, BookingStatus)
    VALUES
        (N'TRIG-BOOK-B-' + RIGHT(CONVERT(NVARCHAR(36), NEWID()), 8), @UserID, @StationID, @PointID,
         DATEADD(MINUTE, 10, @From), DATEADD(MINUTE, 70, @From), N'Confirmed');

    THROW 56990, N'FAILED: overlap booking was not rejected.', 1;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    IF ERROR_NUMBER() = 56020
        PRINT N'PASSED: overlap booking rejected.';
    ELSE
        THROW;
END CATCH;
GO

PRINT N'Check 3: charging session trigger synchronizes point status.';
BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @PointID INT, @StationID INT, @UserID INT, @PolicyID INT;
    SELECT TOP 1 @PointID = cp.PointID, @StationID = cp.StationID
    FROM Infrastructure.ChargingPoint cp
    WHERE NOT EXISTS (
        SELECT 1 FROM Operations.ChargingSession cs
        WHERE cs.PointID = cp.PointID AND cs.SessionStatus = N'Charging'
    )
    ORDER BY cp.PointID;

    SELECT TOP 1 @UserID = UserID FROM [Identity].UserAccount WHERE Username LIKE N'customer%' ORDER BY UserID;
    SELECT TOP 1 @PolicyID = PolicyID FROM Operations.PricingPolicy ORDER BY PolicyID;

    UPDATE Infrastructure.ChargingPoint
    SET PointStatus = N'Available', HealthStatus = N'Normal'
    WHERE PointID = @PointID;

    DECLARE @Session TABLE (SessionID BIGINT);
    INSERT INTO Operations.ChargingSession
        (SessionCode, UserID, StationID, PointID, PolicyID, StartTime, SessionStatus)
    OUTPUT inserted.SessionID INTO @Session
    VALUES
        (N'TRIG-SESS-' + RIGHT(CONVERT(NVARCHAR(36), NEWID()), 8), @UserID, @StationID, @PointID, @PolicyID, SYSDATETIME(), N'Charging');

    IF NOT EXISTS (SELECT 1 FROM Infrastructure.ChargingPoint WHERE PointID = @PointID AND PointStatus = N'Charging')
        THROW 56991, N'FAILED: point did not become Charging.', 1;

    UPDATE Operations.ChargingSession
    SET SessionStatus = N'Completed', EndTime = SYSDATETIME(), TotalKWh = 1, CostTotal = 1
    WHERE SessionID = (SELECT TOP 1 SessionID FROM @Session);

    IF NOT EXISTS (SELECT 1 FROM Infrastructure.ChargingPoint WHERE PointID = @PointID AND PointStatus = N'Available')
        THROW 56992, N'FAILED: point did not return to Available.', 1;

    ROLLBACK TRANSACTION;
    PRINT N'PASSED: session status synchronized point status.';
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

PRINT N'Check 4: maintenance ticket trigger updates point health only for active tickets.';
BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @PointID INT, @StationID INT, @UserID INT;
    SELECT TOP 1 @PointID = cp.PointID, @StationID = cp.StationID
    FROM Infrastructure.ChargingPoint cp
    WHERE NOT EXISTS (
        SELECT 1 FROM Maintenance.MaintenanceTicket mt
        WHERE mt.PointID = cp.PointID
          AND mt.TicketStatus IN (N'Open', N'Assigned', N'InProgress')
          AND mt.Priority IN (N'High', N'Critical')
    )
    ORDER BY cp.PointID;

    SELECT TOP 1 @UserID = UserID FROM [Identity].UserAccount WHERE Username LIKE N'operator%' ORDER BY UserID;

    UPDATE Infrastructure.ChargingPoint
    SET HealthStatus = N'Normal'
    WHERE PointID = @PointID;

    DECLARE @Ticket TABLE (TicketID BIGINT);
    INSERT INTO Maintenance.MaintenanceTicket
        (TicketCode, StationID, PointID, CreatedBy, Priority, TicketStatus, Title)
    OUTPUT inserted.TicketID INTO @Ticket
    VALUES
        (N'TRIG-TICKET-' + RIGHT(CONVERT(NVARCHAR(36), NEWID()), 8), @StationID, @PointID, @UserID, N'High', N'Open', N'Trigger health test');

    IF NOT EXISTS (SELECT 1 FROM Infrastructure.ChargingPoint WHERE PointID = @PointID AND HealthStatus = N'Warning')
        THROW 56993, N'FAILED: high active ticket did not set Warning health.', 1;

    UPDATE Maintenance.MaintenanceTicket
    SET TicketStatus = N'Resolved'
    WHERE TicketID = (SELECT TOP 1 TicketID FROM @Ticket);

    IF NOT EXISTS (SELECT 1 FROM Infrastructure.ChargingPoint WHERE PointID = @PointID AND HealthStatus = N'Normal')
        THROW 56994, N'FAILED: resolved ticket was still treated as active.', 1;

    ROLLBACK TRANSACTION;
    PRINT N'PASSED: ticket health trigger respects active statuses.';
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

PRINT N'Check 5: payment trigger synchronizes invoice status.';
BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @TransactionID BIGINT, @InvoiceID BIGINT;
    SELECT TOP 1 @TransactionID = pt.TransactionID, @InvoiceID = inv.InvoiceID
    FROM Payments.PaymentTransaction pt
    JOIN Payments.Invoice inv ON inv.TransactionID = pt.TransactionID
    ORDER BY pt.TransactionID DESC;

    UPDATE Payments.Invoice SET InvoiceStatus = N'Issued' WHERE InvoiceID = @InvoiceID;
    UPDATE Payments.PaymentTransaction SET TransactionStatus = N'Pending' WHERE TransactionID = @TransactionID;

    UPDATE Payments.PaymentTransaction SET TransactionStatus = N'Completed' WHERE TransactionID = @TransactionID;
    IF NOT EXISTS (SELECT 1 FROM Payments.Invoice WHERE InvoiceID = @InvoiceID AND InvoiceStatus = N'Paid')
        THROW 56995, N'FAILED: completed payment did not mark invoice paid.', 1;

    UPDATE Payments.PaymentTransaction SET TransactionStatus = N'Refunded' WHERE TransactionID = @TransactionID;
    IF NOT EXISTS (SELECT 1 FROM Payments.Invoice WHERE InvoiceID = @InvoiceID AND InvoiceStatus = N'Refunded')
        THROW 56996, N'FAILED: refunded payment did not mark invoice refunded.', 1;

    ROLLBACK TRANSACTION;
    PRINT N'PASSED: payment status synchronized invoice status.';
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

PRINT N'All trigger integration checks completed.';
GO
