==============================================================================
-- 4.2.8 Nhom Stored Procedure bao tri he thong
==============================================================================


==============================================================================
-- Maintenance.sp_ReportError
==============================================================================

--database/05_Create_Stored_Procedures.sql
CREATE OR ALTER PROCEDURE Maintenance.sp_ReportError
    @ErrorCode NVARCHAR(30) = NULL,
    @StationID INT = NULL,
    @PointID INT = NULL,
    @Severity NVARCHAR(20) = N'Medium',
    @Description NVARCHAR(500),
    @CreatedBy INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF @Severity NOT IN (N'Low', N'Medium', N'High', N'Critical')
            THROW 54001, 'Invalid severity.', 1;

        INSERT INTO Maintenance.ErrorLog (ErrorCode, StationID, PointID, Severity, Description)
        VALUES (@ErrorCode, @StationID, @PointID, @Severity, @Description);

        DECLARE @ErrorID BIGINT = SCOPE_IDENTITY();

        INSERT INTO Maintenance.MaintenanceTicket
            (TicketCode, StationID, PointID, ErrorID, CreatedBy, Priority, TicketStatus, Title, Description)
        VALUES
            (N'MT-' + FORMAT(SYSDATETIME(), 'yyyyMMddHHmmss') + N'-' + RIGHT(CONVERT(NVARCHAR(36), NEWID()), 6),
             @StationID, @PointID, @ErrorID, @CreatedBy, @Severity, N'Open', N'Auto ticket from error log', @Description);

        IF @PointID IS NOT NULL
            UPDATE Infrastructure.ChargingPoint SET PointStatus = N'Error', HealthStatus = N'Critical', UpdatedAt = SYSDATETIME()
            WHERE PointID = @PointID;

        COMMIT TRANSACTION;

        SELECT ErrorID, ErrorCode, StationID, PointID, Severity, IsActive
        FROM Maintenance.ErrorLog
        WHERE ErrorID = @ErrorID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- >>> TEST: source kiem thu tinh nang
-- (Trich tu database/features/operations_staff/06_report_error.sql)
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



==============================================================================
-- Maintenance.sp_AssignTicket
==============================================================================

--database/05_Create_Stored_Procedures.sql
CREATE OR ALTER PROCEDURE Maintenance.sp_AssignTicket
    @TicketID BIGINT,
    @AssignedTo INT,
    @AssignedBy INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1 FROM Maintenance.MaintenanceTicket WHERE TicketID = @TicketID AND TicketStatus IN (N'Open', N'Assigned', N'InProgress'))
            THROW 54010, 'Ticket cannot be assigned.', 1;
        IF NOT EXISTS (SELECT 1 FROM [Identity].UserAccount WHERE UserID = @AssignedTo AND AccountStatus = N'Active')
            THROW 54011, 'Assigned user does not exist or is not active.', 1;

        UPDATE Maintenance.MaintenanceTicket
        SET AssignedTo = @AssignedTo,
            TicketStatus = N'Assigned'
        WHERE TicketID = @TicketID;

        INSERT INTO Audit.AuditLog (SchemaName, TableName, RecordID, ActionType, NewValues, ChangedBy)
        VALUES (N'Maintenance', N'MaintenanceTicket', CAST(@TicketID AS NVARCHAR(100)), N'UPDATE', N'Assigned', CAST(@AssignedBy AS NVARCHAR(128)));

        COMMIT TRANSACTION;

        SELECT TicketID, TicketCode, AssignedTo, TicketStatus
        FROM Maintenance.MaintenanceTicket
        WHERE TicketID = @TicketID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- >>> TEST: source kiem thu tinh nang
-- (Trich tu database/features/operations_staff/07_assign_and_close_ticket.sql)
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



==============================================================================
-- Maintenance.sp_ScheduleMaintenance
==============================================================================

--database/05_Create_Stored_Procedures.sql
CREATE OR ALTER PROCEDURE Maintenance.sp_ScheduleMaintenance
    @StationID INT = NULL,
    @PointID INT = NULL,
    @CreatedBy INT,
    @AssignedTo INT = NULL,
    @Priority NVARCHAR(20) = N'Medium',
    @Title NVARCHAR(200),
    @Description NVARCHAR(1000) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF @Priority NOT IN (N'Low', N'Medium', N'High', N'Critical')
            THROW 54012, 'Invalid priority.', 1;
        IF @StationID IS NULL AND @PointID IS NULL
            THROW 54013, 'StationID or PointID is required.', 1;
        IF @PointID IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Infrastructure.ChargingPoint WHERE PointID = @PointID)
            THROW 54014, 'Charging point does not exist.', 1;
        IF @StationID IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Infrastructure.ChargingStation WHERE StationID = @StationID)
            THROW 54015, 'Charging station does not exist.', 1;

        INSERT INTO Maintenance.MaintenanceTicket
            (TicketCode, StationID, PointID, CreatedBy, AssignedTo, Priority, TicketStatus, Title, Description)
        VALUES
            (N'MT-SCH-' + FORMAT(SYSDATETIME(), 'yyyyMMddHHmmss') + N'-' + RIGHT(CONVERT(NVARCHAR(36), NEWID()), 6),
             @StationID, @PointID, @CreatedBy, @AssignedTo, @Priority,
             CASE WHEN @AssignedTo IS NULL THEN N'Open' ELSE N'Assigned' END,
             @Title, @Description);

        DECLARE @TicketID BIGINT = SCOPE_IDENTITY();

        IF @PointID IS NOT NULL
            UPDATE Infrastructure.ChargingPoint
            SET PointStatus = N'Maintenance',
                HealthStatus = CASE WHEN HealthStatus = N'Offline' THEN N'Offline' ELSE N'Warning' END,
                UpdatedAt = SYSDATETIME()
            WHERE PointID = @PointID;

        INSERT INTO Audit.AuditLog (SchemaName, TableName, RecordID, ActionType, NewValues)
        VALUES (N'Maintenance', N'MaintenanceTicket', CAST(@TicketID AS NVARCHAR(100)), N'INSERT', N'Scheduled maintenance');

        COMMIT TRANSACTION;

        SELECT TicketID, TicketCode, StationID, PointID, AssignedTo, Priority, TicketStatus, Title
        FROM Maintenance.MaintenanceTicket
        WHERE TicketID = @TicketID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- >>> TEST: source kiem thu tinh nang
-- (Trich tu database/features/operations_staff/07_assign_and_close_ticket.sql)
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



==============================================================================
-- Maintenance.sp_CloseTicket
==============================================================================

--database/05_Create_Stored_Procedures.sql
CREATE OR ALTER PROCEDURE Maintenance.sp_CloseTicket
    @TicketID BIGINT,
    @ClosedBy INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @PointID INT, @ErrorID BIGINT, @OldStatus NVARCHAR(20);
        SELECT @PointID = PointID, @ErrorID = ErrorID, @OldStatus = TicketStatus
        FROM Maintenance.MaintenanceTicket
        WHERE TicketID = @TicketID;

        IF @OldStatus IS NULL OR @OldStatus IN (N'Closed', N'Cancelled')
            THROW 54020, 'Ticket cannot be closed.', 1;

        UPDATE Maintenance.MaintenanceTicket
        SET TicketStatus = N'Closed', ClosedAt = SYSDATETIME()
        WHERE TicketID = @TicketID;

        IF @ErrorID IS NOT NULL
            UPDATE Maintenance.ErrorLog
            SET IsActive = 0, ResolvedAt = SYSDATETIME(), ResolvedBy = @ClosedBy
            WHERE ErrorID = @ErrorID;

        IF @PointID IS NOT NULL
            UPDATE Infrastructure.ChargingPoint
            SET PointStatus = N'Available', HealthStatus = N'Normal', UpdatedAt = SYSDATETIME()
            WHERE PointID = @PointID;

        COMMIT TRANSACTION;

        SELECT TicketID, TicketStatus, ClosedAt FROM Maintenance.MaintenanceTicket WHERE TicketID = @TicketID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- >>> TEST: source kiem thu tinh nang
-- (Trich tu database/features/operations_staff/07_assign_and_close_ticket.sql)
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
