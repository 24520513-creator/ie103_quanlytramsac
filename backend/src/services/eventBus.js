const { execute } = require('../config/database');

class EventBus {
  async emit(eventType, payload, { userId, aggregateType, aggregateId } = {}) {
    try {
      await execute('dbo.sp_EmitRealtimeEvent', {
        EventType: eventType,
        Payload: payload ? JSON.stringify(payload) : null,
        UserID: userId || null,
        AggregateType: aggregateType || null,
        AggregateID: aggregateId ? String(aggregateId) : null,
      });
    } catch (err) {
      console.error(`[EventBus] Failed to persist event ${eventType}:`, err.message);
    }
  }

  async getMissedEvents(userId, since) {
    try {
      const result = await execute('dbo.sp_GetMissedEvents', {
        UserID: userId, Since: since || new Date(Date.now() - 60000).toISOString(),
      });
      return (result.recordset || []).map(r => ({
        event: r.EventType,
        data: r.Payload ? JSON.parse(r.Payload) : null,
        timestamp: r.CreatedAt,
      }));
    } catch {
      return [];
    }
  }
}

module.exports = new EventBus();
