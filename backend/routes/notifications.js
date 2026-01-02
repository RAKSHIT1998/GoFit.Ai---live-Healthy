import express from 'express';
import OpenAI from 'openai';
import User from '../models/User.js';
import Meal from '../models/Meal.js';
import WaterLog from '../models/WaterLog.js';
import { authMiddleware } from '../middleware/authMiddleware.js';
import mlService from '../services/mlService.js';

const router = express.Router();

// Initialize OpenAI API
const OPENAI_API_KEY = (process.env.OPENAI_API_KEY || '').trim();
const openai = OPENAI_API_KEY ? new OpenAI({ apiKey: OPENAI_API_KEY }) : null;

// Get user context for AI recommendations
async function getUserContext(userId) {
  const user = await User.findById(userId);
  if (!user) return null;
  
  // Get ML insights
  const mlInsights = await mlService.getMLInsights(userId);
  
  // Get today's meals
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const todayMeals = await Meal.find({
    userId: userId,
    timestamp: { $gte: today }
  }).sort({ timestamp: -1 });
  
  // Get today's water intake
  const todayWater = await WaterLog.find({
    userId: userId,
    timestamp: { $gte: today }
  });
  const totalWater = todayWater.reduce((sum, log) => sum + log.amount, 0);
  
  // Get recent meals for pattern analysis
  const recentMeals = await Meal.find({
    userId: userId
  }).sort({ timestamp: -1 }).limit(10);
  
  return {
    user: {
      name: user.name,
      goals: user.goals,
      activityLevel: user.activityLevel,
      dietaryPreferences: user.dietaryPreferences || [],
      allergies: user.allergies || [],
      targetCalories: user.metrics?.targetCalories || 2000,
      targetProtein: user.metrics?.targetProtein || 150,
      targetCarbs: user.metrics?.targetCarbs || 200,
      targetFat: user.metrics?.targetFat || 65,
      weightKg: user.metrics?.weightKg || 70,
      heightCm: user.metrics?.heightCm || 170,
      workoutPreferences: user.onboardingData?.workoutPreferences || [],
      favoriteCuisines: user.onboardingData?.favoriteCuisines || [],
      mealTimingPreference: user.onboardingData?.mealTimingPreference || 'regular',
      drinkingFrequency: user.onboardingData?.drinkingFrequency || 'never',
      smokingStatus: user.onboardingData?.smokingStatus || 'never'
    },
    today: {
      meals: todayMeals.length,
      calories: todayMeals.reduce((sum, meal) => sum + (meal.totalCalories || 0), 0),
      protein: todayMeals.reduce((sum, meal) => sum + (meal.totalProtein || 0), 0),
      carbs: todayMeals.reduce((sum, meal) => sum + (meal.totalCarbs || 0), 0),
      water: totalWater
    },
    mlInsights: mlInsights || {},
    recentMeals: recentMeals.map(m => ({
      items: m.items.map(i => i.name),
      calories: m.totalCalories,
      timestamp: m.timestamp
    }))
  };
}

// Generate AI meal reminder
router.post('/meal-reminder', authMiddleware, async (req, res) => {
  try {
    const { mealType } = req.body;
    
    if (!openai) {
      return res.status(500).json({
        title: "Time to eat! 🍽️",
        body: `Don't forget your ${mealType}. Your body needs fuel to stay healthy!`
      });
    }
    
    const context = await getUserContext(req.user._id);
    if (!context) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    const prompt = `You are a friendly, encouraging health coach. Generate a personalized meal reminder notification for ${context.user.name}.

USER PROFILE:
- Goals: ${context.user.goals}
- Activity Level: ${context.user.activityLevel}
- Dietary Preferences: ${context.user.dietaryPreferences.join(', ') || 'None'}
- Allergies: ${context.user.allergies.join(', ') || 'None'}
- Target Calories: ${context.user.targetCalories} kcal/day
- Favorite Cuisines: ${context.user.favoriteCuisines.join(', ') || 'Varied'}

TODAY'S PROGRESS:
- Meals logged: ${context.today.meals}
- Calories consumed: ${context.today.calories} / ${context.user.targetCalories} kcal
- Protein: ${context.today.protein}g / ${context.user.targetProtein}g
- Carbs: ${context.today.carbs}g / ${context.user.targetCarbs}g
- Water: ${context.today.water.toFixed(1)}L

MEAL TYPE: ${mealType}

Generate a short, encouraging notification (max 100 characters for body) that:
1. Reminds them it's time for ${mealType}
2. Is personalized based on their goals and preferences
3. Mentions their progress if relevant
4. Is friendly and motivating
5. May suggest a specific food from their favorite cuisines if appropriate

Return ONLY a JSON object with "title" (max 50 chars) and "body" (max 100 chars) fields. No markdown, no explanations.`;

    const completion = await openai.chat.completions.create({
      model: 'gpt-4o',
      messages: [
        {
          role: 'system',
          content: 'You are a friendly health coach. Return ONLY valid JSON with "title" and "body" fields. No markdown, no explanations.'
        },
        {
          role: 'user',
          content: prompt
        }
      ],
      max_tokens: 200,
      temperature: 0.7
    });
    
    const content = completion.choices[0]?.message?.content || '';
    let jsonContent;
    
    try {
      // Remove markdown if present
      let jsonString = content.trim().replace(/^```json\s*/i, '').replace(/^```\s*/i, '').replace(/\s*```$/i, '');
      jsonContent = JSON.parse(jsonString);
    } catch (parseError) {
      // Fallback
      jsonContent = {
        title: "Time to eat! 🍽️",
        body: `Don't forget your ${mealType}. Your body needs fuel to stay healthy!`
      };
    }
    
    res.json({
      title: jsonContent.title || `Time for ${mealType}! 🍽️`,
      body: jsonContent.body || `Don't forget your ${mealType}. Your body needs fuel!`
    });
  } catch (error) {
    console.error('Error generating meal reminder:', error);
    res.json({
      title: "Time to eat! 🍽️",
      body: `Don't forget your ${req.body.mealType || 'meal'}. Your body needs fuel!`
    });
  }
});

// Generate AI water reminder
router.post('/water-reminder', authMiddleware, async (req, res) => {
  try {
    if (!openai) {
      return res.status(500).json({
        title: "Stay Hydrated! 💧",
        body: "Time to drink water! Staying hydrated helps your body function at its best."
      });
    }
    
    const context = await getUserContext(req.user._id);
    if (!context) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    const prompt = `You are a friendly, encouraging health coach. Generate a personalized water reminder notification for ${context.user.name}.

USER PROFILE:
- Goals: ${context.user.goals}
- Activity Level: ${context.user.activityLevel}
- Weight: ${context.user.weightKg} kg

TODAY'S PROGRESS:
- Water consumed: ${context.today.water.toFixed(1)}L
- Target: ~${(context.user.weightKg * 0.035).toFixed(1)}L (based on weight)
- Meals logged: ${context.today.meals}
- Calories: ${context.today.calories} / ${context.user.targetCalories} kcal

Generate a short, encouraging notification (max 100 characters for body) that:
1. Reminds them to drink water
2. Mentions their progress if they're behind
3. Is friendly and motivating
4. May mention benefits of hydration

Return ONLY a JSON object with "title" (max 50 chars) and "body" (max 100 chars) fields. No markdown, no explanations.`;

    const completion = await openai.chat.completions.create({
      model: 'gpt-4o',
      messages: [
        {
          role: 'system',
          content: 'You are a friendly health coach. Return ONLY valid JSON with "title" and "body" fields. No markdown, no explanations.'
        },
        {
          role: 'user',
          content: prompt
        }
      ],
      max_tokens: 200,
      temperature: 0.7
    });
    
    const content = completion.choices[0]?.message?.content || '';
    let jsonContent;
    
    try {
      let jsonString = content.trim().replace(/^```json\s*/i, '').replace(/^```\s*/i, '').replace(/\s*```$/i, '');
      jsonContent = JSON.parse(jsonString);
    } catch (parseError) {
      jsonContent = {
        title: "Stay Hydrated! 💧",
        body: "Time to drink water! Staying hydrated helps your body function at its best."
      };
    }
    
    res.json({
      title: jsonContent.title || "Stay Hydrated! 💧",
      body: jsonContent.body || "Time to drink water! Your body needs it!"
    });
  } catch (error) {
    console.error('Error generating water reminder:', error);
    res.json({
      title: "Stay Hydrated! 💧",
      body: "Time to drink water! Staying hydrated helps your body function at its best."
    });
  }
});

// Generate AI workout reminder
router.post('/workout-reminder', authMiddleware, async (req, res) => {
  try {
    if (!openai) {
      return res.status(500).json({
        title: "Workout Time! 💪",
        body: "Time for your workout! Your body will thank you for staying active."
      });
    }
    
    const context = await getUserContext(req.user._id);
    if (!context) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    const prompt = `You are a friendly, encouraging fitness coach. Generate a personalized workout reminder notification for ${context.user.name}.

USER PROFILE:
- Goals: ${context.user.goals}
- Activity Level: ${context.user.activityLevel}
- Workout Preferences: ${context.user.workoutPreferences.join(', ') || 'General fitness'}
- Weight: ${context.user.weightKg} kg
- Height: ${context.user.heightCm} cm

TODAY'S PROGRESS:
- Calories consumed: ${context.today.calories} / ${context.user.targetCalories} kcal
- Water: ${context.today.water.toFixed(1)}L
- Meals: ${context.today.meals}

RECENT ACTIVITY:
${context.recentMeals.length > 0 ? `Recent meals logged: ${context.recentMeals.length}` : 'No recent meals logged'}

Generate a short, encouraging notification (max 100 characters for body) that:
1. Reminds them it's workout time
2. Is personalized based on their goals and workout preferences
3. Is friendly and motivating
4. May suggest a specific type of workout from their preferences

Return ONLY a JSON object with "title" (max 50 chars) and "body" (max 100 chars) fields. No markdown, no explanations.`;

    const completion = await openai.chat.completions.create({
      model: 'gpt-4o',
      messages: [
        {
          role: 'system',
          content: 'You are a friendly fitness coach. Return ONLY valid JSON with "title" and "body" fields. No markdown, no explanations.'
        },
        {
          role: 'user',
          content: prompt
        }
      ],
      max_tokens: 200,
      temperature: 0.7
    });
    
    const content = completion.choices[0]?.message?.content || '';
    let jsonContent;
    
    try {
      let jsonString = content.trim().replace(/^```json\s*/i, '').replace(/^```\s*/i, '').replace(/\s*```$/i, '');
      jsonContent = JSON.parse(jsonString);
    } catch (parseError) {
      jsonContent = {
        title: "Workout Time! 💪",
        body: "Time for your workout! Your body will thank you for staying active."
      };
    }
    
    res.json({
      title: jsonContent.title || "Workout Time! 💪",
      body: jsonContent.body || "Time for your workout! Let's get moving!"
    });
  } catch (error) {
    console.error('Error generating workout reminder:', error);
    res.json({
      title: "Workout Time! 💪",
      body: "Time for your workout! Your body will thank you for staying active."
    });
  }
});

export default router;

