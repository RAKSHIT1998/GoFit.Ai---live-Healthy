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

// Initialize OpenAI
const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY
});

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
    if (!process.env.OPENAI_API_KEY) {
      return res.status(500).json({ 
        message: 'AI analysis service is not configured. Please contact support.',
        error: 'OpenAI API key missing'
      });
    }

    // Analyze with OpenAI Vision API (works without S3)
    const base64Image = file.buffer.toString('base64');
    
    // Set timeout for OpenAI API call (60 seconds)
    const timeoutPromise = new Promise((_, reject) => {
      setTimeout(() => reject(new Error('Request timeout')), 60000);
    });
    
    try {
      console.log('🤖 Starting OpenAI analysis for user:', userId);
      const openaiPromise = openai.chat.completions.create({
        model: "gpt-4o", // Updated to latest model
        messages: [
          {
            role: "system",
            content: "You are a nutrition expert. Analyze food images and provide accurate nutritional information including calories, macronutrients, and sugar content."
          },
          {
            role: "user",
            content: [
              {
                type: "text",
                text: `Analyze this food image carefully and identify ALL food items visible. For each food item, provide detailed nutritional information.

Return a JSON array where each item has:
- name: string (specific food name, e.g., "Grilled Chicken Breast" not just "chicken")
- calories: number (estimated calories for the portion shown)
- protein: number (grams of protein)
- carbs: number (grams of carbohydrates)
- fat: number (grams of fat)
- sugar: number (grams of sugar - IMPORTANT: include this field)
- portionSize: string (estimated portion, e.g., "200g", "1 cup", "1 medium piece")
- confidence: number (0-1, how confident you are in the identification)

Be specific and accurate. If you see multiple items (e.g., rice, chicken, vegetables), list each separately.
Estimate portion sizes based on common serving sizes and what's visible in the image.
Include sugar content for all items (even if 0 for items like plain chicken).

Return ONLY valid JSON array, no markdown, no explanations, just the JSON.`
              },
              {
                type: "image_url",
                image_url: {
                  url: `data:${file.mimetype};base64,${base64Image}`
                }
              }
            ]
          }
        ],
        max_tokens: 3000, // Increased for more detailed nutritional analysis
        temperature: 0.3 // Lower temperature for more consistent, accurate results
      });
      
      // Race between OpenAI call and timeout
      const response = await Promise.race([openaiPromise, timeoutPromise]);
      
      console.log('✅ OpenAI analysis completed');
      
      // Continue with response processing
      const content = response.choices[0].message.content;
      let items = [];
      
      try {
        // Try to parse JSON from response
        const jsonMatch = content.match(/\[[\s\S]*\]/);
        if (jsonMatch) {
          items = JSON.parse(jsonMatch[0]);
        } else {
          items = JSON.parse(content);
        }
      } catch (parseError) {
        console.error('Failed to parse AI response:', parseError);
        console.error('AI Response content:', content);
        // Fallback: create a basic item
        items = [{
          name: "Food item",
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
        throw new Error('AI analysis returned invalid or empty results');
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
        aiVersion: "gpt-4o",
        s3Configured: s3Configured || false
      });
    } catch (openaiError) {
      console.error('❌ OpenAI API error:', openaiError);
      
      // Check if it's a timeout
      if (openaiError.message?.includes('timeout') || openaiError.message === 'Request timeout') {
        return res.status(504).json({ 
          message: 'AI analysis timed out. Please try again with a clearer photo.',
          error: 'Request timeout'
        });
      }
      
      // Check for API key issues
      if (openaiError.message?.includes('API key') || openaiError.status === 401 || openaiError.statusCode === 401) {
        return res.status(500).json({ 
          message: 'AI service authentication failed. Please check server configuration.',
          error: 'OpenAI API key issue'
        });
      }
      
      // Check for rate limiting
      if (openaiError.status === 429 || openaiError.statusCode === 429) {
        return res.status(503).json({ 
          message: 'AI service is currently busy. Please try again in a moment.',
          error: 'Rate limit exceeded'
        });
      }
      
      throw openaiError; // Re-throw to outer catch
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
      errorMessage = 'AI analysis service unavailable. Please check OpenAI API configuration.';
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

