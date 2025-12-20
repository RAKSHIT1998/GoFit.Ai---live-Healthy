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

    // Get user first to check trial status
    const user = await User.findById(req.user._id);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    const expiresDateStr = transaction.expiresDate;
    const expiresDate = expiresDateStr ? new Date(expiresDateStr) : null;
    const isActive = expiresDate && expiresDate > new Date();
    
    // Check if transaction is revoked
    const isRevoked = transaction.revocationDate !== null && transaction.revocationDate !== undefined;
    
    // Determine if trial - check if user had a trial status before purchase
    const purchaseDate = transaction.purchaseDate ? new Date(transaction.purchaseDate) : new Date();
    const wasInTrial = user.subscription?.status === 'trial';
    
    // If user was in trial and just purchased, calculate new end date
    // Otherwise, check if it's within first 3 days (StoreKit trial period)
    const daysSincePurchase = (new Date() - purchaseDate) / (1000 * 60 * 60 * 24);
    const isTrial = wasInTrial || (daysSincePurchase <= 3 && isActive);
    
    // Calculate subscription end date based on plan
    let subscriptionEndDate = expiresDate;
    if (expiresDate) {
      // StoreKit provides the expiration date, use it
      subscriptionEndDate = expiresDate;
    } else {
      // Fallback: calculate based on plan
      subscriptionEndDate = new Date(purchaseDate);
      if (productId.includes('yearly')) {
        subscriptionEndDate.setFullYear(subscriptionEndDate.getFullYear() + 1);
      } else {
        subscriptionEndDate.setMonth(subscriptionEndDate.getMonth() + 1);
      }
    }

    // If user was in trial and now purchasing, transition to active
    // If still in trial period from StoreKit, keep as trial, otherwise mark as active
    const newStatus = isRevoked ? 'cancelled' : (isActive ? (isTrial ? 'trial' : 'active') : 'expired');
    
    user.subscription = {
      status: newStatus,
      plan: productId.includes('yearly') ? 'yearly' : 'monthly',
      startDate: purchaseDate,
      endDate: subscriptionEndDate,
      trialEndDate: isTrial && wasInTrial ? user.subscription.trialEndDate : (isTrial ? subscriptionEndDate : null),
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
    
    const now = new Date();
    
    // Check if trial has expired
    if (user.subscription.status === 'trial' && user.subscription.trialEndDate && user.subscription.trialEndDate < now) {
      user.subscription.status = 'expired';
      await user.save();
    }
    
    // Check if subscription has expired
    if (user.subscription.endDate && user.subscription.endDate < now && user.subscription.status !== 'cancelled') {
      user.subscription.status = 'expired';
      await user.save();
    }

    res.json({
      hasActiveSubscription: ['trial', 'active'].includes(user.subscription.status),
      subscription: user.subscription,
      isInTrial: user.subscription.status === 'trial',
      trialDaysRemaining: user.subscription.trialEndDate 
        ? Math.max(0, Math.ceil((user.subscription.trialEndDate - now) / (1000 * 60 * 60 * 24)))
        : 0
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

