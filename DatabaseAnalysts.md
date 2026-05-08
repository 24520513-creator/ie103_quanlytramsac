# Phân Tích Hệ Thống Cơ Sở Dữ Liệu
## Hệ thống quản lý mạng lưới trạm sạc xe điện và doanh nghiệp nhượng quyền

**Tên dự án:** `EV_Charging_System`
**Nền tảng:** Microsoft SQL Server 2022+ T-SQL
**Phiên bản tài liệu:** 2.0 (Enterprise Redesign)
**Mục đích:** Phân tích kiến trúc & thiết kế database enterprise cho đồ án môn học Quản lý Thông tin (IE103)

---

## Mục Lục

1. [Tổng quan hệ thống](#1-tổng-quan-hệ-thống)
2. [Kiến trúc database tổng thể](#2-kiến-trúc-database-tổng-thể)
3. [Phân tích từng Schema](#3-phân-tích-từng-schema)
4. [Phân tích từng Bảng](#4-phân-tích-từng-bảng)
5. [Phân tích Relationships](#5-phân-tích-relationships)
6. [Phân tích Normalization](#6-phân-tích-normalization)
7. [Phân tích Indexes & Partitioning](#7-phân-tích-indexes--partitioning)
8. [Phân tích Stored Procedures](#8-phân-tích-stored-procedures)
9. [Phân tích Functions](#9-phân-tích-functions)
10. [Phân tích Triggers](#10-phân-tích-triggers)
11. [Phân tích Views & Materialized Views](#11-phân-tích-views--materialized-views)
12. [Phân tích RBAC & Security](#12-phân-tích-rbac--security)
13. [Phân tích Audit & Soft Delete](#13-phân-tích-audit--soft-delete)
14. [Phân tích Authentication Architecture](#14-phân-tích-authentication-architecture)
15. [Phân tích Pricing Engine](#15-phân-tích-pricing-engine)
16. [Phân tích Payment System](#16-phân-tích-payment-system)
17. [Phân tích IoT & Monitoring](#17-phân-tích-iot--monitoring)
18. [Phân tích Analytics & Reporting](#18-phân-tích-analytics--reporting)
19. [Phân tích Backup & Disaster Recovery](#19-phân-tích-backup--disaster-recovery)
20. [Phân tích Performance Optimization](#20-phân-tích-performance-optimization)
21. [Các Business Rules Quan Trọng](#21-các-business-rules-quan-trọng)
22. [Rủi Ro & Giải Pháp](#22-rủi-ro--giải-pháp)
23. [Hướng Phát Triển Tương Lai](#23-hướng-phát-triển-tương-lai)

---

## 1. Tổng quan hệ thống

### 1.1 Giới thiệu dự án

Hệ thống **"Quản lý mạng lưới trạm sạc xe điện và doanh nghiệp nhượng quyền"** phiên bản 2.0 là một nền tảng cơ sở dữ liệu enterprise được thiết kế lại hoàn toàn từ kiến trúc MVP ban đầu. Hệ thống bao phủ toàn bộ chuỗi giá trị: từ hạ tầng vật lý, đối tác nhượng quyền, nhà cung cấp điện, khách hàng & phương tiện, đến vận hành phiên sạc, định giá động, thanh toán đa kênh, giám sát IoT thời gian thực, kiểm toán, phân tích KPI, và báo cáo doanh nghiệp.

### 1.2 So sánh MVP (v1.0) vs Enterprise (v2.0)

| Tiêu chí | v1.0 (MVP) | v2.0 (Enterprise) |
|---|---|---|
| Schemas | 6 | 9 |
| Tables | 11 | 48 |
| Indexes | 15 | 40+ |
| Stored Procedures | 5 | 8+ |
| Functions | 2 | 4+ |
| Triggers | 3 | 8+ |
| Views | 3 | 10+ |
| Roles (RBAC) | 4 (SQL Server) | 7 (Application) + 6 (Database) |
| Permissions | Schema-level | 40+ granular permissions |
| Audit | ❌ Không có | ✅ Immutable audit + status history |
| Soft Delete | ❌ Không có | ✅ IsDeleted + DeletedAt |
| Pricing | Đơn giản (base + multiplier) | Advanced engine (rules, peak hour, region, membership) |
| Payment | Cơ bản (1 bảng) | Enterprise (8 bảng: gateway, refund, wallet, invoice) |
| IoT/Monitoring | Cơ bản (2 bảng) | Advanced (5 bảng: telemetry, heartbeat, alerts) |
| Analytics | ❌ Không có | ✅ Materialized KPIs, hourly/day aggregation |
| Partitioning | ❌ Không có | ✅ Prepared strategy |
| RLS | ❌ Không có | ✅ Row-Level Security |
| Data Masking | ❌ Không có | ✅ Dynamic Data Masking |
| Normalization | 3NF | 3NF/BCNF + denormalization có kiểm soát |

### 1.3 Mục tiêu kiến trúc

| Mục tiêu | Mô tả |
|---|---|
| **Domain-Driven Design** | 9 schema riêng biệt, mỗi schema là một domain boundary |
| **Microservice-Ready** | Mỗi schema có thể độc lập thành microservice |
| **Scalability** | Partitioning sẵn sàng, columnstore cho analytics, read replicas |
| **Auditability** | Mọi thay đổi đều được ghi lại, immutable audit logs |
| **Security-by-Design** | RBAC, RLS, data masking, encryption, least privilege |
| **Analytics-Ready** | Materialized views, pre-aggregated KPIs, BI-ready schema |

---

## 2. Kiến trúc database tổng thể

### 2.1 Sơ đồ kiến trúc schema

```
EV_Charging_System
│
├── Infrastructure          ← Tài sản vật lý, địa lý, hợp đồng (10 tables)
│   ├── Country / Region / Address       ← Địa lý chuẩn hóa
│   ├── Franchise                        ← Doanh nghiệp nhượng quyền
│   ├── ElectricitySupplier              ← Nhà cung cấp điện
│   ├── StationModel                     ← Danh mục model trạm sạc
│   ├── ChargingStation / ChargingPoint  ← Trạm & điểm sạc (mở rộng)
│   ├── StationElectricityContract       ← Hợp đồng điện (many-to-many)
│   └── StationDocument                  ← Tài liệu pháp lý
│
├── Access                  ← RBAC, phân quyền (3 tables)
│   ├── Role / Permission / RolePermission
│
├── Users                   ← Danh tính, xác thực, phương tiện (8 tables)
│   ├── User / UserProfile / UserCredential ← Tách biệt identity & auth
│   ├── UserSession / UserLoginHistory      ← Session & audit
│   ├── UserRole                           ← Phân quyền người dùng
│   ├── Vehicle                            ← Phương tiện (mở rộng)
│   └── UserPaymentMethod                  ← Phương thức thanh toán
│
├── Operations              ← Vận hành cốt lõi (8 tables)
│   ├── PricingPolicy / PricingRule          ← Định giá đa tầng
│   ├── PeakHourDefinition                   ← Khung giờ cao/thấp điểm
│   ├── MembershipTier / UserMembership      ← Khách hàng thân thiết
│   ├── ChargingSession (mở rộng)            ← Phiên sạc (17+ fields)
│   └── MaintenanceSchedule                  ← Bảo trì (mở rộng)
│
├── Payments               ← Tài chính, thanh toán (8 tables)
│   ├── PaymentGateway                      ← Cổng thanh toán
│   ├── Transaction / TransactionStatusHistory ← Giao dịch + audit
│   ├── GatewayTransaction                  ← Trace cổng thanh toán
│   ├── RefundTransaction                   ← Hoàn tiền
│   ├── Wallet / WalletTransaction          ← Ví + sổ cái
│   └── Invoice / InvoiceLineItem           ← Hóa đơn
│
├── Monitoring             ← IoT, giám sát (5 tables)
│   ├── ErrorLog                            ← Nhật ký lỗi (mở rộng)
│   ├── PointTelemetry                      ← Telemetry thời gian thực
│   ├── StationHeartbeat                    ← Heartbeat kết nối
│   ├── AlertRule / Alert                   ← Cảnh báo thông minh
│
├── Audit                  ← Kiểm toán bất biến (5 tables)
│   ├── AuditLog                            ← Audit trail toàn hệ thống
│   ├── StationStatusHistory / PointStatusHistory ← Lịch sử trạng thái
│   ├── SessionStatusHistory                ← Lịch sử phiên sạc
│   └── SchemaChangeLog                     ← DDL migration tracking
│
├── Analytics              ← KPI, tổng hợp (3 tables + 2 indexed views)
│   ├── DailyStationKPI / DailyFranchiseKPI  ← KPI ngày
│   ├── HourlySessionAgg                     ← Tổng hợp giờ
│   ├── ivw_MonthlyRevenueSummary            ← Materialized view
│   └── ivw_DailyStationAvailability         ← Materialized view
│
└── Reporting              ← Business views (10+ views, read-only)
    ├── vw_ActiveChargingSessions
    ├── vw_StationAvailability
    ├── vw_CustomerChargingSummary
    ├── vw_FranchisePerformanceSummary
    ├── vw_DailyRevenueTrend
    ├── vw_PeakHourAnalysis
    ├── vw_EnergyCostAnalysis
    ├── vw_StationUptimeAnalysis
    ├── vw_AuditTrailSummary
    └── ...
```

### 2.2 Domain Boundaries & Coupling

| Schema | Business Domain | Coupling | Scaling Strategy |
|---|---|---|---|
| Infrastructure | Asset management, geography | Low | Standalone service |
| Access | Authorization | Very Low | Can be cached/Redis |
| Users | Identity, profiles | Low | Read replicas |
| Operations | Charging, pricing | High (central) | Partitioning, sharding |
| Payments | Financial transactions | High | ACID-critical, separate DB possible |
| Monitoring | IoT telemetry | Low | Time-series, columnstore |
| Audit | Compliance | Very Low | Append-only, separate filegroup |
| Analytics | BI, KPIs | Very Low (ETL) | Columnstore, read-only replica |
| Reporting | Business intelligence | None (views) | Can be offloaded to SSRS/Power BI |

### 2.3 Nguyên tắc thiết kế

| Nguyên tắc | Áp dụng |
|---|---|
| **Domain-Driven Design** | 9 schema tương ứng 9 domain boundaries |
| **3NF/BCNF** | Hầu hết bảng đạt chuẩn, denormalization có kiểm soát |
| **Audit-First** | Mọi bảng có CreatedAt/UpdatedAt/IsDeleted + trigger audit |
| **Security-by-Design** | RBAC + RLS + Masking + Encryption |
| **Immutability** | Audit logs không thể sửa/xóa |
| **Naming Convention** | Nhất quán: PascalCase, singular, rõ ràng |
| **Parameterization** | Mọi SP đều dùng tham số, không dynamic SQL |

---

## 3. Phân tích từng Schema

### 3.1 `Infrastructure` — Hạ tầng (10 tables)

**Mục đích:** Quản lý toàn bộ tài sản vật lý, địa lý, nhà cung cấp và hợp đồng.

**Các bảng mới so với v1:**
- `Country`, `Region`, `Address` — Chuẩn hóa địa lý (thay vì lưu text address)
- `StationModel` — Danh mục model trạm sạc (OCPP version, max power)
- `StationElectricityContract` — Hợp đồng điện many-to-many (thay vì SupplierID cố định)
- `StationDocument` — Tài liệu pháp lý, bảo hiểm

**Cải tiến so với v1:**
- `Franchise` thêm: FranchiseCode, FranchiseTier, ContractExpiryDate, IsDeleted, audit columns
- `ElectricitySupplier` thêm: SupplierCode, CountryID
- `ChargingStation` thêm: StationCode, StationModelID, AddressID, GPS (Lat/Lng), MaxCapacityKW, FirmwareVersion, NetworkStatus, OperatingHoursJson, HasGenerator, HasSolarPanels, ParkingSpots
- `ChargingPoint` thêm: PointCode, SerialNumber, CurrentVoltage, CurrentAmperage, LastHeartbeat, FirmwareVersion

**Tại sao cần Address chuẩn hóa?**
v1 lưu địa chỉ text trong ChargingStation, gây khó khăn cho:
- Tìm kiếm theo khu vực (tất cả trạm ở Quận 1)
- Phân tích theo vùng miền
- Tích hợp bản đồ GPS
- Đảm bảo tính nhất quán (cùng một địa chỉ không bị nhập khác format)

### 3.2 `Access` — Phân quyền (3 tables)

**Mục đích:** Quản lý 40+ permission chi tiết, 7 role, mapping role-permission.

**Các bảng:**
- `Permission` — Permission chi tiết (VD: `SESSION_START`, `PAYMENT_REFUND`)
- `Role` — Vai trò (SysAdmin, Operator, Technician, FranchiseOwner, Customer, ReadOnly, ApiService)
- `RolePermission` — Many-to-many mapping

**Khác biệt với v1:**
- v1: 4 SQL Server roles với schema-level GRANT
- v2: 7 application roles + 40+ granular permissions + 6 database roles cho SQL Server security

### 3.3 `Users` — Người dùng (8 tables)

**Mục đích:** Quản lý danh tính, xác thực, profile, phương tiện.

**Cải tiến so với v1 (bảng `Customers` duy nhất):**
- `User` — Core identity (Username, Email, Phone, AccountStatus, FailedLoginAttempts, LockoutEnd)
- `UserProfile` — Thông tin nhân khẩu (FullName, Avatar, DOB, NationalID, preferences)
- `UserCredential` — Thông tin xác thực (PasswordHash, PasswordSalt, MFA)
- `UserSession` — Session tracking (Token, RefreshToken, IP, ExpiresAt)
- `UserLoginHistory` — Lịch sử đăng nhập bất biến
- `UserRole` — Phân role cho user
- `Vehicle` — Phương tiện (thêm: VIN, ModelYear, IsDefault)
- `UserPaymentMethod` — Phương thức thanh toán lưu sẵn

**Tại sao tách Customers thành nhiều bảng?**
- **Nguyên lý Separation of Concerns**: Identity ≠ Profile ≠ Credentials
- **Bảo mật**: PasswordHash và Salt riêng, MFA-ready
- **Mở rộng**: Dễ thêm fields mà không ảnh hưởng bảng chính
- **Tuân thủ GDPR**: Dễ xóa PII khi cần

### 3.4 `Operations` — Vận hành (8 tables)

**Mục đích:** Quản lý phiên sạc, định giá động, bảo trì.

**Cải tiến so với v1:**
- `PricingPolicy` thêm: PolicyCode, PolicyType, MinChargeFee, ParkingFeePerMin, OverstayPenaltyPerMin, Priority, IsDeleted
- `PricingRule` **MỚI** — Granular rules (multiplier, discount, fixed price)
- `PeakHourDefinition` **MỚI** — Định nghĩa khung giờ theo Region + DayOfWeek
- `MembershipTier` **MỚI** — Hạng thành viên (Bronze/Silver/Gold/Platinum)
- `UserMembership` **MỚI** — Mapping user → tier
- `ChargingSession` mở rộng: 17+ fields (xem phân tích 4.8)
- `MaintenanceSchedule` thêm: PointID, MaintenanceType, PartsUsed, Cost, Priority

### 3.5 `Payments` — Thanh toán (8 tables)

**Mục đích:** Quản lý giao dịch tài chính, ví điện tử, hóa đơn, hoàn tiền.

**Các bảng mới (v1 chỉ có 1 bảng `Transactions`):**
- `PaymentGateway` — Đăng ký cổng thanh toán
- `Transaction` — Giao dịch (mở rộng: GatewayID, FeeAmount, NetAmount, TransactionStatus)
- `TransactionStatusHistory` — Lịch sử trạng thái giao dịch
- `GatewayTransaction` — Trace call đến cổng thanh toán (request/response)
- `RefundTransaction` — Quản lý hoàn tiền (full/partial)
- `Wallet` — Ví điện tử
- `WalletTransaction` — Sổ cái ví (double-entry)
- `Invoice` + `InvoiceLineItem` — Hóa đơn

### 3.6 `Monitoring` — Giám sát (5 tables)

**Mục đích:** IoT telemetry, heartbeat, cảnh báo thông minh.

**Các bảng mới:**
- `PointTelemetry` — Dữ liệu cảm biến (Voltage, Amperage, PowerKW, Temperature)
- `StationHeartbeat` — Kết nối mạng (ResponseTime, SignalStrength, Uptime)
- `AlertRule` — Ngưỡng cảnh báo cấu hình được
- `Alert` — Cảnh báo thực tế phát sinh

### 3.7 `Audit` — Kiểm toán (5 tables)

**Mục đích:** Lưu trữ bất biến mọi thay đổi trạng thái.

**Các bảng:**
- `AuditLog` — Audit trail toàn hệ thống (TableName, RecordID, Action, OldValue, NewValue)
- `StationStatusHistory` — Lịch sử trạng thái trạm
- `PointStatusHistory` — Lịch sử trạng thái điểm sạc
- `SessionStatusHistory` — Lịch sử trạng thái phiên sạc
- `SchemaChangeLog` — DDL migration tracking

### 3.8 `Analytics` — Phân tích (3 tables + 2 indexed views)

**Mục đích:** Pre-aggregated KPIs cho dashboard thời gian thực.

**Các bảng:**
- `DailyStationKPI` — KPI hàng ngày theo trạm (TotalSessions, TotalKWh, TotalRevenue, UptimePercent)
- `DailyFranchiseKPI` — KPI hàng ngày theo franchise
- `HourlySessionAgg` — Tổng hợp theo giờ (peak hour analysis)
- `ivw_MonthlyRevenueSummary` — Indexed view (materialized)
- `ivw_DailyStationAvailability` — Indexed view (materialized)

### 3.9 `Reporting` — Báo cáo (10+ views)

**Mục đích:** Business intelligence views, read-only, không chứa bảng vật lý.

---

## 4. Phân tích từng Bảng

### 4.1 `Infrastructure.Address`

| Thuộc tính | Chi tiết |
|---|---|
| **Mục đích** | Chuẩn hóa địa chỉ, tái sử dụng cho nhiều entity |
| **Khóa chính** | `AddressID INT IDENTITY(1,1)` |
| **Khóa ngoại** | `RegionID` → `Region` |

| Cột | Kiểu | Đặc điểm | Giải thích |
|---|---|---|---|
| `FullAddress` | Computed | Tự động nối Street + Ward + District + RegionName | Không cần maintain |
| `Latitude` | `DECIMAL(10,7)` | CHECK -90..90 | Tọa độ cho map |
| `Longitude` | `DECIMAL(10,7)` | CHECK -180..180 | Tọa độ cho map |

**Lợi ích:** Một địa chỉ có thể được tham chiếu bởi nhiều entity (Franchise, Station, UserProfile) mà không trùng lặp dữ liệu.

### 4.2 `Infrastructure.ChargingStation`

**Cải tiến từ v1:**

| Cột mới | Kiểu | Mục đích |
|---|---|---|
| `StationCode` | `NVARCHAR(20)` UNIQUE | Mã trạm (VD: ST001) — thân thiện với người dùng hơn ID số |
| `StationModelID` | FK → StationModel | Model trạm (tra cứu max power, OCPP version) |
| `AddressID` | FK → Address | Địa chỉ chuẩn hóa (thay vì text) |
| `Latitude` / `Longitude` | `DECIMAL(10,7)` | Tọa độ GPS cho mobile app |
| `MaxCapacityKW` | `DECIMAL(10,2)` | Tổng công suất trạm |
| `FirmwareVersion` | `NVARCHAR(50)` | Firmware hiện tại |
| `NetworkStatus` | `NVARCHAR(20)` | Online/Offline/Degraded |
| `InstallationDate` | `DATE` | Ngày lắp đặt |
| `OperatingHoursJson` | `NVARCHAR(500)` | JSON giờ hoạt động (flexible) |
| `HasGenerator` / `HasSolarPanels` | `BIT` | Nguồn điện dự phòng |
| `ParkingSpots` | `INT` | Số chỗ đỗ |
| `IsDeleted` / `DeletedAt` | `BIT` / `DATETIME2` | Soft delete |

### 4.3 `Infrastructure.StationElectricityContract`

**Thay thế mối quan hệ đơn giản `ChargingStation.SupplierID`:**

| Cột | Mục đích |
|---|---|
| `StationID` + `SupplierID` | Many-to-many |
| `ContractNumber` | Số hợp đồng pháp lý |
| `UnitPricePerKWh` | Giá điện theo hợp đồng |
| `ContractFrom` / `ContractTo` | Thời hạn hợp đồng |
| `IsActive` | Hợp đồng hiện tại |

**Lợi ích so với v1:**
- Một trạm có thể đổi nhà cung cấp, giữ lại lịch sử giá
- Một nhà cung cấp phục vụ nhiều trạm với giá khác nhau
- Phân tích chi phí điện theo từng hợp đồng

### 4.4 `Users.UserCredential`

| Cột | Mục đích |
|---|---|
| `PasswordHash` + `PasswordSalt` | Hash PBKDF2-SHA256 (không SHA2 đơn thuần như v1) |
| `HashAlgorithm` | Cho phép nâng cấp thuật toán sau này |
| `MFAEnabled` / `MFASecret` / `MFAType` | Hỗ trợ MFA (TOTP, SMS, Email) |
| `PasswordExpiresAt` | Chính sách hết hạn mật khẩu |
| `RequirePasswordChange` | Buộc đổi mật khẩu lần đầu |

### 4.5 `Operations.PricingPolicy`

**Cải tiến so với v1:**

| Cột mới | Mục đích |
|---|---|
| `PolicyCode` | Mã chính sách (VD: STD, PEAK, OFFPEAK) |
| `PolicyType` | Standard, PeakHour, OffPeak, Holiday, Promotional, Membership, Dynamic |
| `MinChargeFee` / `MaxChargeFee` | Phí tối thiểu/tối đa |
| `ParkingFeePerMin` | Phí đỗ xe khi sạc |
| `OverstayPenaltyPerMin` | Phí quá giờ (sau khi sạc xong) |
| `Priority` | Độ ưu tiên khi chọn chính sách |

### 4.6 `Operations.PricingRule`

**Bảng hoàn toàn mới — cốt lõi của Pricing Engine:**

| Cột | Mục đích |
|---|---|
| `RuleType` | PeakHour, OffPeak, Holiday, Regional, ConsumptionTier, MemberTier, PromoCode |
| `ConditionJson` | Điều kiện JSON linh hoạt (VD: `{"hours":"17-19","days":"1-5"}`) |
| `AdjustmentType` | Multiplier, FixedDiscount, PercentageDiscount, FixedPrice, Waiver |
| `AdjustmentValue` | Giá trị điều chỉnh |
| `Priority` | Thứ tự ưu tiên áp dụng |

### 4.7 `Operations.ChargingSession` — Phiên sạc (Bảng trung tâm)

**Mở rộng từ 9 lên 28 cột:**

| Nhóm cột | Cột | Mục đích Analytics |
|---|---|---|
| **Nhận dạng** | `SessionCode` | Mã phiên (VD: SES-20250407-001) |
| | `VehicleID` | Biết xe nào đã sạc → phân tích theo brand/model |
| | `StationID` | Direct FK (tránh JOIN qua Point) |
| **Năng lượng** | `StartBatteryPercent` / `EndBatteryPercent` | % pin → tính charging curve |
| | `MeterStart` / `MeterEnd` | Meter readings → audit trail |
| | `TotalKWh` | Tổng năng lượng |
| **Thời gian** | `ChargingDurationMinutes` | Thời gian sạc thực tế |
| | `AveragePowerKW` / `MaxPowerKW` | Công suất trung bình/đỉnh |
| **Tài chính** | `CostBeforeDiscount` / `DiscountAmount` | Minh bạch chiết khấu |
| | `CostTotal` | Thành tiền |
| **Vận hành** | `StopReason` | Completed, UserStopped, Error, Timeout... |
| | `SessionSource` | MobileApp, WebPortal, RFID, OCPP... |
| | `SessionType` | Public, Private, Corporate, Free |
| | `OcppTransactionID` | Trace OCPP |

### 4.8 `Payments.Transaction`

**Cải tiến so với v1:**

| Cột mới | Mục đích |
|---|---|
| `TransactionCode` | Mã giao dịch (VD: TXN-20250407-001) |
| `GatewayID` | FK → PaymentGateway (cổng thanh toán) |
| `InvoiceID` | FK → Invoice (hóa đơn) |
| `Direction` | D (Debit) / C (Credit) |
| `FeeAmount` | Phí giao dịch |
| `NetAmount` | Computed: Amount - FeeAmount |
| `AmountBaseCurrency` | Computed: Amount / ExchangeRate |
| `TransactionStatus` | Pending, Processing, Completed, Failed, Refunded, Cancelled |
| `PaymentMethod` | Wallet, CreditCard, VNPay, Momo... |

### 4.9 `Monitoring.PointTelemetry`

**Bảng mới cho IoT:**

| Cột | Mục đích |
|---|---|
| `Voltage` | Điện áp hiện tại (V) |
| `Amperage` | Cường độ dòng điện (A) |
| `PowerKW` | Công suất tức thời |
| `TemperatureC` | Nhiệt độ điểm sạc |
| `EnergyDeliveredKWh` | Năng lượng đã cung cấp |
| `CableStatus` | Connected / Disconnected / Fault |
| `ErrorFlags` | Bitmask lỗi thiết bị |

**Tần suất ghi:** Mỗi 5-15 giây từ IoT device → khối lượng dữ liệu lớn → cần partitioning.

### 4.10 `Audit.AuditLog`

**Bảng audit bất biến:**

| Cột | Mục đích |
|---|---|
| `TableName` | Bảng bị thay đổi |
| `RecordID` | ID bản ghi |
| `Action` | I (Insert) / U (Update) / D (Delete) |
| `OldValue` / `NewValue` | JSON của giá trị cũ/mới |
| `ChangedByUserID` | Ai thay đổi |
| `ChangedByIP` | Từ IP nào |

**Tính bất biến:** Trigger `trg_AuditLog_Immutable` chặn mọi UPDATE/DELETE trên bảng này.

---

## 5. Phân tích Relationships

### 5.1 Sơ đồ quan hệ chính

```
[Country] ──1:N──> [Region] ──1:N──> [Address]
                                          │
              ┌───────────────────────────┤
              ▼                           ▼
      [Franchise]                 [ChargingStation] ──N:1──> [StationModel]
              │                           │
              │                       1:N │           ┌──────────────────┐
              │                           ▼           │StationElectricity│
              │                    [ChargingPoint] ───│Contract          │
              │                           │           └──────────────────┘
              │                           │ N:1                │
              │                           ▼                    ▼
              │                    [ErrorLog]         [ElectricitySupplier]
              │                    [PointTelemetry]
              │
              │                    ┌───────────────────┐
              │                    │[ChargingSession]  │─── [PricingPolicy]
              └─────────────── N:1 │(bảng trung tâm)   │─── [MembershipTier]
                                   │                   │─── [Vehicle]
                                   └───────────────────┘
                                           │ 1:1
                                           ▼
                                   [Transaction] ─── [Gateway]
                                        │              │
                                        ▼              ▼
                                   [RefundTransaction]
                                   [Invoice] ── [InvoiceLineItem]
                                   [Wallet] ── [WalletTransaction]
```

### 5.2 Ma trận quan hệ chi tiết

| Bảng 1 | Quan hệ | Bảng 2 | Khóa ngoại | Ý nghĩa |
|---|---|---|---|---|
| `ChargingStation` | N:1 | `Franchise` | `FranchiseID` | Một franchise có nhiều station |
| `ChargingPoint` | N:1 | `ChargingStation` | `StationID` | Một station có nhiều point |
| `ChargingSession` | N:1 | `User` | `UserID` | Một user có nhiều session |
| `ChargingSession` | N:1 | `Vehicle` | `VehicleID` | Một xe có nhiều session |
| `ChargingSession` | N:1 | `ChargingPoint` | `PointID` | Một point có nhiều session |
| `Transaction` | 1:1 | `ChargingSession` | `SessionID` | Mỗi session 1 transaction |
| `Transaction` | N:1 | `PaymentGateway` | `GatewayID` | Gateway xử lý nhiều transaction |
| `InvoiceLineItem` | N:1 | `Invoice` | `InvoiceID` | Một invoice có nhiều line item |
| `UserCredential` | 1:1 | `User` | `UserID` | Mỗi user có 1 credential |
| `UserProfile` | 1:1 | `User` | `UserID` | Mỗi user có 1 profile |

### 5.3 Đặc điểm thiết kế relationship

| Đặc điểm | v1.0 | v2.0 | Lý do |
|---|---|---|---|
| `ON DELETE CASCADE` | Không dùng | Không dùng | An toàn dữ liệu |
| `ON DELETE SET NULL` | Không dùng | Có dùng (một số FK) | Cho phép xóa reference mà không mất data |
| Soft delete | Không có | `IsDeleted BIT` | Phục hồi dữ liệu khi cần |
| Audit FK | Không có | SESSION_CONTEXT cho UserID | Biết ai thay đổi dữ liệu |

---

## 6. Phân tích Normalization

### 6.1 Đánh giá chuẩn hóa

| Bảng | 1NF | 2NF | 3NF | BCNF | Ghi chú |
|---|---|---|---|---|---|
| `Country` | ✅ | ✅ | ✅ | ✅ | |
| `Region` | ✅ | ✅ | ✅ | ✅ | |
| `Address` | ✅ | ✅ | ✅ | ✅ | Computed column cho FullAddress |
| `Franchise` | ✅ | ✅ | ✅ | ✅ | |
| `ChargingStation` | ✅ | ✅ | ✅ | ✅ | StationModelID → model details (3NF) |
| `ChargingPoint` | ✅ | ✅ | ✅ | ✅ | |
| `User` | ✅ | ✅ | ✅ | ✅ | |
| `ChargingSession` | ✅ | ✅ | ⚠️ | ⚠️ | Xem phân tích dưới |
| `Transaction` | ✅ | ✅ | ✅ | ✅ | |
| `WalletTransaction` | ✅ | ✅ | ✅ | ✅ | |
| `AuditLog` | ✅ | ✅ | ✅ | ✅ | |

### 6.2 Denormalization có chủ đích trong ChargingSession

**`ChargingSession.UserID` và `ChargingSession.StationID`** được lưu trực tiếp dù có thể suy ra qua JOIN:
- `UserID` → từ `SessionID → UserID` (có sẵn)
- `StationID` → từ `PointID → StationID`

**Lý do denormalize:**
- ChargingSession là bảng được query nhiều nhất trong hệ thống
- Thêm StationID giúp tránh 1 JOIN (Point → Station) trong mọi query báo cáo
- Với 100M+ sessions, tiết kiệm hàng tỷ JOIN operations
- Đây là **denormalization có kiểm soát**: dữ liệu vẫn nhất quán vì không thể có StationID khác với PointID.StationID

### 6.3 Ví dụ phân tích 3NF cho ChargingSession

**1NF:** Mỗi cột nguyên tử. ✅
- Không có cột nào chứa multiple values

**2NF:** Phụ thuộc đầy đủ vào khóa chính (SessionID). ✅
- `TotalKWh` phụ thuộc vào `SessionID`
- `StartTime` phụ thuộc vào `SessionID`
- Không có phụ thuộc từng phần (PK đơn cột)

**3NF:** Không có phụ thuộc bắc cầu. ⚠️
- `StationID` phụ thuộc vào `PointID`, và `PointID` phụ thuộc vào `SessionID`
- Đây là transitive dependency: `SessionID → PointID → StationID`
- **Giải pháp:** Chấp nhận denormalization vì performance (xem trên)

**BCNF:** Mọi determinant đều là candidate key. ✅
- Không có phụ thuộc hàm không tầm thường nào vi phạm BCNF

---

## 7. Phân tích Indexes & Partitioning

### 7.1 Chiến lược indexing

| Index Type | Số lượng | Mục đích |
|---|---|---|
| Clustered PK | 48 | Mặc định trên IDENTITY |
| Nonclustered FK | 15+ | JOIN performance |
| Covering index | 12+ | Query được cover hoàn toàn |
| Filtered index | 5+ | Chỉ index trên subset dữ liệu active |
| Columnstore | 1 (comment) | Analytics queries |

### 7.2 Covering Indexes quan trọng

**`IX_ChargingSession_RevenueAnalytics`**
```sql
CREATE NONCLUSTERED INDEX IX_ChargingSession_RevenueAnalytics
    ON Operations.ChargingSession (StartTime, SessionStatus)
    INCLUDE (StationID, UserID, TotalKWh, CostTotal, ChargingDurationMinutes, AveragePowerKW)
    WHERE SessionStatus = N'Completed' AND IsDeleted = 0;
```
- **Cover:** Mọi query báo cáo doanh thu, năng lượng, duration
- **Filtered:** Chỉ index session đã hoàn thành (90%+ queries)
- **Kích thước:** Giảm 90% so với index full table

**`IX_Transaction_DateRange`**
```sql
CREATE NONCLUSTERED INDEX IX_Transaction_DateRange
    ON Payments.Transaction (TransactedAt DESC)
    INCLUDE (UserID, Amount, TransactionType, TransactionStatus, FeeAmount)
    WHERE IsDeleted = 0;
```
- **Mục đích:** Báo cáo tài chính, lịch sử giao dịch
- **INCLUDE:** Mọi cột cần cho SUM/COUNT/AVG

### 7.3 Filtered Indexes

| Index | Filter | Tiết kiệm |
|---|---|---|
| `IX_ChargingPoint_Status` | `WHERE PointStatus IN ('Available','Busy')` | Chỉ index 60% points |
| `IX_UserSession_Token` | `WHERE IsRevoked = 0` | Chỉ index session active |
| `IX_ChargingSession_PointID_Status` | `WHERE SessionStatus = 'Charging'` | Chỉ index session đang sạc |
| `IX_Alert_Status` | `WHERE AlertStatus IN ('Open','Acknowledged')` | Chỉ index alert chưa xử lý |
| `IX_MaintenanceSchedule_Date` | `WHERE ScheduleStatus IN ('Scheduled','InProgress')` | Chỉ index lịch chưa hoàn thành |

### 7.4 Partitioning Strategy

**Partition function (đã chuẩn bị, chưa kích hoạt):**

| Bảng | Partition Key | Range | Mục đích |
|---|---|---|---|
| `ChargingSession` | `StartTime` (YEAR) | 2024-2029+ | Sliding window archive |
| `Transaction` | `TransactedAt` (YEAR) | 2024-2029+ | Financial data retention |
| `PointTelemetry` | `RecordedAt` (MONTH) | Rolling 12 months | Time-series pruning |
| `ErrorLog` | `OccurredAt` (YEAR) | 2024-2029+ | Compliance retention |
| `AuditLog` | `ChangedAt` (YEAR) | 2024-2029+ | Immutable log retention |

**Lợi ích của partitioning:**
```sql
-- Có thể archive dữ liệu cũ bằng SWITCH (sub-second thay vì DELETE hàng giờ)
ALTER TABLE Operations.ChargingSession SWITCH PARTITION 1 TO Archive.ChargingSession_2024;
```

### 7.5 Columnstore cho Analytics

Columnstore index được comment trong code, sẵn sàng kích hoạt:
```sql
CREATE NONCLUSTERED COLUMNSTORE INDEX CSIX_ChargingSession_Analytics
    ON Operations.ChargingSession (StartTime, EndTime, StationID, UserID,
        TotalKWh, CostTotal, ChargingDurationMinutes, SessionStatus, SessionType)
    WHERE IsDeleted = 0;
```
- **Tăng tốc:** 10-100x cho aggregation queries
- **Nén:** 5-10x compression ratio

---

## 8. Phân tích Stored Procedures

### 8.1 `Operations.sp_StartChargingSession`

**Cải tiến từ v1:**

| Tính năng | v1.0 | v2.0 |
|---|---|---|
| VehicleID | Không có | Có (track xe nào đang sạc) |
| SessionSource | Mặc định hardcode | Tham số (@Source) |
| Pricing policy | Chọn cố định (@PolicyID) | Tự động chọn policy active |
| Membership | Không có | Tự động áp dụng membership tier |
| Audit | Không có | INSERT vào SessionStatusHistory |
| Error handling | RAISERROR + return code | THROW (chuẩn SQL Server) |
| Point update | Trigger | Stored procedure + trigger (double safety) |

**Flow:**
```
1. Validate user (AccountStatus = 'Active')
2. Validate point (PointStatus = 'Available')
3. Tự động chọn PricingPolicy active (ORDER BY Priority)
4. Lấy MembershipTier hiện tại của user
5. BEGIN TRANSACTION
6. INSERT ChargingSession với đầy đủ fields
7. UPDATE ChargingPoint → Busy
8. INSERT Audit.SessionStatusHistory
9. COMMIT
```

### 8.2 `Operations.sp_EndChargingSession`

**Cải tiến từ v1:**

| Tính năng | v1.0 | v2.0 |
|---|---|---|
| Meter readings | ❌ | ✅ MeterStart/MeterEnd |
| Battery percent | ❌ | ✅ StartBatteryPercent/EndBatteryPercent |
| Duration | Tính lại mỗi lần | ✅ Lưu ChargingDurationMinutes |
| Avg power | ❌ | ✅ AveragePowerKW |
| Discount | ❌ | ✅ CostBeforeDiscount + DiscountAmount |
| Stop reason | Hardcode | ✅ Tham số hóa |
| Pricing | Gọi function | ✅ Gọi pricing engine + membership discount |

### 8.3 `Payments.sp_CreatePayment`

**Kiến trúc mới hoàn toàn:**

```
1. Kiểm tra session tồn tại và completed
2. Kiểm tra duplicate payment (chống thanh toán 2 lần)
3. BEGIN TRANSACTION
4. INSERT Transaction (code tự sinh: TXN-yyyyMMdd-HHmmss-SessionID)
5. Nếu payment method = Wallet:
   a. Kiểm tra số dư
   b. UPDATE Wallet (Balance - Amount)
   c. INSERT WalletTransaction (double-entry)
6. INSERT TransactionStatusHistory
7. COMMIT
```

### 8.4 `Payments.sp_ProcessRefund`

**Flow hoàn tiền enterprise:**
```
1. Kiểm tra OriginalTransaction tồn tại, completed
2. Tính tổng đã hoàn (không vượt quá original amount)
3. BEGIN TRANSACTION
4. INSERT RefundTransaction (tự động: Full/Partial)
5. UPDATE Transaction Status → Refunded / PartiallyRefunded
6. COMMIT
```

### 8.5 `Analytics.sp_DailyKPIAggregation`

**ETL procedure cho analytics:**

Sử dụng `MERGE` để upsert vào:
- `Analytics.DailyStationKPI` — tổng hợp session, kWh, revenue, errors
- `Analytics.DailyFranchiseKPI` — tổng hợp commission, active stations
- `Analytics.HourlySessionAgg` — tổng hợp theo giờ

**Tần suất chạy:** Daily qua SQL Agent Job.

### 8.6 `Reporting.sp_GetMonthlyRevenueReport`

**Cải tiến từ v1:**
- **Pagination:** OFFSET/FETCH NEXT (trang 1, 2, 3...)
- **Filter:** Theo FranchiseID (tùy chọn)
- **Thêm chỉ số:** TotalKWh, TotalCommission, ActiveStations
- **Count query riêng:** Cho tổng số records

### 8.7 Xử lý lỗi & Transaction

Tất cả stored procedures đều tuân theo pattern:
```sql
SET NOCOUNT ON;
SET XACT_ABORT ON;  -- ← Tự động rollback khi có lỗi

BEGIN TRY
    BEGIN TRANSACTION
    -- business logic
    COMMIT
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK;
    THROW;  -- ← Giữ nguyên error thay vì RAISERROR
END CATCH
```

**`SET XACT_ABORT ON`** là cải tiến quan trọng so với v1:
- Tự động rollback khi có runtime error (chia 0, violation...)
- Không cần kiểm tra @@TRANCOUNT trong mọi catch block
- Giảm risk inconsistent data

---

## 9. Phân tích Functions

### 9.1 `Operations.fn_CalculateChargingCost` (Cải tiến)

**So sánh v1 vs v2:**

| v1.0 | v2.0 |
|---|---|
| 3 tham số: Total_kWh, BasePrice, Multiplier | 4 tham số: + DiscountPercent |
| Multiplier do caller truyền vào | Tự động phát hiện peak hour |
| Không discount | Discount từ membership tier |
| `RETURN MONEY` | `RETURN MONEY` |

**Logic mới:**
1. Phát hiện giờ cao điểm (17:00-19:00, weekday) → multiplier 1.5
2. Phát hiện giờ thấp điểm (22:00-05:00) → multiplier 0.7
3. Áp dụng BasePrice × Multiplier
4. Áp dụng discount: `EffectivePrice × (1 - DiscountPercent / 100)`

### 9.2 `Operations.fn_GetEffectivePrice` (Mới)

**Pricing engine function:**
- Input: PolicyID, RegionID, StartTime, TotalKWh
- Output: Giá hiệu quả sau khi áp dụng tất cả PricingRules
- Duyệt rules theo Priority, áp dụng AdjustmentType/AdjustmentValue

### 9.3 `Reporting.fn_GetStationUtilizationRate` (Mới)

**Tính tỷ lệ sử dụng trạm:**
```
Utilization = Σ(session duration overlapping với period) / TotalPeriodDuration × 100
```
Xử lý session bắt đầu trước hoặc kết thúc sau period.

### 9.4 `Reporting.fn_GetFranchiseCommission` (Mới)

**Tính hoa hồng franchise:**
```
Commission = Σ(Session.CostTotal) × Franchise.RevenueShareRate / 100
```
Trong khoảng thời gian với status = Completed.

---

## 10. Phân tích Triggers

### 10.1 Ma trận trigger v2.0

| Trigger | Bảng | Event | Mục đích |
|---|---|---|---|
| `trg_ChargingPoint_StatusChange` | ChargingPoint | AFTER UPDATE | Audit status history + auto error log |
| `trg_ChargingStation_StatusChange` | ChargingStation | AFTER UPDATE | Audit status history |
| `trg_ChargingSession_StatusChange` | ChargingSession | AFTER UPDATE | Audit session status history |
| `trg_ChargingSession_PointSync` | ChargingSession | AFTER INSERT, UPDATE | Đồng bộ PointStatus (safety backup) |
| `trg_Transaction_Immutable` | Transaction | AFTER UPDATE | Chặn sửa completed/refunded transactions |
| `trg_AuditLog_Immutable` | AuditLog | INSTEAD OF DELETE, UPDATE | Audit logs bất biến |
| `trg_User_SoftDelete` | User | AFTER UPDATE | Cascade soft delete |
| `trg_RolePermission_Audit` | RolePermission | AFTER INSERT, UPDATE, DELETE | Audit thay đổi phân quyền |

### 10.2 Cơ chế đồng bộ PointStatus (Cải tiến)

**v1.0:** Chỉ có trigger trên ChargingSession cập nhật ChargingPoint

**v2.0:** **Double safety** — cả trigger và stored procedure đều cập nhật:
- Stored procedure: `UPDATE ChargingPoint SET PointStatus = 'Busy'`
- Trigger: `trg_ChargingSession_PointSync` cũng cập nhật (dự phòng nếu có code bypass SP)

**Bảo vệ trùng lặp:** Mỗi cập nhật chỉ thực hiện khi status hiện tại khớp với expected:
- `SET Busy WHERE Currently = 'Available'`
- `SET Available WHERE Currently = 'Busy'`

### 10.3 Tính bất biến của AuditLog

**Trigger:** `INSTEAD OF DELETE, UPDATE`
```sql
CREATE TRIGGER Audit.trg_AuditLog_Immutable
ON Audit.AuditLog
INSTEAD OF DELETE, UPDATE
AS
    THROW 51002, N'Audit log entries are immutable.', 16;
```

Đây là **rào chắn cuối cùng**: ngay cả DBA cũng không thể xóa audit log qua SQL trực tiếp. (Chỉ có thể truncate table với quyền sysadmin.)

---

## 11. Phân tích Views & Materialized Views

### 11.1 Business Views

| View | Bảng nguồn | Số JOIN | Mục đích |
|---|---|---|---|
| `vw_ActiveChargingSessions` | 7 tables | 6 JOIN | Dashboard real-time |
| `vw_StationAvailability` | 4 tables | 3 JOIN | Trạng thái trạm |
| `vw_CustomerChargingSummary` | 4 tables | 3 JOIN | Lifetime value customer |
| `vw_FranchisePerformanceSummary` | 4 tables | 3 JOIN | Performance franchise |
| `vw_DailyRevenueTrend` | 3 tables | 2 JOIN | Xu hướng doanh thu |
| `vw_PeakHourAnalysis` | 1 table | 0 JOIN | Phân tích giờ cao điểm |
| `vw_EnergyCostAnalysis` | 4 tables | 3 JOIN | Lợi nhuận theo năng lượng |
| `vw_StationUptimeAnalysis` | 3 tables | 2 JOIN | Độ tin cậy trạm |
| `vw_AuditTrailSummary` | 3 tables | 3 JOIN | Timeline kiểm toán |

### 11.2 Indexed (Materialized) Views

**`Analytics.ivw_MonthlyRevenueSummary`**
```sql
CREATE VIEW Analytics.ivw_MonthlyRevenueSummary
WITH SCHEMABINDING
AS
SELECT YEAR(StartTime), MONTH(StartTime), StationID,
       COUNT_BIG(*), COUNT_BIG(DISTINCT UserID),
       SUM(TotalKWh), SUM(CostTotal)
FROM Operations.ChargingSession
WHERE SessionStatus = 'Completed' AND IsDeleted = 0
GROUP BY YEAR(StartTime), MONTH(StartTime), StationID;

CREATE UNIQUE CLUSTERED INDEX CI_ivw_MonthlyRevenueSummary ON ...
```

**Lợi ích:**
- Dữ liệu được duy trì vật lý, tự động cập nhật
- Query báo cáo doanh thu không cần scan bảng gốc
- Phù hợp cho dashboard và Power BI

---

## 12. Phân tích RBAC & Security

### 12.1 Mô hình phân quyền 3 lớp

```
Lớp 1: SQL Server Logins (Server Level)
    ├── ev2_admin_login
    ├── ev2_operator_login
    ├── ev2_technician_login
    ├── ev2_franchise_login
    ├── ev2_readonly_login
    └── ev2_app_service_login

Lớp 2: Database Roles (SQL Server)
    ├── db_role_admin        → CONTROL mọi schema
    ├── db_role_operator     → CRUD Operations, Payments, SELECT others
    ├── db_role_technician   → CRUD Infrastructure, Monitoring, SELECT Operations
    ├── db_role_franchise    → SELECT limited (filtered by RLS)
    ├── db_role_readonly     → SELECT on reporting schemas
    └── db_role_app_service  → SELECT, INSERT, UPDATE Operations/Monitoring

Lớp 3: Application Roles (Access schema)
    ├── SysAdmin (level 100)     → 40+ permissions
    ├── Operator (level 80)      → 25+ permissions
    ├── Technician (level 60)    → 15+ permissions
    ├── FranchiseOwner (level 50)→ 6 permissions
    ├── Customer (level 20)      → 5 permissions
    ├── ReadOnly (level 10)      → 10 permissions
    └── ApiService (level 30)    → 8 permissions
```

### 12.2 40+ Granular Permissions

**Module Users:**
`USER_CREATE`, `USER_READ`, `USER_UPDATE`, `USER_DELETE`, `USER_IMPERSONATE`

**Module Operations:**
`SESSION_START`, `SESSION_STOP`, `SESSION_CANCEL`, `SESSION_OVERRIDE`, `PRICING_CREATE`, `PRICING_READ`, `PRICING_UPDATE`

**Module Payments:**
`PAYMENT_READ`, `PAYMENT_REFUND`, `PAYMENT_ADJUST`

**Module Monitoring:**
`MONITOR_READ`, `ALERT_CONFIG`, `ALERT_ACK`

### 12.3 Row-Level Security (RLS)

FranchiseOwner chỉ thấy được dữ liệu của franchise mình:
```sql
CREATE FUNCTION Access.fn_FranchiseFilter (@FranchiseID INT)
RETURNS TABLE
AS RETURN SELECT 1 AS IsAccessible
WHERE IS_ROLEMEMBER(N'db_role_admin') = 1
   OR IS_ROLEMEMBER(N'db_role_franchise') = 1 AND ...;

CREATE SECURITY POLICY Access.FranchiseFilterPolicy
    ADD FILTER PREDICATE Access.fn_FranchiseFilter (FranchiseID)
    ON Infrastructure.Franchise;
```

### 12.4 Dynamic Data Masking

| Cột | Mask Function |
|---|---|
| `User.Email` | `email()` |
| `User.Phone` | `partial(2, "XXXX", 2)` |
| `UserProfile.FullName` | `partial(1, "XXXX", 0)` |
| `UserProfile.NationalID` | `partial(2, "XXXX", 2)` |
| `PaymentGateway.MerchantID` | `partial(2, "XXXX", 2)` |

---

## 13. Phân tích Audit & Soft Delete

### 13.1 Audit Columns

Mọi bảng business (trừ bảng lookup) đều có:
```sql
CreatedAt   DATETIME2   NOT NULL DEFAULT SYSDATETIME()
UpdatedAt   DATETIME2   NULL
DeletedAt   DATETIME2   NULL
IsDeleted   BIT         NOT NULL DEFAULT 0
CreatedBy   INT         NULL
UpdatedBy   INT         NULL
```

### 13.2 Soft Delete Strategy

| Thao tác | Kỹ thuật | Trigger |
|---|---|---|
| Xóa user | `UPDATE SET IsDeleted=1, DeletedAt=SYSDATETIME()` | Cascade: Vehicles + Sessions |
| Xóa station | `UPDATE SET IsDeleted=1` | Manual cascade qua app |
| Xóa session | `UPDATE SET IsDeleted=1` | Chỉ admin |

**Lợi ích của soft delete:**
- Có thể phục hồi dữ liệu
- Giữ toàn vẹn tham chiếu (FK không bị lỗi)
- Audit trail vẫn còn
- Dữ liệu lịch sử vẫn có trong báo cáo (dùng WHERE IsDeleted=0)

### 13.3 Immutable Audit Trail

```
User action → Trigger captures OldValue/NewValue → INSERT AuditLog
                                  ↓
                     AuditLog không thể UPDATE/DELETE
                                  ↓
                     Dùng cho compliance, investigation
```

---

## 14. Phân tích Authentication Architecture

### 14.1 So sánh v1 vs v2

| Thành phần | v1.0 | v2.0 |
|---|---|---|
| Lưu trữ | 1 bảng Customers | 5 bảng: User + UserProfile + UserCredential + UserSession + UserLoginHistory |
| Password hash | SHA2-256 (thô) | PBKDF2-SHA256 + Salt |
| MFA | ❌ | ✅ TOTP/SMS/Email |
| Session | ❌ | ✅ Token + RefreshToken |
| Login history | ❌ | ✅ Bất biến, có IP + UserAgent |
| Lockout | ❌ | ✅ FailedLoginAttempts + LockoutEnd |
| Password expiry | ❌ | ✅ PasswordExpiresAt |

### 14.2 Security Flow

```
Login Request
    ↓
User.FindByEmail(Email)
    ↓
Check AccountStatus = 'Active'
    ↓
Verify PasswordHash (PBKDF2-SHA256)
    ↓
IF failed:
    Increment FailedLoginAttempts
    IF >= MaxAttempts: SET LockoutEnd
    INSERT UserLoginHistory (Success=0)
    ↓
IF success:
    Reset FailedLoginAttempts
    INSERT UserSession (token, refreshToken, expires)
    INSERT UserLoginHistory (Success=1, IP, UserAgent)
    ↓
Return SessionToken + RefreshToken
```

---

## 15. Phân tích Pricing Engine

### 15.1 Kiến trúc Pricing Engine

```
User starts charging
    ↓
sp_StartChargingSession
    ↓
Tự động chọn PricingPolicy active (Priority cao nhất)
    ↓
Lấy MembershipTier của user
    ↓
Session ghi nhận PolicyID + MembershipTierID
    ↓
User ends charging
    ↓
sp_EndChargingSession
    ↓
fn_CalculateChargingCost(TotalKWh, BasePrice, Discount, StartTime)
    ├── Phát hiện Peak Hour (17:00-19:00) → multiplier 1.5
    ├── Phát hiện Off-Peak (22:00-05:00) → multiplier 0.7
    ├── Áp dụng BasePrice × Multiplier
    └── Áp dụng Membership Discount
```

### 15.2 Pricing Rule Types

| RuleType | Hành vi | Ví dụ |
|---|---|---|
| `PeakHour` | Multiplier | 1.5x cho 17:00-19:00 |
| `OffPeak` | Multiplier | 0.7x cho 22:00-05:00 |
| `Holiday` | Multiplier | 1.2x cho ngày lễ |
| `ConsumptionTier` | FixedDiscount | Giảm 500đ/kWh cho >30kWh |
| `MemberTier` | PercentageDiscount | Gold: -10%, Platinum: -15% |
| `PromoCode` | FixedPrice | 3000đ/kWh cho mã PROMO30 |
| `Regional` | Multiplier | Khu vực khác nhau, giá khác nhau |

### 15.3 Future Extensibility

Cấu trúc `PricingRule.ConditionJson` cho phép thêm bất kỳ điều kiện nào:
```json
{"hours": "17-19", "days": "1-5", "min_kwh": 10, "max_kwh": 50, "station_ids": [1,2,3]}
```

Không cần thay đổi schema để thêm loại pricing mới — chỉ cần INSERT rule mới.

---

## 16. Phân tích Payment System

### 16.1 Kiến trúc thanh toán

```
ChargingSession kết thúc
    ↓
sp_CreatePayment
    ├── Tạo Transaction (Pending)
    ├── Nếu Wallet:
    │   ├── Kiểm tra Balance >= Amount
    │   ├── Wallet.Balance -= Amount
    │   └── WalletTransaction (double-entry)
    ├── Nếu Gateway:
    │   ├── Gọi API cổng thanh toán
    │   ├── GatewayTransaction (request/response)
    │   └── Transaction → Completed / Failed
    └── TransactionStatusHistory
```

### 16.2 ACID Guarantees

| Tính chất | Cơ chế |
|---|---|
| **Atomicity** | BEGIN TRAN / COMMIT / ROLLBACK — toàn bộ hoặc không có gì |
| **Consistency** | CHECK constraints (`Balance >= 0`, `Amount > 0`) + FK |
| **Isolation** | `READ_COMMITTED_SNAPSHOT = ON` — không dirty read |
| **Durability** | `RECOVERY FULL` + transaction log backups |

### 16.3 Refund Flow

```
RefundRequest (Amount, Reason)
    ↓
Kiểm tra OriginalTransaction = Completed
    ↓
Kiểm tra tổng refund <= OriginalAmount
    ↓
Tạo RefundTransaction (Status = Pending → Approved)
    ↓
Cập nhật TransactionStatus (Refunded / PartiallyRefunded)
    ↓
Gọi Gateway refund API
    ↓
RefundTransaction.Status = Completed
```

### 16.4 Financial Consistency

**Double-entry ledger trong WalletTransaction:**
```
WalletTransaction.Amount + WalletTransaction.BalanceBefore = BalanceAfter
(Tính tự động bằng computed column)
```

Mỗi giao dịch debit phải có:
- Transaction tương ứng (để truy xuất nguồn gốc)
- Wallet giảm tương ứng (số dư không thể âm)

---

## 17. Phân tích IoT & Monitoring

### 17.1 IoT Data Flow

```
ChargingPoint (IoT device)
    ↓ MQTT/WebSocket (OCPP 2.0.1)
StationHeartbeat (mỗi 30 giây)
    ↓
PointTelemetry (mỗi 5-15 giây — Voltage, Amperage, Power, Temperature)
    ↓
AlertRule Evaluation
    ├── Nếu vượt ngưỡng → INSERT Alert
    └── Nếu lỗi → INSERT ErrorLog
```

### 17.2 Alert Rules

Các ngưỡng cảnh báo có thể cấu hình (không hardcode):
| Rule | Metric | Condition | Severity |
|---|---|---|---|
| Quá nhiệt | TemperatureC | > 60°C | Critical |
| Quá dòng | Amperage | > 125% rated | High |
| Mất kết nối | Heartbeat | > 5 phút không có | High |
| Điện áp bất thường | Voltage | < 200V hoặc > 260V | Medium |

### 17.3 Heartbeat Monitoring

`StationHeartbeat` ghi mỗi 30 giây:
- `NetworkStatus` (Online/Offline/Degraded)
- `ResponseTimeMs` (độ trễ)
- `UptimeSeconds` (thời gian online)
- `IsHealthy` (tổng hợp)

Cho phép tính **uptime SLA** cho mỗi trạm.

---

## 18. Phân tích Analytics & Reporting

### 18.1 OLTP vs OLAP Separation

```
OLTP (Operational)                          OLAP (Analytical)
──────────────────────────                  ──────────────────────────
Infrastructure.ChargingStation              Analytics.DailyStationKPI
Operations.ChargingSession                  Analytics.DailyFranchiseKPI
Payments.Transaction                        Analytics.HourlySessionAgg
Monitoring.ErrorLog                         Analytics.ivw_MonthlyRevenueSummary

                    ▲                               ▲
                    │        sp_DailyKPIAggregation (ETL)
                    └───────────────────────────────┘
```

### 18.2 KPI Dashboards

**Station KPI (DailyStationKPI):**
| Chỉ số | Nguồn |
|---|---|
| TotalSessions | COUNT(SessionID) |
| TotalKWh | SUM(TotalKWh) |
| TotalRevenue | SUM(CostTotal) |
| AvgPowerKW | AVG(AveragePowerKW) |
| AvgChargingMinutes | AVG(ChargingDurationMinutes) |
| PeakConcurrentSessions | MAX(concurrent) |
| UniqueUsers | COUNT(DISTINCT UserID) |
| ErrorCount | COUNT(ErrorLog) |
| UptimePercent | Tính từ heartbeat |
| RevenuePerKWh | Computed: Revenue / KWh |

**Franchise KPI (DailyFranchiseKPI):**
| Chỉ số | Ý nghĩa |
|---|---|
| TotalSessions | Tổng session các station |
| TotalRevenue | Tổng doanh thu |
| CommissionAmount | Revenue × ShareRate / 100 |
| ActiveStations | Station đang hoạt động |
| TotalErrors | Lỗi trên toàn franchise |

### 18.3 Reporting Views (Business Intelligence)

**`vw_PeakHourAnalysis`** — Phân tích khung giờ:
- HourOfDay, DayOfWeek, SessionCount, TotalKWh, TotalRevenue, AvgDuration

**`vw_EnergyCostAnalysis`** — Phân tích lợi nhuận:
- TotalKWhDelivered, ElectricityUnitPrice, TotalElectricityCost, TotalRevenue, GrossMargin

**`vw_CustomerChargingSummary`** — RFM Segmentation:
- TotalSessions, LifetimeKWh, LifetimeSpend, AvgSpendPerSession, DaysSinceLastCharge

### 18.4 Materialized (Indexed) Views

**`ivw_MonthlyRevenueSummary`:**
- Pre-aggregated theo tháng + station
- Duy trì tự động (indexed view)
- Query báo cáo không scan bảng gốc

---

## 19. Phân tích Backup & Disaster Recovery

### 19.1 Backup Strategy

| Loại | Tần suất | Retention | RPO |
|---|---|---|---|
| Full | Hàng tuần (CN 01:00) | 30 ngày | Baseline |
| Differential | Hàng ngày (01:00) | 14 ngày | Giảm log restore chain |
| Transaction Log | 15 phút | 48 giờ | **15 phút** |

### 19.2 Recovery Objectives

| Tier | Scenario | RPO | RTO | Technology |
|---|---|---|---|---|
| 1 | Database corruption | 15 min | 2 hr | Point-in-time recovery |
| 2 | Server failure | 0 | 30 sec | Always On AG (sync) |
| 3 | Regional disaster | 5 min | 1 hr | Always On AG (async) |
| 4 | Full site loss | 15 min | 4 hr | Azure Blob backups + restore |

### 19.3 Point-in-Time Recovery

```sql
-- Step 1: Full backup (NORECOVERY)
RESTORE DATABASE EV_Charging_System FROM DISK='...full.bak' WITH NORECOVERY;

-- Step 2: Differential (NORECOVERY)
RESTORE DATABASE EV_Charging_System FROM DISK='...diff.bak' WITH NORECOVERY;

-- Step 3: Log backups đến thời điểm mong muốn
RESTORE LOG EV_Charging_System FROM DISK='...log1.trn' WITH NORECOVERY, STOPAT='2025-04-07 14:35:00';
RESTORE LOG EV_Charging_System FROM DISK='...log2.trn' WITH NORECOVERY, STOPAT='2025-04-07 14:35:00';

-- Step 4: Online
RESTORE DATABASE EV_Charging_System WITH RECOVERY;
```

### 19.4 High Availability Architecture

```
Primary (Sync) ←→ Secondary (Sync, Read-Only)
    │
    └──→ DR Secondary (Async, Geo-redundant)
```

---

## 20. Phân tích Performance Optimization

### 20.1 SARGability

**v1.0 (Non-SARGable):**
```sql
WHERE YEAR(t.[Timestamp]) = @Year  -- ← Scan toàn bộ index
```

**v2.0 (SARGable):**
```sql
WHERE t.[Timestamp] >= DATEFROMPARTS(@Year, 1, 1)
  AND t.[Timestamp] <  DATEFROMPARTS(@Year + 1, 1, 1)
  -- ← Index Seek
```

**Tác động:** Chuyển từ Table Scan → Index Seek, tăng tốc 10-100x.

### 20.2 Covering Index Analysis

Query báo cáo doanh thu tháng:
```sql
SELECT SUM(CostTotal), AVG(CostTotal)
FROM Operations.ChargingSession
WHERE StartTime >= '2025-01-01' AND StartTime < '2025-02-01'
  AND SessionStatus = 'Completed' AND IsDeleted = 0;
```

→ `IX_ChargingSession_RevenueAnalytics` cover hoàn toàn query này:
- **Seek** trên `StartTime`
- **Predicate** trên `SessionStatus` + `IsDeleted`
- **INCLUDE** `CostTotal` (không cần Key Lookup)

### 20.3 Query Plan Analysis

| Query | Scan | Seek | Lookup | Index sử dụng |
|---|---|---|---|---|
| `SELECT ... WHERE SessionID = ?` | 0 | 1 (PK) | 0 | PK_ChargingSession |
| `SELECT ... WHERE UserID = ? ORDER BY StartTime DESC` | 0 | 1 | 0 | IX_ChargingSession_UserID |
| `SUM(CostTotal) GROUP BY MONTH(StartTime)` | 0 | 1 | 0 | IX_ChargingSession_RevenueAnalytics |
| `SELECT ... WHERE PointStatus = 'Available'` | 0 | 1 | 0 | IX_ChargingPoint_Status |
| `SELECT ... WHERE Email = ?` | 0 | 1 | 0 | IX_User_Email_AccountStatus |

### 20.4 Transaction Performance

Các stored procedure giữ transaction ngắn nhất có thể:
- `sp_StartChargingSession`: 1 INSERT + 1 UPDATE + 1 INSERT audit
- `sp_EndChargingSession`: 1 UPDATE + 1 UPDATE + 1 INSERT audit

Transaction ngắn → lock được giải phóng nhanh → giảm deadlock.

### 20.5 Hot/Cold Data Strategy

| Layer | Time range | Storage | Indexing |
|---|---|---|---|
| **Hot** | 0-90 days | SSD, In-Memory OLTP (future) | Full indexing |
| **Warm** | 90-365 days | Standard storage | Compressed indexes |
| **Cold** | 1+ years | Archived (Archive schema/DB) | Page compression |

---

## 21. Các Business Rules Quan Trọng

### 21.1 Ma trận business rules

| # | Business Rule | Implemented By | File |
|---|---|---|---|
| BR1 | Revenue share rate 0-100% | CHECK | `02_CreateTables.sql` |
| BR2 | Wallet balance >= 0 | CHECK | `02_CreateTables.sql` |
| BR3 | Mỗi session chỉ một transaction | Trigger + SP | `08_CreateTriggers.sql` + `07_CreateStoredProcedures.sql` |
| BR4 | Amount khớp session cost | SP validation | `07_CreateStoredProcedures.sql` |
| BR5 | Tài khoản locked/closed không thể sạc | SP validation | `07_CreateStoredProcedures.sql` |
| BR6 | Point không Available không thể sạc | SP validation | `07_CreateStoredProcedures.sql` |
| BR7 | Pricing policy phải còn hiệu lực | SP validation | `07_CreateStoredProcedures.sql` |
| BR8 | Wallet balance đủ để thanh toán | SP validation | `07_CreateStoredProcedures.sql` |
| BR9 | Audit logs bất biến | Trigger | `08_CreateTriggers.sql` |
| BR10 | Completed transactions không thể sửa | Trigger | `08_CreateTriggers.sql` |
| BR11 | Mỗi station có station code duy nhất | UNIQUE | `02_CreateTables.sql` |
| BR12 | Mỗi contract number duy nhất | UNIQUE | `02_CreateTables.sql` |
| BR13 | StartTime < EndTime | CHECK | `02_CreateTables.sql` |
| BR14 | BatteryPercent 0-100 | CHECK | `02_CreateTables.sql` |

### 21.2 Business Logic Flow: Quy trình sạc hoàn chỉnh

```
KHÁCH HÀNG                    HỆ THỐNG v2.0
    │                             │
    │ [Bắt đầu sạc]              │
    ├────────────────────────────>│
    │                             │ sp_StartChargingSession
    │                             │ ├─ Validate user (active, not locked)
    │                             │ ├─ Validate point (available)
    │                             │ ├─ Tự động chọn PricingPolicy
    │                             │ ├─ Lấy MembershipTier
    │                             │ ├─ BEGIN TRAN
    │                             │ ├─ INSERT ChargingSession (18 fields)
    │                             │ ├─ UPDATE Point → Busy
    │                             │ ├─ INSERT SessionStatusHistory
    │                             │ └─ COMMIT
    │                             │
    │ <── SessionCode ───────────┤
    │                             │
    │ [Kết thúc sạc]             │
    ├────────────────────────────>│
    │                             │ sp_EndChargingSession
    │                             │ ├─ Tính TotalKWh (MeterEnd - MeterStart)
    │                             │ ├─ Tính DurationMinutes
    │                             │ ├─ Tính AveragePowerKW
    │                             │ ├─ fn_CalculateChargingCost (peak/off-peak, discount)
    │                             │ ├─ BEGIN TRAN
    │                             │ ├─ UPDATE Session (17 fields)
    │                             │ ├─ UPDATE Point → Available
    │                             │ └─ INSERT SessionStatusHistory
    │                             │
    │ [Thanh toán]                │
    ├────────────────────────────>│
    │                             │ sp_CreatePayment
    │                             │ ├─ Validate session completed
    │                             │ ├─ Check duplicate payment
    │                             │ ├─ BEGIN TRAN
    │                             │ ├─ INSERT Transaction (20 fields)
    │                             │ ├─ Wallet: kiểm tra + trừ balance
    │                             │ ├─ WalletTransaction (double-entry)
    │                             │ ├─ TransactionStatusHistory
    │                             │ └─ COMMIT
    │                             │
    │ <── TransactionCode ───────┤
```

---

## 22. Rủi Ro & Giải Pháp

### 22.1 Rủi ro hiện tại

| Rủi ro | Mô tả | Mức độ | Giải pháp |
|---|---|---|---|
| **Race condition** | Kiểm tra PointStatus và INSERT không atomic trong 100% cases | Trung bình | Thêm `UPDLOCK, HOLDLOCK` hoặc application-level lock |
| **Không load balancing** | Mọi request vào một DB | Cao | Read replicas + CQRS |
| **Telemetry volume** | 5-15 giây/record × 1000 points = 5.7M-17M records/ngày | Cao | Partitioning, columnar compression, retention policy |
| **Pricing consistency** | Giá thay đổi giữa lúc bắt đầu và kết thúc session | Thấp | Đã xử lý bằng cách lưu PolicyID + tính cost tại EndTime |
| **Data masking bypass** | User có quyền cao có thể unmask | Thấp | Always Encrypted cho PII thực sự nhạy cảm |
| **Backup storage** | 50GB+ database, backup có thể lớn hơn | Trung bình | Nén backup (COMPRESSION), Azure Blob storage |

### 22.2 Rủi ro đã xử lý

| Rủi ro | Xử lý | File |
|---|---|---|
| Mất tiền do không kiểm tra balance | CHECK + SP validation | `07_CreateStoredProcedures.sql` |
| Chính sách giá hết hạn giữa phiên sạc | Kiểm tra lại tại EndTime | `07_CreateStoredProcedures.sql` |
| Xóa nhầm dữ liệu có quan hệ | Không ON DELETE CASCADE | `02_CreateTables.sql` |
| Mất audit trail | Immutable triggers | `08_CreateTriggers.sql` |
| Duplicate payment | Check trong SP + unique constraint | `07_CreateStoredProcedures.sql` |
| Sửa completed transaction | Immutable trigger | `08_CreateTriggers.sql` |
| SQL injection | Stored procedures + parameterized queries | All SPs |

---

## 23. Hướng Phát Triển Tương Lai

### 23.1 Ngắn hạn (3-6 tháng)

1. **Kích hoạt partitioning** (hiện đang comment)
   - `CREATE PARTITION FUNCTION` cho ChargingSession, Transaction, PointTelemetry
   - Tự động archive partition switching

2. **Kích hoạt columnstore index**
   - `CREATE NONCLUSTERED COLUMNSTORE INDEX` cho ChargingSession
   - Tăng tốc analytics queries 10-100x

3. **Always Encrypted** cho PII
   - UserCredential.PasswordHash
   - UserProfile.NationalID
   - GatewayTransaction.RequestPayload

4. **In-Memory OLTP** cho ChargingSession
   - Giảm latency cho session start/end
   - Tăng throughput cho concurrent sessions

### 23.2 Trung hạn (6-12 tháng)

5. **Hệ thống Booking**
   - Bảng `Booking`: UserID, PointID, ScheduledTime, Duration, Status
   - Cho phép đặt trước điểm sạc

6. **Loyalty Program mở rộng**
   - `Rewards`: UserID, Points, Tier, ExpiryDate
   - Tích điểm, đổi ưu đãi

7. **Real-time Dashboard**
   - Kết nối SignalR đến vw_ActiveChargingSessions
   - Power BI direct query

8. **Multi-language support**
   - Bảng `Localization` cho UI strings
   - Hỗ trợ tiếng Việt + English

### 23.3 Dài hạn (12-24 tháng)

9. **Microservices migration**
   - Payment Service (Payments schema → độc lập)
   - Monitoring Service (Monitoring → độc lập)
   - User Service (Users → độc lập)

10. **Event Sourcing / CQRS**
    - Event Store cho mọi state change
    - Read models optimized cho từng use case

11. **Time-series database cho IoT**
    - Chuyển PointTelemetry, StationHeartbeat sang InfluxDB/TimescaleDB
    - Lưu trữ và query hiệu quả hơn

12. **Machine Learning integration**
    - Dự đoán peak hour dựa trên historical data
    - Anomaly detection cho telemetry
    - Predictive maintenance scheduling

---

## Phụ Lục A: Thống Kê Database v2.0

| Thành phần | v1.0 (MVP) | v2.0 (Enterprise) | Tăng trưởng |
|---|---|---|---|
| Database | 1 | 1 | — |
| Schema | 6 | 9 | +50% |
| Tables | 11 | 48 | +336% |
| Indexes | 15 | 40+ | +167% |
| Functions | 2 | 4+ | +100% |
| Stored Procedures | 5 | 8+ | +60% |
| Triggers | 3 | 8+ | +167% |
| Views | 3 | 10+ | +233% |
| Logins | 4 | 6 | +50% |
| Roles (app) | 0 | 7 | Mới |
| Permissions | 0 | 40+ | Mới |
| Roles (DB) | 4 | 6 | +50% |
| CHECK Constraints | 17 | 45+ | +165% |
| UNIQUE Constraints | 7 | 15+ | +114% |
| FOREIGN KEY Constraints | 11 | 50+ | +355% |

## Phụ Lục B: Cấu Trúc Thư Mục v2.0

```
database/
├── run_all.sql                        ← Master orchestrator (12 bước)
├── schema/
│   ├── 01_CreateDatabase.sql          ← Database + 9 schemas
│   └── 02_CreateTables.sql            ← 48 tables + constraints
├── indexes/
│   └── 03_CreateIndexes.sql           ← 40+ indexes + partitioning
├── security/
│   └── 04_RBAC_And_Security.sql       ← RBAC, RLS, masking, encryption
├── seed/
│   └── 05_SeedData.sql                ← Seed data mở rộng
├── functions/
│   └── 06_CreateFunctions.sql         ← 4+ enterprise functions
├── procedures/
│   └── 07_CreateStoredProcedures.sql  ← 8+ stored procedures
├── triggers/
│   └── 08_CreateTriggers.sql          ← 8+ triggers
├── views/
│   └── 09_CreateViews.sql             ← 10+ business views
├── analytics/
│   └── 10_AnalyticsObjects.sql        ← Indexed views + KPI procedures
├── reporting/
│   └── 11_ReportQueries.sql           ← 10 enterprise reports
└── backup/
    └── 12_BackupAndDR.sql             ← Backup + DR strategy
```

---

**Tài liệu được tạo bởi:** Database Architect & Enterprise Data Engineering Team
**Ngày tạo:** 2026
**Phiên bản:** 2.0 (Enterprise Redesign)
**Môn học:** IE103 — Quản lý Thông tin
