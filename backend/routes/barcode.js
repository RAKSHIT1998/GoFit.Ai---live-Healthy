import express from 'express';
import FoodProduct from '../models/FoodProduct.js';
import { authMiddleware } from '../middleware/authMiddleware.js';

const router = express.Router();

// Scan barcode (search or create)
router.post('/scan', authMiddleware, async (req, res) => {
  try {
    const { barcode } = req.body;

    if (!barcode) {
      return res.status(400).json({ message: 'Barcode is required' });
    }

    // Check if product exists
    let product = await FoodProduct.findOne({ barcode });

    if (product) {
      // Update scan count
      product.timesScanned = (product.timesScanned || 0) + 1;
      product.lastScanned = new Date();
      await product.save();

      return res.json(product);
    }

    // If not found, return null (frontend can prompt user to add manually)
    res.status(404).json({ message: 'Product not found. You can add it manually.' });
  } catch (error) {
    console.error('Scan barcode error:', error);
    res.status(500).json({ message: 'Failed to scan barcode', error: error.message });
  }
});

// Add product manually
router.post('/add', authMiddleware, async (req, res) => {
  try {
    const productData = req.body;

    if (!productData.name) {
      return res.status(400).json({ message: 'Product name is required' });
    }

    const product = new FoodProduct({
      ...productData,
      source: 'user',
      isVerified: false,
      timesScanned: 1,
      lastScanned: new Date()
    });

    await product.save();

    res.status(201).json(product);
  } catch (error) {
    console.error('Add product error:', error);
    res.status(500).json({ message: 'Failed to add product', error: error.message });
  }
});

// Search products
router.get('/search', authMiddleware, async (req, res) => {
  try {
    const { query, category, limit = 20 } = req.query;

    const searchQuery = {};

    if (query) {
      searchQuery.$text = { $search: query };
    }

    if (category) {
      searchQuery.category = category;
    }

    const products = await FoodProduct.find(searchQuery)
      .sort(query ? { score: { $meta: 'textScore' } } : { timesScanned: -1 })
      .limit(parseInt(limit));

    res.json(products);
  } catch (error) {
    console.error('Search products error:', error);
    res.status(500).json({ message: 'Failed to search products', error: error.message });
  }
});

// Get product by ID
router.get('/:productId', authMiddleware, async (req, res) => {
  try {
    const product = await FoodProduct.findById(req.params.productId);

    if (!product) {
      return res.status(404).json({ message: 'Product not found' });
    }

    res.json(product);
  } catch (error) {
    console.error('Get product error:', error);
    res.status(500).json({ message: 'Failed to get product', error: error.message });
  }
});

export default router;


