USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: gan role cho user roi go role do.
- Tham so co the sua: @UserID, @RoleCode.
- Tac dong du lieu: THEM/DELETE THAT dong trong Identity.UserRole cho role demo.
*/

PRINT N'Gán và gỡ role: quản trị viên thay đổi quyền của user thông qua bảng liên kết user-role.';

DECLARE @UserID INT = (SELECT UserID FROM [Identity].UserAccount WHERE Username = N'customer05');

SELECT *
FROM AppView.vw_UserRoleSummary
WHERE UserID = @UserID;

EXEC [Identity].sp_AssignRole
    @UserID = @UserID,
    @RoleCode = N'OperationsStaff';

SELECT *
FROM AppView.vw_UserRoleSummary
WHERE UserID = @UserID;

EXEC [Identity].sp_RemoveRole
    @UserID = @UserID,
    @RoleCode = N'OperationsStaff';

SELECT *
FROM AppView.vw_UserRoleSummary
WHERE UserID = @UserID;
GO




