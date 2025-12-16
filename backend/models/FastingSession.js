import mongoose from 'mongoose';

const fastingSessionSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  startTime: {
    type: Date,
    required: true
  },
  endTime: Date,
  targetHours: {
    type: Number,
    default: 16
  },
  actualHours: Number,
  status: {
    type: String,
    enum: ['active', 'completed', 'cancelled'],
    default: 'active'
  },
  notes: String,
  createdAt: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

fastingSessionSchema.index({ userId: 1, startTime: -1 });

export default mongoose.model('FastingSession', fastingSessionSchema);

