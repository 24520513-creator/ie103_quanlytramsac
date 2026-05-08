const BaseModel = require('./BaseModel');

class PricingPolicy extends BaseModel {
  constructor(row) {
    super();
    if (row) {
      this.PolicyID = row.PolicyID;
      this.PolicyCode = row.PolicyCode;
      this.PolicyName = row.PolicyName;
      this.PolicyType = row.PolicyType;
      this.Description = row.Description;
      this.BasePricePerKWh = row.BasePricePerKWh;
      this.CurrencyCode = row.CurrencyCode;
      this.MinChargeFee = row.MinChargeFee;
      this.MaxChargeFee = row.MaxChargeFee;
      this.ParkingFeePerMin = row.ParkingFeePerMin;
      this.OverstayPenaltyPerMin = row.OverstayPenaltyPerMin;
      this.AppliedFrom = row.AppliedFrom;
      this.AppliedTo = row.AppliedTo;
      this.Priority = row.Priority;
      this.IsActive = row.IsActive ?? true;
      this.IsDeleted = row.IsDeleted ?? false;
      this.DeletedAt = row.DeletedAt;
      this.CreatedBy = row.CreatedBy;
      this.UpdatedBy = row.UpdatedBy;
    }
  }
}

class PricingRule extends BaseModel {
  constructor(row) {
    super();
    if (row) {
      this.PricingRuleID = row.PricingRuleID;
      this.PolicyID = row.PolicyID;
      this.RuleName = row.RuleName;
      this.RuleType = row.RuleType;
      this.ConditionJson = row.ConditionJson;
      this.AdjustmentType = row.AdjustmentType;
      this.AdjustmentValue = row.AdjustmentValue;
      this.Priority = row.Priority;
      this.IsActive = row.IsActive ?? true;
    }
  }
}

class PeakHourDefinition extends BaseModel {
  constructor(row) {
    super();
    if (row) {
      this.PeakHourID = row.PeakHourID;
      this.RegionID = row.RegionID;
      this.DayOfWeek = row.DayOfWeek;
      this.StartHour = row.StartHour;
      this.EndHour = row.EndHour;
      this.IsPeak = row.IsPeak;
      this.Multiplier = row.Multiplier;
      this.IsActive = row.IsActive ?? true;
    }
  }
}

class MembershipTier extends BaseModel {
  constructor(row) {
    super();
    if (row) {
      this.MembershipTierID = row.MembershipTierID;
      this.TierCode = row.TierCode;
      this.TierName = row.TierName;
      this.MinTotalKWh = row.MinTotalKWh;
      this.MinTotalSpend = row.MinTotalSpend;
      this.DiscountPercent = row.DiscountPercent;
      this.PrioritySupport = row.PrioritySupport ?? false;
      this.FreeParkingMinutes = row.FreeParkingMinutes;
      this.MonthlyFee = row.MonthlyFee;
      this.IsActive = row.IsActive ?? true;
    }
  }
}

class UserMembership extends BaseModel {
  constructor(row) {
    super();
    if (row) {
      this.UserMembershipID = row.UserMembershipID;
      this.UserID = row.UserID;
      this.MembershipTierID = row.MembershipTierID;
      this.StartedAt = row.StartedAt;
      this.ExpiresAt = row.ExpiresAt;
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
      this.MembershipTierID = row.MembershipTierID;
      this.StartTime = row.StartTime;
      this.EndTime = row.EndTime;
      this.StartBatteryPercent = row.StartBatteryPercent;
      this.EndBatteryPercent = row.EndBatteryPercent;
      this.MeterStart = row.MeterStart;
      this.MeterEnd = row.MeterEnd;
      this.TotalKWh = row.TotalKWh;
      this.ChargingDurationMinutes = row.ChargingDurationMinutes;
      this.AveragePowerKW = row.AveragePowerKW;
      this.MaxPowerKW = row.MaxPowerKW;
      this.CostBeforeDiscount = row.CostBeforeDiscount;
      this.DiscountAmount = row.DiscountAmount;
      this.CostTotal = row.CostTotal;
      this.CurrencyCode = row.CurrencyCode;
      this.StopReason = row.StopReason;
      this.SessionSource = row.SessionSource;
      this.SessionType = row.SessionType;
      this.SessionStatus = row.SessionStatus;
      this.OcppTransactionID = row.OcppTransactionID;
      this.IsDeleted = row.IsDeleted ?? false;
      this.DeletedAt = row.DeletedAt;
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
      this.ScheduledDate = row.ScheduledDate;
      this.CompletedDate = row.CompletedDate;
      this.MaintenanceType = row.MaintenanceType;
      this.TechnicianName = row.TechnicianName;
      this.TechnicianPhone = row.TechnicianPhone;
      this.Description = row.Description;
      this.ActionTaken = row.ActionTaken;
      this.PartsUsed = row.PartsUsed;
      this.Cost = row.Cost;
      this.ScheduleStatus = row.ScheduleStatus;
      this.Priority = row.Priority;
      this.IsDeleted = row.IsDeleted ?? false;
      this.DeletedAt = row.DeletedAt;
      this.CreatedBy = row.CreatedBy;
      this.UpdatedBy = row.UpdatedBy;
    }
  }
}

module.exports = {
  PricingPolicy, PricingRule, PeakHourDefinition,
  MembershipTier, UserMembership, ChargingSession, MaintenanceSchedule,
};
