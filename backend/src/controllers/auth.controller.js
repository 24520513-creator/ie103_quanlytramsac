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
