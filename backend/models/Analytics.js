import mongoose from 'mongoose';

/**
 * Analytics Model
 * Stores calculated analytics for quick access
 */
const analyticsSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  period: {
    type: String,
    enum: ['daily', 'weekly', 'monthly', 'yearly'],
    required: true
  },
  date: {
    type: Date,
    required: true,
    index: true
  },
  nutrition: {
    totalCalories: Number,
    averageCalories: Number,
    totalProtein: Number,
    averageProtein: Number,
    totalCarbs: Number,
    averageCarbs: Number,
    totalFat: Number,
    averageFat: Number,
    totalSugar: Number,
    averageSugar: Number,
    macroDistribution: {
      protein: Number, // percentage
      carbs: Number,
      fat: Number
    },
    mealCount: Number,
    consistencyScore: Number // 0-100
  },
  fitness: {
    totalWorkouts: Number,
    totalDuration: Number, // minutes
    totalCaloriesBurned: Number,
    averageWorkoutDuration: Number,
    workoutTypes: [{
      type: String,
      count: Number,
      totalDuration: Number
    }],
    consistencyScore: Number
  },
  progress: {
    weightChange: Number, // kg
    bodyFatChange: Number, // percentage
    measurementChanges: {
      chest: Number,
      waist: Number,
      hips: Number,
      arms: Number
    }
  },
  goals: {
    caloriesGoal: Number,
    caloriesAchieved: Number,
    proteinGoal: Number,
    proteinAchieved: Number,
    workoutGoal: Number,
    workoutAchieved: Number
  },
  insights: [String], // AI-generated insights
  createdAt: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

analyticsSchema.index({ userId: 1, period: 1, date: -1 });

export default mongoose.model('Analytics', analyticsSchema);


