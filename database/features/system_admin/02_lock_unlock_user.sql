USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: khoa va mo lai tai khoan.
- Tham so co the sua: @UserID.
- Tac dong du lieu: SUA THAT AccountStatus sang Locked roi tra ve Active.
*/

PRINT N'Khóa và mở tài khoản: quản trị viên thay đổi trạng thái tài khoản để kiểm soát truy cập.';

DECLARE @UserID INT = (SELECT UserID FROM [Identity].UserAccount WHERE Username = N'customer05');

SELECT UserID, Username, AccountStatus, UpdatedAt
FROM [Identity].UserAccount
WHERE UserID = @UserID;

EXEC [Identity].sp_LockUser @UserID = @UserID;

SELECT UserID, Username, AccountStatus, UpdatedAt
FROM [Identity].UserAccount
WHERE UserID = @UserID;

EXEC [Identity].sp_UnlockUser @UserID = @UserID;

SELECT UserID, Username, AccountStatus, UpdatedAt
FROM [Identity].UserAccount
WHERE UserID = @UserID;
GO



