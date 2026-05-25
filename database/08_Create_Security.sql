USE EV_Charging_System;
GO

/*
This script creates the core role-based access control model for the database.
The demo users below are created WITHOUT LOGIN so the script can run in database-only
environments and can be tested with EXECUTE AS USER.

Advanced security features such as Dynamic Data Masking are kept in:
database/09_Advanced_Security.sql

For real SQL Authentication logins in SSMS, run this script first, then run:
database/features/security/08_sql_authentication_logins.sql
*/
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'db_ev_system_admin') CREATE ROLE db_ev_system_admin;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'db_ev_operations_staff') CREATE ROLE db_ev_operations_staff;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'db_ev_business_manager') CREATE ROLE db_ev_business_manager;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'db_ev_customer') CREATE ROLE db_ev_customer;
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'admin01') CREATE USER admin01 WITHOUT LOGIN;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'operator01') CREATE USER operator01 WITHOUT LOGIN;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'business01') CREATE USER business01 WITHOUT LOGIN;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'customer01') CREATE USER customer01 WITHOUT LOGIN;
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

GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::Core TO db_ev_system_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::[Identity] TO db_ev_system_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::Infrastructure TO db_ev_system_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::Franchise TO db_ev_system_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::Operations TO db_ev_system_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::Payments TO db_ev_system_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::Maintenance TO db_ev_system_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::AppView TO db_ev_system_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::Audit TO db_ev_system_admin;
GRANT EXECUTE TO db_ev_system_admin;
GO

GRANT SELECT, INSERT, UPDATE ON SCHEMA::Infrastructure TO db_ev_operations_staff;
GRANT SELECT, INSERT, UPDATE ON SCHEMA::Operations TO db_ev_operations_staff;
GRANT SELECT, INSERT, UPDATE ON SCHEMA::Maintenance TO db_ev_operations_staff;
GRANT SELECT ON SCHEMA::AppView TO db_ev_operations_staff;
GRANT EXECUTE ON SCHEMA::Infrastructure TO db_ev_operations_staff;
GRANT EXECUTE ON SCHEMA::Operations TO db_ev_operations_staff;
GRANT EXECUTE ON SCHEMA::Maintenance TO db_ev_operations_staff;
GRANT EXECUTE ON OBJECT::AppView.sp_GetOperationalKPI TO db_ev_operations_staff;
GRANT EXECUTE ON OBJECT::AppView.sp_GetTelemetryHealth TO db_ev_operations_staff;
DENY SELECT, INSERT, UPDATE, DELETE ON SCHEMA::Payments TO db_ev_operations_staff;
DENY SELECT, INSERT, UPDATE, DELETE ON SCHEMA::[Identity] TO db_ev_operations_staff;
GO

GRANT SELECT ON OBJECT::AppView.vw_StationRevenueDaily TO db_ev_business_manager;
GRANT SELECT ON OBJECT::AppView.vw_FranchiseRevenueMonthly TO db_ev_business_manager;
GRANT SELECT ON OBJECT::AppView.vw_ProfitSharing TO db_ev_business_manager;
GRANT SELECT ON OBJECT::AppView.vw_PaymentSummary TO db_ev_business_manager;
GRANT SELECT ON OBJECT::AppView.vw_PeakHourStatistics TO db_ev_business_manager;
GRANT SELECT ON OBJECT::AppView.vw_TopRevenueStations TO db_ev_business_manager;
GRANT SELECT ON OBJECT::AppView.vw_CustomerGrowth TO db_ev_business_manager;
GRANT SELECT ON OBJECT::AppView.vw_SystemOperationalKPI TO db_ev_business_manager;
GRANT SELECT ON OBJECT::AppView.vw_RegionRevenue TO db_ev_business_manager;
GRANT SELECT ON OBJECT::AppView.vw_ChargingSessionStatistics TO db_ev_business_manager;
GRANT SELECT ON OBJECT::AppView.vw_TopCustomerUsage TO db_ev_business_manager;
GRANT EXECUTE ON OBJECT::Franchise.sp_CreateRevenueSettlement TO db_ev_business_manager;
GRANT EXECUTE ON OBJECT::Franchise.sp_UpdateRevenueSharePolicy TO db_ev_business_manager;
GRANT EXECUTE ON OBJECT::AppView.sp_GetStationRevenue TO db_ev_business_manager;
GRANT EXECUTE ON OBJECT::AppView.sp_GetFranchiseProfitSharing TO db_ev_business_manager;
GRANT EXECUTE ON OBJECT::AppView.sp_GetPaymentSummary TO db_ev_business_manager;
DENY SELECT, INSERT, UPDATE, DELETE ON SCHEMA::[Identity] TO db_ev_business_manager;
DENY SELECT, INSERT, UPDATE, DELETE ON SCHEMA::Payments TO db_ev_business_manager;
DENY INSERT, UPDATE, DELETE ON SCHEMA::Infrastructure TO db_ev_business_manager;
DENY INSERT, UPDATE, DELETE ON SCHEMA::Operations TO db_ev_business_manager;
DENY INSERT, UPDATE, DELETE ON SCHEMA::Maintenance TO db_ev_business_manager;
GO

GRANT SELECT ON OBJECT::AppView.vw_CustomerChargingHistory TO db_ev_customer;
GRANT SELECT ON OBJECT::AppView.vw_AvailableChargingPoints TO db_ev_customer;
GRANT SELECT ON OBJECT::AppView.vw_CustomerBookingHistory TO db_ev_customer;
GRANT SELECT ON OBJECT::AppView.vw_InvoiceDetail TO db_ev_customer;
GRANT EXECUTE ON OBJECT::AppView.sp_GetCustomerUsage TO db_ev_customer;
GRANT EXECUTE ON OBJECT::Operations.sp_CreateVehicle TO db_ev_customer;
GRANT EXECUTE ON OBJECT::Operations.sp_UpdateVehicle TO db_ev_customer;
GRANT EXECUTE ON OBJECT::Operations.sp_CreateBooking TO db_ev_customer;
GRANT EXECUTE ON OBJECT::Operations.sp_CancelBooking TO db_ev_customer;
GRANT EXECUTE ON OBJECT::Operations.sp_StartChargingSession TO db_ev_customer;
GRANT EXECUTE ON OBJECT::Operations.sp_EndChargingSession TO db_ev_customer;
GRANT EXECUTE ON OBJECT::Payments.sp_CreatePayment TO db_ev_customer;
GRANT EXECUTE ON OBJECT::Payments.sp_CreateInvoice TO db_ev_customer;
DENY SELECT, INSERT, UPDATE, DELETE ON SCHEMA::Payments TO db_ev_customer;
DENY SELECT, INSERT, UPDATE, DELETE ON SCHEMA::[Identity] TO db_ev_customer;
GO

PRINT N'08 - Core security roles, users, GRANT and DENY permissions created.';
GO

