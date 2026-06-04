==============================================================================
-- 4.5.6 Nhom View phuc vu van hanh he thong
==============================================================================


==============================================================================
-- AppView.vw_StationStatusOverview
==============================================================================

--database/07_Create_AppViews.sql
CREATE OR ALTER VIEW AppView.vw_StationStatusOverview
AS
SELECT
    s.StationID,
    s.StationCode,
    s.StationName,
    s.StationStatus,
    COUNT(p.PointID) AS TotalPoints,
    SUM(CASE WHEN p.PointStatus = N'Available' THEN 1 ELSE 0 END) AS AvailablePoints,
    SUM(CASE WHEN p.PointStatus = N'Charging' THEN 1 ELSE 0 END) AS ChargingPoints,
    SUM(CASE WHEN p.PointStatus IN (N'Error', N'Maintenance', N'Offline') THEN 1 ELSE 0 END) AS ProblemPoints,
    MAX(psh.ChangedAt) AS LastStatusChangeAt
FROM Infrastructure.ChargingStation s
LEFT JOIN Infrastructure.ChargingPoint p ON p.StationID = s.StationID
LEFT JOIN Infrastructure.PointStatusHistory psh ON psh.PointID = p.PointID
GROUP BY s.StationID, s.StationCode, s.StationName, s.StationStatus;

-- >>> TEST: cau lenh truy van view
USE EV_Charging_System;
GO
SELECT TOP (20) * FROM AppView.vw_StationStatusOverview;


==============================================================================
-- AppView.vw_ActiveChargingSessions
==============================================================================

--database/07_Create_AppViews.sql
CREATE OR ALTER VIEW AppView.vw_ActiveChargingSessions
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
    DATEDIFF(MINUTE, cs.StartTime, SYSDATETIME()) AS RunningMinutes,
    cs.SessionStatus
FROM Operations.ChargingSession cs
JOIN [Identity].UserAccount u ON u.UserID = cs.UserID
LEFT JOIN Operations.Vehicle v ON v.VehicleID = cs.VehicleID
JOIN Infrastructure.ChargingStation s ON s.StationID = cs.StationID
JOIN Infrastructure.ChargingPoint p ON p.PointID = cs.PointID
WHERE cs.SessionStatus = N'Charging';

-- >>> TEST: cau lenh truy van view
USE EV_Charging_System;
GO
SELECT TOP (20) * FROM AppView.vw_ActiveChargingSessions;


==============================================================================
-- AppView.vw_MaintenanceKPI
==============================================================================

--database/07_Create_AppViews.sql
CREATE OR ALTER VIEW AppView.vw_MaintenanceKPI
AS
SELECT
    s.StationCode,
    s.StationName,
    COUNT(DISTINCT mt.TicketID) AS TicketCount,
    COUNT(DISTINCT CASE WHEN mt.TicketStatus IN (N'Open', N'Assigned', N'InProgress') THEN mt.TicketID END) AS OpenTicketCount,
    COUNT(DISTINCT el.ErrorID) AS ErrorCount,
    COUNT(DISTINCT CASE WHEN el.IsActive = 1 THEN el.ErrorID END) AS ActiveErrorCount,
    AVG(CASE WHEN mt.ClosedAt IS NOT NULL THEN DATEDIFF(HOUR, mt.OpenedAt, mt.ClosedAt) END) AS AvgResolveHours
FROM Infrastructure.ChargingStation s
LEFT JOIN Maintenance.MaintenanceTicket mt ON mt.StationID = s.StationID
LEFT JOIN Maintenance.ErrorLog el ON el.StationID = s.StationID
GROUP BY s.StationCode, s.StationName;

-- >>> TEST: cau lenh truy van view
USE EV_Charging_System;
GO
SELECT TOP (20) * FROM AppView.vw_MaintenanceKPI;


==============================================================================
-- AppView.vw_MaintenanceTickets
==============================================================================

--database/07_Create_AppViews.sql
CREATE OR ALTER VIEW AppView.vw_MaintenanceTickets
AS
SELECT
    mt.TicketID,
    mt.TicketCode,
    mt.Priority,
    mt.TicketStatus,
    mt.Title,
    mt.Description,
    mt.OpenedAt,
    mt.ClosedAt,
    s.StationID,
    s.StationCode,
    s.StationName,
    p.PointID,
    p.PointCode,
    createdBy.Username AS CreatedByUsername,
    createdBy.FullName AS CreatedByFullName,
    assignedTo.Username AS AssignedToUsername,
    assignedTo.FullName AS AssignedToFullName
FROM Maintenance.MaintenanceTicket mt
LEFT JOIN Infrastructure.ChargingStation s ON s.StationID = mt.StationID
LEFT JOIN Infrastructure.ChargingPoint p ON p.PointID = mt.PointID
LEFT JOIN [Identity].UserAccount createdBy ON createdBy.UserID = mt.CreatedBy
LEFT JOIN [Identity].UserAccount assignedTo ON assignedTo.UserID = mt.AssignedTo;

-- >>> TEST: cau lenh truy van view
USE EV_Charging_System;
GO
SELECT TOP (20) * FROM AppView.vw_MaintenanceTickets;


==============================================================================
-- AppView.vw_ErrorLogActive
==============================================================================

--database/07_Create_AppViews.sql
CREATE OR ALTER VIEW AppView.vw_ErrorLogActive
AS
SELECT
    e.ErrorID,
    e.ErrorCode,
    e.Severity,
    e.Description,
    e.OccurredAt,
    e.ResolvedAt,
    e.IsActive,
    s.StationID,
    s.StationCode,
    s.StationName,
    p.PointID,
    p.PointCode
FROM Maintenance.ErrorLog e
LEFT JOIN Infrastructure.ChargingStation s ON s.StationID = e.StationID
LEFT JOIN Infrastructure.ChargingPoint p ON p.PointID = e.PointID
WHERE e.IsActive = 1;

-- >>> TEST: cau lenh truy van view
USE EV_Charging_System;
GO
SELECT TOP (20) * FROM AppView.vw_ErrorLogActive;
