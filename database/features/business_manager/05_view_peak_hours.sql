USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: xem gio cao diem dua tren gio bat dau phien sac.
- Khong can sua tham so.
- Tac dong du lieu: CHI DOC DU LIEU, khong them/sua/xoa.
*/

PRINT N'Thống kê giờ cao điểm: quản lý kinh doanh phân tích số phiên và doanh thu theo giờ bắt đầu sạc.';

SELECT *
FROM AppView.vw_PeakHourStatistics
ORDER BY SessionCount DESC, RevenueTotal DESC;
GO




