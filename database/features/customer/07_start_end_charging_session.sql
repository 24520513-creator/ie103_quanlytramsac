USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: tao phien sac moi, sau do ket thuc phien va tinh tien.
- Tham so co the sua: @UserID, @VehicleID, @PointID, @MeterStart, @MeterEnd.
- @MeterEnd phai lon hon hoac bang @MeterStart.
- Tac dong du lieu: THEM THAT ChargingSession va SessionEvent; cap nhat trang thai ChargingPoint trong luc chay roi tra ve Available.
*/

PRINT N'Bắt đầu và kết thúc phiên sạc: khách hàng mở phiên sạc, kết thúc phiên và hệ thống tính kWh, chi phí.';

DECLARE @UserID INT = (SELECT UserID FROM [Identity].UserAccount WHERE Username = N'customer01');
DECLARE @VehicleID INT = (SELECT TOP 1 VehicleID FROM Operations.Vehicle WHERE UserID = @UserID AND IsActive = 1 ORDER BY VehicleID DESC);
DECLARE @PointID INT = (SELECT TOP 1 PointID FROM AppView.vw_AvailableChargingPoints ORDER BY PointID);
DECLARE @Started TABLE (SessionID BIGINT, SessionCode NVARCHAR(40), UserID INT, StationID INT, PointID INT, SessionStatus NVARCHAR(30), StartTime DATETIME2);
DECLARE @SessionID BIGINT;

SELECT TOP 5 *
FROM AppView.vw_ActiveChargingSessions
ORDER BY StartTime DESC;

INSERT INTO @Started
EXEC Operations.sp_StartChargingSession
    @UserID = @UserID,
    @VehicleID = @VehicleID,
    @PointID = @PointID,
    @MeterStart = 1000.00;

SELECT @SessionID = SessionID FROM @Started;
SELECT * FROM @Started;

EXEC Operations.sp_EndChargingSession
    @SessionID = @SessionID,
    @MeterEnd = 1022.50;

SELECT TOP 10 *
FROM AppView.vw_CustomerChargingHistory
WHERE UserID = @UserID
ORDER BY StartTime DESC;
GO




