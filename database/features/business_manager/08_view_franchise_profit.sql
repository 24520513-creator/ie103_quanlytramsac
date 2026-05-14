USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: xem du lieu chia loi nhuan franchise.
- Khong can sua tham so.
- Tac dong du lieu: CHI DOC DU LIEU, khong them/sua/xoa.
*/

PRINT N'Xem chia lợi nhuận franchise: quản lý kinh doanh xem phần doanh thu của đối tác và nền tảng.';

EXEC AppView.sp_GetFranchiseProfitSharing;
GO




