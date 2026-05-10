const BaseRepository = require('./BaseRepository');
const { UserModel, Vehicle, Notification } = require('../models/Users');

const UserRepository = new BaseRepository('User', 'Users', 'UserID', UserModel);
const VehicleRepository = new BaseRepository('Vehicle', 'Users', 'VehicleID', Vehicle);
const NotificationRepository = new BaseRepository('Notification', 'Users', 'NotificationID', Notification);

module.exports = { UserRepository, VehicleRepository, NotificationRepository };
