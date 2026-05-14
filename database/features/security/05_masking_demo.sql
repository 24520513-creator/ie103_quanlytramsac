USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: demo dynamic data masking.
- Khong can sua tham so; mask_viewer la user tam de xem du lieu bi che.
- Tac dong du lieu: CO THE TAO user database mask_viewer neu chua ton tai; khong sua du lieu nghiep vu.
*/

PRINT N'Kiểm tra che dữ liệu nhạy cảm: chứng minh email, điện thoại và password hash bị mask với user không có UNMASK.';

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'mask_viewer')
    CREATE USER mask_viewer WITHOUT LOGIN;
GO

GRANT SELECT ON OBJECT::[Identity].UserAccount TO mask_viewer;
GO

PRINT N'Kiểm tra che dữ liệu nhạy cảm: chứng minh email, điện thoại và password hash bị mask với user không có UNMASK.';
EXECUTE AS USER = 'admin01';
SELECT TOP 5 Username, Email, Phone, PasswordHash
FROM [Identity].UserAccount
ORDER BY UserID;
REVERT;

PRINT N'Kiểm tra che dữ liệu nhạy cảm: chứng minh email, điện thoại và password hash bị mask với user không có UNMASK.';
EXECUTE AS USER = 'mask_viewer';
SELECT TOP 5 Username, Email, Phone, PasswordHash
FROM [Identity].UserAccount
ORDER BY UserID;
REVERT;
GO



