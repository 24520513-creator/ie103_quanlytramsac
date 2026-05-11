const BaseRepository = require('./BaseRepository');
const {
  Country, Region, Address, Franchise,
  ChargingStation, ChargingPoint,
  ElectricitySupplier, ErrorLog,
} = require('../models/Infrastructure');

const CountryRepository = new BaseRepository('Country', 'Infrastructure', 'CountryID', Country);
const RegionRepository = new BaseRepository('Region', 'Infrastructure', 'RegionID', Region);
const AddressRepository = new BaseRepository('Address', 'Infrastructure', 'AddressID', Address);
const FranchiseRepository = new BaseRepository('Franchise', 'Infrastructure', 'FranchiseID', Franchise);
const ChargingStationRepository = new BaseRepository('ChargingStation', 'Infrastructure', 'StationID', ChargingStation);
const ChargingPointRepository = new BaseRepository('ChargingPoint', 'Infrastructure', 'PointID', ChargingPoint);
const ElectricitySupplierRepository = new BaseRepository('ElectricitySupplier', 'Infrastructure', 'SupplierID', ElectricitySupplier);
const ErrorLogRepository = new BaseRepository('ErrorLog', 'Infrastructure', 'ErrorID', ErrorLog);

module.exports = {
  CountryRepository, RegionRepository, AddressRepository,
  FranchiseRepository, ChargingStationRepository, ChargingPointRepository,
  ElectricitySupplierRepository, ErrorLogRepository,
};
