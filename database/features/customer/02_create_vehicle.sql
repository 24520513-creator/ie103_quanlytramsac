USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: them xe moi cho customer01.
- Tham so co the sua: @UserID, @PlateNumber, @Brand, @Model, @BatteryCapacityKWh, @ConnectorTypeID.
- @PlateNumber phai la duy nhat; script dang tu sinh bien so demo de tranh trung.
- Tac dong du lieu: THEM THAT 1 dong vao Operations.Vehicle thong qua Operations.sp_CreateVehicle.
*/

PRINT N'Thêm xe: khách hàng tạo hồ sơ xe mới bằng stored procedure với tham số rõ ràng.';

DECLARE @UserID INT = (SELECT UserID FROM [Identity].UserAccount WHERE Username = N'customer01');
DECLARE @ConnectorTypeID INT = (SELECT TOP 1 ConnectorTypeID FROM Infrastructure.ConnectorType WHERE ConnectorCode = N'CCS2');
DECLARE @PlateNumber NVARCHAR(20) = N'FEATURE-DEMO-' + RIGHT(REPLACE(CONVERT(NVARCHAR(36), NEWID()), N'-', N''), 7);

SELECT VehicleID, PlateNumber, Brand, Model, IsActive
FROM Operations.Vehicle
WHERE UserID = @UserID;

EXEC Operations.sp_CreateVehicle
    @UserID = @UserID,
    @PlateNumber = @PlateNumber,
    @Brand = N'VinFast',
    @Model = N'VF 8',
    @BatteryCapacityKWh = 82.00,
    @PreferredConnectorTypeID = @ConnectorTypeID;

SELECT VehicleID, PlateNumber, Brand, Model, BatteryCapacityKWh, IsActive
FROM Operations.Vehicle
WHERE UserID = @UserID
ORDER BY VehicleID DESC;
GO



