import mongoose from 'mongoose';

/**
 * Workout Model
 * Tracks detailed workout sessions with exercises
 */
const workoutSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  name: {
    type: String,
    default: 'Workout'
  },
  type: {
    type: String,
    enum: ['cardio', 'strength', 'flexibility', 'hiit', 'yoga', 'pilates', 'sports', 'other'],
    default: 'strength'
  },
  duration: Number, // minutes
  caloriesBurned: Number,
  exercises: [{
    name: String,
    type: String, // cardio, strength, flexibility, etc.
    sets: [{
      reps: Number,
      weight: Number, // kg or lbs
      duration: Number, // seconds for time-based exercises
      restTime: Number, // seconds
      notes: String
    }],
    totalVolume: Number, // total weight × reps
    targetMuscles: [String],
    equipment: [String],
    notes: String
  }],
  notes: String,
  rating: Number, // 1-5 user rating
  difficulty: {
    type: String,
    enum: ['easy', 'moderate', 'hard', 'very_hard']
  },
  location: {
    type: String,
    enum: ['gym', 'home', 'outdoor', 'studio', 'other']
  },
  timestamp: {
    type: Date,
    default: Date.now,
    index: true
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

workoutSchema.index({ userId: 1, timestamp: -1 });
workoutSchema.index({ userId: 1, type: 1 });

export default mongoose.model('Workout', workoutSchema);


