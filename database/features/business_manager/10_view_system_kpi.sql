USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: xem KPI van hanh he thong.
- Khong can sua tham so.
- Tac dong du lieu: CHI DOC DU LIEU, khong them/sua/xoa.
*/

PRINT N'Xem KPI vận hành hệ thống: quản lý kinh doanh xem số trạm, cổng, phiên sạc, lỗi, ticket và khách hàng sử dụng nhiều.';

SELECT *
FROM AppView.vw_SystemOperationalKPI;

SELECT TOP 20 *
FROM AppView.vw_ChargingSessionStatistics
ORDER BY SessionDate DESC, SessionStatus;

SELECT TOP 10 *
FROM AppView.vw_TopCustomerUsage
ORDER BY TotalSpend DESC;
GO




