const BaseRepository = require('./BaseRepository');
const { UserModel, Vehicle } = require('../models/Users');

const UserRepository = new BaseRepository('User', 'Users', 'UserID', UserModel);
const VehicleRepository = new BaseRepository('Vehicle', 'Users', 'VehicleID', Vehicle);

module.exports = { UserRepository, VehicleRepository };
