USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: xem top tram co doanh thu cao.
- Co the sua TOP 10 thanh TOP n neu muon xem nhieu/it hon.
- Tac dong du lieu: CHI DOC DU LIEU, khong them/sua/xoa.
*/

PRINT N'Xem top trạm doanh thu cao: quản lý kinh doanh xếp hạng trạm theo doanh thu và số phiên sạc.';

SELECT TOP 10 *
FROM AppView.vw_TopRevenueStations
ORDER BY RevenueTotal DESC, CompletedSessions DESC;
GO




