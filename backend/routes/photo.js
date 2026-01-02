import express from 'express';
import multer from 'multer';
import AWS from 'aws-sdk';
import OpenAI from 'openai';
import { authMiddleware } from '../middleware/authMiddleware.js';
import { Queue } from 'bullmq';
import { getRedis, isRedisEnabled } from '../config/redis.js';

const router = express.Router();

// Configure multer for memory storage
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024 } // 10MB
});

// Initialize OpenAI API for GPT-4o Vision
// Get your API key at: https://platform.openai.com/api-keys
const OPENAI_API_KEY = (process.env.OPENAI_API_KEY || '').trim();
const openai = OPENAI_API_KEY ? new OpenAI({ apiKey: OPENAI_API_KEY }) : null;

// Log OpenAI status on module load
if (OPENAI_API_KEY) {
  console.log(`✅ OPENAI_API_KEY loaded (length: ${OPENAI_API_KEY.length}, starts with: ${OPENAI_API_KEY.substring(0, 10)}...)`);
} else {
  console.error('❌ OPENAI_API_KEY is missing or empty. Food recognition will not work.');
  console.error('   Set OPENAI_API_KEY in Render environment variables: https://platform.openai.com/api-keys');
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

    // Check if OpenAI API key is configured
    if (!OPENAI_API_KEY || OPENAI_API_KEY.length === 0) {
      console.error('❌ OPENAI_API_KEY is not set or empty');
      console.error('   Environment check:', {
        hasEnvVar: !!process.env.OPENAI_API_KEY,
        envVarLength: process.env.OPENAI_API_KEY?.length || 0,
        trimmedLength: OPENAI_API_KEY.length
      });
      return res.status(500).json({ 
        message: 'Food recognition service is not configured. Please set OPENAI_API_KEY environment variable in Render. Get your API key at https://platform.openai.com/api-keys',
        error: 'OpenAI API key missing',
        hint: 'Go to Render Dashboard → Your Service → Environment → Add OPENAI_API_KEY'
      });
    }
    
    if (!openai) {
      console.error('❌ Failed to initialize OpenAI');
      return res.status(500).json({ 
        message: 'Food recognition service initialization failed. Please check OPENAI_API_KEY configuration.',
        error: 'OpenAI initialization failed'
      });
    }

    // Analyze with OpenAI GPT-4o Vision
    try {
      console.log('🤖 Starting OpenAI GPT-4o Vision analysis for user:', userId);
      console.log('📝 OPENAI_API_KEY status:', OPENAI_API_KEY ? `Set (${OPENAI_API_KEY.substring(0, 10)}...)` : 'NOT SET');
      
      // Convert image to base64
      const base64Image = file.buffer.toString('base64');
      
      // Set timeout for OpenAI API call (45 seconds)
      const timeoutPromise = new Promise((_, reject) => {
        setTimeout(() => reject(new Error('Request timeout')), 45000);
      });
      
      const prompt = `You are a nutrition expert analyzing food and drink images. Identify ALL items visible and provide accurate nutritional information.

CRITICAL NAMING RULES:
- Use proper, recognizable dish names when identifying complete dishes (e.g., "Chicken Biryani", "Caesar Salad", "Margherita Pizza", "Pad Thai", "Burger with Fries")
- For individual ingredients in a mixed dish, use descriptive names (e.g., "Grilled Chicken Breast", "Steamed Rice", "Mixed Vegetables")
- For beverages, use brand names when visible (e.g., "Coca Cola", "Pepsi", "Starbucks Coffee") or generic names (e.g., "Orange Juice", "Red Wine", "Green Tea")
- Use common, well-known food names that users would recognize
- If you see a complete dish, name it as the dish (e.g., "Spaghetti Carbonara" not "pasta, eggs, bacon")
- Capitalize food names properly (e.g., "Chicken Tikka Masala" not "chicken tikka masala")

Return a JSON array where each item has:
- name: string (proper dish/food name - use recognizable names like "Chicken Curry", "Caesar Salad", "Orange Juice", "Coca Cola")
- calories: number (estimated calories for the portion shown)
- protein: number (grams of protein)
- carbs: number (grams of carbohydrates)
- fat: number (grams of fat)
- sugar: number (grams of sugar - IMPORTANT: include this field, especially for drinks)
- portionSize: string (estimated portion, e.g., "200g", "1 cup", "250ml", "1 can", "1 serving")
- confidence: number (0-1, how confident you are in the identification)

IMPORTANT:
- If this is a drink/beverage, include calories and sugar content
- For complete dishes, use the dish name rather than listing ingredients separately
- If multiple separate items are visible, list each with its proper name
- Estimate portion sizes based on common serving sizes and what's visible in the image
- Include sugar content for all items (even if 0 for items like plain chicken or water)
- Use proper capitalization and spelling for all food names

Return ONLY valid JSON array, no markdown, no code blocks, no explanations, just the raw JSON array. Example format:
[{"name": "Chicken Biryani", "calories": 450, "protein": 25, "carbs": 55, "fat": 12, "sugar": 2, "portionSize": "1 serving", "confidence": 0.9}]`;

      // Call OpenAI GPT-4o Vision API
      const openaiPromise = openai.chat.completions.create({
        model: 'gpt-4o',
        messages: [
          {
            role: 'user',
            content: [
              {
                type: 'text',
                text: prompt
              },
              {
                type: 'image_url',
                image_url: {
                  url: `data:${file.mimetype || 'image/jpeg'};base64,${base64Image}`
                }
              }
            ]
          }
        ],
        max_tokens: 2000,
        temperature: 0.3 // Lower temperature for more accurate nutrition data
      });
      
      // Race between OpenAI call and timeout
      const completion = await Promise.race([openaiPromise, timeoutPromise]);
      
      const content = completion.choices[0]?.message?.content || '';
      
      console.log('✅ OpenAI GPT-4o Vision analysis completed');
      console.log('📝 Response length:', content.length, 'characters');
      
      // Parse JSON from response
      let items = [];
      
      try {
        // Try to extract JSON array from response (handle markdown code blocks)
        let jsonString = content.trim();
        
        // Remove markdown code blocks if present
        jsonString = jsonString.replace(/^```json\s*/i, '').replace(/^```\s*/i, '').replace(/\s*```$/i, '');
        
        // Try to find JSON array in the response
        const jsonMatch = jsonString.match(/\[[\s\S]*\]/);
        if (jsonMatch) {
          items = JSON.parse(jsonMatch[0]);
        } else {
          // Try parsing the entire content
          items = JSON.parse(jsonString);
        }
        
        console.log(`✅ Parsed ${items.length} food items from OpenAI response`);
      } catch (parseError) {
        console.error('❌ Failed to parse OpenAI response:', parseError);
        console.error('📝 OpenAI Response content (first 500 chars):', content.substring(0, 500));
        console.error('📝 Full response length:', content.length);
        
        // Try to extract any useful information from the response
        const jsonMatch = content.match(/\[[\s\S]*\]/);
        if (jsonMatch) {
          try {
            items = JSON.parse(jsonMatch[0]);
            console.log('✅ Successfully parsed JSON after retry');
          } catch (retryError) {
            console.error('❌ Retry parse also failed:', retryError);
            throw new Error(`Failed to parse OpenAI response: ${parseError.message}. Response preview: ${content.substring(0, 200)}`);
          }
        } else {
          throw new Error(`Failed to parse OpenAI response: ${parseError.message}. No JSON array found in response.`);
        }
      }

      // Validate items array
      if (!Array.isArray(items) || items.length === 0) {
        throw new Error('OpenAI analysis returned invalid or empty results');
      }

    // Calculate totals
    const totals = items.reduce((acc, item) => ({
      calories: acc.calories + (item.calories || 0),
      protein: acc.protein + (item.protein || 0),
      carbs: acc.carbs + (item.carbs || 0),
      fat: acc.fat + (item.fat || 0),
      sugar: acc.sugar + (item.sugar || 0)
    }), { calories: 0, protein: 0, carbs: 0, fat: 0, sugar: 0 });

    // Get the model name that was actually used
    const modelName = 'gpt-4o-vision';

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
    } catch (openaiError) {
      console.error('❌ OpenAI GPT-4o Vision API error:', openaiError);
      console.error('❌ Error details:', {
        message: openaiError.message,
        status: openaiError.status,
        statusCode: openaiError.status,
        code: openaiError.code,
        type: openaiError.type
      });
      
      // Check if it's a timeout
      if (openaiError.message?.includes('timeout') || openaiError.message === 'Request timeout') {
        return res.status(504).json({ 
          message: 'Food analysis timed out. Please try again with a clearer photo.',
          error: 'Request timeout'
        });
      }
      
      // Check for API key issues
      if (openaiError.message?.includes('API key') || 
          openaiError.message?.includes('API_KEY') ||
          openaiError.status === 401 ||
          openaiError.code === 'invalid_api_key') {
        return res.status(401).json({ 
          message: 'Food recognition service authentication failed. Please verify OPENAI_API_KEY is correctly set in Render environment variables.',
          error: 'OpenAI API key issue',
          hint: 'Check Render dashboard → Environment → OPENAI_API_KEY'
        });
      }
      
      // Check for model not found errors
      if (openaiError.message?.includes('model') && openaiError.message?.includes('not found') || 
          openaiError.status === 404 ||
          openaiError.code === 'model_not_found') {
        return res.status(404).json({ 
          message: 'OpenAI model not available. Please check the model name or API access.',
          error: 'Model not found'
        });
      }
      
      // Check for rate limiting
      if (openaiError.status === 429 || openaiError.code === 'rate_limit_exceeded') {
        return res.status(429).json({ 
          message: 'Food recognition service is currently busy. Please try again in a moment.',
          error: 'Rate limit exceeded'
        });
      }
      
      // Check for bad request
      if (openaiError.status === 400 || openaiError.code === 'invalid_request_error') {
        return res.status(400).json({ 
          message: 'Invalid image format or request. Please try with a different photo.',
          error: 'Bad request',
          details: openaiError.message
        });
      }
      
      // Generic OpenAI error - return instead of throwing
      return res.status(500).json({ 
        message: `Food recognition error: ${openaiError.message || 'Unknown error'}. Please check backend logs for details.`,
        error: openaiError.message || 'Unknown OpenAI API error',
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
    } else if (error.message?.includes('OpenAI') || error.message?.includes('API key')) {
      errorMessage = 'Food recognition service unavailable. Please check OPENAI_API_KEY configuration.';
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


