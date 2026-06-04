==============================================================================
-- 4.2.4 Nhom Stored Procedure quan ly dinh danh & phan quyen
==============================================================================


==============================================================================
-- Identity.sp_CreateUser
==============================================================================

--database/05_Create_Stored_Procedures.sql
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

-- >>> TEST: source kiem thu tinh nang
-- (Trich tu database/features/system_admin/01_create_user.sql)
USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: tao user moi va gan role ban dau.
- Tham so co the sua: @Username, @Email, @Phone, @PasswordHash, @FullName, @RoleCode.
- @Username va @Email phai duy nhat; script dang tu sinh suffix de tranh trung.
- Tac dong du lieu: THEM THAT UserAccount va UserRole.
*/

PRINT N'Tạo tài khoản: quản trị viên tạo user mới và gán role ban đầu bằng stored procedure.';

DECLARE @Suffix NVARCHAR(12) = RIGHT(REPLACE(CONVERT(NVARCHAR(36), NEWID()), N'-', N''), 8);
DECLARE @Username NVARCHAR(50) = N'feature_user_' + @Suffix;
DECLARE @Email NVARCHAR(120) = @Username + N'@demo.local';

SELECT TOP 10 UserID, Username, Email, FullName, AccountStatus
FROM [Identity].UserAccount
ORDER BY UserID DESC;

EXEC [Identity].sp_CreateUser
    @Username = @Username,
    @Email = @Email,
    @Phone = NULL,
    @PasswordHash = N'FEATURE-DEMO-HASH',
    @FullName = N'FEATURE-DEMO User',
    @RoleCode = N'Customer';

SELECT TOP 10 UserID, Username, Email, FullName, AccountStatus
FROM [Identity].UserAccount
ORDER BY UserID DESC;
GO



==============================================================================
-- Identity.sp_RegisterCustomer
==============================================================================

--database/05_Create_Stored_Procedures.sql
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

-- >>> TEST: source kiem thu tinh nang
-- (Demo test soan rieng cho bao cao - SP nay khong co file feature test rieng)
USE EV_Charging_System;
GO
-- TEST: Khach hang tu dang ky tai khoan (vai tro Customer duoc gan tu dong)
EXEC [Identity].sp_RegisterCustomer
     @Username = N'demo_customer',
     @Email    = N'demo_customer@example.com',
     @Phone    = N'0900000001',
     @PasswordHash = N'$2a$11$hashGiaLapBcrypt................................',
     @FullName = N'Khach Hang Demo';
-- Ket qua mong doi: tra ve 1 dong UserAccount voi AccountStatus = 'Active'
-- Test am: chay lai voi cung Username/Email se nem loi 51101/51102 (da ton tai)


==============================================================================
-- Identity.sp_RequestPasswordReset
==============================================================================

--database/05_Create_Stored_Procedures.sql
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

-- >>> TEST: source kiem thu tinh nang
-- (Demo test soan rieng cho bao cao - SP nay khong co file feature test rieng)
USE EV_Charging_System;
GO
-- TEST: Tao yeu cau dat lai mat khau cho mot user CO SAN (vd 'customer01').
-- Luu y 1: tham so cua EXEC khong nhan bieu thuc => gan DATEADD vao bien truoc.
-- Luu y 2: bao trong giao dich roi ROLLBACK de khong de lai token thua trong DB.
BEGIN TRAN;
    DECLARE @ExpiresAt DATETIME2 = DATEADD(MINUTE, 30, SYSDATETIME());
    EXEC [Identity].sp_RequestPasswordReset
         @Identifier = N'customer01',                 -- username/email/phone co that
         @TokenHash  = N'DEMO_RESET_TOKEN_001',
         @ExpiresAt  = @ExpiresAt;
    -- Ket qua mong doi: tra ve UserID va ghi 1 dong [Identity].AuthToken
    --                   (TokenType = 'PasswordReset') con hieu luc.
    SELECT TOP 5 AuthTokenID, UserID, TokenType, ExpiresAt, ConsumedAt
    FROM [Identity].AuthToken WHERE TokenHash = N'DEMO_RESET_TOKEN_001';
ROLLBACK;   -- huy thay doi demo
-- Test am: goi voi @Identifier khong ton tai => SP tra ve UserID = NULL (khong loi)


==============================================================================
-- Identity.sp_ResetPasswordByToken
==============================================================================

--database/05_Create_Stored_Procedures.sql
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

-- >>> TEST: source kiem thu tinh nang
-- (Demo test soan rieng cho bao cao - SP nay khong co file feature test rieng)
USE EV_Charging_System;
GO
-- TEST: Dat lai mat khau bang token hop le.
-- Demo tu chua: tao token bang sp_RequestPasswordReset roi dung chinh token do.
-- Bao trong giao dich + ROLLBACK de KHONG doi mat khau that cua tai khoan demo.
BEGIN TRAN;
    DECLARE @Exp DATETIME2 = DATEADD(MINUTE, 30, SYSDATETIME());
    EXEC [Identity].sp_RequestPasswordReset
         @Identifier = N'customer01',
         @TokenHash  = N'DEMO_RESET_TOKEN_002',
         @ExpiresAt  = @Exp;

    EXEC [Identity].sp_ResetPasswordByToken
         @TokenHash    = N'DEMO_RESET_TOKEN_002',
         @PasswordHash = N'$2a$11$hashMoiSauKhiReset........................';
    -- Ket qua mong doi: cap nhat PasswordHash + danh dau token ConsumedAt.
ROLLBACK;   -- huy thay doi demo
-- Test am: goi sp_ResetPasswordByToken voi token sai/het han/da dung
--          => THROW 51110 'Token dat lai mat khau khong hop le hoac da het han.'


==============================================================================
-- Identity.sp_VerifyEmailToken
==============================================================================

--database/05_Create_Stored_Procedures.sql
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

-- >>> TEST: source kiem thu tinh nang
-- (Demo test soan rieng cho bao cao - SP nay khong co file feature test rieng)
USE EV_Charging_System;
GO
-- TEST: Xac thuc email qua token.
-- Demo tu chua: tao 1 token 'EmailVerification' cho user co san roi xac thuc.
-- Bao trong giao dich + ROLLBACK de khong de lai du lieu thua.
BEGIN TRAN;
    DECLARE @UserID INT = (SELECT UserID FROM [Identity].UserAccount WHERE Username = N'customer01');
    INSERT INTO [Identity].AuthToken (UserID, TokenType, TokenHash, ExpiresAt)
    VALUES (@UserID, N'EmailVerification', N'DEMO_EMAIL_TOKEN_001',
            DATEADD(MINUTE, 30, SYSDATETIME()));

    EXEC [Identity].sp_VerifyEmailToken @TokenHash = N'DEMO_EMAIL_TOKEN_001';
    -- Ket qua mong doi: token bi consume; neu account dang 'Pending' se chuyen 'Active'.
ROLLBACK;   -- huy thay doi demo
-- Test am: goi voi token sai/het han => THROW 51111 'Token xac minh email khong hop le...'


==============================================================================
-- Identity.sp_LockUser
==============================================================================

--database/05_Create_Stored_Procedures.sql
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

-- >>> TEST: source kiem thu tinh nang
-- (Trich tu database/features/system_admin/02_lock_unlock_user.sql)
USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: khoa va mo lai tai khoan.
- Tham so co the sua: @UserID.
- Tac dong du lieu: SUA THAT AccountStatus sang Locked roi tra ve Active.
*/

PRINT N'Khóa và mở tài khoản: quản trị viên thay đổi trạng thái tài khoản để kiểm soát truy cập.';

DECLARE @UserID INT = (SELECT UserID FROM [Identity].UserAccount WHERE Username = N'customer05');

SELECT UserID, Username, AccountStatus, UpdatedAt
FROM [Identity].UserAccount
WHERE UserID = @UserID;

EXEC [Identity].sp_LockUser @UserID = @UserID;

SELECT UserID, Username, AccountStatus, UpdatedAt
FROM [Identity].UserAccount
WHERE UserID = @UserID;

EXEC [Identity].sp_UnlockUser @UserID = @UserID;

SELECT UserID, Username, AccountStatus, UpdatedAt
FROM [Identity].UserAccount
WHERE UserID = @UserID;
GO



==============================================================================
-- Identity.sp_UnlockUser
==============================================================================

--database/05_Create_Stored_Procedures.sql
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

-- >>> TEST: source kiem thu tinh nang
-- (Trich tu database/features/system_admin/02_lock_unlock_user.sql)
USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: khoa va mo lai tai khoan.
- Tham so co the sua: @UserID.
- Tac dong du lieu: SUA THAT AccountStatus sang Locked roi tra ve Active.
*/

PRINT N'Khóa và mở tài khoản: quản trị viên thay đổi trạng thái tài khoản để kiểm soát truy cập.';

DECLARE @UserID INT = (SELECT UserID FROM [Identity].UserAccount WHERE Username = N'customer05');

SELECT UserID, Username, AccountStatus, UpdatedAt
FROM [Identity].UserAccount
WHERE UserID = @UserID;

EXEC [Identity].sp_LockUser @UserID = @UserID;

SELECT UserID, Username, AccountStatus, UpdatedAt
FROM [Identity].UserAccount
WHERE UserID = @UserID;

EXEC [Identity].sp_UnlockUser @UserID = @UserID;

SELECT UserID, Username, AccountStatus, UpdatedAt
FROM [Identity].UserAccount
WHERE UserID = @UserID;
GO



==============================================================================
-- Identity.sp_ResetPassword
==============================================================================

--database/05_Create_Stored_Procedures.sql
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

-- >>> TEST: source kiem thu tinh nang
-- (Trich tu database/features/system_admin/03_reset_password.sql)
USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: reset password hash cua user.
- Tham so co the sua: @UserID, @PasswordHash.
- Tac dong du lieu: SUA THAT PasswordHash va ghi audit.
*/

PRINT N'Reset mật khẩu: quản trị viên cập nhật password hash và ghi nhận thao tác vào audit.';

DECLARE @UserID INT = (SELECT UserID FROM [Identity].UserAccount WHERE Username = N'customer05');

SELECT UserID, Username, PasswordHash, UpdatedAt
FROM [Identity].UserAccount
WHERE UserID = @UserID;

EXEC [Identity].sp_ResetPassword
    @UserID = @UserID,
    @PasswordHash = N'FEATURE-DEMO-RESET-HASH';

SELECT UserID, Username, PasswordHash, UpdatedAt
FROM [Identity].UserAccount
WHERE UserID = @UserID;
GO



==============================================================================
-- Identity.sp_AssignRole
==============================================================================

--database/05_Create_Stored_Procedures.sql
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

-- >>> TEST: source kiem thu tinh nang
-- (Trich tu database/features/system_admin/04_assign_remove_role.sql)
USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: gan role cho user roi go role do.
- Tham so co the sua: @UserID, @RoleCode.
- Tac dong du lieu: THEM/DELETE THAT dong trong Identity.UserRole cho role demo.
*/

PRINT N'Gán và gỡ role: quản trị viên thay đổi quyền của user thông qua bảng liên kết user-role.';

DECLARE @UserID INT = (SELECT UserID FROM [Identity].UserAccount WHERE Username = N'customer05');

SELECT *
FROM AppView.vw_UserRoleSummary
WHERE UserID = @UserID;

EXEC [Identity].sp_AssignRole
    @UserID = @UserID,
    @RoleCode = N'OperationsStaff';

SELECT *
FROM AppView.vw_UserRoleSummary
WHERE UserID = @UserID;

EXEC [Identity].sp_RemoveRole
    @UserID = @UserID,
    @RoleCode = N'OperationsStaff';

SELECT *
FROM AppView.vw_UserRoleSummary
WHERE UserID = @UserID;
GO



==============================================================================
-- Identity.sp_RemoveRole
==============================================================================

--database/05_Create_Stored_Procedures.sql
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

-- >>> TEST: source kiem thu tinh nang
-- (Trich tu database/features/system_admin/04_assign_remove_role.sql)
USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: gan role cho user roi go role do.
- Tham so co the sua: @UserID, @RoleCode.
- Tac dong du lieu: THEM/DELETE THAT dong trong Identity.UserRole cho role demo.
*/

PRINT N'Gán và gỡ role: quản trị viên thay đổi quyền của user thông qua bảng liên kết user-role.';

DECLARE @UserID INT = (SELECT UserID FROM [Identity].UserAccount WHERE Username = N'customer05');

SELECT *
FROM AppView.vw_UserRoleSummary
WHERE UserID = @UserID;

EXEC [Identity].sp_AssignRole
    @UserID = @UserID,
    @RoleCode = N'OperationsStaff';

SELECT *
FROM AppView.vw_UserRoleSummary
WHERE UserID = @UserID;

EXEC [Identity].sp_RemoveRole
    @UserID = @UserID,
    @RoleCode = N'OperationsStaff';

SELECT *
FROM AppView.vw_UserRoleSummary
WHERE UserID = @UserID;
GO
