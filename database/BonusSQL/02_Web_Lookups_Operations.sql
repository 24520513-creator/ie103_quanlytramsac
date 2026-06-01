USE EV_Charging_System;
GO

/*
BonusSQL - Web lookup views for Operations Staff flows.
These views turn internal IDs into safe selectable objects for station, point,
session, ticket, and assignee fields.
*/

CREATE OR ALTER VIEW AppView.vw_WebLookupStations
AS
SELECT
    s.StationID,
    s.StationCode,
    s.StationName,
    s.StationStatus,
    s.MaxPowerKW,
    a.FullAddress
FROM Infrastructure.ChargingStation s
LEFT JOIN Core.Address a ON a.AddressID = s.AddressID
WHERE s.StationStatus <> N'Retired';
GO

CREATE OR ALTER VIEW AppView.vw_WebLookupPoints
AS
SELECT
    p.PointID,
    p.PointCode,
    p.StationID,
    s.StationCode,
    s.StationName,
    p.PointStatus,
    p.HealthStatus,
    ct.ConnectorCode,
    ct.ConnectorName,
    p.PowerKW
FROM Infrastructure.ChargingPoint p
JOIN Infrastructure.ChargingStation s ON s.StationID = p.StationID
JOIN Infrastructure.ConnectorType ct ON ct.ConnectorTypeID = p.ConnectorTypeID
WHERE p.PointStatus <> N'Retired';
GO

CREATE OR ALTER VIEW AppView.vw_WebLookupActiveSessions
AS
SELECT
    cs.SessionID,
    cs.SessionCode,
    u.Username,
    u.FullName,
    v.PlateNumber,
    s.StationCode,
    s.StationName,
    p.PointCode,
    cs.StartTime,
    cs.SessionStatus
FROM Operations.ChargingSession cs
JOIN [Identity].UserAccount u ON u.UserID = cs.UserID
LEFT JOIN Operations.Vehicle v ON v.VehicleID = cs.VehicleID
JOIN Infrastructure.ChargingStation s ON s.StationID = cs.StationID
JOIN Infrastructure.ChargingPoint p ON p.PointID = cs.PointID
WHERE cs.SessionStatus = N'Charging';
GO

CREATE OR ALTER VIEW AppView.vw_WebLookupOpenTickets
AS
SELECT
    mt.TicketID,
    mt.TicketCode,
    mt.Priority,
    mt.TicketStatus,
    mt.Title,
    mt.OpenedAt,
    s.StationCode,
    s.StationName,
    p.PointCode,
    assignedTo.Username AS AssignedToUsername,
    assignedTo.FullName AS AssignedToFullName
FROM Maintenance.MaintenanceTicket mt
LEFT JOIN Infrastructure.ChargingStation s ON s.StationID = mt.StationID
LEFT JOIN Infrastructure.ChargingPoint p ON p.PointID = mt.PointID
LEFT JOIN [Identity].UserAccount assignedTo ON assignedTo.UserID = mt.AssignedTo
WHERE mt.TicketStatus IN (N'Open', N'Assigned', N'InProgress', N'Resolved');
GO

CREATE OR ALTER VIEW AppView.vw_WebLookupOperationsStaff
AS
SELECT DISTINCT
    u.UserID,
    u.Username,
    u.FullName,
    u.Email,
    u.AccountStatus
FROM [Identity].UserAccount u
JOIN [Identity].UserRole ur ON ur.UserID = u.UserID
JOIN [Identity].[Role] r ON r.RoleID = ur.RoleID
WHERE r.RoleCode = N'OperationsStaff'
  AND u.AccountStatus = N'Active';
GO

GRANT SELECT ON OBJECT::AppView.vw_WebLookupStations TO db_ev_operations_staff;
GRANT SELECT ON OBJECT::AppView.vw_WebLookupPoints TO db_ev_operations_staff;
GRANT SELECT ON OBJECT::AppView.vw_WebLookupActiveSessions TO db_ev_operations_staff;
GRANT SELECT ON OBJECT::AppView.vw_WebLookupOpenTickets TO db_ev_operations_staff;
GRANT SELECT ON OBJECT::AppView.vw_WebLookupOperationsStaff TO db_ev_operations_staff;

GRANT SELECT ON OBJECT::AppView.vw_WebLookupStations TO db_ev_system_admin;
GRANT SELECT ON OBJECT::AppView.vw_WebLookupPoints TO db_ev_system_admin;
GRANT SELECT ON OBJECT::AppView.vw_WebLookupActiveSessions TO db_ev_system_admin;
GRANT SELECT ON OBJECT::AppView.vw_WebLookupOpenTickets TO db_ev_system_admin;
GRANT SELECT ON OBJECT::AppView.vw_WebLookupOperationsStaff TO db_ev_system_admin;
GO

PRINT N'BonusSQL 02 - Operations web lookup views created.';
GO
