import express from 'express';
import EducationContent from '../models/EducationContent.js';
import { authMiddleware } from '../middleware/authMiddleware.js';

const router = express.Router();

// Get education content
router.get('/list', authMiddleware, async (req, res) => {
  try {
    const { category, type, difficulty, featured, limit = 50, skip = 0 } = req.query;

    const query = { isPublished: true };

    if (category) query.category = category;
    if (type) query.type = type;
    if (difficulty) query.difficulty = difficulty;
    if (featured === 'true') query.isFeatured = true;

    const content = await EducationContent.find(query)
      .sort({ publishedDate: -1 })
      .limit(parseInt(limit))
      .skip(parseInt(skip));

    res.json(content);
  } catch (error) {
    console.error('Get education content error:', error);
    res.status(500).json({ message: 'Failed to get content', error: error.message });
  }
});

// Get featured content
router.get('/featured', authMiddleware, async (req, res) => {
  try {
    const content = await EducationContent.find({
      isPublished: true,
      isFeatured: true
    })
      .sort({ publishedDate: -1 })
      .limit(10);

    res.json(content);
  } catch (error) {
    console.error('Get featured content error:', error);
    res.status(500).json({ message: 'Failed to get featured content', error: error.message });
  }
});

// Get content by category
router.get('/category/:category', authMiddleware, async (req, res) => {
  try {
    const content = await EducationContent.find({
      category: req.params.category,
      isPublished: true
    })
      .sort({ publishedDate: -1 });

    res.json(content);
  } catch (error) {
    console.error('Get category content error:', error);
    res.status(500).json({ message: 'Failed to get category content', error: error.message });
  }
});

// Get single content
router.get('/:contentId', authMiddleware, async (req, res) => {
  try {
    const content = await EducationContent.findById(req.params.contentId);

    if (!content || !content.isPublished) {
      return res.status(404).json({ message: 'Content not found' });
    }

    // Increment views
    content.views = (content.views || 0) + 1;
    await content.save();

    res.json(content);
  } catch (error) {
    console.error('Get content error:', error);
    res.status(500).json({ message: 'Failed to get content', error: error.message });
  }
});

// Like content
router.post('/:contentId/like', authMiddleware, async (req, res) => {
  try {
    const content = await EducationContent.findById(req.params.contentId);

    if (!content) {
      return res.status(404).json({ message: 'Content not found' });
    }

    content.likes = (content.likes || 0) + 1;
    await content.save();

    res.json({ likes: content.likes });
  } catch (error) {
    console.error('Like content error:', error);
    res.status(500).json({ message: 'Failed to like content', error: error.message });
  }
});

export default router;


