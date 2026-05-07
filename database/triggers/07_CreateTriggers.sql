/*=============================================================================
  EV_Charging_System - TRIGGERS
  =============================================================================*/

USE EV_Charging_System;
GO

-- ========================================
-- trg_ChargingPoint_AutoUpdateStatus
-- Updates charging point status when a session starts or ends.
--   INSERT → point becomes 'Đang bận'
--   UPDATE (completed) → point becomes 'Khả dụng'
-- ========================================
CREATE OR ALTER TRIGGER Operations.trg_ChargingPoint_AutoUpdateStatus
ON Operations.ChargingSession
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE p
    SET p.PointStatus = N'Đang bận'
    FROM Infrastructure.ChargingPoint p
    INNER JOIN inserted i ON p.PointID = i.PointID
    WHERE i.Status = N'Đang sạc' AND p.PointStatus = N'Khả dụng';

    UPDATE p
    SET p.PointStatus = N'Khả dụng'
    FROM Infrastructure.ChargingPoint p
    INNER JOIN inserted i ON p.PointID = i.PointID
    INNER JOIN deleted d ON i.SessionID = d.SessionID
    WHERE i.Status = N'Đã sạc xong' AND d.Status = N'Đang sạc'
      AND p.PointStatus = N'Đang bận';
END;
GO

-- ========================================
-- trg_Transactions_ValidateData
-- Validates transaction amount matches session cost
-- and prevents duplicate transactions per session.
-- ========================================
CREATE OR ALTER TRIGGER Operations.trg_Transactions_ValidateData
ON Operations.Transactions
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN Operations.ChargingSession s ON i.SessionID = s.SessionID
        WHERE i.Amount != s.CostTotal
    )
    BEGIN
        ROLLBACK TRANSACTION;
        RAISERROR(N'Số tiền giao dịch không khớp với chi phí phiên sạc.', 16, 1);
        RETURN;
    END;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        WHERE EXISTS (
            SELECT 1 FROM Operations.Transactions t
            WHERE t.SessionID = i.SessionID AND t.TransactionID <> i.TransactionID
        )
    )
    BEGIN
        ROLLBACK TRANSACTION;
        RAISERROR(N'Phiên sạc này đã có giao dịch, không thể tạo trùng lặp.', 16, 1);
        RETURN;
    END;
END;
GO

-- ========================================
-- trg_ChargingPoint_AutoErrorLog
-- Automatically inserts an error log when a point's status changes to 'Đang lỗi'.
-- ========================================
CREATE OR ALTER TRIGGER Infrastructure.trg_ChargingPoint_AutoErrorLog
ON Infrastructure.ChargingPoint
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Monitoring.ErrorLogs (PointID, ErrorCode, Description, OccurredAt, Severity)
    SELECT
        i.PointID,
        N'AUTO_ERR',
        N'Điểm sạc tự động chuyển sang trạng thái lỗi.',
        SYSDATETIME(),
        N'Trung bình'
    FROM inserted i
    INNER JOIN deleted d ON i.PointID = d.PointID
    WHERE i.PointStatus = N'Đang lỗi' AND d.PointStatus <> N'Đang lỗi';
END;
GO

PRINT N'Triggers created successfully.';
GO
