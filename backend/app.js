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
const usersRoutes = require('./routes/users'); // NEW - user profile management
const categoryRoutes = require('./routes/categories');
const cityRoutes = require('./routes/cities');
const vehicleTypeRoutes = require('./routes/vehicle-types');
const requestRoutes = require('./routes/requests');
const countryRoutes = require('./routes/countries');
const uploadRoutes = require('./routes/upload'); // NEW
const uploadS3Routes = require('./routes/uploadS3'); // NEW - S3 upload/signed URLs
const testImageRoutes = require('./routes/test-images'); // TEST
const subscriptionPlansLegacy = require('./routes/subscription-plans-legacy');
const subscriptionPlansNew = require('./routes/subscription-plans-new');
const contentPagesRoutes = require('./routes/content-pages');
console.log('🔧 About to require driver-verifications route');
const driverVerificationRoutes = require('./routes/driver-verifications'); // NEW
console.log('🔧 About to require business-verifications route');
const businessVerificationRoutes = require('./routes/business-verifications-simple'); // Use the simple working version
const modulesRoutes = require('./routes/modules'); // NEW - module management

// Import centralized data routes
const masterProductsRoutes = require('./routes/master-products');
const brandsRoutes = require('./routes/brands');
const subcategoriesRoutes = require('./routes/subcategories');
const variableTypesRoutes = require('./routes/variable-types');

// Import country-specific routes
const countryProductsRoutes = require('./routes/country-products');
const countryBrandsRoutes = require('./routes/country-brands');
const countryCategoriesRoutes = require('./routes/country-categories');
const countrySubcategoriesRoutes = require('./routes/country-subcategories');
const countryVariableTypesRoutes = require('./routes/country-variable-types');

// Import price comparison routes
const priceListingsRoutes = require('./routes/price-listings');
const paymentMethodsRoutes = require('./routes/payment-methods');
const s3Routes = require('./routes/uploadS3');

console.log('🔧 About to register driver-verifications route');

// Serve static files (uploaded images)
app.use('/uploads', express.static('uploads', {
  setHeaders: (res, path) => {
    // Set CORS headers for images
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET');
    res.setHeader('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept');
  }
}));

// Use routes
app.use('/api/auth', authRoutes);
app.use('/api/auth', flutterAuthRoutes); // NEW - adds Flutter-specific endpoints
app.use('/api/users', usersRoutes); // NEW - user profile management
app.use('/api/categories', categoryRoutes);
app.use('/api/cities', cityRoutes);
app.use('/api/vehicle-types', vehicleTypeRoutes);
app.use('/api/requests', requestRoutes);
app.use('/api/countries', countryRoutes);

// Centralized data routes (Super Admin)
app.use('/api/master-products', masterProductsRoutes);
app.use('/api/brands', brandsRoutes);
app.use('/api/subcategories', subcategoriesRoutes);
app.use('/api/variable-types', variableTypesRoutes);

// Country-specific routes
app.use('/api/country-products', countryProductsRoutes);
app.use('/api/country-brands', countryBrandsRoutes);
app.use('/api/country-categories', countryCategoriesRoutes);
app.use('/api/country-subcategories', countrySubcategoriesRoutes);
app.use('/api/country-variable-types', countryVariableTypesRoutes);

// Price comparison routes  
app.use('/api/price-listings', priceListingsRoutes);
app.use('/api/payment-methods', paymentMethodsRoutes);
app.use('/api/s3', s3Routes);

app.use('/api/upload', uploadRoutes); // NEW - image upload endpoint
app.use('/api/uploads', uploadRoutes); // Alias to support admin-react '/uploads/payment-methods'
app.use('/api/s3', uploadS3Routes); // NEW - S3 upload + signed URL endpoints
app.use('/api/test-images', testImageRoutes); // TEST - image serving test
app.use('/api', subscriptionPlansLegacy); // legacy paths /subscription-plans, /user-subscriptions
app.use('/api', subscriptionPlansNew); // new CRUD under /subscription-plans-new
app.use('/api/content-pages', contentPagesRoutes); // content pages management
app.use('/api/driver-verifications', driverVerificationRoutes); // NEW - driver verification management
app.use('/api/business-verifications', businessVerificationRoutes); // NEW - business verification management
app.use('/api/modules', modulesRoutes); // NEW - module management
console.log('🔧 Driver-verifications route registered at /api/driver-verifications');
console.log('🔧 Business-verifications route registered at /api/business-verifications');

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

// Only start the HTTP listener when not running in test environment (so Jest / supertest can import app)
if (process.env.NODE_ENV !== 'test') {
  const PORT = process.env.PORT || 3001;
  const HOST = process.env.HOST || '0.0.0.0'; // Allow connections from all interfaces including Android emulator
  app.listen(PORT, HOST, () => {
    console.log(`Server running on ${HOST}:${PORT}`);
    console.log(`Health check: http://localhost:${PORT}/health`);
    console.log(`Android emulator can access via: http://10.0.2.2:${PORT}/health`);
  });
}

module.exports = app;
