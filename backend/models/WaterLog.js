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

