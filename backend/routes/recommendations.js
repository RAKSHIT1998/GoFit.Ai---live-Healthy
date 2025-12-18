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

  // Generate meal plan with OpenAI - Enhanced prompt for better recommendations
  const prompt = `Generate a comprehensive, personalized daily meal and workout plan for a user with the following profile:

USER PROFILE:
- Goals: ${context.user.goals}
- Activity Level: ${context.user.activityLevel}
- Dietary Preferences: ${context.user.dietaryPreferences.join(', ') || 'None specified'}
- Allergies/Restrictions: ${context.user.allergies.join(', ') || 'None'}
- Target Daily Calories: ${context.user.targetCalories} kcal
- Fasting Preference: ${context.user.fastingPreference}

RECENT MEAL HISTORY (last 5 meals):
${JSON.stringify(context.recentMeals.slice(0, 5), null, 2)}

INSTRUCTIONS:
1. Analyze the user's recent meals to understand their eating patterns and preferences
2. Create a balanced meal plan that aligns with their goals (${context.user.goals})
3. Ensure meals are diverse, nutritious, and match their dietary preferences
4. Design workouts that complement their activity level and goals
5. Consider their fasting preference when scheduling meals
6. Provide detailed, practical instructions for both meals and exercises

Return a JSON object with:
- mealPlan: { breakfast: [], lunch: [], dinner: [], snacks: [] } 
  Each meal item should have:
  - name: string
  - calories: number
  - protein: number (grams)
  - carbs: number (grams)
  - fat: number (grams)
  - ingredients: array of strings (list of ingredients)
  - instructions: string (step-by-step cooking instructions)
  - prepTime: number (minutes)
  - servings: number

- workoutPlan: { exercises: [] }
  Each exercise should have:
  - name: string
  - duration: number (minutes)
  - calories: number (estimated calories burned)
  - type: string (cardio, strength, flexibility, hiit, etc.)
  - instructions: string (detailed step-by-step instructions on how to perform the exercise)
  - sets: number (for strength training, null for cardio)
  - reps: string (e.g., "10-12" or "30 seconds" or "as many as possible")
  - restTime: number (seconds between sets, null for continuous exercises)
  - difficulty: string (beginner, intermediate, advanced)
  - muscleGroups: array of strings (e.g., ["chest", "triceps", "shoulders"])
  - equipment: array of strings (e.g., ["dumbbells", "mat"] or ["none"] for bodyweight)

- hydrationGoal: { targetLiters: number }
- insights: [string array of personalized insights]

IMPORTANT REQUIREMENTS:
- All meal items MUST include complete recipes with specific ingredients and step-by-step cooking instructions
- All exercises MUST include detailed, safe instructions on proper form and execution
- Meal calories should sum approximately to the target (${context.user.targetCalories} kcal) with some flexibility
- Workout plan should be appropriate for ${context.user.activityLevel} activity level
- Include variety to prevent boredom and ensure nutritional completeness
- Consider meal timing based on fasting preference: ${context.user.fastingPreference}

Return ONLY valid JSON, no markdown, no code blocks, no explanations outside the JSON structure. The response must be parseable JSON.`;

  const response = await openai.chat.completions.create({
    model: "gpt-4o", // Updated to latest model for better recommendations
    messages: [
      {
        role: "system",
        content: `You are an expert nutritionist and certified personal trainer with years of experience. 
        Your recommendations are evidence-based, personalized, and practical. 
        Consider the user's goals, activity level, dietary preferences, and recent meal history.
        Provide detailed, actionable meal plans with complete recipes and workout plans with step-by-step exercise instructions.
        Ensure all recommendations are safe, achievable, and aligned with the user's profile.`
      },
      {
        role: "user",
        content: prompt
      }
    ],
    temperature: 0.7, // Balanced creativity and consistency
    max_tokens: 4000 // Increased for more detailed meal recipes and workout instructions
  });

  const content = response.choices[0].message.content;
  let recommendationData;

  try {
    // Try multiple parsing strategies for better reliability
    let jsonString = content.trim();
    
    // Remove markdown code blocks if present
    jsonString = jsonString.replace(/```json\n?/g, '').replace(/```\n?/g, '');
    
    // Try to extract JSON object
    const jsonMatch = jsonString.match(/\{[\s\S]*\}/);
    if (jsonMatch) {
      recommendationData = JSON.parse(jsonMatch[0]);
    } else {
      recommendationData = JSON.parse(jsonString);
    }
  } catch (error) {
    console.error('Failed to parse OpenAI recommendation response:', error);
    console.error('Response content:', content.substring(0, 500));
    // Fallback recommendation with full details
    recommendationData = {
      mealPlan: {
        breakfast: [{
          name: "Oatmeal with fruits",
          calories: 300,
          protein: 10,
          carbs: 50,
          fat: 5,
          ingredients: ["1 cup rolled oats", "1 cup water or milk", "1/2 cup mixed berries", "1 tbsp honey", "1 tbsp chopped nuts"],
          instructions: "1. Bring water or milk to a boil. 2. Add oats and reduce heat to medium. 3. Cook for 5 minutes, stirring occasionally. 4. Remove from heat and let sit for 2 minutes. 5. Top with berries, honey, and nuts.",
          prepTime: 10,
          servings: 1
        }],
        lunch: [{
          name: "Grilled chicken salad",
          calories: 400,
          protein: 30,
          carbs: 20,
          fat: 15,
          ingredients: ["150g chicken breast", "2 cups mixed greens", "1/2 cup cherry tomatoes", "1/4 cup cucumber", "2 tbsp olive oil", "1 tbsp lemon juice", "Salt and pepper"],
          instructions: "1. Season chicken with salt and pepper. 2. Grill for 6-7 minutes per side until cooked through. 3. Let rest for 5 minutes, then slice. 4. Toss greens with tomatoes and cucumber. 5. Mix olive oil and lemon juice for dressing. 6. Top salad with chicken and drizzle with dressing.",
          prepTime: 20,
          servings: 1
        }],
        dinner: [{
          name: "Salmon with vegetables",
          calories: 500,
          protein: 35,
          carbs: 30,
          fat: 20,
          ingredients: ["200g salmon fillet", "1 cup mixed vegetables (broccoli, carrots, bell peppers)", "2 tbsp olive oil", "Lemon wedges", "Garlic powder", "Salt and pepper"],
          instructions: "1. Preheat oven to 400°F. 2. Season salmon with salt, pepper, and garlic powder. 3. Toss vegetables with olive oil and seasonings. 4. Place salmon and vegetables on a baking sheet. 5. Bake for 15-18 minutes until salmon flakes easily. 6. Serve with lemon wedges.",
          prepTime: 25,
          servings: 1
        }],
        snacks: [{
          name: "Greek yogurt with berries",
          calories: 150,
          protein: 15,
          carbs: 10,
          fat: 5,
          ingredients: ["1 cup Greek yogurt", "1/2 cup mixed berries", "1 tbsp honey"],
          instructions: "1. Scoop Greek yogurt into a bowl. 2. Top with fresh berries. 3. Drizzle with honey. 4. Enjoy immediately.",
          prepTime: 2,
          servings: 1
        }]
      },
      workoutPlan: {
        exercises: [{
          name: "30 Minute Brisk Walk",
          duration: 30,
          calories: 150,
          type: "cardio",
          instructions: "1. Start with a 5-minute warm-up at a slow pace. 2. Increase to a brisk walking pace where you can still hold a conversation but feel your heart rate increase. 3. Maintain this pace for 20 minutes. 4. Cool down with 5 minutes of slower walking. 5. Focus on good posture: stand tall, engage your core, and swing your arms naturally.",
          sets: null,
          reps: "30 minutes continuous",
          restTime: null,
          difficulty: "beginner",
          muscleGroups: ["legs", "core", "cardiovascular"],
          equipment: ["none"]
        }]
      },
      hydrationGoal: { targetLiters: 2.5 },
      insights: ["Stay hydrated throughout the day", "Aim for 8-10 glasses of water daily"]
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
    aiVersion: "gpt-4o"
  });

  await recommendation.save();

  return recommendation;
}

export default router;

