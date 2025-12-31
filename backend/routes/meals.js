import express from 'express';
import Meal from '../models/Meal.js';
import { authMiddleware } from '../middleware/authMiddleware.js';
import mlService from '../services/mlService.js';

const router = express.Router();

// Save meal
router.post('/save', authMiddleware, async (req, res) => {
  try {
    const { items, imageUrl, imageKey, totalCalories, totalProtein, totalCarbs, totalFat, totalSugar, mealType, timestamp, aiVersion } = req.body;

    if (!items || !Array.isArray(items) || items.length === 0) {
      return res.status(400).json({ message: 'Items array is required' });
    }

    const meal = new Meal({
      userId: req.user._id,
      items,
      imageUrl,
      imageKey,
      totalCalories: totalCalories || items.reduce((sum, item) => sum + (item.calories || 0), 0),
      totalProtein: totalProtein || items.reduce((sum, item) => sum + (item.protein || 0), 0),
      totalCarbs: totalCarbs || items.reduce((sum, item) => sum + (item.carbs || 0), 0),
      totalFat: totalFat || items.reduce((sum, item) => sum + (item.fat || 0), 0),
      totalSugar: totalSugar || items.reduce((sum, item) => sum + (item.sugar || 0), 0),
      mealType: mealType || 'snack',
      timestamp: timestamp ? new Date(timestamp) : new Date(),
      aiVersion: aiVersion || 'unknown'
    });

    await meal.save();

    // Learn from this meal for ML (async, don't wait)
    mlService.learnFromMeal(meal, req.user._id).catch(err => {
      console.error('ML learning error (non-critical):', err);
    });

    res.status(201).json(meal);
  } catch (error) {
    console.error('Save meal error:', error);
    res.status(500).json({ message: 'Failed to save meal', error: error.message });
  }
});

// Get meals
router.get('/list', authMiddleware, async (req, res) => {
  try {
    const { startDate, endDate, limit = 50, skip = 0 } = req.query;

    const query = { userId: req.user._id };

    if (startDate || endDate) {
      query.timestamp = {};
      if (startDate) query.timestamp.$gte = new Date(startDate);
      if (endDate) query.timestamp.$lte = new Date(endDate);
    }

    const meals = await Meal.find(query)
      .sort({ timestamp: -1 })
      .limit(parseInt(limit))
      .skip(parseInt(skip));

    res.json(meals);
  } catch (error) {
    console.error('Get meals error:', error);
    res.status(500).json({ message: 'Failed to get meals', error: error.message });
  }
});

// Get today's summary
router.get('/summary/today', authMiddleware, async (req, res) => {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    const meals = await Meal.find({
      userId: req.user._id,
      timestamp: { $gte: today, $lt: tomorrow }
    });

    const summary = meals.reduce((acc, meal) => ({
      calories: acc.calories + (meal.totalCalories || 0),
      protein: acc.protein + (meal.totalProtein || 0),
      carbs: acc.carbs + (meal.totalCarbs || 0),
      fat: acc.fat + (meal.totalFat || 0),
      sugar: acc.sugar + (meal.totalSugar || 0),
      mealCount: acc.mealCount + 1
    }), { calories: 0, protein: 0, carbs: 0, fat: 0, sugar: 0, mealCount: 0 });

    res.json(summary);
  } catch (error) {
    console.error('Get summary error:', error);
    res.status(500).json({ message: 'Failed to get summary', error: error.message });
  }
});

// Delete meal
router.delete('/:mealId', authMiddleware, async (req, res) => {
  try {
    const meal = await Meal.findOne({
      _id: req.params.mealId,
      userId: req.user._id
    });

    if (!meal) {
      return res.status(404).json({ message: 'Meal not found' });
    }

    // TODO: Delete image from S3 if needed
    await meal.deleteOne();

    res.json({ message: 'Meal deleted successfully' });
  } catch (error) {
    console.error('Delete meal error:', error);
    res.status(500).json({ message: 'Failed to delete meal', error: error.message });
  }
});

// Batch sync (for offline support)
router.post('/sync', authMiddleware, async (req, res) => {
  try {
    const { meals } = req.body;

    if (!meals || !Array.isArray(meals)) {
      return res.status(400).json({ message: 'Meals array is required' });
    }

    const savedMeals = [];
    const errors = [];

    for (const mealData of meals) {
      try {
        const meal = new Meal({
          ...mealData,
          userId: req.user._id
        });
        await meal.save();
        savedMeals.push(meal);
      } catch (error) {
        errors.push({ meal: mealData, error: error.message });
      }
    }

    res.json({
      saved: savedMeals.length,
      errors: errors.length,
      details: errors
    });
  } catch (error) {
    console.error('Sync meals error:', error);
    res.status(500).json({ message: 'Failed to sync meals', error: error.message });
  }
});

export default router;

