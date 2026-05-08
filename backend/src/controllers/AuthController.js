const authService = require('../services/AuthService');
const { asyncHandler } = require('../middleware/errorHandler');
const { successResponse } = require('../utils/response');

exports.register = asyncHandler(async (req, res) => {
  const result = await authService.register(req.body);
  res.status(201).json(successResponse(result, 'Registration successful'));
});

exports.login = asyncHandler(async (req, res) => {
  const result = await authService.login({
    ...req.body,
    IPAddress: req.ip,
    UserAgent: req.headers['user-agent'],
  });
  res.json(result);
});

exports.refreshToken = asyncHandler(async (req, res) => {
  const result = await authService.refreshToken(req.body.refreshToken);
  res.json(result);
});

exports.logout = asyncHandler(async (req, res) => {
  await authService.logout(req.user.UserID);
  res.json(successResponse(null, 'Logged out successfully'));
});

exports.getProfile = asyncHandler(async (req, res) => {
  const profile = await authService.getProfile(req.user.UserID);
  res.json(successResponse(profile));
});

exports.updateProfile = asyncHandler(async (req, res) => {
  const profile = await authService.updateProfile(req.user.UserID, req.body);
  res.json(successResponse(profile, 'Profile updated'));
});
