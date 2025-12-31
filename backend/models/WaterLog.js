import mongoose from 'mongoose';

const waterLogSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  amount: {
    type: Number,
    required: true // in liters
  },
  beverageType: {
    type: String,
    enum: ['water', 'soda', 'soft_drink', 'juice', 'coffee', 'tea', 'alcohol', 'beer', 'wine', 'liquor', 'other'],
    default: 'water'
  },
  beverageName: {
    type: String, // e.g., "Coca Cola", "Red Wine", "Whiskey"
    default: ''
  },
  calories: {
    type: Number, // Optional calories for the beverage
    default: 0
  },
  sugar: {
    type: Number, // Sugar content in grams
    default: 0
  },
  timestamp: {
    type: Date,
    default: Date.now,
    index: true
  },
  source: {
    type: String,
    enum: ['manual', 'apple_watch'],
    default: 'manual'
  }
}, {
  timestamps: true
});

waterLogSchema.index({ userId: 1, timestamp: -1 });

export default mongoose.model('WaterLog', waterLogSchema);

