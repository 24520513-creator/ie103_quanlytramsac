const authService = require('../services/auth.service');
const { asyncHandler } = require('../middleware/error.middleware');
const { success } = require('../utils/response');

exports.signup = asyncHandler(async (req, res) => {
  const result = await authService.signup(req.body);
  res.status(201).json(success(result, 'Registration successful'));
});

exports.signin = asyncHandler(async (req, res) => {
  const result = await authService.signin(req.body);
  res.json(success(result, 'Login successful'));
});

exports.forgotPassword = asyncHandler(async (req, res) => {
  const result = await authService.forgotPassword(req.body);
  res.json(success(result, 'Password reset email sent'));
});

exports.resetPassword = asyncHandler(async (req, res) => {
  const result = await authService.resetPassword(req.body);
  res.json(success(result, 'Password reset successful'));
});
