const { execute } = require('../config/database');
const { successResponse } = require('../utils/response');
const socketService = require('./socketService');

class NotificationService {
  async create(userId, { Title, Body, Type, ReferenceType, ReferenceID }) {
    const result = await execute('Users.sp_CreateNotification', {
      UserID: userId, Title, Body, Type: Type || 'Info',
      ReferenceType: ReferenceType || null, ReferenceID: ReferenceID || null,
    });
    const notification = result.recordset?.[0] || null;
    if (notification) {
      socketService.sendToUser(userId, 'notification:new', notification);
    }
    return notification;
  }

  async getUserNotifications(userId, filters = {}) {
    const params = { UserID: userId, Page: filters.page || 1, Limit: filters.limit || 20 };
    if (filters.isRead !== undefined) params.UnreadOnly = filters.isRead ? 0 : 1;
    if (filters.type) params.Type = filters.type;

    const result = await execute('Users.sp_GetUserNotifications', params);
    return successResponse(result.recordsets[0] || []);
  }

  async markRead(notificationId, userId) {
    const result = await execute('Users.sp_MarkNotificationRead', {
      NotificationID: notificationId, UserID: userId,
    });
    const updated = result.recordset?.[0] || null;
    if (updated) {
      socketService.sendToUser(userId, 'notification:read', updated);
    }
    return successResponse(updated, 'Notification marked as read');
  }

  async getUnreadCount(userId) {
    const result = await execute('Users.sp_GetUserNotifications', {
      UserID: userId, UnreadOnly: 1, Page: 1, Limit: 1,
    });
    const total = result.recordsets?.[1]?.[0]?.Total || 0;
    return successResponse({ unreadCount: total });
  }
}

module.exports = new NotificationService();
