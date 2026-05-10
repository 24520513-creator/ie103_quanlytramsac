const { query } = require('../config/database');
const { successResponse } = require('../utils/response');

class DashboardService {
  async getAdminDashboard() {
    const result = await query(`SELECT * FROM [Reporting].[vw_RevenueTrend] ORDER BY Date DESC`, {});
    const counts = await query(`
      SELECT
        (SELECT COUNT(*) FROM [Users].[User] WHERE AccountStatus = 'Active') AS TotalUsers,
        (SELECT COUNT(*) FROM [Infrastructure].[ChargingStation] WHERE IsActive = 1) AS TotalStations,
        (SELECT COUNT(*) FROM [Infrastructure].[Franchise] WHERE IsActive = 1) AS TotalFranchises,
        (SELECT COUNT(*) FROM [Operations].[ChargingSession] WHERE SessionStatus = 'Completed') AS TotalSessions,
        (SELECT COUNT(*) FROM [Operations].[ChargingSession] WHERE SessionStatus = 'Charging') AS ActiveSessions,
        (SELECT ISNULL(SUM(TotalKWh), 0) FROM [Operations].[ChargingSession] WHERE SessionStatus = 'Completed') AS TotalKWh,
        (SELECT ISNULL(SUM(CostTotal), 0) FROM [Operations].[ChargingSession] WHERE SessionStatus = 'Completed') AS TotalRevenue,
        (SELECT COUNT(*) FROM [Operations].[Booking] WHERE Status IN ('Pending', 'Confirmed')) AS PendingBookings,
        (SELECT COUNT(*) FROM [Infrastructure].[ErrorLog] WHERE IsResolved = 0) AS UnresolvedErrors,
        (SELECT COUNT(*) FROM [Operations].[MaintenanceSchedule] WHERE Status IN ('Scheduled', 'InProgress')) AS UpcomingMaintenance,
        (SELECT COUNT(*) FROM [Users].[Notification] WHERE IsRead = 0) AS UnreadNotifications
    `, {});
    const topStations = await query(`SELECT TOP 10 s.StationCode, s.StationName, COUNT(cs.SessionID) AS Sessions,
      ISNULL(SUM(cs.TotalKWh), 0) AS KWh, ISNULL(SUM(cs.CostTotal), 0) AS Revenue
      FROM [Operations].[ChargingSession] cs JOIN [Infrastructure].[ChargingStation] s ON cs.StationID = s.StationID
      WHERE cs.SessionStatus = 'Completed' GROUP BY s.StationCode, s.StationName ORDER BY Revenue DESC`, {});
    const recentBookings = await query(`SELECT TOP 5 b.*, s.StationName, p.PointCode
      FROM [Operations].[Booking] b
      JOIN [Infrastructure].[ChargingStation] s ON b.StationID = s.StationID
      LEFT JOIN [Infrastructure].[ChargingPoint] p ON b.PointID = p.PointID
      ORDER BY b.CreatedAt DESC`, {});
    const recentErrors = await query(`SELECT TOP 5 el.*, p.PointCode
      FROM [Infrastructure].[ErrorLog] el
      LEFT JOIN [Infrastructure].[ChargingPoint] p ON el.PointID = p.PointID
      WHERE el.IsResolved = 0 ORDER BY el.CreatedAt DESC`, {});

    return successResponse({
      counts: counts.recordset[0],
      revenueByDay: result.recordset,
      topStations: topStations.recordset,
      recentBookings: recentBookings.recordset,
      recentErrors: recentErrors.recordset,
    });
  }

  async getStationDashboard(stationId, days = 30) {
    const current = await query(`SELECT COUNT(*) AS ActiveSessions FROM [Operations].[ChargingSession]
      WHERE StationID = @ID AND SessionStatus = 'Charging'`, { ID: stationId });
    const totals = await query(`SELECT COUNT(*) AS TotalSessions, ISNULL(SUM(TotalKWh), 0) AS TotalKWh,
      ISNULL(SUM(CostTotal), 0) AS TotalRevenue, ISNULL(AVG(ChargingDurationMinutes), 0) AS AvgDuration
      FROM [Operations].[ChargingSession] WHERE StationID = @ID AND SessionStatus = 'Completed'
      AND StartTime >= DATEADD(DAY, -@Days, SYSDATETIME())`, { ID: stationId, Days: days });
    const points = await query(`SELECT PointStatus, COUNT(*) AS Count FROM [Infrastructure].[ChargingPoint]
      WHERE StationID = @ID AND IsActive = 1 GROUP BY PointStatus`, { ID: stationId });
    const station = await query(`SELECT * FROM [Infrastructure].[ChargingStation] WHERE StationID = @ID`, { ID: stationId });

    return successResponse({
      station: station.recordset[0],
      activeSessions: current.recordset[0]?.ActiveSessions || 0,
      totals: totals.recordset[0],
      pointStatus: points.recordset,
    });
  }

  async getFranchiseDashboard(franchiseId, days = 30) {
    const stations = await query(`SELECT StationID, StationCode, StationName, StationStatus
      FROM [Infrastructure].[ChargingStation] WHERE FranchiseID = @FID AND IsActive = 1`,
      { FID: franchiseId });
    const revenue = await query(`SELECT ISNULL(SUM(CostTotal), 0) AS TotalRevenue, ISNULL(SUM(TotalKWh), 0) AS TotalKWh,
      COUNT(*) AS TotalSessions FROM [Operations].[ChargingSession] WHERE StationID IN
      (SELECT StationID FROM [Infrastructure].[ChargingStation] WHERE FranchiseID = @FID AND IsActive = 1)
      AND SessionStatus = 'Completed' AND StartTime >= DATEADD(DAY, -@Days, SYSDATETIME())`,
      { FID: franchiseId, Days: days });
    const franchise = await query(`SELECT * FROM [Infrastructure].[Franchise] WHERE FranchiseID = @FID`,
      { FID: franchiseId });

    return successResponse({
      franchise: franchise.recordset[0],
      stations: stations.recordset,
      revenue: revenue.recordset[0],
      activeStations: stations.recordset.filter(s => s.StationStatus === 'Active').length,
    });
  }
}

module.exports = new DashboardService();
