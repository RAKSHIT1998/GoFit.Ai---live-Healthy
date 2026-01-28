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

    // Determine subscription status
    let newStatus;
    if (isRevoked) {
      newStatus = 'cancelled';
    } else if (!isActive) {
      newStatus = 'expired';
    } else if (isTrial) {
      newStatus = 'trial';
    } else {
      newStatus = 'active'; // Premium active subscription
    }
    
    // Calculate trial end date
    let trialEndDate = null;
    if (isTrial) {
      if (wasInTrial && user.subscription.trialEndDate) {
        // Keep existing trial end date if user was already in trial
        trialEndDate = user.subscription.trialEndDate;
      } else {
        // New trial - set end date to 3 days from purchase
        trialEndDate = new Date(purchaseDate);
        trialEndDate.setDate(trialEndDate.getDate() + 3);
      }
    }
    
    // Update user subscription
    user.subscription = {
      status: newStatus,
      plan: productId.includes('yearly') ? 'yearly' : 'monthly',
      startDate: purchaseDate,
      endDate: subscriptionEndDate,
      trialEndDate: trialEndDate,
      appleTransactionId: transaction.transactionID?.toString() || transactionId?.toString(),
      appleOriginalTransactionId: transaction.originalTransactionID?.toString(),
      cancelledAt: isRevoked ? new Date() : user.subscription?.cancelledAt
    };

    await user.save();

    // Calculate days remaining
    const now = new Date();
    const calculateDaysRemaining = (endDate) => {
      if (!endDate) return 0;
      const diff = endDate.getTime() - now.getTime();
      const days = Math.ceil(diff / (1000 * 60 * 60 * 24));
      return Math.max(0, days);
    };

    const trialDaysRemaining = trialEndDate ? calculateDaysRemaining(trialEndDate) : 0;
    const subscriptionDaysRemaining = subscriptionEndDate ? calculateDaysRemaining(subscriptionEndDate) : 0;

    console.log(`✅ Subscription verified for user ${user._id}: ${newStatus}, Plan: ${user.subscription.plan}`);
    if (trialDaysRemaining > 0) {
      console.log(`   Trial days remaining: ${trialDaysRemaining}`);
    }
    if (subscriptionDaysRemaining > 0) {
      console.log(`   Subscription days remaining: ${subscriptionDaysRemaining}`);
    }

    res.json({
      success: true,
      subscriptionStatus: user.subscription.status,
      plan: user.subscription.plan,
      expiresDate: expiresDate,
      trialDaysRemaining,
      subscriptionDaysRemaining,
      daysRemaining: isTrial ? trialDaysRemaining : subscriptionDaysRemaining,
      isPremiumActive: newStatus === 'active',
      isInTrial: newStatus === 'trial'
    });
  } catch (error) {
    console.error('Subscription sync error:', error);
    res.status(500).json({ 
      message: 'Failed to sync subscription', 
      error: error.message 
    });
  }
});

// Get subscription status with detailed days calculations
router.get('/status', authMiddleware, async (req, res) => {
  try {
    const user = await User.findById(req.user._id);
    
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    const now = new Date();
    
    // Initialize subscription if it doesn't exist
    if (!user.subscription) {
      user.subscription = {
        status: 'free',
        plan: undefined,
        startDate: null,
        endDate: null,
        trialEndDate: null,
        appleTransactionId: null,
        appleOriginalTransactionId: null
      };
      await user.save();
    }
    
    // Calculate days remaining helper function
    const calculateDaysRemaining = (endDate) => {
      if (!endDate) return 0;
      const diff = endDate.getTime() - now.getTime();
      const days = Math.ceil(diff / (1000 * 60 * 60 * 24));
      return Math.max(0, days);
    };
    
    // Check if trial has expired
    if (user.subscription.status === 'trial' && user.subscription.trialEndDate) {
      if (user.subscription.trialEndDate < now) {
        // Trial expired - check if they have an active paid subscription
        if (user.subscription.endDate && user.subscription.endDate > now) {
          // They have an active paid subscription, transition to active
          user.subscription.status = 'active';
          await user.save();
        } else {
          // No active subscription, mark as expired
          user.subscription.status = 'expired';
          await user.save();
        }
      }
    }
    
    // Check if subscription has expired (but not if cancelled)
    if (user.subscription.status === 'active' && user.subscription.endDate) {
      if (user.subscription.endDate < now) {
        // Subscription expired
        user.subscription.status = 'expired';
        await user.save();
      }
    }
    
    // Calculate days remaining for trial and subscription
    const trialDaysRemaining = user.subscription.trialEndDate 
      ? calculateDaysRemaining(user.subscription.trialEndDate)
      : 0;
    
    const subscriptionDaysRemaining = user.subscription.endDate 
      ? calculateDaysRemaining(user.subscription.endDate)
      : 0;
    
    // Determine if user is premium (active subscription, not trial or expired)
    const isPremiumActive = user.subscription.status === 'active';
    const isInTrial = user.subscription.status === 'trial';
    const isCancelled = user.subscription.status === 'cancelled';
    const isExpired = user.subscription.status === 'expired';
    const hasActiveSubscription = isPremiumActive || isInTrial;

    res.json({
      hasActiveSubscription,
      isPremiumActive,
      isInTrial,
      isCancelled,
      isExpired,
      subscription: {
        status: user.subscription.status,
        plan: user.subscription.plan,
        startDate: user.subscription.startDate,
        endDate: user.subscription.endDate,
        trialEndDate: user.subscription.trialEndDate,
        appleTransactionId: user.subscription.appleTransactionId,
        appleOriginalTransactionId: user.subscription.appleOriginalTransactionId
      },
      // Days calculations
      trialDaysRemaining,
      subscriptionDaysRemaining,
      // Additional info
      daysRemaining: isInTrial ? trialDaysRemaining : subscriptionDaysRemaining,
      // Status details
      statusDetails: {
        isPremium: isPremiumActive,
        isTrial: isInTrial,
        isCancelled: isCancelled,
        isExpired: isExpired,
        canAccessPremium: hasActiveSubscription
      }
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
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    // Mark subscription as cancelled
    // Note: User still has access until endDate
    user.subscription.status = 'cancelled';
    user.subscription.cancelledAt = new Date();
    await user.save();

    console.log(`✅ Subscription cancelled for user ${user._id}. Access until ${user.subscription.endDate}`);

    res.json({ 
      message: 'Subscription cancelled',
      subscription: user.subscription,
      // Calculate days remaining until cancellation takes effect
      daysRemaining: user.subscription.endDate 
        ? Math.max(0, Math.ceil((user.subscription.endDate - new Date()) / (1000 * 60 * 60 * 24)))
        : 0
    });
  } catch (error) {
    console.error('Cancel subscription error:', error);
    res.status(500).json({ message: 'Failed to cancel subscription', error: error.message });
  }
});

// Sync subscription status from StoreKit (called periodically)
router.post('/sync', authMiddleware, async (req, res) => {
  try {
    const user = await User.findById(req.user._id);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Bugfix:
    // Some users may not have `subscription` initialized yet (older accounts / edge cases).
    // Avoid crashing with "Cannot read property 'status' of undefined".
    if (!user.subscription) {
      user.subscription = {
        status: 'free',
        plan: null,
        startDate: null,
        endDate: null,
        trialEndDate: null,
        appleTransactionId: null,
        appleOriginalTransactionId: null,
        cancelledAt: null
      };
    }
    
    const now = new Date();
    let statusChanged = false;
    
    // Auto-update expired subscriptions
    if (user.subscription.status === 'trial' && user.subscription.trialEndDate && user.subscription.trialEndDate < now) {
      if (user.subscription.endDate && user.subscription.endDate > now) {
        user.subscription.status = 'active';
        statusChanged = true;
      } else {
        user.subscription.status = 'expired';
        statusChanged = true;
      }
    }
    
    if (user.subscription.status === 'active' && user.subscription.endDate && user.subscription.endDate < now) {
      user.subscription.status = 'expired';
      statusChanged = true;
    }
    
    if (statusChanged) {
      await user.save();
      console.log(`🔄 Subscription status auto-updated for user ${user._id}: ${user.subscription.status}`);
    }
    
    res.json({
      success: true,
      subscription: user.subscription,
      statusChanged
    });
  } catch (error) {
    console.error('Sync subscription error:', error);
    res.status(500).json({ message: 'Failed to sync subscription', error: error.message });
  }
});

export default router;

