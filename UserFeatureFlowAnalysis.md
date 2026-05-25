# Phan tich luong su dung tinh nang theo nguoi dung - EV_Charging_System

Tai lieu nay tong hop cac luong su dung tinh nang cua tung nhom nguoi dung trong database `EV_Charging_System`. Source hien tai la he thong database-centric, chua co backend/frontend, nen cac tinh nang duoc the hien thong qua SQL Server database object: table, view, stored procedure, function, trigger, security role va script demo trong thu muc `database/features`.

## 1. Tong quan actor va vai tro

He thong co 4 actor dang nhap chinh va 1 actor nghiep vu dang duoc quan ly duoi dang du lieu:

| Actor | Database role | User demo | Vai tro chinh |
|---|---|---|---|
| Customer | `db_ev_customer` | `customer01` | Xem cong sac, quan ly xe, dat lich, sac xe, thanh toan, xem hoa don |
| Operations Staff | `db_ev_operations_staff` | `operator01` | Van hanh tram/cong sac, xu ly loi, quan ly ticket bao tri, xem telemetry |
| Business Manager | `db_ev_business_manager` | `business01` | Xem bao cao doanh thu, KPI, quan ly gia, chia doanh thu franchise, settlement |
| System Admin | `db_ev_system_admin` | `admin01` | Quan ly tai khoan, role, audit log, backup/restore demo |
| Franchise Partner | Chua co role rieng | Khong co | Doi tac nhuuong quyen duoc quan ly qua bang franchise, hop dong va settlement |

Luong tong quat cua he thong:

```text
Customer tao booking va phien sac
-> Operations Staff giam sat ha tang va xu ly su co
-> Payments ghi nhan thanh toan va hoa don
-> Business Manager xem doanh thu, KPI va tao settlement
-> System Admin quan tri user, quyen va audit
```

## 2. Customer - Khach hang

### 2.1. Muc dich

Customer la nguoi dung cuoi cua he thong. Nhom nay su dung he thong de tim cong sac kha dung, quan ly xe dien, dat lich sac, bat dau/ket thuc phien sac, thanh toan va xem hoa don.

### 2.2. Luong su dung chinh

```text
Xem cong sac kha dung
-> Quan ly xe
-> Tao booking
-> Huy booking neu can
-> Bat dau phien sac
-> Ket thuc phien sac
-> Thanh toan
-> Tao/xem hoa don
-> Xem lich su booking va lich su sac
```

### 2.3. Chi tiet tinh nang

| STT | Tinh nang | Mo ta | Database object chinh | Script demo |
|---:|---|---|---|---|
| 1 | Xem tram va cong sac kha dung | Khach hang xem danh sach cong dang san sang de dat lich hoac bat dau sac | `AppView.vw_AvailableChargingPoints` | `database/features/customer/01_view_available_stations.sql` |
| 2 | Them xe | Tao ho so xe moi cho khach hang | `Operations.sp_CreateVehicle`, `Operations.Vehicle` | `database/features/customer/02_create_vehicle.sql` |
| 3 | Cap nhat xe | Sua thong tin model, pin, connector uu tien hoac trang thai xe | `Operations.sp_UpdateVehicle`, `Operations.Vehicle` | `database/features/customer/03_update_vehicle.sql` |
| 4 | Tao booking | Dat truoc mot cong sac theo khung thoi gian hop le | `Operations.sp_CreateBooking`, `Operations.Booking` | `database/features/customer/04_create_booking.sql` |
| 5 | Huy booking | Huy booking con hieu luc | `Operations.sp_CancelBooking`, `Operations.Booking` | `database/features/customer/05_cancel_booking.sql` |
| 6 | Xem lich su booking | Xem cac lan dat lich cua khach hang | `AppView.vw_CustomerBookingHistory` | `database/features/customer/06_view_booking_history.sql` |
| 7 | Bat dau va ket thuc phien sac | Tao phien sac, ket thuc phien, tinh kWh va chi phi | `Operations.sp_StartChargingSession`, `Operations.sp_EndChargingSession` | `database/features/customer/07_start_end_charging_session.sql` |
| 8 | Xem lich su sac | Xem tram, cong, xe, san luong va chi phi cac phien sac | `AppView.vw_CustomerChargingHistory` | `database/features/customer/08_view_charging_history.sql` |
| 9 | Thanh toan va lap hoa don | Tao giao dich thanh toan va invoice cho phien sac da hoan tat | `Payments.sp_CreatePayment`, `Payments.sp_CreateInvoice` | `database/features/customer/09_create_payment_invoice.sql` |
| 10 | Xem chi tiet hoa don | Xem invoice, payment method, trang thai thanh toan va phien sac lien quan | `AppView.vw_InvoiceDetail` | `database/features/customer/10_view_invoice_detail.sql` |

### 2.4. Luong booking

```text
Customer xem AppView.vw_AvailableChargingPoints
-> chon ChargingPoint va Vehicle
-> goi Operations.sp_CreateBooking
-> procedure kiem tra user active, vehicle thuoc user, thoi gian hop le
-> procedure kiem tra point co kha dung va khong bi trung lich
-> tao record trong Operations.Booking voi BookingStatus = 'Confirmed'
```

Bang lien quan:

| Bang | Vai tro |
|---|---|
| `[Identity].UserAccount` | Xac dinh khach hang va trang thai tai khoan |
| `Operations.Vehicle` | Xe duoc dung de dat lich |
| `Infrastructure.ChargingStation` | Tram sac |
| `Infrastructure.ChargingPoint` | Cong sac duoc dat |
| `Operations.Booking` | Lich dat sac |

### 2.5. Luong sac xe

```text
Customer chon cong sac kha dung
-> goi Operations.sp_StartChargingSession
-> he thong tao Operations.ChargingSession voi SessionStatus = 'Charging'
-> ChargingPoint chuyen sang PointStatus = 'Charging'
-> Operations.SessionEvent ghi event Started
-> Customer ket thuc bang Operations.sp_EndChargingSession
-> he thong tinh TotalKWh, DurationMinutes, CostBeforeTax, TaxAmount, CostTotal
-> ChargingSession chuyen sang Completed
-> ChargingPoint quay ve Available
-> Operations.SessionEvent ghi event Completed
```

Bang lien quan:

| Bang | Vai tro |
|---|---|
| `Operations.ChargingSession` | Phien sac thuc te |
| `Infrastructure.ChargingPoint` | Cong sac dang duoc su dung |
| `Operations.PricingPolicy` | Chinh sach gia de tinh tien |
| `Operations.SessionEvent` | Luu su kien bat dau/ket thuc |
| `Audit.AuditLog` | Ghi nhan thay doi quan trong qua trigger |

### 2.6. Luong thanh toan va hoa don

```text
Session phai o trang thai Completed
-> Customer goi Payments.sp_CreatePayment
-> procedure lay CostTotal tu Operations.ChargingSession
-> kiem tra session thuoc user va chua co payment Completed
-> tao Payments.PaymentTransaction
-> Customer goi Payments.sp_CreateInvoice
-> tao Payments.Invoice
-> Customer xem AppView.vw_InvoiceDetail
```

Bang lien quan:

| Bang | Vai tro |
|---|---|
| `Operations.ChargingSession` | Nguon chi phi can thanh toan |
| `Payments.PaymentTransaction` | Giao dich thanh toan |
| `Payments.Invoice` | Hoa don |
| `AppView.vw_InvoiceDetail` | Lop doc chi tiet hoa don |

### 2.7. Kiem soat va gioi han quyen

- Customer thao tac chu yeu qua stored procedure va view.
- Customer khong duoc doc truc tiep cac bang nhay cam nhu `[Identity].UserAccount` va `Payments.PaymentTransaction`.
- He thong chan booking sai thoi gian, booking trung cong dang ban, thanh toan trung va ket thuc session lan hai.

## 3. Operations Staff - Nhan vien van hanh

### 3.1. Muc dich

Operations Staff dam bao tram sac va cong sac hoat dong on dinh. Nhom nay theo doi trang thai tram/cong, giam sat session dang chay, xu ly phien sac loi, ghi nhan loi thiet bi, quan ly ticket bao tri va xem telemetry health.

### 3.2. Luong su dung chinh

```text
Xem trang thai tram
-> Theo doi phien sac dang chay
-> Cap nhat trang thai tram/cong sac
-> Ghi nhan loi thiet bi
-> Tao/phan cong/dong ticket bao tri
-> Theo doi telemetry health
```

### 3.3. Chi tiet tinh nang

| STT | Tinh nang | Mo ta | Database object chinh | Script demo |
|---:|---|---|---|---|
| 1 | Xem trang thai tram | Theo doi so cong kha dung, dang sac va gap su co theo tung tram | `AppView.vw_StationStatusOverview` | `database/features/operations_staff/01_view_station_status.sql` |
| 2 | Cap nhat trang thai tram | Chuyen trang thai tram va ghi nhan audit | `Infrastructure.sp_UpdateStationStatus`, `Infrastructure.ChargingStation` | `database/features/operations_staff/02_update_station_status.sql` |
| 3 | Cap nhat trang thai cong sac | Doi `PointStatus`, `HealthStatus` va kiem tra status history | `Infrastructure.sp_UpdateChargingPointStatus`, `Infrastructure.ChargingPoint` | `database/features/operations_staff/03_update_point_status.sql` |
| 4 | Theo doi phien sac dang chay | Xem cac session dang o trang thai Charging | `AppView.vw_ActiveChargingSessions` | `database/features/operations_staff/04_view_active_sessions.sql` |
| 5 | Xu ly phien sac loi | Chuyen session sang Failed va giai phong cong | `Operations.sp_MarkChargingSessionFailed` | `database/features/operations_staff/05_mark_session_failed.sql` |
| 6 | Ghi nhan loi thiet bi | Tao error log va maintenance ticket tu loi cong sac | `Maintenance.sp_ReportError` | `database/features/operations_staff/06_report_error.sql` |
| 7 | Quan ly ticket bao tri | Lap lich, phan cong va dong ticket bao tri | `Maintenance.sp_ScheduleMaintenance`, `Maintenance.sp_AssignTicket`, `Maintenance.sp_CloseTicket` | `database/features/operations_staff/07_assign_and_close_ticket.sql` |
| 8 | Theo doi telemetry | Xem mau telemetry Warning, Critical hoac Offline | `AppView.sp_GetTelemetryHealth` | `database/features/operations_staff/08_view_telemetry_health.sql` |

### 3.4. Luong cap nhat trang thai cong sac

```text
Operator xem AppView.vw_StationStatusOverview
-> phat hien cong can doi trang thai
-> goi Infrastructure.sp_UpdateChargingPointStatus
-> procedure kiem tra status va health hop le
-> update Infrastructure.ChargingPoint
-> trigger Infrastructure.trg_ChargingPoint_StatusHistory tu ghi PointStatusHistory
-> Audit.AuditLog ghi nhan thay doi
```

Bang lien quan:

| Bang | Vai tro |
|---|---|
| `Infrastructure.ChargingStation` | Tram co cong sac can theo doi |
| `Infrastructure.ChargingPoint` | Cong sac bi doi trang thai |
| `Infrastructure.PointStatusHistory` | Lich su thay doi trang thai cong |
| `Audit.AuditLog` | Audit thay doi |

### 3.5. Luong xu ly session loi

```text
Operator xem AppView.vw_ActiveChargingSessions
-> phat hien session bi loi
-> goi Operations.sp_MarkChargingSessionFailed
-> ChargingSession chuyen sang Failed
-> ChargingPoint duoc giai phong
-> SessionEvent ghi su kien loi
-> trigger Operations.trg_ChargingSession_Audit ghi audit
```

Bang lien quan:

| Bang | Vai tro |
|---|---|
| `Operations.ChargingSession` | Session bi chuyen sang Failed |
| `Infrastructure.ChargingPoint` | Cong sac duoc giai phong |
| `Operations.SessionEvent` | Su kien loi |
| `Audit.AuditLog` | Audit thay doi session |

### 3.6. Luong bao tri

```text
Operator phat hien loi thiet bi
-> goi Maintenance.sp_ReportError
-> he thong tao Maintenance.ErrorLog
-> he thong tao Maintenance.MaintenanceTicket
-> Operator co the goi Maintenance.sp_ScheduleMaintenance
-> Operator goi Maintenance.sp_AssignTicket de phan cong
-> sau khi xu ly xong, goi Maintenance.sp_CloseTicket
```

Bang lien quan:

| Bang | Vai tro |
|---|---|
| `Maintenance.ErrorLog` | Ghi nhan loi thiet bi |
| `Maintenance.MaintenanceTicket` | Ticket xu ly loi |
| `Infrastructure.ChargingStation` | Tram lien quan |
| `Infrastructure.ChargingPoint` | Cong lien quan |
| `[Identity].UserAccount` | Nguoi tao, nguoi duoc gan ticket |

### 3.7. Kiem soat va gioi han quyen

- Operations Staff co quyen tren du lieu van hanh, bao tri va ha tang.
- Nhom nay khong duoc doc truc tiep du lieu nhay cam trong `Payments` va `[Identity]`.
- Cac thay doi trang thai cong sac va session quan trong duoc ghi lich su/audit.

## 4. Business Manager - Quan ly kinh doanh

### 4.1. Muc dich

Business Manager theo doi hieu qua kinh doanh cua he thong: doanh thu, KPI, gio cao diem, tang truong khach hang, tram co doanh thu cao, chinh sach gia, chinh sach chia doanh thu va settlement cho franchise partner.

### 4.2. Luong su dung chinh

```text
Xem doanh thu
-> Xem KPI he thong
-> Phan tich top tram, khu vuc, gio cao diem
-> Quan ly pricing policy
-> Quan ly revenue share policy
-> Tao revenue settlement
-> Xem profit sharing
-> Hoan tien khi can
```

### 4.3. Chi tiet tinh nang

| STT | Tinh nang | Mo ta | Database object chinh | Script demo |
|---:|---|---|---|---|
| 1 | Quan ly chinh sach gia | Tao va vo hieu hoa pricing policy | `Operations.sp_CreatePricingPolicy`, `Operations.sp_DeactivatePricingPolicy` | `database/features/business_manager/01_manage_pricing_policy.sql` |
| 2 | Xem doanh thu theo tram | Lay bo du lieu doanh thu tram theo khoang ngay | `AppView.sp_GetStationRevenue`, `AppView.vw_StationRevenueDaily` | `database/features/business_manager/02_view_station_revenue.sql` |
| 3 | Xem doanh thu theo khu vuc | Tong hop doanh thu theo region | `AppView.vw_RegionRevenue` | `database/features/business_manager/03_view_region_revenue.sql` |
| 4 | Xem top tram doanh thu cao | Xep hang tram theo doanh thu va so phien sac | `AppView.vw_TopRevenueStations` | `database/features/business_manager/04_view_top_revenue_stations.sql` |
| 5 | Thong ke gio cao diem | Phan tich phien sac va doanh thu theo gio bat dau | `AppView.vw_PeakHourStatistics` | `database/features/business_manager/05_view_peak_hours.sql` |
| 6 | Cap nhat revenue share policy | Thay doi ty le chia doanh thu franchise | `Franchise.sp_UpdateRevenueSharePolicy` | `database/features/business_manager/06_update_revenue_share_policy.sql` |
| 7 | Tao revenue settlement | Tao ky doi soat doanh thu cho franchise | `Franchise.sp_CreateRevenueSettlement` | `database/features/business_manager/07_create_revenue_settlement.sql` |
| 8 | Xem chia loi nhuan franchise | Xem phan doanh thu cua doi tac va nen tang | `AppView.sp_GetFranchiseProfitSharing`, `AppView.vw_ProfitSharing` | `database/features/business_manager/08_view_franchise_profit.sql` |
| 9 | Xem tang truong khach hang | Dem khach hang moi theo thang | `AppView.vw_CustomerGrowth` | `database/features/business_manager/09_view_customer_growth.sql` |
| 10 | Xem KPI van hanh he thong | Xem tram, cong, phien sac, loi, ticket va top customer | `AppView.vw_SystemOperationalKPI`, `AppView.vw_TopCustomerUsage` | `database/features/business_manager/10_view_system_kpi.sql` |
| 11 | Hoan tien co ban | Doi trang thai payment va invoice sang Refunded | `Payments.sp_RefundPayment` | `database/features/business_manager/11_refund_payment.sql` |

### 4.4. Luong xem doanh thu

```text
Manager goi AppView.sp_GetStationRevenue
-> procedure doc AppView.vw_StationRevenueDaily
-> du lieu duoc tong hop tu Operations.ChargingSession da Completed
-> ket qua gom doanh thu, tong kWh va so session theo tram/ngay
-> manager dung ket qua de danh gia hieu qua tung tram
```

Bang/view lien quan:

| Object | Vai tro |
|---|---|
| `Operations.ChargingSession` | Nguon doanh thu va san luong |
| `Infrastructure.ChargingStation` | Tram tao doanh thu |
| `Franchise.FranchisePartner` | Doi tac so huu/quan ly tram |
| `AppView.vw_StationRevenueDaily` | View tong hop doanh thu theo ngay |
| `AppView.sp_GetStationRevenue` | Procedure tra bao cao theo khoang ngay |

### 4.5. Luong tao revenue settlement

```text
Manager chon FranchiseID va ky doi soat
-> goi Franchise.sp_CreateRevenueSettlement
-> procedure tim contract active cua franchise
-> procedure tim RevenueSharePolicy active
-> tong hop CostBeforeTax tu cac ChargingSession Completed trong ky
-> Franchise.fn_CalculatePartnerShare tinh phan doi tac
-> he thong tinh phan nen tang con lai
-> insert Franchise.RevenueShareSettlement voi SettlementStatus = 'Approved'
-> ghi Audit.AuditLog voi ActionType = 'SETTLEMENT'
```

Bang/function lien quan:

| Object | Vai tro |
|---|---|
| `Franchise.FranchisePartner` | Doi tac duoc doi soat |
| `Franchise.FranchiseContract` | Hop dong dang hieu luc |
| `Franchise.RevenueSharePolicy` | Ty le chia doanh thu |
| `Operations.ChargingSession` | Nguon doanh thu completed |
| `Franchise.fn_CalculatePartnerShare` | Tinh so tien chia cho doi tac |
| `Franchise.RevenueShareSettlement` | Luu ket qua doi soat |
| `Audit.AuditLog` | Audit thao tac settlement |

### 4.6. Luong hoan tien

```text
Manager chon PaymentTransaction da Completed
-> goi Payments.sp_RefundPayment
-> PaymentTransaction chuyen sang Refunded
-> Invoice lien quan chuyen sang Refunded
-> ghi Audit.AuditLog
```

Luu y: source hien tai khong tao bang refund rieng, hoan tien duoc mo phong bang cach doi trang thai payment/invoice sang `Refunded`.

### 4.7. Kiem soat va gioi han quyen

- Business Manager chu yeu xem du lieu qua schema `AppView`.
- Khong nen doc/sua truc tiep cac bang goc nhay cam nhu `Payments` va `[Identity]`.
- Cac thao tac thay doi quan trong nhu pricing policy, revenue share policy, settlement va refund nen di qua stored procedure.

## 5. System Admin - Quan tri he thong

### 5.1. Muc dich

System Admin quan ly tai khoan, role, trang thai truy cap, reset password, audit log va script backup/restore. Day la role co quyen rong nhat trong demo database.

### 5.2. Luong su dung chinh

```text
Tao tai khoan
-> Gan role
-> Khoa/mo khoa tai khoan
-> Reset password
-> Xem tong hop user-role
-> Xem audit log
-> Chuan bi backup/restore
```

### 5.3. Chi tiet tinh nang

| STT | Tinh nang | Mo ta | Database object chinh | Script demo |
|---:|---|---|---|---|
| 1 | Tao tai khoan | Tao user moi va gan role ban dau | `[Identity].sp_CreateUser` | `database/features/system_admin/01_create_user.sql` |
| 2 | Khoa va mo tai khoan | Doi `AccountStatus` de kiem soat truy cap | `[Identity].sp_LockUser`, `[Identity].sp_UnlockUser` | `database/features/system_admin/02_lock_unlock_user.sql` |
| 3 | Reset password | Cap nhat `PasswordHash` va ghi audit | `[Identity].sp_ResetPassword` | `database/features/system_admin/03_reset_password.sql` |
| 4 | Gan va go role | Quan ly user-role mapping | `[Identity].sp_AssignRole`, `[Identity].sp_RemoveRole` | `database/features/system_admin/04_assign_remove_role.sql` |
| 5 | Xem tong hop user-role | Xem tai khoan, trang thai va danh sach role | `AppView.vw_UserRoleSummary` | `database/features/system_admin/05_view_user_role_summary.sql` |
| 6 | Xem audit log | Kiem tra lich su thay doi du lieu va thao tac quan trong | `Audit.AuditLog` | `database/features/system_admin/06_view_audit_log.sql` |
| 7 | Chuan bi backup/restore | Xem cau lenh mau de sao luu va phuc hoi database | `database/12_Backup_Restore.sql` | `database/features/system_admin/07_backup_restore_demo.sql` |

### 5.4. Luong tao user

```text
Admin goi [Identity].sp_CreateUser
-> procedure kiem tra RoleCode co ton tai trong [Identity].Role
-> insert vao [Identity].UserAccount
-> insert vao [Identity].UserRole
-> ghi Audit.AuditLog voi ActionType = 'INSERT'
-> neu co loi, transaction rollback
```

Bang lien quan:

| Bang | Vai tro |
|---|---|
| `[Identity].UserAccount` | Tai khoan duoc tao |
| `[Identity].Role` | Role nghiep vu |
| `[Identity].UserRole` | Mapping user-role |
| `Audit.AuditLog` | Audit thao tac tao user |

### 5.5. Luong khoa/mo khoa va reset password

```text
Admin chon UserID
-> goi [Identity].sp_LockUser hoac [Identity].sp_UnlockUser
-> AccountStatus doi sang Locked hoac Active
-> ghi Audit.AuditLog
```

```text
Admin chon UserID
-> goi [Identity].sp_ResetPassword
-> PasswordHash duoc cap nhat
-> UpdatedAt duoc cap nhat
-> ghi Audit.AuditLog
```

### 5.6. Luong quan ly role

```text
Admin chon UserID va RoleCode
-> goi [Identity].sp_AssignRole
-> them record vao [Identity].UserRole
-> xem ket qua qua AppView.vw_UserRoleSummary
-> neu can go role, goi [Identity].sp_RemoveRole
```

### 5.7. Kiem soat va gioi han quyen

- Admin co quyen rong nhat nhung thiet ke demo khong phu thuoc vao `db_owner` hoac `sysadmin`.
- `Audit.AuditLog` duoc bao ve boi trigger `Audit.trg_AuditLog_BlockDelete`, chan xoa log.
- Neu chay `database/09_Advanced_Security.sql`, admin co the duoc cap `UNMASK` de xem email, phone va password hash khong bi che.

## 6. Franchise Partner - Doi tac nhuuong quyen

### 6.1. Trang thai trong source hien tai

Franchise Partner co du lieu nghiep vu nhung chua co database role/user rieng de dang nhap. Trong source hien tai, cac thao tac lien quan den franchise duoc Business Manager thuc hien.

### 6.2. Du lieu lien quan

| Bang | Y nghia |
|---|---|
| `Franchise.FranchisePartner` | Thong tin doi tac |
| `Franchise.FranchiseContract` | Hop dong nhuuong quyen |
| `Franchise.FranchiseStation` | Gan tram voi franchise va contract |
| `Franchise.RevenueSharePolicy` | Ty le chia doanh thu |
| `Franchise.RevenueShareSettlement` | Ket qua doi soat doanh thu |

### 6.3. Luong de xuat neu phat trien actor Franchise Partner

Neu sau nay xay backend/frontend va them role rieng cho Franchise Partner, luong hop ly co the la:

```text
Franchise Partner dang nhap
-> xem danh sach tram thuoc doi tac
-> xem doanh thu theo ky
-> xem settlement da duoc phe duyet
-> xem ty le chia doanh thu dang ap dung
-> tai bao cao profit sharing
```

## 7. Ma tran nguoi dung - tinh nang

| Tinh nang | Customer | Operations Staff | Business Manager | System Admin |
|---|---:|---:|---:|---:|
| Xem cong sac kha dung | Co | Co the gian tiep | Khong chinh | Khong chinh |
| Quan ly xe | Co | Khong | Khong | Khong |
| Tao/huy booking | Co | Khong | Khong | Khong |
| Bat dau/ket thuc phien sac | Co | Xu ly loi session | Khong | Khong |
| Thanh toan/hoa don | Co | Khong | Refund | Khong |
| Xem trang thai tram/cong | Khong chinh | Co | Xem bao cao | Co the |
| Cap nhat trang thai tram/cong | Khong | Co | Khong | Co the |
| Ghi nhan loi/ticket bao tri | Khong | Co | Xem KPI | Co the |
| Xem telemetry health | Khong | Co | Co the qua report | Co the |
| Xem doanh thu/KPI | Khong | Mot phan van hanh | Co | Co the |
| Quan ly pricing policy | Khong | Khong | Co | Co the |
| Quan ly revenue share | Khong | Khong | Co | Co the |
| Tao settlement | Khong | Khong | Co | Co the |
| Hoan tien | Khong | Khong | Co | Co the |
| Quan ly user/role | Khong | Khong | Khong | Co |
| Xem audit log | Khong | Khong | Khong | Co |
| Backup/restore demo | Khong | Khong | Khong | Co |

## 8. Ma tran tinh nang - database object

| Nhom tinh nang | Object xu ly chinh | Object doc/bao cao |
|---|---|---|
| Quan ly xe | `Operations.sp_CreateVehicle`, `Operations.sp_UpdateVehicle`, `Operations.Vehicle` | Lich su customer qua `AppView` |
| Dat lich | `Operations.sp_CreateBooking`, `Operations.sp_CancelBooking`, `Operations.Booking` | `AppView.vw_CustomerBookingHistory` |
| Phien sac | `Operations.sp_StartChargingSession`, `Operations.sp_EndChargingSession`, `Operations.sp_MarkChargingSessionFailed` | `AppView.vw_CustomerChargingHistory`, `AppView.vw_ActiveChargingSessions` |
| Thanh toan | `Payments.sp_CreatePayment`, `Payments.sp_RefundPayment`, `Payments.PaymentTransaction` | `AppView.vw_PaymentSummary` |
| Hoa don | `Payments.sp_CreateInvoice`, `Payments.Invoice` | `AppView.vw_InvoiceDetail` |
| Van hanh tram/cong | `Infrastructure.sp_UpdateStationStatus`, `Infrastructure.sp_UpdateChargingPointStatus` | `AppView.vw_StationStatusOverview`, `AppView.vw_AvailableChargingPoints` |
| Telemetry | `Infrastructure.PointTelemetry` | `AppView.sp_GetTelemetryHealth` |
| Bao tri | `Maintenance.sp_ReportError`, `Maintenance.sp_ScheduleMaintenance`, `Maintenance.sp_AssignTicket`, `Maintenance.sp_CloseTicket` | `AppView.vw_MaintenanceKPI` |
| Bao cao doanh thu | `Operations.ChargingSession`, `Payments.PaymentTransaction` | `AppView.vw_StationRevenueDaily`, `AppView.vw_RegionRevenue`, `AppView.vw_TopRevenueStations` |
| Franchise settlement | `Franchise.sp_CreateRevenueSettlement`, `Franchise.fn_CalculatePartnerShare` | `AppView.vw_ProfitSharing`, `AppView.sp_GetFranchiseProfitSharing` |
| Quan tri user | `[Identity].sp_CreateUser`, `[Identity].sp_AssignRole`, `[Identity].sp_RemoveRole` | `AppView.vw_UserRoleSummary` |
| Audit | Trigger va procedure ghi `Audit.AuditLog` | `Audit.AuditLog` |

## 9. Luong nghiep vu tong hop

### 9.1. Luong tu khach hang den doanh thu

```text
Customer xem cong sac kha dung
-> Customer tao booking
-> Customer bat dau phien sac
-> He thong cap nhat cong sang Charging
-> Customer ket thuc phien sac
-> He thong tinh chi phi
-> Customer thanh toan
-> He thong tao hoa don
-> Business Manager xem doanh thu qua AppView
```

### 9.2. Luong tu van hanh den bao tri

```text
Operations Staff xem trang thai tram/cong
-> phat hien cong loi hoac telemetry bat thuong
-> cap nhat cong sang Error/Maintenance
-> ghi ErrorLog
-> tao MaintenanceTicket
-> phan cong nguoi xu ly
-> dong ticket sau khi hoan tat
-> du lieu duoc tong hop vao KPI bao tri
```

### 9.3. Luong tu doanh thu den settlement franchise

```text
ChargingSession Completed tao doanh thu
-> Business Manager xem doanh thu theo tram/franchise
-> Manager cap nhat RevenueSharePolicy neu can
-> Manager tao RevenueShareSettlement theo ky
-> he thong tinh gross revenue, partner share va platform share
-> settlement duoc luu va co the xem qua AppView.vw_ProfitSharing
```

### 9.4. Luong quan tri va audit

```text
System Admin tao user/gan role
-> user thao tac trong he thong theo quyen duoc cap
-> cac thay doi quan trong duoc ghi Audit.AuditLog
-> Admin xem audit log de kiem tra lich su thao tac
-> trigger chan xoa audit log de bao ve bang chung
```

## 10. Ket luan

He thong `EV_Charging_System` duoc chia tinh nang ro theo 4 nhom nguoi dung chinh:

- Customer tap trung vao hanh trinh su dung dich vu sac xe: xem cong, quan ly xe, booking, session, payment va invoice.
- Operations Staff tap trung vao on dinh ha tang: trang thai tram/cong, session loi, telemetry, error log va maintenance ticket.
- Business Manager tap trung vao dieu hanh kinh doanh: doanh thu, KPI, pricing policy, revenue share policy, settlement va refund.
- System Admin tap trung vao quan tri he thong: user, role, password, account status, audit va backup/restore.

Thiet ke database phan tach tot giua luong giao dich, luong bao cao va luong quan tri. Stored procedure dam nhiem xu ly nghiep vu, view dam nhiem lop doc/bao cao, trigger dam nhiem audit va lich su trang thai, con security script dam bao moi role chi co quyen phu hop voi nhiem vu cua minh.
