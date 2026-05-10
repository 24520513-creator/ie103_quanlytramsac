const BaseRepository = require('./BaseRepository');
const { PricingPolicy, ChargingSession } = require('../models/Operations');

const PricingPolicyRepository = new BaseRepository('PricingPolicy', 'Operations', 'PolicyID', PricingPolicy);
const ChargingSessionRepository = new BaseRepository('ChargingSession', 'Operations', 'SessionID', ChargingSession);

module.exports = { PricingPolicyRepository, ChargingSessionRepository };
