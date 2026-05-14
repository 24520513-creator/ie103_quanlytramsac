USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: xem tang truong khach hang theo thang.
- Khong can sua tham so.
- Tac dong du lieu: CHI DOC DU LIEU, khong them/sua/xoa.
*/

PRINT N'Xem tăng trưởng khách hàng: quản lý kinh doanh theo dõi số khách hàng mới theo tháng.';

SELECT *
FROM AppView.vw_CustomerGrowth
ORDER BY CreatedYear, CreatedMonth;
GO




