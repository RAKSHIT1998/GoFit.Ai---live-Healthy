import mongoose from 'mongoose';

const mealSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  items: [{
    name: String,
    calories: Number,
    protein: Number,
    carbs: Number,
    fat: Number,
    sugar: Number, // Added sugar field
    portionSize: String,
    qtyText: String, // For manual entries (e.g., "1 cup", "200g")
    confidence: Number // AI confidence score (0-1)
  }],
  imageUrl: String, // S3 URL
  imageKey: String, // S3 key for deletion
  totalCalories: Number,
  totalProtein: Number,
  totalCarbs: Number,
  totalFat: Number,
  totalSugar: Number, // Added total sugar
  mealType: {
    type: String,
    enum: ['breakfast', 'lunch', 'dinner', 'snack'],
    default: 'snack'
  },
  timestamp: {
    type: Date,
    default: Date.now,
    index: true
  },
  aiVersion: String, // AI model version used
  createdAt: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

// Index for efficient queries
mealSchema.index({ userId: 1, timestamp: -1 });

export default mongoose.model('Meal', mealSchema);

