const chargingSessionService = require('../services/ChargingSessionService');
const paymentService = require('../services/PaymentService');
const dashboardService = require('../services/DashboardService');
const { asyncHandler } = require('../middleware/errorHandler');
const { successResponse, NotFoundError } = require('../utils/response');
const { query } = require('../config/database');

exports.startSession = asyncHandler(async (req, res) => {
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
  const sessions = await chargingSessionService.getActiveSessions({ userId: req.user.UserID, ...req.query });
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

// Payment flows
exports.createPayment = asyncHandler(async (req, res) => {
  const result = await paymentService.createPayment({ ...req.body, UserID: req.user.UserID });
  res.status(201).json(result);
});

exports.getMyWallet = asyncHandler(async (req, res) => {
  const result = await paymentService.getUserWallet(req.user.UserID);
  res.json(result);
});

exports.topUpWallet = asyncHandler(async (req, res) => {
  const result = await paymentService.topUpWallet(req.user.UserID, req.body.amount, req.body.paymentMethod);
  res.json(result);
});

exports.getMyTransactions = asyncHandler(async (req, res) => {
  const txns = await paymentService.getTransactionHistory(req.user.UserID, req.query);
  res.json(successResponse(txns));
});

// Dashboard
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
