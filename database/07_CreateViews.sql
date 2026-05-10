USE EV_Charging_System;
GO

-- ============================================================
-- vw_RevenueTrend: Daily revenue for time-series charts
-- ============================================================
CREATE OR ALTER VIEW Reporting.vw_RevenueTrend
AS
SELECT CAST(StartTime AS DATE) AS Date,
       COUNT(SessionID) AS Sessions,
       ISNULL(SUM(TotalKWh), 0) AS KWh,
       ISNULL(SUM(CostTotal), 0) AS Revenue
FROM Operations.ChargingSession
WHERE SessionStatus = 'Completed' AND StartTime >= DATEADD(DAY, -90, SYSDATETIME())
GROUP BY CAST(StartTime AS DATE);
GO

PRINT N'View created (vw_RevenueTrend).';
GO
