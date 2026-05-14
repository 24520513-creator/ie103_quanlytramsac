USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: xem cac phien sac dang chay.
- Khong can sua tham so.
- Tac dong du lieu: CHI DOC DU LIEU, khong them/sua/xoa.
*/

PRINT N'Theo dõi phiên sạc đang chạy: nhân viên vận hành xem các phiên đang sạc và thời lượng hoạt động.';

SELECT *
FROM AppView.vw_ActiveChargingSessions
ORDER BY StartTime DESC;
GO




