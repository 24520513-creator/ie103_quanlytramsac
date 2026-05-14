USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: cap nhat ty le chia doanh thu cua franchise policy.
- Tham so co the sua: @PolicyID, @PartnerShareRate, @AppliedTo.
- @PartnerShareRate nam trong khoang 0 den 100.
- Tac dong du lieu: SUA THAT Franchise.RevenueSharePolicy.
*/

PRINT N'Cập nhật chính sách chia doanh thu: quản lý kinh doanh thay đổi tỷ lệ chia doanh thu franchise.';

DECLARE @PolicyID INT = (SELECT TOP 1 RevenueSharePolicyID FROM Franchise.RevenueSharePolicy WHERE IsActive = 1 ORDER BY RevenueSharePolicyID);

SELECT RevenueSharePolicyID, PolicyCode, PartnerShareRate, PlatformShareRate, AppliedFrom, AppliedTo, IsActive
FROM Franchise.RevenueSharePolicy
WHERE RevenueSharePolicyID = @PolicyID;

EXEC Franchise.sp_UpdateRevenueSharePolicy
    @RevenueSharePolicyID = @PolicyID,
    @PartnerShareRate = 70.00,
    @AppliedTo = NULL;

SELECT RevenueSharePolicyID, PolicyCode, PartnerShareRate, PlatformShareRate, AppliedFrom, AppliedTo, IsActive
FROM Franchise.RevenueSharePolicy
WHERE RevenueSharePolicyID = @PolicyID;
GO



