USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: demo soft delete tren Vehicle.
- Tham so co the sua: @UserID, @VehicleID.
- Tac dong du lieu: KHONG XOA VAT LY; doi IsActive = 0 roi tra lai IsActive = 1.
*/

PRINT N'Kiểm tra soft delete: vô hiệu hóa xe bằng IsActive thay vì xóa vật lý khỏi database.';

DECLARE @UserID INT = (SELECT UserID FROM [Identity].UserAccount WHERE Username = N'customer01');
DECLARE @VehicleID INT = (SELECT TOP 1 VehicleID FROM Operations.Vehicle WHERE UserID = @UserID ORDER BY VehicleID DESC);

SELECT VehicleID, PlateNumber, Brand, Model, IsActive
FROM Operations.Vehicle
WHERE VehicleID = @VehicleID;

EXEC Operations.sp_UpdateVehicle
    @VehicleID = @VehicleID,
    @UserID = @UserID,
    @IsActive = 0;

SELECT VehicleID, PlateNumber, Brand, Model, IsActive
FROM Operations.Vehicle
WHERE VehicleID = @VehicleID;

EXEC Operations.sp_UpdateVehicle
    @VehicleID = @VehicleID,
    @UserID = @UserID,
    @IsActive = 1;
GO



