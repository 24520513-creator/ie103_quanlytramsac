USE EV_Charging_System;
GO

CREATE OR ALTER VIEW Reporting.vw_CustomerChargingHistory
AS
SELECT
    u.UserID,
    u.Username,
    u.FullName,
    v.PlateNumber,
    cs.SessionID,
    cs.SessionCode,
    s.StationCode,
    s.StationName,
    p.PointCode,
    ct.ConnectorCode,
    cs.StartTime,
    cs.EndTime,
    cs.TotalKWh,
    cs.CostTotal,
    cs.SessionStatus
FROM Operations.ChargingSession cs
JOIN [Identity].UserAccount u ON u.UserID = cs.UserID
LEFT JOIN Operations.Vehicle v ON v.VehicleID = cs.VehicleID
JOIN Infrastructure.ChargingStation s ON s.StationID = cs.StationID
JOIN Infrastructure.ChargingPoint p ON p.PointID = cs.PointID
JOIN Infrastructure.ConnectorType ct ON ct.ConnectorTypeID = p.ConnectorTypeID;
GO

CREATE OR ALTER VIEW Reporting.vw_StationRevenueDaily
AS
SELECT
    CAST(cs.StartTime AS DATE) AS RevenueDate,
    s.StationID,
    s.StationCode,
    s.StationName,
    f.FranchiseCode,
    f.FranchiseName,
    COUNT(cs.SessionID) AS CompletedSessions,
    SUM(ISNULL(cs.TotalKWh, 0)) AS TotalKWh,
    SUM(ISNULL(cs.CostBeforeTax, 0)) AS RevenueBeforeTax,
    SUM(ISNULL(cs.TaxAmount, 0)) AS TaxAmount,
    SUM(ISNULL(cs.CostTotal, 0)) AS RevenueTotal
FROM Operations.ChargingSession cs
JOIN Infrastructure.ChargingStation s ON s.StationID = cs.StationID
JOIN Franchise.FranchisePartner f ON f.FranchiseID = s.FranchiseID
WHERE cs.SessionStatus = N'Completed'
GROUP BY CAST(cs.StartTime AS DATE), s.StationID, s.StationCode, s.StationName, f.FranchiseCode, f.FranchiseName;
GO

CREATE OR ALTER VIEW Reporting.vw_FranchiseRevenueMonthly
AS
SELECT
    YEAR(cs.StartTime) AS RevenueYear,
    MONTH(cs.StartTime) AS RevenueMonth,
    f.FranchiseID,
    f.FranchiseCode,
    f.FranchiseName,
    COUNT(DISTINCT s.StationID) AS StationCount,
    COUNT(cs.SessionID) AS CompletedSessions,
    SUM(ISNULL(cs.TotalKWh, 0)) AS TotalKWh,
    SUM(ISNULL(cs.CostBeforeTax, 0)) AS GrossRevenue
FROM Franchise.FranchisePartner f
JOIN Infrastructure.ChargingStation s ON s.FranchiseID = f.FranchiseID
LEFT JOIN Operations.ChargingSession cs ON cs.StationID = s.StationID AND cs.SessionStatus = N'Completed'
GROUP BY YEAR(cs.StartTime), MONTH(cs.StartTime), f.FranchiseID, f.FranchiseCode, f.FranchiseName;
GO

CREATE OR ALTER VIEW Reporting.vw_ProfitSharing
AS
SELECT
    rs.SettlementCode,
    f.FranchiseCode,
    f.FranchiseName,
    fc.ContractCode,
    rs.PeriodStart,
    rs.PeriodEnd,
    rs.GrossRevenue,
    rs.PartnerShareAmount,
    rs.PlatformShareAmount,
    rs.SettlementStatus
FROM Franchise.RevenueShareSettlement rs
JOIN Franchise.FranchisePartner f ON f.FranchiseID = rs.FranchiseID
JOIN Franchise.FranchiseContract fc ON fc.ContractID = rs.ContractID;
GO

CREATE OR ALTER VIEW Reporting.vw_ConnectorUtilization
AS
SELECT
    ct.ConnectorCode,
    ct.ConnectorName,
    COUNT(DISTINCT p.PointID) AS PointCount,
    COUNT(cs.SessionID) AS CompletedSessions,
    SUM(ISNULL(cs.TotalKWh, 0)) AS TotalKWh,
    SUM(ISNULL(cs.CostTotal, 0)) AS TotalRevenue
FROM Infrastructure.ConnectorType ct
LEFT JOIN Infrastructure.ChargingPoint p ON p.ConnectorTypeID = ct.ConnectorTypeID
LEFT JOIN Operations.ChargingSession cs ON cs.PointID = p.PointID AND cs.SessionStatus = N'Completed'
GROUP BY ct.ConnectorCode, ct.ConnectorName;
GO

CREATE OR ALTER VIEW Reporting.vw_MaintenanceKPI
AS
SELECT
    s.StationCode,
    s.StationName,
    COUNT(DISTINCT mt.TicketID) AS TicketCount,
    COUNT(DISTINCT CASE WHEN mt.TicketStatus IN (N'Open', N'Assigned', N'InProgress') THEN mt.TicketID END) AS OpenTicketCount,
    COUNT(DISTINCT el.ErrorID) AS ErrorCount,
    COUNT(DISTINCT CASE WHEN el.IsActive = 1 THEN el.ErrorID END) AS ActiveErrorCount,
    AVG(CASE WHEN mt.ClosedAt IS NOT NULL THEN DATEDIFF(HOUR, mt.OpenedAt, mt.ClosedAt) END) AS AvgResolveHours
FROM Infrastructure.ChargingStation s
LEFT JOIN Maintenance.MaintenanceTicket mt ON mt.StationID = s.StationID
LEFT JOIN Maintenance.ErrorLog el ON el.StationID = s.StationID
GROUP BY s.StationCode, s.StationName;
GO

CREATE OR ALTER VIEW Reporting.vw_PaymentSummary
AS
SELECT
    pm.MethodCode,
    pt.TransactionType,
    pt.TransactionStatus,
    COUNT(*) AS TransactionCount,
    SUM(pt.Amount) AS TotalAmount
FROM Payments.PaymentTransaction pt
JOIN Payments.PaymentMethod pm ON pm.PaymentMethodID = pt.PaymentMethodID
GROUP BY pm.MethodCode, pt.TransactionType, pt.TransactionStatus;
GO

CREATE OR ALTER PROCEDURE Reporting.sp_ReportStationRevenue
    @FromDate DATE = NULL,
    @ToDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT StationCode, StationName, FranchiseName,
           SUM(CompletedSessions) AS CompletedSessions,
           SUM(TotalKWh) AS TotalKWh,
           SUM(RevenueTotal) AS RevenueTotal
    FROM Reporting.vw_StationRevenueDaily
    WHERE (@FromDate IS NULL OR RevenueDate >= @FromDate)
      AND (@ToDate IS NULL OR RevenueDate <= @ToDate)
    GROUP BY StationCode, StationName, FranchiseName
    ORDER BY RevenueTotal DESC;
END;
GO

CREATE OR ALTER PROCEDURE Reporting.sp_ReportFranchiseProfit
AS
BEGIN
    SET NOCOUNT ON;
    SELECT SettlementCode, FranchiseCode, FranchiseName, PeriodStart, PeriodEnd,
           GrossRevenue, PartnerShareAmount, PlatformShareAmount, SettlementStatus
    FROM Reporting.vw_ProfitSharing
    ORDER BY PeriodEnd DESC, GrossRevenue DESC;
END;
GO

CREATE OR ALTER PROCEDURE Reporting.sp_ReportOperationalKPI
AS
BEGIN
    SET NOCOUNT ON;
    SELECT StationCode, StationName, TicketCount, OpenTicketCount, ErrorCount, ActiveErrorCount, AvgResolveHours
    FROM Reporting.vw_MaintenanceKPI
    ORDER BY ActiveErrorCount DESC, OpenTicketCount DESC, StationCode;
END;
GO

CREATE OR ALTER PROCEDURE Reporting.sp_ReportPaymentRefund
AS
BEGIN
    SET NOCOUNT ON;
    SELECT MethodCode, TransactionType, TransactionStatus, TransactionCount, TotalAmount
    FROM Reporting.vw_PaymentSummary
    ORDER BY TransactionType, TransactionStatus, MethodCode;
END;
GO

CREATE OR ALTER PROCEDURE Reporting.sp_ReportCustomerUsage
    @Top INT = 10
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP (@Top) Username, FullName,
           COUNT(SessionID) AS CompletedSessions,
           SUM(ISNULL(TotalKWh, 0)) AS TotalKWh,
           SUM(ISNULL(CostTotal, 0)) AS TotalSpend
    FROM Reporting.vw_CustomerChargingHistory
    WHERE SessionStatus = N'Completed'
    GROUP BY Username, FullName
    ORDER BY TotalSpend DESC, CompletedSessions DESC;
END;
GO

CREATE OR ALTER PROCEDURE Reporting.sp_ReportTelemetryHealth
AS
BEGIN
    SET NOCOUNT ON;
    SELECT s.StationCode, p.PointCode, ct.ConnectorCode,
           MAX(t.RecordedAt) AS LastRecordedAt,
           MAX(t.TemperatureC) AS MaxTemperatureC,
           SUM(CASE WHEN t.HealthStatus IN (N'Warning', N'Critical', N'Offline') THEN 1 ELSE 0 END) AS IssueSamples
    FROM Infrastructure.PointTelemetry t
    JOIN Infrastructure.ChargingPoint p ON p.PointID = t.PointID
    JOIN Infrastructure.ChargingStation s ON s.StationID = p.StationID
    JOIN Infrastructure.ConnectorType ct ON ct.ConnectorTypeID = p.ConnectorTypeID
    GROUP BY s.StationCode, p.PointCode, ct.ConnectorCode
    HAVING SUM(CASE WHEN t.HealthStatus IN (N'Warning', N'Critical', N'Offline') THEN 1 ELSE 0 END) > 0
    ORDER BY IssueSamples DESC, StationCode, PointCode;
END;
GO

PRINT N'07 - Reporting views and procedures created.';
GO
