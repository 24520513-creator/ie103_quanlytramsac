USE EV_Charging_System;
GO

PRINT N'============================================================';
PRINT N'11 - Role and permission tests using EXECUTE AS USER';
PRINT N'============================================================';
GO

PRINT N'SystemAdmin: expected success reading audit, reports, and users.';
EXECUTE AS USER = 'admin01';
SELECT TOP 5 SchemaName, TableName, ActionType, ChangedAt
FROM Audit.AuditLog
ORDER BY ChangedAt DESC;
EXEC Reporting.sp_ReportOperationalKPI;
SELECT TOP 5 UserID, Username, Email
FROM [Identity].UserAccount
ORDER BY UserID;
REVERT;
GO

PRINT N'OperationsStaff: expected success reading stations, sessions, telemetry, and maintenance.';
EXECUTE AS USER = 'operator01';
SELECT TOP 5 StationID, StationCode, StationStatus
FROM Infrastructure.ChargingStation
ORDER BY StationID;
SELECT TOP 5 SessionID, SessionCode, SessionStatus
FROM Operations.ChargingSession
ORDER BY SessionID DESC;
SELECT TOP 5 PointID, PowerKW, HealthStatus, RecordedAt
FROM Infrastructure.PointTelemetry
ORDER BY RecordedAt DESC;
SELECT TOP 5 TicketCode, TicketStatus, Priority
FROM Maintenance.MaintenanceTicket
ORDER BY TicketID DESC;
REVERT;
GO

PRINT N'OperationsStaff: expected permission denied on payment table.';
EXECUTE AS USER = 'operator01';
BEGIN TRY
    SELECT TOP 1 * FROM Payments.PaymentTransaction;
    PRINT N'Unexpected: operations staff read payment table.';
END TRY
BEGIN CATCH
    PRINT N'Expected permission denied: ' + ERROR_MESSAGE();
END CATCH;
REVERT;
GO

PRINT N'BusinessManager: expected success on franchise, payment/refund report, settlement, and refund.';
EXECUTE AS USER = 'business01';
EXEC Reporting.sp_ReportFranchiseProfit;
EXEC Reporting.sp_ReportPaymentRefund;
DECLARE @FranchiseID INT = (SELECT TOP 1 FranchiseID FROM Franchise.FranchisePartner ORDER BY FranchiseID);
EXEC Franchise.sp_CreateRevenueSettlement @FranchiseID = @FranchiseID, @PeriodStart = '2026-05-01', @PeriodEnd = '2026-05-31';
DECLARE @RefundableTxn BIGINT =
(
    SELECT TOP 1 TransactionID
    FROM Payments.PaymentTransaction
    WHERE TransactionType = N'ChargingPayment'
      AND TransactionStatus = N'Completed'
      AND Payments.fn_RefundableAmount(TransactionID) >= 1000
    ORDER BY TransactionID DESC
);
IF @RefundableTxn IS NOT NULL
    EXEC Payments.sp_ProcessRefund @OriginalTransactionID = @RefundableTxn, @Amount = 1000, @Reason = N'BusinessManager role test refund';
REVERT;
GO

PRINT N'BusinessManager: expected permission denied on Identity.UserAccount.';
EXECUTE AS USER = 'business01';
BEGIN TRY
    SELECT TOP 1 UserID, Email, PasswordHash FROM [Identity].UserAccount;
    PRINT N'Unexpected: business manager read users.';
END TRY
BEGIN CATCH
    PRINT N'Expected permission denied: ' + ERROR_MESSAGE();
END CATCH;
REVERT;
GO

PRINT N'Customer: expected success on customer history view and usage procedure.';
EXECUTE AS USER = 'customer01';
SELECT TOP 5 Username, StationCode, PointCode, TotalKWh, CostTotal
FROM Reporting.vw_CustomerChargingHistory
ORDER BY StartTime DESC;
EXEC Reporting.sp_ReportCustomerUsage @Top = 5;
REVERT;
GO

PRINT N'Customer: expected permission denied on raw payment table.';
EXECUTE AS USER = 'customer01';
BEGIN TRY
    SELECT TOP 1 * FROM Payments.PaymentTransaction;
    PRINT N'Unexpected: customer read payment table.';
END TRY
BEGIN CATCH
    PRINT N'Expected permission denied: ' + ERROR_MESSAGE();
END CATCH;
REVERT;
GO

PRINT N'11 - Role tests completed.';
GO
