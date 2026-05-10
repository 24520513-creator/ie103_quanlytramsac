const express = require('express');
const router = express.Router();

const { authenticate, authorize } = require('../middleware/auth');
const { createCrudController } = require('../controllers/CrudController');
const { createCrudService } = require('../services/CrudFactory');
const authController = require('../controllers/AuthController');
const appController = require('../controllers/AppController');

const {
  CountryRepository, RegionRepository, AddressRepository,
  FranchiseRepository, ChargingStationRepository, ChargingPointRepository,
  ElectricitySupplierRepository, ErrorLogRepository,
} = require('../repositories/InfrastructureRepository');
const {
  UserRepository, VehicleRepository, NotificationRepository,
} = require('../repositories/UsersRepository');
const {
  PricingPolicyRepository, ChargingSessionRepository,
  BookingRepository, MaintenanceScheduleRepository, StationReviewRepository,
} = require('../repositories/OperationsRepository');
const {
  TransactionRepository, WalletRepository, WalletTransactionRepository,
} = require('../repositories/PaymentsRepository');

function registerCrudRoutes(basePath, repository, entityName, uniqueFields = [], middlewares = [authenticate]) {
  const service = createCrudService(repository, entityName, uniqueFields);
  const controller = createCrudController(service, entityName);
  const mw = [...middlewares];

  router.get(`${basePath}`, mw, controller.getAll);
  router.get(`${basePath}/:id`, mw, controller.getById);
  router.post(`${basePath}`, mw, controller.create);
  router.put(`${basePath}/:id`, mw, controller.update);
  router.delete(`${basePath}/:id`, mw, controller.delete);
}

// =============================================================================
// AUTH (public + authenticated)
// =============================================================================
router.post('/auth/register', authController.register);
router.post('/auth/login', authController.login);
router.post('/auth/forgot-password', authController.forgotPassword);
router.post('/auth/reset-password', authController.resetPassword);
router.get('/auth/profile', authenticate, authController.getProfile);
router.put('/auth/profile', authenticate, authController.updateProfile);

// =============================================================================
// INFRASTRUCTURE CRUD
// =============================================================================
registerCrudRoutes('/countries', CountryRepository, 'Country', ['CountryCode', 'CountryName']);
registerCrudRoutes('/regions', RegionRepository, 'Region', ['RegionCode']);
registerCrudRoutes('/addresses', AddressRepository, 'Address', []);
registerCrudRoutes('/franchises', FranchiseRepository, 'Franchise', ['FranchiseCode', 'TaxCode']);
registerCrudRoutes('/stations', ChargingStationRepository, 'ChargingStation', ['StationCode'], [authenticate]);
registerCrudRoutes('/points', ChargingPointRepository, 'ChargingPoint', ['PointCode'], [authenticate]);
registerCrudRoutes('/electricity-suppliers', ElectricitySupplierRepository, 'ElectricitySupplier', ['SupplierCode'], [authenticate, authorize('Admin')]);
registerCrudRoutes('/error-logs', ErrorLogRepository, 'ErrorLog', [], [authenticate, authorize('Admin', 'Manager')]);

// =============================================================================
// USERS CRUD
// =============================================================================
registerCrudRoutes('/users', UserRepository, 'User', ['Username', 'Email'], [authenticate, authorize('Admin')]);
registerCrudRoutes('/vehicles', VehicleRepository, 'Vehicle', ['PlateNumber'], [authenticate]);
registerCrudRoutes('/notifications', NotificationRepository, 'Notification', [], [authenticate]);

// =============================================================================
// OPERATIONS CRUD
// =============================================================================
registerCrudRoutes('/pricing-policies', PricingPolicyRepository, 'PricingPolicy', ['PolicyCode'], [authenticate, authorize('Admin')]);
registerCrudRoutes('/sessions-crud', ChargingSessionRepository, 'ChargingSession', ['SessionCode'], [authenticate]);
registerCrudRoutes('/bookings', BookingRepository, 'Booking', [], [authenticate]);
registerCrudRoutes('/maintenance-schedules', MaintenanceScheduleRepository, 'MaintenanceSchedule', [], [authenticate, authorize('Admin', 'Manager')]);
registerCrudRoutes('/station-reviews', StationReviewRepository, 'StationReview', [], [authenticate]);

// =============================================================================
// PAYMENTS CRUD
// =============================================================================
registerCrudRoutes('/transactions', TransactionRepository, 'Transaction', ['TransactionCode'], [authenticate]);
registerCrudRoutes('/wallets', WalletRepository, 'Wallet', ['WalletCode'], [authenticate]);
registerCrudRoutes('/wallet-transactions', WalletTransactionRepository, 'WalletTransaction', [], [authenticate]);

// =============================================================================
// SESSION WORKFLOWS
// =============================================================================
router.get('/sessions', authenticate, appController.getActiveSessions);
router.get('/sessions/my', authenticate, appController.getMySessions);
router.get('/sessions/history', authenticate, appController.getSessionHistory);
router.get('/sessions/:id', authenticate, appController.getSessionById);
router.post('/sessions/start', authenticate, appController.startSession);
router.post('/sessions/:id/end', authenticate, appController.endSession);
router.post('/sessions/:id/cancel', authenticate, appController.cancelSession);

// =============================================================================
// BOOKING WORKFLOWS
// =============================================================================
router.post('/bookings/:id/confirm', authenticate, appController.confirmBooking);
router.post('/bookings/:id/cancel', authenticate, appController.cancelBooking);
router.get('/bookings/availability', authenticate, appController.checkPointAvailability);

// =============================================================================
// MAINTENANCE WORKFLOWS
// =============================================================================
router.post('/maintenance', authenticate, authorize('Admin', 'Manager'), appController.scheduleMaintenance);
router.post('/maintenance/:id/complete', authenticate, authorize('Admin', 'Manager'), appController.completeMaintenance);
router.get('/maintenance/upcoming', authenticate, appController.getUpcomingMaintenance);

// =============================================================================
// ERROR WORKFLOWS
// =============================================================================
router.post('/errors/:id/resolve', authenticate, authorize('Admin', 'Manager'), appController.resolveError);

// =============================================================================
// NOTIFICATION WORKFLOWS
// =============================================================================
router.get('/notifications/my', authenticate, appController.getUserNotifications);
router.post('/notifications/:id/read', authenticate, appController.markNotificationRead);
router.get('/notifications/unread-count', authenticate, appController.getUnreadNotificationCount);

// =============================================================================
// PAYMENT WORKFLOWS
// =============================================================================
router.post('/payments/create', authenticate, appController.createPayment);
router.get('/wallet/my', authenticate, appController.getMyWallet);
router.post('/wallet/topup', authenticate, appController.topUpWallet);
router.get('/transactions/my', authenticate, appController.getMyTransactions);

// =============================================================================
// DASHBOARD
// =============================================================================
router.get('/dashboard/admin', authenticate, authorize('Admin'), appController.getAdminDashboard);
router.get('/dashboard/station/:id', authenticate, appController.getStationDashboard);
router.get('/dashboard/franchise/:id', authenticate, authorize('Admin', 'Manager'), appController.getFranchiseDashboard);

// =============================================================================
// HEALTH CHECK
// =============================================================================
router.get('/health', (req, res) => {
  res.json({ success: true, data: { status: 'ok', timestamp: new Date().toISOString() }, message: 'Service is running' });
});

module.exports = router;
