import mongoose from 'mongoose';

const weightLogSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  weightKg: {
    type: Number,
    required: true
  },
  timestamp: {
    type: Date,
    default: Date.now,
    index: true
  },
  notes: String
}, {
  timestamps: true
});

weightLogSchema.index({ userId: 1, timestamp: -1 });

export default mongoose.model('WeightLog', weightLogSchema);

