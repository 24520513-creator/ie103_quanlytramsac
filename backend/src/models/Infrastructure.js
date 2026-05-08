const BaseModel = require('./BaseModel');

class Country extends BaseModel {
  constructor(row) {
    super();
    if (row) {
      this.CountryID = row.CountryID;
      this.CountryCode = row.CountryCode;
      this.CountryName = row.CountryName;
      this.CurrencyCode = row.CurrencyCode;
      this.PhonePrefix = row.PhonePrefix;
      this.IsActive = row.IsActive ?? true;
    }
  }
}

class Region extends BaseModel {
  constructor(row) {
    super();
    if (row) {
      this.RegionID = row.RegionID;
      this.CountryID = row.CountryID;
      this.RegionCode = row.RegionCode;
      this.RegionName = row.RegionName;
      this.RegionType = row.RegionType;
      this.TimeZone = row.TimeZone;
      this.IsActive = row.IsActive ?? true;
    }
  }
}

class Address extends BaseModel {
  constructor(row) {
    super();
    if (row) {
      this.AddressID = row.AddressID;
      this.RegionID = row.RegionID;
      this.StreetAddress = row.StreetAddress;
      this.Ward = row.Ward;
      this.District = row.District;
      this.PostalCode = row.PostalCode;
      this.Latitude = row.Latitude;
      this.Longitude = row.Longitude;
      this.FullAddress = row.FullAddress;
      this.IsActive = row.IsActive ?? true;
    }
  }
}

class Franchise extends BaseModel {
  constructor(row) {
    super();
    if (row) {
      this.FranchiseID = row.FranchiseID;
      this.FranchiseCode = row.FranchiseCode;
      this.FranchiseName = row.FranchiseName;
      this.TaxCode = row.TaxCode;
      this.AddressID = row.AddressID;
      this.ContactPerson = row.ContactPerson;
      this.ContactPhone = row.ContactPhone;
      this.ContactEmail = row.ContactEmail;
      this.RevenueShareRate = row.RevenueShareRate;
      this.ContractSignedDate = row.ContractSignedDate;
      this.ContractExpiryDate = row.ContractExpiryDate;
      this.FranchiseTier = row.FranchiseTier;
      this.IsActive = row.IsActive ?? true;
      this.IsDeleted = row.IsDeleted ?? false;
      this.DeletedAt = row.DeletedAt;
      this.CreatedBy = row.CreatedBy;
      this.UpdatedBy = row.UpdatedBy;
    }
  }
}

class ElectricitySupplier extends BaseModel {
  constructor(row) {
    super();
    if (row) {
      this.SupplierID = row.SupplierID;
      this.SupplierCode = row.SupplierCode;
      this.SupplierName = row.SupplierName;
      this.CountryID = row.CountryID;
      this.ContactPhone = row.ContactPhone;
      this.ContactEmail = row.ContactEmail;
      this.IsActive = row.IsActive ?? true;
      this.IsDeleted = row.IsDeleted ?? false;
      this.DeletedAt = row.DeletedAt;
    }
  }
}

class StationModel extends BaseModel {
  constructor(row) {
    super();
    if (row) {
      this.StationModelID = row.StationModelID;
      this.ModelName = row.ModelName;
      this.Manufacturer = row.Manufacturer;
      this.MaxPowerKW = row.MaxPowerKW;
      this.ConnectorTypes = row.ConnectorTypes;
      this.OcppVersion = row.OcppVersion;
      this.IsOCPPCompliant = row.IsOCPPCompliant ?? true;
      this.IsActive = row.IsActive ?? true;
    }
  }
}

class ChargingStation extends BaseModel {
  constructor(row) {
    super();
    if (row) {
      this.StationID = row.StationID;
      this.StationCode = row.StationCode;
      this.StationName = row.StationName;
      this.FranchiseID = row.FranchiseID;
      this.StationModelID = row.StationModelID;
      this.AddressID = row.AddressID;
      this.SupplierID = row.SupplierID;
      this.Latitude = row.Latitude;
      this.Longitude = row.Longitude;
      this.MaxCapacityKW = row.MaxCapacityKW;
      this.OperatingHoursJson = row.OperatingHoursJson;
      this.InstallationDate = row.InstallationDate;
      this.FirmwareVersion = row.FirmwareVersion;
      this.NetworkStatus = row.NetworkStatus;
      this.StationStatus = row.StationStatus;
      this.HasGenerator = row.HasGenerator ?? false;
      this.HasSolarPanels = row.HasSolarPanels ?? false;
      this.ParkingSpots = row.ParkingSpots;
      this.ImageUrl = row.ImageUrl;
      this.Notes = row.Notes;
      this.IsDeleted = row.IsDeleted ?? false;
      this.DeletedAt = row.DeletedAt;
      this.CreatedBy = row.CreatedBy;
      this.UpdatedBy = row.UpdatedBy;
    }
  }
}

class ChargingPoint extends BaseModel {
  constructor(row) {
    super();
    if (row) {
      this.PointID = row.PointID;
      this.PointCode = row.PointCode;
      this.StationID = row.StationID;
      this.SerialNumber = row.SerialNumber;
      this.ConnectorType = row.ConnectorType;
      this.PowerKW = row.PowerKW;
      this.CurrentVoltage = row.CurrentVoltage;
      this.CurrentAmperage = row.CurrentAmperage;
      this.FirmwareVersion = row.FirmwareVersion;
      this.LastHeartbeat = row.LastHeartbeat;
      this.PointStatus = row.PointStatus;
      this.IsDeleted = row.IsDeleted ?? false;
      this.DeletedAt = row.DeletedAt;
    }
  }
}

class StationElectricityContract extends BaseModel {
  constructor(row) {
    super();
    if (row) {
      this.ContractID = row.ContractID;
      this.StationID = row.StationID;
      this.SupplierID = row.SupplierID;
      this.ContractNumber = row.ContractNumber;
      this.UnitPricePerKWh = row.UnitPricePerKWh;
      this.CurrencyCode = row.CurrencyCode;
      this.ContractFrom = row.ContractFrom;
      this.ContractTo = row.ContractTo;
      this.IsActive = row.IsActive ?? true;
      this.IsDeleted = row.IsDeleted ?? false;
      this.DeletedAt = row.DeletedAt;
    }
  }
}

class StationDocument extends BaseModel {
  constructor(row) {
    super();
    if (row) {
      this.DocumentID = row.DocumentID;
      this.StationID = row.StationID;
      this.DocumentType = row.DocumentType;
      this.DocumentName = row.DocumentName;
      this.DocumentUrl = row.DocumentUrl;
      this.ExpiryDate = row.ExpiryDate;
      this.IsVerified = row.IsVerified ?? false;
    }
  }
}

module.exports = {
  Country, Region, Address, Franchise, ElectricitySupplier,
  StationModel, ChargingStation, ChargingPoint,
  StationElectricityContract, StationDocument,
};
