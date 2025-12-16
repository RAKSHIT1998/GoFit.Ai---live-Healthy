import Redis from 'ioredis';

let redisClient = null;
let redisEnabled = false;

export async function connectRedis() {
  // Skip Redis if REDIS_HOST is not set or explicitly disabled
  if (!process.env.REDIS_HOST || process.env.REDIS_ENABLED === 'false') {
    console.log('⚠️  Redis disabled or not configured - continuing without Redis');
    return null;
  }

  try {
    redisClient = new Redis({
      host: process.env.REDIS_HOST,
      port: parseInt(process.env.REDIS_PORT || '6379'),
      password: process.env.REDIS_PASSWORD || undefined,
      retryStrategy: (times) => {
        if (times > 3) {
          console.log('⚠️  Redis connection failed after 3 retries - continuing without Redis');
          return null; // Stop retrying
        }
        const delay = Math.min(times * 50, 2000);
        return delay;
      },
      maxRetriesPerRequest: 1,
      enableOfflineQueue: false
    });

    redisClient.on('connect', () => {
      console.log('✅ Redis connected');
      redisEnabled = true;
    });

    redisClient.on('error', (err) => {
      console.error('❌ Redis error:', err.message);
      redisEnabled = false;
      // Don't throw - allow app to continue without Redis
    });

    redisClient.on('close', () => {
      console.log('⚠️  Redis connection closed');
      redisEnabled = false;
    });

    // Test connection with a timeout
    try {
      await Promise.race([
        redisClient.ping(),
        new Promise((_, reject) => 
          setTimeout(() => reject(new Error('Redis connection timeout')), 5000)
        )
      ]);
      redisEnabled = true;
      return redisClient;
    } catch (pingError) {
      console.error('⚠️  Redis ping failed:', pingError.message);
      redisEnabled = false;
      redisClient = null;
      return null;
    }
  } catch (error) {
    console.error('⚠️  Redis connection failed:', error.message);
    console.log('⚠️  Continuing without Redis - background jobs will be disabled');
    redisEnabled = false;
    redisClient = null;
    // Don't throw - allow app to continue without Redis
    return null;
  }
}

export function getRedis() {
  return redisClient;
}

export function isRedisEnabled() {
  return redisEnabled && redisClient !== null;
}

