import express from 'express';
import Analytics from '../models/Analytics.js';
import Meal from '../models/Meal.js';
import Workout from '../models/Workout.js';
import BodyMeasurement from '../models/BodyMeasurement.js';
import { authMiddleware } from '../middleware/authMiddleware.js';

const router = express.Router();

// Calculate and get analytics
router.get('/calculate', authMiddleware, async (req, res) => {
  try {
    const { period = 'weekly', startDate, endDate } = req.query;

    let start, end;
    if (startDate && endDate) {
      start = new Date(startDate);
      end = new Date(endDate);
    } else {
      // Default to current period
      end = new Date();
      start = new Date();
      
      switch (period) {
        case 'daily':
          start.setHours(0, 0, 0, 0);
          break;
        case 'weekly':
          start.setDate(start.getDate() - 7);
          break;
        case 'monthly':
          start.setMonth(start.getMonth() - 1);
          break;
        case 'yearly':
          start.setFullYear(start.getFullYear() - 1);
          break;
      }
    }

    // Get meals
    const meals = await Meal.find({
      userId: req.user._id,
      timestamp: { $gte: start, $lte: end }
    });

    // Get workouts
    const workouts = await Workout.find({
      userId: req.user._id,
      timestamp: { $gte: start, $lte: end }
    });

    // Get measurements
    const measurements = await BodyMeasurement.find({
      userId: req.user._id,
      timestamp: { $gte: start, $lte: end }
    }).sort({ timestamp: 1 });

    // Calculate nutrition stats
    const nutrition = {
      totalCalories: meals.reduce((sum, m) => sum + (m.totalCalories || 0), 0),
      totalProtein: meals.reduce((sum, m) => sum + (m.totalProtein || 0), 0),
      totalCarbs: meals.reduce((sum, m) => sum + (m.totalCarbs || 0), 0),
      totalFat: meals.reduce((sum, m) => sum + (m.totalFat || 0), 0),
      totalSugar: meals.reduce((sum, m) => sum + (m.totalSugar || 0), 0),
      mealCount: meals.length
    };

    const days = meals.length > 0 ? Math.max(1, Math.ceil((end - start) / (1000 * 60 * 60 * 24))) : 1;
    
    nutrition.averageCalories = nutrition.totalCalories / days;
    nutrition.averageProtein = nutrition.totalProtein / days;
    nutrition.averageCarbs = nutrition.totalCarbs / days;
    nutrition.averageFat = nutrition.totalFat / days;
    nutrition.averageSugar = nutrition.totalSugar / days;

    const totalMacros = nutrition.totalProtein + nutrition.totalCarbs + nutrition.totalFat;
    nutrition.macroDistribution = {
      protein: totalMacros > 0 ? (nutrition.totalProtein / totalMacros) * 100 : 0,
      carbs: totalMacros > 0 ? (nutrition.totalCarbs / totalMacros) * 100 : 0,
      fat: totalMacros > 0 ? (nutrition.totalFat / totalMacros) * 100 : 0
    };

    // Calculate fitness stats
    const fitness = {
      totalWorkouts: workouts.length,
      totalDuration: workouts.reduce((sum, w) => sum + (w.duration || 0), 0),
      totalCaloriesBurned: workouts.reduce((sum, w) => sum + (w.caloriesBurned || 0), 0),
      averageWorkoutDuration: workouts.length > 0 
        ? workouts.reduce((sum, w) => sum + (w.duration || 0), 0) / workouts.length 
        : 0,
      workoutTypes: {}
    };

    workouts.forEach(workout => {
      fitness.workoutTypes[workout.type] = (fitness.workoutTypes[workout.type] || 0) + 1;
    });

    // Calculate progress
    const progress = {};
    if (measurements.length >= 2) {
      const first = measurements[0];
      const last = measurements[measurements.length - 1];
      
      progress.weightChange = last.weight && first.weight ? last.weight - first.weight : null;
      progress.bodyFatChange = last.bodyFat && first.bodyFat ? last.bodyFat - first.bodyFat : null;
      
      if (last.measurements && first.measurements) {
        progress.measurementChanges = {
          chest: last.measurements.chest && first.measurements.chest 
            ? last.measurements.chest - first.measurements.chest : null,
          waist: last.measurements.waist && first.measurements.waist 
            ? last.measurements.waist - first.measurements.waist : null,
          hips: last.measurements.hips && first.measurements.hips 
            ? last.measurements.hips - first.measurements.hips : null
        };
      }
    }

    const analytics = {
      userId: req.user._id,
      period,
      date: end,
      nutrition,
      fitness,
      progress,
      goals: {
        caloriesGoal: req.user.metrics?.targetCalories || 2000,
        caloriesAchieved: nutrition.totalCalories,
        proteinGoal: req.user.metrics?.targetProtein || 0,
        proteinAchieved: nutrition.totalProtein
      },
      insights: []
    };

    // Generate insights
    if (nutrition.averageCalories < (req.user.metrics?.targetCalories || 2000) * 0.8) {
      analytics.insights.push('You\'re eating below your calorie target. Consider adding nutrient-dense foods.');
    }
    
    if (fitness.totalWorkouts < 3) {
      analytics.insights.push('Try to increase your workout frequency for better results.');
    }

    // Save analytics
    await Analytics.findOneAndUpdate(
      { userId: req.user._id, period, date: end },
      analytics,
      { upsert: true, new: true }
    );

    res.json(analytics);
  } catch (error) {
    console.error('Calculate analytics error:', error);
    res.status(500).json({ message: 'Failed to calculate analytics', error: error.message });
  }
});

// Get saved analytics
router.get('/saved', authMiddleware, async (req, res) => {
  try {
    const { period = 'weekly', limit = 10 } = req.query;

    const analytics = await Analytics.find({
      userId: req.user._id,
      period
    })
      .sort({ date: -1 })
      .limit(parseInt(limit));

    res.json(analytics);
  } catch (error) {
    console.error('Get saved analytics error:', error);
    res.status(500).json({ message: 'Failed to get analytics', error: error.message });
  }
});

export default router;


