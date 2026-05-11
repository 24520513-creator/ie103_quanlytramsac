USE EV_Charging_System;
GO

-- ============================================================
-- trg_ChargingPoint_StatusChange (existing)
-- Logs point status changes to PointStatusLog
-- ============================================================
CREATE OR ALTER TRIGGER Infrastructure.trg_ChargingPoint_StatusChange
ON Infrastructure.ChargingPoint
AFTER UPDATE
AS
IF UPDATE(PointStatus)
BEGIN
    SET NOCOUNT ON;
    INSERT INTO Infrastructure.PointStatusLog (PointID, OldStatus, NewStatus, ChangedAt)
    SELECT d.PointID, d.PointStatus, i.PointStatus, SYSDATETIME()
    FROM deleted d JOIN inserted i ON d.PointID = i.PointID
    WHERE d.PointStatus != i.PointStatus;
END;
GO

-- ============================================================
-- trg_Booking_StatusChange (NEW)
-- Logs booking status changes and sends notification
-- ============================================================
CREATE OR ALTER TRIGGER Operations.trg_Booking_StatusChange
ON Operations.Booking
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Users.Notification (UserID, Title, Body, Type, ReferenceType, ReferenceID, CreatedAt)
    SELECT i.UserID,
        CASE i.Status
            WHEN N'Confirmed' THEN N'Đặt lịch đã được xác nhận'
            WHEN N'Cancelled' THEN N'Đặt lịch đã bị hủy'
            WHEN N'Expired'   THEN N'Đặt lịch đã hết hạn'
            WHEN N'Completed' THEN N'Đặt lịch đã hoàn thành'
        END,
        N'Đặt lịch ' + i.BookingCode + N' chuyển sang trạng thái: ' + i.Status,
        'Booking', 'Booking', i.BookingID, SYSDATETIME()
    FROM inserted i
    JOIN deleted d ON i.BookingID = d.BookingID
    WHERE i.Status != d.Status
      AND i.Status IN (N'Confirmed', N'Cancelled', N'Expired', N'Completed');
END;
GO

-- ============================================================
-- trg_Maintenance_PointSync (NEW)
-- Syncs charging point status with maintenance schedule
-- ============================================================
CREATE OR ALTER TRIGGER Operations.trg_Maintenance_PointSync
ON Operations.MaintenanceSchedule
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Set point to Maintenance when scheduled
    UPDATE p
    SET p.PointStatus = 'Maintenance', p.UpdatedAt = SYSDATETIME()
    FROM Infrastructure.ChargingPoint p
    JOIN inserted i ON p.PointID = i.PointID
    WHERE i.Status = N'Scheduled'
      AND i.PointID IS NOT NULL
      AND p.PointStatus = 'Available';

    -- Restore point when completed or cancelled
    UPDATE p
    SET p.PointStatus = 'Available', p.UpdatedAt = SYSDATETIME()
    FROM Infrastructure.ChargingPoint p
    JOIN inserted i ON p.PointID = i.PointID
    WHERE i.Status IN (N'Completed', N'Cancelled')
      AND i.PointID IS NOT NULL;
END;
GO

-- ============================================================
-- trg_Session_Notification (NEW)
-- Sends notification when charging session completes
-- ============================================================
CREATE OR ALTER TRIGGER Operations.trg_Session_Notification
ON Operations.ChargingSession
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Users.Notification (UserID, Title, Body, Type, ReferenceType, ReferenceID, CreatedAt)
    SELECT i.UserID,
           N'Phiên sạc hoàn thành',
           N'Phiên sạc ' + i.SessionCode + N' đã hoàn thành. Chi phí: ' + ISNULL(CAST(i.CostTotal AS NVARCHAR(20)), N'0') + N' VND.',
           'ChargingComplete', 'Session', i.SessionID, SYSDATETIME()
    FROM inserted i
    JOIN deleted d ON i.SessionID = d.SessionID
    WHERE d.SessionStatus = 'Charging'
      AND i.SessionStatus = 'Completed';
END;
GO

-- ============================================================
-- trg_Wallet_LowBalance (NEW)
-- Warns user when wallet balance drops below threshold
-- ============================================================
CREATE OR ALTER TRIGGER Payments.trg_Wallet_LowBalance
ON Payments.Wallet
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Threshold MONEY = 50000;

    INSERT INTO Users.Notification (UserID, Title, Body, Type, ReferenceType, ReferenceID, CreatedAt)
    SELECT i.UserID,
           N'Cảnh báo số dư ví',
           N'Số dư ví của bạn chỉ còn ' + CAST(i.Balance AS NVARCHAR(20)) + N' VND. Vui lòng nạp thêm để tiếp tục sử dụng dịch vụ.',
           'WalletAlert', 'Wallet', i.WalletID, SYSDATETIME()
    FROM inserted i
    JOIN deleted d ON i.WalletID = d.WalletID
    WHERE i.Balance < @Threshold
      AND d.Balance >= @Threshold
      AND i.IsActive = 1;
END;
GO

-- ============================================================
-- trg_ErrorLog_AutoCreate (NEW)
-- Auto-creates error log when point status changes to Error/Offline
-- ============================================================
CREATE OR ALTER TRIGGER Infrastructure.trg_ErrorLog_AutoCreate
ON Infrastructure.ChargingPoint
AFTER UPDATE
AS
IF UPDATE(PointStatus)
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Infrastructure.ErrorLog (PointID, StationID, ErrorCode, Severity, Description, OccurredAt)
    SELECT i.PointID, i.StationID,
           CASE i.PointStatus
               WHEN 'Error' THEN 'E001'
               WHEN 'Offline' THEN 'E002'
               ELSE NULL
           END,
           CASE i.PointStatus
               WHEN 'Error' THEN 'High'
               WHEN 'Offline' THEN 'Medium'
               ELSE NULL
           END,
           CASE i.PointStatus
               WHEN 'Error' THEN N'Charging point reported error: ' + ISNULL(i.PointCode, N'')
               WHEN 'Offline' THEN N'Charging point went offline: ' + ISNULL(i.PointCode, N'')
               ELSE NULL
           END,
           SYSDATETIME()
    FROM inserted i
    JOIN deleted d ON i.PointID = d.PointID
    WHERE i.PointStatus IN ('Error', 'Offline')
      AND d.PointStatus NOT IN ('Error', 'Offline');
END;
GO

PRINT N'6 triggers created.';
GO
