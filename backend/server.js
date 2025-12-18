import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import dotenv from 'dotenv';
import { connectDB } from './config/database.js';
import { connectRedis } from './config/redis.js';
import authRoutes from './routes/auth.js';
import mealRoutes from './routes/meals.js';
import photoRoutes from './routes/photo.js';
import fastingRoutes from './routes/fasting.js';
import recommendationRoutes from './routes/recommendations.js';
import subscriptionRoutes from './routes/subscriptions.js';
import adminRoutes from './routes/admin.js';
import healthRoutes from './routes/health.js';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// Trust proxy for Render (needed for rate limiting behind proxy)
app.set('trust proxy', true);

// Security middleware
app.use(helmet());
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || '*',
  credentials: true
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});
app.use('/api/', limiter);

// Body parsing
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Root route - API information
app.get('/', (req, res) => {
  res.json({
    message: 'GoFit.Ai API Server',
    version: '1.0.0',
    status: 'running',
    timestamp: new Date().toISOString(),
    endpoints: {
      health: '/health',
      api: '/api',
      auth: '/api/auth',
      meals: '/api/meals',
      photo: '/api/photo',
      fasting: '/api/fasting',
      recommendations: '/api/recommendations',
      subscriptions: '/api/subscriptions',
      healthData: '/api/health'
    }
  });
});

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// API routes
app.use('/api/auth', authRoutes);
app.use('/api/photo', photoRoutes);
app.use('/api/meals', mealRoutes);
app.use('/api/fasting', fastingRoutes);
app.use('/api/recommendations', recommendationRoutes);
app.use('/api/subscriptions', subscriptionRoutes);
app.use('/api/health', healthRoutes);
app.use('/api/admin', adminRoutes);

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(err.status || 500).json({
    message: err.message || 'Internal server error',
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ message: 'Route not found' });
});

// Validate required environment variables
function validateEnv() {
  const required = ['JWT_SECRET', 'MONGODB_URI'];
  const missing = required.filter(key => !process.env[key]);
  
  if (missing.length > 0) {
    console.error('❌ Missing required environment variables:');
    missing.forEach(key => {
      console.error(`   - ${key}`);
    });
    console.error('\n📝 Please set these in your Render dashboard:');
    console.error('   Service → Environment → Add Environment Variable');
    console.error('\n💡 See RENDER_ENV_SETUP.md for detailed instructions');
    return false;
  }
  
  return true;
}

// Start server
async function startServer() {
  try {
    // Validate environment variables first
    if (!validateEnv()) {
      console.error('❌ Server startup aborted due to missing environment variables');
      process.exit(1);
    }
    
    // Connect to MongoDB (required)
    await connectDB();
    
    // Connect to Redis (optional)
    try {
      await connectRedis();
    } catch (redisError) {
      console.log('⚠️  Redis connection failed, continuing without Redis');
    }
    
    app.listen(PORT, () => {
      console.log(`🚀 Server running on port ${PORT}`);
      console.log(`📱 Environment: ${process.env.NODE_ENV || 'development'}`);
      console.log(`✅ Required environment variables loaded`);
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
}

startServer();

export default app;

