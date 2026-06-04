==============================================================================
-- 4.2.6 Nhom Stored Procedure quan ly van hanh he thong
==============================================================================


==============================================================================
-- Operations.sp_CreateVehicle
==============================================================================

--database/05_Create_Stored_Procedures.sql
CREATE OR ALTER PROCEDURE Operations.sp_CreateVehicle
    @UserID INT,
    @PlateNumber NVARCHAR(20),
    @Brand NVARCHAR(50),
    @Model NVARCHAR(80),
    @BatteryCapacityKWh DECIMAL(8,2) = NULL,
    @PreferredConnectorTypeID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF (COALESCE(CAST(SESSION_CONTEXT(N'RoleCode') AS NVARCHAR(40)), N'') = N'Customer' OR IS_ROLEMEMBER(N'db_ev_customer') = 1)
           AND ISNULL(@UserID, -1) <> ISNULL(TRY_CONVERT(INT, SESSION_CONTEXT(N'UserID')), -2147483648)
            THROW 52022, 'Customer can only create vehicle for current session user.', 1;

        IF NOT EXISTS (SELECT 1 FROM [Identity].UserAccount WHERE UserID = @UserID AND AccountStatus = N'Active')
            THROW 52020, 'Active user does not exist.', 1;
        IF @PreferredConnectorTypeID IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Infrastructure.ConnectorType WHERE ConnectorTypeID = @PreferredConnectorTypeID AND IsActive = 1)
            THROW 52021, 'Connector type does not exist.', 1;

        INSERT INTO Operations.Vehicle (UserID, PlateNumber, Brand, Model, BatteryCapacityKWh, PreferredConnectorTypeID)
        VALUES (@UserID, @PlateNumber, @Brand, @Model, @BatteryCapacityKWh, @PreferredConnectorTypeID);

        DECLARE @VehicleID INT = SCOPE_IDENTITY();

        INSERT INTO Audit.AuditLog (SchemaName, TableName, RecordID, ActionType, NewValues)
        VALUES (N'Operations', N'Vehicle', CAST(@VehicleID AS NVARCHAR(100)), N'INSERT', @PlateNumber);

        COMMIT TRANSACTION;

        SELECT VehicleID, UserID, PlateNumber, Brand, Model, BatteryCapacityKWh, PreferredConnectorTypeID, IsActive
        FROM Operations.Vehicle
        WHERE VehicleID = @VehicleID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- >>> TEST: source kiem thu tinh nang
-- (Trich tu database/features/customer/02_create_vehicle.sql)
USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: them xe moi cho customer01.
- Tham so co the sua: @UserID, @PlateNumber, @Brand, @Model, @BatteryCapacityKWh, @ConnectorTypeID.
- @PlateNumber phai la duy nhat; script dang tu sinh bien so demo de tranh trung.
- Tac dong du lieu: THEM THAT 1 dong vao Operations.Vehicle thong qua Operations.sp_CreateVehicle.
*/

PRINT N'Thêm xe: khách hàng tạo hồ sơ xe mới bằng stored procedure với tham số rõ ràng.';

DECLARE @UserID INT = (SELECT UserID FROM [Identity].UserAccount WHERE Username = N'customer01');
DECLARE @ConnectorTypeID INT = (SELECT TOP 1 ConnectorTypeID FROM Infrastructure.ConnectorType WHERE ConnectorCode = N'CCS2');
DECLARE @PlateNumber NVARCHAR(20) = N'FEATURE-DEMO-' + RIGHT(REPLACE(CONVERT(NVARCHAR(36), NEWID()), N'-', N''), 7);

SELECT VehicleID, PlateNumber, Brand, Model, IsActive
FROM Operations.Vehicle
WHERE UserID = @UserID;

EXEC Operations.sp_CreateVehicle
    @UserID = @UserID,
    @PlateNumber = @PlateNumber,
    @Brand = N'VinFast',
    @Model = N'VF 8',
    @BatteryCapacityKWh = 82.00,
    @PreferredConnectorTypeID = @ConnectorTypeID;

SELECT VehicleID, PlateNumber, Brand, Model, BatteryCapacityKWh, IsActive
FROM Operations.Vehicle
WHERE UserID = @UserID
ORDER BY VehicleID DESC;
GO



==============================================================================
-- Operations.sp_UpdateVehicle
==============================================================================

--database/05_Create_Stored_Procedures.sql
CREATE OR ALTER PROCEDURE Operations.sp_UpdateVehicle
    @VehicleID INT,
    @UserID INT,
    @PlateNumber NVARCHAR(20) = NULL,
    @Brand NVARCHAR(50) = NULL,
    @Model NVARCHAR(80) = NULL,
    @BatteryCapacityKWh DECIMAL(8,2) = NULL,
    @PreferredConnectorTypeID INT = NULL,
    @IsActive BIT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF (COALESCE(CAST(SESSION_CONTEXT(N'RoleCode') AS NVARCHAR(40)), N'') = N'Customer' OR IS_ROLEMEMBER(N'db_ev_customer') = 1)
           AND ISNULL(@UserID, -1) <> ISNULL(TRY_CONVERT(INT, SESSION_CONTEXT(N'UserID')), -2147483648)
            THROW 52032, 'Customer can only update own vehicle.', 1;

        IF NOT EXISTS (SELECT 1 FROM Operations.Vehicle WHERE VehicleID = @VehicleID AND UserID = @UserID)
            THROW 52030, 'Vehicle does not belong to user.', 1;
        IF @PreferredConnectorTypeID IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Infrastructure.ConnectorType WHERE ConnectorTypeID = @PreferredConnectorTypeID AND IsActive = 1)
            THROW 52031, 'Connector type does not exist.', 1;

        UPDATE Operations.Vehicle
        SET PlateNumber = COALESCE(@PlateNumber, PlateNumber),
            Brand = COALESCE(@Brand, Brand),
            Model = COALESCE(@Model, Model),
            BatteryCapacityKWh = COALESCE(@BatteryCapacityKWh, BatteryCapacityKWh),
            PreferredConnectorTypeID = COALESCE(@PreferredConnectorTypeID, PreferredConnectorTypeID),
            IsActive = COALESCE(@IsActive, IsActive)
        WHERE VehicleID = @VehicleID;

        INSERT INTO Audit.AuditLog (SchemaName, TableName, RecordID, ActionType, NewValues)
        VALUES (N'Operations', N'Vehicle', CAST(@VehicleID AS NVARCHAR(100)), N'UPDATE', COALESCE(@PlateNumber, N'Updated vehicle'));

        COMMIT TRANSACTION;

        SELECT VehicleID, UserID, PlateNumber, Brand, Model, BatteryCapacityKWh, PreferredConnectorTypeID, IsActive
        FROM Operations.Vehicle
        WHERE VehicleID = @VehicleID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- >>> TEST: source kiem thu tinh nang
-- (Trich tu database/features/customer/03_update_vehicle.sql)
USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: cap nhat xe gan nhat cua customer01.
- Tham so co the sua: @UserID, @VehicleID, @Model, @BatteryCapacityKWh, @IsActive.
- @VehicleID phai thuoc dung @UserID, neu khong procedure se bao loi.
- Tac dong du lieu: SUA THAT Operations.Vehicle, khong tao dong moi.
*/

PRINT N'Cập nhật xe: khách hàng chỉnh sửa thông tin xe và trạng thái sử dụng của xe.';

DECLARE @UserID INT = (SELECT UserID FROM [Identity].UserAccount WHERE Username = N'customer01');
DECLARE @VehicleID INT = (SELECT TOP 1 VehicleID FROM Operations.Vehicle WHERE UserID = @UserID ORDER BY VehicleID DESC);

SELECT VehicleID, PlateNumber, Brand, Model, BatteryCapacityKWh, IsActive
FROM Operations.Vehicle
WHERE VehicleID = @VehicleID;

EXEC Operations.sp_UpdateVehicle
    @VehicleID = @VehicleID,
    @UserID = @UserID,
    @Model = N'VF 8 Plus',
    @BatteryCapacityKWh = 87.70,
    @IsActive = 1;

SELECT VehicleID, PlateNumber, Brand, Model, BatteryCapacityKWh, IsActive
FROM Operations.Vehicle
WHERE VehicleID = @VehicleID;
GO



==============================================================================
-- Operations.sp_CreateBooking
==============================================================================

--database/05_Create_Stored_Procedures.sql
CREATE OR ALTER PROCEDURE Operations.sp_CreateBooking
    @UserID INT,
    @VehicleID INT = NULL,
    @PointID INT,
    @BookedFrom DATETIME2,
    @BookedTo DATETIME2
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF (COALESCE(CAST(SESSION_CONTEXT(N'RoleCode') AS NVARCHAR(40)), N'') = N'Customer' OR IS_ROLEMEMBER(N'db_ev_customer') = 1)
           AND ISNULL(@UserID, -1) <> ISNULL(TRY_CONVERT(INT, SESSION_CONTEXT(N'UserID')), -2147483648)
            THROW 52046, 'Customer can only create booking for current session user.', 1;

        IF @BookedFrom >= @BookedTo
            THROW 52040, 'BookedFrom must be before BookedTo.', 1;
        IF NOT EXISTS (SELECT 1 FROM [Identity].UserAccount WHERE UserID = @UserID AND AccountStatus = N'Active')
            THROW 52041, 'Active user does not exist.', 1;
        IF @VehicleID IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Operations.Vehicle WHERE VehicleID = @VehicleID AND UserID = @UserID AND IsActive = 1)
            THROW 52042, 'Vehicle does not belong to user.', 1;

        DECLARE @StationID INT, @PointStatus NVARCHAR(30);
        SELECT @StationID = StationID, @PointStatus = PointStatus
        FROM Infrastructure.ChargingPoint
        WHERE PointID = @PointID;

        IF @StationID IS NULL
            THROW 52043, 'Charging point does not exist.', 1;
        IF @PointStatus NOT IN (N'Available', N'Reserved')
            THROW 52044, 'Charging point is not bookable.', 1;
        IF EXISTS (
            SELECT 1
            FROM Operations.Booking
            WHERE PointID = @PointID
              AND BookingStatus IN (N'Pending', N'Confirmed', N'Active')
              AND BookedFrom < @BookedTo
              AND BookedTo > @BookedFrom
        )
            THROW 52045, 'Charging point already has an overlapping booking.', 1;

        INSERT INTO Operations.Booking
            (BookingCode, UserID, VehicleID, StationID, PointID, BookedFrom, BookedTo, BookingStatus)
        VALUES
            (N'BKG-' + FORMAT(SYSDATETIME(), 'yyyyMMddHHmmss') + N'-' + RIGHT(CONVERT(NVARCHAR(36), NEWID()), 6),
             @UserID, @VehicleID, @StationID, @PointID, @BookedFrom, @BookedTo, N'Confirmed');

        DECLARE @BookingID BIGINT = SCOPE_IDENTITY();

        INSERT INTO Audit.AuditLog (SchemaName, TableName, RecordID, ActionType, NewValues)
        VALUES (N'Operations', N'Booking', CAST(@BookingID AS NVARCHAR(100)), N'INSERT', N'Confirmed');

        COMMIT TRANSACTION;

        SELECT BookingID, BookingCode, UserID, VehicleID, StationID, PointID, BookedFrom, BookedTo, BookingStatus
        FROM Operations.Booking
        WHERE BookingID = @BookingID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- >>> TEST: source kiem thu tinh nang
-- (Trich tu database/features/customer/04_create_booking.sql)
USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: tao lich dat sac cho customer01.
- Tham so co the sua: @UserID, @VehicleID, @PointID, @BookedFrom, @BookedTo.
- @BookedFrom phai nho hon @BookedTo; @PointID khong duoc co booking trung gio.
- Tac dong du lieu: THEM THAT 1 dong vao Operations.Booking voi trang thai Confirmed.
*/

PRINT N'Tạo lịch đặt sạc: khách hàng đặt trước cổng sạc theo khoảng thời gian hợp lệ.';

DECLARE @UserID INT = (SELECT UserID FROM [Identity].UserAccount WHERE Username = N'customer01');
DECLARE @VehicleID INT = (SELECT TOP 1 VehicleID FROM Operations.Vehicle WHERE UserID = @UserID AND IsActive = 1 ORDER BY VehicleID DESC);
DECLARE @PointID INT = (SELECT TOP 1 PointID FROM AppView.vw_AvailableChargingPoints ORDER BY PointID);
DECLARE @BookedFrom DATETIME2 = DATEADD(MINUTE, (ABS(CHECKSUM(NEWID())) % 100000) + 60, SYSDATETIME());
DECLARE @BookedTo DATETIME2 = DATEADD(HOUR, 1, @BookedFrom);

SELECT TOP 10 *
FROM AppView.vw_CustomerBookingHistory
WHERE UserID = @UserID
ORDER BY CreatedAt DESC;

EXEC Operations.sp_CreateBooking
    @UserID = @UserID,
    @VehicleID = @VehicleID,
    @PointID = @PointID,
    @BookedFrom = @BookedFrom,
    @BookedTo = @BookedTo;

SELECT TOP 10 *
FROM AppView.vw_CustomerBookingHistory
WHERE UserID = @UserID
ORDER BY CreatedAt DESC;
GO



==============================================================================
-- Operations.sp_CancelBooking
==============================================================================

--database/05_Create_Stored_Procedures.sql
CREATE OR ALTER PROCEDURE Operations.sp_CancelBooking
    @BookingID BIGINT,
    @UserID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF (COALESCE(CAST(SESSION_CONTEXT(N'RoleCode') AS NVARCHAR(40)), N'') = N'Customer' OR IS_ROLEMEMBER(N'db_ev_customer') = 1)
           AND ISNULL(@UserID, -1) <> ISNULL(TRY_CONVERT(INT, SESSION_CONTEXT(N'UserID')), -2147483648)
            THROW 52051, 'Customer can only cancel own booking.', 1;

        IF NOT EXISTS (
            SELECT 1
            FROM Operations.Booking
            WHERE BookingID = @BookingID
              AND (@UserID IS NULL OR UserID = @UserID)
              AND BookingStatus IN (N'Pending', N'Confirmed', N'Active')
        )
            THROW 52050, 'Booking cannot be cancelled.', 1;

        UPDATE Operations.Booking
        SET BookingStatus = N'Cancelled', UpdatedAt = SYSDATETIME()
        WHERE BookingID = @BookingID;

        INSERT INTO Audit.AuditLog (SchemaName, TableName, RecordID, ActionType, NewValues)
        VALUES (N'Operations', N'Booking', CAST(@BookingID AS NVARCHAR(100)), N'UPDATE', N'Cancelled');

        COMMIT TRANSACTION;

        SELECT BookingID, BookingCode, UserID, PointID, BookedFrom, BookedTo, BookingStatus
        FROM Operations.Booking
        WHERE BookingID = @BookingID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- >>> TEST: source kiem thu tinh nang
-- (Trich tu database/features/customer/05_cancel_booking.sql)
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



==============================================================================
-- Operations.sp_StartChargingSession
==============================================================================

--database/05_Create_Stored_Procedures.sql
CREATE OR ALTER PROCEDURE Operations.sp_StartChargingSession
    @UserID INT,
    @VehicleID INT = NULL,
    @PointID INT,
    @MeterStart DECIMAL(14,4) = NULL,
    @BookingID BIGINT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF (COALESCE(CAST(SESSION_CONTEXT(N'RoleCode') AS NVARCHAR(40)), N'') = N'Customer' OR IS_ROLEMEMBER(N'db_ev_customer') = 1)
           AND ISNULL(@UserID, -1) <> ISNULL(TRY_CONVERT(INT, SESSION_CONTEXT(N'UserID')), -2147483648)
            THROW 52005, 'Customer can only start session for current session user.', 1;

        DECLARE @PointStatus NVARCHAR(30), @StationID INT;
        SELECT @PointStatus = PointStatus, @StationID = StationID
        FROM Infrastructure.ChargingPoint
        WHERE PointID = @PointID;

        IF @PointStatus IS NULL
            THROW 52001, 'Charging point does not exist.', 1;
        IF @PointStatus <> N'Available'
            THROW 52002, 'Charging point is not available.', 1;

        IF NOT EXISTS (SELECT 1 FROM [Identity].UserAccount WHERE UserID = @UserID AND AccountStatus = N'Active')
            THROW 52003, 'User account is not active.', 1;
        IF @VehicleID IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Operations.Vehicle WHERE VehicleID = @VehicleID AND UserID = @UserID AND IsActive = 1)
            THROW 52006, 'Vehicle does not belong to user.', 1;
        IF @BookingID IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Operations.Booking WHERE BookingID = @BookingID AND UserID = @UserID AND PointID = @PointID AND BookingStatus IN (N'Confirmed', N'Active'))
            THROW 52007, 'Booking does not belong to user or point.', 1;

        DECLARE @PolicyID INT;
        SELECT TOP 1 @PolicyID = PolicyID
        FROM Operations.PricingPolicy
        WHERE IsActive = 1
          AND AppliedFrom <= SYSDATETIME()
          AND (AppliedTo IS NULL OR AppliedTo >= SYSDATETIME())
        ORDER BY AppliedFrom DESC;

        IF @PolicyID IS NULL
            THROW 52004, 'No active pricing policy.', 1;

        IF @MeterStart IS NULL
        BEGIN
            SELECT @MeterStart = MAX(MeterEnd)
            FROM Operations.ChargingSession
            WHERE PointID = @PointID
              AND MeterEnd IS NOT NULL;

            SET @MeterStart = ISNULL(@MeterStart, 100000.0000);
        END;

        DECLARE @SessionID BIGINT;
        INSERT INTO Operations.ChargingSession
            (SessionCode, UserID, VehicleID, StationID, PointID, PolicyID, BookingID, MeterStart, SessionStatus)
        VALUES
            (N'SES-' + FORMAT(SYSDATETIME(), 'yyyyMMddHHmmss') + N'-' + RIGHT(CONVERT(NVARCHAR(36), NEWID()), 6),
             @UserID, @VehicleID, @StationID, @PointID, @PolicyID, @BookingID, @MeterStart, N'Charging');

        SET @SessionID = SCOPE_IDENTITY();

        UPDATE Infrastructure.ChargingPoint
        SET PointStatus = N'Charging', UpdatedAt = SYSDATETIME()
        WHERE PointID = @PointID;

        IF @BookingID IS NOT NULL
            UPDATE Operations.Booking SET BookingStatus = N'Active', UpdatedAt = SYSDATETIME() WHERE BookingID = @BookingID;

        INSERT INTO Operations.SessionEvent (SessionID, EventType, EventPayload)
        VALUES (@SessionID, N'Started', N'Charging session started');

        COMMIT TRANSACTION;

        SELECT SessionID, SessionCode, UserID, StationID, PointID, SessionStatus, StartTime
        FROM Operations.ChargingSession
        WHERE SessionID = @SessionID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- >>> TEST: source kiem thu tinh nang
-- (Trich tu database/features/customer/07_start_end_charging_session.sql)
USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: tao phien sac moi, sau do ket thuc phien va tinh tien.
- Tham so co the sua: @UserID, @VehicleID, @PointID, @MeterStart, @MeterEnd.
- @MeterEnd phai lon hon hoac bang @MeterStart.
- Tac dong du lieu: THEM THAT ChargingSession va SessionEvent; cap nhat trang thai ChargingPoint trong luc chay roi tra ve Available.
*/

PRINT N'Bắt đầu và kết thúc phiên sạc: khách hàng mở phiên sạc, kết thúc phiên và hệ thống tính kWh, chi phí.';

DECLARE @UserID INT = (SELECT UserID FROM [Identity].UserAccount WHERE Username = N'customer01');
DECLARE @VehicleID INT = (SELECT TOP 1 VehicleID FROM Operations.Vehicle WHERE UserID = @UserID AND IsActive = 1 ORDER BY VehicleID DESC);
DECLARE @PointID INT = (SELECT TOP 1 PointID FROM AppView.vw_AvailableChargingPoints ORDER BY PointID);
DECLARE @Started TABLE (SessionID BIGINT, SessionCode NVARCHAR(40), UserID INT, StationID INT, PointID INT, SessionStatus NVARCHAR(30), StartTime DATETIME2);
DECLARE @SessionID BIGINT;

SELECT TOP 5 *
FROM AppView.vw_ActiveChargingSessions
ORDER BY StartTime DESC;

INSERT INTO @Started
EXEC Operations.sp_StartChargingSession
    @UserID = @UserID,
    @VehicleID = @VehicleID,
    @PointID = @PointID,
    @MeterStart = 1000.00;

SELECT @SessionID = SessionID FROM @Started;
SELECT * FROM @Started;

EXEC Operations.sp_EndChargingSession
    @SessionID = @SessionID,
    @MeterEnd = 1022.50;

SELECT TOP 10 *
FROM AppView.vw_CustomerChargingHistory
WHERE UserID = @UserID
ORDER BY StartTime DESC;
GO



==============================================================================
-- Operations.sp_EndChargingSession
==============================================================================

--database/05_Create_Stored_Procedures.sql
CREATE OR ALTER PROCEDURE Operations.sp_EndChargingSession
    @SessionID BIGINT,
    @MeterEnd DECIMAL(14,4) = NULL,
    @TotalKWh DECIMAL(14,4) = NULL,
    @StopReason NVARCHAR(60) = N'Completed'
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @PointID INT, @PolicyID INT, @StartTime DATETIME2, @MeterStart DECIMAL(14,4), @Status NVARCHAR(30), @PointPowerKW DECIMAL(8,2);
        SELECT @PointID = PointID, @PolicyID = PolicyID, @StartTime = StartTime, @MeterStart = MeterStart, @Status = SessionStatus
        FROM Operations.ChargingSession
        WHERE SessionID = @SessionID;

        IF @Status IS NULL
            THROW 52010, 'Charging session does not exist.', 1;
        IF (COALESCE(CAST(SESSION_CONTEXT(N'RoleCode') AS NVARCHAR(40)), N'') = N'Customer' OR IS_ROLEMEMBER(N'db_ev_customer') = 1)
           AND NOT EXISTS (
                SELECT 1
                FROM Operations.ChargingSession
                WHERE SessionID = @SessionID
                  AND UserID = TRY_CONVERT(INT, SESSION_CONTEXT(N'UserID'))
           )
            THROW 52013, 'Customer can only end own charging session.', 1;
        IF @Status <> N'Charging'
            THROW 52011, 'Charging session is not in Charging status.', 1;

        SELECT @PointPowerKW = PowerKW
        FROM Infrastructure.ChargingPoint
        WHERE PointID = @PointID;

        IF @TotalKWh IS NULL AND @MeterEnd IS NOT NULL AND @MeterStart IS NOT NULL
            SET @TotalKWh = @MeterEnd - @MeterStart;

        IF @TotalKWh IS NULL
        BEGIN
            DECLARE @ElapsedSeconds INT = DATEDIFF(SECOND, @StartTime, SYSDATETIME());
            DECLARE @EffectiveSeconds INT = CASE WHEN @ElapsedSeconds < 60 THEN 60 ELSE @ElapsedSeconds END;
            DECLARE @Utilization DECIMAL(6,4) = CAST(0.38 + ((ABS(CHECKSUM(@SessionID)) % 33) / 100.0) AS DECIMAL(6,4));

            SET @TotalKWh = ROUND(ISNULL(@PointPowerKW, 22) * (@EffectiveSeconds / 3600.0) * @Utilization, 4);
        END;

        IF @TotalKWh <= 0
            SET @TotalKWh = 0.1000;

        IF @MeterEnd IS NULL AND @MeterStart IS NOT NULL
            SET @MeterEnd = @MeterStart + @TotalKWh;

        DECLARE @CostBeforeTax DECIMAL(19,4) = Operations.fn_CalculateChargingCost(@TotalKWh, @PolicyID, @StartTime);
        DECLARE @TaxAmount DECIMAL(19,4) = ROUND(@CostBeforeTax * 0.08, 4);

        UPDATE Operations.ChargingSession
        SET EndTime = SYSDATETIME(),
            MeterEnd = @MeterEnd,
            TotalKWh = @TotalKWh,
            DurationMinutes = CASE WHEN DATEDIFF(MINUTE, @StartTime, SYSDATETIME()) < 1 THEN 1 ELSE DATEDIFF(MINUTE, @StartTime, SYSDATETIME()) END,
            CostBeforeTax = @CostBeforeTax,
            TaxAmount = @TaxAmount,
            CostTotal = @CostBeforeTax + @TaxAmount,
            StopReason = @StopReason,
            SessionStatus = N'Completed',
            UpdatedAt = SYSDATETIME()
        WHERE SessionID = @SessionID;

        UPDATE Infrastructure.ChargingPoint
        SET PointStatus = N'Available', UpdatedAt = SYSDATETIME()
        WHERE PointID = @PointID;

        INSERT INTO Operations.SessionEvent (SessionID, EventType, EventPayload)
        VALUES (@SessionID, N'Completed', N'Charging session completed');

        COMMIT TRANSACTION;

        SELECT SessionID, SessionCode, TotalKWh, CostBeforeTax, TaxAmount, CostTotal, SessionStatus
        FROM Operations.ChargingSession
        WHERE SessionID = @SessionID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- >>> TEST: source kiem thu tinh nang
-- (Trich tu database/features/customer/07_start_end_charging_session.sql)
USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: tao phien sac moi, sau do ket thuc phien va tinh tien.
- Tham so co the sua: @UserID, @VehicleID, @PointID, @MeterStart, @MeterEnd.
- @MeterEnd phai lon hon hoac bang @MeterStart.
- Tac dong du lieu: THEM THAT ChargingSession va SessionEvent; cap nhat trang thai ChargingPoint trong luc chay roi tra ve Available.
*/

PRINT N'Bắt đầu và kết thúc phiên sạc: khách hàng mở phiên sạc, kết thúc phiên và hệ thống tính kWh, chi phí.';

DECLARE @UserID INT = (SELECT UserID FROM [Identity].UserAccount WHERE Username = N'customer01');
DECLARE @VehicleID INT = (SELECT TOP 1 VehicleID FROM Operations.Vehicle WHERE UserID = @UserID AND IsActive = 1 ORDER BY VehicleID DESC);
DECLARE @PointID INT = (SELECT TOP 1 PointID FROM AppView.vw_AvailableChargingPoints ORDER BY PointID);
DECLARE @Started TABLE (SessionID BIGINT, SessionCode NVARCHAR(40), UserID INT, StationID INT, PointID INT, SessionStatus NVARCHAR(30), StartTime DATETIME2);
DECLARE @SessionID BIGINT;

SELECT TOP 5 *
FROM AppView.vw_ActiveChargingSessions
ORDER BY StartTime DESC;

INSERT INTO @Started
EXEC Operations.sp_StartChargingSession
    @UserID = @UserID,
    @VehicleID = @VehicleID,
    @PointID = @PointID,
    @MeterStart = 1000.00;

SELECT @SessionID = SessionID FROM @Started;
SELECT * FROM @Started;

EXEC Operations.sp_EndChargingSession
    @SessionID = @SessionID,
    @MeterEnd = 1022.50;

SELECT TOP 10 *
FROM AppView.vw_CustomerChargingHistory
WHERE UserID = @UserID
ORDER BY StartTime DESC;
GO



==============================================================================
-- Operations.sp_MarkChargingSessionFailed
==============================================================================

--database/05_Create_Stored_Procedures.sql
CREATE OR ALTER PROCEDURE Operations.sp_MarkChargingSessionFailed
    @SessionID BIGINT,
    @FailedBy INT = NULL,
    @StopReason NVARCHAR(60) = N'Failed'
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @PointID INT, @Status NVARCHAR(30);
        SELECT @PointID = PointID, @Status = SessionStatus
        FROM Operations.ChargingSession
        WHERE SessionID = @SessionID;

        IF @Status IS NULL
            THROW 52060, 'Charging session does not exist.', 1;
        IF @Status NOT IN (N'Pending', N'Charging')
            THROW 52061, 'Only pending or charging sessions can be marked as failed.', 1;

        UPDATE Operations.ChargingSession
        SET SessionStatus = N'Failed',
            StopReason = @StopReason,
            EndTime = COALESCE(EndTime, SYSDATETIME()),
            UpdatedAt = SYSDATETIME()
        WHERE SessionID = @SessionID;

        UPDATE Infrastructure.ChargingPoint
        SET PointStatus = N'Available', UpdatedAt = SYSDATETIME()
        WHERE PointID = @PointID AND PointStatus = N'Charging';

        INSERT INTO Operations.SessionEvent (SessionID, EventType, EventPayload)
        VALUES (@SessionID, N'Failed', @StopReason);

        INSERT INTO Audit.AuditLog (SchemaName, TableName, RecordID, ActionType, OldValues, NewValues, ChangedBy)
        VALUES (N'Operations', N'ChargingSession', CAST(@SessionID AS NVARCHAR(100)), N'UPDATE', @Status, N'Failed', COALESCE(CAST(@FailedBy AS NVARCHAR(128)), ORIGINAL_LOGIN()));

        COMMIT TRANSACTION;

        SELECT SessionID, SessionCode, SessionStatus, StopReason, EndTime
        FROM Operations.ChargingSession
        WHERE SessionID = @SessionID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- >>> TEST: source kiem thu tinh nang
-- (Trich tu database/features/operations_staff/05_mark_session_failed.sql)
USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: tao 1 phien sac dang chay roi danh dau la Failed.
- Tham so co the sua: @UserID, @VehicleID, @PointID, @OperatorID, @StopReason.
- Tac dong du lieu: THEM THAT ChargingSession va SessionEvent; cap nhat SessionStatus sang Failed.
*/

PRINT N'Xử lý phiên sạc lỗi: nhân viên vận hành đánh dấu phiên đang sạc thành thất bại và giải phóng cổng.';

DECLARE @UserID INT = (SELECT UserID FROM [Identity].UserAccount WHERE Username = N'customer02');
DECLARE @VehicleID INT = (SELECT TOP 1 VehicleID FROM Operations.Vehicle WHERE UserID = @UserID AND IsActive = 1 ORDER BY VehicleID);
DECLARE @PointID INT = (SELECT TOP 1 PointID FROM AppView.vw_AvailableChargingPoints ORDER BY PointID);
DECLARE @OperatorID INT = (SELECT UserID FROM [Identity].UserAccount WHERE Username = N'operator01');
DECLARE @Started TABLE (SessionID BIGINT, SessionCode NVARCHAR(40), UserID INT, StationID INT, PointID INT, SessionStatus NVARCHAR(30), StartTime DATETIME2);
DECLARE @SessionID BIGINT;

INSERT INTO @Started
EXEC Operations.sp_StartChargingSession @UserID = @UserID, @VehicleID = @VehicleID, @PointID = @PointID, @MeterStart = 3000.00;

SELECT @SessionID = SessionID FROM @Started;

SELECT *
FROM AppView.vw_ActiveChargingSessions
WHERE SessionID = @SessionID;

EXEC Operations.sp_MarkChargingSessionFailed
    @SessionID = @SessionID,
    @FailedBy = @OperatorID,
    @StopReason = N'FEATURE-DEMO-Connector fault';

SELECT SessionID, SessionCode, SessionStatus, StopReason, EndTime
FROM Operations.ChargingSession
WHERE SessionID = @SessionID;
GO



==============================================================================
-- Operations.sp_CreatePricingPolicy
==============================================================================

--database/05_Create_Stored_Procedures.sql
CREATE OR ALTER PROCEDURE Operations.sp_CreatePricingPolicy
    @PolicyCode NVARCHAR(30),
    @PolicyName NVARCHAR(150),
    @BasePricePerKWh DECIMAL(19,4),
    @PeakMultiplier DECIMAL(5,2) = 1.20,
    @PeakStartHour TIME(0) = NULL,
    @PeakEndHour TIME(0) = NULL,
    @AppliedFrom DATETIME2,
    @AppliedTo DATETIME2 = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF @BasePricePerKWh < 0
            THROW 52070, 'Base price must be non-negative.', 1;
        IF @PeakMultiplier < 1
            THROW 52071, 'Peak multiplier must be at least 1.', 1;
        IF @AppliedTo IS NOT NULL AND @AppliedFrom >= @AppliedTo
            THROW 52072, 'AppliedFrom must be before AppliedTo.', 1;

        INSERT INTO Operations.PricingPolicy
            (PolicyCode, PolicyName, BasePricePerKWh, PeakMultiplier, PeakStartHour, PeakEndHour, AppliedFrom, AppliedTo)
        VALUES
            (@PolicyCode, @PolicyName, @BasePricePerKWh, @PeakMultiplier, @PeakStartHour, @PeakEndHour, @AppliedFrom, @AppliedTo);

        DECLARE @PolicyID INT = SCOPE_IDENTITY();

        INSERT INTO Audit.AuditLog (SchemaName, TableName, RecordID, ActionType, NewValues)
        VALUES (N'Operations', N'PricingPolicy', CAST(@PolicyID AS NVARCHAR(100)), N'INSERT', @PolicyCode);

        COMMIT TRANSACTION;

        SELECT PolicyID, PolicyCode, PolicyName, BasePricePerKWh, PeakMultiplier, IsActive
        FROM Operations.PricingPolicy
        WHERE PolicyID = @PolicyID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- >>> TEST: source kiem thu tinh nang
-- (Trich tu database/features/business_manager/01_manage_pricing_policy.sql)
USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: tao chinh sach gia moi va vo hieu hoa chinh sach vua tao.
- Tham so co the sua: @PolicyCode, @PolicyName, @BasePricePerKWh, @PeakMultiplier, gio cao diem.
- Tac dong du lieu: THEM THAT PricingPolicy, sau do cap nhat IsActive = 0 cho policy vua tao.
*/

PRINT N'Quản lý chính sách giá: quản lý kinh doanh tạo chính sách giá mới và vô hiệu hóa chính sách khi cần.';

DECLARE @PolicyCode NVARCHAR(30) = N'FEATURE-DEMO-PRICE-' + RIGHT(REPLACE(CONVERT(NVARCHAR(36), NEWID()), N'-', N''), 6);
DECLARE @Created TABLE (PolicyID INT, PolicyCode NVARCHAR(30), PolicyName NVARCHAR(150), BasePricePerKWh DECIMAL(19,4), PeakMultiplier DECIMAL(5,2), IsActive BIT);
DECLARE @PolicyID INT;

SELECT TOP 10 PolicyID, PolicyCode, PolicyName, BasePricePerKWh, PeakMultiplier, IsActive
FROM Operations.PricingPolicy
ORDER BY PolicyID DESC;

INSERT INTO @Created
EXEC Operations.sp_CreatePricingPolicy
    @PolicyCode = @PolicyCode,
    @PolicyName = N'FEATURE-DEMO flexible price',
    @BasePricePerKWh = 3900.00,
    @PeakMultiplier = 1.30,
    @PeakStartHour = '17:00',
    @PeakEndHour = '20:00',
    @AppliedFrom = '2026-06-01';

SELECT @PolicyID = PolicyID FROM @Created;
SELECT * FROM @Created;

EXEC Operations.sp_DeactivatePricingPolicy @PolicyID = @PolicyID;

SELECT PolicyID, PolicyCode, PolicyName, BasePricePerKWh, PeakMultiplier, IsActive
FROM Operations.PricingPolicy
WHERE PolicyID = @PolicyID;
GO



==============================================================================
-- Operations.sp_DeactivatePricingPolicy
==============================================================================

--database/05_Create_Stored_Procedures.sql
CREATE OR ALTER PROCEDURE Operations.sp_DeactivatePricingPolicy
    @PolicyID INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1 FROM Operations.PricingPolicy WHERE PolicyID = @PolicyID)
            THROW 52080, 'Pricing policy does not exist.', 1;

        UPDATE Operations.PricingPolicy
        SET IsActive = 0
        WHERE PolicyID = @PolicyID;

        INSERT INTO Audit.AuditLog (SchemaName, TableName, RecordID, ActionType, NewValues)
        VALUES (N'Operations', N'PricingPolicy', CAST(@PolicyID AS NVARCHAR(100)), N'UPDATE', N'Inactive');

        COMMIT TRANSACTION;

        SELECT PolicyID, PolicyCode, PolicyName, IsActive
        FROM Operations.PricingPolicy
        WHERE PolicyID = @PolicyID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- >>> TEST: source kiem thu tinh nang
-- (Trich tu database/features/business_manager/01_manage_pricing_policy.sql)
USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: tao chinh sach gia moi va vo hieu hoa chinh sach vua tao.
- Tham so co the sua: @PolicyCode, @PolicyName, @BasePricePerKWh, @PeakMultiplier, gio cao diem.
- Tac dong du lieu: THEM THAT PricingPolicy, sau do cap nhat IsActive = 0 cho policy vua tao.
*/

PRINT N'Quản lý chính sách giá: quản lý kinh doanh tạo chính sách giá mới và vô hiệu hóa chính sách khi cần.';

DECLARE @PolicyCode NVARCHAR(30) = N'FEATURE-DEMO-PRICE-' + RIGHT(REPLACE(CONVERT(NVARCHAR(36), NEWID()), N'-', N''), 6);
DECLARE @Created TABLE (PolicyID INT, PolicyCode NVARCHAR(30), PolicyName NVARCHAR(150), BasePricePerKWh DECIMAL(19,4), PeakMultiplier DECIMAL(5,2), IsActive BIT);
DECLARE @PolicyID INT;

SELECT TOP 10 PolicyID, PolicyCode, PolicyName, BasePricePerKWh, PeakMultiplier, IsActive
FROM Operations.PricingPolicy
ORDER BY PolicyID DESC;

INSERT INTO @Created
EXEC Operations.sp_CreatePricingPolicy
    @PolicyCode = @PolicyCode,
    @PolicyName = N'FEATURE-DEMO flexible price',
    @BasePricePerKWh = 3900.00,
    @PeakMultiplier = 1.30,
    @PeakStartHour = '17:00',
    @PeakEndHour = '20:00',
    @AppliedFrom = '2026-06-01';

SELECT @PolicyID = PolicyID FROM @Created;
SELECT * FROM @Created;

EXEC Operations.sp_DeactivatePricingPolicy @PolicyID = @PolicyID;

SELECT PolicyID, PolicyCode, PolicyName, BasePricePerKWh, PeakMultiplier, IsActive
FROM Operations.PricingPolicy
WHERE PolicyID = @PolicyID;
GO
