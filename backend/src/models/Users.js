const BaseModel = require('./BaseModel');

class UserModel extends BaseModel {
  constructor(row) {
    super();
    if (row) {
      this.UserID = row.UserID;
      this.UserGuid = row.UserGuid;
      this.Username = row.Username;
      this.Email = row.Email;
      this.Phone = row.Phone;
      this.EmailConfirmed = row.EmailConfirmed ?? false;
      this.PhoneConfirmed = row.PhoneConfirmed ?? false;
      this.AccountStatus = row.AccountStatus;
      this.AccountTier = row.AccountTier;
      this.FailedLoginAttempts = row.FailedLoginAttempts ?? 0;
      this.LockoutEnd = row.LockoutEnd;
      this.LastLoginAt = row.LastLoginAt;
      this.IsDeleted = row.IsDeleted ?? false;
      this.DeletedAt = row.DeletedAt;
      this.CreatedBy = row.CreatedBy;
      this.UpdatedBy = row.UpdatedBy;
    }
  }
}

class UserProfile extends BaseModel {
  constructor(row) {
    super();
    if (row) {
      this.UserProfileID = row.UserProfileID;
      this.UserID = row.UserID;
      this.FullName = row.FullName;
      this.DisplayName = row.DisplayName;
      this.AvatarUrl = row.AvatarUrl;
      this.DateOfBirth = row.DateOfBirth;
      this.Gender = row.Gender;
      this.AddressID = row.AddressID;
      this.NationalID = row.NationalID;
      this.TaxID = row.TaxID;
      this.EmergencyContact = row.EmergencyContact;
      this.EmergencyPhone = row.EmergencyPhone;
      this.PreferredLanguage = row.PreferredLanguage;
      this.NotificationEmail = row.NotificationEmail ?? true;
      this.NotificationSMS = row.NotificationSMS ?? false;
      this.NotificationPush = row.NotificationPush ?? true;
    }
  }
}

class UserCredential extends BaseModel {
  constructor(row) {
    super();
    if (row) {
      this.CredentialID = row.CredentialID;
      this.UserID = row.UserID;
      this.PasswordHash = row.PasswordHash;
      this.PasswordSalt = row.PasswordSalt;
      this.HashAlgorithm = row.HashAlgorithm;
      this.MFAEnabled = row.MFAEnabled ?? false;
      this.MFASecret = row.MFASecret;
      this.MFAType = row.MFAType;
      this.PasswordChangedAt = row.PasswordChangedAt;
      this.PasswordExpiresAt = row.PasswordExpiresAt;
      this.RequirePasswordChange = row.RequirePasswordChange ?? false;
    }
  }
}

class UserSession extends BaseModel {
  constructor(row) {
    super();
    if (row) {
      this.SessionID = row.SessionID;
      this.UserID = row.UserID;
      this.SessionToken = row.SessionToken;
      this.RefreshToken = row.RefreshToken;
      this.IPAddress = row.IPAddress;
      this.UserAgent = row.UserAgent;
      this.DeviceInfo = row.DeviceInfo;
      this.LoginAt = row.LoginAt;
      this.LastActivityAt = row.LastActivityAt;
      this.ExpiresAt = row.ExpiresAt;
      this.LogoutAt = row.LogoutAt;
      this.IsRevoked = row.IsRevoked ?? false;
      this.RevokedAt = row.RevokedAt;
    }
  }
}

class UserLoginHistory extends BaseModel {
  constructor(row) {
    super();
    if (row) {
      this.LoginHistoryID = row.LoginHistoryID;
      this.UserID = row.UserID;
      this.LoginAt = row.LoginAt;
      this.IPAddress = row.IPAddress;
      this.UserAgent = row.UserAgent;
      this.LoginSuccess = row.LoginSuccess;
      this.FailureReason = row.FailureReason;
      this.AuthMethod = row.AuthMethod;
    }
  }
}

class UserRole extends BaseModel {
  constructor(row) {
    super();
    if (row) {
      this.UserRoleID = row.UserRoleID;
      this.UserID = row.UserID;
      this.RoleID = row.RoleID;
      this.AssignedAt = row.AssignedAt;
      this.AssignedBy = row.AssignedBy;
      this.IsActive = row.IsActive ?? true;
      this.ExpiresAt = row.ExpiresAt;
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
      this.VIN = row.VIN;
      this.Brand = row.Brand;
      this.Model = row.Model;
      this.ModelYear = row.ModelYear;
      this.BatteryCapacityKWh = row.BatteryCapacityKWh;
      this.ConnectorType = row.ConnectorType;
      this.IsDefault = row.IsDefault ?? false;
      this.IsDeleted = row.IsDeleted ?? false;
      this.DeletedAt = row.DeletedAt;
    }
  }
}

class UserPaymentMethod extends BaseModel {
  constructor(row) {
    super();
    if (row) {
      this.PaymentMethodID = row.PaymentMethodID;
      this.UserID = row.UserID;
      this.MethodType = row.MethodType;
      this.MethodName = row.MethodName;
      this.MaskedIdentifier = row.MaskedIdentifier;
      this.ExpiryMonth = row.ExpiryMonth;
      this.ExpiryYear = row.ExpiryYear;
      this.IsDefault = row.IsDefault ?? false;
      this.IsVerified = row.IsVerified ?? false;
      this.IsActive = row.IsActive ?? true;
    }
  }
}

module.exports = {
  UserModel, UserProfile, UserCredential, UserSession,
  UserLoginHistory, UserRole, Vehicle, UserPaymentMethod,
};
