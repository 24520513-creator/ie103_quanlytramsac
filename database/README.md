# EV_Charging_System Database

Database độc lập cho đồ án IE103: quản lý mạng lưới trạm sạc xe điện và doanh nghiệp nhượng quyền.

## Cách chạy trong SSMS

1. Mở `database/run_all.sql`.
2. Bật `Query -> SQLCMD Mode`.
3. Chạy toàn bộ script.

Hoặc chạy command line:

```bat
cd database
run_all.bat
```

## Cấu trúc script

| File | Mục đích |
|---|---|
| `00_Drop_And_Create_Database.sql` | Tạo mới database |
| `01_Create_Schemas.sql` | Tạo schema nghiệp vụ |
| `02_Create_Tables.sql` | Tạo bảng, PK, FK, CHECK |
| `03_Create_Constraints_Indexes.sql` | Index cho FK, status, time, report |
| `04_Create_Functions.sql` | Function tính tiền, chia doanh thu, utilization, refundable amount |
| `05_Create_Stored_Procedures.sql` | Procedure nghiệp vụ có transaction |
| `06_Create_Triggers.sql` | Audit/history trigger |
| `07_Create_Reporting.sql` | View/procedure báo cáo |
| `08_Create_Security.sql` | Role/user/permission SQL Server |
| `09_Seed_Demo_Data.sql` | Dữ liệu mẫu hợp lý |
| `10_Demo_Queries.sql` | Query và workflow demo |
| `11_Test_Roles.sql` | Test phân quyền bằng `EXECUTE AS USER` |
| `12_Backup_Restore.sql` | Script backup/restore tham khảo |

## Role chính

- `SystemAdmin`
- `OperationsStaff`
- `BusinessManager`
- `Customer`

## Demo account

- `admin01@gmail.com`
- `operator01@gmail.com`
- `business01@gmail.com`
- `customer01@gmail.com` đến `customer05@gmail.com`

Mật khẩu trong seed chỉ là hash demo cho database; backend có thể thay bằng cơ chế hash thật.
