==============================================================================
-- 4.2.9 Nhom Stored Procedure franchise va chia doanh thu
==============================================================================


==============================================================================
-- Franchise.sp_UpdateRevenueSharePolicy
==============================================================================

--database/05_Create_Stored_Procedures.sql
CREATE OR ALTER PROCEDURE Franchise.sp_UpdateRevenueSharePolicy
    @RevenueSharePolicyID INT,
    @PartnerShareRate DECIMAL(5,2),
    @AppliedTo DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF @PartnerShareRate NOT BETWEEN 0 AND 100
            THROW 55010, 'Partner share rate must be between 0 and 100.', 1;
        IF NOT EXISTS (SELECT 1 FROM Franchise.RevenueSharePolicy WHERE RevenueSharePolicyID = @RevenueSharePolicyID)
            THROW 55011, 'Revenue share policy does not exist.', 1;

        UPDATE Franchise.RevenueSharePolicy
        SET PartnerShareRate = @PartnerShareRate,
            AppliedTo = @AppliedTo
        WHERE RevenueSharePolicyID = @RevenueSharePolicyID;

        INSERT INTO Audit.AuditLog (SchemaName, TableName, RecordID, ActionType, NewValues)
        VALUES (N'Franchise', N'RevenueSharePolicy', CAST(@RevenueSharePolicyID AS NVARCHAR(100)), N'UPDATE', CAST(@PartnerShareRate AS NVARCHAR(50)));

        COMMIT TRANSACTION;

        SELECT RevenueSharePolicyID, ContractID, PartnerShareRate, PlatformShareRate, AppliedFrom, AppliedTo, IsActive
        FROM Franchise.RevenueSharePolicy
        WHERE RevenueSharePolicyID = @RevenueSharePolicyID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- >>> TEST: source kiem thu tinh nang
-- (Trich tu database/features/business_manager/06_update_revenue_share_policy.sql)
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



==============================================================================
-- Franchise.sp_CreateRevenueSettlement
==============================================================================

--database/05_Create_Stored_Procedures.sql
CREATE OR ALTER PROCEDURE Franchise.sp_CreateRevenueSettlement
    @FranchiseID INT,
    @PeriodStart DATE,
    @PeriodEnd DATE
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @ContractID INT, @PartnerRate DECIMAL(5,2);
        SELECT TOP 1 @ContractID = fc.ContractID, @PartnerRate = rsp.PartnerShareRate
        FROM Franchise.FranchiseContract fc
        JOIN Franchise.RevenueSharePolicy rsp ON rsp.ContractID = fc.ContractID AND rsp.IsActive = 1
        WHERE fc.FranchiseID = @FranchiseID
          AND fc.ContractStatus = N'Active'
          AND @PeriodStart BETWEEN fc.StartDate AND fc.EndDate
        ORDER BY fc.StartDate DESC;

        IF @ContractID IS NULL
            THROW 55001, 'Active franchise contract not found.', 1;

        DECLARE @GrossRevenue DECIMAL(19,4);
        SELECT @GrossRevenue = SUM(cs.CostBeforeTax)
        FROM Operations.ChargingSession cs
        JOIN Infrastructure.ChargingStation s ON s.StationID = cs.StationID
        WHERE s.FranchiseID = @FranchiseID
          AND cs.SessionStatus = N'Completed'
          AND CAST(cs.StartTime AS DATE) BETWEEN @PeriodStart AND @PeriodEnd;

        SET @GrossRevenue = ISNULL(@GrossRevenue, 0);

        DECLARE @PartnerShare DECIMAL(19,4) = Franchise.fn_CalculatePartnerShare(@GrossRevenue, @PartnerRate);
        DECLARE @PlatformShare DECIMAL(19,4) = @GrossRevenue - @PartnerShare;

        INSERT INTO Franchise.RevenueShareSettlement
            (SettlementCode, FranchiseID, ContractID, PeriodStart, PeriodEnd, GrossRevenue, PartnerShareAmount, PlatformShareAmount, SettlementStatus, ApprovedAt)
        VALUES
            (N'SET-' + FORMAT(SYSDATETIME(), 'yyyyMMddHHmmss') + N'-' + RIGHT(CONVERT(NVARCHAR(36), NEWID()), 6),
             @FranchiseID, @ContractID, @PeriodStart, @PeriodEnd, @GrossRevenue, @PartnerShare, @PlatformShare, N'Approved', SYSDATETIME());

        DECLARE @SettlementID BIGINT = SCOPE_IDENTITY();

        INSERT INTO Audit.AuditLog (SchemaName, TableName, RecordID, ActionType, NewValues)
        VALUES (N'Franchise', N'RevenueShareSettlement', CAST(@SettlementID AS NVARCHAR(100)), N'SETTLEMENT', CAST(@GrossRevenue AS NVARCHAR(50)));

        COMMIT TRANSACTION;

        SELECT SettlementID, SettlementCode, GrossRevenue, PartnerShareAmount, PlatformShareAmount, SettlementStatus
        FROM Franchise.RevenueShareSettlement
        WHERE SettlementID = @SettlementID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- >>> TEST: source kiem thu tinh nang
-- (Trich tu database/features/business_manager/07_create_revenue_settlement.sql)
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
