USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: tao ky doi soat doanh thu cho franchise.
- Tham so co the sua: @FranchiseID, @PeriodStart, @PeriodEnd.
- Tac dong du lieu: THEM THAT Franchise.RevenueShareSettlement.
*/

PRINT N'Tạo kỳ đối soát doanh thu: quản lý kinh doanh tạo settlement cho đối tác franchise trong một kỳ.';

DECLARE @FranchiseID INT = (SELECT TOP 1 FranchiseID FROM Franchise.FranchisePartner ORDER BY FranchiseID);

SELECT TOP 10 SettlementID, SettlementCode, FranchiseID, PeriodStart, PeriodEnd, GrossRevenue, SettlementStatus
FROM Franchise.RevenueShareSettlement
WHERE FranchiseID = @FranchiseID
ORDER BY SettlementID DESC;

EXEC Franchise.sp_CreateRevenueSettlement
    @FranchiseID = @FranchiseID,
    @PeriodStart = '2026-05-01',
    @PeriodEnd = '2026-05-31';

SELECT TOP 10 SettlementID, SettlementCode, FranchiseID, PeriodStart, PeriodEnd, GrossRevenue, PartnerShareAmount, PlatformShareAmount, SettlementStatus
FROM Franchise.RevenueShareSettlement
WHERE FranchiseID = @FranchiseID
ORDER BY SettlementID DESC;
GO



