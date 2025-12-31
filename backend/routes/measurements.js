import express from 'express';
import BodyMeasurement from '../models/BodyMeasurement.js';
import { authMiddleware } from '../middleware/authMiddleware.js';

const router = express.Router();

// Save measurement
router.post('/save', authMiddleware, async (req, res) => {
  try {
    const { weight, bodyFat, muscleMass, measurements, notes, photoId, timestamp } = req.body;

    const measurement = new BodyMeasurement({
      userId: req.user._id,
      weight: weight ? parseFloat(weight) : null,
      bodyFat: bodyFat ? parseFloat(bodyFat) : null,
      muscleMass: muscleMass ? parseFloat(muscleMass) : null,
      measurements: measurements || {},
      notes,
      photoId,
      timestamp: timestamp ? new Date(timestamp) : new Date()
    });

    await measurement.save();

    res.status(201).json(measurement);
  } catch (error) {
    console.error('Save measurement error:', error);
    res.status(500).json({ message: 'Failed to save measurement', error: error.message });
  }
});

// Get measurements
router.get('/list', authMiddleware, async (req, res) => {
  try {
    const { startDate, endDate, limit = 100 } = req.query;

    const query = { userId: req.user._id };

    if (startDate || endDate) {
      query.timestamp = {};
      if (startDate) query.timestamp.$gte = new Date(startDate);
      if (endDate) query.timestamp.$lte = new Date(endDate);
    }

    const measurements = await BodyMeasurement.find(query)
      .sort({ timestamp: -1 })
      .limit(parseInt(limit));

    res.json(measurements);
  } catch (error) {
    console.error('Get measurements error:', error);
    res.status(500).json({ message: 'Failed to get measurements', error: error.message });
  }
});

// Get latest measurement
router.get('/latest', authMiddleware, async (req, res) => {
  try {
    const measurement = await BodyMeasurement.findOne({
      userId: req.user._id
    }).sort({ timestamp: -1 });

    if (!measurement) {
      return res.status(404).json({ message: 'No measurements found' });
    }

    res.json(measurement);
  } catch (error) {
    console.error('Get latest measurement error:', error);
    res.status(500).json({ message: 'Failed to get latest measurement', error: error.message });
  }
});

// Get measurement trends
router.get('/trends', authMiddleware, async (req, res) => {
  try {
    const { days = 30 } = req.query;

    const startDate = new Date();
    startDate.setDate(startDate.getDate() - parseInt(days));

    const measurements = await BodyMeasurement.find({
      userId: req.user._id,
      timestamp: { $gte: startDate }
    }).sort({ timestamp: 1 });

    const trends = {
      weight: measurements.map(m => ({
        date: m.timestamp,
        value: m.weight
      })).filter(m => m.value !== null && m.value !== undefined),
      bodyFat: measurements.map(m => ({
        date: m.timestamp,
        value: m.bodyFat
      })).filter(m => m.value !== null && m.value !== undefined),
      measurements: {
        chest: measurements.map(m => ({
          date: m.timestamp,
          value: m.measurements?.chest
        })).filter(m => m.value !== null && m.value !== undefined),
        waist: measurements.map(m => ({
          date: m.timestamp,
          value: m.measurements?.waist
        })).filter(m => m.value !== null && m.value !== undefined),
        hips: measurements.map(m => ({
          date: m.timestamp,
          value: m.measurements?.hips
        })).filter(m => m.value !== null && m.value !== undefined)
      }
    };

    res.json(trends);
  } catch (error) {
    console.error('Get trends error:', error);
    res.status(500).json({ message: 'Failed to get trends', error: error.message });
  }
});

// Delete measurement
router.delete('/:measurementId', authMiddleware, async (req, res) => {
  try {
    const measurement = await BodyMeasurement.findOne({
      _id: req.params.measurementId,
      userId: req.user._id
    });

    if (!measurement) {
      return res.status(404).json({ message: 'Measurement not found' });
    }

    await measurement.deleteOne();

    res.json({ message: 'Measurement deleted successfully' });
  } catch (error) {
    console.error('Delete measurement error:', error);
    res.status(500).json({ message: 'Failed to delete measurement', error: error.message });
  }
});

export default router;


