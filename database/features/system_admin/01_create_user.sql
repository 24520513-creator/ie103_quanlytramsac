USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: tao user moi va gan role ban dau.
- Tham so co the sua: @Username, @Email, @Phone, @PasswordHash, @FullName, @RoleCode.
- @Username va @Email phai duy nhat; script dang tu sinh suffix de tranh trung.
- Tac dong du lieu: THEM THAT UserAccount va UserRole.
*/

PRINT N'Tạo tài khoản: quản trị viên tạo user mới và gán role ban đầu bằng stored procedure.';

DECLARE @Suffix NVARCHAR(12) = RIGHT(REPLACE(CONVERT(NVARCHAR(36), NEWID()), N'-', N''), 8);
DECLARE @Username NVARCHAR(50) = N'feature_user_' + @Suffix;
DECLARE @Email NVARCHAR(120) = @Username + N'@demo.local';

SELECT TOP 10 UserID, Username, Email, FullName, AccountStatus
FROM [Identity].UserAccount
ORDER BY UserID DESC;

EXEC [Identity].sp_CreateUser
    @Username = @Username,
    @Email = @Email,
    @Phone = NULL,
    @PasswordHash = N'FEATURE-DEMO-HASH',
    @FullName = N'FEATURE-DEMO User',
    @RoleCode = N'Customer';

SELECT TOP 10 UserID, Username, Email, FullName, AccountStatus
FROM [Identity].UserAccount
ORDER BY UserID DESC;
GO



