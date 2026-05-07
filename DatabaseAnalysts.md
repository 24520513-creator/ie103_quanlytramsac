# Phân Tích Hệ Thống Cơ Sở Dữ Liệu
## Hệ thống quản lý mạng lưới trạm sạc xe điện và doanh nghiệp nhượng quyền

**Tên dự án:** `EV_Charging_System`
**Nền tảng:** Microsoft SQL Server T-SQL
**Phiên bản tài liệu:** 1.0
**Mục đích:** Phân tích kiến trúc & thiết kế database cho đồ án môn học Quản lý Thông tin (IE103)

---

## Mục Lục

1. [Tổng quan hệ thống](#1-tổng-quan-hệ-thống)
2. [Vai trò của database trong hệ thống](#2-vai-trò-của-database-trong-hệ-thống)
3. [Kiến trúc database tổng thể](#3-kiến-trúc-database-tổng-thể)
4. [Phân tích từng Schema](#4-phân-tích-từng-schema)
5. [Phân tích từng Bảng](#5-phân-tích-từng-bảng)
6. [Phân tích Relationships](#6-phân-tích-relationships)
7. [Phân tích Normalization](#7-phân-tích-normalization)
8. [Phân tích Indexes](#8-phân-tích-indexes)
9. [Phân tích Stored Procedures](#9-phân-tích-stored-procedures)
10. [Phân tích Functions](#10-phân-tích-functions)
11. [Phân tích Triggers](#11-phân-tích-triggers)
12. [Phân tích Views](#12-phân-tích-views)
13. [Phân tích Security & RBAC](#13-phân-tích-security--rbac)
14. [Phân tích Reporting System](#14-phân-tích-reporting-system)
15. [Phân tích Backup & Restore](#15-phân-tích-backup--restore)
16. [Phân tích Performance Optimization](#16-phân-tích-performance-optimization)
17. [Các Business Rules Quan Trọng](#17-các-business-rules-quan-trọng)
18. [Các Rủi Ro Dữ Liệu](#18-các-rủi-ro-dữ-liệu)
19. [Hạn Chế Hiện Tại của Hệ Thống](#19-hạn-chế-hiện-tại-của-hệ-thống)
20. [Hướng Phát Triển Tương Lai](#20-hướng-phát-triển-tương-lai)

---

## 1. Tổng quan hệ thống

### 1.1 Giới thiệu dự án

Hệ thống **"Quản lý mạng lưới trạm sạc xe điện và doanh nghiệp nhượng quyền"** là một nền tảng cơ sở dữ liệu được thiết kế để quản lý toàn bộ chuỗi giá trị của mạng lưới trạm sạc xe điện tại Việt Nam. Hệ thống bao phủ từ hạ tầng vật lý (trạm sạc, điểm sạc), đối tác kinh doanh (doanh nghiệp nhượng quyền, nhà cung cấp điện), khách hàng & phương tiện, đến vận hành (phiên sạc, giao dịch, giá cước), giám sát (lỗi, bảo trì), và báo cáo.

### 1.2 Mục tiêu kinh doanh

| Mục tiêu | Mô tả |
|---|---|
| **Quản lý hạ tầng** | Theo dõi toàn bộ trạm sạc và điểm sạc trên cả nước |
| **Vận hành nhượng quyền** | Quản lý doanh nghiệp nhượng quyền, tỷ lệ chia sẻ doanh thu |
| **Quản lý khách hàng** | Lưu trữ thông tin khách hàng, ví điện tử, phương tiện |
| **Định giá linh hoạt** | Áp dụng chính sách giá theo khung giờ (cao điểm, thấp điểm) |
| **Giám sát & bảo trì** | Ghi nhận lỗi thiết bị và lập lịch bảo trì |
| **Báo cáo tài chính** | Tổng hợp doanh thu theo tháng, theo trạm, theo đối tác |

### 1.3 Đối tượng sử dụng

- **Quản trị viên (Admin):** Toàn quyền trên hệ thống
- **Quản lý (Manager):** Quản lý vận hành, xem báo cáo
- **Kỹ thuật viên (Technician):** Quản lý trạm sạc, điểm sạc, bảo trì
- **Người đọc (ReadOnly):** Xem dữ liệu, phục vụ báo cáo & kiểm toán

---

## 2. Vai trò của database trong hệ thống

Database đóng vai trò trung tâm trong hệ thống, đảm nhận các nhiệm vụ:

### 2.1 Lưu trữ tập trung

Tất cả dữ liệu từ hạ tầng, khách hàng, giao dịch đến giám sát đều được lưu trữ trong một database duy nhất (`EV_Charging_System`). Điều này đảm bảo:
- **Tính nhất quán:** Mọi dữ liệu đều được đồng bộ
- **Tính toàn vẹn tham chiếu:** Ràng buộc khóa ngoại (FOREIGN KEY) đảm bảo không có bản ghi "mồ côi"
- **Tính nguyên tử (Atomicity):** Các giao dịch (transaction) đảm bảo tất cả hoặc không có gì

### 2.2 Thực thi business logic

Database không chỉ là kho chứa thụ động mà còn chủ động thực thi business logic thông qua:

- **CHECK constraints:** Kiểm tra dữ liệu đầu vào (vd: tỷ lệ chia sẻ doanh thu 0–100%, số dư ví >= 0)
- **Stored procedures:** Đóng gói quy trình nghiệp vụ (vd: `sp_StartChargingSession`, `sp_CreateTransaction`)
- **Triggers:** Tự động hóa cập nhật trạng thái (vd: tự động chuyển điểm sạc sang "Đang bận" khi bắt đầu phiên)

### 2.3 Bảo mật đa lớp

Database triển khai mô hình phân quyền RBAC (Role-Based Access Control) với 4 vai trò, mỗi vai trò có quyền hạn riêng biệt trên từng schema.

### 2.4 Hỗ trợ quyết định

Các view và stored procedure báo cáo cung cấp thông tin tổng hợp phục vụ:
- Phân tích doanh thu theo tháng
- Đánh giá hiệu suất trạm sạc
- Xác định khung giờ cao điểm
- Theo dõi hiệu quả đối tác nhượng quyền

---

## 3. Kiến trúc database tổng thể

### 3.1 Sơ đồ kiến trúc schema

```
EV_Charging_System
│
├── Infrastructure          ← Hạ tầng trạm sạc
│   ├── Franchisee          ← Doanh nghiệp nhượng quyền
│   ├── ElectricitySuppliers ← Nhà cung cấp điện
│   ├── ChargingStation     ← Trạm sạc
│   └── ChargingPoint       ← Điểm sạc
│
├── Users                   ← Người dùng
│   ├── Customers           ← Khách hàng
│   └── Vehicles            ← Phương tiện
│
├── Operations              ← Vận hành
│   ├── PricingPolicy       ← Chính sách giá
│   ├── ChargingSession     ← Phiên sạc
│   └── Transactions        ← Giao dịch tài chính
│
├── Monitoring              ← Giám sát
│   ├── ErrorLogs           ← Nhật ký lỗi
│   └── MaintenanceSchedule ← Lịch bảo trì
│
├── Reports                 ← Báo cáo (views + functions)
│   ├── vw_MonthlyRevenue
│   ├── vw_StationPerformance
│   ├── vw_ActiveChargingSessions
│   ├── fn_GetStationRevenue
│   └── sp_GetMonthlyRevenue / sp_GetTopStations
│
└── Security                ← Bảo mật (users, roles, permissions)
```

### 3.2 Sơ đồ quan hệ (Relationship Diagram)

```
[Franchisee] ──1:N──> [ChargingStation] ──1:N──> [ChargingPoint]
                              │                                │
                              │ N:1                           │ 1:N ──── [ErrorLogs]
                              │                                │
                              ▼                                ▼
[ElectricitySuppliers] ──1:N──> [ChargingStation]       [ChargingSession] ◄── [PricingPolicy]
                                                                 │
                                                                 │ 1:N
                                                                 ▼
[Customers] ──1:N──> [ChargingSession] ──1:1──> [Transactions]
       │
       └──1:N──> [Vehicles]
```

### 3.3 Nguyên tắc thiết kế

| Nguyên tắc | Áp dụng |
|---|---|
| **Schema separation** | 6 schema riêng biệt cho từng nhóm chức năng |
| **3NF (Third Normal Form)** | Hầu hết các bảng đạt chuẩn 3NF |
| **IDENTITY cho khóa chính** | Tất cả khóa chính đều tự động tăng |
| **Kiểu dữ liệu phù hợp** | `DATETIME2` cho thời gian, `MONEY` cho tiền tệ, `DECIMAL` cho kWh |
| **Ràng buộc ở DB layer** | CHECK, UNIQUE, FOREIGN KEY, NOT NULL |
| **Modular deployment** | 11 file SQL riêng biệt, `run_all.sql` làm điều phối |

---

## 4. Phân tích từng Schema

### 4.1 `Infrastructure` — Hạ tầng

**Mục đích:** Quản lý toàn bộ tài sản vật lý của mạng lưới trạm sạc.

**Lý do thiết kế:** Schema này được tách riêng vì hạ tầng là tài sản cốt lõi, có vòng đời độc lập với vận hành. Việc thay đổi hạ tầng (thêm/xóa trạm) không ảnh hưởng đến schema vận hành.

**Các bảng:**
- `Franchisee` — Doanh nghiệp nhượng quyền
- `ElectricitySuppliers` — Nhà cung cấp điện
- `ChargingStation` — Trạm sạc
- `ChargingPoint` — Điểm sạc (cột sạc)

### 4.2 `Users` — Người dùng

**Mục đích:** Quản lý thông tin khách hàng và phương tiện của họ.

**Lý do thiết kế:** Tách biệt khỏi hạ tầng và vận hành để đảm bảo dữ liệu người dùng được cô lập, dễ quản lý bảo mật.

**Các bảng:**
- `Customers` — Khách hàng (tài khoản, ví điện tử)
- `Vehicles` — Phương tiện (biển số, thông số kỹ thuật)

### 4.3 `Operations` — Vận hành

**Mục đích:** Quản lý toàn bộ hoạt động sạc và giao dịch tài chính.

**Lý do thiết kế:** Đây là schema quan trọng nhất, nơi diễn ra tất cả business logic cốt lõi. Các bảng ở đây có tần suất ghi cao nhất và cần được tối ưu hiệu năng.

**Các bảng:**
- `PricingPolicy` — Chính sách giá
- `ChargingSession` — Phiên sạc (bảng trung tâm)
- `Transactions` — Giao dịch tài chính

### 4.4 `Monitoring` — Giám sát

**Mục đích:** Theo dõi tình trạng kỹ thuật và lịch bảo trì.

**Lý do thiết kế:** Dữ liệu giám sát mang tính chất nhật ký (log), có khối lượng lớn nhưng tần suất truy vấn thấp. Tách riêng giúp không ảnh hưởng đến hiệu năng của schema vận hành.

**Các bảng:**
- `ErrorLogs` — Nhật ký lỗi thiết bị
- `MaintenanceSchedule` — Lịch bảo trì trạm sạc

### 4.5 `Reports` — Báo cáo

**Mục đích:** Cung cấp giao diện dữ liệu chỉ-đọc cho báo cáo và phân tích.

**Lý do thiết kế:** Tập trung tất cả view, function báo cáo vào một schema giúp dễ dàng:
- Phân quyền (chỉ cần GRANT SELECT trên schema này)
- Bảo trì (thay đổi logic báo cáo không ảnh hưởng đến schema khác)
- Tối ưu (có thể thêm indexed views)

**Đối tượng:**
- `vw_MonthlyRevenue` — Doanh thu theo tháng
- `vw_StationPerformance` — Hiệu suất trạm
- `vw_ActiveChargingSessions` — Phiên sạc đang hoạt động
- `fn_GetStationRevenue` — Hàm tính doanh thu trạm
- `sp_GetMonthlyRevenue` / `sp_GetTopStations` — Stored procedure báo cáo

### 4.6 `Security` — Bảo mật

**Mục đích:** Quản lý đối tượng bảo mật cấp database.

**Lý do thiết kế:** Mặc dù SQL Server có security riêng, việc tạo schema Security giúp dễ dàng mở rộng với các đối tượng bảo mật tùy chỉnh trong tương lai (vd: bảng lưu audit log, encryption keys).

---

## 5. Phân tích từng Bảng

### 5.1 `Infrastructure.Franchisee`

| Thuộc tính | Chi tiết |
|---|---|
| **Mục đích** | Lưu thông tin doanh nghiệp đối tác nhượng quyền vận hành trạm sạc |
| **Khóa chính** | `FranchiseeID INT IDENTITY(1,1)` |
| **IDENTITY** | `(1,1)` — bắt đầu từ 1, tăng 1 |
| **Kiểu dữ liệu** | `NVARCHAR` cho tên, mã số thuế, người liên hệ (Unicode cho tiếng Việt) |

**Các cột quan trọng:**

| Cột | Kiểu | Ràng buộc | Giải thích |
|---|---|---|---|
| `FranchiseeName` | `NVARCHAR(100)` | NOT NULL | Tên doanh nghiệp |
| `TaxCode` | `NVARCHAR(20)` | UNIQUE, NOT NULL | Mã số thuế — không trùng |
| `Phone` | `NVARCHAR(20)` | UNIQUE, NULL | Số điện thoại — duy nhất nếu có |
| `Email` | `NVARCHAR(50)` | UNIQUE, NULL | Email — duy nhất nếu có |
| `RevenueShareRate` | `DECIMAL(5,2)` | CHECK 0–100 | Tỷ lệ % chia sẻ doanh thu |
| `ContractDate` | `DATETIME2` | NOT NULL | Ngày ký hợp đồng |

**Business rules:**
- Mỗi doanh nghiệp có mã số thuế duy nhất
- Tỷ lệ chia sẻ doanh thu từ 0% đến 100%
- Số điện thoại và email là duy nhất nhưng có thể NULL (một số doanh nghiệp nhỏ chưa có)

### 5.2 `Infrastructure.ElectricitySuppliers`

| Thuộc tính | Chi tiết |
|---|---|
| **Mục đích** | Lưu thông tin nhà cung cấp điện cho các trạm sạc |
| **Khóa chính** | `SupplierID INT IDENTITY(1,1)` |

**Các cột quan trọng:**

| Cột | Kiểu | Ràng buộc | Giải thích |
|---|---|---|---|
| `UnitPrice_kWh` | `DECIMAL(19,4)` | CHECK >= 0 | Đơn giá mỗi kWh (4 số thập phân cho độ chính xác cao) |
| `Region` | `NVARCHAR(20)` | CHECK IN (Bắc, Trung, Nam) | Khu vực miền — ràng buộc chặt |

**Business rules:**
- Giá điện không âm
- Chỉ hoạt động tại 3 miền: Bắc, Trung, Nam
- Kiểu `DECIMAL(19,4)` cho phép tối đa 19 chữ số với 4 số thập phân, đủ cho đơn giá đến 999.999.999,9999 VND/kWh

### 5.3 `Infrastructure.ChargingStation`

| Thuộc tính | Chi tiết |
|---|---|
| **Mục đích** | Quản lý các trạm sạc vật lý |
| **Khóa chính** | `StationID INT IDENTITY(1,1)` |
| **Khóa ngoại** | `FranchiseeID` → `Franchisee`; `SupplierID` → `ElectricitySuppliers` |

**Các cột quan trọng:**

| Cột | Kiểu | Ràng buộc | Giải thích |
|---|---|---|---|
| `StationName` | `NVARCHAR(100)` | NOT NULL | Tên trạm sạc |
| `Address` | `NVARCHAR(250)` | NULL | Địa chỉ — NULL được phép nếu chưa xác định |
| `StationStatus` | `NVARCHAR(20)` | CHECK IN (Hoạt động, Không hoạt động, Bảo trì) | Trạng thái hoạt động |

**Business rules:**
- Mỗi trạm thuộc về một doanh nghiệp nhượng quyền
- Mỗi trạm có một nhà cung cấp điện
- Trạng thái được kiểm soát chặt chẽ bởi CHECK constraint

### 5.4 `Infrastructure.ChargingPoint`

| Thuộc tính | Chi tiết |
|---|---|
| **Mục đích** | Quản lý từng điểm sạc (cột sạc) trong một trạm |
| **Khóa chính** | `PointID INT IDENTITY(1,1)` |
| **Khóa ngoại** | `StationID` → `ChargingStation` |
| **DEFAULT** | `PointStatus = N'Khả dụng'` |

**Các cột quan trọng:**

| Cột | Kiểu | Ràng buộc | Giải thích |
|---|---|---|---|
| `Power_kW` | `DECIMAL(7,2)` | CHECK >= 0 | Công suất sạc (kW) — 2 số thập phân |
| `ConnectorType` | `NVARCHAR(20)` | NULL | Loại đầu nối (Type 1, Type 2, CCS, CHAdeMO) |
| `PointStatus` | `NVARCHAR(20)` | CHECK IN (Khả dụng, Đang bận, Đang lỗi, Đã tắt) | Trạng thái — mặc định là Khả dụng |

**Business rules:**
- Một trạm có thể có nhiều điểm sạc
- Công suất >= 0
- Trạng thái được tự động cập nhật bởi trigger khi phiên sạc bắt đầu/kết thúc

### 5.5 `Users.Customers`

| Thuộc tính | Chi tiết |
|---|---|
| **Mục đích** | Lưu thông tin tài khoản khách hàng |
| **Khóa chính** | `UserID INT IDENTITY(1,1)` |
| **DEFAULT** | `WalletBalance = 0`, `AccountStatus = N'Chưa mở'` |

**Các cột quan trọng:**

| Cột | Kiểu | Ràng buộc | Giải thích |
|---|---|---|---|
| `Email` | `NVARCHAR(50)` | UNIQUE, NOT NULL | Email đăng nhập — duy nhất |
| `PasswordHash` | `NCHAR(64)` | CHECK LEN = 64 | Mã hash SHA-256 — cố định 64 ký tự hex |
| `WalletBalance` | `MONEY` | CHECK >= 0 | Số dư ví điện tử |
| `AccountStatus` | `NVARCHAR(20)` | CHECK IN (Đang mở, Bị khóa, Chưa mở) | Trạng thái tài khoản |

**Giải thích kiểu dữ liệu `NCHAR(64)` cho PasswordHash:**
- `HASHBYTES('SHA2_256', ...)` tạo ra 32 bytes
- `CONVERT(NCHAR(64), ..., 2)` chuyển thành chuỗi hex 64 ký tự
- `NCHAR` (fixed-length) đảm bảo mọi hash đều đúng độ dài 64
- Lưu hash thay vì plaintext giúp bảo vệ thông tin đăng nhập

**Business rules:**
- Email và số điện thoại duy nhất
- Số dư ví không âm
- Tài khoản "Bị khóa" không thể thực hiện phiên sạc

### 5.6 `Users.Vehicles`

| Thuộc tính | Chi tiết |
|---|---|
| **Mục đích** | Lưu thông tin phương tiện của khách hàng |
| **Khóa chính** | `VehicleID INT IDENTITY(1,1)` |
| **Khóa ngoại** | `UserID` → `Customers` |

| Cột | Kiểu | Ràng buộc | Giải thích |
|---|---|---|---|
| `PlateNumber` | `VARCHAR(20)` | UNIQUE, NOT NULL | Biển số xe — duy nhất toàn quốc |
| `BatteryCapacity_kWh` | `DECIMAL(5,2)` | CHECK >= 0 | Dung lượng pin |

**Giải thích `VARCHAR` thay vì `NVARCHAR` cho biển số xe:**
Biển số xe tại Việt Nam chỉ gồm chữ không dấu và số, do đó `VARCHAR` tiết kiệm 50% dung lượng so với `NVARCHAR`.

**Business rules:**
- Một khách hàng có thể có nhiều xe
- Biển số xe duy nhất (trên toàn hệ thống)

### 5.7 `Operations.PricingPolicy`

| Thuộc tính | Chi tiết |
|---|---|
| **Mục đích** | Định nghĩa các chính sách giá cho dịch vụ sạc |
| **Khóa chính** | `PolicyID INT IDENTITY(1,1)` |

| Cột | Kiểu | Ràng buộc | Giải thích |
|---|---|---|---|
| `BasePrice_kWh` | `DECIMAL(19,4)` | CHECK >= 0 | Giá cơ bản mỗi kWh |
| `PeakHourMultiplier` | `DECIMAL(3,2)` | CHECK > 0 | Hệ số nhân giờ cao điểm |
| `AppliedFrom` | `DATETIME2` | NOT NULL | Ngày bắt đầu hiệu lực |
| `AppliedTo` | `DATETIME2` | NULL | Ngày kết thúc (NULL = vô thời hạn) |

**Business rules:**
- Giá cơ bản >= 0
- Hệ số nhân > 0 (giờ thấp điểm: < 1, giờ cao điểm: > 1)
- Ngày kết thúc phải sau ngày bắt đầu
- `AppliedTo` NULL cho phép chính sách vô thời hạn

### 5.8 `Operations.ChargingSession`

| Thuộc tính | Chi tiết |
|---|---|
| **Mục đích** | Ghi nhận mỗi phiên sạc — bảng trung tâm của hệ thống |
| **Khóa chính** | `SessionID BIGINT IDENTITY(1,1)` — BIGINT vì số lượng phiên sạc rất lớn |
| **DEFAULT** | `StartTime = SYSDATETIME()`, `Status = N'Đang sạc'` |

| Cột | Kiểu | Ràng buộc | Giải thích |
|---|---|---|---|
| `UserID` | `INT` | FK → Customers | Khách hàng thực hiện sạc |
| `PointID` | `INT` | FK → ChargingPoint | Điểm sạc được sử dụng |
| `PolicyID` | `INT` | FK → PricingPolicy | Chính sách giá áp dụng |
| `StartTime` | `DATETIME2` | NOT NULL | Thời điểm bắt đầu |
| `EndTime` | `DATETIME2` | NULL | Thời điểm kết thúc (NULL nếu đang sạc) |
| `Total_kWh` | `DECIMAL(13,4)` | CHECK >= 0, NULL | Tổng kWh tiêu thụ |
| `CostTotal` | `MONEY` | CHECK >= 0, NULL | Tổng chi phí |
| `Status` | `NVARCHAR(20)` | CHECK (Đang sạc, Đã sạc xong) | Trạng thái phiên |

**Lý do chọn `BIGINT` cho SessionID:**

Dự kiến mỗi ngày có hàng ngàn phiên sạc. `INT` (tối đa 2,1 tỷ) có thể đạt giới hạn trong vài năm. `BIGINT` (tối đa 9,2 triệu tỷ) đảm bảo hệ thống hoạt động không giới hạn thời gian.

**Business rules:**
- StartTime < EndTime (đảm bảo thời gian hợp lý)
- Total_kWh và CostTotal >= 0
- Khi phiên kết thúc, trigger tự động cập nhật ChargingPoint.PointStatus

### 5.9 `Operations.Transactions`

| Thuộc tính | Chi tiết |
|---|---|
| **Mục đích** | Ghi nhận giao dịch tài chính từ phiên sạc |
| **Khóa chính** | `TransactionID BIGINT IDENTITY(1,1)` |
| **Khóa ngoại** | `UserID` → `Customers`, `SessionID` → `ChargingSession` |

| Cột | Kiểu | Ràng buộc | Giải thích |
|---|---|---|---|
| `Amount` | `MONEY` | CHECK >= 0 | Số tiền giao dịch |
| `TransactionType` | `NVARCHAR(20)` | CHECK IN (Thanh toán, Nạp tiền, Hoàn tiền, Rút tiền) | Loại giao dịch |
| `[Timestamp]` | `DATETIME2` | CHECK 1990–2030 | Thời điểm giao dịch |

**Business rules:**
- Mỗi phiên sạc chỉ có MỘT giao dịch thanh toán (enforced bằng trigger)
- Số tiền giao dịch phải khớp với CostTotal của phiên sạc (enforced bằng trigger)
- Timestamp trong khoảng 1990–2030 (ngăn dữ liệu lỗi)
- `[Timestamp]` dùng dấu ngoặc vuông vì `TIMESTAMP` là từ khóa trong SQL Server

### 5.10 `Monitoring.ErrorLogs`

| Thuộc tính | Chi tiết |
|---|---|
| **Mục đích** | Ghi nhật ký lỗi thiết bị tại các điểm sạc |
| **Khóa chính** | `ErrorID INT IDENTITY(1,1)` |
| **DEFAULT** | `OccurredAt = SYSDATETIME()` |

| Cột | Kiểu | Ràng buộc | Giải thích |
|---|---|---|---|
| `PointID` | `INT` | FK → ChargingPoint | Điểm sạc gặp lỗi |
| `ErrorCode` | `NVARCHAR(20)` | NOT NULL | Mã lỗi |
| `Severity` | `NVARCHAR(20)` | CHECK (Thấp, Trung bình, Cao, Nguy kịch) | Mức độ nghiêm trọng |

**Business rules:**
- `OccurredAt < ResolvedAt` — thời gian xảy ra lỗi phải trước thời gian khắc phục
- Trigger tự động tạo error log khi ChargingPoint chuyển sang trạng thái "Đang lỗi"

### 5.11 `Monitoring.MaintenanceSchedule`

| Thuộc tính | Chi tiết |
|---|---|
| **Mục đích** | Lập lịch và theo dõi bảo trì trạm sạc |
| **Khóa chính** | `ScheduleID INT IDENTITY(1,1)` |
| **Khóa ngoại** | `StationID` → `ChargingStation` |

| Cột | Kiểu | Ràng buộc | Giải thích |
|---|---|---|---|
| `TechnicianName` | `NVARCHAR(100)` | NOT NULL | Tên kỹ thuật viên phụ trách |
| `Status` | `NVARCHAR(20)` | DEFAULT N'Đã lên lịch', CHECK (Đã lên lịch, Đang thực hiện, Hoàn thành, Hủy) | Trạng thái bảo trì |

---

## 6. Phân tích Relationships

### 6.1 Ma trận quan hệ

| Bảng 1 | Quan hệ | Bảng 2 | Khóa ngoại | Ý nghĩa |
|---|---|---|---|---|
| `ChargingStation` | N:1 | `Franchisee` | `FranchiseeID` | Một doanh nghiệp có nhiều trạm |
| `ChargingStation` | N:1 | `ElectricitySuppliers` | `SupplierID` | Một nhà cung cấp phục vụ nhiều trạm |
| `ChargingPoint` | N:1 | `ChargingStation` | `StationID` | Một trạm có nhiều điểm sạc |
| `Vehicles` | N:1 | `Customers` | `UserID` | Một khách hàng có nhiều xe |
| `ChargingSession` | N:1 | `Customers` | `UserID` | Một khách hàng có nhiều phiên |
| `ChargingSession` | N:1 | `ChargingPoint` | `PointID` | Một điểm sạc có nhiều phiên (lịch sử) |
| `ChargingSession` | N:1 | `PricingPolicy` | `PolicyID` | Nhiều phiên dùng chung một chính sách giá |
| `Transactions` | 1:1 | `ChargingSession` | `SessionID` | Mỗi phiên có đúng một giao dịch |
| `Transactions` | N:1 | `Customers` | `UserID` | Một khách hàng có nhiều giao dịch |
| `ErrorLogs` | N:1 | `ChargingPoint` | `PointID` | Một điểm có nhiều lỗi |
| `MaintenanceSchedule` | N:1 | `ChargingStation` | `StationID` | Một trạm có nhiều lịch bảo trì |

### 6.2 Đặc điểm thiết kế relationship

**Không sử dụng ON DELETE CASCADE:**
Hệ thống cố tình KHÔNG dùng `ON DELETE CASCADE` vì lý do an toàn dữ liệu:
- Không thể vô tình xóa khách hàng đang có phiên sạc
- Không thể vô tình xóa trạm đang có điểm sạc
- Mọi xóa đều phải qua ứng dụng, đảm bảo kiểm tra business logic trước

**Sử dụng LEFT JOIN khi cần:**
Các bảng có quan hệ tùy chọn sử dụng `LEFT JOIN` thay vì `INNER JOIN`:
- `Vehicles` với `Customers` (khách hàng có thể chưa đăng ký xe)
- `ChargingSession` với `ChargingPoint` (phiên chưa kết thúc)

---

## 7. Phân tích Normalization

### 7.1 Đánh giá chuẩn hóa

| Bảng | 1NF | 2NF | 3NF | Ghi chú |
|---|---|---|---|---|
| `Franchisee` | ✓ | ✓ | ✓ | Không có phụ thuộc bắc cầu |
| `ElectricitySuppliers` | ✓ | ✓ | ✓ | |
| `ChargingStation` | ✓ | ✓ | ✓ | Khóa ngoại đơn giản |
| `ChargingPoint` | ✓ | ✓ | ✓ | |
| `Customers` | ✓ | ✓ | ✓ | |
| `Vehicles` | ✓ | ✓ | ✓ | |
| `PricingPolicy` | ✓ | ✓ | ✓ | |
| `ChargingSession` | ✓ | ✓ | ✓ | |
| `Transactions` | ✓ | ✓ | ✓ | |
| `ErrorLogs` | ✓ | ✓ | ✓ | |
| `MaintenanceSchedule` | ✓ | ✓ | ✓ | |

### 7.2 Ví dụ phân tích 3NF cho ChargingStation

**Bước 1 — 1NF:** Mỗi cột có giá trị nguyên tử, không có nhóm lặp.
```
StationID | StationName | Address | StationStatus | FranchiseeID | SupplierID
```
✓ Tất cả cột đều nguyên tử.

**Bước 2 — 2NF:** Mỗi cột không khóa phụ thuộc đầy đủ vào khóa chính.
- Khóa chính: `StationID`
- `FranchiseeID` phụ thuộc vào `StationID` (mỗi trạm có một chủ)
- Không có phụ thuộc từng phần (vì khóa chính là đơn cột)
✓ Đạt 2NF.

**Bước 3 — 3NF:** Không có phụ thuộc bắc cầu.
- `FranchiseeID` → `FranchiseeName` (đã tách sang bảng Franchisee)
- `SupplierID` → `SupplierName` (đã tách sang bảng ElectricitySuppliers)
✓ Đạt 3NF.

### 7.3 Denormalization có chủ đích

**ChargingSession.UserID** — Có thể suy ra từ `PointID → ChargingStation`, nhưng vì UserID thường xuyên được truy vấn (báo cáo, lịch sử), việc lưu trực tiếp giúp tránh JOIN không cần thiết. Đây là denormalization có kiểm soát.

---

## 8. Phân tích Indexes

### 8.1 Chiến lược indexing

| Mục tiêu | Chiến lược |
|---|---|
| **FK joins** | Index trên tất cả khóa ngoại |
| **Báo cáo thời gian** | Index trên timestamp với INCLUDE |
| **Tra cứu trạng thái** | Index trên status column với INCLUDE |
| **Tìm kiếm email** | Index trên Customer.Email |

### 8.2 Từng index cụ thể

#### Foreign Key Indexes

| Index | Bảng | Cột | Query được tối ưu |
|---|---|---|---|
| `IX_ChargingStation_FranchiseeID` | `ChargingStation` | `FranchiseeID` | `SELECT ... WHERE FranchiseeID = ?` |
| `IX_ChargingStation_SupplierID` | `ChargingStation` | `SupplierID` | JOIN với ElectricitySuppliers |
| `IX_ChargingPoint_StationID` | `ChargingPoint` | `StationID` | Lấy danh sách điểm sạc theo trạm |
| `IX_Vehicles_UserID` | `Vehicles` | `UserID` | Lấy xe theo khách hàng |
| `IX_ChargingSession_UserID` | `ChargingSession` | `UserID` | Lịch sử sạc của khách hàng |
| `IX_ChargingSession_PointID` | `ChargingSession` | `PointID` | Lịch sử sạc của điểm sạc |
| `IX_ChargingSession_PolicyID` | `ChargingSession` | `PolicyID` | JOIN với PricingPolicy |
| `IX_Transactions_UserID` | `Transactions` | `UserID` | Lịch sử giao dịch khách hàng |
| `IX_Transactions_SessionID` | `Transactions` | `SessionID` | JOIN 1-1 với ChargingSession |
| `IX_ErrorLogs_PointID` | `ErrorLogs` | `PointID` | Lỗi theo điểm sạc |
| `IX_MaintenanceSchedule_StationID` | `MaintenanceSchedule` | `StationID` | Lịch bảo trì theo trạm |

#### Reporting Indexes (Covering Indexes)

**`IX_Transactions_Timestamp`**
```sql
ON Transactions ([Timestamp])
INCLUDE (Amount, TransactionType)
```
- **Mục đích:** Tối ưu báo cáo doanh thu theo tháng
- **Vấn đề giải quyết:** `WHERE YEAR([Timestamp]) = 2025 GROUP BY MONTH([Timestamp])` — index này cho phép truy vấn doanh thu mà không cần đọc toàn bộ bảng (Index Seek thay vì Table Scan)
- **INCLUDE:** `Amount` và `TransactionType` được lưu kèm ở leaf level, giúp query hoàn toàn được cover bởi index (không cần Key Lookup)

**`IX_ChargingSession_StartTime_EndTime`**
```sql
ON ChargingSession (StartTime, EndTime)
INCLUDE (Total_kWh, CostTotal)
```
- **Mục đích:** Tối ưu báo cáo hiệu suất trạm và phân tích giờ sạc
- **Vấn đề giải quyết:** Các truy vấn lọc theo khoảng thời gian (vd: phiên trong tháng 4) sẽ sử dụng Index Seek trên `StartTime`
- **INCLUDE:** `Total_kWh` và `CostTotal` phục vụ các hàm tổng hợp (SUM, AVG)

**`IX_ChargingStation_StationStatus`**
```sql
ON ChargingStation (StationStatus)
INCLUDE (StationName, Address)
```
- **Mục đích:** Liệt kê trạm theo trạng thái (vd: tất cả trạm "Đang bảo trì")
- **Vấn đề giải quyết:** Lọc theo `StationStatus` thay vì full scan

**`IX_Customers_Email`**
```sql
ON Customers (Email)
INCLUDE (FullName, AccountStatus)
```
- **Mục đích:** Tra cứu khách hàng theo email khi đăng nhập
- **Vấn đề giải quyết:** Tìm kiếm email nhanh, đồng thời có sẵn tên và trạng thái mà không cần Key Lookup

---

## 9. Phân tích Stored Procedures

### 9.1 `Operations.sp_StartChargingSession`

| Thuộc tính | Chi tiết |
|---|---|
| **Mục đích** | Bắt đầu một phiên sạc mới |
| **Input** | `@UserID INT`, `@PointID INT`, `@PolicyID INT` |
| **Output** | `SessionID BIGINT`, message |
| **Transaction** | Có — `BEGIN TRANSACTION` + `COMMIT`/`ROLLBACK` |

**Quy trình xử lý:**

```
1. Kiểm tra UserID có tồn tại và tài khoản "Đang mở"
2. Kiểm tra PointID có tồn tại và trạng thái "Khả dụng"
3. Kiểm tra PolicyID có hiệu lực (GETDATE() BETWEEN AppliedFrom AND AppliedTo)
4. BEGIN TRANSACTION
5. INSERT vào ChargingSession → trigger tự động cập nhật PointStatus
6. Lấy SCOPE_IDENTITY() làm SessionID
7. COMMIT
8. Trả về SessionID
```

**Xử lý lỗi:**
- `TRY...CATCH` bao quanh transaction
- Nếu có lỗi, `ROLLBACK` và `THROW` lại exception
- Mỗi lỗi validation trả về return code âm khác nhau (giúp client xác định nguyên nhân)

**Race condition:** Kiểm tra `PointStatus = N'Khả dụng'` và `INSERT` không được thực hiện trong cùng một atomic operation. Tuy nhiên, trigger tự động cập nhật PointStatus ngay sau INSERT, nên khoảng thời gian dễ tổn thương là rất nhỏ.

### 9.2 `Operations.sp_EndChargingSession`

| Thuộc tính | Chi tiết |
|---|---|
| **Mục đích** | Kết thúc một phiên sạc và tính toán chi phí |
| **Input** | `@SessionID BIGINT`, `@Total_kWh DECIMAL(13,4)` |
| **Output** | `SessionID`, `Total_kWh`, `CostTotal`, message |

**Quy trình xử lý:**

```
1. Lấy PointID, PolicyID từ ChargingSession (cần Status = N'Đang sạc')
2. Kiểm tra session tồn tại
3. Lấy thông tin giá từ PricingPolicy
4. Kiểm tra chính sách giá còn hiệu lực (IF @BasePrice IS NULL → lỗi)
5. Tính CostTotal = fn_CalculateChargingCost(@Total_kWh, @BasePrice, @Multiplier)
6. BEGIN TRANSACTION
7. UPDATE ChargingSession: EndTime, Total_kWh, CostTotal, Status = N'Đã sạc xong'
8. Trigger tự động cập nhật PointStatus = N'Khả dụng'
9. COMMIT
```

**Tại sao cần kiểm tra PricingPolicy hai lần?**
Chính sách giá có thể bị xóa hoặc vô hiệu hóa giữa lúc bắt đầu và kết thúc phiên sạc. Việc kiểm tra lại tại `sp_EndChargingSession` đảm bảo tính chính xác của giá cược.

### 9.3 `Operations.sp_CreateTransaction`

| Thuộc tính | Chi tiết |
|---|---|
| **Mục đích** | Tạo giao dịch thanh toán và trừ tiền từ ví |
| **Input** | `@UserID INT`, `@SessionID BIGINT`, `@Amount MONEY`, `@TransactionType NVARCHAR(20)` |
| **Output** | `TransactionID BIGINT`, message |

**Các bước validation:**
1. Phiên sạc đã kết thúc (`Status = N'Đã sạc xong'`)
2. Khách hàng còn hoạt động
3. Số tiền khớp với `CostTotal` của phiên
4. Số dư ví đủ để thanh toán

**Transaction:**
```
1. BEGIN TRANSACTION
2. INSERT vào Transactions
3. UPDATE Customers SET WalletBalance = WalletBalance - Amount
4. COMMIT
```

**An toàn transaction:** Nếu bước 3 thất bại (vd: CHECK constraint WalletBalance >= 0), CATCH block sẽ ROLLBACK toàn bộ, không mất tiền.

### 9.4 `Reports.sp_GetMonthlyRevenue`

| Thuộc tính | Chi tiết |
|---|---|
| **Mục đích** | Báo cáo doanh thu tổng hợp theo tháng |
| **Input** | `@Year INT` (NULL = năm hiện tại) |
| **Output** | Bảng: RevenueYear, RevenueMonth, Tháng (MM-yyyy), Số giao dịch, Tổng doanh thu, Giá trị trung bình |

**Tối ưu hóa:**
- `GROUP BY YEAR(...), MONTH(...)` thay vì `FORMAT()` — tránh non-deterministic CLR function
- Index `IX_Transactions_Timestamp` cover được query này

### 9.5 `Reports.sp_GetTopStations`

| Thuộc tính | Chi tiết |
|---|---|
| **Mục đích** | Top trạm sạc theo doanh thu hoặc số phiên |
| **Input** | `@TopCount INT = 10`, `@OrderBy NVARCHAR(20) = N'Doanh thu'` |
| **Output** | StationID, StationName, FranchiseeName, TotalSessions, TotalRevenue, Avg_kWh |

**So sánh case-insensitive:** `LOWER(@OrderBy) = LOWER(N'Doanh thu')` đảm bảo hoạt động trên mọi collation.

---

## 10. Phân tích Functions

### 10.1 `Operations.fn_CalculateChargingCost`

| Thuộc tính | Chi tiết |
|---|---|
| **Mục đích** | Tính chi phí dựa trên kWh, giá cơ bản và hệ số nhân |
| **Input** | `@Total_kWh DECIMAL(13,4)`, `@BasePrice_kWh DECIMAL(19,4)`, `@PeakHourMultiplier DECIMAL(3,2)` |
| **Output** | `MONEY` |
| **Loại** | Scalar function |

**Công thức:**
```
Cost = Total_kWh × BasePrice_kWh × PeakHourMultiplier
```

**Xử lý NULL:**
```sql
IF @Total_kWh IS NULL OR @Total_kWh <= 0 RETURN 0;
IF @BasePrice_kWh IS NULL OR @PeakHourMultiplier IS NULL RETURN 0;
```
Cả ba tham số đều được kiểm tra NULL để tránh kết quả NULL không mong muốn.

**Tính quyết định (Determinism):** Hàm này là **deterministic** (kết quả chỉ phụ thuộc vào tham số, không có dữ liệu ngoài). Điều này cho phép sử dụng trong indexed views và computed columns.

### 10.2 `Reports.fn_GetStationRevenue`

| Thuộc tính | Chi tiết |
|---|---|
| **Mục đích** | Tính tổng doanh thu của một trạm trong khoảng thời gian |
| **Input** | `@StationID INT`, `@FromDate DATETIME2`, `@ToDate DATETIME2` |
| **Output** | `MONEY` |

**Logic:**
```sql
SELECT @TotalRevenue = SUM(s.CostTotal)
FROM ChargingSession s
JOIN ChargingPoint p ON s.PointID = p.PointID
WHERE p.StationID = @StationID
  AND s.Status = N'Đã sạc xong'
  AND s.StartTime >= @FromDate
  AND (s.EndTime IS NULL OR s.EndTime <= @ToDate);
```

---

## 11. Phân tích Triggers

### 11.1 `trg_ChargingPoint_AutoUpdateStatus`

| Thuộc tính | Chi tiết |
|---|---|
| **Bảng** | `Operations.ChargingSession` |
| **Thời điểm** | `AFTER INSERT, UPDATE` |
| **Mục đích** | Tự động cập nhật trạng thái điểm sạc |

**Hành vi:**

| Sự kiện | Điều kiện | Hành động |
|---|---|---|
| INSERT | Status = N'Đang sạc' | Đặt PointStatus = N'Đang bận' |
| UPDATE | Status chuyển từ N'Đang sạc' → N'Đã sạc xong' | Đặt PointStatus = N'Khả dụng' |

**An toàn đa hàng (multi-row safety):**
Trigger sử dụng JOIN giữa `inserted` và `deleted` tables (thay vì biến scalar), do đó hoạt động chính xác với batch insert/update.

**Bảo vệ:**
- Chỉ cập nhật `PointStatus = N'Đang bận'` khi hiện tại là `N'Khả dụng'`
- Chỉ cập nhật `PointStatus = N'Khả dụng'` khi hiện tại là `N'Đang bận'`
Ngăn chặn ghi đè trạng thái không mong muốn.

### 11.2 `trg_Transactions_ValidateData`

| Thuộc tính | Chi tiết |
|---|---|
| **Bảng** | `Operations.Transactions` |
| **Thời điểm** | `AFTER INSERT` |
| **Mục đích** | Kiểm tra tính hợp lệ của giao dịch |

**Các kiểm tra:**
1. **Amount khớp CostTotal:** `i.Amount = s.CostTotal` — mỗi giao dịch phải đúng với chi phí phiên sạc
2. **Không trùng lặp:** Mỗi `SessionID` chỉ được có một giao dịch

**Cơ chế ROLLBACK:**
Khi phát hiện vi phạm, trigger gọi `ROLLBACK TRANSACTION` và `RAISERROR`. Toàn bộ giao dịch bị hủy.

### 11.3 `trg_ChargingPoint_AutoErrorLog`

| Thuộc tính | Chi tiết |
|---|---|
| **Bảng** | `Infrastructure.ChargingPoint` |
| **Thời điểm** | `AFTER UPDATE` |
| **Mục đích** | Tự động tạo error log khi điểm sạc chuyển sang lỗi |

**Hành vi:**
Khi `PointStatus` thay đổi từ bất kỳ trạng thái nào sang `N'Đang lỗi'`, trigger tự động INSERT một bản ghi vào `Monitoring.ErrorLogs` với:
- `ErrorCode = 'AUTO_ERR'`
- `Severity = N'Trung bình'`
- `OccurredAt = SYSDATETIME()`

### 11.4 Phân tích an toàn trigger

**Không có đệ quy (no recursion):**
- `trg_ChargingPoint_AutoUpdateStatus` cập nhật `ChargingPoint` — nhưng không có trigger nào trên ChargingPoint cập nhật ChargingSession (không có vòng lặp)
- `trg_Transactions_ValidateData` chỉ đọc (SELECT) các bảng khác — không có vòng lặp

**Xử lý multi-row:**
Tất cả trigger đều sử dụng set-based operations (INNER JOIN với inserted/deleted) thay vì CURSOR hoặc vòng lặp.

---

## 12. Phân tích Views

### 12.1 `Reports.vw_MonthlyRevenue`

**Mục đích:** Báo cáo doanh thu hàng tháng theo từng trạm và doanh nghiệp nhượng quyền.

**Cấu trúc query:**
```
Transactions → ChargingSession → ChargingPoint → ChargingStation → Franchisee
```

**Các chỉ số:**
- `TransactionCount` — Số giao dịch
- `UniqueCustomers` — Số khách hàng duy nhất
- `TotalRevenue` — Tổng doanh thu
- `AvgTransactionValue` — Giá trị giao dịch trung bình

**Tối ưu:**
- Không sử dụng `FORMAT()` trong GROUP BY (tránh non-deterministic CLR function)
- Sử dụng string concatenation đơn giản: `RIGHT('0' + MONTH, 2) + '-' + YEAR`

### 12.2 `Reports.vw_StationPerformance`

**Mục đích:** Đánh giá hiệu suất từng trạm sạc.

**Các chỉ số KPI:**

| Chỉ số | Công thức | Ý nghĩa |
|---|---|---|
| `TotalPoints` | COUNT(PointID) | Tổng số điểm sạc |
| `AvailablePoints` | SUM(CASE WHEN PointStatus = N'Khả dụng') | Điểm sạc sẵn sàng |
| `BusyPoints` | SUM(CASE WHEN PointStatus = N'Đang bận') | Điểm sạc đang dùng |
| `ErrorPoints` | SUM(CASE WHEN PointStatus = N'Đang lỗi') | Điểm sạc bị lỗi |
| `TotalSessions` | COUNT(DISTINCT SessionID) | Tổng phiên sạc |
| `TotalEnergy_kWh` | SUM(Total_kWh) | Tổng năng lượng |
| `TotalRevenue` | SUM(CostTotal) | Tổng doanh thu |
| `RevenuePerSession` | Revenue / Sessions | Doanh thu trung bình mỗi phiên |

### 12.3 `Reports.vw_ActiveChargingSessions`

**Mục đích:** Giám sát thời gian thực các phiên sạc đang diễn ra.

**Các cột thông tin:**
- Thông tin khách hàng: Tên, SĐT, Biển số xe
- Thông tin trạm: Tên trạm, Mã điểm sạc, Loại đầu nối
- Thông tin giá: Chính sách, Giá cơ bản
- Thời gian: `StartTime`, `DurationMinutes` (tính bằng `DATEDIFF`)

**Xử lý nhiều xe:**
Sử dụng `OUTER APPLY (SELECT TOP 1 PlateNumber FROM Vehicles WHERE UserID = ...)` để đảm bảo mỗi phiên chỉ hiển thị một biển số xe, ngay cả khi khách hàng có nhiều xe.

---

## 13. Phân tích Security & RBAC

### 13.1 Mô hình phân quyền

```
SQL Server Logins (server-level)
│
├── ev_admin_login
├── ev_manager_login
├── ev_technician_login
└── ev_readonly_login
        │
        ▼
Database Users (database-level)
        │
        ▼
Database Roles
├── Admin
├── Manager
├── Technician
└── ReadOnly
        │
        ▼
Schema-Level Permissions (GRANT)
```

### 13.2 Ma trận quyền hạn

| Schema | Admin | Manager | Technician | ReadOnly |
|---|---|---|---|---|
| `Infrastructure` | CONTROL | SELECT | SELECT, INSERT, UPDATE, DELETE | SELECT |
| `Users` | CONTROL | SELECT | — | SELECT |
| `Operations` | CONTROL | SELECT, INSERT, UPDATE, DELETE | SELECT, EXECUTE | SELECT |
| `Monitoring` | CONTROL | SELECT | SELECT, INSERT, UPDATE, DELETE | SELECT |
| `Reports` | CONTROL | SELECT, INSERT, UPDATE, DELETE, EXECUTE | — | SELECT |
| `Security` | CONTROL | — | — | — |

### 13.3 Giải thích quyền hạn

**Admin (Quản trị viên):**
- `CONTROL` trên mọi schema — toàn quyền
- `VIEW DEFINITION` trên database — có thể xem metadata
- **Mục đích:** Quản trị hệ thống, tạo/xóa đối tượng, quản lý bảo mật

**Manager (Quản lý):**
- CRUD trên `Operations` và `Reports` — quản lý vận hành và báo cáo
- `SELECT` trên `Infrastructure`, `Users`, `Monitoring` — xem thông tin tham khảo
- `EXECUTE` trên `Operations` và `Reports` — chạy stored procedure
- **Mục đích:** Quản lý hoạt động hàng ngày, xem báo cáo

**Technician (Kỹ thuật viên):**
- CRUD trên `Infrastructure` và `Monitoring` — quản lý hạ tầng, bảo trì, ghi lỗi
- `SELECT` + `EXECUTE` trên `Operations` — xem lịch sử phiên sạc
- **Mục đích:** Bảo trì thiết bị, ghi nhận và sửa lỗi

**ReadOnly (Người đọc):**
- `SELECT` trên tất cả schema (trừ `Security`)
- **Mục đích:** Kiểm toán, báo cáo, phân tích dữ liệu

### 13.4 Nguyên tắc Least Privilege

Mỗi vai trò chỉ có quyền tối thiểu cần thiết để thực hiện công việc:
- Technician không thể xem thông tin tài khoản khách hàng
- ReadOnly không thể sửa dữ liệu
- Manager không thể quản lý bảo mật

---

## 14. Phân tích Reporting System

### 14.1 Báo cáo 1: Doanh thu theo tháng

**Mục đích:** Xem xu hướng doanh thu hàng tháng.

```sql
RIGHT(N'0' + CAST(MONTH(t.[Timestamp]) AS NVARCHAR(2)), 2) + N'-' + CAST(YEAR(t.[Timestamp]) AS NVARCHAR(4)) AS Thang,
COUNT(DISTINCT t.TransactionID) AS SoGiaoDich,
COUNT(DISTINCT t.UserID) AS SoKhachHang,
SUM(t.Amount) AS TongDoanhThu
```

**Index sử dụng:** `IX_Transactions_Timestamp` (Covering Index — không cần Key Lookup)

### 14.2 Báo cáo 2: Top trạm sạc

**Mục đích:** Xác định trạm sạc hiệu quả nhất.

**Điểm đặc biệt:** Sử dụng `LEFT JOIN` để bao gồm trạm chưa có phiên sạc nào.

### 14.3 Báo cáo 3: Khách hàng năng động

**Mục đích:** Xác định khách hàng có doanh thu cao nhất.

**Chỉ số:** Số phiên sạc, Tổng kWh, Tổng chi tiêu.

### 14.4 Báo cáo 4: Phân tích giờ sạc cao điểm

**Mục đích:** Xác định khung giờ có nhu cầu sạc cao nhất — phục vụ chiến lược giá.

```sql
DATEPART(HOUR, StartTime) AS GioTrongNgay,
COUNT(SessionID) AS SoPhien
```

**Business value:** Giúp xác định giờ cao điểm để áp dụng `PeakHourMultiplier` phù hợp.

### 14.5 Báo cáo 5: Hiệu suất nhượng quyền

**Mục đích:** Đánh giá hiệu quả từng doanh nghiệp nhượng quyền.

**Chỉ số quan trọng:**
```sql
ISNULL(SUM(ses.CostTotal) * f.RevenueShareRate / 100, 0) AS HoaHong
```
Tính hoa hồng dựa trên tổng doanh thu và tỷ lệ chia sẻ.

### 14.6 Báo cáo 6: Tần suất lỗi

**Mục đích:** Phân tích lỗi thiết bị để lập kế hoạch bảo trì.

**Chỉ số:** Số lần xuất hiện, số điểm sạc bị ảnh hưởng, số trạm bị ảnh hưởng.

---

## 15. Phân tích Backup & Restore

### 15.1 Chiến lược backup

| Loại | File | Tần suất đề xuất |
|---|---|---|
| **Full** | `EV_Charging_System_Full.bak` | Hàng tuần |
| **Differential** | `EV_Charging_System_Diff.bak` | Hàng ngày |
| **Transaction Log** | `EV_Charging_System_Log.trn` | Mỗi giờ |

### 15.2 Quy trình backup

1. **`xp_create_subdir`** — Tạo thư mục backup nếu chưa tồn tại
2. **`ALTER DATABASE SET RECOVERY FULL`** — Đảm bảo database ở chế độ FULL recovery (cần cho log backup)
3. **Full backup** — Bản sao đầy đủ đầu tiên
4. **Differential backup** — Chỉ backup những trang đã thay đổi từ lần full gần nhất
5. **Log backup** — Backup transaction log (cho phép point-in-time recovery)

### 15.3 Quy trình restore

**Restore Full:**
```sql
RESTORE DATABASE EV_Charging_System
FROM DISK = N'C:\Backup\EV_Charging_System_Full.bak'
WITH REPLACE, STATS = 10;
```

**Restore Point-in-Time:**
```sql
RESTORE DATABASE WITH NORECOVERY;   -- Phục hồi full backup
RESTORE DATABASE WITH NORECOVERY;   -- Phục hồi differential
RESTORE LOG WITH RECOVERY;          -- Phục hồi log đến thời điểm mong muốn
```

---

## 16. Phân tích Performance Optimization

### 16.1 SARGability

**SARG** = Search ARGument — khả năng sử dụng index seek thay vì scan.

**Vấn đề hiện tại:**
```sql
WHERE YEAR(t.[Timestamp]) = @Year
```
→ `WHERE YEAR(...)` là **non-SARGable**, buộc SQL Server phải quét toàn bộ index.

**Giải pháp đề xuất:**
```sql
WHERE t.[Timestamp] >= DATEFROMPARTS(@Year, 1, 1)
  AND t.[Timestamp] <  DATEFROMPARTS(@Year + 1, 1, 1)
```

**Tác động:** Chuyển từ Index Scan sang Index Seek, tăng tốc đáng kể cho báo cáo doanh thu hàng tháng.

### 16.2 Index Seek vs Table Scan

| Tình huống | Không có index | Có index |
|---|---|---|
| JOIN trên FranchiseeID | Table Scan ChargingStation (10 rows) | Index Seek (1-2 rows) |
| JOIN trên PointID | Table Scan ChargingSession (10 rows) | Index Seek (1-2 rows) |
| Tìm kiếm Email | Table Scan Customers (8 rows) | Index Seek (1 row) |
| Báo cáo doanh thu tháng | Table Scan Transactions (10 rows) | Index Seek + Cover |

Với dữ liệu seed nhỏ (10–25 rows/table), sự khác biệt không đáng kể. Nhưng với dữ liệu thực tế (hàng triệu rows), các index này là **rất quan trọng**.

### 16.3 Covering Indexes

Covering index chứa tất cả cột cần thiết cho một query, giúp SQL Server không cần truy cập vào clustered index (Key Lookup).

**Ví dụ:** Query báo cáo doanh thu sử dụng `IX_Transactions_Timestamp`:
- Cột key: `[Timestamp]` — dùng cho WHERE và ORDER BY
- Cột INCLUDE: `Amount`, `TransactionType` — dùng cho SELECT và SUM

→ SQL Server đọc hoàn toàn từ index, không chạm vào bảng chính.

### 16.4 Compilations và Recompilations

Stored procedures sử dụng `CREATE OR ALTER PROCEDURE` — giúp giữ lại query plan đã được biên dịch, tiết kiệm thời gian biên dịch lại mỗi lần gọi.

### 16.5 Transaction Performance

Các stored procedure duy trì transaction ngắn nhất có thể:
- `sp_StartChargingSession`: Chỉ 1 INSERT + SCOPE_IDENTITY
- `sp_EndChargingSession`: Chỉ 1 UPDATE
- `sp_CreateTransaction`: Chỉ 1 INSERT + 1 UPDATE

Transaction ngắn → khóa (lock) được giải phóng nhanh → giảm xung đột (deadlock).

---

## 17. Các Business Rules Quan Trọng

### 17.1 Quy tắc kinh doanh

| # | Business Rule | Implemented By | File |
|---|---|---|---|
| BR1 | Tỷ lệ chia sẻ doanh thu từ 0% đến 100% | CHECK constraint | `02_CreateTables.sql` |
| BR2 | Số dư ví không âm | CHECK constraint | `02_CreateTables.sql` |
| BR3 | Mỗi phiên sạc chỉ có một giao dịch | Trigger | `07_CreateTriggers.sql` |
| BR4 | Số tiền giao dịch khớp với chi phí phiên sạc | Trigger + SP | `07_CreateTriggers.sql` + `06_CreateStoredProcedures.sql` |
| BR5 | Tài khoản bị khóa không thể sạc | SP validation | `06_CreateStoredProcedures.sql` |
| BR6 | Điểm sạc không khả dụng không thể sử dụng | SP validation | `06_CreateStoredProcedures.sql` |
| BR7 | Chính sách giá phải còn hiệu lực | SP validation | `06_CreateStoredProcedures.sql` |
| BR8 | Số dư ví phải đủ để thanh toán | SP validation | `06_CreateStoredProcedures.sql` |
| BR9 | Password hash phải đúng 64 ký tự hex | CHECK constraint | `02_CreateTables.sql` |
| BR10 | Email và SĐT khách hàng là duy nhất | UNIQUE constraints | `02_CreateTables.sql` |

### 17.2 Business logic flow: Quy trình sạc hoàn chỉnh

```
KHÁCH HÀNG                    HỆ THỐNG                         KẾT QUẢ
    │                             │                                │
    │ [Bắt đầu sạc]              │                                │
    ├────────────────────────────>│                                │
    │                             │ sp_StartChargingSession        │
    │                             │ ├─ Kiểm tra tài khoản         │
    │                             │ ├─ Kiểm tra điểm sạc          │
    │                             │ ├─ Kiểm tra chính sách giá    │
    │                             │ ├─ INSERT phiên sạc           │
    │                             │ └─ Trigger → PointStatus=Busy │
    │                             │                                │
    │ <────── SessionID ──────────┤                                │
    │                             │                                │
    │ [Kết thúc sạc]             │                                │
    ├────────────────────────────>│                                │
    │                             │ sp_EndChargingSession          │
    │                             │ ├─ Tính Total_kWh             │
    │                             │ ├─ Tính CostTotal             │
    │                             │ ├─ UPDATE phiên sạc           │
    │                             │ └─ Trigger → PointStatus=Avail│
    │                             │                                │
    │ [Thanh toán]                │                                │
    ├────────────────────────────>│                                │
    │                             │ sp_CreateTransaction           │
    │                             │ ├─ Kiểm tra số dư             │
    │                             │ ├─ INSERT giao dịch           │
    │                             │ └─ Trừ tiền ví                │
    │                             │                                │
    │ <── TransactionID ──────────┤                                │
```

---

## 18. Các Rủi Ro Dữ Liệu

### 18.1 Rủi ro hiện tại

| Rủi ro | Mô tả | Mức độ | Giải pháp |
|---|---|---|---|
| **Race condition** | Kiểm tra PointStatus và INSERT không atomic | Trung bình | Thêm `UPDLOCK, HOLDLOCK` hint |
| **Không có VehicleID trong ChargingSession** | Không biết xe nào đã sạc | Cao | Thêm cột VehicleID |
| **YEAR() non-SARGable** | Phải scan toàn bộ index cho báo cáo tháng | Thấp | Sửa thành range query |
| **Không có archive policy** | Dữ liệu ErrorLogs, ChargingSession tăng mãi | Trung bình | Thêm partitioning hoặc archive job |
| **PasswordHash trong seed data** | Hash được tạo từ plaintext có trong script | Cao | Tạo hash riêng biệt, không public |

### 18.2 Rủi ro đã được xử lý

| Rủi ro | Xử lý | File |
|---|---|---|
| Mất tiền do không kiểm tra số dư | Thêm CHECK balance trước khi trừ | `06_CreateStoredProcedures.sql` |
| Chính sách giá hết hạn giữa phiên sạc | Kiểm tra lại khi kết thúc phiên | `06_CreateStoredProcedures.sql` |
| Xóa nhầm dữ liệu có quan hệ | Không dùng ON DELETE CASCADE | `02_CreateTables.sql` |
| Sai lệch dữ liệu báo cáo do FORMAT | Thay FORMAT bằng phép concatenation | `08_CreateViews.sql` |

---

## 19. Hạn Chế Hiện Tại của Hệ Thống

### 19.1 Hạn chế về chức năng

| Hạn chế | Tác động | Giải pháp tương lai |
|---|---|---|
| **Không hỗ trợ sạc đồng thời nhiều điểm** | Khách hàng chỉ sạc một điểm một lần | Thêm logic check overlapping sessions |
| **Không có lịch sử thay đổi giá** | Không xem được giá cũ của phiên | Thêm bảng PricingPolicyHistory |
| **Không quản lý inventory** | Không theo dõi phụ tùng, thiết bị dự phòng | Thêm schema `Inventory` |
| **Không có booking/đặt trước** | Khách hàng không thể đặt trước điểm sạc | Thêm bảng `Booking` |
| **Không có loyalty program** | Không có tích điểm, ưu đãi thành viên | Thêm bảng `Rewards` |

### 19.2 Hạn chế về kỹ thuật

| Hạn chế | Tác động | Giải pháp tương lai |
|---|---|---|
| **Không có partitioning** | Dữ liệu lịch sử lớn làm chậm query | Range partition trên ChargingSession.StartTime |
| **Không có data compression** | Tốn dung lượng lưu trữ | `ALTER TABLE ... REBUILD WITH (DATA_COMPRESSION = PAGE)` |
| **Không có audit trail** | Không biết ai đã sửa dữ liệu | SQL Server Audit hoặc trigger audit |
| **Không có full-text search** | Không tìm kiếm được địa chỉ, mô tả | CREATE FULLTEXT INDEX |
| **Không có HA/DR** | Rủi ro mất dữ liệu khi server lỗi | Always On Availability Groups hoặc failover |

### 19.3 Hạn chế về bảo mật

| Hạn chế | Giải pháp |
|---|---|
| **Mật khẩu trong seed data là public** | Sử dụng hash từ nguồn tin cậy, không commit plaintext |
| **Security schema chưa được bảo vệ** | Thêm `DENY SELECT ON SCHEMA::Security TO ReadOnly` |
| **Không có dynamic data masking** | Che dấu Email, Phone, WalletBalance với người đọc |

---

## 20. Hướng Phát Triển Tương Lai

### 20.1 Ngắn hạn (3–6 tháng)

1. **Thêm VehicleID vào ChargingSession**
   - Cho phép biết chính xác xe nào được sạc
   - Cập nhật stored procedures tương ứng

2. **Tối ưu SARGability**
   - Thay `YEAR(t.Timestamp) = @Year` bằng range query
   - Cải thiện hiệu năng báo cáo đáng kể

3. **Thêm audit trail**
   - Trigger hoặc Temporal Tables để ghi lại lịch sử thay đổi dữ liệu
   - Phục vụ kiểm toán và truy vết

### 20.2 Trung hạn (6–12 tháng)

4. **Hệ thống đặt lịch sạc (Booking)**
   - Bảng `Booking`: UserID, PointID, ScheduledTime, Duration, Status
   - Cho phép khách hàng đặt trước điểm sạc

5. **Chương trình khách hàng thân thiết**
   - Bảng `Rewards`: UserID, Points, Tier
   - Tích điểm cho mỗi phiên sạc

6. **Table Partitioning**
   - Partition ChargingSession theo tháng (StartTime)
   - Partition Transactions theo tháng (Timestamp)
   - Tăng tốc truy vấn dữ liệu lịch sử

### 20.3 Dài hạn (12–24 tháng)

7. **Báo cáo thời gian thực (Real-time Dashboard)**
   - Sử dụng SQL Server Reporting Services hoặc Power BI
   - Kết nối trực tiếp đến views `vw_ActiveChargingSessions`, `vw_StationPerformance`

8. **Tích hợp thanh toán bên thứ ba**
   - Thêm cột `PaymentGateway`, `ExternalTransactionID` vào Transactions
   - Hỗ trợ VNPAY, Momo, thẻ tín dụng

9. **Hỗ trợ đa ngôn ngữ**
   - Thêm bảng `Localization` để lưu UI strings
   - Cho phép giao diện tiếng Anh và tiếng Việt

10. **Mobile app API layer**
    - Tạo REST API endpoint gọi stored procedures
    - Xác thực qua JWT token

---

## Phụ Lục A: Cấu Trúc Thư Mục

```
database/
├── run_all.sql                        ← Master runner script
├── schema/
│   ├── 01_CreateDatabase.sql          ← CREATE DATABASE + 6 schemas
│   └── 02_CreateTables.sql            ← 11 tables với đầy đủ constraints
├── indexes/
│   └── 03_CreateIndexes.sql           ← 15 indexes
├── seed/
│   └── 04_SeedData.sql                ← Dữ liệu mẫu thực tế
├── functions/
│   └── 05_CreateFunctions.sql         ← 2 scalar functions
├── stored_procedures/
│   └── 06_CreateStoredProcedures.sql  ← 5 stored procedures
├── triggers/
│   └── 07_CreateTriggers.sql          ← 3 triggers
├── views/
│   └── 08_CreateViews.sql             ← 3 views
├── security/
│   └── 09_SecuritySetup.sql           ← 4 logins, 4 users, 4 roles, grants
├── reports/
│   └── 10_ReportQueries.sql           ← 6 báo cáo phân tích
└── backup/
    └── 11_BackupRestore.sql           ← Full + Diff + Log backup & restore
```

## Phụ Lục B: Thống Kê Database

| Thành phần | Số lượng |
|---|---|
| Database | 1 |
| Schema | 6 |
| Tables | 11 |
| Indexes | 15 |
| Functions | 2 |
| Stored Procedures | 5 |
| Triggers | 3 |
| Views | 3 |
| Logins | 4 |
| Database Users | 4 |
| Database Roles | 4 |
| CHECK Constraints | 17 |
| UNIQUE Constraints | 7 |
| FOREIGN KEY Constraints | 11 |
| DEFAULT Constraints | 7 |

---

**Tài liệu được tạo bởi:** Database Architect & Technical Documentation Team
**Ngày tạo:** 2025
**Phiên bản:** 1.0
**Môn học:** IE103 — Quản lý Thông tin
