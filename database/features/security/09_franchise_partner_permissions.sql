USE EV_Charging_System;
GO

/*
HUONG DAN SU DUNG
- Muc dich: kiem tra quyen Franchise Partner bang EXECUTE AS USER.
- Khong can sua tham so, co the doi franchise01 thanh franchise02..franchise08.
- Tac dong du lieu: CHI DOC/THU DOC DU LIEU; loi quyen duoc bat bang TRY...CATCH.
*/

PRINT N'Kiểm tra quyền Franchise Partner: chỉ xem dữ liệu franchise của mình qua AppView, không đọc bảng gốc hoặc chạy quyền quản lý.';

EXECUTE AS USER = 'franchise01';

SELECT USER_NAME() AS CurrentDatabaseUser;

SELECT FranchiseCode, FranchiseName
FROM AppView.vw_MyFranchiseProfile;

SELECT SettlementCode, FranchiseCode, GrossRevenue, PartnerShareAmount, PlatformShareAmount
FROM AppView.vw_MyRevenueShareSettlements;

BEGIN TRY
    SELECT TOP 5 *
    FROM Franchise.FranchisePartner;
END TRY
BEGIN CATCH
    PRINT N'Expected error: franchise partner cannot select Franchise.FranchisePartner directly.';
    SELECT ERROR_MESSAGE() AS ExpectedError;
END CATCH;

BEGIN TRY
    SELECT TOP 5 *
    FROM [Identity].UserAccount;
END TRY
BEGIN CATCH
    PRINT N'Expected error: franchise partner cannot select Identity.UserAccount directly.';
    SELECT ERROR_MESSAGE() AS ExpectedError;
END CATCH;

BEGIN TRY
    EXEC Franchise.sp_UpdateRevenueSharePolicy
        @RevenueSharePolicyID = 1,
        @PartnerShareRate = 70.00,
        @AppliedTo = NULL;
END TRY
BEGIN CATCH
    PRINT N'Expected error: franchise partner cannot update revenue share policy.';
    SELECT ERROR_MESSAGE() AS ExpectedError;
END CATCH;

BEGIN TRY
    EXEC Franchise.sp_CreateRevenueSettlement
        @FranchiseID = 1,
        @PeriodStart = '2026-01-01',
        @PeriodEnd = '2026-01-31';
END TRY
BEGIN CATCH
    PRINT N'Expected error: franchise partner cannot create revenue settlement.';
    SELECT ERROR_MESSAGE() AS ExpectedError;
END CATCH;

REVERT;
GO

