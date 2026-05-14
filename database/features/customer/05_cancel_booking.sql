USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: huy booking con hieu luc cua customer01.
- Tham so co the sua: @UserID, @BookingID.
- Neu khong co booking de huy, script tu tao 1 booking demo roi huy booking do.
- Tac dong du lieu: KHONG XOA VAT LY; chi doi BookingStatus sang Cancelled.
*/

PRINT N'Hủy lịch đặt sạc: khách hàng hủy booking còn hiệu lực và kiểm tra trạng thái sau khi hủy.';

DECLARE @UserID INT = (SELECT UserID FROM [Identity].UserAccount WHERE Username = N'customer01');
DECLARE @BookingID BIGINT = (
    SELECT TOP 1 BookingID
    FROM Operations.Booking
    WHERE UserID = @UserID AND BookingStatus IN (N'Pending', N'Confirmed', N'Active')
    ORDER BY BookingID DESC
);

IF @BookingID IS NULL
BEGIN
    DECLARE @VehicleID INT = (SELECT TOP 1 VehicleID FROM Operations.Vehicle WHERE UserID = @UserID AND IsActive = 1 ORDER BY VehicleID DESC);
    DECLARE @PointID INT = (SELECT TOP 1 PointID FROM AppView.vw_AvailableChargingPoints ORDER BY PointID);
    DECLARE @BookedFrom DATETIME2 = DATEADD(MINUTE, (ABS(CHECKSUM(NEWID())) % 100000) + 60, SYSDATETIME());
    DECLARE @BookedTo DATETIME2 = DATEADD(HOUR, 1, @BookedFrom);
    DECLARE @Created TABLE (BookingID BIGINT, BookingCode NVARCHAR(40), UserID INT, VehicleID INT, StationID INT, PointID INT, BookedFrom DATETIME2, BookedTo DATETIME2, BookingStatus NVARCHAR(20));

    INSERT INTO @Created
    EXEC Operations.sp_CreateBooking
        @UserID = @UserID,
        @VehicleID = @VehicleID,
        @PointID = @PointID,
        @BookedFrom = @BookedFrom,
        @BookedTo = @BookedTo;

    SELECT @BookingID = BookingID FROM @Created;
END;

SELECT *
FROM AppView.vw_CustomerBookingHistory
WHERE BookingID = @BookingID;

EXEC Operations.sp_CancelBooking
    @BookingID = @BookingID,
    @UserID = @UserID;

SELECT *
FROM AppView.vw_CustomerBookingHistory
WHERE BookingID = @BookingID;
GO



