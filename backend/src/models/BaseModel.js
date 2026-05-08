class BaseModel {
  constructor() {
    this.CreatedAt = new Date().toISOString();
    this.UpdatedAt = null;
  }

  static mapKeys(row, map) {
    const obj = {};
    for (const [key, dbKey] of Object.entries(map)) {
      obj[key] = row[dbKey];
    }
    return obj;
  }
}

module.exports = BaseModel;
