# Hướng Dẫn Hệ Thống Cơ Sở Dữ Liệu
## Hệ thống quản lý mạng lưới trạm sạc xe điện & doanh nghiệp nhượng quyền

**Tên dự án:** `EV_Charging_System`
**Nền tảng:** Microsoft SQL Server
**Phiên bản tài liệu:** 3.0 (Hướng dẫn cho người mới)
**Mục đích:** Giúp bất kỳ ai — dù chưa từng học database — có thể hiểu toàn bộ hệ thống này hoạt động như thế nào.

---

## Mục Lục

1. [Giới thiệu dự án](#1-giới-thiệu-dự-án)
2. [Tổng quan hệ thống](#2-tổng-quan-hệ-thống)
3. [Kiến thức Database Cơ Bản](#3-kiến-thức-database-cơ-bản)
4. [Các Module Chính Của Hệ Thống](#4-các-module-chính-của-hệ-thống)
5. [Giải Thích Từng Bảng](#5-giải-thích-từng-bảng)
6. [Giải Thích Relationships (Quan Hệ Giữa Các Bảng)](#6-giải-thích-relationships-quan-hệ-giữa-các-bảng)
7. [Luồng Dữ Liệu Thực Tế](#7-luồng-dữ-liệu-thực-tế)
8. [Giải Thích Realtime System](#8-giải-thích-realtime-system)
9. [Giải Thích Analytics & Dashboard](#9-giải-thích-analytics--dashboard)
10. [Enterprise Features (Tính Năng Doanh Nghiệp)](#10-enterprise-features-tính-năng-doanh-nghiệp)
11. [Các Tính Năng SQL Server Được Sử Dụng](#11-các-tính-năng-sql-server-được-sử-dụng)
12. [Các Vấn Đề Database Thực Tế](#12-các-vấn-đề-database-thực-tế)
13. [Tổng Kết Kiến Trúc](#13-tổng-kết-kiến-trúc)

---

## 1. Giới thiệu dự án

### 1.1 Hệ thống này là gì?

Hãy tưởng tượng bạn đang lái một chiếc xe điện (EV - Electric Vehicle). Xe của bạn sắp hết pin. Bạn cần tìm một trạm sạc gần nhất, đến đó, cắm sạc, và trả tiền.

Hệ thống **EV_Charging_System** là phần mềm đứng sau quản lý toàn bộ quá trình đó. Nó giống như "bộ não" điều khiển mạng lưới trạm sạc xe điện.

### 1.2 Bài toán thực tế nào đang được giải quyết?

**Vấn đề:** Làm sao để một công ty có thể vận hành hàng trăm trạm sạc xe điện trên khắp cả nước một cách hiệu quả?

Các câu hỏi cụ thể cần giải quyết:
- **Chủ trạm:** Ai đang sạc? Trạm nào đang rảnh? Doanh thu hôm nay bao nhiêu?
- **Khách hàng:** Tìm trạm gần đây ở đâu? Sạc hết bao nhiêu tiền? Lịch sử sạc thế nào?
- **Kỹ thuật:** Trạm nào đang hỏng? Cần bảo trì trạm nào?
- **Quản lý:** Franchise nào hoạt động tốt nhất? Giờ nào cao điểm? Doanh thu tổng thể ra sao?

### 1.3 EV Charging Network là gì?

**EV Charging Network** (Mạng lưới trạm sạc xe điện) là một hệ thống bao gồm:
- **Trạm sạc (Station):** Nơi đặt các điểm sạc, có thể có mái che, bãi đỗ xe
- **Điểm sạc (Charging Point):** Từng "cây sạc" riêng lẻ tại trạm, nơi bạn cắm dây vào xe
- **Hệ thống phần mềm:** Quản lý việc đặt lịch, sạc, thanh toán, giám sát

### 1.4 Franchise hoạt động ra sao?

**Franchise** (Nhượng quyền) giống như mô thức "cho thuê thương hiệu":
- Công ty mẹ (chủ hệ thống) cho phép các đối tác (Franchise Owner) mở trạm sạc dưới thương hiệu chung
- Chủ franchise đầu tư trạm sạc, công ty mẹ cung cấp phần mềm và hỗ trợ
- Doanh thu được chia theo tỷ lệ thỏa thuận (Revenue Share Rate)
- Ví dụ: Doanh thu 10 triệu, tỷ lệ chia 80%, chủ franchise nhận 8 triệu, công ty mẹ nhận 2 triệu

### 1.5 Ai sử dụng hệ thống này?

| Người dùng | Vai trò | Ví dụ |
|---|---|---|
| **Customer (Khách hàng)** | Người dùng cuối — đến trạm sạc xe | Bạn, tôi, bất kỳ ai có xe điện |
| **Franchise Owner (Chủ franchise)** | Người đầu tư trạm sạc | Anh A mở 5 trạm sạc ở quận 1 |
| **Operator (Điều hành viên)** | Nhân viên vận hành hệ thống | Nhân viên công ty mẹ giám sát mạng lưới |
| **Technician (Kỹ thuật viên)** | Người sửa chữa, bảo trì | Kỹ sư đến kiểm tra trạm hỏng |
| **System Admin (Quản trị hệ thống)** | Người quản lý toàn bộ hệ thống | Quản lý IT, có toàn quyền |
| **ReadOnly (Người xem)** | Chỉ xem báo cáo, không thao tác | Giám đốc, đối tác |

---

## 2. Tổng quan hệ thống

### 2.1 Kiến trúc tổng thể

Hệ thống của chúng ta có 4 phần chính, hoạt động cùng nhau:

```
┌──────────────────────────────────────────────────────────────┐
│                     NGƯỜI DÙNG                               │
│  (App điện thoại, Website, Dashboard quản lý, ...)           │
└────────────────────┬─────────────────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────────────────┐
│                     BACKEND (Xử lý logic)                    │
│  - Nhận yêu cầu từ Frontend                                  │
│  - Xử lý nghiệp vụ (bắt đầu sạc, tính tiền, ...)              │
│  - Giao tiếp với Database                                    │
│  - Gửi thông báo Realtime                                    │
└────────────────────┬─────────────────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────────────────┐
│                     DATABASE (SQL Server)                    │
│  - Lưu trữ toàn bộ dữ liệu                                   │
│  - Đảm bảo dữ liệu nhất quán, an toàn                        │
│  - Xử lý các truy vấn phức tạp                              │
│  - Tự động cập nhật analytics                                │
└────────────────────┬─────────────────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────────────────┐
│              REALTIME (Socket.IO / WebSocket)                │
│  - Gửi cập nhật tức thời đến người dùng                      │
│  - Thông báo trạng thái trạm, số dư ví, ...                  │
│  - Dashboard cập nhật số liệu live                           │
└──────────────────────────────────────────────────────────────┘
```

### 2.2 Các phần giải thích đơn giản

| Thành phần | Giải thích dễ hiểu | Ví dụ |
|---|---|---|
| **Frontend** | Phần người dùng nhìn thấy và tương tác | App điện thoại để tìm trạm sạc, website quản lý doanh thu |
| **Backend** | "Bộ não" xử lý logic — người dùng không thấy | Khi bạn nhấn "Bắt đầu sạc", Backend kiểm tra trạm còn rảnh không, tính giá, lưu dữ liệu |
| **Database** | "Kho lưu trữ" chứa toàn bộ thông tin | Tên bạn, trạm sạc ở đâu, bạn đã sạc bao nhiêu lần, tốn bao nhiêu tiền |
| **Realtime System** | Hệ thống gửi cập nhật tức thời | Khi bạn sạc xong, số dư ví trong app tự động giảm mà không cần refresh trang |
| **Analytics System** | Hệ thống phân tích dữ liệu để ra báo cáo | Biểu đồ doanh thu theo tháng, trạm nào đông nhất, giờ nào cao điểm |

### 2.3 Dữ liệu đi từ đâu đến đâu?

**Ví dụ: Một người dùng bắt đầu sạc**

```
Bước 1: Người dùng mở app → chọn trạm → nhấn "Bắt đầu sạc"
            │
            ▼
Bước 2: Frontend gửi yêu cầu đến Backend
            │
            ▼
Bước 3: Backend kiểm tra:
        - Tài khoản còn hoạt động không?
        - Điểm sạc còn trống không?
        - Giá điện hiện tại là bao nhiêu?
            │
            ▼
Bước 4: Backend ghi vào Database:
        - Tạo phiên sạc mới
        - Đánh dấu điểm sạc là "đang bận"
        - Ghi lại lịch sử
            │
            ▼
Bước 5: Backend gửi phản hồi về Frontend:
        "Bắt đầu sạc thành công!"
            │
            ▼
Bước 6: Realtime gửi cập nhật cho mọi người:
        - Chủ trạm thấy: "Điểm sạc số 3 đang bận"
        - Dashboard cập nhật số liệu
```

---

## 3. Kiến thức Database Cơ Bản

> **Phần này dành cho bạn chưa từng học database. Đừng lo — chúng ta sẽ đi từ những thứ căn bản nhất.**

### 3.1 Database là gì?

**Database** (Cơ sở dữ liệu) giống như một **tủ hồ sơ khổng lồ** được sắp xếp cực kỳ ngăn nắp.

Hãy tưởng tượng bạn có một tủ hồ sơ giấy:
- **Tủ hồ sơ** = Database (cơ sở dữ liệu)
- **Ngăn kéo** = Schema (khu vực chứa)
- **Bìa hồ sơ** = Table (bảng)
- **Tờ giấy trong bìa** = Row (dòng/bản ghi)
- **Ô thông tin trên tờ giấy** = Column (cột/trường dữ liệu)

### 3.2 Table (Bảng) là gì?

**Table** (Bảng) là nơi chứa một loại thông tin cụ thể.

Ví dụ thực tế trong hệ thống của chúng ta:

| Tên bảng | Chứa thông tin gì? | Ví dụ dữ liệu |
|---|---|---|
| `User` | Tài khoản người dùng | Tên đăng nhập, email, số điện thoại |
| `ChargingStation` | Trạm sạc | Địa chỉ, tên trạm, công suất |
| `ChargingSession` | Phiên sạc | Ai sạc, sạc lúc nào, bao nhiêu kWh |
| `Transaction` | Giao dịch thanh toán | Số tiền, ngày thanh toán, trạng thái |

### 3.3 Row (Dòng/Bản ghi) là gì?

**Row** là một **bản ghi cụ thể** trong bảng.

Ví dụ bảng `User` có thể có:

| UserID | Username | Email | Phone |
|---|---|---|---|
| 1 | nguyenvanA | nguyenvana@email.com | 0908123456 |
| 2 | tranvanB | tranvanb@email.com | 0908987654 |

Mỗi dòng là một người dùng cụ thể. Dòng 1 là thông tin của bạn Nguyễn Văn A.

### 3.4 Column (Cột/Trường) là gì?

**Column** là một **loại thông tin** cụ thể.

Trong bảng `User`:
- `Username` = Tên đăng nhập (kiểu chữ)
- `Email` = Địa chỉ email (kiểu chữ)
- `Phone` = Số điện thoại (kiểu chữ)
- `CreatedAt` = Ngày tạo tài khoản (kiểu ngày tháng)

Mỗi cột có một **kiểu dữ liệu**:
- `NVARCHAR` = Chữ (có dấu tiếng Việt)
- `INT` = Số nguyên
- `DECIMAL` = Số thập phân (tiền tệ)
- `DATETIME2` = Ngày tháng năm
- `BIT` = Đúng/Sai (0 hoặc 1)

### 3.5 Primary Key (Khóa chính) là gì?

**Primary Key** là một cột (hoặc nhiều cột) **định danh duy nhất** mỗi dòng trong bảng.

Giống như **số CMND/CCCD** của mỗi người — không ai giống ai.

```text
Bảng User:
┌─────────┬──────────────┬─────────────────┐
│ UserID  │  Username    │  Email          │
│ (PK)    │              │                 │
├─────────┼──────────────┼─────────────────┤
│    1    │  nguyenvanA  │  a@email.com    │  ← UserID = 1 là duy nhất
│    2    │  tranvanB    │  b@email.com    │  ← UserID = 2 là duy nhất
│  ...    │  ...         │  ...            │
└─────────┴──────────────┴─────────────────┘
```

Trong hệ thống, `UserID` là khóa chính của bảng `User`. Mỗi người dùng có một `UserID` khác nhau.

### 3.6 Foreign Key (Khóa ngoại) là gì?

**Foreign Key** là một cột trong bảng này **tham chiếu** đến khóa chính của bảng khác.

Nó tạo ra "mối quan hệ" (relationship) giữa hai bảng.

```text
Bảng User (Bảng cha):          Bảng ChargingSession (Bảng con):
┌─────────┬──────────┐         ┌────────────┬─────────┬────────┐
│ UserID  │ Username │         │ SessionID  │ UserID  │ ...   │
│ (PK)    │          │         │ (PK)       │ (FK)    │        │
├─────────┼──────────┤         ├────────────┼─────────┼────────┤
│    1    │ A       │◄────────│    101     │    1   │ ...   │ ← A sạc
│    2    │ B       │◄────────│    102     │    2   │ ...   │ ← B sạc
└─────────┴──────────┘         │    103     │    1   │ ...   │ ← A sạc tiếp
                               └────────────┴─────────┴────────┘
```

**UserID** trong bảng `ChargingSession` là Foreign Key — nó cho biết "người dùng nào" đã thực hiện phiên sạc đó.

### 3.7 Relationship (Quan hệ) là gì?

**Relationship** là cách các bảng liên kết với nhau thông qua Foreign Key.

Có 3 kiểu quan hệ chính:

| Kiểu | Ý nghĩa | Ví dụ trong hệ thống |
|---|---|---|
| **One-to-One** (1-1) | Một bản ghi bảng A tương ứng một bản ghi bảng B | 1 User có 1 UserProfile |
| **One-to-Many** (1-N) | Một bản ghi bảng A tương ứng nhiều bản ghi bảng B | 1 User có nhiều ChargingSession |
| **Many-to-Many** (N-N) | Nhiều bản ghi bảng A tương ứng nhiều bản ghi bảng B | 1 Station có nhiều Supplier, 1 Supplier cung cấp cho nhiều Station |

### 3.8 Normalization (Chuẩn hóa) là gì?

**Normalization** là kỹ thuật thiết kế database để **tránh trùng lặp dữ liệu** và **đảm bảo tính nhất quán**.

**Ví dụ: Không chuẩn hóa (dữ liệu trùng lặp)**

| Tên KH | Địa chỉ | Tên trạm đã sạc | Địa chỉ trạm |
|---|---|---|---|
| Nguyễn Văn A | 12 Lê Lợi, Q1 | Trạm sạc Bến Thành | 1 Bến Thành, Q1 |
| Nguyễn Văn A | 12 Lê Lợi, Q1 | Trạm sạc Lê Lợi | 12 Lê Lợi, Q1 |

→ **Vấn đề:** Địa chỉ của Nguyễn Văn A bị lặp lại 2 lần. Nếu anh ta dọn nhà, phải sửa ở nhiều chỗ.

**Sau chuẩn hóa (dữ liệu tách riêng):**

| UserID | Tên KH | Địa chỉ |
|---|---|---|
| 1 | Nguyễn Văn A | 12 Lê Lợi, Q1 |

| SessionID | UserID | StationID |
|---|---|---|
| 101 | 1 | 1 |
| 102 | 1 | 2 |

| StationID | Tên trạm | Địa chỉ trạm |
|---|---|---|
| 1 | Trạm sạc Bến Thành | 1 Bến Thành, Q1 |
| 2 | Trạm sạc Lê Lợi | 12 Lê Lợi, Q1 |

→ **Lợi ích:** Mỗi thông tin chỉ lưu một lần. Khi cần, chúng ta "nối" (JOIN) các bảng lại.

---

## 4. Các Module Chính Của Hệ Thống

Hệ thống được chia thành các **module** (mô-đun) — mỗi module quản lý một mảng nghiệp vụ riêng.

### 4.1 Tổng quan các module

```
┌──────────────────────────────────────────────────────────────────────┐
│                       EV_CHARGING_SYSTEM                             │
├────────────┬──────────┬──────────┬──────────┬──────────┬─────────────┤
│   USERS   │  ACCESS  │INFRASTRUC│OPERATIONS│ PAYMENTS │ MONITORING  │
│  (Người   │  (Phân   │ -TURE    │(Vận hành)│(Thanh    │ (Giám sát)  │
│   dùng)   │  quyền)  │(Hạ tầng) │          │  toán)   │             │
├────────────┴──────────┴──────────┴──────────┴──────────┴─────────────┤
│                        CROSS-CUTTING                                │
│              AUDIT (Kiểm toán) | ANALYTICS (Phân tích)              │
│              REPORTING (Báo cáo)                                     │
└──────────────────────────────────────────────────────────────────────┘
```

### 4.2 Module Users — Người dùng

**Mục đích:** Quản lý tài khoản, thông tin cá nhân, phương tiện của người dùng.

**Ví dụ thực tế:**
- Bạn đăng ký tài khoản → thông tin lưu vào `User`
- Bạn thêm xe của bạn → thông tin lưu vào `Vehicle`
- Bạn đăng nhập → hệ thống kiểm tra `UserCredential`

**Các bảng liên quan:**

| Bảng | Lưu gì? |
|---|---|
| `User` | Thông tin cơ bản: tên đăng nhập, email, số điện thoại |
| `UserProfile` | Thông tin chi tiết: họ tên, ảnh đại diện, ngày sinh |
| `UserCredential` | Thông tin bảo mật: mật khẩu đã mã hóa, MFA |
| `UserSession` | Phiên đăng nhập: token, thời gian hết hạn |
| `UserLoginHistory` | Lịch sử đăng nhập (không thể xóa) |
| `Vehicle` | Xe của người dùng: biển số, hãng, model năm |
| `UserPaymentMethod` | Phương thức thanh toán lưu sẵn |

**Tại sao lại tách thành nhiều bảng?**

Để **an toàn** và **dễ mở rộng**:
- Thông tin cá nhân (`UserProfile`) tách riêng khỏi thông tin đăng nhập (`UserCredential`)
- Nếu có yêu cầu xóa dữ liệu cá nhân (GDPR), chỉ cần xóa `UserProfile` mà không ảnh hưởng đến lịch sử giao dịch
- Mật khẩu được lưu riêng, mã hóa an toàn

### 4.3 Module Access — Phân quyền

**Mục đích:** Kiểm soát **ai được làm gì** trong hệ thống.

**Ví dụ thực tế:**
- Customer chỉ được bắt đầu sạc, không được sửa giá
- FranchiseOwner chỉ xem được trạm của mình, không xem được của đối thủ
- Admin có toàn quyền

**Cách hoạt động:**

```
User ──── có ────> Role ──── có nhiều ────> Permission
                                                   │
                                                   ▼
                                        "được phép làm gì"
                                        (VD: SESSION_START,
                                         PAYMENT_REFUND, ...)
```

### 4.4 Module Infrastructure — Hạ tầng

**Mục đích:** Quản lý các tài sản vật lý: trạm sạc, điểm sạc, địa chỉ, nhà cung cấp điện.

**Ví dụ thực tế:**
- Công ty lắp đặt một trạm sạc mới ở Quận 1 → thông tin vào `ChargingStation`
- Trạm đó có 4 điểm sạc → thông tin vào `ChargingPoint`
- Trạm ký hợp đồng với Điện Lực TP.HCM → thông tin vào `StationElectricityContract`

**Module này quản lý:**

```
Country (Quốc gia)
    └── Region (Tỉnh/Thành phố)
            └── Address (Địa chỉ cụ thể)
                    ├── Franchise (Doanh nghiệp nhượng quyền)
                    └── ChargingStation (Trạm sạc)
                            └── ChargingPoint (Điểm sạc)
```

### 4.5 Module Operations — Vận hành

**Mục đích:** Quản lý phần **cốt lõi** — phiên sạc, định giá, bảo trì.

**Đây là module quan trọng nhất của hệ thống.**

**Các bảng liên quan:**

| Bảng | Lưu gì? |
|---|---|
| `ChargingSession` | Phiên sạc: ai sạc, sạc ở đâu, bao nhiêu điện, bao nhiêu tiền |
| `PricingPolicy` | Chính sách giá: giá cơ bản, phí đỗ xe, phí quá giờ |
| `PricingRule` | Quy tắc giá chi tiết: giảm giá giờ thấp điểm, tăng giá giờ cao điểm |
| `PeakHourDefinition` | Khung giờ cao điểm / thấp điểm |
| `MembershipTier` | Hạng thành viên: Đồng, Bạc, Vàng, Bạch Kim |
| `UserMembership` | Người dùng nào thuộc hạng nào |
| `MaintenanceSchedule` | Lịch bảo trì trạm sạc |

### 4.6 Module Payments — Thanh toán

**Mục đích:** Xử lý tiền bạc — thanh toán, ví điện tử, hóa đơn, hoàn tiền.

**Ví dụ thực tế:**
- Bạn sạc xong, hệ thống tự động trừ tiền từ ví
- Bạn muốn xem hóa đơn chi tiết
- Bạn yêu cầu hoàn tiền vì trạm sạc bị lỗi

**Cách tiền chảy trong hệ thống:**

```
ChargingSession kết thúc
        │
        ▼
Transaction được tạo (Pending)
        │
        ├── Nếu thanh toán bằng Ví (Wallet):
        │       Kiểm tra số dư → Trừ tiền → Ghi sổ cái
        │
        └── Nếu thanh toán qua Cổng (Gateway):
                Gọi API ngân hàng → Thành công/Thất bại
        │
        ▼
TransactionStatusHistory (ghi lại toàn bộ lịch sử)
```

### 4.7 Module Monitoring — Giám sát

**Mục đích:** Theo dõi tình trạng hoạt động của các trạm sạc theo thời gian thực.

**Ví dụ thực tế:**
- Trạm sạc gửi tín hiệu "tôi còn sống" mỗi 30 giây (`StationHeartbeat`)
- Cảm biến ghi lại điện áp, dòng điện, nhiệt độ mỗi 5-15 giây (`PointTelemetry`)
- Nếu nhiệt độ quá cao → hệ thống tự động tạo cảnh báo (`Alert`)

### 4.8 Module Audit — Kiểm toán

**Mục đích:** Ghi lại **mọi thay đổi** trong hệ thống, không thể xóa hay sửa.

**Ví dụ thực tế:**
- Admin sửa giá điện → `AuditLog` ghi lại: ai sửa, giá cũ, giá mới, lúc nào
- Một giao dịch bị khiếu nại → tra cứu `AuditLog` để điều tra

### 4.9 Module Analytics — Phân tích

**Mục đích:** Tổng hợp dữ liệu thành các chỉ số KPI để báo cáo, phân tích.

**Ví dụ thực tế:**
- Dashboard hiển thị: "Hôm nay có 150 phiên sạc, doanh thu 45 triệu"
- Biểu đồ: "Giờ cao điểm là 17h-19h"
- Báo cáo: "Trạm Bến Thành có doanh thu cao nhất tháng"

### 4.10 Module Reporting — Báo cáo

**Mục đích:** Cung cấp các **view** (góc nhìn) dữ liệu cho báo cáo và business intelligence.

Không lưu dữ liệu riêng, chỉ "nhìn" vào dữ liệu từ các module khác và trình bày dưới dạng dễ đọc.

---

## 5. Giải Thích Từng Bảng

### 5.1 Bảng User (Người dùng)

| Câu hỏi | Trả lời |
|---|---|
| **Dùng để lưu gì?** | Thông tin cơ bản của mỗi người dùng hệ thống |
| **Tại sao cần?** | Không có bảng này thì không biết ai đang sử dụng hệ thống |
| **Khóa chính** | `UserID` — mỗi người dùng có một số định danh duy nhất |

**Các cột quan trọng:**

| Cột | Giải thích dễ hiểu |
|---|---|
| `Username` | Tên đăng nhập, ví dụ: `nguyenvanA` |
| `Email` | Địa chỉ email, dùng để đăng nhập hoặc khôi phục mật khẩu |
| `Phone` | Số điện thoại |
| `AccountStatus` | Tình trạng tài khoản: `Active` (đang hoạt động), `Locked` (bị khóa), `Closed` (đã đóng) |
| `FailedLoginAttempts` | Số lần đăng nhập sai — nếu quá 5 lần thì tài khoản bị khóa |
| `LockoutEnd` | Thời gian kết thúc khóa tài khoản |

**Bảng này liên kết với:**
- `UserProfile` — 1-1 (mỗi user có một profile)
- `UserCredential` — 1-1 (mỗi user có một thông tin đăng nhập)
- `ChargingSession` — 1-N (một user có nhiều phiên sạc)
- `UserRole` — 1-N (một user có thể có nhiều vai trò)

**Vòng đời dữ liệu:**
```
Đăng ký → Active → (có thể bị khóa) → (có thể bị xóa mềm)
```

### 5.2 Bảng ChargingStation (Trạm sạc)

| Câu hỏi | Trả lời |
|---|---|
| **Dùng để lưu gì?** | Thông tin từng trạm sạc vật lý |
| **Tại sao cần?** | Để biết trạm nào ở đâu, thuộc franchise nào, công suất bao nhiêu |
| **Khóa chính** | `StationID` |
| **Khóa ngoại** | `FranchiseID` → Franchise, `AddressID` → Address, `StationModelID` → StationModel |

**Các cột quan trọng:**

| Cột | Giải thích dễ hiểu |
|---|---|
| `StationCode` | Mã trạm, VD: `ST001` — dễ nhớ hơn số ID |
| `StationName` | Tên trạm, VD: "Trạm sạc Bến Thành" |
| `Latitude`, `Longitude` | Tọa độ GPS — để hiển thị trên bản đồ |
| `MaxCapacityKW` | Tổng công suất tối đa của trạm |
| `NetworkStatus` | Trạng thái mạng: `Online`, `Offline`, `Degraded` |
| `HasGenerator`, `HasSolarPanels` | Có máy phát điện / pin mặt trời không? |
| `ParkingSpots` | Số chỗ đỗ xe |
| `OperatingHoursJson` | Giờ hoạt động (lưu dạng JSON để linh hoạt) |

**Business Rule quan trọng:**
- Mỗi trạm có **StationCode duy nhất** — không thể có 2 trạm cùng mã
- Khi xóa trạm, dùng **Soft Delete** (đánh dấu là đã xóa, không xóa thật)

### 5.3 Bảng ChargingPoint (Điểm sạc)

| Câu hỏi | Trả lời |
|---|---|
| **Dùng để lưu gì?** | Từng "cây sạc" riêng lẻ trong một trạm |
| **Tại sao cần?** | Một trạm có nhiều điểm sạc, cần quản lý từng điểm |
| **Khóa chính** | `PointID` |
| **Khóa ngoại** | `StationID` → ChargingStation |

**Ví dụ:** Trạm Bến Thành có 4 điểm sạc → 4 dòng trong bảng `ChargingPoint`

**Các cột quan trọng:**

| Cột | Giải thích |
|---|---|
| `PointCode` | Mã điểm sạc, VD: `ST001-P01` |
| `PointType` | Loại: `AC` (sạc chậm), `DC` (sạc nhanh) |
| `PointStatus` | Trạng thái: `Available` (rảnh), `Busy` (đang dùng), `Faulted` (hỏng), `Offline` |
| `PowerRatingKW` | Công suất định mức, VD: 50kW, 150kW |
| `SerialNumber` | Số serial của thiết bị |

**Vòng đời dữ liệu:**
```
Available → Busy (khi có người sạc) → Available (khi sạc xong)
     ↓                                  ↑
  Faulted (khi hỏng) ─── Sau sửa ─────┘
```

### 5.4 Bảng ChargingSession (Phiên sạc) — Bảng quan trọng nhất

| Câu hỏi | Trả lời |
|---|---|
| **Dùng để lưu gì?** | Mỗi lần một người dùng sạc xe |
| **Tại sao cần?** | Đây là trung tâm của toàn bộ hệ thống — mọi thứ xoay quanh phiên sạc |
| **Khóa chính** | `SessionID` |

**Đây là bảng được query nhiều nhất trong toàn hệ thống.**

**Các cột quan trọng (nhóm theo chức năng):**

| Nhóm | Cột | Giải thích |
|---|---|---|
| **Nhận dạng** | `SessionCode` | Mã phiên: `SES-20250407-001` (dễ đọc hơn số ID) |
| | `UserID` | Ai sạc |
| | `StationID` | Sạc ở trạm nào (lưu trực tiếp để tránh JOIN) |
| | `PointID` | Sạc ở điểm nào |
| | `VehicleID` | Xe nào được sạc |
| **Năng lượng** | `MeterStart`, `MeterEnd` | Chỉ số đồng hồ đầu/cuối |
| | `TotalKWh` | Tổng số điện đã sạc (MeterEnd - MeterStart) |
| | `StartBatteryPercent`, `EndBatteryPercent` | % pin đầu/cuối |
| **Thời gian** | `StartTime`, `EndTime` | Thời gian bắt đầu và kết thúc |
| | `ChargingDurationMinutes` | Thời gian sạc thực tế (phút) |
| | `AveragePowerKW`, `MaxPowerKW` | Công suất trung bình và cao nhất |
| **Tài chính** | `CostBeforeDiscount` | Tiền trước khi giảm giá |
| | `DiscountAmount` | Tiền được giảm |
| | `CostTotal` | Tiền phải trả (sau giảm giá) |
| **Vận hành** | `SessionStatus` | Trạng thái: `Charging`, `Completed`, `Cancelled`, `Error` |
| | `StopReason` | Lý do kết thúc: `Completed` (sạc đầy), `UserStopped` (người dùng dừng), `Error` (lỗi) |
| | `SessionSource` | Bắt đầu từ đâu: `MobileApp`, `RFID`, `WebPortal` |

**Tại sao bảng này có quá nhiều cột?**

Vì mỗi phiên sạc cần lưu đầy đủ thông tin để:
- Tính tiền chính xác
- Phân tích hành vi người dùng
- Báo cáo tài chính
- Kiểm toán khi có khiếu nại

### 5.5 Bảng Transaction (Giao dịch)

| Câu hỏi | Trả lời |
|---|---|
| **Dùng để lưu gì?** | Mỗi lần thanh toán |
| **Tại sao cần?** | Để quản lý dòng tiền, đối soát, kiểm toán |
| **Khóa chính** | `TransactionID` |
| **Khóa ngoại** | `SessionID` → ChargingSession (1-1), `GatewayID` → PaymentGateway |

**Các cột quan trọng:**

| Cột | Giải thích |
|---|---|
| `TransactionCode` | Mã giao dịch: `TXN-20250407-001` |
| `Amount` | Số tiền |
| `Direction` | `D` (Debit - thu), `C` (Credit - chi) |
| `TransactionStatus` | `Pending`, `Completed`, `Failed`, `Refunded` |
| `PaymentMethod` | Hình thức: `Wallet`, `CreditCard`, `VNPay`, `Momo` |

**Business Rule:** Mỗi phiên sạc chỉ có **duy nhất 1 giao dịch**.

### 5.6 Bảng PricingPolicy (Chính sách giá)

| Câu hỏi | Trả lời |
|---|---|
| **Dùng để lưu gì?** | Các chính sách giá khác nhau |
| **Tại sao cần?** | Giá sạc điện không cố định — thay đổi theo giờ, theo đối tượng |
| **Khóa chính** | `PolicyID` |

**Ví dụ các chính sách giá:**

| PolicyCode | PolicyType | Giá cơ bản | Phí đỗ xe | Phí quá giờ |
|---|---|---|---|---|
| `STD` | Standard | 3.500đ/kWh | 0đ/phút | 2.000đ/phút |
| `PEAK` | PeakHour | 5.250đ/kWh | 0đ/phút | 3.000đ/phút |
| `OFFPEAK` | OffPeak | 2.450đ/kWh | 0đ/phút | 1.000đ/phút |
| `GOLD` | Membership | 3.150đ/kWh | 0đ/phút | 0đ/phút |

### 5.7 Bảng AuditLog (Nhật ký kiểm toán)

| Câu hỏi | Trả lời |
|---|---|
| **Dùng để lưu gì?** | Mọi thay đổi trong hệ thống |
| **Tại sao cần?** | Để điều tra khi có sự cố, đảm bảo minh bạch |
| **Khóa chính** | `AuditID` |

**Các cột:**

| Cột | Giải thích |
|---|---|
| `TableName` | Bảng nào bị thay đổi (VD: `ChargingStation`) |
| `RecordID` | Bản ghi nào bị thay đổi (VD: `StationID = 5`) |
| `Action` | Hành động: `I` (thêm), `U` (sửa), `D` (xóa) |
| `OldValue` | Giá trị cũ (lưu dạng JSON) |
| `NewValue` | Giá trị mới (lưu dạng JSON) |
| `ChangedByUserID` | Ai đã thay đổi |
| `ChangedAt` | Thay đổi lúc nào |

**Đặc điểm quan trọng:** Dữ liệu trong bảng này **KHÔNG THỂ XÓA HOẶC SỬA** — nó là bất biến.

---

## 6. Giải Thích Relationships (Quan Hệ Giữa Các Bảng)

### 6.1 Tại sao cần relationships?

Không có relationships, dữ liệu sẽ hỗn loạn:
- Bạn có một phiên sạc nhưng không biết **của ai** (không có UserID)
- Bạn xóa một trạm sạc, nhưng các phiên sạc cũ vẫn tham chiếu đến trạm đã mất

Relationships đảm bảo **tính toàn vẹn dữ liệu**.

### 6.2 Sơ đồ quan hệ tổng thể

```
┌──────────────┐
│   Country    │
└──────┬───────┘
       │ 1:N
       ▼
┌──────────────┐
│   Region     │
└──────┬───────┘
       │ 1:N
       ▼
┌──────────────┐          ┌──────────────────┐
│   Address    │◄─────────│   Franchise      │
└──────┬───────┘  N:1     └──────────────────┘
       │ 1:N
       ▼
┌──────────────────┐       ┌──────────────────┐
│ ChargingStation  │───────│  StationModel    │
└──────┬───────────┘  N:1  └──────────────────┘
       │ 1:N
       ▼
┌──────────────────┐       ┌──────────────────────────────┐
│  ChargingPoint   │       │ StationElectricityContract   │
└──────┬───────────┘       └──────────────┬───────────────┘
       │ 1:N                              │ N:1
       ▼                                  ▼
┌──────────────────┐              ┌──────────────────┐
│ ChargingSession  │              │ElectricitySupplier│
└──────┬───────────┘              └──────────────────┘
       │ 1:1
       ▼
┌──────────────────┐
│   Transaction    │
└──────────────────┘
```

### 6.3 Các quan hệ One-to-One (1-1)

**Ví dụ: User và UserProfile**

```
User (1) ─────────── (1) UserProfile
- UserID = 1          - UserID = 1
- Username = "A"      - FullName = "Nguyễn Văn A"
                      - Avatar = "avatar.jpg"
```

**Giải thích:** Mỗi User có **duy nhất một** UserProfile. Mỗi UserProfile thuộc về **duy nhất một** User.

**Tại sao không gộp chung?** Vì thông tin cá nhân (tên thật, ảnh) dễ thay đổi và cần bảo vệ riêng.

### 6.4 Các quan hệ One-to-Many (1-N)

**Ví dụ: Franchise và ChargingStation**

```
Franchise (1) ─────────── (N) ChargingStation
- FranchiseID = 1          - StationID = 1, FranchiseID = 1
  Tên: "ABC Energy"        - StationID = 2, FranchiseID = 1
                            - StationID = 3, FranchiseID = 1
```

**Giải thích:** Một Franchise có **nhiều** ChargingStation. Mỗi ChargingStation thuộc về **một** Franchise.

**Ví dụ khác:**

| Quan hệ | Giải thích |
|---|---|
| `User` → `ChargingSession` | Một người dùng có thể sạc nhiều lần |
| `ChargingStation` → `ChargingPoint` | Một trạm có nhiều điểm sạc |
| `Station` → `MaintenanceSchedule` | Một trạm có nhiều lịch bảo trì |

### 6.5 Các quan hệ Many-to-Many (N-N)

**Ví dụ: Station và ElectricitySupplier**

```
Station (N) ────── (N) Supplier
                          │
                    (Bảng trung gian)
                    StationElectricityContract
```

**Giải thích:**
- Một trạm có thể ký hợp đồng với **nhiều nhà cung cấp điện** (đổi nhà cung cấp)
- Một nhà cung cấp có thể phục vụ **nhiều trạm**

**Bảng trung gian** `StationElectricityContract` chứa:
- `StationID` + `SupplierID` (khóa chính ghép)
- `ContractNumber`, `UnitPricePerKWh`, `ContractFrom`, `ContractTo`
- `IsActive` — hợp đồng nào đang có hiệu lực

**Tại sao cần bảng trung gian?** Vì không thể đặt Foreign Key trực tiếp — một bảng chỉ có một cột, không thể chứa nhiều nhà cung cấp.

### 6.6 Foreign Key bảo vệ dữ liệu như thế nào?

Foreign Key giống như "dây xích" giữa các bảng.

**Ví dụ:** Khi có Foreign Key từ `ChargingSession.UserID` → `User.UserID`:

| Tình huống | Foreign Key làm gì? |
|---|---|
| Bạn thêm phiên sạc với `UserID = 999` (không tồn tại) | **Chặn lại** — không có user nào mang ID 999 |
| Bạn xóa User có `UserID = 1` (đang có phiên sạc) | **Chặn lại** — không thể xóa user đang có dữ liệu |
| Bạn sửa `UserID` từ 1 thành 2 | **Chặn lại** — khóa chính không được sửa nếu có tham chiếu |

Đây là lý do hệ thống không dùng `ON DELETE CASCADE` (tự động xóa theo) — vì rất nguy hiểm.

### 6.7 Chuyện gì xảy ra nếu xóa dữ liệu?

| Hành động | Hệ thống phản ứng thế nào |
|---|---|
| Xóa ChargingStation đang có Point | **Bị chặn** bởi Foreign Key |
| Xóa User đang có Session | **Bị chặn** bởi Foreign Key |
| "Xóa" User | Dùng **Soft Delete**: đánh dấu `IsDeleted = 1`, không xóa thật |
| Buộc phải xóa? | Xóa từ "lá" vào "gốc": xóa Session → xóa Point → xóa Station |

---

## 7. Luồng Dữ Liệu Thực Tế

### 7.1 Flow 1: Người dùng đặt lịch sạc (Booking)

> **Kịch bản:** Chị Mai mở app, tìm trạm gần nhà, chọn giờ, đặt trước.

```
Bước 1: Chị Mai mở app → Xem danh sách trạm
        - Frontend gọi API: GET /stations?lat=...&lng=...
        - Backend query bảng ChargingStation (vị trí, trạng thái)
        - Trả về danh sách trạm kèm điểm sạc còn trống

Bước 2: Chị Mai chọn trạm → Chọn giờ → Nhấn "Đặt lịch"
        - Frontend gọi API: POST /bookings
        - Backend kiểm tra:
            □ Tài khoản còn hoạt động không?
            □ Điểm sạc còn trống vào giờ đó không?
        - Backend INSERT vào bảng Booking:
            UserID = 5, PointID = 12, ScheduledTime = "2026-05-11 14:00"
        - Backend trả về: "Đặt lịch thành công!"
        - Realtime gửi thông báo đến chủ trạm: "Có lịch đặt mới"

Bước 3: Đến giờ hẹn, Chị Mai đến trạm
        - Quét mã QR hoặc nhập mã đặt lịch
        - Backend kiểm tra Booking, chuyển trạng thái thành "Đang sử dụng"
```

**Bảng nào thay đổi?**
- `Booking`: INSERT dòng mới
- `ChargingPoint`: (sau khi bắt đầu) UPDATE PointStatus = 'Busy'

**Realtime event nào?**
- `booking.created` → gửi đến chủ franchise
- `point.status_changed` → gửi đến mọi người đang xem trạm đó

### 7.2 Flow 2: Bắt đầu phiên sạc (Charging)

> **Kịch bản:** Anh Tèo đến trạm, cắm sạc, bắt đầu sạc.

```
Bước 1: Anh Tèo chọn điểm sạc → Nhấn "Bắt đầu sạc"
        - Frontend gọi API: POST /sessions/start
        - Backend gọi stored procedure: sp_StartChargingSession
            {
              @UserID = 10,
              @PointID = 15,
              @VehicleID = 3,
              @Source = 'MobileApp'
            }

Bước 2: sp_StartChargingSession kiểm tra:
        □ UserID 10 có Active không? (User.AccountStatus)
        □ PointID 15 có Available không? (ChargingPoint.PointStatus)
        □ Chọn PricingPolicy phù hợp (tự động theo giờ, ngày)

Bước 3: BEGIN TRANSACTION
        - INSERT ChargingSession (StartTime = now, Status = 'Charging')
        - UPDATE ChargingPoint SET PointStatus = 'Busy'
        - INSERT SessionStatusHistory (trạng thái: 'Started')
        COMMIT

Bước 4: Backend trả về SessionCode cho app
        - App hiển thị: "Đang sạc... 15.2kW | 30% pin"
```

**Bảng nào thay đổi?**
- `ChargingSession`: INSERT — tạo phiên sạc mới
- `ChargingPoint`: UPDATE — đánh dấu đang bận
- `SessionStatusHistory`: INSERT — ghi lại lịch sử

**Realtime event nào?**
- `session.started` → gửi cho chủ trạm
- `point.busy` → gửi cho những ai đang xem điểm sạc đó
- `dashboard.update` → dashboard tự động cập nhật số liệu

### 7.3 Flow 3: Kết thúc phiên sạc và tính tiền

> **Kịch bản:** Xe của Anh Tèo đã sạc đầy, hệ thống tự động kết thúc.

```
Bước 1: Hệ thống (hoặc người dùng) gọi kết thúc sạc
        - Backend gọi sp_EndChargingSession
            {
              @SessionID = 101,
              @MeterEnd = 45.5,
              @EndBatteryPercent = 100,
              @StopReason = 'Completed'
            }

Bước 2: sp_EndChargingSession tính toán:
        - TotalKWh = MeterEnd - MeterStart
        - ChargingDurationMinutes = EndTime - StartTime
        - AveragePowerKW = TotalKWh / (DurationMinutes / 60)
        - CostTotal = fn_CalculateChargingCost(
            TotalKWh, BasePrice, Discount, StartTime
          )

Bước 3: BEGIN TRANSACTION
        - UPDATE ChargingSession (đầy đủ thông tin, Status = 'Completed')
        - UPDATE ChargingPoint SET PointStatus = 'Available'
        - INSERT SessionStatusHistory (trạng thái: 'Completed')
        COMMIT

Bước 4: Tự động gọi sp_CreatePayment
        - Tạo Transaction (Amount = CostTotal)
        - Nếu đủ tiền trong Wallet: trừ tiền
        - Nếu không: chuyển sang phương thức khác
```

**Bảng nào thay đổi?**
- `ChargingSession`: UPDATE 17+ cột
- `ChargingPoint`: UPDATE — trả về trạng thái rảnh
- `Transaction`: INSERT
- `Wallet`: UPDATE (trừ tiền)
- `WalletTransaction`: INSERT (ghi sổ)
- `SessionStatusHistory`: INSERT

**Realtime event nào?**
- `session.completed` → gửi cho người dùng (kèm hóa đơn)
- `point.available` → gửi cho những ai đang chờ
- `wallet.balance_changed` → app tự cập nhật số dư
- `dashboard.update` → KPI được cập nhật

### 7.4 Flow 4: Dashboard analytics update

> **Kịch bản:** Sau mỗi phiên sạc, dashboard cập nhật số liệu.

```
Bước 1: Khi ChargingSession được INSERT/UPDATE,
        trigger trg_ChargingSession_StatusChange tự động chạy

Bước 2: Trigger ghi vào SessionStatusHistory

Bước 3: Cuối ngày, SQL Agent Job chạy sp_DailyKPIAggregation
        - Tổng hợp dữ liệu từ ChargingSession
        - UPSERT vào DailyStationKPI:
            TotalSessions += 1
            TotalKWh += 45.5
            TotalRevenue += 159,250đ
        - UPSERT vào DailyFranchiseKPI:
            CommissionAmount = TotalRevenue × ShareRate

Bước 4: Dashboard đọc từ:
        - DailyStationKPI: "Hôm nay trạm có 12 phiên sạc"
        - ivw_MonthlyRevenueSummary: "Tháng này doanh thu 450 triệu"
        - vw_PeakHourAnalysis: "Giờ cao điểm: 17h-19h"
```

### 7.5 Flow 5: Xử lý hoàn tiền (Refund)

> **Kịch bản:** Trạm sạc bị lỗi giữa chừng, Anh Tèo yêu cầu hoàn tiền.

```
Bước 1: Anh Tèo gửi yêu cầu hoàn tiền
        - Frontend gọi API: POST /refunds
        - Backend gọi sp_ProcessRefund(@OriginalTransactionID, @Amount)

Bước 2: sp_ProcessRefund kiểm tra:
        □ Giao dịch gốc có tồn tại? Completed?
        □ Số tiền hoàn có vượt quá số tiền gốc không?
        □ Đã hoàn bao nhiêu lần rồi? (tránh hoàn quá nhiều)

Bước 3: BEGIN TRANSACTION
        - INSERT RefundTransaction
        - UPDATE Transaction SET Status = 'PartiallyRefunded'
        - Nếu hoàn vào Wallet: UPDATE Wallet.Balance += Amount
        COMMIT
```

---

## 8. Giải Thích Realtime System

### 8.1 Realtime là gì?

**Realtime** (thời gian thực) nghĩa là **ngay lập tức** — không có độ trễ.

**Ví dụ:**
- Bạn nhắn tin Facebook → bạn bè thấy **ngay** (không cần refresh)
- Bạn sạc xe → số dư ví trong app giảm **ngay** (không cần refresh)
- Dashboard doanh thu tăng lên **ngay** khi có phiên sạc mới

### 8.2 Tại sao cần realtime?

Nếu không có realtime:

| Tình huống | Không realtime | Có realtime |
|---|---|---|
| Xem trạm còn trống | Phải refresh trang mỗi lần | Tự động cập nhật khi có thay đổi |
| Kiểm tra số dư ví | Phải thoát ra vào lại | Tự động giảm khi thanh toán |
| Nhận thông báo | Phải kiểm tra thủ công | Popup xuất hiện ngay lập tức |
| Dashboard | Số liệu cũ | Số liệu live |

### 8.3 Socket.IO là gì?

**Socket.IO** là một thư viện giúp tạo kết nối **hai chiều, thời gian thực** giữa Frontend và Backend.

**Cách hoạt động:**

```
KHÔNG có Socket.IO (cách cũ):
Frontend: "Máy chủ ơi, trạm số 5 còn trống không?"
Backend:  "Còn trống."
  (5 giây sau)
Frontend: "Máy chủ ơi, trạm số 5 còn trống không?"
Backend:  "Còn trống."  ← Cùng câu hỏi, cùng câu trả lời → tốn tài nguyên
  (5 giây sau)
Frontend: "Máy chủ ơi, trạm số 5 còn trống không?"
Backend:  "Hết trống rồi." ← Mất 10 giây mới biết!

CÓ Socket.IO (cách mới):
Frontend: "Máy chủ ơi, cho tôi vào phòng 'station:5'"
Backend:  "OK, khi có thay đổi tôi sẽ báo bạn."

... (người khác bắt đầu sạc ở trạm 5)
Backend:  "Chú ý! Trạm 5 vừa hết trống!"
Frontend: "Cảm ơn, tôi cập nhật ngay." ← Tức thời!
```

### 8.4 WebSocket Room hoạt động ra sao?

**Room** (phòng) là kênh giao tiếp riêng cho từng nhóm người dùng.

Ví dụ các "phòng" trong hệ thống:

| Room | Ai ở trong? | Nhận thông báo gì? |
|---|---|---|
| `station:{StationID}` | Người đang xem trạm đó | Trạng thái point thay đổi |
| `franchise:{FranchiseID}` | Chủ franchise đó | Doanh thu mới, bảo trì, cảnh báo |
| `user:{UserID}` | Chính người dùng đó | Số dư ví, thông báo cá nhân |
| `dashboard:admin` | Admin | Số liệu tổng quan |

**Ví dụ: Khi một point thay đổi trạng thái**

```
1. PointID 15 vừa chuyển từ Available → Busy
2. Backend phát hiện (qua trigger hoặc SP)
3. Backend emit event: io.to('station:5').emit('point.status_changed', {
     pointId: 15,
     newStatus: 'Busy'
   })
4. Tất cả người dùng trong room 'station:5'
   (đang xem trạm 5) nhận được thông báo
5. App tự động cập nhật giao diện:
   "Điểm sạc 15: 🟡 Đang bận"
```

### 8.5 Bảng nào liên quan đến realtime?

| Bảng | Khi thay đổi → | Gửi realtime event |
|---|---|---|
| `ChargingPoint` | PointStatus đổi | `point.status_changed` |
| `ChargingSession` | Session mới / kết thúc | `session.started`, `session.completed` |
| `Wallet` | Số dư thay đổi | `wallet.balance_changed` |
| `Alert` | Cảnh báo mới | `alert.new` |
| `Notification` | Thông báo mới | `notification.new` |

---

## 9. Giải Thích Analytics & Dashboard

### 9.1 Dashboard là gì?

**Dashboard** là bảng điều khiển hiển thị các **chỉ số quan trọng** (KPI) dưới dạng biểu đồ, số liệu, bảng biểu.

**Ví dụ dashboard của chủ franchise:**

```
┌─────────────────────────────────────────────────────┐
│  DASHBOARD - Trạm sạc Bến Thành                     │
├──────────────────────┬──────────────────────────────┤
│  📊 Hôm nay          │  📈 Doanh thu tháng này       │
│  Phiên sạc: 12      │  45.000.000₫                 │
│  kWh: 450.5        │  Tăng 15% so với tháng trước │
│  Doanh thu: 1.5M₫  │                              │
├──────────────────────┼──────────────────────────────┤
│  🔴 Trạm đang hoạt động │  ⚡ Giờ cao điểm            │
│  4/6 Online           │  17h-19h (30% doanh thu)   │
│  2/6 Đang sạc         │                            │
└──────────────────────┴──────────────────────────────┘
```

### 9.2 Dashboard lấy dữ liệu từ đâu?

Dashboard không đọc trực tiếp từ bảng gốc (như `ChargingSession`) vì:
- Bảng gốc có **hàng triệu dòng** — query sẽ rất chậm
- Cần tính toán tổng hợp (SUM, COUNT, AVG) — tốn thời gian

Thay vào đó, dashboard đọc từ:

```
Bảng gốc                          Bảng Analytics
(ChargingSession)                 (DailyStationKPI)
                                    
100 triệu dòng        ETL ────→   365 dòng (mỗi ngày 1 dòng)
(Từng phiên sạc)      (Chạy       (Tổng hợp theo ngày)
                      cuối ngày)   

Query: 4 phút                     Query: 0.01 giây
```

### 9.3 Stored Procedure là gì?

**Stored Procedure** (SP) là một "chương trình con" chạy trong database.

Giống như **công thức nấu ăn**:
- Bạn đưa nguyên liệu (tham số)
- Database làm theo các bước đã định sẵn
- Trả ra kết quả

**Ví dụ:** `sp_StartChargingSession` giống như công thức:

```
sp_StartChargingSession(@UserID, @PointID, @VehicleID):
  1. Kiểm tra user còn active không
  2. Kiểm tra point còn available không
  3. Chọn pricing policy phù hợp
  4. Tạo phiên sạc mới
  5. Đánh dấu point là busy
  6. Ghi lịch sử
  7. Trả về SessionCode
```

**Lợi ích:**
- **An toàn:** Ngăn SQL injection (tấn công database)
- **Nhanh:** Đã được biên dịch sẵn
- **Nhất quán:** Mọi nơi đều gọi cùng một SP

### 9.4 Indexed View (Materialized View) là gì?

**View** (khung nhìn) giống như một "cửa sổ" nhìn vào dữ liệu.

**View thường:** Mỗi lần bạn nhìn, database phải tính toán lại.
**Indexed View:** Kết quả được **lưu sẵn** như một bảng thật.

**Ví dụ:** `ivw_MonthlyRevenueSummary`

```
View này hiển thị:
Tháng 1/2026, Trạm 1: 150 phiên, 5,000 kWh, 17.5 triệu
Tháng 1/2026, Trạm 2: 200 phiên, 7,500 kWh, 26.25 triệu
...

Khi có phiên sạc mới → View tự động cập nhật
Khi dashboard hỏi → Trả về ngay lập tức (không tính toán lại)
```

### 9.5 Analytics Pipeline

```
┌──────────────────┐     ┌──────────────────┐     ┌──────────────────┐
│   Bảng gốc       │     │   ETL Process    │     │   Bảng KPI      │
│  (OLTP)          │────→│  (sp_DailyKPI    │────→│  (Analytics)    │
│                  │     │   Aggregation)   │     │                  │
│ ChargingSession  │     │  Chạy cuối ngày │     │ DailyStationKPI │
│ Transaction      │     │  MERGE upsert   │     │ DailyFranchiseKPI│
│ PointTelemetry   │     │  Tổng hợp số    │     │ HourlySessionAgg│
└──────────────────┘     └──────────────────┘     └──────────────────┘
                                                            │
                                                            ▼
                                                   ┌──────────────────┐
                                                   │   Dashboard     │
                                                   │   & Báo cáo    │
                                                   │   (Đọc nhanh)  │
                                                   └──────────────────┘
```

### 9.6 Các business metrics quan trọng

| Chỉ số | Giải thích | Công thức |
|---|---|---|
| **Doanh thu (Revenue)** | Tổng tiền từ các phiên sạc | `SUM(CostTotal)` |
| **Giờ cao điểm (Peak Hour)** | Giờ nào có nhiều phiên sạc nhất | `COUNT(SessionID) GROUP BY Hour` |
| **Tỷ lệ sử dụng trạm (Utilization)** | Trạm được dùng bao nhiêu % thời gian | `(Thời gian có xe sạc / Tổng thời gian) × 100` |
| **Hiệu suất Franchise** | Franchise nào hoạt động tốt nhất | Doanh thu, số phiên, số trạm active |
| **Chi phí điện năng** | Tiền điện phải trả vs tiền thu được | `TotalRevenue - (KWh × Giá điện)` |
| **Thời gian hoạt động (Uptime)** | Trạm online được bao nhiêu % | `(Thời gian online / Tổng thời gian) × 100` |

### 9.7 Bảng analytics tổng hợp

**DailyStationKPI — KPI hàng ngày theo từng trạm:**

| Cột | Giải thích |
|---|---|
| `StationID` | Trạm nào |
| `RecordDate` | Ngày nào |
| `TotalSessions` | Tổng số phiên sạc trong ngày |
| `TotalKWh` | Tổng số điện đã sạc |
| `TotalRevenue` | Tổng doanh thu |
| `AvgPowerKW` | Công suất trung bình |
| `AvgChargingMinutes` | Thời gian sạc trung bình (phút) |
| `PeakConcurrentSessions` | Số phiên đồng thời cao nhất |
| `UniqueUsers` | Số người dùng khác nhau |
| `UptimePercent` | % thời gian trạm hoạt động |

---

## 10. Enterprise Features (Tính Năng Doanh Nghiệp)

### 10.1 Audit Log (Nhật ký kiểm toán)

**Là gì?** Ghi lại **mọi thay đổi** trong hệ thống — ai, làm gì, lúc nào, giá trị cũ, giá trị mới.

**Tại sao cần?**
- **Khiếu nại:** Khách nói "Tôi bị trừ tiền oan" → tra audit để kiểm tra
- **Điều tra:** Ai đã sửa giá điện lúc nửa đêm?
- **Tuân thủ pháp luật:** Cơ quan thuế yêu cầu cung cấp lịch sử giao dịch

**Nếu không có audit log:**
- Khi có sai sót, không biết ai đã gây ra
- Không thể chứng minh hệ thống hoạt động đúng
- Rủi ro pháp lý cao

### 10.2 Soft Delete (Xóa mềm)

**Là gì?** Khi "xóa" dữ liệu, hệ thống không xóa thật mà chỉ **đánh dấu** là đã xóa.

```sql
-- Không phải:
DELETE FROM User WHERE UserID = 5;

-- Mà là:
UPDATE User SET IsDeleted = 1, DeletedAt = SYSDATETIME() WHERE UserID = 5;
```

**Tại sao cần?**
- **Phục hồi:** Xóa nhầm? Chỉ cần sửa `IsDeleted = 0`
- **Toàn vẹn:** Các bảng liên quan (Session, Transaction) vẫn hoạt động
- **Lịch sử:** Báo cáo doanh thu vẫn tính cả dữ liệu cũ

**Nếu không có soft delete:**
- Xóa user → mất toàn bộ lịch sử sạc của user đó
- Báo cáo doanh thu sẽ sai (thiếu dữ liệu cũ)
- Foreign Key sẽ chặn xóa (không xóa được)

### 10.3 Transactions (Giao dịch)

**Là gì?** Một nhóm thao tác database **hoặc làm tất cả, hoặc không làm gì cả**.

**Ví dụ:** Khi bắt đầu sạc, cần:
1. Tạo phiên sạc mới (INSERT)
2. Cập nhật điểm sạc (UPDATE)
3. Ghi lịch sử (INSERT)

Nếu bước 2 thất bại, bước 1 không được giữ lại → **ROLLBACK**.

```text
BEGIN TRANSACTION
    INSERT ChargingSession ...    ──┐
    UPDATE ChargingPoint ...      ──┤── Nếu 1 cái lỗi → Tất cả đều hủy
    INSERT StatusHistory ...      ──┘
COMMIT
```

**Nếu không có transaction:**
- Bước 1 thành công, bước 2 thất bại → có phiên sạc "ma" (không point nào bận)
- Dữ liệu không nhất quán

### 10.4 Rollback (Khôi phục)

**Là gì?** Khi có lỗi, database tự động "quay lại" trạng thái trước khi thay đổi.

Hệ thống sử dụng `SET XACT_ABORT ON` — tự động rollback khi có bất kỳ lỗi nào.

### 10.5 RBAC (Role-Based Access Control)

**Là gì?** Phân quyền dựa trên **vai trò** — không phân quyền cho từng người riêng lẻ.

**Cách hoạt động:**
```
Người dùng → Có vai trò → Vai trò có quyền → Quyền cho phép hành động

Ví dụ:
Anh Tèo → FranchiseOwner → SESSION_READ, PAYMENT_READ, ... → Chỉ xem được trạm của mình
```

**Bảng liên quan:**
- `Role`: Danh sách vai trò (SysAdmin, Operator, Customer, ...)
- `Permission`: Danh sách quyền (SESSION_START, PAYMENT_REFUND, ...)
- `RolePermission`: Vai trò nào có quyền nào
- `UserRole`: Người dùng nào có vai trò nào

### 10.6 Row-Level Security (RLS)

**Là gì?** Tự động **lọc dữ liệu** dựa trên người dùng — ngay cả khi họ chạy cùng một câu query.

**Ví dụ:**
- Chủ franchise A chạy: `SELECT * FROM ChargingStation` → Chỉ thấy trạm của mình
- Chủ franchise B chạy: `SELECT * FROM ChargingStation` → Chỉ thấy trạm của mình
- Admin chạy: `SELECT * FROM ChargingStation` → Thấy tất cả

**Nếu không có RLS:**
- Chủ franchise A có thể xem doanh thu của franchise B
- Rủi ro lộ thông tin kinh doanh

### 10.7 Monitoring (Giám sát)

**Là gì?** Hệ thống tự động theo dõi tình trạng hoạt động.

**Hệ thống giám sát:**
- **Heartbeat:** Mỗi 30 giây, trạm sạc gửi tín hiệu "tôi còn sống"
- **Telemetry:** Mỗi 5-15 giây, cảm biến ghi lại điện áp, dòng điện, nhiệt độ
- **Alert:** Nếu nhiệt độ > 60°C → tự động tạo cảnh báo

### 10.8 Health Checks (Kiểm tra sức khỏe)

**Là gì?** Hệ thống tự kiểm tra xem mọi thứ có hoạt động tốt không.

**Ví dụ:**
- Database có còn kết nối được không?
- Realtime có còn gửi được event không?
- Backup gần nhất đã chạy thành công chưa?

### 10.9 Migration System

**Là gì?** Hệ thống quản lý các thay đổi cấu trúc database theo thời gian.

Khi cần thêm cột mới, không sửa trực tiếp mà tạo một file migration riêng. Điều này giúp:
- Mọi thay đổi đều có lịch sử
- Có thể rollback nếu cần
- Đồng bộ giữa các môi trường (dev, test, production)

---

## 11. Các Tính Năng SQL Server Được Sử Dụng

### 11.1 Stored Procedures

**Giải thích đơn giản:** Một "chương trình con" chạy trong database.

**Business Value:**
- **An toàn:** Chỉ gọi SP, không chạy SQL trực tiếp → chống SQL injection
- **Nhanh:** SP được biên dịch sẵn, database không phải "dịch" lại mỗi lần
- **Nhất quán:** Cùng một logic, gọi từ nhiều nơi, không sợ sai lệch

**Ví dụ trong hệ thống:**

| SP | Việc nó làm |
|---|---|
| `sp_StartChargingSession` | Kiểm tra + tạo phiên sạc + cập nhật trạng thái |
| `sp_EndChargingSession` | Tính tiền + kết thúc phiên + trả point |
| `sp_CreatePayment` | Xử lý thanh toán + cập nhật ví |
| `sp_ProcessRefund` | Xử lý hoàn tiền |
| `sp_DailyKPIAggregation` | Tổng hợp KPI cuối ngày |

### 11.2 Functions (Hàm)

**Giải thích đơn giản:** Giống SP nhưng **trả về một giá trị** (giống công thức toán học).

**Business Value:**
- **Tái sử dụng:** Cùng một hàm tính tiền, dùng ở nhiều chỗ
- **Nhất quán:** Giá luôn được tính cùng một cách
- **Dễ bảo trì:** Sửa một chỗ, ảnh hưởng tất cả

**Ví dụ trong hệ thống:**

| Function | Việc nó làm |
|---|---|
| `fn_CalculateChargingCost` | Tính tiền sạc (có tính giờ cao điểm, giảm giá) |
| `fn_GetEffectivePrice` | Tính giá hiệu quả sau tất cả quy tắc |
| `fn_GetStationUtilizationRate` | Tính tỷ lệ sử dụng trạm |
| `fn_GetFranchiseCommission` | Tính hoa hồng cho franchise |

### 11.3 Triggers (Bộ kích hoạt)

**Giải thích đơn giản:** Một đoạn code **tự động chạy** khi có sự kiện (INSERT, UPDATE, DELETE).

Giống như: "Khi có người bước vào cửa → chuông reo tự động."

**Business Value:**
- **Tự động hóa:** Không cần code backend, database tự làm
- **Bảo vệ dữ liệu:** Chặn sửa/xóa dữ liệu quan trọng
- **Đồng bộ:** Tự động cập nhật bảng liên quan

**Ví dụ trong hệ thống:**

| Trigger | Khi nào chạy? | Làm gì? |
|---|---|---|
| `trg_ChargingPoint_StatusChange` | Sau khi UPDATE ChargingPoint | Ghi lịch sử trạng thái |
| `trg_ChargingSession_PointSync` | Sau khi INSERT/UPDATE Session | Đồng bộ PointStatus (dự phòng) |
| `trg_Transaction_Immutable` | Khi UPDATE Transaction | Chặn sửa giao dịch đã hoàn thành |
| `trg_AuditLog_Immutable` | Khi DELETE/UPDATE AuditLog | **Chặn hoàn toàn** — audit không thể xóa |

### 11.4 Indexed Views (Khung nhìn được đánh chỉ mục)

**Giải thích đơn giản:** Một "bảng ảo" được lưu sẵn trên đĩa, tự động cập nhật.

**Business Value:**
- **Tốc độ:** Query báo cáo chạy nhanh 100-1000 lần so với query thường
- **Tự động:** Không cần ETL riêng, dữ liệu luôn mới

**Ví dụ:**
- `ivw_MonthlyRevenueSummary` — Doanh thu theo tháng, được lưu sẵn
- `ivw_DailyStationAvailability` — Tình trạng trạm, được lưu sẵn

### 11.5 Transactions & ACID

**Giải thích đơn giản:** Đảm bảo các thao tác database hoặc **làm hết** hoặc **không làm gì**.

**ACID là 4 đảm bảo:**

| Tính chất | Giải thích | Ví dụ |
|---|---|---|
| **Atomicity** | Tất cả hoặc không gì cả | Chuyển tiền: cả trừ và cộng đều phải thành công |
| **Consistency** | Dữ liệu luôn hợp lệ | Số dư ví không thể âm |
| **Isolation** | Giao dịch song song không ảnh hưởng nhau | Hai người cùng sạc không làm sai số liệu |
| **Durability** | Khi commit là dữ liệu được lưu vĩnh viễn | Mất điện cũng không mất giao dịch |

### 11.6 Constraints (Ràng buộc)

**Giải thích đơn giản:** Các "luật lệ" database tự động kiểm tra.

| Loại | Ví dụ | Chặn gì? |
|---|---|---|
| **CHECK** | `Balance >= 0` | Không cho ví âm tiền |
| **UNIQUE** | `StationCode` phải duy nhất | Không cho 2 trạm cùng mã |
| **FOREIGN KEY** | `UserID` phải tồn tại trong `User` | Không cho session của user ảo |
| **DEFAULT** | `CreatedAt = SYSDATETIME()` | Tự động ghi ngày tạo |

### 11.7 Indexes (Chỉ mục)

**Giải thích đơn giản:** Giống như **mục lục sách** — giúp tìm dữ liệu nhanh hơn.

- Không có index: Đọc từng dòng một để tìm (giống đọc cả cuốn sách)
- Có index: Nhảy thẳng đến dòng cần tìm (giống tra mục lục)

**Các loại index trong hệ thống:**

| Loại | Giải thích | Ví dụ |
|---|---|---|
| **Clustered** | Dữ liệu được sắp xếp vật lý | Mặc định trên khóa chính |
| **Nonclustered** | Bảng tra riêng, trỏ đến dữ liệu | Index trên UserID, SessionStatus |
| **Covering** | Index chứa đủ mọi cột cần query | Không cần đọc bảng gốc |
| **Filtered** | Chỉ index một phần dữ liệu | Chỉ index session đã hoàn thành |
| **Columnstore** | Nén dữ liệu theo cột | Cho analytics siêu nhanh |

### 11.8 Analytics Queries (Truy vấn phân tích)

**Giải thích đơn giản:** Các câu hỏi phức tạp để lấy thông tin tổng hợp.

**Ví dụ:**
```sql
-- "Tháng này doanh thu bao nhiêu?"
SELECT SUM(CostTotal) FROM ChargingSession
WHERE StartTime >= '2026-05-01' AND StartTime < '2026-06-01'
  AND SessionStatus = 'Completed'
```

```sql
-- "Giờ nào cao điểm nhất?"
SELECT DATEPART(HOUR, StartTime) AS Hour, COUNT(*) AS SessionCount
FROM ChargingSession
GROUP BY DATEPART(HOUR, StartTime)
ORDER BY SessionCount DESC
```

---

## 12. Các Vấn Đề Database Thực Tế

### 12.1 Orphan Records (Bản ghi mồ côi)

**Vấn đề là gì?** Dữ liệu ở bảng con tham chiếu đến bảng cha đã không còn tồn tại.

**Ví dụ:**
- Một `ChargingSession` có `UserID = 5`, nhưng `User` có `UserID = 5` đã bị xóa
- "Phiên sạc mồ côi" — không biết của ai

**Tại sao nguy hiểm?**
- Báo cáo không chính xác
- Không thể tra cứu thông tin người dùng
- Lỗi khi JOIN bảng

**Hệ thống xử lý thế nào?**
- **Foreign Key:** Chặn xóa User nếu còn Session
- **Soft Delete:** Không xóa thật, chỉ đánh dấu
- **SET NULL:** Một số bảng cho phép FK = NULL nếu bảng cha bị xóa

### 12.2 Duplicate Data (Dữ liệu trùng lặp)

**Vấn đề là gì?** Cùng một thông tin xuất hiện ở nhiều chỗ.

**Ví dụ:**
- Cùng một email nhưng có 2 tài khoản
- Cùng một phiên sạc nhưng có 2 giao dịch thanh toán

**Tại sao nguy hiểm?**
- Doanh thu bị tính sai (tính 2 lần)
- Khó xác định đâu là dữ liệu đúng

**Hệ thống xử lý thế nào?**
- **UNIQUE constraint:** Chặn email trùng, StationCode trùng
- **CHECK trong SP:** `sp_CreatePayment` kiểm tra session chưa có transaction
- **UNIQUE INDEX:** Trên các cột không được trùng

### 12.3 Race Condition (Điều kiện tranh)

**Vấn đề là gì?** Hai người cùng thao tác trên cùng dữ liệu cùng lúc.

**Ví dụ:**
- Người A và người B cùng nhấn "Bắt đầu sạc" ở cùng điểm sạc
- Cả hai đều kiểm tra thấy "còn trống"
- Cả hai đều được tạo session → 2 người cùng 1 điểm sạc!

**Tại sao nguy hiểm?**
- Một điểm sạc được "sạc đôi"
- Dữ liệu không nhất quán
- Mất tiền oan

**Hệ thống xử lý thế nào?**
- **Transaction:** Các thao tác trong cùng một giao dịch
- **UPDLOCK:** Khóa dòng dữ liệu khi đọc để chống thay đổi
- **Trigger dự phòng:** Double-check khi cập nhật PointStatus

### 12.4 Deadlock (Khóa chết)

**Vấn đề là gì?** Hai giao dịch chờ nhau giải phóng tài nguyên → không ai tiến lên được.

**Ví dụ:**
```
Giao dịch A: Khóa Bảng 1 → Chờ Bảng 2
Giao dịch B: Khóa Bảng 2 → Chờ Bảng 1
→ Cả hai đều chờ mãi mãi!
```

**Tại sao nguy hiểm?**
- Hệ thống bị treo
- Người dùng không thể thao tác

**Hệ thống xử lý thế nào?**
- **Transaction ngắn:** Giải phóng khóa nhanh
- **Thứ tự khóa nhất quán:** Luôn khóa bảng theo cùng một thứ tự
- **SQL Server tự động phát hiện:** Chọn một giao dịch làm "nạn nhân" và rollback

### 12.5 Stale Realtime State (Trạng thái realtime lỗi thời)

**Vấn đề là gì?** Frontend hiển thị trạng thái khác với dữ liệu thực tế trong database.

**Ví dụ:**
- App hiển thị "Điểm sạc còn trống" nhưng thực tế đã có người sạc
- Dashboard hiển thị số liệu cũ

**Tại sao nguy hiểm?**
- Người dùng đến trạm nhưng không sạc được
- Quyết định sai dựa trên dữ liệu cũ

**Hệ thống xử lý thế nào?**
- **Realtime sync:** Socket.IO gửi cập nhật ngay khi có thay đổi
- **Double-check:** Khi người dùng bắt đầu sạc, kiểm tra lại trạng thái từ database
- **Heartbeat:** Frontend kiểm tra kết nối realtime còn hoạt động không

### 12.6 Inconsistent Analytics (Dữ liệu phân tích không nhất quán)

**Vấn đề là gì?** Số liệu giữa các báo cáo khác nhau.

**Ví dụ:**
- Dashboard hôm nay: "Doanh thu hôm qua: 50 triệu"
- Báo cáo cuối tháng: "Doanh thu hôm qua: 48 triệu"
- Cái nào đúng?

**Tại sao nguy hiểm?**
- Mất lòng tin vào hệ thống
- Quyết định kinh doanh sai

**Hệ thống xử lý thế nào?**
- **Stored procedure tập trung:** Cùng một SP cho mọi tính toán
- **Materialized view:** Dữ liệu được tính một lần, dùng nhiều nơi
- **Timestamp:** Mọi báo cáo đều ghi rõ thời điểm tính

---

## 13. Tổng Kết Kiến Trúc

### 13.1 Tổng quan toàn bộ hệ thống

```
                    ┌────────────────────────────────────────────┐
                    │           NGƯỜI DÙNG                       │
                    │  (App, Web, Dashboard, IoT Device)         │
                    └──────────────────┬─────────────────────────┘
                                       │
                    ┌──────────────────▼─────────────────────────┐
                    │              BACKEND (Node.js)             │
                    │  ┌────────┐ ┌────────┐ ┌───────────────┐  │
                    │  │Auth API│ │Business│ │Realtime Server│  │
                    │  │        │ │  API   │ │(Socket.IO)    │  │
                    │  └────────┘ └────────┘ └───────────────┘  │
                    └──────────────────┬─────────────────────────┘
                                       │
                    ┌──────────────────▼─────────────────────────┐
                    │         DATABASE (SQL Server 2022+)        │
                    │                                           │
                    │  ┌────────────┐ ┌────────────┐          │
                    │  │  OLTP     │ │   OLAP     │          │
                    │  │  (Giao dịch)│ │  (Phân tích)│          │
                    │  │            │ │            │          │
                    │  │ Users     │ │ DailyKPI   │          │
                    │  │ Operations│ │ MonthlyRev │          │
                    │  │ Payments  │ │ HourlyAgg  │          │
                    │  │ Monitoring│ │  ...       │          │
                    │  │ Infrastructure│ │            │          │
                    │  └────────────┘ └────────────┘          │
                    │                                           │
                    │  ┌──────────────────────────────────┐    │
                    │  │  Cross-cutting: Audit | Reporting │    │
                    │  └──────────────────────────────────┘    │
                    └───────────────────────────────────────────┘
```

### 13.2 Tại sao chọn kiến trúc database-centric?

**Database-centric** nghĩa là database là **trung tâm** của hệ thống — mọi thứ xoay quanh nó.

**Ưu điểm:**

| Khía cạnh | Lợi ích |
|---|---|
| **Nhất quán** | Mọi dữ liệu tập trung một chỗ, không sợ lệch |
| **An toàn** | Foreign Key, Constraints, Transactions bảo vệ dữ liệu |
| **Truy vấn phức tạp** | SQL Server xử lý được các báo cáo phức tạp |
| **Tích hợp** | Dễ kết nối với Power BI, Excel, các công cụ BI khác |
| **ACID** | Đảm bảo giao dịch tài chính chính xác tuyệt đối |

### 13.3 Ưu điểm của Realtime Architecture

- **Trải nghiệm người dùng tốt hơn:** Thông tin luôn mới, không cần refresh
- **Phát hiện sự cố nhanh:** Cảnh báo xuất hiện ngay lập tức
- **Dashboard live:** Quản lý thấy số liệu thực tế, không bị trễ

### 13.4 Ưu điểm của Analytics-First Design

- **Dashboard nhanh:** Dữ liệu đã được tổng hợp sẵn, không cần tính toán lại
- **Tiết kiệm tài nguyên:** Không query bảng gốc hàng triệu dòng
- **History tracking:** Dữ liệu KPI được lưu theo ngày, có thể so sánh

### 13.5 Scalability Considerations (Khả năng mở rộng)

Khi hệ thống lớn lên (nhiều trạm hơn, nhiều người dùng hơn), có thể mở rộng bằng cách:

| Chiến lược | Giải thích |
|---|---|
| **Partitioning** | Chia bảng lớn thành nhiều phần nhỏ hơn (theo tháng/năm) |
| **Read Replicas** | Tạo bản sao database chỉ để đọc — giảm tải cho database chính |
| **Columnstore** | Nén dữ liệu analytics — tăng tốc 10-100x |
| **Archiving** | Chuyển dữ liệu cũ sang database riêng — giữ database chính nhẹ |
| **Microservices** | Tách các module thành dịch vụ riêng biệt |

### 13.6 Enterprise Considerations (Yếu tố doanh nghiệp)

Hệ thống được thiết kế với tư duy doanh nghiệp:

| Yếu tố | Giải pháp |
|---|---|
| **Bảo mật** | RBAC + RLS + Data Masking + Encryption |
| **Kiểm toán** | AuditLog bất biến, StatusHistory chi tiết |
| **Sẵn sàng** | Always On Availability Groups, backup strategy |
| **Phục hồi** | Point-in-time recovery, soft delete |
| **Tuân thủ** | GDPR-ready (tách PII), audit trail, immutable logs |
| **Vận hành** | Monitoring, alerting, health checks |

---

## Phụ Lục: Bảng Tổng Hợp Các Module & Bảng Chính

| Module | Bảng chính | Mục đích |
|---|---|---|
| **Users** | User, UserProfile, UserCredential, Vehicle | Quản lý người dùng & xe |
| **Access** | Role, Permission, RolePermission | Phân quyền |
| **Infrastructure** | ChargingStation, ChargingPoint, Address, Franchise | Hạ tầng vật lý |
| **Operations** | ChargingSession, PricingPolicy, PricingRule | Vận hành cốt lõi |
| **Payments** | Transaction, Wallet, Invoice, Refund | Tài chính |
| **Monitoring** | PointTelemetry, Alert, ErrorLog | Giám sát IoT |
| **Audit** | AuditLog, StatusHistory | Kiểm toán |
| **Analytics** | DailyStationKPI, HourlySessionAgg | Phân tích KPI |
| **Reporting** | vw_ActiveChargingSessions, vw_StationAvailability, ... | Báo cáo |

---

> **Tài liệu này được thiết kế cho tất cả mọi người — từ người mới bắt đầu đến chuyên gia.**
> Nếu bạn đọc đến đây mà vẫn còn thắc mắc, hãy xem lại các phần:
> - Phần 3 nếu bạn chưa rõ về database cơ bản
> - Phần 4 nếu bạn muốn hiểu từng module
> - Phần 7 nếu bạn muốn xem dữ liệu chạy thế nào
> - Phần 8 nếu bạn muốn hiểu realtime

---

**Ngày tạo:** 2026
**Phiên bản:** 3.0 (Hướng dẫn cho người mới)
**Môn học:** IE103 — Quản lý Thông tin
