USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: tao 1 phien sac dang chay roi danh dau la Failed.
- Tham so co the sua: @UserID, @VehicleID, @PointID, @OperatorID, @StopReason.
- Tac dong du lieu: THEM THAT ChargingSession va SessionEvent; cap nhat SessionStatus sang Failed.
*/

PRINT N'Xử lý phiên sạc lỗi: nhân viên vận hành đánh dấu phiên đang sạc thành thất bại và giải phóng cổng.';

DECLARE @UserID INT = (SELECT UserID FROM [Identity].UserAccount WHERE Username = N'customer02');
DECLARE @VehicleID INT = (SELECT TOP 1 VehicleID FROM Operations.Vehicle WHERE UserID = @UserID AND IsActive = 1 ORDER BY VehicleID);
DECLARE @PointID INT = (SELECT TOP 1 PointID FROM AppView.vw_AvailableChargingPoints ORDER BY PointID);
DECLARE @OperatorID INT = (SELECT UserID FROM [Identity].UserAccount WHERE Username = N'operator01');
DECLARE @Started TABLE (SessionID BIGINT, SessionCode NVARCHAR(40), UserID INT, StationID INT, PointID INT, SessionStatus NVARCHAR(30), StartTime DATETIME2);
DECLARE @SessionID BIGINT;

INSERT INTO @Started
EXEC Operations.sp_StartChargingSession @UserID = @UserID, @VehicleID = @VehicleID, @PointID = @PointID, @MeterStart = 3000.00;

SELECT @SessionID = SessionID FROM @Started;

SELECT *
FROM AppView.vw_ActiveChargingSessions
WHERE SessionID = @SessionID;

EXEC Operations.sp_MarkChargingSessionFailed
    @SessionID = @SessionID,
    @FailedBy = @OperatorID,
    @StopReason = N'FEATURE-DEMO-Connector fault';

SELECT SessionID, SessionCode, SessionStatus, StopReason, EndTime
FROM Operations.ChargingSession
WHERE SessionID = @SessionID;
GO




