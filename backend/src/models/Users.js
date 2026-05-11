const BaseModel = require('./BaseModel');

class UserModel extends BaseModel {
  constructor(row) {
    super();
    if (row) {
      this.UserID = row.UserID;
      this.Username = row.Username;
      this.Email = row.Email;
      this.Phone = row.Phone;
      this.PasswordHash = row.PasswordHash;
      this.FullName = row.FullName;
      this.AvatarUrl = row.AvatarUrl;
      this.Role = row.Role;
      this.FranchiseID = row.FranchiseID;
      this.AccountStatus = row.AccountStatus;
      this.FailedLoginAttempts = row.FailedLoginAttempts ?? 0;
      this.LockoutEnd = row.LockoutEnd;
      this.LastLoginAt = row.LastLoginAt;
      this.CreatedAt = row.CreatedAt;
      this.UpdatedAt = row.UpdatedAt;
    }
  }
}

class Vehicle extends BaseModel {
  constructor(row) {
    super();
    if (row) {
      this.VehicleID = row.VehicleID;
      this.UserID = row.UserID;
      this.PlateNumber = row.PlateNumber;
      this.Brand = row.Brand;
      this.Model = row.Model;
      this.ModelYear = row.ModelYear;
      this.BatteryCapacityKWh = row.BatteryCapacityKWh;
      this.ConnectorType = row.ConnectorType;
      this.IsActive = row.IsActive ?? true;
      this.CreatedAt = row.CreatedAt;
      this.UpdatedAt = row.UpdatedAt;
    }
  }
}

class Notification extends BaseModel {
  constructor(row) {
    super();
    if (row) {
      this.NotificationID = row.NotificationID;
      this.UserID = row.UserID;
      this.Title = row.Title;
      this.Body = row.Body;
      this.Type = row.Type;
      this.ReferenceType = row.ReferenceType;
      this.ReferenceID = row.ReferenceID;
      this.IsRead = row.IsRead ?? false;
      this.CreatedAt = row.CreatedAt;
    }
  }
}

module.exports = { UserModel, Vehicle, Notification };
