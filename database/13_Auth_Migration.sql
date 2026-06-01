USE EV_Charging_System;
GO

IF OBJECT_ID(N'Identity.AuthToken', N'U') IS NULL
BEGIN
    CREATE TABLE [Identity].AuthToken
    (
        AuthTokenID BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_AuthToken PRIMARY KEY,
        UserID INT NOT NULL,
        TokenType NVARCHAR(30) NOT NULL,
        TokenHash NVARCHAR(128) NOT NULL CONSTRAINT UQ_AuthToken_TokenHash UNIQUE,
        ExpiresAt DATETIME2 NOT NULL,
        ConsumedAt DATETIME2 NULL,
        CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
        CONSTRAINT FK_AuthToken_User FOREIGN KEY (UserID) REFERENCES [Identity].UserAccount(UserID),
        CONSTRAINT CK_AuthToken_Type CHECK (TokenType IN (N'PasswordReset', N'EmailVerification'))
    );
END;
GO

IF OBJECT_ID(N'Identity.AuthEvent', N'U') IS NULL
BEGIN
    CREATE TABLE [Identity].AuthEvent
    (
        AuthEventID BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_AuthEvent PRIMARY KEY,
        UserID INT NULL,
        Identifier NVARCHAR(120) NULL,
        EventType NVARCHAR(40) NOT NULL,
        EventStatus NVARCHAR(20) NOT NULL,
        IpAddress NVARCHAR(45) NULL,
        UserAgent NVARCHAR(300) NULL,
        CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
        CONSTRAINT FK_AuthEvent_User FOREIGN KEY (UserID) REFERENCES [Identity].UserAccount(UserID),
        CONSTRAINT CK_AuthEvent_Type CHECK (EventType IN (N'Register', N'Login', N'Logout', N'PasswordResetRequested', N'PasswordResetCompleted', N'EmailVerified')),
        CONSTRAINT CK_AuthEvent_Status CHECK (EventStatus IN (N'Success', N'Failed', N'Ignored'))
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_UserAccount_Email' AND object_id = OBJECT_ID(N'Identity.UserAccount'))
    CREATE INDEX IX_UserAccount_Email ON [Identity].UserAccount(Email);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_UserAccount_Phone' AND object_id = OBJECT_ID(N'Identity.UserAccount'))
    CREATE INDEX IX_UserAccount_Phone ON [Identity].UserAccount(Phone);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_AuthToken_UserType' AND object_id = OBJECT_ID(N'Identity.AuthToken'))
    CREATE INDEX IX_AuthToken_UserType ON [Identity].AuthToken(UserID, TokenType, ExpiresAt DESC);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_AuthToken_Expires' AND object_id = OBJECT_ID(N'Identity.AuthToken'))
    CREATE INDEX IX_AuthToken_Expires ON [Identity].AuthToken(ExpiresAt) WHERE ConsumedAt IS NULL;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_AuthEvent_UserTime' AND object_id = OBJECT_ID(N'Identity.AuthEvent'))
    CREATE INDEX IX_AuthEvent_UserTime ON [Identity].AuthEvent(UserID, CreatedAt DESC);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_AuthEvent_TypeTime' AND object_id = OBJECT_ID(N'Identity.AuthEvent'))
    CREATE INDEX IX_AuthEvent_TypeTime ON [Identity].AuthEvent(EventType, CreatedAt DESC);
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

PRINT N'13 - Auth migration applied.';
GO
