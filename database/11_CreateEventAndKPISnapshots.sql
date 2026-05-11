USE EV_Charging_System;
GO

-- ============================================================
-- Event persistence table for realtime event bus
-- ============================================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'RealtimeEvent' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.RealtimeEvent (
        EventID       BIGINT IDENTITY(1,1) NOT NULL,
        EventType     NVARCHAR(100) NOT NULL,
        AggregateType NVARCHAR(50) NULL,
        AggregateID   NVARCHAR(50) NULL,
        Payload       NVARCHAR(MAX) NULL,
        UserID        INT NULL,
        CreatedAt     DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
        ProcessedAt   DATETIME2 NULL,
        CONSTRAINT PK_RealtimeEvent PRIMARY KEY CLUSTERED (EventID)
    );

    CREATE NONCLUSTERED INDEX IX_RealtimeEvent_Type
        ON dbo.RealtimeEvent (EventType, CreatedAt DESC)
        INCLUDE (AggregateID, UserID);

    CREATE NONCLUSTERED INDEX IX_RealtimeEvent_User
        ON dbo.RealtimeEvent (UserID, CreatedAt DESC)
        WHERE UserID IS NOT NULL;

    PRINT N'RealtimeEvent table created.';
END
ELSE
BEGIN
    PRINT N'RealtimeEvent table already exists.';
END
GO

-- ============================================================
-- KPI snapshot tables for analytics
-- ============================================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'KPISnapshotHourly' AND schema_id = SCHEMA_ID('Reporting'))
BEGIN
    CREATE TABLE Reporting.KPISnapshotHourly (
        SnapshotID       INT IDENTITY(1,1) NOT NULL,
        SnapshotAt       DATETIME2 NOT NULL,
        TotalUsers       INT NOT NULL DEFAULT 0,
        ActiveStations   INT NOT NULL DEFAULT 0,
        TotalPoints      INT NOT NULL DEFAULT 0,
        AvailablePoints  INT NOT NULL DEFAULT 0,
        BusyPoints       INT NOT NULL DEFAULT 0,
        OfflinePoints    INT NOT NULL DEFAULT 0,
        ActiveSessions   INT NOT NULL DEFAULT 0,
        SessionsLastHour INT NOT NULL DEFAULT 0,
        KWhLastHour      DECIMAL(18,2) NOT NULL DEFAULT 0,
        RevenueLastHour  DECIMAL(18,2) NOT NULL DEFAULT 0,
        UnresolvedErrors INT NOT NULL DEFAULT 0,
        PendingBookings  INT NOT NULL DEFAULT 0,
        TotalRevenue     DECIMAL(18,2) NOT NULL DEFAULT 0,
        TotalKWh         DECIMAL(18,2) NOT NULL DEFAULT 0,
        CONSTRAINT PK_KPISnapshotHourly PRIMARY KEY CLUSTERED (SnapshotID)
    );

    CREATE UNIQUE INDEX IX_KPISnapshotHourly_Time
        ON Reporting.KPISnapshotHourly (SnapshotAt DESC);

    PRINT N'KPISnapshotHourly table created.';
END
ELSE
BEGIN
    PRINT N'KPISnapshotHourly table already exists.';
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'KPISnapshotDaily' AND schema_id = SCHEMA_ID('Reporting'))
BEGIN
    CREATE TABLE Reporting.KPISnapshotDaily (
        SnapshotID       INT IDENTITY(1,1) NOT NULL,
        SnapshotDate     DATE NOT NULL,
        NewUsers         INT NOT NULL DEFAULT 0,
        ActiveStations   INT NOT NULL DEFAULT 0,
        TotalSessions    INT NOT NULL DEFAULT 0,
        CompletedSessions INT NOT NULL DEFAULT 0,
        TotalKWh         DECIMAL(18,2) NOT NULL DEFAULT 0,
        TotalRevenue     DECIMAL(18,2) NOT NULL DEFAULT 0,
        AvgDurationMin   DECIMAL(10,2) NOT NULL DEFAULT 0,
        PeakHour         INT NULL,
        PeakHourSessions INT NOT NULL DEFAULT 0,
        UniqueCustomers  INT NOT NULL DEFAULT 0,
        ErrorsCreated    INT NOT NULL DEFAULT 0,
        ErrorsResolved   INT NOT NULL DEFAULT 0,
        MaintenanceScheduled INT NOT NULL DEFAULT 0,
        MaintenanceCompleted INT NOT NULL DEFAULT 0,
        CONSTRAINT PK_KPISnapshotDaily PRIMARY KEY CLUSTERED (SnapshotID)
    );

    CREATE UNIQUE INDEX IX_KPISnapshotDaily_Date
        ON Reporting.KPISnapshotDaily (SnapshotDate DESC);

    PRINT N'KPISnapshotDaily table created.';
END
ELSE
BEGIN
    PRINT N'KPISnapshotDaily table already exists.';
END
GO

-- ============================================================
-- Stored proc: Record hourly KPI snapshot
-- ============================================================
CREATE OR ALTER PROCEDURE Reporting.sp_TakeHourlySnapshot
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Reporting.KPISnapshotHourly (
        SnapshotAt, TotalUsers, ActiveStations, TotalPoints,
        AvailablePoints, BusyPoints, OfflinePoints, ActiveSessions,
        SessionsLastHour, KWhLastHour, RevenueLastHour,
        UnresolvedErrors, PendingBookings, TotalRevenue, TotalKWh
    )
    SELECT
        SYSDATETIME(),
        (SELECT COUNT(*) FROM [Users].[User] WHERE AccountStatus = 'Active'),
        (SELECT COUNT(*) FROM [Infrastructure].[ChargingStation] WHERE IsActive = 1 AND StationStatus = 'Active'),
        (SELECT COUNT(*) FROM [Infrastructure].[ChargingPoint] WHERE IsActive = 1),
        (SELECT COUNT(*) FROM [Infrastructure].[ChargingPoint] WHERE IsActive = 1 AND PointStatus = 'Available'),
        (SELECT COUNT(*) FROM [Infrastructure].[ChargingPoint] WHERE IsActive = 1 AND PointStatus = 'Busy'),
        (SELECT COUNT(*) FROM [Infrastructure].[ChargingPoint] WHERE IsActive = 1 AND PointStatus = 'Offline'),
        (SELECT COUNT(*) FROM [Operations].[ChargingSession] WHERE SessionStatus = 'Charging'),
        (SELECT COUNT(*) FROM [Operations].[ChargingSession] WHERE StartTime >= DATEADD(HOUR, -1, SYSDATETIME())),
        ISNULL((SELECT SUM(TotalKWh) FROM [Operations].[ChargingSession] WHERE StartTime >= DATEADD(HOUR, -1, SYSDATETIME())), 0),
        ISNULL((SELECT SUM(CostTotal) FROM [Operations].[ChargingSession] WHERE StartTime >= DATEADD(HOUR, -1, SYSDATETIME())), 0),
        (SELECT COUNT(*) FROM [Infrastructure].[ErrorLog] WHERE IsActive = 1 AND ResolvedAt IS NULL),
        (SELECT COUNT(*) FROM [Operations].[Booking] WHERE Status IN ('Pending', 'Confirmed')),
        ISNULL((SELECT SUM(CostTotal) FROM [Operations].[ChargingSession] WHERE SessionStatus = 'Completed'), 0),
        ISNULL((SELECT SUM(TotalKWh) FROM [Operations].[ChargingSession] WHERE SessionStatus = 'Completed'), 0);

    PRINT N'Hourly KPI snapshot recorded.';
END;
GO

-- ============================================================
-- Stored proc: Record daily KPI snapshot (run at midnight)
-- ============================================================
CREATE OR ALTER PROCEDURE Reporting.sp_TakeDailySnapshot
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Today DATE = CAST(SYSDATETIME() AS DATE);
    DECLARE @Yesterday DATE = DATEADD(DAY, -1, @Today);

    INSERT INTO Reporting.KPISnapshotDaily (
        SnapshotDate, NewUsers, ActiveStations, TotalSessions,
        CompletedSessions, TotalKWh, TotalRevenue, AvgDurationMin,
        PeakHour, PeakHourSessions, UniqueCustomers,
        ErrorsCreated, ErrorsResolved,
        MaintenanceScheduled, MaintenanceCompleted
    )
    SELECT
        @Yesterday,
        (SELECT COUNT(*) FROM [Users].[User] WHERE CAST(CreatedAt AS DATE) = @Yesterday),
        (SELECT COUNT(*) FROM [Infrastructure].[ChargingStation] WHERE IsActive = 1 AND StationStatus = 'Active'),
        (SELECT COUNT(*) FROM [Operations].[ChargingSession] WHERE CAST(StartTime AS DATE) = @Yesterday),
        (SELECT COUNT(*) FROM [Operations].[ChargingSession] WHERE CAST(StartTime AS DATE) = @Yesterday AND SessionStatus = 'Completed'),
        ISNULL((SELECT SUM(TotalKWh) FROM [Operations].[ChargingSession] WHERE CAST(StartTime AS DATE) = @Yesterday), 0),
        ISNULL((SELECT SUM(CostTotal) FROM [Operations].[ChargingSession] WHERE CAST(StartTime AS DATE) = @Yesterday), 0),
        ISNULL((SELECT AVG(ChargingDurationMinutes) FROM [Operations].[ChargingSession] WHERE CAST(StartTime AS DATE) = @Yesterday AND SessionStatus = 'Completed'), 0),
        (SELECT TOP 1 DATEPART(HOUR, StartTime) FROM [Operations].[ChargingSession]
         WHERE CAST(StartTime AS DATE) = @Yesterday
         GROUP BY DATEPART(HOUR, StartTime) ORDER BY COUNT(*) DESC),
        (SELECT MAX(c) FROM (SELECT COUNT(*) AS c FROM [Operations].[ChargingSession]
         WHERE CAST(StartTime AS DATE) = @Yesterday GROUP BY DATEPART(HOUR, StartTime)) t),
        (SELECT COUNT(DISTINCT UserID) FROM [Operations].[ChargingSession] WHERE CAST(StartTime AS DATE) = @Yesterday),
        (SELECT COUNT(*) FROM [Infrastructure].[ErrorLog] WHERE CAST(OccurredAt AS DATE) = @Yesterday),
        (SELECT COUNT(*) FROM [Infrastructure].[ErrorLog] WHERE CAST(ResolvedAt AS DATE) = @Yesterday),
        (SELECT COUNT(*) FROM [Operations].[MaintenanceSchedule] WHERE CAST(CreatedAt AS DATE) = @Yesterday),
        (SELECT COUNT(*) FROM [Operations].[MaintenanceSchedule] WHERE CAST(CompletedAt AS DATE) = @Yesterday);

    PRINT N'Daily KPI snapshot recorded.';
END;
GO

PRINT N'Event persistence and KPI snapshot system initialized.';
GO
