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
      this.AddressID = row.AddressID;
      this.ModelName = row.ModelName;
      this.Manufacturer = row.Manufacturer;
      this.MaxPowerKW = row.MaxPowerKW;
      this.ConnectorTypes = row.ConnectorTypes;
      this.Latitude = row.Latitude;
      this.Longitude = row.Longitude;
      this.StationStatus = row.StationStatus;
      this.ImageUrl = row.ImageUrl;
      this.Notes = row.Notes;
      this.IsActive = row.IsActive ?? true;
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
      this.ConnectorType = row.ConnectorType;
      this.PowerKW = row.PowerKW;
      this.SerialNumber = row.SerialNumber;
      this.PointStatus = row.PointStatus;
      this.IsActive = row.IsActive ?? true;
    }
  }
}

module.exports = {
  Country, Region, Address, Franchise,
  ChargingStation, ChargingPoint,
};
