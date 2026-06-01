USE EV_Charging_System;
GO

/*
BonusSQL - Web lookup views for Business Manager and System Admin flows.
These views keep web object selection separate from the original schema and
business procedures.
*/

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
GO

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
GO

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
GO

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
GO

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
GO

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
GO

CREATE OR ALTER VIEW AppView.vw_WebLookupRemovableRoles
AS
SELECT
    ur.UserID,
    r.RoleCode,
    r.RoleName
FROM [Identity].UserRole ur
JOIN [Identity].[Role] r ON r.RoleID = ur.RoleID;
GO

GRANT SELECT ON OBJECT::AppView.vw_WebLookupPricingPolicies TO db_ev_business_manager;
GRANT SELECT ON OBJECT::AppView.vw_WebLookupRevenueSharePolicies TO db_ev_business_manager;
GRANT SELECT ON OBJECT::AppView.vw_WebLookupFranchises TO db_ev_business_manager;
GRANT SELECT ON OBJECT::AppView.vw_WebLookupRefundablePayments TO db_ev_business_manager;

GRANT SELECT ON OBJECT::AppView.vw_WebLookupPricingPolicies TO db_ev_system_admin;
GRANT SELECT ON OBJECT::AppView.vw_WebLookupRevenueSharePolicies TO db_ev_system_admin;
GRANT SELECT ON OBJECT::AppView.vw_WebLookupFranchises TO db_ev_system_admin;
GRANT SELECT ON OBJECT::AppView.vw_WebLookupRefundablePayments TO db_ev_system_admin;
GRANT SELECT ON OBJECT::AppView.vw_WebLookupUsers TO db_ev_system_admin;
GRANT SELECT ON OBJECT::AppView.vw_WebLookupAssignableRoles TO db_ev_system_admin;
GRANT SELECT ON OBJECT::AppView.vw_WebLookupRemovableRoles TO db_ev_system_admin;
GO

PRINT N'BonusSQL 03 - Business/Admin web lookup views created.';
GO
