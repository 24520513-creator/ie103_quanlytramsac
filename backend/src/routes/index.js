const express = require('express');
const router = express.Router();

const { authenticate, optionalAuth, authorize } = require('../middleware/auth');
const { createCrudController } = require('../controllers/CrudController');
const { createCrudService } = require('../services/CrudFactory');
const authController = require('../controllers/AuthController');
const appController = require('../controllers/AppController');

// =============================================================================
// REPOSITORY IMPORTS
// =============================================================================
const {
  CountryRepository, RegionRepository, AddressRepository,
  FranchiseRepository, ElectricitySupplierRepository, StationModelRepository,
  ChargingStationRepository, ChargingPointRepository,
  StationElectricityContractRepository, StationDocumentRepository,
} = require('../repositories/InfrastructureRepository');
const {
  UserRepository, UserProfileRepository, UserCredentialRepository,
  UserSessionRepository, UserLoginHistoryRepository, UserRoleRepository,
  VehicleRepository, UserPaymentMethodRepository,
} = require('../repositories/UsersRepository');
const {
  PricingPolicyRepository, PricingRuleRepository, PeakHourDefinitionRepository,
  MembershipTierRepository, UserMembershipRepository,
  ChargingSessionRepository, MaintenanceScheduleRepository,
} = require('../repositories/OperationsRepository');
const {
  PaymentGatewayRepository, TransactionRepository, TransactionStatusHistoryRepository,
  GatewayTransactionRepository, RefundTransactionRepository,
  WalletRepository, WalletTransactionRepository, InvoiceRepository, InvoiceLineItemRepository,
} = require('../repositories/PaymentsRepository');
const {
  ErrorLogRepository, PointTelemetryRepository, StationHeartbeatRepository,
  AlertRuleRepository, AlertRepository,
} = require('../repositories/MonitoringRepository');
const {
  AuditLogRepository, StationStatusHistoryRepository, PointStatusHistoryRepository,
  SessionStatusHistoryRepository, SchemaChangeLogRepository,
} = require('../repositories/AuditRepository');
const {
  DailyStationKPIRepository, DailyFranchiseKPIRepository, HourlySessionAggRepository,
} = require('../repositories/AnalyticsRepository');

// =============================================================================
// CRUD SERVICE & CONTROLLER FACTORY
// =============================================================================
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
// AUTH ROUTES (public)
// =============================================================================
router.post('/auth/register', authController.register);
router.post('/auth/login', authController.login);
router.post('/auth/refresh', authController.refreshToken);
router.post('/auth/logout', authenticate, authController.logout);
router.get('/auth/profile', authenticate, authController.getProfile);
router.put('/auth/profile', authenticate, authController.updateProfile);

// =============================================================================
// INFRASTRUCTURE (Geography, Assets, Franchise, Suppliers)
// =============================================================================
registerCrudRoutes('/countries', CountryRepository, 'Country', ['CountryCode', 'CountryName']);
registerCrudRoutes('/regions', RegionRepository, 'Region', ['RegionCode']);
registerCrudRoutes('/addresses', AddressRepository, 'Address', []);
registerCrudRoutes('/franchises', FranchiseRepository, 'Franchise', ['FranchiseCode', 'TaxCode']);
registerCrudRoutes('/suppliers', ElectricitySupplierRepository, 'ElectricitySupplier', ['SupplierCode']);
registerCrudRoutes('/station-models', StationModelRepository, 'StationModel', []);
registerCrudRoutes('/stations', ChargingStationRepository, 'ChargingStation', ['StationCode']);
registerCrudRoutes('/points', ChargingPointRepository, 'ChargingPoint', ['PointCode', 'SerialNumber']);
registerCrudRoutes('/station-contracts', StationElectricityContractRepository, 'StationElectricityContract', ['ContractNumber']);
registerCrudRoutes('/station-documents', StationDocumentRepository, 'StationDocument', []);

// =============================================================================
// ACCESS (Roles, Permissions)
// =============================================================================
registerCrudRoutes('/permissions', require('../repositories/AccessRepository').PermissionRepository, 'Permission', ['PermissionCode'], [authenticate, authorize('SysAdmin')]);
registerCrudRoutes('/roles', require('../repositories/AccessRepository').RoleRepository, 'Role', ['RoleCode'], [authenticate, authorize('SysAdmin')]);
registerCrudRoutes('/role-permissions', require('../repositories/AccessRepository').RolePermissionRepository, 'RolePermission', [], [authenticate, authorize('SysAdmin')]);

// =============================================================================
// USERS (Profiles, Vehicles, Payment Methods)
// =============================================================================
registerCrudRoutes('/users', UserRepository, 'User', ['Username', 'Email', 'Phone'], [authenticate, authorize('SysAdmin', 'Operator')]);
registerCrudRoutes('/user-profiles', UserProfileRepository, 'UserProfile', [], [authenticate]);
registerCrudRoutes('/user-credentials', UserCredentialRepository, 'UserCredential', [], [authenticate, authorize('SysAdmin')]);
registerCrudRoutes('/user-sessions', UserSessionRepository, 'UserSession', [], [authenticate, authorize('SysAdmin')]);
registerCrudRoutes('/user-login-history', UserLoginHistoryRepository, 'UserLoginHistory', [], [authenticate, authorize('SysAdmin', 'Operator')]);
registerCrudRoutes('/user-roles', UserRoleRepository, 'UserRole', [], [authenticate, authorize('SysAdmin')]);
registerCrudRoutes('/vehicles', VehicleRepository, 'Vehicle', ['PlateNumber'], [authenticate]);
registerCrudRoutes('/payment-methods', UserPaymentMethodRepository, 'UserPaymentMethod', [], [authenticate]);

// =============================================================================
// OPERATIONS (Pricing, Membership, Sessions, Maintenance)
// =============================================================================
registerCrudRoutes('/pricing-policies', PricingPolicyRepository, 'PricingPolicy', ['PolicyCode'], [authenticate, authorize('SysAdmin', 'Operator')]);
registerCrudRoutes('/pricing-rules', PricingRuleRepository, 'PricingRule', [], [authenticate, authorize('SysAdmin', 'Operator')]);
registerCrudRoutes('/peak-hours', PeakHourDefinitionRepository, 'PeakHourDefinition', [], [authenticate, authorize('SysAdmin', 'Operator')]);
registerCrudRoutes('/membership-tiers', MembershipTierRepository, 'MembershipTier', ['TierCode'], [authenticate, authorize('SysAdmin')]);
registerCrudRoutes('/user-memberships', UserMembershipRepository, 'UserMembership', [], [authenticate]);
registerCrudRoutes('/maintenance-schedules', MaintenanceScheduleRepository, 'MaintenanceSchedule', [], [authenticate]);

// Charging Sessions (with business logic)
router.get('/sessions', authenticate, appController.getActiveSessions);
router.get('/sessions/my', authenticate, appController.getMySessions);
router.get('/sessions/history', authenticate, appController.getSessionHistory);
router.get('/sessions/:id', authenticate, appController.getSessionById);
router.post('/sessions/start', authenticate, appController.startSession);
router.post('/sessions/:id/end', authenticate, appController.endSession);
router.post('/sessions/:id/cancel', authenticate, appController.cancelSession);

// =============================================================================
// PAYMENTS (Gateways, Transactions, Wallets, Invoices)
// =============================================================================
registerCrudRoutes('/payment-gateways', PaymentGatewayRepository, 'PaymentGateway', ['GatewayCode'], [authenticate, authorize('SysAdmin')]);
registerCrudRoutes('/transactions', TransactionRepository, 'Transaction', ['TransactionCode'], [authenticate]);
registerCrudRoutes('/transaction-status-history', TransactionStatusHistoryRepository, 'TransactionStatusHistory', [], [authenticate, authorize('SysAdmin', 'Operator')]);
registerCrudRoutes('/gateway-transactions', GatewayTransactionRepository, 'GatewayTransaction', [], [authenticate, authorize('SysAdmin')]);
registerCrudRoutes('/refunds', RefundTransactionRepository, 'RefundTransaction', ['RefundCode'], [authenticate, authorize('SysAdmin', 'Operator')]);
registerCrudRoutes('/wallets', WalletRepository, 'Wallet', ['WalletCode'], [authenticate]);
registerCrudRoutes('/wallet-transactions', WalletTransactionRepository, 'WalletTransaction', [], [authenticate]);
registerCrudRoutes('/invoices', InvoiceRepository, 'Invoice', ['InvoiceCode'], [authenticate]);
registerCrudRoutes('/invoice-line-items', InvoiceLineItemRepository, 'InvoiceLineItem', [], [authenticate]);

// Payment workflows
router.post('/payments/create', authenticate, appController.createPayment);
router.post('/payments/refund', authenticate, authorize('SysAdmin', 'Operator'), appController.processRefund);
router.get('/wallet/my', authenticate, appController.getMyWallet);
router.post('/wallet/topup', authenticate, appController.topUpWallet);
router.get('/transactions/my', authenticate, appController.getMyTransactions);

// =============================================================================
// MONITORING (Telemetry, Heartbeats, Alerts, Errors)
// =============================================================================
registerCrudRoutes('/error-logs', ErrorLogRepository, 'ErrorLog', [], [authenticate]);
registerCrudRoutes('/telemetry', PointTelemetryRepository, 'PointTelemetry', [], [authenticate, authorize('SysAdmin', 'Technician')]);
registerCrudRoutes('/heartbeats', StationHeartbeatRepository, 'StationHeartbeat', [], [authenticate, authorize('SysAdmin', 'Technician')]);
registerCrudRoutes('/alert-rules', AlertRuleRepository, 'AlertRule', [], [authenticate, authorize('SysAdmin', 'Operator')]);
registerCrudRoutes('/alerts', AlertRepository, 'Alert', [], [authenticate]);

// =============================================================================
// AUDIT
// =============================================================================
registerCrudRoutes('/audit-logs', AuditLogRepository, 'AuditLog', [], [authenticate, authorize('SysAdmin')]);
registerCrudRoutes('/station-status-history', StationStatusHistoryRepository, 'StationStatusHistory', [], [authenticate, authorize('SysAdmin', 'Operator')]);
registerCrudRoutes('/point-status-history', PointStatusHistoryRepository, 'PointStatusHistory', [], [authenticate, authorize('SysAdmin', 'Operator')]);
registerCrudRoutes('/session-status-history', SessionStatusHistoryRepository, 'SessionStatusHistory', [], [authenticate]);
registerCrudRoutes('/schema-changes', SchemaChangeLogRepository, 'SchemaChangeLog', [], [authenticate, authorize('SysAdmin')]);

// =============================================================================
// ANALYTICS
// =============================================================================
registerCrudRoutes('/daily-station-kpis', require('../repositories/AnalyticsRepository').DailyStationKPIRepository, 'DailyStationKPI', [], [authenticate, authorize('SysAdmin', 'Operator')]);
registerCrudRoutes('/daily-franchise-kpis', require('../repositories/AnalyticsRepository').DailyFranchiseKPIRepository, 'DailyFranchiseKPI', [], [authenticate, authorize('SysAdmin', 'Operator')]);
registerCrudRoutes('/hourly-session-agg', require('../repositories/AnalyticsRepository').HourlySessionAggRepository, 'HourlySessionAgg', [], [authenticate, authorize('SysAdmin', 'Operator')]);

// =============================================================================
// DASHBOARD
// =============================================================================
router.get('/dashboard/admin', authenticate, authorize('SysAdmin', 'Operator'), appController.getAdminDashboard);
router.get('/dashboard/station/:id', authenticate, appController.getStationDashboard);
router.get('/dashboard/franchise/:id', authenticate, appController.getFranchiseDashboard);

// =============================================================================
// HEALTH CHECK
// =============================================================================
router.get('/health', (req, res) => {
  res.json({ success: true, data: { status: 'ok', timestamp: new Date().toISOString() }, message: 'Service is running' });
});

module.exports = router;
