# EV Charging System - IE103

Đồ án quản lý trạm sạc điện dùng SQL Server làm trung tâm dữ liệu, nghiệp vụ, phân quyền và báo cáo. Website gồm hai lớp ứng dụng:

- `backend`: Node/Express, xác thực người dùng, gọi view/stored procedure đã whitelist trong catalog, luôn set `SESSION_CONTEXT`.
- `frontend`: React/Vite, giao diện đăng nhập/đăng kí, dashboard theo vai trò, form, bảng dữ liệu, PDF/CSV và import JSON.

## Cấu Trúc

- `database`: schema, bảng, function, stored procedure, trigger, view, security, seed data và script demo.
- `backend`: API xác thực, catalog chức năng, gọi SQL Server, export PDF/CSV, import JSON.
- `frontend`: giao diện người dùng, layout quản trị, dashboard, bảng dữ liệu và form động.
- `docker-compose.yml`: đóng gói frontend/backend; SQL Server có thể dùng instance ngoài.
- `docs`: tài liệu phân tích database và tính năng của đồ án (IE103).

## Database

Database mặc định: `EV_Charging_System`.

Chạy trong SSMS hoặc `sqlcmd` theo thứ tự:

```text
database/00_Drop_And_Create_Database.sql
database/01_Create_Schemas.sql
database/02_Create_Tables.sql
database/03_Create_Constraints_Indexes.sql
database/04_Create_Functions.sql
database/05_Create_Stored_Procedures.sql
database/06_Create_Triggers.sql
database/07_Create_AppViews.sql
database/08_Create_Security.sql
database/09_Seed_Demo_Data.sql
database/features/security/08_sql_authentication_logins.sql
```

Script bổ sung:

- `database/09_Advanced_Security.sql`: masking và ghi chú bảo mật nâng cao.
- `database/12_Backup_Restore.sql`: mẫu backup/restore.
- `database/13_Auth_Migration.sql`: bổ sung bảng/procedure auth cho database đang có sẵn dữ liệu.
- `database/features`: kịch bản demo nghiệp vụ, phân quyền và negative test.
- `database/features/security/08_sql_authentication_logins.sql`: tạo SQL Authentication login demo cho backend.

## Phân Quyền Web

Website dùng hai tầng:

```text
SQL Server role/login -> kiểm soát vai trò được làm gì
SESSION_CONTEXT(UserID, Username, RoleCode) -> lọc dữ liệu theo người dùng hiện tại
```

Backend không nhận SQL tự do từ frontend. Mỗi API map tới action trong `backend/src/catalog.js`.

## Xác Thực

Luồng auth hiện có:

- `POST /api/auth/register`: đăng kí công khai cho khách hàng.
- `POST /api/auth/login`: đăng nhập bằng username, email hoặc số điện thoại.
- `POST /api/auth/logout`: đăng xuất và xóa cookie phiên.
- `GET /api/me`: lấy thông tin user hiện tại.
- `POST /api/auth/forgot-password`: yêu cầu đặt lại mật khẩu.
- `POST /api/auth/reset-password`: đặt lại mật khẩu bằng token.
- `POST /api/auth/verify-email`: xác minh email nếu bật luồng token xác minh.

Backend tự hash mật khẩu bằng `bcrypt`. Frontend không gửi SQL và không xử lý password hash.

## Tài Khoản Demo

Mật khẩu demo: `password`.

| Username | Vai trò |
|---|---|
| `customer01` | Khách hàng |
| `operator01` | Nhân viên vận hành |
| `business01` | Quản lý kinh doanh |
| `franchise01` | Đối tác nhượng quyền |
| `admin01` | Quản trị hệ thống |

## Chạy Website

Backend:

```powershell
cd backend
copy .env.example .env
npm install
npm run dev
```

Frontend:

```powershell
cd frontend
npm install
npm run dev
```

URL mặc định:

- Frontend: `http://localhost:3000`
- Backend: `http://localhost:8000`

Docker Compose:

```powershell
docker compose up --build
```

## Biến Môi Trường Backend

Các biến auth chính nằm trong `backend/.env.example`:

- `FRONTEND_URL=http://localhost:3000`
- `AUTH_COOKIE_NAME=ev_session`
- `ACCESS_TOKEN_TTL=8h`
- `AUTH_COOKIE_MAX_AGE_MS=28800000`
- `RESET_TOKEN_MINUTES=30`
- `LOG_RESET_TOKENS=true`

Khi `LOG_RESET_TOKENS=true`, backend in reset token ra log để kiểm thử local/dev.

## Kiểm Thử Nhanh

Build frontend:

```powershell
cd frontend
npm run build
```

Smoke test backend sau khi backend đang chạy:

```powershell
cd backend
npm run smoke
```

Smoke test kiểm tra:

- đăng nhập đủ 5 role demo;
- `/api/me`;
- dashboard chính từng role;
- customer bị chặn khi gọi action admin;
- export PDF/CSV cho báo cáo.

## Phạm Vi Website

Đã bám theo database hiện có:

- Customer: xe, cổng khả dụng, booking, phiên sạc, payment, invoice.
- Operations Staff: trạng thái trạm/cổng, phiên đang sạc, lỗi thiết bị, ticket, telemetry.
- Business Manager: pricing policy, báo cáo doanh thu/KPI, settlement, profit sharing, refund.
- Franchise Partner: hồ sơ, hợp đồng, trạm, revenue share policy, settlement của chính mình.
- System Admin: user, role, khóa/mở khóa, reset password, audit log, hướng dẫn backup/restore.

Export/import:

- PDF cho các báo cáo có ngày xuất, người lập, vai trò và ký xác nhận.
- CSV cho màn hình đọc dữ liệu và báo cáo.
- Import JSON chỉ bật cho procedure được whitelist, không cho gửi SQL tùy ý.
