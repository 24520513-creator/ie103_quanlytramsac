USE EV_Charging_System;
GO

DECLARE @Hash NVARCHAR(256) = N'$2a$12$DemoHashForIE103DatabaseOnly';

INSERT INTO Core.Country (CountryCode, CountryName, CurrencyCode, PhonePrefix)
VALUES (N'VN', N'Việt Nam', N'VND', N'+84');

DECLARE @VN INT = SCOPE_IDENTITY();

INSERT INTO Core.Region (CountryID, RegionCode, RegionName)
VALUES
(@VN, N'HCMC', N'TP. Hồ Chí Minh'),
(@VN, N'HAN', N'Hà Nội'),
(@VN, N'DN', N'Đà Nẵng');

DECLARE @HCMC INT = (SELECT RegionID FROM Core.Region WHERE RegionCode = N'HCMC');
DECLARE @HAN INT = (SELECT RegionID FROM Core.Region WHERE RegionCode = N'HAN');
DECLARE @DN INT = (SELECT RegionID FROM Core.Region WHERE RegionCode = N'DN');

INSERT INTO Core.Address (RegionID, StreetAddress, Ward, District, Latitude, Longitude)
VALUES
(@HCMC, N'123 Nguyễn Huệ', N'Bến Nghé', N'Quận 1', 10.7765, 106.7012),
(@HCMC, N'456 Lê Lợi', N'Bến Thành', N'Quận 1', 10.7711, 106.6984),
(@HCMC, N'100 Nguyễn Văn Linh', N'Tân Phong', N'Quận 7', 10.7312, 106.7222),
(@HAN, N'45 Tràng Tiền', N'Tràng Tiền', N'Hoàn Kiếm', 21.0278, 105.8522),
(@HAN, N'88 Xuân Thủy', N'Dịch Vọng Hậu', N'Cầu Giấy', 21.0353, 105.7838),
(@DN, N'78 Nguyễn Văn Linh', N'Hải Châu 1', N'Hải Châu', 16.0544, 108.2022),
(@DN, N'34 Lê Duẩn', N'Thạch Thang', N'Hải Châu', 16.0612, 108.2211);

INSERT INTO [Identity].Role (RoleCode, RoleName, Description)
VALUES
(N'SystemAdmin', N'Quản trị hệ thống', N'Toàn quyền cấu hình và dữ liệu'),
(N'OperationsStaff', N'Nhân viên vận hành', N'Quản lý trạm, cổng sạc, phiên sạc, telemetry, lỗi và bảo trì'),
(N'BusinessManager', N'Quản lý kinh doanh', N'Quản lý franchise, hợp đồng, chia doanh thu, thanh toán, invoice, refund'),
(N'Customer', N'Khách hàng', N'Chủ xe sử dụng dịch vụ sạc, ví, thanh toán và lịch sử');

INSERT INTO [Identity].Permission (PermissionCode, PermissionName, ModuleName)
VALUES
(N'STATION.READ', N'Xem trạm sạc', N'Infrastructure'),
(N'STATION.WRITE', N'Sửa trạm sạc', N'Infrastructure'),
(N'SESSION.OPERATE', N'Vận hành phiên sạc', N'Operations'),
(N'PAYMENT.MANAGE', N'Quản lý thanh toán', N'Payments'),
(N'FRANCHISE.MANAGE', N'Quản lý nhượng quyền', N'Franchise'),
(N'MAINTENANCE.MANAGE', N'Quản lý bảo trì', N'Maintenance'),
(N'REPORT.VIEW', N'Xem báo cáo', N'Reporting'),
(N'AUDIT.VIEW', N'Xem audit log', N'Audit');

INSERT INTO [Identity].RolePermission (RoleID, PermissionID)
SELECT r.RoleID, p.PermissionID
FROM [Identity].Role r
JOIN [Identity].Permission p ON
    r.RoleCode = N'SystemAdmin'
 OR (r.RoleCode = N'OperationsStaff' AND p.PermissionCode IN (N'STATION.READ', N'STATION.WRITE', N'SESSION.OPERATE', N'MAINTENANCE.MANAGE', N'REPORT.VIEW'))
 OR (r.RoleCode = N'BusinessManager' AND p.PermissionCode IN (N'FRANCHISE.MANAGE', N'PAYMENT.MANAGE', N'REPORT.VIEW'))
 OR (r.RoleCode = N'Customer' AND p.PermissionCode IN (N'STATION.READ', N'SESSION.OPERATE', N'PAYMENT.MANAGE'));

INSERT INTO [Identity].UserAccount (Username, Email, Phone, PasswordHash, FullName)
VALUES
(N'admin01', N'admin01@gmail.com', N'0901000001', @Hash, N'Quản trị hệ thống'),
(N'operator01', N'operator01@gmail.com', N'0901000002', @Hash, N'Nhân viên vận hành'),
(N'business01', N'business01@gmail.com', N'0901000003', @Hash, N'Quản lý kinh doanh'),
(N'customer01', N'customer01@gmail.com', N'0902000001', @Hash, N'Nguyễn Văn An'),
(N'customer02', N'customer02@gmail.com', N'0902000002', @Hash, N'Trần Thị Bình'),
(N'customer03', N'customer03@gmail.com', N'0902000003', @Hash, N'Lê Minh Cường'),
(N'customer04', N'customer04@gmail.com', N'0902000004', @Hash, N'Phạm Thị Dung'),
(N'customer05', N'customer05@gmail.com', N'0902000005', @Hash, N'Hoàng Quốc Hải');

INSERT INTO [Identity].UserRole (UserID, RoleID)
SELECT u.UserID, r.RoleID
FROM [Identity].UserAccount u
JOIN [Identity].Role r ON r.RoleCode =
    CASE u.Username
        WHEN N'admin01' THEN N'SystemAdmin'
        WHEN N'operator01' THEN N'OperationsStaff'
        WHEN N'business01' THEN N'BusinessManager'
        ELSE N'Customer'
    END;

INSERT INTO [Identity].CustomerProfile (UserID)
SELECT UserID FROM [Identity].UserAccount WHERE Username LIKE N'customer%';

INSERT INTO [Identity].StaffProfile (UserID, EmployeeCode, Department, ManagedRegionID)
SELECT UserID,
       N'EMP-' + RIGHT(N'000' + CAST(UserID AS NVARCHAR(10)), 3),
       CASE Username
           WHEN N'operator01' THEN N'Operations'
           WHEN N'business01' THEN N'Business'
           ELSE N'Administration'
       END,
       @HCMC
FROM [Identity].UserAccount
WHERE Username NOT LIKE N'customer%';

INSERT INTO Payments.PaymentMethod (MethodCode, MethodName, IsOnline)
VALUES
(N'WALLET', N'Ví điện tử nội bộ', 1),
(N'QR', N'Thanh toán QR ngân hàng', 1),
(N'CASH', N'Tiền mặt tại quầy', 0);

INSERT INTO Payments.Wallet (UserID, WalletCode, Balance)
SELECT UserID, N'WAL-' + Username,
       CASE WHEN Username LIKE N'customer%' THEN 3000000 ELSE 1000000 END
FROM [Identity].UserAccount;

INSERT INTO Franchise.FranchisePartner
    (FranchiseCode, FranchiseName, TaxCode, AddressID, ContactUserID, ContactPerson, ContactPhone, ContactEmail)
VALUES
(N'VFSG', N'VinFast Sài Gòn', N'VFSG2026001', 1, (SELECT UserID FROM [Identity].UserAccount WHERE Username = N'business01'), N'Nguyễn Văn Đối Tác', N'0911111111', N'partner-sg@ev.vn'),
(N'EVN-DN', N'EVN Đà Nẵng', N'EVNDN2026001', 6, NULL, N'Lê Văn Đối Tác', N'0922222222', N'partner-dn@ev.vn');

INSERT INTO Franchise.FranchiseContract (FranchiseID, ContractCode, StartDate, EndDate, BaseRevenueShareRate, ContractStatus)
VALUES
((SELECT FranchiseID FROM Franchise.FranchisePartner WHERE FranchiseCode = N'VFSG'), N'FC-VFSG-2026', '2026-01-01', '2028-12-31', 72.00, N'Active'),
((SELECT FranchiseID FROM Franchise.FranchisePartner WHERE FranchiseCode = N'EVN-DN'), N'FC-EVNDN-2026', '2026-01-01', '2027-12-31', 68.00, N'Active');

INSERT INTO Franchise.RevenueSharePolicy (ContractID, PolicyCode, PartnerShareRate, AppliedFrom)
SELECT ContractID, N'RSP-' + ContractCode, BaseRevenueShareRate, StartDate
FROM Franchise.FranchiseContract;

INSERT INTO Infrastructure.ElectricitySupplier (SupplierCode, SupplierName, RegionID, UnitPricePerKWh)
VALUES
(N'EVN-HCMC', N'Điện lực TP. Hồ Chí Minh', @HCMC, 2100),
(N'EVN-HAN', N'Điện lực Hà Nội', @HAN, 2050),
(N'EVN-DN', N'Điện lực Đà Nẵng', @DN, 2000);

INSERT INTO Infrastructure.ConnectorType (ConnectorCode, ConnectorName, MaxPowerKW)
VALUES
(N'CCS2', N'Combined Charging System Type 2', 350),
(N'CHAdeMO', N'CHAdeMO DC', 100),
(N'Type2', N'AC Type 2', 43);

DECLARE @VFSG INT = (SELECT FranchiseID FROM Franchise.FranchisePartner WHERE FranchiseCode = N'VFSG');
DECLARE @EVNDN INT = (SELECT FranchiseID FROM Franchise.FranchisePartner WHERE FranchiseCode = N'EVN-DN');
DECLARE @Operator INT = (SELECT UserID FROM [Identity].UserAccount WHERE Username = N'operator01');

INSERT INTO Infrastructure.ChargingStation
    (StationCode, StationName, FranchiseID, AddressID, SupplierID, StationOperatorID, ModelName, Manufacturer, MaxPowerKW, StationStatus, OpenedAt)
VALUES
(N'VFSG-01', N'Trạm sạc VinFast Nguyễn Huệ', @VFSG, 1, 1, @Operator, N'VF DC 150', N'VinFast', 150, N'Active', '2026-01-10'),
(N'VFSG-02', N'Trạm sạc VinFast Lê Lợi', @VFSG, 2, 1, @Operator, N'VF DC 60', N'VinFast', 60, N'Active', '2026-01-12'),
(N'VFSG-03', N'Trạm sạc VinFast Quận 7', @VFSG, 3, 1, @Operator, N'VF DC 150', N'VinFast', 150, N'Active', '2026-02-01'),
(N'EVNDN-01', N'Trạm sạc EVN Hải Châu', @EVNDN, 6, 3, @Operator, N'ABB Terra 54', N'ABB', 50, N'Active', '2026-02-15'),
(N'EVNDN-02', N'Trạm sạc EVN Lê Duẩn', @EVNDN, 7, 3, @Operator, N'ABB Terra 54', N'ABB', 50, N'UnderMaintenance', '2026-03-01');

INSERT INTO Franchise.FranchiseStation (FranchiseID, StationID, ContractID)
SELECT s.FranchiseID, s.StationID, fc.ContractID
FROM Infrastructure.ChargingStation s
JOIN Franchise.FranchiseContract fc ON fc.FranchiseID = s.FranchiseID AND fc.ContractStatus = N'Active';

DECLARE @CCS2 INT = (SELECT ConnectorTypeID FROM Infrastructure.ConnectorType WHERE ConnectorCode = N'CCS2');
DECLARE @CHA INT = (SELECT ConnectorTypeID FROM Infrastructure.ConnectorType WHERE ConnectorCode = N'CHAdeMO');
DECLARE @T2 INT = (SELECT ConnectorTypeID FROM Infrastructure.ConnectorType WHERE ConnectorCode = N'Type2');

INSERT INTO Infrastructure.StationConnectorType (StationID, ConnectorTypeID)
SELECT StationID, @CCS2 FROM Infrastructure.ChargingStation
UNION ALL SELECT StationID, @T2 FROM Infrastructure.ChargingStation
UNION ALL SELECT StationID, @CHA FROM Infrastructure.ChargingStation WHERE StationCode IN (N'VFSG-01', N'VFSG-03');

DECLARE @StationID INT = 1;
WHILE @StationID <= 5
BEGIN
    INSERT INTO Infrastructure.ChargingPoint (PointCode, StationID, ConnectorTypeID, PowerKW, SerialNumber, PointStatus, HealthStatus)
    VALUES
    (N'P-' + CAST(@StationID AS NVARCHAR(10)) + N'-A', @StationID, @CCS2, CASE WHEN @StationID <= 3 THEN 120 ELSE 50 END, N'SN-' + CAST(@StationID AS NVARCHAR(10)) + N'-A', N'Available', N'Normal'),
    (N'P-' + CAST(@StationID AS NVARCHAR(10)) + N'-B', @StationID, @T2, 22, N'SN-' + CAST(@StationID AS NVARCHAR(10)) + N'-B', N'Available', N'Normal'),
    (N'P-' + CAST(@StationID AS NVARCHAR(10)) + N'-C', @StationID, CASE WHEN @StationID IN (1,3) THEN @CHA ELSE @CCS2 END, 60, N'SN-' + CAST(@StationID AS NVARCHAR(10)) + N'-C',
     CASE WHEN @StationID = 5 THEN N'Maintenance' ELSE N'Available' END,
     CASE WHEN @StationID = 5 THEN N'Warning' ELSE N'Normal' END);
    SET @StationID += 1;
END;

INSERT INTO Operations.PricingPolicy (PolicyCode, PolicyName, BasePricePerKWh, PeakMultiplier, PeakStartHour, PeakEndHour, AppliedFrom)
VALUES
(N'STD-2026', N'Giá tiêu chuẩn 2026', 3500, 1.25, '17:00', '20:00', '2026-01-01'),
(N'NIGHT-2026', N'Giá đêm khuyến khích', 2800, 1.00, NULL, NULL, '2026-01-01');

INSERT INTO Operations.Vehicle (UserID, PlateNumber, Brand, Model, BatteryCapacityKWh, PreferredConnectorTypeID)
SELECT UserID,
       N'EV-' + RIGHT(N'000' + CAST(ROW_NUMBER() OVER (ORDER BY UserID) AS NVARCHAR(10)), 3),
       CASE WHEN UserID % 2 = 0 THEN N'VinFast' ELSE N'Tesla' END,
       CASE WHEN UserID % 2 = 0 THEN N'VF e34' ELSE N'Model 3' END,
       CASE WHEN UserID % 2 = 0 THEN 42 ELSE 75 END,
       @CCS2
FROM [Identity].UserAccount
WHERE Username LIKE N'customer%';

DECLARE @i INT = 1;
WHILE @i <= 40
BEGIN
    DECLARE @CustomerID INT = (SELECT UserID FROM [Identity].UserAccount WHERE Username = N'customer0' + CAST(((@i - 1) % 5) + 1 AS NVARCHAR(1)));
    DECLARE @VehicleID INT = (SELECT TOP 1 VehicleID FROM Operations.Vehicle WHERE UserID = @CustomerID);
    DECLARE @PointID INT = ((@i - 1) % 12) + 1;
    DECLARE @StationForPoint INT = (SELECT StationID FROM Infrastructure.ChargingPoint WHERE PointID = @PointID);
    DECLARE @Start DATETIME2 = DATEADD(HOUR, 7 + (@i % 12), DATEADD(DAY, -(@i % 20), CAST('2026-05-13' AS DATETIME2)));
    DECLARE @KWh DECIMAL(14,4) = 12 + (@i % 25);
    DECLARE @PolicyID INT = 1;
    DECLARE @BaseCost DECIMAL(19,4) = Operations.fn_CalculateChargingCost(@KWh, @PolicyID, @Start);
    DECLARE @Tax DECIMAL(19,4) = ROUND(@BaseCost * 0.08, 4);

    INSERT INTO Operations.ChargingSession
        (SessionCode, UserID, VehicleID, StationID, PointID, PolicyID, StartTime, EndTime, MeterStart, MeterEnd, TotalKWh, DurationMinutes, CostBeforeTax, TaxAmount, CostTotal, SessionStatus, StopReason)
    VALUES
        (N'SES-DEMO-' + RIGHT(N'000' + CAST(@i AS NVARCHAR(10)), 3), @CustomerID, @VehicleID, @StationForPoint, @PointID, @PolicyID,
         @Start, DATEADD(MINUTE, 35 + (@i % 50), @Start), 1000 + @i * 10, 1000 + @i * 10 + @KWh, @KWh, 35 + (@i % 50),
         @BaseCost, @Tax, @BaseCost + @Tax, N'Completed', N'Completed');

    SET @i += 1;
END;

DECLARE @WalletMethod INT = (SELECT PaymentMethodID FROM Payments.PaymentMethod WHERE MethodCode = N'WALLET');
DECLARE @QRMethod INT = (SELECT PaymentMethodID FROM Payments.PaymentMethod WHERE MethodCode = N'QR');

INSERT INTO Payments.PaymentTransaction
    (TransactionCode, UserID, SessionID, PaymentMethodID, TransactionType, Direction, Amount, TransactionStatus, ProviderReference, SettledAt)
SELECT N'TXN-DEMO-' + RIGHT(N'000' + CAST(SessionID AS NVARCHAR(10)), 3),
       UserID, SessionID,
       CASE WHEN SessionID % 4 = 0 THEN @QRMethod ELSE @WalletMethod END,
       N'ChargingPayment', N'D', CostTotal, N'Completed',
       CASE WHEN SessionID % 4 = 0 THEN N'QRBANK-' + CAST(SessionID AS NVARCHAR(20)) ELSE NULL END,
       EndTime
FROM Operations.ChargingSession;

INSERT INTO Payments.WalletTransaction (WalletID, TransactionID, Amount, BalanceBefore, Direction, Description)
SELECT w.WalletID, pt.TransactionID, -pt.Amount, w.Balance, N'D', N'Thanh toán phiên sạc'
FROM Payments.PaymentTransaction pt
JOIN Payments.Wallet w ON w.UserID = pt.UserID
WHERE pt.PaymentMethodID = @WalletMethod;

UPDATE w
SET Balance = Balance - x.PaidAmount,
    LastTransactionAt = SYSDATETIME()
FROM Payments.Wallet w
JOIN (
    SELECT UserID, SUM(Amount) AS PaidAmount
    FROM Payments.PaymentTransaction
    WHERE PaymentMethodID = @WalletMethod
    GROUP BY UserID
) x ON x.UserID = w.UserID;

INSERT INTO Payments.Invoice (InvoiceCode, UserID, SessionID, TransactionID, Subtotal, TaxAmount, TotalAmount, InvoiceStatus, IssuedAt)
SELECT N'INV-DEMO-' + RIGHT(N'000' + CAST(cs.SessionID AS NVARCHAR(10)), 3),
       cs.UserID, cs.SessionID, pt.TransactionID, cs.CostBeforeTax, cs.TaxAmount, cs.CostTotal, N'Paid', cs.EndTime
FROM Operations.ChargingSession cs
JOIN Payments.PaymentTransaction pt ON pt.SessionID = cs.SessionID;

INSERT INTO Payments.QRPaymentRequest (RequestCode, UserID, SessionID, Amount, QRPayload, RequestStatus, ExpiresAt, TransactionID)
SELECT N'QR-DEMO-' + RIGHT(N'000' + CAST(pt.TransactionID AS NVARCHAR(10)), 3),
       pt.UserID, pt.SessionID, pt.Amount, N'vietqr://demo/' + pt.TransactionCode, N'Paid', DATEADD(MINUTE, 15, pt.TransactedAt), pt.TransactionID
FROM Payments.PaymentTransaction pt
WHERE pt.PaymentMethodID = @QRMethod;

DECLARE @RefundOriginal BIGINT = (SELECT TOP 1 TransactionID FROM Payments.PaymentTransaction WHERE TransactionType = N'ChargingPayment' ORDER BY TransactionID);
EXEC Payments.sp_ProcessRefund @OriginalTransactionID = @RefundOriginal, @Amount = 20000, @Reason = N'Hoàn tiền khuyến mại demo';

INSERT INTO Maintenance.ErrorCatalog (ErrorCode, ErrorName, DefaultSeverity, Description)
VALUES
(N'E-CONNECT', N'Lỗi kết nối thiết bị', N'High', N'Mất kết nối OCPP hoặc thiết bị'),
(N'E-TEMP', N'Nhiệt độ cao', N'Medium', N'Cảnh báo nhiệt độ cổng sạc'),
(N'E-POWER', N'Lỗi công suất', N'Critical', N'Dòng điện/công suất bất thường');

INSERT INTO Infrastructure.PointTelemetry (PointID, Voltage, CurrentAmp, TemperatureC, PowerKW, HealthStatus, RecordedAt)
SELECT PointID, 380 + PointID, 60 + PointID, 31 + (PointID % 12), PowerKW * 0.70,
       CASE WHEN PointID IN (5, 15) THEN N'Warning' WHEN PointID = 14 THEN N'Critical' ELSE N'Normal' END,
       DATEADD(MINUTE, -PointID * 3, SYSDATETIME())
FROM Infrastructure.ChargingPoint;

EXEC Maintenance.sp_ReportError
    @ErrorCode = N'E-TEMP',
    @StationID = 5,
    @PointID = 15,
    @Description = N'Nhiệt độ cổng sạc vượt ngưỡng trong giờ cao điểm',
    @CreatedBy = @Operator;

DECLARE @TicketID BIGINT = (SELECT TOP 1 TicketID FROM Maintenance.MaintenanceTicket ORDER BY TicketID DESC);
DECLARE @Technician INT = (SELECT UserID FROM [Identity].UserAccount WHERE Username = N'operator01');
EXEC Maintenance.sp_AssignTicket @TicketID = @TicketID, @TechnicianUserID = @Technician, @AssignedBy = @Operator;

DECLARE @StartPeriod DATE = '2026-05-01';
DECLARE @EndPeriod DATE = '2026-05-31';
EXEC Franchise.sp_CreateRevenueSettlement @FranchiseID = @VFSG, @PeriodStart = @StartPeriod, @PeriodEnd = @EndPeriod;
EXEC Franchise.sp_CreateRevenueSettlement @FranchiseID = @EVNDN, @PeriodStart = @StartPeriod, @PeriodEnd = @EndPeriod;

PRINT N'09 - Demo data seeded.';
GO
