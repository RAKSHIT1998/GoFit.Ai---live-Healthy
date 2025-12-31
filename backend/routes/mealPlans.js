import express from 'express';
import MealPlan from '../models/MealPlan.js';
import { authMiddleware } from '../middleware/authMiddleware.js';

const router = express.Router();

// Create meal plan
router.post('/create', authMiddleware, async (req, res) => {
  try {
    const { name, startDate, endDate, meals, shoppingList } = req.body;

    if (!startDate || !endDate) {
      return res.status(400).json({ message: 'Start date and end date are required' });
    }

    // Deactivate existing active plans
    await MealPlan.updateMany(
      { userId: req.user._id, isActive: true },
      { isActive: false }
    );

    const mealPlan = new MealPlan({
      userId: req.user._id,
      name: name || 'My Meal Plan',
      startDate: new Date(startDate),
      endDate: new Date(endDate),
      meals: meals || [],
      shoppingList: shoppingList || [],
      isActive: true
    });

    await mealPlan.save();

    res.status(201).json(mealPlan);
  } catch (error) {
    console.error('Create meal plan error:', error);
    res.status(500).json({ message: 'Failed to create meal plan', error: error.message });
  }
});

// Get meal plans
router.get('/list', authMiddleware, async (req, res) => {
  try {
    const { activeOnly } = req.query;

    const query = { userId: req.user._id };
    if (activeOnly === 'true') {
      query.isActive = true;
    }

    const mealPlans = await MealPlan.find(query)
      .sort({ startDate: -1 });

    res.json(mealPlans);
  } catch (error) {
    console.error('Get meal plans error:', error);
    res.status(500).json({ message: 'Failed to get meal plans', error: error.message });
  }
});

// Get active meal plan
router.get('/active', authMiddleware, async (req, res) => {
  try {
    const mealPlan = await MealPlan.findOne({
      userId: req.user._id,
      isActive: true
    });

    if (!mealPlan) {
      return res.status(404).json({ message: 'No active meal plan found' });
    }

    res.json(mealPlan);
  } catch (error) {
    console.error('Get active meal plan error:', error);
    res.status(500).json({ message: 'Failed to get active meal plan', error: error.message });
  }
});

// Update meal plan
router.put('/:planId', authMiddleware, async (req, res) => {
  try {
    const mealPlan = await MealPlan.findOne({
      _id: req.params.planId,
      userId: req.user._id
    });

    if (!mealPlan) {
      return res.status(404).json({ message: 'Meal plan not found' });
    }

    const { name, meals, shoppingList, isActive } = req.body;

    if (name) mealPlan.name = name;
    if (meals) mealPlan.meals = meals;
    if (shoppingList) mealPlan.shoppingList = shoppingList;
    if (isActive !== undefined) mealPlan.isActive = isActive;

    await mealPlan.save();

    res.json(mealPlan);
  } catch (error) {
    console.error('Update meal plan error:', error);
    res.status(500).json({ message: 'Failed to update meal plan', error: error.message });
  }
});

// Mark meal as completed
router.post('/:planId/meal/:mealId/complete', authMiddleware, async (req, res) => {
  try {
    const mealPlan = await MealPlan.findOne({
      _id: req.params.planId,
      userId: req.user._id
    });

    if (!mealPlan) {
      return res.status(404).json({ message: 'Meal plan not found' });
    }

    const meal = mealPlan.meals.id(req.params.mealId);
    if (!meal) {
      return res.status(404).json({ message: 'Meal not found' });
    }

    meal.isCompleted = true;
    await mealPlan.save();

    res.json(mealPlan);
  } catch (error) {
    console.error('Mark meal complete error:', error);
    res.status(500).json({ message: 'Failed to mark meal complete', error: error.message });
  }
});

// Delete meal plan
router.delete('/:planId', authMiddleware, async (req, res) => {
  try {
    const mealPlan = await MealPlan.findOne({
      _id: req.params.planId,
      userId: req.user._id
    });

    if (!mealPlan) {
      return res.status(404).json({ message: 'Meal plan not found' });
    }

    await mealPlan.deleteOne();

    res.json({ message: 'Meal plan deleted successfully' });
  } catch (error) {
    console.error('Delete meal plan error:', error);
    res.status(500).json({ message: 'Failed to delete meal plan', error: error.message });
  }
});

export default router;


