const { query } = require('../config/database');

const ALLOWED_COLUMNS = {
  Country: ['CountryCode','CountryName','CurrencyCode','PhonePrefix','IsActive'],
  Region: ['CountryID','RegionCode','RegionName','TimeZone','IsActive'],
  Address: ['RegionID','StreetAddress','Ward','District','PostalCode','Latitude','Longitude','FullAddress','IsActive'],
  Franchise: ['FranchiseCode','FranchiseName','TaxCode','AddressID','ContactPerson','ContactPhone','ContactEmail','RevenueShareRate','ContractSignedDate','IsActive'],
  ElectricitySupplier: ['SupplierCode','SupplierName','RegionID','UnitPricePerKWh','ContactPerson','ContactPhone','ContactEmail','ContractSignedDate','IsActive'],
  ChargingStation: ['StationCode','StationName','FranchiseID','AddressID','SupplierID','ModelName','Manufacturer','MaxPowerKW','ConnectorTypes','Latitude','Longitude','StationStatus','ImageUrl','Notes','IsActive'],
  ChargingPoint: ['PointCode','StationID','ConnectorType','PowerKW','SerialNumber','PointStatus','IsActive'],
  ErrorLog: ['PointID','StationID','ErrorCode','Severity','Description','OccurredAt','ResolvedAt','ResolvedBy','ResolutionNotes','IsActive'],
  User: ['Username','Email','Phone','PasswordHash','FullName','AvatarUrl','Role','FranchiseID','AccountStatus','FailedLoginAttempts','LockoutEnd','LastLoginAt'],
  Vehicle: ['UserID','PlateNumber','Brand','Model','ModelYear','BatteryCapacityKWh','ConnectorType','IsActive'],
  Notification: ['UserID','Title','Body','Type','ReferenceType','ReferenceID','IsRead'],
  PricingPolicy: ['PolicyCode','PolicyName','BasePricePerKWh','CurrencyCode','PeakMultiplier','PeakStartHour','PeakEndHour','IsWeekendPeak','AppliedFrom','AppliedTo','IsActive'],
  Booking: ['BookingCode','UserID','PointID','StationID','VehicleID','BookedFrom','BookedTo','Status'],
  ChargingSession: ['SessionCode','UserID','VehicleID','PointID','StationID','PolicyID','BookingID','StartTime','EndTime','StartBatteryPercent','EndBatteryPercent','MeterStart','MeterEnd','TotalKWh','ChargingDurationMinutes','CostTotal','CurrencyCode','StopReason','SessionStatus'],
  MaintenanceSchedule: ['StationID','PointID','ScheduledBy','ScheduledFrom','ScheduledTo','MaintenanceType','Description','Status','CompletedAt','Notes'],
  StationReview: ['UserID','StationID','Rating','Comment'],
  Wallet: ['UserID','WalletCode','Balance','CurrencyCode','IsActive','LastTransactionAt'],
  Transaction: ['TransactionCode','UserID','SessionID','TransactionType','Direction','Amount','CurrencyCode','TransactionStatus','PaymentMethod','Description','TransactedAt','SettledAt'],
  WalletTransaction: ['WalletID','TransactionID','Amount','BalanceBefore','BalanceAfter','Direction','TransactionType','Description'],
};

const TABLE_META = {
  Country:              { hasIsActive: true,  hasUpdatedAt: false, statusCol: null },
  Region:               { hasIsActive: true,  hasUpdatedAt: false, statusCol: null },
  Address:              { hasIsActive: true,  hasUpdatedAt: false, statusCol: null },
  Franchise:            { hasIsActive: true,  hasUpdatedAt: false, statusCol: null },
  ElectricitySupplier:  { hasIsActive: true,  hasUpdatedAt: false, statusCol: null },
  ChargingStation:      { hasIsActive: true,  hasUpdatedAt: true,  statusCol: 'StationStatus' },
  ChargingPoint:        { hasIsActive: true,  hasUpdatedAt: true,  statusCol: 'PointStatus' },
  ErrorLog:             { hasIsActive: true,  hasUpdatedAt: false, statusCol: null },
  User:                 { hasIsActive: false, hasUpdatedAt: true,  statusCol: 'AccountStatus' },
  Vehicle:              { hasIsActive: true,  hasUpdatedAt: true,  statusCol: null },
  Notification:         { hasIsActive: false, hasUpdatedAt: false, statusCol: 'IsRead' },
  PricingPolicy:        { hasIsActive: true,  hasUpdatedAt: true,  statusCol: null },
  Booking:              { hasIsActive: false, hasUpdatedAt: true,  statusCol: 'Status' },
  ChargingSession:      { hasIsActive: false, hasUpdatedAt: true,  statusCol: 'SessionStatus' },
  MaintenanceSchedule:  { hasIsActive: false, hasUpdatedAt: false, statusCol: 'Status' },
  StationReview:        { hasIsActive: false, hasUpdatedAt: true,  statusCol: null },
  Wallet:               { hasIsActive: true,  hasUpdatedAt: false, statusCol: null },
  Transaction:          { hasIsActive: false, hasUpdatedAt: false, statusCol: 'TransactionStatus' },
  WalletTransaction:    { hasIsActive: false, hasUpdatedAt: false, statusCol: null },
};

// Tables where HARD DELETE is NEVER allowed — soft-delete only
const PROTECTED_TABLES = new Set([
  'Transaction', 'WalletTransaction', 'User', 'ChargingSession',
  'Booking', 'Notification', 'StationReview', 'MaintenanceSchedule',
]);

class BaseRepository {
  constructor(tableName, schemaName, primaryKey, modelClass) {
    this.tableName = `[${schemaName}].[${tableName}]`;
    this.tableShortName = tableName;
    this.schemaName = schemaName;
    this.primaryKey = primaryKey;
    this.modelClass = modelClass;
    this.meta = TABLE_META[tableName] || { hasIsActive: false, hasUpdatedAt: false, statusCol: null };
    this.whitelist = ALLOWED_COLUMNS[tableName] || [];
  }

  _sanitize(data) {
    const safe = {};
    for (const key of Object.keys(data)) {
      if (this.whitelist.includes(key)) {
        safe[key] = data[key];
      }
    }
    return safe;
  }

  _isActiveClause(alias = '') {
    if (!this.meta.hasIsActive) return '';
    return ` AND ${alias}IsActive = 1`;
  }

  _setUpdatedAtClause() {
    if (!this.meta.hasUpdatedAt) return '';
    return `, UpdatedAt = SYSDATETIME()`;
  }

  async findAll(filters = {}) {
    let q = `SELECT * FROM ${this.tableName} WHERE 1=1`;
    const params = {};
    if (filters.isActive !== undefined && this.meta.hasIsActive) {
      q += ` AND IsActive = @IsActive`;
      params.IsActive = filters.isActive ? 1 : 0;
    } else if (this.meta.hasIsActive && filters.isActive === undefined) {
      q += ` AND IsActive = 1`;
    }
    if (filters.status && this.meta.statusCol) {
      q += ` AND ${this.meta.statusCol} = @Status`;
      params.Status = filters.status;
    }
    q += ` ORDER BY ${this.primaryKey} DESC`;
    if (filters.page && filters.limit) {
      const offset = (filters.page - 1) * filters.limit;
      q += ` OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY`;
      params.Offset = offset;
      params.Limit = filters.limit;
    }
    const result = await query(q, params);
    return (result.recordset || []).map(r => new this.modelClass(r));
  }

  async findById(id) {
    const q = `SELECT * FROM ${this.tableName} WHERE ${this.primaryKey} = @Id${this._isActiveClause()}`;
    const result = await query(q, { Id: id });
    if (!result.recordset || result.recordset.length === 0) return null;
    return new this.modelClass(result.recordset[0]);
  }

  async create(data) {
    const safe = this._sanitize(data);
    const columns = Object.keys(safe);
    if (columns.length === 0) throw new Error(`No allowed columns provided for ${this.tableShortName}`);
    const colNames = columns.map(c => `[${c}]`).join(', ');
    const colParams = columns.map(c => `@${c}`).join(', ');
    const q = `INSERT INTO ${this.tableName} (${colNames}) OUTPUT INSERTED.* VALUES (${colParams})`;
    const result = await query(q, safe);
    if (!result.recordset || result.recordset.length === 0) return null;
    return new this.modelClass(result.recordset[0]);
  }

  async update(id, data) {
    const safe = this._sanitize(data);
    const columns = Object.keys(safe);
    if (columns.length === 0) throw new Error(`No allowed columns provided for ${this.tableShortName}`);
    const setClause = columns.map(c => `[${c}] = @${c}`).join(', ');
    const q = `UPDATE ${this.tableName} SET ${setClause}${this._setUpdatedAtClause()} OUTPUT INSERTED.* WHERE ${this.primaryKey} = @Id`;
    const result = await query(q, { ...safe, Id: id });
    if (!result.recordset || result.recordset.length === 0) return null;
    return new this.modelClass(result.recordset[0]);
  }

  async delete(id) {
    if (PROTECTED_TABLES.has(this.tableShortName) || this.meta.hasIsActive) {
      const q = `UPDATE ${this.tableName} SET IsActive = 0${this._setUpdatedAtClause()} WHERE ${this.primaryKey} = @Id`;
      return query(q, { Id: id });
    }
    const q = `DELETE FROM ${this.tableName} WHERE ${this.primaryKey} = @Id`;
    return query(q, { Id: id });
  }

  async findBy(conditions) {
    const safe = this._sanitize(conditions);
    const clauses = Object.entries(safe).map(([k]) => `[${k}] = @${k}`);
    if (clauses.length === 0) {
      return this.findAll();
    }
    const q = `SELECT * FROM ${this.tableName} WHERE ${clauses.join(' AND ')}${this._isActiveClause()} ORDER BY ${this.primaryKey} DESC`;
    const result = await query(q, safe);
    return (result.recordset || []).map(r => new this.modelClass(r));
  }

  async findOneBy(conditions) {
    const results = await this.findBy(conditions);
    return results.length > 0 ? results[0] : null;
  }

  async count(filters = {}) {
    let q = `SELECT COUNT(*) AS Total FROM ${this.tableName} WHERE 1=1`;
    const params = {};
    if (filters.isActive !== undefined && this.meta.hasIsActive) {
      q += ` AND IsActive = @IsActive`;
      params.IsActive = filters.isActive ? 1 : 0;
    } else if (this.meta.hasIsActive && filters.isActive === undefined) {
      q += ` AND IsActive = 1`;
    }
    if (filters.status && this.meta.statusCol) {
      q += ` AND ${this.meta.statusCol} = @Status`;
      params.Status = filters.status;
    }
    const result = await query(q, params);
    return result.recordset[0]?.Total || 0;
  }
}

module.exports = BaseRepository;
