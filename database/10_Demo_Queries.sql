USE EV_Charging_System;
GO

PRINT N'============================================================';
PRINT N'10 - IE103 demo queries and business workflows';
PRINT N'============================================================';

SELECT s.name AS SchemaName, COUNT(t.object_id) AS TableCount
FROM sys.schemas s
LEFT JOIN sys.tables t ON t.schema_id = s.schema_id
WHERE s.name IN (N'Core', N'Identity', N'Infrastructure', N'Franchise', N'Operations', N'Payments', N'Maintenance', N'Reporting', N'Audit')
GROUP BY s.name
ORDER BY s.name;

SELECT TOP 10
    s.StationCode,
    s.StationName,
    f.FranchiseName,
    s.StationStatus,
    COUNT(p.PointID) AS TotalPoints,
    SUM(CASE WHEN p.PointStatus = N'Available' THEN 1 ELSE 0 END) AS AvailablePoints,
    SUM(CASE WHEN p.PointStatus IN (N'Error', N'Maintenance', N'Offline') THEN 1 ELSE 0 END) AS ProblemPoints
FROM Infrastructure.ChargingStation s
JOIN Franchise.FranchisePartner f ON f.FranchiseID = s.FranchiseID
LEFT JOIN Infrastructure.ChargingPoint p ON p.StationID = s.StationID
GROUP BY s.StationCode, s.StationName, f.FranchiseName, s.StationStatus
ORDER BY s.StationCode;

SELECT TOP 20
    SessionCode,
    Username,
    FullName,
    PlateNumber,
    StationCode,
    PointCode,
    ConnectorCode,
    TotalKWh,
    CostTotal,
    SessionStatus
FROM Reporting.vw_CustomerChargingHistory
ORDER BY StartTime DESC;

EXEC Reporting.sp_ReportStationRevenue @FromDate = '2026-05-01', @ToDate = '2026-05-31';
EXEC Reporting.sp_ReportFranchiseProfit;
EXEC Reporting.sp_ReportOperationalKPI;
EXEC Reporting.sp_ReportPaymentRefund;
EXEC Reporting.sp_ReportCustomerUsage @Top = 5;
EXEC Reporting.sp_ReportTelemetryHealth;
GO

PRINT N'Business workflow demo: start session -> end session -> pay -> invoice.';
DECLARE @DemoUserID INT = (SELECT UserID FROM [Identity].UserAccount WHERE Username = N'customer05');
DECLARE @DemoVehicleID INT = (SELECT TOP 1 VehicleID FROM Operations.Vehicle WHERE UserID = @DemoUserID);
DECLARE @DemoPointID INT = (SELECT TOP 1 PointID FROM Infrastructure.ChargingPoint WHERE PointStatus = N'Available' ORDER BY PointID);

EXEC Operations.sp_StartChargingSession
    @UserID = @DemoUserID,
    @VehicleID = @DemoVehicleID,
    @PointID = @DemoPointID,
    @MeterStart = 5000.0000;

DECLARE @DemoSessionID BIGINT =
(
    SELECT TOP 1 SessionID
    FROM Operations.ChargingSession
    WHERE UserID = @DemoUserID AND PointID = @DemoPointID
    ORDER BY SessionID DESC
);

EXEC Operations.sp_EndChargingSession
    @SessionID = @DemoSessionID,
    @MeterEnd = 5026.5000,
    @TotalKWh = 26.5000,
    @StopReason = N'Completed';

EXEC Payments.sp_CreatePayment
    @UserID = @DemoUserID,
    @SessionID = @DemoSessionID,
    @PaymentMethodCode = N'WALLET';

EXEC Payments.sp_CreateInvoice @SessionID = @DemoSessionID;
GO

PRINT N'Rollback demo: invalid refund should fail and leave data unchanged.';
DECLARE @BadOriginal BIGINT = (SELECT TOP 1 TransactionID FROM Payments.PaymentTransaction WHERE TransactionType = N'ChargingPayment' ORDER BY TransactionID DESC);
BEGIN TRY
    EXEC Payments.sp_ProcessRefund
        @OriginalTransactionID = @BadOriginal,
        @Amount = 999999999.0000,
        @Reason = N'Invalid refund rollback demo';
    PRINT N'Unexpected: invalid refund succeeded.';
END TRY
BEGIN CATCH
    PRINT N'Expected rollback/error: ' + ERROR_MESSAGE();
END CATCH;

SELECT TOP 5 RefundID, OriginalTransactionID, Amount, RefundStatus, ProcessedAt
FROM Payments.Refund
ORDER BY RefundID DESC;
GO

PRINT N'10 - Demo queries completed.';
GO
