import express from 'express';
import ProgressPhoto from '../models/ProgressPhoto.js';
import { authMiddleware } from '../middleware/authMiddleware.js';
import multer from 'multer';
import { uploadToS3, deleteFromS3 } from '../utils/s3.js';

const router = express.Router();
const upload = multer({ storage: multer.memoryStorage() });

// Upload progress photo
router.post('/photo', authMiddleware, upload.single('photo'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ message: 'Photo is required' });
    }

    const { photoType, weight, bodyFat, measurements, notes, tags } = req.body;

    // Upload to S3
    let imageUrl = null;
    let imageKey = null;
    
    try {
      const s3Result = await uploadToS3(req.file, `progress/${req.user._id}/`);
      if (s3Result) {
        imageUrl = s3Result.url;
        imageKey = s3Result.key;
      }
    } catch (s3Error) {
      console.error('S3 upload error:', s3Error);
      // Continue without S3 if not configured
    }

    const photo = new ProgressPhoto({
      userId: req.user._id,
      imageUrl: imageUrl || `data:${req.file.mimetype};base64,${req.file.buffer.toString('base64')}`,
      imageKey,
      photoType: photoType || 'front',
      weight: weight ? parseFloat(weight) : null,
      bodyFat: bodyFat ? parseFloat(bodyFat) : null,
      measurements: measurements ? JSON.parse(measurements) : {},
      notes,
      tags: tags ? JSON.parse(tags) : [],
      timestamp: new Date()
    });

    await photo.save();

    res.status(201).json(photo);
  } catch (error) {
    console.error('Upload progress photo error:', error);
    res.status(500).json({ message: 'Failed to upload photo', error: error.message });
  }
});

// Get progress photos
router.get('/photos', authMiddleware, async (req, res) => {
  try {
    const { startDate, endDate, photoType, limit = 50 } = req.query;

    const query = { userId: req.user._id };

    if (startDate || endDate) {
      query.timestamp = {};
      if (startDate) query.timestamp.$gte = new Date(startDate);
      if (endDate) query.timestamp.$lte = new Date(endDate);
    }

    if (photoType) {
      query.photoType = photoType;
    }

    const photos = await ProgressPhoto.find(query)
      .sort({ timestamp: -1 })
      .limit(parseInt(limit));

    res.json(photos);
  } catch (error) {
    console.error('Get progress photos error:', error);
    res.status(500).json({ message: 'Failed to get photos', error: error.message });
  }
});

// Delete progress photo
router.delete('/photo/:photoId', authMiddleware, async (req, res) => {
  try {
    const photo = await ProgressPhoto.findOne({
      _id: req.params.photoId,
      userId: req.user._id
    });

    if (!photo) {
      return res.status(404).json({ message: 'Photo not found' });
    }

    // Delete from S3 if exists
    if (photo.imageKey) {
      try {
        await deleteFromS3(photo.imageKey);
      } catch (s3Error) {
        console.error('S3 delete error:', s3Error);
      }
    }

    await photo.deleteOne();

    res.json({ message: 'Photo deleted successfully' });
  } catch (error) {
    console.error('Delete photo error:', error);
    res.status(500).json({ message: 'Failed to delete photo', error: error.message });
  }
});

export default router;


