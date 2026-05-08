const BaseRepository = require('./BaseRepository');
const { query } = require('../config/database');
const { UserModel, UserProfile, UserCredential, UserSession, UserLoginHistory, UserRole, Vehicle, UserPaymentMethod } = require('../models/Users');

const UserRepository = new BaseRepository('User', 'Users', 'UserID', UserModel);
const UserProfileRepository = new BaseRepository('UserProfile', 'Users', 'UserProfileID', UserProfile);
const UserCredentialRepository = new BaseRepository('UserCredential', 'Users', 'CredentialID', UserCredential);
const UserSessionRepository = new BaseRepository('UserSession', 'Users', 'SessionID', UserSession);
const UserLoginHistoryRepository = new BaseRepository('UserLoginHistory', 'Users', 'LoginHistoryID', UserLoginHistory);
const UserRoleRepository = new BaseRepository('UserRole', 'Users', 'UserRoleID', UserRole);
const VehicleRepository = new BaseRepository('Vehicle', 'Users', 'VehicleID', Vehicle);
const UserPaymentMethodRepository = new BaseRepository('UserPaymentMethod', 'Users', 'PaymentMethodID', UserPaymentMethod);

module.exports = {
  UserRepository, UserProfileRepository, UserCredentialRepository,
  UserSessionRepository, UserLoginHistoryRepository, UserRoleRepository,
  VehicleRepository, UserPaymentMethodRepository,
};
