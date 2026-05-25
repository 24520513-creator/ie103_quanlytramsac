USE master;
GO

/*
HUONG DAN SU DUNG
- Muc dich: tao SQL Server login that de dang nhap SSMS bang SQL Authentication.
- Chay sau database/08_Create_Security.sql.
- Can dang nhap bang tai khoan co quyen CREATE LOGIN, vi CREATE LOGIN la quyen server-level.
- Mat khau ben duoi chi phuc vu demo/do an; neu dung may that, hay doi mat khau sau khi tao.
*/

IF SUSER_ID(N'ev_admin01_login') IS NULL
BEGIN
    CREATE LOGIN ev_admin01_login
    WITH PASSWORD = 'password',
         CHECK_POLICY = ON,
         CHECK_EXPIRATION = OFF;
END;
GO

IF SUSER_ID(N'ev_operator01_login') IS NULL
BEGIN
    CREATE LOGIN ev_operator01_login
    WITH PASSWORD = 'password',
         CHECK_POLICY = ON,
         CHECK_EXPIRATION = OFF;
END;
GO

IF SUSER_ID(N'ev_business01_login') IS NULL
BEGIN
    CREATE LOGIN ev_business01_login
    WITH PASSWORD = 'password',
         CHECK_POLICY = ON,
         CHECK_EXPIRATION = OFF;
END;
GO

IF SUSER_ID(N'ev_customer01_login') IS NULL
BEGIN
    CREATE LOGIN ev_customer01_login
    WITH PASSWORD = 'password',
         CHECK_POLICY = ON,
         CHECK_EXPIRATION = OFF;
END;
GO

USE EV_Charging_System;
GO

DECLARE @UserLoginMap TABLE
(
    DatabaseUser SYSNAME NOT NULL,
    ServerLogin SYSNAME NOT NULL
);

INSERT INTO @UserLoginMap (DatabaseUser, ServerLogin)
VALUES
    (N'admin01', N'ev_admin01_login'),
    (N'operator01', N'ev_operator01_login'),
    (N'business01', N'ev_business01_login'),
    (N'customer01', N'ev_customer01_login');

DECLARE @DatabaseUser SYSNAME;
DECLARE @ServerLogin SYSNAME;
DECLARE @Sql NVARCHAR(MAX);

DECLARE user_login_cursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT DatabaseUser, ServerLogin
    FROM @UserLoginMap;

OPEN user_login_cursor;
FETCH NEXT FROM user_login_cursor INTO @DatabaseUser, @ServerLogin;

WHILE @@FETCH_STATUS = 0
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = @DatabaseUser)
    BEGIN
        SET @Sql = N'CREATE USER ' + QUOTENAME(@DatabaseUser)
            + N' FOR LOGIN ' + QUOTENAME(@ServerLogin) + N';';
        EXEC sys.sp_executesql @Sql;
    END
    ELSE IF EXISTS (
        SELECT 1
        FROM sys.database_principals
        WHERE name = @DatabaseUser
          AND authentication_type_desc = N'NONE'
    )
    BEGIN
        SET @Sql = N'DROP USER ' + QUOTENAME(@DatabaseUser) + N';'
            + N' CREATE USER ' + QUOTENAME(@DatabaseUser)
            + N' FOR LOGIN ' + QUOTENAME(@ServerLogin) + N';';
        EXEC sys.sp_executesql @Sql;
    END
    ELSE IF EXISTS (
        SELECT 1
        FROM sys.database_principals
        WHERE name = @DatabaseUser
          AND authentication_type_desc IN (N'INSTANCE', N'WINDOWS')
          AND sid <> SUSER_SID(@ServerLogin)
    )
    BEGIN
        SET @Sql = N'ALTER USER ' + QUOTENAME(@DatabaseUser)
            + N' WITH LOGIN = ' + QUOTENAME(@ServerLogin) + N';';
        EXEC sys.sp_executesql @Sql;
    END
    ELSE IF EXISTS (
        SELECT 1
        FROM sys.database_principals
        WHERE name = @DatabaseUser
          AND authentication_type_desc NOT IN (N'NONE', N'INSTANCE', N'WINDOWS')
          AND sid <> SUSER_SID(@ServerLogin)
    )
    BEGIN
        THROW 51000, 'Database user exists but is not a SQL/Windows login-mapped user or WITHOUT LOGIN demo user.', 1;
    END;

    FETCH NEXT FROM user_login_cursor INTO @DatabaseUser, @ServerLogin;
END;

CLOSE user_login_cursor;
DEALLOCATE user_login_cursor;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.database_role_members
    WHERE role_principal_id = USER_ID(N'db_ev_system_admin')
      AND member_principal_id = USER_ID(N'admin01')
)
    ALTER ROLE db_ev_system_admin ADD MEMBER admin01;

IF NOT EXISTS (
    SELECT 1
    FROM sys.database_role_members
    WHERE role_principal_id = USER_ID(N'db_ev_operations_staff')
      AND member_principal_id = USER_ID(N'operator01')
)
    ALTER ROLE db_ev_operations_staff ADD MEMBER operator01;

IF NOT EXISTS (
    SELECT 1
    FROM sys.database_role_members
    WHERE role_principal_id = USER_ID(N'db_ev_business_manager')
      AND member_principal_id = USER_ID(N'business01')
)
    ALTER ROLE db_ev_business_manager ADD MEMBER business01;

IF NOT EXISTS (
    SELECT 1
    FROM sys.database_role_members
    WHERE role_principal_id = USER_ID(N'db_ev_customer')
      AND member_principal_id = USER_ID(N'customer01')
)
    ALTER ROLE db_ev_customer ADD MEMBER customer01;
GO

GRANT CONNECT TO admin01;
GRANT CONNECT TO operator01;
GRANT CONNECT TO business01;
GRANT CONNECT TO customer01;
GO

SELECT
    dp.name AS DatabaseUser,
    sp.name AS ServerLogin,
    USER_NAME(rm.role_principal_id) AS DatabaseRole
FROM sys.database_principals dp
JOIN sys.database_role_members rm ON rm.member_principal_id = dp.principal_id
LEFT JOIN sys.server_principals sp ON sp.sid = dp.sid
WHERE dp.name IN (N'admin01', N'operator01', N'business01', N'customer01')
ORDER BY dp.name;
GO

PRINT N'Optional SQL Authentication logins created and mapped to demo database users.';
GO
