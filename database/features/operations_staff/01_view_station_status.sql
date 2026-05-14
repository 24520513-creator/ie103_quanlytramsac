USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: xem tinh trang tram va cong sac.
- Khong can sua tham so.
- Tac dong du lieu: CHI DOC DU LIEU, khong them/sua/xoa.
*/

PRINT N'Xem trạng thái trạm: nhân viên vận hành theo dõi số cổng khả dụng, đang sạc và gặp sự cố theo từng trạm.';

SELECT *
FROM AppView.vw_StationStatusOverview
ORDER BY StationCode;
GO




