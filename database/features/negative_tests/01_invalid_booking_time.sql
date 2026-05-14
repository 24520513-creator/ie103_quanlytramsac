USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: chung minh database chan booking sai thoi gian.
- Tham so co the sua: @UserID, @VehicleID, @PointID, @BookedFrom, @BookedTo.
- Tac dong du lieu: KHONG THEM DU LIEU khi loi dung ky vong xay ra.
*/

PRINT N'Kiểm thử lỗi thời gian đặt sạc: database từ chối booking có thời gian bắt đầu không nhỏ hơn thời gian kết thúc.';

DECLARE @UserID INT = (SELECT UserID FROM [Identity].UserAccount WHERE Username = N'customer01');
DECLARE @VehicleID INT = (SELECT TOP 1 VehicleID FROM Operations.Vehicle WHERE UserID = @UserID AND IsActive = 1 ORDER BY VehicleID DESC);
DECLARE @PointID INT = (SELECT TOP 1 PointID FROM AppView.vw_AvailableChargingPoints ORDER BY PointID);
DECLARE @BeforeCount INT = (SELECT COUNT(*) FROM Operations.Booking WHERE UserID = @UserID);

SELECT @BeforeCount AS BookingCountBefore;

BEGIN TRY
    EXEC Operations.sp_CreateBooking
        @UserID = @UserID,
        @VehicleID = @VehicleID,
        @PointID = @PointID,
        @BookedFrom = '2026-06-02 10:00:00',
        @BookedTo = '2026-06-02 09:00:00';
END TRY
BEGIN CATCH
    PRINT N'Expected error: invalid booking time.';
    SELECT ERROR_MESSAGE() AS ExpectedError;
END CATCH;

SELECT @BeforeCount AS BookingCountBefore,
       COUNT(*) AS BookingCountAfter
FROM Operations.Booking
WHERE UserID = @UserID;
GO




