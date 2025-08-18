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
const countryModuleRoutes = require('./routes/country-modules');
const cityRoutes = require('./routes/cities');
const requestRoutes = require('./routes/requests');
const vehicleTypeRoutes = require('./routes/vehicle-types');
const brandRoutes = require('./routes/brands');
const masterProductRoutes = require('./routes/master-products');
const entityActivationRoutes = require('./routes/entity-activations');
const subscriptionPlansNewRoutes = require('./routes/subscription-plans-new');

const app = express();

// Security middleware
app.use(helmet());
// CORS: include common dev origins (CRA 3000, Vite 5173) unless overridden
const defaultOrigins = ['http://localhost:3000', 'http://localhost:5173'];
app.use(cors({
    origin: process.env.ALLOWED_ORIGINS ? process.env.ALLOWED_ORIGINS.split(',') : defaultOrigins,
    credentials: true
}));

// Rate limiting
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100, // limit each IP to 100 requests per windowMs
    message: {
        error: 'Too many requests from this IP, please try again later.'
    }
});
app.use('/api/', limiter);

// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Logging middleware
app.use(morgan('combined'));

// Health check endpoint
app.get('/health', async (req, res) => {
    try {
        const dbHealth = await dbService.healthCheck();
        if (dbHealth.status !== 'healthy') {
            const diag = await dbService.diagnoseConnectivity();
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
            error: error.message,
            timestamp: new Date().toISOString(),
            diagnosis: diag
        });
    }
});

// API routes
app.use('/api/auth', authRoutes);
app.use('/api/auth', flutterAuthRoutes);
app.use('/api/categories', categoryRoutes);
app.use('/api/cities', cityRoutes);
app.use('/api/requests', requestRoutes);
app.use('/api/vehicle-types', vehicleTypeRoutes);
app.use('/api/country-modules', countryModuleRoutes);
app.use('/api/brands', brandRoutes);
app.use('/api/master-products', masterProductRoutes);
app.use('/api/entity-activations', entityActivationRoutes);
app.use('/api/subscription-plans-new', subscriptionPlansNewRoutes);

// 404 handler
app.use('*', (req, res) => {
    res.status(404).json({
        success: false,
        error: 'Endpoint not found'
    });
});

// Global error handler
app.use((error, req, res, next) => {
    console.error('Global error handler:', error);
    
    res.status(error.statusCode || 500).json({
        success: false,
        error: process.env.NODE_ENV === 'production' 
            ? 'Internal server error' 
            : error.message,
        ...(process.env.NODE_ENV !== 'production' && { stack: error.stack })
    });
});

// Graceful shutdown
process.on('SIGTERM', async () => {
    console.log('SIGTERM received, shutting down gracefully');
    
    try {
        await dbService.close();
        console.log('Database connections closed');
        process.exit(0);
    } catch (error) {
        console.error('Error during shutdown:', error);
        process.exit(1);
    }
});

process.on('SIGINT', async () => {
    console.log('SIGINT received, shutting down gracefully');
    
    try {
        await dbService.close();
        console.log('Database connections closed');
        process.exit(0);
    } catch (error) {
        console.error('Error during shutdown:', error);
        process.exit(1);
    }
});

// Startup DB connectivity check
(async () => {
    try {
        const healthy = await dbService.healthCheck();
        if (healthy.status !== 'healthy') {
            console.error('Database not healthy at startup:', healthy);
        } else {
            console.log('Database connection OK at startup');
        }
    } catch (e) {
        console.error('Failed initial DB connectivity check:', e);
    }
})();

const PORT = process.env.PORT || 3001;

app.listen(PORT, () => {
    console.log(`🚀 Server running on port ${PORT}`);
    console.log(`📊 Environment: ${process.env.NODE_ENV || 'development'}`);
    console.log(`🔗 Health check: http://localhost:${PORT}/health`);
});

module.exports = app;
