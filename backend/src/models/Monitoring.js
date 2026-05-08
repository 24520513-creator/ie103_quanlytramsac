const BaseModel = require('./BaseModel');

class ErrorLog extends BaseModel {
  constructor(row) {
    super();
    if (row) {
      this.ErrorID = row.ErrorID;
      this.PointID = row.PointID;
      this.StationID = row.StationID;
      this.SessionID = row.SessionID;
      this.ErrorCode = row.ErrorCode;
      this.ErrorCategory = row.ErrorCategory;
      this.Severity = row.Severity;
      this.Title = row.Title;
      this.Description = row.Description;
      this.StackTrace = row.StackTrace;
      this.OccurredAt = row.OccurredAt;
      this.ResolvedAt = row.ResolvedAt;
      this.ResolvedBy = row.ResolvedBy;
      this.Resolution = row.Resolution;
      this.IsDeleted = row.IsDeleted ?? false;
    }
  }
}

class PointTelemetry extends BaseModel {
  constructor(row) {
    super();
    if (row) {
      this.TelemetryID = row.TelemetryID;
      this.PointID = row.PointID;
      this.Voltage = row.Voltage;
      this.Amperage = row.Amperage;
      this.PowerKW = row.PowerKW;
      this.TemperatureC = row.TemperatureC;
      this.EnergyDeliveredKWh = row.EnergyDeliveredKWh;
      this.CableStatus = row.CableStatus;
      this.ErrorFlags = row.ErrorFlags;
      this.FirmwareVersion = row.FirmwareVersion;
      this.RecordedAt = row.RecordedAt;
    }
  }
}

class StationHeartbeat extends BaseModel {
  constructor(row) {
    super();
    if (row) {
      this.HeartbeatID = row.HeartbeatID;
      this.StationID = row.StationID;
      this.NetworkStatus = row.NetworkStatus;
      this.ResponseTimeMs = row.ResponseTimeMs;
      this.SignalStrength = row.SignalStrength;
      this.UptimeSeconds = row.UptimeSeconds;
      this.IsHealthy = row.IsHealthy ?? true;
      this.RecordedAt = row.RecordedAt;
    }
  }
}

class AlertRule extends BaseModel {
  constructor(row) {
    super();
    if (row) {
      this.AlertRuleID = row.AlertRuleID;
      this.RuleName = row.RuleName;
      this.RuleCategory = row.RuleCategory;
      this.MetricName = row.MetricName;
      this.Condition = row.Condition;
      this.ThresholdValue = row.ThresholdValue;
      this.DurationSeconds = row.DurationSeconds;
      this.Severity = row.Severity;
      this.NotificationChannel = row.NotificationChannel;
      this.IsActive = row.IsActive ?? true;
    }
  }
}

class Alert extends BaseModel {
  constructor(row) {
    super();
    if (row) {
      this.AlertID = row.AlertID;
      this.AlertRuleID = row.AlertRuleID;
      this.PointID = row.PointID;
      this.StationID = row.StationID;
      this.AlertTitle = row.AlertTitle;
      this.AlertMessage = row.AlertMessage;
      this.MetricValue = row.MetricValue;
      this.Severity = row.Severity;
      this.AlertStatus = row.AlertStatus;
      this.AcknowledgedAt = row.AcknowledgedAt;
      this.AcknowledgedBy = row.AcknowledgedBy;
      this.ResolvedAt = row.ResolvedAt;
      this.ResolvedBy = row.ResolvedBy;
    }
  }
}

module.exports = { ErrorLog, PointTelemetry, StationHeartbeat, AlertRule, Alert };
