USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: chung minh database chan booking trung lich tren cung cong.
- Tham so co the sua: @UserID, @VehicleID, @PointID, khung gio booking.
- Tac dong du lieu: THEM THAT 1 booking hop le de lam mau; booking trung bi tu choi.
*/

PRINT N'Kiểm thử cổng đã bận: database từ chối booking trùng thời gian trên cùng một cổng sạc.';

DECLARE @UserID INT = (SELECT UserID FROM [Identity].UserAccount WHERE Username = N'customer02');
DECLARE @VehicleID INT = (SELECT TOP 1 VehicleID FROM Operations.Vehicle WHERE UserID = @UserID AND IsActive = 1 ORDER BY VehicleID);
DECLARE @PointID INT = (SELECT TOP 1 PointID FROM AppView.vw_AvailableChargingPoints ORDER BY PointID);
DECLARE @BookedFrom DATETIME2 = DATEADD(MINUTE, (ABS(CHECKSUM(NEWID())) % 100000) + 60, SYSDATETIME());
DECLARE @BookedTo DATETIME2 = DATEADD(HOUR, 1, @BookedFrom);
DECLARE @OverlapFrom DATETIME2 = DATEADD(MINUTE, 30, @BookedFrom);
DECLARE @OverlapTo DATETIME2 = DATEADD(MINUTE, 90, @BookedFrom);

EXEC Operations.sp_CreateBooking
    @UserID = @UserID,
    @VehicleID = @VehicleID,
    @PointID = @PointID,
    @BookedFrom = @BookedFrom,
    @BookedTo = @BookedTo;

BEGIN TRY
    EXEC Operations.sp_CreateBooking
        @UserID = @UserID,
        @VehicleID = @VehicleID,
        @PointID = @PointID,
        @BookedFrom = @OverlapFrom,
        @BookedTo = @OverlapTo;
END TRY
BEGIN CATCH
    PRINT N'Expected error: charging point already has an overlapping booking.';
    SELECT ERROR_MESSAGE() AS ExpectedError;
END CATCH;

SELECT BookingID, BookingCode, PointID, BookedFrom, BookedTo, BookingStatus
FROM Operations.Booking
WHERE PointID = @PointID
  AND BookedFrom < @OverlapTo
  AND BookedTo > @BookedFrom
ORDER BY BookingID;
GO



