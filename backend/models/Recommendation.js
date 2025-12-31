import mongoose from 'mongoose';

const recommendationSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  date: {
    type: Date,
    required: true,
    index: true
  },
  type: {
    type: String,
    enum: ['meal', 'workout', 'hydration'],
    required: true
  },
  mealPlan: {
    breakfast: [{
      name: String,
      calories: Number,
      protein: Number,
      carbs: Number,
      fat: Number,
      ingredients: [String],
      instructions: String,
      prepTime: Number, // minutes
      servings: Number
    }],
    lunch: [{
      name: String,
      calories: Number,
      protein: Number,
      carbs: Number,
      fat: Number,
      ingredients: [String],
      instructions: String,
      prepTime: Number,
      servings: Number
    }],
    dinner: [{
      name: String,
      calories: Number,
      protein: Number,
      carbs: Number,
      fat: Number,
      ingredients: [String],
      instructions: String,
      prepTime: Number,
      servings: Number
    }],
    snacks: [{
      name: String,
      calories: Number,
      protein: Number,
      carbs: Number,
      fat: Number,
      ingredients: [String],
      instructions: String,
      prepTime: Number,
      servings: Number
    }]
  },
  workoutPlan: {
    exercises: [{
      name: String,
      duration: Number, // minutes
      calories: Number,
      type: String, // cardio, strength, etc.
      instructions: String, // How to perform the exercise
      sets: Number, // For strength training
      reps: String, // e.g., "10-12" or "30 seconds"
      restTime: Number, // seconds between sets
      difficulty: String, // beginner, intermediate, advanced
      muscleGroups: [String], // e.g., ["chest", "triceps"]
      equipment: [String] // e.g., ["dumbbells", "mat"] or ["none"]
    }]
  },
  hydrationGoal: {
    targetLiters: Number,
    currentLiters: Number
  },
  insights: [String],
  aiVersion: String,
  mlMetadata: {
    userType: String,
    usedFavoriteFoods: [String],
    adaptedForUserType: Boolean
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

recommendationSchema.index({ userId: 1, date: -1 });

export default mongoose.model('Recommendation', recommendationSchema);

