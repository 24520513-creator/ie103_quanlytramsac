USE EV_Charging_System;
GO

PRINT N'============================================================';
PRINT N' Phase 2-5: Clean UTF-8 Seed Data Generation';
PRINT N' All strings use N'' prefix for Unicode support';
PRINT N'============================================================';
GO

-- ============================================================
-- BCRYPT PASSWORD HASHES (salt rounds = 12)
-- Admin@123:  $2a$12$WfM9FV2FadwZ35K1PKGvRuqRae/ShGw1uq6h492ypppUNyyhP6Zq2
-- Manager@123: $2a$12$WfM9FV2FadwZ35K1PKGvRuvBBQK5EZDr0sKGXwrxya8KZdOEAkM0e
-- Customer@123: $2a$12$WfM9FV2FadwZ35K1PKGvRu7B9QXIsNLJsgDXaZGtcKnqq7NxBJLTm
-- ============================================================

DECLARE @AdminHash NVARCHAR(256) = N'$2a$12$WfM9FV2FadwZ35K1PKGvRuqRae/ShGw1uq6h492ypppUNyyhP6Zq2';
DECLARE @ManagerHash NVARCHAR(256) = N'$2a$12$WfM9FV2FadwZ35K1PKGvRuvBBQK5EZDr0sKGXwrxya8KZdOEAkM0e';
DECLARE @CustomerHash NVARCHAR(256) = N'$2a$12$WfM9FV2FadwZ35K1PKGvRu7B9QXIsNLJsgDXaZGtcKnqq7NxBJLTm';

-- ============================================================
-- SECTION 1: Infrastructure — Country & Region
-- ============================================================
INSERT INTO Infrastructure.Country (CountryCode, CountryName, CurrencyCode, PhonePrefix)
VALUES (N'VN', N'Việt Nam', N'VND', N'+84');

DECLARE @VN INT = (SELECT CountryID FROM Infrastructure.Country WHERE CountryCode = N'VN');

INSERT INTO Infrastructure.Region (CountryID, RegionCode, RegionName, TimeZone)
VALUES
    (@VN, N'HCMC', N'TP. Hồ Chí Minh', N'Asia/Ho_Chi_Minh'),
    (@VN, N'HAN',  N'Hà Nội',          N'Asia/Ho_Chi_Minh'),
    (@VN, N'DN',   N'Đà Nẵng',         N'Asia/Ho_Chi_Minh'),
    (@VN, N'BD',   N'Bình Dương',      N'Asia/Ho_Chi_Minh'),
    (@VN, N'VT',   N'Vũng Tàu',        N'Asia/Ho_Chi_Minh');

DECLARE @HCMC INT = (SELECT RegionID FROM Infrastructure.Region WHERE RegionCode = N'HCMC');
DECLARE @HAN   INT = (SELECT RegionID FROM Infrastructure.Region WHERE RegionCode = N'HAN');
DECLARE @DN    INT = (SELECT RegionID FROM Infrastructure.Region WHERE RegionCode = N'DN');
DECLARE @BD    INT = (SELECT RegionID FROM Infrastructure.Region WHERE RegionCode = N'BD');
DECLARE @VT    INT = (SELECT RegionID FROM Infrastructure.Region WHERE RegionCode = N'VT');

-- ============================================================
-- SECTION 2: Infrastructure — Addresses (15 locations)
-- ============================================================
INSERT INTO Infrastructure.Address (RegionID, StreetAddress, Ward, District, Latitude, Longitude)
VALUES
    (@HCMC, N'123 Nguyễn Huệ',       N'Bến Nghé',     N'Quận 1',    10.7765, 106.7012),
    (@HAN,  N'45 Tràng Tiền',        N'Tràng Tiền',   N'Hoàn Kiếm', 21.0278, 105.8522),
    (@DN,   N'78 Nguyễn Văn Linh',   N'Hải Châu 1',   N'Hải Châu',  16.0544, 108.2022),
    (@BD,   N'56 Đại lộ Bình Dương', N'Phú Mỹ',       N'Thủ Dầu Một', 10.9804, 106.6518),
    (@VT,   N'90 Quang Trung',       N'Phường 3',     N'TP. Vũng Tàu', 10.3456, 107.0842),
    (@HCMC, N'456 Lê Lợi',           N'Bến Thành',    N'Quận 1',    10.7711, 106.6984),
    (@HCMC, N'789 Nguyễn Văn Cừ',    N'Nguyễn Cư Trinh', N'Quận 1', 10.7642, 106.6865),
    (@HAN,  N'12 Lý Thường Kiệt',    N'Phan Chu Trinh', N'Hoàn Kiếm', 21.0245, 105.8528),
    (@DN,   N'34 Lê Duẩn',           N'Thạch Thang',  N'Hải Châu',  16.0612, 108.2211),
    (@HCMC, N'100 Nguyễn Văn Linh',  N'Tân Phong',    N'Quận 7',    10.7312, 106.7222),
    (@HCMC, N'200 Lê Văn Việt',      N'Tăng Nhơn Phú A', N'Quận 9',  10.8372, 106.7723),
    (@HAN,  N'67 Nguyễn Chí Thanh',  N'Láng Thượng', N'Đống Đa',   21.0132, 105.8089),
    (@HAN,  N'88 Xuân Thủy',         N'Dịch Vọng Hậu', N'Cầu Giấy', 21.0353, 105.7838),
    (@DN,   N'15 Nguyễn Hữu Thọ',    N'Khuê Trung',   N'Cẩm Lệ',    16.0328, 108.2119),
    (@HCMC, N'50 Bùi Viện',          N'Phạm Ngũ Lão', N'Quận 1',    10.7675, 106.6925);

DECLARE @A1  INT = (SELECT AddressID FROM Infrastructure.Address WHERE StreetAddress = N'123 Nguyễn Huệ');
DECLARE @A2  INT = (SELECT AddressID FROM Infrastructure.Address WHERE StreetAddress = N'45 Tràng Tiền');
DECLARE @A3  INT = (SELECT AddressID FROM Infrastructure.Address WHERE StreetAddress = N'78 Nguyễn Văn Linh');
DECLARE @A4  INT = (SELECT AddressID FROM Infrastructure.Address WHERE StreetAddress = N'56 Đại lộ Bình Dương');
DECLARE @A5  INT = (SELECT AddressID FROM Infrastructure.Address WHERE StreetAddress = N'90 Quang Trung');
DECLARE @A6  INT = (SELECT AddressID FROM Infrastructure.Address WHERE StreetAddress = N'456 Lê Lợi');
DECLARE @A7  INT = (SELECT AddressID FROM Infrastructure.Address WHERE StreetAddress = N'789 Nguyễn Văn Cừ');
DECLARE @A8  INT = (SELECT AddressID FROM Infrastructure.Address WHERE StreetAddress = N'12 Lý Thường Kiệt');
DECLARE @A9  INT = (SELECT AddressID FROM Infrastructure.Address WHERE StreetAddress = N'34 Lê Duẩn');
DECLARE @A10 INT = (SELECT AddressID FROM Infrastructure.Address WHERE StreetAddress = N'100 Nguyễn Văn Linh');
DECLARE @A11 INT = (SELECT AddressID FROM Infrastructure.Address WHERE StreetAddress = N'200 Lê Văn Việt');
DECLARE @A12 INT = (SELECT AddressID FROM Infrastructure.Address WHERE StreetAddress = N'67 Nguyễn Chí Thanh');
DECLARE @A13 INT = (SELECT AddressID FROM Infrastructure.Address WHERE StreetAddress = N'88 Xuân Thủy');
DECLARE @A14 INT = (SELECT AddressID FROM Infrastructure.Address WHERE StreetAddress = N'15 Nguyễn Hữu Thọ');
DECLARE @A15 INT = (SELECT AddressID FROM Infrastructure.Address WHERE StreetAddress = N'50 Bùi Viện');

-- ============================================================
-- SECTION 3: Infrastructure — Electricity Suppliers
-- ============================================================
INSERT INTO Infrastructure.ElectricitySupplier (SupplierCode, SupplierName, RegionID, UnitPricePerKWh, ContactPerson, ContactPhone, ContactEmail, ContractSignedDate)
VALUES
    (N'EVN_HCMC', N'Tổng Công ty Điện lực TP. Hồ Chí Minh', @HCMC, 2100.0000, N'Nguyễn Đức Phương', N'0908111001', N'phunguyen@evnhcmc.vn', '2024-01-01'),
    (N'EVN_HAN',  N'Tổng Công ty Điện lực Hà Nội',         @HAN,  2000.0000, N'Trần Minh Đức',     N'0908111002', N'ductran@evnhan.vn',  '2024-01-01'),
    (N'EVN_CT',   N'Tổng Công ty Điện lực Miền Trung',      @DN,   1900.0000, N'Lê Văn Thành',      N'0908111003', N'thanhle@evnct.vn',   '2024-01-01');

DECLARE @SUP_HCMC INT = (SELECT SupplierID FROM Infrastructure.ElectricitySupplier WHERE SupplierCode = N'EVN_HCMC');
DECLARE @SUP_HAN  INT = (SELECT SupplierID FROM Infrastructure.ElectricitySupplier WHERE SupplierCode = N'EVN_HAN');
DECLARE @SUP_CT   INT = (SELECT SupplierID FROM Infrastructure.ElectricitySupplier WHERE SupplierCode = N'EVN_CT');

-- ============================================================
-- SECTION 4: Infrastructure — Franchises
-- ============================================================
INSERT INTO Infrastructure.Franchise (FranchiseCode, FranchiseName, TaxCode, AddressID, ContactPerson, ContactPhone, ContactEmail, RevenueShareRate, ContractSignedDate)
VALUES
    (N'VINFAST01', N'VinFast Sài Gòn',        N'VFSG2024001', @A1,  N'Nguyễn Văn An',   N'0901001001', N'annv@vinfast.vn',  15.0, '2024-01-01'),
    (N'VINFAST02', N'VinFast Hà Nội',          N'VFHN2024001', @A2,  N'Trần Thị Bích',   N'0901001002', N'bicht@vinfast.vn', 15.0, '2024-01-15'),
    (N'EVN_01',    N'EVN Đà Nẵng',             N'EVNDN2024001', @A3, N'Lê Văn Cường',    N'0901001003', N'cuongl@evn.vn',    10.0, '2024-02-01'),
    (N'GREEN_BD',  N'Green Energy Bình Dương',  N'GEBD2024001', @A4, N'Phạm Thị Dung',   N'0901001004', N'dungpt@green.vn',  12.0, '2024-02-15'),
    (N'VINFAST03', N'VinFast Vũng Tàu',        N'VFVT2024001', @A5,  N'Hoàng Văn Hải',   N'0901001005', N'haitv@vinfast.vn', 15.0, '2024-03-01');

DECLARE @F1 INT = (SELECT FranchiseID FROM Infrastructure.Franchise WHERE FranchiseCode = N'VINFAST01');
DECLARE @F2 INT = (SELECT FranchiseID FROM Infrastructure.Franchise WHERE FranchiseCode = N'VINFAST02');
DECLARE @F3 INT = (SELECT FranchiseID FROM Infrastructure.Franchise WHERE FranchiseCode = N'EVN_01');
DECLARE @F4 INT = (SELECT FranchiseID FROM Infrastructure.Franchise WHERE FranchiseCode = N'GREEN_BD');
DECLARE @F5 INT = (SELECT FranchiseID FROM Infrastructure.Franchise WHERE FranchiseCode = N'VINFAST03');

-- ============================================================
-- SECTION 5: Infrastructure — Charging Stations (10 stations)
-- ============================================================
INSERT INTO Infrastructure.ChargingStation (StationCode, StationName, FranchiseID, AddressID, SupplierID, ModelName, Manufacturer, MaxPowerKW, ConnectorTypes, Latitude, Longitude, StationStatus)
VALUES
    (N'VFSG-01', N'Trạm Sạc VinFast Bến Nghé',     @F1, @A1,  @SUP_HCMC, N'VF-Charge 150', N'VinFast', 150.0, N'CCS2, CHAdeMO', 10.7765, 106.7012, N'Active'),
    (N'VFSG-02', N'Trạm Sạc VinFast Bến Thành',    @F1, @A6,  @SUP_HCMC, N'VF-Charge 60',  N'VinFast',  60.0, N'CCS2',          10.7711, 106.6984, N'Active'),
    (N'VFSG-03', N'Trạm Sạc VinFast Nguyễn Văn Cừ',@F1, @A7,  @SUP_HCMC, N'VF-Charge 60',  N'VinFast',  60.0, N'CCS2',          10.7642, 106.6865, N'Active'),
    (N'VFHN-01', N'Trạm Sạc VinFast Hoàn Kiếm',    @F2, @A2,  @SUP_HAN,  N'VF-Charge 150', N'VinFast', 150.0, N'CCS2, CHAdeMO', 21.0278, 105.8522, N'Active'),
    (N'VFHN-02', N'Trạm Sạc VinFast Phan Chu Trinh',@F2, @A8, @SUP_HAN,  N'VF-Charge 60',  N'VinFast',  60.0, N'CCS2',          21.0245, 105.8528, N'Active'),
    (N'EVN-DN1', N'Trạm Sạc EVN Hải Châu',          @F3, @A3,  @SUP_CT,   N'ABB Terra 54',  N'ABB',      50.0, N'CCS2, Type2',   16.0544, 108.2022, N'Active'),
    (N'EVN-DN2', N'Trạm Sạc EVN Thạch Thang',       @F3, @A9,  @SUP_CT,   N'ABB Terra 54',  N'ABB',      50.0, N'CCS2, Type2',   16.0612, 108.2211, N'Active'),
    (N'GRBD-01', N'Trạm Sạc Green Energy Bình Dương',@F4, @A4, @SUP_HCMC, N'Delta DC 30',   N'Delta',    30.0, N'CCS2',          10.9804, 106.6518, N'Active'),
    (N'VFVT-01', N'Trạm Sạc VinFast Vũng Tàu',     @F5, @A5,  @SUP_HCMC, N'VF-Charge 60',  N'VinFast',  60.0, N'CCS2',          10.3456, 107.0842, N'Active'),
    (N'VFSG-04', N'Trạm Sạc VinFast Nguyễn Văn Linh',@F1, @A10, @SUP_HCMC,N'VF-Charge 150', N'VinFast', 150.0, N'CCS2, CHAdeMO', 10.7312, 106.7222, N'Active');

DECLARE @S1  INT = (SELECT StationID FROM Infrastructure.ChargingStation WHERE StationCode = N'VFSG-01');
DECLARE @S2  INT = (SELECT StationID FROM Infrastructure.ChargingStation WHERE StationCode = N'VFSG-02');
DECLARE @S3  INT = (SELECT StationID FROM Infrastructure.ChargingStation WHERE StationCode = N'VFSG-03');
DECLARE @S4  INT = (SELECT StationID FROM Infrastructure.ChargingStation WHERE StationCode = N'VFHN-01');
DECLARE @S5  INT = (SELECT StationID FROM Infrastructure.ChargingStation WHERE StationCode = N'VFHN-02');
DECLARE @S6  INT = (SELECT StationID FROM Infrastructure.ChargingStation WHERE StationCode = N'EVN-DN1');
DECLARE @S7  INT = (SELECT StationID FROM Infrastructure.ChargingStation WHERE StationCode = N'EVN-DN2');
DECLARE @S8  INT = (SELECT StationID FROM Infrastructure.ChargingStation WHERE StationCode = N'GRBD-01');
DECLARE @S9  INT = (SELECT StationID FROM Infrastructure.ChargingStation WHERE StationCode = N'VFVT-01');
DECLARE @S10 INT = (SELECT StationID FROM Infrastructure.ChargingStation WHERE StationCode = N'VFSG-04');

-- ============================================================
-- SECTION 6: Infrastructure — Charging Points (20 points)
-- ============================================================
INSERT INTO Infrastructure.ChargingPoint (PointCode, StationID, ConnectorType, PowerKW, SerialNumber, PointStatus)
VALUES
    (N'VFSG-01-A', @S1, N'CCS2',    150.0, N'VF-CCS-001', N'Available'),
    (N'VFSG-01-B', @S1, N'CHAdeMO', 100.0, N'VF-CHD-001', N'Available'),
    (N'VFSG-02-A', @S2, N'CCS2',     60.0, N'VF-CCS-002', N'Available'),
    (N'VFSG-02-B', @S2, N'CCS2',     60.0, N'VF-CCS-003', N'Available'),
    (N'VFSG-03-A', @S3, N'CCS2',     60.0, N'VF-CCS-004', N'Available'),
    (N'VFSG-04-A', @S10,N'CCS2',    150.0, N'VF-CCS-005', N'Available'),
    (N'VFSG-04-B', @S10,N'CHAdeMO', 100.0, N'VF-CHD-002', N'Available'),
    (N'VFHN-01-A', @S4, N'CCS2',    150.0, N'VF-CCS-006', N'Available'),
    (N'VFHN-01-B', @S4, N'CHAdeMO', 100.0, N'VF-CHD-003', N'Available'),
    (N'VFHN-02-A', @S5, N'CCS2',     60.0, N'VF-CCS-007', N'Available'),
    (N'VFHN-02-B', @S5, N'CCS2',     60.0, N'VF-CCS-008', N'Available'),
    (N'EVN-DN1-A', @S6, N'CCS2',     50.0, N'ABB-CCS-001', N'Available'),
    (N'EVN-DN1-B', @S6, N'Type2',    43.0, N'ABB-T2-001',  N'Available'),
    (N'EVN-DN2-A', @S7, N'CCS2',     50.0, N'ABB-CCS-002', N'Available'),
    (N'EVN-DN2-B', @S7, N'Type2',    43.0, N'ABB-T2-002',  N'Available'),
    (N'GRBD-01-A', @S8, N'CCS2',     30.0, N'DELTA-001',   N'Available'),
    (N'GRBD-01-B', @S8, N'CCS2',     30.0, N'DELTA-002',   N'Available'),
    (N'VFVT-01-A', @S9, N'CCS2',     60.0, N'VF-CCS-009',  N'Available'),
    (N'VFVT-01-B', @S9, N'CCS2',     60.0, N'VF-CCS-010',  N'Available'),
    (N'VFSG-02-C', @S2, N'Type2',    22.0, N'VF-T2-001',   N'Available');

DECLARE @P1  INT = (SELECT PointID FROM Infrastructure.ChargingPoint WHERE PointCode = N'VFSG-01-A');
DECLARE @P2  INT = (SELECT PointID FROM Infrastructure.ChargingPoint WHERE PointCode = N'VFSG-01-B');
DECLARE @P3  INT = (SELECT PointID FROM Infrastructure.ChargingPoint WHERE PointCode = N'VFSG-02-A');
DECLARE @P4  INT = (SELECT PointID FROM Infrastructure.ChargingPoint WHERE PointCode = N'VFSG-02-B');
DECLARE @P5  INT = (SELECT PointID FROM Infrastructure.ChargingPoint WHERE PointCode = N'VFSG-03-A');
DECLARE @P6  INT = (SELECT PointID FROM Infrastructure.ChargingPoint WHERE PointCode = N'VFSG-04-A');
DECLARE @P7  INT = (SELECT PointID FROM Infrastructure.ChargingPoint WHERE PointCode = N'VFSG-04-B');
DECLARE @P8  INT = (SELECT PointID FROM Infrastructure.ChargingPoint WHERE PointCode = N'VFHN-01-A');
DECLARE @P9  INT = (SELECT PointID FROM Infrastructure.ChargingPoint WHERE PointCode = N'VFHN-01-B');
DECLARE @P10 INT = (SELECT PointID FROM Infrastructure.ChargingPoint WHERE PointCode = N'VFHN-02-A');
DECLARE @P11 INT = (SELECT PointID FROM Infrastructure.ChargingPoint WHERE PointCode = N'VFHN-02-B');
DECLARE @P12 INT = (SELECT PointID FROM Infrastructure.ChargingPoint WHERE PointCode = N'EVN-DN1-A');
DECLARE @P13 INT = (SELECT PointID FROM Infrastructure.ChargingPoint WHERE PointCode = N'EVN-DN1-B');
DECLARE @P14 INT = (SELECT PointID FROM Infrastructure.ChargingPoint WHERE PointCode = N'EVN-DN2-A');
DECLARE @P15 INT = (SELECT PointID FROM Infrastructure.ChargingPoint WHERE PointCode = N'EVN-DN2-B');
DECLARE @P16 INT = (SELECT PointID FROM Infrastructure.ChargingPoint WHERE PointCode = N'GRBD-01-A');
DECLARE @P17 INT = (SELECT PointID FROM Infrastructure.ChargingPoint WHERE PointCode = N'GRBD-01-B');
DECLARE @P18 INT = (SELECT PointID FROM Infrastructure.ChargingPoint WHERE PointCode = N'VFVT-01-A');
DECLARE @P19 INT = (SELECT PointID FROM Infrastructure.ChargingPoint WHERE PointCode = N'VFVT-01-B');
DECLARE @P20 INT = (SELECT PointID FROM Infrastructure.ChargingPoint WHERE PointCode = N'VFSG-02-C');

PRINT N'Infrastructure seeded: 1 country, 5 regions, 15 addresses, 5 franchises, 3 suppliers, 10 stations, 20 points.';
GO

-- ============================================================
-- SECTION 7: Users — Admin & Managers
-- ============================================================
DECLARE @AdminHash NVARCHAR(256) = N'$2a$12$WfM9FV2FadwZ35K1PKGvRuqRae/ShGw1uq6h492ypppUNyyhP6Zq2';
DECLARE @ManagerHash NVARCHAR(256) = N'$2a$12$WfM9FV2FadwZ35K1PKGvRuvBBQK5EZDr0sKGXwrxya8KZdOEAkM0e';
DECLARE @CustomerHash NVARCHAR(256) = N'$2a$12$WfM9FV2FadwZ35K1PKGvRu7B9QXIsNLJsgDXaZGtcKnqq7NxBJLTm';
DECLARE @F1 INT = (SELECT FranchiseID FROM Infrastructure.Franchise WHERE FranchiseCode = N'VINFAST01');
DECLARE @F2 INT = (SELECT FranchiseID FROM Infrastructure.Franchise WHERE FranchiseCode = N'VINFAST02');
DECLARE @F3 INT = (SELECT FranchiseID FROM Infrastructure.Franchise WHERE FranchiseCode = N'EVN_01');

INSERT INTO Users.[User] (Username, Email, Phone, PasswordHash, FullName, Role, FranchiseID, AccountStatus)
VALUES
    (N'admin01', N'admin01@gmail.com', N'0909999000', @AdminHash, N'Admin Hệ Thống', N'Admin', NULL, N'Active');

INSERT INTO Users.[User] (Username, Email, Phone, PasswordHash, FullName, Role, FranchiseID, AccountStatus)
VALUES
    (N'manager01', N'manager01@gmail.com', N'0909999001', @ManagerHash, N'Nguyễn Văn An', N'Manager', @F1, N'Active'),
    (N'manager02', N'manager02@gmail.com', N'0909999002', @ManagerHash, N'Trần Thị Bích', N'Manager', @F2, N'Active'),
    (N'manager03', N'manager03@gmail.com', N'0909999003', @ManagerHash, N'Lê Văn Cường', N'Manager', @F3, N'Active');

-- ============================================================
-- SECTION 8: Users — 50 Customers with Vietnamese names
-- ============================================================
INSERT INTO Users.[User] (Username, Email, Phone, PasswordHash, FullName, Role, AccountStatus)
VALUES
    (N'customer01', N'customer01@gmail.com', N'0909999101', @CustomerHash, N'Nguyễn Văn An',     N'Customer', N'Active'),
    (N'customer02', N'customer02@gmail.com', N'0909999102', @CustomerHash, N'Trần Thị Bích',     N'Customer', N'Active'),
    (N'customer03', N'customer03@gmail.com', N'0909999103', @CustomerHash, N'Lê Văn Cường',      N'Customer', N'Active'),
    (N'customer04', N'customer04@gmail.com', N'0909999104', @CustomerHash, N'Phạm Thị Dung',      N'Customer', N'Active'),
    (N'customer05', N'customer05@gmail.com', N'0909999105', @CustomerHash, N'Hoàng Văn Hải',      N'Customer', N'Active'),
    (N'customer06', N'customer06@gmail.com', N'0909999106', @CustomerHash, N'Huỳnh Thị Hà',       N'Customer', N'Active'),
    (N'customer07', N'customer07@gmail.com', N'0909999107', @CustomerHash, N'Phan Văn Hùng',      N'Customer', N'Active'),
    (N'customer08', N'customer08@gmail.com', N'0909999108', @CustomerHash, N'Vũ Thị Hoa',         N'Customer', N'Active'),
    (N'customer09', N'customer09@gmail.com', N'0909999109', @CustomerHash, N'Đặng Văn Long',      N'Customer', N'Active'),
    (N'customer10', N'customer10@gmail.com', N'0909999110', @CustomerHash, N'Bùi Thị Mai',        N'Customer', N'Active'),
    (N'customer11', N'customer11@gmail.com', N'0909999111', @CustomerHash, N'Đỗ Văn Minh',        N'Customer', N'Active'),
    (N'customer12', N'customer12@gmail.com', N'0909999112', @CustomerHash, N'Hồ Thị Ngọc',        N'Customer', N'Active'),
    (N'customer13', N'customer13@gmail.com', N'0909999113', @CustomerHash, N'Ngô Văn Nam',        N'Customer', N'Active'),
    (N'customer14', N'customer14@gmail.com', N'0909999114', @CustomerHash, N'Dương Thị Phương',   N'Customer', N'Active'),
    (N'customer15', N'customer15@gmail.com', N'0909999115', @CustomerHash, N'Lý Văn Quân',        N'Customer', N'Active'),
    (N'customer16', N'customer16@gmail.com', N'0909999116', @CustomerHash, N'Nguyễn Thị Lan',     N'Customer', N'Active'),
    (N'customer17', N'customer17@gmail.com', N'0909999117', @CustomerHash, N'Trần Văn Dũng',      N'Customer', N'Active'),
    (N'customer18', N'customer18@gmail.com', N'0909999118', @CustomerHash, N'Lê Thị Hồng',        N'Customer', N'Active'),
    (N'customer19', N'customer19@gmail.com', N'0909999119', @CustomerHash, N'Phạm Văn Thắng',     N'Customer', N'Active'),
    (N'customer20', N'customer20@gmail.com', N'0909999120', @CustomerHash, N'Hoàng Thị Tuyết',    N'Customer', N'Active'),
    (N'customer21', N'customer21@gmail.com', N'0909999121', @CustomerHash, N'Huỳnh Văn Phúc',     N'Customer', N'Active'),
    (N'customer22', N'customer22@gmail.com', N'0909999122', @CustomerHash, N'Phan Thị Kiều',      N'Customer', N'Active'),
    (N'customer23', N'customer23@gmail.com', N'0909999123', @CustomerHash, N'Vũ Văn Trọng',       N'Customer', N'Active'),
    (N'customer24', N'customer24@gmail.com', N'0909999124', @CustomerHash, N'Đặng Thị Hương',     N'Customer', N'Active'),
    (N'customer25', N'customer25@gmail.com', N'0909999125', @CustomerHash, N'Bùi Văn Tùng',       N'Customer', N'Active'),
    (N'customer26', N'customer26@gmail.com', N'0909999126', @CustomerHash, N'Đỗ Thị Trang',       N'Customer', N'Active'),
    (N'customer27', N'customer27@gmail.com', N'0909999127', @CustomerHash, N'Hồ Văn Phong',       N'Customer', N'Active'),
    (N'customer28', N'customer28@gmail.com', N'0909999128', @CustomerHash, N'Ngô Thị Yến',        N'Customer', N'Active'),
    (N'customer29', N'customer29@gmail.com', N'0909999129', @CustomerHash, N'Dương Văn Tiến',     N'Customer', N'Active'),
    (N'customer30', N'customer30@gmail.com', N'0909999130', @CustomerHash, N'Lý Thị Thảo',        N'Customer', N'Active'),
    (N'customer31', N'customer31@gmail.com', N'0909999131', @CustomerHash, N'Nguyễn Văn Bình',    N'Customer', N'Active'),
    (N'customer32', N'customer32@gmail.com', N'0909999132', @CustomerHash, N'Trần Thị Mỹ',        N'Customer', N'Active'),
    (N'customer33', N'customer33@gmail.com', N'0909999133', @CustomerHash, N'Lê Văn Đức',         N'Customer', N'Active'),
    (N'customer34', N'customer34@gmail.com', N'0909999134', @CustomerHash, N'Phạm Thị Liên',      N'Customer', N'Active'),
    (N'customer35', N'customer35@gmail.com', N'0909999135', @CustomerHash, N'Hoàng Văn Thịnh',    N'Customer', N'Active'),
    (N'customer36', N'customer36@gmail.com', N'0909999136', @CustomerHash, N'Huỳnh Thị Vân',      N'Customer', N'Active'),
    (N'customer37', N'customer37@gmail.com', N'0909999137', @CustomerHash, N'Phan Văn Khanh',     N'Customer', N'Active'),
    (N'customer38', N'customer38@gmail.com', N'0909999138', @CustomerHash, N'Vũ Thị Nhung',       N'Customer', N'Active'),
    (N'customer39', N'customer39@gmail.com', N'0909999139', @CustomerHash, N'Đặng Văn Mạnh',      N'Customer', N'Active'),
    (N'customer40', N'customer40@gmail.com', N'0909999140', @CustomerHash, N'Bùi Thị Quỳnh',      N'Customer', N'Active'),
    (N'customer41', N'customer41@gmail.com', N'0909999141', @CustomerHash, N'Đỗ Văn Linh',        N'Customer', N'Active'),
    (N'customer42', N'customer42@gmail.com', N'0909999142', @CustomerHash, N'Hồ Thị Chi',         N'Customer', N'Active'),
    (N'customer43', N'customer43@gmail.com', N'0909999143', @CustomerHash, N'Ngô Văn Trí',        N'Customer', N'Active'),
    (N'customer44', N'customer44@gmail.com', N'0909999144', @CustomerHash, N'Dương Thị Giang',    N'Customer', N'Active'),
    (N'customer45', N'customer45@gmail.com', N'0909999145', @CustomerHash, N'Lý Văn Tú',          N'Customer', N'Active'),
    (N'customer46', N'customer46@gmail.com', N'0909999146', @CustomerHash, N'Nguyễn Thị Anh',     N'Customer', N'Active'),
    (N'customer47', N'customer47@gmail.com', N'0909999147', @CustomerHash, N'Trần Văn Vinh',      N'Customer', N'Active'),
    (N'customer48', N'customer48@gmail.com', N'0909999148', @CustomerHash, N'Lê Thị Hiền',        N'Customer', N'Active'),
    (N'customer49', N'customer49@gmail.com', N'0909999149', @CustomerHash, N'Phạm Văn Lộc',       N'Customer', N'Active'),
    (N'customer50', N'customer50@gmail.com', N'0909999150', @CustomerHash, N'Hoàng Thị Duyên',    N'Customer', N'Active');

PRINT N'Users seeded: 1 admin, 3 managers, 50 customers.';
GO

-- ============================================================
-- SECTION 9: Users — Vehicles (60+ vehicles)
-- ============================================================
DECLARE @VehicleData TABLE (Username NVARCHAR(50), Plate NVARCHAR(20), Brand NVARCHAR(50), Model NVARCHAR(100), Year INT, Battery DECIMAL(5,2), Connector NVARCHAR(30), Num INT);
INSERT INTO @VehicleData VALUES
    ('customer01', N'51A-12345', 'VinFast', 'VF8',  2024, 85.0, 'CCS2', 1),
    ('customer01', N'51A-67890', 'VinFast', 'VF5',  2023, 37.2, 'CCS2', 2),
    ('customer02', N'30A-12345', 'VinFast', 'VF9',  2024, 123.0,'CCS2', 1),
    ('customer02', N'30A-54321', 'VinFast', 'VF6',  2024, 59.0, 'CCS2', 2),
    ('customer03', N'43A-12345', 'Tesla',   'Model 3', 2023, 60.0, 'CCS2', 1),
    ('customer04', N'51B-11111', 'VinFast', 'VF8',  2024, 85.0, 'CCS2', 1),
    ('customer05', N'51C-22222', 'VinFast', 'VF7',  2024, 73.0, 'CCS2', 1),
    ('customer05', N'51C-33333', 'Hyundai', 'Ioniq 5',2024, 72.6, 'CCS2', 2),
    ('customer06', N'30B-44444', 'VinFast', 'VF5',  2023, 37.2, 'CCS2', 1),
    ('customer07', N'43B-55555', 'VinFast', 'VF8',  2024, 85.0, 'CCS2', 1),
    ('customer08', N'51D-66666', 'VinFast', 'VF9',  2024, 123.0,'CCS2', 1),
    ('customer09', N'51E-77777', 'Tesla',   'Model Y',2023, 75.0, 'CCS2', 1),
    ('customer10', N'30C-88888', 'VinFast', 'VF6',  2024, 59.0, 'CCS2', 1),
    ('customer11', N'51F-99999', 'VinFast', 'VF5',  2023, 37.2, 'CCS2', 1),
    ('customer11', N'51F-00000', 'Kia',     'EV6',  2024, 77.4, 'CCS2', 2),
    ('customer12', N'43C-12121', 'VinFast', 'VF8',  2024, 85.0, 'CCS2', 1),
    ('customer13', N'51G-23232', 'VinFast', 'VF7',  2024, 73.0, 'CCS2', 1),
    ('customer14', N'30D-34343', 'VinFast', 'VF9',  2024, 123.0,'CCS2', 1),
    ('customer15', N'51H-45454', 'Tesla',   'Model 3',2024, 62.0, 'CCS2', 1),
    ('customer16', N'51I-56565', 'VinFast', 'VF5',  2023, 37.2, 'CCS2', 1),
    ('customer17', N'30E-67676', 'VinFast', 'VF8',  2024, 85.0, 'CCS2', 1),
    ('customer18', N'43D-78787', 'VinFast', 'VF6',  2024, 59.0, 'CCS2', 1),
    ('customer19', N'51J-89898', 'VinFast', 'VF7',  2024, 73.0, 'CCS2', 1),
    ('customer20', N'30F-90909', 'VinFast', 'VF9',  2024, 123.0,'CCS2', 1),
    ('customer21', N'51K-01010', 'Hyundai', 'Ioniq 6',2024, 77.4, 'CCS2', 1),
    ('customer22', N'43E-11110', 'VinFast', 'VF5',  2023, 37.2, 'CCS2', 1),
    ('customer23', N'51L-21212', 'Tesla',   'Model S',2022, 100.0,'CCS2', 1),
    ('customer24', N'30G-31313', 'VinFast', 'VF8',  2024, 85.0, 'CCS2', 1),
    ('customer25', N'51M-41414', 'VinFast', 'VF6',  2024, 59.0, 'CCS2', 1),
    ('customer26', N'51N-51515', 'VinFast', 'VF9',  2024, 123.0,'CCS2', 1),
    ('customer27', N'30H-61616', 'VinFast', 'VF7',  2024, 73.0, 'CCS2', 1),
    ('customer28', N'43F-71717', 'VinFast', 'VF5',  2023, 37.2, 'CCS2', 1),
    ('customer29', N'51O-81818', 'VinFast', 'VF8',  2024, 85.0, 'CCS2', 1),
    ('customer30', N'30I-91919', 'Kia',     'EV6',  2024, 77.4, 'CCS2', 1),
    ('customer31', N'51P-02020', 'VinFast', 'VF6',  2024, 59.0, 'CCS2', 1),
    ('customer31', N'51P-12120', 'BMW',     'iX3',  2024, 74.0, 'CCS2', 2),
    ('customer32', N'30J-22220', 'VinFast', 'VF8',  2024, 85.0, 'CCS2', 1),
    ('customer33', N'43G-32320', 'VinFast', 'VF9',  2024, 123.0,'CCS2', 1),
    ('customer34', N'51Q-42420', 'VinFast', 'VF5',  2023, 37.2, 'CCS2', 1),
    ('customer35', N'30K-52520', 'Tesla',   'Model Y',2024, 75.0, 'CCS2', 1),
    ('customer36', N'51R-62620', 'VinFast', 'VF7',  2024, 73.0, 'CCS2', 1),
    ('customer37', N'43H-72720', 'VinFast', 'VF6',  2024, 59.0, 'CCS2', 1),
    ('customer38', N'51S-82820', 'Hyundai', 'Ioniq 5',2024, 72.6, 'CCS2', 1),
    ('customer39', N'30L-92920', 'VinFast', 'VF8',  2024, 85.0, 'CCS2', 1),
    ('customer40', N'51T-03030', 'VinFast', 'VF9',  2024, 123.0,'CCS2', 1),
    ('customer41', N'43I-13130', 'VinFast', 'VF5',  2023, 37.2, 'CCS2', 1),
    ('customer42', N'51U-23230', 'VinFast', 'VF8',  2024, 85.0, 'CCS2', 1),
    ('customer43', N'30M-33330', 'Tesla',   'Model 3',2024, 62.0, 'CCS2', 1),
    ('customer44', N'51V-43430', 'VinFast', 'VF6',  2024, 59.0, 'CCS2', 1),
    ('customer45', N'43J-53530', 'VinFast', 'VF7',  2024, 73.0, 'CCS2', 1),
    ('customer46', N'51W-63630', 'Kia',     'EV6',  2024, 77.4, 'CCS2', 1),
    ('customer47', N'30N-73730', 'VinFast', 'VF9',  2024, 123.0,'CCS2', 1),
    ('customer48', N'51X-83830', 'VinFast', 'VF5',  2023, 37.2, 'CCS2', 1),
    ('customer49', N'43K-93930', 'VinFast', 'VF8',  2024, 85.0, 'CCS2', 1),
    ('customer50', N'51Y-04040', 'BMW',     'i4',   2024, 80.0, 'CCS2', 1);

INSERT INTO Users.Vehicle (UserID, PlateNumber, Brand, Model, ModelYear, BatteryCapacityKWh, ConnectorType)
SELECT u.UserID, d.Plate, d.Brand, d.Model, d.Year, d.Battery, d.Connector
FROM @VehicleData d
JOIN Users.[User] u ON u.Username = d.Username
ORDER BY d.Num;

PRINT N'Vehicles seeded: ' + CAST(@@ROWCOUNT AS NVARCHAR(10)) + N' vehicles.';
GO

-- ============================================================
-- SECTION 10: Operations — Pricing Policies
-- ============================================================
INSERT INTO Operations.PricingPolicy (PolicyCode, PolicyName, BasePricePerKWh, CurrencyCode, PeakMultiplier, PeakStartHour, PeakEndHour, IsWeekendPeak, AppliedFrom)
VALUES
    (N'STANDARD', N'Giá tiêu chuẩn',    3500, N'VND', 1.50, N'17:00', N'19:00', 0, '2024-01-01'),
    (N'OFFPEAK',  N'Giá thấp điểm',     2800, N'VND', 1.00, NULL,    NULL,    0, '2024-01-01'),
    (N'VIP_MEM',  N'Giá hội viên VIP',  2500, N'VND', 1.30, N'17:00', N'19:00', 0, '2024-01-01'),
    (N'HOLIDAY',  N'Giá ngày lễ',       4000, N'VND', 1.00, NULL,    NULL,    1, '2024-01-01'),
    (N'PROMO_Q1', N'Khuyến mãi Q1 2024', 3000, N'VND', 1.40, N'17:00', N'19:00', 0, '2024-01-01');

PRINT N'Pricing policies seeded: 5 policies.';
GO

-- ============================================================
-- SECTION 11: Payments — Wallets for all users
-- ============================================================
DECLARE @BaseBalance MONEY = 1000000;

DECLARE @WalletData TABLE (UserID INT, WalletCode NVARCHAR(30), Balance MONEY);
INSERT INTO @WalletData
SELECT UserID, N'WAL-' + Username,
    CASE Role
        WHEN N'Admin' THEN 5000000
        WHEN N'Manager' THEN 2000000
        WHEN N'Customer' THEN @BaseBalance + (UserID % 10) * 200000
    END
FROM Users.[User];

INSERT INTO Payments.Wallet (UserID, WalletCode, Balance)
SELECT UserID, WalletCode, Balance FROM @WalletData;

PRINT N'Wallets seeded: ' + CAST(@@ROWCOUNT AS NVARCHAR(10)) + N' wallets.';
GO

-- ============================================================
-- SECTION 12: Operations — Bookings (50 bookings)
-- ============================================================
DECLARE @BookingData TABLE (Username NVARCHAR(50), PointCode NVARCHAR(30), DaysAgo INT, Hour INT, DurationMin INT, VIdx INT, Status NVARCHAR(20));
INSERT INTO @BookingData VALUES
    ('customer01', 'VFSG-01-A', 1, 8, 120, 1, 'Completed'),
    ('customer02', 'VFHN-01-A', 2, 9, 90,  1, 'Completed'),
    ('customer03', 'EVN-DN1-A', 3, 10, 60, 1, 'Completed'),
    ('customer04', 'VFSG-02-A', 4, 14, 120,1, 'Completed'),
    ('customer05', 'VFVT-01-A', 5, 15, 90, 1, 'Completed'),
    ('customer06', 'GRBD-01-A', 6, 7, 120, 1, 'Completed'),
    ('customer07', 'VFSG-01-B', 7, 18, 60, 1, 'Completed'),
    ('customer08', 'VFHN-02-A', 8, 11, 90, 1, 'Completed'),
    ('customer09', 'EVN-DN2-A', 9, 13, 120,1, 'Completed'),
    ('customer10', 'VFSG-03-A', 10, 16, 60, 1, 'Completed'),
    ('customer11', 'VFSG-04-A', 11, 8, 90,  1, 'Completed'),
    ('customer12', 'VFHN-01-B', 12, 17, 60, 1, 'Completed'),
    ('customer13', 'GRBD-01-B', 5, 9, 120,  1, 'Completed'),
    ('customer14', 'VFVT-01-B', 3, 14, 90,  1, 'Completed'),
    ('customer15', 'VFSG-02-B', 2, 10, 60,  1, 'Completed'),
    ('customer16', 'VFSG-01-A', 7, 12, 120, 1, 'Completed'),
    ('customer17', 'VFHN-02-B', 8, 15, 90,  1, 'Completed'),
    ('customer18', 'EVN-DN1-B', 9, 11, 60,  1, 'Completed'),
    ('customer19', 'VFSG-02-C', 10, 16, 120,1, 'Completed'),
    ('customer20', 'GRBD-01-A', 11, 8, 90,  1, 'Completed'),
    ('customer21', 'VFHN-01-A', 12, 17, 60, 1, 'Completed'),
    ('customer22', 'VFSG-03-A', 5, 9, 120,  1, 'Completed'),
    ('customer23', 'EVN-DN2-B', 3, 14, 90,  1, 'Completed'),
    ('customer24', 'VFVT-01-A', 2, 10, 60,  1, 'Completed'),
    ('customer25', 'VFSG-04-B', 1, 18, 120, 1, 'Completed'),
    ('customer26', 'VFSG-01-B', 4, 11, 90,  1, 'Completed'),
    ('customer27', 'VFHN-02-A', 6, 13, 60,  1, 'Completed'),
    ('customer28', 'EVN-DN1-A', 8, 15, 120, 1, 'Completed'),
    ('customer29', 'GRBD-01-B', 9, 7, 90,   1, 'Completed'),
    ('customer30', 'VFSG-02-A', 10, 16, 60, 1, 'Completed'),
    ('customer31', 'VFHN-01-B', 11, 8, 120, 1, 'Completed'),
    ('customer32', 'VFVT-01-B', 12, 17, 90, 1, 'Completed'),
    ('customer33', 'EVN-DN2-A', 5, 9, 60,   1, 'Completed'),
    ('customer34', 'VFSG-03-A', 3, 14, 120, 1, 'Completed'),
    ('customer35', 'VFSG-01-A', 2, 10, 90,  1, 'Completed'),
    ('customer36', 'VFHN-01-A', 1, 18, 60,  1, 'Completed'),
    ('customer37', 'GRBD-01-A', 7, 11, 120, 1, 'Completed'),
    ('customer38', 'VFSG-04-A', 8, 13, 90,  1, 'Completed'),
    ('customer39', 'EVN-DN1-B', 9, 15, 60,  1, 'Completed'),
    ('customer40', 'VFHN-02-B', 10, 7, 120, 1, 'Completed'),
    ('customer41', 'VFVT-01-A', 11, 16, 90, 1, 'Completed'),
    ('customer42', 'VFSG-02-B', 12, 8, 60,  1, 'Completed'),
    ('customer43', 'VFSG-01-B', 5, 17, 120, 1, 'Completed'),
    ('customer44', 'GRBD-01-A', 3, 9, 90,   1, 'Completed'),
    ('customer45', 'EVN-DN2-B', 2, 14, 60,  1, 'Completed'),
    ('customer46', 'VFHN-01-A', 1, 10, 120, 1, 'Completed'),
    ('customer47', 'VFSG-04-B', 4, 15, 90,  1, 'Completed'),
    ('customer48', 'VFVT-01-B', 6, 11, 60,  1, 'Completed'),
    ('customer49', 'VFSG-02-C', 8, 13, 120, 1, 'Completed'),
    ('customer50', 'EVN-DN1-A', 9, 16, 90,  1, 'Completed');

INSERT INTO Operations.Booking (BookingCode, UserID, PointID, StationID, VehicleID, BookedFrom, BookedTo, Status)
SELECT
    N'BOK-' + RIGHT(N'000' + CAST(ROW_NUMBER() OVER (ORDER BY d.DaysAgo, d.Hour) AS NVARCHAR(10)), 4),
    u.UserID,
    p.PointID,
    p.StationID,
    (SELECT TOP 1 VehicleID FROM Users.Vehicle WHERE UserID = u.UserID ORDER BY VehicleID),
    DATEADD(DAY, -d.DaysAgo, DATEADD(HOUR, d.Hour, CAST(SYSDATETIME() AS DATETIME2(0)))),
    DATEADD(MINUTE, d.DurationMin, DATEADD(DAY, -d.DaysAgo, DATEADD(HOUR, d.Hour, CAST(SYSDATETIME() AS DATETIME2(0))))),
    d.Status
FROM @BookingData d
JOIN Users.[User] u ON u.Username = d.Username
JOIN Infrastructure.ChargingPoint p ON p.PointCode = d.PointCode;

PRINT N'Bookings seeded: ' + CAST(@@ROWCOUNT AS NVARCHAR(10)) + N' bookings.';
GO

-- ============================================================
-- SECTION 13: Operations — Charging Sessions (250 sessions)
-- ============================================================
DECLARE @POL_STD INT = (SELECT PolicyID FROM Operations.PricingPolicy WHERE PolicyCode = N'STANDARD');
DECLARE @POL_OFF INT = (SELECT PolicyID FROM Operations.PricingPolicy WHERE PolicyCode = N'OFFPEAK');
DECLARE @SessionsToGenerate INT = 250;
DECLARE @DayOffset INT, @HourOffset INT, @MinuteOffset INT;
DECLARE @SessionCustomer INT, @SessionStation INT, @SessionPoint INT;
DECLARE @SessionStart DATETIME2, @SessionEnd DATETIME2;
DECLARE @SessionKWh DECIMAL(13,4), @SessionDuration INT;
DECLARE @SessionCost MONEY, @SessionPolicy INT;
DECLARE @SessionVehicle INT, @Counter INT = 0;
DECLARE @IsPeak BIT, @BasePrice DECIMAL(19,4);
DECLARE @SessionStationCode NVARCHAR(20), @SessionPointCode NVARCHAR(30);
DECLARE @SessionHour INT;
DECLARE @UserIdOffset INT = (SELECT MIN(UserID) FROM Users.[User] WHERE Role = N'Customer');
DECLARE @StationIds TABLE (sid INT, scode NVARCHAR(20), idx INT);
INSERT INTO @StationIds SELECT StationID, StationCode, ROW_NUMBER() OVER (ORDER BY StationID) FROM Infrastructure.ChargingStation;
DECLARE @PointIds TABLE (pid INT, pcode NVARCHAR(30), sid INT, idx INT);
INSERT INTO @PointIds SELECT PointID, PointCode, StationID, ROW_NUMBER() OVER (ORDER BY PointID) FROM Infrastructure.ChargingPoint;

WHILE @Counter < @SessionsToGenerate
BEGIN
    SET @SessionCustomer = @UserIdOffset + (@Counter % 50);
    SET @SessionStation = ((@Counter / 5) % 10) + 1;
    SET @SessionPoint = ((@Counter / 2) % 20) + 1;
    SET @DayOffset = @Counter / 10;
    IF @DayOffset > 89 SET @DayOffset = @DayOffset % 90;
    SET @HourOffset = 6 + ((@Counter * 7 + @DayOffset * 3) % 16);
    SET @MinuteOffset = ((@Counter * 13 + @DayOffset * 7) % 60);
    SET @SessionStart = DATEADD(DAY, -@DayOffset, DATEADD(HOUR, @HourOffset, DATEADD(MINUTE, @MinuteOffset, CAST(SYSDATETIME() AS DATETIME2(0)))));
    SET @SessionDuration = 20 + ((@Counter * 17 + @DayOffset * 11) % 160);
    SET @SessionEnd = DATEADD(MINUTE, @SessionDuration, @SessionStart);
    SET @SessionKWh = 10.0 + ((@Counter * 3 + @DayOffset * 7) % 70) + RAND(CAST(@Counter AS FLOAT) * 1000) * 5;
    SET @SessionHour = DATEPART(HOUR, @SessionStart);
    SET @IsPeak = CASE WHEN @SessionHour BETWEEN 17 AND 18 AND DATEPART(WEEKDAY, @SessionStart) NOT IN (1,7) THEN 1 ELSE 0 END;
    SET @SessionPolicy = CASE WHEN @IsPeak = 1 THEN @POL_STD WHEN @SessionHour BETWEEN 22 AND 23 OR @SessionHour < 5 THEN @POL_OFF ELSE @POL_STD END;
    SELECT @BasePrice = BasePricePerKWh FROM Operations.PricingPolicy WHERE PolicyID = @SessionPolicy;
    IF @IsPeak = 1 SET @SessionCost = @SessionKWh * @BasePrice * 1.5;
    ELSE SET @SessionCost = @SessionKWh * @BasePrice;
    SELECT @SessionVehicle = VehicleID FROM Users.Vehicle WHERE UserID = @SessionCustomer ORDER BY VehicleID OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY;
    SELECT @SessionStationCode = scode FROM @StationIds WHERE idx = @SessionStation;
    SELECT @SessionPointCode = pcode FROM @PointIds WHERE pid = (SELECT pid FROM @PointIds WHERE idx = @SessionPoint);

    INSERT INTO Operations.ChargingSession (SessionCode, UserID, VehicleID, PointID, StationID, PolicyID, StartTime, EndTime, StartBatteryPercent, EndBatteryPercent, MeterStart, MeterEnd, TotalKWh, ChargingDurationMinutes, CostTotal, StopReason, SessionStatus)
    VALUES (
        N'SES-' + FORMAT(@SessionStart, 'yyyyMMdd') + N'-' + RIGHT(N'000' + CAST(@Counter + 1 AS NVARCHAR(10)), 4),
        @SessionCustomer,
        @SessionVehicle,
        (SELECT pid FROM @PointIds WHERE idx = @SessionPoint),
        (SELECT sid FROM @StationIds WHERE idx = @SessionStation),
        @SessionPolicy,
        @SessionStart, @SessionEnd,
        CAST(10 + ((@Counter * 5) % 80) AS DECIMAL(5,2)),
        CAST(30 + ((@Counter * 7) % 60) AS DECIMAL(5,2)),
        1000.0 + @Counter * 10.0,
        1000.0 + @Counter * 10.0 + @SessionKWh * 10.0,
        @SessionKWh, @SessionDuration, @SessionCost,
        N'Completed', N'Completed'
    );

    SET @Counter = @Counter + 1;
END

PRINT N'Charging sessions seeded: ' + CAST(@@ROWCOUNT AS NVARCHAR(10)) + N' sessions.';
GO

-- ============================================================
-- SECTION 14: Payments — Transactions (from completed sessions)
-- ============================================================
INSERT INTO Payments.[Transaction] (TransactionCode, UserID, SessionID, TransactionType, Direction, Amount, TransactionStatus, PaymentMethod, TransactedAt)
SELECT
    N'TXN-' + FORMAT(SYSDATETIME(), 'yyyyMMdd') + N'-' + RIGHT(N'000000' + CAST(ROW_NUMBER() OVER (ORDER BY cs.SessionID) AS NVARCHAR(10)), 6),
    cs.UserID,
    cs.SessionID,
    N'ChargingPayment',
    N'D',
    cs.CostTotal,
    N'Completed',
    N'Wallet',
    cs.EndTime
FROM Operations.ChargingSession cs
WHERE cs.SessionStatus = N'Completed';

PRINT N'Transactions seeded: ' + CAST(@@ROWCOUNT AS NVARCHAR(10)) + N' transactions.';
GO

-- ============================================================
-- SECTION 15: Payments — Wallet Transactions (debit entries)
-- ============================================================
INSERT INTO Payments.WalletTransaction (WalletID, TransactionID, Amount, BalanceBefore, Direction, TransactionType, Description)
SELECT
    w.WalletID,
    t.TransactionID,
    -t.Amount,
    w.Balance - SUM(t.Amount) OVER (PARTITION BY w.WalletID ORDER BY t.TransactedAt ROWS UNBOUNDED PRECEDING) + t.Amount,
    N'D',
    N'ChargingPayment',
    N'Thanh toán phí sạc xe điện'
FROM Payments.[Transaction] t
JOIN Payments.Wallet w ON t.UserID = w.UserID
WHERE t.TransactionType = N'ChargingPayment' AND t.TransactionStatus = N'Completed'
ORDER BY t.TransactedAt;

PRINT N'Wallet transactions seeded: ' + CAST(@@ROWCOUNT AS NVARCHAR(10)) + N' entries.';
GO

-- ============================================================
-- SECTION 16: Operations — Maintenance Schedules (15 records)
-- ============================================================
DECLARE @MaintData TABLE (PointCode NVARCHAR(30), DaysAgo INT, DaysFrom DECIMAL(3,1), MType NVARCHAR(50), Status NVARCHAR(20), MgrUsername NVARCHAR(50));
INSERT INTO @MaintData VALUES
    ('VFSG-01-B', 45, 0.5, 'Preventive', 'Completed', 'manager01'),
    ('VFSG-02-C', 30, 1.0, 'Inspection', 'Completed', 'manager01'),
    ('VFHN-01-B', 60, 0.8, 'Preventive', 'Completed', 'manager02'),
    ('EVN-DN1-B', 50, 0.5, 'Corrective', 'Completed', 'manager03'),
    ('GRBD-01-B', 40, 1.0, 'Preventive', 'Completed', 'manager01'),
    ('VFVT-01-B', 35, 0.5, 'Inspection', 'Completed', 'manager01'),
    ('VFSG-02-A', 20, 2.0, 'Upgrade',    'Completed', 'manager01'),
    ('VFHN-02-B', 15, 1.0, 'Preventive', 'Completed', 'manager02'),
    ('EVN-DN2-B', 25, 0.5, 'Corrective', 'Completed', 'manager03'),
    ('VFSG-04-B', 10, 1.5, 'Preventive', 'Completed', 'manager01'),
    ('VFSG-01-A', 3,  2.0, 'Preventive', 'Completed', 'manager01'),
    ('VFHN-01-A', 5,  1.0, 'Inspection', 'Completed', 'manager02'),
    ('EVN-DN1-A', 7,  0.5, 'Upgrade',    'Completed', 'manager03'),
    ('GRBD-01-A', 2,  3.0, 'Preventive', 'Scheduled', 'manager01'),
    ('VFVT-01-A', 1,  2.0, 'Preventive', 'Scheduled', 'manager01'),
    (NULL, 14, 4.0, 'Preventive', 'Scheduled', 'manager02');

INSERT INTO Operations.MaintenanceSchedule (PointID, StationID, ScheduledBy, ScheduledFrom, ScheduledTo, MaintenanceType, Description, Status, CompletedAt, Notes)
SELECT
    p.PointID,
    p.StationID,
    uMgr.UserID,
    DATEADD(DAY, -d.DaysAgo, DATEADD(HOUR, 8, CAST(SYSDATETIME() AS DATETIME2(0)))),
    DATEADD(DAY, -d.DaysAgo, DATEADD(HOUR, 11, CAST(SYSDATETIME() AS DATETIME2(0)))),
    d.MType,
    CASE d.MType
        WHEN N'Preventive' THEN N'Bảo trì định kỳ theo lịch nhà sản xuất'
        WHEN N'Corrective' THEN N'Sửa chữa lỗi thiết bị'
        WHEN N'Inspection' THEN N'Kiểm tra định kỳ hệ thống'
        WHEN N'Upgrade' THEN N'Nâng cấp phần mềm firmware'
        WHEN N'Scheduled' THEN N'Bảo trì theo kế hoạch'
    END,
    d.Status,
    CASE WHEN d.Status = 'Completed' THEN DATEADD(DAY, -d.DaysAgo, DATEADD(HOUR, 11, CAST(SYSDATETIME() AS DATETIME2(0)))) ELSE NULL END,
    CASE WHEN d.Status = 'Completed' THEN N'Hoàn thành bảo trì đúng tiến độ' ELSE NULL END
FROM @MaintData d
LEFT JOIN Infrastructure.ChargingPoint p ON p.PointCode = d.PointCode
JOIN Users.[User] uMgr ON uMgr.Username = d.MgrUsername;

PRINT N'Maintenance schedules seeded: ' + CAST(@@ROWCOUNT AS NVARCHAR(10)) + N' schedules.';
GO

-- ============================================================
-- SECTION 17: Operations — Station Reviews (30 reviews)
-- ============================================================
DECLARE @ReviewData TABLE (Username NVARCHAR(50), StationCode NVARCHAR(20), Rating INT, Comment NVARCHAR(500));
INSERT INTO @ReviewData VALUES
    ('customer01', 'VFSG-01', 5, N'Trạm sạc rất tốt, nhân viên hỗ trợ nhiệt tình'),
    ('customer02', 'VFHN-01', 4, N'Chất lượng tốt, giá cả hợp lý'),
    ('customer03', 'EVN-DN1', 5, N'Sạc nhanh, tiện lợi, sẽ quay lại'),
    ('customer04', 'VFSG-02', 4, N'Dễ tìm, có chỗ đậu xe rộng rãi'),
    ('customer05', 'VFVT-01', 3, N'Tốt nhưng cần thêm điểm sạc'),
    ('customer06', 'GRBD-01', 5, N'Phục vụ tuyệt vời, sạc ổn định'),
    ('customer07', 'VFSG-01', 4, N'Sạc nhanh, giá tốt'),
    ('customer08', 'VFHN-02', 5, N'Rất hài lòng, ứng dụng dễ sử dụng'),
    ('customer09', 'EVN-DN2', 4, N'Ổn định, không có lỗi gì'),
    ('customer10', 'VFSG-03', 3, N'Cần cải thiện tốc độ sạc'),
    ('customer11', 'VFSG-04', 5, N'Trạm mới, thiết bị hiện đại'),
    ('customer12', 'VFHN-01', 4, N'Thuận tiện cho khu vực trung tâm'),
    ('customer13', 'GRBD-01', 5, N'Giá rẻ hơn các trạm khác'),
    ('customer14', 'VFVT-01', 4, N'Gần biển, view đẹp khi chờ sạc'),
    ('customer15', 'VFSG-02', 5, N'Nhân viên thân thiện, hỗ trợ tốt'),
    ('customer16', 'VFSG-01', 4, N'Sạc ổn định, không bị gián đoạn'),
    ('customer17', 'VFHN-02', 3, N'Có lúc phải chờ vì đông'),
    ('customer18', 'EVN-DN1', 5, N'Rất tốt, luôn có chỗ trống'),
    ('customer19', 'VFSG-02', 4, N'Tiện lợi, gần trung tâm mua sắm'),
    ('customer20', 'GRBD-01', 5, N'Điểm sạc yêu thích của tôi'),
    ('customer21', 'VFHN-01', 4, N'Chất lượng dịch vụ tốt'),
    ('customer22', 'VFSG-03', 3, N'Cần nâng cấp thiết bị'),
    ('customer23', 'EVN-DN2', 5, N'Sạc nhanh, giá phải chăng'),
    ('customer24', 'VFVT-01', 4, N'Địa điểm đẹp, dễ tìm'),
    ('customer25', 'VFSG-04', 5, N'Trạm sạc hiện đại nhất tôi từng dùng'),
    ('customer26', 'VFSG-01', 4, N'Luôn đảm bảo chất lượng'),
    ('customer27', 'VFHN-02', 5, N'Hỗ trợ khách hàng tuyệt vời'),
    ('customer28', 'EVN-DN1', 3, N'Có thể cải thiện thêm tốc độ'),
    ('customer29', 'GRBD-01', 4, N'Ổn định, giá tốt'),
    ('customer30', 'VFSG-02', 5, N'Sẽ giới thiệu cho bạn bè');

INSERT INTO Operations.StationReview (UserID, StationID, Rating, Comment)
SELECT u.UserID, s.StationID, d.Rating, d.Comment
FROM @ReviewData d
JOIN Users.[User] u ON u.Username = d.Username
JOIN Infrastructure.ChargingStation s ON s.StationCode = d.StationCode;

PRINT N'Station reviews seeded: ' + CAST(@@ROWCOUNT AS NVARCHAR(10)) + N' reviews.';
GO

-- ============================================================
-- SECTION 18: Users — Notifications (100+ notifications)
-- ============================================================
INSERT INTO Users.Notification (UserID, Title, Body, Type, ReferenceType, ReferenceID, IsRead, CreatedAt)
SELECT
    cs.UserID,
    N'Phiên sạc hoàn thành',
    N'Phiên sạc ' + cs.SessionCode + N' đã hoàn thành. Chi phí: ' + CAST(CAST(cs.CostTotal AS BIGINT) AS NVARCHAR(20)) + N' VND.',
    N'ChargingComplete',
    N'Session',
    cs.SessionID,
    CASE WHEN cs.EndTime < DATEADD(DAY, -7, SYSDATETIME()) THEN 1 ELSE 0 END,
    cs.EndTime
FROM Operations.ChargingSession cs
WHERE cs.SessionStatus = N'Completed'
  AND cs.UserID IN (SELECT UserID FROM Users.[User] WHERE Role = N'Customer' AND UserID % 3 = 0);

INSERT INTO Users.Notification (UserID, Title, Body, Type, ReferenceType, ReferenceID, IsRead, CreatedAt)
SELECT
    u.UserID,
    N'Chào mừng bạn đến với EV Charging!',
    N'Tài khoản ' + u.FullName + N' đã được tạo thành công. Hãy bắt đầu sạc xe điện ngay hôm nay!',
    N'System',
    NULL, NULL, 1,
    u.CreatedAt
FROM Users.[User] u
WHERE u.Role = N'Customer';

PRINT N'Notifications seeded: ' + CAST(@@ROWCOUNT AS NVARCHAR(10)) + N' notifications.';
GO

-- ============================================================
-- SECTION 19: Infrastructure — Error Logs (20 errors)
-- ============================================================
INSERT INTO Infrastructure.ErrorLog (PointID, StationID, ErrorCode, Severity, Description, OccurredAt, ResolvedAt, ResolvedBy, ResolutionNotes, IsActive)
SELECT
    p.PointID, p.StationID,
    N'E001', N'High',
    N'Lỗi kết nối CCS2: mất tín hiệu trong quá trình sạc',
    DATEADD(DAY, -60, SYSDATETIME()),
    DATEADD(DAY, -58, SYSDATETIME()),
    (SELECT UserID FROM Users.[User] WHERE Username = N'manager01'),
    N'Đã reset thiết bị và kiểm tra cáp sạc', 0
FROM Infrastructure.ChargingPoint p WHERE p.PointCode = N'VFSG-01-B'
UNION ALL SELECT p.PointID, p.StationID, N'E002', N'Medium', N'Thiết bị mất kết nối mạng', DATEADD(DAY, -45, SYSDATETIME()), DATEADD(DAY, -44, SYSDATETIME()), (SELECT UserID FROM Users.[User] WHERE Username = N'manager01'), N'Đã khởi động lại router', 0 FROM Infrastructure.ChargingPoint p WHERE p.PointCode = N'VFSG-02-C'
UNION ALL SELECT p.PointID, p.StationID, N'E003', N'Low', N'Cảnh báo nhiệt độ cao', DATEADD(DAY, -30, SYSDATETIME()), DATEADD(DAY, -29, SYSDATETIME()), (SELECT UserID FROM Users.[User] WHERE Username = N'manager02'), N'Nhiệt độ đã trở lại bình thường', 0 FROM Infrastructure.ChargingPoint p WHERE p.PointCode = N'VFHN-01-B'
UNION ALL SELECT p.PointID, p.StationID, N'E001', N'Critical', N'Lỗi nghiêm trọng: quá dòng khi sạc', DATEADD(DAY, -20, SYSDATETIME()), DATEADD(DAY, -19, SYSDATETIME()), (SELECT UserID FROM Users.[User] WHERE Username = N'manager03'), N'Đã thay thế bộ phận bảo vệ quá dòng', 0 FROM Infrastructure.ChargingPoint p WHERE p.PointCode = N'EVN-DN1-B'
UNION ALL SELECT p.PointID, p.StationID, N'E002', N'Medium', N'Mất kết nối OCPP', DATEADD(DAY, -15, SYSDATETIME()), DATEADD(DAY, -14, SYSDATETIME()), (SELECT UserID FROM Users.[User] WHERE Username = N'manager01'), N'Kết nối lại thành công', 0 FROM Infrastructure.ChargingPoint p WHERE p.PointCode = N'GRBD-01-B'
UNION ALL SELECT p.PointID, p.StationID, N'E001', N'Medium', N'Lỗi cảm biến dòng điện', DATEADD(DAY, -10, SYSDATETIME()), DATEADD(DAY, -9, SYSDATETIME()), (SELECT UserID FROM Users.[User] WHERE Username = N'manager02'), N'Đã hiệu chỉnh cảm biến', 0 FROM Infrastructure.ChargingPoint p WHERE p.PointCode = N'VFHN-02-B'
UNION ALL SELECT p.PointID, p.StationID, N'E003', N'Low', N'Sụt áp nhẹ trong giờ cao điểm', DATEADD(DAY, -7, SYSDATETIME()), NULL, NULL, NULL, 1 FROM Infrastructure.ChargingPoint p WHERE p.PointCode = N'EVN-DN2-B'
UNION ALL SELECT p.PointID, p.StationID, N'E001', N'High', N'Lỗi giao tiếp CHAdeMO', DATEADD(DAY, -5, SYSDATETIME()), DATEADD(DAY, -4, SYSDATETIME()), (SELECT UserID FROM Users.[User] WHERE Username = N'manager01'), N'Đã cập nhật firmware', 0 FROM Infrastructure.ChargingPoint p WHERE p.PointCode = N'VFSG-04-B'
UNION ALL SELECT p.PointID, p.StationID, N'E002', N'Critical', N'Mất hoàn toàn kết nối internet', DATEADD(DAY, -3, SYSDATETIME()), DATEADD(DAY, -2, SYSDATETIME()), (SELECT UserID FROM Users.[User] WHERE Username = N'manager01'), N'Đã liên hệ ISP và khắc phục', 0 FROM Infrastructure.ChargingPoint p WHERE p.PointCode = N'VFSG-01-A'
UNION ALL SELECT p.PointID, p.StationID, N'E003', N'Medium', N'Nhiệt độ môi trường vượt ngưỡng', DATEADD(DAY, -1, SYSDATETIME()), NULL, NULL, NULL, 1 FROM Infrastructure.ChargingPoint p WHERE p.PointCode = N'GRBD-01-A';

PRINT N'Error logs seeded: ' + CAST(@@ROWCOUNT AS NVARCHAR(10)) + N' errors.';
GO

-- ============================================================
-- SECTION 20: Point Status Logs (from session starts)
-- ============================================================
INSERT INTO Infrastructure.PointStatusLog (PointID, OldStatus, NewStatus, ChangedAt)
SELECT cs.PointID, N'Available', N'Busy', cs.StartTime
FROM Operations.ChargingSession cs
WHERE cs.SessionStatus = N'Completed';

INSERT INTO Infrastructure.PointStatusLog (PointID, OldStatus, NewStatus, ChangedAt)
SELECT cs.PointID, N'Busy', N'Available', cs.EndTime
FROM Operations.ChargingSession cs
WHERE cs.SessionStatus = N'Completed';

PRINT N'Point status logs seeded.';
GO

-- ============================================================
-- SECTION 21: Realtime Events
-- ============================================================
INSERT INTO dbo.RealtimeEvent (EventType, AggregateType, AggregateID, Payload, UserID, CreatedAt, ProcessedAt)
SELECT
    N'SessionCompleted',
    N'ChargingSession',
    CAST(cs.SessionID AS NVARCHAR(50)),
    N'{"sessionId":' + CAST(cs.SessionID AS NVARCHAR(20)) + N',"kWh":' + CAST(cs.TotalKWh AS NVARCHAR(20)) + N',"cost":' + CAST(CAST(cs.CostTotal AS BIGINT) AS NVARCHAR(20)) + N'}',
    cs.UserID,
    cs.EndTime,
    cs.EndTime
FROM Operations.ChargingSession cs
WHERE cs.SessionStatus = N'Completed' AND cs.SessionID % 5 = 0;

INSERT INTO dbo.RealtimeEvent (EventType, AggregateType, AggregateID, Payload, UserID, CreatedAt, ProcessedAt)
VALUES
    (N'SystemStartup', N'System', N'EV_CHARGING', N'{"version":"2.0.0","status":"operational"}', NULL, DATEADD(DAY, -90, SYSDATETIME()), DATEADD(DAY, -90, SYSDATETIME())),
    (N'SystemHealthCheck', N'System', N'EV_CHARGING', N'{"activeStations":10,"onlinePoints":20,"activeSessions":0}', NULL, SYSDATETIME(), NULL);

PRINT N'Realtime events seeded.';
GO

-- ============================================================
-- SECTION 22: KPI Snapshots (Hourly + Daily)
-- ============================================================
INSERT INTO Reporting.KPISnapshotHourly (SnapshotAt, TotalUsers, ActiveStations, TotalPoints, AvailablePoints, BusyPoints, OfflinePoints, ActiveSessions, SessionsLastHour, KWhLastHour, RevenueLastHour, UnresolvedErrors, PendingBookings, TotalRevenue, TotalKWh)
VALUES
    (SYSDATETIME(), 54, 10, 20, 18, 0, 0, 0, 8, 350.50, 1225000, 2, 0, 45000000, 12500.00);

INSERT INTO Reporting.KPISnapshotDaily (SnapshotDate, NewUsers, ActiveStations, TotalSessions, CompletedSessions, TotalKWh, TotalRevenue, AvgDurationMin, PeakHour, PeakHourSessions, UniqueCustomers, ErrorsCreated, ErrorsResolved, MaintenanceScheduled, MaintenanceCompleted)
VALUES
    (CAST(DATEADD(DAY, -1, SYSDATETIME()) AS DATE), 0, 10, 35, 35, 1450.00, 5075000, 65, 17, 8, 20, 1, 0, 2, 1);

DECLARE @i INT = 2;
WHILE @i <= 30
BEGIN
    INSERT INTO Reporting.KPISnapshotDaily (SnapshotDate, NewUsers, ActiveStations, TotalSessions, CompletedSessions, TotalKWh, TotalRevenue, AvgDurationMin, PeakHour, PeakHourSessions, UniqueCustomers, ErrorsCreated, ErrorsResolved, MaintenanceScheduled, MaintenanceCompleted)
    VALUES (
        CAST(DATEADD(DAY, -@i, SYSDATETIME()) AS DATE),
        CASE WHEN @i <= 7 THEN 2 WHEN @i <= 14 THEN 1 ELSE 0 END,
        10,
        20 + (@i % 15),
        18 + (@i % 12),
        800.00 + (@i * 25),
        2800000 + (@i * 87500),
        55 + (@i % 20),
        17 + (@i % 3),
        5 + (@i % 4),
        10 + (@i % 8),
        @i % 3,
        @i % 2,
        @i % 3,
        @i % 2
    );
    SET @i = @i + 1;
END

PRINT N'KPI snapshots seeded: 1 hourly + 30 daily.';
GO

-- ============================================================
-- SECTION 23: Update wallet balances based on transactions
-- ============================================================
UPDATE w
SET w.Balance = w.Balance - COALESCE((
    SELECT SUM(t.Amount)
    FROM Payments.[Transaction] t
    WHERE t.UserID = w.UserID AND t.TransactionStatus = N'Completed' AND t.Direction = N'D'
), 0)
FROM Payments.Wallet w;

PRINT N'Wallet balances updated based on transaction history.';
GO

-- ============================================================
-- SECTION 24: Recalculate PointStatusLog to reflect actual data
-- Clean up any incorrect statuses
-- ============================================================
UPDATE Infrastructure.ChargingPoint
SET PointStatus = N'Available', UpdatedAt = SYSDATETIME()
WHERE PointStatus != N'Available' AND PointStatus != N'Maintenance';

PRINT N'Point statuses reset to available.';
GO

PRINT N'';
PRINT N'============================================================';
PRINT N' Seed data generation completed successfully!';
PRINT N'';
PRINT N' Summary:';
PRINT N'   - 1 Country, 5 Regions, 15 Addresses';
PRINT N'   - 3 Electricity Suppliers, 5 Franchises';
PRINT N'   - 10 Charging Stations, 20 Charging Points';
PRINT N'   - 1 Admin, 3 Managers, 50 Customers';
PRINT N'   - 55+ Vehicles, 5 Pricing Policies';
PRINT N'   - 54 Wallets, 50 Bookings';
PRINT N'   - 250 Charging Sessions, 250 Transactions';
PRINT N'   - 15 Maintenance Schedules, 30 Station Reviews';
PRINT N'   - 150+ Notifications, 10 Error Logs';
PRINT N'   - 30 Daily KPI Snapshots';
PRINT N'';
PRINT N' Default passwords:';
PRINT N'   Admin:    admin01@gmail.com / Admin@123';
PRINT N'   Manager:  manager01..03 / Manager@123';
PRINT N'   Customer: customer01..50 / Customer@123';
PRINT N'============================================================';
GO
