import mongoose from 'mongoose';

/**
 * DefaultMeal Model
 * Pre-populated meals available offline for all users
 */
const defaultMealSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true
  },
  description: String,
  items: [{
    name: String,
    calories: Number,
    protein: Number,
    carbs: Number,
    fat: Number,
    sugar: Number,
    portionSize: String,
    qtyText: String
  }],
  totalCalories: {
    type: Number,
    required: true
  },
  totalProtein: {
    type: Number,
    default: 0
  },
  totalCarbs: {
    type: Number,
    default: 0
  },
  totalFat: {
    type: Number,
    default: 0
  },
  totalSugar: {
    type: Number,
    default: 0
  },
  mealType: {
    type: String,
    enum: ['breakfast', 'lunch', 'dinner', 'snack'],
    required: true
  },
  tags: [String], // e.g., ['vegetarian', 'high-protein', 'quick']
  cuisineType: String, // e.g., 'American', 'Mediterranean', 'Asian'
  prepTime: Number, // minutes
  servings: Number,
  difficulty: {
    type: String,
    enum: ['easy', 'medium', 'hard'],
    default: 'easy'
  },
  instructions: String, // How to prepare
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

defaultMealSchema.index({ mealType: 1, isActive: 1 });
defaultMealSchema.index({ tags: 1 });

export default mongoose.model('DefaultMeal', defaultMealSchema);

