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

class Booking extends BaseModel {
  constructor(row) {
    super();
    if (row) {
      this.BookingID = row.BookingID;
      this.UserID = row.UserID;
      this.PointID = row.PointID;
      this.StationID = row.StationID;
      this.VehicleID = row.VehicleID;
      this.BookingTime = row.BookingTime;
      this.StartTime = row.StartTime;
      this.EndTime = row.EndTime;
      this.Status = row.Status;
      this.Notes = row.Notes;
      this.CancelledAt = row.CancelledAt;
      this.CancelReason = row.CancelReason;
      this.CreatedAt = row.CreatedAt;
    }
  }
}

class MaintenanceSchedule extends BaseModel {
  constructor(row) {
    super();
    if (row) {
      this.MaintenanceID = row.MaintenanceID;
      this.StationID = row.StationID;
      this.PointID = row.PointID;
      this.ScheduledDate = row.ScheduledDate;
      this.MaintenanceType = row.MaintenanceType;
      this.Description = row.Description;
      this.PartsUsed = row.PartsUsed;
      this.Cost = row.Cost;
      this.Priority = row.Priority;
      this.Status = row.Status;
      this.CompletedAt = row.CompletedAt;
      this.CompletedBy = row.CompletedBy;
      this.CreatedAt = row.CreatedAt;
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
      this.SessionID = row.SessionID;
      this.Rating = row.Rating;
      this.Comment = row.Comment;
      this.CreatedAt = row.CreatedAt;
    }
  }
}

module.exports = {
  PricingPolicy, ChargingSession,
  Booking, MaintenanceSchedule, StationReview,
};
