const jwt = require('jsonwebtoken');
const authConfig = require('../config/auth');
const eventBus = require('./eventBus');

class SocketService {
  constructor() {
    this.io = null;
    this.onlineUsers = new Map();
    this.userSockets = new Map();
  }

  init(server) {
    const { Server } = require('socket.io');
    this.io = new Server(server, {
      cors: {
        origin: process.env.NODE_ENV === 'production'
          ? (process.env.CORS_ORIGINS || '').split(',')
          : true,
        credentials: true,
      },
      pingInterval: 25000,
      pingTimeout: 20000,
    });

    this.io.use((socket, next) => {
      const token = socket.handshake.auth?.token;
      if (!token) return next(new Error('No token provided'));
      try {
        const decoded = jwt.verify(token, authConfig.jwtSecret);
        socket.user = decoded;
        next();
      } catch {
        next(new Error('Invalid token'));
      }
    });

    this.io.on('connection', (socket) => {
      const user = socket.user;
      const userId = user.UserID;

      // Track multiple socket connections per user
      if (!this.userSockets.has(userId)) {
        this.userSockets.set(userId, new Set());
      }
      this.userSockets.get(userId).add(socket.id);
      this.onlineUsers.set(userId, { user, lastSeen: Date.now() });

      socket.join(`user:${userId}`);

      if (user.Role === 'Admin') socket.join('role:Admin');
      if (user.Role === 'Manager' || user.Role === 'Admin') {
        socket.join('role:Manager');
        if (user.FranchiseID) socket.join(`franchise:${user.FranchiseID}`);
      }

      socket.on('join-station', (stationId) => {
        socket.join(`station:${stationId}`);
      });

      socket.on('leave-station', (stationId) => {
        socket.leave(`station:${stationId}`);
      });

      socket.on('heartbeat', () => {
        this.onlineUsers.set(userId, { user, lastSeen: Date.now() });
      });

      socket.on('disconnect', () => {
        const sockets = this.userSockets.get(userId);
        if (sockets) {
          sockets.delete(socket.id);
          if (sockets.size === 0) {
            this.userSockets.delete(userId);
            this.onlineUsers.delete(userId);
          }
        }
      });
    });

    return this.io;
  }

  sendToUser(userId, event, data, persist = true) {
    if (!this.io) return;
    this.io.to(`user:${userId}`).emit(event, data);
    if (persist) eventBus.emit(event, data, { userId, aggregateType: event.split(':')[0], aggregateId: data?.SessionID || data?.BookingID || data?.TransactionID });
  }

  sendToRole(role, event, data, persist = true) {
    if (!this.io) return;
    this.io.to(`role:${role}`).emit(event, data);
    if (persist) eventBus.emit(event, data, { aggregateType: event.split(':')[0] });
  }

  sendToFranchise(franchiseId, event, data, persist = true) {
    if (!this.io) return;
    this.io.to(`franchise:${franchiseId}`).emit(event, data);
    if (persist) eventBus.emit(event, data, { aggregateType: event.split(':')[0] });
  }

  sendToStation(stationId, event, data, persist = true) {
    if (!this.io) return;
    this.io.to(`station:${stationId}`).emit(event, data);
    if (persist) eventBus.emit(event, data, { aggregateType: event.split(':')[0], aggregateId: stationId });
  }

  broadcast(event, data, persist = true) {
    if (!this.io) return;
    this.io.emit(event, data);
    if (persist) eventBus.emit(event, data);
  }

  getOnlineUserIds() {
    return [...this.onlineUsers.keys()];
  }

  isUserOnline(userId) {
    return this.userSockets.has(userId) && (this.userSockets.get(userId)?.size || 0) > 0;
  }

  getUserConnectionCount(userId) {
    return this.userSockets.get(userId)?.size || 0;
  }

  getStats() {
    return {
      totalConnections: this.io?.engine?.clientsCount || 0,
      uniqueUsers: this.onlineUsers.size,
      users: [...this.onlineUsers.entries()].map(([id, info]) => ({
        userId: id,
        role: info.user.Role,
        lastSeen: info.lastSeen,
        connections: this.userSockets.get(id)?.size || 0,
      })),
    };
  }
}

module.exports = new SocketService();
