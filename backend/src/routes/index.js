const express = require('express');
const router = express.Router();

const { authenticate, authorize } = require('../middleware/auth');
const { createCrudController } = require('../controllers/CrudController');
const { createCrudService } = require('../services/CrudFactory');
const authController = require('../controllers/AuthController');
const sessionController = require('../controllers/SessionController');
const paymentController = require('../controllers/PaymentController');
const bookingController = require('../controllers/BookingController');
const maintenanceController = require('../controllers/MaintenanceController');
const notificationController = require('../controllers/NotificationController');
const dashboardController = require('../controllers/DashboardController');
const pdfService = require('../services/PdfService');

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
registerCrudRoutes('/countries', CountryRepository, 'Country', ['CountryCode', 'CountryName'], [authenticate, authorize('Admin')]);
registerCrudRoutes('/regions', RegionRepository, 'Region', ['RegionCode'], [authenticate, authorize('Admin')]);
registerCrudRoutes('/addresses', AddressRepository, 'Address', [], [authenticate, authorize('Admin')]);
registerCrudRoutes('/franchises', FranchiseRepository, 'Franchise', ['FranchiseCode', 'TaxCode'], [authenticate, authorize('Admin')]);
registerCrudRoutes('/stations', ChargingStationRepository, 'ChargingStation', ['StationCode'], [authenticate, authorize('Admin')]);
registerCrudRoutes('/points', ChargingPointRepository, 'ChargingPoint', ['PointCode'], [authenticate, authorize('Admin')]);
registerCrudRoutes('/electricity-suppliers', ElectricitySupplierRepository, 'ElectricitySupplier', ['SupplierCode'], [authenticate, authorize('Admin')]);
registerCrudRoutes('/error-logs', ErrorLogRepository, 'ErrorLog', [], [authenticate, authorize('Admin', 'Manager')]);

// =============================================================================
// USERS CRUD
// =============================================================================
// Notification workflow routes (must be before CRUD to avoid :id catch-all)
router.get('/notifications/my', authenticate, notificationController.getUserNotifications);
router.post('/notifications/:id/read', authenticate, notificationController.markNotificationRead);
router.get('/notifications/unread-count', authenticate, notificationController.getUnreadNotificationCount);

registerCrudRoutes('/users', UserRepository, 'User', ['Username', 'Email'], [authenticate, authorize('Admin')]);
registerCrudRoutes('/vehicles', VehicleRepository, 'Vehicle', ['PlateNumber'], [authenticate, authorize('Admin')]);
registerCrudRoutes('/notifications', NotificationRepository, 'Notification', [], [authenticate, authorize('Admin')]);

// =============================================================================
// OPERATIONS CRUD
// =============================================================================
registerCrudRoutes('/pricing-policies', PricingPolicyRepository, 'PricingPolicy', ['PolicyCode'], [authenticate, authorize('Admin')]);
registerCrudRoutes('/sessions-crud', ChargingSessionRepository, 'ChargingSession', ['SessionCode'], [authenticate, authorize('Admin')]);
router.post('/bookings', authenticate, bookingController.createBooking);
router.get('/bookings/availability', authenticate, bookingController.checkPointAvailability);
registerCrudRoutes('/bookings', BookingRepository, 'Booking', [], [authenticate, authorize('Admin')]);
registerCrudRoutes('/maintenance-schedules', MaintenanceScheduleRepository, 'MaintenanceSchedule', [], [authenticate, authorize('Admin', 'Manager')]);
router.post('/station-reviews', authenticate, (req, res, next) => {
  req.body.UserID = req.user.UserID;
  next();
});
registerCrudRoutes('/station-reviews', StationReviewRepository, 'StationReview', [], [authenticate, authorize('Admin')]);

// =============================================================================
// PAYMENT WORKFLOWS (must be before PAYMENTS CRUD to avoid :id conflicts)
// =============================================================================
router.post('/payments/create', authenticate, paymentController.createPayment);
router.get('/wallet/my', authenticate, paymentController.getMyWallet);
router.post('/wallet/topup', authenticate, paymentController.topUpWallet);
router.get('/transactions/my', authenticate, paymentController.getMyTransactions);

// =============================================================================
// PAYMENTS CRUD
// =============================================================================
registerCrudRoutes('/transactions', TransactionRepository, 'Transaction', ['TransactionCode'], [authenticate, authorize('Admin')]);
registerCrudRoutes('/wallets', WalletRepository, 'Wallet', ['WalletCode'], [authenticate, authorize('Admin')]);
registerCrudRoutes('/wallet-transactions', WalletTransactionRepository, 'WalletTransaction', [], [authenticate, authorize('Admin')]);

// =============================================================================
// SESSION WORKFLOWS
// =============================================================================
router.get('/sessions', authenticate, sessionController.getActive);
router.get('/sessions/my', authenticate, sessionController.getMine);
router.get('/sessions/history', authenticate, sessionController.getHistory);
router.get('/sessions/:id', authenticate, sessionController.getById);
router.post('/sessions/start', authenticate, sessionController.start);
router.post('/sessions/:id/end', authenticate, sessionController.end);
router.post('/sessions/:id/cancel', authenticate, sessionController.cancel);

// =============================================================================
// BOOKING WORKFLOWS
// =============================================================================
router.post('/bookings/:id/confirm', authenticate, bookingController.confirmBooking);
router.post('/bookings/:id/cancel', authenticate, bookingController.cancelBooking);

// =============================================================================
// MAINTENANCE WORKFLOWS
// =============================================================================
router.post('/maintenance', authenticate, authorize('Admin', 'Manager'), maintenanceController.scheduleMaintenance);
router.post('/maintenance/:id/complete', authenticate, authorize('Admin', 'Manager'), maintenanceController.completeMaintenance);
router.get('/maintenance/upcoming', authenticate, maintenanceController.getUpcomingMaintenance);

// =============================================================================
// ERROR WORKFLOWS
// =============================================================================
router.post('/errors/:id/resolve', authenticate, authorize('Admin', 'Manager'), maintenanceController.resolveError);

// =============================================================================
// DASHBOARD
// =============================================================================
router.get('/dashboard/admin', authenticate, authorize('Admin'), dashboardController.getAdminDashboard);
router.get('/dashboard/station/:id', authenticate, dashboardController.getStationDashboard);
router.get('/dashboard/franchise/:id', authenticate, authorize('Admin', 'Manager'), dashboardController.getFranchiseDashboard);

// =============================================================================
// EXPORT
// =============================================================================
router.get('/export/revenue/:franchiseId', authenticate, authorize('Admin', 'Manager'), async (req, res) => {
  try {
    const pdf = await pdfService.generateRevenueReport(req.params.franchiseId);
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `attachment; filename=revenue-${req.params.franchiseId}.pdf`);
    res.send(pdf);
  } catch (err) {
    console.error('PDF export failed:', err.message);
    res.status(500).json({ success: false, message: 'Failed to generate PDF' });
  }
});

// =============================================================================
// HEALTH CHECK & MONITORING
// =============================================================================
router.get('/health', async (req, res) => {
  try {
    const { query } = require('../config/database');
    const dbResult = await query('SELECT 1 AS Ping', {});
    const memUsage = process.memoryUsage();
    res.json({
      success: true,
      data: {
        status: 'ok',
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        database: dbResult.recordset?.[0]?.Ping === 1 ? 'connected' : 'error',
        memory: {
          heapUsed: Math.round(memUsage.heapUsed / 1024 / 1024) + 'MB',
          heapTotal: Math.round(memUsage.heapTotal / 1024 / 1024) + 'MB',
          rss: Math.round(memUsage.rss / 1024 / 1024) + 'MB',
        },
        environment: process.env.NODE_ENV || 'development',
      },
      message: 'Service is healthy',
    });
  } catch (err) {
    res.status(503).json({
      success: false,
      data: { status: 'degraded', database: 'disconnected' },
      message: 'Service health check failed: ' + err.message,
    });
  }
});

router.get('/health/encoding', authenticate, authorize('Admin'), async (req, res) => {
  const { query } = require('../config/database');
  const encodingUtils = require('../utils/encoding');
  const results = [];
  for (const test of encodingUtils.VIETNAMESE_TEST_STRINGS) {
    try {
      const r = await query(`SELECT @Input AS Input, N'${test}' AS Expected`, { Input: test });
      const input = r.recordset[0]?.Input;
      const expected = r.recordset[0]?.Expected;
      const match = input === expected;
      results.push({ test, input, expected, match });
    } catch (err) {
      results.push({ test, error: err.message });
    }
  }
  const allPass = results.every(r => r.match);
  res.json({ success: true, data: { allPass, tests: results } });
});

router.get('/health/memory', authenticate, authorize('Admin'), (req, res) => {
  const mem = process.memoryUsage();
  res.json({
    success: true,
    data: {
      heapUsed: mem.heapUsed,
      heapTotal: mem.heapTotal,
      rss: mem.rss,
      external: mem.external,
      heapUsedMB: Math.round(mem.heapUsed / 1024 / 1024),
      heapTotalMB: Math.round(mem.heapTotal / 1024 / 1024),
      rssMB: Math.round(mem.rss / 1024 / 1024),
    },
  });
});

module.exports = router;
