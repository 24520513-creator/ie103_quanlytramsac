require('dotenv').config({ path: '.env' });
const app = require('./app');
const { getPool } = require('./config/db');

const PORT = process.env.PORT || 3000;

async function start() {
  try {
    await getPool();
    console.log('Database connected successfully');

    app.listen(PORT, () => {
      console.log(`EV Charging Backend running on port ${PORT}`);
      console.log(`Swagger docs: http://localhost:${PORT}/api-docs`);
      console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
    });
  } catch (err) {
    console.error('Failed to start server:', err);
    process.exit(1);
  }
}

start();
