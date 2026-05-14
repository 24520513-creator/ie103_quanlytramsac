USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: cap nhat trang thai tram de demo van hanh.
- Tham so co the sua: @StationID, @StationStatus, @OperatorID.
- Trang thai hop le: Active, Inactive, UnderMaintenance, Retired.
- Tac dong du lieu: SUA THAT ChargingStation; script doi sang UnderMaintenance roi doi lai Active.
*/

PRINT N'Cập nhật trạng thái trạm: nhân viên vận hành chuyển trạng thái trạm và ghi nhận thay đổi vào audit.';

DECLARE @StationID INT = (SELECT TOP 1 StationID FROM Infrastructure.ChargingStation WHERE StationStatus = N'Active' ORDER BY StationID);
DECLARE @OperatorID INT = (SELECT UserID FROM [Identity].UserAccount WHERE Username = N'operator01');

SELECT StationID, StationCode, StationName, StationStatus
FROM Infrastructure.ChargingStation
WHERE StationID = @StationID;

EXEC Infrastructure.sp_UpdateStationStatus
    @StationID = @StationID,
    @StationStatus = N'UnderMaintenance',
    @ChangedBy = @OperatorID;

SELECT StationID, StationCode, StationName, StationStatus
FROM Infrastructure.ChargingStation
WHERE StationID = @StationID;

EXEC Infrastructure.sp_UpdateStationStatus
    @StationID = @StationID,
    @StationStatus = N'Active',
    @ChangedBy = @OperatorID;
GO



