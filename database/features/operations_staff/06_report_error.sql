USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: bao loi thiet bi va tu dong tao ticket bao tri.
- Tham so co the sua: @PointID, @StationID, @OperatorID, @ErrorCode, @Severity, @Description.
- @Severity hop le: Low, Medium, High, Critical.
- Tac dong du lieu: THEM THAT ErrorLog va MaintenanceTicket; cap nhat cong sang Error/Critical.
*/

PRINT N'Ghi nhận lỗi thiết bị: nhân viên vận hành báo lỗi cổng sạc, hệ thống tạo error log và ticket bảo trì.';

DECLARE @OperatorID INT = (SELECT UserID FROM [Identity].UserAccount WHERE Username = N'operator01');
DECLARE @PointID INT = (SELECT TOP 1 PointID FROM Infrastructure.ChargingPoint WHERE PointStatus = N'Available' ORDER BY PointID DESC);
DECLARE @StationID INT = (SELECT StationID FROM Infrastructure.ChargingPoint WHERE PointID = @PointID);

SELECT PointID, PointCode, PointStatus, HealthStatus
FROM Infrastructure.ChargingPoint
WHERE PointID = @PointID;

EXEC Maintenance.sp_ReportError
    @ErrorCode = N'FEATURE-DEMO-ERR',
    @StationID = @StationID,
    @PointID = @PointID,
    @Severity = N'High',
    @Description = N'FEATURE-DEMO charging point reports high temperature.',
    @CreatedBy = @OperatorID;

SELECT TOP 10 TicketID, TicketCode, StationID, PointID, Priority, TicketStatus, Title
FROM Maintenance.MaintenanceTicket
WHERE PointID = @PointID
ORDER BY TicketID DESC;
GO




