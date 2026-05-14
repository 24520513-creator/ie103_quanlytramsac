USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: xem bo du lieu doanh thu theo tram.
- Tham so co the sua: @FromDate va @ToDate trong lenh EXEC.
- Tac dong du lieu: CHI DOC DU LIEU, khong them/sua/xoa.
*/

PRINT N'Xem doanh thu theo trạm: quản lý kinh doanh lấy dữ liệu doanh thu trạm theo khoảng ngày.';

EXEC AppView.sp_GetStationRevenue
    @FromDate = '2026-05-01',
    @ToDate = '2026-05-31';
GO




