USE EV_Charging_System;
GO

CREATE TABLE Core.Region
(
    RegionID INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Region PRIMARY KEY,
    RegionCode NVARCHAR(20) NOT NULL CONSTRAINT UQ_Region_Code UNIQUE,
    RegionName NVARCHAR(100) NOT NULL,
    TimeZone NVARCHAR(60) NOT NULL DEFAULT N'Asia/Ho_Chi_Minh',
    IsActive BIT NOT NULL DEFAULT 1
);
GO

CREATE TABLE Core.Address
(
    AddressID INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Address PRIMARY KEY,
    RegionID INT NOT NULL,
    StreetAddress NVARCHAR(255) NOT NULL,
    Ward NVARCHAR(100) NULL,
    District NVARCHAR(100) NULL,
    Latitude DECIMAL(10,7) NULL,
    Longitude DECIMAL(10,7) NULL,
    FullAddress AS (COALESCE(StreetAddress + N', ', N'') + COALESCE(Ward + N', ', N'') + COALESCE(District, N'')),
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT FK_Address_Region FOREIGN KEY (RegionID) REFERENCES Core.Region(RegionID),
    CONSTRAINT CK_Address_Latitude CHECK (Latitude IS NULL OR Latitude BETWEEN -90 AND 90),
    CONSTRAINT CK_Address_Longitude CHECK (Longitude IS NULL OR Longitude BETWEEN -180 AND 180)
);
GO

CREATE TABLE [Identity].Role
(
    RoleID INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Role PRIMARY KEY,
    RoleCode NVARCHAR(40) NOT NULL CONSTRAINT UQ_Role_Code UNIQUE,
    RoleName NVARCHAR(100) NOT NULL,
    Description NVARCHAR(500) NULL,
    IsSystemRole BIT NOT NULL DEFAULT 1
);
GO

CREATE TABLE [Identity].UserAccount
(
    UserID INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_UserAccount PRIMARY KEY,
    Username NVARCHAR(50) NOT NULL CONSTRAINT UQ_UserAccount_Username UNIQUE,
    Email NVARCHAR(120) NOT NULL CONSTRAINT UQ_UserAccount_Email UNIQUE,
    Phone NVARCHAR(20) NULL CONSTRAINT UQ_UserAccount_Phone UNIQUE,
    PasswordHash NVARCHAR(256) NOT NULL,
    FullName NVARCHAR(120) NOT NULL,
    AccountStatus NVARCHAR(20) NOT NULL DEFAULT N'Active',
    LastLoginAt DATETIME2 NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt DATETIME2 NULL,
    CONSTRAINT CK_UserAccount_Status CHECK (AccountStatus IN (N'Pending', N'Active', N'Suspended', N'Locked'))
);
GO

CREATE TABLE [Identity].UserRole
(
    UserID INT NOT NULL,
    RoleID INT NOT NULL,
    AssignedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_UserRole PRIMARY KEY (UserID, RoleID),
    CONSTRAINT FK_UserRole_User FOREIGN KEY (UserID) REFERENCES [Identity].UserAccount(UserID),
    CONSTRAINT FK_UserRole_Role FOREIGN KEY (RoleID) REFERENCES [Identity].Role(RoleID)
);
GO

CREATE TABLE Franchise.FranchisePartner
(
    FranchiseID INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_FranchisePartner PRIMARY KEY,
    FranchiseCode NVARCHAR(30) NOT NULL CONSTRAINT UQ_FranchisePartner_Code UNIQUE,
    FranchiseName NVARCHAR(200) NOT NULL,
    TaxCode NVARCHAR(30) NOT NULL CONSTRAINT UQ_FranchisePartner_TaxCode UNIQUE,
    AddressID INT NULL,
    ContactUserID INT NULL,
    ContactPerson NVARCHAR(120) NULL,
    ContactPhone NVARCHAR(20) NULL,
    ContactEmail NVARCHAR(120) NULL,
    PartnerStatus NVARCHAR(20) NOT NULL DEFAULT N'Active',
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT FK_FranchisePartner_Address FOREIGN KEY (AddressID) REFERENCES Core.Address(AddressID),
    CONSTRAINT FK_FranchisePartner_ContactUser FOREIGN KEY (ContactUserID) REFERENCES [Identity].UserAccount(UserID),
    CONSTRAINT CK_FranchisePartner_Status CHECK (PartnerStatus IN (N'Pending', N'Active', N'Suspended', N'Terminated'))
);
GO

CREATE TABLE Franchise.FranchiseContract
(
    ContractID INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_FranchiseContract PRIMARY KEY,
    FranchiseID INT NOT NULL,
    ContractCode NVARCHAR(40) NOT NULL CONSTRAINT UQ_FranchiseContract_Code UNIQUE,
    StartDate DATE NOT NULL,
    EndDate DATE NOT NULL,
    BaseRevenueShareRate DECIMAL(5,2) NOT NULL,
    ContractStatus NVARCHAR(20) NOT NULL DEFAULT N'Active',
    SignedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT FK_FranchiseContract_Franchise FOREIGN KEY (FranchiseID) REFERENCES Franchise.FranchisePartner(FranchiseID),
    CONSTRAINT CK_FranchiseContract_Date CHECK (StartDate < EndDate),
    CONSTRAINT CK_FranchiseContract_Rate CHECK (BaseRevenueShareRate BETWEEN 0 AND 100),
    CONSTRAINT CK_FranchiseContract_Status CHECK (ContractStatus IN (N'Draft', N'Active', N'Expired', N'Terminated'))
);
GO

CREATE TABLE Infrastructure.ElectricitySupplier
(
    SupplierID INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_ElectricitySupplier PRIMARY KEY,
    SupplierCode NVARCHAR(30) NOT NULL CONSTRAINT UQ_ElectricitySupplier_Code UNIQUE,
    SupplierName NVARCHAR(200) NOT NULL,
    RegionID INT NOT NULL,
    UnitPricePerKWh DECIMAL(19,4) NOT NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    CONSTRAINT FK_ElectricitySupplier_Region FOREIGN KEY (RegionID) REFERENCES Core.Region(RegionID),
    CONSTRAINT CK_ElectricitySupplier_Price CHECK (UnitPricePerKWh >= 0)
);
GO

CREATE TABLE Infrastructure.ChargingStation
(
    StationID INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_ChargingStation PRIMARY KEY,
    StationCode NVARCHAR(30) NOT NULL CONSTRAINT UQ_ChargingStation_Code UNIQUE,
    StationName NVARCHAR(200) NOT NULL,
    FranchiseID INT NOT NULL,
    AddressID INT NOT NULL,
    SupplierID INT NULL,
    StationOperatorID INT NULL,
    ModelName NVARCHAR(100) NULL,
    Manufacturer NVARCHAR(100) NULL,
    MaxPowerKW DECIMAL(8,2) NOT NULL,
    StationStatus NVARCHAR(30) NOT NULL DEFAULT N'Active',
    OpenedAt DATE NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt DATETIME2 NULL,
    CONSTRAINT FK_ChargingStation_Franchise FOREIGN KEY (FranchiseID) REFERENCES Franchise.FranchisePartner(FranchiseID),
    CONSTRAINT FK_ChargingStation_Address FOREIGN KEY (AddressID) REFERENCES Core.Address(AddressID),
    CONSTRAINT FK_ChargingStation_Supplier FOREIGN KEY (SupplierID) REFERENCES Infrastructure.ElectricitySupplier(SupplierID),
    CONSTRAINT FK_ChargingStation_Operator FOREIGN KEY (StationOperatorID) REFERENCES [Identity].UserAccount(UserID),
    CONSTRAINT CK_ChargingStation_Power CHECK (MaxPowerKW > 0),
    CONSTRAINT CK_ChargingStation_Status CHECK (StationStatus IN (N'Active', N'Inactive', N'UnderMaintenance', N'Retired'))
);
GO

CREATE TABLE Franchise.FranchiseStation
(
    FranchiseID INT NOT NULL,
    StationID INT NOT NULL,
    ContractID INT NOT NULL,
    AssignedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_FranchiseStation PRIMARY KEY (FranchiseID, StationID),
    CONSTRAINT FK_FranchiseStation_Franchise FOREIGN KEY (FranchiseID) REFERENCES Franchise.FranchisePartner(FranchiseID),
    CONSTRAINT FK_FranchiseStation_Station FOREIGN KEY (StationID) REFERENCES Infrastructure.ChargingStation(StationID),
    CONSTRAINT FK_FranchiseStation_Contract FOREIGN KEY (ContractID) REFERENCES Franchise.FranchiseContract(ContractID)
);
GO

CREATE TABLE Infrastructure.ConnectorType
(
    ConnectorTypeID INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_ConnectorType PRIMARY KEY,
    ConnectorCode NVARCHAR(30) NOT NULL CONSTRAINT UQ_ConnectorType_Code UNIQUE,
    ConnectorName NVARCHAR(100) NOT NULL,
    MaxPowerKW DECIMAL(8,2) NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    CONSTRAINT CK_ConnectorType_MaxPower CHECK (MaxPowerKW IS NULL OR MaxPowerKW > 0)
);
GO

CREATE TABLE Infrastructure.StationConnectorType
(
    StationID INT NOT NULL,
    ConnectorTypeID INT NOT NULL,
    CONSTRAINT PK_StationConnectorType PRIMARY KEY (StationID, ConnectorTypeID),
    CONSTRAINT FK_StationConnectorType_Station FOREIGN KEY (StationID) REFERENCES Infrastructure.ChargingStation(StationID),
    CONSTRAINT FK_StationConnectorType_Connector FOREIGN KEY (ConnectorTypeID) REFERENCES Infrastructure.ConnectorType(ConnectorTypeID)
);
GO

CREATE TABLE Infrastructure.ChargingPoint
(
    PointID INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_ChargingPoint PRIMARY KEY,
    PointCode NVARCHAR(40) NOT NULL CONSTRAINT UQ_ChargingPoint_Code UNIQUE,
    StationID INT NOT NULL,
    ConnectorTypeID INT NOT NULL,
    PowerKW DECIMAL(8,2) NOT NULL,
    SerialNumber NVARCHAR(100) NULL CONSTRAINT UQ_ChargingPoint_Serial UNIQUE,
    PointStatus NVARCHAR(30) NOT NULL DEFAULT N'Available',
    HealthStatus NVARCHAR(20) NOT NULL DEFAULT N'Normal',
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt DATETIME2 NULL,
    CONSTRAINT FK_ChargingPoint_Station FOREIGN KEY (StationID) REFERENCES Infrastructure.ChargingStation(StationID),
    CONSTRAINT FK_ChargingPoint_Connector FOREIGN KEY (ConnectorTypeID) REFERENCES Infrastructure.ConnectorType(ConnectorTypeID),
    CONSTRAINT CK_ChargingPoint_Power CHECK (PowerKW > 0),
    CONSTRAINT CK_ChargingPoint_Status CHECK (PointStatus IN (N'Available', N'Reserved', N'Charging', N'Offline', N'Error', N'Maintenance', N'Retired')),
    CONSTRAINT CK_ChargingPoint_Health CHECK (HealthStatus IN (N'Normal', N'Warning', N'Critical', N'Offline'))
);
GO

CREATE TABLE Infrastructure.PointStatusHistory
(
    PointStatusHistoryID BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_PointStatusHistory PRIMARY KEY,
    PointID INT NOT NULL,
    OldStatus NVARCHAR(30) NOT NULL,
    NewStatus NVARCHAR(30) NOT NULL,
    ChangedBy INT NULL,
    ChangedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT FK_PointStatusHistory_Point FOREIGN KEY (PointID) REFERENCES Infrastructure.ChargingPoint(PointID),
    CONSTRAINT FK_PointStatusHistory_User FOREIGN KEY (ChangedBy) REFERENCES [Identity].UserAccount(UserID)
);
GO

CREATE TABLE Infrastructure.PointTelemetry
(
    TelemetryID BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_PointTelemetry PRIMARY KEY,
    PointID INT NOT NULL,
    Voltage DECIMAL(8,2) NULL,
    CurrentAmp DECIMAL(8,2) NULL,
    TemperatureC DECIMAL(5,2) NULL,
    PowerKW DECIMAL(8,2) NULL,
    HealthStatus NVARCHAR(20) NOT NULL,
    RecordedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT FK_PointTelemetry_Point FOREIGN KEY (PointID) REFERENCES Infrastructure.ChargingPoint(PointID),
    CONSTRAINT CK_PointTelemetry_Health CHECK (HealthStatus IN (N'Normal', N'Warning', N'Critical', N'Offline')),
    CONSTRAINT CK_PointTelemetry_NonNegative CHECK ((Voltage IS NULL OR Voltage >= 0) AND (CurrentAmp IS NULL OR CurrentAmp >= 0) AND (PowerKW IS NULL OR PowerKW >= 0))
);
GO

CREATE TABLE Operations.Vehicle
(
    VehicleID INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Vehicle PRIMARY KEY,
    UserID INT NOT NULL,
    PlateNumber NVARCHAR(20) NOT NULL CONSTRAINT UQ_Vehicle_Plate UNIQUE,
    Brand NVARCHAR(50) NOT NULL,
    Model NVARCHAR(80) NOT NULL,
    BatteryCapacityKWh DECIMAL(8,2) NULL,
    PreferredConnectorTypeID INT NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT FK_Vehicle_User FOREIGN KEY (UserID) REFERENCES [Identity].UserAccount(UserID),
    CONSTRAINT FK_Vehicle_Connector FOREIGN KEY (PreferredConnectorTypeID) REFERENCES Infrastructure.ConnectorType(ConnectorTypeID),
    CONSTRAINT CK_Vehicle_Battery CHECK (BatteryCapacityKWh IS NULL OR BatteryCapacityKWh > 0)
);
GO

CREATE TABLE Operations.PricingPolicy
(
    PolicyID INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_PricingPolicy PRIMARY KEY,
    PolicyCode NVARCHAR(30) NOT NULL CONSTRAINT UQ_PricingPolicy_Code UNIQUE,
    PolicyName NVARCHAR(150) NOT NULL,
    BasePricePerKWh DECIMAL(19,4) NOT NULL,
    PeakMultiplier DECIMAL(5,2) NOT NULL DEFAULT 1.20,
    PeakStartHour TIME(0) NULL,
    PeakEndHour TIME(0) NULL,
    AppliedFrom DATETIME2 NOT NULL,
    AppliedTo DATETIME2 NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    CONSTRAINT CK_PricingPolicy_Price CHECK (BasePricePerKWh >= 0),
    CONSTRAINT CK_PricingPolicy_Multiplier CHECK (PeakMultiplier >= 1),
    CONSTRAINT CK_PricingPolicy_Date CHECK (AppliedTo IS NULL OR AppliedFrom < AppliedTo)
);
GO

CREATE TABLE Operations.Booking
(
    BookingID BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Booking PRIMARY KEY,
    BookingCode NVARCHAR(40) NOT NULL CONSTRAINT UQ_Booking_Code UNIQUE,
    UserID INT NOT NULL,
    VehicleID INT NULL,
    StationID INT NOT NULL,
    PointID INT NOT NULL,
    BookedFrom DATETIME2 NOT NULL,
    BookedTo DATETIME2 NOT NULL,
    BookingStatus NVARCHAR(20) NOT NULL DEFAULT N'Pending',
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt DATETIME2 NULL,
    CONSTRAINT FK_Booking_User FOREIGN KEY (UserID) REFERENCES [Identity].UserAccount(UserID),
    CONSTRAINT FK_Booking_Vehicle FOREIGN KEY (VehicleID) REFERENCES Operations.Vehicle(VehicleID),
    CONSTRAINT FK_Booking_Station FOREIGN KEY (StationID) REFERENCES Infrastructure.ChargingStation(StationID),
    CONSTRAINT FK_Booking_Point FOREIGN KEY (PointID) REFERENCES Infrastructure.ChargingPoint(PointID),
    CONSTRAINT CK_Booking_Time CHECK (BookedFrom < BookedTo),
    CONSTRAINT CK_Booking_Status CHECK (BookingStatus IN (N'Pending', N'Confirmed', N'Active', N'Completed', N'Cancelled', N'Expired'))
);
GO

CREATE TABLE Operations.ChargingSession
(
    SessionID BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_ChargingSession PRIMARY KEY,
    SessionCode NVARCHAR(40) NOT NULL CONSTRAINT UQ_ChargingSession_Code UNIQUE,
    UserID INT NOT NULL,
    VehicleID INT NULL,
    StationID INT NOT NULL,
    PointID INT NOT NULL,
    PolicyID INT NOT NULL,
    BookingID BIGINT NULL,
    StartTime DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    EndTime DATETIME2 NULL,
    MeterStart DECIMAL(14,4) NULL,
    MeterEnd DECIMAL(14,4) NULL,
    TotalKWh DECIMAL(14,4) NULL,
    DurationMinutes INT NULL,
    CostBeforeTax DECIMAL(19,4) NULL,
    TaxAmount DECIMAL(19,4) NOT NULL DEFAULT 0,
    CostTotal DECIMAL(19,4) NULL,
    SessionStatus NVARCHAR(30) NOT NULL DEFAULT N'Charging',
    StopReason NVARCHAR(60) NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt DATETIME2 NULL,
    CONSTRAINT FK_ChargingSession_User FOREIGN KEY (UserID) REFERENCES [Identity].UserAccount(UserID),
    CONSTRAINT FK_ChargingSession_Vehicle FOREIGN KEY (VehicleID) REFERENCES Operations.Vehicle(VehicleID),
    CONSTRAINT FK_ChargingSession_Station FOREIGN KEY (StationID) REFERENCES Infrastructure.ChargingStation(StationID),
    CONSTRAINT FK_ChargingSession_Point FOREIGN KEY (PointID) REFERENCES Infrastructure.ChargingPoint(PointID),
    CONSTRAINT FK_ChargingSession_Policy FOREIGN KEY (PolicyID) REFERENCES Operations.PricingPolicy(PolicyID),
    CONSTRAINT FK_ChargingSession_Booking FOREIGN KEY (BookingID) REFERENCES Operations.Booking(BookingID),
    CONSTRAINT CK_ChargingSession_Status CHECK (SessionStatus IN (N'Pending', N'Charging', N'Completed', N'Cancelled', N'Failed', N'EmergencyStopped')),
    CONSTRAINT CK_ChargingSession_KWh CHECK (TotalKWh IS NULL OR TotalKWh >= 0),
    CONSTRAINT CK_ChargingSession_Cost CHECK (CostTotal IS NULL OR CostTotal >= 0),
    CONSTRAINT CK_ChargingSession_Time CHECK (EndTime IS NULL OR StartTime <= EndTime)
);
GO

CREATE TABLE Operations.SessionEvent
(
    SessionEventID BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_SessionEvent PRIMARY KEY,
    SessionID BIGINT NOT NULL,
    EventType NVARCHAR(40) NOT NULL,
    EventPayload NVARCHAR(MAX) NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT FK_SessionEvent_Session FOREIGN KEY (SessionID) REFERENCES Operations.ChargingSession(SessionID)
);
GO

CREATE TABLE Payments.PaymentTransaction
(
    TransactionID BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_PaymentTransaction PRIMARY KEY,
    TransactionCode NVARCHAR(40) NOT NULL CONSTRAINT UQ_PaymentTransaction_Code UNIQUE,
    UserID INT NOT NULL,
    SessionID BIGINT NOT NULL,
    PaymentMethod NVARCHAR(30) NOT NULL DEFAULT N'CASH',
    Amount DECIMAL(19,4) NOT NULL,
    TransactionStatus NVARCHAR(20) NOT NULL DEFAULT N'Pending',
    ProviderReference NVARCHAR(100) NULL,
    Description NVARCHAR(500) NULL,
    PaidAt DATETIME2 NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT FK_PaymentTransaction_User FOREIGN KEY (UserID) REFERENCES [Identity].UserAccount(UserID),
    CONSTRAINT FK_PaymentTransaction_Session FOREIGN KEY (SessionID) REFERENCES Operations.ChargingSession(SessionID),
    CONSTRAINT CK_PaymentTransaction_Amount CHECK (Amount >= 0),
    CONSTRAINT CK_PaymentTransaction_Method CHECK (PaymentMethod IN (N'CASH', N'QR', N'BANK_TRANSFER')),
    CONSTRAINT CK_PaymentTransaction_Status CHECK (TransactionStatus IN (N'Pending', N'Completed', N'Failed', N'Cancelled', N'Refunded'))
);
GO

CREATE TABLE Payments.Invoice
(
    InvoiceID BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Invoice PRIMARY KEY,
    InvoiceCode NVARCHAR(40) NOT NULL CONSTRAINT UQ_Invoice_Code UNIQUE,
    UserID INT NOT NULL,
    SessionID BIGINT NOT NULL,
    TransactionID BIGINT NULL,
    Subtotal DECIMAL(19,4) NOT NULL,
    TaxAmount DECIMAL(19,4) NOT NULL DEFAULT 0,
    TotalAmount DECIMAL(19,4) NOT NULL,
    InvoiceStatus NVARCHAR(20) NOT NULL DEFAULT N'Issued',
    IssuedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT FK_Invoice_User FOREIGN KEY (UserID) REFERENCES [Identity].UserAccount(UserID),
    CONSTRAINT FK_Invoice_Session FOREIGN KEY (SessionID) REFERENCES Operations.ChargingSession(SessionID),
    CONSTRAINT FK_Invoice_Transaction FOREIGN KEY (TransactionID) REFERENCES Payments.PaymentTransaction(TransactionID),
    CONSTRAINT CK_Invoice_Amount CHECK (Subtotal >= 0 AND TaxAmount >= 0 AND TotalAmount >= 0),
    CONSTRAINT CK_Invoice_Status CHECK (InvoiceStatus IN (N'Issued', N'Paid', N'Cancelled', N'Refunded'))
);
GO

CREATE TABLE Franchise.RevenueSharePolicy
(
    RevenueSharePolicyID INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_RevenueSharePolicy PRIMARY KEY,
    ContractID INT NOT NULL,
    PolicyCode NVARCHAR(40) NOT NULL CONSTRAINT UQ_RevenueSharePolicy_Code UNIQUE,
    PartnerShareRate DECIMAL(5,2) NOT NULL,
    PlatformShareRate AS (CONVERT(DECIMAL(5,2), 100.00 - PartnerShareRate)),
    AppliedFrom DATE NOT NULL,
    AppliedTo DATE NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    CONSTRAINT FK_RevenueSharePolicy_Contract FOREIGN KEY (ContractID) REFERENCES Franchise.FranchiseContract(ContractID),
    CONSTRAINT CK_RevenueSharePolicy_Rate CHECK (PartnerShareRate BETWEEN 0 AND 100),
    CONSTRAINT CK_RevenueSharePolicy_Date CHECK (AppliedTo IS NULL OR AppliedFrom < AppliedTo)
);
GO

CREATE TABLE Franchise.RevenueShareSettlement
(
    SettlementID BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_RevenueShareSettlement PRIMARY KEY,
    SettlementCode NVARCHAR(40) NOT NULL CONSTRAINT UQ_RevenueShareSettlement_Code UNIQUE,
    FranchiseID INT NOT NULL,
    ContractID INT NOT NULL,
    PeriodStart DATE NOT NULL,
    PeriodEnd DATE NOT NULL,
    GrossRevenue DECIMAL(19,4) NOT NULL,
    PartnerShareAmount DECIMAL(19,4) NOT NULL,
    PlatformShareAmount DECIMAL(19,4) NOT NULL,
    SettlementStatus NVARCHAR(20) NOT NULL DEFAULT N'Draft',
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    ApprovedAt DATETIME2 NULL,
    CONSTRAINT FK_RevenueShareSettlement_Franchise FOREIGN KEY (FranchiseID) REFERENCES Franchise.FranchisePartner(FranchiseID),
    CONSTRAINT FK_RevenueShareSettlement_Contract FOREIGN KEY (ContractID) REFERENCES Franchise.FranchiseContract(ContractID),
    CONSTRAINT CK_RevenueShareSettlement_Date CHECK (PeriodStart <= PeriodEnd),
    CONSTRAINT CK_RevenueShareSettlement_Amount CHECK (GrossRevenue >= 0 AND PartnerShareAmount >= 0 AND PlatformShareAmount >= 0),
    CONSTRAINT CK_RevenueShareSettlement_Status CHECK (SettlementStatus IN (N'Draft', N'Approved', N'Paid', N'Cancelled'))
);
GO

CREATE TABLE Maintenance.ErrorLog
(
    ErrorID BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_ErrorLog PRIMARY KEY,
    ErrorCode NVARCHAR(30) NULL,
    StationID INT NULL,
    PointID INT NULL,
    Severity NVARCHAR(20) NOT NULL DEFAULT N'Medium',
    Description NVARCHAR(500) NOT NULL,
    OccurredAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    ResolvedAt DATETIME2 NULL,
    ResolvedBy INT NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    CONSTRAINT FK_ErrorLog_Station FOREIGN KEY (StationID) REFERENCES Infrastructure.ChargingStation(StationID),
    CONSTRAINT FK_ErrorLog_Point FOREIGN KEY (PointID) REFERENCES Infrastructure.ChargingPoint(PointID),
    CONSTRAINT FK_ErrorLog_ResolvedBy FOREIGN KEY (ResolvedBy) REFERENCES [Identity].UserAccount(UserID),
    CONSTRAINT CK_ErrorLog_Severity CHECK (Severity IN (N'Low', N'Medium', N'High', N'Critical'))
);
GO

CREATE TABLE Maintenance.MaintenanceTicket
(
    TicketID BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_MaintenanceTicket PRIMARY KEY,
    TicketCode NVARCHAR(40) NOT NULL CONSTRAINT UQ_MaintenanceTicket_Code UNIQUE,
    StationID INT NULL,
    PointID INT NULL,
    ErrorID BIGINT NULL,
    CreatedBy INT NOT NULL,
    AssignedTo INT NULL,
    Priority NVARCHAR(20) NOT NULL DEFAULT N'Medium',
    TicketStatus NVARCHAR(20) NOT NULL DEFAULT N'Open',
    Title NVARCHAR(200) NOT NULL,
    Description NVARCHAR(1000) NULL,
    OpenedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    ClosedAt DATETIME2 NULL,
    CONSTRAINT FK_MaintenanceTicket_Station FOREIGN KEY (StationID) REFERENCES Infrastructure.ChargingStation(StationID),
    CONSTRAINT FK_MaintenanceTicket_Point FOREIGN KEY (PointID) REFERENCES Infrastructure.ChargingPoint(PointID),
    CONSTRAINT FK_MaintenanceTicket_Error FOREIGN KEY (ErrorID) REFERENCES Maintenance.ErrorLog(ErrorID),
    CONSTRAINT FK_MaintenanceTicket_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES [Identity].UserAccount(UserID),
    CONSTRAINT FK_MaintenanceTicket_AssignedTo FOREIGN KEY (AssignedTo) REFERENCES [Identity].UserAccount(UserID),
    CONSTRAINT CK_MaintenanceTicket_Priority CHECK (Priority IN (N'Low', N'Medium', N'High', N'Critical')),
    CONSTRAINT CK_MaintenanceTicket_Status CHECK (TicketStatus IN (N'Open', N'Assigned', N'InProgress', N'Resolved', N'Closed', N'Cancelled'))
);
GO

CREATE TABLE Audit.AuditLog
(
    AuditID BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_AuditLog PRIMARY KEY,
    SchemaName SYSNAME NOT NULL,
    TableName SYSNAME NOT NULL,
    RecordID NVARCHAR(100) NULL,
    ActionType NVARCHAR(20) NOT NULL,
    OldValues NVARCHAR(MAX) NULL,
    NewValues NVARCHAR(MAX) NULL,
    ChangedBy NVARCHAR(128) NULL DEFAULT ORIGINAL_LOGIN(),
    ChangedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT CK_AuditLog_Action CHECK (ActionType IN (N'INSERT', N'UPDATE', N'DELETE', N'PAYMENT', N'SETTLEMENT', N'SECURITY'))
);
GO

PRINT N'02 - Simplified tables created.';
GO
