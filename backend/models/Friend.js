import mongoose from 'mongoose';

const friendSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  friendId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  status: {
    type: String,
    enum: ['pending', 'accepted', 'blocked'],
    default: 'pending'
  },
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
});

// Ensure unique constraint: users can't be duplicated
friendSchema.index({ userId: 1, friendId: 1 }, { unique: true });

// Update the updatedAt timestamp before saving
friendSchema.pre('save', function(next) {
  this.updatedAt = Date.now();
  next();
});

const Friend = mongoose.model('Friend', friendSchema);

export default Friend;
