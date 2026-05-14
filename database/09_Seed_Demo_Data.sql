USE EV_Charging_System;
GO

/*
HUONG DAN SU DUNG
- Muc dich: tao du lieu lon nhu he thong da hoat dong gan 2 nam.
- Chay sau cac script 00 -> 08.
- Du lieu tao ra:
  + 20 nhan su/quan tri/kinh doanh/van hanh va 500 customer.
  + 12 tinh/thanh lon, 8 doi tac franchise, 60 tram sac, 300 cong sac.
  + 120000 charging sessions trong khoang 2024-05-15 den 2026-05-13.
  + Booking, payment, invoice, telemetry, error log, maintenance ticket va settlement theo quy mo lon.
- Script nay duoc thiet ke cho database moi sau khi chay 00_Drop_And_Create_Database.sql.
*/

SET NOCOUNT ON;

DECLARE @Hash NVARCHAR(256) = N'$2a$12$DemoHashForIE103DatabaseOnly';
DECLARE @StartDate DATETIME2 = '2024-05-15T00:00:00';
DECLARE @EndDate DATETIME2 = '2026-05-13T23:59:00';
DECLARE @TotalMinutes INT = DATEDIFF(MINUTE, @StartDate, @EndDate);

INSERT INTO Core.Region (RegionCode, RegionName)
VALUES
(N'HCMC', N'Ho Chi Minh City'),
(N'HAN', N'Ha Noi'),
(N'DN', N'Da Nang'),
(N'HP', N'Hai Phong'),
(N'CT', N'Can Tho'),
(N'BD', N'Binh Duong'),
(N'DNAI', N'Dong Nai'),
(N'KH', N'Khanh Hoa'),
(N'QN', N'Quang Ninh'),
(N'TH', N'Thanh Hoa'),
(N'HUE', N'Thue'),
(N'BRVT', N'Ba Ria - Vung Tau');

INSERT INTO Core.Address (RegionID, StreetAddress, Ward, District, Latitude, Longitude)
SELECT r.RegionID,
       N'Partner office ' + CAST(n.n AS NVARCHAR(10)),
       N'Central Ward',
       N'Central District',
       9.0000000 + (n.n * 0.1700000),
       105.0000000 + (n.n * 0.1100000)
FROM (
    SELECT TOP (8) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects
) n
JOIN Core.Region r ON r.RegionID = ((n.n - 1) % 12) + 1;

INSERT INTO Core.Address (RegionID, StreetAddress, Ward, District, Latitude, Longitude)
SELECT r.RegionID,
       N'Station street ' + CAST(n.n AS NVARCHAR(10)),
       N'Ward ' + CAST(((n.n - 1) % 20) + 1 AS NVARCHAR(10)),
       N'District ' + CAST(((n.n - 1) % 12) + 1 AS NVARCHAR(10)),
       9.5000000 + ((n.n % 50) * 0.0800000),
       105.5000000 + ((n.n % 60) * 0.0700000)
FROM (
    SELECT TOP (60) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects
) n
JOIN Core.Region r ON r.RegionID = ((n.n - 1) % 12) + 1;

INSERT INTO [Identity].[Role] (RoleCode, RoleName, Description)
VALUES
(N'SystemAdmin', N'System administrator', N'Full database administration role'),
(N'OperationsStaff', N'Operations staff', N'Operates stations, charging points, sessions, errors, and tickets'),
(N'BusinessManager', N'Business manager', N'Views revenue, manages pricing, franchise settlement, and KPI datasets'),
(N'Customer', N'Customer', N'Owns vehicles, books charging, starts sessions, pays, and views history');

INSERT INTO [Identity].UserAccount (Username, Email, Phone, PasswordHash, FullName)
VALUES
(N'admin01', N'admin01@gmail.com', N'0901000001', @Hash, N'System Admin 01'),
(N'admin02', N'admin02@gmail.com', N'0901000002', @Hash, N'System Admin 02'),
(N'business01', N'business01@gmail.com', N'0901100001', @Hash, N'Business Manager 01'),
(N'business02', N'business02@gmail.com', N'0901100002', @Hash, N'Business Manager 02'),
(N'business03', N'business03@gmail.com', N'0901100003', @Hash, N'Business Manager 03'),
(N'business04', N'business04@gmail.com', N'0901100004', @Hash, N'Business Manager 04'),
(N'business05', N'business05@gmail.com', N'0901100005', @Hash, N'Business Manager 05'),
(N'operator01', N'operator01@gmail.com', N'0901200001', @Hash, N'Operations Staff 01'),
(N'operator02', N'operator02@gmail.com', N'0901200002', @Hash, N'Operations Staff 02'),
(N'operator03', N'operator03@gmail.com', N'0901200003', @Hash, N'Operations Staff 03'),
(N'operator04', N'operator04@gmail.com', N'0901200004', @Hash, N'Operations Staff 04'),
(N'operator05', N'operator05@gmail.com', N'0901200005', @Hash, N'Operations Staff 05'),
(N'operator06', N'operator06@gmail.com', N'0901200006', @Hash, N'Operations Staff 06'),
(N'operator07', N'operator07@gmail.com', N'0901200007', @Hash, N'Operations Staff 07'),
(N'operator08', N'operator08@gmail.com', N'0901200008', @Hash, N'Operations Staff 08'),
(N'operator09', N'operator09@gmail.com', N'0901200009', @Hash, N'Operations Staff 09'),
(N'operator10', N'operator10@gmail.com', N'0901200010', @Hash, N'Operations Staff 10'),
(N'operator11', N'operator11@gmail.com', N'0901200011', @Hash, N'Operations Staff 11'),
(N'operator12', N'operator12@gmail.com', N'0901200012', @Hash, N'Operations Staff 12'),
(N'operator13', N'operator13@gmail.com', N'0901200013', @Hash, N'Operations Staff 13');

WITH N AS
(
    SELECT TOP (500) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT INTO [Identity].UserAccount (Username, Email, Phone, PasswordHash, FullName, CreatedAt)
SELECT CASE WHEN n <= 99 THEN N'customer' + RIGHT(N'00' + CAST(n AS NVARCHAR(10)), 2)
            ELSE N'customer' + CAST(n AS NVARCHAR(10)) END,
       CASE WHEN n <= 99 THEN N'customer' + RIGHT(N'00' + CAST(n AS NVARCHAR(10)), 2)
            ELSE N'customer' + CAST(n AS NVARCHAR(10)) END + N'@gmail.com',
       N'091' + RIGHT(N'0000000' + CAST(n AS NVARCHAR(10)), 7),
       @Hash,
       N'Customer ' + RIGHT(N'000' + CAST(n AS NVARCHAR(10)), 3),
       DATEADD(DAY, n % 700, @StartDate)
FROM N;

INSERT INTO [Identity].UserRole (UserID, RoleID)
SELECT u.UserID, r.RoleID
FROM [Identity].UserAccount u
JOIN [Identity].[Role] r ON r.RoleCode =
    CASE
        WHEN u.Username LIKE N'admin%' THEN N'SystemAdmin'
        WHEN u.Username LIKE N'operator%' THEN N'OperationsStaff'
        WHEN u.Username LIKE N'business%' THEN N'BusinessManager'
        ELSE N'Customer'
    END;

INSERT INTO Franchise.FranchisePartner
    (FranchiseCode, FranchiseName, TaxCode, AddressID, ContactUserID, ContactPerson, ContactPhone, ContactEmail)
SELECT N'FRC' + RIGHT(N'00' + CAST(n.n AS NVARCHAR(10)), 2),
       N'EV Franchise Partner ' + CAST(n.n AS NVARCHAR(10)),
       N'TAX2026' + RIGHT(N'00' + CAST(n.n AS NVARCHAR(10)), 2),
       n.n,
       (SELECT TOP 1 UserID FROM [Identity].UserAccount WHERE Username = N'business' + RIGHT(N'00' + CAST(((n.n - 1) % 5) + 1 AS NVARCHAR(10)), 2)),
       N'Partner Contact ' + CAST(n.n AS NVARCHAR(10)),
       N'092' + RIGHT(N'0000000' + CAST(n.n AS NVARCHAR(10)), 7),
       N'partner' + CAST(n.n AS NVARCHAR(10)) + N'@ev.vn'
FROM (
    SELECT TOP (8) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects
) n;

INSERT INTO Franchise.FranchiseContract (FranchiseID, ContractCode, StartDate, EndDate, BaseRevenueShareRate, ContractStatus)
SELECT FranchiseID,
       N'FC-' + FranchiseCode + N'-2024',
       CAST('2024-05-01' AS DATE),
       CAST('2027-12-31' AS DATE),
       60.00 + (FranchiseID % 8),
       N'Active'
FROM Franchise.FranchisePartner;

INSERT INTO Franchise.RevenueSharePolicy (ContractID, PolicyCode, PartnerShareRate, AppliedFrom)
SELECT ContractID, N'RSP-' + ContractCode, BaseRevenueShareRate, StartDate
FROM Franchise.FranchiseContract;

INSERT INTO Infrastructure.ElectricitySupplier (SupplierCode, SupplierName, RegionID, UnitPricePerKWh)
SELECT N'EVN-' + r.RegionCode,
       N'EVN ' + r.RegionName,
       r.RegionID,
       1900 + (r.RegionID * 25)
FROM Core.Region r;

INSERT INTO Infrastructure.ConnectorType (ConnectorCode, ConnectorName, MaxPowerKW)
VALUES
(N'CCS2', N'Combined Charging System Type 2', 350),
(N'CHAdeMO', N'CHAdeMO DC', 100),
(N'Type2', N'AC Type 2', 43),
(N'GBT', N'GB/T DC', 180);

DECLARE @CCS2 INT = (SELECT ConnectorTypeID FROM Infrastructure.ConnectorType WHERE ConnectorCode = N'CCS2');
DECLARE @CHA INT = (SELECT ConnectorTypeID FROM Infrastructure.ConnectorType WHERE ConnectorCode = N'CHAdeMO');
DECLARE @T2 INT = (SELECT ConnectorTypeID FROM Infrastructure.ConnectorType WHERE ConnectorCode = N'Type2');
DECLARE @GBT INT = (SELECT ConnectorTypeID FROM Infrastructure.ConnectorType WHERE ConnectorCode = N'GBT');

WITH N AS
(
    SELECT TOP (60) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects
)
INSERT INTO Infrastructure.ChargingStation
    (StationCode, StationName, FranchiseID, AddressID, SupplierID, StationOperatorID, ModelName, Manufacturer, MaxPowerKW, StationStatus, OpenedAt)
SELECT N'ST-' + RIGHT(N'000' + CAST(n AS NVARCHAR(10)), 3),
       N'EV Charging Station ' + RIGHT(N'000' + CAST(n AS NVARCHAR(10)), 3),
       ((n - 1) % 8) + 1,
       8 + n,
       ((n - 1) % 12) + 1,
       (SELECT TOP 1 UserID FROM [Identity].UserAccount WHERE Username = N'operator' + RIGHT(N'00' + CAST(((n - 1) % 13) + 1 AS NVARCHAR(10)), 2)),
       CASE WHEN n % 3 = 0 THEN N'ABB Terra 184' WHEN n % 3 = 1 THEN N'VF DC 150' ELSE N'Siemens Sicharge' END,
       CASE WHEN n % 3 = 0 THEN N'ABB' WHEN n % 3 = 1 THEN N'VinFast' ELSE N'Siemens' END,
       CASE WHEN n % 4 = 0 THEN 300 WHEN n % 4 = 1 THEN 150 WHEN n % 4 = 2 THEN 120 ELSE 60 END,
       CASE WHEN n % 29 = 0 THEN N'UnderMaintenance' ELSE N'Active' END,
       DATEADD(DAY, n * 4, @StartDate)
FROM N;

INSERT INTO Franchise.FranchiseStation (FranchiseID, StationID, ContractID)
SELECT s.FranchiseID, s.StationID, fc.ContractID
FROM Infrastructure.ChargingStation s
JOIN Franchise.FranchiseContract fc ON fc.FranchiseID = s.FranchiseID AND fc.ContractStatus = N'Active';

INSERT INTO Infrastructure.StationConnectorType (StationID, ConnectorTypeID)
SELECT StationID, @CCS2 FROM Infrastructure.ChargingStation
UNION ALL SELECT StationID, @T2 FROM Infrastructure.ChargingStation
UNION ALL SELECT StationID, @CHA FROM Infrastructure.ChargingStation WHERE StationID % 2 = 0
UNION ALL SELECT StationID, @GBT FROM Infrastructure.ChargingStation WHERE StationID % 3 = 0;

WITH N AS
(
    SELECT TOP (300) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT INTO Infrastructure.ChargingPoint (PointCode, StationID, ConnectorTypeID, PowerKW, SerialNumber, PointStatus, HealthStatus)
SELECT N'P-' + RIGHT(N'000' + CAST(((n - 1) / 5) + 1 AS NVARCHAR(10)), 3) + N'-' + CHAR(65 + ((n - 1) % 5)),
       ((n - 1) / 5) + 1,
       CASE WHEN n % 5 = 0 THEN @T2
            WHEN n % 5 = 1 THEN @CCS2
            WHEN n % 5 = 2 THEN @CCS2
            WHEN n % 5 = 3 THEN @CHA
            ELSE @GBT END,
       CASE WHEN n % 5 = 0 THEN 22
            WHEN n % 5 IN (1,2) THEN 150
            WHEN n % 5 = 3 THEN 60
            ELSE 120 END,
       N'SN-HIST-' + RIGHT(N'000000' + CAST(n AS NVARCHAR(10)), 6),
       CASE WHEN n % 113 = 0 THEN N'Maintenance'
            WHEN n % 97 = 0 THEN N'Offline'
            ELSE N'Available' END,
       CASE WHEN n % 113 = 0 THEN N'Warning'
            WHEN n % 97 = 0 THEN N'Offline'
            ELSE N'Normal' END
FROM N;

INSERT INTO Operations.PricingPolicy (PolicyCode, PolicyName, BasePricePerKWh, PeakMultiplier, PeakStartHour, PeakEndHour, AppliedFrom)
VALUES
(N'STD-2024', N'Standard price 2024-2026', 3500, 1.25, '17:00', '20:00', CAST(@StartDate AS DATE)),
(N'NIGHT-2024', N'Night price 2024-2026', 2800, 1.00, NULL, NULL, CAST(@StartDate AS DATE)),
(N'FAST-2024', N'Fast charging price 2024-2026', 4300, 1.35, '16:00', '21:00', CAST(@StartDate AS DATE));

WITH Customers AS
(
    SELECT ROW_NUMBER() OVER (ORDER BY UserID) AS rn, UserID
    FROM [Identity].UserAccount
    WHERE Username LIKE N'customer%'
)
INSERT INTO Operations.Vehicle (UserID, PlateNumber, Brand, Model, BatteryCapacityKWh, PreferredConnectorTypeID)
SELECT UserID,
       N'EV-' + RIGHT(N'000000' + CAST(rn AS NVARCHAR(10)), 6),
       CASE WHEN rn % 5 = 0 THEN N'VinFast'
            WHEN rn % 5 = 1 THEN N'Tesla'
            WHEN rn % 5 = 2 THEN N'Hyundai'
            WHEN rn % 5 = 3 THEN N'Kia'
            ELSE N'BYD' END,
       CASE WHEN rn % 5 = 0 THEN N'VF 8'
            WHEN rn % 5 = 1 THEN N'Model 3'
            WHEN rn % 5 = 2 THEN N'Ioniq 5'
            WHEN rn % 5 = 3 THEN N'EV6'
            ELSE N'Atto 3' END,
       CASE WHEN rn % 5 = 0 THEN 82.00
            WHEN rn % 5 = 1 THEN 75.00
            WHEN rn % 5 = 2 THEN 72.60
            WHEN rn % 5 = 3 THEN 77.40
            ELSE 60.50 END,
       CASE WHEN rn % 7 = 0 THEN @T2 ELSE @CCS2 END
FROM Customers;

WITH Customers AS
(
    SELECT ROW_NUMBER() OVER (ORDER BY UserID) AS rn, UserID
    FROM [Identity].UserAccount
    WHERE Username LIKE N'customer%'
)
INSERT INTO Operations.Vehicle (UserID, PlateNumber, Brand, Model, BatteryCapacityKWh, PreferredConnectorTypeID)
SELECT UserID,
       N'EV-2-' + RIGHT(N'00000' + CAST(rn AS NVARCHAR(10)), 5),
       CASE WHEN rn % 2 = 0 THEN N'VinFast' ELSE N'Tesla' END,
       CASE WHEN rn % 2 = 0 THEN N'VF e34' ELSE N'Model Y' END,
       CASE WHEN rn % 2 = 0 THEN 42.00 ELSE 78.00 END,
       @CCS2
FROM Customers
WHERE rn % 3 = 0;

SELECT TOP (120000)
       ROW_NUMBER() OVER (ORDER BY a.object_id, b.object_id) AS Seq
INTO #Nums
FROM sys.all_objects a CROSS JOIN sys.all_objects b;

SELECT ROW_NUMBER() OVER (ORDER BY u.UserID) AS CustomerRow,
       u.UserID,
       (SELECT TOP 1 v.VehicleID FROM Operations.Vehicle v WHERE v.UserID = u.UserID ORDER BY v.VehicleID) AS VehicleID
INTO #Customers
FROM [Identity].UserAccount u
WHERE u.Username LIKE N'customer%';

SELECT n.Seq,
       c.UserID,
       c.VehicleID,
       ((n.Seq * 17) % 300) + 1 AS PointID,
       CAST(NULL AS INT) AS StationID,
       CASE WHEN n.Seq % 11 = 0 THEN 2 WHEN n.Seq % 7 = 0 THEN 3 ELSE 1 END AS PolicyID,
       DATEADD(MINUTE, (n.Seq * 37) % @TotalMinutes, @StartDate) AS StartTime,
       20 + (n.Seq % 80) AS DurationMinutes,
       CAST(6.0 + ((n.Seq * 13) % 70) * 0.55 AS DECIMAL(14,4)) AS TotalKWh,
       CAST(100000 + (n.Seq * 8.5) AS DECIMAL(14,4)) AS MeterStart,
       CAST(NULL AS DECIMAL(19,4)) AS CostBeforeTax,
       CAST(NULL AS DECIMAL(19,4)) AS TaxAmount,
       CAST(NULL AS DECIMAL(19,4)) AS CostTotal,
       CAST(NULL AS NVARCHAR(30)) AS SessionStatus
INTO #SessionSeed
FROM #Nums n
JOIN #Customers c ON c.CustomerRow = ((n.Seq * 37) % 500) + 1;

UPDATE ss
SET StationID = p.StationID,
    CostBeforeTax = Operations.fn_CalculateChargingCost(ss.TotalKWh, ss.PolicyID, ss.StartTime),
    SessionStatus = CASE
        WHEN ss.Seq % 997 = 0 THEN N'EmergencyStopped'
        WHEN ss.Seq % 43 = 0 THEN N'Failed'
        ELSE N'Completed'
    END
FROM #SessionSeed ss
JOIN Infrastructure.ChargingPoint p ON p.PointID = ss.PointID;

UPDATE #SessionSeed
SET TaxAmount = ROUND(CostBeforeTax * 0.08, 4),
    CostTotal = CostBeforeTax + ROUND(CostBeforeTax * 0.08, 4);

INSERT INTO Operations.Booking
    (BookingCode, UserID, VehicleID, StationID, PointID, BookedFrom, BookedTo, BookingStatus, CreatedAt, UpdatedAt)
SELECT N'BKG-HIST-' + RIGHT(N'000000' + CAST(Seq AS NVARCHAR(10)), 6),
       UserID,
       VehicleID,
       StationID,
       PointID,
       DATEADD(MINUTE, -20, StartTime),
       DATEADD(MINUTE, DurationMinutes + 20, StartTime),
       CASE WHEN SessionStatus = N'Completed' THEN N'Completed' ELSE N'Expired' END,
       DATEADD(DAY, -1, StartTime),
       DATEADD(MINUTE, DurationMinutes, StartTime)
FROM #SessionSeed
WHERE Seq % 4 = 0;

INSERT INTO Operations.ChargingSession
    (SessionCode, UserID, VehicleID, StationID, PointID, PolicyID, BookingID, StartTime, EndTime,
     MeterStart, MeterEnd, TotalKWh, DurationMinutes, CostBeforeTax, TaxAmount, CostTotal, SessionStatus, StopReason, CreatedAt, UpdatedAt)
SELECT N'SES-HIST-' + RIGHT(N'000000' + CAST(ss.Seq AS NVARCHAR(10)), 6),
       ss.UserID,
       ss.VehicleID,
       ss.StationID,
       ss.PointID,
       ss.PolicyID,
       b.BookingID,
       ss.StartTime,
       DATEADD(MINUTE, ss.DurationMinutes, ss.StartTime),
       ss.MeterStart,
       ss.MeterStart + ss.TotalKWh,
       ss.TotalKWh,
       ss.DurationMinutes,
       ss.CostBeforeTax,
       ss.TaxAmount,
       ss.CostTotal,
       ss.SessionStatus,
       CASE WHEN ss.SessionStatus = N'Completed' THEN N'Completed'
            WHEN ss.SessionStatus = N'Failed' THEN N'Connector fault'
            ELSE N'Emergency stop' END,
       ss.StartTime,
       DATEADD(MINUTE, ss.DurationMinutes, ss.StartTime)
FROM #SessionSeed ss
LEFT JOIN Operations.Booking b ON b.BookingCode = N'BKG-HIST-' + RIGHT(N'000000' + CAST(ss.Seq AS NVARCHAR(10)), 6);

INSERT INTO Operations.SessionEvent (SessionID, EventType, EventPayload, CreatedAt)
SELECT cs.SessionID,
       CASE WHEN cs.SessionStatus = N'Completed' THEN N'Completed' ELSE cs.SessionStatus END,
       cs.StopReason,
       cs.EndTime
FROM Operations.ChargingSession cs
WHERE cs.SessionCode LIKE N'SES-HIST-%';

INSERT INTO Payments.PaymentTransaction
    (TransactionCode, UserID, SessionID, PaymentMethod, Amount, TransactionStatus, ProviderReference, PaidAt, CreatedAt)
SELECT N'TXN-HIST-' + RIGHT(N'000000' + CAST(ss.Seq AS NVARCHAR(10)), 6),
       cs.UserID,
       cs.SessionID,
       CASE WHEN ss.Seq % 5 = 0 THEN N'BANK_TRANSFER'
            WHEN ss.Seq % 3 = 0 THEN N'QR'
            ELSE N'CASH' END,
       cs.CostTotal,
       CASE WHEN ss.Seq % 1201 = 0 THEN N'Refunded' ELSE N'Completed' END,
       CASE WHEN ss.Seq % 3 = 0 THEN N'HIST-PROVIDER-' + CAST(ss.Seq AS NVARCHAR(20)) ELSE NULL END,
       DATEADD(MINUTE, 2, cs.EndTime),
       DATEADD(MINUTE, 2, cs.EndTime)
FROM #SessionSeed ss
JOIN Operations.ChargingSession cs ON cs.SessionCode = N'SES-HIST-' + RIGHT(N'000000' + CAST(ss.Seq AS NVARCHAR(10)), 6)
WHERE cs.SessionStatus = N'Completed';

INSERT INTO Payments.Invoice
    (InvoiceCode, UserID, SessionID, TransactionID, Subtotal, TaxAmount, TotalAmount, InvoiceStatus, IssuedAt)
SELECT N'INV-HIST-' + RIGHT(N'000000' + CAST(ss.Seq AS NVARCHAR(10)), 6),
       cs.UserID,
       cs.SessionID,
       pt.TransactionID,
       cs.CostBeforeTax,
       cs.TaxAmount,
       cs.CostTotal,
       CASE WHEN pt.TransactionStatus = N'Refunded' THEN N'Refunded' ELSE N'Paid' END,
       DATEADD(MINUTE, 3, cs.EndTime)
FROM #SessionSeed ss
JOIN Operations.ChargingSession cs ON cs.SessionCode = N'SES-HIST-' + RIGHT(N'000000' + CAST(ss.Seq AS NVARCHAR(10)), 6)
JOIN Payments.PaymentTransaction pt ON pt.SessionID = cs.SessionID;

SELECT TOP (219000)
       ROW_NUMBER() OVER (ORDER BY a.object_id, b.object_id) AS Seq
INTO #TelemetryNums
FROM sys.all_objects a CROSS JOIN sys.all_objects b;

INSERT INTO Infrastructure.PointTelemetry
    (PointID, Voltage, CurrentAmp, TemperatureC, PowerKW, HealthStatus, RecordedAt)
SELECT ((Seq - 1) % 300) + 1,
       370 + (Seq % 20),
       35 + (Seq % 70),
       27 + (Seq % 28),
       10 + (Seq % 120),
       CASE WHEN Seq % 997 = 0 THEN N'Offline'
            WHEN Seq % 389 = 0 THEN N'Critical'
            WHEN Seq % 113 = 0 THEN N'Warning'
            ELSE N'Normal' END,
       DATEADD(HOUR, ((Seq - 1) / 300) * 24 + (Seq % 24), @StartDate)
FROM #TelemetryNums;

SELECT TOP (720)
       ROW_NUMBER() OVER (ORDER BY a.object_id, b.object_id) AS Seq
INTO #ErrorNums
FROM sys.all_objects a CROSS JOIN sys.all_objects b;

INSERT INTO Maintenance.ErrorLog
    (ErrorCode, StationID, PointID, Severity, Description, OccurredAt, ResolvedAt, ResolvedBy, IsActive)
SELECT N'HIST-ERR-' + RIGHT(N'0000' + CAST(n.Seq AS NVARCHAR(10)), 4),
       p.StationID,
       p.PointID,
       CASE WHEN n.Seq % 17 = 0 THEN N'Critical'
            WHEN n.Seq % 7 = 0 THEN N'High'
            WHEN n.Seq % 3 = 0 THEN N'Medium'
            ELSE N'Low' END,
       N'Historical device issue sample',
       DATEADD(DAY, n.Seq % 720, @StartDate),
       CASE WHEN n.Seq % 9 = 0 THEN NULL ELSE DATEADD(HOUR, 4 + (n.Seq % 48), DATEADD(DAY, n.Seq % 720, @StartDate)) END,
       CASE WHEN n.Seq % 9 = 0 THEN NULL ELSE (SELECT TOP 1 UserID FROM [Identity].UserAccount WHERE Username = N'operator' + RIGHT(N'00' + CAST(((n.Seq - 1) % 13) + 1 AS NVARCHAR(10)), 2)) END,
       CASE WHEN n.Seq % 9 = 0 THEN 1 ELSE 0 END
FROM #ErrorNums n
JOIN Infrastructure.ChargingPoint p ON p.PointID = ((n.Seq * 5) % 300) + 1;

INSERT INTO Maintenance.MaintenanceTicket
    (TicketCode, StationID, PointID, ErrorID, CreatedBy, AssignedTo, Priority, TicketStatus, Title, Description, OpenedAt, ClosedAt)
SELECT N'MT-HIST-' + RIGHT(N'0000' + CAST(e.ErrorID AS NVARCHAR(10)), 4),
       e.StationID,
       e.PointID,
       e.ErrorID,
       OperatorUser.UserID,
       OperatorUser.UserID,
       e.Severity,
       CASE WHEN e.ResolvedAt IS NULL THEN N'InProgress' ELSE N'Closed' END,
       N'Historical maintenance ticket',
       N'Generated to simulate two years of operation',
       e.OccurredAt,
       e.ResolvedAt
FROM Maintenance.ErrorLog e
CROSS APPLY (
    SELECT TOP 1 UserID
    FROM [Identity].UserAccount
    WHERE Username LIKE N'operator%'
    ORDER BY UserID
) OperatorUser
WHERE e.ErrorCode LIKE N'HIST-ERR-%';

DECLARE @MonthStart DATE = CAST('2024-05-01' AS DATE);
WHILE @MonthStart <= CAST('2026-05-01' AS DATE)
BEGIN
    DECLARE @MonthEnd DATE = EOMONTH(@MonthStart);
    DECLARE @FranchiseID INT;

    DECLARE FranchiseCursor CURSOR LOCAL FAST_FORWARD FOR
        SELECT FranchiseID FROM Franchise.FranchisePartner ORDER BY FranchiseID;

    OPEN FranchiseCursor;
    FETCH NEXT FROM FranchiseCursor INTO @FranchiseID;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        EXEC Franchise.sp_CreateRevenueSettlement
            @FranchiseID = @FranchiseID,
            @PeriodStart = @MonthStart,
            @PeriodEnd = @MonthEnd;

        FETCH NEXT FROM FranchiseCursor INTO @FranchiseID;
    END;
    CLOSE FranchiseCursor;
    DEALLOCATE FranchiseCursor;

    SET @MonthStart = DATEADD(MONTH, 1, @MonthStart);
END;

DROP TABLE #Nums;
DROP TABLE #Customers;
DROP TABLE #SessionSeed;
DROP TABLE #TelemetryNums;
DROP TABLE #ErrorNums;

PRINT N'09 - Large two-year seed data created: 520 users, 500 customers, 60 stations, 300 points, 120000 sessions, telemetry, maintenance, payments, invoices, and settlements.';
GO
