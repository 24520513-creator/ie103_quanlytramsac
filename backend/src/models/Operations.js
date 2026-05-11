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
      this.CreatedAt = row.CreatedAt;
      this.UpdatedAt = row.UpdatedAt;
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
      this.BookingID = row.BookingID;
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
      this.CreatedAt = row.CreatedAt;
      this.UpdatedAt = row.UpdatedAt;
    }
  }
}

class Booking extends BaseModel {
  constructor(row) {
    super();
    if (row) {
      this.BookingID = row.BookingID;
      this.BookingCode = row.BookingCode;
      this.UserID = row.UserID;
      this.PointID = row.PointID;
      this.StationID = row.StationID;
      this.VehicleID = row.VehicleID;
      this.BookedFrom = row.BookedFrom;
      this.BookedTo = row.BookedTo;
      this.Status = row.Status;
      this.CreatedAt = row.CreatedAt;
      this.UpdatedAt = row.UpdatedAt;
    }
  }
}

class MaintenanceSchedule extends BaseModel {
  constructor(row) {
    super();
    if (row) {
      this.ScheduleID = row.ScheduleID;
      this.StationID = row.StationID;
      this.PointID = row.PointID;
      this.ScheduledBy = row.ScheduledBy;
      this.ScheduledFrom = row.ScheduledFrom;
      this.ScheduledTo = row.ScheduledTo;
      this.MaintenanceType = row.MaintenanceType;
      this.Description = row.Description;
      this.Status = row.Status;
      this.CompletedAt = row.CompletedAt;
      this.Notes = row.Notes;
      this.CreatedAt = row.CreatedAt;
      this.UpdatedAt = row.UpdatedAt;
    }
  }
}

class StationReview extends BaseModel {
  constructor(row) {
    super();
    if (row) {
      this.ReviewID = row.ReviewID;
      this.UserID = row.UserID;
      this.StationID = row.StationID;
      this.Rating = row.Rating;
      this.Comment = row.Comment;
      this.CreatedAt = row.CreatedAt;
      this.UpdatedAt = row.UpdatedAt;
    }
  }
}

module.exports = {
  PricingPolicy, ChargingSession,
  Booking, MaintenanceSchedule, StationReview,
};
