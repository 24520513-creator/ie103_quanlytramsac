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

exports.getProfile = asyncHandler(async (req, res) => {
  const profile = await authService.getProfile(req.user.UserID);
  res.json(successResponse(profile));
});

exports.updateProfile = asyncHandler(async (req, res) => {
  const profile = await authService.updateProfile(req.user.UserID, req.body);
  res.json(successResponse(profile, 'Profile updated'));
});

exports.forgotPassword = asyncHandler(async (req, res) => {
  const result = await authService.forgotPassword(req.body);
  res.json(successResponse(result, 'Password reset email sent'));
});

exports.resetPassword = asyncHandler(async (req, res) => {
  const result = await authService.resetPassword(req.body);
  res.json(successResponse(result, 'Password reset successful'));
});
