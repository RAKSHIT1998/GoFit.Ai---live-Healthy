import mongoose from 'mongoose';

/**
 * Progress Photo Model
 * Tracks user progress photos for visual progress tracking
 */
const progressPhotoSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  imageUrl: {
    type: String,
    required: true
  },
  imageKey: String, // S3 key if using S3
  photoType: {
    type: String,
    enum: ['front', 'side', 'back', 'full_body', 'face', 'other'],
    default: 'front'
  },
  weight: Number, // Weight at time of photo (kg)
  bodyFat: Number, // Body fat percentage if available
  measurements: {
    chest: Number,
    waist: Number,
    hips: Number,
    arms: Number,
    thighs: Number
  },
  notes: String,
  tags: [String], // e.g., ["before", "after", "milestone"]
  timestamp: {
    type: Date,
    default: Date.now,
    index: true
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

progressPhotoSchema.index({ userId: 1, timestamp: -1 });

export default mongoose.model('ProgressPhoto', progressPhotoSchema);


