const { query, execute } = require('../config/database');
const { NotFoundError, ValidationError, successResponse } = require('../utils/response');

class ChargingSessionService {
  async startSession({ UserID, VehicleID, PointID, StartBatteryPercent, MeterStart }) {
    const result = await execute('Operations.sp_StartChargingSession', {
      UserID, VehicleID: VehicleID || null, PointID,
      StartBatteryPercent: StartBatteryPercent || null, MeterStart: MeterStart || null,
    });
    return successResponse(result.recordset[0], 'Charging session started');
  }

  async endSession(sessionId, { EndBatteryPercent, MeterEnd, TotalKWh, StopReason }) {
    const result = await execute('Operations.sp_EndChargingSession', {
      SessionID: sessionId, EndBatteryPercent: EndBatteryPercent || null,
      MeterEnd: MeterEnd || null, TotalKWh: TotalKWh || null,
      StopReason: StopReason || 'Completed',
    });
    return successResponse(result.recordset[0], 'Charging session completed');
  }

  async cancelSession(sessionId, reason) {
    const session = await query(`SELECT * FROM [Operations].[ChargingSession] WHERE SessionID = @SessionID`,
      { SessionID: sessionId });
    if (session.recordset.length === 0) throw new NotFoundError('ChargingSession');
    const s = session.recordset[0];
    if (!['Charging', 'Pending'].includes(s.SessionStatus)) {
      throw new ValidationError(`Cannot cancel session with status ${s.SessionStatus}`);
    }

    await query(`UPDATE [Operations].[ChargingSession] SET SessionStatus = 'Cancelled', StopReason = @Reason, UpdatedAt = SYSDATETIME() WHERE SessionID = @SessionID`,
      { SessionID: sessionId, Reason: reason || 'CancelledByUser' });
    await query(`UPDATE [Infrastructure].[ChargingPoint] SET PointStatus = 'Available', UpdatedAt = SYSDATETIME() WHERE PointID = @PointID`,
      { PointID: s.PointID });

    return successResponse(null, 'Charging session cancelled');
  }

  async getActiveSessions(filters = {}) {
    let q = `SELECT cs.*, u.Username, u.FullName, s.StationCode, s.StationName, p.PointCode, v.PlateNumber
      FROM [Operations].[ChargingSession] cs
      JOIN [Users].[User] u ON cs.UserID = u.UserID
      JOIN [Infrastructure].[ChargingStation] s ON cs.StationID = s.StationID
      JOIN [Infrastructure].[ChargingPoint] p ON cs.PointID = p.PointID
      LEFT JOIN [Users].[Vehicle] v ON cs.VehicleID = v.VehicleID
      WHERE 1=1`;
    const params = {};

    if (filters.status) { q += ` AND cs.SessionStatus = @Status`; params.Status = filters.status; }
    if (filters.userId) { q += ` AND cs.UserID = @UserID`; params.UserID = filters.userId; }
    if (filters.stationId) { q += ` AND cs.StationID = @StationID`; params.StationID = filters.stationId; }
    if (filters.fromDate) { q += ` AND cs.StartTime >= @FromDate`; params.FromDate = filters.fromDate; }
    if (filters.toDate) { q += ` AND cs.StartTime <= @ToDate`; params.ToDate = filters.toDate; }

    q += ` ORDER BY cs.StartTime DESC`;
    if (filters.page && filters.limit) {
      const offset = (filters.page - 1) * filters.limit;
      q += ` OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY`;
      params.Offset = offset;
      params.Limit = filters.limit;
    }

    const result = await query(q, params);
    return result.recordset;
  }

  async getSessionHistory(userId) {
    return this.getActiveSessions({ userId, status: 'Completed' });
  }
}

module.exports = new ChargingSessionService();
