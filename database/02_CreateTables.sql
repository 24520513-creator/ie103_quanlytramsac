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

CREATE TABLE Infrastructure.ChargingStation
(
    StationID       INT IDENTITY(1,1) NOT NULL,
    StationCode     NVARCHAR(20) NOT NULL,
    StationName     NVARCHAR(200) NOT NULL,
    FranchiseID     INT NOT NULL,
    AddressID       INT NOT NULL,
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

CREATE TABLE Operations.ChargingSession
(
    SessionID                BIGINT IDENTITY(1,1) NOT NULL,
    SessionCode              NVARCHAR(30) NOT NULL,
    UserID                   INT NOT NULL,
    VehicleID                INT NULL,
    PointID                  INT NOT NULL,
    StationID                INT NOT NULL,
    PolicyID                 INT NOT NULL,
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
    CONSTRAINT CK_ChargingSession_KWh CHECK (TotalKWh IS NULL OR TotalKWh >= 0),
    CONSTRAINT CK_ChargingSession_Time CHECK (EndTime IS NULL OR StartTime < EndTime),
    CONSTRAINT CK_ChargingSession_Status CHECK (SessionStatus IN ('Charging', 'Completed', 'Cancelled', 'Failed', 'Pending')),
    CONSTRAINT CK_ChargingSession_StopReason CHECK (StopReason IS NULL OR StopReason IN ('Completed', 'UserStopped', 'PaymentFailed', 'Error', 'Timeout', 'EmergencyStop', 'Maintenance', 'Other'))
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
-- INDEXES
-- ============================================================

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

PRINT N'Indexes created.';
GO
