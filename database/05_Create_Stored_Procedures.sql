USE EV_Charging_System;
GO

CREATE OR ALTER PROCEDURE [Identity].sp_CreateUser
    @Username NVARCHAR(50),
    @Email NVARCHAR(120),
    @Phone NVARCHAR(20) = NULL,
    @PasswordHash NVARCHAR(256),
    @FullName NVARCHAR(120),
    @RoleCode NVARCHAR(40)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @RoleID INT = (SELECT RoleID FROM [Identity].Role WHERE RoleCode = @RoleCode);
        IF @RoleID IS NULL
            THROW 51001, 'Role does not exist.', 1;

        INSERT INTO [Identity].UserAccount (Username, Email, Phone, PasswordHash, FullName)
        VALUES (@Username, @Email, @Phone, @PasswordHash, @FullName);

        DECLARE @UserID INT = SCOPE_IDENTITY();
        INSERT INTO [Identity].UserRole (UserID, RoleID) VALUES (@UserID, @RoleID);

        INSERT INTO Audit.AuditLog (SchemaName, TableName, RecordID, ActionType, NewValues)
        VALUES (N'Identity', N'UserAccount', CAST(@UserID AS NVARCHAR(100)), N'INSERT', @Username);

        COMMIT TRANSACTION;

        SELECT UserID, Username, Email, FullName, AccountStatus
        FROM [Identity].UserAccount
        WHERE UserID = @UserID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE [Identity].sp_RegisterCustomer
    @Username NVARCHAR(50),
    @Email NVARCHAR(120),
    @Phone NVARCHAR(20) = NULL,
    @PasswordHash NVARCHAR(256),
    @FullName NVARCHAR(120)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF EXISTS (SELECT 1 FROM [Identity].UserAccount WHERE Username = @Username)
            THROW 51101, N'Tên đăng nhập đã được sử dụng.', 1;
        IF EXISTS (SELECT 1 FROM [Identity].UserAccount WHERE Email = @Email)
            THROW 51102, N'Email đã được sử dụng.', 1;
        IF @Phone IS NOT NULL AND EXISTS (SELECT 1 FROM [Identity].UserAccount WHERE Phone = @Phone)
            THROW 51103, N'Số điện thoại đã được sử dụng.', 1;

        DECLARE @RoleID INT = (SELECT RoleID FROM [Identity].Role WHERE RoleCode = N'Customer');
        IF @RoleID IS NULL
            THROW 51104, N'Vai trò Customer chưa tồn tại.', 1;

        INSERT INTO [Identity].UserAccount (Username, Email, Phone, PasswordHash, FullName, AccountStatus)
        VALUES (@Username, @Email, NULLIF(@Phone, N''), @PasswordHash, @FullName, N'Active');

        DECLARE @UserID INT = SCOPE_IDENTITY();
        INSERT INTO [Identity].UserRole (UserID, RoleID) VALUES (@UserID, @RoleID);

        INSERT INTO [Identity].AuthEvent (UserID, Identifier, EventType, EventStatus)
        VALUES (@UserID, @Username, N'Register', N'Success');

        INSERT INTO Audit.AuditLog (SchemaName, TableName, RecordID, ActionType, NewValues)
        VALUES (N'Identity', N'UserAccount', CAST(@UserID AS NVARCHAR(100)), N'SECURITY', N'Register customer');

        COMMIT TRANSACTION;

        SELECT UserID, Username, Email, Phone, FullName, AccountStatus
        FROM [Identity].UserAccount
        WHERE UserID = @UserID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE [Identity].sp_RequestPasswordReset
    @Identifier NVARCHAR(120),
    @TokenHash NVARCHAR(128),
    @ExpiresAt DATETIME2
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @UserID INT = (
        SELECT TOP 1 UserID
        FROM [Identity].UserAccount
        WHERE Username = @Identifier OR Email = @Identifier OR Phone = @Identifier
    );

    IF @UserID IS NULL
    BEGIN
        INSERT INTO [Identity].AuthEvent (Identifier, EventType, EventStatus)
        VALUES (@Identifier, N'PasswordResetRequested', N'Ignored');
        SELECT CAST(NULL AS INT) AS UserID;
        RETURN;
    END;

    INSERT INTO [Identity].AuthToken (UserID, TokenType, TokenHash, ExpiresAt)
    VALUES (@UserID, N'PasswordReset', @TokenHash, @ExpiresAt);

    INSERT INTO [Identity].AuthEvent (UserID, Identifier, EventType, EventStatus)
    VALUES (@UserID, @Identifier, N'PasswordResetRequested', N'Success');

    SELECT @UserID AS UserID;
END;
GO

CREATE OR ALTER PROCEDURE [Identity].sp_ResetPasswordByToken
    @TokenHash NVARCHAR(128),
    @PasswordHash NVARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @UserID INT = (
            SELECT TOP 1 UserID
            FROM [Identity].AuthToken WITH (UPDLOCK, HOLDLOCK)
            WHERE TokenHash = @TokenHash
              AND TokenType = N'PasswordReset'
              AND ConsumedAt IS NULL
              AND ExpiresAt >= SYSDATETIME()
        );

        IF @UserID IS NULL
            THROW 51110, N'Token đặt lại mật khẩu không hợp lệ hoặc đã hết hạn.', 1;

        UPDATE [Identity].UserAccount
        SET PasswordHash = @PasswordHash, UpdatedAt = SYSDATETIME()
        WHERE UserID = @UserID;

        UPDATE [Identity].AuthToken
        SET ConsumedAt = SYSDATETIME()
        WHERE TokenHash = @TokenHash;

        INSERT INTO [Identity].AuthEvent (UserID, EventType, EventStatus)
        VALUES (@UserID, N'PasswordResetCompleted', N'Success');

        INSERT INTO Audit.AuditLog (SchemaName, TableName, RecordID, ActionType, NewValues)
        VALUES (N'Identity', N'UserAccount', CAST(@UserID AS NVARCHAR(100)), N'SECURITY', N'Password reset by token');

        COMMIT TRANSACTION;

        SELECT UserID, Username, Email, AccountStatus, UpdatedAt
        FROM [Identity].UserAccount
        WHERE UserID = @UserID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE [Identity].sp_VerifyEmailToken
    @TokenHash NVARCHAR(128)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @UserID INT = (
            SELECT TOP 1 UserID
            FROM [Identity].AuthToken WITH (UPDLOCK, HOLDLOCK)
            WHERE TokenHash = @TokenHash
              AND TokenType = N'EmailVerification'
              AND ConsumedAt IS NULL
              AND ExpiresAt >= SYSDATETIME()
        );

        IF @UserID IS NULL
            THROW 51111, N'Token xác minh email không hợp lệ hoặc đã hết hạn.', 1;

        UPDATE [Identity].UserAccount
        SET AccountStatus = N'Active', UpdatedAt = SYSDATETIME()
        WHERE UserID = @UserID AND AccountStatus = N'Pending';

        UPDATE [Identity].AuthToken
        SET ConsumedAt = SYSDATETIME()
        WHERE TokenHash = @TokenHash;

        INSERT INTO [Identity].AuthEvent (UserID, EventType, EventStatus)
        VALUES (@UserID, N'EmailVerified', N'Success');

        COMMIT TRANSACTION;

        SELECT UserID, Username, Email, AccountStatus
        FROM [Identity].UserAccount
        WHERE UserID = @UserID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE [Identity].sp_LockUser
    @UserID INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1 FROM [Identity].UserAccount WHERE UserID = @UserID)
            THROW 51010, 'User does not exist.', 1;

        UPDATE [Identity].UserAccount
        SET AccountStatus = N'Locked', UpdatedAt = SYSDATETIME()
        WHERE UserID = @UserID;

        INSERT INTO Audit.AuditLog (SchemaName, TableName, RecordID, ActionType, NewValues)
        VALUES (N'Identity', N'UserAccount', CAST(@UserID AS NVARCHAR(100)), N'SECURITY', N'Locked');

        COMMIT TRANSACTION;

        SELECT UserID, Username, Email, AccountStatus
        FROM [Identity].UserAccount
        WHERE UserID = @UserID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE [Identity].sp_UnlockUser
    @UserID INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1 FROM [Identity].UserAccount WHERE UserID = @UserID)
            THROW 51011, 'User does not exist.', 1;

        UPDATE [Identity].UserAccount
        SET AccountStatus = N'Active', UpdatedAt = SYSDATETIME()
        WHERE UserID = @UserID;

        INSERT INTO Audit.AuditLog (SchemaName, TableName, RecordID, ActionType, NewValues)
        VALUES (N'Identity', N'UserAccount', CAST(@UserID AS NVARCHAR(100)), N'SECURITY', N'Active');

        COMMIT TRANSACTION;

        SELECT UserID, Username, Email, AccountStatus
        FROM [Identity].UserAccount
        WHERE UserID = @UserID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE [Identity].sp_ResetPassword
    @UserID INT,
    @PasswordHash NVARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1 FROM [Identity].UserAccount WHERE UserID = @UserID)
            THROW 51012, 'User does not exist.', 1;

        UPDATE [Identity].UserAccount
        SET PasswordHash = @PasswordHash, UpdatedAt = SYSDATETIME()
        WHERE UserID = @UserID;

        INSERT INTO Audit.AuditLog (SchemaName, TableName, RecordID, ActionType, NewValues)
        VALUES (N'Identity', N'UserAccount', CAST(@UserID AS NVARCHAR(100)), N'SECURITY', N'Password reset');

        COMMIT TRANSACTION;

        SELECT UserID, Username, Email, AccountStatus, UpdatedAt
        FROM [Identity].UserAccount
        WHERE UserID = @UserID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE [Identity].sp_AssignRole
    @UserID INT,
    @RoleCode NVARCHAR(40)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @RoleID INT = (SELECT RoleID FROM [Identity].Role WHERE RoleCode = @RoleCode);
        IF @RoleID IS NULL
            THROW 51013, 'Role does not exist.', 1;
        IF NOT EXISTS (SELECT 1 FROM [Identity].UserAccount WHERE UserID = @UserID)
            THROW 51014, 'User does not exist.', 1;

        IF NOT EXISTS (SELECT 1 FROM [Identity].UserRole WHERE UserID = @UserID AND RoleID = @RoleID)
            INSERT INTO [Identity].UserRole (UserID, RoleID) VALUES (@UserID, @RoleID);

        INSERT INTO Audit.AuditLog (SchemaName, TableName, RecordID, ActionType, NewValues)
        VALUES (N'Identity', N'UserRole', CAST(@UserID AS NVARCHAR(100)), N'SECURITY', @RoleCode);

        COMMIT TRANSACTION;

        SELECT u.UserID, u.Username, r.RoleCode, r.RoleName
        FROM [Identity].UserRole ur
        JOIN [Identity].UserAccount u ON u.UserID = ur.UserID
        JOIN [Identity].Role r ON r.RoleID = ur.RoleID
        WHERE u.UserID = @UserID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE [Identity].sp_RemoveRole
    @UserID INT,
    @RoleCode NVARCHAR(40)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @RoleID INT = (SELECT RoleID FROM [Identity].Role WHERE RoleCode = @RoleCode);
        IF @RoleID IS NULL
            THROW 51015, 'Role does not exist.', 1;

        DELETE FROM [Identity].UserRole
        WHERE UserID = @UserID AND RoleID = @RoleID;

        INSERT INTO Audit.AuditLog (SchemaName, TableName, RecordID, ActionType, OldValues)
        VALUES (N'Identity', N'UserRole', CAST(@UserID AS NVARCHAR(100)), N'SECURITY', @RoleCode);

        COMMIT TRANSACTION;

        SELECT u.UserID, u.Username, r.RoleCode, r.RoleName
        FROM [Identity].UserRole ur
        JOIN [Identity].UserAccount u ON u.UserID = ur.UserID
        JOIN [Identity].Role r ON r.RoleID = ur.RoleID
        WHERE u.UserID = @UserID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE Infrastructure.sp_CreateChargingStation
    @StationCode NVARCHAR(30),
    @StationName NVARCHAR(200),
    @FranchiseID INT,
    @AddressID INT,
    @SupplierID INT = NULL,
    @StationOperatorID INT = NULL,
    @MaxPowerKW DECIMAL(8,2)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO Infrastructure.ChargingStation
            (StationCode, StationName, FranchiseID, AddressID, SupplierID, StationOperatorID, MaxPowerKW, StationStatus, OpenedAt)
        VALUES
            (@StationCode, @StationName, @FranchiseID, @AddressID, @SupplierID, @StationOperatorID, @MaxPowerKW, N'Active', CAST(SYSDATETIME() AS DATE));

        DECLARE @StationID INT = SCOPE_IDENTITY();

        INSERT INTO Audit.AuditLog (SchemaName, TableName, RecordID, ActionType, NewValues)
        VALUES (N'Infrastructure', N'ChargingStation', CAST(@StationID AS NVARCHAR(100)), N'INSERT', @StationCode);

        COMMIT TRANSACTION;

        SELECT StationID, StationCode, StationName, StationStatus
        FROM Infrastructure.ChargingStation
        WHERE StationID = @StationID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE Infrastructure.sp_CreateChargingPoint
    @PointCode NVARCHAR(40),
    @StationID INT,
    @ConnectorTypeID INT,
    @PowerKW DECIMAL(8,2),
    @SerialNumber NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO Infrastructure.ChargingPoint
            (PointCode, StationID, ConnectorTypeID, PowerKW, SerialNumber, PointStatus)
        VALUES
            (@PointCode, @StationID, @ConnectorTypeID, @PowerKW, @SerialNumber, N'Available');

        DECLARE @PointID INT = SCOPE_IDENTITY();

        IF NOT EXISTS (
            SELECT 1 FROM Infrastructure.StationConnectorType
            WHERE StationID = @StationID AND ConnectorTypeID = @ConnectorTypeID
        )
        BEGIN
            INSERT INTO Infrastructure.StationConnectorType (StationID, ConnectorTypeID)
            VALUES (@StationID, @ConnectorTypeID);
        END;

        INSERT INTO Audit.AuditLog (SchemaName, TableName, RecordID, ActionType, NewValues)
        VALUES (N'Infrastructure', N'ChargingPoint', CAST(@PointID AS NVARCHAR(100)), N'INSERT', @PointCode);

        COMMIT TRANSACTION;

        SELECT PointID, PointCode, StationID, ConnectorTypeID, PowerKW, PointStatus
        FROM Infrastructure.ChargingPoint
        WHERE PointID = @PointID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE Infrastructure.sp_UpdateStationStatus
    @StationID INT,
    @StationStatus NVARCHAR(30),
    @ChangedBy INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF @StationStatus NOT IN (N'Active', N'Inactive', N'UnderMaintenance', N'Retired')
            THROW 51020, 'Invalid station status.', 1;

        IF NOT EXISTS (SELECT 1 FROM Infrastructure.ChargingStation WHERE StationID = @StationID)
            THROW 51021, 'Charging station does not exist.', 1;

        UPDATE Infrastructure.ChargingStation
        SET StationStatus = @StationStatus, UpdatedAt = SYSDATETIME()
        WHERE StationID = @StationID;

        INSERT INTO Audit.AuditLog (SchemaName, TableName, RecordID, ActionType, NewValues, ChangedBy)
        VALUES (N'Infrastructure', N'ChargingStation', CAST(@StationID AS NVARCHAR(100)), N'UPDATE', @StationStatus, COALESCE(CAST(@ChangedBy AS NVARCHAR(128)), ORIGINAL_LOGIN()));

        COMMIT TRANSACTION;

        SELECT StationID, StationCode, StationName, StationStatus
        FROM Infrastructure.ChargingStation
        WHERE StationID = @StationID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE Infrastructure.sp_UpdateChargingPointStatus
    @PointID INT,
    @PointStatus NVARCHAR(30),
    @HealthStatus NVARCHAR(20) = NULL,
    @ChangedBy INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF @PointStatus NOT IN (N'Available', N'Reserved', N'Charging', N'Offline', N'Error', N'Maintenance', N'Retired')
            THROW 51030, 'Invalid charging point status.', 1;
        IF @HealthStatus IS NOT NULL AND @HealthStatus NOT IN (N'Normal', N'Warning', N'Critical', N'Offline')
            THROW 51031, 'Invalid health status.', 1;
        IF NOT EXISTS (SELECT 1 FROM Infrastructure.ChargingPoint WHERE PointID = @PointID)
            THROW 51032, 'Charging point does not exist.', 1;

        UPDATE Infrastructure.ChargingPoint
        SET PointStatus = @PointStatus,
            HealthStatus = COALESCE(@HealthStatus, HealthStatus),
            UpdatedAt = SYSDATETIME()
        WHERE PointID = @PointID;

        INSERT INTO Audit.AuditLog (SchemaName, TableName, RecordID, ActionType, NewValues, ChangedBy)
        VALUES (N'Infrastructure', N'ChargingPoint', CAST(@PointID AS NVARCHAR(100)), N'UPDATE', @PointStatus, COALESCE(CAST(@ChangedBy AS NVARCHAR(128)), ORIGINAL_LOGIN()));

        COMMIT TRANSACTION;

        SELECT PointID, PointCode, PointStatus, HealthStatus
        FROM Infrastructure.ChargingPoint
        WHERE PointID = @PointID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

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

CREATE OR ALTER PROCEDURE Payments.sp_CreatePayment
    @UserID INT,
    @SessionID BIGINT,
    @PaymentMethod NVARCHAR(30) = N'CASH'
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF (COALESCE(CAST(SESSION_CONTEXT(N'RoleCode') AS NVARCHAR(40)), N'') = N'Customer' OR IS_ROLEMEMBER(N'db_ev_customer') = 1)
           AND ISNULL(@UserID, -1) <> ISNULL(TRY_CONVERT(INT, SESSION_CONTEXT(N'UserID')), -2147483648)
            THROW 53015, 'Customer can only create payment for current session user.', 1;

        DECLARE @Amount DECIMAL(19,4), @SessionUserID INT, @Status NVARCHAR(30);
        SELECT @Amount = CostTotal, @SessionUserID = UserID, @Status = SessionStatus
        FROM Operations.ChargingSession
        WHERE SessionID = @SessionID;

        IF @Status <> N'Completed'
            THROW 53010, 'Session must be completed before payment.', 1;
        IF @SessionUserID <> @UserID
            THROW 53011, 'Session does not belong to user.', 1;
        IF @Amount IS NULL OR @Amount <= 0
            THROW 53012, 'Invalid payment amount.', 1;
        IF @PaymentMethod NOT IN (N'CASH', N'QR', N'BANK_TRANSFER')
            THROW 53013, 'Invalid payment method.', 1;
        IF EXISTS (SELECT 1 FROM Payments.PaymentTransaction WHERE SessionID = @SessionID AND TransactionStatus = N'Completed')
            THROW 53014, 'Session has already been paid.', 1;

        INSERT INTO Payments.PaymentTransaction
            (TransactionCode, UserID, SessionID, PaymentMethod, Amount, TransactionStatus, PaidAt)
        VALUES
            (N'TXN-' + FORMAT(SYSDATETIME(), 'yyyyMMddHHmmss') + N'-' + RIGHT(CONVERT(NVARCHAR(36), NEWID()), 6),
             @UserID, @SessionID, @PaymentMethod, @Amount, N'Completed', SYSDATETIME());

        DECLARE @TransactionID BIGINT = SCOPE_IDENTITY();

        INSERT INTO Audit.AuditLog (SchemaName, TableName, RecordID, ActionType, NewValues)
        VALUES (N'Payments', N'PaymentTransaction', CAST(@TransactionID AS NVARCHAR(100)), N'PAYMENT', CAST(@Amount AS NVARCHAR(50)));

        COMMIT TRANSACTION;

        SELECT TransactionID, TransactionCode, UserID, SessionID, PaymentMethod, Amount, TransactionStatus
        FROM Payments.PaymentTransaction
        WHERE TransactionID = @TransactionID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE Payments.sp_RefundPayment
    @TransactionID BIGINT,
    @Reason NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @Status NVARCHAR(20), @SessionID BIGINT;
        SELECT @Status = TransactionStatus, @SessionID = SessionID
        FROM Payments.PaymentTransaction
        WHERE TransactionID = @TransactionID;

        IF @Status IS NULL
            THROW 53040, 'Payment transaction does not exist.', 1;
        IF @Status <> N'Completed'
            THROW 53041, 'Only completed payments can be refunded.', 1;

        UPDATE Payments.PaymentTransaction
        SET TransactionStatus = N'Refunded',
            Description = COALESCE(@Reason, Description)
        WHERE TransactionID = @TransactionID;

        UPDATE Payments.Invoice
        SET InvoiceStatus = N'Refunded'
        WHERE TransactionID = @TransactionID;

        INSERT INTO Audit.AuditLog (SchemaName, TableName, RecordID, ActionType, OldValues, NewValues)
        VALUES (N'Payments', N'PaymentTransaction', CAST(@TransactionID AS NVARCHAR(100)), N'PAYMENT', N'Completed', N'Refunded');

        COMMIT TRANSACTION;

        SELECT TransactionID, SessionID, PaymentMethod, Amount, TransactionStatus, Description
        FROM Payments.PaymentTransaction
        WHERE TransactionID = @TransactionID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE Payments.sp_CreateInvoice
    @SessionID BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF EXISTS (SELECT 1 FROM Payments.Invoice WHERE SessionID = @SessionID)
            THROW 53020, 'Invoice already exists.', 1;

        DECLARE @UserID INT, @Subtotal DECIMAL(19,4), @Tax DECIMAL(19,4), @Total DECIMAL(19,4), @TransactionID BIGINT;

        SELECT @UserID = UserID, @Subtotal = CostBeforeTax, @Tax = TaxAmount, @Total = CostTotal
        FROM Operations.ChargingSession
        WHERE SessionID = @SessionID AND SessionStatus = N'Completed';

        IF (COALESCE(CAST(SESSION_CONTEXT(N'RoleCode') AS NVARCHAR(40)), N'') = N'Customer' OR IS_ROLEMEMBER(N'db_ev_customer') = 1)
           AND ISNULL(@UserID, -1) <> ISNULL(TRY_CONVERT(INT, SESSION_CONTEXT(N'UserID')), -2147483648)
            THROW 53022, 'Customer can only create invoice for own charging session.', 1;

        SELECT TOP 1 @TransactionID = TransactionID
        FROM Payments.PaymentTransaction
        WHERE SessionID = @SessionID
          AND TransactionStatus = N'Completed'
        ORDER BY CreatedAt DESC;

        IF @UserID IS NULL OR @Total IS NULL
            THROW 53021, 'Cannot create invoice for incomplete session.', 1;

        INSERT INTO Payments.Invoice
            (InvoiceCode, UserID, SessionID, TransactionID, Subtotal, TaxAmount, TotalAmount, InvoiceStatus)
        VALUES
            (N'INV-' + FORMAT(SYSDATETIME(), 'yyyyMMddHHmmss') + N'-' + RIGHT(CONVERT(NVARCHAR(36), NEWID()), 6),
             @UserID, @SessionID, @TransactionID, @Subtotal, @Tax, @Total,
             CASE WHEN @TransactionID IS NULL THEN N'Issued' ELSE N'Paid' END);

        DECLARE @InvoiceID BIGINT = SCOPE_IDENTITY();

        COMMIT TRANSACTION;

        SELECT InvoiceID, InvoiceCode, UserID, SessionID, TotalAmount, InvoiceStatus
        FROM Payments.Invoice
        WHERE InvoiceID = @InvoiceID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

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

CREATE OR ALTER PROCEDURE Maintenance.sp_ReportError
    @ErrorCode NVARCHAR(30) = NULL,
    @StationID INT = NULL,
    @PointID INT = NULL,
    @Severity NVARCHAR(20) = N'Medium',
    @Description NVARCHAR(500),
    @CreatedBy INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF @Severity NOT IN (N'Low', N'Medium', N'High', N'Critical')
            THROW 54001, 'Invalid severity.', 1;

        INSERT INTO Maintenance.ErrorLog (ErrorCode, StationID, PointID, Severity, Description)
        VALUES (@ErrorCode, @StationID, @PointID, @Severity, @Description);

        DECLARE @ErrorID BIGINT = SCOPE_IDENTITY();

        INSERT INTO Maintenance.MaintenanceTicket
            (TicketCode, StationID, PointID, ErrorID, CreatedBy, Priority, TicketStatus, Title, Description)
        VALUES
            (N'MT-' + FORMAT(SYSDATETIME(), 'yyyyMMddHHmmss') + N'-' + RIGHT(CONVERT(NVARCHAR(36), NEWID()), 6),
             @StationID, @PointID, @ErrorID, @CreatedBy, @Severity, N'Open', N'Auto ticket from error log', @Description);

        IF @PointID IS NOT NULL
            UPDATE Infrastructure.ChargingPoint SET PointStatus = N'Error', HealthStatus = N'Critical', UpdatedAt = SYSDATETIME()
            WHERE PointID = @PointID;

        COMMIT TRANSACTION;

        SELECT ErrorID, ErrorCode, StationID, PointID, Severity, IsActive
        FROM Maintenance.ErrorLog
        WHERE ErrorID = @ErrorID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE Maintenance.sp_AssignTicket
    @TicketID BIGINT,
    @AssignedTo INT,
    @AssignedBy INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1 FROM Maintenance.MaintenanceTicket WHERE TicketID = @TicketID AND TicketStatus IN (N'Open', N'Assigned', N'InProgress'))
            THROW 54010, 'Ticket cannot be assigned.', 1;
        IF NOT EXISTS (SELECT 1 FROM [Identity].UserAccount WHERE UserID = @AssignedTo AND AccountStatus = N'Active')
            THROW 54011, 'Assigned user does not exist or is not active.', 1;

        UPDATE Maintenance.MaintenanceTicket
        SET AssignedTo = @AssignedTo,
            TicketStatus = N'Assigned'
        WHERE TicketID = @TicketID;

        INSERT INTO Audit.AuditLog (SchemaName, TableName, RecordID, ActionType, NewValues, ChangedBy)
        VALUES (N'Maintenance', N'MaintenanceTicket', CAST(@TicketID AS NVARCHAR(100)), N'UPDATE', N'Assigned', CAST(@AssignedBy AS NVARCHAR(128)));

        COMMIT TRANSACTION;

        SELECT TicketID, TicketCode, AssignedTo, TicketStatus
        FROM Maintenance.MaintenanceTicket
        WHERE TicketID = @TicketID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE Maintenance.sp_ScheduleMaintenance
    @StationID INT = NULL,
    @PointID INT = NULL,
    @CreatedBy INT,
    @AssignedTo INT = NULL,
    @Priority NVARCHAR(20) = N'Medium',
    @Title NVARCHAR(200),
    @Description NVARCHAR(1000) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF @Priority NOT IN (N'Low', N'Medium', N'High', N'Critical')
            THROW 54012, 'Invalid priority.', 1;
        IF @StationID IS NULL AND @PointID IS NULL
            THROW 54013, 'StationID or PointID is required.', 1;
        IF @PointID IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Infrastructure.ChargingPoint WHERE PointID = @PointID)
            THROW 54014, 'Charging point does not exist.', 1;
        IF @StationID IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Infrastructure.ChargingStation WHERE StationID = @StationID)
            THROW 54015, 'Charging station does not exist.', 1;

        INSERT INTO Maintenance.MaintenanceTicket
            (TicketCode, StationID, PointID, CreatedBy, AssignedTo, Priority, TicketStatus, Title, Description)
        VALUES
            (N'MT-SCH-' + FORMAT(SYSDATETIME(), 'yyyyMMddHHmmss') + N'-' + RIGHT(CONVERT(NVARCHAR(36), NEWID()), 6),
             @StationID, @PointID, @CreatedBy, @AssignedTo, @Priority,
             CASE WHEN @AssignedTo IS NULL THEN N'Open' ELSE N'Assigned' END,
             @Title, @Description);

        DECLARE @TicketID BIGINT = SCOPE_IDENTITY();

        IF @PointID IS NOT NULL
            UPDATE Infrastructure.ChargingPoint
            SET PointStatus = N'Maintenance',
                HealthStatus = CASE WHEN HealthStatus = N'Offline' THEN N'Offline' ELSE N'Warning' END,
                UpdatedAt = SYSDATETIME()
            WHERE PointID = @PointID;

        INSERT INTO Audit.AuditLog (SchemaName, TableName, RecordID, ActionType, NewValues)
        VALUES (N'Maintenance', N'MaintenanceTicket', CAST(@TicketID AS NVARCHAR(100)), N'INSERT', N'Scheduled maintenance');

        COMMIT TRANSACTION;

        SELECT TicketID, TicketCode, StationID, PointID, AssignedTo, Priority, TicketStatus, Title
        FROM Maintenance.MaintenanceTicket
        WHERE TicketID = @TicketID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE Maintenance.sp_CloseTicket
    @TicketID BIGINT,
    @ClosedBy INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @PointID INT, @ErrorID BIGINT, @OldStatus NVARCHAR(20);
        SELECT @PointID = PointID, @ErrorID = ErrorID, @OldStatus = TicketStatus
        FROM Maintenance.MaintenanceTicket
        WHERE TicketID = @TicketID;

        IF @OldStatus IS NULL OR @OldStatus IN (N'Closed', N'Cancelled')
            THROW 54020, 'Ticket cannot be closed.', 1;

        UPDATE Maintenance.MaintenanceTicket
        SET TicketStatus = N'Closed', ClosedAt = SYSDATETIME()
        WHERE TicketID = @TicketID;

        IF @ErrorID IS NOT NULL
            UPDATE Maintenance.ErrorLog
            SET IsActive = 0, ResolvedAt = SYSDATETIME(), ResolvedBy = @ClosedBy
            WHERE ErrorID = @ErrorID;

        IF @PointID IS NOT NULL
            UPDATE Infrastructure.ChargingPoint
            SET PointStatus = N'Available', HealthStatus = N'Normal', UpdatedAt = SYSDATETIME()
            WHERE PointID = @PointID;

        COMMIT TRANSACTION;

        SELECT TicketID, TicketStatus, ClosedAt FROM Maintenance.MaintenanceTicket WHERE TicketID = @TicketID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE Franchise.sp_UpdateRevenueSharePolicy
    @RevenueSharePolicyID INT,
    @PartnerShareRate DECIMAL(5,2),
    @AppliedTo DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF @PartnerShareRate NOT BETWEEN 0 AND 100
            THROW 55010, 'Partner share rate must be between 0 and 100.', 1;
        IF NOT EXISTS (SELECT 1 FROM Franchise.RevenueSharePolicy WHERE RevenueSharePolicyID = @RevenueSharePolicyID)
            THROW 55011, 'Revenue share policy does not exist.', 1;

        UPDATE Franchise.RevenueSharePolicy
        SET PartnerShareRate = @PartnerShareRate,
            AppliedTo = @AppliedTo
        WHERE RevenueSharePolicyID = @RevenueSharePolicyID;

        INSERT INTO Audit.AuditLog (SchemaName, TableName, RecordID, ActionType, NewValues)
        VALUES (N'Franchise', N'RevenueSharePolicy', CAST(@RevenueSharePolicyID AS NVARCHAR(100)), N'UPDATE', CAST(@PartnerShareRate AS NVARCHAR(50)));

        COMMIT TRANSACTION;

        SELECT RevenueSharePolicyID, ContractID, PartnerShareRate, PlatformShareRate, AppliedFrom, AppliedTo, IsActive
        FROM Franchise.RevenueSharePolicy
        WHERE RevenueSharePolicyID = @RevenueSharePolicyID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE Franchise.sp_CreateRevenueSettlement
    @FranchiseID INT,
    @PeriodStart DATE,
    @PeriodEnd DATE
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @ContractID INT, @PartnerRate DECIMAL(5,2);
        SELECT TOP 1 @ContractID = fc.ContractID, @PartnerRate = rsp.PartnerShareRate
        FROM Franchise.FranchiseContract fc
        JOIN Franchise.RevenueSharePolicy rsp ON rsp.ContractID = fc.ContractID AND rsp.IsActive = 1
        WHERE fc.FranchiseID = @FranchiseID
          AND fc.ContractStatus = N'Active'
          AND @PeriodStart BETWEEN fc.StartDate AND fc.EndDate
        ORDER BY fc.StartDate DESC;

        IF @ContractID IS NULL
            THROW 55001, 'Active franchise contract not found.', 1;

        DECLARE @GrossRevenue DECIMAL(19,4);
        SELECT @GrossRevenue = SUM(cs.CostBeforeTax)
        FROM Operations.ChargingSession cs
        JOIN Infrastructure.ChargingStation s ON s.StationID = cs.StationID
        WHERE s.FranchiseID = @FranchiseID
          AND cs.SessionStatus = N'Completed'
          AND CAST(cs.StartTime AS DATE) BETWEEN @PeriodStart AND @PeriodEnd;

        SET @GrossRevenue = ISNULL(@GrossRevenue, 0);

        DECLARE @PartnerShare DECIMAL(19,4) = Franchise.fn_CalculatePartnerShare(@GrossRevenue, @PartnerRate);
        DECLARE @PlatformShare DECIMAL(19,4) = @GrossRevenue - @PartnerShare;

        INSERT INTO Franchise.RevenueShareSettlement
            (SettlementCode, FranchiseID, ContractID, PeriodStart, PeriodEnd, GrossRevenue, PartnerShareAmount, PlatformShareAmount, SettlementStatus, ApprovedAt)
        VALUES
            (N'SET-' + FORMAT(SYSDATETIME(), 'yyyyMMddHHmmss') + N'-' + RIGHT(CONVERT(NVARCHAR(36), NEWID()), 6),
             @FranchiseID, @ContractID, @PeriodStart, @PeriodEnd, @GrossRevenue, @PartnerShare, @PlatformShare, N'Approved', SYSDATETIME());

        DECLARE @SettlementID BIGINT = SCOPE_IDENTITY();

        INSERT INTO Audit.AuditLog (SchemaName, TableName, RecordID, ActionType, NewValues)
        VALUES (N'Franchise', N'RevenueShareSettlement', CAST(@SettlementID AS NVARCHAR(100)), N'SETTLEMENT', CAST(@GrossRevenue AS NVARCHAR(50)));

        COMMIT TRANSACTION;

        SELECT SettlementID, SettlementCode, GrossRevenue, PartnerShareAmount, PlatformShareAmount, SettlementStatus
        FROM Franchise.RevenueShareSettlement
        WHERE SettlementID = @SettlementID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

PRINT N'05 - Simplified stored procedures created.';
GO
