/*=============================================================================
  EV_Charging_System - CREATE ALL TABLES
  =============================================================================*/

USE EV_Charging_System;
GO

-- ========================================
-- Infrastructure.Franchisee
-- ========================================
CREATE TABLE Infrastructure.Franchisee
(
    FranchiseeID      INT            IDENTITY(1,1) NOT NULL,
    FranchiseeName    NVARCHAR(100)  NOT NULL,
    TaxCode           NVARCHAR(20)   NOT NULL,
    ContactPerson     NVARCHAR(50)   NULL,
    Phone             NVARCHAR(20)   NULL,
    Email             NVARCHAR(50)   NULL,
    RevenueShareRate  DECIMAL(5,2)   NOT NULL,
    ContractDate      DATETIME2      NOT NULL,

    CONSTRAINT PK_Franchisee
        PRIMARY KEY (FranchiseeID),

    CONSTRAINT UQ_Franchisee_TaxCode
        UNIQUE (TaxCode),

    CONSTRAINT UQ_Franchisee_Phone
        UNIQUE (Phone),

    CONSTRAINT UQ_Franchisee_Email
        UNIQUE (Email),

    CONSTRAINT CK_Franchisee_RevenueShareRate
        CHECK (RevenueShareRate BETWEEN 0 AND 100)
);
GO

-- ========================================
-- Infrastructure.ElectricitySuppliers
-- ========================================
CREATE TABLE Infrastructure.ElectricitySuppliers
(
    SupplierID    INT            IDENTITY(1,1) NOT NULL,
    SupplierName  NVARCHAR(50)   NOT NULL,
    UnitPrice_kWh DECIMAL(19,4) NOT NULL,
    Region        NVARCHAR(20)   NOT NULL,
    ContactInfo   NVARCHAR(50)   NULL,

    CONSTRAINT PK_ElectricitySuppliers
        PRIMARY KEY (SupplierID),

    CONSTRAINT CK_ElectricitySuppliers_UnitPrice_kWh
        CHECK (UnitPrice_kWh >= 0),

    CONSTRAINT CK_ElectricitySuppliers_Region
        CHECK (Region IN (N'Bắc', N'Trung', N'Nam'))
);
GO

-- ========================================
-- Infrastructure.ChargingStation
-- ========================================
CREATE TABLE Infrastructure.ChargingStation
(
    StationID      INT            IDENTITY(1,1) NOT NULL,
    FranchiseeID   INT            NOT NULL,
    SupplierID     INT            NOT NULL,
    StationName    NVARCHAR(100)  NOT NULL,
    Address        NVARCHAR(250)  NULL,
    StationStatus  NVARCHAR(20)   NOT NULL,

    CONSTRAINT PK_ChargingStation
        PRIMARY KEY (StationID),

    CONSTRAINT CK_ChargingStation_StationStatus
        CHECK (StationStatus IN (N'Hoạt động', N'Không hoạt động', N'Bảo trì')),

    CONSTRAINT FK_ChargingStation_Franchisee
        FOREIGN KEY (FranchiseeID)
        REFERENCES Infrastructure.Franchisee (FranchiseeID),

    CONSTRAINT FK_ChargingStation_ElectricitySuppliers
        FOREIGN KEY (SupplierID)
        REFERENCES Infrastructure.ElectricitySuppliers (SupplierID)
);
GO

-- ========================================
-- Infrastructure.ChargingPoint
-- ========================================
CREATE TABLE Infrastructure.ChargingPoint
(
    PointID        INT            IDENTITY(1,1) NOT NULL,
    StationID      INT            NOT NULL,
    Power_kW       DECIMAL(7,2)   NOT NULL,
    ConnectorType  NVARCHAR(20)   NULL,
    PointStatus    NVARCHAR(20)   NOT NULL DEFAULT N'Khả dụng',

    CONSTRAINT PK_ChargingPoint
        PRIMARY KEY (PointID),

    CONSTRAINT CK_ChargingPoint_Power_kW
        CHECK (Power_kW >= 0),

    CONSTRAINT CK_ChargingPoint_PointStatus
        CHECK (PointStatus IN (N'Khả dụng', N'Đang bận', N'Đang lỗi', N'Đã tắt')),

    CONSTRAINT FK_ChargingPoint_ChargingStation
        FOREIGN KEY (StationID)
        REFERENCES Infrastructure.ChargingStation (StationID)
);
GO

-- ========================================
-- Users.Customers
-- ========================================
CREATE TABLE Users.Customers
(
    UserID         INT           IDENTITY(1,1) NOT NULL,
    FullName       NVARCHAR(50)  NOT NULL,
    Email          NVARCHAR(50)  NOT NULL,
    Phone          NVARCHAR(20)  NULL,
    PasswordHash   NCHAR(64)      NOT NULL,
    WalletBalance  MONEY         NOT NULL DEFAULT 0,
    AccountStatus  NVARCHAR(20)  NOT NULL DEFAULT N'Chưa mở',

    CONSTRAINT PK_Customers
        PRIMARY KEY (UserID),

    CONSTRAINT UQ_Customers_Email
        UNIQUE (Email),

    CONSTRAINT UQ_Customers_Phone
        UNIQUE (Phone),

    CONSTRAINT CK_Customers_WalletBalance
        CHECK (WalletBalance >= 0),

    CONSTRAINT CK_Customers_PasswordHash
        CHECK (LEN(PasswordHash) = 64),

    CONSTRAINT CK_Customers_AccountStatus
        CHECK (AccountStatus IN (N'Đang mở', N'Bị khóa', N'Chưa mở'))
);
GO

-- ========================================
-- Users.Vehicles
-- ========================================
CREATE TABLE Users.Vehicles
(
    VehicleID          INT           IDENTITY(1,1) NOT NULL,
    UserID             INT           NOT NULL,
    PlateNumber        VARCHAR(20)   NOT NULL,
    Brand              NVARCHAR(20)  NULL,
    Model              NVARCHAR(50)  NULL,
    BatteryCapacity_kWh DECIMAL(5,2) NULL,
    ConnectorType      NVARCHAR(20)  NULL,

    CONSTRAINT PK_Vehicles
        PRIMARY KEY (VehicleID),

    CONSTRAINT UQ_Vehicles_PlateNumber
        UNIQUE (PlateNumber),

    CONSTRAINT CK_Vehicles_BatteryCapacity_kWh
        CHECK (BatteryCapacity_kWh >= 0),

    CONSTRAINT FK_Vehicles_Customers
        FOREIGN KEY (UserID)
        REFERENCES Users.Customers (UserID)
);
GO

-- ========================================
-- Operations.PricingPolicy
-- ========================================
CREATE TABLE Operations.PricingPolicy
(
    PolicyID            INT            IDENTITY(1,1) NOT NULL,
    PolicyName          NVARCHAR(50)   NOT NULL,
    BasePrice_kWh       DECIMAL(19,4)  NOT NULL,
    PeakHourMultiplier  DECIMAL(3,2)   NOT NULL,
    AppliedFrom         DATETIME2      NOT NULL,
    AppliedTo           DATETIME2      NULL,

    CONSTRAINT PK_PricingPolicy
        PRIMARY KEY (PolicyID),

    CONSTRAINT CK_PricingPolicy_BasePrice_kWh
        CHECK (BasePrice_kWh >= 0),

    CONSTRAINT CK_PricingPolicy_PeakHourMultiplier
        CHECK (PeakHourMultiplier > 0),

    CONSTRAINT CK_PricingPolicy_AppliedRange
        CHECK (AppliedFrom < AppliedTo)
);
GO

-- ========================================
-- Operations.ChargingSession
-- ========================================
CREATE TABLE Operations.ChargingSession
(
    SessionID   BIGINT          IDENTITY(1,1) NOT NULL,
    UserID      INT             NOT NULL,
    PointID     INT             NOT NULL,
    PolicyID    INT             NOT NULL,
    StartTime   DATETIME2       NOT NULL DEFAULT SYSDATETIME(),
    EndTime     DATETIME2       NULL,
    Total_kWh   DECIMAL(13,4)   NULL,
    CostTotal   MONEY           NULL,
    Status      NVARCHAR(20)    NOT NULL DEFAULT N'Đang sạc',

    CONSTRAINT PK_ChargingSession
        PRIMARY KEY (SessionID),

    CONSTRAINT CK_ChargingSession_Total_kWh
        CHECK (Total_kWh >= 0),

    CONSTRAINT CK_ChargingSession_CostTotal
        CHECK (CostTotal >= 0),

    CONSTRAINT CK_ChargingSession_TimeRange
        CHECK (StartTime < EndTime),

    CONSTRAINT CK_ChargingSession_Status
        CHECK (Status IN (N'Đang sạc', N'Đã sạc xong')),

    CONSTRAINT FK_ChargingSession_Customers
        FOREIGN KEY (UserID)
        REFERENCES Users.Customers (UserID),

    CONSTRAINT FK_ChargingSession_ChargingPoint
        FOREIGN KEY (PointID)
        REFERENCES Infrastructure.ChargingPoint (PointID),

    CONSTRAINT FK_ChargingSession_PricingPolicy
        FOREIGN KEY (PolicyID)
        REFERENCES Operations.PricingPolicy (PolicyID)
);
GO

-- ========================================
-- Operations.Transactions
-- ========================================
CREATE TABLE Operations.Transactions
(
    TransactionID   BIGINT          IDENTITY(1,1) NOT NULL,
    UserID          INT             NOT NULL,
    SessionID       BIGINT          NOT NULL,
    Amount          MONEY           NOT NULL,
    TransactionType NVARCHAR(20)    NOT NULL,
    [Timestamp]     DATETIME2       NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT PK_Transactions
        PRIMARY KEY (TransactionID),

    CONSTRAINT CK_Transactions_Amount
        CHECK (Amount >= 0),

    CONSTRAINT CK_Transactions_Timestamp
        CHECK ([Timestamp] BETWEEN '1990-01-01' AND '2030-01-01'),

    CONSTRAINT FK_Transactions_Customers
        FOREIGN KEY (UserID)
        REFERENCES Users.Customers (UserID),

    CONSTRAINT CK_Transactions_TransactionType
        CHECK (TransactionType IN (N'Thanh toán', N'Nạp tiền', N'Hoàn tiền', N'Rút tiền')),

    CONSTRAINT FK_Transactions_ChargingSession
        FOREIGN KEY (SessionID)
        REFERENCES Operations.ChargingSession (SessionID)
);
GO

-- ========================================
-- Monitoring.ErrorLogs
-- ========================================
CREATE TABLE Monitoring.ErrorLogs
(
    ErrorID     INT            IDENTITY(1,1) NOT NULL,
    PointID     INT            NOT NULL,
    ErrorCode   NVARCHAR(20)   NOT NULL,
    Description NVARCHAR(100)  NULL,
    OccurredAt  DATETIME2      NOT NULL DEFAULT SYSDATETIME(),
    ResolvedAt  DATETIME2      NULL,
    Severity    NVARCHAR(20)   NULL,

    CONSTRAINT PK_ErrorLogs
        PRIMARY KEY (ErrorID),

    CONSTRAINT CK_ErrorLogs_ResolvedAt
        CHECK (OccurredAt < ResolvedAt),

    CONSTRAINT CK_ErrorLogs_Severity
        CHECK (Severity IN (N'Thấp', N'Trung bình', N'Cao', N'Nguy kịch')),

    CONSTRAINT FK_ErrorLogs_ChargingPoint
        FOREIGN KEY (PointID)
        REFERENCES Infrastructure.ChargingPoint (PointID)
);
GO

-- ========================================
-- Monitoring.MaintenanceSchedule
-- ========================================
CREATE TABLE Monitoring.MaintenanceSchedule
(
    ScheduleID      INT             IDENTITY(1,1) NOT NULL,
    StationID       INT             NOT NULL,
    TechnicianName  NVARCHAR(100)   NOT NULL,
    PlannedDate     DATETIME2       NOT NULL,
    ActionTaken     NVARCHAR(500)   NULL,
    Status          NVARCHAR(20)    NOT NULL DEFAULT N'Đã lên lịch',

    CONSTRAINT PK_MaintenanceSchedule
        PRIMARY KEY (ScheduleID),

    CONSTRAINT CK_MaintenanceSchedule_Status
        CHECK (Status IN (N'Đã lên lịch', N'Đang thực hiện', N'Hoàn thành', N'Hủy')),

    CONSTRAINT FK_MaintenanceSchedule_ChargingStation
        FOREIGN KEY (StationID)
        REFERENCES Infrastructure.ChargingStation (StationID)
);
GO

PRINT N'All 11 tables created successfully.';
GO
