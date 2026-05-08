/*==============================================================================
  EV_Charging_System_Validation - ENTERPRISE FUNCTIONS
  =============================================================================*/

USE EV_Charging_System_Validation;
GO

-- ===========================================================================
-- fn_CalculateChargingCost - Multi-rule pricing engine
-- ===========================================================================
CREATE OR ALTER FUNCTION Operations.fn_CalculateChargingCost
(
    @TotalKWh           DECIMAL(13,4),
    @BasePricePerKWh    DECIMAL(19,4),
    @DiscountPercent    DECIMAL(5,2),
    @StartTime          DATETIME2
)
RETURNS MONEY
AS
BEGIN
    DECLARE @Cost MONEY;
    DECLARE @EffectivePrice DECIMAL(19,4);
    DECLARE @Hour INT = DATEPART(HOUR, @StartTime);
    DECLARE @DayOfWeek INT = DATEPART(WEEKDAY, @StartTime);
    DECLARE @Multiplier DECIMAL(3,2) = 1.00;

    -- Peak hour detection (17:00-19:00 weekdays)
    IF @Hour BETWEEN 17 AND 18 AND @DayOfWeek BETWEEN 2 AND 6
        SET @Multiplier = 1.50;
    -- Off-peak (22:00-05:00)
    ELSE IF @Hour >= 22 OR @Hour < 5
        SET @Multiplier = 0.70;

    IF @TotalKWh IS NULL OR @TotalKWh <= 0
        RETURN 0;

    SET @EffectivePrice = @BasePricePerKWh * @Multiplier;
    SET @EffectivePrice = @EffectivePrice * (1 - ISNULL(@DiscountPercent, 0) / 100);
    SET @Cost = CAST(@TotalKWh * @EffectivePrice AS MONEY);

    RETURN @Cost;
END;
GO

-- ===========================================================================
-- fn_GetStationUtilizationRate - Station utilization percentage
-- ===========================================================================
CREATE OR ALTER FUNCTION Reporting.fn_GetStationUtilizationRate
(
    @StationID INT,
    @FromDate  DATE,
    @ToDate    DATE
)
RETURNS DECIMAL(5,2)
AS
BEGIN
    DECLARE @Utilization DECIMAL(5,2);
    DECLARE @TotalMinutes INT;
    DECLARE @BusyMinutes INT;

    SET @TotalMinutes = DATEDIFF(MINUTE, @FromDate, @ToDate);

    SELECT @BusyMinutes = ISNULL(SUM(
        DATEDIFF(MINUTE,
            CASE WHEN StartTime < @FromDate THEN @FromDate ELSE StartTime END,
            CASE WHEN ISNULL(EndTime, SYSDATETIME()) > @ToDate THEN @ToDate ELSE ISNULL(EndTime, SYSDATETIME()) END
        )
    ), 0)
    FROM Operations.ChargingSession
    WHERE StationID = @StationID
      AND StartTime < ISNULL(EndTime, SYSDATETIME())
      AND StartTime < @ToDate
      AND ISNULL(EndTime, SYSDATETIME()) > @FromDate
      AND IsDeleted = 0;

    SET @Utilization = CASE WHEN @TotalMinutes > 0
        THEN CAST(@BusyMinutes AS DECIMAL(10,2)) / @TotalMinutes * 100
        ELSE 0 END;

    RETURN @Utilization;
END;
GO

-- ===========================================================================
-- fn_GetEffectivePrice - Returns effective price with all rules applied
-- ===========================================================================
CREATE OR ALTER FUNCTION Operations.fn_GetEffectivePrice
(
    @PolicyID   INT,
    @RegionID   INT,
    @StartTime  DATETIME2,
    @TotalKWh   DECIMAL(13,4)
)
RETURNS DECIMAL(19,4)
AS
BEGIN
    DECLARE @BasePrice DECIMAL(19,4);
    DECLARE @EffectivePrice DECIMAL(19,4);
    DECLARE @Hour INT = DATEPART(HOUR, @StartTime);
    DECLARE @DayOfWeek INT = DATEPART(WEEKDAY, @StartTime);

    SELECT @BasePrice = BasePricePerKWh
    FROM Operations.PricingPolicy
    WHERE PolicyID = @PolicyID AND IsActive = 1;

    SET @EffectivePrice = @BasePrice;

    -- Apply pricing rules sorted by priority
    SELECT @EffectivePrice = CASE pr.AdjustmentType
        WHEN N'Multiplier' THEN @EffectivePrice * pr.AdjustmentValue
        WHEN N'FixedDiscount' THEN @EffectivePrice - pr.AdjustmentValue
        WHEN N'PercentageDiscount' THEN @EffectivePrice * (1 - pr.AdjustmentValue / 100)
        WHEN N'FixedPrice' THEN pr.AdjustmentValue
        ELSE @EffectivePrice
    END
    FROM Operations.PricingRule pr
    WHERE pr.PolicyID = @PolicyID AND pr.IsActive = 1
    ORDER BY pr.Priority ASC;

    RETURN CASE WHEN @EffectivePrice < 0 THEN 0 ELSE @EffectivePrice END;
END;
GO

-- ===========================================================================
-- fn_GetFranchiseCommission - Calculate commission for a franchise
-- ===========================================================================
CREATE OR ALTER FUNCTION Reporting.fn_GetFranchiseCommission
(
    @FranchiseID INT,
    @FromDate    DATE,
    @ToDate      DATE
)
RETURNS MONEY
AS
BEGIN
    DECLARE @Commission MONEY;

    SELECT @Commission = ISNULL(SUM(cs.CostTotal * f.RevenueShareRate / 100), 0)
    FROM Operations.ChargingSession cs
    JOIN Infrastructure.ChargingStation s ON cs.StationID = s.StationID
    JOIN Infrastructure.Franchise f ON s.FranchiseID = f.FranchiseID
    WHERE f.FranchiseID = @FranchiseID
      AND cs.SessionStatus = N'Completed'
      AND cs.StartTime >= @FromDate
      AND cs.EndTime <= @ToDate
      AND cs.IsDeleted = 0;

    RETURN @Commission;
END;
GO

PRINT N'Enterprise functions created successfully.';
GO

