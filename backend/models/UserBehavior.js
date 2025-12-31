import mongoose from 'mongoose';

/**
 * User Behavior Tracking Model
 * Tracks user interactions, preferences, and patterns for ML learning
 */
const userBehaviorSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  
  // User Type Classification
  userType: {
    type: String,
    enum: [
      'busy_professional',    // Time-constrained, needs quick meals
      'fitness_enthusiast',  // Active, high protein focus
      'health_conscious',   // Balanced nutrition, organic preferences
      'weight_loss_seeker',  // Calorie-focused, portion control
      'muscle_builder',     // High protein, strength training focus
      'family_cook',         // Family-friendly, budget-conscious
      'beginner',            // New to fitness/nutrition
      'experienced'          // Advanced knowledge
    ],
    default: 'beginner'
  },
  
  // Behavior Patterns
  eatingPatterns: {
    preferredMealTimes: [{
      mealType: String, // breakfast, lunch, dinner, snack
      averageTime: String, // "08:00", "13:00", etc.
      frequency: Number // How often this meal is logged
    }],
    averageMealCalories: Number,
    preferredMacroRatio: {
      protein: Number, // percentage
      carbs: Number,
      fat: Number
    },
    favoriteFoods: [{
      name: String,
      frequency: Number, // How many times logged
      lastLogged: Date,
      averageCalories: Number
    }],
    avoidedFoods: [{
      name: String,
      reason: String, // allergy, preference, etc.
      frequency: Number
    }]
  },
  
  // Activity Patterns
  activityPatterns: {
    preferredWorkoutTimes: [{
      timeOfDay: String, // morning, afternoon, evening
      frequency: Number
    }],
    preferredWorkoutTypes: [{
      type: String, // cardio, strength, flexibility, hiit
      frequency: Number,
      averageDuration: Number
    }],
    activityConsistency: {
      daysPerWeek: Number,
      averageDailySteps: Number,
      averageActiveCalories: Number
    }
  },
  
  // Recommendation Feedback
  recommendationFeedback: [{
    recommendationId: mongoose.Schema.Types.ObjectId,
    type: String, // meal, workout, hydration
    action: String, // viewed, logged, skipped, rated
    rating: Number, // 1-5 if rated
    timestamp: Date
  }],
  
  // Learning Metrics
  learningMetrics: {
    totalMealsLogged: Number,
    totalWorkoutsLogged: Number,
    daysActive: Number,
    averageDailyCalories: Number,
    averageDailyProtein: Number,
    averageDailyCarbs: Number,
    averageDailyFat: Number,
    averageDailySugar: Number,
    consistencyScore: Number, // 0-100, based on logging consistency
    engagementScore: Number, // 0-100, based on app usage
    lastUpdated: Date
  },
  
  // Preference Learning
  learnedPreferences: {
    cuisineTypes: [{
      type: String, // Italian, Asian, Mediterranean, etc.
      preferenceScore: Number // 0-100
    }],
    cookingComplexity: {
      preferred: String, // quick, moderate, elaborate
      averagePrepTime: Number
    },
    mealSize: {
      preferred: String, // small, medium, large
      averageCalories: Number
    },
    dietaryTrends: [{
      trend: String, // low_carb, high_protein, etc.
      strength: Number // 0-100
    }]
  },
  
  // Gradual Adaptation
  adaptationHistory: [{
    date: Date,
    changes: [{
      category: String, // meal_timing, portion_size, workout_intensity, etc.
      oldValue: mongoose.Schema.Types.Mixed,
      newValue: mongoose.Schema.Types.Mixed,
      reason: String
    }]
  }],
  
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

// Indexes for efficient queries
userBehaviorSchema.index({ userId: 1, updatedAt: -1 });
userBehaviorSchema.index({ 'learningMetrics.lastUpdated': -1 });

export default mongoose.model('UserBehavior', userBehaviorSchema);

