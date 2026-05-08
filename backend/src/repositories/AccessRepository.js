const BaseRepository = require('./BaseRepository');
const { Permission, Role, RolePermission } = require('../models/Access');

const PermissionRepository = new BaseRepository('Permission', 'Access', 'PermissionID', Permission);
const RoleRepository = new BaseRepository('Role', 'Access', 'RoleID', Role);
const RolePermissionRepository = new BaseRepository('RolePermission', 'Access', 'RolePermissionID', RolePermission);

module.exports = { PermissionRepository, RoleRepository, RolePermissionRepository };
