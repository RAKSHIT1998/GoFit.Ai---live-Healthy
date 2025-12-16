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
      fat: Number
    }],
    lunch: [{
      name: String,
      calories: Number,
      protein: Number,
      carbs: Number,
      fat: Number
    }],
    dinner: [{
      name: String,
      calories: Number,
      protein: Number,
      carbs: Number,
      fat: Number
    }],
    snacks: [{
      name: String,
      calories: Number,
      protein: Number,
      carbs: Number,
      fat: Number
    }]
  },
  workoutPlan: {
    exercises: [{
      name: String,
      duration: Number, // minutes
      calories: Number,
      type: String // cardio, strength, etc.
    }]
  },
  hydrationGoal: {
    targetLiters: Number,
    currentLiters: Number
  },
  insights: [String],
  aiVersion: String,
  createdAt: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

recommendationSchema.index({ userId: 1, date: -1 });

export default mongoose.model('Recommendation', recommendationSchema);

