import express from 'express';
import User from '../models/User.js';
import { authMiddleware } from '../middleware/authMiddleware.js';

const router = express.Router();

/**
 * StoreKit 2 verification happens on-device (iOS).
 * This endpoint syncs the already-verified subscription state to the backend.
 */
router.post('/verify', authMiddleware, async (req, res) => {
  try {
    const { transactionData, productId, transactionId } = req.body;

    if (!transactionData || !productId) {
      return res.status(400).json({ message: 'Transaction data and product ID are required' });
    }

    // Decode base64 transaction data
    let transaction;
    try {
      const decoded = Buffer.from(transactionData, 'base64').toString('utf-8');
      transaction = JSON.parse(decoded);
    } catch (error) {
      return res.status(400).json({ message: 'Invalid transaction data format' });
    }

    // Extract subscription information from StoreKit 2 transaction
    // StoreKit 2 transaction JSON structure:
    // - signedDate: ISO 8601 date string
    // - productID: product identifier
    // - transactionID: transaction ID
    // - originalTransactionID: original transaction ID
    // - purchaseDate: purchase date
    // - expiresDate: expiration date (for subscriptions)
    // - isUpgrade: boolean
    // - revocationDate: revocation date if refunded
    // - environment: "Production" or "Sandbox"

    const expiresDateStr = transaction.expiresDate;
    const expiresDate = expiresDateStr ? new Date(expiresDateStr) : null;
    const isActive = expiresDate && expiresDate > new Date();
    
    // Check if transaction is revoked
    const isRevoked = transaction.revocationDate !== null && transaction.revocationDate !== undefined;
    
    // Determine if trial (StoreKit 2 doesn't explicitly mark trials, but we can infer from product)
    // For now, we'll check if it's within the first 3 days as a trial indicator
    const purchaseDate = transaction.purchaseDate ? new Date(transaction.purchaseDate) : new Date();
    const daysSincePurchase = (new Date() - purchaseDate) / (1000 * 60 * 60 * 24);
    const isTrial = daysSincePurchase <= 3 && isActive;

    // Update user subscription
    const user = await User.findById(req.user._id);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    user.subscription = {
      status: isRevoked ? 'cancelled' : (isActive ? (isTrial ? 'trial' : 'active') : 'expired'),
      plan: productId.includes('yearly') ? 'yearly' : 'monthly',
      startDate: purchaseDate,
      endDate: expiresDate,
      trialEndDate: isTrial ? expiresDate : null,
      appleTransactionId: transaction.transactionID?.toString() || transactionId?.toString(),
      appleOriginalTransactionId: transaction.originalTransactionID?.toString()
    };

    await user.save();

    res.json({
      success: true,
      subscriptionStatus: user.subscription.status,
      plan: user.subscription.plan,
      expiresDate: expiresDate
    });
  } catch (error) {
    console.error('Subscription sync error:', error);
    res.status(500).json({ 
      message: 'Failed to sync subscription', 
      error: error.message 
    });
  }
});

// Get subscription status
router.get('/status', authMiddleware, async (req, res) => {
  try {
    const user = await User.findById(req.user._id);
    
    if (!user || !user.subscription) {
      return res.json({
        hasActiveSubscription: false,
        subscription: null
      });
    }
    
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

