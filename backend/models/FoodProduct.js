import mongoose from 'mongoose';

/**
 * Food Product Model
 * Barcode-scanned packaged foods database
 */
const foodProductSchema = new mongoose.Schema({
  barcode: {
    type: String,
    unique: true,
    sparse: true,
    index: true
  },
  name: {
    type: String,
    required: true
  },
  brand: String,
  category: String, // e.g., "Snacks", "Beverages", "Dairy"
  imageUrl: String,
  servingSize: {
    amount: Number,
    unit: String // e.g., "g", "ml", "pieces"
  },
  nutrition: {
    calories: Number,
    protein: Number,
    carbs: Number,
    fat: Number,
    sugar: Number,
    fiber: Number,
    sodium: Number,
    saturatedFat: Number,
    transFat: Number,
    cholesterol: Number
  },
  ingredients: [String],
  allergens: [String], // e.g., ["milk", "gluten", "nuts"]
  isVerified: {
    type: Boolean,
    default: false
  },
  source: {
    type: String,
    enum: ['user', 'database', 'api', 'community']
  },
  timesScanned: {
    type: Number,
    default: 0
  },
  lastScanned: Date,
  createdAt: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

foodProductSchema.index({ name: 'text', brand: 'text' });
foodProductSchema.index({ category: 1 });
foodProductSchema.index({ 'nutrition.calories': 1 });

export default mongoose.model('FoodProduct', foodProductSchema);


