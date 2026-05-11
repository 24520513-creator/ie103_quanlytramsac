USE EV_Charging_System;
GO

-- ============================================================
-- sp_AutoExpirePendingBookings
-- Expires bookings where BookedFrom has passed and status is still Pending
-- Uses CURSOR to process each expired booking and send notifications
-- ============================================================
CREATE OR ALTER PROCEDURE Operations.sp_AutoExpirePendingBookings
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @BookingID INT, @BookingCode NVARCHAR(30), @UserID INT, @Count INT = 0;

    DECLARE expired_cursor CURSOR LOCAL FAST_FORWARD FOR
        SELECT BookingID, BookingCode, UserID
        FROM Operations.Booking
        WHERE Status = N'Pending'
          AND BookedFrom < SYSDATETIME();

    OPEN expired_cursor;

    FETCH NEXT FROM expired_cursor INTO @BookingID, @BookingCode, @UserID;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN TRY
            UPDATE Operations.Booking
            SET Status = N'Expired', UpdatedAt = SYSDATETIME()
            WHERE BookingID = @BookingID;

            INSERT INTO Users.Notification (UserID, Title, Body, Type, ReferenceType, ReferenceID, CreatedAt)
            VALUES (@UserID, N'Đặt lịch đã hết hạn',
                N'Đặt lịch ' + @BookingCode + N' đã hết hạn do không được xác nhận đúng giờ.',
                'Booking', 'Booking', @BookingID, SYSDATETIME());

            SET @Count = @Count + 1;
        END TRY
        BEGIN CATCH
            -- Log error but continue processing
            PRINT N'Error expiring booking ' + CAST(@BookingID AS NVARCHAR(10)) + N': ' + ERROR_MESSAGE();
        END CATCH;

        FETCH NEXT FROM expired_cursor INTO @BookingID, @BookingCode, @UserID;
    END;

    CLOSE expired_cursor;
    DEALLOCATE expired_cursor;

    RETURN @Count;
END;
GO

-- ============================================================
-- sp_AutoCompleteOverdueMaintenance
-- Completes maintenance schedules that are overdue (past ScheduledTo)
-- Restores affected charging points to Available
-- Uses CURSOR to process each overdue schedule
-- ============================================================
CREATE OR ALTER PROCEDURE Operations.sp_AutoCompleteOverdueMaintenance
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ScheduleID INT, @PointID INT, @Count INT = 0;

    DECLARE maint_cursor CURSOR LOCAL FAST_FORWARD FOR
        SELECT ScheduleID, PointID
        FROM Operations.MaintenanceSchedule
        WHERE Status IN (N'Scheduled', N'InProgress')
          AND ScheduledTo < SYSDATETIME();

    OPEN maint_cursor;

    FETCH NEXT FROM maint_cursor INTO @ScheduleID, @PointID;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN TRY
            UPDATE Operations.MaintenanceSchedule
            SET Status = N'Completed', CompletedAt = SYSDATETIME(),
                Notes = N'Auto-completed by system (overdue)'
            WHERE ScheduleID = @ScheduleID;

            IF @PointID IS NOT NULL
                UPDATE Infrastructure.ChargingPoint
                SET PointStatus = 'Available', UpdatedAt = SYSDATETIME()
                WHERE PointID = @PointID;

            SET @Count = @Count + 1;
        END TRY
        BEGIN CATCH
            PRINT N'Error completing maintenance ' + CAST(@ScheduleID AS NVARCHAR(10)) + N': ' + ERROR_MESSAGE();
        END CATCH;

        FETCH NEXT FROM maint_cursor INTO @ScheduleID, @PointID;
    END;

    CLOSE maint_cursor;
    DEALLOCATE maint_cursor;

    RETURN @Count;
END;
GO

-- ============================================================
-- sp_CleanupExpiredNotifications
-- Deletes notifications older than @Days days that have been read
-- Uses CURSOR to process and delete in batches
-- ============================================================
CREATE OR ALTER PROCEDURE Users.sp_CleanupExpiredNotifications
    @Days INT = 90,
    @BatchSize INT = 100
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NotificationID INT, @DeletedCount INT = 0;
    DECLARE @CutoffDate DATETIME2 = DATEADD(DAY, -@Days, SYSDATETIME());

    DECLARE cleanup_cursor CURSOR LOCAL FAST_FORWARD FOR
        SELECT TOP (@BatchSize) NotificationID
        FROM Users.Notification
        WHERE IsRead = 1
          AND CreatedAt < @CutoffDate
        ORDER BY CreatedAt;

    OPEN cleanup_cursor;

    FETCH NEXT FROM cleanup_cursor INTO @NotificationID;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        DELETE FROM Users.Notification WHERE NotificationID = @NotificationID;
        SET @DeletedCount = @DeletedCount + 1;

        FETCH NEXT FROM cleanup_cursor INTO @NotificationID;
    END;

    CLOSE cleanup_cursor;
    DEALLOCATE cleanup_cursor;

    RETURN @DeletedCount;
END;
GO

-- ============================================================
-- sp_RecordHourlySnapshot: Wrapper for analytics snapshot
-- ============================================================
CREATE OR ALTER PROCEDURE Reporting.sp_RecordHourlySnapshot
AS
BEGIN
    SET NOCOUNT ON;
    EXEC Reporting.sp_TakeHourlySnapshot;
END;
GO

-- ============================================================
-- sp_RecordDailySnapshot: Wrapper for daily analytics snapshot
-- ============================================================
CREATE OR ALTER PROCEDURE Reporting.sp_RecordDailySnapshot
AS
BEGIN
    SET NOCOUNT ON;
    EXEC Reporting.sp_TakeDailySnapshot;
END;
GO

PRINT N'5 batch job stored procedures created.';
GO
