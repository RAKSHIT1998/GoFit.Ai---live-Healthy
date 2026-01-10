import mongoose from 'mongoose';

/**
 * DefaultWorkout Model
 * Pre-populated workouts available offline for all users
 */
const defaultWorkoutSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true
  },
  description: String,
  type: {
    type: String,
    enum: ['cardio', 'strength', 'flexibility', 'hiit', 'yoga', 'pilates', 'sports', 'other'],
    required: true
  },
  estimatedDuration: Number, // minutes
  estimatedCalories: Number, // estimated calories burned
  exercises: [{
    name: String,
    type: String, // cardio, strength, flexibility, etc.
    sets: Number,
    reps: String, // e.g., "10-12", "30 seconds", "AMRAP"
    duration: Number, // seconds for time-based exercises
    restTime: Number, // seconds between sets
    targetMuscles: [String],
    equipment: [String],
    instructions: String, // How to perform the exercise
    notes: String
  }],
  difficulty: {
    type: String,
    enum: ['easy', 'moderate', 'hard', 'very_hard'],
    required: true
  },
  location: {
    type: String,
    enum: ['gym', 'home', 'outdoor', 'studio', 'any'],
    default: 'any'
  },
  equipment: [String], // Required equipment
  tags: [String], // e.g., ['full-body', 'beginner-friendly', 'quick']
  targetMuscles: [String], // Overall target muscle groups
  instructions: String, // General workout instructions
  tips: String, // Tips for getting the most out of the workout
  isActive: {
    type: Boolean,
    default: true
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

defaultWorkoutSchema.index({ type: 1, isActive: 1 });
defaultWorkoutSchema.index({ difficulty: 1 });
defaultWorkoutSchema.index({ location: 1 });

export default mongoose.model('DefaultWorkout', defaultWorkoutSchema);





