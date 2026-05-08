const BaseRepository = require('./BaseRepository');
const { ErrorLog, PointTelemetry, StationHeartbeat, AlertRule, Alert } = require('../models/Monitoring');

const ErrorLogRepository = new BaseRepository('ErrorLog', 'Monitoring', 'ErrorID', ErrorLog);
const PointTelemetryRepository = new BaseRepository('PointTelemetry', 'Monitoring', 'TelemetryID', PointTelemetry);
const StationHeartbeatRepository = new BaseRepository('StationHeartbeat', 'Monitoring', 'HeartbeatID', StationHeartbeat);
const AlertRuleRepository = new BaseRepository('AlertRule', 'Monitoring', 'AlertRuleID', AlertRule);
const AlertRepository = new BaseRepository('Alert', 'Monitoring', 'AlertID', Alert);

module.exports = { ErrorLogRepository, PointTelemetryRepository, StationHeartbeatRepository, AlertRuleRepository, AlertRepository };
