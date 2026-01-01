import express from 'express';
import jwt from 'jsonwebtoken';
import User from '../models/User.js';
import { authMiddleware } from '../middleware/authMiddleware.js';

const router = express.Router();

// Register
router.post('/register', async (req, res) => {
  try {
    const { name, email, password, goals, activityLevel, dietaryPreferences, allergies, fastingPreference } = req.body;

    console.log('🔵 Registration request received:', { 
      name: name?.substring(0, 10) + '...', 
      email: email?.substring(0, 10) + '...',
      hasPassword: !!password 
    });

    if (!name || !email || !password) {
      console.log('❌ Registration failed: Missing required fields');
      return res.status(400).json({ message: 'Name, email, and password are required' });
    }

    if (password.length < 8) {
      console.log('❌ Registration failed: Password too short');
      return res.status(400).json({ message: 'Password must be at least 8 characters' });
    }

    // Check if user exists
    const existingUser = await User.findOne({ email: email.toLowerCase() });
    if (existingUser) {
      console.log('❌ Registration failed: User already exists');
      return res.status(400).json({ message: 'User already exists' });
    }

    // Create user with 3-day free trial
    const now = new Date();
    const trialEndDate = new Date(now);
    trialEndDate.setDate(trialEndDate.getDate() + 3); // 3-day free trial
    
    const user = new User({
      name,
      email: email.toLowerCase(),
      passwordHash: password, // Will be hashed by pre-save hook
      goals: goals || 'maintain',
      activityLevel: activityLevel || 'moderate',
      dietaryPreferences: dietaryPreferences || [],
      allergies: allergies || [],
      fastingPreference: fastingPreference || 'none',
      subscription: {
        status: 'trial', // Start with trial status
        startDate: now,
        trialEndDate: trialEndDate,
        endDate: trialEndDate // Trial ends after 3 days
        // plan field is intentionally omitted during trial
      }
    });

    await user.save();
    console.log('✅ User created successfully in database:', {
      id: user._id.toString(),
      email: user.email,
      subscriptionStatus: user.subscription.status,
      trialEndDate: user.subscription.trialEndDate
    });

    // Generate token
    const token = generateToken(user._id);

    res.status(201).json({
      accessToken: token,
      user: {
        id: user._id.toString(),
        name: user.name,
        email: user.email,
        goals: user.goals
      }
    });
  } catch (error) {
    console.error('❌ Registration error:', error);
    
    // Extract more detailed error message
    let errorMessage = 'Registration failed';
    if (error.name === 'ValidationError') {
      // Mongoose validation error
      const firstError = Object.values(error.errors)[0];
      errorMessage = firstError?.message || error.message || 'Validation failed';
      console.error('Validation errors:', error.errors);
    } else if (error.code === 11000) {
      // Duplicate key error (email already exists)
      errorMessage = 'User with this email already exists';
      console.error('Duplicate key error:', error.keyPattern);
    } else if (error.message) {
      errorMessage = error.message;
    }
    
    res.status(500).json({ 
      message: errorMessage,
      error: error.message 
    });
  }
});

// Login
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    console.log('🔵 Login request received for:', email?.substring(0, 10) + '...');

    if (!email || !password) {
      return res.status(400).json({ message: 'Email and password are required' });
    }

    // Find user
    const user = await User.findOne({ email: email.toLowerCase() });
    if (!user) {
      console.log('❌ Login failed: User not found');
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    // Check password
    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      console.log('❌ Login failed: Invalid password');
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    console.log('✅ Login successful for user:', user._id.toString());

    // Generate token
    const token = generateToken(user._id);

    res.json({
      accessToken: token,
      user: {
        id: user._id.toString(),
        name: user.name,
        email: user.email,
        goals: user.goals
      }
    });
  } catch (error) {
    console.error('❌ Login error:', error);
    res.status(500).json({ message: 'Login failed', error: error.message });
  }
});

// Get current user
router.get('/me', authMiddleware, async (req, res) => {
  try {
    console.log('🔵 /me request for user:', req.user._id.toString());
    res.json({
      id: req.user._id.toString(),
      name: req.user.name,
      email: req.user.email,
      goals: req.user.goals,
      activityLevel: req.user.activityLevel,
      dietaryPreferences: req.user.dietaryPreferences,
      allergies: req.user.allergies,
      fastingPreference: req.user.fastingPreference,
      appleHealthEnabled: req.user.appleHealthEnabled,
      subscription: req.user.subscription,
      metrics: req.user.metrics
    });
  } catch (error) {
    console.error('❌ Get user error:', error);
    res.status(500).json({ message: 'Failed to get user', error: error.message });
  }
});

// Update user profile
router.put('/profile', authMiddleware, async (req, res) => {
  try {
    const { name, goals, activityLevel, dietaryPreferences, allergies, fastingPreference, metrics } = req.body;

    const updateData = {};
    if (name) updateData.name = name;
    if (goals) updateData.goals = goals;
    if (activityLevel) updateData.activityLevel = activityLevel;
    if (dietaryPreferences) updateData.dietaryPreferences = dietaryPreferences;
    if (allergies) updateData.allergies = allergies;
    if (fastingPreference) updateData.fastingPreference = fastingPreference;
    if (metrics) updateData.metrics = { ...req.user.metrics, ...metrics };

    const user = await User.findByIdAndUpdate(
      req.user._id,
      { $set: updateData },
      { new: true }
    ).select('-passwordHash');

    res.json(user);
  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({ message: 'Failed to update profile', error: error.message });
  }
});

// Change password
router.post('/change-password', authMiddleware, async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;

    if (!currentPassword || !newPassword) {
      return res.status(400).json({ message: 'Current and new passwords are required' });
    }

    if (newPassword.length < 8) {
      return res.status(400).json({ message: 'New password must be at least 8 characters' });
    }

    const user = await User.findById(req.user._id);
    const isMatch = await user.comparePassword(currentPassword);
    
    if (!isMatch) {
      return res.status(401).json({ message: 'Current password is incorrect' });
    }

    user.passwordHash = newPassword; // Will be hashed by pre-save hook
    await user.save();

    res.json({ message: 'Password changed successfully' });
  } catch (error) {
    console.error('Change password error:', error);
    res.status(500).json({ message: 'Failed to change password', error: error.message });
  }
});

// Sign in with Apple
router.post('/apple', async (req, res) => {
  try {
    const { idToken, userIdentifier, email, name } = req.body;

    if (!idToken || !userIdentifier) {
      return res.status(400).json({ message: 'Apple ID token and user identifier are required' });
    }

    // Verify Apple ID token (in production, you should verify with Apple's servers)
    // For now, we'll trust the token from the client and use the userIdentifier
    // In production, use: https://appleid.apple.com/auth/keys to verify the token
    
    // Check if user exists by Apple ID
    let user = await User.findOne({ appleId: userIdentifier });

    if (user) {
      // Existing user - generate token
      const token = generateToken(user._id);
      return res.json({
        accessToken: token,
        user: {
          id: user._id.toString(),
          name: user.name,
          email: user.email,
          goals: user.goals
        }
      });
    }

    // New user - check if email already exists
    if (email) {
      const existingUser = await User.findOne({ email: email.toLowerCase() });
      if (existingUser) {
        // Link Apple ID to existing account
        existingUser.appleId = userIdentifier;
        if (name && !existingUser.name) {
          existingUser.name = name;
        }
        await existingUser.save();
        
        const token = generateToken(existingUser._id);
        return res.json({
          accessToken: token,
          user: {
            id: existingUser._id.toString(),
            name: existingUser.name,
            email: existingUser.email,
            goals: existingUser.goals
          }
        });
      }
    }

    // Create new user with Apple ID and 3-day free trial
    const now = new Date();
    const trialEndDate = new Date(now);
    trialEndDate.setDate(trialEndDate.getDate() + 3); // 3-day free trial
    
    user = new User({
      name: name || 'Apple User',
      email: email ? email.toLowerCase() : `${userIdentifier}@apple.privaterelay.app`,
      appleId: userIdentifier,
      // No passwordHash for Apple users
      goals: 'maintain',
      activityLevel: 'moderate',
      dietaryPreferences: [],
      allergies: [],
      fastingPreference: 'none',
      subscription: {
        status: 'trial', // Start with trial status
        startDate: now,
        trialEndDate: trialEndDate,
        endDate: trialEndDate // Trial ends after 3 days
      }
    });

    await user.save();

    // Generate token
    const token = generateToken(user._id);

    res.status(201).json({
      accessToken: token,
      user: {
        id: user._id.toString(),
        name: user.name,
        email: user.email,
        goals: user.goals
      }
    });
  } catch (error) {
    console.error('Apple Sign In error:', error);
    
    let errorMessage = 'Apple Sign In failed';
    if (error.code === 11000) {
      // Duplicate key error
      if (error.keyPattern?.appleId) {
        errorMessage = 'This Apple ID is already associated with another account';
      } else if (error.keyPattern?.email) {
        errorMessage = 'This email is already associated with another account';
      }
    } else if (error.message) {
      errorMessage = error.message;
    }
    
    res.status(500).json({ 
      message: errorMessage,
      error: error.message 
    });
  }
});

// Export user data
router.get('/export', authMiddleware, async (req, res) => {
  try {
    const user = await User.findById(req.user._id)
      .populate('meals')
      .populate('fastingSessions')
      .select('-passwordHash');
    
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Get all user data
    const Meal = (await import('../models/Meal.js')).default;
    const FastingSession = (await import('../models/FastingSession.js')).default;
    const WaterLog = (await import('../models/WaterLog.js')).default;
    const WeightLog = (await import('../models/WeightLog.js')).default;

    const [meals, fastingSessions, waterLogs, weightLogs] = await Promise.all([
      Meal.find({ userId: req.user._id }).lean(),
      FastingSession.find({ userId: req.user._id }).lean(),
      WaterLog.find({ userId: req.user._id }).lean(),
      WeightLog.find({ userId: req.user._id }).lean()
    ]);

    const exportData = {
      user: {
        id: user._id.toString(),
        name: user.name,
        email: user.email,
        goals: user.goals,
        activityLevel: user.activityLevel,
        dietaryPreferences: user.dietaryPreferences,
        allergies: user.allergies,
        fastingPreference: user.fastingPreference,
        metrics: user.metrics,
        subscription: user.subscription,
        createdAt: user.createdAt,
        updatedAt: user.updatedAt
      },
      meals: meals.map(m => ({
        ...m,
        _id: m._id.toString(),
        userId: m.userId?.toString()
      })),
      fastingSessions: fastingSessions.map(f => ({
        ...f,
        _id: f._id.toString(),
        userId: f.userId?.toString()
      })),
      waterLogs: waterLogs.map(w => ({
        ...w,
        _id: w._id.toString(),
        userId: w.userId?.toString()
      })),
      weightLogs: weightLogs.map(w => ({
        ...w,
        _id: w._id.toString(),
        userId: w.userId?.toString()
      })),
      exportDate: new Date().toISOString()
    };

    res.json(exportData);
  } catch (error) {
    console.error('Export data error:', error);
    res.status(500).json({ message: 'Failed to export data', error: error.message });
  }
});

// Delete account
router.delete('/account', authMiddleware, async (req, res) => {
  try {
    const user = await User.findById(req.user._id);
    
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Delete all associated data
    const Meal = (await import('../models/Meal.js')).default;
    const FastingSession = (await import('../models/FastingSession.js')).default;
    const WaterLog = (await import('../models/WaterLog.js')).default;
    const WeightLog = (await import('../models/WeightLog.js')).default;

    await Promise.all([
      Meal.deleteMany({ userId: req.user._id }),
      FastingSession.deleteMany({ userId: req.user._id }),
      WaterLog.deleteMany({ userId: req.user._id }),
      WeightLog.deleteMany({ userId: req.user._id })
    ]);

    // Delete user account
    await user.deleteOne();

    res.json({ message: 'Account deleted successfully' });
  } catch (error) {
    console.error('Delete account error:', error);
    res.status(500).json({ message: 'Failed to delete account', error: error.message });
  }
});

// Helper function
function generateToken(userId) {
  const secret = process.env.JWT_SECRET;
  if (!secret) {
    throw new Error('JWT_SECRET not configured');
  }
  return jwt.sign({ id: userId }, secret, {
    expiresIn: process.env.JWT_EXPIRES_IN || '7d'
  });
}

export default router;
