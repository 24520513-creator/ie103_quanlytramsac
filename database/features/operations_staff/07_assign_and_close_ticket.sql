USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: lap lich bao tri, phan cong va dong ticket.
- Tham so co the sua: @PointID, @StationID, @OperatorID, @Priority, @Title, @Description.
- Tac dong du lieu: THEM THAT MaintenanceTicket; sau do cap nhat Assigned va Closed.
*/

PRINT N'Quản lý ticket bảo trì: nhân viên vận hành lập lịch, phân công và đóng ticket bảo trì.';

DECLARE @OperatorID INT = (SELECT UserID FROM [Identity].UserAccount WHERE Username = N'operator01');
DECLARE @PointID INT = (SELECT TOP 1 PointID FROM Infrastructure.ChargingPoint WHERE PointStatus = N'Available' ORDER BY PointID DESC);
DECLARE @StationID INT = (SELECT StationID FROM Infrastructure.ChargingPoint WHERE PointID = @PointID);
DECLARE @Scheduled TABLE (TicketID BIGINT, TicketCode NVARCHAR(40), StationID INT, PointID INT, AssignedTo INT, Priority NVARCHAR(20), TicketStatus NVARCHAR(20), Title NVARCHAR(200));
DECLARE @TicketID BIGINT;

SELECT TOP 5 TicketID, TicketCode, TicketStatus, AssignedTo
FROM Maintenance.MaintenanceTicket
ORDER BY TicketID DESC;

INSERT INTO @Scheduled
EXEC Maintenance.sp_ScheduleMaintenance
    @StationID = @StationID,
    @PointID = @PointID,
    @CreatedBy = @OperatorID,
    @AssignedTo = NULL,
    @Priority = N'Medium',
    @Title = N'FEATURE-DEMO scheduled inspection',
    @Description = N'FEATURE-DEMO planned maintenance demo.';

SELECT @TicketID = TicketID FROM @Scheduled;

EXEC Maintenance.sp_AssignTicket
    @TicketID = @TicketID,
    @AssignedTo = @OperatorID,
    @AssignedBy = @OperatorID;

EXEC Maintenance.sp_CloseTicket
    @TicketID = @TicketID,
    @ClosedBy = @OperatorID;

SELECT TicketID, TicketCode, TicketStatus, AssignedTo, ClosedAt
FROM Maintenance.MaintenanceTicket
WHERE TicketID = @TicketID;
GO



