import express from 'express';
import Recommendation from '../models/Recommendation.js';
import Meal from '../models/Meal.js';
import User from '../models/User.js';
import OpenAI from 'openai';
import { authMiddleware } from '../middleware/authMiddleware.js';
import mlService from '../services/mlService.js';

const router = express.Router();

// Initialize OpenAI API
// Get your API key at: https://platform.openai.com/api-keys
const OPENAI_API_KEY = (process.env.OPENAI_API_KEY || '').trim();
const openai = OPENAI_API_KEY ? new OpenAI({ apiKey: OPENAI_API_KEY }) : null;

// Log OpenAI status on module load
if (OPENAI_API_KEY) {
  console.log(`✅ OPENAI_API_KEY loaded (length: ${OPENAI_API_KEY.length}, starts with: ${OPENAI_API_KEY.substring(0, 10)}...)`);
} else {
  console.error('❌ OPENAI_API_KEY is missing or empty. Recommendations will not work.');
  console.error('   Set OPENAI_API_KEY in Render environment variables: https://platform.openai.com/api-keys');
}

// Get daily recommendations
// This endpoint uses OpenAI (ChatGPT) to generate personalized meal and workout plans
// It sends ALL customer data collected during onboarding to ChatGPT for personalization
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
      // Check if OpenAI is configured before attempting generation
      if (!OPENAI_API_KEY || !openai) {
        console.warn('⚠️ OpenAI not configured - skipping AI recommendation generation');
        // Return null or empty recommendation - client will use fallback data
        return res.status(200).json({
          mealPlan: { breakfast: [], lunch: [], dinner: [], snacks: [] },
          workoutPlan: { exercises: [] },
          hydrationGoal: { targetLiters: 2.5 },
          insights: ['AI recommendations are not available. Using built-in recommendations.']
        });
      }
      
      // Generate new recommendation using ChatGPT (OpenAI GPT-4o) with all onboarding data
      console.log('📝 No recommendation found for today, generating new one with ChatGPT...');
      console.log(`🤖 Sending user data to ChatGPT (OpenAI GPT-4o) for personalized meal and workout recommendations (user: ${req.user._id})`);
      try {
        recommendation = await generateRecommendation(req.user);
        console.log('✅ New personalized meal and workout recommendations generated successfully by ChatGPT (OpenAI GPT-4o)');
      } catch (genError) {
        console.error('❌ Failed to generate recommendation:', genError.message);
        // Return empty recommendation - client will use fallback data
        return res.status(200).json({
          mealPlan: { breakfast: [], lunch: [], dinner: [], snacks: [] },
          workoutPlan: { exercises: [] },
          hydrationGoal: { targetLiters: 2.5 },
          insights: ['AI recommendations are temporarily unavailable. Using built-in recommendations.']
        });
      }
    } else {
      console.log('✅ Found existing recommendation for today');
    }

    res.json(recommendation);
  } catch (error) {
    console.error('❌ Get recommendations error:', error.message);
    // Don't log full stack in production
    if (process.env.NODE_ENV === 'development') {
      console.error('❌ Error stack:', error.stack);
    }
    // Return empty recommendation instead of error - client will use fallback
    res.status(200).json({
      mealPlan: { breakfast: [], lunch: [], dinner: [], snacks: [] },
      workoutPlan: { exercises: [] },
      hydrationGoal: { targetLiters: 2.5 },
      insights: ['Recommendations are temporarily unavailable. Using built-in recommendations.']
    });
  }
});

// Generate new recommendation
// This endpoint uses OpenAI (ChatGPT) to regenerate personalized meal and workout plans
// It sends ALL customer data collected during onboarding to ChatGPT for personalization
router.post('/regenerate', authMiddleware, async (req, res) => {
  try {
    // Check if OpenAI is configured before attempting generation
    if (!OPENAI_API_KEY || !openai) {
      console.warn('⚠️ OpenAI not configured - cannot regenerate recommendations');
      // Return empty recommendation - client will use fallback data
      return res.status(200).json({
        mealPlan: { breakfast: [], lunch: [], dinner: [], snacks: [] },
        workoutPlan: { exercises: [] },
        hydrationGoal: { targetLiters: 2.5 },
        insights: ['AI recommendations are not available. Using built-in recommendations.']
      });
    }
    
    // CRITICAL: Delete existing recommendations for today to force new generation
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    
    const deletedCount = await Recommendation.deleteMany({
      userId: req.user._id,
      date: { $gte: today }
    });
    
    if (deletedCount.deletedCount > 0) {
      console.log(`🗑️ Deleted ${deletedCount.deletedCount} existing recommendation(s) to force regeneration`);
    }
    
    console.log('📝 Regenerating personalized meal and workout recommendations for user:', req.user._id);
    console.log(`🤖 Sending user data to ChatGPT (OpenAI GPT-4o) for regeneration...`);
    console.log(`🔄 This will generate completely NEW meals and workouts (not cached)`);
    try {
      const recommendation = await generateRecommendation(req.user, true); // Pass forceNew=true
      console.log('✅ Personalized meal and workout recommendations regenerated successfully by ChatGPT (OpenAI GPT-4o)');
      console.log(`🆕 New recommendations generated with fresh meals and workouts`);
      res.json(recommendation);
    } catch (genError) {
      console.error('❌ Failed to regenerate recommendation:', genError.message);
      // Don't log full stack in production
      if (process.env.NODE_ENV === 'development') {
        console.error('❌ Error stack:', genError.stack);
      }
      // Return empty recommendation instead of error - client will use fallback
      res.status(200).json({
        mealPlan: { breakfast: [], lunch: [], dinner: [], snacks: [] },
        workoutPlan: { exercises: [] },
        hydrationGoal: { targetLiters: 2.5 },
        insights: ['AI recommendations are temporarily unavailable. Using built-in recommendations.']
      });
    }
  } catch (error) {
    console.error('❌ Regenerate recommendations error:', error.message);
    // Don't log full stack in production
    if (process.env.NODE_ENV === 'development') {
      console.error('❌ Error stack:', error.stack);
    }
    // Return empty recommendation instead of error - client will use fallback
    res.status(200).json({
      mealPlan: { breakfast: [], lunch: [], dinner: [], snacks: [] },
      workoutPlan: { exercises: [] },
      hydrationGoal: { targetLiters: 2.5 },
      insights: ['Recommendations are temporarily unavailable. Using built-in recommendations.']
    });
  }
});

// Get ML insights for user
router.get('/ml-insights', authMiddleware, async (req, res) => {
  try {
    const insights = await mlService.getMLInsights(req.user._id);
    if (!insights) {
      return res.status(404).json({ message: 'No ML insights available yet' });
    }
    res.json(insights);
  } catch (error) {
    console.error('Get ML insights error:', error);
    res.status(500).json({ message: 'Failed to get ML insights', error: error.message });
  }
});

// Track recommendation feedback
router.post('/feedback', authMiddleware, async (req, res) => {
  try {
    const { recommendationId, type, action, rating } = req.body;
    
    if (!recommendationId || !type || !action) {
      return res.status(400).json({ message: 'recommendationId, type, and action are required' });
    }
    
    await mlService.trackRecommendationFeedback(
      req.user._id,
      recommendationId,
      type,
      action,
      rating
    );
    
    // Check if recommendations need adaptation
    const adaptations = await mlService.adaptRecommendations(req.user._id);
    
    res.json({ 
      success: true,
      adaptations: adaptations || null
    });
  } catch (error) {
    console.error('Track feedback error:', error);
    res.status(500).json({ message: 'Failed to track feedback', error: error.message });
  }
});

/**
 * Build dietary restrictions text for prompt
 */
function buildDietaryRestrictions(dietaryPreferences) {
  if (!dietaryPreferences || dietaryPreferences.length === 0) {
    return '';
  }
  
  const restrictions = [];
  
  if (dietaryPreferences.includes('vegan')) {
    restrictions.push(
      '⚠️ CRITICAL: USER IS VEGAN - ABSOLUTELY NO animal products:\n' +
      '   - NO meat (beef, pork, chicken, turkey, lamb, fish, seafood, etc.)\n' +
      '   - NO eggs (in any form: scrambled, boiled, fried, etc.)\n' +
      '   - NO dairy (milk, cheese, butter, yogurt, cream, etc.)\n' +
      '   - NO honey or bee products\n' +
      '   - NO animal-derived ingredients (gelatin, lard, etc.)\n' +
      '   - ONLY plant-based foods are allowed\n' +
      '   - Use plant-based protein: legumes, tofu, tempeh, seitan, nuts, seeds, quinoa, etc.'
    );
  } else if (dietaryPreferences.includes('vegetarian')) {
    restrictions.push(
      '⚠️ USER IS VEGETARIAN - NO meat or fish:\n' +
      '   - NO meat (beef, pork, chicken, turkey, lamb, etc.)\n' +
      '   - NO fish or seafood\n' +
      '   - Eggs and dairy products ARE allowed'
    );
  }
  
  if (dietaryPreferences.includes('keto')) {
    restrictions.push('⚠️ USER IS ON KETO - Very low carb (under 20g net carbs/day), high fat, moderate protein');
  }
  
  if (dietaryPreferences.includes('paleo')) {
    restrictions.push('⚠️ USER IS ON PALEO - No grains, legumes, dairy, or processed foods. Focus on meat, fish, eggs, vegetables, fruits, nuts.');
  }
  
  if (dietaryPreferences.includes('low_carb')) {
    restrictions.push('⚠️ USER PREFERS LOW CARB - Limit carbohydrates, focus on protein and healthy fats');
  }
  
  if (dietaryPreferences.includes('mediterranean')) {
    restrictions.push('⚠️ USER PREFERS MEDITERRANEAN DIET - Focus on vegetables, fruits, whole grains, olive oil, fish, moderate wine');
  }
  
  return restrictions.length > 0 ? `- DIETARY RESTRICTIONS (MANDATORY - MUST BE STRICTLY ENFORCED):\n${restrictions.map(r => `  ${r}`).join('\n')}` : '';
}

/**
 * Check if a meal item violates dietary preferences
 */
function violatesDietaryPreference(mealItem, dietaryPreferences) {
  if (!dietaryPreferences || dietaryPreferences.length === 0) {
    return false;
  }
  
  const mealName = (mealItem.name || '').toLowerCase();
  const ingredients = (mealItem.ingredients || []).map(i => i.toLowerCase()).join(' ');
  const allText = `${mealName} ${ingredients}`.toLowerCase();
  
  // Non-vegan items - comprehensive list including all variations
  const nonVeganItems = [
    // Meats
    'beef', 'pork', 'chicken', 'turkey', 'lamb', 'duck', 'goose', 'venison', 'bison', 'rabbit',
    'meat', 'poultry', 'red meat', 'white meat',
    // Fish and seafood
    'fish', 'salmon', 'tuna', 'cod', 'haddock', 'mackerel', 'sardine', 'anchovy', 'herring',
    'shrimp', 'prawn', 'crab', 'lobster', 'crayfish', 'mussel', 'oyster', 'clam', 'scallop',
    'seafood', 'shellfish', 'squid', 'octopus', 'calamari',
    // Eggs (all forms)
    'egg', 'eggs', 'scrambled', 'fried egg', 'boiled egg', 'poached egg', 'omelet', 'omelette',
    'frittata', 'quiche', 'egg white', 'egg yolk', 'deviled egg', 'egg salad',
    // Dairy products
    'milk', 'cheese', 'butter', 'yogurt', 'yoghurt', 'cream', 'sour cream', 'heavy cream',
    'dairy', 'whey', 'casein', 'lactose', 'ghee', 'buttermilk', 'cottage cheese',
    'mozzarella', 'cheddar', 'parmesan', 'feta', 'ricotta', 'cream cheese',
    // Other animal products
    'honey', 'gelatin', 'lard', 'tallow', 'rendered fat',
    // Processed meats
    'bacon', 'sausage', 'ham', 'pepperoni', 'salami', 'prosciutto', 'chorizo', 'bologna',
    'hot dog', 'frankfurter', 'bratwurst', 'kielbasa', 'pastrami', 'corned beef',
    // Broth/stock
    'chicken broth', 'beef broth', 'fish stock', 'bone broth', 'chicken stock', 'beef stock'
  ];
  
  // Non-vegetarian items (meat and fish, but allow eggs/dairy)
  const nonVegetarianItems = [
    // Meats
    'beef', 'pork', 'chicken', 'turkey', 'lamb', 'duck', 'goose', 'venison', 'bison', 'rabbit',
    'meat', 'poultry', 'red meat', 'white meat',
    // Fish and seafood
    'fish', 'salmon', 'tuna', 'cod', 'haddock', 'mackerel', 'sardine', 'anchovy', 'herring',
    'shrimp', 'prawn', 'crab', 'lobster', 'crayfish', 'mussel', 'oyster', 'clam', 'scallop',
    'seafood', 'shellfish', 'squid', 'octopus', 'calamari',
    // Processed meats
    'bacon', 'sausage', 'ham', 'pepperoni', 'salami', 'prosciutto', 'chorizo', 'bologna',
    'hot dog', 'frankfurter', 'bratwurst', 'kielbasa', 'pastrami', 'corned beef',
    // Broth/stock
    'chicken broth', 'beef broth', 'fish stock', 'bone broth', 'chicken stock', 'beef stock'
  ];
  
  if (dietaryPreferences.includes('vegan')) {
    // Check for any non-vegan items - use word boundaries for better matching
    for (const item of nonVeganItems) {
      // Use word boundary regex to avoid false positives (e.g., "chicken" in "chickpea")
      const regex = new RegExp(`\\b${item.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}\\b`, 'i');
      if (regex.test(allText)) {
        console.log(`🚫 Vegan violation detected: "${item}" found in "${mealName}"`);
        return true;
      }
    }
  } else if (dietaryPreferences.includes('vegetarian')) {
    // Check for meat/fish but allow eggs/dairy - use word boundaries
    for (const item of nonVegetarianItems) {
      const regex = new RegExp(`\\b${item.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}\\b`, 'i');
      if (regex.test(allText)) {
        console.log(`🚫 Vegetarian violation detected: "${item}" found in "${mealName}"`);
        return true;
      }
    }
  }
  
  return false;
}

/**
 * Filter meal plan to remove items that violate dietary preferences
 */
function filterMealPlanByDietaryPreferences(mealPlan, dietaryPreferences) {
  if (!mealPlan || !dietaryPreferences || dietaryPreferences.length === 0) {
    return mealPlan;
  }
  
  const filtered = {
    breakfast: [],
    lunch: [],
    dinner: [],
    snacks: []
  };
  
  // Filter each meal category
  ['breakfast', 'lunch', 'dinner', 'snacks'].forEach(category => {
    if (mealPlan[category] && Array.isArray(mealPlan[category])) {
      filtered[category] = mealPlan[category].filter(meal => {
        const violates = violatesDietaryPreference(meal, dietaryPreferences);
        if (violates) {
          console.log(`⚠️ Filtered out non-compliant meal: ${meal.name} (violates ${dietaryPreferences.join(', ')})`);
        }
        return !violates;
      });
    }
  });
  
  return filtered;
}

/**
 * Generate personalized meal and workout recommendations using ChatGPT (OpenAI GPT-4o)
 * 
 * This function uses ChatGPT to generate:
 * - Personalized meal plans (breakfast, lunch, dinner, snacks) with complete recipes
 * - Personalized workout plans (exercises with detailed instructions, sets, reps, etc.)
 * 
 * This function:
 * 1. Collects ALL customer data from onboarding (preferences, goals, lifestyle, etc.)
 * 2. Sends comprehensive user profile to ChatGPT (OpenAI GPT-4o)
 * 3. Receives personalized daily meal and workout plans from ChatGPT
 * 4. Filters meals to ensure dietary compliance (vegan/vegetarian)
 * 5. Saves recommendations to database for daily use
 * 
 * @param {Object} user - User document with all onboarding data
 * @returns {Object} Recommendation document with meal and workout plans generated by ChatGPT
 */
async function generateRecommendation(user) {
  console.log(`🤖 Starting ChatGPT (OpenAI GPT-4o) recommendation generation for user: ${user._id}`);
  console.log(`📊 User profile: goals=${user.goals}, activityLevel=${user.activityLevel}`);
  console.log(`🍽️ ChatGPT will generate personalized meal plan with recipes`);
  console.log(`💪 ChatGPT will generate personalized workout plan with exercise instructions`);
  
  // Get ML insights for personalized recommendations
  let mlInsights = await mlService.getMLInsights(user._id);
  
  // Classify user type if not already done
  if (!mlInsights || !mlInsights.userType) {
    await mlService.classifyUserType(user._id);
    const updatedInsights = await mlService.getMLInsights(user._id);
    if (updatedInsights) {
      // Reassign mlInsights to use the updated insights
      mlInsights = updatedInsights;
    }
  }
  
  // Get user's recent meals and health data
  const recentMeals = await Meal.find({
    userId: user._id
  })
    .sort({ timestamp: -1 })
    .limit(10);

  const today = new Date();
  today.setHours(0, 0, 0, 0);

  // Build enhanced context for AI with ML insights and comprehensive onboarding data
  // This includes ALL data collected during onboarding to ensure ChatGPT has complete user profile
  const context = {
    user: {
      // Basic profile
      name: user.name,
      goals: user.goals,
      activityLevel: user.activityLevel,
      dietaryPreferences: user.dietaryPreferences || [],
      allergies: user.allergies || [],
      fastingPreference: user.fastingPreference,
      
      // Physical metrics
      weightKg: user.metrics?.weightKg || 70,
      heightCm: user.metrics?.heightCm || 170,
      targetWeightKg: user.metrics?.targetWeightKg || null, // Target weight from onboarding
      targetCalories: user.metrics?.targetCalories || 2000,
      targetProtein: user.metrics?.targetProtein || 150,
      targetCarbs: user.metrics?.targetCarbs || 200,
      targetFat: user.metrics?.targetFat || 65,
      
      // Comprehensive onboarding data for personalization (ALL fields collected during signup)
      workoutPreferences: user.onboardingData?.workoutPreferences || user.workoutPreferences || [],
      favoriteCuisines: user.onboardingData?.favoriteCuisines || user.favoriteCuisines || [],
      foodPreferences: user.onboardingData?.foodPreferences || user.foodPreferences || [],
      workoutTimeAvailability: user.onboardingData?.workoutTimeAvailability || user.workoutTimeAvailability || 'moderate',
      lifestyleFactors: user.onboardingData?.lifestyleFactors || user.lifestyleFactors || [],
      favoriteFoods: user.onboardingData?.favoriteFoods || [], // From onboarding
      mealTimingPreference: user.onboardingData?.mealTimingPreference || 'regular',
      cookingSkill: user.onboardingData?.cookingSkill || 'intermediate', // Cooking ability for recipe complexity
      budgetPreference: user.onboardingData?.budgetPreference || 'moderate', // Budget for meal planning
      motivationLevel: user.onboardingData?.motivationLevel || 'moderate', // Motivation level for workout intensity
      drinkingFrequency: user.onboardingData?.drinkingFrequency || user.drinkingFrequency || 'never',
      smokingStatus: user.onboardingData?.smokingStatus || user.smokingStatus || 'never',
      
      // Machine Learning insights (learned from user behavior over time)
      userType: mlInsights?.userType || 'beginner',
      mlFavoriteFoods: mlInsights?.preferences?.favoriteFoods || [], // ML-learned favorites (may differ from onboarding)
      preferredMealTimes: mlInsights?.preferences?.preferredMealTimes || [],
      averageMealCalories: mlInsights?.preferences?.averageMealCalories || 0,
      preferredMacroRatio: mlInsights?.preferences?.preferredMacroRatio || {
        protein: 30,
        carbs: 40,
        fat: 30
      },
      mlRecommendations: mlInsights?.recommendations || {}
    },
    recentMeals: recentMeals.map(m => ({
      items: m.items.map(i => i.name),
      calories: m.totalCalories,
      protein: m.totalProtein || 0,
      carbs: m.totalCarbs || 0,
      fat: m.totalFat || 0,
      timestamp: m.timestamp
    }))
  };

  // Check if OpenAI API key is configured
  if (!OPENAI_API_KEY || OPENAI_API_KEY.trim() === '') {
    console.error('❌ OPENAI_API_KEY is not set or empty for recommendations');
    throw new Error('AI recommendation service is not configured. Please set OPENAI_API_KEY environment variable. Get your API key at https://platform.openai.com/api-keys');
  }
  
  if (!openai) {
    console.error('❌ Failed to initialize OpenAI for recommendations');
    throw new Error('AI recommendation service initialization failed. Please check OPENAI_API_KEY configuration.');
  }

  // Generate meal plan with OpenAI - Enhanced prompt with ML insights
  // Build dietary restrictions section with explicit rules
  const dietaryRestrictions = buildDietaryRestrictions(context.user.dietaryPreferences);
  
  const prompt = `Generate a comprehensive, personalized daily meal and workout plan for a user with the following profile:

USER PROFILE (COMPREHENSIVE - ALL ONBOARDING DATA):
- Name: ${context.user.name}
- Goals: ${context.user.goals}
- Activity Level: ${context.user.activityLevel}
- Dietary Preferences: ${context.user.dietaryPreferences.join(', ') || 'None specified'}
${dietaryRestrictions}
- Allergies/Restrictions: ${context.user.allergies.join(', ') || 'None'}
- Current Weight: ${context.user.weightKg} kg
- Height: ${context.user.heightCm} cm
- Target Weight: ${context.user.targetWeightKg ? context.user.targetWeightKg + ' kg' : 'Not specified'}
- Target Daily Calories: ${context.user.targetCalories} kcal
- Target Protein: ${context.user.targetProtein}g
- Target Carbs: ${context.user.targetCarbs}g
- Target Fat: ${context.user.targetFat}g
- Fasting Preference: ${context.user.fastingPreference}

WORKOUT & FITNESS PREFERENCES (from onboarding):
- Workout Preferences: ${context.user.workoutPreferences.join(', ') || 'General fitness'}
- Workout Time Availability: ${context.user.workoutTimeAvailability}
- Motivation Level: ${context.user.motivationLevel}

FOOD & LIFESTYLE PREFERENCES (from onboarding):
- Favorite Cuisines: ${context.user.favoriteCuisines.join(', ') || 'Varied'}
- Food Preferences: ${context.user.foodPreferences.join(', ') || 'Balanced'}
- Favorite Foods: ${context.user.favoriteFoods.join(', ') || 'None specified'}
- Meal Timing Preference: ${context.user.mealTimingPreference || 'Regular'}
- Cooking Skill Level: ${context.user.cookingSkill || 'Intermediate'}
- Budget Preference: ${context.user.budgetPreference || 'Moderate'}

LIFESTYLE HABITS (from onboarding):
- Drinking Frequency: ${context.user.drinkingFrequency || 'Never'}
- Smoking Status: ${context.user.smokingStatus || 'Never'}
- Lifestyle Factors: ${context.user.lifestyleFactors.join(', ') || 'Standard'}

MACHINE LEARNING INSIGHTS (learned from user behavior over time):
- User Type: ${context.user.userType}
- ML-Learned Favorite Foods: ${context.user.mlFavoriteFoods?.join(', ') || 'None yet - user is new, use onboarding favorites'}
- Preferred Meal Times: ${JSON.stringify(context.user.preferredMealTimes)}
- Average Meal Calories: ${context.user.averageMealCalories.toFixed(0)} kcal
- Preferred Macro Ratio: Protein ${context.user.preferredMacroRatio.protein}%, Carbs ${context.user.preferredMacroRatio.carbs}%, Fat ${context.user.preferredMacroRatio.fat}%
- ML Recommendations: ${JSON.stringify(context.user.mlRecommendations)}

RECENT MEAL HISTORY (last 5 meals):
${JSON.stringify(context.recentMeals.slice(0, 5), null, 2)}

INSTRUCTIONS:
0. **CRITICAL - DIETARY RESTRICTIONS MUST BE STRICTLY ENFORCED - THIS IS NON-NEGOTIABLE**: 
   ${context.user.dietaryPreferences.includes('vegan') ? 
     '🚫🚫🚫 USER IS VEGAN - ABSOLUTELY NO ANIMAL PRODUCTS ALLOWED. THIS IS MANDATORY. 🚫🚫🚫\n' +
     '   - FORBIDDEN: All meat (beef, pork, chicken, turkey, lamb, duck, venison, etc.)\n' +
     '   - FORBIDDEN: All fish and seafood (salmon, tuna, shrimp, crab, lobster, etc.)\n' +
     '   - FORBIDDEN: All eggs (scrambled eggs, fried eggs, boiled eggs, omelets, frittatas, quiches, etc.)\n' +
     '   - FORBIDDEN: All dairy (milk, cheese, butter, yogurt, cream, sour cream, etc.)\n' +
     '   - FORBIDDEN: Honey, gelatin, lard, animal broths/stocks\n' +
     '   - FORBIDDEN: Any processed foods containing animal products\n' +
     '   - ALLOWED ONLY: Plant-based foods (vegetables, fruits, grains, legumes, nuts, seeds)\n' +
     '   - PROTEIN SOURCES: Tofu, tempeh, seitan, legumes, lentils, chickpeas, beans, quinoa, nuts, seeds\n' +
     '   - IF YOU SUGGEST ANY ANIMAL PRODUCT (including eggs, chicken, fish, dairy), THE ENTIRE RECOMMENDATION IS INVALID\n' +
     '   - DOUBLE-CHECK every meal name and ingredient list before including it\n' +
     '   - Example of FORBIDDEN meals: "Scrambled Eggs", "Chicken Salad", "Salmon Bowl", "Greek Yogurt Parfait"\n' +
     '   - Example of ALLOWED meals: "Tofu Scramble", "Chickpea Salad", "Lentil Curry", "Oatmeal with Berries"\n' :
     context.user.dietaryPreferences.includes('vegetarian') ?
     '🚫 USER IS VEGETARIAN - NO MEAT OR FISH ALLOWED. THIS IS MANDATORY. 🚫\n' +
     '   - FORBIDDEN: All meat (beef, pork, chicken, turkey, lamb, duck, etc.)\n' +
     '   - FORBIDDEN: All fish and seafood (salmon, tuna, shrimp, crab, lobster, etc.)\n' +
     '   - FORBIDDEN: Meat broths/stocks (chicken broth, beef broth, fish stock)\n' +
     '   - ALLOWED: Eggs (scrambled, fried, boiled, omelets, etc.)\n' +
     '   - ALLOWED: Dairy products (milk, cheese, butter, yogurt, etc.)\n' +
     '   - IF YOU SUGGEST ANY MEAT OR FISH, THE ENTIRE RECOMMENDATION IS INVALID\n' +
     '   - DOUBLE-CHECK every meal name and ingredient list before including it\n' +
     '   - Example of FORBIDDEN meals: "Chicken Salad", "Salmon Bowl", "Beef Stir Fry"\n' +
     '   - Example of ALLOWED meals: "Scrambled Eggs", "Cheese Pizza", "Greek Yogurt Parfait", "Vegetable Curry"\n' :
     ''}
   ${context.user.dietaryPreferences.includes('keto') ? 
     '⚠️ USER IS ON KETO - Very low carb (under 20g net carbs per day), high fat, moderate protein.\n' :
     ''}
   ${context.user.dietaryPreferences.includes('paleo') ? 
     '⚠️ USER IS ON PALEO - No grains, legumes, dairy, or processed foods. Focus on meat, fish, eggs, vegetables, fruits, nuts.\n' :
     ''}
   ${context.user.dietaryPreferences.includes('low_carb') ? 
     '⚠️ USER PREFERS LOW CARB - Limit carbohydrates, focus on protein and healthy fats.\n' :
     ''}
   ${context.user.dietaryPreferences.includes('mediterranean') ? 
     '⚠️ USER PREFERS MEDITERRANEAN DIET - Focus on vegetables, fruits, whole grains, olive oil, fish, moderate wine.\n' :
     ''}
   These dietary restrictions are MANDATORY and non-negotiable. Every meal must comply 100%.

1. **PRIORITIZE ALL ONBOARDING DATA**: Use ALL the comprehensive onboarding data collected during signup to create highly personalized recommendations:
   - **Workout Preferences**: Incorporate their preferred workout types (${context.user.workoutPreferences.join(', ') || 'general fitness'}) into the workout plan
   - **Favorite Cuisines**: Include meals from their favorite cuisines (${context.user.favoriteCuisines.join(', ') || 'varied'}) in meal suggestions - this is critical for user satisfaction
   - **Food Preferences**: Consider their food preferences (${context.user.foodPreferences.join(', ') || 'balanced'}) when creating meal plans
   - **Favorite Foods**: If they specified favorite foods (${context.user.favoriteFoods.join(', ') || 'none'}), incorporate them into meal suggestions
   - **Workout Time**: Design workouts that fit their available time (${context.user.workoutTimeAvailability})
   - **Cooking Skill**: Adjust recipe complexity based on their cooking skill (${context.user.cookingSkill || 'intermediate'}) - simpler recipes for beginners, more complex for advanced
   - **Budget Preference**: Consider their budget preference (${context.user.budgetPreference || 'moderate'}) when suggesting ingredients and meal options
   - **Motivation Level**: Adjust workout intensity and meal plan complexity based on motivation level (${context.user.motivationLevel || 'moderate'})
   - **Lifestyle Factors**: Adapt recommendations based on their lifestyle (${context.user.lifestyleFactors.join(', ') || 'standard'})
   - **Target Weight**: If they specified a target weight (${context.user.targetWeightKg || 'not specified'}), create a plan that helps them reach it
2. **PRIORITIZE ML INSIGHTS**: Use the machine learning insights to personalize recommendations:
   - If user has favorite foods, incorporate them into meal suggestions
   - Respect preferred meal times from their behavior patterns
   - Match their preferred macro ratio when possible
   - Consider their user type (${context.user.userType}) for appropriate recommendations
3. Analyze the user's recent meals to understand their eating patterns and preferences
4. Create a balanced meal plan that aligns with their goals (${context.user.goals}) AND learned preferences
5. Ensure meals are diverse, nutritious, and match their dietary preferences
6. Design workouts that complement their activity level, goals, AND workout preferences
7. Consider their fasting preference when scheduling meals
8. **GRADUAL ADAPTATION**: If this is a returning user, gradually adapt recommendations based on their behavior patterns
9. Provide detailed, practical instructions for both meals and exercises

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

CRITICAL JSON FORMAT REQUIREMENTS:
- Return ONLY valid JSON object, no markdown, no code blocks, no explanations
- workoutPlan.exercises MUST be an array of objects, NOT a string
- Each exercise object must have: name, duration, calories, type, instructions, sets (or null), reps, restTime (or null), difficulty, muscleGroups (array), equipment (array)
- mealPlan arrays (breakfast, lunch, dinner, snacks) must be arrays of objects
- Do NOT return exercises as a string representation of an array
- The JSON must be valid and parseable

You are an expert nutritionist and certified personal trainer with years of experience. 
        Your recommendations are evidence-based, personalized, and practical. 
        Consider the user's goals, activity level, dietary preferences, and recent meal history.
        Provide detailed, actionable meal plans with complete recipes and workout plans with step-by-step exercise instructions.
Ensure all recommendations are safe, achievable, and aligned with the user's profile.`;

  try {
    // Check OpenAI API key first
    if (!OPENAI_API_KEY || OPENAI_API_KEY.trim() === '') {
      console.error('❌ OPENAI_API_KEY is not set or empty');
      throw new Error('AI recommendation service is not configured. Please set OPENAI_API_KEY environment variable.');
    }
    
    if (!openai) {
      console.error('❌ OpenAI client not initialized');
      throw new Error('AI recommendation service initialization failed.');
    }
    
    // Use OpenAI GPT-4o (ChatGPT) for recommendations (high quality and reliable)
    const modelPreference = process.env.OPENAI_MODEL || 'gpt-4o';
    
    console.log(`✅ Using ChatGPT (OpenAI ${modelPreference}) for meal and workout recommendations`);
    console.log(`🤖 Making ChatGPT API request for personalized recommendations (user: ${user._id})...`);
    console.log(`📊 User context: goals=${user.goals}, activityLevel=${user.activityLevel}, targetCalories=${user.metrics?.targetCalories || 2000}`);
    console.log(`🍽️ ChatGPT will generate: Personalized meal plan (breakfast, lunch, dinner, snacks)`);
    console.log(`💪 ChatGPT will generate: Personalized workout plan (exercises with instructions)`);
    
    // Generate content with OpenAI
    const completion = await openai.chat.completions.create({
      model: modelPreference,
      messages: [
        {
          role: 'system',
          content: `You are an expert nutritionist and certified personal trainer. 

CRITICAL DIETARY RESTRICTION REQUIREMENTS:
${context.user.dietaryPreferences.includes('vegan') ? 
  '🚫 USER IS VEGAN - ABSOLUTELY FORBIDDEN: meat, fish, eggs, dairy, honey, gelatin, or any animal products.\n' +
  'ONLY plant-based foods allowed. If you suggest ANY animal product, the recommendation is INVALID.\n' :
  context.user.dietaryPreferences.includes('vegetarian') ?
  '🚫 USER IS VEGETARIAN - FORBIDDEN: meat, fish, seafood. ALLOWED: eggs, dairy.\n' +
  'If you suggest ANY meat or fish, the recommendation is INVALID.\n' :
  ''}
You MUST strictly follow all dietary restrictions. Double-check every meal name and ingredient.

CRITICAL JSON FORMAT REQUIREMENTS:
1. Return ONLY valid JSON object - no markdown, no code blocks, no explanations
2. workoutPlan.exercises MUST be a JSON array of objects, NEVER a string or JavaScript code
3. Each exercise object must have: name, duration, calories, type, instructions, sets (or null), reps, restTime (or null), difficulty, muscleGroups (array), equipment (array)
4. mealPlan arrays (breakfast, lunch, dinner, snacks) MUST be arrays of objects
5. DO NOT use JavaScript string concatenation syntax like " + " or "\\n" + "
6. Return pure, valid JSON that can be directly parsed by JSON.parse()
7. Example: {"workoutPlan": {"exercises": [{"name": "Running", "duration": 30, "calories": 150, "type": "cardio", "instructions": "Run at moderate pace", "sets": null, "reps": "continuous", "restTime": null, "difficulty": "beginner", "muscleGroups": ["legs"], "equipment": ["none"]}]}}`
        },
        {
          role: 'user',
          content: prompt
        }
      ],
        temperature: 0.7, // Balanced creativity and consistency
      max_tokens: 4000, // Increased for more detailed meal recipes and workout instructions
      response_format: { type: 'json_object' } // Request JSON format
    });
    
    const content = completion.choices[0]?.message?.content || '';
    
    console.log('✅ ChatGPT recommendation generation completed successfully');
    console.log(`📊 ChatGPT response received: ${content.length} characters`);
    console.log(`🤖 ChatGPT API request successful - personalized meal and workout recommendations generated for user: ${user._id}`);
    console.log(`🍽️💪 ChatGPT generated both meal plan and workout plan with detailed instructions`);
    console.log('📝 Response length:', content.length, 'characters');
    
  let recommendationData;

  try {
    // Try multiple parsing strategies for better reliability
    let jsonString = content.trim();
    
    // Remove markdown code blocks if present (OpenAI might still add them sometimes)
    jsonString = jsonString.replace(/^```json\s*/i, '').replace(/^```\s*/i, '').replace(/\s*```$/i, '');
    
    // Try to extract JSON object
    const jsonMatch = jsonString.match(/\{[\s\S]*\}/);
    if (jsonMatch) {
      recommendationData = JSON.parse(jsonMatch[0]);
    } else {
      recommendationData = JSON.parse(jsonString);
    }
    
    // Validate and fix the structure
    if (recommendationData.workoutPlan && recommendationData.workoutPlan.exercises) {
      // Ensure exercises is an array
      if (typeof recommendationData.workoutPlan.exercises === 'string') {
        console.log('⚠️ Exercises is a string, attempting to parse...');
        console.log('📝 Exercises string preview:', recommendationData.workoutPlan.exercises.substring(0, 200));
        try {
          // The string might be a JavaScript code representation with concatenation
          // Example: "[\\n' +\n  '  {\\n' +\n  \"    name: 'Swimming',\\n\"..."
          // This is a JavaScript string literal that represents code, not JSON
          let exerciseString = recommendationData.workoutPlan.exercises;
          
          console.log('📝 Raw exercises string (first 500 chars):', exerciseString.substring(0, 500));
          
          // Strategy: Build the actual JSON by removing all JavaScript concatenation patterns
          // The format is: "[\\n' +\n  '  {\\n' +\n  \"    name: 'Swimming',\\n\"..."
          
          // Step 1: Remove outer quotes if present
          exerciseString = exerciseString.replace(/^["']|["']$/g, '');
          
          // Step 2: Remove all JavaScript string concatenation patterns
          // The actual pattern from OpenAI is: "[\\n' +\n  '  {\\n' +\n  \"    name: '...',\\n\" +..."
          // Pattern breakdown: "[\\n' +\n  '  {\\n' +\n  \"    name: 'Brisk Walking',\\n\" +..."
          
          // Remove the most common pattern: ' +\n  ' (quote, space, plus, newline, spaces, quote)
          // This handles: ' +\n  ' or " +\n  "
          exerciseString = exerciseString.replace(/['"]\s*\+\s*\n\s*['"]/g, '');
          
          // Remove pattern: \\n' +\n  ' (escaped newline, quote, space, plus, newline, spaces, quote)
          exerciseString = exerciseString.replace(/\\n['"]\s*\+\s*\n\s*['"]/g, '');
          
          // Remove pattern: ' +\n' or " +\n" (quote, space, plus, newline, quote) - no spaces
          exerciseString = exerciseString.replace(/['"]\s*\+\s*\n['"]/g, '');
          
          // Remove pattern: \\n' +\n' (escaped newline, quote, space, plus, newline, quote)
          exerciseString = exerciseString.replace(/\\n['"]\s*\+\s*\n['"]/g, '');
          
          // Remove pattern: ' +' or " +" (quote, space, plus, quote) - same line
          exerciseString = exerciseString.replace(/['"]\s*\+\s*['"]/g, '');
          
          // Remove any remaining: ' + or " + (quote, space, plus) at end of line
          exerciseString = exerciseString.replace(/['"]\s*\+\s*$/gm, '');
          
          // Remove standalone concatenation: + with newlines around it
          exerciseString = exerciseString.replace(/\s*\+\s*\n\s*/g, ' ');
          exerciseString = exerciseString.replace(/\\n\s*\+\s*\n\s*/g, '');
          
          // Remove any remaining standalone + operators (with spaces)
          exerciseString = exerciseString.replace(/\s*\+\s*/g, ' ');
          
          // Clean up multiple spaces
          exerciseString = exerciseString.replace(/\s{2,}/g, ' ');
          
          // Step 3: Replace escaped characters with their actual values
          // Handle \\n (literal backslash-n) -> newline
          // Handle \\' (literal backslash-quote) -> quote
          // Handle \\" (literal backslash-double-quote) -> double quote
          exerciseString = exerciseString.replace(/\\n/g, '\n');
          exerciseString = exerciseString.replace(/\\'/g, "'");
          exerciseString = exerciseString.replace(/\\"/g, '"');
          exerciseString = exerciseString.replace(/\\t/g, '\t');
          
          // Step 4: Clean up any remaining whitespace issues
          exerciseString = exerciseString.trim();
          
          // Step 5: Try to extract JSON array from the cleaned string
          // Find the first [ and last ] to get the array bounds
          const firstBracket = exerciseString.indexOf('[');
          const lastBracket = exerciseString.lastIndexOf(']');
          
          if (firstBracket === -1 || lastBracket === -1 || lastBracket <= firstBracket) {
            throw new Error('Could not find valid array brackets');
          }
          
          // Extract just the array content
          let jsonArrayString = exerciseString.substring(firstBracket, lastBracket + 1);
          
          console.log('📝 Cleaned JSON array (first 500 chars):', jsonArrayString.substring(0, 500));
          
          // Step 6: Parse the JSON
          const parsed = JSON.parse(jsonArrayString);
          if (Array.isArray(parsed)) {
            recommendationData.workoutPlan.exercises = parsed;
            console.log('✅ Successfully parsed exercises from cleaned string');
          } else {
            throw new Error('Parsed result is not an array');
          }
        } catch (e) {
          console.error('❌ Failed to parse exercises string:', e);
          console.error('📝 Full exercises string (first 1000 chars):', recommendationData.workoutPlan.exercises.substring(0, 1000));
          
          // Last resort: Try extracting all string literals and joining them
          try {
            console.log('⚠️ Attempting string literal extraction as last resort...');
            let jsString = recommendationData.workoutPlan.exercises;
            
            // Remove outer quotes if present
            jsString = jsString.replace(/^["']|["']$/g, '');
            
            // Extract all string literals (both single and double quoted, handling escapes)
            // Pattern matches: "..." or '...' including escaped quotes
            const stringLiterals = [];
            const stringPattern = /(["'])((?:(?:\\.)|(?!\1)[^\\])*?)\1/g;
            let match;
            
            while ((match = stringPattern.exec(jsString)) !== null) {
              const quote = match[1];
              const content = match[2];
              // Unescape the content
              const unescaped = content
                .replace(/\\n/g, '\n')
                .replace(/\\'/g, "'")
                .replace(/\\"/g, '"')
                .replace(/\\t/g, '\t')
                .replace(/\\\\/g, '\\');
              stringLiterals.push(unescaped);
            }
            
            if (stringLiterals.length > 0) {
              // Join all string literals together
              const reconstructed = stringLiterals.join('');
              console.log('📝 Reconstructed from string literals (first 500 chars):', reconstructed.substring(0, 500));
              
              // Try to find and parse the JSON array
              const arrayMatch = reconstructed.match(/\[[\s\S]*\]/);
              if (arrayMatch) {
                try {
                  const parsed = JSON.parse(arrayMatch[0]);
                  if (Array.isArray(parsed)) {
                    recommendationData.workoutPlan.exercises = parsed;
                    console.log('✅ Successfully parsed exercises using string literal extraction');
                  } else {
                    throw new Error('Parsed result is not an array');
                  }
                } catch (parseErr) {
                  console.error('❌ JSON parse failed on extracted array:', parseErr.message);
                  // Try one more time with additional cleaning
                  let arrayStr = arrayMatch[0];
                  // Remove any remaining artifacts
                  arrayStr = arrayStr.replace(/\s*\+\s*/g, ' ');
                  arrayStr = arrayStr.replace(/\n\s*\n/g, '\n');
                  try {
                    const parsed = JSON.parse(arrayStr);
                    if (Array.isArray(parsed)) {
                      recommendationData.workoutPlan.exercises = parsed;
                      console.log('✅ Successfully parsed exercises after additional cleaning');
                    } else {
                      throw new Error('Still not an array after cleaning');
                    }
                  } catch (finalErr) {
                    throw parseErr; // Throw original error
                  }
                }
              } else {
                throw new Error('No array found in reconstructed string');
              }
            } else {
              throw new Error('No string literals found to extract');
            }
          } catch (reconstructError) {
            console.error('❌ String literal extraction also failed:', reconstructError);
            console.error('📝 Full exercises string for debugging (first 2000 chars):', recommendationData.workoutPlan.exercises.substring(0, 2000));
            // If all parsing fails, set to empty array to prevent validation error
            recommendationData.workoutPlan.exercises = [];
            console.log('⚠️ Set exercises to empty array due to parsing failure');
          }
        }
      }
      
      // Ensure it's an array
      if (!Array.isArray(recommendationData.workoutPlan.exercises)) {
        console.error('❌ Exercises is not an array, converting...');
        recommendationData.workoutPlan.exercises = [];
      }
      
      // Validate each exercise object
      recommendationData.workoutPlan.exercises = recommendationData.workoutPlan.exercises.map((exercise, index) => {
        if (typeof exercise === 'string') {
          console.error(`⚠️ Exercise at index ${index} is a string, skipping...`);
          return null;
        }
        
        // Ensure muscleGroups is an array of strings
        let muscleGroups = [];
        if (Array.isArray(exercise.muscleGroups)) {
          muscleGroups = exercise.muscleGroups
            .map(mg => String(mg || '').trim())
            .filter(mg => mg.length > 0);
        } else if (exercise.muscleGroups) {
          // Handle case where it's a single string or non-array
          muscleGroups = [String(exercise.muscleGroups).trim()].filter(mg => mg.length > 0);
        }
        
        // Ensure equipment is an array of strings
        let equipment = ['none'];
        if (Array.isArray(exercise.equipment)) {
          equipment = exercise.equipment
            .map(eq => String(eq || '').trim())
            .filter(eq => eq.length > 0);
          if (equipment.length === 0) {
            equipment = ['none'];
          }
        } else if (exercise.equipment) {
          // Handle case where it's a single string or non-array
          const eqStr = String(exercise.equipment).trim();
          equipment = eqStr.length > 0 ? [eqStr] : ['none'];
        }
        
        // Ensure all required fields are present
        return {
          name: String(exercise.name || `Exercise ${index + 1}`).trim(),
          duration: Number(exercise.duration) || 10,
          calories: Number(exercise.calories) || 0,
          type: String(exercise.type || 'cardio').trim(),
          instructions: String(exercise.instructions || '').trim(),
          sets: exercise.sets != null ? Number(exercise.sets) : null,
          reps: String(exercise.reps || '10').trim(),
          restTime: exercise.restTime != null ? Number(exercise.restTime) : null,
          difficulty: String(exercise.difficulty || 'beginner').trim(),
          muscleGroups: muscleGroups,
          equipment: equipment
        };
      }).filter(ex => ex !== null); // Remove null entries
    }
    
    // Validate mealPlan structure
    if (recommendationData.mealPlan) {
      ['breakfast', 'lunch', 'dinner', 'snacks'].forEach(mealType => {
        if (recommendationData.mealPlan[mealType] && !Array.isArray(recommendationData.mealPlan[mealType])) {
          console.error(`⚠️ ${mealType} is not an array, converting...`);
          recommendationData.mealPlan[mealType] = [];
        }
      });
      
      // CRITICAL: Filter out meals that violate dietary preferences (especially vegan/vegetarian)
      if (user.dietaryPreferences && user.dietaryPreferences.length > 0) {
        const originalCount = {
          breakfast: recommendationData.mealPlan.breakfast?.length || 0,
          lunch: recommendationData.mealPlan.lunch?.length || 0,
          dinner: recommendationData.mealPlan.dinner?.length || 0,
          snacks: recommendationData.mealPlan.snacks?.length || 0
        };
        
        // Log meals before filtering for debugging
        if (user.dietaryPreferences.includes('vegan') || user.dietaryPreferences.includes('vegetarian')) {
          console.log(`🔍 Checking ${user.dietaryPreferences.join(', ')} compliance before filtering...`);
          ['breakfast', 'lunch', 'dinner', 'snacks'].forEach(category => {
            if (recommendationData.mealPlan[category]) {
              recommendationData.mealPlan[category].forEach(meal => {
                console.log(`  - ${category}: "${meal.name}"`);
              });
            }
          });
        }
        
        recommendationData.mealPlan = filterMealPlanByDietaryPreferences(
          recommendationData.mealPlan,
          user.dietaryPreferences
        );
        
        const filteredCount = {
          breakfast: recommendationData.mealPlan.breakfast?.length || 0,
          lunch: recommendationData.mealPlan.lunch?.length || 0,
          dinner: recommendationData.mealPlan.dinner?.length || 0,
          snacks: recommendationData.mealPlan.snacks?.length || 0
        };
        
        const totalRemoved = 
          (originalCount.breakfast - filteredCount.breakfast) +
          (originalCount.lunch - filteredCount.lunch) +
          (originalCount.dinner - filteredCount.dinner) +
          (originalCount.snacks - filteredCount.snacks);
        
        if (totalRemoved > 0) {
          console.log(`🚫 CRITICAL: Filtered out ${totalRemoved} meal(s) that violated ${user.dietaryPreferences.join(', ')} dietary preferences`);
          console.log(`📊 Meal counts - Before: ${JSON.stringify(originalCount)}, After: ${JSON.stringify(filteredCount)}`);
          
          // If all meals were filtered out, log a warning
          if (filteredCount.breakfast === 0 && filteredCount.lunch === 0 && 
              filteredCount.dinner === 0 && filteredCount.snacks === 0) {
            console.error(`❌ CRITICAL: ALL meals were filtered out! AI generated non-compliant recommendations.`);
          }
        } else {
          console.log(`✅ All meals comply with ${user.dietaryPreferences.join(', ')} dietary preferences`);
        }
      }
    }
    
    // Final validation: Ensure exercises is an array before saving
    if (recommendationData.workoutPlan && recommendationData.workoutPlan.exercises) {
      if (!Array.isArray(recommendationData.workoutPlan.exercises)) {
        console.error('❌ CRITICAL: exercises is still not an array after parsing! Type:', typeof recommendationData.workoutPlan.exercises);
        console.error('📝 Value:', JSON.stringify(recommendationData.workoutPlan.exercises).substring(0, 500));
        recommendationData.workoutPlan.exercises = [];
      } else {
        console.log('✅ Final validation: exercises is an array with', recommendationData.workoutPlan.exercises.length, 'items');
      }
    }
    
    console.log('✅ Successfully parsed and validated recommendation data');
    } catch (parseError) {
      console.error('❌ Failed to parse OpenAI recommendation response:', parseError);
      console.error('📝 Response content (first 500 chars):', content ? content.substring(0, 500) : 'No content');
      console.error('📝 Full response length:', content ? content.length : 0);
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

  // Delete any existing recommendation for today before saving new one (if forceNew or if one exists)
  if (forceNew) {
    await Recommendation.deleteMany({
      userId: user._id,
      date: { $gte: today }
    });
    console.log(`🗑️ Deleted existing recommendations before saving new ones (forceNew=true)`);
  } else {
    // Check if recommendation exists and update it instead of creating duplicate
    const existing = await Recommendation.findOne({
      userId: user._id,
      date: { $gte: today }
    });
    
    if (existing) {
      // Update existing recommendation with new ChatGPT-generated content
      existing.mealPlan = recommendationData.mealPlan;
      existing.workoutPlan = recommendationData.workoutPlan;
      existing.hydrationGoal = recommendationData.hydrationGoal;
      existing.insights = recommendationData.insights || [];
      existing.aiVersion = process.env.OPENAI_MODEL || 'gpt-4o';
      existing.mlMetadata = {
        userType: context.user.userType,
        usedFavoriteFoods: context.user.favoriteFoods.slice(0, 3),
        adaptedForUserType: true
      };
      await existing.save();
      console.log(`✅ Updated existing recommendation with new ChatGPT-generated meals and workouts`);
      return existing;
    }
  }

  // Save new recommendation with ML metadata
  const recommendation = new Recommendation({
    userId: user._id,
    date: today,
    type: 'meal',
    mealPlan: recommendationData.mealPlan,
    workoutPlan: recommendationData.workoutPlan,
    hydrationGoal: recommendationData.hydrationGoal,
    insights: recommendationData.insights || [],
    aiVersion: process.env.OPENAI_MODEL || 'gpt-4o',
    // Add ML metadata
    mlMetadata: {
      userType: context.user.userType,
      usedFavoriteFoods: context.user.favoriteFoods.slice(0, 3),
      adaptedForUserType: true
    }
  });

  await recommendation.save();
  
  console.log('✅ New recommendation saved with fresh ChatGPT-generated meals and workouts');

  return recommendation;
  } catch (openaiError) {
    console.error('❌ OpenAI API error:', openaiError);
    console.error('❌ Error details:', {
      message: openaiError.message,
      status: openaiError.status,
      statusCode: openaiError.status,
      code: openaiError.code,
      type: openaiError.type
    });
    
    // Check for specific error types
    if (openaiError.message?.includes('API key') || 
        openaiError.message?.includes('not configured') ||
        openaiError.status === 401 ||
        openaiError.code === 'invalid_api_key') {
      throw new Error('AI recommendation service is not configured. Please set OPENAI_API_KEY environment variable. Get your API key at https://platform.openai.com/api-keys');
    }
    
    if (openaiError.message?.includes('timeout') || openaiError.code === 'timeout') {
      throw new Error('AI recommendation request timed out. Please try again.');
    }
    
    if (openaiError.message?.includes('model') && openaiError.message?.includes('not found') || 
        openaiError.status === 404 ||
        openaiError.code === 'model_not_found') {
      throw new Error('OpenAI model not available. Please check the model name or API access.');
    }
    
    if (openaiError.status === 429 || openaiError.code === 'rate_limit_exceeded') {
      throw new Error('AI recommendation service is currently busy. Please try again in a moment.');
    }
    
    // For other errors, throw to be handled by the route handler
    throw new Error(`AI recommendation error: ${openaiError.message || 'Unknown error'}. Please check backend logs for details.`);
  }
}

export default router;

