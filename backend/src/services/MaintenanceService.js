const { execute } = require('../config/database');
const { NotFoundError, successResponse } = require('../utils/response');
const socketService = require('./socketService');
const notificationService = require('./NotificationService');

class MaintenanceService {
  async scheduleMaintenance({ StationID, PointID, ScheduledFrom, ScheduledTo, ScheduledBy, MaintenanceType, Description }) {
    const result = await execute('Operations.sp_ScheduleMaintenance', {
      StationID, PointID: PointID || null, ScheduledBy,
      ScheduledFrom, ScheduledTo,
      MaintenanceType: MaintenanceType || 'Routine', Description: Description || null,
    });
    if (!result.recordset || result.recordset.length === 0) {
      throw new Error('Schedule maintenance returned no result');
    }
    const schedule = result.recordset[0];

    socketService.sendToStation(StationID, 'maintenance:scheduled', schedule);
    socketService.sendToRole('Manager', 'maintenance:scheduled', schedule);
    socketService.sendToRole('Admin', 'maintenance:scheduled', schedule);

    return successResponse(schedule, 'Maintenance scheduled');
  }

  async completeMaintenance(maintenanceId, { Notes, CompletedAt }) {
    const result = await execute('Operations.sp_CompleteMaintenance', {
      ScheduleID: maintenanceId, Notes: Notes || null, CompletedAt: CompletedAt || null,
    });
    if (!result.recordset || result.recordset.length === 0) {
      throw new NotFoundError('MaintenanceSchedule');
    }
    const completed = result.recordset[0];

    socketService.sendToStation(completed.StationID, 'maintenance:completed', completed);
    socketService.sendToRole('Manager', 'maintenance:completed', completed);

    return successResponse(completed, 'Maintenance completed');
  }

  async getUpcoming(days = 7) {
    const result = await execute('Operations.sp_GetUpcomingMaintenance', { Days: days });
    return successResponse(result.recordset || []);
  }

  async resolveError(errorId, { ResolvedBy }) {
    const result = await execute('Infrastructure.sp_ResolveError', {
      ErrorID: errorId, ResolvedBy: ResolvedBy || null,
    });
    if (!result.recordset || result.recordset.length === 0) {
      throw new NotFoundError('ErrorLog');
    }
    const resolved = result.recordset[0];

    socketService.sendToStation(resolved.StationID, 'error:resolved', resolved);
    socketService.sendToRole('Manager', 'error:resolved', resolved);
    socketService.sendToRole('Admin', 'error:resolved', resolved);

    if (resolved.ReportedBy) {
      notificationService.create(resolved.ReportedBy, {
        Title: 'Lỗi đã được xử lý',
        Body: `Lỗi #${errorId} tại trạm đã được giải quyết.`,
        Type: 'Success',
        ReferenceType: 'Error',
        ReferenceID: errorId,
      });
    }

    return successResponse(resolved, 'Error resolved');
  }
}

module.exports = new MaintenanceService();
