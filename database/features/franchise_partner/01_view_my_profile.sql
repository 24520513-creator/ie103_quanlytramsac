USE EV_Charging_System;
GO

/*
HUONG DAN SU DUNG
- Muc dich: Franchise Partner xem ho so doi tac cua chinh minh.
- Khong can sua tham so, co the doi franchise01 thanh franchise02..franchise08.
- Tac dong du lieu: CHI DOC DU LIEU.
*/

PRINT N'Franchise Partner xem hồ sơ franchise của chính mình.';

EXECUTE AS USER = 'franchise01';

SELECT USER_NAME() AS CurrentDatabaseUser;

EXEC AppView.sp_GetMyFranchiseProfile;

REVERT;
GO

