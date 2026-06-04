==============================================================================
-- 4.5.9 Nhom View ho tro Web UI
==============================================================================


==============================================================================
-- AppView.vw_WebLookupConnectorTypes
==============================================================================

--database/07_Create_AppViews.sql
CREATE OR ALTER VIEW AppView.vw_WebLookupConnectorTypes
AS
SELECT
    ConnectorTypeID,
    ConnectorCode,
    ConnectorName,
    MaxPowerKW,
    IsActive
FROM Infrastructure.ConnectorType
WHERE IsActive = 1;

-- >>> TEST: cau lenh truy van view
USE EV_Charging_System;
GO
SELECT TOP (20) * FROM AppView.vw_WebLookupConnectorTypes;


==============================================================================
-- AppView.vw_WebLookupCustomerVehicles
==============================================================================

--database/07_Create_AppViews.sql
CREATE OR ALTER VIEW AppView.vw_WebLookupCustomerVehicles
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

-- >>> TEST: cau lenh truy van view
USE EV_Charging_System;
GO
-- View nay LOC theo nguoi dang nhap (RLS) -> phai set SESSION_CONTEXT truoc, neu khong se rong.
EXEC sys.sp_set_session_context @key = N'UserID',   @value = 52;         -- customer01
EXEC sys.sp_set_session_context @key = N'RoleCode', @value = N'Customer';
SELECT TOP (20) * FROM AppView.vw_WebLookupCustomerVehicles;


==============================================================================
-- AppView.vw_WebLookupAvailablePoints
==============================================================================

--database/07_Create_AppViews.sql
CREATE OR ALTER VIEW AppView.vw_WebLookupAvailablePoints
AS
SELECT
    r.RegionName,
    s.StationID,
    s.StationCode,
    s.StationName,
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
  AND p.PointStatus = N'Available'
  AND p.HealthStatus <> N'Offline';

-- >>> TEST: cau lenh truy van view
USE EV_Charging_System;
GO
SELECT TOP (20) * FROM AppView.vw_WebLookupAvailablePoints;


==============================================================================
-- AppView.vw_WebLookupCustomerBookings
==============================================================================

--database/07_Create_AppViews.sql
CREATE OR ALTER VIEW AppView.vw_WebLookupCustomerBookings
AS
SELECT
    b.BookingID,
    b.BookingCode,
    b.UserID,
    b.VehicleID,
    b.PointID,
    b.StationID,
    v.PlateNumber,
    s.StationCode,
    s.StationName,
    p.PointCode,
    b.BookedFrom,
    b.BookedTo,
    b.BookingStatus,
    b.CreatedAt
FROM Operations.Booking b
LEFT JOIN Operations.Vehicle v ON v.VehicleID = b.VehicleID
JOIN Infrastructure.ChargingPoint p ON p.PointID = b.PointID
JOIN Infrastructure.ChargingStation s ON s.StationID = b.StationID
WHERE b.UserID = TRY_CONVERT(INT, SESSION_CONTEXT(N'UserID'));

-- >>> TEST: cau lenh truy van view
USE EV_Charging_System;
GO
-- View nay LOC theo nguoi dang nhap (RLS) -> phai set SESSION_CONTEXT truoc, neu khong se rong.
EXEC sys.sp_set_session_context @key = N'UserID',   @value = 52;         -- customer01
EXEC sys.sp_set_session_context @key = N'RoleCode', @value = N'Customer';
SELECT TOP (20) * FROM AppView.vw_WebLookupCustomerBookings;


==============================================================================
-- AppView.vw_WebLookupCustomerSessions
==============================================================================

--database/07_Create_AppViews.sql
CREATE OR ALTER VIEW AppView.vw_WebLookupCustomerSessions
AS
SELECT
    cs.SessionID,
    cs.SessionCode,
    cs.UserID,
    cs.VehicleID,
    cs.PointID,
    cs.StationID,
    cs.BookingID,
    v.PlateNumber,
    s.StationCode,
    s.StationName,
    p.PointCode,
    cs.StartTime,
    cs.EndTime,
    cs.TotalKWh,
    cs.CostTotal,
    cs.SessionStatus,
    CAST(CASE WHEN EXISTS (
        SELECT 1
        FROM Payments.PaymentTransaction pt
        WHERE pt.SessionID = cs.SessionID
          AND pt.TransactionStatus = N'Completed'
    ) THEN 1 ELSE 0 END AS BIT) AS HasCompletedPayment,
    CAST(CASE WHEN EXISTS (
        SELECT 1
        FROM Payments.Invoice i
        WHERE i.SessionID = cs.SessionID
    ) THEN 1 ELSE 0 END AS BIT) AS HasInvoice
FROM Operations.ChargingSession cs
LEFT JOIN Operations.Vehicle v ON v.VehicleID = cs.VehicleID
JOIN Infrastructure.ChargingStation s ON s.StationID = cs.StationID
JOIN Infrastructure.ChargingPoint p ON p.PointID = cs.PointID
WHERE cs.UserID = TRY_CONVERT(INT, SESSION_CONTEXT(N'UserID'));

-- >>> TEST: cau lenh truy van view
USE EV_Charging_System;
GO
-- View nay LOC theo nguoi dang nhap (RLS) -> phai set SESSION_CONTEXT truoc, neu khong se rong.
EXEC sys.sp_set_session_context @key = N'UserID',   @value = 52;         -- customer01
EXEC sys.sp_set_session_context @key = N'RoleCode', @value = N'Customer';
SELECT TOP (20) * FROM AppView.vw_WebLookupCustomerSessions;


==============================================================================
-- AppView.vw_WebLookupStations
==============================================================================

--database/07_Create_AppViews.sql
CREATE OR ALTER VIEW AppView.vw_WebLookupStations
AS
SELECT
    s.StationID,
    s.StationCode,
    s.StationName,
    s.StationStatus,
    s.MaxPowerKW,
    a.FullAddress
FROM Infrastructure.ChargingStation s
LEFT JOIN Core.Address a ON a.AddressID = s.AddressID
WHERE s.StationStatus <> N'Retired';

-- >>> TEST: cau lenh truy van view
USE EV_Charging_System;
GO
SELECT TOP (20) * FROM AppView.vw_WebLookupStations;


==============================================================================
-- AppView.vw_WebLookupPoints
==============================================================================

--database/07_Create_AppViews.sql
CREATE OR ALTER VIEW AppView.vw_WebLookupPoints
AS
SELECT
    p.PointID,
    p.PointCode,
    p.StationID,
    s.StationCode,
    s.StationName,
    p.PointStatus,
    p.HealthStatus,
    ct.ConnectorCode,
    ct.ConnectorName,
    p.PowerKW
FROM Infrastructure.ChargingPoint p
JOIN Infrastructure.ChargingStation s ON s.StationID = p.StationID
JOIN Infrastructure.ConnectorType ct ON ct.ConnectorTypeID = p.ConnectorTypeID
WHERE p.PointStatus <> N'Retired';

-- >>> TEST: cau lenh truy van view
USE EV_Charging_System;
GO
SELECT TOP (20) * FROM AppView.vw_WebLookupPoints;


==============================================================================
-- AppView.vw_WebLookupActiveSessions
==============================================================================

--database/07_Create_AppViews.sql
CREATE OR ALTER VIEW AppView.vw_WebLookupActiveSessions
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
    cs.SessionStatus
FROM Operations.ChargingSession cs
JOIN [Identity].UserAccount u ON u.UserID = cs.UserID
LEFT JOIN Operations.Vehicle v ON v.VehicleID = cs.VehicleID
JOIN Infrastructure.ChargingStation s ON s.StationID = cs.StationID
JOIN Infrastructure.ChargingPoint p ON p.PointID = cs.PointID
WHERE cs.SessionStatus = N'Charging';

-- >>> TEST: cau lenh truy van view
USE EV_Charging_System;
GO
SELECT TOP (20) * FROM AppView.vw_WebLookupActiveSessions;


==============================================================================
-- AppView.vw_WebLookupOpenTickets
==============================================================================

--database/07_Create_AppViews.sql
CREATE OR ALTER VIEW AppView.vw_WebLookupOpenTickets
AS
SELECT
    mt.TicketID,
    mt.TicketCode,
    mt.Priority,
    mt.TicketStatus,
    mt.Title,
    mt.OpenedAt,
    s.StationCode,
    s.StationName,
    p.PointCode,
    assignedTo.Username AS AssignedToUsername,
    assignedTo.FullName AS AssignedToFullName
FROM Maintenance.MaintenanceTicket mt
LEFT JOIN Infrastructure.ChargingStation s ON s.StationID = mt.StationID
LEFT JOIN Infrastructure.ChargingPoint p ON p.PointID = mt.PointID
LEFT JOIN [Identity].UserAccount assignedTo ON assignedTo.UserID = mt.AssignedTo
WHERE mt.TicketStatus IN (N'Open', N'Assigned', N'InProgress', N'Resolved');

-- >>> TEST: cau lenh truy van view
USE EV_Charging_System;
GO
SELECT TOP (20) * FROM AppView.vw_WebLookupOpenTickets;


==============================================================================
-- AppView.vw_WebLookupOperationsStaff
==============================================================================

--database/07_Create_AppViews.sql
CREATE OR ALTER VIEW AppView.vw_WebLookupOperationsStaff
AS
SELECT DISTINCT
    u.UserID,
    u.Username,
    u.FullName,
    u.Email,
    u.AccountStatus
FROM [Identity].UserAccount u
JOIN [Identity].UserRole ur ON ur.UserID = u.UserID
JOIN [Identity].[Role] r ON r.RoleID = ur.RoleID
WHERE r.RoleCode = N'OperationsStaff'
  AND u.AccountStatus = N'Active';

-- >>> TEST: cau lenh truy van view
USE EV_Charging_System;
GO
SELECT TOP (20) * FROM AppView.vw_WebLookupOperationsStaff;


==============================================================================
-- AppView.vw_WebLookupPricingPolicies
==============================================================================

--database/07_Create_AppViews.sql
CREATE OR ALTER VIEW AppView.vw_WebLookupPricingPolicies
AS
SELECT
    PolicyID,
    PolicyCode,
    PolicyName,
    BasePricePerKWh,
    PeakMultiplier,
    AppliedFrom,
    AppliedTo,
    IsActive
FROM Operations.PricingPolicy;

-- >>> TEST: cau lenh truy van view
USE EV_Charging_System;
GO
SELECT TOP (20) * FROM AppView.vw_WebLookupPricingPolicies;


==============================================================================
-- AppView.vw_WebLookupRevenueSharePolicies
==============================================================================

--database/07_Create_AppViews.sql
CREATE OR ALTER VIEW AppView.vw_WebLookupRevenueSharePolicies
AS
SELECT
    rsp.RevenueSharePolicyID,
    f.FranchiseID,
    f.FranchiseCode,
    f.FranchiseName,
    fc.ContractID,
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
WHERE rsp.IsActive = 1
  AND fc.ContractStatus = N'Active'
  AND f.PartnerStatus = N'Active';

-- >>> TEST: cau lenh truy van view
USE EV_Charging_System;
GO
SELECT TOP (20) * FROM AppView.vw_WebLookupRevenueSharePolicies;


==============================================================================
-- AppView.vw_WebLookupFranchises
==============================================================================

--database/07_Create_AppViews.sql
CREATE OR ALTER VIEW AppView.vw_WebLookupFranchises
AS
SELECT
    FranchiseID,
    FranchiseCode,
    FranchiseName,
    PartnerStatus,
    ContactPerson,
    ContactPhone,
    ContactEmail
FROM Franchise.FranchisePartner;

-- >>> TEST: cau lenh truy van view
USE EV_Charging_System;
GO
SELECT TOP (20) * FROM AppView.vw_WebLookupFranchises;


==============================================================================
-- AppView.vw_WebLookupRefundablePayments
==============================================================================

--database/07_Create_AppViews.sql
CREATE OR ALTER VIEW AppView.vw_WebLookupRefundablePayments
AS
SELECT
    pt.TransactionID,
    pt.TransactionCode,
    pt.PaymentMethod,
    pt.Amount,
    pt.PaidAt,
    pt.TransactionStatus,
    u.UserID,
    u.Username,
    u.FullName,
    cs.SessionID,
    cs.SessionCode,
    i.InvoiceID,
    i.InvoiceCode,
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
SELECT TOP (20) * FROM AppView.vw_WebLookupRefundablePayments;


==============================================================================
-- AppView.vw_WebLookupUsers
==============================================================================

--database/07_Create_AppViews.sql
CREATE OR ALTER VIEW AppView.vw_WebLookupUsers
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

-- >>> TEST: cau lenh truy van view
USE EV_Charging_System;
GO
SELECT TOP (20) * FROM AppView.vw_WebLookupUsers;


==============================================================================
-- AppView.vw_WebLookupAssignableRoles
==============================================================================

--database/07_Create_AppViews.sql
CREATE OR ALTER VIEW AppView.vw_WebLookupAssignableRoles
AS
SELECT
    u.UserID,
    r.RoleCode,
    r.RoleName
FROM [Identity].UserAccount u
CROSS JOIN [Identity].[Role] r
WHERE NOT EXISTS (
    SELECT 1
    FROM [Identity].UserRole ur
    WHERE ur.UserID = u.UserID
      AND ur.RoleID = r.RoleID
);

-- >>> TEST: cau lenh truy van view
USE EV_Charging_System;
GO
SELECT TOP (20) * FROM AppView.vw_WebLookupAssignableRoles;


==============================================================================
-- AppView.vw_WebLookupRemovableRoles
==============================================================================

--database/07_Create_AppViews.sql
CREATE OR ALTER VIEW AppView.vw_WebLookupRemovableRoles
AS
SELECT
    ur.UserID,
    r.RoleCode,
    r.RoleName
FROM [Identity].UserRole ur
JOIN [Identity].[Role] r ON r.RoleID = ur.RoleID;

-- >>> TEST: cau lenh truy van view
USE EV_Charging_System;
GO
SELECT TOP (20) * FROM AppView.vw_WebLookupRemovableRoles;
