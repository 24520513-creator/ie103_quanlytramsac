==============================================================================
-- 4.5.5 Nhom View phuc vu quan ly kinh doanh
==============================================================================


==============================================================================
-- AppView.vw_StationRevenueDaily
==============================================================================

--database/07_Create_AppViews.sql
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

-- >>> TEST: cau lenh truy van view
USE EV_Charging_System;
GO
SELECT TOP (20) * FROM AppView.vw_StationRevenueDaily;


==============================================================================
-- AppView.vw_StationRevenueByYear
==============================================================================

--database/07_Create_AppViews.sql
CREATE OR ALTER VIEW AppView.vw_StationRevenueByYear
AS
SELECT
    s.StationID,
    s.StationCode,
    s.StationName,
    YEAR(cs.StartTime)              AS RevenueYear,
    COUNT(cs.SessionID)             AS CompletedSessions,
    SUM(ISNULL(cs.TotalKWh, 0))     AS TotalKWh,
    SUM(ISNULL(cs.CostTotal, 0))    AS RevenueTotal
FROM Operations.ChargingSession cs
JOIN Infrastructure.ChargingStation s ON s.StationID = cs.StationID
WHERE cs.SessionStatus = N'Completed'
GROUP BY s.StationID, s.StationCode, s.StationName, YEAR(cs.StartTime);

-- >>> TEST: cau lenh truy van view
USE EV_Charging_System;
GO
SELECT TOP (20) * FROM AppView.vw_StationRevenueByYear;


==============================================================================
-- AppView.vw_FranchiseRevenueMonthly
==============================================================================

--database/07_Create_AppViews.sql
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

-- >>> TEST: cau lenh truy van view
USE EV_Charging_System;
GO
SELECT TOP (20) * FROM AppView.vw_FranchiseRevenueMonthly;


==============================================================================
-- AppView.vw_RegionRevenue
==============================================================================

--database/07_Create_AppViews.sql
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

-- >>> TEST: cau lenh truy van view
USE EV_Charging_System;
GO
SELECT TOP (20) * FROM AppView.vw_RegionRevenue;


==============================================================================
-- AppView.vw_TopRevenueStations
==============================================================================

--database/07_Create_AppViews.sql
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

-- >>> TEST: cau lenh truy van view
USE EV_Charging_System;
GO
SELECT TOP (20) * FROM AppView.vw_TopRevenueStations;


==============================================================================
-- AppView.vw_TopCustomerUsage
==============================================================================

--database/07_Create_AppViews.sql
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

-- >>> TEST: cau lenh truy van view
USE EV_Charging_System;
GO
SELECT TOP (20) * FROM AppView.vw_TopCustomerUsage;


==============================================================================
-- AppView.vw_PeakHourStatistics
==============================================================================

--database/07_Create_AppViews.sql
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

-- >>> TEST: cau lenh truy van view
USE EV_Charging_System;
GO
SELECT TOP (20) * FROM AppView.vw_PeakHourStatistics;


==============================================================================
-- AppView.vw_ChargingSessionStatistics
==============================================================================

--database/07_Create_AppViews.sql
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

-- >>> TEST: cau lenh truy van view
USE EV_Charging_System;
GO
SELECT TOP (20) * FROM AppView.vw_ChargingSessionStatistics;


==============================================================================
-- AppView.vw_CustomerGrowth
==============================================================================

--database/07_Create_AppViews.sql
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

-- >>> TEST: cau lenh truy van view
USE EV_Charging_System;
GO
SELECT TOP (20) * FROM AppView.vw_CustomerGrowth;


==============================================================================
-- AppView.vw_PaymentSummary
==============================================================================

--database/07_Create_AppViews.sql
CREATE OR ALTER VIEW AppView.vw_PaymentSummary
AS
SELECT
    pt.PaymentMethod,
    pt.TransactionStatus,
    COUNT(*) AS TransactionCount,
    SUM(pt.Amount) AS TotalAmount
FROM Payments.PaymentTransaction pt
GROUP BY pt.PaymentMethod, pt.TransactionStatus;

-- >>> TEST: cau lenh truy van view
USE EV_Charging_System;
GO
SELECT TOP (20) * FROM AppView.vw_PaymentSummary;


==============================================================================
-- AppView.vw_RefundablePayments
==============================================================================

--database/07_Create_AppViews.sql
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

-- >>> TEST: cau lenh truy van view
USE EV_Charging_System;
GO
SELECT TOP (20) * FROM AppView.vw_RefundablePayments;


==============================================================================
-- AppView.vw_PricingPolicies
==============================================================================

--database/07_Create_AppViews.sql
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

-- >>> TEST: cau lenh truy van view
USE EV_Charging_System;
GO
SELECT TOP (20) * FROM AppView.vw_PricingPolicies;


==============================================================================
-- AppView.vw_ProfitSharing
==============================================================================

--database/07_Create_AppViews.sql
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

-- >>> TEST: cau lenh truy van view
USE EV_Charging_System;
GO
SELECT TOP (20) * FROM AppView.vw_ProfitSharing;


==============================================================================
-- AppView.vw_ConnectorUtilization
==============================================================================

--database/07_Create_AppViews.sql
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

-- >>> TEST: cau lenh truy van view
USE EV_Charging_System;
GO
SELECT TOP (20) * FROM AppView.vw_ConnectorUtilization;


==============================================================================
-- AppView.vw_SystemOperationalKPI
==============================================================================

--database/07_Create_AppViews.sql
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

-- >>> TEST: cau lenh truy van view
USE EV_Charging_System;
GO
SELECT TOP (20) * FROM AppView.vw_SystemOperationalKPI;
