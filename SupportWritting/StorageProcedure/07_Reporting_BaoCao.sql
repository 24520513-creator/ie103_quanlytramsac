==============================================================================
-- 4.2.10 Nhom Reporting Procedure
==============================================================================


==============================================================================
-- AppView.sp_GetStationRevenue
==============================================================================

--database/07_Create_AppViews.sql
CREATE OR ALTER PROCEDURE AppView.sp_GetStationRevenue
    @FromDate DATE = NULL,
    @ToDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT StationCode, StationName, FranchiseName,
           SUM(CompletedSessions) AS CompletedSessions,
           SUM(TotalKWh) AS TotalKWh,
           SUM(RevenueTotal) AS RevenueTotal
    FROM AppView.vw_StationRevenueDaily
    WHERE (@FromDate IS NULL OR RevenueDate >= @FromDate)
      AND (@ToDate IS NULL OR RevenueDate <= @ToDate)
    GROUP BY StationCode, StationName, FranchiseName
    ORDER BY RevenueTotal DESC;
END;
GO

-- >>> TEST: source kiem thu tinh nang
-- (Trich tu database/features/business_manager/02_view_station_revenue.sql)
USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: xem bo du lieu doanh thu theo tram.
- Tham so co the sua: @FromDate va @ToDate trong lenh EXEC.
- Tac dong du lieu: CHI DOC DU LIEU, khong them/sua/xoa.
*/

PRINT N'Xem doanh thu theo trạm: quản lý kinh doanh lấy dữ liệu doanh thu trạm theo khoảng ngày.';

EXEC AppView.sp_GetStationRevenue
    @FromDate = '2026-05-01',
    @ToDate = '2026-05-31';
GO



==============================================================================
-- AppView.sp_GetFranchiseProfitSharing
==============================================================================

--database/07_Create_AppViews.sql
CREATE OR ALTER PROCEDURE AppView.sp_GetFranchiseProfitSharing
AS
BEGIN
    SET NOCOUNT ON;
    SELECT SettlementCode, FranchiseCode, FranchiseName, PeriodStart, PeriodEnd,
           GrossRevenue, PartnerShareAmount, PlatformShareAmount, SettlementStatus
    FROM AppView.vw_ProfitSharing
    ORDER BY PeriodEnd DESC, GrossRevenue DESC;
END;
GO

-- >>> TEST: source kiem thu tinh nang
-- (Trich tu database/features/business_manager/08_view_franchise_profit.sql)
USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: xem du lieu chia loi nhuan franchise.
- Khong can sua tham so.
- Tac dong du lieu: CHI DOC DU LIEU, khong them/sua/xoa.
*/

PRINT N'Xem chia lợi nhuận franchise: quản lý kinh doanh xem phần doanh thu của đối tác và nền tảng.';

EXEC AppView.sp_GetFranchiseProfitSharing;
GO



==============================================================================
-- AppView.sp_GetPaymentSummary
==============================================================================

--database/07_Create_AppViews.sql
CREATE OR ALTER PROCEDURE AppView.sp_GetPaymentSummary
AS
BEGIN
    SET NOCOUNT ON;
    SELECT PaymentMethod, TransactionStatus, TransactionCount, TotalAmount
    FROM AppView.vw_PaymentSummary
    ORDER BY TransactionStatus, PaymentMethod;
END;
GO

-- >>> TEST: source kiem thu tinh nang
-- (Demo test soan rieng cho bao cao - SP nay khong co file feature test rieng)
USE EV_Charging_System;
GO
-- TEST: Tong hop thanh toan toan he thong (khong tham so)
EXEC AppView.sp_GetPaymentSummary;
-- Ket qua mong doi: cac dong tong hop theo phuong thuc / trang thai thanh toan


==============================================================================
-- AppView.sp_GetCustomerUsage
==============================================================================

--database/07_Create_AppViews.sql
CREATE OR ALTER PROCEDURE AppView.sp_GetCustomerUsage
    @Top INT = 10
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP (@Top) Username, FullName,
           COUNT(SessionID) AS CompletedSessions,
           SUM(ISNULL(TotalKWh, 0)) AS TotalKWh,
           SUM(ISNULL(CostTotal, 0)) AS TotalSpend
    FROM AppView.vw_CustomerChargingHistory
    WHERE SessionStatus = N'Completed'
    GROUP BY Username, FullName
    ORDER BY TotalSpend DESC, CompletedSessions DESC;
END;
GO

-- >>> TEST: source kiem thu tinh nang
-- (Demo test soan rieng cho bao cao - SP nay khong co file feature test rieng)
USE EV_Charging_System;
GO
-- TEST: Top khach hang theo muc do su dung (mac dinh Top 10)
EXEC AppView.sp_GetCustomerUsage @Top = 5;
-- Ket qua mong doi: 5 khach hang co so phien/chi tieu cao nhat


==============================================================================
-- AppView.sp_GetOperationalKPI
==============================================================================

--database/07_Create_AppViews.sql
CREATE OR ALTER PROCEDURE AppView.sp_GetOperationalKPI
AS
BEGIN
    SET NOCOUNT ON;
    SELECT StationCode, StationName, TicketCount, OpenTicketCount, ErrorCount, ActiveErrorCount, AvgResolveHours
    FROM AppView.vw_MaintenanceKPI
    ORDER BY ActiveErrorCount DESC, OpenTicketCount DESC, StationCode;
END;
GO

-- >>> TEST: source kiem thu tinh nang
-- (Demo test soan rieng cho bao cao - SP nay khong co file feature test rieng)
USE EV_Charging_System;
GO
-- TEST: Cac chi so KPI van hanh tong quan (khong tham so)
EXEC AppView.sp_GetOperationalKPI;
-- Ket qua mong doi: 1 dong cac chi so KPI (so tram, phien, doanh thu, ...)


==============================================================================
-- AppView.sp_GetTelemetryHealth
==============================================================================

--database/07_Create_AppViews.sql
CREATE OR ALTER PROCEDURE AppView.sp_GetTelemetryHealth
AS
BEGIN
    SET NOCOUNT ON;
    SELECT s.StationCode, p.PointCode, ct.ConnectorCode,
           MAX(t.RecordedAt) AS LastRecordedAt,
           MAX(t.TemperatureC) AS MaxTemperatureC,
           SUM(CASE WHEN t.HealthStatus IN (N'Warning', N'Critical', N'Offline') THEN 1 ELSE 0 END) AS IssueSamples
    FROM Infrastructure.PointTelemetry t
    JOIN Infrastructure.ChargingPoint p ON p.PointID = t.PointID
    JOIN Infrastructure.ChargingStation s ON s.StationID = p.StationID
    JOIN Infrastructure.ConnectorType ct ON ct.ConnectorTypeID = p.ConnectorTypeID
    GROUP BY s.StationCode, p.PointCode, ct.ConnectorCode
    HAVING SUM(CASE WHEN t.HealthStatus IN (N'Warning', N'Critical', N'Offline') THEN 1 ELSE 0 END) > 0
    ORDER BY IssueSamples DESC, StationCode, PointCode;
END;
GO

-- >>> TEST: source kiem thu tinh nang
-- (Trich tu database/features/operations_staff/08_view_telemetry_health.sql)
USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: xem cac mau telemetry co canh bao suc khoe thiet bi.
- Khong can sua tham so.
- Tac dong du lieu: CHI DOC DU LIEU, khong them/sua/xoa.
*/

PRINT N'Theo dõi sức khỏe thiết bị: nhân viên vận hành xem các mẫu telemetry cảnh báo hoặc nghiêm trọng.';

EXEC AppView.sp_GetTelemetryHealth;
GO



==============================================================================
-- AppView.sp_GetCurrentUserProfile
==============================================================================

--database/07_Create_AppViews.sql
CREATE OR ALTER PROCEDURE AppView.sp_GetCurrentUserProfile
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM AppView.vw_CurrentUserProfile;
END;
GO

-- >>> TEST: source kiem thu tinh nang
-- (Demo test soan rieng cho bao cao - SP nay khong co file feature test rieng)
USE EV_Charging_System;
GO
-- TEST: Lay ho so cua nguoi dung dang dang nhap (dua tren SESSION_CONTEXT/USER hien tai)
EXEC AppView.sp_GetCurrentUserProfile;
-- Ket qua mong doi: thong tin ho so cua chinh nguoi dung phien hien tai


==============================================================================
-- AppView.sp_GetMyFranchiseProfile
==============================================================================

--database/07_Create_AppViews.sql
CREATE OR ALTER PROCEDURE AppView.sp_GetMyFranchiseProfile
AS
BEGIN
    SET NOCOUNT ON;
    SELECT FranchiseID, FranchiseCode, FranchiseName, TaxCode, ContactPerson,
           ContactPhone, ContactEmail, PartnerStatus, FullAddress
    FROM AppView.vw_MyFranchiseProfile;
END;
GO

-- >>> TEST: source kiem thu tinh nang
-- (Trich tu database/features/franchise_partner/01_view_my_profile.sql)
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



==============================================================================
-- AppView.sp_GetMyFranchiseContracts
==============================================================================

--database/07_Create_AppViews.sql
CREATE OR ALTER PROCEDURE AppView.sp_GetMyFranchiseContracts
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ContractID, FranchiseCode, FranchiseName, ContractCode, StartDate,
           EndDate, BaseRevenueShareRate, ContractStatus
    FROM AppView.vw_MyFranchiseContracts
    ORDER BY StartDate DESC, ContractCode;
END;
GO

-- >>> TEST: source kiem thu tinh nang
-- (Trich tu database/features/franchise_partner/02_view_my_contracts.sql)
USE EV_Charging_System;
GO

/*
HUONG DAN SU DUNG
- Muc dich: Franchise Partner xem hop dong nhuuong quyen cua chinh minh.
- Khong can sua tham so, co the doi franchise01 thanh franchise02..franchise08.
- Tac dong du lieu: CHI DOC DU LIEU.
*/

PRINT N'Franchise Partner xem hợp đồng nhượng quyền của chính mình.';

EXECUTE AS USER = 'franchise01';

SELECT USER_NAME() AS CurrentDatabaseUser;

EXEC AppView.sp_GetMyFranchiseContracts;

REVERT;
GO



==============================================================================
-- AppView.sp_GetMyFranchiseStations
==============================================================================

--database/07_Create_AppViews.sql
CREATE OR ALTER PROCEDURE AppView.sp_GetMyFranchiseStations
AS
BEGIN
    SET NOCOUNT ON;
    SELECT StationID, StationCode, StationName, MaxPowerKW, StationStatus,
           ContractCode, FullAddress
    FROM AppView.vw_MyFranchiseStations
    ORDER BY StationCode;
END;
GO

-- >>> TEST: source kiem thu tinh nang
-- (Trich tu database/features/franchise_partner/03_view_my_stations.sql)
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



==============================================================================
-- AppView.sp_GetMyRevenueSharePolicies
==============================================================================

--database/07_Create_AppViews.sql
CREATE OR ALTER PROCEDURE AppView.sp_GetMyRevenueSharePolicies
AS
BEGIN
    SET NOCOUNT ON;
    SELECT RevenueSharePolicyID, FranchiseCode, FranchiseName, ContractCode,
           PolicyCode, PartnerShareRate, PlatformShareRate, AppliedFrom,
           AppliedTo, IsActive
    FROM AppView.vw_MyRevenueSharePolicies
    ORDER BY IsActive DESC, AppliedFrom DESC, PolicyCode;
END;
GO

-- >>> TEST: source kiem thu tinh nang
-- (Trich tu database/features/franchise_partner/04_view_my_revenue_share_policy.sql)
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



==============================================================================
-- AppView.sp_GetMyRevenueShareSettlements
==============================================================================

--database/07_Create_AppViews.sql
CREATE OR ALTER PROCEDURE AppView.sp_GetMyRevenueShareSettlements
AS
BEGIN
    SET NOCOUNT ON;
    SELECT SettlementID, SettlementCode, FranchiseCode, FranchiseName,
           ContractCode, PeriodStart, PeriodEnd, GrossRevenue,
           PartnerShareAmount, PlatformShareAmount, SettlementStatus,
           ApprovedAt
    FROM AppView.vw_MyRevenueShareSettlements
    ORDER BY PeriodEnd DESC, SettlementCode;
END;
GO

-- >>> TEST: source kiem thu tinh nang
-- (Trich tu database/features/franchise_partner/05_view_my_settlements.sql)
USE EV_Charging_System;
GO

/*
HUONG DAN SU DUNG
- Muc dich: Franchise Partner xem settlement va profit sharing cua chinh minh.
- Khong can sua tham so, co the doi franchise01 thanh franchise02..franchise08.
- Tac dong du lieu: CHI DOC DU LIEU.
*/

PRINT N'Franchise Partner xem settlement/profit sharing của chính mình.';

EXECUTE AS USER = 'franchise01';

SELECT USER_NAME() AS CurrentDatabaseUser;

EXEC AppView.sp_GetMyRevenueShareSettlements;

REVERT;
GO



==============================================================================
-- AppView.sp_ActivatePricingPolicy
==============================================================================

--database/05_Create_Stored_Procedures.sql
CREATE OR ALTER PROCEDURE AppView.sp_ActivatePricingPolicy
    @PolicyID INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRAN;

        IF NOT EXISTS (
            SELECT 1
            FROM Operations.PricingPolicy
            WHERE PolicyID = @PolicyID
        )
            THROW 57001, 'Pricing policy does not exist.', 1;

        IF NOT EXISTS (
            SELECT 1
            FROM Operations.PricingPolicy
            WHERE PolicyID = @PolicyID
              AND IsActive = 0
        )
            THROW 57002, 'Pricing policy is already active.', 1;

        UPDATE Operations.PricingPolicy
        SET IsActive = 1
        WHERE PolicyID = @PolicyID;

        INSERT INTO Audit.AuditLog (SchemaName, TableName, RecordID, ActionType, NewValues)
        VALUES (N'Operations', N'PricingPolicy', CAST(@PolicyID AS NVARCHAR(100)), N'UPDATE', N'Active');

        COMMIT;

        SELECT PolicyID, PolicyCode, PolicyName, IsActive
        FROM Operations.PricingPolicy
        WHERE PolicyID = @PolicyID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END;
GO

-- >>> TEST: source kiem thu tinh nang
-- (Demo test soan rieng cho bao cao - SP nay khong co file feature test rieng)
USE EV_Charging_System;
GO
-- TEST: Kich hoat mot chinh sach gia (cac chinh sach trung pham vi se bi vo hieu).
-- Bao trong giao dich + ROLLBACK de khong doi trang thai du lieu that.
BEGIN TRAN;
    DECLARE @PolicyID INT = (SELECT TOP 1 PolicyID FROM Operations.PricingPolicy ORDER BY PolicyID DESC);
    EXEC AppView.sp_ActivatePricingPolicy @PolicyID = @PolicyID;
    -- Ket qua mong doi: PricingPolicy duoc chuyen sang trang thai dang ap dung.
ROLLBACK;   -- huy thay doi demo
