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

    -- Check if weekend and weekend peak is disabled
    IF @IsWeekendPeak = 0 AND DATEPART(WEEKDAY, @CheckTime) IN (1, 7)
        RETURN 0;

    DECLARE @CheckTimeOnly TIME(0) = CAST(@CheckTime AS TIME(0));

    IF @PeakStartHour < @PeakEndHour
        -- Normal range: e.g. 17:00 - 19:00
        IF @CheckTimeOnly >= @PeakStartHour AND @CheckTimeOnly < @PeakEndHour
            SET @IsPeak = 1;
    ELSE
        -- Overnight range: e.g. 22:00 - 05:00
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

PRINT N'Functions created.';
GO
