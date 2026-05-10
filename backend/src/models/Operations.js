const BaseModel = require('./BaseModel');

class PricingPolicy extends BaseModel {
  constructor(row) {
    super();
    if (row) {
      this.PolicyID = row.PolicyID;
      this.PolicyCode = row.PolicyCode;
      this.PolicyName = row.PolicyName;
      this.BasePricePerKWh = row.BasePricePerKWh;
      this.CurrencyCode = row.CurrencyCode;
      this.PeakMultiplier = row.PeakMultiplier;
      this.PeakStartHour = row.PeakStartHour;
      this.PeakEndHour = row.PeakEndHour;
      this.IsWeekendPeak = row.IsWeekendPeak ?? false;
      this.AppliedFrom = row.AppliedFrom;
      this.AppliedTo = row.AppliedTo;
      this.IsActive = row.IsActive ?? true;
    }
  }
}

class ChargingSession extends BaseModel {
  constructor(row) {
    super();
    if (row) {
      this.SessionID = row.SessionID;
      this.SessionCode = row.SessionCode;
      this.UserID = row.UserID;
      this.VehicleID = row.VehicleID;
      this.PointID = row.PointID;
      this.StationID = row.StationID;
      this.PolicyID = row.PolicyID;
      this.StartTime = row.StartTime;
      this.EndTime = row.EndTime;
      this.StartBatteryPercent = row.StartBatteryPercent;
      this.EndBatteryPercent = row.EndBatteryPercent;
      this.MeterStart = row.MeterStart;
      this.MeterEnd = row.MeterEnd;
      this.TotalKWh = row.TotalKWh;
      this.ChargingDurationMinutes = row.ChargingDurationMinutes;
      this.CostTotal = row.CostTotal;
      this.CurrencyCode = row.CurrencyCode;
      this.StopReason = row.StopReason;
      this.SessionStatus = row.SessionStatus;
    }
  }
}

module.exports = { PricingPolicy, ChargingSession };
