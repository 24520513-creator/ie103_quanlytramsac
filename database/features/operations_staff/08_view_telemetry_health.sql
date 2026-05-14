USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: xem cac mau telemetry co canh bao suc khoe thiet bi.
- Khong can sua tham so.
- Tac dong du lieu: CHI DOC DU LIEU, khong them/sua/xoa.
*/

PRINT N'Theo dõi sức khỏe thiết bị: nhân viên vận hành xem các mẫu telemetry cảnh báo hoặc nghiêm trọng.';

EXEC AppView.sp_GetTelemetryHealth;
GO




