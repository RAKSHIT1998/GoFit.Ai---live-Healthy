import express from 'express';
import User from '../models/User.js';
import Meal from '../models/Meal.js';
import FastingSession from '../models/FastingSession.js';
import { authMiddleware } from '../middleware/authMiddleware.js';

const router = express.Router();

// Admin middleware (check if user is admin)
const adminMiddleware = async (req, res, next) => {
  // TODO: Add admin check logic
  // For now, allow if user exists
  next();
};

// Get all users
router.get('/users', authMiddleware, adminMiddleware, async (req, res) => {
  try {
    const { limit = 50, skip = 0, search } = req.query;

    const query = {};
    if (search) {
      query.$or = [
        { name: { $regex: search, $options: 'i' } },
        { email: { $regex: search, $options: 'i' } }
      ];
    }

    const users = await User.find(query)
      .select('-passwordHash')
      .sort({ createdAt: -1 })
      .limit(parseInt(limit))
      .skip(parseInt(skip));

    const total = await User.countDocuments(query);

    res.json({
      users,
      total,
      limit: parseInt(limit),
      skip: parseInt(skip)
    });
  } catch (error) {
    console.error('Get users error:', error);
    res.status(500).json({ message: 'Failed to get users', error: error.message });
  }
});

// Get user details
router.get('/users/:userId', authMiddleware, adminMiddleware, async (req, res) => {
  try {
    const user = await User.findById(req.params.userId).select('-passwordHash');
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    const mealCount = await Meal.countDocuments({ userId: user._id });
    const fastingCount = await FastingSession.countDocuments({ userId: user._id });

    res.json({
      user,
      stats: {
        mealCount,
        fastingCount
      }
    });
  } catch (error) {
    console.error('Get user details error:', error);
    res.status(500).json({ message: 'Failed to get user details', error: error.message });
  }
});

// Disable user
router.post('/users/:userId/disable', authMiddleware, adminMiddleware, async (req, res) => {
  try {
    const user = await User.findById(req.params.userId);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Add disabled flag or delete account
    await user.deleteOne();

    res.json({ message: 'User disabled successfully' });
  } catch (error) {
    console.error('Disable user error:', error);
    res.status(500).json({ message: 'Failed to disable user', error: error.message });
  }
});

// Get metrics
router.get('/metrics', authMiddleware, adminMiddleware, async (req, res) => {
  try {
    const totalUsers = await User.countDocuments();
    const activeSubscriptions = await User.countDocuments({
      'subscription.status': { $in: ['trial', 'active'] }
    });
    const totalMeals = await Meal.countDocuments();
    const totalFastingSessions = await FastingSession.countDocuments({ status: 'completed' });

    // Daily active users (last 24 hours)
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    const dailyActiveUsers = await User.countDocuments({
      updatedAt: { $gte: yesterday }
    });

    res.json({
      totalUsers,
      activeSubscriptions,
      totalMeals,
      totalFastingSessions,
      dailyActiveUsers,
      timestamp: new Date()
    });
  } catch (error) {
    console.error('Get metrics error:', error);
    res.status(500).json({ message: 'Failed to get metrics', error: error.message });
  }
});

// Get food scan logs
router.get('/scans', authMiddleware, adminMiddleware, async (req, res) => {
  try {
    const { limit = 100, skip = 0, startDate, endDate } = req.query;

    const query = {};
    if (startDate || endDate) {
      query.timestamp = {};
      if (startDate) query.timestamp.$gte = new Date(startDate);
      if (endDate) query.timestamp.$lte = new Date(endDate);
    }

    const meals = await Meal.find(query)
      .populate('userId', 'name email')
      .sort({ timestamp: -1 })
      .limit(parseInt(limit))
      .skip(parseInt(skip));

    res.json(meals);
  } catch (error) {
    console.error('Get scan logs error:', error);
    res.status(500).json({ message: 'Failed to get scan logs', error: error.message });
  }
});

export default router;

