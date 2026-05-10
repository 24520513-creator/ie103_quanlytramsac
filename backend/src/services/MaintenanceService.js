const { query } = require('../config/database');
const { NotFoundError, successResponse } = require('../utils/response');

class MaintenanceService {
  async scheduleMaintenance({ StationID, PointID, ScheduledDate, MaintenanceType, Description, Priority }) {
    const result = await query(`INSERT INTO [Operations].[MaintenanceSchedule]
      (StationID, PointID, ScheduledDate, MaintenanceType, Description, Priority, Status, CreatedAt)
      OUTPUT INSERTED.*
      VALUES (@StationID, @PointID, @ScheduledDate, @Type, @Description, @Priority, 'Scheduled', SYSDATETIME())`, {
      StationID, PointID: PointID || null, ScheduledDate, Type: MaintenanceType || 'Routine',
      Description: Description || null, Priority: Priority || 'Normal',
    });
    return successResponse(result.recordset[0], 'Maintenance scheduled');
  }

  async completeMaintenance(maintenanceId, { PartsUsed, Cost, CompletedBy }) {
    const existing = await query(`SELECT * FROM [Operations].[MaintenanceSchedule] WHERE MaintenanceID = @ID`,
      { ID: maintenanceId });
    if (existing.recordset.length === 0) throw new NotFoundError('MaintenanceSchedule');
    const result = await query(`UPDATE [Operations].[MaintenanceSchedule]
      SET Status = 'Completed', PartsUsed = @PartsUsed, Cost = @Cost, CompletedBy = @CompletedBy,
      CompletedAt = SYSDATETIME(), UpdatedAt = SYSDATETIME()
      OUTPUT INSERTED.* WHERE MaintenanceID = @ID`, {
      ID: maintenanceId, PartsUsed: PartsUsed || null, Cost: Cost || null, CompletedBy: CompletedBy || null,
    });
    return successResponse(result.recordset[0], 'Maintenance completed');
  }

  async getUpcoming(days = 7) {
    const result = await query(`SELECT ms.*, s.StationCode, s.StationName, p.PointCode
      FROM [Operations].[MaintenanceSchedule] ms
      JOIN [Infrastructure].[ChargingStation] s ON ms.StationID = s.StationID
      LEFT JOIN [Infrastructure].[ChargingPoint] p ON ms.PointID = p.PointID
      WHERE ms.Status IN ('Scheduled', 'InProgress')
      AND ms.ScheduledDate <= DATEADD(DAY, @Days, SYSDATETIME())
      ORDER BY ms.ScheduledDate`, { Days: days });
    return successResponse(result.recordset);
  }

  async resolveError(errorId, { ResolvedBy }) {
    const existing = await query(`SELECT * FROM [Infrastructure].[ErrorLog] WHERE ErrorLogID = @ID`,
      { ID: errorId });
    if (existing.recordset.length === 0) throw new NotFoundError('ErrorLog');
    const result = await query(`UPDATE [Infrastructure].[ErrorLog]
      SET IsResolved = 1, ResolvedAt = SYSDATETIME(), ResolvedBy = @ResolvedBy
      OUTPUT INSERTED.* WHERE ErrorLogID = @ID`,
      { ID: errorId, ResolvedBy: ResolvedBy || null });
    return successResponse(result.recordset[0], 'Error resolved');
  }
}

module.exports = new MaintenanceService();
