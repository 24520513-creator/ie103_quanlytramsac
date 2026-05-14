USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: demo row-level security tam thoi.
- Khong can sua tham so.
- Tac dong du lieu: TAO TAM schema/function/security policy, cap quyen SELECT tam thoi, sau do DROP/REVOKE de don dep.
*/

PRINT N'Kiểm tra row-level security: customer chỉ nhìn thấy phiên sạc thuộc tài khoản của mình trong policy tạm thời.';

IF EXISTS (SELECT 1 FROM sys.security_policies WHERE name = N'ChargingSessionCustomerPolicy')
    DROP SECURITY POLICY SecurityDemo.ChargingSessionCustomerPolicy;
GO

IF EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'SecurityDemo.fn_FilterChargingSessionByUser') AND type IN (N'IF', N'TF', N'FN'))
    DROP FUNCTION SecurityDemo.fn_FilterChargingSessionByUser;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'SecurityDemo')
    EXEC(N'CREATE SCHEMA SecurityDemo AUTHORIZATION dbo;');
GO

CREATE FUNCTION SecurityDemo.fn_FilterChargingSessionByUser(@UserID INT)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
    SELECT 1 AS fn_securitypredicate_result
    WHERE USER_NAME() IN (N'dbo', N'admin01')
       OR @UserID = (
            SELECT ua.UserID
            FROM [Identity].UserAccount AS ua
            WHERE ua.Username = USER_NAME()
       );
GO

CREATE SECURITY POLICY SecurityDemo.ChargingSessionCustomerPolicy
ADD FILTER PREDICATE SecurityDemo.fn_FilterChargingSessionByUser(UserID)
ON Operations.ChargingSession
WITH (STATE = ON);
GO

GRANT SELECT ON OBJECT::Operations.ChargingSession TO customer01;
GO

PRINT N'Kiểm tra row-level security: customer chỉ nhìn thấy phiên sạc thuộc tài khoản của mình trong policy tạm thời.';
EXECUTE AS USER = 'admin01';
SELECT COUNT(*) AS VisibleSessionsForAdmin
FROM Operations.ChargingSession;
REVERT;

PRINT N'Kiểm tra row-level security: customer chỉ nhìn thấy phiên sạc thuộc tài khoản của mình trong policy tạm thời.';
EXECUTE AS USER = 'customer01';
SELECT USER_NAME() AS CurrentDatabaseUser;
SELECT SessionID, SessionCode, UserID, StartTime, SessionStatus
FROM Operations.ChargingSession
ORDER BY SessionID;
REVERT;
GO

REVOKE SELECT ON OBJECT::Operations.ChargingSession FROM customer01;
DROP SECURITY POLICY SecurityDemo.ChargingSessionCustomerPolicy;
DROP FUNCTION SecurityDemo.fn_FilterChargingSessionByUser;
DROP SCHEMA SecurityDemo;
GO


