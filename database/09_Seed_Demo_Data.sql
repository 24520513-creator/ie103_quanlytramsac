USE EV_Charging_System;
GO

/*
HUONG DAN SU DUNG (seed v2 - realistic Vietnam)
- Muc dich: mo phong he thong da hoat dong ~2 nam, phan bo theo thuc te Viet Nam.
- Chay sau cac script 00 -> 08 (tren DB moi). Sau do chay 10 -> 13 nhu binh thuong.
- Quy mo (uoc luong):
  + ~40 tinh/thanh (TP lon nhieu tram, tinh nho 1-2, mien nui 0-1).
  + ~155 tram sac, ~850 cong sac, 15 franchise, ~28 operations, 500 customer.
  + ~300k charging session trong 2 nam gan nhat, tap trung gio cao diem,
    mat do tang dan theo thoi gian; co moc tang gia 2025 (phuc vu bao cao YoY).
  + Booking, payment, invoice, telemetry, error, ticket, settlement theo ty le.
- Toi uu: tat trigger nghiep vu trong luc bulk-load roi bat lai (nhanh + tu set status).
- Tham so dieu chinh: @SessionCount, @TelemetryRows.
*/

SET NOCOUNT ON;

DECLARE @Hash       NVARCHAR(256) = N'$2a$12$DemoHashForIE103DatabaseOnly';  -- 13_Auth_Migration se dat hash that cho tai khoan demo
DECLARE @EndDate    DATETIME2 = SYSDATETIME();
DECLARE @StartDate  DATETIME2 = DATEADD(YEAR, -2, @EndDate);
DECLARE @Y2         DATETIME2 = DATEADD(YEAR, -1, @EndDate);   -- moc doi gia 2025
DECLARE @Days       INT = DATEDIFF(DAY, @StartDate, @EndDate);
DECLARE @SessionCount  INT = 300000;
DECLARE @TelemetryRows INT = 300000;

/* ============================================================
   0) TAT TRIGGER NGHIEP VU (tang toc bulk-load; bat lai o cuoi)
   ============================================================ */
DISABLE TRIGGER ALL ON [Identity].UserAccount;
DISABLE TRIGGER ALL ON [Identity].UserRole;
DISABLE TRIGGER ALL ON Franchise.FranchisePartner;
DISABLE TRIGGER ALL ON Franchise.FranchiseContract;
DISABLE TRIGGER ALL ON Franchise.RevenueSharePolicy;
DISABLE TRIGGER ALL ON Franchise.RevenueShareSettlement;
DISABLE TRIGGER ALL ON Infrastructure.ChargingPoint;
DISABLE TRIGGER ALL ON Operations.Booking;
DISABLE TRIGGER ALL ON Operations.ChargingSession;
DISABLE TRIGGER ALL ON Payments.PaymentTransaction;
DISABLE TRIGGER ALL ON Maintenance.MaintenanceTicket;

/* ============================================================
   1) REGION (~40 tinh, co trong so StationCount; mien nui 0-1)
   ============================================================ */
DECLARE @Prov TABLE (RegionCode NVARCHAR(20), RegionName NVARCHAR(100), Tier INT, StationCount INT);
INSERT INTO @Prov (RegionCode, RegionName, Tier, StationCount) VALUES
-- Tier 1: sieu do thi
(N'HCM',  N'TP Ho Chi Minh', 1, 26),
(N'HN',   N'Ha Noi',         1, 22),
(N'DNG',  N'Da Nang',        1, 10),
(N'BD',   N'Binh Duong',     1,  8),
(N'HP',   N'Hai Phong',      1,  7),
(N'DN',   N'Dong Nai',       1,  7),
(N'CT',   N'Can Tho',        1,  5),
-- Tier 2: tinh/thanh lon
(N'BRVT', N'Ba Ria - Vung Tau', 2, 5),
(N'KH',   N'Khanh Hoa',      2, 5),
(N'QNI',  N'Quang Ninh',     2, 4),
(N'LD',   N'Lam Dong',       2, 4),
(N'NA',   N'Nghe An',        2, 4),
(N'TH',   N'Thanh Hoa',      2, 4),
(N'TTH',  N'Thua Thien Hue', 2, 4),
(N'BN',   N'Bac Ninh',       2, 3),
(N'HD',   N'Hai Duong',      2, 3),
(N'LA',   N'Long An',        2, 3),
(N'TG',   N'Tien Giang',     2, 3),
(N'VP',   N'Vinh Phuc',      2, 3),
(N'AG',   N'An Giang',       2, 3),
(N'KG',   N'Kien Giang',     2, 3),
-- Tier 3: tinh nho
(N'QNM',  N'Quang Nam',      3, 2),
(N'BTH',  N'Binh Thuan',     3, 2),
(N'GL',   N'Gia Lai',        3, 2),
(N'DLK',  N'Dak Lak',        3, 2),
(N'TN',   N'Tay Ninh',       3, 1),
(N'HNM',  N'Ha Nam',         3, 1),
(N'NB',   N'Ninh Binh',      3, 1),
(N'TB',   N'Thai Binh',      3, 1),
(N'PT',   N'Phu Tho',        3, 1),
(N'BG',   N'Bac Giang',      3, 1),
-- Tier 4: mien nui (0-1 tram)
(N'LCI',  N'Lao Cai',        4, 1),
(N'HG',   N'Ha Giang',       4, 1),
(N'SL',   N'Son La',         4, 1),
(N'DB',   N'Dien Bien',      4, 0),
(N'LCH',  N'Lai Chau',       4, 0),
(N'CB',   N'Cao Bang',       4, 0),
(N'BK',   N'Bac Kan',        4, 0),
(N'KT',   N'Kon Tum',        4, 0);

INSERT INTO Core.Region (RegionCode, RegionName)
SELECT RegionCode, RegionName FROM @Prov;

/* ============================================================
   2) ROLES + USERS
   ============================================================ */
INSERT INTO [Identity].[Role] (RoleCode, RoleName, Description)
VALUES
(N'SystemAdmin', N'System administrator', N'Full database administration role'),
(N'OperationsStaff', N'Operations staff', N'Operates stations, charging points, sessions, errors, and tickets'),
(N'BusinessManager', N'Business manager', N'Views revenue, manages pricing, franchise settlement, and KPI datasets'),
(N'FranchisePartner', N'Franchise partner', N'Reads own franchise profile, contracts, stations, policies, and settlements'),
(N'Customer', N'Customer', N'Owns vehicles, books charging, starts sessions, pays, and views history');

-- Admin (3) + Business (5)
INSERT INTO [Identity].UserAccount (Username, Email, Phone, PasswordHash, FullName) VALUES
(N'admin01', N'admin01@gmail.com', N'0901000001', @Hash, N'System Admin 01'),
(N'admin02', N'admin02@gmail.com', N'0901000002', @Hash, N'System Admin 02'),
(N'admin03', N'admin03@gmail.com', N'0901000003', @Hash, N'System Admin 03'),
(N'business01', N'business01@gmail.com', N'0901100001', @Hash, N'Business Manager 01'),
(N'business02', N'business02@gmail.com', N'0901100002', @Hash, N'Business Manager 02'),
(N'business03', N'business03@gmail.com', N'0901100003', @Hash, N'Business Manager 03'),
(N'business04', N'business04@gmail.com', N'0901100004', @Hash, N'Business Manager 04'),
(N'business05', N'business05@gmail.com', N'0901100005', @Hash, N'Business Manager 05');

-- Operations staff (28): ~1 nguoi / 5-6 tram
WITH N AS (SELECT TOP (28) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n FROM sys.all_objects)
INSERT INTO [Identity].UserAccount (Username, Email, Phone, PasswordHash, FullName)
SELECT N'operator' + RIGHT(N'00' + CAST(n AS NVARCHAR(10)), 2),
       N'operator' + RIGHT(N'00' + CAST(n AS NVARCHAR(10)), 2) + N'@ev.vn',
       N'0901' + RIGHT(N'0000000' + CAST(200000 + n AS NVARCHAR(10)), 7),
       @Hash,
       N'Operations Staff ' + RIGHT(N'00' + CAST(n AS NVARCHAR(10)), 2)
FROM N;

-- Franchise partner users (15)
WITH N AS (SELECT TOP (15) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n FROM sys.all_objects)
INSERT INTO [Identity].UserAccount (Username, Email, Phone, PasswordHash, FullName)
SELECT N'franchise' + RIGHT(N'00' + CAST(n AS NVARCHAR(10)), 2),
       N'franchise' + RIGHT(N'00' + CAST(n AS NVARCHAR(10)), 2) + N'@ev.vn',
       N'093' + RIGHT(N'0000000' + CAST(n AS NVARCHAR(10)), 7),
       @Hash,
       N'Franchise Partner User ' + RIGHT(N'00' + CAST(n AS NVARCHAR(10)), 2)
FROM N;

-- Customers (500), CreatedAt rai deu ~2 nam (hoi nghieng ve gan day)
WITH N AS (SELECT TOP (500) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n FROM sys.all_objects a CROSS JOIN sys.all_objects b)
INSERT INTO [Identity].UserAccount (Username, Email, Phone, PasswordHash, FullName, AccountStatus, CreatedAt)
SELECT CASE WHEN n <= 99 THEN N'customer' + RIGHT(N'00' + CAST(n AS NVARCHAR(10)), 2) ELSE N'customer' + CAST(n AS NVARCHAR(10)) END,
       CASE WHEN n <= 99 THEN N'customer' + RIGHT(N'00' + CAST(n AS NVARCHAR(10)), 2) ELSE N'customer' + CAST(n AS NVARCHAR(10)) END + N'@gmail.com',
       N'091' + RIGHT(N'0000000' + CAST(n AS NVARCHAR(10)), 7),
       @Hash,
       N'Customer ' + RIGHT(N'000' + CAST(n AS NVARCHAR(10)), 3),
       CASE WHEN n % 71 = 0 THEN N'Suspended' WHEN n % 97 = 0 THEN N'Locked' WHEN n % 53 = 0 THEN N'Pending' ELSE N'Active' END,
       DATEADD(DAY, CAST(@Days * SQRT((ABS(CHECKSUM(n)) % 100000) / 100000.0) AS INT), @StartDate)
FROM N;

INSERT INTO [Identity].UserRole (UserID, RoleID)
SELECT u.UserID, r.RoleID
FROM [Identity].UserAccount u
JOIN [Identity].[Role] r ON r.RoleCode =
    CASE WHEN u.Username LIKE N'admin%' THEN N'SystemAdmin'
         WHEN u.Username LIKE N'operator%' THEN N'OperationsStaff'
         WHEN u.Username LIKE N'business%' THEN N'BusinessManager'
         WHEN u.Username LIKE N'franchise%' THEN N'FranchisePartner'
         ELSE N'Customer' END;

/* ============================================================
   3) FRANCHISE (15) + CONTRACT + REVENUE SHARE POLICY
   ============================================================ */
-- Van phong franchise (1 dia chi / franchise) o cac vung lon
INSERT INTO Core.Address (RegionID, StreetAddress, Ward, District, Latitude, Longitude)
SELECT r.RegionID, N'Franchise office ' + CAST(n.n AS NVARCHAR(10)), N'Central Ward', N'Central District',
       10.0 + (n.n * 0.13), 106.0 + (n.n * 0.09)
FROM (SELECT TOP (15) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n FROM sys.all_objects) n
JOIN Core.Region r ON r.RegionID = ((n.n - 1) % (SELECT COUNT(*) FROM Core.Region)) + 1;

INSERT INTO Franchise.FranchisePartner
    (FranchiseCode, FranchiseName, TaxCode, AddressID, ContactUserID, ContactPerson, ContactPhone, ContactEmail)
SELECT N'FRC' + RIGHT(N'00' + CAST(n.n AS NVARCHAR(10)), 2),
       N'EV Franchise Partner ' + CAST(n.n AS NVARCHAR(10)),
       N'TAX' + RIGHT(N'0000000000' + CAST(n.n AS NVARCHAR(10)), 10),
       a.AddressID,
       (SELECT UserID FROM [Identity].UserAccount WHERE Username = N'franchise' + RIGHT(N'00' + CAST(n.n AS NVARCHAR(10)), 2)),
       N'Partner Contact ' + CAST(n.n AS NVARCHAR(10)),
       N'092' + RIGHT(N'0000000' + CAST(n.n AS NVARCHAR(10)), 7),
       N'partner' + CAST(n.n AS NVARCHAR(10)) + N'@ev.vn'
FROM (SELECT TOP (15) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n FROM sys.all_objects) n
JOIN Core.Address a ON a.StreetAddress = N'Franchise office ' + CAST(n.n AS NVARCHAR(10));

INSERT INTO Franchise.FranchiseContract (FranchiseID, ContractCode, StartDate, EndDate, BaseRevenueShareRate, ContractStatus)
SELECT FranchiseID, N'FC-' + FranchiseCode + N'-2024',
       CAST(@StartDate AS DATE), DATEADD(YEAR, 3, CAST(@StartDate AS DATE)),
       58.00 + (FranchiseID % 10), N'Active'
FROM Franchise.FranchisePartner;

INSERT INTO Franchise.RevenueSharePolicy (ContractID, PolicyCode, PartnerShareRate, AppliedFrom)
SELECT ContractID, N'RSP-' + ContractCode, BaseRevenueShareRate, StartDate
FROM Franchise.FranchiseContract;

/* ============================================================
   4) SUPPLIER (1/region) + CONNECTOR TYPES
   ============================================================ */
INSERT INTO Infrastructure.ElectricitySupplier (SupplierCode, SupplierName, RegionID, UnitPricePerKWh)
SELECT N'EVN-' + r.RegionCode, N'EVN ' + r.RegionName, r.RegionID, 1900 + (r.RegionID * 5)
FROM Core.Region r;

INSERT INTO Infrastructure.ConnectorType (ConnectorCode, ConnectorName, MaxPowerKW)
VALUES
(N'CCS2', N'Combined Charging System Type 2', 350),
(N'CHAdeMO', N'CHAdeMO DC', 100),
(N'Type2', N'AC Type 2', 43),
(N'GBT', N'GB/T DC', 180);

DECLARE @CCS2 INT = (SELECT ConnectorTypeID FROM Infrastructure.ConnectorType WHERE ConnectorCode = N'CCS2');
DECLARE @CHA  INT = (SELECT ConnectorTypeID FROM Infrastructure.ConnectorType WHERE ConnectorCode = N'CHAdeMO');
DECLARE @T2   INT = (SELECT ConnectorTypeID FROM Infrastructure.ConnectorType WHERE ConnectorCode = N'Type2');
DECLARE @GBT  INT = (SELECT ConnectorTypeID FROM Infrastructure.ConnectorType WHERE ConnectorCode = N'GBT');

/* ============================================================
   5) STATIONS — expand theo StationCount tung tinh (tier hoa)
   ============================================================ */
DECLARE @OpCount INT = (SELECT COUNT(*) FROM [Identity].UserAccount WHERE Username LIKE N'operator%');

;WITH Tally AS (SELECT TOP (30) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS k FROM sys.all_objects),
Expanded AS (
    SELECT r.RegionID, p.RegionCode, p.RegionName, p.Tier, t.k,
           ROW_NUMBER() OVER (ORDER BY p.Tier, p.RegionCode, t.k) AS seq
    FROM @Prov p
    JOIN Core.Region r ON r.RegionCode = p.RegionCode
    JOIN Tally t ON t.k <= p.StationCount
)
SELECT seq, RegionID, RegionCode, RegionName, Tier, k,
       N'ST-' + RIGHT(N'000' + CAST(seq AS NVARCHAR(10)), 3) AS StationCode,
       N'EV ' + RegionName + N' Station ' + CAST(k AS NVARCHAR(10)) AS StationName,
       -- Franchise: tram tier-1 thuoc 3 franchise lon, con lai trai deu 15
       CASE WHEN Tier = 1 THEN ((seq % 3) + 1) ELSE ((seq % 15) + 1) END AS FranchiseID,
       -- Cong suat tram theo tier
       CASE Tier WHEN 1 THEN (CASE seq % 3 WHEN 0 THEN 300 WHEN 1 THEN 180 ELSE 150 END)
                 WHEN 2 THEN (CASE seq % 2 WHEN 0 THEN 150 ELSE 120 END)
                 WHEN 3 THEN 120 ELSE 60 END AS MaxPowerKW,
       -- So cong theo tier
       CASE Tier WHEN 1 THEN 6 + (seq % 5)     -- 6..10
                 WHEN 2 THEN 3 + (seq % 3)     -- 3..5
                 WHEN 3 THEN 2 + (seq % 2)     -- 2..3
                 ELSE 1 + (seq % 2) END AS PointCount, -- 1..2
       CASE WHEN seq % 29 = 0 THEN N'UnderMaintenance'
            WHEN seq % 53 = 0 THEN N'Inactive'
            ELSE N'Active' END AS StationStatus,
       DATEADD(DAY, (seq * 4) % @Days, @StartDate) AS OpenedAt
INTO #StationPlan
FROM Expanded;

-- Dia chi tram (1/tram), nhan toa do theo vung + jitter
INSERT INTO Core.Address (RegionID, StreetAddress, Ward, District, Latitude, Longitude)
SELECT sp.RegionID,
       N'Station address ' + sp.StationCode,
       N'Ward ' + CAST((sp.seq % 20) + 1 AS NVARCHAR(10)),
       N'District ' + CAST((sp.seq % 12) + 1 AS NVARCHAR(10)),
       9.0 + (sp.RegionID * 0.30) + (sp.k * 0.01),
       104.0 + (sp.RegionID * 0.25) + (sp.k * 0.01)
FROM #StationPlan sp;

INSERT INTO Infrastructure.ChargingStation
    (StationCode, StationName, FranchiseID, AddressID, SupplierID, StationOperatorID, ModelName, Manufacturer, MaxPowerKW, StationStatus, OpenedAt)
SELECT sp.StationCode, sp.StationName, sp.FranchiseID, a.AddressID,
       (SELECT TOP 1 SupplierID FROM Infrastructure.ElectricitySupplier WHERE RegionID = sp.RegionID),
       (SELECT UserID FROM [Identity].UserAccount WHERE Username = N'operator' + RIGHT(N'00' + CAST(((sp.seq - 1) % @OpCount) + 1 AS NVARCHAR(10)), 2)),
       CASE sp.seq % 3 WHEN 0 THEN N'ABB Terra 184' WHEN 1 THEN N'VinFast DC 150' ELSE N'Siemens Sicharge' END,
       CASE sp.seq % 3 WHEN 0 THEN N'ABB' WHEN 1 THEN N'VinFast' ELSE N'Siemens' END,
       sp.MaxPowerKW, sp.StationStatus, sp.OpenedAt
FROM #StationPlan sp
JOIN Core.Address a ON a.StreetAddress = N'Station address ' + sp.StationCode;

INSERT INTO Franchise.FranchiseStation (FranchiseID, StationID, ContractID)
SELECT s.FranchiseID, s.StationID, fc.ContractID
FROM Infrastructure.ChargingStation s
JOIN Franchise.FranchiseContract fc ON fc.FranchiseID = s.FranchiseID AND fc.ContractStatus = N'Active';

-- Loai dau sac cua tram
INSERT INTO Infrastructure.StationConnectorType (StationID, ConnectorTypeID)
SELECT StationID, @CCS2 FROM Infrastructure.ChargingStation
UNION ALL SELECT StationID, @T2 FROM Infrastructure.ChargingStation
UNION ALL SELECT StationID, @CHA FROM Infrastructure.ChargingStation WHERE StationID % 2 = 0
UNION ALL SELECT StationID, @GBT FROM Infrastructure.ChargingStation WHERE StationID % 3 = 0;

/* ============================================================
   6) CHARGING POINTS — expand theo PointCount tung tram
   ============================================================ */
;WITH Tally AS (SELECT TOP (12) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS k FROM sys.all_objects)
INSERT INTO Infrastructure.ChargingPoint (PointCode, StationID, ConnectorTypeID, PowerKW, SerialNumber, PointStatus, HealthStatus)
SELECT s.StationCode + N'-' + CHAR(64 + t.k),
       s.StationID,
       CASE (s.StationID + t.k) % 5 WHEN 0 THEN @T2 WHEN 1 THEN @CCS2 WHEN 2 THEN @CCS2 WHEN 3 THEN @CHA ELSE @GBT END,
       CASE WHEN (s.StationID + t.k) % 5 = 0 THEN 22
            WHEN (s.StationID + t.k) % 5 IN (1,2) THEN CASE WHEN s.MaxPowerKW >= 150 THEN 150 ELSE s.MaxPowerKW END
            WHEN (s.StationID + t.k) % 5 = 3 THEN 60 ELSE 120 END,
       N'SN-' + s.StationCode + N'-' + CHAR(64 + t.k),
       CASE WHEN s.StationStatus <> N'Active' THEN N'Maintenance'
            WHEN (s.StationID * 7 + t.k) % 113 = 0 THEN N'Maintenance'
            WHEN (s.StationID * 7 + t.k) % 97 = 0 THEN N'Offline'
            ELSE N'Available' END,
       CASE WHEN (s.StationID * 7 + t.k) % 113 = 0 THEN N'Warning'
            WHEN (s.StationID * 7 + t.k) % 97 = 0 THEN N'Offline'
            ELSE N'Normal' END
FROM Infrastructure.ChargingStation s
JOIN #StationPlan sp ON sp.StationCode = s.StationCode
JOIN Tally t ON t.k <= sp.PointCount;

/* ============================================================
   7) PRICING POLICY — moc 2024 va 2025 (tang gia) cho bao cao YoY
   ============================================================ */
INSERT INTO Operations.PricingPolicy (PolicyCode, PolicyName, BasePricePerKWh, PeakMultiplier, PeakStartHour, PeakEndHour, AppliedFrom, AppliedTo, IsActive)
VALUES
(N'STD-2024',   N'Standard price (year 1)',  3500, 1.25, '17:00', '20:00', CAST(@StartDate AS DATE), CAST(@Y2 AS DATE), 0),
(N'NIGHT-2024', N'Night price (year 1)',     2800, 1.00, NULL,    NULL,    CAST(@StartDate AS DATE), CAST(@Y2 AS DATE), 0),
(N'FAST-2024',  N'Fast charging (year 1)',   4300, 1.35, '16:00', '21:00', CAST(@StartDate AS DATE), CAST(@Y2 AS DATE), 0),
(N'STD-2025',   N'Standard price (year 2)',  3900, 1.25, '17:00', '20:00', CAST(@Y2 AS DATE), NULL, 1),
(N'NIGHT-2025', N'Night price (year 2)',     3100, 1.00, NULL,    NULL,    CAST(@Y2 AS DATE), NULL, 1),
(N'FAST-2025',  N'Fast charging (year 2)',   4800, 1.35, '16:00', '21:00', CAST(@Y2 AS DATE), NULL, 1);

DECLARE @STD24 INT = (SELECT PolicyID FROM Operations.PricingPolicy WHERE PolicyCode = N'STD-2024');
DECLARE @NGT24 INT = (SELECT PolicyID FROM Operations.PricingPolicy WHERE PolicyCode = N'NIGHT-2024');
DECLARE @FST24 INT = (SELECT PolicyID FROM Operations.PricingPolicy WHERE PolicyCode = N'FAST-2024');
DECLARE @STD25 INT = (SELECT PolicyID FROM Operations.PricingPolicy WHERE PolicyCode = N'STD-2025');
DECLARE @NGT25 INT = (SELECT PolicyID FROM Operations.PricingPolicy WHERE PolicyCode = N'NIGHT-2025');
DECLARE @FST25 INT = (SELECT PolicyID FROM Operations.PricingPolicy WHERE PolicyCode = N'FAST-2025');

/* ============================================================
   8) VEHICLES (~1.3 / customer)
   ============================================================ */
;WITH Customers AS (SELECT ROW_NUMBER() OVER (ORDER BY UserID) AS rn, UserID FROM [Identity].UserAccount WHERE Username LIKE N'customer%')
INSERT INTO Operations.Vehicle (UserID, PlateNumber, Brand, Model, BatteryCapacityKWh, PreferredConnectorTypeID)
SELECT UserID, N'EV-' + RIGHT(N'000000' + CAST(rn AS NVARCHAR(10)), 6),
       CASE rn % 5 WHEN 0 THEN N'VinFast' WHEN 1 THEN N'Tesla' WHEN 2 THEN N'Hyundai' WHEN 3 THEN N'Kia' ELSE N'BYD' END,
       CASE rn % 5 WHEN 0 THEN N'VF 8' WHEN 1 THEN N'Model 3' WHEN 2 THEN N'Ioniq 5' WHEN 3 THEN N'EV6' ELSE N'Atto 3' END,
       CASE rn % 5 WHEN 0 THEN 82.00 WHEN 1 THEN 75.00 WHEN 2 THEN 72.60 WHEN 3 THEN 77.40 ELSE 60.50 END,
       CASE WHEN rn % 7 = 0 THEN @T2 ELSE @CCS2 END
FROM Customers;

;WITH Customers AS (SELECT ROW_NUMBER() OVER (ORDER BY UserID) AS rn, UserID FROM [Identity].UserAccount WHERE Username LIKE N'customer%')
INSERT INTO Operations.Vehicle (UserID, PlateNumber, Brand, Model, BatteryCapacityKWh, PreferredConnectorTypeID)
SELECT UserID, N'EV-2-' + RIGHT(N'00000' + CAST(rn AS NVARCHAR(10)), 5),
       CASE WHEN rn % 2 = 0 THEN N'VinFast' ELSE N'Tesla' END,
       CASE WHEN rn % 2 = 0 THEN N'VF e34' ELSE N'Model Y' END,
       CASE WHEN rn % 2 = 0 THEN 42.00 ELSE 78.00 END, @CCS2
FROM Customers WHERE rn % 3 = 0;

/* ============================================================
   9) CHARGING SESSIONS (~@SessionCount) — 2 nam, nghieng gan day,
      tap trung gio cao diem; policy theo nam (YoY)
   ============================================================ */
DECLARE @PointTotal INT = (SELECT COUNT(*) FROM Infrastructure.ChargingPoint);
DECLARE @CustTotal  INT = 500;

SELECT TOP (@SessionCount) ROW_NUMBER() OVER (ORDER BY a.object_id, b.object_id) AS Seq
INTO #Nums
FROM sys.all_objects a CROSS JOIN sys.all_objects b;

SELECT ROW_NUMBER() OVER (ORDER BY u.UserID) AS CustomerRow, u.UserID,
       (SELECT TOP 1 v.VehicleID FROM Operations.Vehicle v WHERE v.UserID = u.UserID ORDER BY v.VehicleID) AS VehicleID
INTO #Customers
FROM [Identity].UserAccount u WHERE u.Username LIKE N'customer%';

-- Map PointID lien tuc 1..N (du IDENTITY khong lien tuc)
SELECT ROW_NUMBER() OVER (ORDER BY PointID) AS rn, PointID, StationID
INTO #Points
FROM Infrastructure.ChargingPoint;

;WITH Base AS (
    SELECT n.Seq,
           c.UserID, c.VehicleID,
           pt.PointID, pt.StationID,
           -- ngay: nghieng ve gan day (SQRT skew)
           CAST((@Days - 1) * SQRT((ABS(CHECKSUM(n.Seq, 7)) % 100000) / 100000.0) AS INT) AS DayIdx,
           -- gio: dồn cao diem sang (7-9) & toi (17-20)
           CASE (ABS(CHECKSUM(n.Seq, 13)) % 20)
                WHEN 0 THEN 8 WHEN 1 THEN 8 WHEN 2 THEN 7 WHEN 3 THEN 9
                WHEN 4 THEN 17 WHEN 5 THEN 18 WHEN 6 THEN 18 WHEN 7 THEN 19 WHEN 8 THEN 20
                WHEN 9 THEN 12 WHEN 10 THEN 11 WHEN 11 THEN 13 WHEN 12 THEN 16
                WHEN 13 THEN 10 WHEN 14 THEN 14 WHEN 15 THEN 15 WHEN 16 THEN 21
                WHEN 17 THEN 22 WHEN 18 THEN 6 ELSE 23 END AS Hr,
           (n.Seq % 60) AS Minu,
           20 + (n.Seq % 80) AS DurationMinutes,
           CAST(6.0 + ((ABS(CHECKSUM(n.Seq, 3)) % 70)) * 0.55 AS DECIMAL(14,4)) AS TotalKWh,
           CAST(100000 + (n.Seq * 8.5) AS DECIMAL(14,4)) AS MeterStart,
           (n.Seq % 11) AS PolicyBucket
    FROM #Nums n
    JOIN #Customers c ON c.CustomerRow = (ABS(CHECKSUM(n.Seq, 37)) % @CustTotal) + 1
    JOIN #Points pt   ON pt.rn = (ABS(CHECKSUM(n.Seq, 101)) % @PointTotal) + 1
)
SELECT Seq, UserID, VehicleID, PointID, StationID, DurationMinutes, TotalKWh, MeterStart,
       DATEADD(MINUTE, Minu, DATEADD(HOUR, Hr, DATEADD(DAY, DayIdx, CAST(CAST(@StartDate AS DATE) AS DATETIME2)))) AS StartTime,
       PolicyBucket,
       CAST(NULL AS INT) AS PolicyID,
       CAST(NULL AS NVARCHAR(30)) AS SessionStatus,
       CAST(NULL AS DECIMAL(19,4)) AS CostBeforeTax,
       CAST(NULL AS DECIMAL(19,4)) AS TaxAmount,
       CAST(NULL AS DECIMAL(19,4)) AS CostTotal
INTO #SessionSeed
FROM Base;

-- Chon PolicyID theo nam (truoc/sau @Y2) + loai (std/night/fast)
UPDATE #SessionSeed
SET PolicyID = CASE
        WHEN StartTime < @Y2 THEN (CASE WHEN PolicyBucket = 0 THEN @NGT24 WHEN PolicyBucket IN (1,2) THEN @FST24 ELSE @STD24 END)
        ELSE (CASE WHEN PolicyBucket = 0 THEN @NGT25 WHEN PolicyBucket IN (1,2) THEN @FST25 ELSE @STD25 END)
    END,
    SessionStatus = CASE
        WHEN Seq % 997 = 0 THEN N'EmergencyStopped'
        WHEN Seq % 50 = 0 THEN N'Cancelled'
        WHEN Seq % 25 = 0 THEN N'Failed'
        ELSE N'Completed' END;

-- Phien dang sac: chon 250 phien co StartTime gan @EndDate nhat (cho man hinh "dang sac" / active sessions)
;WITH Recent AS (SELECT TOP (250) Seq FROM #SessionSeed ORDER BY StartTime DESC)
UPDATE ss SET ss.SessionStatus = N'Charging'
FROM #SessionSeed ss JOIN Recent r ON r.Seq = ss.Seq;

UPDATE #SessionSeed
SET CostBeforeTax = Operations.fn_CalculateChargingCost(TotalKWh, PolicyID, StartTime)
WHERE SessionStatus IN (N'Completed', N'Failed', N'EmergencyStopped');

UPDATE #SessionSeed
SET TaxAmount = ROUND(ISNULL(CostBeforeTax,0) * 0.08, 4),
    CostTotal = ISNULL(CostBeforeTax,0) + ROUND(ISNULL(CostBeforeTax,0) * 0.08, 4)
WHERE CostBeforeTax IS NOT NULL;

-- Booking lich su (~30% phien): Completed/Expired de KHONG vi pham trigger overlap
INSERT INTO Operations.Booking (BookingCode, UserID, VehicleID, StationID, PointID, BookedFrom, BookedTo, BookingStatus, CreatedAt, UpdatedAt)
SELECT N'BKG-' + RIGHT(N'00000000' + CAST(Seq AS NVARCHAR(10)), 8),
       UserID, VehicleID, StationID, PointID,
       DATEADD(MINUTE, -20, StartTime), DATEADD(MINUTE, DurationMinutes + 20, StartTime),
       CASE WHEN SessionStatus = N'Completed' THEN N'Completed' ELSE N'Expired' END,
       DATEADD(DAY, -1, StartTime), DATEADD(MINUTE, DurationMinutes, StartTime)
FROM #SessionSeed
WHERE Seq % 3 = 0 AND SessionStatus <> N'Charging';

-- Charging sessions
INSERT INTO Operations.ChargingSession
    (SessionCode, UserID, VehicleID, StationID, PointID, PolicyID, BookingID, StartTime, EndTime,
     MeterStart, MeterEnd, TotalKWh, DurationMinutes, CostBeforeTax, TaxAmount, CostTotal, SessionStatus, StopReason, CreatedAt, UpdatedAt)
SELECT N'SES-' + RIGHT(N'00000000' + CAST(ss.Seq AS NVARCHAR(10)), 8),
       ss.UserID, ss.VehicleID, ss.StationID, ss.PointID, ss.PolicyID, b.BookingID,
       ss.StartTime,
       CASE WHEN ss.SessionStatus = N'Charging' THEN NULL ELSE DATEADD(MINUTE, ss.DurationMinutes, ss.StartTime) END,
       ss.MeterStart,
       CASE WHEN ss.SessionStatus = N'Charging' THEN NULL ELSE ss.MeterStart + ss.TotalKWh END,
       CASE WHEN ss.SessionStatus = N'Cancelled' THEN NULL ELSE ss.TotalKWh END,
       CASE WHEN ss.SessionStatus = N'Charging' THEN NULL ELSE ss.DurationMinutes END,
       ss.CostBeforeTax, ISNULL(ss.TaxAmount,0), ss.CostTotal,
       ss.SessionStatus,
       CASE ss.SessionStatus WHEN N'Completed' THEN N'Completed' WHEN N'Failed' THEN N'Connector fault'
            WHEN N'EmergencyStopped' THEN N'Emergency stop' WHEN N'Cancelled' THEN N'User cancelled' ELSE NULL END,
       ss.StartTime,
       CASE WHEN ss.SessionStatus = N'Charging' THEN NULL ELSE DATEADD(MINUTE, ss.DurationMinutes, ss.StartTime) END
FROM #SessionSeed ss
LEFT JOIN Operations.Booking b ON b.BookingCode = N'BKG-' + RIGHT(N'00000000' + CAST(ss.Seq AS NVARCHAR(10)), 8);

INSERT INTO Operations.SessionEvent (SessionID, EventType, EventPayload, CreatedAt)
SELECT cs.SessionID, cs.SessionStatus, cs.StopReason, ISNULL(cs.EndTime, cs.StartTime)
FROM Operations.ChargingSession cs;

/* ============================================================
   10) PAYMENTS + INVOICES (cho phien Completed)
   ============================================================ */
INSERT INTO Payments.PaymentTransaction
    (TransactionCode, UserID, SessionID, PaymentMethod, Amount, TransactionStatus, ProviderReference, PaidAt, CreatedAt)
SELECT N'TXN-' + RIGHT(N'00000000' + CAST(ss.Seq AS NVARCHAR(10)), 8),
       cs.UserID, cs.SessionID,
       CASE WHEN ss.Seq % 5 = 0 THEN N'BANK_TRANSFER' WHEN ss.Seq % 3 = 0 THEN N'QR' ELSE N'CASH' END,
       cs.CostTotal,
       CASE WHEN ss.Seq % 1201 = 0 THEN N'Refunded' ELSE N'Completed' END,
       CASE WHEN ss.Seq % 3 = 0 THEN N'PROVIDER-' + CAST(ss.Seq AS NVARCHAR(20)) ELSE NULL END,
       DATEADD(MINUTE, 2, cs.EndTime), DATEADD(MINUTE, 2, cs.EndTime)
FROM #SessionSeed ss
JOIN Operations.ChargingSession cs ON cs.SessionCode = N'SES-' + RIGHT(N'00000000' + CAST(ss.Seq AS NVARCHAR(10)), 8)
WHERE cs.SessionStatus = N'Completed';

INSERT INTO Payments.Invoice
    (InvoiceCode, UserID, SessionID, TransactionID, Subtotal, TaxAmount, TotalAmount, InvoiceStatus, IssuedAt)
SELECT N'INV-' + RIGHT(N'00000000' + CAST(ss.Seq AS NVARCHAR(10)), 8),
       cs.UserID, cs.SessionID, pt.TransactionID, cs.CostBeforeTax, cs.TaxAmount, cs.CostTotal,
       CASE WHEN pt.TransactionStatus = N'Refunded' THEN N'Refunded' ELSE N'Paid' END,
       DATEADD(MINUTE, 3, cs.EndTime)
FROM #SessionSeed ss
JOIN Operations.ChargingSession cs ON cs.SessionCode = N'SES-' + RIGHT(N'00000000' + CAST(ss.Seq AS NVARCHAR(10)), 8)
JOIN Payments.PaymentTransaction pt ON pt.SessionID = cs.SessionID;

/* ============================================================
   11) TELEMETRY (~@TelemetryRows)
   ============================================================ */
SELECT TOP (@TelemetryRows) ROW_NUMBER() OVER (ORDER BY a.object_id, b.object_id) AS Seq
INTO #TelemetryNums
FROM sys.all_objects a CROSS JOIN sys.all_objects b;

INSERT INTO Infrastructure.PointTelemetry (PointID, Voltage, CurrentAmp, TemperatureC, PowerKW, HealthStatus, RecordedAt)
SELECT p.PointID, 370 + (t.Seq % 20), 35 + (t.Seq % 70), 27 + (t.Seq % 28), 10 + (t.Seq % 120),
       CASE WHEN t.Seq % 997 = 0 THEN N'Offline' WHEN t.Seq % 389 = 0 THEN N'Critical'
            WHEN t.Seq % 113 = 0 THEN N'Warning' ELSE N'Normal' END,
       DATEADD(MINUTE, (t.Seq * 173) % (@Days * 1440), @StartDate)
FROM #TelemetryNums t
JOIN #Points p ON p.rn = (t.Seq % @PointTotal) + 1;

/* ============================================================
   12) ERROR LOG + MAINTENANCE TICKET (~1.8k)
   ============================================================ */
SELECT TOP (1800) ROW_NUMBER() OVER (ORDER BY a.object_id, b.object_id) AS Seq
INTO #ErrorNums FROM sys.all_objects a CROSS JOIN sys.all_objects b;

INSERT INTO Maintenance.ErrorLog (ErrorCode, StationID, PointID, Severity, Description, OccurredAt, ResolvedAt, ResolvedBy, IsActive)
SELECT N'ERR-' + RIGHT(N'00000' + CAST(n.Seq AS NVARCHAR(10)), 5),
       p.StationID, p.PointID,
       CASE WHEN n.Seq % 17 = 0 THEN N'Critical' WHEN n.Seq % 7 = 0 THEN N'High' WHEN n.Seq % 3 = 0 THEN N'Medium' ELSE N'Low' END,
       N'Device issue sample ' + CAST(n.Seq AS NVARCHAR(10)),
       DATEADD(DAY, (n.Seq * 11) % @Days, @StartDate),
       CASE WHEN n.Seq % 9 = 0 THEN NULL ELSE DATEADD(HOUR, 4 + (n.Seq % 48), DATEADD(DAY, (n.Seq * 11) % @Days, @StartDate)) END,
       CASE WHEN n.Seq % 9 = 0 THEN NULL ELSE (SELECT UserID FROM [Identity].UserAccount WHERE Username = N'operator' + RIGHT(N'00' + CAST(((n.Seq - 1) % @OpCount) + 1 AS NVARCHAR(10)), 2)) END,
       CASE WHEN n.Seq % 9 = 0 THEN 1 ELSE 0 END
FROM #ErrorNums n
JOIN #Points p ON p.rn = (n.Seq % @PointTotal) + 1;

INSERT INTO Maintenance.MaintenanceTicket (TicketCode, StationID, PointID, ErrorID, CreatedBy, AssignedTo, Priority, TicketStatus, Title, Description, OpenedAt, ClosedAt)
SELECT N'MT-' + RIGHT(N'00000' + CAST(e.ErrorID AS NVARCHAR(10)), 5),
       e.StationID, e.PointID, e.ErrorID, op.UserID, op.UserID, e.Severity,
       CASE WHEN e.ResolvedAt IS NULL THEN (CASE WHEN e.ErrorID % 3 = 0 THEN N'InProgress' WHEN e.ErrorID % 3 = 1 THEN N'Assigned' ELSE N'Open' END) ELSE N'Closed' END,
       N'Maintenance ticket for ' + e.ErrorCode,
       N'Auto-generated to simulate two years of operation',
       e.OccurredAt, e.ResolvedAt
FROM Maintenance.ErrorLog e
CROSS APPLY (SELECT TOP 1 UserID FROM [Identity].UserAccount WHERE Username LIKE N'operator%' ORDER BY UserID) op
WHERE e.ErrorCode LIKE N'ERR-%';

/* ============================================================
   13) BAT LAI TRIGGER + dong bo trang thai diem dang sac
   ============================================================ */
ENABLE TRIGGER ALL ON [Identity].UserAccount;
ENABLE TRIGGER ALL ON [Identity].UserRole;
ENABLE TRIGGER ALL ON Franchise.FranchisePartner;
ENABLE TRIGGER ALL ON Franchise.FranchiseContract;
ENABLE TRIGGER ALL ON Franchise.RevenueSharePolicy;
ENABLE TRIGGER ALL ON Franchise.RevenueShareSettlement;
ENABLE TRIGGER ALL ON Infrastructure.ChargingPoint;
ENABLE TRIGGER ALL ON Operations.Booking;
ENABLE TRIGGER ALL ON Operations.ChargingSession;
ENABLE TRIGGER ALL ON Payments.PaymentTransaction;
ENABLE TRIGGER ALL ON Maintenance.MaintenanceTicket;

-- Diem dang co phien Charging -> PointStatus = Charging
UPDATE cp SET cp.PointStatus = N'Charging', cp.UpdatedAt = SYSDATETIME()
FROM Infrastructure.ChargingPoint cp
WHERE cp.PointStatus = N'Available'
  AND EXISTS (SELECT 1 FROM Operations.ChargingSession cs WHERE cs.PointID = cp.PointID AND cs.SessionStatus = N'Charging');

/* ============================================================
   14) SETTLEMENT theo thang (qua stored procedure)
   ============================================================ */
DECLARE @StartDate2 DATE = DATEADD(YEAR, -2, CAST(SYSDATETIME() AS DATE));
DECLARE @MonthStart DATE = DATEFROMPARTS(YEAR(@StartDate2), MONTH(@StartDate2), 1);
DECLARE @LastMonth  DATE = DATEFROMPARTS(YEAR(SYSDATETIME()), MONTH(SYSDATETIME()), 1);

WHILE @MonthStart <= @LastMonth
BEGIN
    DECLARE @MonthEnd DATE = EOMONTH(@MonthStart);
    DECLARE @FranchiseID INT;

    DECLARE FranchiseCursor CURSOR LOCAL FAST_FORWARD FOR
        SELECT FranchiseID FROM Franchise.FranchisePartner ORDER BY FranchiseID;
    OPEN FranchiseCursor;
    FETCH NEXT FROM FranchiseCursor INTO @FranchiseID;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN TRY
            EXEC Franchise.sp_CreateRevenueSettlement @FranchiseID = @FranchiseID, @PeriodStart = @MonthStart, @PeriodEnd = @MonthEnd;
        END TRY
        BEGIN CATCH
            -- bo qua thang khong co doanh thu
        END CATCH;
        FETCH NEXT FROM FranchiseCursor INTO @FranchiseID;
    END;
    CLOSE FranchiseCursor;
    DEALLOCATE FranchiseCursor;

    SET @MonthStart = DATEADD(MONTH, 1, @MonthStart);
END;

DROP TABLE #StationPlan;
DROP TABLE #Nums;
DROP TABLE #Customers;
DROP TABLE #Points;
DROP TABLE #SessionSeed;
DROP TABLE #TelemetryNums;
DROP TABLE #ErrorNums;

PRINT N'09 - Realistic VN two-year seed created: ~40 regions, ~155 stations, ~850 points, 500 customers, ~300k sessions, telemetry, maintenance, payments, invoices, settlements.';
GO
