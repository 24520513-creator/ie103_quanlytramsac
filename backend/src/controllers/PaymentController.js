const paymentService = require('../services/PaymentService');
const { asyncHandler } = require('../middleware/errorHandler');
const { successResponse, ValidationError } = require('../utils/response');

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
