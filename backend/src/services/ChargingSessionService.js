const { execute } = require('../config/database');
const { NotFoundError, ValidationError, successResponse } = require('../utils/response');
const socketService = require('./socketService');
const notificationService = require('./NotificationService');

class ChargingSessionService {
  async startSession({ UserID, VehicleID, PointID, StartBatteryPercent, MeterStart }) {
    const result = await execute('Operations.sp_StartChargingSession', {
      UserID, VehicleID: VehicleID || null, PointID,
      StartBatteryPercent: StartBatteryPercent || null, MeterStart: MeterStart || null,
    });
    if (!result.recordset || result.recordset.length === 0) {
      throw new Error('Charging session start returned no result');
    }
    const session = result.recordset[0];
    const stationResult = await execute('Infrastructure.sp_GetStationIdByPoint', { PointID });
    const stationId = stationResult.recordset[0]?.StationID;
    if (stationId) {
      socketService.sendToStation(stationId, 'session:started', session);
    }
    socketService.sendToUser(UserID, 'session:started', session);
    socketService.sendToRole('Manager', 'session:started', session);
    return successResponse(session, 'Charging session started');
  }

  async endSession(sessionId, { EndBatteryPercent, MeterEnd, TotalKWh, StopReason }) {
    const result = await execute('Operations.sp_EndChargingSession', {
      SessionID: sessionId, EndBatteryPercent: EndBatteryPercent || null,
      MeterEnd: MeterEnd || null, TotalKWh: TotalKWh || null,
      StopReason: StopReason || 'Completed',
    });
    if (!result.recordset || result.recordset.length === 0) {
      throw new NotFoundError('ChargingSession');
    }
    const session = result.recordset[0];
    socketService.sendToStation(session.StationID, 'session:ended', session);
    socketService.sendToUser(session.UserID, 'session:ended', session);
    socketService.sendToRole('Manager', 'session:ended', session);
    return successResponse(session, 'Charging session completed');
  }

  async cancelSession(sessionId, reason) {
    const result = await execute('Operations.sp_CancelChargingSession', {
      SessionID: sessionId, StopReason: reason || 'CancelledByUser',
    });
    if (!result.recordset || result.recordset.length === 0) {
      throw new NotFoundError('ChargingSession');
    }
    const s = result.recordset[0];

    try {
      socketService.sendToStation(s.StationID, 'session:cancelled', { SessionID: sessionId, PointID: s.PointID });
      socketService.sendToUser(s.UserID, 'session:cancelled', { SessionID: sessionId });
      await notificationService.create(s.UserID, {
        Title: 'Phiên sạc đã hủy',
        Body: `Phiên sạc tại điểm #${s.PointID} đã bị hủy.`,
        Type: 'Warning',
        ReferenceType: 'Session',
        ReferenceID: sessionId,
      });
    } catch (notifyErr) {
      console.error('Post-commit notification failed:', notifyErr.message);
    }

    return successResponse(null, 'Charging session cancelled');
  }

  async getActiveSessions(filters = {}) {
    const params = { Page: filters.page || 1, Limit: filters.limit || 50 };
    if (filters.status) params.Status = filters.status;
    if (filters.userId) params.UserID = filters.userId;
    if (filters.stationId) params.StationID = filters.stationId;
    if (filters.fromDate) params.FromDate = filters.fromDate;
    if (filters.toDate) params.ToDate = filters.toDate;

    const result = await execute('Operations.sp_GetActiveSessions', params);
    return result.recordset || [];
  }

  async getSessionHistory(userId) {
    return this.getActiveSessions({ userId, status: 'Completed' });
  }
}

module.exports = new ChargingSessionService();
