import express from 'express';
import User from '../models/User.js';
import WaterLog from '../models/WaterLog.js';
import WeightLog from '../models/WeightLog.js';
import { authMiddleware } from '../middleware/authMiddleware.js';

const router = express.Router();

// Sync Apple Health data
router.post('/sync', authMiddleware, async (req, res) => {
  try {
    const { steps, activeCalories, heartRate, date } = req.body;

    const user = await User.findById(req.user._id);
    
    if (!user.healthData) {
      user.healthData = { lastSyncDate: new Date(), dailySteps: [] };
    }

    const syncDate = date ? new Date(date) : new Date();
    syncDate.setHours(0, 0, 0, 0);

    // Update or create daily entry
    const existingEntry = user.healthData.dailySteps.find(
      entry => entry.date.getTime() === syncDate.getTime()
    );

    if (existingEntry) {
      if (steps !== undefined) existingEntry.steps = steps;
      if (activeCalories !== undefined) existingEntry.activeCalories = activeCalories;
      if (heartRate) {
        existingEntry.heartRate = {
          resting: heartRate.resting || existingEntry.heartRate?.resting,
          average: heartRate.average || existingEntry.heartRate?.average
        };
      }
    } else {
      user.healthData.dailySteps.push({
        date: syncDate,
        steps: steps || 0,
        activeCalories: activeCalories || 0,
        heartRate: heartRate || { resting: null, average: null }
      });
    }

    user.healthData.lastSyncDate = new Date();
    user.appleHealthEnabled = true;
    await user.save();

    res.json({ message: 'Health data synced successfully' });
  } catch (error) {
    console.error('Sync health data error:', error);
    res.status(500).json({ message: 'Failed to sync health data', error: error.message });
  }
});

// Get health summary
router.get('/summary', authMiddleware, async (req, res) => {
  try {
    const { startDate, endDate } = req.query;

    const user = await User.findById(req.user._id);
    
    let dailySteps = user.healthData?.dailySteps || [];
    
    if (startDate || endDate) {
      dailySteps = dailySteps.filter(entry => {
        const entryDate = new Date(entry.date);
        if (startDate && entryDate < new Date(startDate)) return false;
        if (endDate && entryDate > new Date(endDate)) return false;
        return true;
      });
    }

    // Get today's data
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const todayEntry = dailySteps.find(
      entry => new Date(entry.date).getTime() === today.getTime()
    );

    // Get water logs
    const waterQuery = { userId: user._id };
    if (startDate) waterQuery.timestamp = { $gte: new Date(startDate) };
    if (endDate) {
      if (!waterQuery.timestamp) waterQuery.timestamp = {};
      waterQuery.timestamp.$lte = new Date(endDate);
    }

    const waterLogs = await WaterLog.find(waterQuery);
    const todayWater = waterLogs
      .filter(log => {
        const logDate = new Date(log.timestamp);
        return logDate.getTime() >= today.getTime();
      })
      .reduce((sum, log) => sum + log.amount, 0);

    res.json({
      today: {
        steps: todayEntry?.steps || 0,
        activeCalories: todayEntry?.activeCalories || 0,
        heartRate: todayEntry?.heartRate || { resting: null, average: null },
        water: todayWater
      },
      history: dailySteps,
      lastSyncDate: user.healthData?.lastSyncDate
    });
  } catch (error) {
    console.error('Get health summary error:', error);
    res.status(500).json({ message: 'Failed to get health summary', error: error.message });
  }
});

// Log water
router.post('/water', authMiddleware, async (req, res) => {
  try {
    const { amount, timestamp } = req.body;

    if (!amount || amount <= 0) {
      return res.status(400).json({ message: 'Valid amount is required' });
    }

    const log = new WaterLog({
      userId: req.user._id,
      amount,
      timestamp: timestamp ? new Date(timestamp) : new Date(),
      source: 'manual'
    });

    await log.save();

    res.status(201).json(log);
  } catch (error) {
    console.error('Log water error:', error);
    res.status(500).json({ message: 'Failed to log water', error: error.message });
  }
});

// Log weight
router.post('/weight', authMiddleware, async (req, res) => {
  try {
    const { weightKg, timestamp, notes } = req.body;

    if (!weightKg || weightKg <= 0) {
      return res.status(400).json({ message: 'Valid weight is required' });
    }

    const log = new WeightLog({
      userId: req.user._id,
      weightKg,
      timestamp: timestamp ? new Date(timestamp) : new Date(),
      notes
    });

    await log.save();

    // Update user's current weight
    const user = await User.findById(req.user._id);
    user.metrics = { ...user.metrics, weightKg };
    await user.save();

    res.status(201).json(log);
  } catch (error) {
    console.error('Log weight error:', error);
    res.status(500).json({ message: 'Failed to log weight', error: error.message });
  }
});

// Get weight history
router.get('/weight', authMiddleware, async (req, res) => {
  try {
    const { limit = 100 } = req.query;

    const logs = await WeightLog.find({ userId: req.user._id })
      .sort({ timestamp: -1 })
      .limit(parseInt(limit));

    res.json(logs);
  } catch (error) {
    console.error('Get weight history error:', error);
    res.status(500).json({ message: 'Failed to get weight history', error: error.message });
  }
});

export default router;

