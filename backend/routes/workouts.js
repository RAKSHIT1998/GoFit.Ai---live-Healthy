import express from 'express';
import Workout from '../models/Workout.js';
import { authMiddleware } from '../middleware/authMiddleware.js';

const router = express.Router();

// Save workout
router.post('/save', authMiddleware, async (req, res) => {
  try {
    const { name, type, duration, caloriesBurned, exercises, notes, rating, difficulty, location, timestamp } = req.body;

    if (!exercises || !Array.isArray(exercises) || exercises.length === 0) {
      return res.status(400).json({ message: 'Exercises array is required' });
    }

    const workout = new Workout({
      userId: req.user._id,
      name: name || 'Workout',
      type: type || 'strength',
      duration: duration || 0,
      caloriesBurned: caloriesBurned || 0,
      exercises,
      notes,
      rating,
      difficulty,
      location: location || 'gym',
      timestamp: timestamp ? new Date(timestamp) : new Date()
    });

    await workout.save();

    res.status(201).json(workout);
  } catch (error) {
    console.error('Save workout error:', error);
    res.status(500).json({ message: 'Failed to save workout', error: error.message });
  }
});

// Get workouts
router.get('/list', authMiddleware, async (req, res) => {
  try {
    const { startDate, endDate, type, limit = 50, skip = 0 } = req.query;

    const query = { userId: req.user._id };

    if (startDate || endDate) {
      query.timestamp = {};
      if (startDate) query.timestamp.$gte = new Date(startDate);
      if (endDate) query.timestamp.$lte = new Date(endDate);
    }

    if (type) {
      query.type = type;
    }

    const workouts = await Workout.find(query)
      .sort({ timestamp: -1 })
      .limit(parseInt(limit))
      .skip(parseInt(skip));

    res.json(workouts);
  } catch (error) {
    console.error('Get workouts error:', error);
    res.status(500).json({ message: 'Failed to get workouts', error: error.message });
  }
});

// Get workout statistics
router.get('/stats', authMiddleware, async (req, res) => {
  try {
    const { startDate, endDate } = req.query;

    const query = { userId: req.user._id };

    if (startDate || endDate) {
      query.timestamp = {};
      if (startDate) query.timestamp.$gte = new Date(startDate);
      if (endDate) query.timestamp.$lte = new Date(endDate);
    }

    const workouts = await Workout.find(query);

    const stats = {
      totalWorkouts: workouts.length,
      totalDuration: workouts.reduce((sum, w) => sum + (w.duration || 0), 0),
      totalCaloriesBurned: workouts.reduce((sum, w) => sum + (w.caloriesBurned || 0), 0),
      averageDuration: workouts.length > 0 
        ? workouts.reduce((sum, w) => sum + (w.duration || 0), 0) / workouts.length 
        : 0,
      workoutTypes: {},
      exercises: {}
    };

    workouts.forEach(workout => {
      // Count by type
      stats.workoutTypes[workout.type] = (stats.workoutTypes[workout.type] || 0) + 1;

      // Count exercises
      workout.exercises.forEach(exercise => {
        stats.exercises[exercise.name] = (stats.exercises[exercise.name] || 0) + 1;
      });
    });

    res.json(stats);
  } catch (error) {
    console.error('Get workout stats error:', error);
    res.status(500).json({ message: 'Failed to get stats', error: error.message });
  }
});

// Delete workout
router.delete('/:workoutId', authMiddleware, async (req, res) => {
  try {
    const workout = await Workout.findOne({
      _id: req.params.workoutId,
      userId: req.user._id
    });

    if (!workout) {
      return res.status(404).json({ message: 'Workout not found' });
    }

    await workout.deleteOne();

    res.json({ message: 'Workout deleted successfully' });
  } catch (error) {
    console.error('Delete workout error:', error);
    res.status(500).json({ message: 'Failed to delete workout', error: error.message });
  }
});

export default router;


