USE EV_Charging_System;
GO

-- ============================================================
-- Country & Region
-- ============================================================
INSERT INTO Infrastructure.Country (CountryCode, CountryName, CurrencyCode, PhonePrefix)
VALUES ('VN', N'Việt Nam', 'VND', '+84');

DECLARE @VN INT = (SELECT CountryID FROM Infrastructure.Country WHERE CountryCode = 'VN');

INSERT INTO Infrastructure.Region (CountryID, RegionCode, RegionName, TimeZone)
VALUES
    (@VN, 'HCMC', N'TP. Hồ Chí Minh', 'Asia/Ho_Chi_Minh'),
    (@VN, 'HAN',  N'Hà Nội',           'Asia/Ho_Chi_Minh'),
    (@VN, 'DN',   N'Đà Nẵng',          'Asia/Ho_Chi_Minh'),
    (@VN, 'BD',   N'Bình Dương',       'Asia/Ho_Chi_Minh'),
    (@VN, 'VT',   N'Vũng Tàu',         'Asia/Ho_Chi_Minh');

-- ============================================================
-- Addresses
-- ============================================================
DECLARE @HCMC INT = (SELECT RegionID FROM Infrastructure.Region WHERE RegionCode = 'HCMC');
DECLARE @HAN   INT = (SELECT RegionID FROM Infrastructure.Region WHERE RegionCode = 'HAN');
DECLARE @DN    INT = (SELECT RegionID FROM Infrastructure.Region WHERE RegionCode = 'DN');
DECLARE @BD    INT = (SELECT RegionID FROM Infrastructure.Region WHERE RegionCode = 'BD');
DECLARE @VT    INT = (SELECT RegionID FROM Infrastructure.Region WHERE RegionCode = 'VT');

INSERT INTO Infrastructure.Address (RegionID, StreetAddress, Ward, District, Latitude, Longitude)
VALUES
    (@HCMC, N'123 Nguyễn Huệ',   N'Bến Nghé',    N'Quận 1', 10.7765, 106.7012),
    (@HAN,  N'45 Tràng Tiền',    N'Tràng Tiền',  N'Hoàn Kiếm', 21.0278, 105.8522),
    (@DN,   N'78 Nguyễn Văn Linh', N'Hải Châu 1', N'Hải Châu', 16.0544, 108.2022),
    (@BD,   N'56 Đại lộ Bình Dương', N'Phú Mỹ',   N'Thủ Dầu Một', 10.9804, 106.6518),
    (@VT,   N'90 Quang Trung',    N'Phường 3',    N'TP. Vũng Tàu', 10.3456, 107.0842),
    (@HCMC, N'456 Lê Lợi',       N'Bến Thành',   N'Quận 1', 10.7711, 106.6984),
    (@HCMC, N'789 Nguyễn Văn Cừ', N'Nguyễn Cư Trinh', N'Quận 1', 10.7642, 106.6865),
    (@HAN,  N'12 Lý Thường Kiệt', N'Phan Chu Trinh', N'Hoàn Kiếm', 21.0245, 105.8528),
    (@DN,   N'34 Lê Duẩn',        N'Thạch Thang', N'Hải Châu', 16.0612, 108.2211),
    (@HCMC, N'100 Nguyễn Văn Linh', N'Tân Phong', N'Quận 7', 10.7312, 106.7222);

-- ============================================================
-- Franchises
-- ============================================================
DECLARE @A1 INT = (SELECT AddressID FROM Infrastructure.Address WHERE StreetAddress = N'123 Nguyễn Huệ');
DECLARE @A2 INT = (SELECT AddressID FROM Infrastructure.Address WHERE StreetAddress = N'45 Tràng Tiền');
DECLARE @A3 INT = (SELECT AddressID FROM Infrastructure.Address WHERE StreetAddress = N'78 Nguyễn Văn Linh');
DECLARE @A4 INT = (SELECT AddressID FROM Infrastructure.Address WHERE StreetAddress = N'56 Đại lộ Bình Dương');
DECLARE @A5 INT = (SELECT AddressID FROM Infrastructure.Address WHERE StreetAddress = N'90 Quang Trung');

INSERT INTO Infrastructure.Franchise (FranchiseCode, FranchiseName, TaxCode, AddressID, ContactPerson, ContactPhone, ContactEmail, RevenueShareRate, ContractSignedDate)
VALUES
    ('VINFAST01', N'VinFast Sài Gòn',   'VFSG2024001', @A1, N'Nguyễn Văn A', '0901001001', 'a.nguyen@vinfast.vn', 15.0, '2024-01-01'),
    ('VINFAST02', N'VinFast Hà Nội',    'VFHN2024001', @A2, N'Trần Thị B',   '0901001002', 'b.tran@vinfast.vn',  15.0, '2024-01-15'),
    ('EVN_01',    N'EVN Đà Nẵng',       'EVNDN2024001', @A3, N'Lê Văn C',     '0901001003', 'c.le@evn.vn',        10.0, '2024-02-01'),
    ('GREEN_BD',  N'Green Energy Bình Dương', 'GEBD2024001', @A4, N'Phạm Thị D','0901001004', 'd.pham@green.vn',    12.0, '2024-02-15'),
    ('VINFAST03', N'VinFast Vũng Tàu',  'VFVT2024001', @A5, N'Hoàng Văn E',  '0901001005', 'e.hoang@vinfast.vn', 15.0, '2024-03-01');

-- ============================================================
-- Electricity Suppliers
-- ============================================================
INSERT INTO Infrastructure.ElectricitySupplier (SupplierCode, SupplierName, RegionID, UnitPricePerKWh, ContactPerson, ContactPhone, ContactEmail, ContractSignedDate)
VALUES
    ('EVN-SG', N'EVN Sài Gòn',       @HCMC, 2534, N'Nguyễn Văn Phát', '02838290001', 'evn.sg@evn.vn',  '2024-01-01'),
    ('EVN-HN', N'EVN Hà Nội',        @HAN,  2486, N'Trần Minh Hoàng', '02438290002', 'evn.hn@evn.vn',  '2024-01-01'),
    ('EVN-DN', N'EVN Đà Nẵng',       @DN,   2432, N'Lê Văn Thanh',    '02363829003', 'evn.dn@evn.vn',  '2024-02-01'),
    ('EVN-BD', N'EVN Bình Dương',    @BD,   2590, N'Phạm Thị Hoa',    '02743829004', 'evn.bd@evn.vn',  '2024-02-15'),
    ('EVN-VT', N'EVN Vũng Tàu',      @VT,   2575, N'Hoàng Văn Bảo',   '02543829005', 'evn.vt@evn.vn',  '2024-02-15');

-- ============================================================
-- Charging Stations
-- ============================================================
DECLARE @SUP_SG INT = (SELECT SupplierID FROM Infrastructure.ElectricitySupplier WHERE SupplierCode = 'EVN-SG');
DECLARE @SUP_HN INT = (SELECT SupplierID FROM Infrastructure.ElectricitySupplier WHERE SupplierCode = 'EVN-HN');
DECLARE @SUP_DN INT = (SELECT SupplierID FROM Infrastructure.ElectricitySupplier WHERE SupplierCode = 'EVN-DN');
DECLARE @SUP_BD INT = (SELECT SupplierID FROM Infrastructure.ElectricitySupplier WHERE SupplierCode = 'EVN-BD');
DECLARE @SUP_VT INT = (SELECT SupplierID FROM Infrastructure.ElectricitySupplier WHERE SupplierCode = 'EVN-VT');
DECLARE @F1 INT = (SELECT FranchiseID FROM Infrastructure.Franchise WHERE FranchiseCode = 'VINFAST01');
DECLARE @F2 INT = (SELECT FranchiseID FROM Infrastructure.Franchise WHERE FranchiseCode = 'VINFAST02');
DECLARE @F3 INT = (SELECT FranchiseID FROM Infrastructure.Franchise WHERE FranchiseCode = 'EVN_01');
DECLARE @F4 INT = (SELECT FranchiseID FROM Infrastructure.Franchise WHERE FranchiseCode = 'GREEN_BD');
DECLARE @F5 INT = (SELECT FranchiseID FROM Infrastructure.Franchise WHERE FranchiseCode = 'VINFAST03');
DECLARE @A6 INT = (SELECT AddressID FROM Infrastructure.Address WHERE StreetAddress = N'456 Lê Lợi');
DECLARE @A7 INT = (SELECT AddressID FROM Infrastructure.Address WHERE StreetAddress = N'789 Nguyễn Văn Cừ');
DECLARE @A8 INT = (SELECT AddressID FROM Infrastructure.Address WHERE StreetAddress = N'12 Lý Thường Kiệt');
DECLARE @A9 INT = (SELECT AddressID FROM Infrastructure.Address WHERE StreetAddress = N'34 Lê Duẩn');
DECLARE @A10 INT = (SELECT AddressID FROM Infrastructure.Address WHERE StreetAddress = N'100 Nguyễn Văn Linh');

INSERT INTO Infrastructure.ChargingStation (StationCode, StationName, FranchiseID, AddressID, SupplierID, ModelName, Manufacturer, MaxPowerKW, ConnectorTypes, Latitude, Longitude, StationStatus)
VALUES
    ('VFSG-01', N'Trạm Sạc VinFast Bến Nghé',    @F1, @A1, @SUP_SG, N'VF-Charge 150', 'VinFast', 150.0, N'CCS2,CHAdeMO', 10.7765, 106.7012, 'Active'),
    ('VFSG-02', N'Trạm Sạc VinFast Bến Thành',   @F1, @A6, @SUP_SG, N'VF-Charge 60',  'VinFast', 60.0,  N'CCS2', 10.7711, 106.6984, 'Active'),
    ('VFHN-01', N'Trạm Sạc VinFast Hoàn Kiếm',   @F2, @A2, @SUP_HN, N'VF-Charge 150', 'VinFast', 150.0, N'CCS2,CHAdeMO', 21.0278, 105.8522, 'Active'),
    ('VFHN-02', N'Trạm Sạc VinFast Phan Chu Trinh', @F2, @A8, @SUP_HN, N'VF-Charge 60', 'VinFast', 60.0, N'CCS2', 21.0245, 105.8528, 'Active'),
    ('EVN-DN1', N'Trạm Sạc EVN Hải Châu',        @F3, @A3, @SUP_DN, N'ABB Terra 54',  'ABB', 50.0,  N'CCS2,Type2', 16.0544, 108.2022, 'Active'),
    ('EVN-DN2', N'Trạm Sạc EVN Thạch Thang',     @F3, @A9, @SUP_DN, N'ABB Terra 54',  'ABB', 50.0,  N'CCS2,Type2', 16.0612, 108.2211, 'Active'),
    ('GRBD-01', N'Trạm Sạc Green Energy',         @F4, @A4, @SUP_BD, N'Delta DC Wallbox', 'Delta', 30.0, N'CCS2', 10.9804, 106.6518, 'Active'),
    ('VFVT-01', N'Trạm Sạc VinFast Vũng Tàu',    @F5, @A5, @SUP_VT, N'VF-Charge 60',  'VinFast', 60.0,  N'CCS2', 10.3456, 107.0842, 'Active'),
    ('VFSG-03', N'Trạm Sạc VinFast Nguyễn Văn Cừ', @F1, @A7, @SUP_SG, N'VF-Charge 60', 'VinFast', 60.0, N'CCS2', 10.7642, 106.6865, 'Active'),
    ('VFSG-04', N'Trạm Sạc VinFast Nguyễn Văn Linh', @F1, @A10, @SUP_SG, N'VF-Charge 150', 'VinFast', 150.0, N'CCS2,CHAdeMO', 10.7312, 106.7222, 'Active');

-- ============================================================
-- Charging Points
-- ============================================================
DECLARE @S1 INT = (SELECT StationID FROM Infrastructure.ChargingStation WHERE StationCode = 'VFSG-01');
DECLARE @S2 INT = (SELECT StationID FROM Infrastructure.ChargingStation WHERE StationCode = 'VFSG-02');
DECLARE @S3 INT = (SELECT StationID FROM Infrastructure.ChargingStation WHERE StationCode = 'VFHN-01');
DECLARE @S4 INT = (SELECT StationID FROM Infrastructure.ChargingStation WHERE StationCode = 'VFHN-02');
DECLARE @S5 INT = (SELECT StationID FROM Infrastructure.ChargingStation WHERE StationCode = 'EVN-DN1');
DECLARE @S6 INT = (SELECT StationID FROM Infrastructure.ChargingStation WHERE StationCode = 'EVN-DN2');
DECLARE @S7 INT = (SELECT StationID FROM Infrastructure.ChargingStation WHERE StationCode = 'GRBD-01');
DECLARE @S8 INT = (SELECT StationID FROM Infrastructure.ChargingStation WHERE StationCode = 'VFVT-01');
DECLARE @S9 INT = (SELECT StationID FROM Infrastructure.ChargingStation WHERE StationCode = 'VFSG-03');
DECLARE @S10 INT = (SELECT StationID FROM Infrastructure.ChargingStation WHERE StationCode = 'VFSG-04');

INSERT INTO Infrastructure.ChargingPoint (PointCode, StationID, ConnectorType, PowerKW, SerialNumber, PointStatus)
VALUES
    ('VFSG-01-A', @S1, 'CCS2',    150.0, 'VF-CCS-001', 'Available'),
    ('VFSG-01-B', @S1, 'CHAdeMO', 100.0, 'VF-CHD-001', 'Available'),
    ('VFSG-02-A', @S2, 'CCS2',     60.0, 'VF-CCS-002', 'Available'),
    ('VFSG-02-B', @S2, 'CCS2',     60.0, 'VF-CCS-003', 'Available'),
    ('VFHN-01-A', @S3, 'CCS2',    150.0, 'VF-CCS-004', 'Available'),
    ('VFHN-01-B', @S3, 'CHAdeMO', 100.0, 'VF-CHD-002', 'Available'),
    ('VFHN-02-A', @S4, 'CCS2',     60.0, 'VF-CCS-005', 'Available'),
    ('EVN-DN1-A', @S5, 'CCS2',     50.0, 'ABB-CCS-001', 'Available'),
    ('EVN-DN1-B', @S5, 'Type2',    43.0, 'ABB-T2-001',  'Available'),
    ('EVN-DN2-A', @S6, 'CCS2',     50.0, 'ABB-CCS-002', 'Available'),
    ('GRBD-01-A', @S7, 'CCS2',     30.0, 'DELTA-001',   'Available'),
    ('GRBD-01-B', @S7, 'CCS2',     30.0, 'DELTA-002',   'Available'),
    ('VFVT-01-A', @S8, 'CCS2',     60.0, 'VF-CCS-006',  'Available'),
    ('VFSG-03-A', @S9, 'CCS2',     60.0, 'VF-CCS-007',  'Available'),
    ('VFSG-04-A', @S10, 'CCS2',   150.0, 'VF-CCS-008',  'Available'),
    ('VFSG-04-B', @S10, 'CHAdeMO',100.0, 'VF-CHD-003',  'Available');

-- ============================================================
-- Users (Admin, Managers, Customers)
-- ============================================================
INSERT INTO Users.[User] (Username, Email, Phone, PasswordHash, FullName, Role, FranchiseID, AccountStatus)
VALUES
    ('admin',     'admin@evsystem.vn',     '0909999001', '$2a$12$YtGnQYRWgrEzo7thrTerpeX5HOcaD9oClhqjEkOqvaSBuXLv3P9Au', N'Admin Hệ Thống',  'Admin',    NULL, 'Active'),
    ('manager_sg', 'manager.sg@vinfast.vn','0909999002', '$2a$12$YtGnQYRWgrEzo7thrTerpeX5HOcaD9oClhqjEkOqvaSBuXLv3P9Au', N'Nguyễn Quản Lý SG', 'Manager', @F1, 'Active'),
    ('manager_hn', 'manager.hn@vinfast.vn','0909999003', '$2a$12$YtGnQYRWgrEzo7thrTerpeX5HOcaD9oClhqjEkOqvaSBuXLv3P9Au', N'Trần Quản Lý HN',  'Manager', @F2, 'Active'),
    ('manager_dn', 'manager.dn@evn.vn',   '0909999004', '$2a$12$YtGnQYRWgrEzo7thrTerpeX5HOcaD9oClhqjEkOqvaSBuXLv3P9Au', N'Lê Quản Lý ĐN',    'Manager', @F3, 'Active'),
    ('customer01', 'cust01@gmail.com',     '0909999005', '$2a$12$YtGnQYRWgrEzo7thrTerpeX5HOcaD9oClhqjEkOqvaSBuXLv3P9Au', N'Phạm Văn Khách',   'Customer', NULL, 'Active'),
    ('customer02', 'cust02@gmail.com',     '0909999006', '$2a$12$YtGnQYRWgrEzo7thrTerpeX5HOcaD9oClhqjEkOqvaSBuXLv3P9Au', N'Lê Thị Khách',     'Customer', NULL, 'Active'),
    ('customer03', 'cust03@gmail.com',     '0909999007', '$2a$12$YtGnQYRWgrEzo7thrTerpeX5HOcaD9oClhqjEkOqvaSBuXLv3P9Au', N'Hoàng Minh Khách', 'Customer', NULL, 'Active');

PRINT N'Default password for all seed users: 123456';

-- ============================================================
-- Vehicles
-- ============================================================
DECLARE @C1 INT = (SELECT UserID FROM Users.[User] WHERE Username = 'customer01');
DECLARE @C2 INT = (SELECT UserID FROM Users.[User] WHERE Username = 'customer02');
DECLARE @C3 INT = (SELECT UserID FROM Users.[User] WHERE Username = 'customer03');

INSERT INTO Users.Vehicle (UserID, PlateNumber, Brand, Model, ModelYear, BatteryCapacityKWh, ConnectorType)
VALUES
    (@C1, N'51A-12345', 'VinFast', 'VF8',   2024, 85.0, 'CCS2'),
    (@C1, N'51A-67890', 'VinFast', 'VF5',   2023, 37.2, 'CCS2'),
    (@C2, N'30A-12345', 'VinFast', 'VF9',   2024, 123.0,'CCS2'),
    (@C3, N'43A-12345', 'Tesla',   'Model 3', 2023, 60.0, 'CCS2');

-- ============================================================
-- Pricing Policies
-- ============================================================
INSERT INTO Operations.PricingPolicy (PolicyCode, PolicyName, BasePricePerKWh, CurrencyCode, PeakMultiplier, PeakStartHour, PeakEndHour, IsWeekendPeak, AppliedFrom)
VALUES
    ('STANDARD', N'Giá tiêu chuẩn',       3500, 'VND', 1.50, '17:00', '19:00', 0, '2024-01-01'),
    ('OFFPEAK',  N'Giá thấp điểm',        2800, 'VND', 1.00, NULL,    NULL,   0, '2024-01-01'),
    ('VIP_MEM',  N'Giá hội viên VIP',     2500, 'VND', 1.30, '17:00', '19:00', 0, '2024-01-01'),
    ('HOLIDAY',  N'Giá ngày lễ',          4000, 'VND', 1.00, NULL,    NULL,   1, '2024-01-01'),
    ('PROMO_Q1', N'Khuyến mãi Q1 2024',   3000, 'VND', 1.40, '17:00', '19:00', 0, '2024-01-01');

-- ============================================================
-- Wallets
-- ============================================================
INSERT INTO Payments.Wallet (UserID, WalletCode, Balance)
    SELECT UserID, 'WAL-' + Username, 500000 FROM Users.[User] WHERE Role IN ('Customer', 'Admin');

-- ============================================================
-- Bookings (NEW)
-- ============================================================
DECLARE @P1 INT = (SELECT PointID FROM Infrastructure.ChargingPoint WHERE PointCode = 'VFSG-01-A');
DECLARE @P5 INT = (SELECT PointID FROM Infrastructure.ChargingPoint WHERE PointCode = 'VFHN-01-A');
DECLARE @P11 INT = (SELECT PointID FROM Infrastructure.ChargingPoint WHERE PointCode = 'GRBD-01-A');
DECLARE @V1 INT = (SELECT VehicleID FROM Users.Vehicle WHERE PlateNumber = N'51A-12345');
DECLARE @V3 INT = (SELECT VehicleID FROM Users.Vehicle WHERE PlateNumber = N'30A-12345');
DECLARE @V4 INT = (SELECT VehicleID FROM Users.Vehicle WHERE PlateNumber = N'43A-12345');

INSERT INTO Operations.Booking (BookingCode, UserID, PointID, StationID, VehicleID, BookedFrom, BookedTo, Status)
VALUES
    ('BOK-FUTURE-01', @C1, @P1, @S1, @V1,
        DATEADD(DAY, 1, DATEADD(HOUR, 10, CAST(CAST(SYSDATETIME() AS DATE) AS DATETIME2))),
        DATEADD(DAY, 1, DATEADD(HOUR, 12, CAST(CAST(SYSDATETIME() AS DATE) AS DATETIME2))),
        N'Confirmed'),
    ('BOK-PAST-01', @C2, @P5, @S3, @V3,
        DATEADD(DAY, -2, DATEADD(HOUR, 14, CAST(CAST(SYSDATETIME() AS DATE) AS DATETIME2))),
        DATEADD(DAY, -2, DATEADD(HOUR, 15, CAST(CAST(SYSDATETIME() AS DATE) AS DATETIME2))),
        N'Completed'),
    ('BOK-CANCEL-01', @C3, @P11, @S7, @V4,
        DATEADD(DAY, -7, DATEADD(HOUR, 8, CAST(CAST(SYSDATETIME() AS DATE) AS DATETIME2))),
        DATEADD(DAY, -7, DATEADD(HOUR, 9, CAST(CAST(SYSDATETIME() AS DATE) AS DATETIME2))),
        N'Cancelled');

DECLARE @BOK1 INT = (SELECT BookingID FROM Operations.Booking WHERE BookingCode = 'BOK-FUTURE-01');
DECLARE @BOK2 INT = (SELECT BookingID FROM Operations.Booking WHERE BookingCode = 'BOK-PAST-01');

-- ============================================================
-- Sample Charging Sessions & Transactions
-- ============================================================
DECLARE @POL1 INT = (SELECT PolicyID FROM Operations.PricingPolicy WHERE PolicyCode = 'STANDARD');

INSERT INTO Operations.ChargingSession (SessionCode, UserID, VehicleID, PointID, StationID, PolicyID, BookingID,
    StartTime, EndTime, MeterStart, MeterEnd, TotalKWh, ChargingDurationMinutes, CostTotal, StopReason, SessionStatus)
VALUES
    ('SES-20240101-A1', @C1, @V1, @P1, @S1, @POL1, @BOK2,
        DATEADD(DAY, -2, DATEADD(HOUR, 14, CAST(CAST(SYSDATETIME() AS DATE) AS DATETIME2))),
        DATEADD(DAY, -2, DATEADD(HOUR, 15, CAST(CAST(SYSDATETIME() AS DATE) AS DATETIME2))),
        1000, 1050, 50.00, 60, 175000, 'Completed', 'Completed'),
    ('SES-20240101-A2', @C2, @V3, @P5, @S3, @POL1, NULL,
        DATEADD(DAY, -2, DATEADD(HOUR, 18, CAST(CAST(SYSDATETIME() AS DATE) AS DATETIME2))),
        DATEADD(DAY, -2, DATEADD(HOUR, 19, CAST(CAST(SYSDATETIME() AS DATE) AS DATETIME2))),
        2000, 2060, 60.00, 60, 210000, 'Completed', 'Completed'),
    ('SES-20240101-A3', @C1, @V1, @P11, @S7, @POL1, NULL,
        DATEADD(DAY, -3, DATEADD(HOUR, 10, CAST(CAST(SYSDATETIME() AS DATE) AS DATETIME2))),
        DATEADD(DAY, -3, DATEADD(HOUR, 11, CAST(CAST(SYSDATETIME() AS DATE) AS DATETIME2))),
        500, 530, 30.00, 60, 105000, 'Completed', 'Completed');

DECLARE @SES1 BIGINT = (SELECT SessionID FROM Operations.ChargingSession WHERE SessionCode = 'SES-20240101-A1');
DECLARE @SES2 BIGINT = (SELECT SessionID FROM Operations.ChargingSession WHERE SessionCode = 'SES-20240101-A2');
DECLARE @SES3 BIGINT = (SELECT SessionID FROM Operations.ChargingSession WHERE SessionCode = 'SES-20240101-A3');

INSERT INTO Payments.[Transaction] (TransactionCode, UserID, SessionID, TransactionType, Direction, Amount, TransactionStatus, PaymentMethod, TransactedAt)
VALUES
    ('TXN-SES1', @C1, @SES1, 'ChargingPayment', 'D', 175000, 'Completed', 'Wallet', DATEADD(DAY, -2, SYSDATETIME())),
    ('TXN-SES2', @C2, @SES2, 'ChargingPayment', 'D', 210000, 'Completed', 'Wallet', DATEADD(DAY, -2, SYSDATETIME())),
    ('TXN-SES3', @C1, @SES3, 'ChargingPayment', 'D', 105000, 'Completed', 'Wallet', DATEADD(DAY, -3, SYSDATETIME()));

-- ============================================================
-- ErrorLogs (NEW)
-- ============================================================
DECLARE @P9 INT = (SELECT PointID FROM Infrastructure.ChargingPoint WHERE PointCode = 'EVN-DN1-B');
DECLARE @P15 INT = (SELECT PointID FROM Infrastructure.ChargingPoint WHERE PointCode = 'VFSG-04-A');

INSERT INTO Infrastructure.ErrorLog (PointID, StationID, ErrorCode, Severity, Description, OccurredAt)
VALUES
    (@P9, @S5, 'E001', 'High', N'Mất kết nối module sạc tại điểm sạc EVN-DN1-B',
        DATEADD(HOUR, -12, SYSDATETIME())),
    (@P9, @S5, 'E002', 'Medium', N'Nhiệt độ điểm sạc cao bất thường (>60°C)',
        DATEADD(HOUR, -10, SYSDATETIME())),
    (@P15, @S10, 'E003', 'High', N'Lỗi cảm biến dòng điện tại điểm sạc VFSG-04-A',
        DATEADD(HOUR, -8, SYSDATETIME())),
    (NULL, @S6, 'E004', 'Low', N'Cập nhật firmware không thành công tại trạm EVN-DN2',
        DATEADD(HOUR, -24, SYSDATETIME()));

-- ============================================================
-- MaintenanceSchedules (NEW)
-- ============================================================
DECLARE @ADMIN INT = (SELECT UserID FROM Users.[User] WHERE Username = 'admin');
DECLARE @P10 INT = (SELECT PointID FROM Infrastructure.ChargingPoint WHERE PointCode = 'EVN-DN2-A');
DECLARE @P6 INT = (SELECT PointID FROM Infrastructure.ChargingPoint WHERE PointCode = 'VFHN-01-B');
DECLARE @P14 INT = (SELECT PointID FROM Infrastructure.ChargingPoint WHERE PointCode = 'VFSG-03-A');

INSERT INTO Operations.MaintenanceSchedule (PointID, StationID, ScheduledBy, ScheduledFrom, ScheduledTo, MaintenanceType, Description, Status)
VALUES
    (@P10, @S6, @ADMIN,
        DATEADD(DAY, 1, DATEADD(HOUR, 8, CAST(CAST(SYSDATETIME() AS DATE) AS DATETIME2))),
        DATEADD(DAY, 1, DATEADD(HOUR, 10, CAST(CAST(SYSDATETIME() AS DATE) AS DATETIME2))),
        'Preventive', N'Bảo trì định kỳ điểm sạc EVN-DN2-A', N'Scheduled'),
    (@P6, @S3, (SELECT UserID FROM Users.[User] WHERE Username = 'manager_hn'),
        DATEADD(DAY, -2, DATEADD(HOUR, 9, CAST(CAST(SYSDATETIME() AS DATE) AS DATETIME2))),
        DATEADD(DAY, -2, DATEADD(HOUR, 11, CAST(CAST(SYSDATETIME() AS DATE) AS DATETIME2))),
        'Corrective', N'Sửa chữa điểm sạc CHAdeMO tại Hoàn Kiếm', N'Completed'),
    (@P14, @S9, (SELECT UserID FROM Users.[User] WHERE Username = 'manager_sg'),
        DATEADD(DAY, -7, DATEADD(HOUR, 8, CAST(CAST(SYSDATETIME() AS DATE) AS DATETIME2))),
        DATEADD(DAY, -7, DATEADD(HOUR, 10, CAST(CAST(SYSDATETIME() AS DATE) AS DATETIME2))),
        'Inspection', N'Kiểm tra định kỳ điểm sạc VFSG-03-A', N'Completed');

-- ============================================================
-- StationReviews (NEW)
-- ============================================================
INSERT INTO Operations.StationReview (UserID, StationID, Rating, Comment, CreatedAt)
VALUES
    (@C1, @S1, 5, N'Trạm sạc tiện lợi, tốc độ sạc nhanh, nhân viên hỗ trợ nhiệt tình.', DATEADD(DAY, -5, SYSDATETIME())),
    (@C1, @S3, 4, N'Vị trí thuận lợi, giá hợp lý. Hơi đông vào giờ cao điểm.', DATEADD(DAY, -3, SYSDATETIME())),
    (@C2, @S1, 5, N'Trạm sạc sạch sẽ, có wifi, rất hài lòng.', DATEADD(DAY, -4, SYSDATETIME())),
    (@C2, @S8, 3, N'Cần bảo trì thường xuyên hơn, có vài điểm sạc bị lỗi.', DATEADD(DAY, -2, SYSDATETIME()));

-- ============================================================
-- Notifications (NEW)
-- ============================================================
INSERT INTO Users.Notification (UserID, Title, Body, Type, ReferenceType, ReferenceID, IsRead, CreatedAt)
VALUES
    (@C1, N'Phiên sạc hoàn thành', N'Phiên sạc tại Trạm Sạc VinFast Bến Nghé đã hoàn thành. KWh: 50, Chi phí: 175,000 VND.',
        'ChargingComplete', 'Session', @SES1, 1, DATEADD(DAY, -2, SYSDATETIME())),
    (@C1, N'Khuyến mãi đặc biệt', N'Giảm 10% cho phiên sạc tiếp theo khi nạp ví từ 200,000 VND. Áp dụng đến hết tháng.',
        'Promotion', NULL, NULL, 0, DATEADD(DAY, -1, SYSDATETIME())),
    (@C2, N'Phiên sạc hoàn thành', N'Phiên sạc tại Trạm Sạc VinFast Hoàn Kiếm đã hoàn thành. KWh: 60, Chi phí: 210,000 VND.',
        'ChargingComplete', 'Session', @SES2, 1, DATEADD(DAY, -2, SYSDATETIME())),
    (@C2, N'Cảnh báo số dư ví', N'Số dư ví của bạn chỉ còn 290,000 VND. Vui lòng nạp thêm để tiếp tục sử dụng dịch vụ.',
        'WalletAlert', 'Wallet', (SELECT WalletID FROM Payments.Wallet WHERE UserID = @C2), 0, DATEADD(HOUR, -6, SYSDATETIME())),
    (@C3, N'Chào mừng đến với EVCharge Pro!', N'Chào mừng bạn đến với hệ thống trạm sạc xe điện thông minh. Hãy khám phá các trạm sạc gần bạn!',
        'System', NULL, NULL, 0, DATEADD(DAY, -10, SYSDATETIME())),
    (@C3, N'Bảo trì trạm sạc', N'Trạm sạc Green Energy sẽ bảo trì vào ngày mai từ 08:00-10:00. Vui lòng sắp xếp lịch sạc phù hợp.',
        'Maintenance', 'MaintenanceSchedule', (SELECT ScheduleID FROM Operations.MaintenanceSchedule WHERE PointID = @P10), 0, DATEADD(HOUR, -2, SYSDATETIME()));

PRINT N'Seed data inserted successfully.';
GO
