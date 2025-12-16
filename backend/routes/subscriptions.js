import express from 'express';
import User from '../models/User.js';
import { authMiddleware } from '../middleware/authMiddleware.js';
import verifyReceipt from 'apple-receipt-verify';

const router = express.Router();

// Verify Apple receipt
router.post('/verify', authMiddleware, async (req, res) => {
  try {
    const { receiptData, productId } = req.body;

    if (!receiptData) {
      return res.status(400).json({ message: 'Receipt data is required' });
    }

    // Verify with Apple
    const options = {
      receipt: receiptData,
      secret: process.env.APPLE_SHARED_SECRET,
      production: process.env.NODE_ENV === 'production',
      excludeOldTransactions: false
    };

    const result = await verifyReceipt(options);

    if (result.status !== 0) {
      return res.status(400).json({ message: 'Invalid receipt', status: result.status });
    }

    // Process receipt
    const latestReceipt = result.latest_receipt_info?.[result.latest_receipt_info.length - 1];
    const transactionId = latestReceipt?.transaction_id;
    const originalTransactionId = latestReceipt?.original_transaction_id;
    const expiresDate = latestReceipt?.expires_date_ms 
      ? new Date(parseInt(latestReceipt.expires_date_ms))
      : null;

    const isTrial = latestReceipt?.is_trial_period === 'true';
    const isActive = expiresDate && expiresDate > new Date();

    // Update user subscription
    const user = await User.findById(req.user._id);
    
    user.subscription = {
      status: isActive ? (isTrial ? 'trial' : 'active') : 'expired',
      plan: productId.includes('yearly') ? 'yearly' : 'monthly',
      startDate: new Date(),
      endDate: expiresDate,
      trialEndDate: isTrial ? expiresDate : null,
      appleTransactionId: transactionId,
      appleOriginalTransactionId: originalTransactionId
    };

    await user.save();

    res.json({
      isValid: true,
      subscriptionStatus: user.subscription.status,
      plan: user.subscription.plan,
      expiresDate: expiresDate
    });
  } catch (error) {
    console.error('Verify receipt error:', error);
    res.status(500).json({ message: 'Failed to verify receipt', error: error.message });
  }
});

// Get subscription status
router.get('/status', authMiddleware, async (req, res) => {
  try {
    const user = await User.findById(req.user._id);
    
    // Check if subscription is still valid
    if (user.subscription.endDate && user.subscription.endDate < new Date()) {
      user.subscription.status = 'expired';
      await user.save();
    }

    res.json({
      hasActiveSubscription: ['trial', 'active'].includes(user.subscription.status),
      subscription: user.subscription
    });
  } catch (error) {
    console.error('Get subscription status error:', error);
    res.status(500).json({ message: 'Failed to get subscription status', error: error.message });
  }
});

// Cancel subscription
router.post('/cancel', authMiddleware, async (req, res) => {
  try {
    const user = await User.findById(req.user._id);
    user.subscription.status = 'cancelled';
    await user.save();

    res.json({ message: 'Subscription cancelled' });
  } catch (error) {
    console.error('Cancel subscription error:', error);
    res.status(500).json({ message: 'Failed to cancel subscription', error: error.message });
  }
});

export default router;

