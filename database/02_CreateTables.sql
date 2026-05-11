USE EV_Charging_System;
GO

-- ============================================================
-- SCHEMA: Infrastructure
-- ============================================================

CREATE TABLE Infrastructure.Country
(
    CountryID    INT IDENTITY(1,1) NOT NULL,
    CountryCode  NCHAR(2) NOT NULL,
    CountryName  NVARCHAR(100) NOT NULL,
    CurrencyCode NCHAR(3) NOT NULL,
    PhonePrefix  NVARCHAR(5) NULL,
    IsActive     BIT NOT NULL DEFAULT 1,

    CONSTRAINT PK_Country PRIMARY KEY (CountryID),
    CONSTRAINT UQ_Country_Code UNIQUE (CountryCode),
    CONSTRAINT UQ_Country_Name UNIQUE (CountryName),
    CONSTRAINT CK_Country_Code CHECK (CountryCode LIKE '[A-Z][A-Z]'),
    CONSTRAINT CK_Country_Currency CHECK (CurrencyCode LIKE '[A-Z][A-Z][A-Z]')
);
GO

CREATE TABLE Infrastructure.Region
(
    RegionID   INT IDENTITY(1,1) NOT NULL,
    CountryID  INT NOT NULL,
    RegionCode NVARCHAR(10) NOT NULL,
    RegionName NVARCHAR(100) NOT NULL,
    TimeZone   NVARCHAR(50) NULL,
    IsActive   BIT NOT NULL DEFAULT 1,

    CONSTRAINT PK_Region PRIMARY KEY (RegionID),
    CONSTRAINT UQ_Region_Country_Code UNIQUE (CountryID, RegionCode),
    CONSTRAINT FK_Region_Country FOREIGN KEY (CountryID)
        REFERENCES Infrastructure.Country(CountryID)
);
GO

CREATE TABLE Infrastructure.Address
(
    AddressID     INT IDENTITY(1,1) NOT NULL,
    RegionID      INT NOT NULL,
    StreetAddress NVARCHAR(255) NOT NULL,
    Ward          NVARCHAR(100) NULL,
    District      NVARCHAR(100) NULL,
    PostalCode    NVARCHAR(20) NULL,
    Latitude      DECIMAL(10,7) NULL,
    Longitude     DECIMAL(10,7) NULL,
    FullAddress   AS (COALESCE(StreetAddress + N', ', N'')
                      + COALESCE(Ward + N', ', N'')
                      + COALESCE(District + N', ', N'')),
    IsActive      BIT NOT NULL DEFAULT 1,
    CreatedAt     DATETIME2 NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT PK_Address PRIMARY KEY (AddressID),
    CONSTRAINT FK_Address_Region FOREIGN KEY (RegionID)
        REFERENCES Infrastructure.Region(RegionID),
    CONSTRAINT CK_Address_Lat CHECK (Latitude BETWEEN -90 AND 90),
    CONSTRAINT CK_Address_Lng CHECK (Longitude BETWEEN -180 AND 180)
);
GO

CREATE TABLE Infrastructure.Franchise
(
    FranchiseID        INT IDENTITY(1,1) NOT NULL,
    FranchiseCode      NVARCHAR(20) NOT NULL,
    FranchiseName      NVARCHAR(200) NOT NULL,
    TaxCode            NVARCHAR(20) NOT NULL,
    AddressID          INT NULL,
    ContactPerson      NVARCHAR(100) NULL,
    ContactPhone       NVARCHAR(20) NULL,
    ContactEmail       NVARCHAR(100) NULL,
    RevenueShareRate   DECIMAL(5,2) NOT NULL,
    ContractSignedDate DATE NOT NULL,
    IsActive           BIT NOT NULL DEFAULT 1,
    CreatedAt          DATETIME2 NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT PK_Franchise PRIMARY KEY (FranchiseID),
    CONSTRAINT UQ_Franchise_Code UNIQUE (FranchiseCode),
    CONSTRAINT UQ_Franchise_Tax UNIQUE (TaxCode),
    CONSTRAINT FK_Franchise_Address FOREIGN KEY (AddressID)
        REFERENCES Infrastructure.Address(AddressID),
    CONSTRAINT CK_Franchise_Revenue CHECK (RevenueShareRate BETWEEN 0 AND 100)
);
GO

-- ============================================================
-- ElectricitySupplier (NEW)
-- ============================================================
CREATE TABLE Infrastructure.ElectricitySupplier
(
    SupplierID       INT IDENTITY(1,1) NOT NULL,
    SupplierCode     NVARCHAR(20) NOT NULL,
    SupplierName     NVARCHAR(200) NOT NULL,
    RegionID         INT NOT NULL,
    UnitPricePerKWh  DECIMAL(19,4) NOT NULL,
    ContactPerson    NVARCHAR(100) NULL,
    ContactPhone     NVARCHAR(20) NULL,
    ContactEmail     NVARCHAR(100) NULL,
    ContractSignedDate DATE NULL,
    IsActive         BIT NOT NULL DEFAULT 1,
    CreatedAt        DATETIME2 NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT PK_ElectricitySupplier PRIMARY KEY (SupplierID),
    CONSTRAINT UQ_ElectricitySupplier_Code UNIQUE (SupplierCode),
    CONSTRAINT FK_ElectricitySupplier_Region FOREIGN KEY (RegionID)
        REFERENCES Infrastructure.Region(RegionID),
    CONSTRAINT CK_ElectricitySupplier_Price CHECK (UnitPricePerKWh >= 0)
);
GO

CREATE TABLE Infrastructure.ChargingStation
(
    StationID       INT IDENTITY(1,1) NOT NULL,
    StationCode     NVARCHAR(20) NOT NULL,
    StationName     NVARCHAR(200) NOT NULL,
    FranchiseID     INT NOT NULL,
    AddressID       INT NOT NULL,
    SupplierID      INT NULL,                          -- NEW: FK to ElectricitySupplier
    ModelName       NVARCHAR(100) NULL,
    Manufacturer    NVARCHAR(100) NULL,
    MaxPowerKW      DECIMAL(7,2) NULL,
    ConnectorTypes  NVARCHAR(255) NULL,
    Latitude        DECIMAL(10,7) NULL,
    Longitude       DECIMAL(10,7) NULL,
    StationStatus   NVARCHAR(20) NOT NULL DEFAULT N'Active',
    ImageUrl        NVARCHAR(500) NULL,
    Notes           NVARCHAR(1000) NULL,
    IsActive        BIT NOT NULL DEFAULT 1,
    CreatedAt       DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt       DATETIME2 NULL,

    CONSTRAINT PK_ChargingStation PRIMARY KEY (StationID),
    CONSTRAINT UQ_ChargingStation_Code UNIQUE (StationCode),
    CONSTRAINT FK_ChargingStation_Franchise FOREIGN KEY (FranchiseID)
        REFERENCES Infrastructure.Franchise(FranchiseID),
    CONSTRAINT FK_ChargingStation_Address FOREIGN KEY (AddressID)
        REFERENCES Infrastructure.Address(AddressID),
    CONSTRAINT FK_ChargingStation_Supplier FOREIGN KEY (SupplierID)   -- NEW
        REFERENCES Infrastructure.ElectricitySupplier(SupplierID),
    CONSTRAINT CK_ChargingStation_Lat CHECK (Latitude BETWEEN -90 AND 90),
    CONSTRAINT CK_ChargingStation_Lng CHECK (Longitude BETWEEN -180 AND 180),
    CONSTRAINT CK_ChargingStation_Status CHECK (StationStatus IN (N'Active', N'Inactive', N'UnderMaintenance', N'Retired'))
);
GO

CREATE TABLE Infrastructure.ChargingPoint
(
    PointID       INT IDENTITY(1,1) NOT NULL,
    PointCode     NVARCHAR(30) NOT NULL,
    StationID     INT NOT NULL,
    ConnectorType NVARCHAR(30) NOT NULL,
    PowerKW       DECIMAL(7,2) NOT NULL,
    SerialNumber  NVARCHAR(100) NULL,
    PointStatus   NVARCHAR(20) NOT NULL DEFAULT N'Available',
    IsActive      BIT NOT NULL DEFAULT 1,
    CreatedAt     DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt     DATETIME2 NULL,

    CONSTRAINT PK_ChargingPoint PRIMARY KEY (PointID),
    CONSTRAINT UQ_ChargingPoint_Code UNIQUE (PointCode),
    CONSTRAINT UQ_ChargingPoint_Serial UNIQUE (SerialNumber),
    CONSTRAINT FK_ChargingPoint_Station FOREIGN KEY (StationID)
        REFERENCES Infrastructure.ChargingStation(StationID),
    CONSTRAINT CK_ChargingPoint_Power CHECK (PowerKW > 0),
    CONSTRAINT CK_ChargingPoint_Status CHECK (PointStatus IN (N'Available', N'Busy', N'Error', N'Offline', N'Maintenance'))
);
GO

-- ============================================================
-- PointStatusLog (moved from trigger file)
-- ============================================================
CREATE TABLE Infrastructure.PointStatusLog
(
    LogID      BIGINT IDENTITY(1,1) NOT NULL,
    PointID    INT NOT NULL,
    OldStatus  NVARCHAR(20) NOT NULL,
    NewStatus  NVARCHAR(20) NOT NULL,
    ChangedAt  DATETIME2 NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT PK_PointStatusLog PRIMARY KEY (LogID),
    CONSTRAINT FK_PointStatusLog_Point FOREIGN KEY (PointID)
        REFERENCES Infrastructure.ChargingPoint(PointID)
);
GO

PRINT N'Infrastructure tables created.';
GO

-- ============================================================
-- SCHEMA: Users
-- ============================================================

CREATE TABLE Users.[User]
(
    UserID              INT IDENTITY(1,1) NOT NULL,
    Username            NVARCHAR(50) NOT NULL,
    Email               NVARCHAR(100) NOT NULL,
    Phone               NVARCHAR(20) NULL,
    PasswordHash        NVARCHAR(256) NOT NULL,
    FullName            NVARCHAR(100) NOT NULL,
    AvatarUrl           NVARCHAR(500) NULL,
    Role                NVARCHAR(10) NOT NULL,
    FranchiseID         INT NULL,
    AccountStatus       NVARCHAR(10) NOT NULL DEFAULT N'Active',
    FailedLoginAttempts INT NOT NULL DEFAULT 0,
    LockoutEnd          DATETIME2 NULL,
    LastLoginAt         DATETIME2 NULL,
    CreatedAt           DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt           DATETIME2 NULL,

    CONSTRAINT PK_User PRIMARY KEY (UserID),
    CONSTRAINT UQ_User_Username UNIQUE (Username),
    CONSTRAINT UQ_User_Email UNIQUE (Email),
    CONSTRAINT UQ_User_Phone UNIQUE (Phone),
    CONSTRAINT FK_User_Franchise FOREIGN KEY (FranchiseID)
        REFERENCES Infrastructure.Franchise(FranchiseID),
    CONSTRAINT CK_User_Role CHECK (Role IN ('Customer', 'Manager', 'Admin')),
    CONSTRAINT CK_User_Status CHECK (AccountStatus IN ('Pending', 'Active', 'Suspended', 'Locked'))
);
GO

CREATE TABLE Users.Vehicle
(
    VehicleID          INT IDENTITY(1,1) NOT NULL,
    UserID             INT NOT NULL,
    PlateNumber        NVARCHAR(20) NOT NULL,
    Brand              NVARCHAR(50) NULL,
    Model              NVARCHAR(100) NULL,
    ModelYear          INT NULL,
    BatteryCapacityKWh DECIMAL(5,2) NULL,
    ConnectorType      NVARCHAR(30) NULL,
    IsActive           BIT NOT NULL DEFAULT 1,
    CreatedAt          DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt          DATETIME2 NULL,

    CONSTRAINT PK_Vehicle PRIMARY KEY (VehicleID),
    CONSTRAINT UQ_Vehicle_Plate UNIQUE (PlateNumber),
    CONSTRAINT FK_Vehicle_User FOREIGN KEY (UserID)
        REFERENCES Users.[User](UserID),
    CONSTRAINT CK_Vehicle_Year CHECK (ModelYear IS NULL OR ModelYear >= 2000)
);
GO

-- ============================================================
-- Notification (NEW)
-- ============================================================
CREATE TABLE Users.Notification
(
    NotificationID  INT IDENTITY(1,1) NOT NULL,
    UserID          INT NOT NULL,
    Title           NVARCHAR(200) NOT NULL,
    Body            NVARCHAR(1000) NOT NULL,
    Type            NVARCHAR(30) NOT NULL,
    ReferenceType   NVARCHAR(30) NULL,
    ReferenceID     BIGINT NULL,
    IsRead          BIT NOT NULL DEFAULT 0,
    CreatedAt       DATETIME2 NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT PK_Notification PRIMARY KEY (NotificationID),
    CONSTRAINT FK_Notification_User FOREIGN KEY (UserID)
        REFERENCES Users.[User](UserID),
    CONSTRAINT CK_Notification_Type CHECK (Type IN (N'ChargingComplete', N'Payment', N'Promotion', N'System', N'Maintenance', N'Booking', N'WalletAlert'))
);
GO

-- ============================================================
-- ErrorLog (NEW - references Users.User, so placed here)
-- ============================================================
CREATE TABLE Infrastructure.ErrorLog
(
    ErrorID         INT IDENTITY(1,1) NOT NULL,
    PointID         INT NULL,
    StationID       INT NULL,
    ErrorCode       NVARCHAR(30) NOT NULL,
    Severity        NVARCHAR(10) NOT NULL DEFAULT N'Medium',
    Description     NVARCHAR(500) NOT NULL,
    OccurredAt      DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    ResolvedAt      DATETIME2 NULL,
    ResolvedBy      INT NULL,
    ResolutionNotes NVARCHAR(500) NULL,
    IsActive        BIT NOT NULL DEFAULT 1,

    CONSTRAINT PK_ErrorLog PRIMARY KEY (ErrorID),
    CONSTRAINT FK_ErrorLog_Point FOREIGN KEY (PointID)
        REFERENCES Infrastructure.ChargingPoint(PointID),
    CONSTRAINT FK_ErrorLog_Station FOREIGN KEY (StationID)
        REFERENCES Infrastructure.ChargingStation(StationID),
    CONSTRAINT FK_ErrorLog_ResolvedBy FOREIGN KEY (ResolvedBy)
        REFERENCES Users.[User](UserID),
    CONSTRAINT CK_ErrorLog_Severity CHECK (Severity IN (N'Low', N'Medium', N'High', N'Critical'))
);
GO

PRINT N'Users tables created.';
GO

-- ============================================================
-- SCHEMA: Operations
-- ============================================================

CREATE TABLE Operations.PricingPolicy
(
    PolicyID        INT IDENTITY(1,1) NOT NULL,
    PolicyCode      NVARCHAR(20) NOT NULL,
    PolicyName      NVARCHAR(200) NOT NULL,
    BasePricePerKWh DECIMAL(19,4) NOT NULL,
    CurrencyCode    NCHAR(3) NOT NULL DEFAULT N'VND',
    PeakMultiplier  DECIMAL(3,2) NOT NULL DEFAULT 1.50,
    PeakStartHour   TIME(0) NULL,
    PeakEndHour     TIME(0) NULL,
    IsWeekendPeak   BIT NOT NULL DEFAULT 0,
    AppliedFrom     DATETIME2 NOT NULL,
    AppliedTo       DATETIME2 NULL,
    IsActive        BIT NOT NULL DEFAULT 1,
    CreatedAt       DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt       DATETIME2 NULL,

    CONSTRAINT PK_PricingPolicy PRIMARY KEY (PolicyID),
    CONSTRAINT UQ_PricingPolicy_Code UNIQUE (PolicyCode),
    CONSTRAINT CK_PricingPolicy_Price CHECK (BasePricePerKWh >= 0),
    CONSTRAINT CK_PricingPolicy_Peak CHECK (PeakMultiplier >= 1.0),
    CONSTRAINT CK_PricingPolicy_Dates CHECK (AppliedTo IS NULL OR AppliedFrom < AppliedTo)
);
GO

-- ============================================================
-- Booking (NEW)
-- ============================================================
CREATE TABLE Operations.Booking
(
    BookingID   INT IDENTITY(1,1) NOT NULL,
    BookingCode NVARCHAR(30) NOT NULL,
    UserID      INT NOT NULL,
    PointID     INT NOT NULL,
    StationID   INT NOT NULL,
    VehicleID   INT NULL,
    BookedFrom  DATETIME2 NOT NULL,
    BookedTo    DATETIME2 NOT NULL,
    Status      NVARCHAR(20) NOT NULL DEFAULT N'Pending',
    CreatedAt   DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt   DATETIME2 NULL,

    CONSTRAINT PK_Booking PRIMARY KEY (BookingID),
    CONSTRAINT UQ_Booking_Code UNIQUE (BookingCode),
    CONSTRAINT FK_Booking_User FOREIGN KEY (UserID)
        REFERENCES Users.[User](UserID),
    CONSTRAINT FK_Booking_Point FOREIGN KEY (PointID)
        REFERENCES Infrastructure.ChargingPoint(PointID),
    CONSTRAINT FK_Booking_Station FOREIGN KEY (StationID)
        REFERENCES Infrastructure.ChargingStation(StationID),
    CONSTRAINT FK_Booking_Vehicle FOREIGN KEY (VehicleID)
        REFERENCES Users.Vehicle(VehicleID),
    CONSTRAINT CK_Booking_Time CHECK (BookedFrom < BookedTo),
    CONSTRAINT CK_Booking_Status CHECK (Status IN (N'Pending', N'Confirmed', N'Active', N'Completed', N'Cancelled', N'Expired'))
);
GO

CREATE TABLE Operations.ChargingSession
(
    SessionID                BIGINT IDENTITY(1,1) NOT NULL,
    SessionCode              NVARCHAR(30) NOT NULL,
    UserID                   INT NOT NULL,
    VehicleID                INT NULL,
    PointID                  INT NOT NULL,
    StationID                INT NOT NULL,
    PolicyID                 INT NOT NULL,
    BookingID                INT NULL,                          -- NEW: FK to Booking
    StartTime                DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    EndTime                  DATETIME2 NULL,
    StartBatteryPercent      DECIMAL(5,2) NULL,
    EndBatteryPercent        DECIMAL(5,2) NULL,
    MeterStart               DECIMAL(13,4) NULL,
    MeterEnd                 DECIMAL(13,4) NULL,
    TotalKWh                 DECIMAL(13,4) NULL,
    ChargingDurationMinutes  INT NULL,
    CostTotal                MONEY NULL,
    CurrencyCode             NCHAR(3) NOT NULL DEFAULT N'VND',
    StopReason               NVARCHAR(50) NULL,
    SessionStatus            NVARCHAR(20) NOT NULL DEFAULT N'Charging',
    CreatedAt                DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt                DATETIME2 NULL,

    CONSTRAINT PK_ChargingSession PRIMARY KEY (SessionID),
    CONSTRAINT UQ_ChargingSession_Code UNIQUE (SessionCode),
    CONSTRAINT FK_ChargingSession_User FOREIGN KEY (UserID)
        REFERENCES Users.[User](UserID),
    CONSTRAINT FK_ChargingSession_Vehicle FOREIGN KEY (VehicleID)
        REFERENCES Users.Vehicle(VehicleID),
    CONSTRAINT FK_ChargingSession_Point FOREIGN KEY (PointID)
        REFERENCES Infrastructure.ChargingPoint(PointID),
    CONSTRAINT FK_ChargingSession_Station FOREIGN KEY (StationID)
        REFERENCES Infrastructure.ChargingStation(StationID),
    CONSTRAINT FK_ChargingSession_Policy FOREIGN KEY (PolicyID)
        REFERENCES Operations.PricingPolicy(PolicyID),
    CONSTRAINT FK_ChargingSession_Booking FOREIGN KEY (BookingID)   -- NEW
        REFERENCES Operations.Booking(BookingID),
    CONSTRAINT CK_ChargingSession_KWh CHECK (TotalKWh IS NULL OR TotalKWh >= 0),
    CONSTRAINT CK_ChargingSession_Time CHECK (EndTime IS NULL OR StartTime < EndTime),
    CONSTRAINT CK_ChargingSession_Status CHECK (SessionStatus IN ('Charging', 'Completed', 'Cancelled', 'Failed', 'Pending')),
    CONSTRAINT CK_ChargingSession_StopReason CHECK (StopReason IS NULL OR StopReason IN ('Completed', 'UserStopped', 'PaymentFailed', 'Error', 'Timeout', 'EmergencyStop', 'Maintenance', 'CancelledByUser', 'Other'))
);
GO

-- ============================================================
-- MaintenanceSchedule (NEW)
-- ============================================================
CREATE TABLE Operations.MaintenanceSchedule
(
    ScheduleID      INT IDENTITY(1,1) NOT NULL,
    PointID         INT NULL,
    StationID       INT NULL,
    ScheduledBy     INT NOT NULL,
    ScheduledFrom   DATETIME2 NOT NULL,
    ScheduledTo     DATETIME2 NOT NULL,
    MaintenanceType NVARCHAR(50) NOT NULL,
    Description     NVARCHAR(500) NULL,
    Status          NVARCHAR(20) NOT NULL DEFAULT N'Scheduled',
    CompletedAt     DATETIME2 NULL,
    Notes           NVARCHAR(1000) NULL,
    CreatedAt       DATETIME2 NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT PK_MaintenanceSchedule PRIMARY KEY (ScheduleID),
    CONSTRAINT FK_MaintenanceSchedule_Point FOREIGN KEY (PointID)
        REFERENCES Infrastructure.ChargingPoint(PointID),
    CONSTRAINT FK_MaintenanceSchedule_Station FOREIGN KEY (StationID)
        REFERENCES Infrastructure.ChargingStation(StationID),
    CONSTRAINT FK_MaintenanceSchedule_User FOREIGN KEY (ScheduledBy)
        REFERENCES Users.[User](UserID),
    CONSTRAINT CK_MaintenanceSchedule_Time CHECK (ScheduledFrom < ScheduledTo),
    CONSTRAINT CK_MaintenanceSchedule_Type CHECK (MaintenanceType IN (N'Preventive', N'Corrective', N'Inspection', N'Upgrade')),
    CONSTRAINT CK_MaintenanceSchedule_Status CHECK (Status IN (N'Scheduled', N'InProgress', N'Completed', N'Cancelled'))
);
GO

-- ============================================================
-- StationReview (NEW)
-- ============================================================
CREATE TABLE Operations.StationReview
(
    ReviewID   INT IDENTITY(1,1) NOT NULL,
    UserID     INT NOT NULL,
    StationID  INT NOT NULL,
    Rating     INT NOT NULL,
    Comment    NVARCHAR(1000) NULL,
    CreatedAt  DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt  DATETIME2 NULL,

    CONSTRAINT PK_StationReview PRIMARY KEY (ReviewID),
    CONSTRAINT FK_StationReview_User FOREIGN KEY (UserID)
        REFERENCES Users.[User](UserID),
    CONSTRAINT FK_StationReview_Station FOREIGN KEY (StationID)
        REFERENCES Infrastructure.ChargingStation(StationID),
    CONSTRAINT UQ_StationReview_User_Station UNIQUE (UserID, StationID),
    CONSTRAINT CK_StationReview_Rating CHECK (Rating BETWEEN 1 AND 5)
);
GO

PRINT N'Operations tables created.';
GO

-- ============================================================
-- SCHEMA: Payments
-- ============================================================

CREATE TABLE Payments.Wallet
(
    WalletID           INT IDENTITY(1,1) NOT NULL,
    UserID             INT NOT NULL,
    WalletCode         NVARCHAR(30) NOT NULL,
    Balance            MONEY NOT NULL DEFAULT 0,
    CurrencyCode       NCHAR(3) NOT NULL DEFAULT N'VND',
    IsActive           BIT NOT NULL DEFAULT 1,
    LastTransactionAt  DATETIME2 NULL,
    CreatedAt          DATETIME2 NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT PK_Wallet PRIMARY KEY (WalletID),
    CONSTRAINT UQ_Wallet_Code UNIQUE (WalletCode),
    CONSTRAINT UQ_Wallet_User UNIQUE (UserID),
    CONSTRAINT FK_Wallet_User FOREIGN KEY (UserID)
        REFERENCES Users.[User](UserID),
    CONSTRAINT CK_Wallet_Balance CHECK (Balance >= 0)
);
GO

CREATE TABLE Payments.[Transaction]
(
    TransactionID     BIGINT IDENTITY(1,1) NOT NULL,
    TransactionCode   NVARCHAR(30) NOT NULL,
    UserID            INT NOT NULL,
    SessionID         BIGINT NULL,
    TransactionType   NVARCHAR(30) NOT NULL,
    Direction         NCHAR(1) NOT NULL DEFAULT N'D',
    Amount            MONEY NOT NULL,
    CurrencyCode      NCHAR(3) NOT NULL DEFAULT N'VND',
    TransactionStatus NVARCHAR(20) NOT NULL DEFAULT N'Pending',
    PaymentMethod     NVARCHAR(30) NULL,
    Description       NVARCHAR(500) NULL,
    TransactedAt      DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    SettledAt         DATETIME2 NULL,
    CreatedAt         DATETIME2 NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT PK_Transaction PRIMARY KEY (TransactionID),
    CONSTRAINT UQ_Transaction_Code UNIQUE (TransactionCode),
    CONSTRAINT FK_Transaction_User FOREIGN KEY (UserID)
        REFERENCES Users.[User](UserID),
    CONSTRAINT FK_Transaction_Session FOREIGN KEY (SessionID)
        REFERENCES Operations.ChargingSession(SessionID),
    CONSTRAINT CK_Transaction_Amount CHECK (Amount >= 0),
    CONSTRAINT CK_Transaction_Direction CHECK (Direction IN ('D', 'C')),
    CONSTRAINT CK_Transaction_Type CHECK (TransactionType IN ('ChargingPayment', 'WalletTopUp', 'Refund')),
    CONSTRAINT CK_Transaction_Status CHECK (TransactionStatus IN ('Pending', 'Completed', 'Failed', 'Refunded', 'Cancelled'))
);
GO

CREATE TABLE Payments.WalletTransaction
(
    WalletTransactionID INT IDENTITY(1,1) NOT NULL,
    WalletID            INT NOT NULL,
    TransactionID       BIGINT NULL,
    Amount              MONEY NOT NULL,
    BalanceBefore       MONEY NOT NULL,
    BalanceAfter        AS (BalanceBefore + Amount),
    Direction           NCHAR(1) NOT NULL,
    TransactionType     NVARCHAR(30) NOT NULL,
    Description         NVARCHAR(500) NULL,
    CreatedAt           DATETIME2 NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT PK_WalletTransaction PRIMARY KEY (WalletTransactionID),
    CONSTRAINT FK_WalletTransaction_Wallet FOREIGN KEY (WalletID)
        REFERENCES Payments.Wallet(WalletID),
    CONSTRAINT FK_WalletTransaction_Transaction FOREIGN KEY (TransactionID)
        REFERENCES Payments.[Transaction](TransactionID),
    CONSTRAINT CK_WalletTxn_Direction CHECK (Direction IN ('D', 'C')),
    CONSTRAINT CK_WalletTxn_Type CHECK (TransactionType IN ('ChargingPayment', 'WalletTopUp', 'Refund'))
);
GO

PRINT N'Payments tables created.';
GO

-- ============================================================
-- ErrorCatalog (for centralized error handling)
-- ============================================================
CREATE TABLE Infrastructure.ErrorCatalog
(
    ErrorCode    INT NOT NULL,
    ErrorMessage NVARCHAR(500) NOT NULL,
    Severity     NVARCHAR(10) NOT NULL DEFAULT N'Error',

    CONSTRAINT PK_ErrorCatalog PRIMARY KEY (ErrorCode),
    CONSTRAINT CK_ErrorCatalog_Severity CHECK (Severity IN (N'Info', N'Warning', N'Error', N'Critical'))
);
GO

-- Seed ErrorCatalog
INSERT INTO Infrastructure.ErrorCatalog (ErrorCode, ErrorMessage, Severity) VALUES
    -- ChargingPoint errors (50001-50009)
    (50001, N'Charging point not found', 'Error'),
    (50002, N'Charging point is not available', 'Error'),
    (50003, N'User account is not active', 'Error'),
    (50004, N'Station is not active', 'Error'),
    (50005, N'No active pricing policy', 'Error'),
    -- Session errors (50010-50019)
    (50010, N'Session not found', 'Error'),
    (50011, N'Session is not in Charging status', 'Error'),
    (50012, N'Cannot cancel session in current status', 'Error'),
    -- Payment errors (50020-50029)
    (50020, N'Session not found', 'Error'),
    (50021, N'Session must be completed before payment', 'Error'),
    (50022, N'Session does not belong to user', 'Error'),
    (50023, N'Invalid payment amount', 'Error'),
    (50024, N'Payment already completed for this session', 'Error'),
    (50025, N'No active wallet found', 'Error'),
    (50026, N'Insufficient wallet balance', 'Error'),
    -- Booking errors (50030-50039)
    (50030, N'Time slot is not available', 'Error'),
    (50031, N'Booking not found', 'Error'),
    (50032, N'Booking cannot be modified in current status', 'Error'),
    (50033, N'Booking is already confirmed', 'Error'),
    -- Maintenance errors (50040-50049)
    (50040, N'Maintenance schedule overlaps with active booking', 'Error'),
    (50041, N'Maintenance schedule not found', 'Error'),
    (50042, N'Maintenance schedule cannot be modified in current status', 'Error'),
    -- Validation errors (50050-50059)
    (50050, N'Invalid input data', 'Error'),
    (50051, N'Duplicate entry', 'Error');
GO

PRINT N'ErrorCatalog seeded.';
GO

-- ============================================================
-- INDEXES
-- ============================================================

-- Existing indexes (unchanged)
CREATE NONCLUSTERED INDEX IX_Region_CountryID ON Infrastructure.Region(CountryID);
CREATE NONCLUSTERED INDEX IX_Address_RegionID ON Infrastructure.Address(RegionID);
CREATE NONCLUSTERED INDEX IX_Franchise_AddressID ON Infrastructure.Franchise(AddressID);
CREATE NONCLUSTERED INDEX IX_ChargingStation_FranchiseID ON Infrastructure.ChargingStation(FranchiseID);
CREATE NONCLUSTERED INDEX IX_ChargingStation_AddressID ON Infrastructure.ChargingStation(AddressID);
CREATE NONCLUSTERED INDEX IX_ChargingPoint_StationID ON Infrastructure.ChargingPoint(StationID);
CREATE NONCLUSTERED INDEX IX_ChargingPoint_Status ON Infrastructure.ChargingPoint(PointStatus) WHERE IsActive = 1;

CREATE NONCLUSTERED INDEX IX_User_FranchiseID ON Users.[User](FranchiseID);
CREATE NONCLUSTERED INDEX IX_User_Role ON Users.[User](Role);
CREATE NONCLUSTERED INDEX IX_User_Email ON Users.[User](Email);
CREATE NONCLUSTERED INDEX IX_Vehicle_UserID ON Users.Vehicle(UserID);

CREATE NONCLUSTERED INDEX IX_ChargingSession_UserID ON Operations.ChargingSession(UserID);
CREATE NONCLUSTERED INDEX IX_ChargingSession_StationID ON Operations.ChargingSession(StationID);
CREATE NONCLUSTERED INDEX IX_ChargingSession_PointID ON Operations.ChargingSession(PointID);
CREATE NONCLUSTERED INDEX IX_ChargingSession_Status ON Operations.ChargingSession(SessionStatus);
CREATE NONCLUSTERED INDEX IX_ChargingSession_StartTime ON Operations.ChargingSession(StartTime DESC);

CREATE NONCLUSTERED INDEX IX_Wallet_UserID ON Payments.Wallet(UserID);
CREATE NONCLUSTERED INDEX IX_Transaction_UserID ON Payments.[Transaction](UserID);
CREATE NONCLUSTERED INDEX IX_Transaction_SessionID ON Payments.[Transaction](SessionID);
CREATE NONCLUSTERED INDEX IX_Transaction_Status ON Payments.[Transaction](TransactionStatus);
CREATE NONCLUSTERED INDEX IX_WalletTransaction_WalletID ON Payments.WalletTransaction(WalletID);

-- New indexes
-- ElectricitySupplier
CREATE NONCLUSTERED INDEX IX_ElectricitySupplier_Region ON Infrastructure.ElectricitySupplier(RegionID);

-- ErrorLog
CREATE NONCLUSTERED INDEX IX_ErrorLog_PointID ON Infrastructure.ErrorLog(PointID);
CREATE NONCLUSTERED INDEX IX_ErrorLog_StationID ON Infrastructure.ErrorLog(StationID);
CREATE NONCLUSTERED INDEX IX_ErrorLog_Severity ON Infrastructure.ErrorLog(Severity) WHERE IsActive = 1;

-- PointStatusLog
CREATE NONCLUSTERED INDEX IX_PointStatusLog_PointID ON Infrastructure.PointStatusLog(PointID);
CREATE NONCLUSTERED INDEX IX_PointStatusLog_ChangedAt ON Infrastructure.PointStatusLog(ChangedAt DESC);

-- Booking
CREATE NONCLUSTERED INDEX IX_Booking_UserID ON Operations.Booking(UserID);
CREATE NONCLUSTERED INDEX IX_Booking_PointID ON Operations.Booking(PointID);
CREATE NONCLUSTERED INDEX IX_Booking_Status ON Operations.Booking(Status);
CREATE NONCLUSTERED INDEX IX_Booking_TimeRange ON Operations.Booking(PointID, BookedFrom, BookedTo) WHERE Status IN (N'Pending', N'Confirmed', N'Active');

-- MaintenanceSchedule
CREATE NONCLUSTERED INDEX IX_Maintenance_PointID ON Operations.MaintenanceSchedule(PointID);
CREATE NONCLUSTERED INDEX IX_Maintenance_StationID ON Operations.MaintenanceSchedule(StationID);
CREATE NONCLUSTERED INDEX IX_Maintenance_Status ON Operations.MaintenanceSchedule(Status);
CREATE NONCLUSTERED INDEX IX_Maintenance_TimeRange ON Operations.MaintenanceSchedule(ScheduledFrom, ScheduledTo);

-- Notification
CREATE NONCLUSTERED INDEX IX_Notification_User_Unread ON Users.Notification(UserID, IsRead) INCLUDE (CreatedAt);
CREATE NONCLUSTERED INDEX IX_Notification_CreatedAt ON Users.Notification(CreatedAt DESC);

-- StationReview
CREATE UNIQUE NONCLUSTERED INDEX UQ_Review_User_Station ON Operations.StationReview(UserID, StationID);

-- ChargingStation_Supplier
CREATE NONCLUSTERED INDEX IX_ChargingStation_SupplierID ON Infrastructure.ChargingStation(SupplierID);

-- ChargingSession_Booking
CREATE NONCLUSTERED INDEX IX_ChargingSession_BookingID ON Operations.ChargingSession(BookingID);

PRINT N'All indexes created.';
GO
