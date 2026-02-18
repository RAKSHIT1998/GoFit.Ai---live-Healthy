import mongoose from 'mongoose';

const sharedActivitySchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  friendId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  activityType: {
    type: String,
    enum: ['workout', 'meal', 'weight', 'water', 'progress_photo', 'achievement'],
    required: true
  },
  activityId: {
    type: mongoose.Schema.Types.ObjectId,
    required: true
  },
  title: String,
  description: String,
  metadata: {
    // For workouts
    exerciseName: String,
    duration: Number,
    calories: Number,
    
    // For meals
    mealName: String,
    calories: Number,
    protein: Number,
    carbs: Number,
    fats: Number,
    
    // For weight
    value: Number,
    unit: String,
    
    // For photos
    photoUrl: String,
    
    // For achievements
    achievementName: String,
    achievementIcon: String
  },
  viewedBy: [{
    userId: mongoose.Schema.Types.ObjectId,
    viewedAt: Date
  }],
  reactions: [{
    userId: mongoose.Schema.Types.ObjectId,
    reaction: {
      type: String,
      enum: ['fire', 'love', 'wow', 'like', 'rocket']
    },
    createdAt: Date
  }],
  createdAt: {
    type: Date,
    default: Date.now,
    index: true
  }
});

// Index for activity feed
sharedActivitySchema.index({ friendId: 1, createdAt: -1 });
sharedActivitySchema.index({ userId: 1, createdAt: -1 });

const SharedActivity = mongoose.model('SharedActivity', sharedActivitySchema);

export default SharedActivity;
