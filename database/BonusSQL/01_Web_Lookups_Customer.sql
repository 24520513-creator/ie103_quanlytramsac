USE EV_Charging_System;
GO

/*
BonusSQL - Web lookup views for Customer flows.
Purpose: provide human-readable select options for the web UI without changing
existing tables, seed data, constraints, or stored procedures.
*/

CREATE OR ALTER VIEW AppView.vw_WebLookupConnectorTypes
AS
SELECT
    ConnectorTypeID,
    ConnectorCode,
    ConnectorName,
    MaxPowerKW,
    IsActive
FROM Infrastructure.ConnectorType
WHERE IsActive = 1;
GO

CREATE OR ALTER VIEW AppView.vw_WebLookupCustomerVehicles
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
GO

CREATE OR ALTER VIEW AppView.vw_WebLookupAvailablePoints
AS
SELECT
    r.RegionName,
    s.StationID,
    s.StationCode,
    s.StationName,
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
  AND p.PointStatus = N'Available'
  AND p.HealthStatus <> N'Offline';
GO

CREATE OR ALTER VIEW AppView.vw_WebLookupCustomerBookings
AS
SELECT
    b.BookingID,
    b.BookingCode,
    b.UserID,
    b.VehicleID,
    b.PointID,
    b.StationID,
    v.PlateNumber,
    s.StationCode,
    s.StationName,
    p.PointCode,
    b.BookedFrom,
    b.BookedTo,
    b.BookingStatus,
    b.CreatedAt
FROM Operations.Booking b
LEFT JOIN Operations.Vehicle v ON v.VehicleID = b.VehicleID
JOIN Infrastructure.ChargingPoint p ON p.PointID = b.PointID
JOIN Infrastructure.ChargingStation s ON s.StationID = b.StationID
WHERE b.UserID = TRY_CONVERT(INT, SESSION_CONTEXT(N'UserID'));
GO

CREATE OR ALTER VIEW AppView.vw_WebLookupCustomerSessions
AS
SELECT
    cs.SessionID,
    cs.SessionCode,
    cs.UserID,
    cs.VehicleID,
    cs.PointID,
    cs.StationID,
    cs.BookingID,
    v.PlateNumber,
    s.StationCode,
    s.StationName,
    p.PointCode,
    cs.StartTime,
    cs.EndTime,
    cs.TotalKWh,
    cs.CostTotal,
    cs.SessionStatus,
    CAST(CASE WHEN EXISTS (
        SELECT 1
        FROM Payments.PaymentTransaction pt
        WHERE pt.SessionID = cs.SessionID
          AND pt.TransactionStatus = N'Completed'
    ) THEN 1 ELSE 0 END AS BIT) AS HasCompletedPayment,
    CAST(CASE WHEN EXISTS (
        SELECT 1
        FROM Payments.Invoice i
        WHERE i.SessionID = cs.SessionID
    ) THEN 1 ELSE 0 END AS BIT) AS HasInvoice
FROM Operations.ChargingSession cs
LEFT JOIN Operations.Vehicle v ON v.VehicleID = cs.VehicleID
JOIN Infrastructure.ChargingStation s ON s.StationID = cs.StationID
JOIN Infrastructure.ChargingPoint p ON p.PointID = cs.PointID
WHERE cs.UserID = TRY_CONVERT(INT, SESSION_CONTEXT(N'UserID'));
GO

GRANT SELECT ON OBJECT::AppView.vw_WebLookupConnectorTypes TO db_ev_customer;
GRANT SELECT ON OBJECT::AppView.vw_WebLookupConnectorTypes TO db_ev_operations_staff;
GRANT SELECT ON OBJECT::AppView.vw_WebLookupConnectorTypes TO db_ev_business_manager;
GRANT SELECT ON OBJECT::AppView.vw_WebLookupConnectorTypes TO db_ev_system_admin;

GRANT SELECT ON OBJECT::AppView.vw_WebLookupCustomerVehicles TO db_ev_customer;
GRANT SELECT ON OBJECT::AppView.vw_WebLookupAvailablePoints TO db_ev_customer;
GRANT SELECT ON OBJECT::AppView.vw_WebLookupCustomerBookings TO db_ev_customer;
GRANT SELECT ON OBJECT::AppView.vw_WebLookupCustomerSessions TO db_ev_customer;
GO

PRINT N'BonusSQL 01 - Customer web lookup views created.';
GO
