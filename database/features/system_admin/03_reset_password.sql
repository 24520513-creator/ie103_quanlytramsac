USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: reset password hash cua user.
- Tham so co the sua: @UserID, @PasswordHash.
- Tac dong du lieu: SUA THAT PasswordHash va ghi audit.
*/

PRINT N'Reset mật khẩu: quản trị viên cập nhật password hash và ghi nhận thao tác vào audit.';

DECLARE @UserID INT = (SELECT UserID FROM [Identity].UserAccount WHERE Username = N'customer05');

SELECT UserID, Username, PasswordHash, UpdatedAt
FROM [Identity].UserAccount
WHERE UserID = @UserID;

EXEC [Identity].sp_ResetPassword
    @UserID = @UserID,
    @PasswordHash = N'FEATURE-DEMO-RESET-HASH';

SELECT UserID, Username, PasswordHash, UpdatedAt
FROM [Identity].UserAccount
WHERE UserID = @UserID;
GO



