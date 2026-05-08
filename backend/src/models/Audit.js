const BaseModel = require('./BaseModel');

class AuditLog extends BaseModel {
  constructor(row) {
    super();
    if (row) {
      this.AuditID = row.AuditID;
      this.TableName = row.TableName;
      this.RecordID = row.RecordID;
      this.Action = row.Action;
      this.OldValue = row.OldValue;
      this.NewValue = row.NewValue;
      this.ChangedColumns = row.ChangedColumns;
      this.ChangedByUserID = row.ChangedByUserID;
      this.ChangedByIP = row.ChangedByIP;
      this.ChangeReason = row.ChangeReason;
      this.ChangedAt = row.ChangedAt;
    }
  }
}

class StationStatusHistory extends BaseModel {
  constructor(row) {
    super();
    if (row) {
      this.StatusHistoryID = row.StatusHistoryID;
      this.StationID = row.StationID;
      this.PreviousStatus = row.PreviousStatus;
      this.NewStatus = row.NewStatus;
      this.ChangedByUserID = row.ChangedByUserID;
      this.ChangeReason = row.ChangeReason;
      this.ChangedAt = row.ChangedAt;
    }
  }
}

class PointStatusHistory extends BaseModel {
  constructor(row) {
    super();
    if (row) {
      this.StatusHistoryID = row.StatusHistoryID;
      this.PointID = row.PointID;
      this.PreviousStatus = row.PreviousStatus;
      this.NewStatus = row.NewStatus;
      this.ChangedByUserID = row.ChangedByUserID;
      this.ChangeReason = row.ChangeReason;
      this.ChangedAt = row.ChangedAt;
    }
  }
}

class SessionStatusHistory extends BaseModel {
  constructor(row) {
    super();
    if (row) {
      this.StatusHistoryID = row.StatusHistoryID;
      this.SessionID = row.SessionID;
      this.PreviousStatus = row.PreviousStatus;
      this.NewStatus = row.NewStatus;
      this.ChangedByUserID = row.ChangedByUserID;
      this.ChangeReason = row.ChangeReason;
      this.ChangedAt = row.ChangedAt;
    }
  }
}

class SchemaChangeLog extends BaseModel {
  constructor(row) {
    super();
    if (row) {
      this.ChangeID = row.ChangeID;
      this.ChangeVersion = row.ChangeVersion;
      this.ChangeDescription = row.ChangeDescription;
      this.ChangeScript = row.ChangeScript;
      this.AppliedBy = row.AppliedBy;
      this.AppliedAt = row.AppliedAt;
      this.Checksum = row.Checksum;
    }
  }
}

module.exports = { AuditLog, StationStatusHistory, PointStatusHistory, SessionStatusHistory, SchemaChangeLog };
