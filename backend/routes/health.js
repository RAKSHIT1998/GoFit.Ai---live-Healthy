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

// Log water/liquid
router.post('/water', authMiddleware, async (req, res) => {
  try {
    const { amount, beverageType, beverageName, calories, timestamp } = req.body;

    if (!amount || amount <= 0) {
      return res.status(400).json({ message: 'Valid amount is required' });
    }

    const log = new WaterLog({
      userId: req.user._id,
      amount,
      beverageType: beverageType || 'water',
      beverageName: beverageName || '',
      calories: calories || 0,
      timestamp: timestamp ? new Date(timestamp) : new Date(),
      source: 'manual'
    });

    await log.save();

    res.status(201).json(log);
  } catch (error) {
    console.error('Log water error:', error);
    res.status(500).json({ message: 'Failed to log liquid', error: error.message });
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

// Get water history
router.get('/water', authMiddleware, async (req, res) => {
  try {
    const { limit = 100, startDate, endDate } = req.query;

    const query = { userId: req.user._id };
    
    if (startDate || endDate) {
      query.timestamp = {};
      if (startDate) query.timestamp.$gte = new Date(startDate);
      if (endDate) query.timestamp.$lte = new Date(endDate);
    }

    const logs = await WaterLog.find(query)
      .sort({ timestamp: -1 })
      .limit(parseInt(limit));

    res.json(logs);
  } catch (error) {
    console.error('Get water history error:', error);
    res.status(500).json({ message: 'Failed to get water history', error: error.message });
  }
});

// Get health statistics
router.get('/stats', authMiddleware, async (req, res) => {
  try {
    const { days = 30 } = req.query;
    const daysBack = parseInt(days);
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - daysBack);
    startDate.setHours(0, 0, 0, 0);

    const user = await User.findById(req.user._id);
    
    // Get health data
    const healthData = user.healthData?.dailySteps || [];
    const filteredData = healthData.filter(entry => {
      const entryDate = new Date(entry.date);
      return entryDate >= startDate;
    });

    // Calculate averages
    const totalSteps = filteredData.reduce((sum, entry) => sum + (entry.steps || 0), 0);
    const totalCalories = filteredData.reduce((sum, entry) => sum + (entry.activeCalories || 0), 0);
    const avgSteps = filteredData.length > 0 ? totalSteps / filteredData.length : 0;
    const avgCalories = filteredData.length > 0 ? totalCalories / filteredData.length : 0;

    // Get water logs
    const waterLogs = await WaterLog.find({
      userId: req.user._id,
      timestamp: { $gte: startDate }
    });
    const totalWater = waterLogs.reduce((sum, log) => sum + log.amount, 0);
    const avgWater = waterLogs.length > 0 ? totalWater / daysBack : 0;

    // Get weight logs
    const weightLogs = await WeightLog.find({
      userId: req.user._id,
      timestamp: { $gte: startDate }
    }).sort({ timestamp: -1 });

    const firstWeight = weightLogs.length > 0 ? weightLogs[weightLogs.length - 1].weightKg : null;
    const lastWeight = weightLogs.length > 0 ? weightLogs[0].weightKg : null;
    const weightChange = firstWeight && lastWeight ? lastWeight - firstWeight : null;

    res.json({
      period: {
        days: daysBack,
        startDate: startDate,
        endDate: new Date()
      },
      steps: {
        total: totalSteps,
        average: Math.round(avgSteps),
        daysWithData: filteredData.length
      },
      calories: {
        total: totalCalories,
        average: Math.round(avgCalories),
        daysWithData: filteredData.length
      },
      water: {
        total: totalWater,
        average: Math.round(avgWater * 10) / 10,
        daysWithData: waterLogs.length
      },
      weight: {
        current: lastWeight,
        start: firstWeight,
        change: weightChange,
        records: weightLogs.length
      }
    });
  } catch (error) {
    console.error('Get health stats error:', error);
    res.status(500).json({ message: 'Failed to get health statistics', error: error.message });
  }
});

export default router;

