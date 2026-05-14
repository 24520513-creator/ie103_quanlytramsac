USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: chung minh database chan ket thuc lai session da Completed.
- Tham so co the sua: @UserID, @VehicleID, @PointID, meter values.
- Tac dong du lieu: THEM THAT 1 session completed; lan ket thuc thu hai bi tu choi.
*/

PRINT N'Kiểm thử kết thúc phiên nhiều lần: database từ chối kết thúc lại phiên sạc đã hoàn tất.';

DECLARE @UserID INT = (SELECT UserID FROM [Identity].UserAccount WHERE Username = N'customer03');
DECLARE @VehicleID INT = (SELECT TOP 1 VehicleID FROM Operations.Vehicle WHERE UserID = @UserID AND IsActive = 1 ORDER BY VehicleID);
DECLARE @PointID INT = (SELECT TOP 1 PointID FROM AppView.vw_AvailableChargingPoints ORDER BY PointID);
DECLARE @Started TABLE (SessionID BIGINT, SessionCode NVARCHAR(40), UserID INT, StationID INT, PointID INT, SessionStatus NVARCHAR(30), StartTime DATETIME2);
DECLARE @SessionID BIGINT;

INSERT INTO @Started
EXEC Operations.sp_StartChargingSession @UserID = @UserID, @VehicleID = @VehicleID, @PointID = @PointID, @MeterStart = 4000.00;

SELECT @SessionID = SessionID FROM @Started;

EXEC Operations.sp_EndChargingSession @SessionID = @SessionID, @MeterEnd = 4010.00;

BEGIN TRY
    EXEC Operations.sp_EndChargingSession @SessionID = @SessionID, @MeterEnd = 4012.00;
END TRY
BEGIN CATCH
    PRINT N'Expected error: completed session cannot be ended again.';
    SELECT ERROR_MESSAGE() AS ExpectedError;
END CATCH;

SELECT SessionID, SessionCode, SessionStatus, MeterStart, MeterEnd, TotalKWh
FROM Operations.ChargingSession
WHERE SessionID = @SessionID;
GO




