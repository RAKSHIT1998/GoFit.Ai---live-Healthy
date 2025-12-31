import mongoose from 'mongoose';

/**
 * Recipe Model
 * Recipe library with favorites
 */
const recipeSchema = new mongoose.Schema({
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
  imageUrl: String,
  cuisineType: String, // Italian, Asian, Mediterranean, etc.
  mealType: {
    type: String,
    enum: ['breakfast', 'lunch', 'dinner', 'snack', 'dessert', 'drink']
  },
  prepTime: Number, // minutes
  cookTime: Number, // minutes
  totalTime: Number, // minutes
  servings: Number,
  difficulty: {
    type: String,
    enum: ['easy', 'medium', 'hard']
  },
  ingredients: [{
    name: String,
    quantity: String,
    unit: String,
    notes: String
  }],
  instructions: [{
    step: Number,
    description: String,
    duration: Number, // optional step duration
    temperature: Number, // optional cooking temperature
    notes: String
  }],
  nutrition: {
    calories: Number,
    protein: Number,
    carbs: Number,
    fat: Number,
    sugar: Number,
    fiber: Number,
    sodium: Number
  },
  tags: [String], // e.g., ["vegetarian", "high-protein", "quick"]
  isFavorite: {
    type: Boolean,
    default: false,
    index: true
  },
  source: {
    type: String,
    enum: ['user', 'ai_generated', 'imported', 'community']
  },
  timesCooked: {
    type: Number,
    default: 0
  },
  lastCooked: Date,
  rating: Number, // 1-5
  notes: String,
  createdAt: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

recipeSchema.index({ userId: 1, isFavorite: 1 });
recipeSchema.index({ userId: 1, mealType: 1 });
recipeSchema.index({ userId: 1, cuisineType: 1 });
recipeSchema.index({ 'tags': 1 });

export default mongoose.model('Recipe', recipeSchema);


