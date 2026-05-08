const { query } = require('../config/database');
const { NotFoundError, ValidationError, ForbiddenError, successResponse } = require('../utils/response');
const { ChargingSession } = require('../models/Operations');
const BaseRepository = require('../repositories/BaseRepository');
const ChargingSessionRepo = new BaseRepository('ChargingSession', 'Operations', 'SessionID', ChargingSession);

class ChargingSessionService {
  async startSession({ UserID, VehicleID, PointID, StartBatteryPercent, MeterStart, SessionSource, SessionType }) {
    const pointResult = await query(`SELECT * FROM [Infrastructure].[ChargingPoint] WHERE PointID = @PointID AND IsDeleted = 0`, { PointID });
    if (pointResult.recordset.length === 0) throw new NotFoundError('ChargingPoint');
    const point = pointResult.recordset[0];
    if (point.PointStatus !== 'Available') throw new ValidationError(`Point is ${point.PointStatus}, not available`);

    const userResult = await query(`SELECT AccountStatus FROM [Users].[User] WHERE UserID = @UserID AND IsDeleted = 0`, { UserID });
    if (userResult.recordset.length === 0) throw new NotFoundError('User');
    if (userResult.recordset[0].AccountStatus !== 'Active') throw new ValidationError('User account is not active');

    const stationResult = await query(`SELECT * FROM [Infrastructure].[ChargingStation] WHERE StationID = @StationID AND IsDeleted = 0`, { StationID: point.StationID });
    const station = stationResult.recordset[0];
    if (station.StationStatus !== 'Active') throw new ValidationError(`Station is ${station.StationStatus}`);

    const activePolicy = await query(`SELECT TOP 1 * FROM [Operations].[PricingPolicy] WHERE IsActive = 1 AND IsDeleted = 0
      AND AppliedFrom <= SYSDATETIME() AND (AppliedTo IS NULL OR AppliedTo >= SYSDATETIME()) ORDER BY Priority DESC`, {});
    const policy = activePolicy.recordset[0];
    if (!policy) throw new ValidationError('No active pricing policy available');

    const membershipResult = await query(`SELECT TOP 1 mt.* FROM [Operations].[UserMembership] um
      JOIN [Operations].[MembershipTier] mt ON um.MembershipTierID = mt.MembershipTierID
      WHERE um.UserID = @UserID AND um.IsActive = 1 AND (um.ExpiresAt IS NULL OR um.ExpiresAt > SYSDATETIME())`, { UserID });
    const membership = membershipResult.recordset[0];

    const sessionCode = `SES-${new Date().toISOString().slice(0,10).replace(/-/g,'')}-${Date.now().toString(36).toUpperCase()}`;

    const result = await query(`INSERT INTO [Operations].[ChargingSession]
      (SessionCode, UserID, VehicleID, PointID, StationID, PolicyID, MembershipTierID, StartTime,
       StartBatteryPercent, MeterStart, SessionSource, SessionType, SessionStatus, CreatedAt)
      OUTPUT INSERTED.*
      VALUES (@Code, @UserID, @VehicleID, @PointID, @StationID, @PolicyID, @MembershipTierID, SYSDATETIME(),
       @BatteryPct, @MeterStart, @Source, @Type, 'Charging', SYSDATETIME())`, {
      Code: sessionCode, UserID, VehicleID: VehicleID || null, PointID, StationID: point.StationID,
      PolicyID: policy.PolicyID, MembershipTierID: membership?.MembershipTierID || null,
      BatteryPct: StartBatteryPercent || null, MeterStart: MeterStart || null,
      Source: SessionSource || 'MobileApp', Type: SessionType || 'Public',
    });
    const session = result.recordset[0];

    await query(`UPDATE [Infrastructure].[ChargingPoint] SET PointStatus = 'Busy', UpdatedAt = SYSDATETIME() WHERE PointID = @PointID`, { PointID });

    await query(`INSERT INTO [Audit].[SessionStatusHistory] (SessionID, PreviousStatus, NewStatus, ChangedAt)
      VALUES (@SessionID, NULL, 'Charging', SYSDATETIME())`, { SessionID: session.SessionID });

    return successResponse(new ChargingSession(session), 'Charging session started');
  }

  async endSession(sessionId, { EndBatteryPercent, MeterEnd, StopReason }) {
    const sessionResult = await query(`SELECT * FROM [Operations].[ChargingSession] WHERE SessionID = @SessionID AND IsDeleted = 0`, { SessionID: sessionId });
    if (sessionResult.recordset.length === 0) throw new NotFoundError('ChargingSession');
    const session = sessionResult.recordset[0];
    if (session.SessionStatus !== 'Charging') throw new ValidationError(`Session is ${session.SessionStatus}, not Charging`);

    const now = new Date();
    const start = new Date(session.StartTime);
    const durationMinutes = Math.round((now - start) / 60000);

    const meterResult = await query(`SELECT EnergyDeliveredKWh FROM [Monitoring].[PointTelemetry] WHERE PointID = @PointID ORDER BY RecordedAt DESC`, { PointID: session.PointID });
    const latestKWh = meterResult.recordset[0]?.EnergyDeliveredKWh || null;

    const totalKWh = latestKWh || (MeterEnd && session.MeterStart ? MeterEnd - session.MeterStart : null);
    const avgPowerKW = totalKWh && durationMinutes > 0 ? (totalKWh / (durationMinutes / 60)) : null;

    const policyResult = await query(`SELECT * FROM [Operations].[PricingPolicy] WHERE PolicyID = @PolicyID`, { PolicyID: session.PolicyID });
    const policy = policyResult.recordset[0];
    let costBeforeDiscount = totalKWh && policy ? totalKWh * parseFloat(policy.BasePricePerKWh) : null;

    const isPeak = await this._checkPeakHour(now);
    if (isPeak && costBeforeDiscount) costBeforeDiscount *= 1.5;

    let discountAmount = 0;
    if (session.MembershipTierID) {
      const tierResult = await query(`SELECT DiscountPercent FROM [Operations].[MembershipTier] WHERE MembershipTierID = @TierID`, { TierID: session.MembershipTierID });
      if (tierResult.recordset.length > 0) {
        discountAmount = costBeforeDiscount ? (costBeforeDiscount * parseFloat(tierResult.recordset[0].DiscountPercent) / 100) : 0;
      }
    }
    const costTotal = costBeforeDiscount ? costBeforeDiscount - discountAmount : null;

    await query(`UPDATE [Operations].[ChargingSession] SET
      EndTime = SYSDATETIME(), EndBatteryPercent = @EndBattery, MeterEnd = @MeterEnd,
      TotalKWh = @TotalKWh, ChargingDurationMinutes = @Duration, AveragePowerKW = @AvgPowerKW,
      MaxPowerKW = @AvgPowerKW, CostBeforeDiscount = @CostBefore, DiscountAmount = @Discount,
      CostTotal = @CostTotal, StopReason = @StopReason, SessionStatus = 'Completed', UpdatedAt = SYSDATETIME()
      WHERE SessionID = @SessionID`, {
      SessionID: sessionId, EndBattery: EndBatteryPercent || null, MeterEnd: MeterEnd || null,
      TotalKWh: totalKWh, Duration: durationMinutes, AvgPowerKW: avgPowerKW,
      CostBefore: costBeforeDiscount, Discount: discountAmount, CostTotal: costTotal,
      StopReason: StopReason || 'Completed',
    });

    await query(`UPDATE [Infrastructure].[ChargingPoint] SET PointStatus = 'Available', UpdatedAt = SYSDATETIME() WHERE PointID = @PointID`, { PointID: session.PointID });

    await query(`INSERT INTO [Audit].[SessionStatusHistory] (SessionID, PreviousStatus, NewStatus, ChangedAt)
      VALUES (@SessionID, 'Charging', 'Completed', SYSDATETIME())`, { SessionID: sessionId });

    const updated = await query(`SELECT * FROM [Operations].[ChargingSession] WHERE SessionID = @SessionID`, { SessionID: sessionId });
    return successResponse(new ChargingSession(updated.recordset[0]), 'Charging session completed');
  }

  async cancelSession(sessionId, reason) {
    const session = await query(`SELECT * FROM [Operations].[ChargingSession] WHERE SessionID = @SessionID AND IsDeleted = 0`, { SessionID: sessionId });
    if (session.recordset.length === 0) throw new NotFoundError('ChargingSession');
    const s = session.recordset[0];
    if (!['Charging', 'Pending'].includes(s.SessionStatus)) throw new ValidationError(`Cannot cancel session with status ${s.SessionStatus}`);

    await query(`UPDATE [Operations].[ChargingSession] SET SessionStatus = 'Cancelled', StopReason = @Reason, UpdatedAt = SYSDATETIME() WHERE SessionID = @SessionID`,
      { SessionID: sessionId, Reason: reason || 'CancelledByUser' });
    await query(`UPDATE [Infrastructure].[ChargingPoint] SET PointStatus = 'Available', UpdatedAt = SYSDATETIME() WHERE PointID = @PointID`, { PointID: s.PointID });
    await query(`INSERT INTO [Audit].[SessionStatusHistory] (SessionID, PreviousStatus, NewStatus, ChangeReason, ChangedAt)
      VALUES (@SessionID, @Prev, 'Cancelled', @Reason, SYSDATETIME())`, { SessionID: sessionId, Prev: s.SessionStatus, Reason: reason || null });

    return successResponse(null, 'Charging session cancelled');
  }

  async getActiveSessions(filters = {}) {
    let q = `SELECT cs.*, u.Username, up.FullName, s.StationCode, s.StationName, p.PointCode, v.PlateNumber
      FROM [Operations].[ChargingSession] cs
      JOIN [Users].[User] u ON cs.UserID = u.UserID
      LEFT JOIN [Users].[UserProfile] up ON u.UserID = up.UserID
      JOIN [Infrastructure].[ChargingStation] s ON cs.StationID = s.StationID
      JOIN [Infrastructure].[ChargingPoint] p ON cs.PointID = p.PointID
      LEFT JOIN [Users].[Vehicle] v ON cs.VehicleID = v.VehicleID
      WHERE cs.IsDeleted = 0`;
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

  async _checkPeakHour(date) {
    const hour = date.getHours();
    const day = date.getDay();
    if (day >= 1 && day <= 5 && (hour >= 17 && hour < 19)) return true;
    if (hour >= 22 || hour < 5) return false;
    return false;
  }
}

module.exports = new ChargingSessionService();
