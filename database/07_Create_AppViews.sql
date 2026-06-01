USE EV_Charging_System;
GO

CREATE OR ALTER VIEW AppView.vw_CustomerChargingHistory
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
JOIN Infrastructure.ConnectorType ct ON ct.ConnectorTypeID = p.ConnectorTypeID
WHERE NOT (COALESCE(CAST(SESSION_CONTEXT(N'RoleCode') AS NVARCHAR(40)), N'') = N'Customer' OR IS_ROLEMEMBER(N'db_ev_customer') = 1)
   OR cs.UserID = TRY_CONVERT(INT, SESSION_CONTEXT(N'UserID'));
GO

CREATE OR ALTER VIEW AppView.vw_StationRevenueDaily
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

CREATE OR ALTER VIEW AppView.vw_FranchiseRevenueMonthly
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

CREATE OR ALTER VIEW AppView.vw_ProfitSharing
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

CREATE OR ALTER VIEW AppView.vw_MyFranchiseProfile
AS
SELECT
    f.FranchiseID,
    f.FranchiseCode,
    f.FranchiseName,
    f.TaxCode,
    f.ContactPerson,
    f.ContactPhone,
    f.ContactEmail,
    f.PartnerStatus,
    a.FullAddress
FROM Franchise.FranchisePartner f
JOIN [Identity].UserAccount u ON u.UserID = f.ContactUserID
LEFT JOIN Core.Address a ON a.AddressID = f.AddressID
WHERE NOT (COALESCE(CAST(SESSION_CONTEXT(N'RoleCode') AS NVARCHAR(40)), N'') = N'FranchisePartner' OR IS_ROLEMEMBER(N'db_ev_franchise_partner') = 1)
   OR f.ContactUserID = TRY_CONVERT(INT, SESSION_CONTEXT(N'UserID'));
GO

CREATE OR ALTER VIEW AppView.vw_MyFranchiseContracts
AS
SELECT
    fc.ContractID,
    f.FranchiseCode,
    f.FranchiseName,
    fc.ContractCode,
    fc.StartDate,
    fc.EndDate,
    fc.BaseRevenueShareRate,
    fc.ContractStatus
FROM Franchise.FranchiseContract fc
JOIN Franchise.FranchisePartner f ON f.FranchiseID = fc.FranchiseID
JOIN [Identity].UserAccount u ON u.UserID = f.ContactUserID
WHERE NOT (COALESCE(CAST(SESSION_CONTEXT(N'RoleCode') AS NVARCHAR(40)), N'') = N'FranchisePartner' OR IS_ROLEMEMBER(N'db_ev_franchise_partner') = 1)
   OR f.ContactUserID = TRY_CONVERT(INT, SESSION_CONTEXT(N'UserID'));
GO

CREATE OR ALTER VIEW AppView.vw_MyFranchiseStations
AS
SELECT
    fs.FranchiseID,
    f.FranchiseCode,
    f.FranchiseName,
    fs.StationID,
    s.StationCode,
    s.StationName,
    s.MaxPowerKW,
    s.StationStatus,
    fc.ContractCode,
    a.FullAddress
FROM Franchise.FranchiseStation fs
JOIN Franchise.FranchisePartner f ON f.FranchiseID = fs.FranchiseID
JOIN [Identity].UserAccount u ON u.UserID = f.ContactUserID
JOIN Infrastructure.ChargingStation s ON s.StationID = fs.StationID
JOIN Franchise.FranchiseContract fc ON fc.ContractID = fs.ContractID
LEFT JOIN Core.Address a ON a.AddressID = s.AddressID
WHERE NOT (COALESCE(CAST(SESSION_CONTEXT(N'RoleCode') AS NVARCHAR(40)), N'') = N'FranchisePartner' OR IS_ROLEMEMBER(N'db_ev_franchise_partner') = 1)
   OR f.ContactUserID = TRY_CONVERT(INT, SESSION_CONTEXT(N'UserID'));
GO

CREATE OR ALTER VIEW AppView.vw_MyRevenueSharePolicies
AS
SELECT
    rsp.RevenueSharePolicyID,
    f.FranchiseCode,
    f.FranchiseName,
    fc.ContractCode,
    rsp.PolicyCode,
    rsp.PartnerShareRate,
    rsp.PlatformShareRate,
    rsp.AppliedFrom,
    rsp.AppliedTo,
    rsp.IsActive
FROM Franchise.RevenueSharePolicy rsp
JOIN Franchise.FranchiseContract fc ON fc.ContractID = rsp.ContractID
JOIN Franchise.FranchisePartner f ON f.FranchiseID = fc.FranchiseID
JOIN [Identity].UserAccount u ON u.UserID = f.ContactUserID
WHERE NOT (COALESCE(CAST(SESSION_CONTEXT(N'RoleCode') AS NVARCHAR(40)), N'') = N'FranchisePartner' OR IS_ROLEMEMBER(N'db_ev_franchise_partner') = 1)
   OR f.ContactUserID = TRY_CONVERT(INT, SESSION_CONTEXT(N'UserID'));
GO

CREATE OR ALTER VIEW AppView.vw_MyRevenueShareSettlements
AS
SELECT
    rs.SettlementID,
    rs.SettlementCode,
    f.FranchiseCode,
    f.FranchiseName,
    fc.ContractCode,
    rs.PeriodStart,
    rs.PeriodEnd,
    rs.GrossRevenue,
    rs.PartnerShareAmount,
    rs.PlatformShareAmount,
    rs.SettlementStatus,
    rs.ApprovedAt
FROM Franchise.RevenueShareSettlement rs
JOIN Franchise.FranchisePartner f ON f.FranchiseID = rs.FranchiseID
JOIN [Identity].UserAccount u ON u.UserID = f.ContactUserID
JOIN Franchise.FranchiseContract fc ON fc.ContractID = rs.ContractID
WHERE NOT (COALESCE(CAST(SESSION_CONTEXT(N'RoleCode') AS NVARCHAR(40)), N'') = N'FranchisePartner' OR IS_ROLEMEMBER(N'db_ev_franchise_partner') = 1)
   OR f.ContactUserID = TRY_CONVERT(INT, SESSION_CONTEXT(N'UserID'));
GO

CREATE OR ALTER VIEW AppView.vw_ConnectorUtilization
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

CREATE OR ALTER VIEW AppView.vw_MaintenanceKPI
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

CREATE OR ALTER VIEW AppView.vw_PaymentSummary
AS
SELECT
    pt.PaymentMethod,
    pt.TransactionStatus,
    COUNT(*) AS TransactionCount,
    SUM(pt.Amount) AS TotalAmount
FROM Payments.PaymentTransaction pt
GROUP BY pt.PaymentMethod, pt.TransactionStatus;
GO

CREATE OR ALTER VIEW AppView.vw_AvailableChargingPoints
AS
SELECT
    r.RegionName,
    s.StationID,
    s.StationCode,
    s.StationName,
    s.StationStatus,
    p.PointID,
    p.PointCode,
    p.PointStatus,
    p.HealthStatus,
    ct.ConnectorCode,
    ct.ConnectorName,
    p.PowerKW
FROM Infrastructure.ChargingPoint p
JOIN Infrastructure.ChargingStation s ON s.StationID = p.StationID
JOIN Infrastructure.ConnectorType ct ON ct.ConnectorTypeID = p.ConnectorTypeID
LEFT JOIN Core.Address a ON a.AddressID = s.AddressID
LEFT JOIN Core.Region r ON r.RegionID = a.RegionID
WHERE s.StationStatus = N'Active'
  AND p.PointStatus = N'Available';
GO

CREATE OR ALTER VIEW AppView.vw_CustomerBookingHistory
AS
SELECT
    b.BookingID,
    b.BookingCode,
    b.UserID,
    u.Username,
    u.FullName,
    v.PlateNumber,
    s.StationCode,
    s.StationName,
    p.PointCode,
    b.BookedFrom,
    b.BookedTo,
    b.BookingStatus,
    b.CreatedAt,
    b.UpdatedAt
FROM Operations.Booking b
JOIN [Identity].UserAccount u ON u.UserID = b.UserID
LEFT JOIN Operations.Vehicle v ON v.VehicleID = b.VehicleID
JOIN Infrastructure.ChargingPoint p ON p.PointID = b.PointID
JOIN Infrastructure.ChargingStation s ON s.StationID = p.StationID
WHERE NOT (COALESCE(CAST(SESSION_CONTEXT(N'RoleCode') AS NVARCHAR(40)), N'') = N'Customer' OR IS_ROLEMEMBER(N'db_ev_customer') = 1)
   OR b.UserID = TRY_CONVERT(INT, SESSION_CONTEXT(N'UserID'));
GO

CREATE OR ALTER VIEW AppView.vw_InvoiceDetail
AS
SELECT
    i.InvoiceID,
    i.InvoiceCode,
    i.InvoiceStatus,
    i.IssuedAt,
    i.Subtotal,
    i.TaxAmount,
    i.TotalAmount,
    pt.TransactionCode,
    pt.PaymentMethod,
    pt.TransactionStatus,
    u.UserID,
    u.Username,
    u.FullName,
    cs.SessionCode,
    cs.StartTime,
    cs.EndTime,
    cs.TotalKWh,
    s.StationCode,
    s.StationName,
    p.PointCode
FROM Payments.Invoice i
JOIN Payments.PaymentTransaction pt ON pt.TransactionID = i.TransactionID
JOIN Operations.ChargingSession cs ON cs.SessionID = pt.SessionID
JOIN [Identity].UserAccount u ON u.UserID = cs.UserID
JOIN Infrastructure.ChargingStation s ON s.StationID = cs.StationID
JOIN Infrastructure.ChargingPoint p ON p.PointID = cs.PointID
WHERE NOT (COALESCE(CAST(SESSION_CONTEXT(N'RoleCode') AS NVARCHAR(40)), N'') = N'Customer' OR IS_ROLEMEMBER(N'db_ev_customer') = 1)
   OR cs.UserID = TRY_CONVERT(INT, SESSION_CONTEXT(N'UserID'));
GO

CREATE OR ALTER VIEW AppView.vw_ActiveChargingSessions
AS
SELECT
    cs.SessionID,
    cs.SessionCode,
    u.Username,
    u.FullName,
    v.PlateNumber,
    s.StationCode,
    s.StationName,
    p.PointCode,
    cs.StartTime,
    DATEDIFF(MINUTE, cs.StartTime, SYSDATETIME()) AS RunningMinutes,
    cs.SessionStatus
FROM Operations.ChargingSession cs
JOIN [Identity].UserAccount u ON u.UserID = cs.UserID
LEFT JOIN Operations.Vehicle v ON v.VehicleID = cs.VehicleID
JOIN Infrastructure.ChargingStation s ON s.StationID = cs.StationID
JOIN Infrastructure.ChargingPoint p ON p.PointID = cs.PointID
WHERE cs.SessionStatus = N'Charging';
GO

CREATE OR ALTER VIEW AppView.vw_StationStatusOverview
AS
SELECT
    s.StationID,
    s.StationCode,
    s.StationName,
    s.StationStatus,
    COUNT(p.PointID) AS TotalPoints,
    SUM(CASE WHEN p.PointStatus = N'Available' THEN 1 ELSE 0 END) AS AvailablePoints,
    SUM(CASE WHEN p.PointStatus = N'Charging' THEN 1 ELSE 0 END) AS ChargingPoints,
    SUM(CASE WHEN p.PointStatus IN (N'Error', N'Maintenance', N'Offline') THEN 1 ELSE 0 END) AS ProblemPoints,
    MAX(psh.ChangedAt) AS LastStatusChangeAt
FROM Infrastructure.ChargingStation s
LEFT JOIN Infrastructure.ChargingPoint p ON p.StationID = s.StationID
LEFT JOIN Infrastructure.PointStatusHistory psh ON psh.PointID = p.PointID
GROUP BY s.StationID, s.StationCode, s.StationName, s.StationStatus;
GO

CREATE OR ALTER VIEW AppView.vw_PeakHourStatistics
AS
SELECT
    DATEPART(HOUR, cs.StartTime) AS StartHour,
    COUNT(*) AS SessionCount,
    SUM(ISNULL(cs.TotalKWh, 0)) AS TotalKWh,
    SUM(ISNULL(cs.CostTotal, 0)) AS RevenueTotal
FROM Operations.ChargingSession cs
WHERE cs.SessionStatus = N'Completed'
GROUP BY DATEPART(HOUR, cs.StartTime);
GO

CREATE OR ALTER VIEW AppView.vw_TopRevenueStations
AS
SELECT
    s.StationID,
    s.StationCode,
    s.StationName,
    COUNT(cs.SessionID) AS CompletedSessions,
    SUM(ISNULL(cs.TotalKWh, 0)) AS TotalKWh,
    SUM(ISNULL(cs.CostTotal, 0)) AS RevenueTotal
FROM Infrastructure.ChargingStation s
LEFT JOIN Operations.ChargingSession cs ON cs.StationID = s.StationID AND cs.SessionStatus = N'Completed'
GROUP BY s.StationID, s.StationCode, s.StationName;
GO

CREATE OR ALTER VIEW AppView.vw_CustomerGrowth
AS
SELECT
    YEAR(u.CreatedAt) AS CreatedYear,
    MONTH(u.CreatedAt) AS CreatedMonth,
    COUNT(*) AS NewCustomers
FROM [Identity].UserAccount u
JOIN [Identity].UserRole ur ON ur.UserID = u.UserID
JOIN [Identity].[Role] r ON r.RoleID = ur.RoleID
WHERE r.RoleCode = N'Customer'
GROUP BY YEAR(u.CreatedAt), MONTH(u.CreatedAt);
GO

CREATE OR ALTER VIEW AppView.vw_SystemOperationalKPI
AS
SELECT
    (SELECT COUNT(*) FROM Infrastructure.ChargingStation WHERE StationStatus <> N'Retired') AS ActiveStations,
    (SELECT COUNT(*) FROM Infrastructure.ChargingPoint WHERE PointStatus <> N'Retired') AS ActivePoints,
    (SELECT COUNT(*) FROM Operations.ChargingSession WHERE SessionStatus = N'Charging') AS ActiveSessions,
    (SELECT COUNT(*) FROM Operations.ChargingSession WHERE SessionStatus = N'Completed') AS CompletedSessions,
    (SELECT COUNT(*) FROM Operations.ChargingSession WHERE SessionStatus = N'Failed') AS FailedSessions,
    (SELECT COUNT(*) FROM Maintenance.MaintenanceTicket WHERE TicketStatus IN (N'Open', N'Assigned', N'InProgress')) AS OpenTickets,
    (SELECT SUM(ISNULL(CostTotal, 0)) FROM Operations.ChargingSession WHERE SessionStatus = N'Completed') AS TotalRevenue;
GO

CREATE OR ALTER VIEW AppView.vw_RegionRevenue
AS
SELECT
    r.RegionID,
    r.RegionName,
    COUNT(DISTINCT s.StationID) AS StationCount,
    COUNT(cs.SessionID) AS CompletedSessions,
    SUM(ISNULL(cs.TotalKWh, 0)) AS TotalKWh,
    SUM(ISNULL(cs.CostTotal, 0)) AS RevenueTotal
FROM Core.Region r
JOIN Core.Address a ON a.RegionID = r.RegionID
JOIN Infrastructure.ChargingStation s ON s.AddressID = a.AddressID
LEFT JOIN Operations.ChargingSession cs ON cs.StationID = s.StationID AND cs.SessionStatus = N'Completed'
GROUP BY r.RegionID, r.RegionName;
GO

CREATE OR ALTER VIEW AppView.vw_UserRoleSummary
AS
SELECT
    u.UserID,
    u.Username,
    u.FullName,
    u.Email,
    u.Phone,
    u.AccountStatus,
    STRING_AGG(r.RoleCode, N', ') AS RoleCodes
FROM [Identity].UserAccount u
LEFT JOIN [Identity].UserRole ur ON ur.UserID = u.UserID
LEFT JOIN [Identity].[Role] r ON r.RoleID = ur.RoleID
GROUP BY u.UserID, u.Username, u.FullName, u.Email, u.Phone, u.AccountStatus;
GO

CREATE OR ALTER VIEW AppView.vw_ChargingSessionStatistics
AS
SELECT
    CAST(cs.StartTime AS DATE) AS SessionDate,
    cs.SessionStatus,
    COUNT(*) AS SessionCount,
    SUM(ISNULL(cs.TotalKWh, 0)) AS TotalKWh,
    SUM(ISNULL(cs.CostTotal, 0)) AS RevenueTotal,
    AVG(CASE WHEN cs.EndTime IS NOT NULL THEN DATEDIFF(MINUTE, cs.StartTime, cs.EndTime) END) AS AvgDurationMinutes
FROM Operations.ChargingSession cs
GROUP BY CAST(cs.StartTime AS DATE), cs.SessionStatus;
GO

CREATE OR ALTER VIEW AppView.vw_TopCustomerUsage
AS
SELECT
    u.UserID,
    u.Username,
    u.FullName,
    COUNT(cs.SessionID) AS CompletedSessions,
    SUM(ISNULL(cs.TotalKWh, 0)) AS TotalKWh,
    SUM(ISNULL(cs.CostTotal, 0)) AS TotalSpend
FROM [Identity].UserAccount u
JOIN Operations.ChargingSession cs ON cs.UserID = u.UserID AND cs.SessionStatus = N'Completed'
GROUP BY u.UserID, u.Username, u.FullName;
GO

CREATE OR ALTER PROCEDURE AppView.sp_GetStationRevenue
    @FromDate DATE = NULL,
    @ToDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT StationCode, StationName, FranchiseName,
           SUM(CompletedSessions) AS CompletedSessions,
           SUM(TotalKWh) AS TotalKWh,
           SUM(RevenueTotal) AS RevenueTotal
    FROM AppView.vw_StationRevenueDaily
    WHERE (@FromDate IS NULL OR RevenueDate >= @FromDate)
      AND (@ToDate IS NULL OR RevenueDate <= @ToDate)
    GROUP BY StationCode, StationName, FranchiseName
    ORDER BY RevenueTotal DESC;
END;
GO

CREATE OR ALTER PROCEDURE AppView.sp_GetFranchiseProfitSharing
AS
BEGIN
    SET NOCOUNT ON;
    SELECT SettlementCode, FranchiseCode, FranchiseName, PeriodStart, PeriodEnd,
           GrossRevenue, PartnerShareAmount, PlatformShareAmount, SettlementStatus
    FROM AppView.vw_ProfitSharing
    ORDER BY PeriodEnd DESC, GrossRevenue DESC;
END;
GO

CREATE OR ALTER PROCEDURE AppView.sp_GetMyFranchiseProfile
AS
BEGIN
    SET NOCOUNT ON;
    SELECT FranchiseID, FranchiseCode, FranchiseName, TaxCode, ContactPerson,
           ContactPhone, ContactEmail, PartnerStatus, FullAddress
    FROM AppView.vw_MyFranchiseProfile;
END;
GO

CREATE OR ALTER PROCEDURE AppView.sp_GetMyFranchiseContracts
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ContractID, FranchiseCode, FranchiseName, ContractCode, StartDate,
           EndDate, BaseRevenueShareRate, ContractStatus
    FROM AppView.vw_MyFranchiseContracts
    ORDER BY StartDate DESC, ContractCode;
END;
GO

CREATE OR ALTER PROCEDURE AppView.sp_GetMyFranchiseStations
AS
BEGIN
    SET NOCOUNT ON;
    SELECT StationID, StationCode, StationName, MaxPowerKW, StationStatus,
           ContractCode, FullAddress
    FROM AppView.vw_MyFranchiseStations
    ORDER BY StationCode;
END;
GO

CREATE OR ALTER PROCEDURE AppView.sp_GetMyRevenueSharePolicies
AS
BEGIN
    SET NOCOUNT ON;
    SELECT RevenueSharePolicyID, FranchiseCode, FranchiseName, ContractCode,
           PolicyCode, PartnerShareRate, PlatformShareRate, AppliedFrom,
           AppliedTo, IsActive
    FROM AppView.vw_MyRevenueSharePolicies
    ORDER BY IsActive DESC, AppliedFrom DESC, PolicyCode;
END;
GO

CREATE OR ALTER PROCEDURE AppView.sp_GetMyRevenueShareSettlements
AS
BEGIN
    SET NOCOUNT ON;
    SELECT SettlementID, SettlementCode, FranchiseCode, FranchiseName,
           ContractCode, PeriodStart, PeriodEnd, GrossRevenue,
           PartnerShareAmount, PlatformShareAmount, SettlementStatus,
           ApprovedAt
    FROM AppView.vw_MyRevenueShareSettlements
    ORDER BY PeriodEnd DESC, SettlementCode;
END;
GO

CREATE OR ALTER PROCEDURE AppView.sp_GetOperationalKPI
AS
BEGIN
    SET NOCOUNT ON;
    SELECT StationCode, StationName, TicketCount, OpenTicketCount, ErrorCount, ActiveErrorCount, AvgResolveHours
    FROM AppView.vw_MaintenanceKPI
    ORDER BY ActiveErrorCount DESC, OpenTicketCount DESC, StationCode;
END;
GO

CREATE OR ALTER PROCEDURE AppView.sp_GetPaymentSummary
AS
BEGIN
    SET NOCOUNT ON;
    SELECT PaymentMethod, TransactionStatus, TransactionCount, TotalAmount
    FROM AppView.vw_PaymentSummary
    ORDER BY TransactionStatus, PaymentMethod;
END;
GO

CREATE OR ALTER PROCEDURE AppView.sp_GetCustomerUsage
    @Top INT = 10
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP (@Top) Username, FullName,
           COUNT(SessionID) AS CompletedSessions,
           SUM(ISNULL(TotalKWh, 0)) AS TotalKWh,
           SUM(ISNULL(CostTotal, 0)) AS TotalSpend
    FROM AppView.vw_CustomerChargingHistory
    WHERE SessionStatus = N'Completed'
    GROUP BY Username, FullName
    ORDER BY TotalSpend DESC, CompletedSessions DESC;
END;
GO

CREATE OR ALTER PROCEDURE AppView.sp_GetTelemetryHealth
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

CREATE OR ALTER VIEW AppView.vw_CurrentUserProfile
AS
SELECT
    u.UserID,
    u.Username,
    u.FullName,
    u.Email,
    u.Phone,
    u.AccountStatus,
    STRING_AGG(r.RoleCode, N',') AS RoleCodes,
    STRING_AGG(r.RoleName, N', ') AS RoleNames,
    u.LastLoginAt,
    u.CreatedAt,
    u.UpdatedAt
FROM [Identity].UserAccount u
JOIN [Identity].UserRole ur ON ur.UserID = u.UserID
JOIN [Identity].[Role] r ON r.RoleID = ur.RoleID
WHERE u.UserID = TRY_CONVERT(INT, SESSION_CONTEXT(N'UserID'))
GROUP BY u.UserID, u.Username, u.FullName, u.Email, u.Phone, u.AccountStatus, u.LastLoginAt, u.CreatedAt, u.UpdatedAt;
GO

CREATE OR ALTER PROCEDURE AppView.sp_GetCurrentUserProfile
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM AppView.vw_CurrentUserProfile;
END;
GO

CREATE OR ALTER VIEW AppView.vw_MyVehicles
AS
SELECT
    v.VehicleID,
    v.UserID,
    v.PlateNumber,
    v.Brand,
    v.Model,
    v.BatteryCapacityKWh,
    v.PreferredConnectorTypeID,
    ct.ConnectorCode,
    ct.ConnectorName,
    v.IsActive,
    v.CreatedAt
FROM Operations.Vehicle v
LEFT JOIN Infrastructure.ConnectorType ct ON ct.ConnectorTypeID = v.PreferredConnectorTypeID
WHERE v.UserID = TRY_CONVERT(INT, SESSION_CONTEXT(N'UserID'));
GO

CREATE OR ALTER VIEW AppView.vw_PricingPolicies
AS
SELECT
    PolicyID,
    PolicyCode,
    PolicyName,
    BasePricePerKWh,
    PeakMultiplier,
    PeakStartHour,
    PeakEndHour,
    AppliedFrom,
    AppliedTo,
    IsActive
FROM Operations.PricingPolicy;
GO

CREATE OR ALTER VIEW AppView.vw_RefundablePayments
AS
SELECT
    pt.TransactionID,
    pt.TransactionCode,
    pt.TransactionStatus,
    pt.PaymentMethod,
    pt.Amount,
    pt.PaidAt,
    pt.CreatedAt,
    u.UserID,
    u.Username,
    u.FullName,
    cs.SessionID,
    cs.SessionCode,
    i.InvoiceID,
    i.InvoiceCode,
    i.InvoiceStatus,
    s.StationCode,
    s.StationName,
    p.PointCode
FROM Payments.PaymentTransaction pt
JOIN [Identity].UserAccount u ON u.UserID = pt.UserID
JOIN Operations.ChargingSession cs ON cs.SessionID = pt.SessionID
LEFT JOIN Payments.Invoice i ON i.TransactionID = pt.TransactionID
JOIN Infrastructure.ChargingStation s ON s.StationID = cs.StationID
JOIN Infrastructure.ChargingPoint p ON p.PointID = cs.PointID
WHERE pt.TransactionStatus = N'Completed';
GO

CREATE OR ALTER VIEW AppView.vw_MaintenanceTickets
AS
SELECT
    mt.TicketID,
    mt.TicketCode,
    mt.Priority,
    mt.TicketStatus,
    mt.Title,
    mt.Description,
    mt.OpenedAt,
    mt.ClosedAt,
    s.StationID,
    s.StationCode,
    s.StationName,
    p.PointID,
    p.PointCode,
    createdBy.Username AS CreatedByUsername,
    createdBy.FullName AS CreatedByFullName,
    assignedTo.Username AS AssignedToUsername,
    assignedTo.FullName AS AssignedToFullName
FROM Maintenance.MaintenanceTicket mt
LEFT JOIN Infrastructure.ChargingStation s ON s.StationID = mt.StationID
LEFT JOIN Infrastructure.ChargingPoint p ON p.PointID = mt.PointID
LEFT JOIN [Identity].UserAccount createdBy ON createdBy.UserID = mt.CreatedBy
LEFT JOIN [Identity].UserAccount assignedTo ON assignedTo.UserID = mt.AssignedTo;
GO

CREATE OR ALTER VIEW AppView.vw_ErrorLogActive
AS
SELECT
    e.ErrorID,
    e.ErrorCode,
    e.Severity,
    e.Description,
    e.OccurredAt,
    e.ResolvedAt,
    e.IsActive,
    s.StationID,
    s.StationCode,
    s.StationName,
    p.PointID,
    p.PointCode
FROM Maintenance.ErrorLog e
LEFT JOIN Infrastructure.ChargingStation s ON s.StationID = e.StationID
LEFT JOIN Infrastructure.ChargingPoint p ON p.PointID = e.PointID
WHERE e.IsActive = 1;
GO

CREATE OR ALTER VIEW AppView.vw_AuditLogRecent
AS
SELECT TOP (1000)
    AuditID,
    SchemaName,
    TableName,
    RecordID,
    ActionType,
    ChangedBy,
    ChangedAt,
    OldValues,
    NewValues
FROM Audit.AuditLog
ORDER BY ChangedAt DESC, AuditID DESC;
GO

PRINT N'07 - Application data views and query procedures created.';
GO
