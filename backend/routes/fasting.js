import express from 'express';
import FastingSession from '../models/FastingSession.js';
import { authMiddleware } from '../middleware/authMiddleware.js';

const router = express.Router();

// Start fasting
router.post('/start', authMiddleware, async (req, res) => {
  try {
    const { targetHours = 16 } = req.body;

    // Check if there's an active session
    const activeSession = await FastingSession.findOne({
      userId: req.user._id,
      status: 'active'
    });

    if (activeSession) {
      return res.status(400).json({ message: 'Fasting session already active' });
    }

    const session = new FastingSession({
      userId: req.user._id,
      startTime: new Date(),
      targetHours,
      status: 'active'
    });

    await session.save();

    res.status(201).json(session);
  } catch (error) {
    console.error('Start fasting error:', error);
    res.status(500).json({ message: 'Failed to start fasting', error: error.message });
  }
});

// End fasting
router.post('/end', authMiddleware, async (req, res) => {
  try {
    const session = await FastingSession.findOne({
      userId: req.user._id,
      status: 'active'
    });

    if (!session) {
      return res.status(404).json({ message: 'No active fasting session' });
    }

    const endTime = new Date();
    const actualHours = (endTime - session.startTime) / (1000 * 60 * 60);

    session.endTime = endTime;
    session.actualHours = actualHours;
    session.status = 'completed';

    await session.save();

    res.json(session);
  } catch (error) {
    console.error('End fasting error:', error);
    res.status(500).json({ message: 'Failed to end fasting', error: error.message });
  }
});

// Get current fasting status
router.get('/current', authMiddleware, async (req, res) => {
  try {
    const session = await FastingSession.findOne({
      userId: req.user._id,
      status: 'active'
    }).sort({ startTime: -1 });

    if (!session) {
      return res.json({ status: 'not_fasting' });
    }

    const now = new Date();
    const elapsedHours = (now - session.startTime) / (1000 * 60 * 60);
    const remainingHours = Math.max(0, session.targetHours - elapsedHours);

    res.json({
      status: 'fasting',
      startTime: session.startTime,
      targetHours: session.targetHours,
      elapsedHours,
      remainingHours,
      progress: Math.min(100, (elapsedHours / session.targetHours) * 100)
    });
  } catch (error) {
    console.error('Get fasting status error:', error);
    res.status(500).json({ message: 'Failed to get fasting status', error: error.message });
  }
});

// Get fasting history
router.get('/history', authMiddleware, async (req, res) => {
  try {
    const { limit = 30, skip = 0 } = req.query;

    const sessions = await FastingSession.find({
      userId: req.user._id
    })
      .sort({ startTime: -1 })
      .limit(parseInt(limit))
      .skip(parseInt(skip));

    res.json(sessions);
  } catch (error) {
    console.error('Get fasting history error:', error);
    res.status(500).json({ message: 'Failed to get fasting history', error: error.message });
  }
});

// Get fasting statistics
router.get('/stats', authMiddleware, async (req, res) => {
  try {
    const { startDate, endDate } = req.query;

    const query = {
      userId: req.user._id,
      status: 'completed'
    };

    if (startDate || endDate) {
      query.startTime = {};
      if (startDate) query.startTime.$gte = new Date(startDate);
      if (endDate) query.startTime.$lte = new Date(endDate);
    }

    const sessions = await FastingSession.find(query);

    const stats = {
      totalSessions: sessions.length,
      totalHours: sessions.reduce((sum, s) => sum + (s.actualHours || 0), 0),
      averageHours: sessions.length > 0 
        ? sessions.reduce((sum, s) => sum + (s.actualHours || 0), 0) / sessions.length 
        : 0,
      longestFast: sessions.length > 0
        ? Math.max(...sessions.map(s => s.actualHours || 0))
        : 0,
      currentStreak: 0 // TODO: Calculate streak
    };

    res.json(stats);
  } catch (error) {
    console.error('Get fasting stats error:', error);
    res.status(500).json({ message: 'Failed to get fasting stats', error: error.message });
  }
});

export default router;

