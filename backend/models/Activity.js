import mongoose from 'mongoose';

const activitySchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  activityType: {
    type: String,
    enum: ['workout', 'meal', 'weight_log', 'water_log', 'achievement', 'milestone'],
    required: true
  },
  // Reference to the actual activity
  linkedId: {
    type: mongoose.Schema.Types.ObjectId,
    required: true
  },
  // Summary data for quick display
  summary: {
    title: String,
    description: String,
    icon: String,
    color: String
  },
  // Stats if applicable
  stats: {
    calories: Number,
    duration: Number, // in minutes
    distance: Number,
    weight: Number,
    waterIntake: Number,
    exerciseName: String
  },
  // Engagement
  likes: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }],
  comments: [{
    userId: mongoose.Schema.Types.ObjectId,
    text: String,
    createdAt: Date
  }],
  visibility: {
    type: String,
    enum: ['friends', 'public', 'private'],
    default: 'friends'
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

// Index for faster queries
activitySchema.index({ userId: 1, createdAt: -1 });
activitySchema.index({ activityType: 1 });
activitySchema.index({ visibility: 1 });

const Activity = mongoose.model('Activity', activitySchema);

export default Activity;
