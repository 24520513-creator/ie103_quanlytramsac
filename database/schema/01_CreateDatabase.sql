/*==============================================================================
  EV_Charging_System - ENTERPRISE DATABASE CREATION
  ==============================================================================
  Architecture:     Domain-separated, microservice-ready, analytics-optimized
  Target Server:    Microsoft SQL Server 2022+
  Compliance:       SOC2, GDPR-ready, PCI-DSS patterns
  ==============================================================================*/

-- =============================================================================
-- 0. DROP EXISTING DATABASE (FOR RE-RUN SAFETY)
-- =============================================================================
IF DB_ID(N'EV_Charging_System') IS NOT NULL
BEGIN
    ALTER DATABASE EV_Charging_System SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE EV_Charging_System;
END
GO

-- 1. CREATE DATABASE WITH PORTABLE CONFIGURATION
-- =============================================================================
-- Use SQL Server's default data/log locations so the script works across
-- developer machines and different instance names in SSMS.
CREATE DATABASE EV_Charging_System
COLLATE Latin1_General_CI_AS;
GO

-- =============================================================================
-- 2. SET PRODUCTION DATABASE OPTIONS
-- =============================================================================
ALTER DATABASE EV_Charging_System SET RECOVERY FULL;
ALTER DATABASE EV_Charging_System SET AUTO_CREATE_STATISTICS ON;
ALTER DATABASE EV_Charging_System SET AUTO_UPDATE_STATISTICS ON;
ALTER DATABASE EV_Charging_System SET AUTO_UPDATE_STATISTICS_ASYNC ON;
ALTER DATABASE EV_Charging_System SET PAGE_VERIFY CHECKSUM;
ALTER DATABASE EV_Charging_System SET READ_COMMITTED_SNAPSHOT ON;
ALTER DATABASE EV_Charging_System SET ALLOW_SNAPSHOT_ISOLATION ON;
ALTER DATABASE EV_Charging_System SET DELAYED_DURABILITY = DISABLED;
GO

USE EV_Charging_System;
GO

-- =============================================================================
-- 3. CREATE SCHEMAS (Domain Boundaries)
-- =============================================================================
-- Infrastructure: Physical assets, locations, suppliers, contracts
CREATE SCHEMA Infrastructure;
GO

-- Access: Role-based access control, permissions, security policies
CREATE SCHEMA Access;
GO

-- Users: User profiles, authentication, sessions, vehicles
CREATE SCHEMA Users;
GO

-- Operations: Charging sessions, pricing, maintenance workflows
CREATE SCHEMA Operations;
GO

-- Payments: Transactions, wallets, invoices, gateways, refunds
CREATE SCHEMA Payments;
GO

-- Monitoring: Telemetry, heartbeats, error logs, alerts
CREATE SCHEMA Monitoring;
GO

-- Audit: Immutable audit logs, status history, change tracking
CREATE SCHEMA Audit;
GO

-- Analytics: Materialized KPIs, aggregation tables, BI snapshots
CREATE SCHEMA Analytics;
GO

-- Reporting: Report views, business intelligence queries
CREATE SCHEMA Reporting;
GO

PRINT N'Database EV_Charging_System created with 9 domain schemas.';
GO
