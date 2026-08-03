require('dotenv').config({ path: require('path').resolve(__dirname, '../.env') });

const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const morgan = require('morgan');
const errorHandler = require('./middleware/errorHandler');

// ─── Register Mongoose models ─────────────────────────────────────────────────
// Importing here ensures schemas + indexes are registered before any request
// is served, regardless of which route file requires which model first.
require('./models/MasterConfig');   // must come before Student (Student refs it)
require('./models/Student');
require('./models/Transaction');
require('./models/AllocationLog');
require('./models/Admin');

const app = express();

// ─── Security ────────────────────────────────────────────────────────────────
app.use(helmet());

// ─── CORS ─────────────────────────────────────────────────────────────────────
// Allow all origins — this is an internal LAN school app; all clients are
// trusted devices on the school network. Restricting by IP would break every
// time a device's DHCP lease changes.
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Accept'],
  preflightContinue: false,
  optionsSuccessStatus: 204,
}));

// ─── HTTP request logger ─────────────────────────────────────────────────────
if (process.env.NODE_ENV !== 'test') {
  app.use(morgan('dev'));
}

// ─── Body parsing ────────────────────────────────────────────────────────────
app.use(express.json());
app.use(express.urlencoded({ extended: false }));

// ─── Health check ─────────────────────────────────────────────────────────────
app.get('/api/health', (req, res) => {
  res.json({ success: true, data: { status: 'ok' }, message: 'Server is running.' });
});

app.get('/', (req, res) => {
  res.json({ success: true, message: 'API is running. Access endpoints via /api' });
});

const auth = require('./middleware/auth');

// ─── Routes ───────────────────────────────────────────────────────────────────
// Public routes (no auth middleware)
app.use('/api/auth', require('./routes/authRoutes'));

// Protected routes
app.use('/api/master-config', auth, require('./routes/masterConfigRoutes'));
app.use('/api/students',      auth, require('./routes/studentRoutes'));
app.use('/api/whatsapp',      auth, require('./routes/whatsappRoutes'));
app.use('/api/allocations',   auth, require('./routes/allocationRoutes'));
app.use('/api/dashboard',      auth, require('./routes/dashboardRoutes'));

// ─── 404 handler ─────────────────────────────────────────────────────────────
app.use((req, res) => {
  res.status(404).json({ success: false, error: 'Route not found.' });
});

// ─── Global error handler (must be last) ─────────────────────────────────────
app.use(errorHandler);

module.exports = app;
