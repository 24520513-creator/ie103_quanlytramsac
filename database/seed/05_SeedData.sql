/*==============================================================================
  EV_Charging_System - SEED DATA
  =============================================================================*/

USE EV_Charging_System;
GO

-- ===========================================================================
-- 1. GEOGRAPHY DATA
-- ===========================================================================
INSERT INTO Infrastructure.Country (CountryCode, CountryName, CurrencyCode, PhonePrefix)
VALUES (N'VN', N'Vietnam', N'VND', N'+84');
GO

DECLARE @VietnamID INT = (SELECT CountryID FROM Infrastructure.Country WHERE CountryCode = N'VN');

INSERT INTO Infrastructure.Region (CountryID, RegionCode, RegionName, RegionType)
VALUES
    (@VietnamID, N'HN', N'HÃ  Ná»™i',         N'City'),
    (@VietnamID, N'HCM', N'Há»“ ChÃ­ Minh',    N'City'),
    (@VietnamID, N'DN', N'ÄÃ  Náºµng',         N'City'),
    (@VietnamID, N'HP', N'Háº£i PhÃ²ng',       N'City'),
    (@VietnamID, N'HUE', N'Huáº¿',            N'City'),
    (@VietnamID, N'NA', N'Nghá»‡ An',         N'Province');
GO

-- ===========================================================================
-- 2. ADDRESSES
-- ===========================================================================
INSERT INTO Infrastructure.Address (RegionID, StreetAddress, Ward, District, Latitude, Longitude)
VALUES
    ((SELECT RegionID FROM Infrastructure.Region WHERE RegionCode = N'HN'),  N'123 Cáº§u Giáº¥y',     N'Dá»‹ch Vá»ng',   N'Cáº§u Giáº¥y',     21.0285, 105.8048),
    ((SELECT RegionID FROM Infrastructure.Region WHERE RegionCode = N'HN'),  N'456 Nguyá»…n TrÃ£i',  N'ThÆ°á»£ng ÄÃ¬nh', N'Thanh XuÃ¢n',   21.0000, 105.8100),
    ((SELECT RegionID FROM Infrastructure.Region WHERE RegionCode = N'HCM'), N'78 LÃª Lá»£i',        N'Báº¿n NghÃ©',    N'Quáº­n 1',       10.7769, 106.7009),
    ((SELECT RegionID FROM Infrastructure.Region WHERE RegionCode = N'HCM'), N'12 VÃµ VÄƒn NgÃ¢n',   N'Linh Chiá»ƒu',  N'Thá»§ Äá»©c',      10.8500, 106.7700),
    ((SELECT RegionID FROM Infrastructure.Region WHERE RegionCode = N'DN'),  N'200 Nguyá»…n VÄƒn Linh', N'Nam DÆ°Æ¡ng', N'Háº£i ChÃ¢u',   16.0600, 108.2200),
    ((SELECT RegionID FROM Infrastructure.Region WHERE RegionCode = N'HUE'), N'50 HÃ¹ng VÆ°Æ¡ng',    N'PhÃº Há»™i',     N'TP Huáº¿',       16.4637, 107.5909),
    ((SELECT RegionID FROM Infrastructure.Region WHERE RegionCode = N'HCM'), N'30 Pháº¡m VÄƒn Äá»“ng', N'PhÃº Nhuáº­n',   N'BÃ¬nh Tháº¡nh',   10.8100, 106.7000),
    ((SELECT RegionID FROM Infrastructure.Region WHERE RegionCode = N'HCM'), N'55 TrÆ°á»ng Chinh',  N'TÃ¢n Thá»›i Nháº¥t', N'TÃ¢n BÃ¬nh',  10.7965, 106.6550),
    ((SELECT RegionID FROM Infrastructure.Region WHERE RegionCode = N'HP'),  N'90 VÄƒn Cao',       N'Äáº±ng Giang',  N'NgÃ´ Quyá»n',    20.8500, 106.6800),
    ((SELECT RegionID FROM Infrastructure.Region WHERE RegionCode = N'NA'),  N'15 LÃª Mao',        N'LÃª Mao',      N'Vinh',         18.6733, 105.6923);
GO

-- ===========================================================================
-- 3. ELECTRICITY SUPPLIERS
-- ===========================================================================
DECLARE @VietnamID2 INT = (SELECT CountryID FROM Infrastructure.Country WHERE CountryCode = N'VN');

INSERT INTO Infrastructure.ElectricitySupplier (SupplierCode, SupplierName, CountryID, ContactPhone, ContactEmail)
VALUES
    (N'EVN_N', N'EVN Miá»n Báº¯c',     @VietnamID2, N'19006789', N'evn@north.vn'),
    (N'EVN_C', N'EVN Miá»n Trung',   @VietnamID2, N'19006789', N'evn@central.vn'),
    (N'EVN_S', N'EVN Miá»n Nam',     @VietnamID2, N'19006789', N'evn@south.vn'),
    (N'EVN_HN', N'Äiá»‡n lá»±c HÃ  Ná»™i', @VietnamID2, N'19001234', N'hanoi@evn.vn'),
    (N'EVN_HCM',N'Äiá»‡n lá»±c TP HCM', @VietnamID2, N'19005678', N'hcmc@evn.vn');
GO

-- ===========================================================================
-- 4. STATION MODELS
-- ===========================================================================
INSERT INTO Infrastructure.StationModel (ModelName, Manufacturer, MaxPowerKW, ConnectorTypes, OcppVersion)
VALUES
    (N'Alpha AC 22',    N'EVBox',       22.00,   N'Type 2',        N'1.6-J'),
    (N'Ultra DC 50',    N'ABB',         50.00,   N'CCS,CHAdeMO',   N'2.0.1'),
    (N'Terra DC 150',   N'Tritium',     150.00,  N'CCS,CHAdeMO',   N'2.0.1'),
    (N'Wallbox AC 7.4', N'Schneider',   7.40,    N'Type 2,Type 1', N'1.6'),
    (N'HyperCharge 350',N'BTC Power',   350.00,  N'CCS',           N'2.0.1');
GO

-- ===========================================================================
-- 5. FRANCHISES
-- ===========================================================================
INSERT INTO Infrastructure.Franchise (FranchiseCode, FranchiseName, TaxCode, AddressID, ContactPerson, ContactPhone, ContactEmail, RevenueShareRate, ContractSignedDate, FranchiseTier)
VALUES
    (N'FR001', N'CÃ´ng ty TNHH NÄƒng lÆ°á»£ng Xanh',  N'MS00001', 1, N'Nguyá»…n VÄƒn An',   '0901000001', 'an.nguyen@greenenergy.vn', 15.00, '2024-01-15', N'Gold'),
    (N'FR002', N'Doanh nghiá»‡p TÆ° nhÃ¢n Äiá»‡n khÃ­',  N'MS00002', 3, N'Tráº§n Thá»‹ BÃ¬nh',   '0901000002', 'binh.tran@dienkhi.vn',   20.00, '2024-03-01', N'Silver'),
    (N'FR003', N'CÃ´ng ty CP Sáº¡c Nhanh',           N'MS00003', 5, N'LÃª HoÃ ng CÆ°á»ng',  '0901000003', 'cuong.le@sacnhanh.vn',   12.50, '2024-06-20', N'Gold'),
    (N'FR004', N'CÃ´ng ty TNHH EV Power',          N'MS00004', 7, N'Pháº¡m Minh Äá»©c',   '0901000004', 'duc.pham@evpower.vn',   18.00, '2024-08-05', N'Platinum'),
    (N'FR005', N'Há»™ kinh doanh Tráº¡m Xanh',        N'MS00005', 9, N'HoÃ ng Thá»‹ Em',    '0901000005', 'em.hoang@tramxanh.vn',  25.00, '2025-01-10', N'Bronze');
GO

-- ===========================================================================
-- 6. CHARGING STATIONS
-- ===========================================================================
INSERT INTO Infrastructure.ChargingStation (StationCode, StationName, FranchiseID, StationModelID, AddressID, SupplierID, Latitude, Longitude, MaxCapacityKW, InstallationDate, FirmwareVersion, StationStatus)
VALUES
    (N'ST001', N'Tráº¡m sáº¡c Xanh - Cáº§u Giáº¥y',   1, 1, 1, 1, 21.0285, 105.8048, 94.00,  '2024-02-01', N'v2.1.3', N'Active'),
    (N'ST002', N'Tráº¡m sáº¡c Xanh - Thanh XuÃ¢n',  1, 4, 2, 1, 21.0000, 105.8100, 44.00,  '2024-02-15', N'v2.1.3', N'Active'),
    (N'ST003', N'Tráº¡m sáº¡c Äiá»‡n khÃ­ - Quáº­n 1',  2, 2, 3, 3, 10.7769, 106.7009, 129.40, '2024-04-01', N'v3.0.1', N'Active'),
    (N'ST004', N'Tráº¡m sáº¡c Äiá»‡n khÃ­ - Thá»§ Äá»©c', 2, 4, 4, 3, 10.8500, 106.7700, 44.00,  '2024-04-15', N'v2.1.3', N'UnderMaintenance'),
    (N'ST005', N'Tráº¡m sáº¡c Nhanh - ÄÃ  Náºµng',    3, 3, 5, 2, 16.0600, 108.2200, 222.00, '2024-07-01', N'v3.2.0', N'Active'),
    (N'ST006', N'Tráº¡m sáº¡c Nhanh - Huáº¿',         3, 4, 6, 2, 16.4637, 107.5909, 44.00,  '2024-07-20', N'v2.1.3', N'Inactive'),
    (N'ST007', N'Tráº¡m EV Power - BÃ¬nh Tháº¡nh',   4, 2, 7, 5, 10.8100, 106.7000, 94.00,  '2024-09-01', N'v3.0.1', N'Active'),
    (N'ST008', N'Tráº¡m EV Power - TÃ¢n BÃ¬nh',     4, 4, 8, 5, 10.7965, 106.6550, 29.40,  '2024-09-15', N'v2.1.3', N'Active'),
    (N'ST009', N'Tráº¡m Xanh - Háº£i PhÃ²ng',        5, 1, 9, 1, 20.8500, 106.6800, 72.00,  '2025-02-01', N'v2.1.3', N'Active'),
    (N'ST010', N'Tráº¡m Xanh - Vinh',             5, 4, 10,2, 18.6733, 105.6923, 44.00,  '2025-02-20', N'v2.1.3', N'Active');
GO

-- ===========================================================================
-- 7. CHARGING POINTS
-- ===========================================================================
INSERT INTO Infrastructure.ChargingPoint (PointCode, StationID, SerialNumber, ConnectorType, PowerKW, FirmwareVersion, PointStatus)
VALUES
    (N'ST001-P01', 1, N'EVB-AC22-240001', N'Type 2',  22.00, N'v2.1.3', N'Available'),
    (N'ST001-P02', 1, N'EVB-AC22-240002', N'Type 2',  22.00, N'v2.1.3', N'Busy'),
    (N'ST001-P03', 1, N'EVB-AC22-240003', N'CHADEMO', 50.00, N'v2.1.3', N'Available'),
    (N'ST002-P01', 2, N'SCH-WB7-240001',  N'Type 2',  22.00, N'v2.1.3', N'Available'),
    (N'ST002-P02', 2, N'SCH-WB7-240002',  N'Type 2',  22.00, N'v2.1.3', N'Busy'),
    (N'ST003-P01', 3, N'ABB-DC50-240001', N'CCS',     50.00, N'v3.0.1', N'Available'),
    (N'ST003-P02', 3, N'ABB-DC50-240002', N'CCS',     50.00, N'v3.0.1', N'Available'),
    (N'ST003-P03', 3, N'ABB-DC50-240003', N'Type 2',  22.00, N'v3.0.1', N'Error'),
    (N'ST003-P04', 3, N'ABB-DC50-240004', N'Type 1',  7.40,  N'v3.0.1', N'Offline'),
    (N'ST004-P01', 4, N'SCH-WB7-240003',  N'Type 2',  22.00, N'v2.1.3', N'Offline'),
    (N'ST004-P02', 4, N'SCH-WB7-240004',  N'Type 2',  22.00, N'v2.1.3', N'Offline'),
    (N'ST005-P01', 5, N'TRI-DC150-240001',N'CHADEMO',150.00, N'v3.2.0', N'Available'),
    (N'ST005-P02', 5, N'TRI-DC150-240002',N'CCS',     50.00, N'v3.2.0', N'Busy'),
    (N'ST005-P03', 5, N'TRI-DC150-240003',N'Type 2',  22.00, N'v3.2.0', N'Available'),
    (N'ST006-P01', 6, N'SCH-WB7-240005',  N'Type 2',  22.00, N'v2.1.3', N'Available'),
    (N'ST006-P02', 6, N'SCH-WB7-240006',  N'Type 2',  22.00, N'v2.1.3', N'Available'),
    (N'ST007-P01', 7, N'ABB-DC50-240005', N'CCS',     50.00, N'v3.0.1', N'Available'),
    (N'ST007-P02', 7, N'ABB-DC50-240006', N'Type 2',  22.00, N'v3.0.1', N'Busy'),
    (N'ST007-P03', 7, N'ABB-DC50-240007', N'Type 2',  22.00, N'v3.0.1', N'Available'),
    (N'ST008-P01', 8, N'SCH-WB7-240007',  N'Type 2',  22.00, N'v2.1.3', N'Available'),
    (N'ST008-P02', 8, N'SCH-WB7-240008',  N'Type 1',  7.40,  N'v2.1.3', N'Available'),
    (N'ST009-P01', 9, N'EVB-AC22-240004', N'CCS',     50.00, N'v2.1.3', N'Available'),
    (N'ST009-P02', 9, N'EVB-AC22-240005', N'Type 2',  22.00, N'v2.1.3', N'Available'),
    (N'ST010-P01',10, N'SCH-WB7-240009',  N'Type 2',  22.00, N'v2.1.3', N'Available'),
    (N'ST010-P02',10, N'SCH-WB7-240010',  N'Type 2',  22.00, N'v2.1.3', N'Busy');
GO

-- ===========================================================================
-- 8. ELECTRICITY CONTRACTS
-- ===========================================================================
INSERT INTO Infrastructure.StationElectricityContract (StationID, SupplierID, ContractNumber, UnitPricePerKWh, ContractFrom)
SELECT s.StationID, s.SupplierID,
       N'ELEC-' + s.StationCode + N'-2024',
       CASE s.SupplierID
           WHEN 1 THEN 2500.0000 WHEN 2 THEN 2400.0000
           WHEN 3 THEN 2600.0000 WHEN 4 THEN 2700.0000
           WHEN 5 THEN 2550.0000 ELSE 2500.0000
       END,
       '2024-01-01'
FROM Infrastructure.ChargingStation s;
GO

-- ===========================================================================
-- 9. SYSTEM USER + DEMO ACCOUNTS + TEST USERS
-- ===========================================================================
INSERT INTO Users.[User] (Username, Email, Phone, AccountStatus)
VALUES
    (N'system',   N'system@evcharge.vn',     N'0900000000', N'Active'),
    (N'admin',    N'admin@evcharge.com',     N'0900000001', N'Active'),
    (N'operator', N'operator@evcharge.com',  N'0900000002', N'Active'),
    (N'customer', N'customer@evcharge.com',  N'0900000003', N'Active'),
    (N'nguyenthimai', N'mai.nguyen@email.com',  N'0912000001', N'Active'),
    (N'tranvannam',   N'nam.tran@email.com',    N'0912000002', N'Active'),
    (N'lethihuong',   N'huong.le@email.com',    N'0912000003', N'Active'),
    (N'phamvantuan',  N'tuan.pham@email.com',   N'0912000004', N'Active'),
    (N'hoangminhtam', N'tam.hoang@email.com',   N'0912000005', N'Active'),
    (N'dothanhson',   N'son.do@email.com',      N'0912000006', N'Suspended'),
    (N'vuthilan',     N'lan.vu@email.com',      N'0912000007', N'Active'),
    (N'ngovanhai',    N'hai.ngo@email.com',     N'0912000008', N'Active');
GO

-- Insert user profiles
INSERT INTO Users.UserProfile (UserID, FullName)SELECT UserID, N'System Administrator' FROM Users.[User] WHERE Username = N'admin'        UNION ALL
SELECT UserID, N'Station Operator'     FROM Users.[User] WHERE Username = N'operator'     UNION ALL
SELECT UserID, N'Demo Customer'        FROM Users.[User] WHERE Username = N'customer'     UNION ALLSELECT UserID, N'Nguyá»…n Thá»‹ Mai'    FROM Users.[User] WHERE Username = N'nguyenthimai' UNION ALL
SELECT UserID, N'Tráº§n VÄƒn Nam'      FROM Users.[User] WHERE Username = N'tranvannam'   UNION ALL
SELECT UserID, N'LÃª Thá»‹ HÆ°Æ¡ng'      FROM Users.[User] WHERE Username = N'lethihuong'   UNION ALL
SELECT UserID, N'Pháº¡m VÄƒn Tuáº¥n'     FROM Users.[User] WHERE Username = N'phamvantuan'  UNION ALL
SELECT UserID, N'HoÃ ng Minh TÃ¢m'    FROM Users.[User] WHERE Username = N'hoangminhtam' UNION ALL
SELECT UserID, N'Äá»— Thanh SÆ¡n'      FROM Users.[User] WHERE Username = N'dothanhson'   UNION ALL
SELECT UserID, N'VÅ© Thá»‹ Lan'        FROM Users.[User] WHERE Username = N'vuthilan'     UNION ALL
SELECT UserID, N'NgÃ´ VÄƒn Háº£i'       FROM Users.[User] WHERE Username = N'ngovanhai';
GO

-- Assign roles to users
-- Admin user gets SysAdmin role
INSERT INTO Users.UserRole (UserID, RoleID)
SELECT u.UserID, r.RoleID
FROM Users.[User] u, Access.Role r
WHERE u.Username = N'admin'
AND r.RoleCode = N'SysAdmin';

-- Operator user gets Operator role
INSERT INTO Users.UserRole (UserID, RoleID)
SELECT u.UserID, r.RoleID
FROM Users.[User] u, Access.Role r
WHERE u.Username = N'operator'
AND r.RoleCode = N'Operator';

-- Customer user and test users get Customer role
INSERT INTO Users.UserRole (UserID, RoleID)
SELECT u.UserID, r.RoleID
FROM Users.[User] u, Access.Role r
WHERE u.Username IN (N'customer', N'nguyenthimai', N'tranvannam', N'lethihuong', N'phamvantuan', N'hoangminhtam', N'dothanhson', N'vuthilan', N'ngovanhai')
AND r.RoleCode = N'CUSTOMER';
GO

-- ===========================================================================
-- 10. VEHICLES
-- ===========================================================================
INSERT INTO Users.Vehicle (UserID, PlateNumber, VIN, Brand, Model, ModelYear, BatteryCapacityKWh, ConnectorType)
SELECT u.UserID, N'29A-12345', N'VIN-VF8-001', N'VinFast', N'VF 8',      2024, 82.00, N'CCS'    FROM Users.[User] u WHERE u.Username = N'nguyenthimai' UNION ALL
SELECT u.UserID, N'29A-67890', N'VIN-VF5-001', N'VinFast', N'VF 5',      2023, 37.00, N'Type 2' FROM Users.[User] u WHERE u.Username = N'nguyenthimai' UNION ALL
SELECT u.UserID, N'51G-54321', N'VIN-TS3-001', N'Tesla',   N'Model 3',  2024, 60.00, N'CCS'    FROM Users.[User] u WHERE u.Username = N'tranvannam'   UNION ALL
SELECT u.UserID, N'30F-98765', N'VIN-HYI5-01', N'Hyundai', N'Ioniq 5',  2024, 58.00, N'CCS'    FROM Users.[User] u WHERE u.Username = N'lethihuong'   UNION ALL
SELECT u.UserID, N'43H-11111', N'VIN-VF9-001', N'VinFast', N'VF 9',      2025, 92.00, N'CCS'    FROM Users.[User] u WHERE u.Username = N'phamvantuan'  UNION ALL
SELECT u.UserID, N'59B-22222', N'VIN-POR-001', N'Porsche', N'Taycan',    2024, 79.00, N'CCS'    FROM Users.[User] u WHERE u.Username = N'hoangminhtam' UNION ALL
SELECT u.UserID, N'29V-33333', N'VIN-BMW-001', N'BMW',     N'i4',       2024, 67.00, N'CCS'    FROM Users.[User] u WHERE u.Username = N'dothanhson'   UNION ALL
SELECT u.UserID, N'51D-44444', N'VIN-VF7-001', N'VinFast', N'VF 7',      2024, 59.00, N'Type 2' FROM Users.[User] u WHERE u.Username = N'vuthilan'     UNION ALL
SELECT u.UserID, N'30K-55555', N'VIN-KIA-001', N'Kia',     N'EV6',      2024, 58.00, N'CCS'    FROM Users.[User] u WHERE u.Username = N'ngovanhai';
GO

-- ===========================================================================
-- 11. MEMBERSHIP TIERS
-- ===========================================================================
INSERT INTO Operations.MembershipTier (TierCode, TierName, MinTotalKWh, MinTotalSpend, DiscountPercent, PrioritySupport, FreeParkingMinutes)
VALUES
    (N'BASIC',    N'Basic',     0,       0,        0.00, 0, 0),
    (N'SILVER',   N'Silver',    500,     2000000,  5.00, 0, 15),
    (N'GOLD',     N'Gold',      2000,    10000000, 10.00, 1, 30),
    (N'PLATINUM', N'Platinum',  5000,    30000000, 15.00, 1, 60);
GO

-- ===========================================================================
-- ===========================================================================
-- 12. PRICING POLICIES
-- ===========================================================================
INSERT INTO Operations.PricingPolicy (PolicyCode, PolicyName, PolicyType, BasePricePerKWh, AppliedFrom, AppliedTo, Priority)
VALUES
    (N'STD',    N'GiÃ¡ tiÃªu chuáº©n',       N'Standard',   3500.0000, '2024-01-01', NULL,         0),
    (N'PEAK',   N'GiÃ¡ giá» cao Ä‘iá»ƒm',     N'PeakHour',   3500.0000, '2024-01-01', NULL,         1),
    (N'OFFPK',  N'GiÃ¡ giá» tháº¥p Ä‘iá»ƒm',    N'OffPeak',    3500.0000, '2024-01-01', NULL,         2),
    (N'PROMO',  N'Khuyáº¿n mÃ£i thÃ¡ng 3',   N'Promotional', 3000.0000, '2025-03-01', '2025-03-31', 3),
    (N'MEMVIP', N'GÃ³i thÃ nh viÃªn VIP',   N'Membership', 2800.0000, '2025-01-01', NULL,         4);
GO

-- ===========================================================================
-- 13. PRICING RULES
-- ===========================================================================
INSERT INTO Operations.PricingRule (PolicyID, RuleName, RuleType, ConditionJson, AdjustmentType, AdjustmentValue, Priority)
SELECT p.PolicyID, N'Peak Hour 1.5x', N'PeakHour', N'{"hours":"17-19","days":"1-5"}', N'Multiplier', 1.50, 10
FROM Operations.PricingPolicy p WHERE p.PolicyCode = N'PEAK'
UNION ALL
SELECT p.PolicyID, N'Off-Peak 0.7x', N'OffPeak', N'{"hours":"22-05","days":"1-7"}', N'Multiplier', 0.70, 10
FROM Operations.PricingPolicy p WHERE p.PolicyCode = N'OFFPK'
UNION ALL
SELECT p.PolicyID, N'Holiday 1.2x', N'Holiday', N'{"holidays":["2025-01-01","2025-04-30","2025-05-01","2025-09-02"]}', N'Multiplier', 1.20, 20
FROM Operations.PricingPolicy p WHERE p.PolicyCode = N'STD';
GO

-- ===========================================================================
-- 14. PEAK HOUR DEFINITIONS
-- ===========================================================================
INSERT INTO Operations.PeakHourDefinition (RegionID, DayOfWeek, StartHour, EndHour, IsPeak, Multiplier)
SELECT NULL, d.Day, CAST(h.StartTime AS TIME), CAST(h.EndTime AS TIME), 1, 1.50
FROM (VALUES (1),(2),(3),(4),(5)) d(Day)
CROSS JOIN (VALUES ('17:00','19:00')) h(StartTime, EndTime)
UNION ALL
SELECT NULL, d.Day, CAST('22:00' AS TIME), CAST('05:00' AS TIME), 0, 0.70
FROM (VALUES (1),(2),(3),(4),(5),(6),(7)) d(Day);
GO

-- ===========================================================================
-- 15. CHARGING SESSIONS
-- ===========================================================================
INSERT INTO Operations.ChargingSession (SessionCode, UserID, VehicleID, PointID, StationID, PolicyID, StartTime, EndTime, StartBatteryPercent, EndBatteryPercent, MeterStart, MeterEnd, TotalKWh, ChargingDurationMinutes, AveragePowerKW, CostTotal, SessionStatus, StopReason)
VALUES
    (N'SES-2025-00001', 2,  2,  2,  1, 1, '2025-04-01 08:15:00', '2025-04-01 09:45:00', 20.00, 85.00, 1000.0000, 1035.5000, 35.5000,  90, 23.67, 124250.0000, N'Completed', N'Completed'),
    (N'SES-2025-00002', 3,  3,  5,  2, 1, '2025-04-01 10:00:00', '2025-04-01 11:20:00', 30.00, 72.00, 2000.0000, 2025.0000, 25.0000,  80, 18.75, 87500.0000,  N'Completed', N'Completed'),
    (N'SES-2025-00003', 4,  4, 13,  5, 2, '2025-04-01 18:00:00', '2025-04-01 19:10:00', 15.00, 90.00, 3000.0000, 3040.0000, 40.0000,  70, 34.29, 210000.0000, N'Completed', N'Completed'),
    (N'SES-2025-00004', 6,  6,  7,  3, 1, '2025-04-02 09:30:00', '2025-04-02 10:50:00', 25.00, 95.00, 4000.0000, 4050.0000, 50.0000,  80, 37.50, 175000.0000, N'Completed', N'Completed'),
    (N'SES-2025-00005', 8,  8, 18,  7, 2, '2025-04-02 17:30:00', '2025-04-02 18:45:00', 40.00, 88.00, 5000.0000, 5030.0000, 30.0000,  75, 24.00, 157500.0000, N'Completed', N'Completed'),
    (N'SES-2025-00006', 2,  1,  3,  1, 3, '2025-04-03 23:00:00', '2025-04-04 01:30:00', 10.00, 100.00,6000.0000, 6060.0000, 60.0000, 150, 24.00, 147000.0000, N'Completed', N'Completed'),
    (N'SES-2025-00007', 9,  9, 22,  9, 1, '2025-04-03 14:00:00', '2025-04-03 15:15:00', 50.00, 90.00, 7000.0000, 7022.0000, 22.0000,  75, 17.60, 77000.0000,  N'Completed', N'Completed'),
    (N'SES-2025-00008', 4,  4,  6,  3, 1, '2025-04-04 11:00:00', '2025-04-04 12:30:00', 20.00, 85.00, 8000.0000, 8045.0000, 45.0000,  90, 30.00, 157500.0000, N'Completed', N'Completed'),
    (N'SES-2025-00009', 3,  3, 14,  5, 2, '2025-04-05 19:00:00', '2025-04-05 20:10:00', 35.00, 80.00, 9000.0000, 9028.0000, 28.0000,  70, 24.00, 147000.0000, N'Completed', N'Completed'),
    (N'SES-2025-00010', 6,  6, 12,  5, 1, '2025-04-06 07:00:00', '2025-04-06 08:20:00', 5.00,  95.00, 10000.0000,10055.0000, 55.0000,  80, 41.25, 192500.0000, N'Completed', N'Completed'),
    (N'SES-2025-00011', 2,  1,  2,  1, 1, '2025-04-07 09:00:00', NULL,                  55.00, NULL,  11000.0000, NULL,      NULL,     NULL, NULL, NULL,          N'Charging',  NULL);
GO

-- ===========================================================================
-- 16. TRANSACTIONS
-- ===========================================================================
INSERT INTO Payments.PaymentGateway (GatewayCode, GatewayName, GatewayType, IsActive)
VALUES (N'INTERNAL', N'Internal Wallet', N'Internal', 1);
GO

DECLARE @GatewayID INT = (SELECT GatewayID FROM Payments.PaymentGateway WHERE GatewayCode = N'INTERNAL');

INSERT INTO Payments.[Transaction] (TransactionCode, UserID, SessionID, GatewayID, TransactionType, Direction, Amount, TransactionStatus, TransactedAt)
SELECT N'TXN-2025-' + RIGHT('00000' + CAST(ROW_NUMBER() OVER (ORDER BY cs.SessionID) AS NVARCHAR(5)), 5),
       cs.UserID, cs.SessionID, @GatewayID, N'ChargingPayment', N'D', cs.CostTotal, N'Completed', cs.EndTime
FROM Operations.ChargingSession cs
WHERE cs.SessionStatus = N'Completed' AND cs.CostTotal IS NOT NULL;
GO

-- ===========================================================================
-- 17. WALLETS
-- ===========================================================================
INSERT INTO Payments.Wallet (UserID, WalletCode, Balance)
SELECT u.UserID, N'WALLET-' + u.Username, 500000
FROM Users.[User] u WHERE u.Username != N'system';
GO

-- ===========================================================================
-- 18. ERROR LOGS
-- ===========================================================================
INSERT INTO Monitoring.ErrorLog (PointID, StationID, SessionID, ErrorCode, ErrorCategory, Severity, Title, Description, OccurredAt, ResolvedAt)
VALUES
    (8,  3, NULL, N'ERR_001', N'Network',  N'High',    N'Máº¥t káº¿t ná»‘i bá»™ sáº¡c',         N'Máº¥t káº¿t ná»‘i bá»™ sáº¡c táº¡i Ä‘iá»ƒm ST003-P03',       '2025-03-15 10:30:00', '2025-03-15 11:00:00'),
    (9,  3, NULL, N'ERR_002', N'Power',    N'High',    N'Lá»—i nguá»“n Ä‘iá»‡n Ä‘áº§u vÃ o',     N'Lá»—i nguá»“n Ä‘iá»‡n Ä‘áº§u vÃ o, tráº¡m ST003',          '2025-03-20 14:00:00', '2025-03-20 16:30:00'),
    (10, 4, NULL, N'ERR_003', N'Hardware', N'Medium',  N'CÃ¡p sáº¡c bá»‹ há»ng',            N'CÃ¡p sáº¡c bá»‹ há»ng táº¡i Ä‘iá»ƒm ST004-P01',          '2025-04-01 08:00:00', '2025-04-02 09:00:00'),
    (11, 4, NULL, N'ERR_004', N'Software', N'Low',     N'Lá»—i pháº§n má»m Ä‘iá»u khiá»ƒn',    N'Lá»—i pháº§n má»m Ä‘iá»u khiá»ƒn táº¡i Ä‘iá»ƒm ST004-P02',  '2025-04-05 12:00:00', NULL);
GO

-- ===========================================================================
-- 19. MAINTENANCE SCHEDULES
-- ===========================================================================
INSERT INTO Operations.MaintenanceSchedule (StationID, PointID, ScheduledDate, MaintenanceType, TechnicianName, TechnicianPhone, Description, ScheduleStatus, Priority)
VALUES
    (1,  NULL, '2025-05-01 08:00', N'Routine',    N'Nguyá»…n VÄƒn Ká»¹ thuáº­t', '0902000001', N'Kiá»ƒm tra tá»•ng thá»ƒ há»‡ thá»‘ng Ä‘iá»‡n',     N'Scheduled', N'Normal'),
    (3,  NULL, '2025-05-05 09:00', N'Inspection', N'Tráº§n VÄƒn Sá»­a chá»¯a',   '0902000002', N'Báº£o dÆ°á»¡ng Ä‘á»‹nh ká»³ bá»™ sáº¡c CCS',        N'Scheduled', N'Normal'),
    (4,  NULL, '2025-05-10 10:00', N'Repair',     N'LÃª VÄƒn Báº£o trÃ¬',      '0902000003', N'Sá»­a chá»¯a tráº¡m, thay tháº¿ linh kiá»‡n',     N'Scheduled', N'High'),
    (5,  NULL, '2025-05-15 08:00', N'Calibration',N'Pháº¡m VÄƒn Ká»¹ thuáº­t',   '0902000004', N'Hiá»‡u chuáº©n thiáº¿t bá»‹ Ä‘o',               N'Scheduled', N'Normal'),
    (7,  NULL, '2025-04-20 09:30', N'Routine',    N'HoÃ ng VÄƒn Sá»­a chá»¯a',  '0902000005', N'Vá»‡ sinh vÃ  kiá»ƒm tra Ä‘áº§u ná»‘i',           N'Completed', N'Normal');
GO

-- ===========================================================================
-- 20. RECORD INITIAL MIGRATION VERSION
-- ===========================================================================
INSERT INTO Audit.SchemaChangeLog (ChangeVersion, ChangeDescription, ChangeScript)
VALUES (N'v2.0.0', N'Enterprise redesign: 48 tables, 9 schemas, RBAC, audit, analytics', N'02_CreateTables.sql');
GO

PRINT N'Seed data inserted successfully.';
GO

