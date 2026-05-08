const BaseRepository = require('./BaseRepository');
const { PricingPolicy, PricingRule, PeakHourDefinition, MembershipTier, UserMembership, ChargingSession, MaintenanceSchedule } = require('../models/Operations');

const PricingPolicyRepository = new BaseRepository('PricingPolicy', 'Operations', 'PolicyID', PricingPolicy);
const PricingRuleRepository = new BaseRepository('PricingRule', 'Operations', 'PricingRuleID', PricingRule);
const PeakHourDefinitionRepository = new BaseRepository('PeakHourDefinition', 'Operations', 'PeakHourID', PeakHourDefinition);
const MembershipTierRepository = new BaseRepository('MembershipTier', 'Operations', 'MembershipTierID', MembershipTier);
const UserMembershipRepository = new BaseRepository('UserMembership', 'Operations', 'UserMembershipID', UserMembership);
const ChargingSessionRepository = new BaseRepository('ChargingSession', 'Operations', 'SessionID', ChargingSession);
const MaintenanceScheduleRepository = new BaseRepository('MaintenanceSchedule', 'Operations', 'ScheduleID', MaintenanceSchedule);

module.exports = {
  PricingPolicyRepository, PricingRuleRepository, PeakHourDefinitionRepository,
  MembershipTierRepository, UserMembershipRepository,
  ChargingSessionRepository, MaintenanceScheduleRepository,
};
