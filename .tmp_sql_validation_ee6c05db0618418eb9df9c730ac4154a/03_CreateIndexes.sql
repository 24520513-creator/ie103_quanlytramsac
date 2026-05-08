/*==============================================================================
  EV_Charging_System_Validation - ENTERPRISE INDEX STRATEGY
  ==============================================================================
  Strategy: Clustered | Nonclustered | Filtered | Covering | Columnstore
  =============================================================================*/

USE EV_Charging_System_Validation;
GO

-- ===========================================================================
-- 1. INFRASTRUCTURE SCHEMA INDEXES
-- ===========================================================================

-- ChargingStation: geographic lookups + status queries
CREATE NONCLUSTERED INDEX IX_ChargingStation_FranchiseID
    ON Infrastructure.ChargingStation (FranchiseID)
    INCLUDE (StationName, StationStatus, Latitude, Longitude);
GO

CREATE NONCLUSTERED INDEX IX_ChargingStation_StationStatus
    ON Infrastructure.ChargingStation (StationStatus)
    INCLUDE (StationID, StationCode, StationName, MaxCapacityKW);
GO

CREATE NONCLUSTERED INDEX IX_ChargingStation_Location
    ON Infrastructure.ChargingStation (Latitude, Longitude)
    WHERE Latitude IS NOT NULL AND Longitude IS NOT NULL;
GO

-- ChargingPoint: status + station lookups
CREATE NONCLUSTERED INDEX IX_ChargingPoint_StationID
    ON Infrastructure.ChargingPoint (StationID)
    INCLUDE (PointCode, ConnectorType, PowerKW, PointStatus);
GO

CREATE NONCLUSTERED INDEX IX_ChargingPoint_Status
    ON Infrastructure.ChargingPoint (PointStatus, StationID)
    INCLUDE (PowerKW)
    WHERE PointStatus IN (N'Available', N'Busy');
GO

-- StationElectricityContract: active contract lookups
CREATE NONCLUSTERED INDEX IX_StationElectricityContract_StationID
    ON Infrastructure.StationElectricityContract (StationID, IsActive)
    INCLUDE (SupplierID, UnitPricePerKWh)
    WHERE IsActive = 1;
GO

-- Franchise: active franchise lookups
CREATE NONCLUSTERED INDEX IX_Franchise_IsActive
    ON Infrastructure.Franchise (IsActive)
    INCLUDE (FranchiseCode, FranchiseName, RevenueShareRate);
GO

-- ===========================================================================
-- 2. ACCESS SCHEMA INDEXES
-- ===========================================================================

CREATE NONCLUSTERED INDEX IX_RolePermission_RoleID
    ON Access.RolePermission (RoleID)
    INCLUDE (PermissionID);
GO

-- ===========================================================================
-- 3. USERS SCHEMA INDEXES
-- ===========================================================================

-- User: authentication lookups
CREATE NONCLUSTERED INDEX IX_User_Email_AccountStatus
    ON Users.[User] (Email, AccountStatus)
    INCLUDE (UserGuid, Username);
GO

CREATE NONCLUSTERED INDEX IX_User_Username
    ON Users.[User] (Username)
    INCLUDE (UserID, AccountStatus, Email);
GO

CREATE NONCLUSTERED INDEX IX_User_AccountStatus
    ON Users.[User] (AccountStatus)
    INCLUDE (UserID, Email, Username, LastLoginAt);
GO

-- Vehicle: user vehicle lookups
CREATE NONCLUSTERED INDEX IX_Vehicle_UserID
    ON Users.Vehicle (UserID)
    INCLUDE (PlateNumber, Brand, Model, BatteryCapacityKWh, ConnectorType)
    WHERE IsDeleted = 0;
GO

-- UserSession: active session lookups
CREATE NONCLUSTERED INDEX IX_UserSession_UserID
    ON Users.UserSession (UserID, IsRevoked)
    INCLUDE (SessionToken, ExpiresAt);
GO

CREATE NONCLUSTERED INDEX IX_UserSession_Token
    ON Users.UserSession (SessionToken)
    WHERE IsRevoked = 0;
GO

-- UserLoginHistory: user audit
CREATE NONCLUSTERED INDEX IX_UserLoginHistory_UserID
    ON Users.UserLoginHistory (UserID, LoginAt DESC)
    INCLUDE (LoginSuccess, IPAddress);
GO

-- ===========================================================================
-- 4. OPERATIONS SCHEMA INDEXES
-- ===========================================================================

-- ChargingSession: THE most queried table - extensive covering indexes
CREATE NONCLUSTERED INDEX IX_ChargingSession_UserID
    ON Operations.ChargingSession (UserID, StartTime DESC)
    INCLUDE (SessionCode, PointID, StationID, TotalKWh, CostTotal, SessionStatus)
    WHERE IsDeleted = 0;
GO

CREATE NONCLUSTERED INDEX IX_ChargingSession_StationID
    ON Operations.ChargingSession (StationID, StartTime DESC)
    INCLUDE (UserID, TotalKWh, CostTotal, ChargingDurationMinutes, SessionStatus);
GO

CREATE NONCLUSTERED INDEX IX_ChargingSession_PointID_Status
    ON Operations.ChargingSession (PointID, SessionStatus)
    INCLUDE (SessionID, StartTime)
    WHERE SessionStatus = N'Charging';
GO

CREATE NONCLUSTERED INDEX IX_ChargingSession_TimeRange
    ON Operations.ChargingSession (StartTime, EndTime)
    INCLUDE (UserID, PointID, TotalKWh, CostTotal, SessionStatus)
    WHERE IsDeleted = 0;
GO

-- Covering index for revenue analytics
CREATE NONCLUSTERED INDEX IX_ChargingSession_RevenueAnalytics
    ON Operations.ChargingSession (StartTime, SessionStatus)
    INCLUDE (StationID, UserID, TotalKWh, CostTotal, ChargingDurationMinutes, AveragePowerKW)
    WHERE SessionStatus = N'Completed' AND IsDeleted = 0;
GO

-- PricingPolicy: active policy lookups
CREATE NONCLUSTERED INDEX IX_PricingPolicy_Active
    ON Operations.PricingPolicy (IsActive, AppliedFrom, AppliedTo)
    INCLUDE (PolicyCode, PolicyName, BasePricePerKWh, PolicyType);
GO

-- MaintenanceSchedule: upcoming maintenance
CREATE NONCLUSTERED INDEX IX_MaintenanceSchedule_StationID
    ON Operations.MaintenanceSchedule (StationID, ScheduleStatus)
    INCLUDE (ScheduledDate, MaintenanceType, Priority);
GO

CREATE NONCLUSTERED INDEX IX_MaintenanceSchedule_Date
    ON Operations.MaintenanceSchedule (ScheduledDate)
    WHERE ScheduleStatus IN (N'Scheduled', N'InProgress');
GO

-- ===========================================================================
-- 5. PAYMENTS SCHEMA INDEXES
-- ===========================================================================

-- Transaction: financial lookups + reporting
CREATE NONCLUSTERED INDEX IX_Transaction_UserID
    ON Payments.[Transaction] (UserID, TransactedAt DESC)
    INCLUDE (TransactionCode, Amount, TransactionType, TransactionStatus)
    WHERE IsDeleted = 0;
GO

CREATE NONCLUSTERED INDEX IX_Transaction_SessionID
    ON Payments.[Transaction] (SessionID)
    WHERE SessionID IS NOT NULL;
GO

CREATE NONCLUSTERED INDEX IX_Transaction_Status
    ON Payments.[Transaction] (TransactionStatus, CreatedAt)
    INCLUDE (Amount, TransactionType)
    WHERE TransactionStatus IN (N'Pending', N'Processing');
GO

CREATE NONCLUSTERED INDEX IX_Transaction_DateRange
    ON Payments.[Transaction] (TransactedAt DESC)
    INCLUDE (UserID, Amount, TransactionType, TransactionStatus, FeeAmount)
    WHERE IsDeleted = 0;
GO

-- Invoice: billing lookups
CREATE NONCLUSTERED INDEX IX_Invoice_UserID
    ON Payments.Invoice (UserID, InvoiceStatus)
    INCLUDE (InvoiceCode, TotalAmount, DueDate);
GO

-- GatewayTransaction: status tracking
CREATE NONCLUSTERED INDEX IX_GatewayTransaction_TransactionID
    ON Payments.GatewayTransaction (TransactionID)
    INCLUDE (GatewayID, GatewayReferenceID, GatewayStatus, AttemptCount);
GO

CREATE NONCLUSTERED INDEX IX_GatewayTransaction_ReferenceID
    ON Payments.GatewayTransaction (GatewayReferenceID)
    WHERE GatewayReferenceID IS NOT NULL;
GO

-- ===========================================================================
-- 6. MONITORING SCHEMA INDEXES
-- ===========================================================================

-- ErrorLog: error lookup + trending
CREATE NONCLUSTERED INDEX IX_ErrorLog_PointID
    ON Monitoring.ErrorLog (PointID, OccurredAt DESC)
    INCLUDE (ErrorCode, Severity, ResolvedAt);
GO

CREATE NONCLUSTERED INDEX IX_ErrorLog_StationID
    ON Monitoring.ErrorLog (StationID, OccurredAt DESC)
    WHERE StationID IS NOT NULL;
GO

CREATE NONCLUSTERED INDEX IX_ErrorLog_TimeRange
    ON Monitoring.ErrorLog (OccurredAt DESC)
    INCLUDE (ErrorCode, Severity, PointID, StationID);
GO

-- PointTelemetry: time-series lookups
CREATE NONCLUSTERED INDEX IX_PointTelemetry_PointID_Time
    ON Monitoring.PointTelemetry (PointID, RecordedAt DESC)
    INCLUDE (Voltage, Amperage, PowerKW, TemperatureC);
GO

-- StationHeartbeat: connectivity monitoring
CREATE NONCLUSTERED INDEX IX_StationHeartbeat_StationID
    ON Monitoring.StationHeartbeat (StationID, RecordedAt DESC)
    INCLUDE (NetworkStatus, IsHealthy, ResponseTimeMs);
GO

CREATE NONCLUSTERED INDEX IX_StationHeartbeat_Recent
    ON Monitoring.StationHeartbeat (RecordedAt DESC)
    INCLUDE (StationID, NetworkStatus, IsHealthy);
GO

-- Alert: active alerts
CREATE NONCLUSTERED INDEX IX_Alert_Status
    ON Monitoring.Alert (AlertStatus, Severity, CreatedAt DESC)
    INCLUDE (AlertTitle, PointID, StationID)
    WHERE AlertStatus IN (N'Open', N'Acknowledged');
GO

-- ===========================================================================
-- 7. AUDIT SCHEMA INDEXES
-- ===========================================================================

CREATE NONCLUSTERED INDEX IX_AuditLog_Table_Record
    ON Audit.AuditLog (TableName, RecordID, ChangedAt DESC)
    INCLUDE (Action, ChangedByUserID);
GO

CREATE NONCLUSTERED INDEX IX_StationStatusHistory_StationID
    ON Audit.StationStatusHistory (StationID, ChangedAt DESC);
GO

CREATE NONCLUSTERED INDEX IX_PointStatusHistory_PointID
    ON Audit.PointStatusHistory (PointID, ChangedAt DESC);
GO

CREATE NONCLUSTERED INDEX IX_SessionStatusHistory_SessionID
    ON Audit.SessionStatusHistory (SessionID, ChangedAt DESC);
GO

-- ===========================================================================
-- 8. ANALYTICS SCHEMA INDEXES
-- ===========================================================================

CREATE NONCLUSTERED INDEX IX_DailyStationKPI_Date
    ON Analytics.DailyStationKPI (KpiDate DESC, StationID)
    INCLUDE (TotalSessions, TotalKWh, TotalRevenue, UniqueUsers);
GO

CREATE NONCLUSTERED INDEX IX_DailyFranchiseKPI_Date
    ON Analytics.DailyFranchiseKPI (KpiDate DESC, FranchiseID)
    INCLUDE (TotalSessions, TotalRevenue, CommissionAmount);
GO

CREATE NONCLUSTERED INDEX IX_HourlySessionAgg_PeakAnalysis
    ON Analytics.HourlySessionAgg (AggDate, StationID)
    INCLUDE (AggHour, TotalSessions, TotalKWh, TotalRevenue);
GO

-- ===========================================================================
-- 9. PARTITIONING STRATEGY
-- ===========================================================================
-- Partitioning is prepared for larger tables.
-- Actual partition function/scheme creation is environment-specific.
-- Below are the recommended partition columns:

-- ChargingSession:   Partition by YEAR(StartTime) for sliding window
-- Transaction:       Partition by YEAR(TransactedAt) for sliding window
-- PointTelemetry:    Partition by YEAR(RecordedAt) for sliding window
-- StationHeartbeat:  Partition by YEAR(RecordedAt) for sliding window
-- ErrorLog:          Partition by YEAR(OccurredAt) for sliding window
-- AuditLog:          Partition by YEAR(ChangedAt) for sliding window

/*
-- Example partition setup (uncomment for deployment):
CREATE PARTITION FUNCTION PF_ChargingSession_Year (DATETIME2)
    AS RANGE RIGHT FOR VALUES (
        '2024-01-01', '2025-01-01', '2026-01-01',
        '2027-01-01', '2028-01-01', '2029-01-01'
    );
GO

CREATE PARTITION SCHEME PS_ChargingSession_Year
    AS PARTITION PF_ChargingSession_Year
    ALL TO ([PRIMARY]);
GO

-- Create partitioned clustered index:
CREATE CLUSTERED INDEX CX_ChargingSession_StartTime
    ON Operations.ChargingSession (StartTime)
    ON PS_ChargingSession_Year (StartTime);
GO
*/

-- ===========================================================================
-- 10. COLUMNSTORE FOR ANALYTICS
-- ===========================================================================
-- For large-scale analytics workloads, add columnstore indexes:

/*
CREATE NONCLUSTERED COLUMNSTORE INDEX CSIX_ChargingSession_Analytics
    ON Operations.ChargingSession (
        StartTime, EndTime, StationID, UserID, TotalKWh, CostTotal,
        ChargingDurationMinutes, SessionStatus, SessionType
    )
    WHERE IsDeleted = 0;
GO
*/

PRINT N'Enterprise indexes created successfully.';
GO

