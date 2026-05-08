require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');

const routes = require('./routes');
const { errorHandler } = require('./middleware/errorHandler');
const authConfig = require('./config/auth');
const { getPool } = require('./config/database');

const app = express();

// Security
app.use(helmet());
app.use(cors({ origin: '*', credentials: true }));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));
app.use(morgan('dev'));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  message: { success: false, data: null, message: 'Too many requests, please try again later' },
});
app.use('/api/', limiter);

// API routes
app.use('/api', routes);

// Error handler
app.use(errorHandler);

// Start server
async function start() {
  try {
    await getPool();
    console.log('Database connected successfully');

    app.listen(authConfig.port, () => {
      console.log(`EV Charging Backend running on port ${authConfig.port}`);
      console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
    });
  } catch (err) {
    console.error('Failed to start server:', err);
    process.exit(1);
  }
}

start();
