==============================================================================
-- 4.5.8 Nhom View phuc vu franchise partner
==============================================================================


==============================================================================
-- AppView.vw_MyFranchiseProfile
==============================================================================

--database/07_Create_AppViews.sql
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

-- >>> TEST: cau lenh truy van view
USE EV_Charging_System;
GO
-- View nay LOC theo nguoi dang nhap (RLS) -> phai set SESSION_CONTEXT truoc, neu khong se rong.
EXEC sys.sp_set_session_context @key = N'UserID',   @value = 37;         -- franchise01
EXEC sys.sp_set_session_context @key = N'RoleCode', @value = N'FranchisePartner';
SELECT TOP (20) * FROM AppView.vw_MyFranchiseProfile;


==============================================================================
-- AppView.vw_MyFranchiseContracts
==============================================================================

--database/07_Create_AppViews.sql
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

-- >>> TEST: cau lenh truy van view
USE EV_Charging_System;
GO
-- View nay LOC theo nguoi dang nhap (RLS) -> phai set SESSION_CONTEXT truoc, neu khong se rong.
EXEC sys.sp_set_session_context @key = N'UserID',   @value = 37;         -- franchise01
EXEC sys.sp_set_session_context @key = N'RoleCode', @value = N'FranchisePartner';
SELECT TOP (20) * FROM AppView.vw_MyFranchiseContracts;


==============================================================================
-- AppView.vw_MyFranchiseStations
==============================================================================

--database/07_Create_AppViews.sql
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

-- >>> TEST: cau lenh truy van view
USE EV_Charging_System;
GO
-- View nay LOC theo nguoi dang nhap (RLS) -> phai set SESSION_CONTEXT truoc, neu khong se rong.
EXEC sys.sp_set_session_context @key = N'UserID',   @value = 37;         -- franchise01
EXEC sys.sp_set_session_context @key = N'RoleCode', @value = N'FranchisePartner';
SELECT TOP (20) * FROM AppView.vw_MyFranchiseStations;


==============================================================================
-- AppView.vw_MyRevenueSharePolicies
==============================================================================

--database/07_Create_AppViews.sql
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

-- >>> TEST: cau lenh truy van view
USE EV_Charging_System;
GO
-- View nay LOC theo nguoi dang nhap (RLS) -> phai set SESSION_CONTEXT truoc, neu khong se rong.
EXEC sys.sp_set_session_context @key = N'UserID',   @value = 37;         -- franchise01
EXEC sys.sp_set_session_context @key = N'RoleCode', @value = N'FranchisePartner';
SELECT TOP (20) * FROM AppView.vw_MyRevenueSharePolicies;


==============================================================================
-- AppView.vw_MyRevenueShareSettlements
==============================================================================

--database/07_Create_AppViews.sql
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

-- >>> TEST: cau lenh truy van view
USE EV_Charging_System;
GO
-- View nay LOC theo nguoi dang nhap (RLS) -> phai set SESSION_CONTEXT truoc, neu khong se rong.
EXEC sys.sp_set_session_context @key = N'UserID',   @value = 37;         -- franchise01
EXEC sys.sp_set_session_context @key = N'RoleCode', @value = N'FranchisePartner';
SELECT TOP (20) * FROM AppView.vw_MyRevenueShareSettlements;
