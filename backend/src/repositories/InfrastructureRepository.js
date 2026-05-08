const BaseRepository = require('./BaseRepository');
const { Country, Region, Address, Franchise, ElectricitySupplier, StationModel, ChargingStation, ChargingPoint, StationElectricityContract, StationDocument } = require('../models/Infrastructure');

const CountryRepository = new BaseRepository('Country', 'Infrastructure', 'CountryID', Country);
const RegionRepository = new BaseRepository('Region', 'Infrastructure', 'RegionID', Region);
const AddressRepository = new BaseRepository('Address', 'Infrastructure', 'AddressID', Address);
const FranchiseRepository = new BaseRepository('Franchise', 'Infrastructure', 'FranchiseID', Franchise);
const ElectricitySupplierRepository = new BaseRepository('ElectricitySupplier', 'Infrastructure', 'SupplierID', ElectricitySupplier);
const StationModelRepository = new BaseRepository('StationModel', 'Infrastructure', 'StationModelID', StationModel);
const ChargingStationRepository = new BaseRepository('ChargingStation', 'Infrastructure', 'StationID', ChargingStation);
const ChargingPointRepository = new BaseRepository('ChargingPoint', 'Infrastructure', 'PointID', ChargingPoint);
const StationElectricityContractRepository = new BaseRepository('StationElectricityContract', 'Infrastructure', 'ContractID', StationElectricityContract);
const StationDocumentRepository = new BaseRepository('StationDocument', 'Infrastructure', 'DocumentID', StationDocument);

module.exports = {
  CountryRepository, RegionRepository, AddressRepository,
  FranchiseRepository, ElectricitySupplierRepository, StationModelRepository,
  ChargingStationRepository, ChargingPointRepository,
  StationElectricityContractRepository, StationDocumentRepository,
};
