const chargingSessionService = require('../services/ChargingSessionService');
const paymentService = require('../services/PaymentService');
const dashboardService = require('../services/DashboardService');
const bookingService = require('../services/BookingService');
const maintenanceService = require('../services/MaintenanceService');
const notificationService = require('../services/NotificationService');
const { asyncHandler } = require('../middleware/errorHandler');
const { successResponse, NotFoundError, ValidationError } = require('../utils/response');
const { query } = require('../config/database');

// =========================================================================
// Session flows
// =========================================================================
exports.startSession = asyncHandler(async (req, res) => {
  const { PointID } = req.body;
  if (!PointID) throw new ValidationError('PointID is required');
  const result = await chargingSessionService.startSession({ ...req.body, UserID: req.user.UserID });
  res.status(201).json(result);
});

exports.endSession = asyncHandler(async (req, res) => {
  const result = await chargingSessionService.endSession(req.params.id, req.body);
  res.json(result);
});

exports.cancelSession = asyncHandler(async (req, res) => {
  const result = await chargingSessionService.cancelSession(req.params.id, req.body.reason);
  res.json(result);
});

exports.getActiveSessions = asyncHandler(async (req, res) => {
  const sessions = await chargingSessionService.getActiveSessions({ ...req.query, userId: req.user.UserID });
  res.json(successResponse(sessions));
});

exports.getMySessions = asyncHandler(async (req, res) => {
  // SECURITY: userId is always from token, cannot be overridden by query params
  const sessions = await chargingSessionService.getActiveSessions({ userId: req.user.UserID, ...removeOverrides(req.query, ['userId']) });
  res.json(successResponse(sessions));
});

exports.getSessionById = asyncHandler(async (req, res) => {
  const result = await query(`SELECT cs.*, u.Username, u.FullName, s.StationName, p.PointCode, v.PlateNumber
    FROM [Operations].[ChargingSession] cs
    JOIN [Users].[User] u ON cs.UserID = u.UserID
    JOIN [Infrastructure].[ChargingStation] s ON cs.StationID = s.StationID
    JOIN [Infrastructure].[ChargingPoint] p ON cs.PointID = p.PointID
    LEFT JOIN [Users].[Vehicle] v ON cs.VehicleID = v.VehicleID
    WHERE cs.SessionID = @ID`, { ID: req.params.id });
  if (result.recordset.length === 0) throw new NotFoundError('Session');
  res.json(successResponse(result.recordset[0]));
});

exports.getSessionHistory = asyncHandler(async (req, res) => {
  const history = await chargingSessionService.getSessionHistory(req.user.UserID);
  res.json(successResponse(history));
});

// =========================================================================
// Payment flows
// =========================================================================
exports.createPayment = asyncHandler(async (req, res) => {
  const { SessionID } = req.body;
  if (!SessionID) throw new ValidationError('SessionID is required');
  const result = await paymentService.createPayment({ ...req.body, UserID: req.user.UserID });
  res.status(201).json(result);
});

exports.getMyWallet = asyncHandler(async (req, res) => {
  const result = await paymentService.getUserWallet(req.user.UserID);
  res.json(result);
});

exports.topUpWallet = asyncHandler(async (req, res) => {
  const amount = parseFloat(req.body.amount);
  if (!amount || amount <= 0 || !Number.isFinite(amount)) {
    throw new ValidationError('A valid positive amount is required');
  }
  const result = await paymentService.topUpWallet(req.user.UserID, amount, req.body.paymentMethod);
  res.json(result);
});

exports.getMyTransactions = asyncHandler(async (req, res) => {
  const txns = await paymentService.getTransactionHistory(req.user.UserID, req.query);
  res.json(successResponse(txns));
});

// =========================================================================
// Booking flows
// =========================================================================
exports.createBooking = asyncHandler(async (req, res) => {
  const { PointID, StationID, BookedFrom, BookedTo } = req.body;
  if (!PointID || !StationID || !BookedFrom || !BookedTo) {
    throw new ValidationError('PointID, StationID, BookedFrom, BookedTo are required');
  }
  const result = await bookingService.createBooking({ ...req.body, UserID: req.user.UserID });
  res.status(201).json(result);
});

exports.confirmBooking = asyncHandler(async (req, res) => {
  const result = await bookingService.confirmBooking(req.params.id);
  res.json(result);
});

exports.cancelBooking = asyncHandler(async (req, res) => {
  const result = await bookingService.cancelBooking(req.params.id, req.body.reason);
  res.json(result);
});

exports.checkPointAvailability = asyncHandler(async (req, res) => {
  const { pointId, startTime, endTime } = req.query;
  if (!pointId || !startTime || !endTime) {
    throw new ValidationError('pointId, startTime, endTime query params are required');
  }
  const result = await bookingService.checkAvailability(pointId, startTime, endTime);
  res.json(result);
});

// =========================================================================
// Maintenance flows
// =========================================================================
exports.scheduleMaintenance = asyncHandler(async (req, res) => {
  const { StationID, ScheduledFrom, ScheduledTo } = req.body;
  if (!StationID || !ScheduledFrom || !ScheduledTo) {
    throw new ValidationError('StationID, ScheduledFrom, ScheduledTo are required');
  }
  const result = await maintenanceService.scheduleMaintenance({ ...req.body, ScheduledBy: req.user.UserID });
  res.status(201).json(result);
});

exports.completeMaintenance = asyncHandler(async (req, res) => {
  const result = await maintenanceService.completeMaintenance(req.params.id, { Notes: req.body.Notes, CompletedAt: req.body.CompletedAt });
  res.json(result);
});

exports.getUpcomingMaintenance = asyncHandler(async (req, res) => {
  const result = await maintenanceService.getUpcoming(req.query.days);
  res.json(result);
});

exports.resolveError = asyncHandler(async (req, res) => {
  const result = await maintenanceService.resolveError(req.params.id, { ResolvedBy: req.user.UserID });
  res.json(result);
});

// =========================================================================
// Notification flows
// =========================================================================
exports.getUserNotifications = asyncHandler(async (req, res) => {
  const result = await notificationService.getUserNotifications(req.user.UserID, req.query);
  res.json(result);
});

exports.markNotificationRead = asyncHandler(async (req, res) => {
  const result = await notificationService.markRead(req.params.id, req.user.UserID);
  res.json(result);
});

exports.getUnreadNotificationCount = asyncHandler(async (req, res) => {
  const result = await notificationService.getUnreadCount(req.user.UserID);
  res.json(result);
});

// =========================================================================
// Dashboard
// =========================================================================
exports.getStationDashboard = asyncHandler(async (req, res) => {
  const result = await dashboardService.getStationDashboard(req.params.id, req.query.days);
  res.json(result);
});

exports.getFranchiseDashboard = asyncHandler(async (req, res) => {
  const result = await dashboardService.getFranchiseDashboard(req.params.id, req.query.days);
  res.json(result);
});

exports.getAdminDashboard = asyncHandler(async (req, res) => {
  const result = await dashboardService.getAdminDashboard();
  res.json(result);
});

// =========================================================================
// Helpers
// =========================================================================
function removeOverrides(obj, blocked) {
  const result = { ...obj };
  for (const key of blocked) {
    delete result[key];
  }
  return result;
}
