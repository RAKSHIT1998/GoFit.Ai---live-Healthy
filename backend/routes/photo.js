import express from 'express';
import multer from 'multer';
import AWS from 'aws-sdk';
import axios from 'axios';
import { authMiddleware } from '../middleware/authMiddleware.js';
import { Queue } from 'bullmq';
import { getRedis, isRedisEnabled } from '../config/redis.js';

const router = express.Router();

// Configure multer for memory storage
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024 } // 10MB
});

// Initialize LogMeal API
// Get your API key at: https://logmeal.com/api
const LOGMEAL_API_KEY = (process.env.LOGMEAL_API_KEY || '').trim();
const LOGMEAL_API_URL = 'https://api.logmeal.com/v2/image/segmentation/complete';

// Log LogMeal status on module load
if (LOGMEAL_API_KEY) {
  console.log(`✅ LOGMEAL_API_KEY loaded (length: ${LOGMEAL_API_KEY.length}, starts with: ${LOGMEAL_API_KEY.substring(0, 10)}...)`);
} else {
  console.error('❌ LOGMEAL_API_KEY is missing or empty. Food recognition will not work.');
  console.error('   Set LOGMEAL_API_KEY in Render environment variables: https://logmeal.com/api');
}

// Initialize S3 client
const s3 = new AWS.S3({
  accessKeyId: process.env.AWS_ACCESS_KEY_ID,
  secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
  region: process.env.AWS_REGION || 'us-east-1'
});

// Initialize queue for background processing (only if Redis is available)
let photoQueue = null;
if (isRedisEnabled()) {
  try {
    photoQueue = new Queue('photo-analysis', {
      connection: getRedis()
    });
  } catch (error) {
    console.log('⚠️  Photo queue initialization failed, continuing without background jobs');
  }
}

// Upload and analyze photo
router.post('/analyze', authMiddleware, upload.single('photo'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ message: 'No photo provided' });
    }

    const userId = req.user._id.toString();
    const file = req.file;
    
    // Check if S3 is configured
    const s3Configured = process.env.S3_BUCKET_NAME && 
                         process.env.AWS_ACCESS_KEY_ID && 
                         process.env.AWS_SECRET_ACCESS_KEY;
    
    let imageUrl = null;
    let imageKey = null;
    
    // Upload to S3 only if configured (optional)
    if (s3Configured) {
      try {
        const filename = `meals/${userId}/${Date.now()}-${file.originalname}`;
        const uploadParams = {
          Bucket: process.env.S3_BUCKET_NAME,
          Key: filename,
          Body: file.buffer,
          ContentType: file.mimetype,
          ACL: 'private'
        };

        await s3.putObject(uploadParams).promise();
        imageUrl = `https://${process.env.S3_BUCKET_NAME}.s3.${process.env.AWS_REGION || 'us-east-1'}.amazonaws.com/${filename}`;
        imageKey = filename;
      } catch (s3Error) {
        console.error('⚠️ S3 upload failed, continuing without storage:', s3Error.message);
        // Continue without S3 storage - we can still analyze the photo
      }
    } else {
      console.log('ℹ️ S3 not configured, skipping image storage. Photo will be analyzed but not saved.');
    }

    // Check if LogMeal API key is configured
    if (!LOGMEAL_API_KEY || LOGMEAL_API_KEY.length === 0) {
      console.error('❌ LOGMEAL_API_KEY is not set or empty');
      console.error('   Environment check:', {
        hasEnvVar: !!process.env.LOGMEAL_API_KEY,
        envVarLength: process.env.LOGMEAL_API_KEY?.length || 0,
        trimmedLength: LOGMEAL_API_KEY.length
      });
      return res.status(500).json({ 
        message: 'Food recognition service is not configured. Please set LOGMEAL_API_KEY environment variable in Render. Get your API key at https://logmeal.com/api',
        error: 'LogMeal API key missing',
        hint: 'Go to Render Dashboard → Your Service → Environment → Add LOGMEAL_API_KEY'
      });
    }

    // Analyze with LogMeal API
    try {
      console.log('🤖 Starting LogMeal analysis for user:', userId);
      console.log('📝 LOGMEAL_API_KEY status:', LOGMEAL_API_KEY ? `Set (${LOGMEAL_API_KEY.substring(0, 10)}...)` : 'NOT SET');
      
      // Set timeout for LogMeal API call (30 seconds)
      const timeoutPromise = new Promise((_, reject) => {
        setTimeout(() => reject(new Error('Request timeout')), 30000);
      });
      
      // Prepare form data for LogMeal API
      const FormData = (await import('form-data')).default;
      const formData = new FormData();
      formData.append('image', file.buffer, {
        filename: file.originalname || 'photo.jpg',
        contentType: file.mimetype || 'image/jpeg'
      });
      
      // Call LogMeal API
      const logmealPromise = axios.post(LOGMEAL_API_URL, formData, {
        headers: {
          'Authorization': `Bearer ${LOGMEAL_API_KEY}`,
          ...formData.getHeaders()
        },
        timeout: 30000
      });
      
      // Race between LogMeal call and timeout
      const logmealResponse = await Promise.race([logmealPromise, timeoutPromise]);
      
      console.log('✅ LogMeal analysis completed');
      console.log('📝 Response status:', logmealResponse.status);
      console.log('📝 Response data keys:', Object.keys(logmealResponse.data || {}));
      console.log('📝 Response preview:', JSON.stringify(logmealResponse.data).substring(0, 500));
      
      // Parse LogMeal response and convert to our format
      let items = [];
      
      // Parse LogMeal response and convert to our format
      const responseData = logmealResponse.data;
      
      // LogMeal API can return different response formats
      // Check for segmentation array (multiple food items)
      if (responseData.segmentation && Array.isArray(responseData.segmentation)) {
        items = responseData.segmentation.map((seg, index) => {
          const foodItem = seg.food_item || seg;
          const nutrition = foodItem.nutrition || foodItem.nutrition_info || {};
          
          return {
            name: foodItem.name || foodItem.food_name || `Food Item ${index + 1}`,
            calories: Math.round(nutrition.calories || nutrition.cal || 0),
            protein: Math.round((nutrition.protein || 0) * 100) / 100,
            carbs: Math.round((nutrition.carbs || nutrition.carbohydrates || 0) * 100) / 100,
            fat: Math.round((nutrition.fat || 0) * 100) / 100,
            sugar: Math.round((nutrition.sugar || 0) * 100) / 100,
            portionSize: foodItem.portion_size || foodItem.portion || '1 serving',
            confidence: seg.confidence || 0.8
          };
        });
        
        console.log(`✅ Parsed ${items.length} food items from LogMeal segmentation`);
      } 
      // Check for single food item response
      else if (responseData.food_item || responseData.food) {
        const foodItem = responseData.food_item || responseData.food;
        const nutrition = foodItem.nutrition || foodItem.nutrition_info || {};
        
        items = [{
          name: foodItem.name || foodItem.food_name || 'Food Item',
          calories: Math.round(nutrition.calories || nutrition.cal || 0),
          protein: Math.round((nutrition.protein || 0) * 100) / 100,
          carbs: Math.round((nutrition.carbs || nutrition.carbohydrates || 0) * 100) / 100,
          fat: Math.round((nutrition.fat || 0) * 100) / 100,
          sugar: Math.round((nutrition.sugar || 0) * 100) / 100,
          portionSize: foodItem.portion_size || foodItem.portion || '1 serving',
          confidence: 0.9
        }];
        
        console.log(`✅ Parsed 1 food item from LogMeal response`);
      } 
      // Check for array of food items directly
      else if (Array.isArray(responseData) && responseData.length > 0) {
        items = responseData.map((foodItem, index) => {
          const nutrition = foodItem.nutrition || foodItem.nutrition_info || {};
          
          return {
            name: foodItem.name || foodItem.food_name || `Food Item ${index + 1}`,
            calories: Math.round(nutrition.calories || nutrition.cal || 0),
            protein: Math.round((nutrition.protein || 0) * 100) / 100,
            carbs: Math.round((nutrition.carbs || nutrition.carbohydrates || 0) * 100) / 100,
            fat: Math.round((nutrition.fat || 0) * 100) / 100,
            sugar: Math.round((nutrition.sugar || 0) * 100) / 100,
            portionSize: foodItem.portion_size || foodItem.portion || '1 serving',
            confidence: foodItem.confidence || 0.8
          };
        });
        
        console.log(`✅ Parsed ${items.length} food items from LogMeal array response`);
      } else {
        console.error('❌ LogMeal API returned unexpected response format:', JSON.stringify(responseData).substring(0, 500));
        throw new Error('LogMeal API returned unexpected response format');
    }

      // Validate items array
      if (!Array.isArray(items) || items.length === 0) {
        throw new Error('LogMeal analysis returned invalid or empty results');
      }

    // Calculate totals
    const totals = items.reduce((acc, item) => ({
      calories: acc.calories + (item.calories || 0),
      protein: acc.protein + (item.protein || 0),
      carbs: acc.carbs + (item.carbs || 0),
      fat: acc.fat + (item.fat || 0),
      sugar: acc.sugar + (item.sugar || 0)
    }), { calories: 0, protein: 0, carbs: 0, fat: 0, sugar: 0 });

    // Get the API name that was actually used
    const modelName = 'logmeal-api';

    res.json({
      items,
      imageUrl: imageUrl || null, // null if S3 not configured
      imageKey: imageKey || null, // null if S3 not configured
      totalCalories: totals.calories,
      totalProtein: totals.protein,
      totalCarbs: totals.carbs,
      totalFat: totals.fat,
      totalSugar: totals.sugar,
      aiVersion: modelName,
      s3Configured: s3Configured || false
    });
    } catch (logmealError) {
      console.error('❌ LogMeal API error:', logmealError);
      console.error('❌ Error details:', {
        message: logmealError.message,
        status: logmealError.response?.status,
        statusCode: logmealError.response?.status,
        code: logmealError.code,
        responseData: logmealError.response?.data
      });
      
      // Check if it's a timeout
      if (logmealError.message?.includes('timeout') || logmealError.message === 'Request timeout' || logmealError.code === 'ECONNABORTED') {
        return res.status(504).json({ 
          message: 'Food analysis timed out. Please try again with a clearer photo.',
          error: 'Request timeout'
        });
      }
      
      // Check for API key issues
      if (logmealError.message?.includes('API key') || 
          logmealError.message?.includes('API_KEY') ||
          logmealError.response?.status === 401 || 
          logmealError.response?.status === 403) {
        return res.status(401).json({ 
          message: 'Food recognition service authentication failed. Please verify LOGMEAL_API_KEY is correctly set in Render environment variables.',
          error: 'LogMeal API key issue',
          hint: 'Check Render dashboard → Environment → LOGMEAL_API_KEY'
        });
      }
      
      // Check for not found errors
      if (logmealError.message?.includes('not found') || 
          logmealError.response?.status === 404) {
        return res.status(404).json({ 
          message: 'LogMeal API endpoint not found. Please check the API endpoint configuration.',
          error: 'Endpoint not found'
        });
      }
      
      // Check for rate limiting
      if (logmealError.response?.status === 429) {
        return res.status(429).json({ 
          message: 'Food recognition service is currently busy. Please try again in a moment.',
          error: 'Rate limit exceeded'
        });
      }
      
      // Check for bad request
      if (logmealError.response?.status === 400) {
        return res.status(400).json({ 
          message: 'Invalid image format or request. Please try with a different photo.',
          error: 'Bad request',
          details: logmealError.response?.data?.message || logmealError.message
        });
      }
      
      // Generic LogMeal error - return instead of throwing
      return res.status(500).json({ 
        message: `Food recognition error: ${logmealError.message || 'Unknown error'}. Please check backend logs for details.`,
        error: logmealError.message || 'Unknown LogMeal API error',
        hint: 'Check Render logs for detailed error information'
      });
    }
  } catch (error) {
    console.error('Photo analysis error:', error);
    
    // Provide more specific error messages
    let errorMessage = 'Failed to analyze photo';
    let statusCode = 500;
    
    if (error.message?.includes('timeout') || error.message?.includes('timed out')) {
      errorMessage = 'Analysis timed out. Please try again with a clearer photo.';
      statusCode = 504;
    } else if (error.message?.includes('bucket')) {
      errorMessage = 'S3 storage not configured. Photo will be analyzed but not saved.';
      statusCode = 500;
    } else if (error.message?.includes('LogMeal') || error.message?.includes('API key')) {
      errorMessage = 'Food recognition service unavailable. Please check LOGMEAL_API_KEY configuration.';
      statusCode = 503;
    } else if (error.message) {
      errorMessage = error.message;
    }
    
    res.status(statusCode).json({ 
      message: errorMessage, 
      error: error.message || 'Unknown error'
    });
  }
});

export default router;

