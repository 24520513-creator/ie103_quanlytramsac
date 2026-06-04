==============================================================================
-- 4.5.4 Nhom View phuc vu khach hang
==============================================================================


==============================================================================
-- AppView.vw_CustomerChargingHistory
==============================================================================

--database/07_Create_AppViews.sql
CREATE OR ALTER VIEW AppView.vw_CustomerChargingHistory
AS
SELECT
    u.UserID,
    u.Username,
    u.FullName,
    v.PlateNumber,
    cs.SessionID,
    cs.SessionCode,
    s.StationCode,
    s.StationName,
    p.PointCode,
    ct.ConnectorCode,
    cs.StartTime,
    cs.EndTime,
    cs.TotalKWh,
    cs.CostTotal,
    cs.SessionStatus
FROM Operations.ChargingSession cs
JOIN [Identity].UserAccount u ON u.UserID = cs.UserID
LEFT JOIN Operations.Vehicle v ON v.VehicleID = cs.VehicleID
JOIN Infrastructure.ChargingStation s ON s.StationID = cs.StationID
JOIN Infrastructure.ChargingPoint p ON p.PointID = cs.PointID
JOIN Infrastructure.ConnectorType ct ON ct.ConnectorTypeID = p.ConnectorTypeID
WHERE NOT (COALESCE(CAST(SESSION_CONTEXT(N'RoleCode') AS NVARCHAR(40)), N'') = N'Customer' OR IS_ROLEMEMBER(N'db_ev_customer') = 1)
   OR cs.UserID = TRY_CONVERT(INT, SESSION_CONTEXT(N'UserID'));

-- >>> TEST: cau lenh truy van view
USE EV_Charging_System;
GO
-- View nay LOC theo nguoi dang nhap (RLS) -> phai set SESSION_CONTEXT truoc, neu khong se rong.
EXEC sys.sp_set_session_context @key = N'UserID',   @value = 52;         -- customer01
EXEC sys.sp_set_session_context @key = N'RoleCode', @value = N'Customer';
SELECT TOP (20) * FROM AppView.vw_CustomerChargingHistory;


==============================================================================
-- AppView.vw_CustomerBookingHistory
==============================================================================

--database/07_Create_AppViews.sql
CREATE OR ALTER VIEW AppView.vw_CustomerBookingHistory
AS
SELECT
    b.BookingID,
    b.BookingCode,
    b.UserID,
    u.Username,
    u.FullName,
    v.PlateNumber,
    s.StationCode,
    s.StationName,
    p.PointCode,
    b.BookedFrom,
    b.BookedTo,
    b.BookingStatus,
    b.CreatedAt,
    b.UpdatedAt
FROM Operations.Booking b
JOIN [Identity].UserAccount u ON u.UserID = b.UserID
LEFT JOIN Operations.Vehicle v ON v.VehicleID = b.VehicleID
JOIN Infrastructure.ChargingPoint p ON p.PointID = b.PointID
JOIN Infrastructure.ChargingStation s ON s.StationID = p.StationID
WHERE NOT (COALESCE(CAST(SESSION_CONTEXT(N'RoleCode') AS NVARCHAR(40)), N'') = N'Customer' OR IS_ROLEMEMBER(N'db_ev_customer') = 1)
   OR b.UserID = TRY_CONVERT(INT, SESSION_CONTEXT(N'UserID'));

-- >>> TEST: cau lenh truy van view
USE EV_Charging_System;
GO
-- View nay LOC theo nguoi dang nhap (RLS) -> phai set SESSION_CONTEXT truoc, neu khong se rong.
EXEC sys.sp_set_session_context @key = N'UserID',   @value = 52;         -- customer01
EXEC sys.sp_set_session_context @key = N'RoleCode', @value = N'Customer';
SELECT TOP (20) * FROM AppView.vw_CustomerBookingHistory;


==============================================================================
-- AppView.vw_InvoiceDetail
==============================================================================

--database/07_Create_AppViews.sql
CREATE OR ALTER VIEW AppView.vw_InvoiceDetail
AS
SELECT
    i.InvoiceID,
    i.InvoiceCode,
    i.InvoiceStatus,
    i.IssuedAt,
    i.Subtotal,
    i.TaxAmount,
    i.TotalAmount,
    pt.TransactionCode,
    pt.PaymentMethod,
    pt.TransactionStatus,
    u.UserID,
    u.Username,
    u.FullName,
    cs.SessionCode,
    cs.StartTime,
    cs.EndTime,
    cs.TotalKWh,
    s.StationCode,
    s.StationName,
    p.PointCode
FROM Payments.Invoice i
JOIN Payments.PaymentTransaction pt ON pt.TransactionID = i.TransactionID
JOIN Operations.ChargingSession cs ON cs.SessionID = pt.SessionID
JOIN [Identity].UserAccount u ON u.UserID = cs.UserID
JOIN Infrastructure.ChargingStation s ON s.StationID = cs.StationID
JOIN Infrastructure.ChargingPoint p ON p.PointID = cs.PointID
WHERE NOT (COALESCE(CAST(SESSION_CONTEXT(N'RoleCode') AS NVARCHAR(40)), N'') = N'Customer' OR IS_ROLEMEMBER(N'db_ev_customer') = 1)
   OR cs.UserID = TRY_CONVERT(INT, SESSION_CONTEXT(N'UserID'));

-- >>> TEST: cau lenh truy van view
USE EV_Charging_System;
GO
-- View nay LOC theo nguoi dang nhap (RLS) -> phai set SESSION_CONTEXT truoc, neu khong se rong.
EXEC sys.sp_set_session_context @key = N'UserID',   @value = 52;         -- customer01
EXEC sys.sp_set_session_context @key = N'RoleCode', @value = N'Customer';
SELECT TOP (20) * FROM AppView.vw_InvoiceDetail;


==============================================================================
-- AppView.vw_MyVehicles
==============================================================================

--database/07_Create_AppViews.sql
CREATE OR ALTER VIEW AppView.vw_MyVehicles
AS
SELECT
    v.VehicleID,
    v.UserID,
    v.PlateNumber,
    v.Brand,
    v.Model,
    v.BatteryCapacityKWh,
    v.PreferredConnectorTypeID,
    ct.ConnectorCode,
    ct.ConnectorName,
    v.IsActive,
    v.CreatedAt
FROM Operations.Vehicle v
LEFT JOIN Infrastructure.ConnectorType ct ON ct.ConnectorTypeID = v.PreferredConnectorTypeID
WHERE v.UserID = TRY_CONVERT(INT, SESSION_CONTEXT(N'UserID'));

-- >>> TEST: cau lenh truy van view
USE EV_Charging_System;
GO
-- View nay LOC theo nguoi dang nhap (RLS) -> phai set SESSION_CONTEXT truoc, neu khong se rong.
EXEC sys.sp_set_session_context @key = N'UserID',   @value = 52;         -- customer01
EXEC sys.sp_set_session_context @key = N'RoleCode', @value = N'Customer';
SELECT TOP (20) * FROM AppView.vw_MyVehicles;


==============================================================================
-- AppView.vw_MyChargingSummary
==============================================================================

--database/07_Create_AppViews.sql
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

-- >>> TEST: cau lenh truy van view
USE EV_Charging_System;
GO
-- View nay LOC theo nguoi dang nhap (RLS) -> phai set SESSION_CONTEXT truoc, neu khong se rong.
EXEC sys.sp_set_session_context @key = N'UserID',   @value = 52;         -- customer01
EXEC sys.sp_set_session_context @key = N'RoleCode', @value = N'Customer';
SELECT TOP (20) * FROM AppView.vw_MyChargingSummary;


==============================================================================
-- AppView.vw_AvailableChargingPoints
==============================================================================

--database/07_Create_AppViews.sql
CREATE OR ALTER VIEW AppView.vw_AvailableChargingPoints
AS
SELECT
    r.RegionName,
    s.StationID,
    s.StationCode,
    s.StationName,
    s.StationStatus,
    p.PointID,
    p.PointCode,
    p.PointStatus,
    p.HealthStatus,
    ct.ConnectorCode,
    ct.ConnectorName,
    p.PowerKW
FROM Infrastructure.ChargingPoint p
JOIN Infrastructure.ChargingStation s ON s.StationID = p.StationID
JOIN Infrastructure.ConnectorType ct ON ct.ConnectorTypeID = p.ConnectorTypeID
LEFT JOIN Core.Address a ON a.AddressID = s.AddressID
LEFT JOIN Core.Region r ON r.RegionID = a.RegionID
WHERE s.StationStatus = N'Active'
  AND p.PointStatus = N'Available';

-- >>> TEST: cau lenh truy van view
USE EV_Charging_System;
GO
SELECT TOP (20) * FROM AppView.vw_AvailableChargingPoints;
