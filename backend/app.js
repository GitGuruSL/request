// Update your main app.js to include the new Flutter auth routes

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');

const app = express();

// Security middleware
app.use(helmet());
app.use(cors());

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});
app.use(limiter);

// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Logging
app.use(morgan('combined'));

// Health check endpoint
app.get('/health', async (req, res) => {
  try {
    const { pool } = require('./database');
    const result = await pool.query('SELECT NOW()');
    res.json({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      database: {
        status: 'healthy',
        timestamp: result.rows[0].now,
        connectionCount: pool.totalCount,
        idleCount: pool.idleCount,
        waitingCount: pool.waitingCount
      },
      version: '1.0.0'
    });
  } catch (error) {
    res.status(503).json({
      status: 'unhealthy',
      timestamp: new Date().toISOString(),
      error: error.message
    });
  }
});

// Import routes
const authRoutes = require('./routes/auth');
const flutterAuthRoutes = require('./routes/flutter-auth'); // NEW
const categoryRoutes = require('./routes/categories');
const cityRoutes = require('./routes/cities');
const vehicleTypeRoutes = require('./routes/vehicle-types');
const requestRoutes = require('./routes/requests');

// Use routes
app.use('/api/auth', authRoutes);
app.use('/api/auth', flutterAuthRoutes); // NEW - adds Flutter-specific endpoints
app.use('/api/categories', categoryRoutes);
app.use('/api/cities', cityRoutes);
app.use('/api/vehicle-types', vehicleTypeRoutes);
app.use('/api/requests', requestRoutes);

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    success: false,
    message: 'Something went wrong!',
    error: process.env.NODE_ENV === 'development' ? err.message : undefined
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    message: 'Route not found'
  });
});

const PORT = process.env.PORT || 3001;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Health check: http://localhost:${PORT}/health`);
});

module.exports = app;
