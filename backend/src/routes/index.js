const express = require('express');
const router = express.Router();

const { authenticate, authorize } = require('../middleware/auth');
const { createCrudController } = require('../controllers/CrudController');
const { createCrudService } = require('../services/CrudFactory');
const authController = require('../controllers/AuthController');
const appController = require('../controllers/AppController');

const {
  CountryRepository, RegionRepository, AddressRepository,
  FranchiseRepository,
  ChargingStationRepository, ChargingPointRepository,
} = require('../repositories/InfrastructureRepository');
const {
  UserRepository, VehicleRepository,
} = require('../repositories/UsersRepository');
const {
  PricingPolicyRepository, ChargingSessionRepository,
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
// AUTH (public)
// =============================================================================
router.post('/auth/register', authController.register);
router.post('/auth/login', authController.login);
router.post('/auth/forgot-password', authController.forgotPassword);
router.post('/auth/reset-password', authController.resetPassword);
router.get('/auth/profile', authenticate, authController.getProfile);
router.put('/auth/profile', authenticate, authController.updateProfile);

// =============================================================================
// INFRASTRUCTURE
// =============================================================================
registerCrudRoutes('/countries', CountryRepository, 'Country', ['CountryCode', 'CountryName']);
registerCrudRoutes('/regions', RegionRepository, 'Region', ['RegionCode']);
registerCrudRoutes('/addresses', AddressRepository, 'Address', []);
registerCrudRoutes('/franchises', FranchiseRepository, 'Franchise', ['FranchiseCode', 'TaxCode']);
registerCrudRoutes('/stations', ChargingStationRepository, 'ChargingStation', ['StationCode'], [authenticate]);
registerCrudRoutes('/points', ChargingPointRepository, 'ChargingPoint', ['PointCode'], [authenticate]);

// =============================================================================
// USERS
// =============================================================================
registerCrudRoutes('/users', UserRepository, 'User', ['Username', 'Email'], [authenticate, authorize('Admin')]);
registerCrudRoutes('/vehicles', VehicleRepository, 'Vehicle', ['PlateNumber'], [authenticate]);

// =============================================================================
// OPERATIONS
// =============================================================================
registerCrudRoutes('/pricing-policies', PricingPolicyRepository, 'PricingPolicy', ['PolicyCode'], [authenticate, authorize('Admin')]);
registerCrudRoutes('/sessions-crud', ChargingSessionRepository, 'ChargingSession', ['SessionCode'], [authenticate]);

// Charging workflows
router.get('/sessions', authenticate, appController.getActiveSessions);
router.get('/sessions/my', authenticate, appController.getMySessions);
router.get('/sessions/history', authenticate, appController.getSessionHistory);
router.get('/sessions/:id', authenticate, appController.getSessionById);
router.post('/sessions/start', authenticate, appController.startSession);
router.post('/sessions/:id/end', authenticate, appController.endSession);
router.post('/sessions/:id/cancel', authenticate, appController.cancelSession);

// =============================================================================
// PAYMENTS
// =============================================================================
registerCrudRoutes('/transactions', TransactionRepository, 'Transaction', ['TransactionCode'], [authenticate]);
registerCrudRoutes('/wallets', WalletRepository, 'Wallet', ['WalletCode'], [authenticate]);
registerCrudRoutes('/wallet-transactions', WalletTransactionRepository, 'WalletTransaction', [], [authenticate]);

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
