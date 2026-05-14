USE EV_Charging_System;
GO

CREATE OR ALTER FUNCTION Operations.fn_CalculateChargingCost
(
    @TotalKWh DECIMAL(14,4),
    @PolicyID INT,
    @StartTime DATETIME2
)
RETURNS DECIMAL(19,4)
AS
BEGIN
    DECLARE @Cost DECIMAL(19,4) = 0;
    DECLARE @BasePrice DECIMAL(19,4);
    DECLARE @Multiplier DECIMAL(5,2);
    DECLARE @PeakStart TIME(0);
    DECLARE @PeakEnd TIME(0);
    DECLARE @CurrentTime TIME(0) = CAST(@StartTime AS TIME(0));

    SELECT @BasePrice = BasePricePerKWh,
           @Multiplier = PeakMultiplier,
           @PeakStart = PeakStartHour,
           @PeakEnd = PeakEndHour
    FROM Operations.PricingPolicy
    WHERE PolicyID = @PolicyID;

    IF @BasePrice IS NULL OR @TotalKWh IS NULL
        RETURN 0;

    SET @Cost = @TotalKWh * @BasePrice;

    IF @PeakStart IS NOT NULL AND @PeakEnd IS NOT NULL
       AND @CurrentTime BETWEEN @PeakStart AND @PeakEnd
        SET @Cost = @Cost * @Multiplier;

    RETURN ROUND(@Cost, 4);
END;
GO

CREATE OR ALTER FUNCTION Franchise.fn_CalculatePartnerShare
(
    @GrossRevenue DECIMAL(19,4),
    @PartnerShareRate DECIMAL(5,2)
)
RETURNS DECIMAL(19,4)
AS
BEGIN
    RETURN ROUND(ISNULL(@GrossRevenue, 0) * ISNULL(@PartnerShareRate, 0) / 100.0, 4);
END;
GO

CREATE OR ALTER FUNCTION Reporting.fn_PointUtilizationRate
(
    @PointID INT,
    @FromDate DATETIME2,
    @ToDate DATETIME2
)
RETURNS DECIMAL(9,4)
AS
BEGIN
    DECLARE @TotalMinutes DECIMAL(18,4) = NULLIF(DATEDIFF(MINUTE, @FromDate, @ToDate), 0);
    DECLARE @ChargingMinutes DECIMAL(18,4);

    SELECT @ChargingMinutes = SUM(ISNULL(DurationMinutes, 0))
    FROM Operations.ChargingSession
    WHERE PointID = @PointID
      AND SessionStatus = N'Completed'
      AND StartTime >= @FromDate
      AND StartTime < @ToDate;

    RETURN ISNULL(ROUND(@ChargingMinutes * 100.0 / @TotalMinutes, 4), 0);
END;
GO

CREATE OR ALTER FUNCTION Payments.fn_RefundableAmount
(
    @OriginalTransactionID BIGINT
)
RETURNS DECIMAL(19,4)
AS
BEGIN
    DECLARE @Original DECIMAL(19,4);
    DECLARE @Refunded DECIMAL(19,4);

    SELECT @Original = Amount
    FROM Payments.PaymentTransaction
    WHERE TransactionID = @OriginalTransactionID
      AND TransactionType = N'ChargingPayment'
      AND TransactionStatus IN (N'Completed', N'Refunded');

    SELECT @Refunded = SUM(Amount)
    FROM Payments.Refund
    WHERE OriginalTransactionID = @OriginalTransactionID
      AND RefundStatus = N'Completed';

    RETURN ISNULL(@Original, 0) - ISNULL(@Refunded, 0);
END;
GO

PRINT N'04 - Functions created.';
GO
