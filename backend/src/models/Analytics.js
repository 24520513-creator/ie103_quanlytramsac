const BaseModel = require('./BaseModel');

class DailyStationKPI extends BaseModel {
  constructor(row) {
    super();
    if (row) {
      this.KPIID = row.KPIID;
      this.StationID = row.StationID;
      this.KpiDate = row.KpiDate;
      this.TotalSessions = row.TotalSessions;
      this.TotalKWh = row.TotalKWh;
      this.TotalRevenue = row.TotalRevenue;
      this.AvgPowerKW = row.AvgPowerKW;
      this.AvgChargingMinutes = row.AvgChargingMinutes;
      this.PeakConcurrentSessions = row.PeakConcurrentSessions;
      this.UniqueUsers = row.UniqueUsers;
      this.ErrorCount = row.ErrorCount;
      this.UptimePercent = row.UptimePercent;
      this.RevenuePerKWh = row.RevenuePerKWh;
    }
  }
}

class DailyFranchiseKPI extends BaseModel {
  constructor(row) {
    super();
    if (row) {
      this.KPIID = row.KPIID;
      this.FranchiseID = row.FranchiseID;
      this.KpiDate = row.KpiDate;
      this.TotalSessions = row.TotalSessions;
      this.TotalKWh = row.TotalKWh;
      this.TotalRevenue = row.TotalRevenue;
      this.CommissionAmount = row.CommissionAmount;
      this.ActiveStations = row.ActiveStations;
      this.TotalErrors = row.TotalErrors;
      this.UniqueUsers = row.UniqueUsers;
      this.AvgRevenuePerSession = row.AvgRevenuePerSession;
    }
  }
}

class HourlySessionAgg extends BaseModel {
  constructor(row) {
    super();
    if (row) {
      this.AggID = row.AggID;
      this.StationID = row.StationID;
      this.AggDate = row.AggDate;
      this.AggHour = row.AggHour;
      this.TotalSessions = row.TotalSessions;
      this.TotalKWh = row.TotalKWh;
      this.TotalRevenue = row.TotalRevenue;
      this.AvgDurationMin = row.AvgDurationMin;
    }
  }
}

module.exports = { DailyStationKPI, DailyFranchiseKPI, HourlySessionAgg };
