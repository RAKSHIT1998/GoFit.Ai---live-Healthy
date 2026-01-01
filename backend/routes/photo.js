import express from 'express';
import multer from 'multer';
import AWS from 'aws-sdk';
import { GoogleGenerativeAI } from '@google/generative-ai';
import { authMiddleware } from '../middleware/authMiddleware.js';
import { Queue } from 'bullmq';
import { getRedis, isRedisEnabled } from '../config/redis.js';

const router = express.Router();

// Configure multer for memory storage
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024 } // 10MB
});

// Initialize Google Gemini AI
// Get your free API key at: https://aistudio.google.com/app/apikey
const GEMINI_API_KEY = (process.env.GEMINI_API_KEY || '').trim();
const genAI = GEMINI_API_KEY ? new GoogleGenerativeAI(GEMINI_API_KEY) : null;

// Log Gemini status on module load
if (GEMINI_API_KEY) {
  console.log(`✅ GEMINI_API_KEY loaded (length: ${GEMINI_API_KEY.length}, starts with: ${GEMINI_API_KEY.substring(0, 10)}...)`);
} else {
  console.error('❌ GEMINI_API_KEY is missing or empty. Food recognition will not work.');
  console.error('   Set GEMINI_API_KEY in Render environment variables: https://aistudio.google.com/app/apikey');
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

    // Check if Google Gemini API key is configured
    if (!GEMINI_API_KEY || GEMINI_API_KEY.length === 0) {
      console.error('❌ GEMINI_API_KEY is not set or empty');
      console.error('   Environment check:', {
        hasEnvVar: !!process.env.GEMINI_API_KEY,
        envVarLength: process.env.GEMINI_API_KEY?.length || 0,
        trimmedLength: GEMINI_API_KEY.length
      });
      return res.status(500).json({ 
        message: 'Food recognition service is not configured. Please set GEMINI_API_KEY environment variable in Render. Get your free API key at https://aistudio.google.com/app/apikey',
        error: 'Gemini API key missing',
        hint: 'Go to Render Dashboard → Your Service → Environment → Add GEMINI_API_KEY'
      });
    }
    
    if (!genAI) {
      console.error('❌ Failed to initialize GoogleGenerativeAI');
      return res.status(500).json({ 
        message: 'Food recognition service initialization failed. Please check GEMINI_API_KEY configuration.',
        error: 'Gemini initialization failed'
      });
    }

    // Analyze with Google Gemini Vision API
    const base64Image = file.buffer.toString('base64');
    
    // Set timeout for Gemini API call (45 seconds - Gemini is typically faster)
    const timeoutPromise = new Promise((_, reject) => {
      setTimeout(() => reject(new Error('Request timeout')), 45000);
    });
    
    try {
      console.log('🤖 Starting Google Gemini analysis for user:', userId);
      console.log('📝 GEMINI_API_KEY status:', GEMINI_API_KEY ? `Set (${GEMINI_API_KEY.substring(0, 10)}...)` : 'NOT SET');
      
      // Use Gemini 1.5 Flash for image analysis (fast and supports vision)
      // Note: gemini-pro doesn't support images, must use gemini-1.5-pro or gemini-1.5-flash
      let model;
      const modelPreference = process.env.GEMINI_MODEL || 'gemini-1.5-flash'; // Default to flash for speed
      
      try {
        // Try preferred model first
        model = genAI.getGenerativeModel({ model: modelPreference });
        console.log(`✅ Using model: ${modelPreference}`);
      } catch (modelError) {
        console.error(`❌ Failed to initialize ${modelPreference}, trying alternatives:`, modelError.message);
        // Try alternative models if preferred fails
        const fallbackModels = ['gemini-1.5-pro', 'gemini-1.5-flash', 'gemini-pro-vision'];
        let modelInitialized = false;
        
        for (const fallbackModel of fallbackModels) {
          if (fallbackModel === modelPreference) continue; // Skip if already tried
          
          try {
            model = genAI.getGenerativeModel({ model: fallbackModel });
            console.log(`✅ Using fallback model: ${fallbackModel}`);
            modelInitialized = true;
            break;
          } catch (e) {
            console.error(`❌ Failed to initialize ${fallbackModel}:`, e.message);
          }
        }
        
        if (!modelInitialized) {
          throw new Error(`Failed to initialize any Gemini model. Last error: ${modelError.message}. Please check your GEMINI_API_KEY and model availability.`);
        }
      }
      
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

Return ONLY valid JSON array, no markdown, no explanations, no code blocks, just the raw JSON array. Example format:
[{"name": "Chicken Biryani", "calories": 450, "protein": 25, "carbs": 55, "fat": 12, "sugar": 2, "portionSize": "1 serving", "confidence": 0.9}]`;

      // Generate content with image
      const geminiPromise = (async () => {
        try {
          const result = await model.generateContent([
            prompt,
            {
              inlineData: {
                data: base64Image,
                mimeType: file.mimetype || 'image/jpeg'
              }
            }
          ]);
          return result.response;
        } catch (error) {
          console.error('❌ Gemini API call error:', error);
          throw error;
        }
      })();
      
      // Race between Gemini call and timeout
      const response = await Promise.race([geminiPromise, timeoutPromise]);
      const content = response.text();
      
      console.log('✅ Google Gemini analysis completed');
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
        
        console.log(`✅ Parsed ${items.length} food items from Gemini response`);
      } catch (parseError) {
        console.error('❌ Failed to parse Gemini response:', parseError);
        console.error('📝 Gemini Response content (first 500 chars):', content.substring(0, 500));
        console.error('📝 Full response length:', content.length);
        
        // Try to extract any useful information from the response
        // Sometimes Gemini returns text before/after the JSON
        const jsonMatch = content.match(/\[[\s\S]*\]/);
        if (jsonMatch) {
          try {
            items = JSON.parse(jsonMatch[0]);
            console.log('✅ Successfully parsed JSON after retry');
          } catch (retryError) {
            console.error('❌ Retry parse also failed:', retryError);
            throw new Error(`Failed to parse Gemini response: ${parseError.message}. Response preview: ${content.substring(0, 200)}`);
          }
        } else {
          throw new Error(`Failed to parse Gemini response: ${parseError.message}. No JSON array found in response.`);
        }
      }

      // Validate items array
      if (!Array.isArray(items) || items.length === 0) {
        throw new Error('Gemini analysis returned invalid or empty results');
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
    const modelName = process.env.GEMINI_MODEL || 'gemini-1.5-flash';
    
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
    } catch (geminiError) {
      console.error('❌ Google Gemini API error:', geminiError);
      console.error('❌ Error details:', {
        message: geminiError.message,
        status: geminiError.status,
        statusCode: geminiError.statusCode,
        code: geminiError.code
      });
      
      // Check if it's a timeout
      if (geminiError.message?.includes('timeout') || geminiError.message === 'Request timeout') {
        return res.status(504).json({ 
          message: 'Food analysis timed out. Please try again with a clearer photo.',
          error: 'Request timeout'
        });
      }
      
      // Check for API key issues
      if (geminiError.message?.includes('API key') || 
          geminiError.message?.includes('API_KEY') ||
          geminiError.status === 401 || 
          geminiError.statusCode === 401 ||
          geminiError.code === 401) {
        return res.status(500).json({ 
          message: 'Food recognition service authentication failed. Please verify GEMINI_API_KEY is correctly set in Render environment variables.',
          error: 'Gemini API key issue',
          hint: 'Check Render dashboard → Environment → GEMINI_API_KEY'
        });
      }
      
      // Check for model not found errors
      if (geminiError.message?.includes('not found') || 
          geminiError.message?.includes('404') ||
          geminiError.status === 404 ||
          geminiError.statusCode === 404) {
        return res.status(500).json({ 
          message: 'Gemini model not available. Please check the model name or API access.',
          error: 'Model not found',
          hint: 'The model might not be available for your API key. Check Google AI Studio for available models.'
        });
      }
      
      // Check for rate limiting
      if (geminiError.status === 429 || geminiError.statusCode === 429) {
        return res.status(503).json({ 
          message: 'Food recognition service is currently busy. Please try again in a moment.',
          error: 'Rate limit exceeded'
        });
      }
      
      // Generic Gemini error - return instead of throwing
      return res.status(500).json({ 
        message: `Food recognition error: ${geminiError.message || 'Unknown error'}. Please check backend logs for details.`,
        error: geminiError.message || 'Unknown Gemini API error',
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
    } else if (error.message?.includes('Gemini') || error.message?.includes('API key')) {
      errorMessage = 'Food recognition service unavailable. Please check GEMINI_API_KEY configuration.';
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

