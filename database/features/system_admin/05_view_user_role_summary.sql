USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: xem tong hop user va role.
- Khong can sua tham so.
- Tac dong du lieu: CHI DOC DU LIEU, khong them/sua/xoa.
*/

PRINT N'Xem tổng hợp user-role: quản trị viên xem tài khoản, trạng thái và danh sách role hiện có.';

SELECT *
FROM AppView.vw_UserRoleSummary
ORDER BY UserID;
GO




