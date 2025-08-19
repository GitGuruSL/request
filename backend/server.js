const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const dotenv = require('dotenv');

// Load environment variables
dotenv.config({ path: '.env.rds' });

// Import services
const dbService = require('./services/database');

// Import routes
const authRoutes = require('./routes/auth');
const flutterAuthRoutes = require('./routes/flutter-auth');
const categoryRoutes = require('./routes/categories');
const subcategoryRoutes = require('./routes/subcategories');
const countryModuleRoutes = require('./routes/country-modules');
const cityRoutes = require('./routes/cities');
const requestRoutes = require('./routes/requests');
const vehicleTypeRoutes = require('./routes/vehicle-types');
const uploadRoutes = require('./routes/upload'); // Image upload routes
const brandRoutes = require('./routes/brands');
const masterProductRoutes = require('./routes/master-products');
const entityActivationRoutes = require('./routes/entity-activations');
const subscriptionPlansNewRoutes = require('./routes/subscription-plans-new');

// New country-specific routes
const countryProductRoutes = require('./routes/country-products');
const countryCategoryRoutes = require('./routes/country-categories');
const countrySubcategoryRoutes = require('./routes/country-subcategories');
const countryBrandRoutes = require('./routes/country-brands');
const countryVariableTypeRoutes = require('./routes/country-variable-types');
const adminUserRoutes = require('./routes/admin-users');

const app = express();

// Security middleware
app.use(helmet({
  crossOriginResourcePolicy: { policy: "cross-origin" }
}));

// CORS configuration
const allowedOrigins = [
  'http://localhost:3000',
  'http://localhost:3001', 
  'http://127.0.0.1:3000',
  'http://127.0.0.1:3001',
  'https://admin.requestmarketplace.com',
  'https://requestmarketplace.com'
];

app.use(cors({
  origin: (origin, callback) => {
    if (!origin || allowedOrigins.includes(origin)) {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With']
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 1000, // limit each IP to 1000 requests per windowMs
  message: 'Too many requests from this IP, please try again later.',
  standardHeaders: true,
  legacyHeaders: false,
});
app.use(limiter);

// Middleware
app.use(morgan('combined'));
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

// Health check endpoint
app.get('/health', async (req, res) => {
    try {
        const dbHealth = await dbService.healthCheck();
        
        if (!dbHealth.connected) {
            const diag = await dbService.diagnoseConnectivity().catch(()=>null);
            return res.status(503).json({
                status: 'unhealthy',
                timestamp: new Date().toISOString(),
                database: dbHealth,
                diagnosis: diag
            });
        }
        
        res.json({
            status: 'healthy',
            timestamp: new Date().toISOString(),
            database: dbHealth,
            version: process.env.npm_package_version || '1.0.0'
        });
    } catch (error) {
        const diag = await dbService.diagnoseConnectivity().catch(()=>null);
        res.status(503).json({
            status: 'unhealthy',
            timestamp: new Date().toISOString(),
            error: error.message,
            diagnosis: diag
        });
    }
});

// Test endpoint
app.get('/test', (req, res) => {
    res.json({ 
        message: 'Server is running!', 
        timestamp: new Date().toISOString(),
        environment: process.env.NODE_ENV || 'development'
    });
});

// Serve static files (uploaded images)
app.use('/uploads', express.static('uploads', {
  setHeaders: (res, path) => {
    // Set CORS headers for images
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET');
    res.setHeader('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept');
  }
}));

// API routes
app.use('/api/auth', authRoutes);
app.use('/api/flutter/auth', flutterAuthRoutes);
app.use('/api/categories', categoryRoutes);
app.use('/api/subcategories', subcategoryRoutes);
app.use('/api/cities', cityRoutes);
app.use('/api/requests', requestRoutes);
app.use('/api/vehicle-types', vehicleTypeRoutes);
app.use('/api/upload', uploadRoutes); // Image upload endpoint
app.use('/api/country-modules', countryModuleRoutes);
app.use('/api/brands', brandRoutes);
app.use('/api/master-products', masterProductRoutes);
app.use('/api/entity-activations', entityActivationRoutes);
app.use('/api/subscription-plans-new', subscriptionPlansNewRoutes);

// Country-specific routes
app.use('/api/country-products', countryProductRoutes);
app.use('/api/country-categories', countryCategoryRoutes);
app.use('/api/country-subcategories', countrySubcategoryRoutes);
app.use('/api/country-brands', countryBrandRoutes);
app.use('/api/country-variable-types', countryVariableTypeRoutes);
app.use('/api/admin-users', adminUserRoutes);

// Global error handler
app.use((err, req, res, next) => {
    console.error('Global error handler:', err);
    
    if (err.message === 'Not allowed by CORS') {
        return res.status(403).json({
            success: false,
            error: 'CORS policy violation',
            origin: req.get('Origin')
        });
    }
    
    res.status(500).json({
        success: false,
        error: 'Internal server error',
        message: process.env.NODE_ENV === 'development' ? err.message : 'Something went wrong'
    });
});

// 404 handler
app.use('*', (req, res) => {
    res.status(404).json({
        success: false,
        error: 'Endpoint not found',
        path: req.originalUrl,
        method: req.method
    });
});

// Simple ping endpoint for connectivity diagnostics (before starting server)
app.get('/api/ping', (req, res) => {
  res.json({ success: true, message: 'pong', time: new Date().toISOString() });
});

// Start server
const PORT = process.env.PORT || 3001;
const HOST = process.env.HOST || '0.0.0.0'; // Bind to all interfaces for Android emulator / devices
app.listen(PORT, HOST, () => {
  console.log(`🚀 Server running on ${HOST}:${PORT}`);
  console.log(`🔗 Health check: http://localhost:${PORT}/health`);
  console.log(`📊 API base: http://localhost:${PORT}/api`);
  console.log(`🤖 Android emulator: http://10.0.2.2:${PORT}/api`);
  console.log(`📶 Ping: http://localhost:${PORT}/api/ping`);
  console.log(`🌍 CORS allowed origins: ${allowedOrigins.join(', ')}`);
});

module.exports = app;
