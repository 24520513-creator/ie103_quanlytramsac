const BaseRepository = require('./BaseRepository');
const { AuditLog, StationStatusHistory, PointStatusHistory, SessionStatusHistory, SchemaChangeLog } = require('../models/Audit');

const AuditLogRepository = new BaseRepository('AuditLog', 'Audit', 'AuditID', AuditLog);
const StationStatusHistoryRepository = new BaseRepository('StationStatusHistory', 'Audit', 'StatusHistoryID', StationStatusHistory);
const PointStatusHistoryRepository = new BaseRepository('PointStatusHistory', 'Audit', 'StatusHistoryID', PointStatusHistory);
const SessionStatusHistoryRepository = new BaseRepository('SessionStatusHistory', 'Audit', 'StatusHistoryID', SessionStatusHistory);
const SchemaChangeLogRepository = new BaseRepository('SchemaChangeLog', 'Audit', 'ChangeID', SchemaChangeLog);

module.exports = { AuditLogRepository, StationStatusHistoryRepository, PointStatusHistoryRepository, SessionStatusHistoryRepository, SchemaChangeLogRepository };
