USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: chung minh transaction rollback khi co loi giua chung.
- Tham so co the sua: @UserID, @ConnectorTypeID, @PlateNumber.
- Tac dong du lieu: KHONG DE LAI VEHICLE MOI vi transaction bi rollback.
*/

PRINT N'Kiểm thử rollback transaction: lỗi cưỡng bức làm toàn bộ thao tác tạo dữ liệu dở bị hủy.';

DECLARE @UserID INT = (SELECT UserID FROM [Identity].UserAccount WHERE Username = N'customer04');
DECLARE @ConnectorTypeID INT = (SELECT TOP 1 ConnectorTypeID FROM Infrastructure.ConnectorType WHERE ConnectorCode = N'CCS2');
DECLARE @PlateNumber NVARCHAR(20) = N'FEATURE-DEMO-ROLLBK';

SELECT COUNT(*) AS VehicleCountBefore
FROM Operations.Vehicle
WHERE PlateNumber = @PlateNumber;

BEGIN TRY
    BEGIN TRANSACTION;

    EXEC Operations.sp_CreateVehicle
        @UserID = @UserID,
        @PlateNumber = @PlateNumber,
        @Brand = N'VinFast',
        @Model = N'VF 9',
        @BatteryCapacityKWh = 92.00,
        @PreferredConnectorTypeID = @ConnectorTypeID;

    THROW 59999, 'FEATURE-DEMO forced error after vehicle creation.', 1;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    PRINT N'Expected error: forced error caused rollback.';
    SELECT ERROR_MESSAGE() AS ExpectedError;
END CATCH;

SELECT COUNT(*) AS VehicleCountAfterRollback
FROM Operations.Vehicle
WHERE PlateNumber = @PlateNumber;
GO



