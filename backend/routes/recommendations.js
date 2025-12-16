import express from 'express';
import Recommendation from '../models/Recommendation.js';
import Meal from '../models/Meal.js';
import User from '../models/User.js';
import OpenAI from 'openai';
import { authMiddleware } from '../middleware/authMiddleware.js';

const router = express.Router();

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY
});

// Get daily recommendations
router.get('/daily', authMiddleware, async (req, res) => {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    // Check if recommendation exists for today
    let recommendation = await Recommendation.findOne({
      userId: req.user._id,
      date: { $gte: today }
    });

    if (!recommendation) {
      // Generate new recommendation
      recommendation = await generateRecommendation(req.user);
    }

    res.json(recommendation);
  } catch (error) {
    console.error('Get recommendations error:', error);
    res.status(500).json({ message: 'Failed to get recommendations', error: error.message });
  }
});

// Generate new recommendation
router.post('/regenerate', authMiddleware, async (req, res) => {
  try {
    const recommendation = await generateRecommendation(req.user);
    res.json(recommendation);
  } catch (error) {
    console.error('Regenerate recommendations error:', error);
    res.status(500).json({ message: 'Failed to regenerate recommendations', error: error.message });
  }
});

async function generateRecommendation(user) {
  // Get user's recent meals and health data
  const recentMeals = await Meal.find({
    userId: user._id
  })
    .sort({ timestamp: -1 })
    .limit(10);

  const today = new Date();
  today.setHours(0, 0, 0, 0);

  // Build context for AI
  const context = {
    user: {
      goals: user.goals,
      activityLevel: user.activityLevel,
      dietaryPreferences: user.dietaryPreferences,
      allergies: user.allergies,
      fastingPreference: user.fastingPreference,
      targetCalories: user.metrics?.targetCalories || 2000
    },
    recentMeals: recentMeals.map(m => ({
      items: m.items.map(i => i.name),
      calories: m.totalCalories,
      timestamp: m.timestamp
    }))
  };

  // Generate meal plan with OpenAI
  const prompt = `Generate a personalized daily meal and workout plan for a user with the following profile:
Goals: ${context.user.goals}
Activity Level: ${context.user.activityLevel}
Dietary Preferences: ${context.user.dietaryPreferences.join(', ') || 'None'}
Allergies: ${context.user.allergies.join(', ') || 'None'}
Target Calories: ${context.user.targetCalories}
Fasting Preference: ${context.user.fastingPreference}

Recent meals: ${JSON.stringify(context.recentMeals.slice(0, 5))}

Return a JSON object with:
- mealPlan: { breakfast: [], lunch: [], dinner: [], snacks: [] } - each item has name, calories, protein, carbs, fat
- workoutPlan: { exercises: [] } - each exercise has name, duration (minutes), calories, type
- hydrationGoal: { targetLiters: number }
- insights: [string array of personalized insights]

Return ONLY valid JSON, no markdown.`;

  const response = await openai.chat.completions.create({
    model: "gpt-4",
    messages: [
      {
        role: "system",
        content: "You are a nutrition and fitness expert. Provide personalized meal and workout recommendations."
      },
      {
        role: "user",
        content: prompt
      }
    ],
    temperature: 0.7,
    max_tokens: 2000
  });

  const content = response.choices[0].message.content;
  let recommendationData;

  try {
    const jsonMatch = content.match(/\{[\s\S]*\}/);
    recommendationData = JSON.parse(jsonMatch ? jsonMatch[0] : content);
  } catch (error) {
    // Fallback recommendation
    recommendationData = {
      mealPlan: {
        breakfast: [{ name: "Oatmeal with fruits", calories: 300, protein: 10, carbs: 50, fat: 5 }],
        lunch: [{ name: "Grilled chicken salad", calories: 400, protein: 30, carbs: 20, fat: 15 }],
        dinner: [{ name: "Salmon with vegetables", calories: 500, protein: 35, carbs: 30, fat: 20 }],
        snacks: [{ name: "Greek yogurt", calories: 150, protein: 15, carbs: 10, fat: 5 }]
      },
      workoutPlan: {
        exercises: [
          { name: "30 min walk", duration: 30, calories: 150, type: "cardio" }
        ]
      },
      hydrationGoal: { targetLiters: 2.5 },
      insights: ["Stay hydrated throughout the day"]
    };
  }

  // Save recommendation
  const recommendation = new Recommendation({
    userId: user._id,
    date: today,
    type: 'meal',
    mealPlan: recommendationData.mealPlan,
    workoutPlan: recommendationData.workoutPlan,
    hydrationGoal: recommendationData.hydrationGoal,
    insights: recommendationData.insights || [],
    aiVersion: "gpt-4"
  });

  await recommendation.save();

  return recommendation;
}

export default router;

