USE master;
GO

IF DB_ID(N'EV_Charging_System') IS NOT NULL
BEGIN
    ALTER DATABASE EV_Charging_System SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE EV_Charging_System;
END;
GO

CREATE DATABASE EV_Charging_System;
GO

ALTER DATABASE EV_Charging_System SET RECOVERY SIMPLE;
GO

USE EV_Charging_System;
GO

PRINT N'00 - Database EV_Charging_System created.';
GO
