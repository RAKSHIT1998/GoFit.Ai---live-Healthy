import express from 'express';
import Recipe from '../models/Recipe.js';
import { authMiddleware } from '../middleware/authMiddleware.js';

const router = express.Router();

// Create recipe
router.post('/create', authMiddleware, async (req, res) => {
  try {
    const recipe = new Recipe({
      userId: req.user._id,
      ...req.body,
      source: 'user'
    });

    await recipe.save();

    res.status(201).json(recipe);
  } catch (error) {
    console.error('Create recipe error:', error);
    res.status(500).json({ message: 'Failed to create recipe', error: error.message });
  }
});

// Get recipes
router.get('/list', authMiddleware, async (req, res) => {
  try {
    const { mealType, cuisineType, isFavorite, tags, limit = 50, skip = 0 } = req.query;

    const query = { userId: req.user._id };

    if (mealType) query.mealType = mealType;
    if (cuisineType) query.cuisineType = cuisineType;
    if (isFavorite === 'true') query.isFavorite = true;
    if (tags) {
      query.tags = { $in: Array.isArray(tags) ? tags : [tags] };
    }

    const recipes = await Recipe.find(query)
      .sort({ createdAt: -1 })
      .limit(parseInt(limit))
      .skip(parseInt(skip));

    res.json(recipes);
  } catch (error) {
    console.error('Get recipes error:', error);
    res.status(500).json({ message: 'Failed to get recipes', error: error.message });
  }
});

// Get favorite recipes
router.get('/favorites', authMiddleware, async (req, res) => {
  try {
    const recipes = await Recipe.find({
      userId: req.user._id,
      isFavorite: true
    }).sort({ createdAt: -1 });

    res.json(recipes);
  } catch (error) {
    console.error('Get favorites error:', error);
    res.status(500).json({ message: 'Failed to get favorites', error: error.message });
  }
});

// Toggle favorite
router.post('/:recipeId/favorite', authMiddleware, async (req, res) => {
  try {
    const recipe = await Recipe.findOne({
      _id: req.params.recipeId,
      userId: req.user._id
    });

    if (!recipe) {
      return res.status(404).json({ message: 'Recipe not found' });
    }

    recipe.isFavorite = !recipe.isFavorite;
    await recipe.save();

    res.json(recipe);
  } catch (error) {
    console.error('Toggle favorite error:', error);
    res.status(500).json({ message: 'Failed to toggle favorite', error: error.message });
  }
});

// Update recipe
router.put('/:recipeId', authMiddleware, async (req, res) => {
  try {
    const recipe = await Recipe.findOne({
      _id: req.params.recipeId,
      userId: req.user._id
    });

    if (!recipe) {
      return res.status(404).json({ message: 'Recipe not found' });
    }

    Object.assign(recipe, req.body);
    await recipe.save();

    res.json(recipe);
  } catch (error) {
    console.error('Update recipe error:', error);
    res.status(500).json({ message: 'Failed to update recipe', error: error.message });
  }
});

// Mark as cooked
router.post('/:recipeId/cooked', authMiddleware, async (req, res) => {
  try {
    const recipe = await Recipe.findOne({
      _id: req.params.recipeId,
      userId: req.user._id
    });

    if (!recipe) {
      return res.status(404).json({ message: 'Recipe not found' });
    }

    recipe.timesCooked = (recipe.timesCooked || 0) + 1;
    recipe.lastCooked = new Date();
    await recipe.save();

    res.json(recipe);
  } catch (error) {
    console.error('Mark cooked error:', error);
    res.status(500).json({ message: 'Failed to mark cooked', error: error.message });
  }
});

// Delete recipe
router.delete('/:recipeId', authMiddleware, async (req, res) => {
  try {
    const recipe = await Recipe.findOne({
      _id: req.params.recipeId,
      userId: req.user._id
    });

    if (!recipe) {
      return res.status(404).json({ message: 'Recipe not found' });
    }

    await recipe.deleteOne();

    res.json({ message: 'Recipe deleted successfully' });
  } catch (error) {
    console.error('Delete recipe error:', error);
    res.status(500).json({ message: 'Failed to delete recipe', error: error.message });
  }
});

export default router;


