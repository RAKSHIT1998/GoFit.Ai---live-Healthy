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
import progressRoutes from './routes/progress.js';
import workoutRoutes from './routes/workouts.js';
import mealPlanRoutes from './routes/mealPlans.js';
import recipeRoutes from './routes/recipes.js';
import challengeRoutes from './routes/challenges.js';
import measurementRoutes from './routes/measurements.js';
import barcodeRoutes from './routes/barcode.js';
import educationRoutes from './routes/education.js';
import analyticsRoutes from './routes/analytics.js';
import onboardingRoutes from './routes/onboarding.js';
import notificationRoutes from './routes/notifications.js';

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

// Rate limiting - General API routes (excludes auth routes which have their own limiters)
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 500, // Increased to 500 requests per 15 minutes (was 100 - too restrictive for mobile app)
  message: 'Too many requests from this IP, please try again later.',
  standardHeaders: true,
  legacyHeaders: false,
  skip: (req) => {
    // Skip rate limiting for auth routes, recommendations, photo analysis, and subscriptions (handled by separate limiters)
    // Check both req.path (relative to mount point) and req.originalUrl (full path)
    const path = req.path || '';
    const originalUrl = req.originalUrl || req.url || '';
    // When mounted at /api/, req.path for /api/auth/register is /auth/register
    // originalUrl contains the full path including /api/
    const isAuthRoute = path.startsWith('/auth') || originalUrl.includes('/api/auth') || originalUrl.includes('/auth/');
    const isRecommendationsRoute = path.startsWith('/recommendations') || originalUrl.includes('/api/recommendations');
    const isPhotoRoute = path.startsWith('/photo') || originalUrl.includes('/api/photo');
    const isSubscriptionRoute = path.startsWith('/subscriptions') || originalUrl.includes('/api/subscriptions');
    return isAuthRoute || isRecommendationsRoute || isPhotoRoute || isSubscriptionRoute;
  }
});

// Rate limiter specifically for registration (lenient for onboarding, but prevents abuse)
const registrationLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 200, // Increased to 200 registration attempts per 15 minutes per IP (was 100)
  message: 'Too many registration attempts. Please wait a few minutes and try again.',
  standardHeaders: true,
  legacyHeaders: false,
  skipSuccessfulRequests: true, // Don't count successful registrations
});

// Rate limiter for other authentication routes (login, me, etc.)
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 300, // Increased to 300 auth requests per 15 minutes per IP (was 100 - too restrictive)
  message: 'Too many authentication attempts, please try again later.',
  standardHeaders: true,
  legacyHeaders: false,
  skipSuccessfulRequests: true, // Don't count successful requests
  skip: (req) => {
    // Skip rate limiting for registration endpoint (handled by registrationLimiter)
    const path = req.path || '';
    const originalUrl = req.originalUrl || req.url || '';
    return path === '/register' || path.startsWith('/api/auth/register') || originalUrl.includes('/api/auth/register');
  }
});

// Rate limiter for recommendations (more lenient since it's a core feature)
const recommendationsLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 300, // Increased to 300 requests per 15 minutes (was 200)
  message: 'Too many recommendation requests. Please wait a moment and try again.',
  standardHeaders: true,
  legacyHeaders: false,
  skipSuccessfulRequests: false, // Count all requests (including successful ones)
});

// Rate limiter for photo analysis (very lenient since it requires multiple retries)
const photoLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 200, // Allow 200 photo analysis requests per 15 minutes per IP (accounts for retries)
  message: 'Too many photo analysis requests. Please wait a moment and try again.',
  standardHeaders: true,
  legacyHeaders: false,
  skipSuccessfulRequests: false, // Count all requests (including successful ones)
});

// Rate limiter for subscription routes (lenient since status checks happen frequently)
const subscriptionLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 300, // Allow 300 subscription requests per 15 minutes per IP
  message: 'Too many subscription requests. Please wait a moment and try again.',
  standardHeaders: true,
  legacyHeaders: false,
  skipSuccessfulRequests: false, // Count all requests
});

// IMPORTANT: Apply limiters in order of specificity (most specific first)
// This ensures requests hit the correct limiter

// Apply registration limiter specifically to registration endpoint (most specific)
app.use('/api/auth/register', registrationLimiter);

// Apply auth limiter to other auth routes (login, me, etc.)
app.use('/api/auth', authLimiter);

// Apply recommendations limiter to recommendations routes
app.use('/api/recommendations', recommendationsLimiter);

// Apply photo limiter to photo analysis routes (before general limiter)
app.use('/api/photo', photoLimiter);

// Apply subscription limiter to subscription routes (before general limiter)
app.use('/api/subscriptions', subscriptionLimiter);

// Apply general limiter to all other API routes (least specific, applied last)
// The skip function ensures auth, recommendations, photo, and subscription routes are not counted by this limiter
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
      healthData: '/api/health',
      progress: '/api/progress',
      workouts: '/api/workouts',
      mealPlans: '/api/meal-plans',
      recipes: '/api/recipes',
      challenges: '/api/challenges',
      measurements: '/api/measurements',
      barcode: '/api/barcode',
      education: '/api/education',
      analytics: '/api/analytics',
      onboarding: '/api/onboarding',
      notifications: '/api/notifications'
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
app.use('/api/progress', progressRoutes);
app.use('/api/workouts', workoutRoutes);
app.use('/api/meal-plans', mealPlanRoutes);
app.use('/api/recipes', recipeRoutes);
app.use('/api/challenges', challengeRoutes);
app.use('/api/measurements', measurementRoutes);
app.use('/api/barcode', barcodeRoutes);
app.use('/api/education', educationRoutes);
app.use('/api/analytics', analyticsRoutes);
app.use('/api/onboarding', onboardingRoutes);
app.use('/api/notifications', notificationRoutes);

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
      
      // Log OpenAI API key status (without exposing the key)
      if (process.env.OPENAI_API_KEY) {
        const keyPreview = process.env.OPENAI_API_KEY.substring(0, 10) + '...';
        console.log(`✅ OPENAI_API_KEY is configured (${keyPreview})`);
      } else {
        console.log(`⚠️  OPENAI_API_KEY is NOT configured - AI features will not work`);
        console.log(`   Get your API key at: https://platform.openai.com/api-keys`);
      }
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
}

startServer();

export default app;

