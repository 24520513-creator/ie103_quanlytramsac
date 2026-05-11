const notificationService = require('../services/NotificationService');
const { asyncHandler } = require('../middleware/errorHandler');
const { ValidationError } = require('../utils/response');

exports.getUserNotifications = asyncHandler(async (req, res) => {
  const result = await notificationService.getUserNotifications(req.user.UserID, req.query);
  res.json(result);
});

exports.markNotificationRead = asyncHandler(async (req, res) => {
  if (!req.params.id) throw new ValidationError('Notification ID is required');
  const result = await notificationService.markRead(req.params.id, req.user.UserID);
  res.json(result);
});

exports.getUnreadNotificationCount = asyncHandler(async (req, res) => {
  const result = await notificationService.getUnreadCount(req.user.UserID);
  res.json(result);
});
