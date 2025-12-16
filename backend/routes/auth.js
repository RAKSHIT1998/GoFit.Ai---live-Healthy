import express from 'express';
import jwt from 'jsonwebtoken';
import User from '../models/User.js';
import { authMiddleware } from '../middleware/authMiddleware.js';

const router = express.Router();

// Register
router.post('/register', async (req, res) => {
  try {
    const { name, email, password, goals, activityLevel, dietaryPreferences, allergies, fastingPreference } = req.body;

    if (!name || !email || !password) {
      return res.status(400).json({ message: 'Name, email, and password are required' });
    }

    if (password.length < 8) {
      return res.status(400).json({ message: 'Password must be at least 8 characters' });
    }

    // Check if user exists
    const existingUser = await User.findOne({ email: email.toLowerCase() });
    if (existingUser) {
      return res.status(400).json({ message: 'User already exists' });
    }

    // Create user
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
        status: 'free'
        // plan field is intentionally omitted for free users
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
    console.error('Registration error:', error);
    res.status(500).json({ message: 'Registration failed', error: error.message });
  }
});

// Login
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ message: 'Email and password are required' });
    }

    // Find user
    const user = await User.findOne({ email: email.toLowerCase() });
    if (!user) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    // Check password
    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

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
    console.error('Login error:', error);
    res.status(500).json({ message: 'Login failed', error: error.message });
  }
});

// Get current user
router.get('/me', authMiddleware, async (req, res) => {
  try {
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
    console.error('Get user error:', error);
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

