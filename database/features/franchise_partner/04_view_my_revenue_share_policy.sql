USE EV_Charging_System;
GO

/*
HUONG DAN SU DUNG
- Muc dich: Franchise Partner xem chinh sach chia doanh thu cua chinh minh.
- Khong can sua tham so, co the doi franchise01 thanh franchise02..franchise08.
- Tac dong du lieu: CHI DOC DU LIEU.
*/

PRINT N'Franchise Partner xem revenue share policy của chính mình.';

EXECUTE AS USER = 'franchise01';

SELECT USER_NAME() AS CurrentDatabaseUser;

EXEC AppView.sp_GetMyRevenueSharePolicies;

REVERT;
GO

