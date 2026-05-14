USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: cap nhat xe gan nhat cua customer01.
- Tham so co the sua: @UserID, @VehicleID, @Model, @BatteryCapacityKWh, @IsActive.
- @VehicleID phai thuoc dung @UserID, neu khong procedure se bao loi.
- Tac dong du lieu: SUA THAT Operations.Vehicle, khong tao dong moi.
*/

PRINT N'Cập nhật xe: khách hàng chỉnh sửa thông tin xe và trạng thái sử dụng của xe.';

DECLARE @UserID INT = (SELECT UserID FROM [Identity].UserAccount WHERE Username = N'customer01');
DECLARE @VehicleID INT = (SELECT TOP 1 VehicleID FROM Operations.Vehicle WHERE UserID = @UserID ORDER BY VehicleID DESC);

SELECT VehicleID, PlateNumber, Brand, Model, BatteryCapacityKWh, IsActive
FROM Operations.Vehicle
WHERE VehicleID = @VehicleID;

EXEC Operations.sp_UpdateVehicle
    @VehicleID = @VehicleID,
    @UserID = @UserID,
    @Model = N'VF 8 Plus',
    @BatteryCapacityKWh = 87.70,
    @IsActive = 1;

SELECT VehicleID, PlateNumber, Brand, Model, BatteryCapacityKWh, IsActive
FROM Operations.Vehicle
WHERE VehicleID = @VehicleID;
GO



