# EV_Charging_System - Database Project IE103

Đây là database độc lập cho đồ án:

> Hệ thống quản lý mạng lưới trạm sạc xe điện và doanh nghiệp nhượng quyền

Trọng tâm project là SQL Server/SSMS. Backend, frontend và deploy có thể phát triển tiếp sau, nhưng database hiện tại đã đủ tự chạy, tự seed dữ liệu, test nghiệp vụ, test phân quyền và xem báo cáo.

## Thiết kế hiện tại

- DBMS: Microsoft SQL Server.
- Database: `EV_Charging_System`.
- Schema chính:
  - `Core`: quốc gia, khu vực, địa chỉ.
  - `Identity`: user, role, permission, user-role, profile.
  - `Infrastructure`: trạm sạc, cổng sạc, connector, telemetry.
  - `Franchise`: đối tác, hợp đồng, trạm thuộc franchise, chính sách chia doanh thu, settlement.
  - `Operations`: xe, đặt lịch, phiên sạc, giá sạc, sự kiện phiên.
  - `Payments`: ví, QR, giao dịch, hóa đơn, hoàn tiền.
  - `Maintenance`: lỗi, ticket, phân công, lịch sử xử lý.
  - `Reporting`: view/procedure báo cáo.
  - `Audit`: audit log.

## Cách chạy nhanh

Trong SSMS:

1. Mở `database/run_all.sql`.
2. Bật `Query -> SQLCMD Mode`.
3. Execute toàn bộ file.

Command line:

```bat
cd database
run_all.bat
```

`run_all.bat` đọc `backend/.env` nếu có, nhưng database không phụ thuộc backend.

## File database

Folder `database` đã được dọn gọn thành bộ script chính:

```text
00_Drop_And_Create_Database.sql
01_Create_Schemas.sql
02_Create_Tables.sql
03_Create_Constraints_Indexes.sql
04_Create_Functions.sql
05_Create_Stored_Procedures.sql
06_Create_Triggers.sql
07_Create_Reporting.sql
08_Create_Security.sql
09_Seed_Demo_Data.sql
10_Demo_Queries.sql
11_Test_Roles.sql
12_Backup_Restore.sql
run_all.sql
run_all.bat
README.md
```

## Role chính

- `SystemAdmin`
- `OperationsStaff`
- `BusinessManager`
- `Customer`

## Demo bằng SSMS

Sau khi chạy `run_all.sql`, các phần sau đã được thực hiện:

- Tạo database, schema, table, PK/FK/CHECK/index.
- Seed dữ liệu giả lập hợp lý.
- Chạy query báo cáo.
- Demo luồng: start session -> end session -> payment -> invoice.
- Demo rollback refund sai số tiền.
- Demo phân quyền bằng `EXECUTE AS USER`.

Các script có thể chạy riêng:

- `database/10_Demo_Queries.sql`
- `database/11_Test_Roles.sql`
- `database/12_Backup_Restore.sql`

## Hướng phát triển backend/frontend sau này

Database đã có khóa chính/khóa ngoại, status lifecycle, role model, procedure nghiệp vụ và report view rõ ràng, nên backend có thể map API theo các module:

- `/stations`, `/charging-points`
- `/sessions`, `/bookings`
- `/wallets`, `/payments`, `/invoices`, `/refunds`
- `/franchises`, `/contracts`, `/settlements`
- `/maintenance`, `/telemetry`
- `/reports`
- `/users`, `/roles`
