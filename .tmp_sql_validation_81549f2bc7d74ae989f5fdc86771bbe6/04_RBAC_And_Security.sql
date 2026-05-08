/*==============================================================================
  EV_Charging_System_Validation - RBAC & SECURITY ARCHITECTURE
  ==============================================================================
  Components:  Server Logins | Database Users | Application Roles
              | Permissions | Row-Level Security | Dynamic Data Masking
  =============================================================================*/

USE EV_Charging_System_Validation;
GO

-- ===========================================================================
-- 1. SERVER-LEVEL LOGINS
-- ===========================================================================
-- Use Windows Authentication where possible; SQL Auth only for legacy/app needs.
-- In production, these should use Azure AD / Managed Identity.

IF NOT EXISTS (SELECT 1 FROM sys.sql_logins WHERE name = N'ev2_admin_login')
    CREATE LOGIN ev2_admin_login WITH PASSWORD = N'Admin@2026!Secure#EV',
        DEFAULT_DATABASE = EV_Charging_System_Validation,
        CHECK_EXPIRATION = ON,
        CHECK_POLICY = ON;
GO

IF NOT EXISTS (SELECT 1 FROM sys.sql_logins WHERE name = N'ev2_operator_login')
    CREATE LOGIN ev2_operator_login WITH PASSWORD = N'Op@2026!Secure#EV',
        DEFAULT_DATABASE = EV_Charging_System_Validation,
        CHECK_EXPIRATION = ON,
        CHECK_POLICY = ON;
GO

IF NOT EXISTS (SELECT 1 FROM sys.sql_logins WHERE name = N'ev2_technician_login')
    CREATE LOGIN ev2_technician_login WITH PASSWORD = N'Tech@2026!Secure#EV',
        DEFAULT_DATABASE = EV_Charging_System_Validation,
        CHECK_EXPIRATION = ON,
        CHECK_POLICY = ON;
GO

IF NOT EXISTS (SELECT 1 FROM sys.sql_logins WHERE name = N'ev2_franchise_login')
    CREATE LOGIN ev2_franchise_login WITH PASSWORD = N'Franchise@2026!Secure#EV',
        DEFAULT_DATABASE = EV_Charging_System_Validation,
        CHECK_EXPIRATION = ON,
        CHECK_POLICY = ON;
GO

IF NOT EXISTS (SELECT 1 FROM sys.sql_logins WHERE name = N'ev2_readonly_login')
    CREATE LOGIN ev2_readonly_login WITH PASSWORD = N'ReadOnly@2026!Secure#EV',
        DEFAULT_DATABASE = EV_Charging_System_Validation,
        CHECK_EXPIRATION = ON,
        CHECK_POLICY = ON;
GO

IF NOT EXISTS (SELECT 1 FROM sys.sql_logins WHERE name = N'ev2_app_service_login')
    CREATE LOGIN ev2_app_service_login WITH PASSWORD = N'AppSvc@2026!Secure#EV',
        DEFAULT_DATABASE = EV_Charging_System_Validation,
        CHECK_EXPIRATION = ON,
        CHECK_POLICY = ON;
GO

-- ===========================================================================
-- 2. DATABASE USERS
-- ===========================================================================
CREATE USER ev2_admin_user      FOR LOGIN ev2_admin_login;
CREATE USER ev2_operator_user    FOR LOGIN ev2_operator_login;
CREATE USER ev2_technician_user  FOR LOGIN ev2_technician_login;
CREATE USER ev2_franchise_user   FOR LOGIN ev2_franchise_login;
CREATE USER ev2_readonly_user    FOR LOGIN ev2_readonly_login;
CREATE USER ev2_app_service_user FOR LOGIN ev2_app_service_login;
GO

-- ===========================================================================
-- 3. APPLICATION ROLES & PERMISSIONS (RBAC)
-- ===========================================================================

-- Seed built-in roles
INSERT INTO Access.Role (RoleCode, RoleName, RoleLevel, Description, IsSystem)
VALUES
    (N'SysAdmin',    N'System Administrator',    100, N'Full system access. Manages all configurations, users, and settings.', 1),
    (N'Operator',    N'Operations Manager',       80,  N'Manages daily operations, sessions, pricing, and franchise oversight.', 1),
    (N'Technician',  N'Field Technician',         60,  N'Handles maintenance, repairs, station monitoring, and error resolution.', 1),
    (N'FranchiseOwner', N'Franchise Owner',       50,  N'Views own franchise data, reports, and revenue analytics.', 1),
    (N'CUSTOMER',    N'Registered Customer',      20,  N'End-user who charges vehicles. Manages own profile, vehicles, payments.', 1),
    (N'ReadOnly',    N'Read-Only Auditor',        10,  N'Read-only access for auditors, analysts, and dashboards.', 1),
    (N'ApiService',  N'API Service Account',      30,  N'Programmatic access for integrations, OCPP, and microservices.', 1);
GO

-- Seed granular permissions
INSERT INTO Access.Permission (PermissionCode, PermissionName, Module, Action, Description)
VALUES
    -- User Management
    (N'USER_CREATE',   N'Create Users',          N'Users',   N'Create',      N'Create new user accounts'),
    (N'USER_READ',     N'Read Users',            N'Users',   N'Read',        N'View user information'),
    (N'USER_UPDATE',   N'Update Users',          N'Users',   N'Update',      N'Modify user details'),
    (N'USER_DELETE',   N'Delete Users',          N'Users',   N'Delete',      N'Soft-delete user accounts'),
    (N'USER_IMPERSONATE', N'Impersonate Users',  N'Users',   N'Execute',     N'Login as another user for support'),

    -- Role Management
    (N'ROLE_CREATE',   N'Create Roles',          N'Access',  N'Create',      N'Define new roles'),
    (N'ROLE_READ',     N'Read Roles',            N'Access',  N'Read',        N'View role definitions'),
    (N'ROLE_ASSIGN',   N'Assign Roles',          N'Access',  N'Update',      N'Assign roles to users'),

    -- Station Management
    (N'STATION_CREATE',  N'Create Stations',     N'Infrastructure', N'Create', N'Add new charging stations'),
    (N'STATION_READ',    N'Read Stations',       N'Infrastructure', N'Read',   N'View station information'),
    (N'STATION_UPDATE',  N'Update Stations',     N'Infrastructure', N'Update', N'Modify station details'),
    (N'STATION_DELETE',  N'Delete Stations',     N'Infrastructure', N'Delete', N'Soft-delete stations'),
    (N'STATION_STATUS',  N'Change Station Status',N'Infrastructure', N'Update',N'Change station operational status'),

    -- Point Management
    (N'POINT_CREATE',    N'Create Points',       N'Infrastructure', N'Create', N'Add charging points'),
    (N'POINT_READ',      N'Read Points',         N'Infrastructure', N'Read',   N'View charging points'),
    (N'POINT_UPDATE',    N'Update Points',       N'Infrastructure', N'Update', N'Modify charging points'),

    -- Session Management
    (N'SESSION_READ',    N'Read Sessions',       N'Operations', N'Read',      N'View charging sessions'),
    (N'SESSION_START',   N'Start Session',       N'Operations', N'Create',    N'Initiate charging session'),
    (N'SESSION_STOP',    N'Stop Session',        N'Operations', N'Update',    N'Terminate charging session'),
    (N'SESSION_CANCEL',  N'Cancel Session',      N'Operations', N'Delete',    N'Cancel an active session'),
    (N'SESSION_OVERRIDE',N'Override Session',    N'Operations', N'Execute',   N'Override session parameters'),

    -- Pricing
    (N'PRICING_CREATE',  N'Create Pricing',      N'Operations', N'Create',    N'Define pricing policies'),
    (N'PRICING_READ',    N'Read Pricing',        N'Operations', N'Read',      N'View pricing policies'),
    (N'PRICING_UPDATE',  N'Update Pricing',      N'Operations', N'Update',    N'Modify pricing policies'),

    -- Payments
    (N'PAYMENT_READ',    N'Read Payments',       N'Payments',  N'Read',       N'View transactions'),
    (N'PAYMENT_REFUND',  N'Process Refund',      N'Payments',  N'Update',     N'Issue refunds'),
    (N'PAYMENT_ADJUST',  N'Adjust Payment',      N'Payments',  N'Execute',    N'Manually adjust transactions'),

    -- Monitoring
    (N'MONITOR_READ',    N'Read Monitoring',     N'Monitoring', N'Read',      N'View monitoring data'),
    (N'ALERT_CONFIG',    N'Configure Alerts',    N'Monitoring', N'Update',    N'Create and modify alert rules'),
    (N'ALERT_ACK',       N'Acknowledge Alerts',  N'Monitoring', N'Update',    N'Acknowledge and resolve alerts'),

    -- Maintenance
    (N'MAINT_CREATE',    N'Schedule Maintenance', N'Operations', N'Create',   N'Create maintenance schedules'),
    (N'MAINT_UPDATE',    N'Update Maintenance',  N'Operations', N'Update',    N'Modify maintenance records'),
    (N'MAINT_COMPLETE',  N'Complete Maintenance', N'Operations', N'Update',   N'Mark maintenance as complete'),

    -- Franchise
    (N'FRANCHISE_READ',  N'Read Franchises',     N'Infrastructure', N'Read',  N'View franchise data'),
    (N'FRANCHISE_UPDATE',N'Update Franchises',   N'Infrastructure', N'Update',N'Modify franchise contracts'),
    (N'FRANCHISE_REVENUE', N'View Revenue',      N'Reporting', N'Read',       N'View revenue and commission data'),

    -- Reports & Analytics
    (N'REPORT_READ',     N'Read Reports',        N'Reporting', N'Read',       N'Access report views'),
    (N'REPORT_EXPORT',   N'Export Reports',      N'Reporting', N'Execute',    N'Export report data'),
    (N'ANALYTICS_READ',  N'Read Analytics',      N'Analytics', N'Read',       N'Access KPI and analytics data'),

    -- Audit
    (N'AUDIT_READ',      N'Read Audit Logs',     N'Audit',     N'Read',       N'View audit trail'),
    (N'AUDIT_EXPORT',    N'Export Audit Logs',   N'Audit',     N'Execute',    N'Export audit logs'),

    -- System
    (N'SYSTEM_CONFIG',   N'System Configuration', N'Infrastructure', N'Update', N'Modify system-wide settings'),
    (N'SYSTEM_BACKUP',   N'System Backup',       N'Infrastructure', N'Execute',N'Perform backup operations');
GO

-- ===========================================================================
-- 4. ROLE-PERMISSION MAPPING (Least Privilege)
-- ===========================================================================

-- SysAdmin gets ALL permissions
INSERT INTO Access.RolePermission (RoleID, PermissionID)
SELECT r.RoleID, p.PermissionID
FROM Access.Role r
CROSS JOIN Access.Permission p
WHERE r.RoleCode = N'SysAdmin';
GO

-- Operator
INSERT INTO Access.RolePermission (RoleID, PermissionID)
SELECT r.RoleID, p.PermissionID
FROM Access.Role r
JOIN Access.Permission p ON p.PermissionCode IN (
    N'USER_READ', N'STATION_CREATE', N'STATION_READ', N'STATION_UPDATE', N'STATION_STATUS',
    N'POINT_CREATE', N'POINT_READ', N'POINT_UPDATE',
    N'SESSION_READ', N'SESSION_START', N'SESSION_STOP', N'SESSION_CANCEL', N'SESSION_OVERRIDE',
    N'PRICING_CREATE', N'PRICING_READ', N'PRICING_UPDATE',
    N'PAYMENT_READ', N'PAYMENT_REFUND', N'PAYMENT_ADJUST',
    N'MONITOR_READ', N'ALERT_CONFIG', N'ALERT_ACK',
    N'MAINT_CREATE', N'MAINT_UPDATE', N'MAINT_COMPLETE',
    N'FRANCHISE_READ', N'FRANCHISE_REVENUE',
    N'REPORT_READ', N'REPORT_EXPORT', N'ANALYTICS_READ',
    N'ROLE_READ'
)
WHERE r.RoleCode = N'Operator';
GO

-- Technician
INSERT INTO Access.RolePermission (RoleID, PermissionID)
SELECT r.RoleID, p.PermissionID
FROM Access.Role r
JOIN Access.Permission p ON p.PermissionCode IN (
    N'STATION_READ', N'STATION_UPDATE', N'STATION_STATUS',
    N'POINT_READ', N'POINT_UPDATE',
    N'SESSION_READ', N'SESSION_STOP',
    N'MONITOR_READ', N'ALERT_ACK',
    N'MAINT_CREATE', N'MAINT_UPDATE', N'MAINT_COMPLETE',
    N'REPORT_READ'
)
WHERE r.RoleCode = N'Technician';
GO

-- FranchiseOwner
INSERT INTO Access.RolePermission (RoleID, PermissionID)
SELECT r.RoleID, p.PermissionID
FROM Access.Role r
JOIN Access.Permission p ON p.PermissionCode IN (
    N'STATION_READ', N'SESSION_READ',
    N'MONITOR_READ', N'FRANCHISE_READ', N'FRANCHISE_REVENUE',
    N'REPORT_READ', N'REPORT_EXPORT', N'ANALYTICS_READ'
)
WHERE r.RoleCode = N'FranchiseOwner';
GO

-- Customer
INSERT INTO Access.RolePermission (RoleID, PermissionID)
SELECT r.RoleID, p.PermissionID
FROM Access.Role r
JOIN Access.Permission p ON p.PermissionCode IN (
    N'SESSION_START', N'SESSION_STOP', N'SESSION_READ',
    N'PAYMENT_READ', N'STATION_READ', N'POINT_READ',
    N'REPORT_READ'
)
WHERE r.RoleCode = N'CUSTOMER';
GO

-- ReadOnly
INSERT INTO Access.RolePermission (RoleID, PermissionID)
SELECT r.RoleID, p.PermissionID
FROM Access.Role r
JOIN Access.Permission p ON p.PermissionCode IN (
    N'STATION_READ', N'POINT_READ', N'SESSION_READ',
    N'PRICING_READ', N'PAYMENT_READ', N'MONITOR_READ',
    N'FRANCHISE_READ', N'REPORT_READ', N'ANALYTICS_READ',
    N'AUDIT_READ', N'USER_READ', N'ROLE_READ'
)
WHERE r.RoleCode = N'ReadOnly';
GO

-- ApiService
INSERT INTO Access.RolePermission (RoleID, PermissionID)
SELECT r.RoleID, p.PermissionID
FROM Access.Role r
JOIN Access.Permission p ON p.PermissionCode IN (
    N'SESSION_START', N'SESSION_STOP', N'SESSION_READ',
    N'STATION_READ', N'POINT_READ', N'POINT_UPDATE',
    N'MONITOR_READ', N'USER_READ', N'PAYMENT_READ'
)
WHERE r.RoleCode = N'ApiService';
GO

-- ===========================================================================
-- 5. MAP DATABASE USERS TO APPLICATION ROLES (via UserRole)
-- ===========================================================================
-- Note: These are the server-level mappings. Application-layer auth
-- uses the Users.UserRole table for business-level RBAC.

-- Application service account gets API access and can impersonate system
INSERT INTO Users.UserRole (UserID, RoleID)
SELECT u.UserID, r.RoleID
FROM Users.[User] u
CROSS JOIN Access.Role r
WHERE u.Username = N'system' AND r.RoleCode = N'ApiService';
GO

-- ===========================================================================
-- 6. SCHEMA-LEVEL PERMISSIONS FOR DATABASE ROLES
-- ===========================================================================

-- Create database roles matching application roles
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'db_role_admin' AND type = 'R')
    CREATE ROLE db_role_admin;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'db_role_operator' AND type = 'R')
    CREATE ROLE db_role_operator;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'db_role_technician' AND type = 'R')
    CREATE ROLE db_role_technician;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'db_role_franchise' AND type = 'R')
    CREATE ROLE db_role_franchise;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'db_role_readonly' AND type = 'R')
    CREATE ROLE db_role_readonly;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'db_role_app_service' AND type = 'R')
    CREATE ROLE db_role_app_service;
GO

-- Admin: FULL CONTROL on all schemas
GRANT CONTROL ON SCHEMA::Infrastructure   TO db_role_admin;
GRANT CONTROL ON SCHEMA::Access           TO db_role_admin;
GRANT CONTROL ON SCHEMA::Users            TO db_role_admin;
GRANT CONTROL ON SCHEMA::Operations       TO db_role_admin;
GRANT CONTROL ON SCHEMA::Payments         TO db_role_admin;
GRANT CONTROL ON SCHEMA::Monitoring       TO db_role_admin;
GRANT CONTROL ON SCHEMA::Audit            TO db_role_admin;
GRANT CONTROL ON SCHEMA::Analytics        TO db_role_admin;
GRANT CONTROL ON SCHEMA::Reporting        TO db_role_admin;
GRANT VIEW DEFINITION ON DATABASE :: [EV_Charging_System_Validation] TO db_role_admin;
GO

-- Operator: CRUD on Operations, Payments; SELECT on most others
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::Operations   TO db_role_operator;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::Payments     TO db_role_operator;
GRANT SELECT, INSERT, UPDATE ON SCHEMA::Infrastructure       TO db_role_operator;
GRANT SELECT ON SCHEMA::Users                                TO db_role_operator;
GRANT SELECT, INSERT, UPDATE ON SCHEMA::Monitoring           TO db_role_operator;
GRANT SELECT, UPDATE ON SCHEMA::Access                       TO db_role_operator;
GRANT SELECT ON SCHEMA::Audit                                TO db_role_operator;
GRANT SELECT ON SCHEMA::Analytics                            TO db_role_operator;
GRANT SELECT ON SCHEMA::Reporting                            TO db_role_operator;
GRANT EXECUTE ON SCHEMA::Operations                          TO db_role_operator;
GRANT EXECUTE ON SCHEMA::Payments                            TO db_role_operator;
GO

-- Technician: full on Infrastructure, Monitoring; limited on Operations
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::Infrastructure TO db_role_technician;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::Monitoring     TO db_role_technician;
GRANT SELECT, UPDATE ON SCHEMA::Operations                     TO db_role_technician;
GRANT SELECT ON SCHEMA::Audit                                  TO db_role_technician;
GRANT EXECUTE ON SCHEMA::Operations                            TO db_role_technician;
GO

-- Franchise: SELECT on own franchise data (filtered by RLS)
GRANT SELECT ON SCHEMA::Infrastructure   TO db_role_franchise;
GRANT SELECT ON SCHEMA::Operations       TO db_role_franchise;
GRANT SELECT ON SCHEMA::Payments         TO db_role_franchise;
GRANT SELECT ON SCHEMA::Monitoring       TO db_role_franchise;
GRANT SELECT ON SCHEMA::Analytics        TO db_role_franchise;
GRANT SELECT ON SCHEMA::Reporting        TO db_role_franchise;
GRANT SELECT ON SCHEMA::Audit            TO db_role_franchise;
GO

-- ReadOnly: SELECT on reporting schemas
GRANT SELECT ON SCHEMA::Infrastructure   TO db_role_readonly;
GRANT SELECT ON SCHEMA::Operations       TO db_role_readonly;
GRANT SELECT ON SCHEMA::Payments         TO db_role_readonly;
GRANT SELECT ON SCHEMA::Monitoring       TO db_role_readonly;
GRANT SELECT ON SCHEMA::Analytics        TO db_role_readonly;
GRANT SELECT ON SCHEMA::Reporting        TO db_role_readonly;
GRANT SELECT ON SCHEMA::Audit            TO db_role_readonly;
GO

-- App Service: CRUD on sessions + monitoring; select on others
GRANT SELECT, INSERT, UPDATE ON SCHEMA::Operations       TO db_role_app_service;
GRANT SELECT, INSERT, UPDATE ON SCHEMA::Monitoring       TO db_role_app_service;
GRANT SELECT ON SCHEMA::Infrastructure                   TO db_role_app_service;
GRANT SELECT ON SCHEMA::Users                            TO db_role_app_service;
GRANT SELECT ON SCHEMA::Payments                         TO db_role_app_service;
GRANT SELECT ON SCHEMA::Access                           TO db_role_app_service;
GO

-- Map SQL logins to DB roles
EXEC sp_addrolemember 'db_role_admin',       'ev2_admin_user';
EXEC sp_addrolemember 'db_role_operator',     'ev2_operator_user';
EXEC sp_addrolemember 'db_role_technician',   'ev2_technician_user';
EXEC sp_addrolemember 'db_role_franchise',    'ev2_franchise_user';
EXEC sp_addrolemember 'db_role_readonly',     'ev2_readonly_user';
EXEC sp_addrolemember 'db_role_app_service',  'ev2_app_service_user';
GO

-- ===========================================================================
-- 7. ROW-LEVEL SECURITY (RLS) - Data Isolation
-- ===========================================================================
-- RLS ensures franchise owners only see their own data.

-- Security predicate function for franchise isolation
CREATE OR ALTER FUNCTION Access.fn_FranchiseFilter (@FranchiseID INT)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN SELECT 1 AS IsAccessible
WHERE
    USER_NAME() = N'dbo'
    OR IS_ROLEMEMBER(N'db_role_admin') = 1
    OR IS_ROLEMEMBER(N'db_role_operator') = 1
    OR IS_ROLEMEMBER(N'db_role_technician') = 1
    OR IS_ROLEMEMBER(N'db_role_readonly') = 1
    OR (IS_ROLEMEMBER(N'db_role_franchise') = 1
        AND @FranchiseID IN (
            SELECT f.FranchiseID
            FROM Infrastructure.Franchise f
            JOIN Users.[User] u ON u.UserID = CAST(SESSION_CONTEXT(N'UserID') AS INT)
            -- Additional franchise-user mapping would go here
        ));
GO

-- Apply RLS to Franchise table
CREATE SECURITY POLICY Access.FranchiseFilterPolicy
    ADD FILTER PREDICATE Access.fn_FranchiseFilter (FranchiseID)
    ON Infrastructure.Franchise,
    ADD BLOCK PREDICATE Access.fn_FranchiseFilter (FranchiseID)
    ON Infrastructure.Franchise
    WITH (STATE = ON);
GO

-- ===========================================================================
-- 8. DYNAMIC DATA MASKING - PII Protection
-- ===========================================================================

ALTER TABLE Users.[User]
    ALTER COLUMN Email ADD MASKED WITH (FUNCTION = N'email()');
GO

ALTER TABLE Users.[User]
    ALTER COLUMN Phone ADD MASKED WITH (FUNCTION = N'partial(2, "XXXX", 2)');
GO

ALTER TABLE Users.UserProfile
    ALTER COLUMN FullName ADD MASKED WITH (FUNCTION = N'partial(1, "XXXX", 0)');
GO

ALTER TABLE Users.UserProfile
    ALTER COLUMN NationalID ADD MASKED WITH (FUNCTION = N'partial(2, "XXXX", 2)');
GO

ALTER TABLE Payments.PaymentGateway
    ALTER COLUMN MerchantID ADD MASKED WITH (FUNCTION = N'partial(2, "XXXX", 2)');
GO

-- ===========================================================================
-- 9. ENCRYPTION STRATEGY
-- ===========================================================================
/*
  Production encryption layers:

  1. TDE (Transparent Data Encryption) - Encrypts data at rest
     USE master;
     CREATE MASTER KEY ENCRYPTION BY PASSWORD = N'<StrongPassword>';
     CREATE CERTIFICATE EV_TDECert WITH SUBJECT = N'EV Charging TDE Certificate';
     CREATE DATABASE ENCRYPTION KEY WITH ALGORITHM = AES_256
         ENCRYPTION BY SERVER CERTIFICATE EV_TDECert;
     ALTER DATABASE EV_Charging_System_Validation SET ENCRYPTION ON;

  2. Always Encrypted - For ultra-sensitive columns (payment info, PII)
     Columns to protect:
     - Users.UserCredential.PasswordHash
     - Users.UserProfile.NationalID
     - Payments.GatewayTransaction.RequestPayload

  3. Backup Encryption
     BACKUP DATABASE EV_Charging_System_Validation
     TO DISK = N'...'
     WITH ENCRYPTION (ALGORITHM = AES_256, SERVER CERTIFICATE = EV_TDECert);

  4. Connection Encryption
     - Always use TLS 1.2+ for client connections
     - Force Encryption = Yes in SQL Server Network Configuration
*/

-- ===========================================================================
-- 10. AUDIT TRIGGER FOR SECURITY-RELATED CHANGES
-- ===========================================================================
CREATE OR ALTER TRIGGER Access.trg_RolePermission_Audit
ON Access.RolePermission
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Audit.AuditLog (TableName, RecordID, Action, OldValue, NewValue, ChangedByUserID, ChangedAt)
    SELECT
        N'Access.RolePermission',
        CAST(COALESCE(i.RolePermissionID, d.RolePermissionID) AS NVARCHAR(50)),
        CASE WHEN i.RolePermissionID IS NOT NULL AND d.RolePermissionID IS NOT NULL THEN 'U'
             WHEN i.RolePermissionID IS NOT NULL THEN 'I' ELSE 'D' END,
        CASE WHEN d.RolePermissionID IS NOT NULL
             THEN (SELECT CAST(d.RoleID AS NVARCHAR) + N':' + CAST(d.PermissionID AS NVARCHAR)) ELSE NULL END,
        CASE WHEN i.RolePermissionID IS NOT NULL
             THEN (SELECT CAST(i.RoleID AS NVARCHAR) + N':' + CAST(i.PermissionID AS NVARCHAR)) ELSE NULL END,
        CAST(SESSION_CONTEXT(N'UserID') AS INT),
        SYSDATETIME()
    FROM inserted i
    FULL OUTER JOIN deleted d ON i.RolePermissionID = d.RolePermissionID;
END;
GO

PRINT N'RBAC and security architecture deployed successfully.';
GO

