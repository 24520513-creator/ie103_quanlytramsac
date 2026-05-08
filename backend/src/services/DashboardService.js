const { query } = require('../config/database');
const { successResponse } = require('../utils/response');

class DashboardService {
  async getStationDashboard(stationId, days = 30) {
    const kpi = await query(`SELECT * FROM [Analytics].[DailyStationKPI] WHERE StationID = @StationID AND KpiDate >= DATEADD(DAY, -@Days, SYSDATETIME()) ORDER BY KpiDate DESC`,
      { StationID: stationId, Days: days });

    const current = await query(`SELECT COUNT(*) AS ActiveSessions FROM [Operations].[ChargingSession] WHERE StationID = @StationID AND SessionStatus = 'Charging' AND IsDeleted = 0`,
      { StationID: stationId });

    const totals = await query(`SELECT COUNT(*) AS TotalSessions, ISNULL(SUM(TotalKWh), 0) AS TotalKWh, ISNULL(SUM(CostTotal), 0) AS TotalRevenue,
      ISNULL(AVG(ChargingDurationMinutes), 0) AS AvgDuration
      FROM [Operations].[ChargingSession] WHERE StationID = @StationID AND SessionStatus = 'Completed' AND IsDeleted = 0
      AND StartTime >= DATEADD(DAY, -@Days, SYSDATETIME())`, { StationID: stationId, Days: days });

    const points = await query(`SELECT PointStatus, COUNT(*) AS Count FROM [Infrastructure].[ChargingPoint] WHERE StationID = @StationID AND IsDeleted = 0 GROUP BY PointStatus`,
      { StationID: stationId });

    return successResponse({
      kpis: kpi.recordset,
      activeSessions: current.recordset[0]?.ActiveSessions || 0,
      totals: totals.recordset[0],
      pointStatus: points.recordset,
    });
  }

  async getFranchiseDashboard(franchiseId, days = 30) {
    const kpi = await query(`SELECT * FROM [Analytics].[DailyFranchiseKPI] WHERE FranchiseID = @FranchiseID AND KpiDate >= DATEADD(DAY, -@Days, SYSDATETIME()) ORDER BY KpiDate DESC`,
      { FranchiseID: franchiseId, Days: days });

    const stations = await query(`SELECT StationID, StationCode, StationName, StationStatus, NetworkStatus FROM [Infrastructure].[ChargingStation] WHERE FranchiseID = @FranchiseID AND IsDeleted = 0`,
      { FranchiseID: franchiseId });

    const revenue = await query(`SELECT ISNULL(SUM(CostTotal), 0) AS TotalRevenue, ISNULL(SUM(TotalKWh), 0) AS TotalKWh,
      COUNT(*) AS TotalSessions FROM [Operations].[ChargingSession] WHERE StationID IN
      (SELECT StationID FROM [Infrastructure].[ChargingStation] WHERE FranchiseID = @FranchiseID AND IsDeleted = 0)
      AND SessionStatus = 'Completed' AND StartTime >= DATEADD(DAY, -@Days, SYSDATETIME())`, { FranchiseID: franchiseId });

    return successResponse({
      kpis: kpi.recordset,
      stations: stations.recordset,
      revenue: revenue.recordset[0],
      activeStations: stations.recordset.filter(s => s.StationStatus === 'Active').length,
    });
  }

  async getAdminDashboard() {
    const totalUsers = await query(`SELECT COUNT(*) AS Count FROM [Users].[User] WHERE IsDeleted = 0`, {});
    const totalStations = await query(`SELECT COUNT(*) AS Count FROM [Infrastructure].[ChargingStation] WHERE IsDeleted = 0`, {});
    const totalSessions = await query(`SELECT COUNT(*) AS Count FROM [Operations].[ChargingSession] WHERE SessionStatus = 'Completed' AND IsDeleted = 0`, {});
    const activeSessions = await query(`SELECT COUNT(*) AS Count FROM [Operations].[ChargingSession] WHERE SessionStatus = 'Charging' AND IsDeleted = 0`, {});
    const totalRevenue = await query(`SELECT ISNULL(SUM(CostTotal), 0) AS Total FROM [Operations].[ChargingSession] WHERE SessionStatus = 'Completed' AND IsDeleted = 0`, {});
    const totalKWh = await query(`SELECT ISNULL(SUM(TotalKWh), 0) AS Total FROM [Operations].[ChargingSession] WHERE SessionStatus = 'Completed' AND IsDeleted = 0`, {});
    const franchises = await query(`SELECT COUNT(*) AS Count FROM [Infrastructure].[Franchise] WHERE IsDeleted = 0`, {});
    const activeAlerts = await query(`SELECT COUNT(*) AS Count FROM [Monitoring].[Alert] WHERE AlertStatus = 'Open'`, {});

    const revenueByDay = await query(`SELECT CAST(StartTime AS DATE) AS Date, ISNULL(SUM(CostTotal), 0) AS Revenue
      FROM [Operations].[ChargingSession] WHERE SessionStatus = 'Completed' AND IsDeleted = 0 AND StartTime >= DATEADD(DAY, -30, SYSDATETIME())
      GROUP BY CAST(StartTime AS DATE) ORDER BY Date`, {});

    const topStations = await query(`SELECT TOP 10 s.StationCode, s.StationName, COUNT(cs.SessionID) AS Sessions,
      ISNULL(SUM(cs.TotalKWh), 0) AS KWh, ISNULL(SUM(cs.CostTotal), 0) AS Revenue
      FROM [Operations].[ChargingSession] cs JOIN [Infrastructure].[ChargingStation] s ON cs.StationID = s.StationID
      WHERE cs.SessionStatus = 'Completed' AND cs.IsDeleted = 0 GROUP BY s.StationCode, s.StationName ORDER BY Revenue DESC`, {});

    return successResponse({
      counts: {
        users: totalUsers.recordset[0].Count,
        stations: totalStations.recordset[0].Count,
        sessions: totalSessions.recordset[0].Count,
        activeSessions: activeSessions.recordset[0].Count,
        franchises: franchises.recordset[0].Count,
        activeAlerts: activeAlerts.recordset[0].Count,
      },
      totals: {
        revenue: totalRevenue.recordset[0].Total,
        kwh: totalKWh.recordset[0].Total,
      },
      revenueByDay: revenueByDay.recordset,
      topStations: topStations.recordset,
    });
  }
}

module.exports = new DashboardService();
