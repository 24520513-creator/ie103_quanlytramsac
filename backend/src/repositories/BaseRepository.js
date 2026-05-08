const { query, sql } = require('../config/database');

class BaseRepository {
  constructor(tableName, schemaName, primaryKey, modelClass) {
    this.tableName = `[${schemaName}].[${tableName}]`;
    this.schemaName = schemaName;
    this.primaryKey = primaryKey;
    this.modelClass = modelClass;
    this.auditColumns = 'CreatedAt, UpdatedAt, IsDeleted, DeletedAt';
  }

  async findAll(filters = {}) {
    let q = `SELECT * FROM ${this.tableName} WHERE 1=1`;
    const params = {};
    if (filters.isDeleted !== undefined) {
      q += ` AND IsDeleted = @IsDeleted`;
      params.IsDeleted = filters.isDeleted ? 1 : 0;
    } else {
      q += ` AND IsDeleted = 0`;
    }
    if (filters.isActive !== undefined) {
      if (await this._hasColumn('IsActive')) {
        q += ` AND IsActive = @IsActive`;
        params.IsActive = filters.IsActive ?? 1;
      }
    }
    if (filters.status) {
      q += ` AND ${this._getStatusColumn()} = @Status`;
      params.Status = filters.status;
    }
    if (filters.search) {
      q += ` AND (CAST(${this.primaryKey} AS NVARCHAR) LIKE @Search OR 1=0)`;
      params.Search = `%${filters.search}%`;
    }
    if (filters.page && filters.limit) {
      const offset = (filters.page - 1) * filters.limit;
      q += ` ORDER BY ${this.primaryKey} DESC OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY`;
      params.Offset = offset;
      params.Limit = filters.limit;
    }
    const result = await query(q, params);
    return (result.recordset || []).map(r => new this.modelClass(r));
  }

  async findById(id) {
    const q = `SELECT * FROM ${this.tableName} WHERE ${this.primaryKey} = @Id AND IsDeleted = 0`;
    const result = await query(q, { Id: id });
    if (!result.recordset || result.recordset.length === 0) return null;
    return new this.modelClass(result.recordset[0]);
  }

  async create(data) {
    const columns = Object.keys(data).filter(k => k !== this.primaryKey && !k.startsWith('_'));
    const colNames = columns.map(c => `[${c}]`).join(', ');
    const colParams = columns.map(c => `@${c}`).join(', ');
    const q = `INSERT INTO ${this.tableName} (${colNames}) OUTPUT INSERTED.* VALUES (${colParams})`;
    const result = await query(q, data);
    if (!result.recordset || result.recordset.length === 0) return null;
    return new this.modelClass(result.recordset[0]);
  }

  async update(id, data) {
    const columns = Object.keys(data).filter(k => k !== this.primaryKey && !k.startsWith('_'));
    const setClause = columns.map(c => `[${c}] = @${c}`).join(', ');
    const q = `UPDATE ${this.tableName} SET ${setClause}, UpdatedAt = SYSDATETIME() OUTPUT INSERTED.* WHERE ${this.primaryKey} = @Id AND IsDeleted = 0`;
    const result = await query(q, { ...data, Id: id });
    if (!result.recordset || result.recordset.length === 0) return null;
    return new this.modelClass(result.recordset[0]);
  }

  async delete(id, soft = true) {
    if (soft) {
      const q = `UPDATE ${this.tableName} SET IsDeleted = 1, DeletedAt = SYSDATETIME(), UpdatedAt = SYSDATETIME() WHERE ${this.primaryKey} = @Id`;
      return query(q, { Id: id });
    } else {
      const q = `DELETE FROM ${this.tableName} WHERE ${this.primaryKey} = @Id`;
      return query(q, { Id: id });
    }
  }

  async count(filters = {}) {
    let q = `SELECT COUNT(*) AS Total FROM ${this.tableName} WHERE IsDeleted = 0`;
    const params = {};
    if (filters.status) {
      q += ` AND ${this._getStatusColumn()} = @Status`;
      params.Status = filters.status;
    }
    const result = await query(q, params);
    return result.recordset[0]?.Total || 0;
  }

  async findBy(conditions) {
    const clauses = Object.entries(conditions).map(([k]) => `[${k}] = @${k}`);
    const q = `SELECT * FROM ${this.tableName} WHERE ${clauses.join(' AND ')} AND IsDeleted = 0`;
    const result = await query(q, conditions);
    return (result.recordset || []).map(r => new this.modelClass(r));
  }

  async findOneBy(conditions) {
    const results = await this.findBy(conditions);
    return results.length > 0 ? results[0] : null;
  }

  async exists(id) {
    const q = `SELECT COUNT(*) AS Cnt FROM ${this.tableName} WHERE ${this.primaryKey} = @Id AND IsDeleted = 0`;
    const result = await query(q, { Id: id });
    return (result.recordset[0]?.Cnt || 0) > 0;
  }

  async _hasColumn(colName) {
    const q = `SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = @Schema AND TABLE_NAME = @Table AND COLUMN_NAME = @Col`;
    const result = await query(q, { Schema: this.schemaName, Table: this.tableName.replace(/[\[\]]/g, '').split('.')[1], Col: colName });
    return result.recordset.length > 0;
  }

  _getStatusColumn() {
    const statusCols = ['SessionStatus', 'TransactionStatus', 'PointStatus', 'StationStatus', 'ScheduleStatus', 'InvoiceStatus', 'AlertStatus', 'AccountStatus', 'Status'];
    return statusCols[0];
  }
}

module.exports = BaseRepository;
