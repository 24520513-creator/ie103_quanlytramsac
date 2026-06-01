/* ============================================================================
   BonusSQL/05_Web_Reports.sql
   Báo cáo phân tích bổ sung cho web (KHÔNG sửa các file gốc 05/07/08).
   Tạo view trong schema AppView rồi GRANT SELECT cho đúng DB role — theo đúng
   pattern của 03_Web_Lookups_Business_Admin.sql.
   ============================================================================ */
USE EV_Charging_System;
GO

/* ----------------------------------------------------------------------------
   1) Doanh thu theo trạm theo NĂM — báo cáo so sánh YoY (kiểu "doanh thu theo
      sản phẩm 2006 vs 2007"). Dùng cho BusinessManager.
   ---------------------------------------------------------------------------- */
CREATE OR ALTER VIEW AppView.vw_StationRevenueByYear
AS
SELECT
    s.StationID,
    s.StationCode,
    s.StationName,
    YEAR(cs.StartTime)              AS RevenueYear,
    COUNT(cs.SessionID)             AS CompletedSessions,
    SUM(ISNULL(cs.TotalKWh, 0))     AS TotalKWh,
    SUM(ISNULL(cs.CostTotal, 0))    AS RevenueTotal
FROM Operations.ChargingSession cs
JOIN Infrastructure.ChargingStation s ON s.StationID = cs.StationID
WHERE cs.SessionStatus = N'Completed'
GROUP BY s.StationID, s.StationCode, s.StationName, YEAR(cs.StartTime);
GO

/* ----------------------------------------------------------------------------
   2) Số tài khoản theo vai trò và trạng thái — dùng cho SystemAdmin
      (chart + report).
   ---------------------------------------------------------------------------- */
CREATE OR ALTER VIEW AppView.vw_AccountsByRole
AS
SELECT
    COALESCE(r.RoleCode, N'(Chưa gán)') AS RoleCode,
    u.AccountStatus,
    COUNT(DISTINCT u.UserID)            AS AccountCount
FROM [Identity].UserAccount u
LEFT JOIN [Identity].UserRole ur ON ur.UserID = u.UserID
LEFT JOIN [Identity].[Role] r    ON r.RoleID = ur.RoleID
GROUP BY COALESCE(r.RoleCode, N'(Chưa gán)'), u.AccountStatus;
GO

/* ----------------------------------------------------------------------------
   3) Tổng hợp sạc theo tháng của CHÍNH khách hàng đang đăng nhập.
      Lọc theo SESSION_CONTEXT('UserID') — giống vw_CustomerChargingHistory.
      Dùng cho Customer (dashboard chart + report).
   ---------------------------------------------------------------------------- */
CREATE OR ALTER VIEW AppView.vw_MyChargingSummary
AS
SELECT
    YEAR(cs.StartTime)              AS UsageYear,
    MONTH(cs.StartTime)            AS UsageMonth,
    COUNT(cs.SessionID)            AS SessionCount,
    SUM(ISNULL(cs.TotalKWh, 0))   AS TotalKWh,
    SUM(ISNULL(cs.CostTotal, 0))  AS TotalSpend
FROM Operations.ChargingSession cs
WHERE cs.UserID = TRY_CONVERT(INT, SESSION_CONTEXT(N'UserID'))
GROUP BY YEAR(cs.StartTime), MONTH(cs.StartTime);
GO

/* ----------------------------------------------------------------------------
   GRANT SELECT — theo đúng DB role đã định nghĩa trong 08_Create_Security.sql.
   ---------------------------------------------------------------------------- */
GRANT SELECT ON OBJECT::AppView.vw_StationRevenueByYear TO db_ev_business_manager;

GRANT SELECT ON OBJECT::AppView.vw_AccountsByRole       TO db_ev_system_admin;

GRANT SELECT ON OBJECT::AppView.vw_MyChargingSummary    TO db_ev_customer;
GO

PRINT N'BonusSQL/05 - Web report views created and granted.';
GO
