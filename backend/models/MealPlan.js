import mongoose from 'mongoose';

/**
 * Meal Plan Model
 * Weekly/monthly meal planning
 */
const mealPlanSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  name: {
    type: String,
    default: 'My Meal Plan'
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
  meals: [{
    date: Date,
    mealType: {
      type: String,
      enum: ['breakfast', 'lunch', 'dinner', 'snack']
    },
    items: [{
      name: String,
      calories: Number,
      protein: Number,
      carbs: Number,
      fat: Number,
      sugar: Number,
      portionSize: String,
      recipeId: mongoose.Schema.Types.ObjectId // Reference to recipe if available
    }],
    totalCalories: Number,
    totalProtein: Number,
    totalCarbs: Number,
    totalFat: Number,
    totalSugar: Number,
    notes: String,
    isCompleted: {
      type: Boolean,
      default: false
    }
  }],
  shoppingList: [{
    ingredient: String,
    quantity: String,
    category: String, // produce, meat, dairy, etc.
    isPurchased: {
      type: Boolean,
      default: false
    }
  }],
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

mealPlanSchema.index({ userId: 1, startDate: -1 });
mealPlanSchema.index({ userId: 1, isActive: 1 });

export default mongoose.model('MealPlan', mealPlanSchema);


