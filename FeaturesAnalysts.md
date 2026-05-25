# FeaturesAnalysts.md - Phân tích tính năng hệ thống EV_Charging_System

Tài liệu này phân tích tính năng của đề tài **“Hệ thống quản lý mạng lưới trạm sạc xe điện và doanh nghiệp nhượng quyền”** dựa trên source code hiện có trong repository, đặc biệt là thư mục `database`. Phạm vi phân tích tập trung vào SQL Server database: schema, bảng, stored procedure, view, function, trigger, seed data, phân quyền và các script demo. Source hiện tại không có backend/frontend, vì vậy tài liệu không phân tích API route hoặc giao diện người dùng.

## Mục lục

1. [Tổng quan source và database](#1-tổng-quan-source-và-database)
2. [Cấu trúc database](#2-cấu-trúc-database)
3. [Role và actor trong hệ thống](#3-role-và-actor-trong-hệ-thống)
4. [Phân tích tính năng theo role](#4-phân-tích-tính-năng-theo-role)
5. [Phân tích tính năng theo module hệ thống](#5-phân-tích-tính-năng-theo-module-hệ-thống)
6. [Ma trận role - chức năng](#6-ma-trận-role---chức-năng)
7. [Ma trận tính năng - database object](#7-ma-trận-tính-năng---database-object)
8. [Luồng nghiệp vụ chính](#8-luồng-nghiệp-vụ-chính)
9. [Phân tích stored procedure](#9-phân-tích-stored-procedure)
10. [Phân tích view/report](#10-phân-tích-viewreport)
11. [Phân tích trigger/function](#11-phân-tích-triggerfunction)
12. [Phân tích bảo mật và phân quyền](#12-phân-tích-bảo-mật-và-phân-quyền)
13. [Cách sử dụng file này để viết báo cáo](#13-cách-sử-dụng-file-này-để-viết-báo-cáo)

# 1. Tổng quan source và database

| Hạng mục | Giá trị |
|---|---|
| Tên database | `EV_Charging_System` |
| DBMS | Microsoft SQL Server |
| Phong cách hệ thống | Database-centric information management system |
| Source chính | `database/*.sql`, `database/features/**/*.sql` |
| Backend/frontend | Chưa thấy trong source hiện tại |
| Tính năng trọng tâm | Quản lý trạm sạc, cổng sạc, booking, phiên sạc, thanh toán, hóa đơn, franchise, chia doanh thu, bảo trì, báo cáo, RBAC |
| Seed data | Có seed data quy mô lớn mô phỏng gần 2 năm hoạt động |

Các file nguồn quan trọng:

| File | Nội dung |
|---|---|
| `database/00_Drop_And_Create_Database.sql` | Tạo database `EV_Charging_System` |
| `database/01_Create_Schemas.sql` | Tạo 9 schema nghiệp vụ |
| `database/02_Create_Tables.sql` | Tạo 27 bảng, PK, FK, CHECK, UNIQUE |
| `database/03_Create_Constraints_Indexes.sql` | Tạo 40 index |
| `database/04_Create_Functions.sql` | Tạo 3 function |
| `database/05_Create_Stored_Procedures.sql` | Tạo 28 stored procedure nghiệp vụ |
| `database/06_Create_Triggers.sql` | Tạo 4 trigger |
| `database/07_Create_AppViews.sql` | Tạo 20 view và 6 procedure báo cáo |
| `database/08_Create_Security.sql` | Tạo database role, user demo, GRANT/DENY |
| `database/09_Advanced_Security.sql` | Dynamic Data Masking |
| `database/09_Seed_Demo_Data.sql` | Seed data lớn phục vụ demo |
| `database/12_Backup_Restore.sql` | Script mẫu backup/restore |
| `database/features/FEATURE_INDEX.md` | Mục lục các kịch bản demo theo role |

# 2. Cấu trúc database

## 2.1. Danh sách schema

| STT | Schema | Vai trò |
|---:|---|---|
| 1 | `Core` | Dữ liệu nền về khu vực và địa chỉ |
| 2 | `Identity` | Tài khoản, role nghiệp vụ, user-role |
| 3 | `Infrastructure` | Hạ tầng trạm sạc, cổng sạc, connector, telemetry |
| 4 | `Franchise` | Đối tác nhượng quyền, hợp đồng, chính sách chia doanh thu, quyết toán |
| 5 | `Operations` | Xe, booking, phiên sạc, chính sách giá, sự kiện session |
| 6 | `Payments` | Giao dịch thanh toán và hóa đơn |
| 7 | `Maintenance` | Lỗi thiết bị và ticket bảo trì |
| 8 | `AppView` | View/procedure phục vụ đọc dữ liệu, báo cáo và demo |
| 9 | `Audit` | Nhật ký thay đổi dữ liệu và hành động quan trọng |

Nguồn: `database/01_Create_Schemas.sql`.

## 2.2. Danh sách bảng hiện có

| STT | Schema | Bảng | Nhóm nghiệp vụ |
|---:|---|---|---|
| 1 | `Core` | `Region` | Khu vực |
| 2 | `Core` | `Address` | Địa chỉ |
| 3 | `Identity` | `Role` | Phân quyền nghiệp vụ |
| 4 | `Identity` | `UserAccount` | Tài khoản |
| 5 | `Identity` | `UserRole` | Gán role cho user |
| 6 | `Franchise` | `FranchisePartner` | Đối tác nhượng quyền |
| 7 | `Franchise` | `FranchiseContract` | Hợp đồng |
| 8 | `Franchise` | `FranchiseStation` | Gán trạm với franchise/contract |
| 9 | `Franchise` | `RevenueSharePolicy` | Chính sách chia doanh thu |
| 10 | `Franchise` | `RevenueShareSettlement` | Quyết toán doanh thu |
| 11 | `Infrastructure` | `ElectricitySupplier` | Nhà cung cấp điện |
| 12 | `Infrastructure` | `ChargingStation` | Trạm sạc |
| 13 | `Infrastructure` | `ConnectorType` | Loại đầu sạc |
| 14 | `Infrastructure` | `StationConnectorType` | Loại connector của trạm |
| 15 | `Infrastructure` | `ChargingPoint` | Cổng sạc |
| 16 | `Infrastructure` | `PointStatusHistory` | Lịch sử trạng thái cổng |
| 17 | `Infrastructure` | `PointTelemetry` | Telemetry cổng sạc |
| 18 | `Operations` | `Vehicle` | Xe khách hàng |
| 19 | `Operations` | `PricingPolicy` | Chính sách giá |
| 20 | `Operations` | `Booking` | Đặt lịch sạc |
| 21 | `Operations` | `ChargingSession` | Phiên sạc |
| 22 | `Operations` | `SessionEvent` | Sự kiện trong phiên sạc |
| 23 | `Payments` | `PaymentTransaction` | Giao dịch thanh toán |
| 24 | `Payments` | `Invoice` | Hóa đơn |
| 25 | `Maintenance` | `ErrorLog` | Nhật ký lỗi |
| 26 | `Maintenance` | `MaintenanceTicket` | Ticket bảo trì |
| 27 | `Audit` | `AuditLog` | Audit log |

Nguồn: `database/02_Create_Tables.sql`.

## 2.3. Các bảng chính nên dùng khi mô tả lược đồ rút gọn

| Schema | Bảng chính | Lý do giữ trong lược đồ tính năng |
|---|---|---|
| `Core` | `Address` | Liên kết vị trí với trạm và franchise partner |
| `Identity` | `UserAccount` | Trung tâm user cho customer, operator, manager, admin |
| `Infrastructure` | `ChargingStation` | Thực thể trạm sạc |
| `Infrastructure` | `ChargingPoint` | Thực thể cổng sạc, liên quan trực tiếp booking/session |
| `Infrastructure` | `ConnectorType` | Loại đầu sạc cho point và vehicle |
| `Operations` | `Vehicle` | Xe của khách hàng |
| `Operations` | `Booking` | Đặt lịch cổng sạc |
| `Operations` | `ChargingSession` | Bảng giao dịch lõi của hệ thống |
| `Operations` | `PricingPolicy` | Tính giá phiên sạc |
| `Payments` | `PaymentTransaction` | Thanh toán phiên sạc |
| `Payments` | `Invoice` | Hóa đơn |
| `Franchise` | `FranchisePartner` | Đối tác nhượng quyền |
| `Franchise` | `FranchiseContract` | Hợp đồng nhượng quyền |
| `Franchise` | `RevenueSharePolicy` | Tỷ lệ chia doanh thu |
| `Franchise` | `RevenueShareSettlement` | Kết quả quyết toán |
| `Maintenance` | `ErrorLog` | Lỗi thiết bị/trạm |
| `Maintenance` | `MaintenanceTicket` | Quy trình xử lý lỗi |
| `Audit` | `AuditLog` | Theo dõi thay đổi và bảo mật |

# 3. Role và actor trong hệ thống

## 3.1. Actor nghiệp vụ

| Actor | Có bảng/role trong source? | Diễn giải |
|---|---|---|
| System Admin | Có database role `db_ev_system_admin`; có user demo `admin01`; có logical role `SystemAdmin` trong seed data | Quản trị tài khoản, role, audit, dữ liệu toàn hệ thống |
| Operations Staff | Có database role `db_ev_operations_staff`; có user demo `operator01`; có logical role `OperationsStaff` | Vận hành trạm, cổng sạc, session lỗi, telemetry, maintenance |
| Business Manager | Có database role `db_ev_business_manager`; có user demo `business01`; có logical role `BusinessManager` | Xem báo cáo, tạo settlement, cập nhật revenue share policy |
| Customer | Có database role `db_ev_customer`; có user demo `customer01`; có logical role `Customer` | Quản lý xe, booking, phiên sạc, thanh toán, hóa đơn |
| Franchise Partner | Có bảng `Franchise.FranchisePartner`; chưa thấy database role/user riêng | Được quản lý như đối tượng dữ liệu, không phải actor đăng nhập riêng trong security script |

## 3.2. Database role được tạo trong security script

| Database role | User demo | Nguồn |
|---|---|---|
| `db_ev_system_admin` | `admin01` | `database/08_Create_Security.sql` |
| `db_ev_operations_staff` | `operator01` | `database/08_Create_Security.sql` |
| `db_ev_business_manager` | `business01` | `database/08_Create_Security.sql` |
| `db_ev_customer` | `customer01` | `database/08_Create_Security.sql` |

# 4. Phân tích tính năng theo role

## 4.1. System Admin

### Mục đích

System Admin đại diện cho người quản trị hệ thống. Role này có quyền rộng nhất trong database để quản lý dữ liệu, tài khoản, role, audit và chuẩn bị backup/restore demo.

### Tính năng chính

| STT | Tính năng | Mô tả nghiệp vụ | Bảng liên quan | View/Procedure/Function/Trigger liên quan | Quyền cần có | Nguồn |
|---:|---|---|---|---|---|---|
| 1 | Tạo tài khoản | Tạo user mới và gán role ban đầu | `[Identity].UserAccount`, `[Identity].UserRole`, `[Identity].Role`, `Audit.AuditLog` | `[Identity].sp_CreateUser` | `EXEC`, DML schema `Identity`, `Audit` | `system_admin/01_create_user.sql` |
| 2 | Khóa/mở khóa tài khoản | Đổi `AccountStatus` sang `Locked` hoặc `Active` | `[Identity].UserAccount`, `Audit.AuditLog` | `[Identity].sp_LockUser`, `[Identity].sp_UnlockUser` | `EXEC` | `system_admin/02_lock_unlock_user.sql` |
| 3 | Reset password | Cập nhật `PasswordHash` | `[Identity].UserAccount`, `Audit.AuditLog` | `[Identity].sp_ResetPassword` | `EXEC` | `system_admin/03_reset_password.sql` |
| 4 | Gán/gỡ role | Quản lý user-role mapping | `[Identity].UserRole`, `[Identity].Role`, `[Identity].UserAccount`, `Audit.AuditLog` | `[Identity].sp_AssignRole`, `[Identity].sp_RemoveRole` | `EXEC` | `system_admin/04_assign_remove_role.sql` |
| 5 | Xem user-role summary | Xem tài khoản và danh sách role | `[Identity].UserAccount`, `[Identity].UserRole`, `[Identity].Role` | `AppView.vw_UserRoleSummary` | `SELECT` | `system_admin/05_view_user_role_summary.sql` |
| 6 | Xem audit log | Kiểm tra lịch sử thay đổi | `Audit.AuditLog` | `Audit.trg_AuditLog_BlockDelete` bảo vệ xóa | `SELECT` | `system_admin/06_view_audit_log.sql` |
| 7 | Backup/restore demo | Chuẩn bị câu lệnh backup và restore | Database-level | Không có procedure, là script mẫu | Quyền backup/restore SQL Server | `database/12_Backup_Restore.sql` |
| 8 | Xem dữ liệu không bị mask | Đọc email/phone/password hash không bị che nếu chạy advanced security | `[Identity].UserAccount` | Dynamic Data Masking, `GRANT UNMASK` | `UNMASK` | `database/09_Advanced_Security.sql` |

### Luồng thao tác tiêu biểu

1. Admin gọi `[Identity].sp_CreateUser`.
2. Procedure kiểm tra `RoleCode` có tồn tại trong `[Identity].Role`.
3. Procedure insert vào `[Identity].UserAccount`.
4. Procedure insert vào `[Identity].UserRole`.
5. Procedure ghi `Audit.AuditLog` với `ActionType = 'INSERT'`.
6. Nếu lỗi xảy ra, transaction rollback vì procedure dùng `TRY/CATCH`, `XACT_ABORT ON`.

### Gợi ý demo

| Bước | Script |
|---:|---|
| 1 | Chạy `database/features/system_admin/01_create_user.sql` để tạo user mới |
| 2 | Chạy `database/features/system_admin/02_lock_unlock_user.sql` để khóa/mở user |
| 3 | Chạy `database/features/system_admin/04_assign_remove_role.sql` để gán/gỡ role |
| 4 | Chạy `database/features/system_admin/05_view_user_role_summary.sql` để kiểm tra role |
| 5 | Chạy `database/features/system_admin/06_view_audit_log.sql` để xem audit |

## 4.2. Operations Staff

### Mục đích

Operations Staff đại diện cho nhân viên vận hành trạm sạc. Role này theo dõi trạng thái trạm/cổng, xử lý session lỗi, ghi nhận lỗi thiết bị, quản lý ticket bảo trì và xem telemetry.

### Tính năng chính

| STT | Tính năng | Mô tả nghiệp vụ | Bảng liên quan | View/Procedure/Function/Trigger liên quan | Quyền cần có | Nguồn |
|---:|---|---|---|---|---|---|
| 1 | Xem trạng thái trạm | Theo dõi tổng số point, point available/charging/problem | `ChargingStation`, `ChargingPoint`, `PointStatusHistory` | `AppView.vw_StationStatusOverview` | `SELECT AppView` | `operations_staff/01_view_station_status.sql` |
| 2 | Cập nhật trạng thái trạm | Đổi `StationStatus` | `Infrastructure.ChargingStation`, `Audit.AuditLog` | `Infrastructure.sp_UpdateStationStatus` | `EXEC`, `UPDATE Infrastructure` | `operations_staff/02_update_station_status.sql` |
| 3 | Cập nhật trạng thái cổng | Đổi `PointStatus`, `HealthStatus` | `ChargingPoint`, `PointStatusHistory`, `AuditLog` | `Infrastructure.sp_UpdateChargingPointStatus`, `Infrastructure.trg_ChargingPoint_StatusHistory` | `EXEC`, `UPDATE Infrastructure` | `operations_staff/03_update_point_status.sql` |
| 4 | Xem session đang chạy | Theo dõi các phiên đang sạc | `ChargingSession`, `ChargingPoint`, `ChargingStation`, `UserAccount`, `Vehicle` | `AppView.vw_ActiveChargingSessions` | `SELECT AppView` | `operations_staff/04_view_active_sessions.sql` |
| 5 | Đánh dấu session lỗi | Chuyển session `Charging/Pending` sang `Failed`, giải phóng point | `ChargingSession`, `ChargingPoint`, `SessionEvent`, `AuditLog` | `Operations.sp_MarkChargingSessionFailed`, `Operations.trg_ChargingSession_Audit` | `EXEC Operations` | `operations_staff/05_mark_session_failed.sql` |
| 6 | Ghi nhận lỗi thiết bị | Tạo error log và ticket tự động | `Maintenance.ErrorLog`, `Maintenance.MaintenanceTicket`, `ChargingPoint` | `Maintenance.sp_ReportError` | `EXEC Maintenance` | `operations_staff/06_report_error.sql` |
| 7 | Quản lý ticket bảo trì | Lập lịch, phân công, đóng ticket | `MaintenanceTicket`, `ErrorLog`, `ChargingPoint`, `AuditLog` | `Maintenance.sp_ScheduleMaintenance`, `sp_AssignTicket`, `sp_CloseTicket` | `EXEC Maintenance` | `operations_staff/07_assign_and_close_ticket.sql` |
| 8 | Xem telemetry health | Xem mẫu telemetry cảnh báo/lỗi/offline | `PointTelemetry`, `ChargingPoint`, `ChargingStation`, `ConnectorType` | `AppView.sp_GetTelemetryHealth` | `EXEC` | `operations_staff/08_view_telemetry_health.sql` |

### Luồng thao tác tiêu biểu

1. Operator xem `AppView.vw_StationStatusOverview`.
2. Khi phát hiện point cần đổi trạng thái, operator gọi `Infrastructure.sp_UpdateChargingPointStatus`.
3. Procedure kiểm tra status và health hợp lệ.
4. Procedure update `Infrastructure.ChargingPoint`.
5. Trigger `Infrastructure.trg_ChargingPoint_StatusHistory` tự ghi `PointStatusHistory` và `Audit.AuditLog`.
6. Nếu lỗi nghiêm trọng, operator gọi `Maintenance.sp_ReportError`, hệ thống tạo `ErrorLog` và `MaintenanceTicket`.

### Gợi ý demo

| Bước | Script |
|---:|---|
| 1 | `operations_staff/01_view_station_status.sql` |
| 2 | `operations_staff/03_update_point_status.sql` |
| 3 | `operations_staff/06_report_error.sql` |
| 4 | `operations_staff/07_assign_and_close_ticket.sql` |
| 5 | `operations_staff/08_view_telemetry_health.sql` |

## 4.3. Business Manager

### Mục đích

Business Manager đại diện cho quản lý kinh doanh. Role này xem báo cáo doanh thu, KPI, khách hàng, giờ cao điểm, franchise profit sharing và chạy quyết toán doanh thu cho đối tác.

### Tính năng chính

| STT | Tính năng | Mô tả nghiệp vụ | Bảng liên quan | View/Procedure/Function/Trigger liên quan | Quyền cần có | Nguồn |
|---:|---|---|---|---|---|---|
| 1 | Xem doanh thu theo trạm | Tổng hợp doanh thu, kWh, số session theo trạm | `ChargingSession`, `ChargingStation`, `FranchisePartner` | `AppView.vw_StationRevenueDaily`, `AppView.sp_GetStationRevenue` | `SELECT/EXEC AppView` | `business_manager/02_view_station_revenue.sql` |
| 2 | Xem doanh thu theo khu vực | Tổng hợp revenue theo region | `Region`, `Address`, `ChargingStation`, `ChargingSession` | `AppView.vw_RegionRevenue` | `SELECT` | `business_manager/03_view_region_revenue.sql` |
| 3 | Xem top trạm doanh thu | Xếp hạng trạm theo revenue | `ChargingStation`, `ChargingSession` | `AppView.vw_TopRevenueStations` | `SELECT` | `business_manager/04_view_top_revenue_stations.sql` |
| 4 | Xem giờ cao điểm | Phân tích session/revenue theo giờ bắt đầu | `ChargingSession` | `AppView.vw_PeakHourStatistics` | `SELECT` | `business_manager/05_view_peak_hours.sql` |
| 5 | Cập nhật revenue share policy | Thay đổi tỷ lệ chia doanh thu | `Franchise.RevenueSharePolicy`, `AuditLog` | `Franchise.sp_UpdateRevenueSharePolicy` | `EXEC` | `business_manager/06_update_revenue_share_policy.sql` |
| 6 | Tạo revenue settlement | Quyết toán doanh thu theo kỳ cho franchise | `RevenueShareSettlement`, `ChargingSession`, `ChargingStation`, `FranchiseContract`, `RevenueSharePolicy` | `Franchise.sp_CreateRevenueSettlement`, `Franchise.fn_CalculatePartnerShare` | `EXEC` | `business_manager/07_create_revenue_settlement.sql` |
| 7 | Xem profit sharing | Xem gross revenue, partner share, platform share | `RevenueShareSettlement`, `FranchisePartner`, `FranchiseContract` | `AppView.vw_ProfitSharing`, `AppView.sp_GetFranchiseProfitSharing` | `SELECT/EXEC` | `business_manager/08_view_franchise_profit.sql` |
| 8 | Xem tăng trưởng khách hàng | Đếm customer mới theo tháng | `UserAccount`, `UserRole`, `Role` | `AppView.vw_CustomerGrowth` | `SELECT` | `business_manager/09_view_customer_growth.sql` |
| 9 | Xem KPI hệ thống | Số trạm, cổng, session, lỗi, ticket, revenue | Nhiều bảng | `AppView.vw_SystemOperationalKPI`, `vw_TopCustomerUsage` | `SELECT` | `business_manager/10_view_system_kpi.sql` |
| 10 | Quản lý pricing policy | Tạo và vô hiệu hóa chính sách giá | `Operations.PricingPolicy`, `AuditLog` | `Operations.sp_CreatePricingPolicy`, `sp_DeactivatePricingPolicy` | Có script demo, nhưng `08_Create_Security.sql` chưa grant EXEC cho `db_ev_business_manager` | `business_manager/01_manage_pricing_policy.sql` |
| 11 | Hoàn tiền cơ bản | Chuyển payment/invoice sang `Refunded` | `PaymentTransaction`, `Invoice`, `AuditLog` | `Payments.sp_RefundPayment` | Có script demo, nhưng `08_Create_Security.sql` chưa grant EXEC cho `db_ev_business_manager` | `business_manager/11_refund_payment.sql` |

### Luồng thao tác tiêu biểu

1. Manager xem `AppView.vw_TopRevenueStations` hoặc gọi `AppView.sp_GetStationRevenue`.
2. Manager chọn franchise và period cần quyết toán.
3. Manager gọi `Franchise.sp_CreateRevenueSettlement`.
4. Procedure tìm contract active và revenue share policy active.
5. Procedure tổng hợp `CostBeforeTax` từ `Operations.ChargingSession` completed theo franchise.
6. Function `Franchise.fn_CalculatePartnerShare` tính phần đối tác.
7. Insert `Franchise.RevenueShareSettlement` với `SettlementStatus = 'Approved'`.
8. Ghi `Audit.AuditLog` với `ActionType = 'SETTLEMENT'`.

### Gợi ý demo

| Bước | Script |
|---:|---|
| 1 | `business_manager/02_view_station_revenue.sql` |
| 2 | `business_manager/04_view_top_revenue_stations.sql` |
| 3 | `business_manager/06_update_revenue_share_policy.sql` |
| 4 | `business_manager/07_create_revenue_settlement.sql` |
| 5 | `business_manager/08_view_franchise_profit.sql` |
| 6 | `security/03_business_permissions.sql` để chứng minh không đọc trực tiếp bảng `Payments` và không update `Infrastructure` |

## 4.4. Customer

### Mục đích

Customer đại diện cho người dùng sử dụng dịch vụ sạc xe điện. Role này xem trạm/cổng khả dụng, quản lý xe, đặt lịch, bắt đầu/kết thúc phiên sạc, thanh toán và xem hóa đơn.

### Tính năng chính

| STT | Tính năng | Mô tả nghiệp vụ | Bảng liên quan | View/Procedure/Function/Trigger liên quan | Quyền cần có | Nguồn |
|---:|---|---|---|---|---|---|
| 1 | Xem trạm/cổng khả dụng | Tìm point có thể đặt hoặc bắt đầu sạc | `ChargingStation`, `ChargingPoint`, `ConnectorType`, `Address`, `Region` | `AppView.vw_AvailableChargingPoints` | `SELECT` | `customer/01_view_available_stations.sql` |
| 2 | Thêm xe | Tạo hồ sơ xe mới | `Operations.Vehicle`, `AuditLog` | `Operations.sp_CreateVehicle` | `EXEC` | `customer/02_create_vehicle.sql` |
| 3 | Cập nhật xe | Sửa thông tin xe hoặc soft delete bằng `IsActive` | `Operations.Vehicle`, `AuditLog` | `Operations.sp_UpdateVehicle` | `EXEC` | `customer/03_update_vehicle.sql`, `security/07_soft_delete_demo.sql` |
| 4 | Tạo booking | Đặt trước cổng sạc theo khung giờ | `Operations.Booking`, `AuditLog` | `Operations.sp_CreateBooking` | `EXEC` | `customer/04_create_booking.sql` |
| 5 | Hủy booking | Hủy booking còn hiệu lực | `Operations.Booking`, `AuditLog` | `Operations.sp_CancelBooking` | `EXEC` | `customer/05_cancel_booking.sql` |
| 6 | Xem lịch sử booking | Xem các lần đặt lịch | `Booking`, `UserAccount`, `Vehicle`, `ChargingPoint`, `ChargingStation` | `AppView.vw_CustomerBookingHistory` | `SELECT` | `customer/06_view_booking_history.sql` |
| 7 | Bắt đầu/kết thúc phiên sạc | Tạo session, tính kWh, chi phí, giải phóng point | `ChargingSession`, `ChargingPoint`, `SessionEvent`, `Booking` | `Operations.sp_StartChargingSession`, `sp_EndChargingSession`, `Operations.fn_CalculateChargingCost` | `EXEC` | `customer/07_start_end_charging_session.sql` |
| 8 | Xem lịch sử sạc | Xem session, trạm, cổng, xe, kWh, chi phí | `ChargingSession`, `UserAccount`, `Vehicle`, `ChargingStation`, `ChargingPoint`, `ConnectorType` | `AppView.vw_CustomerChargingHistory` | `SELECT` | `customer/08_view_charging_history.sql` |
| 9 | Thanh toán | Tạo giao dịch thanh toán cho session completed | `PaymentTransaction`, `ChargingSession`, `AuditLog` | `Payments.sp_CreatePayment`, `Payments.trg_PaymentTransaction_Audit` | `EXEC` | `customer/09_create_payment_invoice.sql` |
| 10 | Lập hóa đơn | Tạo invoice cho session completed | `Invoice`, `PaymentTransaction`, `ChargingSession` | `Payments.sp_CreateInvoice` | `EXEC` | `customer/09_create_payment_invoice.sql` |
| 11 | Xem chi tiết hóa đơn | Xem invoice, payment, session, station, point | `Invoice`, `PaymentTransaction`, `ChargingSession`, `UserAccount`, `ChargingStation`, `ChargingPoint` | `AppView.vw_InvoiceDetail` | `SELECT` | `customer/10_view_invoice_detail.sql` |

### Luồng thao tác tiêu biểu

1. Customer xem `AppView.vw_AvailableChargingPoints`.
2. Customer tạo xe bằng `Operations.sp_CreateVehicle` nếu chưa có xe.
3. Customer tạo booking bằng `Operations.sp_CreateBooking`.
4. Procedure kiểm tra user active, vehicle thuộc user, point bookable, không overlap.
5. Customer bắt đầu session bằng `Operations.sp_StartChargingSession`.
6. Point chuyển sang `Charging`, session event `Started` được ghi.
7. Customer kết thúc session bằng `Operations.sp_EndChargingSession`.
8. Procedure tính chi phí bằng `Operations.fn_CalculateChargingCost`.
9. Customer thanh toán bằng `Payments.sp_CreatePayment`.
10. Customer tạo invoice bằng `Payments.sp_CreateInvoice`.

### Gợi ý demo

| Bước | Script |
|---:|---|
| 1 | `customer/01_view_available_stations.sql` |
| 2 | `customer/02_create_vehicle.sql` |
| 3 | `customer/04_create_booking.sql` |
| 4 | `customer/07_start_end_charging_session.sql` |
| 5 | `customer/09_create_payment_invoice.sql` |
| 6 | `customer/10_view_invoice_detail.sql` |
| 7 | `security/01_customer_permissions.sql` để chứng minh customer không đọc trực tiếp `Payments` và `Identity` |

## 4.5. Franchise Partner

### Mục đích

Franchise Partner là doanh nghiệp nhượng quyền/sở hữu hoặc vận hành trạm sạc. Trong source hiện tại, franchise partner là dữ liệu nghiệp vụ trong schema `Franchise`, chưa thấy database role, user login hoặc script demo riêng cho actor này.

### Tính năng chính

| STT | Tính năng | Mô tả nghiệp vụ | Bảng liên quan | View/Procedure/Function/Trigger liên quan | Quyền cần có | Nguồn |
|---:|---|---|---|---|---|---|
| 1 | Lưu thông tin đối tác | Quản lý mã, tên, mã số thuế, liên hệ | `Franchise.FranchisePartner` | Chưa thấy procedure CRUD riêng | Chưa có role riêng | `database/02_Create_Tables.sql` |
| 2 | Lưu hợp đồng | Quản lý thời hạn và tỷ lệ chia cơ bản | `Franchise.FranchiseContract` | Chưa thấy procedure CRUD riêng | Chưa có role riêng | `database/02_Create_Tables.sql` |
| 3 | Gắn trạm với franchise | Liên kết trạm với partner/contract | `Franchise.FranchiseStation`, `Infrastructure.ChargingStation` | Seed data insert trực tiếp | Chưa có role riêng | `database/09_Seed_Demo_Data.sql` |
| 4 | Xem kết quả chia doanh thu | Xem settlement đã tạo | `RevenueShareSettlement`, `FranchisePartner`, `FranchiseContract` | `AppView.vw_ProfitSharing`, `AppView.sp_GetFranchiseProfitSharing` | Hiện grant cho Business Manager, chưa có role Franchise Partner | `database/07_Create_AppViews.sql` |

### Luồng thao tác tiêu biểu

1. Seed data tạo `Franchise.FranchisePartner`.
2. Seed data tạo `Franchise.FranchiseContract`.
3. Seed data tạo `Franchise.RevenueSharePolicy`.
4. Station được gắn với partner qua `Infrastructure.ChargingStation.FranchiseID` và `Franchise.FranchiseStation`.
5. Business Manager tạo settlement bằng `Franchise.sp_CreateRevenueSettlement`.
6. Franchise Partner chưa có luồng đăng nhập/đọc dữ liệu riêng trong security script.

### Gợi ý demo

Vì chưa có role riêng, nên demo franchise thông qua Business Manager:

| Bước | Script |
|---:|---|
| 1 | `business_manager/07_create_revenue_settlement.sql` |
| 2 | `business_manager/08_view_franchise_profit.sql` |
| 3 | Trình bày rõ: Franchise Partner là đối tượng dữ liệu, không phải principal bảo mật trong source hiện tại |

# 5. Phân tích tính năng theo module hệ thống

| Module | Tính năng hiện có | Bảng chính | Object xử lý | Ghi chú |
|---|---|---|---|---|
| Quản lý tài khoản và phân quyền | Tạo user, khóa/mở khóa, reset password, gán/gỡ role, xem user-role | `UserAccount`, `Role`, `UserRole` | `[Identity].sp_CreateUser`, `sp_LockUser`, `sp_UnlockUser`, `sp_ResetPassword`, `sp_AssignRole`, `sp_RemoveRole`, `vw_UserRoleSummary` | Có RBAC SQL Server và logical role trong dữ liệu |
| Quản lý khu vực/địa chỉ | Lưu region, address, tọa độ | `Region`, `Address` | Chưa thấy procedure CRUD riêng | Seed data insert trực tiếp |
| Quản lý trạm sạc | Tạo trạm, cập nhật trạng thái, xem status overview | `ChargingStation` | `Infrastructure.sp_CreateChargingStation`, `sp_UpdateStationStatus`, `vw_StationStatusOverview` | Operations Staff có quyền thao tác |
| Quản lý cổng sạc | Tạo point, cập nhật status/health, ghi history | `ChargingPoint`, `PointStatusHistory` | `Infrastructure.sp_CreateChargingPoint`, `sp_UpdateChargingPointStatus`, `trg_ChargingPoint_StatusHistory` | Trigger tự ghi history |
| Quản lý xe khách hàng | Thêm/sửa/soft delete xe | `Vehicle` | `Operations.sp_CreateVehicle`, `sp_UpdateVehicle` | Soft delete bằng `IsActive` |
| Đặt lịch sạc | Tạo/hủy booking, chống overlap | `Booking` | `Operations.sp_CreateBooking`, `sp_CancelBooking`, `vw_CustomerBookingHistory` | Có negative tests |
| Phiên sạc | Start/end/mark failed session, tính giá | `ChargingSession`, `SessionEvent`, `ChargingPoint` | `sp_StartChargingSession`, `sp_EndChargingSession`, `sp_MarkChargingSessionFailed`, `fn_CalculateChargingCost`, `trg_ChargingSession_Audit` | Bảng lõi |
| Thanh toán và hóa đơn | Tạo payment, refund, invoice | `PaymentTransaction`, `Invoice` | `Payments.sp_CreatePayment`, `sp_RefundPayment`, `sp_CreateInvoice`, `trg_PaymentTransaction_Audit` | Refund không có bảng riêng |
| Quản lý doanh nghiệp nhượng quyền | Lưu partner, station ownership | `FranchisePartner`, `FranchiseStation`, `ChargingStation` | Chưa thấy procedure CRUD riêng | Seed data tạo partner/station |
| Hợp đồng nhượng quyền | Lưu contract active/expired | `FranchiseContract` | Chưa thấy procedure CRUD riêng | Dùng trong settlement |
| Chính sách chia doanh thu | Cập nhật partner share rate | `RevenueSharePolicy` | `Franchise.sp_UpdateRevenueSharePolicy` | Business Manager được grant EXEC |
| Quyết toán doanh thu | Tạo settlement theo period | `RevenueShareSettlement` | `Franchise.sp_CreateRevenueSettlement`, `fn_CalculatePartnerShare`, `vw_ProfitSharing` | Có audit `SETTLEMENT` |
| Telemetry/giám sát | Lưu telemetry và xem health issue | `PointTelemetry` | `AppView.sp_GetTelemetryHealth` | Seed data tạo 219000 samples |
| Bảo trì/lỗi | Report error, tạo/assign/close ticket | `ErrorLog`, `MaintenanceTicket` | `Maintenance.sp_ReportError`, `sp_ScheduleMaintenance`, `sp_AssignTicket`, `sp_CloseTicket` | Operations Staff |
| Báo cáo/thống kê | Revenue, KPI, peak hour, customer growth, top customer | Nhiều bảng | 20 view, 6 AppView procedure | Tập trung trong schema `AppView` |
| Audit/log | Ghi audit và chặn xóa audit | `AuditLog` | audit inserts trong procedure, 4 trigger | `Audit.trg_AuditLog_BlockDelete` chặn delete |
| Backup/restore | Script mẫu backup/restore | Database-level | `database/12_Backup_Restore.sql` | Không phải stored procedure |

# 6. Ma trận role - chức năng

Ký hiệu: `C` = Create, `R` = Read, `U` = Update, `D` = Delete, `EXEC` = được chạy procedure, `VIEW` = được xem view, `-` = không có quyền hoặc chưa thấy trong source.

| Chức năng | System Admin | Operations Staff | Business Manager | Customer | Franchise Partner | Ghi chú |
|---|---|---|---|---|---|---|
| Quản lý tài khoản | C/R/U/D/EXEC | - | - | - | - | Admin được DML schema `Identity`; các role khác bị DENY direct `Identity` |
| Xem user-role summary | VIEW | - | - | - | - | `vw_UserRoleSummary` chủ yếu demo admin |
| Quản lý khu vực/địa chỉ | C/R/U/D | - | R qua report | - | - | Không có procedure CRUD riêng |
| Quản lý trạm sạc | C/R/U/D/EXEC | C/R/U/EXEC | VIEW | VIEW | - | Manager bị DENY INSERT/UPDATE/DELETE `Infrastructure` |
| Quản lý cổng sạc | C/R/U/D/EXEC | C/R/U/EXEC | VIEW | VIEW | - | Customer xem point available qua view |
| Quản lý xe khách hàng | C/R/U/D/EXEC | R/U theo schema Operations | - | EXEC | - | Customer dùng procedure, không grant table trực tiếp |
| Đặt lịch sạc | C/R/U/D/EXEC | R/U theo schema Operations | VIEW báo cáo | EXEC/VIEW | - | Customer tạo/hủy booking qua procedure |
| Phiên sạc | C/R/U/D/EXEC | C/R/U/EXEC | VIEW báo cáo | EXEC/VIEW | - | Operations có thể mark failed |
| Thanh toán | C/R/U/D/EXEC | DENY | DENY direct; refund script có nhưng chưa grant EXEC trong security core | EXEC create payment | - | Business Manager không được đọc trực tiếp `Payments` |
| Hóa đơn | C/R/U/D/EXEC | DENY | DENY direct | EXEC/VIEW | - | Customer xem qua `vw_InvoiceDetail` |
| Franchise partner/contract | C/R/U/D/EXEC | - | R/EXEC settlement-policy | - | - | Chưa có role Franchise Partner |
| Revenue share policy | C/R/U/D/EXEC | - | EXEC update policy | - | - | Grant trong security core |
| Revenue settlement | C/R/U/D/EXEC | - | EXEC/VIEW | - | - | Grant trong security core |
| Telemetry | C/R/U/D | R/EXEC report | VIEW KPI gián tiếp | - | - | Operations xem `sp_GetTelemetryHealth` |
| Maintenance/lỗi | C/R/U/D/EXEC | C/R/U/EXEC | VIEW KPI | - | - | Manager không được mutate Maintenance |
| Báo cáo/thống kê | R/EXEC | VIEW/EXEC một số report | VIEW/EXEC report kinh doanh | VIEW/EXEC customer usage | - | AppView là read model |
| Audit/log | C/R/U/D nhưng delete bị trigger chặn | - | - | - | - | `trg_AuditLog_BlockDelete` chặn delete |
| Backup/restore | Script mẫu | - | - | - | - | Cần quyền SQL Server tương ứng |

# 7. Ma trận tính năng - database object

| Tính năng | Bảng chính | Procedure | View | Function | Trigger | Ghi chú |
|---|---|---|---|---|---|---|
| Tạo tài khoản | `UserAccount`, `UserRole`, `Role`, `AuditLog` | `[Identity].sp_CreateUser` | `vw_UserRoleSummary` | - | - | Có transaction và audit |
| Khóa/mở khóa user | `UserAccount`, `AuditLog` | `sp_LockUser`, `sp_UnlockUser` | - | - | - | Ghi audit `SECURITY` |
| Gán/gỡ role | `UserRole`, `Role`, `UserAccount`, `AuditLog` | `sp_AssignRole`, `sp_RemoveRole` | `vw_UserRoleSummary` | - | - | Không cho duplicate do PK |
| Xem điểm sạc khả dụng | `ChargingPoint`, `ChargingStation`, `ConnectorType`, `Address`, `Region` | - | `vw_AvailableChargingPoints` | - | - | Customer-facing view |
| Tạo/cập nhật xe | `Vehicle`, `AuditLog` | `sp_CreateVehicle`, `sp_UpdateVehicle` | - | - | - | Kiểm tra user active và ownership |
| Tạo/hủy booking | `Booking`, `AuditLog` | `sp_CreateBooking`, `sp_CancelBooking` | `vw_CustomerBookingHistory` | - | - | Có check overlap |
| Start/end session | `ChargingSession`, `ChargingPoint`, `SessionEvent`, `Booking` | `sp_StartChargingSession`, `sp_EndChargingSession` | `vw_CustomerChargingHistory`, `vw_ActiveChargingSessions` | `fn_CalculateChargingCost` | `trg_ChargingSession_Audit`, `trg_ChargingPoint_StatusHistory` | Luồng lõi |
| Mark session failed | `ChargingSession`, `ChargingPoint`, `SessionEvent`, `AuditLog` | `sp_MarkChargingSessionFailed` | `vw_ActiveChargingSessions` | - | `trg_ChargingSession_Audit` | Operations Staff |
| Tạo payment | `PaymentTransaction`, `ChargingSession`, `AuditLog` | `sp_CreatePayment` | `vw_PaymentSummary` | - | `trg_PaymentTransaction_Audit` | Chặn duplicate completed payment |
| Refund | `PaymentTransaction`, `Invoice`, `AuditLog` | `sp_RefundPayment` | `vw_PaymentSummary`, `vw_InvoiceDetail` | - | `trg_PaymentTransaction_Audit` | Không có bảng refund riêng |
| Tạo invoice | `Invoice`, `PaymentTransaction`, `ChargingSession` | `sp_CreateInvoice` | `vw_InvoiceDetail` | - | - | Chặn duplicate invoice theo session |
| Cập nhật station/point status | `ChargingStation`, `ChargingPoint`, `PointStatusHistory`, `AuditLog` | `sp_UpdateStationStatus`, `sp_UpdateChargingPointStatus` | `vw_StationStatusOverview` | - | `trg_ChargingPoint_StatusHistory` | Operations Staff |
| Report error/ticket | `ErrorLog`, `MaintenanceTicket`, `ChargingPoint`, `AuditLog` | `sp_ReportError`, `sp_ScheduleMaintenance`, `sp_AssignTicket`, `sp_CloseTicket` | `vw_MaintenanceKPI` | - | - | Tích hợp bảo trì |
| Revenue settlement | `RevenueShareSettlement`, `RevenueSharePolicy`, `FranchiseContract`, `ChargingSession`, `ChargingStation` | `sp_CreateRevenueSettlement`, `sp_UpdateRevenueSharePolicy` | `vw_ProfitSharing`, `vw_FranchiseRevenueMonthly` | `fn_CalculatePartnerShare` | - | Business Manager |
| Báo cáo doanh thu/KPI | `ChargingSession`, `ChargingStation`, `PaymentTransaction`, `MaintenanceTicket`, nhiều bảng | `AppView.sp_GetStationRevenue`, `sp_GetOperationalKPI`, `sp_GetPaymentSummary` | 20 view `AppView` | `fn_PointUtilizationRate` | - | Read model |
| Audit/log | `AuditLog` | Ghi audit trong nhiều procedure | - | - | `trg_AuditLog_BlockDelete` | Chặn xóa audit |

# 8. Luồng nghiệp vụ chính

## 8.1. Booking Flow

| Hạng mục | Nội dung |
|---|---|
| Mục đích | Customer đặt trước cổng sạc trong khung giờ hợp lệ |
| Actor | Customer |
| Điều kiện đầu vào | User active, vehicle thuộc user nếu có, point tồn tại, point có status `Available` hoặc `Reserved`, thời gian hợp lệ |
| Procedure/view | `AppView.vw_AvailableChargingPoints`, `Operations.sp_CreateBooking` |
| Bảng ảnh hưởng | `Operations.Booking`, `Audit.AuditLog` |
| Kết quả | Booking mới có `BookingStatus = 'Confirmed'` |

Các bước xử lý:

1. Customer xem `AppView.vw_AvailableChargingPoints`.
2. Customer chọn `PointID`, `VehicleID`, `BookedFrom`, `BookedTo`.
3. Gọi `Operations.sp_CreateBooking`.
4. Procedure kiểm tra `BookedFrom < BookedTo`.
5. Procedure kiểm tra user active trong `[Identity].UserAccount`.
6. Procedure kiểm tra vehicle thuộc user và `IsActive = 1`.
7. Procedure kiểm tra point tồn tại và bookable.
8. Procedure kiểm tra không có booking overlap trên cùng `PointID`.
9. Insert `Operations.Booking`.
10. Insert audit log.

Exception trong source:

| Mã lỗi | Nội dung |
|---|---|
| `52040` | `BookedFrom must be before BookedTo.` |
| `52041` | `Active user does not exist.` |
| `52042` | `Vehicle does not belong to user.` |
| `52043` | `Charging point does not exist.` |
| `52044` | `Charging point is not bookable.` |
| `52045` | `Charging point already has an overlapping booking.` |

## 8.2. Charging Session Flow

| Hạng mục | Nội dung |
|---|---|
| Mục đích | Ghi nhận phiên sạc, trạng thái point, năng lượng và chi phí |
| Actor | Customer; Operations Staff có thể xử lý lỗi session |
| Điều kiện đầu vào | Point `Available`, user active, có active pricing policy |
| Procedure/view | `Operations.sp_StartChargingSession`, `Operations.sp_EndChargingSession`, `Operations.sp_MarkChargingSessionFailed`, `Operations.fn_CalculateChargingCost` |
| Bảng ảnh hưởng | `ChargingSession`, `ChargingPoint`, `Booking`, `SessionEvent`, `AuditLog`, `PointStatusHistory` |
| Kết quả | Session `Completed` hoặc `Failed`, point được giải phóng |

Các bước xử lý start:

1. Gọi `Operations.sp_StartChargingSession`.
2. Kiểm tra point tồn tại và `PointStatus = 'Available'`.
3. Kiểm tra user active.
4. Lấy pricing policy active mới nhất.
5. Insert `Operations.ChargingSession` với `SessionStatus = 'Charging'`.
6. Update `Infrastructure.ChargingPoint` sang `Charging`.
7. Nếu có `BookingID`, update booking sang `Active`.
8. Insert `Operations.SessionEvent` với event `Started`.

Các bước xử lý end:

1. Gọi `Operations.sp_EndChargingSession`.
2. Kiểm tra session tồn tại và status `Charging`.
3. Tính `TotalKWh` từ meter nếu cần.
4. Kiểm tra `TotalKWh > 0`.
5. Gọi `Operations.fn_CalculateChargingCost`.
6. Tính tax 8%.
7. Update session sang `Completed`.
8. Update point sang `Available`.
9. Insert session event `Completed`.

Exception trong source:

| Mã lỗi | Nội dung |
|---|---|
| `52001` | Charging point does not exist |
| `52002` | Charging point is not available |
| `52003` | User account is not active |
| `52004` | No active pricing policy |
| `52010` | Charging session does not exist |
| `52011` | Charging session is not in Charging status |
| `52012` | Total kWh must be positive |
| `52060` | Charging session does not exist |
| `52061` | Only pending or charging sessions can be marked as failed |

## 8.3. Payment Flow

| Hạng mục | Nội dung |
|---|---|
| Mục đích | Tạo giao dịch thanh toán cho phiên sạc đã hoàn tất |
| Actor | Customer |
| Điều kiện đầu vào | Session `Completed`, session thuộc user, amount hợp lệ, chưa có payment completed |
| Procedure/view | `Payments.sp_CreatePayment`, `AppView.vw_PaymentSummary` |
| Bảng ảnh hưởng | `Payments.PaymentTransaction`, `Audit.AuditLog` |
| Kết quả | Payment transaction `Completed` |

Exception trong source:

| Mã lỗi | Nội dung |
|---|---|
| `53010` | Session must be completed before payment |
| `53011` | Session does not belong to user |
| `53012` | Invalid payment amount |
| `53013` | Invalid payment method |
| `53014` | Session has already been paid |

## 8.4. Invoice Flow

| Hạng mục | Nội dung |
|---|---|
| Mục đích | Tạo hóa đơn cho phiên sạc completed |
| Actor | Customer |
| Điều kiện đầu vào | Session completed; invoice chưa tồn tại |
| Procedure/view | `Payments.sp_CreateInvoice`, `AppView.vw_InvoiceDetail` |
| Bảng ảnh hưởng | `Payments.Invoice` |
| Kết quả | Invoice `Paid` nếu có completed transaction, ngược lại `Issued` |

Exception trong source:

| Mã lỗi | Nội dung |
|---|---|
| `53020` | Invoice already exists |
| `53021` | Cannot create invoice for incomplete session |

## 8.5. Franchise Revenue Settlement Flow

| Hạng mục | Nội dung |
|---|---|
| Mục đích | Chốt doanh thu theo kỳ cho franchise partner |
| Actor | Business Manager |
| Điều kiện đầu vào | Franchise có contract active và revenue share policy active |
| Procedure/view/function | `Franchise.sp_CreateRevenueSettlement`, `Franchise.fn_CalculatePartnerShare`, `AppView.vw_ProfitSharing` |
| Bảng ảnh hưởng | `RevenueShareSettlement`, `AuditLog`; đọc `ChargingSession`, `ChargingStation`, `FranchiseContract`, `RevenueSharePolicy` |
| Kết quả | Settlement được tạo với `SettlementStatus = 'Approved'` |

Exception trong source:

| Mã lỗi | Nội dung |
|---|---|
| `55001` | Active franchise contract not found |
| `55010` | Partner share rate must be between 0 and 100 |
| `55011` | Revenue share policy does not exist |

## 8.6. Maintenance Flow

| Hạng mục | Nội dung |
|---|---|
| Mục đích | Ghi nhận lỗi thiết bị và xử lý ticket bảo trì |
| Actor | Operations Staff |
| Điều kiện đầu vào | Severity/priority hợp lệ, station hoặc point hợp lệ |
| Procedure/view | `Maintenance.sp_ReportError`, `sp_ScheduleMaintenance`, `sp_AssignTicket`, `sp_CloseTicket`, `AppView.vw_MaintenanceKPI` |
| Bảng ảnh hưởng | `ErrorLog`, `MaintenanceTicket`, `ChargingPoint`, `AuditLog` |
| Kết quả | Lỗi/ticket được ghi nhận; point có thể chuyển `Error`/`Maintenance`; khi close thì về `Available`/`Normal` |

Exception trong source:

| Mã lỗi | Nội dung |
|---|---|
| `54001` | Invalid severity |
| `54010` | Ticket cannot be assigned |
| `54011` | Assigned user does not exist or is not active |
| `54012` | Invalid priority |
| `54013` | StationID or PointID is required |
| `54014` | Charging point does not exist |
| `54015` | Charging station does not exist |
| `54020` | Ticket cannot be closed |

## 8.7. Reporting Flow

| Hạng mục | Nội dung |
|---|---|
| Mục đích | Cung cấp dataset báo cáo/KPI không cần đọc trực tiếp bảng gốc |
| Actor | Business Manager, Operations Staff, Customer, System Admin |
| Điều kiện đầu vào | Seed data hoặc dữ liệu nghiệp vụ đã có |
| Procedure/view | 20 view và 6 procedure trong `AppView` |
| Bảng ảnh hưởng | Chỉ đọc dữ liệu, không ghi |
| Kết quả | Dataset doanh thu, KPI, lịch sử, top station/customer, telemetry health |

## 8.8. Security/RBAC Flow

| Hạng mục | Nội dung |
|---|---|
| Mục đích | Chứng minh phân quyền theo role bằng SQL Server principal |
| Actor | Admin, operator, business, customer |
| Điều kiện đầu vào | Đã chạy `08_Create_Security.sql` |
| Script | `features/security/01_customer_permissions.sql` đến `04_admin_permissions.sql` |
| Bảng ảnh hưởng | Chủ yếu đọc thử và bắt lỗi permission denied |
| Kết quả | Role chỉ truy cập được view/procedure phù hợp; bị chặn bảng nhạy cảm |

# 9. Phân tích stored procedure

| Procedure | Schema | Mục đích | Tham số chính | Bảng đọc | Bảng ghi | Transaction/Error handling | Role phù hợp |
|---|---|---|---|---|---|---|---|
| `sp_CreateUser` | `Identity` | Tạo user và gán role | username, email, password hash, role code | `Role` | `UserAccount`, `UserRole`, `AuditLog` | Có transaction, TRY/CATCH, THROW | System Admin |
| `sp_LockUser` | `Identity` | Khóa tài khoản | `UserID` | `UserAccount` | `UserAccount`, `AuditLog` | Có | System Admin |
| `sp_UnlockUser` | `Identity` | Mở khóa tài khoản | `UserID` | `UserAccount` | `UserAccount`, `AuditLog` | Có | System Admin |
| `sp_ResetPassword` | `Identity` | Reset password hash | `UserID`, `PasswordHash` | `UserAccount` | `UserAccount`, `AuditLog` | Có | System Admin |
| `sp_AssignRole` | `Identity` | Gán role | `UserID`, `RoleCode` | `Role`, `UserAccount`, `UserRole` | `UserRole`, `AuditLog` | Có | System Admin |
| `sp_RemoveRole` | `Identity` | Gỡ role | `UserID`, `RoleCode` | `Role`, `UserRole`, `UserAccount` | `UserRole`, `AuditLog` | Có | System Admin |
| `sp_CreateChargingStation` | `Infrastructure` | Tạo trạm sạc | station info, franchise, address, supplier, operator | - | `ChargingStation`, `AuditLog` | Có | System Admin, Operations Staff |
| `sp_CreateChargingPoint` | `Infrastructure` | Tạo cổng sạc | point code, station, connector, power | `StationConnectorType` | `ChargingPoint`, `StationConnectorType`, `AuditLog` | Có | System Admin, Operations Staff |
| `sp_UpdateStationStatus` | `Infrastructure` | Đổi trạng thái trạm | `StationID`, status, changed by | `ChargingStation` | `ChargingStation`, `AuditLog` | Có | Operations Staff |
| `sp_UpdateChargingPointStatus` | `Infrastructure` | Đổi trạng thái/health cổng | `PointID`, point status, health | `ChargingPoint` | `ChargingPoint`, `AuditLog`; trigger ghi history | Có | Operations Staff |
| `sp_CreateVehicle` | `Operations` | Tạo xe | user, plate, brand, model, battery, connector | `UserAccount`, `ConnectorType` | `Vehicle`, `AuditLog` | Có | Customer |
| `sp_UpdateVehicle` | `Operations` | Cập nhật xe | vehicle, user, thông tin xe | `Vehicle`, `ConnectorType` | `Vehicle`, `AuditLog` | Có | Customer |
| `sp_CreateBooking` | `Operations` | Tạo booking | user, vehicle, point, from/to | `UserAccount`, `Vehicle`, `ChargingPoint`, `Booking` | `Booking`, `AuditLog` | Có | Customer |
| `sp_CancelBooking` | `Operations` | Hủy booking | booking, user optional | `Booking` | `Booking`, `AuditLog` | Có | Customer |
| `sp_StartChargingSession` | `Operations` | Bắt đầu session | user, vehicle, point, meter start, booking | `ChargingPoint`, `UserAccount`, `PricingPolicy` | `ChargingSession`, `ChargingPoint`, `Booking`, `SessionEvent` | Có | Customer |
| `sp_EndChargingSession` | `Operations` | Kết thúc session và tính tiền | session, meter end, total kWh, stop reason | `ChargingSession`, `PricingPolicy` qua function | `ChargingSession`, `ChargingPoint`, `SessionEvent` | Có | Customer |
| `sp_MarkChargingSessionFailed` | `Operations` | Đánh dấu session lỗi | session, failed by, reason | `ChargingSession` | `ChargingSession`, `ChargingPoint`, `SessionEvent`, `AuditLog` | Có | Operations Staff |
| `sp_CreatePayment` | `Payments` | Tạo payment | user, session, method | `ChargingSession`, `PaymentTransaction` | `PaymentTransaction`, `AuditLog` | Có | Customer |
| `sp_RefundPayment` | `Payments` | Hoàn tiền cơ bản | transaction, reason | `PaymentTransaction` | `PaymentTransaction`, `Invoice`, `AuditLog` | Có | Có script Business Manager, nhưng chưa grant trong security core |
| `sp_CreateInvoice` | `Payments` | Tạo invoice | session | `Invoice`, `ChargingSession`, `PaymentTransaction` | `Invoice` | Có | Customer |
| `sp_CreatePricingPolicy` | `Operations` | Tạo pricing policy | code, name, price, peak config, dates | - | `PricingPolicy`, `AuditLog` | Có | Có script Business Manager, nhưng chưa grant trong security core |
| `sp_DeactivatePricingPolicy` | `Operations` | Vô hiệu hóa pricing policy | `PolicyID` | `PricingPolicy` | `PricingPolicy`, `AuditLog` | Có | Có script Business Manager, nhưng chưa grant trong security core |
| `sp_ReportError` | `Maintenance` | Ghi lỗi và auto ticket | error, station, point, severity, description, created by | - | `ErrorLog`, `MaintenanceTicket`, `ChargingPoint` | Có | Operations Staff |
| `sp_AssignTicket` | `Maintenance` | Phân công ticket | ticket, assigned to, assigned by | `MaintenanceTicket`, `UserAccount` | `MaintenanceTicket`, `AuditLog` | Có | Operations Staff |
| `sp_ScheduleMaintenance` | `Maintenance` | Lập ticket bảo trì | station/point, created by, assigned, priority, title | `ChargingPoint`, `ChargingStation` | `MaintenanceTicket`, `ChargingPoint`, `AuditLog` | Có | Operations Staff |
| `sp_CloseTicket` | `Maintenance` | Đóng ticket | ticket, closed by | `MaintenanceTicket` | `MaintenanceTicket`, `ErrorLog`, `ChargingPoint` | Có | Operations Staff |
| `sp_UpdateRevenueSharePolicy` | `Franchise` | Cập nhật tỷ lệ chia | policy id, partner share, applied to | `RevenueSharePolicy` | `RevenueSharePolicy`, `AuditLog` | Có | Business Manager |
| `sp_CreateRevenueSettlement` | `Franchise` | Tạo quyết toán doanh thu | franchise, period start/end | `FranchiseContract`, `RevenueSharePolicy`, `ChargingSession`, `ChargingStation` | `RevenueShareSettlement`, `AuditLog` | Có | Business Manager |
| `sp_GetStationRevenue` | `AppView` | Báo cáo doanh thu trạm | from date, to date | `vw_StationRevenueDaily` | - | Không transaction, read-only | Business Manager |
| `sp_GetFranchiseProfitSharing` | `AppView` | Báo cáo chia lợi nhuận | - | `vw_ProfitSharing` | - | Read-only | Business Manager |
| `sp_GetOperationalKPI` | `AppView` | KPI maintenance | - | `vw_MaintenanceKPI` | - | Read-only | Operations Staff |
| `sp_GetPaymentSummary` | `AppView` | Tổng hợp payment | - | `vw_PaymentSummary` | - | Read-only | Business Manager |
| `sp_GetCustomerUsage` | `AppView` | Top customer usage | top N | `vw_CustomerChargingHistory` | - | Read-only | Customer, Business Manager theo nhu cầu báo cáo |
| `sp_GetTelemetryHealth` | `AppView` | Telemetry cảnh báo/lỗi | - | `PointTelemetry`, `ChargingPoint`, `ChargingStation`, `ConnectorType` | - | Read-only | Operations Staff |

# 10. Phân tích view/report

| View/Report | Schema | Mục đích | Dữ liệu tổng hợp từ bảng nào | Role nên được xem | Ý nghĩa báo cáo |
|---|---|---|---|---|---|
| `vw_CustomerChargingHistory` | `AppView` | Lịch sử sạc | `ChargingSession`, `UserAccount`, `Vehicle`, `ChargingStation`, `ChargingPoint`, `ConnectorType` | Customer | Xem session, kWh, chi phí |
| `vw_StationRevenueDaily` | `AppView` | Doanh thu ngày theo trạm | `ChargingSession`, `ChargingStation`, `FranchisePartner` | Business Manager | Theo dõi doanh thu/kWh/tax theo trạm |
| `vw_FranchiseRevenueMonthly` | `AppView` | Doanh thu tháng theo franchise | `FranchisePartner`, `ChargingStation`, `ChargingSession` | Business Manager | Đánh giá franchise theo tháng |
| `vw_ProfitSharing` | `AppView` | Kết quả chia doanh thu | `RevenueShareSettlement`, `FranchisePartner`, `FranchiseContract` | Business Manager | Xem partner/platform share |
| `vw_ConnectorUtilization` | `AppView` | Hiệu quả theo connector | `ConnectorType`, `ChargingPoint`, `ChargingSession` | Business Manager, Operations Staff | Phân tích loại đầu sạc |
| `vw_MaintenanceKPI` | `AppView` | KPI bảo trì | `ChargingStation`, `MaintenanceTicket`, `ErrorLog` | Operations Staff | Ticket/error/avg resolve |
| `vw_PaymentSummary` | `AppView` | Tổng hợp payment | `PaymentTransaction` | Business Manager | Số lượng và tổng tiền theo method/status |
| `vw_AvailableChargingPoints` | `AppView` | Cổng sạc khả dụng | `ChargingPoint`, `ChargingStation`, `ConnectorType`, `Address`, `Region` | Customer | Tìm cổng có thể đặt/sạc |
| `vw_CustomerBookingHistory` | `AppView` | Lịch sử booking | `Booking`, `UserAccount`, `Vehicle`, `ChargingPoint`, `ChargingStation` | Customer | Xem booking và trạng thái |
| `vw_InvoiceDetail` | `AppView` | Chi tiết hóa đơn | `Invoice`, `PaymentTransaction`, `ChargingSession`, `UserAccount`, `ChargingStation`, `ChargingPoint` | Customer | Xem invoice/payment/session |
| `vw_ActiveChargingSessions` | `AppView` | Session đang chạy | `ChargingSession`, `UserAccount`, `Vehicle`, `ChargingStation`, `ChargingPoint` | Operations Staff | Theo dõi thời lượng đang sạc |
| `vw_StationStatusOverview` | `AppView` | Tổng quan trạng thái trạm | `ChargingStation`, `ChargingPoint`, `PointStatusHistory` | Operations Staff | Số point available/charging/problem |
| `vw_PeakHourStatistics` | `AppView` | Giờ cao điểm | `ChargingSession` | Business Manager | Phân tích session/revenue theo giờ |
| `vw_TopRevenueStations` | `AppView` | Top trạm doanh thu | `ChargingStation`, `ChargingSession` | Business Manager | Xếp hạng station |
| `vw_CustomerGrowth` | `AppView` | Tăng trưởng khách hàng | `UserAccount`, `UserRole`, `Role` | Business Manager | Customer mới theo tháng |
| `vw_SystemOperationalKPI` | `AppView` | KPI toàn hệ thống | `ChargingStation`, `ChargingPoint`, `ChargingSession`, `MaintenanceTicket` | Business Manager | Tổng quan vận hành |
| `vw_RegionRevenue` | `AppView` | Doanh thu theo khu vực | `Region`, `Address`, `ChargingStation`, `ChargingSession` | Business Manager | So sánh khu vực |
| `vw_UserRoleSummary` | `AppView` | Tổng hợp user-role | `UserAccount`, `UserRole`, `Role` | System Admin | Quản trị tài khoản |
| `vw_ChargingSessionStatistics` | `AppView` | Thống kê session theo ngày/status | `ChargingSession` | Business Manager | Số session, kWh, revenue, duration |
| `vw_TopCustomerUsage` | `AppView` | Top khách hàng sử dụng | `UserAccount`, `ChargingSession` | Business Manager | Nhận diện khách hàng giá trị cao |

Lưu ý bảo mật: các view customer trong source hiện tại chưa thấy điều kiện lọc cố định theo `USER_NAME()` hoặc `UserID` hiện hành. Source có demo Row-Level Security tạm thời trong `features/security/06_row_level_security_demo.sql`, nhưng không cài RLS vĩnh viễn trong setup chính.

# 11. Phân tích trigger/function

| Object | Loại | Mục đích | Kích hoạt khi nào | Bảng ảnh hưởng | Ý nghĩa quản lý thông tin |
|---|---|---|---|---|---|
| `Operations.fn_CalculateChargingCost` | Function | Tính tiền sạc theo kWh, policy và giờ cao điểm | Được gọi trong `sp_EndChargingSession` và seed data | Đọc `PricingPolicy` | Chuẩn hóa công thức tính tiền |
| `Franchise.fn_CalculatePartnerShare` | Function | Tính phần doanh thu của partner | Được gọi trong `sp_CreateRevenueSettlement` | Không ghi bảng | Chuẩn hóa công thức chia doanh thu |
| `AppView.fn_PointUtilizationRate` | Function | Tính tỷ lệ sử dụng point trong khoảng thời gian | Có thể gọi trong phân tích/report | Đọc `ChargingSession` | Hỗ trợ phân tích hiệu suất cổng sạc |
| `Infrastructure.trg_ChargingPoint_StatusHistory` | Trigger | Ghi lịch sử và audit khi point đổi trạng thái | `AFTER UPDATE` trên `ChargingPoint` | `PointStatusHistory`, `AuditLog` | Theo dõi thay đổi trạng thái thiết bị |
| `Operations.trg_ChargingSession_Audit` | Trigger | Audit khi insert/update session hoặc đổi status | `AFTER INSERT, UPDATE` trên `ChargingSession` | `AuditLog` | Theo dõi vòng đời phiên sạc |
| `Payments.trg_PaymentTransaction_Audit` | Trigger | Audit payment insert/update | `AFTER INSERT, UPDATE` trên `PaymentTransaction` | `AuditLog` | Theo dõi giao dịch thanh toán |
| `Audit.trg_AuditLog_BlockDelete` | Trigger | Chặn xóa audit log | `INSTEAD OF DELETE` trên `AuditLog` | `AuditLog` | Bảo vệ lịch sử thay đổi |

# 12. Phân tích bảo mật và phân quyền

## 12.1. Database roles và users

`database/08_Create_Security.sql` tạo 4 database roles:

| Role | User demo | Cách tạo user |
|---|---|---|
| `db_ev_system_admin` | `admin01` | `CREATE USER admin01 WITHOUT LOGIN` |
| `db_ev_operations_staff` | `operator01` | `CREATE USER operator01 WITHOUT LOGIN` |
| `db_ev_business_manager` | `business01` | `CREATE USER business01 WITHOUT LOGIN` |
| `db_ev_customer` | `customer01` | `CREATE USER customer01 WITHOUT LOGIN` |

User `WITHOUT LOGIN` giúp demo bằng `EXECUTE AS USER` trong SSMS mà không cần cấu hình SQL Authentication.

## 12.2. GRANT/DENY chính

| Role | GRANT chính | DENY chính |
|---|---|---|
| `db_ev_system_admin` | `SELECT, INSERT, UPDATE, DELETE` trên tất cả schema; `GRANT EXECUTE`; `UNMASK` nếu chạy advanced security | Không thấy DENY rõ trong source |
| `db_ev_operations_staff` | `SELECT, INSERT, UPDATE` trên `Infrastructure`, `Operations`, `Maintenance`; `SELECT AppView`; `EXECUTE` trên các schema vận hành | DENY direct DML/SELECT trên `Payments`, `[Identity]` |
| `db_ev_business_manager` | SELECT các reporting views; EXEC settlement/report procedures | DENY direct DML/SELECT trên `[Identity]`, `Payments`; DENY INSERT/UPDATE/DELETE trên `Infrastructure`, `Operations`, `Maintenance` |
| `db_ev_customer` | SELECT customer views; EXEC vehicle, booking, session, payment, invoice procedures | DENY direct DML/SELECT trên `Payments`, `[Identity]` |

## 12.3. Bảng nhạy cảm bị chặn

| Bảng/schema | Role bị chặn | Lý do |
|---|---|---|
| `[Identity]` schema | Customer, Operations Staff, Business Manager | Chứa email, phone, password hash, trạng thái tài khoản |
| `Payments` schema | Customer, Operations Staff, Business Manager | Chứa giao dịch, amount, provider reference, invoice |
| `Infrastructure` mutation | Business Manager | Manager chỉ nên xem báo cáo, không vận hành thiết bị |
| `Operations` mutation | Business Manager | Manager không trực tiếp sửa session/booking |
| `Maintenance` mutation | Business Manager | Manager xem KPI, không xử lý ticket |

## 12.4. View/procedure dùng để che giấu bảng gốc

| Nhu cầu | Không đọc trực tiếp | Dùng object thay thế |
|---|---|---|
| Customer xem lịch sử sạc | `Operations.ChargingSession` | `AppView.vw_CustomerChargingHistory` |
| Customer xem hóa đơn | `Payments.Invoice`, `Payments.PaymentTransaction` | `AppView.vw_InvoiceDetail` |
| Customer tạo payment | `Payments.PaymentTransaction` | `Payments.sp_CreatePayment` |
| Business Manager xem payment summary | `Payments.PaymentTransaction` | `AppView.vw_PaymentSummary`, `AppView.sp_GetPaymentSummary` |
| Business Manager xem revenue | `Operations.ChargingSession` | `AppView.vw_StationRevenueDaily`, `vw_TopRevenueStations`, `sp_GetStationRevenue` |
| Operations Staff xem active sessions | `Operations.ChargingSession` | `AppView.vw_ActiveChargingSessions` |

## 12.5. Least Privilege

Source thể hiện nguyên tắc least privilege ở mức database:

- Customer chỉ được gọi procedure nghiệp vụ và xem view được cấp.
- Operations Staff được thao tác operational schemas nhưng bị chặn dữ liệu identity/payment.
- Business Manager xem báo cáo và chạy settlement, nhưng bị chặn cập nhật operational tables.
- System Admin có quyền rộng nhất nhưng audit log vẫn có trigger chặn delete.

## 12.6. Dynamic Data Masking

`database/09_Advanced_Security.sql` thêm masking:

| Cột | Masking function |
|---|---|
| `[Identity].UserAccount.Email` | `email()` |
| `[Identity].UserAccount.Phone` | `partial(0,"XXXX",4)` |
| `[Identity].UserAccount.PasswordHash` | `default()` |

`db_ev_system_admin` được `GRANT UNMASK`. Demo nằm ở `database/features/security/05_masking_demo.sql`.

## 12.7. Row-Level Security

Có demo Row-Level Security trong `database/features/security/06_row_level_security_demo.sql`:

- Tạo tạm schema `SecurityDemo`.
- Tạo function `SecurityDemo.fn_FilterChargingSessionByUser`.
- Tạo security policy `SecurityDemo.ChargingSessionCustomerPolicy`.
- Grant tạm `SELECT` trên `Operations.ChargingSession` cho `customer01`.
- Sau demo có `REVOKE`, drop policy, drop function, drop schema.

Kết luận: RLS có trong demo script, nhưng chưa phải một phần cài đặt cố định của database chính.

## 12.8. EXECUTE AS và contained user

- Core procedures không khai báo `WITH EXECUTE AS`.
- Feature scripts dùng `EXECUTE AS USER = 'customer01'`, `operator01`, `business01`, `admin01` để kiểm thử phân quyền.
- Users demo được tạo `WITHOUT LOGIN`, phù hợp demo database-contained context.
- Script `features/security/08_sql_authentication_logins.sql` tùy chọn tạo SQL Authentication logins thật và map vào database users.

# 13. Cách sử dụng file này để viết báo cáo

| Nhu cầu viết báo cáo | Nên dùng phần nào |
|---|---|
| Mô tả hệ thống có những tính năng gì | Phần 1, 2, 5 |
| Viết tính năng theo role | Phần 3, 4, 6 |
| Thiết kế demo SQL Server theo từng role | Phần 4, 8 và `database/features/FEATURE_INDEX.md` |
| Viết phần bảo mật/phân quyền | Phần 6, 12 |
| Viết phần stored procedure | Phần 9 |
| Viết phần view/report/dashboard | Phần 10 |
| Viết phần trigger/function/audit | Phần 11 |
| Viết phần tính ứng dụng database | Phần 5, 7, 8 |
| Viết kết luận về giới hạn hiện tại | Các ghi chú trong phần 4, 10, 12 |

Khi dùng tài liệu này để viết báo cáo, nên nhấn mạnh rằng hệ thống hiện tại là **database-centric**: các tính năng nghiệp vụ được thể hiện qua stored procedure, view, trigger, security script và demo SQL trong SSMS. Không nên mô tả các tính năng frontend/backend nếu không bổ sung source tương ứng, vì repository hiện tại chưa chứa các phần đó.

