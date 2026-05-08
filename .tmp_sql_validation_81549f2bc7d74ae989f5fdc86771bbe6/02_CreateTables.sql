/*==============================================================================
  EV_Charging_System_Validation - ENTERPRISE TABLE DEFINITIONS
  ==============================================================================
  Schemas:   Infrastructure | Access | Users | Operations | Payments
            | Monitoring | Audit | Analytics | Reporting
  Tables:    40+ enterprise tables with full audit, constraints, security
  =============================================================================*/

USE EV_Charging_System_Validation;
GO

-- ===========================================================================
-- SCHEMA: Infrastructure (Physical Assets, Locations, Suppliers)
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- Infrastructure.Country - Lookup table for geographic regions
-- ---------------------------------------------------------------------------
CREATE TABLE Infrastructure.Country
(
    CountryID       INT             IDENTITY(1,1)   NOT NULL,
    CountryCode     NCHAR(2)        NOT NULL,
    CountryName     NVARCHAR(100)   NOT NULL,
    CurrencyCode    NCHAR(3)        NOT NULL,
    PhonePrefix     NVARCHAR(5)     NULL,
    IsActive        BIT             NOT NULL DEFAULT 1,

    CONSTRAINT PK_Country PRIMARY KEY (CountryID),
    CONSTRAINT UQ_Country_CountryCode UNIQUE (CountryCode),
    CONSTRAINT UQ_Country_CountryName UNIQUE (CountryName),
    CONSTRAINT CK_Country_CountryCode CHECK (CountryCode LIKE '[A-Z][A-Z]'),
    CONSTRAINT CK_Country_CurrencyCode CHECK (CurrencyCode LIKE '[A-Z][A-Z][A-Z]')
);
GO

-- ---------------------------------------------------------------------------
-- Infrastructure.Region - Subnational regions (states, provinces, cities)
-- ---------------------------------------------------------------------------
CREATE TABLE Infrastructure.Region
(
    RegionID        INT             IDENTITY(1,1)   NOT NULL,
    CountryID       INT             NOT NULL,
    RegionCode      NVARCHAR(10)    NOT NULL,
    RegionName      NVARCHAR(100)   NOT NULL,
    RegionType      NVARCHAR(20)    NOT NULL,
    [TimeZone]      NVARCHAR(50)    NULL,
    IsActive        BIT             NOT NULL DEFAULT 1,

    CONSTRAINT PK_Region PRIMARY KEY (RegionID),
    CONSTRAINT UQ_Region_CountryID_RegionCode UNIQUE (CountryID, RegionCode),
    CONSTRAINT FK_Region_Country FOREIGN KEY (CountryID)
        REFERENCES Infrastructure.Country (CountryID),
    CONSTRAINT CK_Region_RegionType CHECK (RegionType IN (N'Province', N'State', N'City', N'District'))
);
GO

-- ---------------------------------------------------------------------------
-- Infrastructure.Address - Normalized address entity (reusable)
-- ---------------------------------------------------------------------------
CREATE TABLE Infrastructure.Address
(
    AddressID       INT             IDENTITY(1,1)   NOT NULL,
    RegionID        INT             NOT NULL,
    StreetAddress   NVARCHAR(255)   NOT NULL,
    Ward            NVARCHAR(100)   NULL,
    District        NVARCHAR(100)   NULL,
    PostalCode      NVARCHAR(20)    NULL,
    Latitude        DECIMAL(10,7)   NULL,
    Longitude       DECIMAL(10,7)   NULL,
    FullAddress     AS              (COALESCE(StreetAddress + N', ', N'')
                                     + COALESCE(Ward + N', ', N'')
                                     + COALESCE(District + N', ', N'')),
    IsActive        BIT             NOT NULL DEFAULT 1,
    CreatedAt       DATETIME2       NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt       DATETIME2       NULL,

    CONSTRAINT PK_Address PRIMARY KEY (AddressID),
    CONSTRAINT FK_Address_Region FOREIGN KEY (RegionID)
        REFERENCES Infrastructure.Region (RegionID),
    CONSTRAINT CK_Address_Latitude CHECK (Latitude BETWEEN -90 AND 90),
    CONSTRAINT CK_Address_Longitude CHECK (Longitude BETWEEN -180 AND 180)
);
GO

-- ---------------------------------------------------------------------------
-- Infrastructure.Franchise - Franchise/franchise business entity
-- ---------------------------------------------------------------------------
CREATE TABLE Infrastructure.Franchise
(
    FranchiseID         INT             IDENTITY(1,1)   NOT NULL,
    FranchiseCode       NVARCHAR(20)    NOT NULL,
    FranchiseName       NVARCHAR(200)   NOT NULL,
    TaxCode             NVARCHAR(20)    NOT NULL,
    AddressID           INT             NULL,
    ContactPerson       NVARCHAR(100)   NULL,
    ContactPhone        NVARCHAR(20)    NULL,
    ContactEmail        NVARCHAR(100)   NULL,
    RevenueShareRate    DECIMAL(5,2)    NOT NULL,
    ContractSignedDate  DATE            NOT NULL,
    ContractExpiryDate  DATE            NULL,
    FranchiseTier       NVARCHAR(20)    NOT NULL DEFAULT N'Standard',
    IsActive            BIT             NOT NULL DEFAULT 1,
    IsDeleted           BIT             NOT NULL DEFAULT 0,
    CreatedAt           DATETIME2       NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt           DATETIME2       NULL,
    DeletedAt           DATETIME2       NULL,
    CreatedBy           INT             NULL,
    UpdatedBy           INT             NULL,

    CONSTRAINT PK_Franchise PRIMARY KEY (FranchiseID),
    CONSTRAINT UQ_Franchise_FranchiseCode UNIQUE (FranchiseCode),
    CONSTRAINT UQ_Franchise_TaxCode UNIQUE (TaxCode),
    CONSTRAINT FK_Franchise_Address FOREIGN KEY (AddressID)
        REFERENCES Infrastructure.Address (AddressID),
    CONSTRAINT CK_Franchise_RevenueShareRate CHECK (RevenueShareRate BETWEEN 0 AND 100),
    CONSTRAINT CK_Franchise_FranchiseTier CHECK (FranchiseTier IN (N'Bronze', N'Silver', N'Gold', N'Platinum', N'Standard')),
    CONSTRAINT CK_Franchise_ContractDates CHECK (ContractExpiryDate IS NULL OR ContractSignedDate < ContractExpiryDate)
);
GO

-- ---------------------------------------------------------------------------
-- Infrastructure.ElectricitySupplier - Energy providers
-- ---------------------------------------------------------------------------
CREATE TABLE Infrastructure.ElectricitySupplier
(
    SupplierID          INT             IDENTITY(1,1)   NOT NULL,
    SupplierCode        NVARCHAR(20)    NOT NULL,
    SupplierName        NVARCHAR(200)   NOT NULL,
    CountryID           INT             NOT NULL,
    ContactPhone        NVARCHAR(20)    NULL,
    ContactEmail        NVARCHAR(100)   NULL,
    IsActive            BIT             NOT NULL DEFAULT 1,
    IsDeleted           BIT             NOT NULL DEFAULT 0,
    CreatedAt           DATETIME2       NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt           DATETIME2       NULL,
    DeletedAt           DATETIME2       NULL,

    CONSTRAINT PK_ElectricitySupplier PRIMARY KEY (SupplierID),
    CONSTRAINT UQ_ElectricitySupplier_SupplierCode UNIQUE (SupplierCode),
    CONSTRAINT FK_ElectricitySupplier_Country FOREIGN KEY (CountryID)
        REFERENCES Infrastructure.Country (CountryID)
);
GO

-- ---------------------------------------------------------------------------
-- Infrastructure.StationModel - Charging station make/model catalog
-- ---------------------------------------------------------------------------
CREATE TABLE Infrastructure.StationModel
(
    StationModelID      INT             IDENTITY(1,1)   NOT NULL,
    ModelName           NVARCHAR(100)   NOT NULL,
    Manufacturer        NVARCHAR(100)   NOT NULL,
    MaxPowerKW          DECIMAL(7,2)    NOT NULL,
    ConnectorTypes      NVARCHAR(255)   NULL,
    OcppVersion         NVARCHAR(10)    NULL,
    IsOCPPCompliant     BIT             NOT NULL DEFAULT 1,
    IsActive            BIT             NOT NULL DEFAULT 1,
    CreatedAt           DATETIME2       NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT PK_StationModel PRIMARY KEY (StationModelID),
    CONSTRAINT CK_StationModel_MaxPowerKW CHECK (MaxPowerKW > 0)
);
GO

-- ---------------------------------------------------------------------------
-- Infrastructure.ChargingStation - Core station entity (enhanced)
-- ---------------------------------------------------------------------------
CREATE TABLE Infrastructure.ChargingStation
(
    StationID           INT             IDENTITY(1,1)   NOT NULL,
    StationCode         NVARCHAR(20)    NOT NULL,
    StationName         NVARCHAR(200)   NOT NULL,
    FranchiseID         INT             NOT NULL,
    StationModelID      INT             NULL,
    AddressID           INT             NOT NULL,
    SupplierID          INT             NULL,
    Latitude            DECIMAL(10,7)   NULL,
    Longitude           DECIMAL(10,7)   NULL,
    MaxCapacityKW       DECIMAL(10,2)   NULL,
    OperatingHoursJson  NVARCHAR(500)   NULL,
    InstallationDate    DATE            NULL,
    FirmwareVersion     NVARCHAR(50)    NULL,
    NetworkStatus       NVARCHAR(20)    NOT NULL DEFAULT N'Online',
    StationStatus       NVARCHAR(20)    NOT NULL DEFAULT N'Active',
    HasGenerator        BIT             NOT NULL DEFAULT 0,
    HasSolarPanels      BIT             NOT NULL DEFAULT 0,
    ParkingSpots        INT             NULL,
    ImageUrl            NVARCHAR(500)   NULL,
    Notes               NVARCHAR(1000)  NULL,
    IsDeleted           BIT             NOT NULL DEFAULT 0,
    CreatedAt           DATETIME2       NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt           DATETIME2       NULL,
    DeletedAt           DATETIME2       NULL,
    CreatedBy           INT             NULL,
    UpdatedBy           INT             NULL,

    CONSTRAINT PK_ChargingStation PRIMARY KEY (StationID),
    CONSTRAINT UQ_ChargingStation_StationCode UNIQUE (StationCode),
    CONSTRAINT FK_ChargingStation_Franchise FOREIGN KEY (FranchiseID)
        REFERENCES Infrastructure.Franchise (FranchiseID),
    CONSTRAINT FK_ChargingStation_StationModel FOREIGN KEY (StationModelID)
        REFERENCES Infrastructure.StationModel (StationModelID),
    CONSTRAINT FK_ChargingStation_Address FOREIGN KEY (AddressID)
        REFERENCES Infrastructure.Address (AddressID),
    CONSTRAINT FK_ChargingStation_ElectricitySupplier FOREIGN KEY (SupplierID)
        REFERENCES Infrastructure.ElectricitySupplier (SupplierID),
    CONSTRAINT CK_ChargingStation_Latitude CHECK (Latitude BETWEEN -90 AND 90),
    CONSTRAINT CK_ChargingStation_Longitude CHECK (Longitude BETWEEN -180 AND 180),
    CONSTRAINT CK_ChargingStation_StationStatus CHECK (StationStatus IN (N'Active', N'Inactive', N'UnderMaintenance', N'Retired')),
    CONSTRAINT CK_ChargingStation_NetworkStatus CHECK (NetworkStatus IN (N'Online', N'Offline', N'Degraded', N'Unknown'))
);
GO

-- ---------------------------------------------------------------------------
-- Infrastructure.ChargingPoint - Individual connector/outlet (enhanced)
-- ---------------------------------------------------------------------------
CREATE TABLE Infrastructure.ChargingPoint
(
    PointID             INT             IDENTITY(1,1)   NOT NULL,
    PointCode           NVARCHAR(30)    NOT NULL,
    StationID           INT             NOT NULL,
    SerialNumber        NVARCHAR(100)   NULL,
    ConnectorType       NVARCHAR(30)    NOT NULL,
    PowerKW             DECIMAL(7,2)    NOT NULL,
    CurrentVoltage      DECIMAL(7,2)    NULL,
    CurrentAmperage     DECIMAL(7,2)    NULL,
    FirmwareVersion     NVARCHAR(50)    NULL,
    LastHeartbeat       DATETIME2       NULL,
    PointStatus         NVARCHAR(20)    NOT NULL DEFAULT N'Available',
    IsDeleted           BIT             NOT NULL DEFAULT 0,
    CreatedAt           DATETIME2       NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt           DATETIME2       NULL,
    DeletedAt           DATETIME2       NULL,

    CONSTRAINT PK_ChargingPoint PRIMARY KEY (PointID),
    CONSTRAINT UQ_ChargingPoint_PointCode UNIQUE (PointCode),
    CONSTRAINT UQ_ChargingPoint_SerialNumber UNIQUE (SerialNumber),
    CONSTRAINT FK_ChargingPoint_ChargingStation FOREIGN KEY (StationID)
        REFERENCES Infrastructure.ChargingStation (StationID),
    CONSTRAINT CK_ChargingPoint_PowerKW CHECK (PowerKW > 0),
    CONSTRAINT CK_ChargingPoint_PointStatus CHECK (PointStatus IN (N'Available', N'Busy', N'Error', N'Offline', N'Maintenance', N'Reserved'))
);
GO

-- ---------------------------------------------------------------------------
-- Infrastructure.StationElectricityContract - Many-to-many supplier contracts
-- ---------------------------------------------------------------------------
CREATE TABLE Infrastructure.StationElectricityContract
(
    ContractID          INT             IDENTITY(1,1)   NOT NULL,
    StationID           INT             NOT NULL,
    SupplierID          INT             NOT NULL,
    ContractNumber      NVARCHAR(50)    NOT NULL,
    UnitPricePerKWh     DECIMAL(19,4)   NOT NULL,
    CurrencyCode        NCHAR(3)        NOT NULL DEFAULT N'VND',
    ContractFrom        DATE            NOT NULL,
    ContractTo          DATE            NULL,
    IsActive            BIT             NOT NULL DEFAULT 1,
    IsDeleted           BIT             NOT NULL DEFAULT 0,
    CreatedAt           DATETIME2       NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt           DATETIME2       NULL,
    DeletedAt           DATETIME2       NULL,

    CONSTRAINT PK_StationElectricityContract PRIMARY KEY (ContractID),
    CONSTRAINT UQ_StationElectricityContract_ContractNumber UNIQUE (ContractNumber),
    CONSTRAINT FK_StationElectricityContract_ChargingStation FOREIGN KEY (StationID)
        REFERENCES Infrastructure.ChargingStation (StationID),
    CONSTRAINT FK_StationElectricityContract_ElectricitySupplier FOREIGN KEY (SupplierID)
        REFERENCES Infrastructure.ElectricitySupplier (SupplierID),
    CONSTRAINT CK_StationElectricityContract_UnitPrice CHECK (UnitPricePerKWh >= 0),
    CONSTRAINT CK_StationElectricityContract_Dates CHECK (ContractTo IS NULL OR ContractFrom < ContractTo)
);
GO

-- ---------------------------------------------------------------------------
-- Infrastructure.StationDocument - Legal/operational documents per station
-- ---------------------------------------------------------------------------
CREATE TABLE Infrastructure.StationDocument
(
    DocumentID          INT             IDENTITY(1,1)   NOT NULL,
    StationID           INT             NOT NULL,
    DocumentType        NVARCHAR(50)    NOT NULL,
    DocumentName        NVARCHAR(200)   NOT NULL,
    DocumentUrl         NVARCHAR(500)   NOT NULL,
    ExpiryDate          DATE            NULL,
    IsVerified          BIT             NOT NULL DEFAULT 0,
    CreatedAt           DATETIME2       NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT PK_StationDocument PRIMARY KEY (DocumentID),
    CONSTRAINT FK_StationDocument_ChargingStation FOREIGN KEY (StationID)
        REFERENCES Infrastructure.ChargingStation (StationID),
    CONSTRAINT CK_StationDocument_DocumentType CHECK (DocumentType IN (N'BusinessLicense', N'ElectricityContract',
        N'Insurance', N'InspectionReport', N'MaintenanceLog', N'Other'))
);
GO

PRINT N'Infrastructure schema tables created.';
GO

-- ===========================================================================
-- SCHEMA: Access (RBAC, Permissions, Security Policies)
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- Access.Permission - Granular action permissions
-- ---------------------------------------------------------------------------
CREATE TABLE Access.Permission
(
    PermissionID        INT             IDENTITY(1,1)   NOT NULL,
    PermissionCode      NVARCHAR(50)    NOT NULL,
    PermissionName      NVARCHAR(200)   NOT NULL,
    Module              NVARCHAR(50)    NOT NULL,
    [Action]            NVARCHAR(50)    NOT NULL,
    Description         NVARCHAR(500)   NULL,
    IsActive            BIT             NOT NULL DEFAULT 1,
    CreatedAt           DATETIME2       NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT PK_Permission PRIMARY KEY (PermissionID),
    CONSTRAINT UQ_Permission_PermissionCode UNIQUE (PermissionCode)
);
GO

-- ---------------------------------------------------------------------------
-- Access.Role - Named role definitions
-- ---------------------------------------------------------------------------
CREATE TABLE Access.Role
(
    RoleID              INT             IDENTITY(1,1)   NOT NULL,
    RoleCode            NVARCHAR(20)    NOT NULL,
    RoleName            NVARCHAR(100)   NOT NULL,
    RoleLevel           INT             NOT NULL DEFAULT 0,
    Description         NVARCHAR(500)   NULL,
    IsActive            BIT             NOT NULL DEFAULT 1,
    IsSystem            BIT             NOT NULL DEFAULT 0,
    CreatedAt           DATETIME2       NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT PK_Role PRIMARY KEY (RoleID),
    CONSTRAINT UQ_Role_RoleCode UNIQUE (RoleCode)
);
GO

-- ---------------------------------------------------------------------------
-- Access.RolePermission - Many-to-many role-to-permission mapping
-- ---------------------------------------------------------------------------
CREATE TABLE Access.RolePermission
(
    RolePermissionID    INT             IDENTITY(1,1)   NOT NULL,
    RoleID              INT             NOT NULL,
    PermissionID        INT             NOT NULL,
    GrantedAt           DATETIME2       NOT NULL DEFAULT SYSDATETIME(),
    GrantedBy           INT             NULL,

    CONSTRAINT PK_RolePermission PRIMARY KEY (RolePermissionID),
    CONSTRAINT UQ_RolePermission_RoleID_PermissionID UNIQUE (RoleID, PermissionID),
    CONSTRAINT FK_RolePermission_Role FOREIGN KEY (RoleID)
        REFERENCES Access.Role (RoleID),
    CONSTRAINT FK_RolePermission_Permission FOREIGN KEY (PermissionID)
        REFERENCES Access.Permission (PermissionID)
);
GO

PRINT N'Access schema tables created.';
GO

-- ===========================================================================
-- SCHEMA: Users (Profiles, Authentication, Vehicles)
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- Users.[User] - Core user identity (separated from auth)
-- ---------------------------------------------------------------------------
CREATE TABLE Users.[User]
(
    UserID              INT             IDENTITY(1,1)   NOT NULL,
    UserGuid            UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
    Username            NVARCHAR(50)    NOT NULL,
    Email               NVARCHAR(100)   NOT NULL,
    Phone               NVARCHAR(20)    NULL,
    EmailConfirmed      BIT             NOT NULL DEFAULT 0,
    PhoneConfirmed      BIT             NOT NULL DEFAULT 0,
    AccountStatus       NVARCHAR(20)    NOT NULL DEFAULT N'Pending',
    AccountTier         NVARCHAR(20)    NOT NULL DEFAULT N'Regular',
    FailedLoginAttempts INT             NOT NULL DEFAULT 0,
    LockoutEnd          DATETIME2       NULL,
    LastLoginAt         DATETIME2       NULL,
    IsDeleted           BIT             NOT NULL DEFAULT 0,
    CreatedAt           DATETIME2       NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt           DATETIME2       NULL,
    DeletedAt           DATETIME2       NULL,
    CreatedBy           INT             NULL,
    UpdatedBy           INT             NULL,

    CONSTRAINT PK_User PRIMARY KEY (UserID),
    CONSTRAINT UQ_User_UserGuid UNIQUE (UserGuid),
    CONSTRAINT UQ_User_Username UNIQUE (Username),
    CONSTRAINT UQ_User_Email UNIQUE (Email),
    CONSTRAINT UQ_User_Phone UNIQUE (Phone),
    CONSTRAINT CK_User_AccountStatus CHECK (AccountStatus IN (N'Pending', N'Active', N'Suspended', N'Locked', N'Closed')),
    CONSTRAINT CK_User_AccountTier CHECK (AccountTier IN (N'Regular', N'Premium', N'VIP', N'Corporate')),
    CONSTRAINT CK_User_FailedLoginAttempts CHECK (FailedLoginAttempts >= 0)
);
GO

-- ---------------------------------------------------------------------------
-- Users.UserProfile - Extended profile information (1:1 with User)
-- ---------------------------------------------------------------------------
CREATE TABLE Users.UserProfile
(
    UserProfileID       INT             IDENTITY(1,1)   NOT NULL,
    UserID              INT             NOT NULL,
    FullName            NVARCHAR(100)   NOT NULL,
    DisplayName         NVARCHAR(100)   NULL,
    AvatarUrl           NVARCHAR(500)   NULL,
    DateOfBirth         DATE            NULL,
    Gender              NCHAR(1)        NULL,
    AddressID           INT             NULL,
    NationalID          NVARCHAR(20)    NULL,
    TaxID               NVARCHAR(20)    NULL,
    EmergencyContact    NVARCHAR(100)   NULL,
    EmergencyPhone      NVARCHAR(20)    NULL,
    PreferredLanguage   NVARCHAR(10)    NOT NULL DEFAULT N'vi',
    NotificationEmail   BIT             NOT NULL DEFAULT 1,
    NotificationSMS     BIT             NOT NULL DEFAULT 0,
    NotificationPush    BIT             NOT NULL DEFAULT 1,
    CreatedAt           DATETIME2       NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt           DATETIME2       NULL,

    CONSTRAINT PK_UserProfile PRIMARY KEY (UserProfileID),
    CONSTRAINT UQ_UserProfile_UserID UNIQUE (UserID),
    CONSTRAINT FK_UserProfile_User FOREIGN KEY (UserID)
        REFERENCES Users.[User] (UserID),
    CONSTRAINT FK_UserProfile_Address FOREIGN KEY (AddressID)
        REFERENCES Infrastructure.Address (AddressID),
    CONSTRAINT CK_UserProfile_Gender CHECK (Gender IN (N'M', N'F', N'O'))
);
GO

-- ---------------------------------------------------------------------------
-- Users.UserCredential - Authentication credentials (separated from profile)
-- ---------------------------------------------------------------------------
CREATE TABLE Users.UserCredential
(
    CredentialID        INT             IDENTITY(1,1)   NOT NULL,
    UserID              INT             NOT NULL,
    PasswordHash        NVARCHAR(256)   NOT NULL,
    PasswordSalt        NVARCHAR(128)   NOT NULL,
    HashAlgorithm       NVARCHAR(20)    NOT NULL DEFAULT N'PBKDF2-SHA256',
    MFAEnabled          BIT             NOT NULL DEFAULT 0,
    MFASecret           NVARCHAR(128)   NULL,
    MFAType             NVARCHAR(20)    NULL,
    PasswordChangedAt   DATETIME2       NOT NULL DEFAULT SYSDATETIME(),
    PasswordExpiresAt   DATETIME2       NULL,
    RequirePasswordChange BIT           NOT NULL DEFAULT 0,
    CreatedAt           DATETIME2       NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT PK_UserCredential PRIMARY KEY (CredentialID),
    CONSTRAINT UQ_UserCredential_UserID UNIQUE (UserID),
    CONSTRAINT FK_UserCredential_User FOREIGN KEY (UserID)
        REFERENCES Users.[User] (UserID),
    CONSTRAINT CK_UserCredential_MFAType CHECK (MFAType IS NULL OR MFAType IN (N'TOTP', N'SMS', N'Email', N'Hardware'))
);
GO

-- ---------------------------------------------------------------------------
-- Users.UserSession - Active session tracking
-- ---------------------------------------------------------------------------
CREATE TABLE Users.UserSession
(
    SessionID           INT             IDENTITY(1,1)   NOT NULL,
    UserID              INT             NOT NULL,
    SessionToken        NVARCHAR(512)   NOT NULL,
    RefreshToken        NVARCHAR(512)   NULL,
    IPAddress           NVARCHAR(45)    NULL,
    UserAgent           NVARCHAR(500)   NULL,
    DeviceInfo          NVARCHAR(500)   NULL,
    LoginAt             DATETIME2       NOT NULL DEFAULT SYSDATETIME(),
    LastActivityAt      DATETIME2       NOT NULL DEFAULT SYSDATETIME(),
    ExpiresAt           DATETIME2       NOT NULL,
    LogoutAt            DATETIME2       NULL,
    IsRevoked           BIT             NOT NULL DEFAULT 0,
    RevokedAt           DATETIME2       NULL,

    CONSTRAINT PK_UserSession PRIMARY KEY (SessionID),
    CONSTRAINT FK_UserSession_User FOREIGN KEY (UserID)
        REFERENCES Users.[User] (UserID)
);
GO

-- ---------------------------------------------------------------------------
-- Users.UserLoginHistory - Immutable login audit trail
-- ---------------------------------------------------------------------------
CREATE TABLE Users.UserLoginHistory
(
    LoginHistoryID      BIGINT          IDENTITY(1,1)   NOT NULL,
    UserID              INT             NOT NULL,
    LoginAt             DATETIME2       NOT NULL DEFAULT SYSDATETIME(),
    IPAddress           NVARCHAR(45)    NULL,
    UserAgent           NVARCHAR(500)   NULL,
    LoginSuccess        BIT             NOT NULL,
    FailureReason       NVARCHAR(200)   NULL,
    AuthMethod          NVARCHAR(20)    NOT NULL DEFAULT N'Password',

    CONSTRAINT PK_UserLoginHistory PRIMARY KEY (LoginHistoryID),
    CONSTRAINT FK_UserLoginHistory_User FOREIGN KEY (UserID)
        REFERENCES Users.[User] (UserID),
    CONSTRAINT CK_UserLoginHistory_AuthMethod CHECK (AuthMethod IN (N'Password', N'MFA-TOTP', N'MFA-SMS',
        N'Google', N'Facebook', N'SSO', N'RefreshToken'))
);
GO

-- ---------------------------------------------------------------------------
-- Users.UserRole - Many-to-many user-to-role assignment
-- ---------------------------------------------------------------------------
CREATE TABLE Users.UserRole
(
    UserRoleID          INT             IDENTITY(1,1)   NOT NULL,
    UserID              INT             NOT NULL,
    RoleID              INT             NOT NULL,
    AssignedAt          DATETIME2       NOT NULL DEFAULT SYSDATETIME(),
    AssignedBy          INT             NULL,
    IsActive            BIT             NOT NULL DEFAULT 1,
    ExpiresAt           DATETIME2       NULL,

    CONSTRAINT PK_UserRole PRIMARY KEY (UserRoleID),
    CONSTRAINT UQ_UserRole_UserID_RoleID UNIQUE (UserID, RoleID),
    CONSTRAINT FK_UserRole_User FOREIGN KEY (UserID)
        REFERENCES Users.[User] (UserID),
    CONSTRAINT FK_UserRole_Role FOREIGN KEY (RoleID)
        REFERENCES Access.Role (RoleID)
);
GO

-- ---------------------------------------------------------------------------
-- Users.Vehicle - Customer vehicles (enhanced)
-- ---------------------------------------------------------------------------
CREATE TABLE Users.Vehicle
(
    VehicleID           INT             IDENTITY(1,1)   NOT NULL,
    UserID              INT             NOT NULL,
    PlateNumber         NVARCHAR(20)    NOT NULL,
    VIN                 NVARCHAR(17)    NULL,
    Brand               NVARCHAR(50)    NULL,
    Model               NVARCHAR(100)   NULL,
    ModelYear           INT             NULL,
    BatteryCapacityKWh  DECIMAL(5,2)    NULL,
    ConnectorType       NVARCHAR(30)    NULL,
    IsDefault           BIT             NOT NULL DEFAULT 0,
    IsDeleted           BIT             NOT NULL DEFAULT 0,
    CreatedAt           DATETIME2       NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt           DATETIME2       NULL,
    DeletedAt           DATETIME2       NULL,

    CONSTRAINT PK_Vehicle PRIMARY KEY (VehicleID),
    CONSTRAINT UQ_Vehicle_PlateNumber UNIQUE (PlateNumber),
    CONSTRAINT UQ_Vehicle_VIN UNIQUE (VIN),
    CONSTRAINT FK_Vehicle_User FOREIGN KEY (UserID)
        REFERENCES Users.[User] (UserID),
    CONSTRAINT CK_Vehicle_BatteryCapacityKWh CHECK (BatteryCapacityKWh IS NULL OR BatteryCapacityKWh >= 0),
    CONSTRAINT CK_Vehicle_ModelYear CHECK (ModelYear IS NULL OR ModelYear >= 2000)
);
GO

-- ---------------------------------------------------------------------------
-- Users.UserPaymentMethod - Saved payment methods
-- ---------------------------------------------------------------------------
CREATE TABLE Users.UserPaymentMethod
(
    PaymentMethodID     INT             IDENTITY(1,1)   NOT NULL,
    UserID              INT             NOT NULL,
    MethodType          NVARCHAR(20)    NOT NULL,
    MethodName          NVARCHAR(100)   NULL,
    MaskedIdentifier    NVARCHAR(50)    NOT NULL,
    ExpiryMonth         TINYINT         NULL,
    ExpiryYear          SMALLINT        NULL,
    IsDefault           BIT             NOT NULL DEFAULT 0,
    IsVerified          BIT             NOT NULL DEFAULT 0,
    IsActive            BIT             NOT NULL DEFAULT 1,
    CreatedAt           DATETIME2       NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt           DATETIME2       NULL,

    CONSTRAINT PK_UserPaymentMethod PRIMARY KEY (PaymentMethodID),
    CONSTRAINT FK_UserPaymentMethod_User FOREIGN KEY (UserID)
        REFERENCES Users.[User] (UserID),
    CONSTRAINT CK_UserPaymentMethod_MethodType CHECK (MethodType IN (N'CreditCard', N'DebitCard', N'EWallet',
        N'BankTransfer', N'Visa', N'Mastercard', N'VNPay', N'Momo', N'ZaloPay'))
);
GO

PRINT N'Users schema tables created.';
GO

-- ===========================================================================
-- SCHEMA: Operations (Charging Sessions, Pricing, Maintenance)
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- Operations.PricingPolicy - Top-level pricing policy container
-- ---------------------------------------------------------------------------
CREATE TABLE Operations.PricingPolicy
(
    PolicyID            INT             IDENTITY(1,1)   NOT NULL,
    PolicyCode          NVARCHAR(20)    NOT NULL,
    PolicyName          NVARCHAR(200)   NOT NULL,
    PolicyType          NVARCHAR(30)    NOT NULL DEFAULT N'Standard',
    Description         NVARCHAR(1000)  NULL,
    BasePricePerKWh     DECIMAL(19,4)   NOT NULL,
    CurrencyCode        NCHAR(3)        NOT NULL DEFAULT N'VND',
    MinChargeFee        DECIMAL(19,4)   NULL DEFAULT 0,
    MaxChargeFee        DECIMAL(19,4)   NULL,
    ParkingFeePerMin    DECIMAL(19,4)   NULL DEFAULT 0,
    OverstayPenaltyPerMin DECIMAL(19,4) NULL,
    AppliedFrom         DATETIME2       NOT NULL,
    AppliedTo           DATETIME2       NULL,
    Priority            INT             NOT NULL DEFAULT 0,
    IsActive            BIT             NOT NULL DEFAULT 1,
    IsDeleted           BIT             NOT NULL DEFAULT 0,
    CreatedAt           DATETIME2       NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt           DATETIME2       NULL,
    CreatedBy           INT             NULL,
    UpdatedBy           INT             NULL,

    CONSTRAINT PK_PricingPolicy PRIMARY KEY (PolicyID),
    CONSTRAINT UQ_PricingPolicy_PolicyCode UNIQUE (PolicyCode),
    CONSTRAINT CK_PricingPolicy_BasePrice CHECK (BasePricePerKWh >= 0),
    CONSTRAINT CK_PricingPolicy_Dates CHECK (AppliedTo IS NULL OR AppliedFrom < AppliedTo),
    CONSTRAINT CK_PricingPolicy_PolicyType CHECK (PolicyType IN (N'Standard', N'PeakHour', N'OffPeak',
        N'Holiday', N'Promotional', N'Membership', N'Corporate', N'Dynamic'))
);
GO

-- ---------------------------------------------------------------------------
-- Operations.PricingRule - Granular pricing rules within a policy
-- ---------------------------------------------------------------------------
CREATE TABLE Operations.PricingRule
(
    PricingRuleID       INT             IDENTITY(1,1)   NOT NULL,
    PolicyID            INT             NOT NULL,
    RuleName            NVARCHAR(200)   NOT NULL,
    RuleType            NVARCHAR(30)    NOT NULL,
    ConditionJson       NVARCHAR(2000)  NULL,
    AdjustmentType      NVARCHAR(20)    NOT NULL,
    AdjustmentValue     DECIMAL(19,4)   NOT NULL,
    Priority            INT             NOT NULL DEFAULT 0,
    IsActive            BIT             NOT NULL DEFAULT 1,
    CreatedAt           DATETIME2       NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt           DATETIME2       NULL,

    CONSTRAINT PK_PricingRule PRIMARY KEY (PricingRuleID),
    CONSTRAINT FK_PricingRule_PricingPolicy FOREIGN KEY (PolicyID)
        REFERENCES Operations.PricingPolicy (PolicyID),
    CONSTRAINT CK_PricingRule_RuleType CHECK (RuleType IN (N'PeakHour', N'OffPeak', N'Holiday', N'Regional',
        N'ConsumptionTier', N'MemberTier', N'PromoCode', N'TimeOfDay', N'DayOfWeek')),
    CONSTRAINT CK_PricingRule_AdjustmentType CHECK (AdjustmentType IN (N'Multiplier', N'FixedDiscount',
        N'PercentageDiscount', N'FixedPrice', N'Waiver'))
);
GO

-- ---------------------------------------------------------------------------
-- Operations.PeakHourDefinition - Time-based peak/off-peak windows
-- ---------------------------------------------------------------------------
CREATE TABLE Operations.PeakHourDefinition
(
    PeakHourID          INT             IDENTITY(1,1)   NOT NULL,
    RegionID            INT             NULL,
    DayOfWeek           TINYINT         NOT NULL,
    StartHour           TIME(0)         NOT NULL,
    EndHour             TIME(0)         NOT NULL,
    IsPeak              BIT             NOT NULL,
    Multiplier          DECIMAL(3,2)    NOT NULL DEFAULT 1.00,
    IsActive            BIT             NOT NULL DEFAULT 1,
    CreatedAt           DATETIME2       NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT PK_PeakHourDefinition PRIMARY KEY (PeakHourID),
    CONSTRAINT FK_PeakHourDefinition_Region FOREIGN KEY (RegionID)
        REFERENCES Infrastructure.Region (RegionID),
    CONSTRAINT CK_PeakHourDefinition_DayOfWeek CHECK (DayOfWeek BETWEEN 1 AND 7),
    -- Allow overnight windows such as 22:00 -> 05:00 for off-peak pricing.
    CONSTRAINT CK_PeakHourDefinition_Hours CHECK (StartHour <> EndHour),
    CONSTRAINT CK_PeakHourDefinition_Multiplier CHECK (Multiplier > 0)
);
GO

-- ---------------------------------------------------------------------------
-- Operations.MembershipTier - Customer loyalty tiers
-- ---------------------------------------------------------------------------
CREATE TABLE Operations.MembershipTier
(
    MembershipTierID    INT             IDENTITY(1,1)   NOT NULL,
    TierCode            NVARCHAR(20)    NOT NULL,
    TierName            NVARCHAR(100)   NOT NULL,
    MinTotalKWh         DECIMAL(13,2)   NULL DEFAULT 0,
    MinTotalSpend       DECIMAL(19,4)   NULL DEFAULT 0,
    DiscountPercent     DECIMAL(5,2)    NOT NULL DEFAULT 0,
    PrioritySupport     BIT             NOT NULL DEFAULT 0,
    FreeParkingMinutes  INT             NULL DEFAULT 0,
    MonthlyFee          DECIMAL(19,4)   NULL DEFAULT 0,
    IsActive            BIT             NOT NULL DEFAULT 1,
    CreatedAt           DATETIME2       NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT PK_MembershipTier PRIMARY KEY (MembershipTierID),
    CONSTRAINT UQ_MembershipTier_TierCode UNIQUE (TierCode),
    CONSTRAINT CK_MembershipTier_DiscountPercent CHECK (DiscountPercent BETWEEN 0 AND 100)
);
GO

-- ---------------------------------------------------------------------------
-- Operations.UserMembership - User-to-tier assignments
-- ---------------------------------------------------------------------------
CREATE TABLE Operations.UserMembership
(
    UserMembershipID    INT             IDENTITY(1,1)   NOT NULL,
    UserID              INT             NOT NULL,
    MembershipTierID    INT             NOT NULL,
    StartedAt           DATETIME2       NOT NULL DEFAULT SYSDATETIME(),
    ExpiresAt           DATETIME2       NULL,
    IsActive            BIT             NOT NULL DEFAULT 1,
    CreatedAt           DATETIME2       NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT PK_UserMembership PRIMARY KEY (UserMembershipID),
    CONSTRAINT FK_UserMembership_User FOREIGN KEY (UserID)
        REFERENCES Users.[User] (UserID),
    CONSTRAINT FK_UserMembership_MembershipTier FOREIGN KEY (MembershipTierID)
        REFERENCES Operations.MembershipTier (MembershipTierID)
);
GO

-- ---------------------------------------------------------------------------
-- Operations.ChargingSession - Core session entity (fully enhanced)
-- ---------------------------------------------------------------------------
CREATE TABLE Operations.ChargingSession
(
    SessionID               BIGINT          IDENTITY(1,1)   NOT NULL,
    SessionCode             NVARCHAR(30)    NOT NULL,
    UserID                  INT             NOT NULL,
    VehicleID               INT             NULL,
    PointID                 INT             NOT NULL,
    StationID               INT             NOT NULL,
    PolicyID                INT             NOT NULL,
    MembershipTierID        INT             NULL,
    StartTime               DATETIME2       NOT NULL DEFAULT SYSDATETIME(),
    EndTime                 DATETIME2       NULL,
    StartBatteryPercent     DECIMAL(5,2)    NULL,
    EndBatteryPercent       DECIMAL(5,2)    NULL,
    MeterStart              DECIMAL(13,4)   NULL,
    MeterEnd                DECIMAL(13,4)   NULL,
    TotalKWh                DECIMAL(13,4)   NULL,
    ChargingDurationMinutes INT             NULL,
    AveragePowerKW          DECIMAL(7,2)    NULL,
    MaxPowerKW              DECIMAL(7,2)    NULL,
    CostBeforeDiscount      MONEY           NULL,
    DiscountAmount          MONEY           NULL,
    CostTotal               MONEY           NULL,
    CurrencyCode            NCHAR(3)        NOT NULL DEFAULT N'VND',
    StopReason              NVARCHAR(50)    NULL,
    SessionSource           NVARCHAR(30)    NOT NULL DEFAULT N'MobileApp',
    SessionType             NVARCHAR(20)    NOT NULL DEFAULT N'Public',
    SessionStatus           NVARCHAR(20)    NOT NULL DEFAULT N'Charging',
    OcppTransactionID       NVARCHAR(50)    NULL,
    IsDeleted               BIT             NOT NULL DEFAULT 0,
    CreatedAt               DATETIME2       NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt               DATETIME2       NULL,
    DeletedAt               DATETIME2       NULL,

    CONSTRAINT PK_ChargingSession PRIMARY KEY (SessionID),
    CONSTRAINT UQ_ChargingSession_SessionCode UNIQUE (SessionCode),
    CONSTRAINT FK_ChargingSession_User FOREIGN KEY (UserID)
        REFERENCES Users.[User] (UserID),
    CONSTRAINT FK_ChargingSession_Vehicle FOREIGN KEY (VehicleID)
        REFERENCES Users.Vehicle (VehicleID),
    CONSTRAINT FK_ChargingSession_ChargingPoint FOREIGN KEY (PointID)
        REFERENCES Infrastructure.ChargingPoint (PointID),
    CONSTRAINT FK_ChargingSession_ChargingStation FOREIGN KEY (StationID)
        REFERENCES Infrastructure.ChargingStation (StationID),
    CONSTRAINT FK_ChargingSession_PricingPolicy FOREIGN KEY (PolicyID)
        REFERENCES Operations.PricingPolicy (PolicyID),
    CONSTRAINT FK_ChargingSession_MembershipTier FOREIGN KEY (MembershipTierID)
        REFERENCES Operations.MembershipTier (MembershipTierID),
    CONSTRAINT CK_ChargingSession_TotalKWh CHECK (TotalKWh IS NULL OR TotalKWh >= 0),
    CONSTRAINT CK_ChargingSession_BatteryPercent CHECK (StartBatteryPercent IS NULL OR (StartBatteryPercent BETWEEN 0 AND 100)
        AND (EndBatteryPercent IS NULL OR (EndBatteryPercent BETWEEN 0 AND 100))),
    CONSTRAINT CK_ChargingSession_Duration CHECK (ChargingDurationMinutes IS NULL OR ChargingDurationMinutes >= 0),
    CONSTRAINT CK_ChargingSession_TimeRange CHECK (EndTime IS NULL OR StartTime < EndTime),
    CONSTRAINT CK_ChargingSession_StopReason CHECK (StopReason IS NULL OR StopReason IN (N'Completed', N'UserStopped',
        N'PaymentFailed', N'Error', N'Timeout', N'EmergencyStop', N'VehicleFull', N'Maintenance', N'Other')),
    CONSTRAINT CK_ChargingSession_SessionSource CHECK (SessionSource IN (N'MobileApp', N'WebPortal', N'RFIDCard',
        N'OCPP', N'AdminPanel', N'API')),
    CONSTRAINT CK_ChargingSession_SessionType CHECK (SessionType IN (N'Public', N'Private', N'Corporate', N'Free', N'Demo')),
    CONSTRAINT CK_ChargingSession_SessionStatus CHECK (SessionStatus IN (N'Charging', N'Completed', N'Cancelled',
        N'Failed', N'Pending', N'Interrupted'))
);
GO

-- ---------------------------------------------------------------------------
-- Operations.MaintenanceSchedule - Planned maintenance events
-- ---------------------------------------------------------------------------
CREATE TABLE Operations.MaintenanceSchedule
(
    ScheduleID          INT             IDENTITY(1,1)   NOT NULL,
    StationID           INT             NOT NULL,
    PointID             INT             NULL,
    ScheduledDate       DATETIME2       NOT NULL,
    CompletedDate       DATETIME2       NULL,
    MaintenanceType     NVARCHAR(30)    NOT NULL,
    TechnicianName      NVARCHAR(100)   NOT NULL,
    TechnicianPhone     NVARCHAR(20)    NULL,
    Description         NVARCHAR(1000)  NULL,
    ActionTaken         NVARCHAR(2000)  NULL,
    PartsUsed           NVARCHAR(500)   NULL,
    Cost                MONEY           NULL,
    ScheduleStatus      NVARCHAR(20)    NOT NULL DEFAULT N'Scheduled',
    Priority            NVARCHAR(10)    NOT NULL DEFAULT N'Normal',
    IsDeleted           BIT             NOT NULL DEFAULT 0,
    CreatedAt           DATETIME2       NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt           DATETIME2       NULL,
    CreatedBy           INT             NULL,
    UpdatedBy           INT             NULL,

    CONSTRAINT PK_MaintenanceSchedule PRIMARY KEY (ScheduleID),
    CONSTRAINT FK_MaintenanceSchedule_ChargingStation FOREIGN KEY (StationID)
        REFERENCES Infrastructure.ChargingStation (StationID),
    CONSTRAINT FK_MaintenanceSchedule_ChargingPoint FOREIGN KEY (PointID)
        REFERENCES Infrastructure.ChargingPoint (PointID),
    CONSTRAINT CK_MaintenanceSchedule_Status CHECK (ScheduleStatus IN (N'Scheduled', N'InProgress', N'Completed', N'Cancelled')),
    CONSTRAINT CK_MaintenanceSchedule_Type CHECK (MaintenanceType IN (N'Routine', N'Repair', N'Inspection',
        N'Upgrade', N'Emergency', N'Calibration')),
    CONSTRAINT CK_MaintenanceSchedule_Priority CHECK (Priority IN (N'Low', N'Normal', N'High', N'Critical'))
);
GO

PRINT N'Operations schema tables created.';
GO

-- ===========================================================================
-- SCHEMA: Payments (Transactions, Wallets, Invoices, Gateways)
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- Payments.PaymentGateway - Registered gateway providers
-- ---------------------------------------------------------------------------
CREATE TABLE Payments.PaymentGateway
(
    GatewayID           INT             IDENTITY(1,1)   NOT NULL,
    GatewayCode         NVARCHAR(20)    NOT NULL,
    GatewayName         NVARCHAR(100)   NOT NULL,
    GatewayType         NVARCHAR(30)    NOT NULL,
    ApiEndpoint         NVARCHAR(500)   NULL,
    MerchantID          NVARCHAR(100)   NULL,
    IsActive            BIT             NOT NULL DEFAULT 1,
    CreatedAt           DATETIME2       NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT PK_PaymentGateway PRIMARY KEY (GatewayID),
    CONSTRAINT UQ_PaymentGateway_GatewayCode UNIQUE (GatewayCode),
    CONSTRAINT CK_PaymentGateway_GatewayType CHECK (GatewayType IN (N'CreditCard', N'EWallet', N'BankTransfer',
        N'VNPay', N'Momo', N'ZaloPay', N'PayPal', N'Stripe', N'Internal'))
);
GO

-- ---------------------------------------------------------------------------
-- Payments.[Transaction] - Financial transaction record
-- ---------------------------------------------------------------------------
CREATE TABLE Payments.[Transaction]
(
    TransactionID       BIGINT          IDENTITY(1,1)   NOT NULL,
    TransactionCode     NVARCHAR(30)    NOT NULL,
    UserID              INT             NOT NULL,
    SessionID           BIGINT          NULL,
    InvoiceID           INT             NULL,
    GatewayID           INT             NULL,
    TransactionType     NVARCHAR(30)    NOT NULL,
    Direction           NCHAR(1)        NOT NULL DEFAULT N'D',
    Amount              MONEY           NOT NULL,
    CurrencyCode        NCHAR(3)        NOT NULL DEFAULT N'VND',
    ExchangeRate        DECIMAL(19,4)   NULL DEFAULT 1.0000,
    AmountBaseCurrency  AS              CAST(Amount / ExchangeRate AS MONEY),
    FeeAmount           MONEY           NULL DEFAULT 0,
    NetAmount           AS              CAST(Amount - ISNULL(FeeAmount, 0) AS MONEY),
    TransactionStatus   NVARCHAR(20)    NOT NULL DEFAULT N'Pending',
    PaymentMethod       NVARCHAR(30)    NULL,
    ReferenceCode       NVARCHAR(100)   NULL,
    Description         NVARCHAR(500)   NULL,
    TransactedAt        DATETIME2       NOT NULL DEFAULT SYSDATETIME(),
    SettledAt           DATETIME2       NULL,
    IsDeleted           BIT             NOT NULL DEFAULT 0,
    CreatedAt           DATETIME2       NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt           DATETIME2       NULL,

    CONSTRAINT PK_Transaction PRIMARY KEY (TransactionID),
    CONSTRAINT UQ_Transaction_TransactionCode UNIQUE (TransactionCode),
    CONSTRAINT FK_Transaction_User FOREIGN KEY (UserID)
        REFERENCES Users.[User] (UserID),
    CONSTRAINT FK_Transaction_ChargingSession FOREIGN KEY (SessionID)
        REFERENCES Operations.ChargingSession (SessionID),
    CONSTRAINT FK_Transaction_PaymentGateway FOREIGN KEY (GatewayID)
        REFERENCES Payments.PaymentGateway (GatewayID),
    CONSTRAINT CK_Transaction_Amount CHECK (Amount >= 0),
    CONSTRAINT CK_Transaction_Direction CHECK (Direction IN (N'D', N'C')),
    CONSTRAINT CK_Transaction_TransactionType CHECK (TransactionType IN (N'ChargingPayment', N'WalletTopUp',
        N'Refund', N'Withdrawal', N'MembershipFee', N'Penalty', N'Commission')),
    CONSTRAINT CK_Transaction_TransactionStatus CHECK (TransactionStatus IN (N'Pending', N'Processing', N'Completed',
        N'Failed', N'Refunded', N'PartiallyRefunded', N'Cancelled'))
);
GO

-- ---------------------------------------------------------------------------
-- Payments.TransactionStatusHistory - Status change audit
-- ---------------------------------------------------------------------------
CREATE TABLE Payments.TransactionStatusHistory
(
    StatusHistoryID     BIGINT          IDENTITY(1,1)   NOT NULL,
    TransactionID       BIGINT          NOT NULL,
    PreviousStatus      NVARCHAR(20)    NULL,
    NewStatus           NVARCHAR(20)    NOT NULL,
    ChangedBy           NVARCHAR(100)   NULL,
    Reason              NVARCHAR(500)   NULL,
    ChangedAt           DATETIME2       NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT PK_TransactionStatusHistory PRIMARY KEY (StatusHistoryID),
    CONSTRAINT FK_TransactionStatusHistory_Transaction FOREIGN KEY (TransactionID)
        REFERENCES Payments.[Transaction] (TransactionID)
);
GO

-- ---------------------------------------------------------------------------
-- Payments.GatewayTransaction - External gateway call records
-- ---------------------------------------------------------------------------
CREATE TABLE Payments.GatewayTransaction
(
    GatewayTransactionID BIGINT          IDENTITY(1,1)   NOT NULL,
    TransactionID        BIGINT          NOT NULL,
    GatewayID            INT             NOT NULL,
    GatewayReferenceID   NVARCHAR(200)   NULL,
    RequestPayload       NVARCHAR(MAX)   NULL,
    ResponsePayload      NVARCHAR(MAX)   NULL,
    GatewayStatus        NVARCHAR(30)    NOT NULL,
    GatewayMessage       NVARCHAR(500)   NULL,
    AttemptCount         INT             NOT NULL DEFAULT 1,
    AttemptedAt          DATETIME2       NOT NULL DEFAULT SYSDATETIME(),
    CompletedAt          DATETIME2       NULL,

    CONSTRAINT PK_GatewayTransaction PRIMARY KEY (GatewayTransactionID),
    CONSTRAINT FK_GatewayTransaction_Transaction FOREIGN KEY (TransactionID)
        REFERENCES Payments.[Transaction] (TransactionID),
    CONSTRAINT FK_GatewayTransaction_PaymentGateway FOREIGN KEY (GatewayID)
        REFERENCES Payments.PaymentGateway (GatewayID)
);
GO

-- ---------------------------------------------------------------------------
-- Payments.RefundTransaction - Refund tracking
-- ---------------------------------------------------------------------------
CREATE TABLE Payments.RefundTransaction
(
    RefundID            BIGINT          IDENTITY(1,1)   NOT NULL,
    OriginalTransactionID BIGINT        NOT NULL,
    RefundCode          NVARCHAR(30)    NOT NULL,
    RefundAmount        MONEY           NOT NULL,
    RefundReason        NVARCHAR(500)   NOT NULL,
    RefundType          NVARCHAR(20)    NOT NULL DEFAULT N'Full',
    RefundStatus        NVARCHAR(20)    NOT NULL DEFAULT N'Pending',
    ApprovedBy          INT             NULL,
    ApprovedAt          DATETIME2       NULL,
    GatewayRefundID     NVARCHAR(200)   NULL,
    Notes               NVARCHAR(1000)  NULL,
    CreatedAt           DATETIME2       NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt           DATETIME2       NULL,

    CONSTRAINT PK_RefundTransaction PRIMARY KEY (RefundID),
    CONSTRAINT UQ_RefundTransaction_RefundCode UNIQUE (RefundCode),
    CONSTRAINT FK_RefundTransaction_OriginalTransaction FOREIGN KEY (OriginalTransactionID)
        REFERENCES Payments.[Transaction] (TransactionID),
    CONSTRAINT CK_RefundTransaction_Amount CHECK (RefundAmount > 0),
    CONSTRAINT CK_RefundTransaction_Type CHECK (RefundType IN (N'Full', N'Partial')),
    CONSTRAINT CK_RefundTransaction_Status CHECK (RefundStatus IN (N'Pending', N'Approved', N'Processing',
        N'Completed', N'Rejected', N'Failed'))
);
GO

-- ---------------------------------------------------------------------------
-- Payments.Wallet - User wallets
-- ---------------------------------------------------------------------------
CREATE TABLE Payments.Wallet
(
    WalletID            INT             IDENTITY(1,1)   NOT NULL,
    UserID              INT             NOT NULL,
    WalletCode          NVARCHAR(30)    NOT NULL,
    Balance             MONEY           NOT NULL DEFAULT 0,
    PendingBalance      MONEY           NOT NULL DEFAULT 0,
    CurrencyCode        NCHAR(3)        NOT NULL DEFAULT N'VND',
    IsActive            BIT             NOT NULL DEFAULT 1,
    LastTransactionAt   DATETIME2       NULL,
    CreatedAt           DATETIME2       NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt           DATETIME2       NULL,

    CONSTRAINT PK_Wallet PRIMARY KEY (WalletID),
    CONSTRAINT UQ_Wallet_WalletCode UNIQUE (WalletCode),
    CONSTRAINT UQ_Wallet_UserID UNIQUE (UserID),
    CONSTRAINT FK_Wallet_User FOREIGN KEY (UserID)
        REFERENCES Users.[User] (UserID),
    CONSTRAINT CK_Wallet_Balance CHECK (Balance >= 0),
    CONSTRAINT CK_Wallet_PendingBalance CHECK (PendingBalance >= 0)
);
GO

-- ---------------------------------------------------------------------------
-- Payments.WalletTransaction - Wallet movement ledger
-- ---------------------------------------------------------------------------
CREATE TABLE Payments.WalletTransaction
(
    WalletTransactionID BIGINT          IDENTITY(1,1)   NOT NULL,
    WalletID            INT             NOT NULL,
    TransactionID       BIGINT          NULL,
    Amount              MONEY           NOT NULL,
    BalanceBefore       MONEY           NOT NULL,
    BalanceAfter        AS              CAST(BalanceBefore + Amount AS MONEY),
    Direction           NCHAR(1)        NOT NULL,
    TransactionType     NVARCHAR(30)    NOT NULL,
    Description         NVARCHAR(500)   NULL,
    CreatedAt           DATETIME2       NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT PK_WalletTransaction PRIMARY KEY (WalletTransactionID),
    CONSTRAINT FK_WalletTransaction_Wallet FOREIGN KEY (WalletID)
        REFERENCES Payments.Wallet (WalletID),
    CONSTRAINT FK_WalletTransaction_Transaction FOREIGN KEY (TransactionID)
        REFERENCES Payments.[Transaction] (TransactionID),
    CONSTRAINT CK_WalletTransaction_Direction CHECK (Direction IN (N'D', N'C'))
);
GO

-- ---------------------------------------------------------------------------
-- Payments.Invoice - Billing invoice
-- ---------------------------------------------------------------------------
CREATE TABLE Payments.Invoice
(
    InvoiceID           INT             IDENTITY(1,1)   NOT NULL,
    InvoiceCode         NVARCHAR(30)    NOT NULL,
    UserID              INT             NOT NULL,
    InvoiceType         NVARCHAR(20)    NOT NULL DEFAULT N'Charging',
    InvoiceStatus       NVARCHAR(20)    NOT NULL DEFAULT N'Draft',
    SubTotal            MONEY           NOT NULL DEFAULT 0,
    TaxAmount           MONEY           NOT NULL DEFAULT 0,
    TaxRate             DECIMAL(5,2)    NOT NULL DEFAULT 0,
    DiscountAmount      MONEY           NOT NULL DEFAULT 0,
    TotalAmount         AS              CAST(SubTotal + TaxAmount - DiscountAmount AS MONEY),
    CurrencyCode        NCHAR(3)        NOT NULL DEFAULT N'VND',
    BillingAddress      NVARCHAR(500)   NULL,
    InvoiceDate         DATE            NOT NULL DEFAULT CAST(SYSDATETIME() AS DATE),
    DueDate             DATE            NULL,
    PaidAt              DATETIME2       NULL,
    Notes               NVARCHAR(1000)  NULL,
    IsDeleted           BIT             NOT NULL DEFAULT 0,
    CreatedAt           DATETIME2       NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt           DATETIME2       NULL,

    CONSTRAINT PK_Invoice PRIMARY KEY (InvoiceID),
    CONSTRAINT UQ_Invoice_InvoiceCode UNIQUE (InvoiceCode),
    CONSTRAINT FK_Invoice_User FOREIGN KEY (UserID)
        REFERENCES Users.[User] (UserID),
    CONSTRAINT CK_Invoice_InvoiceType CHECK (InvoiceType IN (N'Charging', N'Membership', N'Penalty', N'Refund', N'Corporate')),
    CONSTRAINT CK_Invoice_InvoiceStatus CHECK (InvoiceStatus IN (N'Draft', N'Issued', N'Paid', N'Overdue', N'Cancelled', N'Refunded'))
);
GO

-- ---------------------------------------------------------------------------
-- Payments.InvoiceLineItem - Invoice line details
-- ---------------------------------------------------------------------------
CREATE TABLE Payments.InvoiceLineItem
(
    LineItemID          INT             IDENTITY(1,1)   NOT NULL,
    InvoiceID           INT             NOT NULL,
    SessionID           BIGINT          NULL,
    Description         NVARCHAR(500)   NOT NULL,
    Quantity            DECIMAL(13,4)   NOT NULL DEFAULT 1,
    UnitPrice           MONEY           NOT NULL,
    LineTotal           AS              CAST(Quantity * UnitPrice AS MONEY),
    TaxRate             DECIMAL(5,2)    NULL DEFAULT 0,

    CONSTRAINT PK_InvoiceLineItem PRIMARY KEY (LineItemID),
    CONSTRAINT FK_InvoiceLineItem_Invoice FOREIGN KEY (InvoiceID)
        REFERENCES Payments.Invoice (InvoiceID),
    CONSTRAINT FK_InvoiceLineItem_ChargingSession FOREIGN KEY (SessionID)
        REFERENCES Operations.ChargingSession (SessionID)
);
GO

PRINT N'Payments schema tables created.';
GO

-- ===========================================================================
-- SCHEMA: Monitoring (Telemetry, Alerts, Errors)
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- Monitoring.ErrorLog - Enhanced error/incident logging
-- ---------------------------------------------------------------------------
CREATE TABLE Monitoring.ErrorLog
(
    ErrorID             BIGINT          IDENTITY(1,1)   NOT NULL,
    PointID             INT             NULL,
    StationID           INT             NULL,
    SessionID           BIGINT          NULL,
    ErrorCode           NVARCHAR(30)    NOT NULL,
    ErrorCategory       NVARCHAR(30)    NOT NULL,
    Severity            NVARCHAR(10)    NOT NULL,
    Title               NVARCHAR(200)   NOT NULL,
    Description         NVARCHAR(2000)  NULL,
    StackTrace          NVARCHAR(MAX)   NULL,
    OccurredAt          DATETIME2       NOT NULL DEFAULT SYSDATETIME(),
    ResolvedAt          DATETIME2       NULL,
    ResolvedBy          INT             NULL,
    Resolution          NVARCHAR(1000)  NULL,
    IsDeleted           BIT             NOT NULL DEFAULT 0,
    CreatedAt           DATETIME2       NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT PK_ErrorLog PRIMARY KEY (ErrorID),
    CONSTRAINT FK_ErrorLog_ChargingPoint FOREIGN KEY (PointID)
        REFERENCES Infrastructure.ChargingPoint (PointID),
    CONSTRAINT FK_ErrorLog_ChargingStation FOREIGN KEY (StationID)
        REFERENCES Infrastructure.ChargingStation (StationID),
    CONSTRAINT FK_ErrorLog_ChargingSession FOREIGN KEY (SessionID)
        REFERENCES Operations.ChargingSession (SessionID),
    CONSTRAINT CK_ErrorLog_Severity CHECK (Severity IN (N'Low', N'Medium', N'High', N'Critical')),
    CONSTRAINT CK_ErrorLog_ErrorCategory CHECK (ErrorCategory IN (N'Hardware', N'Software', N'Network', N'Power',
        N'Connector', N'Payment', N'Security', N'Other'))
);
GO

-- ---------------------------------------------------------------------------
-- Monitoring.PointTelemetry - IoT telemetry data from charging points
-- ---------------------------------------------------------------------------
CREATE TABLE Monitoring.PointTelemetry
(
    TelemetryID         BIGINT          IDENTITY(1,1)   NOT NULL,
    PointID             INT             NOT NULL,
    Voltage             DECIMAL(7,2)    NULL,
    Amperage            DECIMAL(7,2)    NULL,
    PowerKW             DECIMAL(7,2)    NULL,
    TemperatureC        DECIMAL(5,2)    NULL,
    EnergyDeliveredKWh  DECIMAL(13,4)   NULL,
    CableStatus         NVARCHAR(20)    NULL,
    ErrorFlags          INT             NULL,
    FirmwareVersion     NVARCHAR(50)    NULL,
    RecordedAt          DATETIME2       NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT PK_PointTelemetry PRIMARY KEY (TelemetryID),
    CONSTRAINT FK_PointTelemetry_ChargingPoint FOREIGN KEY (PointID)
        REFERENCES Infrastructure.ChargingPoint (PointID),
    CONSTRAINT CK_PointTelemetry_CableStatus CHECK (CableStatus IS NULL OR CableStatus IN (N'Connected', N'Disconnected', N'Fault'))
);
GO

-- ---------------------------------------------------------------------------
-- Monitoring.StationHeartbeat - Station connectivity monitoring
-- ---------------------------------------------------------------------------
CREATE TABLE Monitoring.StationHeartbeat
(
    HeartbeatID         BIGINT          IDENTITY(1,1)   NOT NULL,
    StationID           INT             NOT NULL,
    NetworkStatus       NVARCHAR(20)    NOT NULL,
    ResponseTimeMs      INT             NULL,
    SignalStrength      INT             NULL,
    UptimeSeconds       BIGINT          NULL,
    IsHealthy           BIT             NOT NULL DEFAULT 1,
    RecordedAt          DATETIME2       NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT PK_StationHeartbeat PRIMARY KEY (HeartbeatID),
    CONSTRAINT FK_StationHeartbeat_ChargingStation FOREIGN KEY (StationID)
        REFERENCES Infrastructure.ChargingStation (StationID),
    CONSTRAINT CK_StationHeartbeat_NetworkStatus CHECK (NetworkStatus IN (N'Online', N'Offline', N'Degraded', N'Unknown'))
);
GO

-- ---------------------------------------------------------------------------
-- Monitoring.AlertRule - Configurable alert threshold rules
-- ---------------------------------------------------------------------------
CREATE TABLE Monitoring.AlertRule
(
    AlertRuleID         INT             IDENTITY(1,1)   NOT NULL,
    RuleName            NVARCHAR(200)   NOT NULL,
    RuleCategory        NVARCHAR(30)    NOT NULL,
    MetricName          NVARCHAR(50)    NOT NULL,
    Condition           NVARCHAR(10)    NOT NULL,
    ThresholdValue      DECIMAL(19,4)   NOT NULL,
    DurationSeconds     INT             NULL,
    Severity            NVARCHAR(10)    NOT NULL DEFAULT N'Medium',
    NotificationChannel NVARCHAR(50)    NULL,
    IsActive            BIT             NOT NULL DEFAULT 1,
    CreatedAt           DATETIME2       NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT PK_AlertRule PRIMARY KEY (AlertRuleID),
    CONSTRAINT CK_AlertRule_Condition CHECK (Condition IN (N'>', N'<', N'>=', N'<=', N'=', N'!=')),
    CONSTRAINT CK_AlertRule_Severity CHECK (Severity IN (N'Low', N'Medium', N'High', N'Critical'))
);
GO

-- ---------------------------------------------------------------------------
-- Monitoring.Alert - Generated alert instances
-- ---------------------------------------------------------------------------
CREATE TABLE Monitoring.Alert
(
    AlertID             BIGINT          IDENTITY(1,1)   NOT NULL,
    AlertRuleID         INT             NOT NULL,
    PointID             INT             NULL,
    StationID           INT             NULL,
    AlertTitle          NVARCHAR(200)   NOT NULL,
    AlertMessage        NVARCHAR(2000)  NULL,
    MetricValue         DECIMAL(19,4)   NULL,
    Severity            NVARCHAR(10)    NOT NULL,
    AlertStatus         NVARCHAR(20)    NOT NULL DEFAULT N'Open',
    AcknowledgedAt      DATETIME2       NULL,
    AcknowledgedBy      INT             NULL,
    ResolvedAt          DATETIME2       NULL,
    ResolvedBy          INT             NULL,
    CreatedAt           DATETIME2       NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT PK_Alert PRIMARY KEY (AlertID),
    CONSTRAINT FK_Alert_AlertRule FOREIGN KEY (AlertRuleID)
        REFERENCES Monitoring.AlertRule (AlertRuleID),
    CONSTRAINT FK_Alert_ChargingPoint FOREIGN KEY (PointID)
        REFERENCES Infrastructure.ChargingPoint (PointID),
    CONSTRAINT FK_Alert_ChargingStation FOREIGN KEY (StationID)
        REFERENCES Infrastructure.ChargingStation (StationID),
    CONSTRAINT CK_Alert_AlertStatus CHECK (AlertStatus IN (N'Open', N'Acknowledged', N'Resolved', N'Dismissed'))
);
GO

PRINT N'Monitoring schema tables created.';
GO

-- ===========================================================================
-- SCHEMA: Audit (Immutable Logs, Status History)
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- Audit.AuditLog - Immutable system-wide audit trail
-- ---------------------------------------------------------------------------
CREATE TABLE Audit.AuditLog
(
    AuditID             BIGINT          IDENTITY(1,1)   NOT NULL,
    TableName           NVARCHAR(100)   NOT NULL,
    RecordID            NVARCHAR(50)    NOT NULL,
    [Action]            NCHAR(1)        NOT NULL,
    OldValue            NVARCHAR(MAX)   NULL,
    NewValue            NVARCHAR(MAX)   NULL,
    ChangedColumns      NVARCHAR(500)   NULL,
    ChangedByUserID     INT             NULL,
    ChangedByIP         NVARCHAR(45)    NULL,
    ChangeReason        NVARCHAR(500)   NULL,
    ChangedAt           DATETIME2       NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT PK_AuditLog PRIMARY KEY (AuditID),
    CONSTRAINT CK_AuditLog_Action CHECK ([Action] IN ('I', 'U', 'D'))
);
GO

-- ---------------------------------------------------------------------------
-- Audit.StationStatusHistory - Station status change tracking
-- ---------------------------------------------------------------------------
CREATE TABLE Audit.StationStatusHistory
(
    StatusHistoryID     BIGINT          IDENTITY(1,1)   NOT NULL,
    StationID           INT             NOT NULL,
    PreviousStatus      NVARCHAR(20)    NULL,
    NewStatus           NVARCHAR(20)    NOT NULL,
    ChangedByUserID     INT             NULL,
    ChangeReason        NVARCHAR(500)   NULL,
    ChangedAt           DATETIME2       NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT PK_StationStatusHistory PRIMARY KEY (StatusHistoryID),
    CONSTRAINT FK_StationStatusHistory_ChargingStation FOREIGN KEY (StationID)
        REFERENCES Infrastructure.ChargingStation (StationID)
);
GO

-- ---------------------------------------------------------------------------
-- Audit.PointStatusHistory - Charging point status change tracking
-- ---------------------------------------------------------------------------
CREATE TABLE Audit.PointStatusHistory
(
    StatusHistoryID     BIGINT          IDENTITY(1,1)   NOT NULL,
    PointID             INT             NOT NULL,
    PreviousStatus      NVARCHAR(20)    NULL,
    NewStatus           NVARCHAR(20)    NOT NULL,
    ChangedByUserID     INT             NULL,
    ChangeReason        NVARCHAR(500)   NULL,
    ChangedAt           DATETIME2       NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT PK_PointStatusHistory PRIMARY KEY (StatusHistoryID),
    CONSTRAINT FK_PointStatusHistory_ChargingPoint FOREIGN KEY (PointID)
        REFERENCES Infrastructure.ChargingPoint (PointID)
);
GO

-- ---------------------------------------------------------------------------
-- Audit.SessionStatusHistory - Charging session status tracking
-- ---------------------------------------------------------------------------
CREATE TABLE Audit.SessionStatusHistory
(
    StatusHistoryID     BIGINT          IDENTITY(1,1)   NOT NULL,
    SessionID           BIGINT          NOT NULL,
    PreviousStatus      NVARCHAR(20)    NULL,
    NewStatus           NVARCHAR(20)    NOT NULL,
    ChangedByUserID     INT             NULL,
    ChangeReason        NVARCHAR(500)   NULL,
    ChangedAt           DATETIME2       NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT PK_SessionStatusHistory PRIMARY KEY (StatusHistoryID),
    CONSTRAINT FK_SessionStatusHistory_ChargingSession FOREIGN KEY (SessionID)
        REFERENCES Operations.ChargingSession (SessionID)
);
GO

-- ---------------------------------------------------------------------------
-- Audit.SchemaChangeLog - Track DDL changes (database migrations)
-- ---------------------------------------------------------------------------
CREATE TABLE Audit.SchemaChangeLog
(
    ChangeID            INT             IDENTITY(1,1)   NOT NULL,
    ChangeVersion       NVARCHAR(20)    NOT NULL,
    ChangeDescription   NVARCHAR(500)   NOT NULL,
    ChangeScript        NVARCHAR(200)   NULL,
    AppliedBy           NVARCHAR(100)   NOT NULL DEFAULT SUSER_SNAME(),
    AppliedAt           DATETIME2       NOT NULL DEFAULT SYSDATETIME(),
    Checksum            NVARCHAR(64)    NULL,

    CONSTRAINT PK_SchemaChangeLog PRIMARY KEY (ChangeID),
    CONSTRAINT UQ_SchemaChangeLog_ChangeVersion UNIQUE (ChangeVersion)
);
GO

PRINT N'Audit schema tables created.';
GO

-- ===========================================================================
-- SCHEMA: Analytics (Materialized KPIs, Aggregations)
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- Analytics.DailyStationKPI - Pre-aggregated daily station metrics
-- ---------------------------------------------------------------------------
CREATE TABLE Analytics.DailyStationKPI
(
    KPIID               BIGINT          IDENTITY(1,1)   NOT NULL,
    StationID           INT             NOT NULL,
    KpiDate             DATE            NOT NULL,
    TotalSessions       INT             NOT NULL DEFAULT 0,
    TotalKWh            DECIMAL(16,4)   NOT NULL DEFAULT 0,
    TotalRevenue        MONEY           NOT NULL DEFAULT 0,
    AvgPowerKW          DECIMAL(7,2)    NULL,
    AvgChargingMinutes  INT             NULL,
    PeakConcurrentSessions INT          NULL DEFAULT 0,
    UniqueUsers         INT             NOT NULL DEFAULT 0,
    ErrorCount          INT             NOT NULL DEFAULT 0,
    UptimePercent       DECIMAL(5,2)    NULL,
    RevenuePerKWh       AS              CASE WHEN TotalKWh > 0
                                            THEN CAST(TotalRevenue / TotalKWh AS MONEY) ELSE 0 END,
    CreatedAt           DATETIME2       NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT PK_DailyStationKPI PRIMARY KEY (KPIID),
    CONSTRAINT UQ_DailyStationKPI_StationID_KpiDate UNIQUE (StationID, KpiDate),
    CONSTRAINT FK_DailyStationKPI_ChargingStation FOREIGN KEY (StationID)
        REFERENCES Infrastructure.ChargingStation (StationID)
);
GO

-- ---------------------------------------------------------------------------
-- Analytics.DailyFranchiseKPI - Daily franchise-level aggregation
-- ---------------------------------------------------------------------------
CREATE TABLE Analytics.DailyFranchiseKPI
(
    KPIID               BIGINT          IDENTITY(1,1)   NOT NULL,
    FranchiseID         INT             NOT NULL,
    KpiDate             DATE            NOT NULL,
    TotalSessions       INT             NOT NULL DEFAULT 0,
    TotalKWh            DECIMAL(16,4)   NOT NULL DEFAULT 0,
    TotalRevenue        MONEY           NOT NULL DEFAULT 0,
    CommissionAmount    MONEY           NOT NULL DEFAULT 0,
    ActiveStations      INT             NOT NULL DEFAULT 0,
    TotalErrors         INT             NOT NULL DEFAULT 0,
    UniqueUsers         INT             NOT NULL DEFAULT 0,
    AvgRevenuePerSession AS             CASE WHEN TotalSessions > 0
                                            THEN CAST(TotalRevenue / TotalSessions AS MONEY) ELSE 0 END,
    CreatedAt           DATETIME2       NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT PK_DailyFranchiseKPI PRIMARY KEY (KPIID),
    CONSTRAINT UQ_DailyFranchiseKPI_FranchiseID_KpiDate UNIQUE (FranchiseID, KpiDate),
    CONSTRAINT FK_DailyFranchiseKPI_Franchise FOREIGN KEY (FranchiseID)
        REFERENCES Infrastructure.Franchise (FranchiseID)
);
GO

-- ---------------------------------------------------------------------------
-- Analytics.HourlySessionAgg - Hourly session aggregation for peak analysis
-- ---------------------------------------------------------------------------
CREATE TABLE Analytics.HourlySessionAgg
(
    AggID               BIGINT          IDENTITY(1,1)   NOT NULL,
    StationID           INT             NOT NULL,
    AggDate             DATE            NOT NULL,
    AggHour             TINYINT         NOT NULL,
    TotalSessions       INT             NOT NULL DEFAULT 0,
    TotalKWh            DECIMAL(16,4)   NOT NULL DEFAULT 0,
    TotalRevenue        MONEY           NOT NULL DEFAULT 0,
    AvgDurationMin      INT             NULL,
    CreatedAt           DATETIME2       NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT PK_HourlySessionAgg PRIMARY KEY (AggID),
    CONSTRAINT UQ_HourlySessionAgg_StationID_Date_Hour UNIQUE (StationID, AggDate, AggHour),
    CONSTRAINT FK_HourlySessionAgg_ChargingStation FOREIGN KEY (StationID)
        REFERENCES Infrastructure.ChargingStation (StationID),
    CONSTRAINT CK_HourlySessionAgg_Hour CHECK (AggHour BETWEEN 0 AND 23)
);
GO

PRINT N'Analytics schema tables created.';
GO

-- ===========================================================================
-- SCHEMA: Reporting (Business Views - created separately in 09_CreateViews.sql)
-- ===========================================================================

PRINT N'All enterprise tables created successfully. Total: 48 tables across 9 schemas.';
GO

