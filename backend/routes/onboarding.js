import express from 'express';
import User from '../models/User.js';
import { authMiddleware } from '../middleware/authMiddleware.js';
import { calculateCalories, calculateMacros, calculateCaloriesForTargetWeight } from '../utils/calorieCalculator.js';

const router = express.Router();

// Get calorie recommendations for authenticated user
router.get('/calories', authMiddleware, async (req, res) => {
  try {
    const user = await User.findById(req.user._id);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    const calorieData = calculateCalories(user);
    if (!calorieData) {
      return res.status(400).json({ 
        message: 'Incomplete user data. Please provide weight and height in your profile.' 
      });
    }

    const macros = calculateMacros(calorieData.recommendedCalories, user.dietaryPreferences);

    // Update user metrics with calculated values
    user.metrics = {
      ...user.metrics,
      targetCalories: calorieData.recommendedCalories,
      targetProtein: macros.protein,
      targetCarbs: macros.carbs,
      targetFat: macros.fat
    };
    await user.save();

    res.json({
      success: true,
      calories: calorieData,
      macros,
      message: 'Calorie recommendations calculated based on your profile'
    });
  } catch (error) {
    console.error('❌ Calculate calories error:', error);
    res.status(500).json({ message: 'Failed to calculate calories', error: error.message });
  }
});

// Auto-calculate and save calories after onboarding (called after registration)
router.post('/calculate-calories', authMiddleware, async (req, res) => {
  try {
    const user = await User.findById(req.user._id);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    const calorieData = calculateCalories(user);
    if (!calorieData) {
      return res.status(400).json({ 
        message: 'Incomplete user data. Please provide weight and height in your profile.' 
      });
    }

    const macros = calculateMacros(calorieData.recommendedCalories, user.dietaryPreferences);

    // Update user metrics with calculated values
    user.metrics = {
      ...user.metrics,
      targetCalories: calorieData.recommendedCalories,
      targetProtein: macros.protein,
      targetCarbs: macros.carbs,
      targetFat: macros.fat
    };
    await user.save();

    console.log('✅ Auto-calculated calories for user:', {
      userId: user._id.toString(),
      calories: calorieData.recommendedCalories,
      goal: calorieData.goal
    });

    res.json({
      success: true,
      calories: calorieData,
      macros,
      message: 'Calorie recommendations automatically calculated and saved'
    });
  } catch (error) {
    console.error('❌ Auto-calculate calories error:', error);
    res.status(500).json({ message: 'Failed to calculate calories', error: error.message });
  }
});

// Calculate calories and protein based on target weight (for onboarding)
router.post('/target-weight-calories', async (req, res) => {
  try {
    const { weightKg, heightCm, targetWeightKg, goal, activityLevel, dietaryPreferences = [] } = req.body;
    
    if (!weightKg || !heightCm || !targetWeightKg) {
      return res.status(400).json({ 
        message: 'Weight, height, and target weight are required' 
      });
    }

    // Create a temporary user object for calculation
    const tempUser = {
      metrics: {
        weightKg: parseFloat(weightKg),
        heightCm: parseFloat(heightCm),
        goals: goal || 'maintain',
        activityLevel: activityLevel || 'moderate',
        age: 30 // Default age, can be made configurable
      },
      dietaryPreferences: Array.isArray(dietaryPreferences) ? dietaryPreferences : []
    };

    const calorieData = calculateCaloriesForTargetWeight(tempUser, parseFloat(targetWeightKg));
    if (!calorieData) {
      return res.status(400).json({ 
        message: 'Failed to calculate calories. Please check your input.' 
      });
    }

    const macros = calculateMacros(calorieData.recommendedCalories, tempUser.dietaryPreferences);

    res.json({
      success: true,
      calories: calorieData,
      macros,
      recommendations: {
        dailyCalories: calorieData.recommendedCalories,
        dailyProtein: macros.protein,
        dailyCarbs: macros.carbs,
        dailyFat: macros.fat,
        proteinPercent: macros.proteinPercent,
        carbsPercent: macros.carbsPercent,
        fatPercent: macros.fatPercent
      },
      message: `Based on your goal to ${goal === 'lose' ? 'lose' : goal === 'gain' ? 'gain' : 'maintain'} weight, here are your personalized recommendations.`
    });
  } catch (error) {
    console.error('❌ Calculate target weight calories error:', error);
    res.status(500).json({ message: 'Failed to calculate calories', error: error.message });
  }
});

export default router;
