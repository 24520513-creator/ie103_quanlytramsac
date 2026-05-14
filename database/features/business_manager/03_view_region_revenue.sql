USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: xem doanh thu tong hop theo khu vuc.
- Khong can sua tham so.
- Tac dong du lieu: CHI DOC DU LIEU, khong them/sua/xoa.
*/

PRINT N'Xem doanh thu theo khu vực: quản lý kinh doanh tổng hợp doanh thu theo region.';

SELECT *
FROM AppView.vw_RegionRevenue
ORDER BY RevenueTotal DESC;
GO




