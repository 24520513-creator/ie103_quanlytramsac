const chargingSessionService = require('../services/ChargingSessionService');
const { asyncHandler } = require('../middleware/errorHandler');
const { successResponse, NotFoundError, ValidationError } = require('../utils/response');
const { execute } = require('../config/database');

exports.start = asyncHandler(async (req, res) => {
  const { PointID } = req.body;
  if (!PointID) throw new ValidationError('PointID is required');
  const result = await chargingSessionService.startSession({ ...req.body, UserID: req.user.UserID });
  res.status(201).json(result);
});

exports.end = asyncHandler(async (req, res) => {
  if (!req.params.id) throw new ValidationError('Session ID is required');
  const result = await chargingSessionService.endSession(req.params.id, req.body);
  res.json(result);
});

exports.cancel = asyncHandler(async (req, res) => {
  if (!req.params.id) throw new ValidationError('Session ID is required');
  const result = await chargingSessionService.cancelSession(req.params.id, req.body.reason);
  res.json(result);
});

exports.getActive = asyncHandler(async (req, res) => {
  const sessions = await chargingSessionService.getActiveSessions({ ...req.query, userId: req.user.UserID });
  res.json(successResponse(sessions));
});

exports.getMine = asyncHandler(async (req, res) => {
  const sessions = await chargingSessionService.getActiveSessions({ userId: req.user.UserID });
  res.json(successResponse(sessions));
});

exports.getById = asyncHandler(async (req, res) => {
  if (!req.params.id) throw new ValidationError('Session ID is required');
  const result = await execute('Operations.sp_GetSessionById', { SessionID: req.params.id });
  if (!result.recordset || result.recordset.length === 0) throw new NotFoundError('Session');
  res.json(successResponse(result.recordset[0]));
});

exports.getHistory = asyncHandler(async (req, res) => {
  const history = await chargingSessionService.getSessionHistory(req.user.UserID);
  res.json(successResponse(history));
});
