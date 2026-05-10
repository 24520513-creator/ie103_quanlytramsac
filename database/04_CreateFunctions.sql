USE EV_Charging_System;
GO

-- ============================================================
-- fn_IsPeakHour: Check if a given datetime falls in peak hours
-- ============================================================
CREATE OR ALTER FUNCTION dbo.fn_IsPeakHour
(
    @CheckTime DATETIME2,
    @PolicyID  INT
)
RETURNS BIT
AS
BEGIN
    DECLARE @IsPeak BIT = 0;
    DECLARE @PeakStartHour TIME(0), @PeakEndHour TIME(0);
    DECLARE @IsWeekendPeak BIT;

    SELECT @PeakStartHour = PeakStartHour, @PeakEndHour = PeakEndHour, @IsWeekendPeak = IsWeekendPeak
    FROM Operations.PricingPolicy WHERE PolicyID = @PolicyID;

    IF @PeakStartHour IS NULL OR @PeakEndHour IS NULL
        RETURN 0;

    IF @IsWeekendPeak = 0 AND DATEPART(WEEKDAY, @CheckTime) IN (1, 7)
        RETURN 0;

    DECLARE @CheckTimeOnly TIME(0) = CAST(@CheckTime AS TIME(0));

    IF @PeakStartHour < @PeakEndHour
        IF @CheckTimeOnly >= @PeakStartHour AND @CheckTimeOnly < @PeakEndHour
            SET @IsPeak = 1;
    ELSE
        IF @CheckTimeOnly >= @PeakStartHour OR @CheckTimeOnly < @PeakEndHour
            SET @IsPeak = 1;

    RETURN @IsPeak;
END;
GO

-- ============================================================
-- fn_CalculateChargingCost: Calculate total cost for a session
-- ============================================================
CREATE OR ALTER FUNCTION dbo.fn_CalculateChargingCost
(
    @TotalKWh       DECIMAL(13,4),
    @PolicyID       INT,
    @StartTime      DATETIME2
)
RETURNS MONEY
AS
BEGIN
    DECLARE @BasePrice    DECIMAL(19,4);
    DECLARE @Multiplier   DECIMAL(3,2) = 1.0;
    DECLARE @Cost         MONEY;

    SELECT @BasePrice = BasePricePerKWh, @Multiplier = PeakMultiplier
    FROM Operations.PricingPolicy WHERE PolicyID = @PolicyID;

    IF @TotalKWh IS NULL OR @TotalKWh <= 0
        RETURN NULL;

    IF dbo.fn_IsPeakHour(@StartTime, @PolicyID) = 1
        SET @Cost = @TotalKWh * @BasePrice * @Multiplier;
    ELSE
        SET @Cost = @TotalKWh * @BasePrice;

    RETURN @Cost;
END;
GO

-- ============================================================
-- fn_IsPointAvailable: Check if a point is free in a given time range
-- ============================================================
CREATE OR ALTER FUNCTION Operations.fn_IsPointAvailable
(
    @PointID   INT,
    @FromTime  DATETIME2,
    @ToTime    DATETIME2
)
RETURNS BIT
AS
BEGIN
    DECLARE @IsAvailable BIT = 1;

    -- Check if point exists and is active
    IF NOT EXISTS (SELECT 1 FROM Infrastructure.ChargingPoint WHERE PointID = @PointID AND IsActive = 1 AND PointStatus != 'Error' AND PointStatus != 'Offline')
        RETURN 0;

    -- Check overlapping bookings (Pending, Confirmed, Active)
    IF EXISTS (
        SELECT 1 FROM Operations.Booking
        WHERE PointID = @PointID
          AND Status IN (N'Pending', N'Confirmed', N'Active')
          AND BookedFrom < @ToTime
          AND BookedTo > @FromTime
    )
        SET @IsAvailable = 0;

    -- Check overlapping maintenance (Scheduled, InProgress)
    IF EXISTS (
        SELECT 1 FROM Operations.MaintenanceSchedule
        WHERE (PointID = @PointID OR PointID IS NULL)
          AND Status IN (N'Scheduled', N'InProgress')
          AND ScheduledFrom < @ToTime
          AND ScheduledTo > @FromTime
    )
        SET @IsAvailable = 0;

    RETURN @IsAvailable;
END;
GO

-- ============================================================
-- fn_CalculateEstimatedCost: Estimate charging cost for a booking
-- ============================================================
CREATE OR ALTER FUNCTION Operations.fn_CalculateEstimatedCost
(
    @TotalKWh   DECIMAL(13,4),
    @PolicyID   INT,
    @StartTime  DATETIME2
)
RETURNS MONEY
AS
BEGIN
    RETURN dbo.fn_CalculateChargingCost(@TotalKWh, @PolicyID, @StartTime);
END;
GO

-- ============================================================
-- fn_GetStationAverageRating: Get average rating for a station
-- ============================================================
CREATE OR ALTER FUNCTION Operations.fn_GetStationAverageRating
(
    @StationID INT
)
RETURNS DECIMAL(3,2)
AS
BEGIN
    DECLARE @AvgRating DECIMAL(3,2);

    SELECT @AvgRating = CAST(AVG(CAST(Rating AS DECIMAL(3,2))) AS DECIMAL(3,2))
    FROM Operations.StationReview
    WHERE StationID = @StationID;

    RETURN ISNULL(@AvgRating, 0);
END;
GO

-- ============================================================
-- fn_GetUserUnreadNotificationCount
-- ============================================================
CREATE OR ALTER FUNCTION Users.fn_GetUserUnreadNotificationCount
(
    @UserID INT
)
RETURNS INT
AS
BEGIN
    DECLARE @Count INT;

    SELECT @Count = COUNT(*)
    FROM Users.Notification
    WHERE UserID = @UserID AND IsRead = 0;

    RETURN @Count;
END;
GO

PRINT N'6 functions created.';
GO
