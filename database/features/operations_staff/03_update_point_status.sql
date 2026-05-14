USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: cap nhat trang thai cong sac va kiem tra lich su trang thai.
- Tham so co the sua: @PointID, @PointStatus, @HealthStatus, @OperatorID.
- Tac dong du lieu: SUA THAT ChargingPoint; trigger tao PointStatusHistory va AuditLog.
*/

PRINT N'Cập nhật trạng thái cổng sạc: nhân viên vận hành đổi trạng thái cổng và kiểm tra lịch sử trạng thái.';

DECLARE @PointID INT = (SELECT TOP 1 PointID FROM Infrastructure.ChargingPoint WHERE PointStatus = N'Available' ORDER BY PointID);
DECLARE @OperatorID INT = (SELECT UserID FROM [Identity].UserAccount WHERE Username = N'operator01');

SELECT PointID, PointCode, PointStatus, HealthStatus
FROM Infrastructure.ChargingPoint
WHERE PointID = @PointID;

EXEC Infrastructure.sp_UpdateChargingPointStatus
    @PointID = @PointID,
    @PointStatus = N'Offline',
    @HealthStatus = N'Offline',
    @ChangedBy = @OperatorID;

SELECT TOP 5 *
FROM Infrastructure.PointStatusHistory
WHERE PointID = @PointID
ORDER BY ChangedAt DESC;

EXEC Infrastructure.sp_UpdateChargingPointStatus
    @PointID = @PointID,
    @PointStatus = N'Available',
    @HealthStatus = N'Normal',
    @ChangedBy = @OperatorID;

SELECT PointID, PointCode, PointStatus, HealthStatus
FROM Infrastructure.ChargingPoint
WHERE PointID = @PointID;
GO



