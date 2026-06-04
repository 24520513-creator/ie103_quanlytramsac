# Chương 4 — Cài đặt các đối tượng cơ sở dữ liệu (Database Objects)

> Phân tích nguồn: thư mục `database/` của hệ thống **EV_Charging_System** (SQL Server 2022).
> Tài liệu này liệt kê **Stored Procedure, Function, Trigger, View/Reporting Procedure, Security, Backup/Restore**.
> Phần thiết kế bảng/khóa/index thuộc Chương 2–3, không lặp lại ở đây.

Quy ước demo (theo seed `09_Seed_Demo_Data.sql` + `08_Create_Security.sql`):
- Database user demo: `admin01`, `operator01`, `business01`, `customer01`, `franchise01..08` (đều `WITHOUT LOGIN`, test bằng `EXECUTE AS USER`).
- App user tương ứng trong `Identity.UserAccount`: `customer01`, `operator01`, `business01`, `franchise01`, `admin01` (mật khẩu hash của `password`).
- Nhiều SP và view lọc dữ liệu theo `SESSION_CONTEXT(N'UserID')` / `SESSION_CONTEXT(N'RoleCode')` do backend set khi đăng nhập. Khi test thuần SQL bằng `EXECUTE AS USER`, cơ chế lọc dựa vào `IS_ROLEMEMBER(...)` vẫn hoạt động.

---

## 0. Bảng tổng hợp toàn bộ đối tượng

| Nhóm | Số lượng | File nguồn |
|---|---|---|
| Function (UDF) | 3 | `database/04_Create_Functions.sql` |
| Stored Procedure nghiệp vụ | 33 | `database/05_Create_Stored_Procedures.sql` |
| Trigger | 15 | `database/06_Create_Triggers.sql` |
| View (AppView) | 53 | `database/07_Create_AppViews.sql` |
| Reporting Procedure (AppView) | 12 | `database/07_Create_AppViews.sql` (+ `sp_ActivatePricingPolicy` ở 05) |
| Database Role | 5 | `database/08_Create_Security.sql` |
| User demo | 13 | `database/08_Create_Security.sql` |
| Advanced Security (Masking) | 3 cột mask | `database/09_Advanced_Security.sql` |
| Backup/Restore demo | 2 script | `database/12_Backup_Restore.sql`, `features/system_admin/07_backup_restore_demo.sql` |

---

# 1. STORED PROCEDURE

Tất cả SP nghiệp vụ nằm trong `database/05_Create_Stored_Procedures.sql`. **Toàn bộ đều dùng `SET XACT_ABORT ON` + `BEGIN TRAN ... COMMIT` + `TRY/CATCH` + `THROW`** (trừ `sp_RequestPasswordReset` chỉ ghi log, không transaction). Mọi SP ghi `Audit.AuditLog` đều kích hoạt thêm trigger audit tương ứng.

## 1.1 Bảng tổng hợp Stored Procedure

| # | Tên đầy đủ | Schema | Mục đích nghiệp vụ | Transaction/TryCatch/THROW |
|---|---|---|---|---|
| 1 | `Identity.sp_CreateUser` | Identity | Admin tạo user + gán role | ✔/✔/✔ |
| 2 | `Identity.sp_RegisterCustomer` | Identity | Khách tự đăng ký (role Customer) | ✔/✔/✔ |
| 3 | `Identity.sp_RequestPasswordReset` | Identity | Sinh token reset mật khẩu | ✘/✘/✘ (chỉ log) |
| 4 | `Identity.sp_ResetPasswordByToken` | Identity | Đổi mật khẩu bằng token | ✔/✔/✔ |
| 5 | `Identity.sp_VerifyEmailToken` | Identity | Kích hoạt tài khoản qua token email | ✔/✔/✔ |
| 6 | `Identity.sp_LockUser` | Identity | Khóa tài khoản | ✔/✔/✔ |
| 7 | `Identity.sp_UnlockUser` | Identity | Mở khóa tài khoản | ✔/✔/✔ |
| 8 | `Identity.sp_ResetPassword` | Identity | Admin reset mật khẩu theo UserID | ✔/✔/✔ |
| 9 | `Identity.sp_AssignRole` | Identity | Gán role cho user | ✔/✔/✔ |
| 10 | `Identity.sp_RemoveRole` | Identity | Gỡ role khỏi user | ✔/✔/✔ |
| 11 | `Infrastructure.sp_CreateChargingStation` | Infrastructure | Tạo trạm sạc | ✔/✔/✔ |
| 12 | `Infrastructure.sp_CreateChargingPoint` | Infrastructure | Tạo cổng sạc + map connector | ✔/✔/✔ |
| 13 | `Infrastructure.sp_UpdateStationStatus` | Infrastructure | Đổi trạng thái trạm | ✔/✔/✔ |
| 14 | `Infrastructure.sp_UpdateChargingPointStatus` | Infrastructure | Đổi trạng thái + sức khỏe cổng | ✔/✔/✔ |
| 15 | `Operations.sp_CreateVehicle` | Operations | Khách thêm xe điện | ✔/✔/✔ |
| 16 | `Operations.sp_UpdateVehicle` | Operations | Cập nhật xe | ✔/✔/✔ |
| 17 | `Operations.sp_CreateBooking` | Operations | Đặt chỗ cổng sạc (chống trùng giờ) | ✔/✔/✔ |
| 18 | `Operations.sp_CancelBooking` | Operations | Hủy đặt chỗ | ✔/✔/✔ |
| 19 | `Operations.sp_StartChargingSession` | Operations | Bắt đầu phiên sạc | ✔/✔/✔ |
| 20 | `Operations.sp_EndChargingSession` | Operations | Kết thúc phiên, tính tiền + thuế | ✔/✔/✔ |
| 21 | `Operations.sp_MarkChargingSessionFailed` | Operations | Đánh dấu phiên sạc thất bại | ✔/✔/✔ |
| 22 | `Payments.sp_CreatePayment` | Payments | Thanh toán phiên sạc | ✔/✔/✔ |
| 23 | `Payments.sp_RefundPayment` | Payments | Hoàn tiền giao dịch | ✔/✔/✔ |
| 24 | `Payments.sp_CreateInvoice` | Payments | Xuất hóa đơn | ✔/✔/✔ |
| 25 | `Operations.sp_CreatePricingPolicy` | Operations | Tạo chính sách giá | ✔/✔/✔ |
| 26 | `Operations.sp_DeactivatePricingPolicy` | Operations | Vô hiệu chính sách giá | ✔/✔/✔ |
| 27 | `Maintenance.sp_ReportError` | Maintenance | Báo lỗi + tự tạo ticket | ✔/✔/✔ |
| 28 | `Maintenance.sp_AssignTicket` | Maintenance | Phân công ticket | ✔/✔/✔ |
| 29 | `Maintenance.sp_ScheduleMaintenance` | Maintenance | Lên lịch bảo trì | ✔/✔/✔ |
| 30 | `Maintenance.sp_CloseTicket` | Maintenance | Đóng ticket + phục hồi cổng | ✔/✔/✔ |
| 31 | `Franchise.sp_UpdateRevenueSharePolicy` | Franchise | Cập nhật tỉ lệ chia doanh thu | ✔/✔/✔ |
| 32 | `Franchise.sp_CreateRevenueSettlement` | Franchise | Quyết toán doanh thu đối tác | ✔/✔/✔ |
| 33 | `AppView.sp_ActivatePricingPolicy` | AppView | Kích hoạt lại chính sách giá (web action) | ✔/✔/✔ |

## 1.2 Chi tiết từng Stored Procedure

> File nguồn chung: `database/05_Create_Stored_Procedures.sql`.

### (1) `Identity.sp_CreateUser`
- **Mục đích:** Admin tạo tài khoản mới và gán 1 role theo `RoleCode`.
- **Input:** `@Username, @Email, @Phone=NULL, @PasswordHash, @FullName, @RoleCode`.
- **Output:** result set `UserID, Username, Email, FullName, AccountStatus`.
- **Liên quan:** `Identity.Role`, `Identity.UserAccount`, `Identity.UserRole`, `Audit.AuditLog`; kích hoạt trigger `trg_UserAccount_Audit`, `trg_UserRole_Audit`.
- **THROW:** 51001 nếu role không tồn tại.
- **Demo EXEC:**
```sql
EXEC [Identity].sp_CreateUser
     @Username = N'tech01', @Email = N'tech01@ev.vn', @Phone = N'0900000001',
     @PasswordHash = N'$2a$10$demohash', @FullName = N'Kỹ Thuật 01',
     @RoleCode = N'OperationsStaff';
```
- **SELECT kiểm tra:**
```sql
SELECT UserID, Username, AccountStatus FROM [Identity].UserAccount WHERE Username = N'tech01';
SELECT * FROM AppView.vw_UserRoleSummary WHERE Username = N'tech01';
```

### (2) `Identity.sp_RegisterCustomer`
- **Mục đích:** Khách tự đăng ký, mặc định role `Customer`, status `Active`, ghi `AuthEvent`.
- **Input:** `@Username, @Email, @Phone=NULL, @PasswordHash, @FullName`.
- **Output:** `UserID, Username, Email, Phone, FullName, AccountStatus`.
- **Liên quan:** `Identity.UserAccount/Role/UserRole/AuthEvent`, `Audit.AuditLog`.
- **THROW:** 51101 trùng username, 51102 trùng email, 51103 trùng phone, 51104 thiếu role Customer.
- **Demo EXEC:**
```sql
EXEC [Identity].sp_RegisterCustomer
     @Username=N'kh_demo', @Email=N'kh_demo@gmail.com', @Phone=N'0911222333',
     @PasswordHash=N'$2a$10$demohash', @FullName=N'Khách Demo';
```
- **SELECT kiểm tra:** `SELECT * FROM AppView.vw_UserRoleSummary WHERE Username=N'kh_demo';`

### (3) `Identity.sp_RequestPasswordReset`
- **Mục đích:** Tìm user theo username/email/phone, sinh token `PasswordReset` trong `AuthToken`. Không lộ việc user tồn tại hay không (ghi `Ignored` nếu không thấy).
- **Input:** `@Identifier, @TokenHash, @ExpiresAt`.
- **Output:** `UserID` (NULL nếu không tìm thấy).
- **Liên quan:** `Identity.UserAccount/AuthToken/AuthEvent`.
- **Transaction:** không (chỉ ghi log/token).
- **Demo EXEC:**
```sql
EXEC [Identity].sp_RequestPasswordReset
     @Identifier=N'customer01@gmail.com',
     @TokenHash=N'reset-token-hash-demo',
     @ExpiresAt = DATEADD(HOUR,1,SYSDATETIME());
```
- **SELECT kiểm tra:** `SELECT TOP 5 * FROM [Identity].AuthToken ORDER BY TokenID DESC;`

### (4) `Identity.sp_ResetPasswordByToken`
- **Mục đích:** Đổi mật khẩu khi token hợp lệ + chưa dùng + chưa hết hạn (dùng `UPDLOCK,HOLDLOCK` chống race).
- **Input:** `@TokenHash, @PasswordHash`.
- **Output:** `UserID, Username, Email, AccountStatus, UpdatedAt`.
- **THROW:** 51110 token không hợp lệ/hết hạn.
- **Demo EXEC:** `EXEC [Identity].sp_ResetPasswordByToken @TokenHash=N'reset-token-hash-demo', @PasswordHash=N'$2a$10$newhash';`
- **SELECT kiểm tra:** `SELECT ConsumedAt FROM [Identity].AuthToken WHERE TokenHash=N'reset-token-hash-demo';`

### (5) `Identity.sp_VerifyEmailToken`
- **Mục đích:** Token `EmailVerification` hợp lệ → chuyển `AccountStatus` từ `Pending` sang `Active`.
- **Input:** `@TokenHash`. **Output:** `UserID, Username, Email, AccountStatus`. **THROW:** 51111.
- **Demo EXEC:** `EXEC [Identity].sp_VerifyEmailToken @TokenHash=N'email-token-hash-demo';`

### (6) `Identity.sp_LockUser` / (7) `Identity.sp_UnlockUser`
- **Mục đích:** Đổi `AccountStatus` thành `Locked` / `Active`.
- **Input:** `@UserID`. **Output:** `UserID, Username, Email, AccountStatus`. **THROW:** 51010 / 51011.
- **Demo EXEC:**
```sql
DECLARE @uid INT = (SELECT UserID FROM [Identity].UserAccount WHERE Username=N'customer01');
EXEC [Identity].sp_LockUser   @UserID=@uid;
EXEC [Identity].sp_UnlockUser @UserID=@uid;
```
- **SELECT kiểm tra:** `SELECT AccountStatus FROM [Identity].UserAccount WHERE Username=N'customer01';`

### (8) `Identity.sp_ResetPassword`
- **Mục đích:** Admin đặt lại mật khẩu theo `UserID`.
- **Input:** `@UserID, @PasswordHash`. **THROW:** 51012.
- **Demo EXEC:** `EXEC [Identity].sp_ResetPassword @UserID=1, @PasswordHash=N'$2a$10$resethash';`

### (9) `Identity.sp_AssignRole` / (10) `Identity.sp_RemoveRole`
- **Mục đích:** Thêm/gỡ liên kết `UserRole`. **Input:** `@UserID, @RoleCode`.
- **Output:** danh sách role hiện tại của user. **THROW:** 51013/51014 (assign), 51015 (remove).
- **Demo EXEC:**
```sql
EXEC [Identity].sp_AssignRole @UserID=1, @RoleCode=N'BusinessManager';
EXEC [Identity].sp_RemoveRole @UserID=1, @RoleCode=N'BusinessManager';
```
- **SELECT kiểm tra:** `SELECT * FROM AppView.vw_UserRoleSummary WHERE UserID=1;`

### (11) `Infrastructure.sp_CreateChargingStation`
- **Mục đích:** Tạo trạm sạc mới (status `Active`).
- **Input:** `@StationCode, @StationName, @FranchiseID, @AddressID, @SupplierID=NULL, @StationOperatorID=NULL, @MaxPowerKW`.
- **Output:** `StationID, StationCode, StationName, StationStatus`.
- **Liên quan:** `Infrastructure.ChargingStation`, `Audit.AuditLog`.
- **Demo EXEC:**
```sql
DECLARE @addr INT = (SELECT TOP 1 AddressID FROM Core.Address ORDER BY AddressID);
DECLARE @fr INT = (SELECT TOP 1 FranchiseID FROM Franchise.FranchisePartner ORDER BY FranchiseID);
EXEC Infrastructure.sp_CreateChargingStation
     @StationCode=N'ST-DEMO', @StationName=N'Trạm Demo', @FranchiseID=@fr,
     @AddressID=@addr, @MaxPowerKW=120.00;
```
- **SELECT kiểm tra:** `SELECT * FROM AppView.vw_WebLookupStations WHERE StationCode=N'ST-DEMO';`

### (12) `Infrastructure.sp_CreateChargingPoint`
- **Mục đích:** Tạo cổng sạc; nếu trạm chưa có connector type thì thêm vào `StationConnectorType`.
- **Input:** `@PointCode, @StationID, @ConnectorTypeID, @PowerKW, @SerialNumber=NULL`.
- **Output:** `PointID, PointCode, StationID, ConnectorTypeID, PowerKW, PointStatus`.
- **Demo EXEC:**
```sql
DECLARE @sid INT = (SELECT TOP 1 StationID FROM Infrastructure.ChargingStation ORDER BY StationID);
DECLARE @ct INT = (SELECT TOP 1 ConnectorTypeID FROM Infrastructure.ConnectorType);
EXEC Infrastructure.sp_CreateChargingPoint @PointCode=N'PT-DEMO', @StationID=@sid, @ConnectorTypeID=@ct, @PowerKW=60.00;
```
- **SELECT kiểm tra:** `SELECT * FROM AppView.vw_WebLookupPoints WHERE PointCode=N'PT-DEMO';`

### (13) `Infrastructure.sp_UpdateStationStatus`
- **Mục đích:** Đổi trạng thái trạm (`Active/Inactive/UnderMaintenance/Retired`).
- **Input:** `@StationID, @StationStatus, @ChangedBy=NULL`. **THROW:** 51020 status sai, 51021 trạm không tồn tại.
- **Demo EXEC:** `EXEC Infrastructure.sp_UpdateStationStatus @StationID=1, @StationStatus=N'UnderMaintenance';`
- **SELECT kiểm tra:** `SELECT StationStatus FROM Infrastructure.ChargingStation WHERE StationID=1;`

### (14) `Infrastructure.sp_UpdateChargingPointStatus`
- **Mục đích:** Đổi `PointStatus` + tùy chọn `HealthStatus`. **THROW:** 51030/51031/51032.
- **Input:** `@PointID, @PointStatus, @HealthStatus=NULL, @ChangedBy=NULL`.
- **Lưu ý:** Việc UPDATE này kích hoạt trigger `trg_ChargingPoint_StatusHistory` ghi lịch sử.
- **Demo EXEC:** `EXEC Infrastructure.sp_UpdateChargingPointStatus @PointID=1, @PointStatus=N'Maintenance', @HealthStatus=N'Warning';`
- **SELECT kiểm tra:** `SELECT TOP 5 * FROM Infrastructure.PointStatusHistory WHERE PointID=1 ORDER BY ChangedAt DESC;`

### (15) `Operations.sp_CreateVehicle`
- **Mục đích:** Khách thêm xe điện; kiểm soát Customer chỉ tạo cho chính mình (SESSION_CONTEXT).
- **Input:** `@UserID, @PlateNumber, @Brand, @Model, @BatteryCapacityKWh=NULL, @PreferredConnectorTypeID=NULL`.
- **Output:** thông tin xe vừa tạo. **THROW:** 52022 (sai user), 52020 (user không active), 52021 (connector sai).
- **Demo EXEC:**
```sql
DECLARE @uid INT = (SELECT UserID FROM [Identity].UserAccount WHERE Username=N'customer01');
EXEC Operations.sp_CreateVehicle @UserID=@uid, @PlateNumber=N'51K-99999', @Brand=N'VinFast', @Model=N'VF8';
```
- **SELECT kiểm tra:** `SELECT * FROM Operations.Vehicle WHERE PlateNumber=N'51K-99999';`

### (16) `Operations.sp_UpdateVehicle`
- **Mục đích:** Cập nhật xe (COALESCE giữ giá trị cũ nếu NULL). **THROW:** 52032/52030/52031.
- **Input:** `@VehicleID, @UserID, @PlateNumber=NULL, @Brand=NULL, @Model=NULL, @BatteryCapacityKWh=NULL, @PreferredConnectorTypeID=NULL, @IsActive=NULL`.
- **Demo EXEC:** `EXEC Operations.sp_UpdateVehicle @VehicleID=1, @UserID=1, @Model=N'VF9';`

### (17) `Operations.sp_CreateBooking`
- **Mục đích:** Đặt chỗ cổng sạc; chống đặt trùng khoảng giờ trên cùng cổng. Sinh `BookingCode` tự động.
- **Input:** `@UserID, @VehicleID=NULL, @PointID, @BookedFrom, @BookedTo`.
- **Output:** thông tin booking. **THROW:** 52046, 52040 (from≥to), 52041, 52042, 52043, 52044, 52045 (trùng giờ).
- **Liên quan:** `Operations.Booking`, `Infrastructure.ChargingPoint`; kích hoạt trigger `trg_Booking_PreventOverlap`.
- **Demo EXEC:**
```sql
DECLARE @uid INT=(SELECT UserID FROM [Identity].UserAccount WHERE Username=N'customer01');
DECLARE @pid INT=(SELECT TOP 1 PointID FROM Infrastructure.ChargingPoint WHERE PointStatus=N'Available');
EXEC Operations.sp_CreateBooking @UserID=@uid, @PointID=@pid,
     @BookedFrom=DATEADD(HOUR,1,SYSDATETIME()), @BookedTo=DATEADD(HOUR,2,SYSDATETIME());
```
- **SELECT kiểm tra:** `SELECT * FROM AppView.vw_WebLookupCustomerBookings ORDER BY CreatedAt DESC;` (chạy trong context customer01)

### (18) `Operations.sp_CancelBooking`
- **Mục đích:** Hủy booking đang `Pending/Confirmed/Active`. **THROW:** 52051, 52050.
- **Input:** `@BookingID, @UserID=NULL`.
- **Demo EXEC:** `EXEC Operations.sp_CancelBooking @BookingID=1, @UserID=1;`
- **SELECT kiểm tra:** `SELECT BookingStatus FROM Operations.Booking WHERE BookingID=1;`

### (19) `Operations.sp_StartChargingSession`
- **Mục đích:** Bắt đầu phiên sạc: chọn `PricingPolicy` đang hiệu lực, set cổng `Charging`, tạo `SessionEvent`, sinh `SessionCode`.
- **Input:** `@UserID, @VehicleID=NULL, @PointID, @MeterStart=NULL, @BookingID=NULL`.
- **Output:** `SessionID, SessionCode, UserID, StationID, PointID, SessionStatus, StartTime`.
- **THROW:** 52005, 52001, 52002 (cổng không available), 52003, 52006, 52007, 52004 (không có policy).
- **Liên quan:** `ChargingSession, ChargingPoint, Booking, PricingPolicy, SessionEvent`; trigger `trg_ChargingSession_Audit`, `trg_ChargingSession_SyncPointStatus`.
- **Demo EXEC:**
```sql
DECLARE @uid INT=(SELECT UserID FROM [Identity].UserAccount WHERE Username=N'customer01');
DECLARE @pid INT=(SELECT TOP 1 PointID FROM Infrastructure.ChargingPoint WHERE PointStatus=N'Available');
EXEC Operations.sp_StartChargingSession @UserID=@uid, @PointID=@pid;
```
- **SELECT kiểm tra:** `SELECT * FROM AppView.vw_ActiveChargingSessions ORDER BY StartTime DESC;`

### (20) `Operations.sp_EndChargingSession`
- **Mục đích:** Kết thúc phiên: tính `TotalKWh` (từ meter hoặc ước lượng theo công suất × thời gian × hệ số), gọi `fn_CalculateChargingCost`, cộng thuế 8%, set cổng `Available`.
- **Input:** `@SessionID, @MeterEnd=NULL, @TotalKWh=NULL, @StopReason=N'Completed'`.
- **Output:** `SessionID, SessionCode, TotalKWh, CostBeforeTax, TaxAmount, CostTotal, SessionStatus`.
- **THROW:** 52010, 52013 (Customer kết thúc phiên người khác), 52011 (không ở trạng thái Charging).
- **Liên quan:** `fn_CalculateChargingCost`, `ChargingSession, ChargingPoint, SessionEvent`.
- **Demo EXEC:**
```sql
DECLARE @sid BIGINT=(SELECT TOP 1 SessionID FROM Operations.ChargingSession WHERE SessionStatus=N'Charging' ORDER BY SessionID DESC);
EXEC Operations.sp_EndChargingSession @SessionID=@sid, @TotalKWh=18.5;
```
- **SELECT kiểm tra:** `SELECT SessionID, TotalKWh, CostBeforeTax, TaxAmount, CostTotal, SessionStatus FROM Operations.ChargingSession WHERE SessionID=@sid;`

### (21) `Operations.sp_MarkChargingSessionFailed`
- **Mục đích:** Đánh dấu phiên `Pending/Charging` thành `Failed`, giải phóng cổng. **THROW:** 52060/52061.
- **Input:** `@SessionID, @FailedBy=NULL, @StopReason=N'Failed'`.
- **Demo EXEC:** `EXEC Operations.sp_MarkChargingSessionFailed @SessionID=@sid, @StopReason=N'Mất kết nối';`

### (22) `Payments.sp_CreatePayment`
- **Mục đích:** Thanh toán phiên đã `Completed`; chặn thanh toán 2 lần.
- **Input:** `@UserID, @SessionID, @PaymentMethod=N'CASH'` (CASH/QR/BANK_TRANSFER).
- **Output:** `TransactionID, TransactionCode, UserID, SessionID, PaymentMethod, Amount, TransactionStatus`.
- **THROW:** 53015, 53010 (chưa Completed), 53011, 53012, 53013, 53014 (đã thanh toán).
- **Liên quan:** `PaymentTransaction, ChargingSession`; trigger `trg_PaymentTransaction_Audit`, `trg_PaymentTransaction_UpdateInvoice`.
- **Demo EXEC:** `EXEC Payments.sp_CreatePayment @UserID=1, @SessionID=@sid, @PaymentMethod=N'QR';`
- **SELECT kiểm tra:** `SELECT * FROM Payments.PaymentTransaction WHERE SessionID=@sid;`

### (23) `Payments.sp_RefundPayment`
- **Mục đích:** Hoàn tiền giao dịch `Completed` → `Refunded`, đồng bộ invoice. **THROW:** 53040/53041.
- **Input:** `@TransactionID, @Reason=NULL`.
- **Demo EXEC:** `EXEC Payments.sp_RefundPayment @TransactionID=1, @Reason=N'Khách khiếu nại';`
- **SELECT kiểm tra:** `SELECT TransactionStatus FROM Payments.PaymentTransaction WHERE TransactionID=1;`

### (24) `Payments.sp_CreateInvoice`
- **Mục đích:** Xuất hóa đơn cho phiên `Completed`; trạng thái `Paid` nếu đã có giao dịch, ngược lại `Issued`. **THROW:** 53020 (đã có), 53022, 53021.
- **Input:** `@SessionID`.
- **Demo EXEC:** `EXEC Payments.sp_CreateInvoice @SessionID=@sid;`
- **SELECT kiểm tra:** `SELECT * FROM AppView.vw_InvoiceDetail WHERE SessionCode=(SELECT SessionCode FROM Operations.ChargingSession WHERE SessionID=@sid);`

### (25) `Operations.sp_CreatePricingPolicy`
- **Mục đích:** Tạo chính sách giá (giá cơ bản, hệ số giờ cao điểm). **THROW:** 52070/52071/52072.
- **Input:** `@PolicyCode, @PolicyName, @BasePricePerKWh, @PeakMultiplier=1.20, @PeakStartHour=NULL, @PeakEndHour=NULL, @AppliedFrom, @AppliedTo=NULL`.
- **Demo EXEC:**
```sql
EXEC Operations.sp_CreatePricingPolicy
     @PolicyCode=N'PP-DEMO', @PolicyName=N'Giá demo', @BasePricePerKWh=3500,
     @PeakMultiplier=1.30, @PeakStartHour='17:00', @PeakEndHour='21:00',
     @AppliedFrom=SYSDATETIME();
```
- **SELECT kiểm tra:** `SELECT * FROM AppView.vw_PricingPolicies WHERE PolicyCode=N'PP-DEMO';`

### (26) `Operations.sp_DeactivatePricingPolicy`
- **Mục đích:** Set `IsActive=0`. **THROW:** 52080. **Input:** `@PolicyID`.
- **Demo EXEC:** `EXEC Operations.sp_DeactivatePricingPolicy @PolicyID=1;`

### (27) `Maintenance.sp_ReportError`
- **Mục đích:** Ghi `ErrorLog` và tự sinh `MaintenanceTicket`; nếu có PointID thì set cổng `Error/Critical`. **THROW:** 54001.
- **Input:** `@ErrorCode=NULL, @StationID=NULL, @PointID=NULL, @Severity=N'Medium', @Description, @CreatedBy`.
- **Demo EXEC:**
```sql
EXEC Maintenance.sp_ReportError @PointID=1, @Severity=N'High',
     @Description=N'Cổng sạc quá nhiệt', @CreatedBy=(SELECT UserID FROM [Identity].UserAccount WHERE Username=N'operator01');
```
- **SELECT kiểm tra:** `SELECT * FROM AppView.vw_ErrorLogActive WHERE PointID=1;`

### (28) `Maintenance.sp_AssignTicket`
- **Mục đích:** Phân công ticket → status `Assigned`. **THROW:** 54010/54011.
- **Input:** `@TicketID, @AssignedTo, @AssignedBy`.
- **Demo EXEC:** `EXEC Maintenance.sp_AssignTicket @TicketID=1, @AssignedTo=@opUid, @AssignedBy=@opUid;`

### (29) `Maintenance.sp_ScheduleMaintenance`
- **Mục đích:** Tạo ticket bảo trì theo lịch; set cổng `Maintenance`. **THROW:** 54012/54013/54014/54015.
- **Input:** `@StationID=NULL, @PointID=NULL, @CreatedBy, @AssignedTo=NULL, @Priority=N'Medium', @Title, @Description=NULL`.
- **Demo EXEC:** `EXEC Maintenance.sp_ScheduleMaintenance @PointID=1, @CreatedBy=@opUid, @Title=N'Bảo trì định kỳ';`

### (30) `Maintenance.sp_CloseTicket`
- **Mục đích:** Đóng ticket, resolve error liên quan, phục hồi cổng `Available/Normal`. **THROW:** 54020.
- **Input:** `@TicketID, @ClosedBy`.
- **Demo EXEC:** `EXEC Maintenance.sp_CloseTicket @TicketID=1, @ClosedBy=@opUid;`
- **SELECT kiểm tra:** `SELECT TicketStatus, ClosedAt FROM Maintenance.MaintenanceTicket WHERE TicketID=1;`

### (31) `Franchise.sp_UpdateRevenueSharePolicy`
- **Mục đích:** Cập nhật tỉ lệ chia cho đối tác (0–100). **THROW:** 55010/55011.
- **Input:** `@RevenueSharePolicyID, @PartnerShareRate, @AppliedTo=NULL`.
- **Demo EXEC:** `EXEC Franchise.sp_UpdateRevenueSharePolicy @RevenueSharePolicyID=1, @PartnerShareRate=65;`

### (32) `Franchise.sp_CreateRevenueSettlement`
- **Mục đích:** Quyết toán doanh thu kỳ cho franchise: tổng `CostBeforeTax` các phiên Completed của trạm thuộc franchise, gọi `fn_CalculatePartnerShare`. **THROW:** 55001.
- **Input:** `@FranchiseID, @PeriodStart, @PeriodEnd`.
- **Output:** `SettlementID, SettlementCode, GrossRevenue, PartnerShareAmount, PlatformShareAmount, SettlementStatus`.
- **Demo EXEC:**
```sql
EXEC Franchise.sp_CreateRevenueSettlement @FranchiseID=1,
     @PeriodStart='2025-01-01', @PeriodEnd='2025-01-31';
```
- **SELECT kiểm tra:** `SELECT * FROM AppView.vw_ProfitSharing ORDER BY PeriodEnd DESC;`

### (33) `AppView.sp_ActivatePricingPolicy`  *(web action)*
- **Mục đích:** Kích hoạt lại chính sách giá đã `IsActive=0`. **THROW:** 57001 (không tồn tại), 57002 (đã active).
- **Input:** `@PolicyID`. **Quyền:** GRANT EXECUTE cho `db_ev_business_manager`.
- **Demo EXEC:** `EXEC AppView.sp_ActivatePricingPolicy @PolicyID=1;`

---

# 2. FUNCTION

File nguồn: `database/04_Create_Functions.sql`. Cả 3 đều là **scalar function**.

## 2.1 Bảng tổng hợp Function

| Tên đầy đủ | Return type | Mục đích | Input |
|---|---|---|---|
| `Operations.fn_CalculateChargingCost` | `DECIMAL(19,4)` | Tính tiền 1 phiên theo kWh + giờ cao điểm | `@TotalKWh, @PolicyID, @StartTime` |
| `Franchise.fn_CalculatePartnerShare` | `DECIMAL(19,4)` | Tính phần chia cho đối tác | `@GrossRevenue, @PartnerShareRate` |
| `AppView.fn_PointUtilizationRate` | `DECIMAL(9,4)` | Tỉ lệ % sử dụng 1 cổng theo khoảng thời gian | `@PointID, @FromDate, @ToDate` |

## 2.2 Chi tiết

### `Operations.fn_CalculateChargingCost(@TotalKWh, @PolicyID, @StartTime)`
- **Logic:** Lấy `BasePricePerKWh, PeakMultiplier, PeakStartHour, PeakEndHour` từ `PricingPolicy`. `Cost = TotalKWh × BasePrice`; nếu giờ của `@StartTime` rơi vào khoảng cao điểm thì `Cost ×= PeakMultiplier`. Trả `ROUND(Cost,4)`; trả 0 nếu thiếu giá/kWh.
- **Liên quan:** `Operations.PricingPolicy`. Được gọi trong `sp_EndChargingSession`.
- **Ví dụ gọi:**
```sql
SELECT Operations.fn_CalculateChargingCost(20.0, 1, '2025-06-01T18:00:00') AS Cost;
```
- **Kỳ vọng:** = `20 × BasePrice × PeakMultiplier` (vì 18:00 trong giờ cao điểm của policy 1).

### `Franchise.fn_CalculatePartnerShare(@GrossRevenue, @PartnerShareRate)`
- **Logic:** `ROUND(GrossRevenue × Rate / 100, 4)`, xử lý NULL = 0.
- **Ví dụ gọi:** `SELECT Franchise.fn_CalculatePartnerShare(1000000, 60) AS PartnerShare;` → **600000.0000**.

### `AppView.fn_PointUtilizationRate(@PointID, @FromDate, @ToDate)`
- **Logic:** `(SUM(DurationMinutes các phiên Completed trong khoảng) × 100) / tổng số phút khoảng [From,To)`. Trả 0 nếu mẫu số 0.
- **Liên quan:** `Operations.ChargingSession`.
- **Ví dụ gọi:**
```sql
SELECT AppView.fn_PointUtilizationRate(1, '2025-06-01', '2025-06-02') AS UtilizationPct;
```
- **Kỳ vọng:** giá trị % (0–100), ví dụ ~12.5 nếu cổng sạc tổng 180 phút trong 1 ngày.

---

# 3. TRIGGER

File nguồn: `database/06_Create_Triggers.sql`. (Một số trigger được `CREATE OR ALTER` 2 lần trong file — bản sau là bản hiệu lực; nội dung tương đương.)

## 3.1 Bảng tổng hợp Trigger

| Trigger | Bảng | Thời điểm | Sự kiện | Mục đích |
|---|---|---|---|---|
| `Infrastructure.trg_ChargingPoint_StatusHistory` | ChargingPoint | AFTER | UPDATE | Ghi `PointStatusHistory` + audit khi đổi trạng thái cổng |
| `Operations.trg_ChargingSession_Audit` | ChargingSession | AFTER | INSERT,UPDATE | Audit thay đổi `SessionStatus` |
| `Payments.trg_PaymentTransaction_Audit` | PaymentTransaction | AFTER | INSERT,UPDATE | Audit thay đổi `TransactionStatus` |
| `Identity.trg_UserAccount_Audit` | UserAccount | AFTER | INSERT,UPDATE | Audit; đánh dấu `SECURITY` khi đổi email/phone/password |
| `Identity.trg_UserRole_Audit` | UserRole | AFTER | INSERT | Chặn AssignedAt < CreatedAt; audit gán role |
| `Franchise.trg_FranchisePartner_Audit` | FranchisePartner | AFTER | INSERT,UPDATE | Audit trạng thái đối tác |
| `Franchise.trg_FranchiseContract_Audit` | FranchiseContract | AFTER | INSERT,UPDATE | Ràng buộc ngày; audit |
| `Franchise.trg_RevenueSharePolicy_Audit` | RevenueSharePolicy | AFTER | INSERT,UPDATE | Ràng buộc AppliedFrom; audit tỉ lệ |
| `Franchise.trg_RevenueShareSettlement_Audit` | RevenueShareSettlement | AFTER | INSERT,UPDATE | Ràng buộc kỳ; audit |
| `Operations.trg_Booking_PreventOverlap` | Booking | AFTER | INSERT,UPDATE | Chặn đặt chỗ trùng giờ cùng cổng |
| `Operations.trg_ChargingSession_SyncPointStatus` | ChargingSession | AFTER | INSERT,UPDATE | Đồng bộ trạng thái cổng theo phiên |
| `Maintenance.trg_Ticket_UpdatePointHealth` | MaintenanceTicket | AFTER | INSERT,UPDATE | Cập nhật `HealthStatus` cổng theo ticket |
| `Payments.trg_PaymentTransaction_UpdateInvoice` | PaymentTransaction | AFTER | INSERT,UPDATE | Đồng bộ `InvoiceStatus` theo giao dịch |
| `Audit.trg_AuditLog_BlockDelete` | AuditLog | INSTEAD OF | DELETE | Cấm xóa audit log (THROW 56001) |
| `Audit.trg_AuditLog_BlockUpdate` | AuditLog | INSTEAD OF | UPDATE | Cấm sửa audit log (THROW 56002) |

## 3.2 Chi tiết một số trigger trọng tâm (kèm demo)

### `Operations.trg_Booking_PreventOverlap` (business rule)
- **Mục đích:** Khi INSERT/UPDATE booking, nếu khoảng `[BookedFrom,BookedTo)` chồng lấn booking khác đang hoạt động trên cùng `PointID` → `THROW 56020`.
- **Demo kích hoạt:**
```sql
-- Tạo booking hợp lệ, rồi tạo booking thứ 2 trùng giờ cùng PointID -> trigger chặn
EXEC Operations.sp_CreateBooking @UserID=1, @PointID=1,
     @BookedFrom='2025-06-10T08:00', @BookedTo='2025-06-10T09:00';
EXEC Operations.sp_CreateBooking @UserID=1, @PointID=1,
     @BookedFrom='2025-06-10T08:30', @BookedTo='2025-06-10T09:30'; -- kỳ vọng lỗi 52045/56020
```
- **SELECT kiểm tra:** `SELECT * FROM Operations.Booking WHERE PointID=1 ORDER BY BookedFrom;`

### `Infrastructure.trg_ChargingPoint_StatusHistory`
- **Mục đích:** Mỗi lần `PointStatus` đổi → chèn 1 dòng vào `PointStatusHistory` + 1 dòng `AuditLog`.
- **Demo:** `EXEC Infrastructure.sp_UpdateChargingPointStatus @PointID=1, @PointStatus=N'Offline';`
- **SELECT kiểm tra:** `SELECT TOP 3 * FROM Infrastructure.PointStatusHistory WHERE PointID=1 ORDER BY ChangedAt DESC;`

### `Audit.trg_AuditLog_BlockDelete` / `trg_AuditLog_BlockUpdate` (INSTEAD OF)
- **Mục đích:** Bảo vệ tính toàn vẹn audit — không cho phép DELETE/UPDATE.
- **Demo (đều phải lỗi):**
```sql
DELETE FROM Audit.AuditLog WHERE AuditID = 1;            -- Msg 56001
UPDATE Audit.AuditLog SET ActionType=N'X' WHERE AuditID=1; -- Msg 56002
```
- **SELECT kiểm tra:** `SELECT COUNT(*) FROM Audit.AuditLog;` (số dòng không đổi).

### `Operations.trg_ChargingSession_SyncPointStatus`
- **Mục đích:** Khi `SessionStatus` → `Charging` thì cổng = `Charging`; khi sang `Completed/Failed/Cancelled/EmergencyStopped` (và không còn phiên Charging nào khác) thì cổng = `Available`.
- **Demo:** chạy `sp_StartChargingSession` rồi `sp_EndChargingSession` và quan sát `PointStatus`.
- **SELECT kiểm tra:** `SELECT PointID, PointStatus FROM Infrastructure.ChargingPoint WHERE PointID=@pid;`

### `Payments.trg_PaymentTransaction_UpdateInvoice`
- **Mục đích:** `TransactionStatus=Completed` → invoice `Paid`; `Refunded` → invoice `Refunded`.
- **Demo:** `EXEC Payments.sp_RefundPayment @TransactionID=1;` → kiểm tra invoice.
- **SELECT kiểm tra:** `SELECT InvoiceStatus FROM Payments.Invoice WHERE TransactionID=1;`

### `Maintenance.trg_Ticket_UpdatePointHealth`
- **Mục đích:** Ticket `Critical/High` đang mở → cổng `Critical/Warning`; ticket đóng → tính lại `HealthStatus` (`Normal` nếu hết ticket nghiêm trọng).

### Nhóm trigger audit còn lại
`trg_ChargingSession_Audit`, `trg_PaymentTransaction_Audit`, `trg_UserAccount_Audit`, `trg_UserRole_Audit`, `trg_FranchisePartner_Audit`, `trg_FranchiseContract_Audit`, `trg_RevenueSharePolicy_Audit`, `trg_RevenueShareSettlement_Audit`: ghi `Audit.AuditLog` (Old/New value) khi INSERT/UPDATE; một số kèm ràng buộc nghiệp vụ qua `THROW` (56004, 56010, 56011, 56012, 56013).
- **SELECT kiểm tra chung:** `SELECT TOP 20 * FROM AppView.vw_AuditLogRecent;`

---

# 4. VIEW VÀ REPORTING PROCEDURE (schema AppView)

File nguồn: `database/07_Create_AppViews.sql`. Nhiều view lọc theo người dùng đăng nhập bằng `SESSION_CONTEXT(N'UserID')`/`IS_ROLEMEMBER(...)`.

## 4.1 Reporting Procedure (AppView)

| Procedure | Nguồn dữ liệu (view) | Role phù hợp | Demo EXEC |
|---|---|---|---|
| `AppView.sp_GetStationRevenue @FromDate,@ToDate` | `vw_StationRevenueDaily` | BusinessManager | `EXEC AppView.sp_GetStationRevenue @FromDate='2025-01-01',@ToDate='2025-12-31';` |
| `AppView.sp_GetFranchiseProfitSharing` | `vw_ProfitSharing` | BusinessManager | `EXEC AppView.sp_GetFranchiseProfitSharing;` |
| `AppView.sp_GetPaymentSummary` | `vw_PaymentSummary` | BusinessManager | `EXEC AppView.sp_GetPaymentSummary;` |
| `AppView.sp_GetCustomerUsage @Top` | `vw_CustomerChargingHistory` | Customer | `EXEC AppView.sp_GetCustomerUsage @Top=10;` |
| `AppView.sp_GetOperationalKPI` | `vw_MaintenanceKPI` | OperationsStaff | `EXEC AppView.sp_GetOperationalKPI;` |
| `AppView.sp_GetTelemetryHealth` | `PointTelemetry` (+join) | OperationsStaff | `EXEC AppView.sp_GetTelemetryHealth;` |
| `AppView.sp_GetCurrentUserProfile` | `vw_CurrentUserProfile` | Tất cả role | `EXEC AppView.sp_GetCurrentUserProfile;` |
| `AppView.sp_GetMyFranchiseProfile` | `vw_MyFranchiseProfile` | FranchisePartner | `EXEC AppView.sp_GetMyFranchiseProfile;` |
| `AppView.sp_GetMyFranchiseContracts` | `vw_MyFranchiseContracts` | FranchisePartner | `EXEC AppView.sp_GetMyFranchiseContracts;` |
| `AppView.sp_GetMyFranchiseStations` | `vw_MyFranchiseStations` | FranchisePartner | `EXEC AppView.sp_GetMyFranchiseStations;` |
| `AppView.sp_GetMyRevenueSharePolicies` | `vw_MyRevenueSharePolicies` | FranchisePartner | `EXEC AppView.sp_GetMyRevenueSharePolicies;` |
| `AppView.sp_GetMyRevenueShareSettlements` | `vw_MyRevenueShareSettlements` | FranchisePartner | `EXEC AppView.sp_GetMyRevenueShareSettlements;` |

> Các reporting procedure đều `SET NOCOUNT ON` và chỉ `SELECT` (không transaction). Lưu ý: các SP `sp_GetMy*` chỉ trả dữ liệu khi chạy trong ngữ cảnh đăng nhập đúng (web set SESSION_CONTEXT); test SQL nên dùng `EXECUTE AS USER='franchise01'`.

## 4.2 View báo cáo nghiệp vụ chính

| View | Bảng nguồn | Mục đích báo cáo | Role |
|---|---|---|---|
| `vw_CustomerChargingHistory` | ChargingSession, UserAccount, Vehicle, Station, Point, ConnectorType | Lịch sử sạc của khách (lọc theo user) | Customer |
| `vw_CustomerBookingHistory` | Booking + Station/Point/User/Vehicle | Lịch sử đặt chỗ (lọc theo user) | Customer |
| `vw_InvoiceDetail` | Invoice, PaymentTransaction, ChargingSession,... | Chi tiết hóa đơn (lọc theo user) | Customer |
| `vw_MyVehicles` | Vehicle, ConnectorType | Xe của khách đang đăng nhập | Customer |
| `vw_MyChargingSummary` | ChargingSession | Tổng hợp sạc theo tháng của khách | Customer |
| `vw_AvailableChargingPoints` | ChargingPoint, Station, ConnectorType, Region | Cổng sạc còn trống theo khu vực | Customer |
| `vw_StationRevenueDaily` | ChargingSession, Station, FranchisePartner | Doanh thu trạm theo ngày | BusinessManager |
| `vw_StationRevenueByYear` | ChargingSession, Station | Doanh thu trạm theo năm (YoY) | BusinessManager |
| `vw_FranchiseRevenueMonthly` | FranchisePartner, Station, ChargingSession | Doanh thu franchise theo tháng | BusinessManager |
| `vw_RegionRevenue` | Region, Address, Station, ChargingSession | Doanh thu theo vùng | BusinessManager |
| `vw_TopRevenueStations` | Station, ChargingSession | Top trạm doanh thu cao | BusinessManager |
| `vw_TopCustomerUsage` | UserAccount, ChargingSession | Top khách hàng dùng nhiều | BusinessManager |
| `vw_PeakHourStatistics` | ChargingSession | Thống kê giờ cao điểm | BusinessManager |
| `vw_ChargingSessionStatistics` | ChargingSession | Thống kê phiên theo ngày/trạng thái | BusinessManager |
| `vw_CustomerGrowth` | UserAccount, UserRole, Role | Tăng trưởng khách theo tháng | BusinessManager |
| `vw_PaymentSummary` | PaymentTransaction | Tổng hợp giao dịch theo phương thức | BusinessManager |
| `vw_RefundablePayments` | PaymentTransaction + invoice/session | DS giao dịch có thể hoàn tiền | BusinessManager |
| `vw_PricingPolicies` | PricingPolicy | Danh sách chính sách giá | BusinessManager |
| `vw_ProfitSharing` | RevenueShareSettlement, FranchisePartner, Contract | Chia lợi nhuận đối tác | BusinessManager |
| `vw_ConnectorUtilization` | ConnectorType, ChargingPoint, ChargingSession | Mức sử dụng theo loại connector | BusinessManager |
| `vw_SystemOperationalKPI` | nhiều bảng (subquery) | KPI vận hành toàn hệ thống | BusinessManager |
| `vw_StationStatusOverview` | Station, Point, PointStatusHistory | Tổng quan trạng thái trạm | OperationsStaff |
| `vw_ActiveChargingSessions` | ChargingSession + join | Phiên đang sạc | OperationsStaff |
| `vw_MaintenanceKPI` | Station, Ticket, ErrorLog | KPI bảo trì | OperationsStaff |
| `vw_MaintenanceTickets` | MaintenanceTicket + join | Danh sách ticket | OperationsStaff |
| `vw_ErrorLogActive` | ErrorLog + Station/Point | Lỗi đang mở | OperationsStaff |
| `vw_UserRoleSummary` | UserAccount, UserRole, Role | Tổng hợp user–role | SystemAdmin |
| `vw_AccountsByRole` | UserAccount, UserRole, Role | Số tài khoản theo role/trạng thái | SystemAdmin |
| `vw_AuditLogRecent` | AuditLog (TOP 1000) | Nhật ký audit gần nhất | SystemAdmin |
| `vw_CurrentUserProfile` | UserAccount, UserRole, Role | Hồ sơ user đang đăng nhập | Tất cả |
| `vw_MyFranchiseProfile` / `vw_MyFranchiseContracts` / `vw_MyFranchiseStations` / `vw_MyRevenueSharePolicies` / `vw_MyRevenueShareSettlements` | các bảng Franchise + UserAccount | Dữ liệu riêng của đối tác (lọc theo user) | FranchisePartner |

**Demo & kỳ vọng tiêu biểu:**
```sql
-- Doanh thu trạm (BusinessManager)
EXECUTE AS USER='business01';
SELECT TOP 10 * FROM AppView.vw_TopRevenueStations ORDER BY RevenueTotal DESC;
REVERT;

-- Lịch sử sạc của khách (chỉ thấy phiên của chính mình)
EXECUTE AS USER='customer01';
SELECT TOP 10 * FROM AppView.vw_CustomerChargingHistory ORDER BY StartTime DESC;
REVERT;
```
Kỳ vọng: `business01` thấy mọi trạm; `customer01` chỉ thấy phiên của `customer01`.

## 4.3 View lookup phục vụ Web UI

Các view `vw_WebLookup*` cung cấp danh sách option/đổ dữ liệu cho web (đa số là `SELECT` đơn giản, một số lọc theo `SESSION_CONTEXT`):

| View | Bảng nguồn | Role được GRANT |
|---|---|---|
| `vw_WebLookupConnectorTypes` | ConnectorType | Customer, Operations, Business, Admin |
| `vw_WebLookupCustomerVehicles` | Vehicle, ConnectorType (lọc user) | Customer |
| `vw_WebLookupAvailablePoints` | Point, Station, ConnectorType, Region | Customer |
| `vw_WebLookupCustomerBookings` | Booking + join (lọc user) | Customer |
| `vw_WebLookupCustomerSessions` | ChargingSession + cờ HasPayment/HasInvoice (lọc user) | Customer |
| `vw_WebLookupStations` | Station, Address | Operations, Admin |
| `vw_WebLookupPoints` | Point, Station, ConnectorType | Operations, Admin |
| `vw_WebLookupActiveSessions` | ChargingSession + join | Operations, Admin |
| `vw_WebLookupOpenTickets` | MaintenanceTicket + join | Operations, Admin |
| `vw_WebLookupOperationsStaff` | UserAccount, UserRole, Role | Operations, Admin |
| `vw_WebLookupPricingPolicies` | PricingPolicy | Business, Admin |
| `vw_WebLookupRevenueSharePolicies` | RevenueSharePolicy + Contract + Partner | Business, Admin |
| `vw_WebLookupFranchises` | FranchisePartner | Business, Admin |
| `vw_WebLookupRefundablePayments` | PaymentTransaction + join | Business, Admin |
| `vw_WebLookupUsers` | UserAccount, UserRole, Role | Admin |
| `vw_WebLookupAssignableRoles` | UserAccount × Role (chưa gán) | Admin |
| `vw_WebLookupRemovableRoles` | UserRole, Role | Admin |

---

# 5. SECURITY (DCL / RBAC)

File nguồn chính: `database/08_Create_Security.sql`; nâng cao: `database/09_Advanced_Security.sql`; demo: `database/features/security/*.sql`.

## 5.1 Database Role và User demo

| Role | User demo | Vai trò ứng dụng |
|---|---|---|
| `db_ev_system_admin` | `admin01` | Quản trị hệ thống |
| `db_ev_operations_staff` | `operator01` | Nhân viên vận hành |
| `db_ev_business_manager` | `business01` | Quản lý kinh doanh |
| `db_ev_customer` | `customer01` | Khách hàng |
| `db_ev_franchise_partner` | `franchise01`..`franchise08` | Đối tác nhượng quyền |

> Tất cả user demo tạo `WITHOUT LOGIN` để chạy được trong môi trường chỉ-database và test bằng `EXECUTE AS USER`. (Login SQL thật cho SSMS nằm ở `features/security/08_sql_authentication_logins.sql`.)

## 5.2 Tóm tắt GRANT / DENY theo role

**`db_ev_system_admin`** — toàn quyền:
- `GRANT SELECT,INSERT,UPDATE,DELETE` trên **tất cả schema** (Core, Identity, Infrastructure, Franchise, Operations, Payments, Maintenance, AppView, Audit).
- `GRANT EXECUTE` toàn database. `GRANT UNMASK` (xem dữ liệu nhạy cảm — ở 09).

**`db_ev_operations_staff`** — vận hành:
- `GRANT SELECT,INSERT,UPDATE` trên Infrastructure, Operations, Maintenance; `GRANT EXECUTE` các schema đó.
- `GRANT SELECT` trên SCHEMA::AppView + EXECUTE một số report SP (`sp_GetCurrentUserProfile`, `sp_GetOperationalKPI`, `sp_GetTelemetryHealth`).
- `DENY SELECT,INSERT,UPDATE,DELETE` trên **Payments** và **Identity**.

**`db_ev_business_manager`** — kinh doanh (chỉ đọc báo cáo + vài action giá/quyết toán):
- `GRANT SELECT` các view báo cáo (StationRevenueDaily, FranchiseRevenueMonthly, ProfitSharing, PaymentSummary, PeakHour, TopRevenueStations, CustomerGrowth, SystemOperationalKPI, RegionRevenue, ChargingSessionStatistics, TopCustomerUsage, PricingPolicies, RefundablePayments, StationRevenueByYear, các Web lookup business).
- `GRANT EXECUTE`: `sp_CreatePricingPolicy`, `sp_DeactivatePricingPolicy`, `sp_ActivatePricingPolicy`, `sp_RefundPayment`, `sp_CreateRevenueSettlement`, `sp_UpdateRevenueSharePolicy`, các report SP.
- `DENY` toàn bộ DML trên **Identity, Payments**; `DENY INSERT/UPDATE/DELETE` trên Infrastructure, Operations, Maintenance (chỉ đọc).

**`db_ev_customer`** — khách hàng:
- `GRANT SELECT` các view cá nhân (CustomerChargingHistory, AvailableChargingPoints, CustomerBookingHistory, InvoiceDetail, MyVehicles, MyChargingSummary, các Web lookup customer).
- `GRANT EXECUTE`: `sp_CreateVehicle/UpdateVehicle`, `sp_CreateBooking/CancelBooking`, `sp_StartChargingSession/EndChargingSession`, `sp_CreatePayment/CreateInvoice`, `sp_GetCurrentUserProfile`, `sp_GetCustomerUsage`.
- `DENY SELECT,INSERT,UPDATE,DELETE` trên **Payments** và **Identity** (chỉ tương tác qua SP).

**`db_ev_franchise_partner`** — đối tác:
- `GRANT SELECT` các view `vw_My*` + EXECUTE các `sp_GetMy*`, `sp_GetCurrentUserProfile`.
- `DENY` toàn bộ DML trên Identity, Payments, Franchise, Infrastructure, Operations, Maintenance — chỉ xem dữ liệu của mình qua view (lọc SESSION_CONTEXT).

## 5.3 Advanced Security — Dynamic Data Masking (`09_Advanced_Security.sql`)
- `Identity.UserAccount.Email` → `MASKED WITH (FUNCTION='email()')`.
- `Identity.UserAccount.Phone` → `partial(0,"XXXX",4)`.
- `Identity.UserAccount.PasswordHash` → `default()`.
- `GRANT UNMASK TO db_ev_system_admin` (chỉ admin xem rõ).

## 5.4 Demo kiểm tra quyền bằng `EXECUTE AS USER`

**Thành công (đúng quyền):**
```sql
EXECUTE AS USER = 'business01';
SELECT TOP 5 * FROM AppView.vw_TopRevenueStations;   -- OK: business được GRANT
REVERT;

EXECUTE AS USER = 'customer01';
EXEC AppView.sp_GetCustomerUsage @Top = 5;           -- OK
REVERT;
```

**Thất bại (bị DENY):**
```sql
EXECUTE AS USER = 'operator01';
SELECT * FROM Payments.PaymentTransaction;           -- LỖI: DENY trên schema Payments
REVERT;

EXECUTE AS USER = 'customer01';
SELECT * FROM [Identity].UserAccount;                -- LỖI: DENY trên schema Identity
REVERT;
```

**Masking (`features/security/05_masking_demo.sql`):**
```sql
EXECUTE AS USER='admin01';      SELECT TOP 5 Username,Email,Phone,PasswordHash FROM [Identity].UserAccount; REVERT; -- rõ (có UNMASK)
EXECUTE AS USER='mask_viewer';  SELECT TOP 5 Username,Email,Phone,PasswordHash FROM [Identity].UserAccount; REVERT; -- bị che
```

**Row-Level Security (`features/security/06_row_level_security_demo.sql`):** tạo tạm `SecurityDemo.fn_FilterChargingSessionByUser` + `SECURITY POLICY ... ADD FILTER PREDICATE ON Operations.ChargingSession` để chứng minh customer chỉ thấy phiên của mình, sau đó dọn dẹp (DROP/REVOKE).

---

# 6. BACKUP / RESTORE / IMPORT / EXPORT

## 6.1 Danh sách script

| Script | Mục đích |
|---|---|
| `database/12_Backup_Restore.sql` | Mẫu lệnh BACKUP/RESTORE (comment, chạy ở `master`) |
| `database/features/system_admin/07_backup_restore_demo.sql` | Demo hiển thị lệnh backup/restore qua result set (không thực thi) |
| `database/00_Drop_And_Create_Database.sql` → `13_Auth_Migration.sql` | Pipeline rebuild/import lại toàn bộ DB + seed (đóng vai trò import dữ liệu) |

> Hệ thống không có script export riêng ở tầng SQL; **export PDF/CSV** được thực hiện ở tầng backend (đã pass smoke test). Import dữ liệu = chạy lại bộ script `00→09→13` (đặc biệt `09_Seed_Demo_Data.sql`).

## 6.2 Source code chính (Backup/Restore)

`database/12_Backup_Restore.sql`:
```sql
BACKUP DATABASE EV_Charging_System
TO DISK = 'C:\Backup\EV_Charging_System.bak'
WITH INIT, FORMAT, STATS = 10;

RESTORE DATABASE EV_Charging_System_RestoreDemo
FROM DISK = 'C:\Backup\EV_Charging_System.bak'
WITH FILE = 1,
     MOVE 'EV_Charging_System'     TO 'C:\Backup\EV_Charging_System_RestoreDemo.mdf',
     MOVE 'EV_Charging_System_log' TO 'C:\Backup\EV_Charging_System_RestoreDemo_log.ldf',
     STATS = 10;
```

`features/system_admin/07_backup_restore_demo.sql` (bản có COMPRESSION, dùng `C:\Temp`):
```sql
SELECT
    DB_NAME() AS DatabaseName,
    N'BACKUP DATABASE EV_Charging_System TO DISK = N''C:\Temp\EV_Charging_System.bak'' WITH INIT, COMPRESSION, STATS = 5;' AS BackupCommand,
    N'RESTORE DATABASE EV_Charging_System_RestoreDemo FROM DISK = N''C:\Temp\EV_Charging_System.bak'' WITH MOVE ... , RECOVERY, STATS = 5;' AS RestoreCommand;
```

## 6.3 Kịch bản demo & kiểm tra kết quả

**Backup:**
```sql
USE master;
BACKUP DATABASE EV_Charging_System
TO DISK = N'C:\Backup\EV_Charging_System.bak'
WITH INIT, FORMAT, STATS = 10;
```
Kiểm tra: file `.bak` xuất hiện + lịch sử backup:
```sql
SELECT TOP 5 database_name, backup_start_date, backup_finish_date, type
FROM msdb.dbo.backupset
WHERE database_name = N'EV_Charging_System'
ORDER BY backup_start_date DESC;
```

**Restore sang DB demo:**
```sql
RESTORE DATABASE EV_Charging_System_RestoreDemo
FROM DISK = N'C:\Backup\EV_Charging_System.bak'
WITH FILE=1,
     MOVE 'EV_Charging_System'     TO 'C:\Backup\EV_RestoreDemo.mdf',
     MOVE 'EV_Charging_System_log' TO 'C:\Backup\EV_RestoreDemo_log.ldf',
     RECOVERY, STATS=10;
```
Kiểm tra dữ liệu sau restore:
```sql
SELECT COUNT(*) AS UserCount        FROM EV_Charging_System_RestoreDemo.[Identity].UserAccount;
SELECT COUNT(*) AS SessionCount     FROM EV_Charging_System_RestoreDemo.Operations.ChargingSession;
```
Kỳ vọng: số dòng khớp DB gốc (theo seed: ~530 user, ~300k session).

**Import/rebuild (sqlcmd, lưu ý cờ `-I`):**
```bat
sqlcmd -S "localhost\SQLEXPRESS" -E -I -i 00_Drop_And_Create_Database.sql
sqlcmd -S "localhost\SQLEXPRESS" -E -I -i 01_Create_Schemas.sql
:: ... 02..09 ...
sqlcmd -S "localhost\SQLEXPRESS" -E -I -i 13_Auth_Migration.sql
```
Kiểm tra import thành công:
```sql
SELECT
  (SELECT COUNT(*) FROM sys.procedures)                       AS Procedures,
  (SELECT COUNT(*) FROM sys.views)                            AS Views,
  (SELECT COUNT(*) FROM sys.objects WHERE type='TR')          AS Triggers,
  (SELECT COUNT(*) FROM sys.objects WHERE type IN('FN','IF','TF')) AS Functions;
```
(Đối chiếu thêm: `database/features/00_setup_check/01_check_database_objects.sql` và `02_check_seed_data.sql`.)

---

*Hết Chương 4.*
