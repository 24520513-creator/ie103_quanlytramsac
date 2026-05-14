USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: tao lich dat sac cho customer01.
- Tham so co the sua: @UserID, @VehicleID, @PointID, @BookedFrom, @BookedTo.
- @BookedFrom phai nho hon @BookedTo; @PointID khong duoc co booking trung gio.
- Tac dong du lieu: THEM THAT 1 dong vao Operations.Booking voi trang thai Confirmed.
*/

PRINT N'Tạo lịch đặt sạc: khách hàng đặt trước cổng sạc theo khoảng thời gian hợp lệ.';

DECLARE @UserID INT = (SELECT UserID FROM [Identity].UserAccount WHERE Username = N'customer01');
DECLARE @VehicleID INT = (SELECT TOP 1 VehicleID FROM Operations.Vehicle WHERE UserID = @UserID AND IsActive = 1 ORDER BY VehicleID DESC);
DECLARE @PointID INT = (SELECT TOP 1 PointID FROM AppView.vw_AvailableChargingPoints ORDER BY PointID);
DECLARE @BookedFrom DATETIME2 = DATEADD(MINUTE, (ABS(CHECKSUM(NEWID())) % 100000) + 60, SYSDATETIME());
DECLARE @BookedTo DATETIME2 = DATEADD(HOUR, 1, @BookedFrom);

SELECT TOP 10 *
FROM AppView.vw_CustomerBookingHistory
WHERE UserID = @UserID
ORDER BY CreatedAt DESC;

EXEC Operations.sp_CreateBooking
    @UserID = @UserID,
    @VehicleID = @VehicleID,
    @PointID = @PointID,
    @BookedFrom = @BookedFrom,
    @BookedTo = @BookedTo;

SELECT TOP 10 *
FROM AppView.vw_CustomerBookingHistory
WHERE UserID = @UserID
ORDER BY CreatedAt DESC;
GO



