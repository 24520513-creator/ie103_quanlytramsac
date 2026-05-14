USE EV_Charging_System;
GO

/*
Optional server login examples. Run manually only if the SQL Server account can CREATE LOGIN.
CREATE LOGIN ev_admin01_login WITH PASSWORD = 'Admin@123';
CREATE LOGIN ev_operator01_login WITH PASSWORD = 'Operator@123';
CREATE LOGIN ev_business01_login WITH PASSWORD = 'Business@123';
CREATE LOGIN ev_customer01_login WITH PASSWORD = 'Customer@123';
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

ALTER ROLE db_ev_system_admin ADD MEMBER admin01;
ALTER ROLE db_ev_operations_staff ADD MEMBER operator01;
ALTER ROLE db_ev_business_manager ADD MEMBER business01;
ALTER ROLE db_ev_customer ADD MEMBER customer01;
GO

GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::Core TO db_ev_system_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::[Identity] TO db_ev_system_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::Infrastructure TO db_ev_system_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::Franchise TO db_ev_system_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::Operations TO db_ev_system_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::Payments TO db_ev_system_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::Maintenance TO db_ev_system_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::Reporting TO db_ev_system_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::Audit TO db_ev_system_admin;
GRANT EXECUTE TO db_ev_system_admin;
GO

GRANT SELECT, INSERT, UPDATE ON SCHEMA::Infrastructure TO db_ev_operations_staff;
GRANT SELECT, INSERT, UPDATE ON SCHEMA::Operations TO db_ev_operations_staff;
GRANT SELECT, INSERT, UPDATE ON SCHEMA::Maintenance TO db_ev_operations_staff;
GRANT SELECT ON SCHEMA::Reporting TO db_ev_operations_staff;
GRANT EXECUTE ON SCHEMA::Infrastructure TO db_ev_operations_staff;
GRANT EXECUTE ON SCHEMA::Operations TO db_ev_operations_staff;
GRANT EXECUTE ON SCHEMA::Maintenance TO db_ev_operations_staff;
GRANT EXECUTE ON OBJECT::Reporting.sp_ReportOperationalKPI TO db_ev_operations_staff;
GRANT EXECUTE ON OBJECT::Reporting.sp_ReportTelemetryHealth TO db_ev_operations_staff;
DENY SELECT, INSERT, UPDATE, DELETE ON SCHEMA::Payments TO db_ev_operations_staff;
DENY SELECT, INSERT, UPDATE, DELETE ON SCHEMA::[Identity] TO db_ev_operations_staff;
GO

GRANT SELECT ON SCHEMA::Franchise TO db_ev_business_manager;
GRANT SELECT ON SCHEMA::Payments TO db_ev_business_manager;
GRANT SELECT ON SCHEMA::Reporting TO db_ev_business_manager;
GRANT EXECUTE ON OBJECT::Franchise.sp_CreateRevenueSettlement TO db_ev_business_manager;
GRANT EXECUTE ON OBJECT::Payments.sp_CreatePayment TO db_ev_business_manager;
GRANT EXECUTE ON OBJECT::Payments.sp_CreateInvoice TO db_ev_business_manager;
GRANT EXECUTE ON OBJECT::Payments.sp_ProcessRefund TO db_ev_business_manager;
GRANT EXECUTE ON OBJECT::Reporting.sp_ReportStationRevenue TO db_ev_business_manager;
GRANT EXECUTE ON OBJECT::Reporting.sp_ReportFranchiseProfit TO db_ev_business_manager;
GRANT EXECUTE ON OBJECT::Reporting.sp_ReportPaymentRefund TO db_ev_business_manager;
DENY SELECT, INSERT, UPDATE, DELETE ON SCHEMA::[Identity] TO db_ev_business_manager;
DENY INSERT, UPDATE, DELETE ON SCHEMA::Infrastructure TO db_ev_business_manager;
DENY INSERT, UPDATE, DELETE ON SCHEMA::Operations TO db_ev_business_manager;
DENY INSERT, UPDATE, DELETE ON SCHEMA::Maintenance TO db_ev_business_manager;
GO

GRANT SELECT ON OBJECT::Reporting.vw_CustomerChargingHistory TO db_ev_customer;
GRANT EXECUTE ON OBJECT::Reporting.sp_ReportCustomerUsage TO db_ev_customer;
GRANT EXECUTE ON OBJECT::Operations.sp_StartChargingSession TO db_ev_customer;
GRANT EXECUTE ON OBJECT::Operations.sp_EndChargingSession TO db_ev_customer;
GRANT EXECUTE ON OBJECT::Payments.sp_TopUpWallet TO db_ev_customer;
GRANT EXECUTE ON OBJECT::Payments.sp_CreatePayment TO db_ev_customer;
GRANT EXECUTE ON OBJECT::Payments.sp_CreateInvoice TO db_ev_customer;
DENY SELECT, INSERT, UPDATE, DELETE ON SCHEMA::Payments TO db_ev_customer;
DENY SELECT, INSERT, UPDATE, DELETE ON SCHEMA::[Identity] TO db_ev_customer;
GO

PRINT N'08 - Security roles and permissions created.';
GO
