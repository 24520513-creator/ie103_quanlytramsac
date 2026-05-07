/*=============================================================================
  EV_Charging_System - SEED DATA
  =============================================================================*/

USE EV_Charging_System;
GO

-- ========================================
-- Infrastructure.Franchisee
-- ========================================
INSERT INTO Infrastructure.Franchisee (FranchiseeName, TaxCode, ContactPerson, Phone, Email, RevenueShareRate, ContractDate)
VALUES
    (N'Công ty TNHH Năng lượng Xanh', 'MS00001', N'Nguyễn Văn An', '0901000001', 'an.nguyen@greenenergy.vn', 15.00, '2024-01-15'),
    (N'Doanh nghiệp Tư nhân Điện khí', 'MS00002', N'Trần Thị Bình', '0901000002', 'binh.tran@dienkhi.vn', 20.00, '2024-03-01'),
    (N'Công ty CP Sạc Nhanh', 'MS00003', N'Lê Hoàng Cường', '0901000003', 'cuong.le@sacnhanh.vn', 12.50, '2024-06-20'),
    (N'Công ty TNHH EV Power', 'MS00004', N'Phạm Minh Đức', '0901000004', 'duc.pham@evpower.vn', 18.00, '2024-08-05'),
    (N'Hộ kinh doanh Trạm Xanh', 'MS00005', N'Hoàng Thị Em', '0901000005', 'em.hoang@tramxanh.vn', 25.00, '2025-01-10');
GO

-- ========================================
-- Infrastructure.ElectricitySuppliers
-- ========================================
INSERT INTO Infrastructure.ElectricitySuppliers (SupplierName, UnitPrice_kWh, Region, ContactInfo)
VALUES
    (N'EVN Miền Bắc', 2500.0000, N'Bắc', 'evn@north.vn'),
    (N'EVN Miền Trung', 2400.0000, N'Trung', 'evn@central.vn'),
    (N'EVN Miền Nam', 2600.0000, N'Nam', 'evn@south.vn'),
    (N'Điện lực Hà Nội', 2700.0000, N'Bắc', 'hanoi@evn.vn'),
    (N'Điện lực TP HCM', 2550.0000, N'Nam', 'hcmc@evn.vn');
GO

-- ========================================
-- Infrastructure.ChargingStation
-- ========================================
INSERT INTO Infrastructure.ChargingStation (FranchiseeID, SupplierID, StationName, Address, StationStatus)
VALUES
    (1, 1, N'Trạm sạc Xanh - Cầu Giấy', N'123 Cầu Giấy, Hà Nội', N'Hoạt động'),
    (1, 1, N'Trạm sạc Xanh - Thanh Xuân', N'456 Nguyễn Trãi, Hà Nội', N'Hoạt động'),
    (2, 3, N'Trạm sạc Điện khí - Quận 1', N'78 Lê Lợi, Quận 1, TP HCM', N'Hoạt động'),
    (2, 3, N'Trạm sạc Điện khí - Thủ Đức', N'12 Võ Văn Ngân, Thủ Đức', N'Bảo trì'),
    (3, 2, N'Trạm sạc Nhanh - Đà Nẵng', N'200 Nguyễn Văn Linh, Đà Nẵng', N'Hoạt động'),
    (3, 2, N'Trạm sạc Nhanh - Huế', N'50 Hùng Vương, Huế', N'Không hoạt động'),
    (4, 5, N'Trạm EV Power - Bình Thạnh', N'30 Phạm Văn Đồng, Bình Thạnh', N'Hoạt động'),
    (4, 4, N'Trạm EV Power - Tân Bình', N'55 Trường Chinh, Tân Bình', N'Hoạt động'),
    (5, 1, N'Trạm Xanh - Hải Phòng', N'90 Văn Cao, Hải Phòng', N'Hoạt động'),
    (5, 2, N'Trạm Xanh - Vinh', N'15 Lê Mao, Vinh', N'Hoạt động');
GO

-- ========================================
-- Infrastructure.ChargingPoint
-- ========================================
INSERT INTO Infrastructure.ChargingPoint (StationID, Power_kW, ConnectorType, PointStatus)
VALUES
    (1, 22.00, N'Type 2', N'Khả dụng'),
    (1, 50.00, N'CCS', N'Đang bận'),
    (1, 22.00, N'Type 2', N'Khả dụng'),
    (2, 22.00, N'Type 2', N'Khả dụng'),
    (2, 22.00, N'Type 2', N'Đang bận'),
    (3, 50.00, N'CCS', N'Khả dụng'),
    (3, 50.00, N'CCS', N'Khả dụng'),
    (3, 22.00, N'Type 2', N'Đang lỗi'),
    (3, 7.40, N'Type 1', N'Đã tắt'),
    (4, 22.00, N'Type 2', N'Đã tắt'),
    (4, 22.00, N'Type 2', N'Đã tắt'),
    (5, 150.00, N'CHAdeMO', N'Khả dụng'),
    (5, 50.00, N'CCS', N'Đang bận'),
    (5, 22.00, N'Type 2', N'Khả dụng'),
    (6, 22.00, N'Type 2', N'Khả dụng'),
    (6, 22.00, N'Type 2', N'Khả dụng'),
    (7, 50.00, N'CCS', N'Khả dụng'),
    (7, 22.00, N'Type 2', N'Đang bận'),
    (7, 22.00, N'Type 2', N'Khả dụng'),
    (8, 22.00, N'Type 2', N'Khả dụng'),
    (8, 7.40, N'Type 1', N'Khả dụng'),
    (9, 50.00, N'CCS', N'Khả dụng'),
    (9, 22.00, N'Type 2', N'Khả dụng'),
    (10, 22.00, N'Type 2', N'Khả dụng'),
    (10, 22.00, N'Type 2', N'Đang bận');
GO

-- ========================================
-- Users.Customers
-- ========================================
INSERT INTO Users.Customers (FullName, Email, Phone, PasswordHash, WalletBalance, AccountStatus)
VALUES
    (N'Nguyễn Thị Mai', 'mai.nguyen@email.com', '0912000001', CONVERT(NCHAR(64), HASHBYTES('SHA2_256', 'pass123'), 2), 500000, N'Đang mở'),
    (N'Trần Văn Nam', 'nam.tran@email.com', '0912000002', CONVERT(NCHAR(64), HASHBYTES('SHA2_256', 'pass456'), 2), 200000, N'Đang mở'),
    (N'Lê Thị Hương', 'huong.le@email.com', '0912000003', CONVERT(NCHAR(64), HASHBYTES('SHA2_256', 'pass789'), 2), 1000000, N'Đang mở'),
    (N'Phạm Văn Tuấn', 'tuan.pham@email.com', '0912000004', CONVERT(NCHAR(64), HASHBYTES('SHA2_256', 'passabc'), 2), 0, N'Chưa mở'),
    (N'Hoàng Minh Tâm', 'tam.hoang@email.com', '0912000005', CONVERT(NCHAR(64), HASHBYTES('SHA2_256', 'passxyz'), 2), 750000, N'Đang mở'),
    (N'Đỗ Thanh Sơn', 'son.do@email.com', '0912000006', CONVERT(NCHAR(64), HASHBYTES('SHA2_256', 'pass111'), 2), 300000, N'Bị khóa'),
    (N'Vũ Thị Lan', 'lan.vu@email.com', '0912000007', CONVERT(NCHAR(64), HASHBYTES('SHA2_256', 'pass222'), 2), 1500000, N'Đang mở'),
    (N'Ngô Văn Hải', 'hai.ngo@email.com', '0912000008', CONVERT(NCHAR(64), HASHBYTES('SHA2_256', 'pass333'), 2), 80000, N'Đang mở');
GO

-- ========================================
-- Users.Vehicles
-- ========================================
INSERT INTO Users.Vehicles (UserID, PlateNumber, Brand, Model, BatteryCapacity_kWh, ConnectorType)
VALUES
    (1, '29A-12345', N'VinFast', N'VF 8', 82.00, N'CCS'),
    (1, '29A-67890', N'VinFast', N'VF 5', 37.00, N'Type 2'),
    (2, '51G-54321', N'Tesla', N'Model 3', 60.00, N'CCS'),
    (3, '30F-98765', N'Hyundai', N'Ioniq 5', 58.00, N'CCS'),
    (4, '43H-11111', N'VinFast', N'VF 9', 92.00, N'CCS'),
    (5, '59B-22222', N'Porsche', N'Taycan', 79.00, N'CCS'),
    (6, '29V-33333', N'BMW', N'i4', 67.00, N'CCS'),
    (7, '51D-44444', N'VinFast', N'VF 7', 59.00, N'Type 2'),
    (8, '30K-55555', N'Kia', N'EV6', 58.00, N'CCS');
GO

-- ========================================
-- Operations.PricingPolicy
-- ========================================
INSERT INTO Operations.PricingPolicy (PolicyName, BasePrice_kWh, PeakHourMultiplier, AppliedFrom, AppliedTo)
VALUES
    (N'Giá tiêu chuẩn', 3500.0000, 1.00, '2024-01-01', '2025-12-31'),
    (N'Giá giờ cao điểm', 3500.0000, 1.50, '2024-01-01', '2025-12-31'),
    (N'Giá giờ thấp điểm', 3500.0000, 0.70, '2024-01-01', '2025-12-31'),
    (N'Khuyến mãi tháng 3', 3000.0000, 1.00, '2025-03-01', '2025-03-31'),
    (N'Gói thành viên VIP', 2800.0000, 1.00, '2025-01-01', '2025-12-31');
GO

-- ========================================
-- Operations.ChargingSession
-- ========================================
INSERT INTO Operations.ChargingSession (UserID, PointID, PolicyID, StartTime, EndTime, Total_kWh, CostTotal, Status)
VALUES
    (1, 2, 1, '2025-04-01 08:15:00', '2025-04-01 09:45:00', 35.5000, 124250, N'Đã sạc xong'),
    (2, 5, 1, '2025-04-01 10:00:00', '2025-04-01 11:20:00', 25.0000, 87500, N'Đã sạc xong'),
    (3, 13, 2, '2025-04-01 18:00:00', '2025-04-01 19:10:00', 40.0000, 210000, N'Đã sạc xong'),
    (5, 7, 1, '2025-04-02 09:30:00', '2025-04-02 10:50:00', 50.0000, 175000, N'Đã sạc xong'),
    (7, 18, 2, '2025-04-02 17:30:00', '2025-04-02 18:45:00', 30.0000, 157500, N'Đã sạc xong'),
    (1, 3, 3, '2025-04-03 23:00:00', '2025-04-04 01:30:00', 60.0000, 147000, N'Đã sạc xong'),
    (8, 22, 1, '2025-04-03 14:00:00', '2025-04-03 15:15:00', 22.0000, 77000, N'Đã sạc xong'),
    (3, 6, 1, '2025-04-04 11:00:00', '2025-04-04 12:30:00', 45.0000, 157500, N'Đã sạc xong'),
    (2, 14, 2, '2025-04-05 19:00:00', '2025-04-05 20:10:00', 28.0000, 147000, N'Đã sạc xong'),
    (5, 12, 1, '2025-04-06 07:00:00', '2025-04-06 08:20:00', 55.0000, 192500, N'Đã sạc xong');
GO

-- ========================================
-- Operations.Transactions
-- ========================================
INSERT INTO Operations.Transactions (UserID, SessionID, Amount, TransactionType, [Timestamp])
VALUES
    (1, 1, 124250, N'Thanh toán', '2025-04-01 09:45:00'),
    (2, 2, 87500,  N'Thanh toán', '2025-04-01 11:20:00'),
    (3, 3, 210000, N'Thanh toán', '2025-04-01 19:10:00'),
    (5, 4, 175000, N'Thanh toán', '2025-04-02 10:50:00'),
    (7, 5, 157500, N'Thanh toán', '2025-04-02 18:45:00'),
    (1, 6, 147000, N'Thanh toán', '2025-04-04 01:30:00'),
    (8, 7, 77000,  N'Thanh toán', '2025-04-03 15:15:00'),
    (3, 8, 157500, N'Thanh toán', '2025-04-04 12:30:00'),
    (2, 9, 147000, N'Thanh toán', '2025-04-05 20:10:00'),
    (5, 10, 192500, N'Thanh toán', '2025-04-06 08:20:00');
GO

-- ========================================
-- Monitoring.ErrorLogs
-- ========================================
INSERT INTO Monitoring.ErrorLogs (PointID, ErrorCode, Description, OccurredAt, ResolvedAt, Severity)
VALUES
    (8, N'ERR_001', N'Mất kết nối bộ sạc', '2025-03-15 10:30:00', '2025-03-15 11:00:00', N'Cao'),
    (9, N'ERR_002', N'Lỗi nguồn điện đầu vào', '2025-03-20 14:00:00', '2025-03-20 16:30:00', N'Cao'),
    (10, N'ERR_003', N'Cáp sạc bị hỏng', '2025-04-01 08:00:00', '2025-04-02 09:00:00', N'Trung bình'),
    (11, N'ERR_004', N'Lỗi phần mềm điều khiển', '2025-04-05 12:00:00', NULL, N'Thấp');
GO

-- ========================================
-- Monitoring.MaintenanceSchedule
-- ========================================
INSERT INTO Monitoring.MaintenanceSchedule (StationID, TechnicianName, PlannedDate, ActionTaken, Status)
VALUES
    (1, N'Nguyễn Văn Kỹ thuật', '2025-05-01 08:00:00', N'Kiểm tra tổng thể hệ thống điện', N'Đã lên lịch'),
    (3, N'Trần Văn Sửa chữa', '2025-05-05 09:00:00', N'Bảo dưỡng định kỳ bộ sạc CCS', N'Đã lên lịch'),
    (4, N'Lê Văn Bảo trì', '2025-05-10 10:00:00', N'Sửa chữa trạm, thay thế linh kiện', N'Đã lên lịch'),
    (5, N'Phạm Văn Kỹ thuật', '2025-05-15 08:00:00', N'Hiệu chuẩn thiết bị đo', N'Đã lên lịch'),
    (7, N'Hoàng Văn Sửa chữa', '2025-04-20 09:30:00', N'Vệ sinh và kiểm tra đầu nối', N'Hoàn thành');
GO

PRINT N'Seed data inserted successfully.';
GO
