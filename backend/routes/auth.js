import express from 'express';
import jwt from 'jsonwebtoken';
import crypto from 'crypto';
import User from '../models/User.js';
import { authMiddleware } from '../middleware/authMiddleware.js';
import { sendEmail } from '../utils/emailService.js';

const router = express.Router();

// Register
router.post('/register', async (req, res) => {
  try {
    const { 
      name, email, password, 
      goals, activityLevel, dietaryPreferences, allergies, fastingPreference,
      weightKg, heightCm,
      workoutPreferences, favoriteCuisines, foodPreferences, 
      workoutTimeAvailability, lifestyleFactors,
      favoriteFoods, mealTimingPreference, cookingSkill,
      budgetPreference, motivationLevel, drinkingFrequency, smokingStatus
    } = req.body;

    console.log('🔵 Registration request received:', { 
      name: name?.substring(0, 10) + '...', 
      email: email?.substring(0, 10) + '...',
      hasPassword: !!password,
      hasOnboardingData: !!(workoutPreferences || favoriteCuisines || drinkingFrequency || smokingStatus),
      onboardingFields: {
        workoutPreferences: workoutPreferences?.length || 0,
        favoriteCuisines: favoriteCuisines?.length || 0,
        drinkingFrequency: drinkingFrequency || 'not provided',
        smokingStatus: smokingStatus || 'not provided'
      }
    });

    // Validate and sanitize input
    if (!name || !email || !password) {
      console.log('❌ Registration failed: Missing required fields');
      return res.status(400).json({ message: 'Name, email, and password are required' });
    }

    // Trim and validate name
    const trimmedName = name.trim();
    if (trimmedName.length === 0) {
      console.log('❌ Registration failed: Name is empty or whitespace only');
      return res.status(400).json({ message: 'Name cannot be empty' });
    }
    if (trimmedName.length > 100) {
      console.log('❌ Registration failed: Name too long');
      return res.status(400).json({ message: 'Name must be less than 100 characters' });
    }

    // Validate and normalize email
    const trimmedEmail = email.trim().toLowerCase();
    if (trimmedEmail.length === 0) {
      console.log('❌ Registration failed: Email is empty');
      return res.status(400).json({ message: 'Email cannot be empty' });
    }
    // Basic email validation
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(trimmedEmail)) {
      console.log('❌ Registration failed: Invalid email format');
      return res.status(400).json({ message: 'Please enter a valid email address' });
    }

    // Validate password
    const trimmedPassword = password.trim();
    if (trimmedPassword.length < 8) {
      console.log('❌ Registration failed: Password too short');
      return res.status(400).json({ message: 'Password must be at least 8 characters' });
    }
    if (trimmedPassword.length > 128) {
      console.log('❌ Registration failed: Password too long');
      return res.status(400).json({ message: 'Password must be less than 128 characters' });
    }

    // Check if user exists
    const existingUser = await User.findOne({ email: trimmedEmail });
    if (existingUser) {
      console.log('❌ Registration failed: User already exists');
      return res.status(400).json({ message: 'An account with this email already exists. Please sign in instead.' });
    }

    // Create user with 3-day free trial
    const now = new Date();
    const trialEndDate = new Date(now);
    trialEndDate.setDate(trialEndDate.getDate() + 3); // 3-day free trial
    
    const user = new User({
      name: trimmedName,
      email: trimmedEmail,
      passwordHash: trimmedPassword, // Will be hashed by pre-save hook
      goals: goals || 'maintain',
      activityLevel: activityLevel || 'moderate',
      dietaryPreferences: dietaryPreferences || [],
      allergies: allergies || [],
      fastingPreference: fastingPreference || 'none',
      metrics: {
        weightKg: weightKg || 70,
        heightCm: heightCm || 170
      },
      // Direct fields for easier access
      workoutPreferences: workoutPreferences || [],
      favoriteCuisines: favoriteCuisines || [],
      foodPreferences: foodPreferences || [],
      workoutTimeAvailability: workoutTimeAvailability || 'any',
      lifestyleFactors: lifestyleFactors || [],
      drinkingFrequency: drinkingFrequency || 'never',
      smokingStatus: smokingStatus || 'never',
      // Comprehensive onboarding data for AI personalization
      onboardingData: {
        workoutPreferences: workoutPreferences || [],
        favoriteCuisines: favoriteCuisines || [],
        foodPreferences: foodPreferences || [],
        workoutTimeAvailability: workoutTimeAvailability || 'any',
        lifestyleFactors: lifestyleFactors || [],
        favoriteFoods: favoriteFoods || [],
        mealTimingPreference: mealTimingPreference || 'regular',
        cookingSkill: cookingSkill || 'intermediate',
        budgetPreference: budgetPreference || 'moderate',
        motivationLevel: motivationLevel || 'moderate',
        drinkingFrequency: drinkingFrequency || 'never',
        smokingStatus: smokingStatus || 'never'
      },
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
      name: user.name,
      subscriptionStatus: user.subscription.status,
      trialEndDate: user.subscription.trialEndDate,
      hasOnboardingData: !!(user.onboardingData && Object.keys(user.onboardingData).length > 0),
      workoutPreferences: user.workoutPreferences?.length || 0,
      drinkingFrequency: user.drinkingFrequency || 'not set',
      smokingStatus: user.smokingStatus || 'not set'
    });

    // Send welcome email (non-blocking)
    try {
      await sendEmail(user.email, 'welcome', { name: user.name });
    } catch (emailError) {
      console.error('⚠️ Failed to send welcome email (non-critical):', emailError);
      // Don't fail registration if email fails
    }

    // Auto-calculate calories based on onboarding data
    try {
      const { calculateCalories, calculateMacros } = await import('../utils/calorieCalculator.js');
      
      const calorieData = calculateCalories(user);
      if (calorieData) {
        const macros = calculateMacros(calorieData.recommendedCalories, user.dietaryPreferences);
        
        // Update user metrics
        user.metrics = {
          ...user.metrics,
          targetCalories: calorieData.recommendedCalories,
          targetProtein: macros.protein,
          targetCarbs: macros.carbs,
          targetFat: macros.fat
        };
        await user.save();
        
        console.log('✅ Auto-calculated calories for new user:', {
          calories: calorieData.recommendedCalories,
          protein: macros.protein,
          carbs: macros.carbs,
          fat: macros.fat,
          goal: calorieData.goal
        });
      }
    } catch (error) {
      console.error('⚠️ Failed to auto-calculate calories (non-critical):', error.message);
      // Don't fail registration if calorie calculation fails
    }

    // Generate token
    let token;
    try {
      token = generateToken(user._id);
    } catch (tokenError) {
      console.error('❌ Token generation failed:', tokenError);
      // If token generation fails, still return success but log the error
      // The user was created successfully, they can login to get a token
      return res.status(201).json({
        accessToken: null,
        message: 'Account created successfully. Please sign in to continue.',
        user: {
          id: user._id.toString(),
          name: user.name,
          email: user.email,
          goals: user.goals
        }
      });
    }

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
    console.error('Error stack:', error.stack);
    
    // Extract more detailed error message
    let errorMessage = 'Registration failed';
    let statusCode = 500;
    
    if (error.name === 'ValidationError') {
      // Mongoose validation error
      statusCode = 400;
      const firstError = Object.values(error.errors)[0];
      errorMessage = firstError?.message || error.message || 'Validation failed';
      console.error('Validation errors:', error.errors);
    } else if (error.code === 11000) {
      // Duplicate key error (email already exists)
      statusCode = 400;
      errorMessage = 'User with this email already exists';
      console.error('Duplicate key error:', error.keyPattern);
    } else if (error.message) {
      // Check if it's a known error with a status code
      if (error.message.includes('required') || error.message.includes('invalid')) {
        statusCode = 400;
      }
      errorMessage = error.message;
    }
    
    res.status(statusCode).json({ 
      message: errorMessage,
      ...(process.env.NODE_ENV === 'development' && { error: error.message, stack: error.stack })
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

    // Normalize email (trim and lowercase) - must match registration format
    const normalizedEmail = email.trim().toLowerCase();
    if (!normalizedEmail) {
      return res.status(400).json({ message: 'Email is required' });
    }

    // Find user by normalized email
    const user = await User.findOne({ email: normalizedEmail });
    if (!user) {
      console.log('❌ Login failed: User not found for email:', normalizedEmail.substring(0, 10) + '...');
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    // Check if user has a password (Apple-only users don't have passwords)
    if (!user.passwordHash) {
      console.log('❌ Login failed: User has no password (Apple-only account)');
      return res.status(401).json({ message: 'This account was created with Apple Sign In. Please use Apple Sign In to log in.' });
    }

    // Normalize password (trim) - must match registration format
    // Note: We trim but don't reject empty passwords here since validation happens in comparePassword
    const normalizedPassword = password.trim();
    
    // Check password
    const isMatch = await user.comparePassword(normalizedPassword);
    if (!isMatch) {
      console.log('❌ Login failed: Invalid password for user:', user._id.toString());
      // Additional debug logging (only in development)
      if (process.env.NODE_ENV === 'development') {
        console.log('🔍 Debug: Password hash exists:', !!user.passwordHash);
        console.log('🔍 Debug: Password hash length:', user.passwordHash?.length || 0);
      }
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

// Update user targets (weight, calories, macros, etc.)
router.put('/targets', authMiddleware, async (req, res) => {
  try {
    const { 
      weightKg, 
      heightCm, 
      targetWeightKg,
      targetCalories, 
      targetProtein, 
      targetCarbs, 
      targetFat,
      liquidIntakeGoal,
      goals,
      activityLevel
    } = req.body;

    const updateData = {};
    
    // Update metrics
    if (weightKg !== undefined) {
      updateData['metrics.weightKg'] = weightKg;
    }
    if (heightCm !== undefined) {
      updateData['metrics.heightCm'] = heightCm;
    }
    if (targetWeightKg !== undefined) {
      updateData['metrics.targetWeightKg'] = targetWeightKg;
    }
    if (targetCalories !== undefined) {
      updateData['metrics.targetCalories'] = targetCalories;
    }
    if (targetProtein !== undefined) {
      updateData['metrics.targetProtein'] = targetProtein;
    }
    if (targetCarbs !== undefined) {
      updateData['metrics.targetCarbs'] = targetCarbs;
    }
    if (targetFat !== undefined) {
      updateData['metrics.targetFat'] = targetFat;
    }
    if (liquidIntakeGoal !== undefined) {
      updateData['metrics.liquidIntakeGoal'] = liquidIntakeGoal;
    }
    
    // Update goals and activity level
    if (goals) updateData.goals = goals;
    if (activityLevel) updateData.activityLevel = activityLevel;

    const user = await User.findByIdAndUpdate(
      req.user._id,
      { $set: updateData },
      { new: true }
    ).select('-passwordHash');

    // Recalculate calories if weight, height, goals, or activity level changed
    if (weightKg !== undefined || heightCm !== undefined || goals || activityLevel) {
      try {
        const { calculateCalories, calculateMacros } = await import('../utils/calorieCalculator.js');
        const calorieData = calculateCalories(user);
        if (calorieData) {
          const macros = calculateMacros(calorieData.recommendedCalories, user.dietaryPreferences);
          
          // Update calculated values
          await User.findByIdAndUpdate(
            req.user._id,
            { 
              $set: {
                'metrics.targetCalories': calorieData.recommendedCalories,
                'metrics.targetProtein': macros.protein,
                'metrics.targetCarbs': macros.carbs,
                'metrics.targetFat': macros.fat
              }
            }
          );
          
          // Fetch updated user
          const updatedUser = await User.findById(req.user._id).select('-passwordHash');
          return res.json(updatedUser);
        }
      } catch (calcError) {
        console.error('⚠️ Failed to recalculate calories (non-critical):', calcError);
        // Continue with the update even if calculation fails
      }
    }

    res.json(user);
  } catch (error) {
    console.error('Update targets error:', error);
    res.status(500).json({ message: 'Failed to update targets', error: error.message });
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
      // Normalize email to match registration format (trim + lowercase)
      const normalizedEmail = email.trim().toLowerCase();
      const existingUser = await User.findOne({ email: normalizedEmail });
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
    
    // Extract onboarding data from request if available
    const {
      goals, activityLevel, dietaryPreferences, allergies, fastingPreference,
      weightKg, heightCm,
      workoutPreferences, favoriteCuisines, foodPreferences,
      workoutTimeAvailability, lifestyleFactors,
      favoriteFoods, mealTimingPreference, cookingSkill,
      budgetPreference, motivationLevel, drinkingFrequency, smokingStatus
    } = req.body;
    
    user = new User({
      name: name || 'Apple User',
      email: email ? email.trim().toLowerCase() : `${userIdentifier}@apple.privaterelay.app`,
      appleId: userIdentifier,
      // No passwordHash for Apple users
      goals: goals || 'maintain',
      activityLevel: activityLevel || 'moderate',
      dietaryPreferences: dietaryPreferences || [],
      allergies: allergies || [],
      fastingPreference: fastingPreference || 'none',
      metrics: {
        weightKg: weightKg || 70,
        heightCm: heightCm || 170
      },
      // Direct fields for easier access
      workoutPreferences: workoutPreferences || [],
      favoriteCuisines: favoriteCuisines || [],
      foodPreferences: foodPreferences || [],
      workoutTimeAvailability: workoutTimeAvailability || 'any',
      lifestyleFactors: lifestyleFactors || [],
      drinkingFrequency: drinkingFrequency || 'never',
      smokingStatus: smokingStatus || 'never',
      // Comprehensive onboarding data for AI personalization
      onboardingData: {
        workoutPreferences: workoutPreferences || [],
        favoriteCuisines: favoriteCuisines || [],
        foodPreferences: foodPreferences || [],
        workoutTimeAvailability: workoutTimeAvailability || 'any',
        lifestyleFactors: lifestyleFactors || [],
        favoriteFoods: favoriteFoods || [],
        mealTimingPreference: mealTimingPreference || 'regular',
        cookingSkill: cookingSkill || 'intermediate',
        budgetPreference: budgetPreference || 'moderate',
        motivationLevel: motivationLevel || 'moderate',
        drinkingFrequency: drinkingFrequency || 'never',
        smokingStatus: smokingStatus || 'never'
      },
      subscription: {
        status: 'trial', // Start with trial status
        startDate: now,
        trialEndDate: trialEndDate,
        endDate: trialEndDate // Trial ends after 3 days
      }
    });

    await user.save();
    
    // Auto-calculate calories based on onboarding data
    try {
      const { calculateCalories, calculateMacros } = await import('../utils/calorieCalculator.js');
      
      const calorieData = calculateCalories(user);
      if (calorieData) {
        const macros = calculateMacros(calorieData.recommendedCalories, user.dietaryPreferences);
        
        // Update user metrics
        user.metrics = {
          ...user.metrics,
          targetCalories: calorieData.recommendedCalories,
          targetProtein: macros.protein,
          targetCarbs: macros.carbs,
          targetFat: macros.fat
        };
        await user.save();
      }
    } catch (error) {
      console.error('⚠️ Failed to auto-calculate calories for Apple user (non-critical):', error.message);
    }

    // Send welcome email for new Apple users (non-blocking)
    try {
      await sendEmail(user.email, 'welcome', { name: user.name });
    } catch (emailError) {
      console.error('⚠️ Failed to send welcome email (non-critical):', emailError);
      // Don't fail signup if email fails
    }

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

// Forgot password
router.post('/forgot-password', async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({ message: 'Email is required' });
    }

    // Normalize email to match registration format (trim + lowercase)
    const normalizedEmail = email.trim().toLowerCase();
    const user = await User.findOne({ email: normalizedEmail });
    
    // Don't reveal if user exists or not (security best practice)
    if (!user) {
      // Still return success to prevent email enumeration
      return res.json({ 
        message: 'If an account with that email exists, a password reset link has been sent.' 
      });
    }

    // Check if user has password (Apple-only users can't reset password)
    if (!user.passwordHash) {
      return res.json({ 
        message: 'If an account with that email exists, a password reset link has been sent.' 
      });
    }

    // Generate reset token
    const resetToken = crypto.randomBytes(32).toString('hex');
    user.resetPasswordToken = crypto.createHash('sha256').update(resetToken).digest('hex');
    user.resetPasswordExpires = Date.now() + 3600000; // 1 hour
    await user.save();

    // Create reset link
    const resetLink = `${process.env.APP_URL || 'https://gofitai.org'}/reset-password?token=${resetToken}`;

    // Send email (non-blocking)
    try {
      await sendEmail(user.email, 'forgotPassword', { 
        name: user.name, 
        resetLink: resetLink 
      });
      console.log('✅ Password reset email sent to:', user.email);
    } catch (emailError) {
      console.error('❌ Failed to send password reset email:', emailError);
      // Reset the token if email fails
      user.resetPasswordToken = undefined;
      user.resetPasswordExpires = undefined;
      await user.save();
      return res.status(500).json({ message: 'Failed to send password reset email' });
    }

    res.json({ 
      message: 'If an account with that email exists, a password reset link has been sent.' 
    });
  } catch (error) {
    console.error('Forgot password error:', error);
    res.status(500).json({ message: 'Failed to process password reset request', error: error.message });
  }
});

// Reset password
router.post('/reset-password', async (req, res) => {
  try {
    const { token, password } = req.body;

    if (!token || !password) {
      return res.status(400).json({ message: 'Token and new password are required' });
    }

    if (password.length < 8) {
      return res.status(400).json({ message: 'Password must be at least 8 characters' });
    }

    // Hash the token to compare with stored hash
    const hashedToken = crypto.createHash('sha256').update(token).digest('hex');

    const user = await User.findOne({
      resetPasswordToken: hashedToken,
      resetPasswordExpires: { $gt: Date.now() }
    });

    if (!user) {
      return res.status(400).json({ message: 'Invalid or expired reset token' });
    }

    // Update password
    user.passwordHash = password; // Will be hashed by pre-save hook
    user.resetPasswordToken = undefined;
    user.resetPasswordExpires = undefined;
    await user.save();

    res.json({ message: 'Password has been reset successfully' });
  } catch (error) {
    console.error('Reset password error:', error);
    res.status(500).json({ message: 'Failed to reset password', error: error.message });
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
    console.error('❌ JWT_SECRET is not configured in environment variables');
    throw new Error('Server configuration error: JWT_SECRET not configured. Please contact support.');
  }
  try {
    return jwt.sign({ id: userId }, secret, {
      expiresIn: process.env.JWT_EXPIRES_IN || '7d'
    });
  } catch (error) {
    console.error('❌ JWT sign error:', error);
    throw new Error('Failed to generate authentication token. Please try again.');
  }
}

export default router;
