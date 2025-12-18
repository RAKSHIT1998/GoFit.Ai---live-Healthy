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
    const filename = `meals/${userId}/${Date.now()}-${file.originalname}`;

    // Upload to S3
    const uploadParams = {
      Bucket: process.env.S3_BUCKET_NAME,
      Key: filename,
      Body: file.buffer,
      ContentType: file.mimetype,
      ACL: 'private'
    };

    await s3.putObject(uploadParams).promise();
    const imageUrl = `https://${process.env.S3_BUCKET_NAME}.s3.${process.env.AWS_REGION}.amazonaws.com/${filename}`;

    // Analyze with OpenAI Vision API
    const base64Image = file.buffer.toString('base64');
    
    const response = await openai.chat.completions.create({
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
      imageUrl,
      imageKey: filename,
      totalCalories: totals.calories,
      totalProtein: totals.protein,
      totalCarbs: totals.carbs,
      totalFat: totals.fat,
      totalSugar: totals.sugar,
      aiVersion: "gpt-4o"
    });
  } catch (error) {
    console.error('Photo analysis error:', error);
    res.status(500).json({ message: 'Failed to analyze photo', error: error.message });
  }
});

export default router;

