import express from 'express';
import multer from 'multer';
import { authMiddleware } from '../middleware/authMiddleware.js';
import axios from 'axios';
import FormData from 'form-data';

const router = express.Router();

// Configure multer for memory storage
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024 } // 10MB
});

// Edamam Food Recognition API (Free tier: 10,000 requests/month)
// Get your free API keys at: https://developer.edamam.com/
const EDAMAM_APP_ID = process.env.EDAMAM_APP_ID || '';
const EDAMAM_APP_KEY = process.env.EDAMAM_APP_KEY || '';

// Upload and analyze photo using Edamam API
router.post('/analyze', authMiddleware, upload.single('photo'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ message: 'No photo provided' });
    }

    // Check if Edamam is configured
    if (!EDAMAM_APP_ID || !EDAMAM_APP_KEY) {
      return res.status(500).json({ 
        message: 'Food recognition service is not configured. Please set EDAMAM_APP_ID and EDAMAM_APP_KEY environment variables.',
        error: 'Edamam API not configured'
      });
    }

    const userId = req.user._id.toString();
    const file = req.file;
    
    console.log('🍎 Starting Edamam food recognition for user:', userId);

    // Prepare form data for Edamam API
    const formData = new FormData();
    formData.append('image', file.buffer, {
      filename: file.originalname || 'food.jpg',
      contentType: file.mimetype
    });

    // Call Edamam Food Recognition API
    const timeoutPromise = new Promise((_, reject) => {
      setTimeout(() => reject(new Error('Request timeout')), 30000); // 30 second timeout
    });

    try {
      const edamamPromise = axios.post('https://api.edamam.com/api/food-database/v2/parser', formData, {
        headers: {
          ...formData.getHeaders(),
          'app_id': EDAMAM_APP_ID,
          'app_key': EDAMAM_APP_KEY
        },
        timeout: 30000
      });

      const response = await Promise.race([edamamPromise, timeoutPromise]);
      
      console.log('✅ Edamam analysis completed');

      // Parse Edamam response
      const edamamData = response.data;
      let items = [];

      if (edamamData.hints && edamamData.hints.length > 0) {
        items = edamamData.hints.map(hint => {
          const food = hint.food;
          const nutrients = food.nutrients || {};
          
          // Calculate portion-based nutrition (Edamam returns per 100g)
          const portionWeight = hint.measures && hint.measures[0] ? 
            (hint.measures[0].weight || 100) : 100;
          const multiplier = portionWeight / 100;

          return {
            name: food.label || 'Food item',
            calories: Math.round((nutrients.ENERC_KCAL || 0) * multiplier),
            protein: Math.round((nutrients.PROCNT || 0) * multiplier * 10) / 10,
            carbs: Math.round((nutrients.CHOCDF || 0) * multiplier * 10) / 10,
            fat: Math.round((nutrients.FAT || 0) * multiplier * 10) / 10,
            sugar: Math.round((nutrients.SUGAR || 0) * multiplier * 10) / 10,
            portionSize: `${Math.round(portionWeight)}g`,
            confidence: hint.measures && hint.measures[0] ? 0.8 : 0.6
          };
        });
      }

      // If no items found, try alternative approach
      if (items.length === 0 && edamamData.text) {
        // Edamam sometimes returns text description
        items = [{
          name: edamamData.text || 'Food item',
          calories: 200,
          protein: 10,
          carbs: 30,
          fat: 5,
          sugar: 5,
          portionSize: '1 serving',
          confidence: 0.5
        }];
      }

      // Validate items array
      if (!Array.isArray(items) || items.length === 0) {
        throw new Error('Food recognition returned no results. Please try a clearer photo.');
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
        imageUrl: null, // Edamam doesn't store images
        imageKey: null,
        totalCalories: totals.calories,
        totalProtein: totals.protein,
        totalCarbs: totals.carbs,
        totalFat: totals.fat,
        totalSugar: totals.sugar,
        aiVersion: 'edamam-v2',
        s3Configured: false
      });
    } catch (edamamError) {
      console.error('❌ Edamam API error:', edamamError);
      
      // Check if it's a timeout
      if (edamamError.message?.includes('timeout') || edamamError.message === 'Request timeout') {
        return res.status(504).json({ 
          message: 'Food recognition timed out. Please try again with a clearer photo.',
          error: 'Request timeout'
        });
      }
      
      // Check for API key issues
      if (edamamError.response?.status === 401 || edamamError.response?.status === 403) {
        return res.status(500).json({ 
          message: 'Food recognition service authentication failed. Please check server configuration.',
          error: 'Edamam API key issue'
        });
      }
      
      // Check for rate limiting
      if (edamamError.response?.status === 429) {
        return res.status(503).json({ 
          message: 'Food recognition service is currently busy. Please try again in a moment.',
          error: 'Rate limit exceeded'
        });
      }
      
      throw edamamError;
    }
  } catch (error) {
    console.error('Photo analysis error:', error);
    
    let errorMessage = 'Failed to analyze photo';
    let statusCode = 500;
    
    if (error.message?.includes('timeout') || error.message?.includes('timed out')) {
      errorMessage = 'Analysis timed out. Please try again with a clearer photo.';
      statusCode = 504;
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

