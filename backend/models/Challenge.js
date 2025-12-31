import mongoose from 'mongoose';

/**
 * Challenge Model
 * Fitness and nutrition challenges/goals
 */
const challengeSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  name: {
    type: String,
    required: true
  },
  description: String,
  type: {
    type: String,
    enum: ['weight_loss', 'muscle_gain', 'strength', 'endurance', 'nutrition', 'consistency', 'custom'],
    required: true
  },
  target: {
    metric: String, // e.g., "weight", "calories", "workouts", "steps"
    targetValue: Number,
    currentValue: {
      type: Number,
      default: 0
    },
    unit: String // e.g., "kg", "kcal", "days"
  },
  startDate: {
    type: Date,
    required: true,
    index: true
  },
  endDate: {
    type: Date,
    required: true
  },
  milestones: [{
    name: String,
    targetValue: Number,
    achieved: {
      type: Boolean,
      default: false
    },
    achievedDate: Date,
    reward: String // Optional reward description
  }],
  progress: [{
    date: Date,
    value: Number,
    notes: String
  }],
  status: {
    type: String,
    enum: ['active', 'completed', 'paused', 'cancelled'],
    default: 'active',
    index: true
  },
  isPublic: {
    type: Boolean,
    default: false
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

challengeSchema.index({ userId: 1, status: 1, startDate: -1 });
challengeSchema.index({ userId: 1, type: 1 });

export default mongoose.model('Challenge', challengeSchema);


