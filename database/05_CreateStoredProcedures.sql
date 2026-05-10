USE EV_Charging_System;
GO

-- ============================================================
-- sp_StartChargingSession (MODIFIED: added @BookingID)
-- ============================================================
CREATE OR ALTER PROCEDURE Operations.sp_StartChargingSession
    @UserID        INT,
    @VehicleID     INT = NULL,
    @PointID       INT,
    @BookingID     INT = NULL,      -- NEW
    @StartBatteryPercent DECIMAL(5,2) = NULL,
    @MeterStart    DECIMAL(13,4) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @TranCount INT = @@TRANCOUNT;

    BEGIN TRY
        IF @TranCount = 0 BEGIN TRANSACTION;

        DECLARE @PointStatus NVARCHAR(20), @StationID INT, @ConnectorType NVARCHAR(30);
        SELECT @PointStatus = PointStatus, @StationID = StationID, @ConnectorType = ConnectorType
        FROM Infrastructure.ChargingPoint WHERE PointID = @PointID AND IsActive = 1;

        IF @PointStatus IS NULL
            EXEC dbo.sp_ThrowError 50001;
        IF @PointStatus != 'Available'
            EXEC dbo.sp_ThrowError 50002;

        IF NOT EXISTS (SELECT 1 FROM Users.[User] WHERE UserID = @UserID AND AccountStatus = 'Active')
            EXEC dbo.sp_ThrowError 50003;

        IF NOT EXISTS (SELECT 1 FROM Infrastructure.ChargingStation WHERE StationID = @StationID AND StationStatus = 'Active' AND IsActive = 1)
            EXEC dbo.sp_ThrowError 50004;

        DECLARE @PolicyID INT;
        SELECT TOP 1 @PolicyID = PolicyID
        FROM Operations.PricingPolicy
        WHERE IsActive = 1 AND AppliedFrom <= SYSDATETIME() AND (AppliedTo IS NULL OR AppliedTo >= SYSDATETIME())
        ORDER BY PolicyID;

        IF @PolicyID IS NULL
            EXEC dbo.sp_ThrowError 50005;

        -- If BookingID provided, validate and confirm booking
        IF @BookingID IS NOT NULL
        BEGIN
            DECLARE @BookingStatus NVARCHAR(20);
            SELECT @BookingStatus = Status FROM Operations.Booking WHERE BookingID = @BookingID;
            IF @BookingStatus IS NULL
                EXEC dbo.sp_ThrowError 50031;
            IF @BookingStatus NOT IN (N'Pending', N'Confirmed')
                EXEC dbo.sp_ThrowError 50032;

            UPDATE Operations.Booking SET Status = N'Active', UpdatedAt = SYSDATETIME()
            WHERE BookingID = @BookingID;
        END;

        DECLARE @SessionCode NVARCHAR(30) = 'SES-' + FORMAT(SYSDATETIME(), 'yyyyMMdd') + '-' + LEFT(CAST(NEWID() AS NVARCHAR(36)), 6);

        DECLARE @SessionID BIGINT;
        INSERT INTO Operations.ChargingSession (SessionCode, UserID, VehicleID, PointID, StationID, PolicyID, BookingID,
            StartTime, StartBatteryPercent, MeterStart, SessionStatus)
        VALUES (@SessionCode, @UserID, @VehicleID, @PointID, @StationID, @PolicyID, @BookingID,
            SYSDATETIME(), @StartBatteryPercent, @MeterStart, 'Charging');

        SET @SessionID = SCOPE_IDENTITY();

        UPDATE Infrastructure.ChargingPoint SET PointStatus = 'Busy', UpdatedAt = SYSDATETIME() WHERE PointID = @PointID;

        IF @TranCount = 0 COMMIT TRANSACTION;

        SELECT * FROM Operations.ChargingSession WHERE SessionID = @SessionID;
    END TRY
    BEGIN CATCH
        IF @TranCount = 0 AND @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- ============================================================
-- sp_EndChargingSession (MODIFIED: added notification)
-- ============================================================
CREATE OR ALTER PROCEDURE Operations.sp_EndChargingSession
    @SessionID            BIGINT,
    @EndBatteryPercent    DECIMAL(5,2) = NULL,
    @MeterEnd             DECIMAL(13,4) = NULL,
    @TotalKWh             DECIMAL(13,4) = NULL,
    @StopReason           NVARCHAR(50) = 'Completed'
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @TranCount INT = @@TRANCOUNT;

    BEGIN TRY
        IF @TranCount = 0 BEGIN TRANSACTION;

        DECLARE @CurrentStatus NVARCHAR(20), @PointID INT, @PolicyID INT, @StartTime DATETIME2,
                @UserID INT, @StationID INT, @CostTotal MONEY;

        SELECT @CurrentStatus = SessionStatus, @PointID = PointID, @PolicyID = PolicyID,
               @StartTime = StartTime, @UserID = UserID, @StationID = StationID
        FROM Operations.ChargingSession WHERE SessionID = @SessionID;

        IF @CurrentStatus IS NULL
            EXEC dbo.sp_ThrowError 50010;
        IF @CurrentStatus != 'Charging'
            EXEC dbo.sp_ThrowError 50011;

        DECLARE @DurationMinutes INT = DATEDIFF(MINUTE, @StartTime, SYSDATETIME());

        DECLARE @CalculatedCost MONEY;
        IF @TotalKWh IS NOT NULL AND @TotalKWh > 0
            SET @CalculatedCost = dbo.fn_CalculateChargingCost(@TotalKWh, @PolicyID, @StartTime);
        ELSE IF @MeterEnd IS NOT NULL
        BEGIN
            DECLARE @MeterStart DECIMAL(13,4);
            SELECT @MeterStart = MeterStart FROM Operations.ChargingSession WHERE SessionID = @SessionID;
            IF @MeterStart IS NOT NULL
            BEGIN
                SET @TotalKWh = @MeterEnd - @MeterStart;
                SET @CalculatedCost = dbo.fn_CalculateChargingCost(@TotalKWh, @PolicyID, @StartTime);
            END;
        END;

        SET @CostTotal = @CalculatedCost;

        UPDATE Operations.ChargingSession SET
            EndTime = SYSDATETIME(),
            EndBatteryPercent = @EndBatteryPercent,
            MeterEnd = @MeterEnd,
            TotalKWh = @TotalKWh,
            ChargingDurationMinutes = @DurationMinutes,
            CostTotal = @CostTotal,
            StopReason = @StopReason,
            SessionStatus = 'Completed',
            UpdatedAt = SYSDATETIME()
        WHERE SessionID = @SessionID;

        UPDATE Infrastructure.ChargingPoint SET PointStatus = 'Available', UpdatedAt = SYSDATETIME() WHERE PointID = @PointID;

        -- Update related booking if exists
        DECLARE @BookingID INT;
        SELECT @BookingID = BookingID FROM Operations.ChargingSession WHERE SessionID = @SessionID;
        IF @BookingID IS NOT NULL
        BEGIN
            UPDATE Operations.Booking SET Status = N'Completed', UpdatedAt = SYSDATETIME()
            WHERE BookingID = @BookingID;
        END;

        -- Create notification for completed session
        DECLARE @StationName NVARCHAR(200);
        SELECT @StationName = StationName FROM Infrastructure.ChargingStation WHERE StationID = @StationID;

        INSERT INTO Users.Notification (UserID, Title, Body, Type, ReferenceType, ReferenceID, CreatedAt)
        VALUES (@UserID, N'Phiên sạc hoàn thành',
            N'Phiên sạc tại ' + ISNULL(@StationName, N'') + N' đã hoàn thành. ' +
            N'KWh: ' + ISNULL(CAST(@TotalKWh AS NVARCHAR(20)), N'0') +
            N', Chi phí: ' + ISNULL(CAST(@CostTotal AS NVARCHAR(20)), N'0') + N' VND',
            'ChargingComplete', 'Session', @SessionID, SYSDATETIME());

        IF @TranCount = 0 COMMIT TRANSACTION;

        SELECT * FROM Operations.ChargingSession WHERE SessionID = @SessionID;
    END TRY
    BEGIN CATCH
        IF @TranCount = 0 AND @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- ============================================================
-- sp_CreatePayment (unchanged)
-- ============================================================
CREATE OR ALTER PROCEDURE Payments.sp_CreatePayment
    @UserID         INT,
    @SessionID      BIGINT,
    @PaymentMethod  NVARCHAR(30) = 'Wallet'
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @TranCount INT = @@TRANCOUNT;

    BEGIN TRY
        IF @TranCount = 0 BEGIN TRANSACTION;

        DECLARE @SessionStatus NVARCHAR(20), @CostTotal MONEY, @SessionUserID INT;
        SELECT @SessionStatus = SessionStatus, @CostTotal = CostTotal, @SessionUserID = UserID
        FROM Operations.ChargingSession WHERE SessionID = @SessionID;

        IF @SessionStatus IS NULL
            EXEC dbo.sp_ThrowError 50020;
        IF @SessionStatus != 'Completed'
            EXEC dbo.sp_ThrowError 50021;
        IF @SessionUserID != @UserID
            EXEC dbo.sp_ThrowError 50022;
        IF @CostTotal IS NULL OR @CostTotal <= 0
            EXEC dbo.sp_ThrowError 50023;

        IF EXISTS (SELECT 1 FROM Payments.[Transaction] WHERE SessionID = @SessionID AND TransactionStatus = 'Completed')
            EXEC dbo.sp_ThrowError 50024;

        DECLARE @TxnCode NVARCHAR(30) = 'TXN-' + FORMAT(SYSDATETIME(), 'yyyyMMdd') + '-' + LEFT(CAST(NEWID() AS NVARCHAR(36)), 6);

        DECLARE @TxnID BIGINT;
        INSERT INTO Payments.[Transaction] (TransactionCode, UserID, SessionID, TransactionType, Direction, Amount, TransactionStatus, PaymentMethod)
        VALUES (@TxnCode, @UserID, @SessionID, 'ChargingPayment', 'D', @CostTotal, 'Pending', @PaymentMethod);

        SET @TxnID = SCOPE_IDENTITY();

        IF @PaymentMethod = 'Wallet'
        BEGIN
            DECLARE @WalletID INT, @Balance MONEY;
            SELECT @WalletID = WalletID, @Balance = Balance
            FROM Payments.Wallet WHERE UserID = @UserID AND IsActive = 1;

            IF @WalletID IS NULL
                EXEC dbo.sp_ThrowError 50025;
            IF @Balance < @CostTotal
            BEGIN
                UPDATE Payments.[Transaction] SET TransactionStatus = 'Failed' WHERE TransactionID = @TxnID;
                EXEC dbo.sp_ThrowError 50026;
            END;

            UPDATE Payments.Wallet SET Balance = Balance - @CostTotal, LastTransactionAt = SYSDATETIME() WHERE WalletID = @WalletID;

            INSERT INTO Payments.WalletTransaction (WalletID, TransactionID, Amount, BalanceBefore, Direction, TransactionType)
            VALUES (@WalletID, @TxnID, -@CostTotal, @Balance, 'D', 'ChargingPayment');

            UPDATE Payments.[Transaction] SET TransactionStatus = 'Completed', SettledAt = SYSDATETIME() WHERE TransactionID = @TxnID;
        END;

        IF @TranCount = 0 COMMIT TRANSACTION;

        SELECT * FROM Payments.[Transaction] WHERE TransactionID = @TxnID;
    END TRY
    BEGIN CATCH
        IF @TranCount = 0 AND @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- ============================================================
-- sp_CreateBooking (NEW)
-- ============================================================
CREATE OR ALTER PROCEDURE Operations.sp_CreateBooking
    @UserID     INT,
    @PointID    INT,
    @VehicleID  INT = NULL,
    @BookedFrom DATETIME2,
    @BookedTo   DATETIME2
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @TranCount INT = @@TRANCOUNT;

    BEGIN TRY
        IF @TranCount = 0 BEGIN TRANSACTION;

        IF @BookedFrom >= @BookedTo
            THROW 50050, 'BookedFrom must be earlier than BookedTo', 1;

        IF NOT EXISTS (SELECT 1 FROM Users.[User] WHERE UserID = @UserID AND AccountStatus = 'Active')
            EXEC dbo.sp_ThrowError 50003;

        DECLARE @StationID INT, @PointStatus NVARCHAR(20);
        SELECT @StationID = StationID, @PointStatus = PointStatus
        FROM Infrastructure.ChargingPoint WHERE PointID = @PointID AND IsActive = 1;

        IF @PointStatus IS NULL
            EXEC dbo.sp_ThrowError 50001;

        IF Operations.fn_IsPointAvailable(@PointID, @BookedFrom, @BookedTo) = 0
            EXEC dbo.sp_ThrowError 50030;

        DECLARE @BookingCode NVARCHAR(30) = 'BOK-' + FORMAT(SYSDATETIME(), 'yyyyMMdd') + '-' + LEFT(CAST(NEWID() AS NVARCHAR(36)), 6);

        INSERT INTO Operations.Booking (BookingCode, UserID, PointID, StationID, VehicleID, BookedFrom, BookedTo, Status)
        VALUES (@BookingCode, @UserID, @PointID, @StationID, @VehicleID, @BookedFrom, @BookedTo, N'Pending');

        DECLARE @BookingID INT = SCOPE_IDENTITY();

        -- Create notification
        INSERT INTO Users.Notification (UserID, Title, Body, Type, ReferenceType, ReferenceID, CreatedAt)
        VALUES (@UserID, N'Đặt lịch sạc thành công',
            N'Mã đặt lịch: ' + @BookingCode + N'. Thời gian: ' +
            FORMAT(@BookedFrom, 'dd/MM/yyyy HH:mm') + N' - ' + FORMAT(@BookedTo, 'HH:mm') + N'.',
            'Booking', 'Booking', @BookingID, SYSDATETIME());

        IF @TranCount = 0 COMMIT TRANSACTION;

        SELECT * FROM Operations.Booking WHERE BookingID = @BookingID;
    END TRY
    BEGIN CATCH
        IF @TranCount = 0 AND @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- ============================================================
-- sp_ConfirmBooking (NEW)
-- ============================================================
CREATE OR ALTER PROCEDURE Operations.sp_ConfirmBooking
    @BookingID INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Status NVARCHAR(20), @UserID INT;
    SELECT @Status = Status, @UserID = UserID FROM Operations.Booking WHERE BookingID = @BookingID;

    IF @Status IS NULL
        EXEC dbo.sp_ThrowError 50031;
    IF @Status != N'Pending'
        EXEC dbo.sp_ThrowError 50033;

    UPDATE Operations.Booking SET Status = N'Confirmed', UpdatedAt = SYSDATETIME()
    WHERE BookingID = @BookingID;

    SELECT * FROM Operations.Booking WHERE BookingID = @BookingID;
END;
GO

-- ============================================================
-- sp_CancelBooking (NEW)
-- ============================================================
CREATE OR ALTER PROCEDURE Operations.sp_CancelBooking
    @BookingID INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Status NVARCHAR(20), @UserID INT;
    SELECT @Status = Status, @UserID = UserID FROM Operations.Booking WHERE BookingID = @BookingID;

    IF @Status IS NULL
        EXEC dbo.sp_ThrowError 50031;
    IF @Status IN (N'Completed', N'Cancelled', N'Expired')
        EXEC dbo.sp_ThrowError 50032;

    UPDATE Operations.Booking SET Status = N'Cancelled', UpdatedAt = SYSDATETIME()
    WHERE BookingID = @BookingID;

    -- Notify user
    INSERT INTO Users.Notification (UserID, Title, Body, Type, ReferenceType, ReferenceID, CreatedAt)
    VALUES (@UserID, N'Đã hủy đặt lịch', N'Đặt lịch mã ' + CAST(@BookingID AS NVARCHAR(10)) + N' đã được hủy.',
            'Booking', 'Booking', @BookingID, SYSDATETIME());

    SELECT * FROM Operations.Booking WHERE BookingID = @BookingID;
END;
GO

-- ============================================================
-- sp_CheckPointAvailability (NEW)
-- ============================================================
CREATE OR ALTER PROCEDURE Operations.sp_CheckPointAvailability
    @PointID  INT,
    @FromTime DATETIME2,
    @ToTime   DATETIME2,
    @IsAvailable BIT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @IsAvailable = Operations.fn_IsPointAvailable(@PointID, @FromTime, @ToTime);
END;
GO

-- ============================================================
-- sp_ReportError (NEW)
-- ============================================================
CREATE OR ALTER PROCEDURE Infrastructure.sp_ReportError
    @PointID     INT = NULL,
    @StationID   INT = NULL,
    @ErrorCode   NVARCHAR(30),
    @Severity    NVARCHAR(10) = 'Medium',
    @Description NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Infrastructure.ErrorLog (PointID, StationID, ErrorCode, Severity, Description, OccurredAt)
    VALUES (@PointID, @StationID, @ErrorCode, @Severity, @Description, SYSDATETIME());

    DECLARE @ErrorID INT = SCOPE_IDENTITY();
    SELECT * FROM Infrastructure.ErrorLog WHERE ErrorID = @ErrorID;
END;
GO

-- ============================================================
-- sp_ResolveError (NEW)
-- ============================================================
CREATE OR ALTER PROCEDURE Infrastructure.sp_ResolveError
    @ErrorID        INT,
    @ResolvedBy     INT,
    @ResolutionNotes NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Infrastructure.ErrorLog
    SET ResolvedAt = SYSDATETIME(), ResolvedBy = @ResolvedBy,
        ResolutionNotes = @ResolutionNotes, IsActive = 0
    WHERE ErrorID = @ErrorID;

    SELECT * FROM Infrastructure.ErrorLog WHERE ErrorID = @ErrorID;
END;
GO

-- ============================================================
-- sp_GetActiveErrors (NEW)
-- ============================================================
CREATE OR ALTER PROCEDURE Infrastructure.sp_GetActiveErrors
    @Severity NVARCHAR(10) = NULL,
    @Page     INT = 1,
    @Limit    INT = 20
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = (@Page - 1) * @Limit;

    SELECT el.*, p.PointCode, s.StationCode, s.StationName
    FROM Infrastructure.ErrorLog el
    LEFT JOIN Infrastructure.ChargingPoint p ON el.PointID = p.PointID
    LEFT JOIN Infrastructure.ChargingStation s ON el.StationID = s.StationID
    WHERE el.IsActive = 1
      AND (@Severity IS NULL OR el.Severity = @Severity)
    ORDER BY el.OccurredAt DESC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END;
GO

-- ============================================================
-- sp_ScheduleMaintenance (NEW)
-- ============================================================
CREATE OR ALTER PROCEDURE Operations.sp_ScheduleMaintenance
    @PointID        INT = NULL,
    @StationID      INT = NULL,
    @ScheduledBy    INT,
    @ScheduledFrom  DATETIME2,
    @ScheduledTo    DATETIME2,
    @MaintenanceType NVARCHAR(50) = 'Preventive',
    @Description    NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @TranCount INT = @@TRANCOUNT;

    BEGIN TRY
        IF @TranCount = 0 BEGIN TRANSACTION;

        -- Check overlapping bookings if point-level
        IF @PointID IS NOT NULL
        BEGIN
            IF EXISTS (
                SELECT 1 FROM Operations.Booking
                WHERE PointID = @PointID AND Status IN (N'Pending', N'Confirmed', N'Active')
                  AND BookedFrom < @ScheduledTo AND BookedTo > @ScheduledFrom
            )
                EXEC dbo.sp_ThrowError 50040;
        END;

        INSERT INTO Operations.MaintenanceSchedule (PointID, StationID, ScheduledBy, ScheduledFrom, ScheduledTo,
            MaintenanceType, Description, Status)
        VALUES (@PointID, @StationID, @ScheduledBy, @ScheduledFrom, @ScheduledTo,
            @MaintenanceType, @Description, N'Scheduled');

        DECLARE @ScheduleID INT = SCOPE_IDENTITY();

        -- Set point to Maintenance if point-level
        IF @PointID IS NOT NULL
            UPDATE Infrastructure.ChargingPoint SET PointStatus = 'Maintenance', UpdatedAt = SYSDATETIME()
            WHERE PointID = @PointID;

        IF @TranCount = 0 COMMIT TRANSACTION;

        SELECT * FROM Operations.MaintenanceSchedule WHERE ScheduleID = @ScheduleID;
    END TRY
    BEGIN CATCH
        IF @TranCount = 0 AND @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- ============================================================
-- sp_CompleteMaintenance (NEW)
-- ============================================================
CREATE OR ALTER PROCEDURE Operations.sp_CompleteMaintenance
    @ScheduleID INT,
    @Notes      NVARCHAR(1000) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Status NVARCHAR(20), @PointID INT;
    SELECT @Status = Status, @PointID = PointID FROM Operations.MaintenanceSchedule WHERE ScheduleID = @ScheduleID;

    IF @Status IS NULL
        EXEC dbo.sp_ThrowError 50041;
    IF @Status NOT IN (N'Scheduled', N'InProgress')
        EXEC dbo.sp_ThrowError 50042;

    UPDATE Operations.MaintenanceSchedule
    SET Status = N'Completed', CompletedAt = SYSDATETIME(), Notes = @Notes
    WHERE ScheduleID = @ScheduleID;

    -- Restore point
    IF @PointID IS NOT NULL
        UPDATE Infrastructure.ChargingPoint SET PointStatus = 'Available', UpdatedAt = SYSDATETIME()
        WHERE PointID = @PointID;

    SELECT * FROM Operations.MaintenanceSchedule WHERE ScheduleID = @ScheduleID;
END;
GO

-- ============================================================
-- sp_GetUpcomingMaintenance (NEW)
-- ============================================================
CREATE OR ALTER PROCEDURE Operations.sp_GetUpcomingMaintenance
    @Days INT = 7
AS
BEGIN
    SET NOCOUNT ON;

    SELECT ms.*, p.PointCode, s.StationCode, s.StationName, u.FullName AS ScheduledByName
    FROM Operations.MaintenanceSchedule ms
    LEFT JOIN Infrastructure.ChargingPoint p ON ms.PointID = p.PointID
    LEFT JOIN Infrastructure.ChargingStation s ON ms.StationID = s.StationID
    LEFT JOIN Users.[User] u ON ms.ScheduledBy = u.UserID
    WHERE ms.Status IN (N'Scheduled', N'InProgress')
      AND ms.ScheduledFrom <= DATEADD(DAY, @Days, SYSDATETIME())
    ORDER BY ms.ScheduledFrom;
END;
GO

-- ============================================================
-- sp_CreateNotification (NEW - helper called by triggers)
-- ============================================================
CREATE OR ALTER PROCEDURE Users.sp_CreateNotification
    @UserID       INT,
    @Title        NVARCHAR(200),
    @Body         NVARCHAR(1000),
    @Type         NVARCHAR(30),
    @ReferenceType NVARCHAR(30) = NULL,
    @ReferenceID  BIGINT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Users.Notification (UserID, Title, Body, Type, ReferenceType, ReferenceID, CreatedAt)
    VALUES (@UserID, @Title, @Body, @Type, @ReferenceType, @ReferenceID, SYSDATETIME());

    SELECT SCOPE_IDENTITY() AS NotificationID;
END;
GO

-- ============================================================
-- sp_GetUserNotifications (NEW)
-- ============================================================
CREATE OR ALTER PROCEDURE Users.sp_GetUserNotifications
    @UserID  INT,
    @UnreadOnly BIT = 0,
    @Page    INT = 1,
    @Limit   INT = 20
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = (@Page - 1) * @Limit;

    SELECT *
    FROM Users.Notification
    WHERE UserID = @UserID
      AND (@UnreadOnly = 0 OR IsRead = 0)
    ORDER BY CreatedAt DESC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;

    SELECT COUNT(*) AS Total
    FROM Users.Notification
    WHERE UserID = @UserID
      AND (@UnreadOnly = 0 OR IsRead = 0);
END;
GO

-- ============================================================
-- sp_MarkNotificationRead (NEW)
-- ============================================================
CREATE OR ALTER PROCEDURE Users.sp_MarkNotificationRead
    @NotificationID INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Users.Notification SET IsRead = 1
    WHERE NotificationID = @NotificationID;
END;
GO

PRINT N'16 stored procedures created.';
GO
