# Usecase Feature Tree Diagram - EV_Charging_System

Tai lieu nay trinh bay cac tinh nang cua he thong theo dang cay lua chon cho tung nhom nguoi dung. Moi cay bat dau tu actor, tach thanh cac nhom chuc nang lon, sau do den hanh dong cu the va database object tuong ung.

Dang cay nay phu hop de:

- Dua vao bao cao phan tich he thong.
- Lam noi dung chuan truoc khi ve diagram bang Mermaid, Draw.io hoac AI image generator.
- Trinh bay ro moi user co the chon nhung tinh nang nao.
- Gan moi tinh nang voi stored procedure, view hoac function trong database.

## 1. Customer

```text
Customer
├── Xem trạm/cổng sạc
│   └── Xem cổng khả dụng
│       └── AppView.vw_AvailableChargingPoints
├── Quản lý xe
│   ├── Thêm xe
│   │   └── Operations.sp_CreateVehicle
│   └── Cập nhật xe
│       └── Operations.sp_UpdateVehicle
├── Đặt lịch sạc
│   ├── Tạo booking
│   │   └── Operations.sp_CreateBooking
│   ├── Hủy booking
│   │   └── Operations.sp_CancelBooking
│   └── Xem lịch sử booking
│       └── AppView.vw_CustomerBookingHistory
├── Phiên sạc
│   ├── Bắt đầu phiên sạc
│   │   └── Operations.sp_StartChargingSession
│   ├── Kết thúc phiên sạc
│   │   └── Operations.sp_EndChargingSession
│   └── Xem lịch sử sạc
│       └── AppView.vw_CustomerChargingHistory
└── Thanh toán - hóa đơn
    ├── Thanh toán
    │   └── Payments.sp_CreatePayment
    ├── Tạo hóa đơn
    │   └── Payments.sp_CreateInvoice
    └── Xem chi tiết hóa đơn
        └── AppView.vw_InvoiceDetail
```

### Phan tich nhanh

Customer la nguoi dung cuoi cua he thong. Cac nhanh tinh nang cua Customer tap trung vao hanh trinh su dung dich vu sac xe: tim cong sac, quan ly xe, dat lich, thuc hien phien sac, thanh toan va xem hoa don.

Database object cua Customer chu yeu la cac procedure trong schema `Operations` va `Payments`, ket hop voi cac view trong schema `AppView`. Customer khong thao tac truc tiep voi bang goc nhay cam nhu `[Identity].UserAccount` hay `Payments.PaymentTransaction`.

## 2. Operations Staff

```text
Operations Staff
├── Giám sát trạng thái
│   ├── Xem trạng thái trạm
│   │   └── AppView.vw_StationStatusOverview
│   └── Xem phiên sạc đang chạy
│       └── AppView.vw_ActiveChargingSessions
├── Cập nhật hạ tầng
│   ├── Cập nhật trạng thái trạm
│   │   └── Infrastructure.sp_UpdateStationStatus
│   └── Cập nhật trạng thái cổng sạc
│       └── Infrastructure.sp_UpdateChargingPointStatus
├── Xử lý phiên sạc lỗi
│   └── Đánh dấu session lỗi
│       └── Operations.sp_MarkChargingSessionFailed
├── Quản lý lỗi và bảo trì
│   ├── Ghi nhận lỗi thiết bị
│   │   └── Maintenance.sp_ReportError
│   ├── Lập lịch bảo trì
│   │   └── Maintenance.sp_ScheduleMaintenance
│   ├── Phân công ticket
│   │   └── Maintenance.sp_AssignTicket
│   └── Đóng ticket
│       └── Maintenance.sp_CloseTicket
└── Theo dõi telemetry
    └── Xem telemetry health
        └── AppView.sp_GetTelemetryHealth
```

### Phan tich nhanh

Operations Staff la nhom van hanh he thong. Cac nhanh tinh nang cua nhom nay tap trung vao trang thai tram sac, cong sac, session dang chay, loi thiet bi, ticket bao tri va telemetry.

Database object cua Operations Staff nam chu yeu trong cac schema `Infrastructure`, `Operations`, `Maintenance` va `AppView`. Khi nhan vien thay doi trang thai cong sac, trigger `Infrastructure.trg_ChargingPoint_StatusHistory` se ghi lai lich su thay doi. Khi session bi danh dau loi, trigger audit cua `Operations.ChargingSession` giup ghi nhan su kien quan trong.

## 3. Business Manager

```text
Business Manager
├── Quản lý chính sách giá
│   ├── Tạo pricing policy
│   │   └── Operations.sp_CreatePricingPolicy
│   └── Vô hiệu hóa pricing policy
│       └── Operations.sp_DeactivatePricingPolicy
├── Báo cáo doanh thu
│   ├── Xem doanh thu theo trạm
│   │   └── AppView.sp_GetStationRevenue
│   ├── Xem doanh thu theo ngày
│   │   └── AppView.vw_StationRevenueDaily
│   ├── Xem doanh thu theo khu vực
│   │   └── AppView.vw_RegionRevenue
│   └── Xem top trạm doanh thu cao
│       └── AppView.vw_TopRevenueStations
├── Phân tích vận hành - kinh doanh
│   ├── Thống kê giờ cao điểm
│   │   └── AppView.vw_PeakHourStatistics
│   ├── Xem tăng trưởng khách hàng
│   │   └── AppView.vw_CustomerGrowth
│   ├── Xem KPI hệ thống
│   │   └── AppView.vw_SystemOperationalKPI
│   └── Xem top khách hàng sử dụng
│       └── AppView.vw_TopCustomerUsage
├── Quản lý chia doanh thu franchise
│   ├── Cập nhật revenue share policy
│   │   └── Franchise.sp_UpdateRevenueSharePolicy
│   ├── Tạo revenue settlement
│   │   └── Franchise.sp_CreateRevenueSettlement
│   ├── Tính phần chia cho đối tác
│   │   └── Franchise.fn_CalculatePartnerShare
│   └── Xem profit sharing
│       └── AppView.sp_GetFranchiseProfitSharing
└── Quản lý thanh toán đặc biệt
    └── Hoàn tiền
        └── Payments.sp_RefundPayment
```

### Phan tich nhanh

Business Manager la nhom quan ly hieu qua kinh doanh. Cac nhanh tinh nang gom quan ly gia, xem doanh thu, phan tich KPI, quan ly chia doanh thu cho franchise va hoan tien khi can.

Database object cua Business Manager chu yeu nam trong schema `AppView` de doc bao cao. Cac thao tac co tac dong du lieu nhu tao pricing policy, cap nhat revenue share policy, tao settlement va refund duoc thuc hien qua stored procedure de dam bao tinh toan va audit dung.

## 4. System Admin

```text
System Admin
├── Quản lý tài khoản
│   ├── Tạo tài khoản
│   │   └── Identity.sp_CreateUser
│   ├── Khóa tài khoản
│   │   └── Identity.sp_LockUser
│   ├── Mở khóa tài khoản
│   │   └── Identity.sp_UnlockUser
│   └── Reset password
│       └── Identity.sp_ResetPassword
├── Quản lý role
│   ├── Gán role
│   │   └── Identity.sp_AssignRole
│   ├── Gỡ role
│   │   └── Identity.sp_RemoveRole
│   └── Xem tổng hợp user-role
│       └── AppView.vw_UserRoleSummary
├── Kiểm tra audit
│   ├── Xem audit log
│   │   └── Audit.AuditLog
│   └── Chặn xóa audit log
│       └── Audit.trg_AuditLog_BlockDelete
└── Sao lưu và phục hồi
    └── Chuẩn bị backup/restore
        └── database/12_Backup_Restore.sql
```

### Phan tich nhanh

System Admin quan ly phan tai khoan, role, quyen truy cap va audit. Day la actor phu trach viec tao user, khoa/mo tai khoan, reset password, gan/go role va kiem tra lich su thao tac.

Database object cua System Admin nam chu yeu trong schema `[Identity]`, `Audit` va `AppView`. Cac procedure quan tri user ghi log vao `Audit.AuditLog`. Trigger `Audit.trg_AuditLog_BlockDelete` giup bao ve audit log khoi viec bi xoa.

## 5. Franchise Partner

Trong source hien tai, Franchise Partner co du lieu nghiep vu nhung chua co database role/user rieng de dang nhap. Cac thao tac lien quan den franchise dang duoc Business Manager thuc hien. Tuy nhien, neu phat trien thanh actor rieng, cay tinh nang co the duoc thiet ke nhu sau:

```text
Franchise Partner
├── Xem thông tin đối tác
│   └── Xem hồ sơ franchise
│       └── Franchise.FranchisePartner
├── Xem hợp đồng
│   └── Xem hợp đồng nhượng quyền
│       └── Franchise.FranchiseContract
├── Xem trạm thuộc đối tác
│   ├── Xem mapping franchise - station
│   │   └── Franchise.FranchiseStation
│   └── Xem thông tin trạm
│       └── Infrastructure.ChargingStation
├── Xem chính sách chia doanh thu
│   └── Xem revenue share policy
│       └── Franchise.RevenueSharePolicy
└── Xem đối soát doanh thu
    ├── Xem settlement
    │   └── Franchise.RevenueShareSettlement
    └── Xem profit sharing
        └── AppView.vw_ProfitSharing
```

### Phan tich nhanh

Franchise Partner hien tai la thuc the du lieu, khong phai user dang nhap rieng trong security script. Neu mo rong he thong, role nay nen chi co quyen xem du lieu lien quan den chinh doi tac do: thong tin doi tac, hop dong, tram thuoc doi tac, policy chia doanh thu va settlement.

## 6. Prompt mau de AI generate diagram

Co the dung prompt chung sau cho tung cay:

```text
Create a clean professional "Usecase Feature Tree Diagram" for an EV Charging Management System.

Design style:
- Modern system analysis diagram
- White or light background
- Clear branching tree hierarchy
- Vietnamese labels
- Include database object names under each feature
- Use clean rounded rectangles
- Use distinct colors for feature groups
- Make all text readable
- Do not make it a sequential workflow
- It must look like a choice tree
- Do not invent extra features

Use this exact tree content:

[Paste one feature tree here]
```

## 7. Ghi chu trinh bay

- Moi actor nen ve thanh mot diagram rieng de tranh qua nhieu chu trong mot hinh.
- Node goc la ten actor.
- Level 1 la nhom chuc nang.
- Level 2 la hanh dong nguoi dung co the chon.
- Level 3 la database object xu ly tinh nang: view, stored procedure, function, trigger hoac script.
- Voi bao cao database, nen giu ten object SQL trong diagram vi no chung minh tinh nang co lien ket voi source code that.
