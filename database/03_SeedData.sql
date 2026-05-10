USE EV_Charging_System;
GO

-- ============================================================
-- Country & Region
-- ============================================================
INSERT INTO Infrastructure.Country (CountryCode, CountryName, CurrencyCode, PhonePrefix)
VALUES ('VN', N'Việt Nam', 'VND', '+84');
GO

DECLARE @VN INT = (SELECT CountryID FROM Infrastructure.Country WHERE CountryCode = 'VN');

INSERT INTO Infrastructure.Region (CountryID, RegionCode, RegionName, TimeZone)
VALUES
    (@VN, 'HCMC', N'TP. Hồ Chí Minh', 'Asia/Ho_Chi_Minh'),
    (@VN, 'HAN',  N'Hà Nội',          'Asia/Ho_Chi_Minh'),
    (@VN, 'DN',   N'Đà Nẵng',         'Asia/Ho_Chi_Minh'),
    (@VN, 'BD',   N'Bình Dương',      'Asia/Ho_Chi_Minh'),
    (@VN, 'VT',   N'Vũng Tàu',        'Asia/Ho_Chi_Minh');
GO

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
GO

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
GO

-- ============================================================
-- Charging Stations
-- ============================================================
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

INSERT INTO Infrastructure.ChargingStation (StationCode, StationName, FranchiseID, AddressID, ModelName, Manufacturer, MaxPowerKW, ConnectorTypes, Latitude, Longitude, StationStatus)
VALUES
    ('VFSG-01', N'Trạm Sạc VinFast Bến Nghé',    @F1, @A1, N'VF-Charge 150', 'VinFast', 150.0, N'CCS2,CHAdeMO', 10.7765, 106.7012, 'Active'),
    ('VFSG-02', N'Trạm Sạc VinFast Bến Thành',   @F1, @A6, N'VF-Charge 60',  'VinFast', 60.0,  N'CCS2', 10.7711, 106.6984, 'Active'),
    ('VFHN-01', N'Trạm Sạc VinFast Hoàn Kiếm',   @F2, @A2, N'VF-Charge 150', 'VinFast', 150.0, N'CCS2,CHAdeMO', 21.0278, 105.8522, 'Active'),
    ('VFHN-02', N'Trạm Sạc VinFast Phan Chu Trinh', @F2, @A8, N'VF-Charge 60', 'VinFast', 60.0, N'CCS2', 21.0245, 105.8528, 'Active'),
    ('EVN-DN1', N'Trạm Sạc EVN Hải Châu',        @F3, @A3, N'ABB Terra 54',  'ABB', 50.0,  N'CCS2,Type2', 16.0544, 108.2022, 'Active'),
    ('EVN-DN2', N'Trạm Sạc EVN Thạch Thang',     @F3, @A9, N'ABB Terra 54',  'ABB', 50.0,  N'CCS2,Type2', 16.0612, 108.2211, 'Active'),
    ('GRBD-01', N'Trạm Sạc Green Energy',         @F4, @A4, N'Delta DC Wallbox', 'Delta', 30.0, N'CCS2', 10.9804, 106.6518, 'Active'),
    ('VFVT-01', N'Trạm Sạc VinFast Vũng Tàu',    @F5, @A5, N'VF-Charge 60',  'VinFast', 60.0,  N'CCS2', 10.3456, 107.0842, 'Active'),
    ('VFSG-03', N'Trạm Sạc VinFast Nguyễn Văn Cừ', @F1, @A7, N'VF-Charge 60', 'VinFast', 60.0, N'CCS2', 10.7642, 106.6865, 'Active'),
    ('VFSG-04', N'Trạm Sạc VinFast Nguyễn Văn Linh', @F1, @A10, N'VF-Charge 150', 'VinFast', 150.0, N'CCS2,CHAdeMO', 10.7312, 106.7222, 'Active');
GO

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
GO

-- ============================================================
-- Users (Admin, Managers, Customers)
-- ============================================================
INSERT INTO Users.[User] (Username, Email, Phone, PasswordHash, FullName, Role, FranchiseID, AccountStatus)
VALUES
    -- Admin
    ('admin',     'admin@evsystem.vn',     '0909999001', '$2a$10$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36PQm4sEPhMNPfFhpYN76uO', N'Admin Hệ Thống',  'Admin',    NULL, 'Active'),
    -- Managers
    ('manager_sg', 'manager.sg@vinfast.vn','0909999002', '$2a$10$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36PQm4sEPhMNPfFhpYN76uO', N'Nguyễn Quản Lý SG', 'Manager', @F1, 'Active'),
    ('manager_hn', 'manager.hn@vinfast.vn','0909999003', '$2a$10$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36PQm4sEPhMNPfFhpYN76uO', N'Trần Quản Lý HN',  'Manager', @F2, 'Active'),
    ('manager_dn', 'manager.dn@evn.vn',   '0909999004', '$2a$10$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36PQm4sEPhMNPfFhpYN76uO', N'Lê Quản Lý ĐN',    'Manager', @F3, 'Active'),
    -- Customers
    ('customer01', 'cust01@gmail.com',     '0909999005', '$2a$10$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36PQm4sEPhMNPfFhpYN76uO', N'Phạm Văn Khách',   'Customer', NULL, 'Active'),
    ('customer02', 'cust02@gmail.com',     '0909999006', '$2a$10$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36PQm4sEPhMNPfFhpYN76uO', N'Lê Thị Khách',     'Customer', NULL, 'Active'),
    ('customer03', 'cust03@gmail.com',     '0909999007', '$2a$10$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36PQm4sEPhMNPfFhpYN76uO', N'Hoàng Minh Khách', 'Customer', NULL, 'Active');
GO

-- Note: Default password for all seed users is '123456'
-- Password hash above is bcrypt for '123456'
PRINT N'Default password for all seed users: 123456';
GO

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
GO

-- ============================================================
-- Wallets (Auto-create for customers)
-- ============================================================
INSERT INTO Payments.Wallet (UserID, WalletCode, Balance)
    SELECT UserID, 'WAL-' + Username, 500000 FROM Users.[User] WHERE Role IN ('Customer', 'Admin');
GO

-- ============================================================
-- Sample Charging Sessions & Transactions
-- ============================================================
DECLARE @P1 INT = (SELECT PointID FROM Infrastructure.ChargingPoint WHERE PointCode = 'VFSG-01-A');
DECLARE @P3 INT = (SELECT PointID FROM Infrastructure.ChargingPoint WHERE PointCode = 'VFHN-01-A');
DECLARE @P7 INT = (SELECT PointID FROM Infrastructure.ChargingPoint WHERE PointCode = 'VFVT-01-A');
DECLARE @POL1 INT = (SELECT PolicyID FROM Operations.PricingPolicy WHERE PolicyCode = 'STANDARD');
DECLARE @S1_ID INT = (SELECT StationID FROM Infrastructure.ChargingStation WHERE StationCode = 'VFSG-01');
DECLARE @S3_ID INT = (SELECT StationID FROM Infrastructure.ChargingStation WHERE StationCode = 'VFHN-01');
DECLARE @S8_ID INT = (SELECT StationID FROM Infrastructure.ChargingStation WHERE StationCode = 'VFVT-01');

INSERT INTO Operations.ChargingSession (SessionCode, UserID, VehicleID, PointID, StationID, PolicyID,
    StartTime, EndTime, MeterStart, MeterEnd, TotalKWh, ChargingDurationMinutes, CostTotal, StopReason, SessionStatus)
VALUES
    ('SES-20240101-A1', @C1, (SELECT VehicleID FROM Users.Vehicle WHERE PlateNumber = N'51A-12345'), @P1, @S1_ID, @POL1,
        '2024-01-15 08:00:00', '2024-01-15 09:30:00', 1000, 1050, 50.00, 90, 175000, 'Completed', 'Completed'),
    ('SES-20240101-A2', @C2, (SELECT VehicleID FROM Users.Vehicle WHERE PlateNumber = N'30A-12345'), @P3, @S3_ID, @POL1,
        '2024-01-15 18:00:00', '2024-01-15 19:00:00', 2000, 2060, 60.00, 60, 210000, 'Completed', 'Completed'),
    ('SES-20240101-A3', @C1, (SELECT VehicleID FROM Users.Vehicle WHERE PlateNumber = N'51A-67890'), @P7, @S8_ID, @POL1,
        '2024-01-16 10:00:00', '2024-01-16 11:00:00', 500, 530, 30.00, 60, 105000, 'Completed', 'Completed');
GO

-- Corresponding Transactions
DECLARE @SES1 BIGINT = (SELECT SessionID FROM Operations.ChargingSession WHERE SessionCode = 'SES-20240101-A1');
DECLARE @SES2 BIGINT = (SELECT SessionID FROM Operations.ChargingSession WHERE SessionCode = 'SES-20240101-A2');
DECLARE @SES3 BIGINT = (SELECT SessionID FROM Operations.ChargingSession WHERE SessionCode = 'SES-20240101-A3');

INSERT INTO Payments.[Transaction] (TransactionCode, UserID, SessionID, TransactionType, Direction, Amount, TransactionStatus, PaymentMethod, TransactedAt)
VALUES
    ('TXN-SES1', @C1, @SES1, 'ChargingPayment', 'D', 175000, 'Completed', 'Wallet', '2024-01-15 09:30:00'),
    ('TXN-SES2', @C2, @SES2, 'ChargingPayment', 'D', 210000, 'Completed', 'Wallet', '2024-01-15 19:00:00'),
    ('TXN-SES3', @C1, @SES3, 'ChargingPayment', 'D', 105000, 'Completed', 'Wallet', '2024-01-16 11:00:00');
GO

PRINT N'Seed data inserted successfully.';
GO
