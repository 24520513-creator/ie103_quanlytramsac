/*=============================================================================
  EV_Charging_System - SECURITY SETUP
  Logins, Users, Roles, and Permissions
  =============================================================================*/

USE EV_Charging_System;
GO

-- ========================================
-- Server Logins
-- ========================================
IF NOT EXISTS (SELECT 1 FROM sys.sql_logins WHERE name = N'ev_admin_login')
    CREATE LOGIN ev_admin_login WITH PASSWORD = N'Admin@123456', DEFAULT_DATABASE = EV_Charging_System;
GO

IF NOT EXISTS (SELECT 1 FROM sys.sql_logins WHERE name = N'ev_manager_login')
    CREATE LOGIN ev_manager_login WITH PASSWORD = N'Manager@123456', DEFAULT_DATABASE = EV_Charging_System;
GO

IF NOT EXISTS (SELECT 1 FROM sys.sql_logins WHERE name = N'ev_technician_login')
    CREATE LOGIN ev_technician_login WITH PASSWORD = N'Technician@123456', DEFAULT_DATABASE = EV_Charging_System;
GO

IF NOT EXISTS (SELECT 1 FROM sys.sql_logins WHERE name = N'ev_readonly_login')
    CREATE LOGIN ev_readonly_login WITH PASSWORD = N'ReadOnly@123456', DEFAULT_DATABASE = EV_Charging_System;
GO

-- ========================================
-- Database Users
-- ========================================
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'ev_admin_user')
    CREATE USER ev_admin_user FOR LOGIN ev_admin_login;
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'ev_manager_user')
    CREATE USER ev_manager_user FOR LOGIN ev_manager_login;
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'ev_technician_user')
    CREATE USER ev_technician_user FOR LOGIN ev_technician_login;
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'ev_readonly_user')
    CREATE USER ev_readonly_user FOR LOGIN ev_readonly_login;
GO

-- ========================================
-- Database Roles
-- ========================================
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'Admin' AND type = 'R')
    CREATE ROLE Admin;
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'Manager' AND type = 'R')
    CREATE ROLE Manager;
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'Technician' AND type = 'R')
    CREATE ROLE Technician;
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'ReadOnly' AND type = 'R')
    CREATE ROLE ReadOnly;
GO

-- ========================================
-- Assign Users to Roles
-- ========================================
EXEC sp_addrolemember 'Admin', 'ev_admin_user';
EXEC sp_addrolemember 'Manager', 'ev_manager_user';
EXEC sp_addrolemember 'Technician', 'ev_technician_user';
EXEC sp_addrolemember 'ReadOnly', 'ev_readonly_user';
GO

-- ========================================
-- Schema-Level Permissions
-- ========================================

-- Admin: full control on all schemas
GRANT CONTROL ON SCHEMA::Infrastructure TO Admin;
GRANT CONTROL ON SCHEMA::Users TO Admin;
GRANT CONTROL ON SCHEMA::Operations TO Admin;
GRANT CONTROL ON SCHEMA::Monitoring TO Admin;
GRANT CONTROL ON SCHEMA::Reports TO Admin;
GRANT CONTROL ON SCHEMA::Security TO Admin;
GRANT VIEW DEFINITION ON DATABASE::EV_Charging_System TO Admin;
GO

-- Manager: CRUD on Operations + Reports; read-only on Infrastructure, Users, Monitoring
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::Operations TO Manager;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::Reports TO Manager;
GRANT SELECT ON SCHEMA::Infrastructure TO Manager;
GRANT SELECT ON SCHEMA::Users TO Manager;
GRANT SELECT ON SCHEMA::Monitoring TO Manager;
GRANT EXECUTE ON SCHEMA::Operations TO Manager;
GRANT EXECUTE ON SCHEMA::Reports TO Manager;
GO

-- Technician: full access on Infrastructure + Monitoring; read on Operations
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::Infrastructure TO Technician;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::Monitoring TO Technician;
GRANT SELECT ON SCHEMA::Operations TO Technician;
GRANT EXECUTE ON SCHEMA::Operations TO Technician;
GO

-- ReadOnly: SELECT on all schemas
GRANT SELECT ON SCHEMA::Infrastructure TO ReadOnly;
GRANT SELECT ON SCHEMA::Users TO ReadOnly;
GRANT SELECT ON SCHEMA::Operations TO ReadOnly;
GRANT SELECT ON SCHEMA::Monitoring TO ReadOnly;
GRANT SELECT ON SCHEMA::Reports TO ReadOnly;
GO

PRINT N'Security setup completed.';
GO
