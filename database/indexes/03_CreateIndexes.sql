/*=============================================================================
  EV_Charging_System - CREATE INDEXES
  =============================================================================*/

USE EV_Charging_System;
GO

-- Foreign key indexes
CREATE INDEX IX_ChargingStation_FranchiseeID
    ON Infrastructure.ChargingStation (FranchiseeID);
GO

CREATE INDEX IX_ChargingStation_SupplierID
    ON Infrastructure.ChargingStation (SupplierID);
GO

CREATE INDEX IX_ChargingPoint_StationID
    ON Infrastructure.ChargingPoint (StationID);
GO

CREATE INDEX IX_Vehicles_UserID
    ON Users.Vehicles (UserID);
GO

CREATE INDEX IX_ChargingSession_UserID
    ON Operations.ChargingSession (UserID);
GO

CREATE INDEX IX_ChargingSession_PointID
    ON Operations.ChargingSession (PointID);
GO

CREATE INDEX IX_ChargingSession_PolicyID
    ON Operations.ChargingSession (PolicyID);
GO

CREATE INDEX IX_Transactions_UserID
    ON Operations.Transactions (UserID);
GO

CREATE INDEX IX_Transactions_SessionID
    ON Operations.Transactions (SessionID);
GO

CREATE INDEX IX_ErrorLogs_PointID
    ON Monitoring.ErrorLogs (PointID);
GO

CREATE INDEX IX_MaintenanceSchedule_StationID
    ON Monitoring.MaintenanceSchedule (StationID);
GO

-- Transaction timestamp index for reporting
CREATE INDEX IX_Transactions_Timestamp
    ON Operations.Transactions ([Timestamp])
    INCLUDE (Amount, TransactionType);
GO

-- Charging session time index
CREATE INDEX IX_ChargingSession_StartTime_EndTime
    ON Operations.ChargingSession (StartTime, EndTime)
    INCLUDE (Total_kWh, CostTotal);
GO

-- Station lookup index
CREATE INDEX IX_ChargingStation_StationStatus
    ON Infrastructure.ChargingStation (StationStatus)
    INCLUDE (StationName, Address);
GO

-- Customer email index
CREATE INDEX IX_Customers_Email
    ON Users.Customers (Email)
    INCLUDE (FullName, AccountStatus);
GO

PRINT N'All indexes created successfully.';
GO
