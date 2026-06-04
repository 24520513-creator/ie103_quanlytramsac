==============================================================================
-- 4.2.5 Nhom Stored Procedure quan ly ha tang tram sac
==============================================================================


==============================================================================
-- Infrastructure.sp_CreateChargingStation
==============================================================================

--database/05_Create_Stored_Procedures.sql
CREATE OR ALTER PROCEDURE Infrastructure.sp_CreateChargingStation
    @StationCode NVARCHAR(30),
    @StationName NVARCHAR(200),
    @FranchiseID INT,
    @AddressID INT,
    @SupplierID INT = NULL,
    @StationOperatorID INT = NULL,
    @MaxPowerKW DECIMAL(8,2)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO Infrastructure.ChargingStation
            (StationCode, StationName, FranchiseID, AddressID, SupplierID, StationOperatorID, MaxPowerKW, StationStatus, OpenedAt)
        VALUES
            (@StationCode, @StationName, @FranchiseID, @AddressID, @SupplierID, @StationOperatorID, @MaxPowerKW, N'Active', CAST(SYSDATETIME() AS DATE));

        DECLARE @StationID INT = SCOPE_IDENTITY();

        INSERT INTO Audit.AuditLog (SchemaName, TableName, RecordID, ActionType, NewValues)
        VALUES (N'Infrastructure', N'ChargingStation', CAST(@StationID AS NVARCHAR(100)), N'INSERT', @StationCode);

        COMMIT TRANSACTION;

        SELECT StationID, StationCode, StationName, StationStatus
        FROM Infrastructure.ChargingStation
        WHERE StationID = @StationID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- >>> TEST: source kiem thu tinh nang
-- (Demo test soan rieng cho bao cao - SP nay khong co file feature test rieng)
USE EV_Charging_System;
GO
-- TEST: Tao tram sac moi (gan voi franchise partner + dia chi co san).
-- Bao trong giao dich + ROLLBACK de khong chen tram rac vao DB.
BEGIN TRAN;
    DECLARE @FranchiseID INT = (SELECT TOP 1 FranchiseID FROM Franchise.FranchisePartner ORDER BY FranchiseID);
    DECLARE @AddressID   INT = (SELECT TOP 1 AddressID   FROM Core.Address ORDER BY AddressID);
    EXEC Infrastructure.sp_CreateChargingStation
         @StationCode = N'ST-DEMO-01',
         @StationName = N'Tram Sac Demo Quan 1',
         @FranchiseID = @FranchiseID,
         @AddressID   = @AddressID,
         @MaxPowerKW  = 150.00;
    -- Ket qua mong doi: tra ve tram vua tao voi StationStatus = 'Active'.
ROLLBACK;   -- huy thay doi demo


==============================================================================
-- Infrastructure.sp_CreateChargingPoint
==============================================================================

--database/05_Create_Stored_Procedures.sql
CREATE OR ALTER PROCEDURE Infrastructure.sp_CreateChargingPoint
    @PointCode NVARCHAR(40),
    @StationID INT,
    @ConnectorTypeID INT,
    @PowerKW DECIMAL(8,2),
    @SerialNumber NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO Infrastructure.ChargingPoint
            (PointCode, StationID, ConnectorTypeID, PowerKW, SerialNumber, PointStatus)
        VALUES
            (@PointCode, @StationID, @ConnectorTypeID, @PowerKW, @SerialNumber, N'Available');

        DECLARE @PointID INT = SCOPE_IDENTITY();

        IF NOT EXISTS (
            SELECT 1 FROM Infrastructure.StationConnectorType
            WHERE StationID = @StationID AND ConnectorTypeID = @ConnectorTypeID
        )
        BEGIN
            INSERT INTO Infrastructure.StationConnectorType (StationID, ConnectorTypeID)
            VALUES (@StationID, @ConnectorTypeID);
        END;

        INSERT INTO Audit.AuditLog (SchemaName, TableName, RecordID, ActionType, NewValues)
        VALUES (N'Infrastructure', N'ChargingPoint', CAST(@PointID AS NVARCHAR(100)), N'INSERT', @PointCode);

        COMMIT TRANSACTION;

        SELECT PointID, PointCode, StationID, ConnectorTypeID, PowerKW, PointStatus
        FROM Infrastructure.ChargingPoint
        WHERE PointID = @PointID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- >>> TEST: source kiem thu tinh nang
-- (Demo test soan rieng cho bao cao - SP nay khong co file feature test rieng)
USE EV_Charging_System;
GO
-- TEST: Them tru sac vao mot tram da co.
-- Bao trong giao dich + ROLLBACK de khong chen tru sac rac vao DB.
BEGIN TRAN;
    DECLARE @StationID INT = (SELECT TOP 1 StationID FROM Infrastructure.ChargingStation ORDER BY StationID DESC);
    DECLARE @ConnID    INT = (SELECT TOP 1 ConnectorTypeID FROM Infrastructure.ConnectorType ORDER BY ConnectorTypeID);
    EXEC Infrastructure.sp_CreateChargingPoint
         @PointCode       = N'CP-DEMO-01',
         @StationID       = @StationID,
         @ConnectorTypeID = @ConnID,
         @PowerKW         = 60.00,
         @SerialNumber    = N'SN-DEMO-0001';
    -- Ket qua mong doi: tao tru sac moi voi trang thai 'Available'.
ROLLBACK;   -- huy thay doi demo


==============================================================================
-- Infrastructure.sp_UpdateStationStatus
==============================================================================

--database/05_Create_Stored_Procedures.sql
CREATE OR ALTER PROCEDURE Infrastructure.sp_UpdateStationStatus
    @StationID INT,
    @StationStatus NVARCHAR(30),
    @ChangedBy INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF @StationStatus NOT IN (N'Active', N'Inactive', N'UnderMaintenance', N'Retired')
            THROW 51020, 'Invalid station status.', 1;

        IF NOT EXISTS (SELECT 1 FROM Infrastructure.ChargingStation WHERE StationID = @StationID)
            THROW 51021, 'Charging station does not exist.', 1;

        UPDATE Infrastructure.ChargingStation
        SET StationStatus = @StationStatus, UpdatedAt = SYSDATETIME()
        WHERE StationID = @StationID;

        INSERT INTO Audit.AuditLog (SchemaName, TableName, RecordID, ActionType, NewValues, ChangedBy)
        VALUES (N'Infrastructure', N'ChargingStation', CAST(@StationID AS NVARCHAR(100)), N'UPDATE', @StationStatus, COALESCE(CAST(@ChangedBy AS NVARCHAR(128)), ORIGINAL_LOGIN()));

        COMMIT TRANSACTION;

        SELECT StationID, StationCode, StationName, StationStatus
        FROM Infrastructure.ChargingStation
        WHERE StationID = @StationID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- >>> TEST: source kiem thu tinh nang
-- (Trich tu database/features/operations_staff/02_update_station_status.sql)
USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: cap nhat trang thai tram de demo van hanh.
- Tham so co the sua: @StationID, @StationStatus, @OperatorID.
- Trang thai hop le: Active, Inactive, UnderMaintenance, Retired.
- Tac dong du lieu: SUA THAT ChargingStation; script doi sang UnderMaintenance roi doi lai Active.
*/

PRINT N'Cập nhật trạng thái trạm: nhân viên vận hành chuyển trạng thái trạm và ghi nhận thay đổi vào audit.';

DECLARE @StationID INT = (SELECT TOP 1 StationID FROM Infrastructure.ChargingStation WHERE StationStatus = N'Active' ORDER BY StationID);
DECLARE @OperatorID INT = (SELECT UserID FROM [Identity].UserAccount WHERE Username = N'operator01');

SELECT StationID, StationCode, StationName, StationStatus
FROM Infrastructure.ChargingStation
WHERE StationID = @StationID;

EXEC Infrastructure.sp_UpdateStationStatus
    @StationID = @StationID,
    @StationStatus = N'UnderMaintenance',
    @ChangedBy = @OperatorID;

SELECT StationID, StationCode, StationName, StationStatus
FROM Infrastructure.ChargingStation
WHERE StationID = @StationID;

EXEC Infrastructure.sp_UpdateStationStatus
    @StationID = @StationID,
    @StationStatus = N'Active',
    @ChangedBy = @OperatorID;
GO



==============================================================================
-- Infrastructure.sp_UpdateChargingPointStatus
==============================================================================

--database/05_Create_Stored_Procedures.sql
CREATE OR ALTER PROCEDURE Infrastructure.sp_UpdateChargingPointStatus
    @PointID INT,
    @PointStatus NVARCHAR(30),
    @HealthStatus NVARCHAR(20) = NULL,
    @ChangedBy INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF @PointStatus NOT IN (N'Available', N'Reserved', N'Charging', N'Offline', N'Error', N'Maintenance', N'Retired')
            THROW 51030, 'Invalid charging point status.', 1;
        IF @HealthStatus IS NOT NULL AND @HealthStatus NOT IN (N'Normal', N'Warning', N'Critical', N'Offline')
            THROW 51031, 'Invalid health status.', 1;
        IF NOT EXISTS (SELECT 1 FROM Infrastructure.ChargingPoint WHERE PointID = @PointID)
            THROW 51032, 'Charging point does not exist.', 1;

        UPDATE Infrastructure.ChargingPoint
        SET PointStatus = @PointStatus,
            HealthStatus = COALESCE(@HealthStatus, HealthStatus),
            UpdatedAt = SYSDATETIME()
        WHERE PointID = @PointID;

        INSERT INTO Audit.AuditLog (SchemaName, TableName, RecordID, ActionType, NewValues, ChangedBy)
        VALUES (N'Infrastructure', N'ChargingPoint', CAST(@PointID AS NVARCHAR(100)), N'UPDATE', @PointStatus, COALESCE(CAST(@ChangedBy AS NVARCHAR(128)), ORIGINAL_LOGIN()));

        COMMIT TRANSACTION;

        SELECT PointID, PointCode, PointStatus, HealthStatus
        FROM Infrastructure.ChargingPoint
        WHERE PointID = @PointID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- >>> TEST: source kiem thu tinh nang
-- (Trich tu database/features/operations_staff/03_update_point_status.sql)
USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: cap nhat trang thai cong sac va kiem tra lich su trang thai.
- Tham so co the sua: @PointID, @PointStatus, @HealthStatus, @OperatorID.
- Tac dong du lieu: SUA THAT ChargingPoint; trigger tao PointStatusHistory va AuditLog.
*/

PRINT N'Cập nhật trạng thái cổng sạc: nhân viên vận hành đổi trạng thái cổng và kiểm tra lịch sử trạng thái.';

DECLARE @PointID INT = (SELECT TOP 1 PointID FROM Infrastructure.ChargingPoint WHERE PointStatus = N'Available' ORDER BY PointID);
DECLARE @OperatorID INT = (SELECT UserID FROM [Identity].UserAccount WHERE Username = N'operator01');

SELECT PointID, PointCode, PointStatus, HealthStatus
FROM Infrastructure.ChargingPoint
WHERE PointID = @PointID;

EXEC Infrastructure.sp_UpdateChargingPointStatus
    @PointID = @PointID,
    @PointStatus = N'Offline',
    @HealthStatus = N'Offline',
    @ChangedBy = @OperatorID;

SELECT TOP 5 *
FROM Infrastructure.PointStatusHistory
WHERE PointID = @PointID
ORDER BY ChangedAt DESC;

EXEC Infrastructure.sp_UpdateChargingPointStatus
    @PointID = @PointID,
    @PointStatus = N'Available',
    @HealthStatus = N'Normal',
    @ChangedBy = @OperatorID;

SELECT PointID, PointCode, PointStatus, HealthStatus
FROM Infrastructure.ChargingPoint
WHERE PointID = @PointID;
GO
