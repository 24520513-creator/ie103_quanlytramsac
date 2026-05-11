const { execute } = require('../config/database');
const { successResponse } = require('../utils/response');

class DashboardService {
  async getAdminDashboard() {
    const result = await execute('Reporting.sp_GetAdminDashboard', {});
    return successResponse({
      revenueByDay: result.recordsets[0],
      counts: result.recordsets[1][0],
      topStations: result.recordsets[2],
      recentBookings: result.recordsets[3],
      recentErrors: result.recordsets[4],
    });
  }

  async getStationDashboard(stationId, days = 30) {
    const result = await execute('Reporting.sp_GetStationDashboard', { StationID: stationId, Days: days });
    return successResponse({
      activeSessions: result.recordsets[0][0]?.ActiveSessions || 0,
      totals: result.recordsets[1][0],
      pointStatus: result.recordsets[2],
      station: result.recordsets[3][0],
    });
  }

  async getFranchiseDashboard(franchiseId, days = 30) {
    const result = await execute('Reporting.sp_GetFranchiseDashboard', { FranchiseID: franchiseId, Days: days });
    const stations = result.recordsets[0];
    return successResponse({
      franchise: result.recordsets[2][0],
      stations,
      revenue: result.recordsets[1][0],
      activeStations: stations.filter(s => s.StationStatus === 'Active').length,
    });
  }
}

module.exports = new DashboardService();
