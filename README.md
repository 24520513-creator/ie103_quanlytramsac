# EV Charging System - IE103 Database Project

Day la do an co trong tam la SQL Server/SSMS cho he thong quan ly mang tram sac xe dien va doi tac nhuong quyen.

Backend va frontend da duoc loai khoi source hien tai de tap trung vao phan database. Neu can phat trien ung dung sau nay, co the build lai tu dau dua tren schema, stored procedure, view va security script trong thu muc `database`.

## Thanh phan chinh

- DBMS: Microsoft SQL Server.
- Database: `EV_Charging_System`.
- Thu muc chinh: `database`.
- Tai lieu phan tich: `DatabaseAnalysts.md`.

## Schema

- `Core`: quoc gia, khu vuc, dia chi.
- `Identity`: tai khoan, role, user-role.
- `Infrastructure`: tram sac, cong sac, connector, telemetry.
- `Franchise`: doi tac, hop dong, chinh sach chia doanh thu, settlement.
- `Operations`: xe, booking, phien sac, chinh sach gia.
- `Payments`: giao dich thanh toan, hoa don.
- `Maintenance`: loi, ticket bao tri.
- `AppView`: view va procedure phuc vu demo, bao cao.
- `Audit`: audit log.

## Thu tu chay script

Chay trong SSMS theo thu tu:

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
```

Script bo sung:

- `database/09_Advanced_Security.sql`: Dynamic Data Masking va cac ghi chu bao mat nang cao.
- `database/12_Backup_Restore.sql`: mau backup/restore.
- `database/features`: cac kich ban demo nghiep vu, phan quyen, bao cao va negative test.
- `database/features/security/08_sql_authentication_logins.sql`: script tuy chon de tao SQL Authentication login that trong SSMS.

## Role demo

- `SystemAdmin`
- `OperationsStaff`
- `BusinessManager`
- `Customer`

## Security core

Phan quyen SQL Server nam trong `database/08_Create_Security.sql`. File nay chi tap trung vao phan bat buoc cua mon hoc:

- `CREATE USER`
- `CREATE ROLE`
- role membership
- `GRANT`
- `DENY`
- nguyen tac least privilege

Mo hinh can trinh bay:

```text
Server Login -> Database User -> Database Role -> Permission
```

Trong demo chinh, cac user duoc tao bang `CREATE USER ... WITHOUT LOGIN` de co the chay bang `EXECUTE AS USER` ngay trong SSMS ma khong phu thuoc cau hinh SQL Authentication cua may cham.

## Ma tran quyen

| Database role | Vai tro nghiep vu | Quyen duoc cap | Quyen bi chan co chu dich |
|---|---|---|---|
| `db_ev_system_admin` | Quan tri he thong | Quan ly du lieu, user-role, cau hinh, audit; co `UNMASK` neu chay advanced security. | Khong dung `db_owner`/`sysadmin`; audit log van duoc trigger bao ve. |
| `db_ev_operations_staff` | Nhan vien van hanh | Xem/cap nhat du lieu `Infrastructure`, `Operations`, `Maintenance`; goi procedure van hanh. | Khong doc `Identity`, khong doc/sua `Payments`. |
| `db_ev_business_manager` | Quan ly kinh doanh | Xem view/procedure bao cao, doanh thu, KPI, franchise settlement. | Khong doc truc tiep schema `Payments`, khong sua `Infrastructure`, `Operations`, `Maintenance`, `Identity`. |
| `db_ev_customer` | Khach hang | Xem view lich su/hoa don/cong sac kha dung; goi procedure xe, booking, phien sac, payment. | Khong doc truc tiep `Payments`, `Identity`. |

## Demo phan quyen trong SSMS

Chay cac demo core sau khi setup database va seed data:

```text
database/features/security/01_customer_permissions.sql
database/features/security/02_operations_permissions.sql
database/features/security/03_business_permissions.sql
database/features/security/04_admin_permissions.sql
```

Cac demo nay chung minh: moi role co mot truy van duoc phep va mot truy van bi chan bang permission denied.

`REVOKE` duoc giai thich nhu thao tac thu hoi quyen trong nhom DCL. Neu can demo them, co the them mot doan phu luc ngan cap tam quyen bang `GRANT`, thu hoi bang `REVOKE`, roi chay lai truy van de thay loi.

## Advanced Security

`database/09_Advanced_Security.sql` gom cac tinh nang nang cao, hien tai la Dynamic Data Masking cho `Email`, `Phone`, `PasswordHash`. Cac demo nang cao nam trong `database/features/security`:

- `05_masking_demo.sql`: Dynamic Data Masking.
- `06_row_level_security_demo.sql`: Row-Level Security tam thoi.
- `07_soft_delete_demo.sql`: soft delete.
- `08_sql_authentication_logins.sql`: SQL Authentication login that.

Neu muon dang nhap SSMS bang SQL Authentication thay vi chi demo bang `EXECUTE AS USER`, chay them `database/features/security/08_sql_authentication_logins.sql` sau khi da chay `08_Create_Security.sql`. Script nay can tai khoan co quyen `CREATE LOGIN`.

## Pham vi do an

Source hien tai uu tien:

- Thiet ke CSDL, schema, rang buoc, index.
- Stored procedure cho cac nghiep vu chinh.
- Trigger va audit log.
- View/procedure bao cao.
- Seed data phuc vu demo.
- Demo phan quyen va kiem thu tinh huong sai.
