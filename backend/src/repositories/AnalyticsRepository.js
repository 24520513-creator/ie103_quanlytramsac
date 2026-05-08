const BaseRepository = require('./BaseRepository');
const { DailyStationKPI, DailyFranchiseKPI, HourlySessionAgg } = require('../models/Analytics');

const DailyStationKPIRepository = new BaseRepository('DailyStationKPI', 'Analytics', 'KPIID', DailyStationKPI);
const DailyFranchiseKPIRepository = new BaseRepository('DailyFranchiseKPI', 'Analytics', 'KPIID', DailyFranchiseKPI);
const HourlySessionAggRepository = new BaseRepository('HourlySessionAgg', 'Analytics', 'AggID', HourlySessionAgg);

module.exports = { DailyStationKPIRepository, DailyFranchiseKPIRepository, HourlySessionAggRepository };
