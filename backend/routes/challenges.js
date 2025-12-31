import express from 'express';
import Challenge from '../models/Challenge.js';
import { authMiddleware } from '../middleware/authMiddleware.js';

const router = express.Router();

// Create challenge
router.post('/create', authMiddleware, async (req, res) => {
  try {
    const { name, description, type, target, startDate, endDate, milestones, isPublic } = req.body;

    if (!name || !type || !target || !startDate || !endDate) {
      return res.status(400).json({ message: 'Name, type, target, startDate, and endDate are required' });
    }

    const challenge = new Challenge({
      userId: req.user._id,
      name,
      description,
      type,
      target: {
        ...target,
        currentValue: 0
      },
      startDate: new Date(startDate),
      endDate: new Date(endDate),
      milestones: milestones || [],
      isPublic: isPublic || false,
      status: 'active'
    });

    await challenge.save();

    res.status(201).json(challenge);
  } catch (error) {
    console.error('Create challenge error:', error);
    res.status(500).json({ message: 'Failed to create challenge', error: error.message });
  }
});

// Get challenges
router.get('/list', authMiddleware, async (req, res) => {
  try {
    const { status, type } = req.query;

    const query = { userId: req.user._id };

    if (status) query.status = status;
    if (type) query.type = type;

    const challenges = await Challenge.find(query)
      .sort({ startDate: -1 });

    res.json(challenges);
  } catch (error) {
    console.error('Get challenges error:', error);
    res.status(500).json({ message: 'Failed to get challenges', error: error.message });
  }
});

// Get active challenges
router.get('/active', authMiddleware, async (req, res) => {
  try {
    const challenges = await Challenge.find({
      userId: req.user._id,
      status: 'active'
    }).sort({ startDate: -1 });

    res.json(challenges);
  } catch (error) {
    console.error('Get active challenges error:', error);
    res.status(500).json({ message: 'Failed to get active challenges', error: error.message });
  }
});

// Update challenge progress
router.post('/:challengeId/progress', authMiddleware, async (req, res) => {
  try {
    const { value, notes } = req.body;

    const challenge = await Challenge.findOne({
      _id: req.params.challengeId,
      userId: req.user._id
    });

    if (!challenge) {
      return res.status(404).json({ message: 'Challenge not found' });
    }

    // Update current value
    challenge.target.currentValue = value || challenge.target.currentValue;

    // Add progress entry
    challenge.progress.push({
      date: new Date(),
      value: value || challenge.target.currentValue,
      notes
    });

    // Check milestones
    challenge.milestones.forEach(milestone => {
      if (!milestone.achieved && challenge.target.currentValue >= milestone.targetValue) {
        milestone.achieved = true;
        milestone.achievedDate = new Date();
      }
    });

    // Check if challenge is completed
    if (challenge.target.currentValue >= challenge.target.targetValue && challenge.status === 'active') {
      challenge.status = 'completed';
    }

    await challenge.save();

    res.json(challenge);
  } catch (error) {
    console.error('Update progress error:', error);
    res.status(500).json({ message: 'Failed to update progress', error: error.message });
  }
});

// Update challenge status
router.put('/:challengeId/status', authMiddleware, async (req, res) => {
  try {
    const { status } = req.body;

    const challenge = await Challenge.findOne({
      _id: req.params.challengeId,
      userId: req.user._id
    });

    if (!challenge) {
      return res.status(404).json({ message: 'Challenge not found' });
    }

    challenge.status = status;
    await challenge.save();

    res.json(challenge);
  } catch (error) {
    console.error('Update status error:', error);
    res.status(500).json({ message: 'Failed to update status', error: error.message });
  }
});

// Delete challenge
router.delete('/:challengeId', authMiddleware, async (req, res) => {
  try {
    const challenge = await Challenge.findOne({
      _id: req.params.challengeId,
      userId: req.user._id
    });

    if (!challenge) {
      return res.status(404).json({ message: 'Challenge not found' });
    }

    await challenge.deleteOne();

    res.json({ message: 'Challenge deleted successfully' });
  } catch (error) {
    console.error('Delete challenge error:', error);
    res.status(500).json({ message: 'Failed to delete challenge', error: error.message });
  }
});

export default router;


