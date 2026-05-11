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
-- sp_CreateBooking (UPDATED: added @StationID param, PointStatus check)
-- ============================================================
CREATE OR ALTER PROCEDURE Operations.sp_CreateBooking
    @UserID     INT,
    @PointID    INT,
    @StationID  INT = NULL,
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

        DECLARE @ActualStationID INT, @PointStatus NVARCHAR(20);
        SELECT @ActualStationID = StationID, @PointStatus = PointStatus
        FROM Infrastructure.ChargingPoint WHERE PointID = @PointID AND IsActive = 1;

        IF @PointStatus IS NULL
            EXEC dbo.sp_ThrowError 50001;
        IF @PointStatus != 'Available'
            EXEC dbo.sp_ThrowError 50002;

        -- Use provided StationID or derive from point
        SET @StationID = COALESCE(@StationID, @ActualStationID);

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
-- sp_CancelBooking (UPDATED: only Pending/Confirmed can be cancelled)
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
    IF @Status NOT IN (N'Pending', N'Confirmed')
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
-- sp_ResolveError (UPDATED: @ResolvedBy is optional)
-- ============================================================
CREATE OR ALTER PROCEDURE Infrastructure.sp_ResolveError
    @ErrorID         INT,
    @ResolvedBy      INT = NULL,
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
-- sp_CompleteMaintenance (UPDATED: added @CompletedAt param)
-- ============================================================
CREATE OR ALTER PROCEDURE Operations.sp_CompleteMaintenance
    @ScheduleID  INT,
    @Notes       NVARCHAR(1000) = NULL,
    @CompletedAt DATETIME2 = NULL
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
    SET Status = N'Completed', CompletedAt = ISNULL(@CompletedAt, SYSDATETIME()), Notes = @Notes
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
-- sp_CreateNotification (UPDATED: returns full record)
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

    INSERT INTO Users.Notification (UserID, Title, Body, Type, ReferenceType, ReferenceID, IsRead, CreatedAt)
    VALUES (@UserID, @Title, @Body, @Type, @ReferenceType, @ReferenceID, 0, SYSDATETIME());

    DECLARE @NotificationID INT = SCOPE_IDENTITY();
    SELECT * FROM Users.Notification WHERE NotificationID = @NotificationID;
END;
GO

-- ============================================================
-- sp_GetUserNotifications (UPDATED: added @Type filter)
-- ============================================================
CREATE OR ALTER PROCEDURE Users.sp_GetUserNotifications
    @UserID     INT,
    @UnreadOnly BIT = 0,
    @Type       NVARCHAR(30) = NULL,
    @Page       INT = 1,
    @Limit      INT = 20
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = (@Page - 1) * @Limit;

    SELECT *
    FROM Users.Notification
    WHERE UserID = @UserID
      AND (@UnreadOnly = 0 OR IsRead = 0)
      AND (@Type IS NULL OR [Type] = @Type)
    ORDER BY CreatedAt DESC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;

    SELECT COUNT(*) AS Total
    FROM Users.Notification
    WHERE UserID = @UserID
      AND (@UnreadOnly = 0 OR IsRead = 0)
      AND (@Type IS NULL OR [Type] = @Type);
END;
GO

-- ============================================================
-- sp_MarkNotificationRead (UPDATED: added @UserID filter, returns record)
-- ============================================================
CREATE OR ALTER PROCEDURE Users.sp_MarkNotificationRead
    @NotificationID INT,
    @UserID         INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Users.Notification SET IsRead = 1
    WHERE NotificationID = @NotificationID
      AND (@UserID IS NULL OR UserID = @UserID);

    SELECT * FROM Users.Notification WHERE NotificationID = @NotificationID;
END;
GO

-- ============================================================================
-- NEW STORED PROCEDURES: Auth, Dashboard, Wallet, Sessions, Events, PDF
-- ============================================================================

-- ============================================================
-- Users.sp_RegisterUser (with auto wallet creation)
-- ============================================================
CREATE OR ALTER PROCEDURE Users.sp_RegisterUser
    @Username       NVARCHAR(50),
    @Email          NVARCHAR(200),
    @Phone          NVARCHAR(20) = NULL,
    @PasswordHash   NVARCHAR(500),
    @FullName       NVARCHAR(200),
    @Role           NVARCHAR(20) = 'Customer'
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @TranCount INT = @@TRANCOUNT;

    BEGIN TRY
        IF @TranCount = 0 BEGIN TRANSACTION;

        IF EXISTS (SELECT 1 FROM Users.[User] WHERE Email = @Email OR Username = @Username)
            THROW 50060, N'Tên đăng nhập hoặc email đã tồn tại.', 1;

        INSERT INTO Users.[User] (Username, Email, Phone, PasswordHash, FullName, Role, AccountStatus, CreatedAt)
        VALUES (@Username, @Email, @Phone, @PasswordHash, @FullName, @Role, 'Active', SYSDATETIME());

        DECLARE @UserID INT = SCOPE_IDENTITY();

        INSERT INTO Payments.Wallet (UserID, WalletCode, Balance, CreatedAt)
        VALUES (@UserID, 'WAL-' + @Username, 0, SYSDATETIME());

        IF @TranCount = 0 COMMIT TRANSACTION;

        SELECT UserID, Username, Email, Role FROM Users.[User] WHERE UserID = @UserID;
    END TRY
    BEGIN CATCH
        IF @TranCount = 0 AND @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- ============================================================
-- Users.sp_GetUserByLogin
-- ============================================================
CREATE OR ALTER PROCEDURE Users.sp_GetUserByLogin
    @Login NVARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM Users.[User] WHERE (Email = @Login OR Username = @Login);
END;
GO

-- ============================================================
-- Users.sp_UpdateFailedLoginAttempts
-- ============================================================
CREATE OR ALTER PROCEDURE Users.sp_UpdateFailedLoginAttempts
    @UserID  INT,
    @Attempts INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Users.[User] SET FailedLoginAttempts = @Attempts WHERE UserID = @UserID;
    IF @Attempts >= 5
        UPDATE Users.[User] SET LockoutEnd = DATEADD(HOUR, 1, SYSDATETIME()) WHERE UserID = @UserID;
END;
GO

-- ============================================================
-- Users.sp_ResetLoginSuccess
-- ============================================================
CREATE OR ALTER PROCEDURE Users.sp_ResetLoginSuccess
    @UserID INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Users.[User] SET FailedLoginAttempts = 0, LastLoginAt = SYSDATETIME() WHERE UserID = @UserID;
END;
GO

-- ============================================================
-- Users.sp_GetUserProfile
-- ============================================================
CREATE OR ALTER PROCEDURE Users.sp_GetUserProfile
    @UserID INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT UserID, Username, Email, Phone, FullName, AvatarUrl, Role,
           FranchiseID, AccountStatus, LastLoginAt, CreatedAt
    FROM Users.[User] WHERE UserID = @UserID;
END;
GO

-- ============================================================
-- Users.sp_UpdateUserProfile
-- ============================================================
CREATE OR ALTER PROCEDURE Users.sp_UpdateUserProfile
    @UserID   INT,
    @FullName NVARCHAR(200) = NULL,
    @AvatarUrl NVARCHAR(500) = NULL,
    @Phone    NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Users.[User] SET
        FullName  = ISNULL(@FullName, FullName),
        AvatarUrl = ISNULL(@AvatarUrl, AvatarUrl),
        Phone     = ISNULL(@Phone, Phone),
        UpdatedAt = SYSDATETIME()
    WHERE UserID = @UserID;

    SELECT UserID, Username, Email, Phone, FullName, AvatarUrl, Role,
           FranchiseID, AccountStatus, LastLoginAt, CreatedAt
    FROM Users.[User] WHERE UserID = @UserID;
END;
GO

-- ============================================================
-- Users.sp_CheckEmailExists
-- ============================================================
CREATE OR ALTER PROCEDURE Users.sp_CheckEmailExists
    @Email NVARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT UserID, Email FROM Users.[User] WHERE Email = @Email;
END;
GO

-- ============================================================
-- Users.sp_UpdatePassword
-- ============================================================
CREATE OR ALTER PROCEDURE Users.sp_UpdatePassword
    @UserID      INT,
    @PasswordHash NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Users.[User] SET PasswordHash = @PasswordHash, UpdatedAt = SYSDATETIME() WHERE UserID = @UserID;
END;
GO

-- ============================================================
-- Operations.sp_CancelChargingSession (self-contained transaction)
-- ============================================================
CREATE OR ALTER PROCEDURE Operations.sp_CancelChargingSession
    @SessionID BIGINT,
    @StopReason NVARCHAR(50) = 'CancelledByUser'
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @TranCount INT = @@TRANCOUNT;

    BEGIN TRY
        IF @TranCount = 0 BEGIN TRANSACTION;

        DECLARE @CurrentStatus NVARCHAR(20), @PointID INT, @UserID INT, @StationID INT;
        SELECT @CurrentStatus = SessionStatus, @PointID = PointID, @UserID = UserID, @StationID = StationID
        FROM Operations.ChargingSession WHERE SessionID = @SessionID;

        IF @CurrentStatus IS NULL
            EXEC dbo.sp_ThrowError 50010;
        IF @CurrentStatus NOT IN ('Charging', 'Pending')
            EXEC dbo.sp_ThrowError 50011;

        UPDATE Operations.ChargingSession SET
            SessionStatus = 'Cancelled', StopReason = @StopReason, UpdatedAt = SYSDATETIME()
        WHERE SessionID = @SessionID;

        UPDATE Infrastructure.ChargingPoint SET PointStatus = 'Available', UpdatedAt = SYSDATETIME()
        WHERE PointID = @PointID;

        IF @TranCount = 0 COMMIT TRANSACTION;

        SELECT SessionID, PointID, StationID, UserID FROM Operations.ChargingSession WHERE SessionID = @SessionID;
    END TRY
    BEGIN CATCH
        IF @TranCount = 0 AND @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- ============================================================
-- Operations.sp_GetActiveSessions (dynamic filter SP)
-- ============================================================
CREATE OR ALTER PROCEDURE Operations.sp_GetActiveSessions
    @Status     NVARCHAR(20) = NULL,
    @UserID     INT = NULL,
    @StationID  INT = NULL,
    @FromDate   DATETIME2 = NULL,
    @ToDate     DATETIME2 = NULL,
    @Page       INT = 1,
    @Limit      INT = 20
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Offset INT = (@Page - 1) * @Limit;

    SELECT cs.*, u.Username, u.FullName, s.StationCode, s.StationName, p.PointCode, v.PlateNumber
    FROM Operations.ChargingSession cs
    JOIN Users.[User] u ON cs.UserID = u.UserID
    JOIN Infrastructure.ChargingStation s ON cs.StationID = s.StationID
    JOIN Infrastructure.ChargingPoint p ON cs.PointID = p.PointID
    LEFT JOIN Users.Vehicle v ON cs.VehicleID = v.VehicleID
    WHERE (@Status IS NULL OR cs.SessionStatus = @Status)
      AND (@UserID IS NULL OR cs.UserID = @UserID)
      AND (@StationID IS NULL OR cs.StationID = @StationID)
      AND (@FromDate IS NULL OR cs.StartTime >= @FromDate)
      AND (@ToDate IS NULL OR cs.StartTime <= @ToDate)
    ORDER BY cs.StartTime DESC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END;
GO

-- ============================================================
-- Operations.sp_GetSessionById (join query)
-- ============================================================
CREATE OR ALTER PROCEDURE Operations.sp_GetSessionById
    @SessionID BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT cs.*, u.Username, u.FullName, s.StationName, p.PointCode, v.PlateNumber
    FROM Operations.ChargingSession cs
    JOIN Users.[User] u ON cs.UserID = u.UserID
    JOIN Infrastructure.ChargingStation s ON cs.StationID = s.StationID
    JOIN Infrastructure.ChargingPoint p ON cs.PointID = p.PointID
    LEFT JOIN Users.Vehicle v ON cs.VehicleID = v.VehicleID
    WHERE cs.SessionID = @SessionID;
END;
GO

-- ============================================================
-- Infrastructure.sp_GetStationIdByPoint
-- ============================================================
CREATE OR ALTER PROCEDURE Infrastructure.sp_GetStationIdByPoint
    @PointID INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT StationID FROM Infrastructure.ChargingPoint WHERE PointID = @PointID;
END;
GO

-- ============================================================
-- Payments.sp_GetOrCreateWallet
-- ============================================================
CREATE OR ALTER PROCEDURE Payments.sp_GetOrCreateWallet
    @UserID INT,
    @Username NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @WalletID INT;
    SELECT @WalletID = WalletID FROM Payments.Wallet WHERE UserID = @UserID AND IsActive = 1;

    IF @WalletID IS NULL
    BEGIN
        IF @Username IS NULL
            SELECT @Username = Username FROM Users.[User] WHERE UserID = @UserID;
        SET @Username = ISNULL(@Username, CAST(@UserID AS NVARCHAR(10)));

        INSERT INTO Payments.Wallet (UserID, WalletCode, Balance, CreatedAt)
        VALUES (@UserID, 'WAL-' + @Username, 0, SYSDATETIME());

        SET @WalletID = SCOPE_IDENTITY();
    END;

    SELECT * FROM Payments.Wallet WHERE WalletID = @WalletID;
END;
GO

-- ============================================================
-- Payments.sp_TopUpWallet (self-contained transaction)
-- ============================================================
CREATE OR ALTER PROCEDURE Payments.sp_TopUpWallet
    @UserID        INT,
    @Amount        MONEY,
    @PaymentMethod NVARCHAR(30) = 'BankTransfer'
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @TranCount INT = @@TRANCOUNT;

    BEGIN TRY
        IF @TranCount = 0 BEGIN TRANSACTION;

        DECLARE @WalletID INT, @Balance MONEY;
        SELECT @WalletID = WalletID, @Balance = Balance
        FROM Payments.Wallet WHERE UserID = @UserID AND IsActive = 1;

        IF @WalletID IS NULL
            EXEC dbo.sp_ThrowError 50025;

        DECLARE @TxnCode NVARCHAR(30) = 'TXN-' + FORMAT(SYSDATETIME(), 'yyyyMMdd') + '-' + LEFT(CAST(NEWID() AS NVARCHAR(36)), 6);

        DECLARE @TxnID BIGINT;
        INSERT INTO Payments.[Transaction] (TransactionCode, UserID, TransactionType, Direction, Amount, CurrencyCode, TransactionStatus, PaymentMethod, TransactedAt, CreatedAt)
        VALUES (@TxnCode, @UserID, 'WalletTopUp', 'C', @Amount, 'VND', 'Completed', @PaymentMethod, SYSDATETIME(), SYSDATETIME());

        SET @TxnID = SCOPE_IDENTITY();

        UPDATE Payments.Wallet SET Balance = Balance + @Amount, LastTransactionAt = SYSDATETIME()
        WHERE WalletID = @WalletID;

        INSERT INTO Payments.WalletTransaction (WalletID, TransactionID, Amount, BalanceBefore, Direction, TransactionType, CreatedAt)
        VALUES (@WalletID, @TxnID, @Amount, @Balance, 'C', 'WalletTopUp', SYSDATETIME());

        SET @Balance = @Balance + @Amount;

        IF @TranCount = 0 COMMIT TRANSACTION;

        SELECT @TxnID AS TransactionID, @Balance AS NewBalance;
    END TRY
    BEGIN CATCH
        IF @TranCount = 0 AND @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- ============================================================
-- Payments.sp_GetTransactionHistory (dynamic filter SP)
-- ============================================================
CREATE OR ALTER PROCEDURE Payments.sp_GetTransactionHistory
    @UserID INT = NULL,
    @Status NVARCHAR(20) = NULL,
    @Type   NVARCHAR(30) = NULL,
    @Page   INT = 1,
    @Limit  INT = 20
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Offset INT = (@Page - 1) * @Limit;

    SELECT t.*, cs.SessionCode
    FROM Payments.[Transaction] t
    LEFT JOIN Operations.ChargingSession cs ON t.SessionID = cs.SessionID
    WHERE (@UserID IS NULL OR t.UserID = @UserID)
      AND (@Status IS NULL OR t.TransactionStatus = @Status)
      AND (@Type IS NULL OR t.TransactionType = @Type)
    ORDER BY t.TransactedAt DESC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END;
GO

-- ============================================================
-- Reporting.sp_GetAdminDashboard (multi-result-set SP)
-- ============================================================
CREATE OR ALTER PROCEDURE Reporting.sp_GetAdminDashboard
AS
BEGIN
    SET NOCOUNT ON;

    SELECT * FROM Reporting.vw_RevenueTrend ORDER BY Date DESC;

    SELECT
        (SELECT COUNT(*) FROM Users.[User] WHERE AccountStatus = 'Active') AS TotalUsers,
        (SELECT COUNT(*) FROM Infrastructure.ChargingStation WHERE IsActive = 1) AS TotalStations,
        (SELECT COUNT(*) FROM Infrastructure.Franchise WHERE IsActive = 1) AS TotalFranchises,
        (SELECT COUNT(*) FROM Operations.ChargingSession WHERE SessionStatus = 'Completed') AS TotalSessions,
        (SELECT COUNT(*) FROM Operations.ChargingSession WHERE SessionStatus = 'Charging') AS ActiveSessions,
        (SELECT ISNULL(SUM(TotalKWh), 0) FROM Operations.ChargingSession WHERE SessionStatus = 'Completed') AS TotalKWh,
        (SELECT ISNULL(SUM(CostTotal), 0) FROM Operations.ChargingSession WHERE SessionStatus = 'Completed') AS TotalRevenue,
        (SELECT COUNT(*) FROM Operations.Booking WHERE Status IN ('Pending', 'Confirmed')) AS PendingBookings,
        (SELECT COUNT(*) FROM Infrastructure.ErrorLog WHERE IsActive = 1 AND ResolvedAt IS NULL) AS UnresolvedErrors,
        (SELECT COUNT(*) FROM Operations.MaintenanceSchedule WHERE Status IN ('Scheduled', 'InProgress')) AS UpcomingMaintenance,
        (SELECT COUNT(*) FROM Users.Notification WHERE IsRead = 0) AS UnreadNotifications;

    SELECT TOP 10 s.StationCode, s.StationName,
        COUNT(cs.SessionID) AS Sessions,
        ISNULL(SUM(cs.TotalKWh), 0) AS KWh,
        ISNULL(SUM(cs.CostTotal), 0) AS Revenue
    FROM Operations.ChargingSession cs
    JOIN Infrastructure.ChargingStation s ON cs.StationID = s.StationID
    WHERE cs.SessionStatus = 'Completed'
    GROUP BY s.StationCode, s.StationName
    ORDER BY Revenue DESC;

    SELECT TOP 5 b.*, s.StationName, p.PointCode
    FROM Operations.Booking b
    JOIN Infrastructure.ChargingStation s ON b.StationID = s.StationID
    LEFT JOIN Infrastructure.ChargingPoint p ON b.PointID = p.PointID
    ORDER BY b.CreatedAt DESC;

    SELECT TOP 5 el.*, p.PointCode
    FROM Infrastructure.ErrorLog el
    LEFT JOIN Infrastructure.ChargingPoint p ON el.PointID = p.PointID
    WHERE el.IsActive = 1 AND el.ResolvedAt IS NULL
    ORDER BY el.OccurredAt DESC;
END;
GO

-- ============================================================
-- Reporting.sp_GetStationDashboard
-- ============================================================
CREATE OR ALTER PROCEDURE Reporting.sp_GetStationDashboard
    @StationID INT,
    @Days      INT = 30
AS
BEGIN
    SET NOCOUNT ON;

    SELECT COUNT(*) AS ActiveSessions
    FROM Operations.ChargingSession
    WHERE StationID = @StationID AND SessionStatus = 'Charging';

    SELECT
        COUNT(*) AS TotalSessions,
        ISNULL(SUM(TotalKWh), 0) AS TotalKWh,
        ISNULL(SUM(CostTotal), 0) AS TotalRevenue,
        ISNULL(AVG(ChargingDurationMinutes), 0) AS AvgDuration
    FROM Operations.ChargingSession
    WHERE StationID = @StationID AND SessionStatus = 'Completed'
      AND StartTime >= DATEADD(DAY, -@Days, SYSDATETIME());

    SELECT PointStatus, COUNT(*) AS Count
    FROM Infrastructure.ChargingPoint
    WHERE StationID = @StationID AND IsActive = 1
    GROUP BY PointStatus;

    SELECT * FROM Infrastructure.ChargingStation WHERE StationID = @StationID;
END;
GO

-- ============================================================
-- Reporting.sp_GetFranchiseDashboard
-- ============================================================
CREATE OR ALTER PROCEDURE Reporting.sp_GetFranchiseDashboard
    @FranchiseID INT,
    @Days        INT = 30
AS
BEGIN
    SET NOCOUNT ON;

    SELECT StationID, StationCode, StationName, StationStatus
    FROM Infrastructure.ChargingStation
    WHERE FranchiseID = @FranchiseID AND IsActive = 1;

    SELECT
        ISNULL(SUM(CostTotal), 0) AS TotalRevenue,
        ISNULL(SUM(TotalKWh), 0) AS TotalKWh,
        COUNT(*) AS TotalSessions
    FROM Operations.ChargingSession
    WHERE StationID IN (
        SELECT StationID FROM Infrastructure.ChargingStation WHERE FranchiseID = @FranchiseID AND IsActive = 1
    ) AND SessionStatus = 'Completed'
      AND StartTime >= DATEADD(DAY, -@Days, SYSDATETIME());

    SELECT * FROM Infrastructure.Franchise WHERE FranchiseID = @FranchiseID;
END;
GO

-- ============================================================
-- Reporting.sp_GetFranchiseReportData (for PDF)
-- ============================================================
CREATE OR ALTER PROCEDURE Reporting.sp_GetFranchiseReportData
    @FranchiseID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT * FROM Infrastructure.Franchise WHERE FranchiseID = @FranchiseID;

    SELECT StationID, StationCode, StationName, StationStatus
    FROM Infrastructure.ChargingStation WHERE FranchiseID = @FranchiseID AND IsActive = 1;

    SELECT
        ISNULL(SUM(CostTotal), 0) AS TotalRevenue,
        ISNULL(SUM(TotalKWh), 0) AS TotalKWh,
        COUNT(*) AS TotalSessions
    FROM Operations.ChargingSession
    WHERE StationID IN (
        SELECT StationID FROM Infrastructure.ChargingStation WHERE FranchiseID = @FranchiseID AND IsActive = 1
    ) AND SessionStatus = 'Completed';
END;
GO

-- ============================================================
-- dbo.sp_EmitRealtimeEvent
-- ============================================================
CREATE OR ALTER PROCEDURE dbo.sp_EmitRealtimeEvent
    @EventType      NVARCHAR(100),
    @Payload        NVARCHAR(MAX) = NULL,
    @UserID         INT = NULL,
    @AggregateType  NVARCHAR(50) = NULL,
    @AggregateID    NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.RealtimeEvent (EventType, AggregateType, AggregateID, Payload, UserID, CreatedAt)
    VALUES (@EventType, @AggregateType, @AggregateID, @Payload, @UserID, SYSDATETIME());
END;
GO

-- ============================================================
-- dbo.sp_GetMissedEvents
-- ============================================================
CREATE OR ALTER PROCEDURE dbo.sp_GetMissedEvents
    @UserID INT,
    @Since  DATETIME2
AS
BEGIN
    SET NOCOUNT ON;
    SELECT EventType, Payload, CreatedAt
    FROM dbo.RealtimeEvent
    WHERE (UserID = @UserID OR UserID IS NULL)
      AND CreatedAt > @Since
    ORDER BY CreatedAt;
END;
GO

-- ============================================================
-- Operations.sp_CheckBookingAvailability (returns result set)
-- ============================================================
CREATE OR ALTER PROCEDURE Operations.sp_CheckBookingAvailability
    @PointID  INT,
    @FromTime DATETIME2,
    @ToTime   DATETIME2
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @PointStatus NVARCHAR(20), @Cnt INT, @IsAvailable BIT;
    SELECT @PointStatus = PointStatus FROM Infrastructure.ChargingPoint WHERE PointID = @PointID;
    SELECT @Cnt = COUNT(*) FROM Operations.Booking
        WHERE PointID = @PointID AND Status IN ('Pending', 'Confirmed')
        AND BookedFrom < @ToTime AND BookedTo > @FromTime;
    SET @IsAvailable = CASE WHEN @PointStatus = 'Available' AND @Cnt = 0 THEN 1 ELSE 0 END;
    SELECT @IsAvailable AS IsAvailable, ISNULL(@Cnt, 0) AS ConflictingBookings;
END;
GO

-- ============================================================================
-- END NEW STORED PROCEDURES
-- ============================================================================

PRINT N'Additional stored procedures created (Auth, Dashboard, Wallet, Sessions, Events, PDF).';
GO
