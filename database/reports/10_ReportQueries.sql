/*=============================================================================
  EV_Charging_System - REPORTING QUERIES
  =============================================================================*/

USE EV_Charging_System;
GO

-- ========================================
-- 1. Monthly Revenue Report
-- ========================================
PRINT N'===== 1. BÁO CÁO DOANH THU THEO THÁNG =====';
SELECT
    RIGHT(N'0' + CAST(MONTH(t.[Timestamp]) AS NVARCHAR(2)), 2)
        + N'-' + CAST(YEAR(t.[Timestamp]) AS NVARCHAR(4)) AS Thang,
    COUNT(DISTINCT t.TransactionID)   AS SoGiaoDich,
    COUNT(DISTINCT t.UserID)          AS SoKhachHang,
    SUM(t.Amount)                     AS TongDoanhThu
FROM Operations.Transactions t
GROUP BY YEAR(t.[Timestamp]), MONTH(t.[Timestamp])
ORDER BY YEAR(t.[Timestamp]), MONTH(t.[Timestamp]);
GO

-- ========================================
-- 2. Top Charging Stations by Revenue
-- ========================================
PRINT N'===== 2. TOP 5 TRẠM SẠC THEO DOANH THU =====';
SELECT TOP 5
    s.StationName,
    s.Address,
    f.FranchiseeName,
    COUNT(ses.SessionID)          AS TongPhien,
    ISNULL(SUM(ses.CostTotal), 0) AS TongDoanhThu
FROM Infrastructure.ChargingStation s
JOIN Infrastructure.Franchisee f ON s.FranchiseeID = f.FranchiseeID
JOIN Infrastructure.ChargingPoint p ON s.StationID = p.StationID
LEFT JOIN Operations.ChargingSession ses ON p.PointID = ses.PointID AND ses.Status = N'Đã sạc xong'
GROUP BY s.StationID, s.StationName, s.Address, f.FranchiseeName
ORDER BY TongDoanhThu DESC;
GO

-- ========================================
-- 3. Most Active Customers
-- ========================================
PRINT N'===== 3. KHÁCH HÀNG NĂNG ĐỘNG NHẤT =====';
SELECT TOP 5
    c.UserID,
    c.FullName,
    c.Email,
    c.Phone,
    COUNT(ses.SessionID)          AS SoPhienSac,
    ISNULL(SUM(ses.Total_kWh), 0) AS TongkWh,
    ISNULL(SUM(ses.CostTotal), 0) AS TongChiTieu
FROM Users.Customers c
JOIN Operations.ChargingSession ses ON c.UserID = ses.UserID AND ses.Status = N'Đã sạc xong'
GROUP BY c.UserID, c.FullName, c.Email, c.Phone
ORDER BY TongChiTieu DESC;
GO

-- ========================================
-- 4. Peak Charging Hours Analysis
-- ========================================
PRINT N'===== 4. PHÂN TÍCH GIỜ SẠC CAO ĐIỂM =====';
SELECT
    DATEPART(HOUR, StartTime)      AS GioTrongNgay,
    COUNT(SessionID)               AS SoPhien,
    AVG(Total_kWh)                 AS kWhTrungBinh,
    SUM(CostTotal)                 AS TongDoanhThu
FROM Operations.ChargingSession
WHERE Status = N'Đã sạc xong'
GROUP BY DATEPART(HOUR, StartTime)
ORDER BY SoPhien DESC;
GO

-- ========================================
-- 5. Franchise Performance Report
-- ========================================
PRINT N'===== 5. HIỆU SUẤT DOANH NGHIỆP NHƯỢNG QUYỀN =====';
SELECT
    f.FranchiseeID,
    f.FranchiseeName,
    f.RevenueShareRate,
    COUNT(DISTINCT s.StationID)                         AS SoTram,
    COUNT(DISTINCT ses.SessionID)                       AS TongPhien,
    ISNULL(SUM(ses.CostTotal), 0)                       AS TongDoanhThu,
    ISNULL(SUM(ses.CostTotal) * f.RevenueShareRate / 100, 0) AS HoaHong
FROM Infrastructure.Franchisee f
LEFT JOIN Infrastructure.ChargingStation s ON f.FranchiseeID = s.FranchiseeID
LEFT JOIN Infrastructure.ChargingPoint p ON s.StationID = p.StationID
LEFT JOIN Operations.ChargingSession ses ON p.PointID = ses.PointID AND ses.Status = N'Đã sạc xong'
GROUP BY f.FranchiseeID, f.FranchiseeName, f.RevenueShareRate
ORDER BY TongDoanhThu DESC;
GO

-- ========================================
-- 6. Error Frequency Analysis
-- ========================================
PRINT N'===== 6. TẦN SUẤT LỖI THIẾT BỊ =====';
SELECT
    e.ErrorCode,
    COUNT(e.ErrorID)              AS SoLanXuatHien,
    COUNT(DISTINCT e.PointID)     AS SoDiemSacBiLoi,
    COUNT(DISTINCT p.StationID)   AS SoTramBiAnhHuong,
    MIN(e.OccurredAt)             AS LanDauTien,
    MAX(e.OccurredAt)             AS LanGanNhat
FROM Monitoring.ErrorLogs e
JOIN Infrastructure.ChargingPoint p ON e.PointID = p.PointID
GROUP BY e.ErrorCode
ORDER BY SoLanXuatHien DESC;
GO

PRINT N'All report queries executed.';
GO
