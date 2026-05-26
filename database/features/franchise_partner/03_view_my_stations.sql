USE EV_Charging_System;
GO

/*
HUONG DAN SU DUNG
- Muc dich: Franchise Partner xem cac tram thuoc franchise cua chinh minh.
- Khong can sua tham so, co the doi franchise01 thanh franchise02..franchise08.
- Tac dong du lieu: CHI DOC DU LIEU.
*/

PRINT N'Franchise Partner xem các trạm thuộc franchise của chính mình.';

EXECUTE AS USER = 'franchise01';

SELECT USER_NAME() AS CurrentDatabaseUser;

EXEC AppView.sp_GetMyFranchiseStations;

REVERT;
GO

