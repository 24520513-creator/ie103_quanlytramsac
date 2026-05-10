const BaseRepository = require('./BaseRepository');
const {
  PricingPolicy, ChargingSession,
  Booking, MaintenanceSchedule, StationReview,
} = require('../models/Operations');

const PricingPolicyRepository = new BaseRepository('PricingPolicy', 'Operations', 'PolicyID', PricingPolicy);
const ChargingSessionRepository = new BaseRepository('ChargingSession', 'Operations', 'SessionID', ChargingSession);
const BookingRepository = new BaseRepository('Booking', 'Operations', 'BookingID', Booking);
const MaintenanceScheduleRepository = new BaseRepository('MaintenanceSchedule', 'Operations', 'MaintenanceID', MaintenanceSchedule);
const StationReviewRepository = new BaseRepository('StationReview', 'Operations', 'ReviewID', StationReview);

module.exports = {
  PricingPolicyRepository, ChargingSessionRepository,
  BookingRepository, MaintenanceScheduleRepository, StationReviewRepository,
};
