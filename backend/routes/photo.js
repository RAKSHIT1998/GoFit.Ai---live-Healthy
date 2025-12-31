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
const GEMINI_API_KEY = process.env.GEMINI_API_KEY || '';
const genAI = GEMINI_API_KEY ? new GoogleGenerativeAI(GEMINI_API_KEY) : null;

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
    if (!genAI || !GEMINI_API_KEY) {
      return res.status(500).json({ 
        message: 'Food recognition service is not configured. Please set GEMINI_API_KEY environment variable. Get your free API key at https://aistudio.google.com/app/apikey',
        error: 'Gemini API key missing'
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
      
      // Use Gemini Pro for image analysis (supports multimodal including images)
      const model = genAI.getGenerativeModel({ model: 'gemini-pro' });
      
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

      const geminiPromise = model.generateContent([
        prompt,
        {
          inlineData: {
            data: base64Image,
            mimeType: file.mimetype || 'image/jpeg'
          }
        }
      ]);
      
      // Race between Gemini call and timeout
      const result = await Promise.race([geminiPromise, timeoutPromise]);
      const response = await result.response;
      const content = response.text();
      
      console.log('✅ Google Gemini analysis completed');
      
      // Parse JSON from response
    let items = [];
    
    try {
        // Try to extract JSON array from response
      const jsonMatch = content.match(/\[[\s\S]*\]/);
      if (jsonMatch) {
        items = JSON.parse(jsonMatch[0]);
      } else {
          // Try parsing the entire content
        items = JSON.parse(content);
      }
    } catch (parseError) {
        console.error('Failed to parse Gemini response:', parseError);
        console.error('Gemini Response content:', content);
      // Fallback: create a basic item
      items = [{
          name: "Food/Drink item",
        calories: 200,
        protein: 10,
        carbs: 30,
        fat: 5,
        sugar: 5,
        portionSize: "1 serving",
        confidence: 0.5
      }];
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

    res.json({
      items,
      imageUrl: imageUrl || null, // null if S3 not configured
      imageKey: imageKey || null, // null if S3 not configured
      totalCalories: totals.calories,
      totalProtein: totals.protein,
      totalCarbs: totals.carbs,
      totalFat: totals.fat,
      totalSugar: totals.sugar,
        aiVersion: "gemini-pro",
      s3Configured: s3Configured || false
    });
    } catch (geminiError) {
      console.error('❌ Google Gemini API error:', geminiError);
      
      // Check if it's a timeout
      if (geminiError.message?.includes('timeout') || geminiError.message === 'Request timeout') {
        return res.status(504).json({ 
          message: 'Food analysis timed out. Please try again with a clearer photo.',
          error: 'Request timeout'
        });
      }
      
      // Check for API key issues
      if (geminiError.message?.includes('API key') || geminiError.status === 401 || geminiError.statusCode === 401) {
        return res.status(500).json({ 
          message: 'Food recognition service authentication failed. Please check GEMINI_API_KEY configuration.',
          error: 'Gemini API key issue'
        });
      }
      
      // Check for rate limiting
      if (geminiError.status === 429 || geminiError.statusCode === 429) {
        return res.status(503).json({ 
          message: 'Food recognition service is currently busy. Please try again in a moment.',
          error: 'Rate limit exceeded'
        });
      }
      
      throw geminiError; // Re-throw to outer catch
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

