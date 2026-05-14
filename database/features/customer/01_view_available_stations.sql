USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: xem cac tram va cong sac dang kha dung.
- Khong can sua tham so; neu muon loc khu vuc, them WHERE RegionName = N''...'' sau FROM AppView.vw_AvailableChargingPoints.
- Tac dong du lieu: CHI DOC DU LIEU, khong them/sua/xoa.
*/

PRINT N'Xem trạm và cổng sạc khả dụng: khách hàng tra cứu các cổng đang sẵn sàng để đặt lịch hoặc bắt đầu sạc.';

SELECT TOP 20 *
FROM AppView.vw_AvailableChargingPoints
ORDER BY RegionName, StationCode, PointCode;
GO




