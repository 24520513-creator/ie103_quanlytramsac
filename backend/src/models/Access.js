const BaseModel = require('./BaseModel');

class Permission extends BaseModel {
  constructor(row) {
    super();
    if (row) {
      this.PermissionID = row.PermissionID;
      this.PermissionCode = row.PermissionCode;
      this.PermissionName = row.PermissionName;
      this.Module = row.Module;
      this.Action = row.Action;
      this.Description = row.Description;
      this.IsActive = row.IsActive ?? true;
    }
  }
}

class Role extends BaseModel {
  constructor(row) {
    super();
    if (row) {
      this.RoleID = row.RoleID;
      this.RoleCode = row.RoleCode;
      this.RoleName = row.RoleName;
      this.RoleLevel = row.RoleLevel;
      this.Description = row.Description;
      this.IsActive = row.IsActive ?? true;
      this.IsSystem = row.IsSystem ?? false;
    }
  }
}

class RolePermission extends BaseModel {
  constructor(row) {
    super();
    if (row) {
      this.RolePermissionID = row.RolePermissionID;
      this.RoleID = row.RoleID;
      this.PermissionID = row.PermissionID;
      this.GrantedAt = row.GrantedAt;
      this.GrantedBy = row.GrantedBy;
    }
  }
}

module.exports = { Permission, Role, RolePermission };
