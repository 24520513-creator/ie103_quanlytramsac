const { query } = require('../config/database');
const { successResponse } = require('../utils/response');

class NotificationService {
  async getUserNotifications(userId, filters = {}) {
    let q = `SELECT * FROM [Users].[Notification] WHERE UserID = @UserID`;
    const params = { UserID: userId };
    if (filters.isRead !== undefined) {
      q += ` AND IsRead = @IsRead`;
      params.IsRead = filters.isRead ? 1 : 0;
    }
    if (filters.type) {
      q += ` AND NotificationType = @Type`;
      params.Type = filters.type;
    }
    q += ` ORDER BY CreatedAt DESC`;
    if (filters.page && filters.limit) {
      const offset = (filters.page - 1) * filters.limit;
      q += ` OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY`;
      params.Offset = offset;
      params.Limit = filters.limit;
    }
    const result = await query(q, params);
    return successResponse(result.recordset);
  }

  async markRead(notificationId, userId) {
    const result = await query(`UPDATE [Users].[Notification] SET IsRead = 1, ReadAt = SYSDATETIME()
      OUTPUT INSERTED.* WHERE NotificationID = @ID AND UserID = @UserID`,
      { ID: notificationId, UserID: userId });
    return successResponse(result.recordset[0] || null, 'Notification marked as read');
  }

  async getUnreadCount(userId) {
    const result = await query(`SELECT COUNT(*) AS Cnt FROM [Users].[Notification]
      WHERE UserID = @UserID AND IsRead = 0`, { UserID: userId });
    return successResponse({ unreadCount: result.recordset[0].Cnt });
  }
}

module.exports = new NotificationService();
