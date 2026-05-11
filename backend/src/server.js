require('dotenv').config({ path: '.env' });
const app = require('./app');
const { getPool, closePool } = require('./config/database');
const socketService = require('./services/socketService');

const PORT = process.env.PORT || 3000;

process.on('unhandledRejection', (reason) => {
  console.error('UNHANDLED PROMISE REJECTION:', reason);
});
process.on('uncaughtException', (err) => {
  console.error('UNCAUGHT EXCEPTION:', err);
});

async function start() {
  try {
    await getPool();
    console.log('Database connected successfully');

    const server = app.listen(PORT, () => {
      console.log(`EV Charging Backend running on port ${PORT}`);
      console.log(`Swagger docs: http://localhost:${PORT}/api-docs`);
      console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
    });

    socketService.init(server);
    console.log('WebSocket server initialized');

    const gracefulShutdown = async () => {
      console.log('\nShutting down gracefully...');
      server.close();
      await closePool();
      process.exit(0);
    };
    process.on('SIGINT', gracefulShutdown);
    process.on('SIGTERM', gracefulShutdown);
  } catch (err) {
    console.error('Failed to start server:', err);
    process.exit(1);
  }
}

start();
