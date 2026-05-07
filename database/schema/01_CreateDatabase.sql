/*=============================================================================
  EV_Charging_System - CREATE DATABASE & SCHEMAS
  =============================================================================*/

IF DB_ID(N'EV_Charging_System') IS NULL
BEGIN
    CREATE DATABASE EV_Charging_System;
END
GO

USE EV_Charging_System;
GO

CREATE SCHEMA Infrastructure;
GO

CREATE SCHEMA Users;
GO

CREATE SCHEMA Operations;
GO

CREATE SCHEMA Monitoring;
GO

CREATE SCHEMA Reports;
GO

CREATE SCHEMA Security;
GO

PRINT N'Database and schemas created successfully.';
GO
