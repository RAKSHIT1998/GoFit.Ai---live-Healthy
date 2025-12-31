import mongoose from 'mongoose';

/**
 * Body Measurement Model
 * Tracks body measurements over time
 */
const bodyMeasurementSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  weight: Number, // kg
  bodyFat: Number, // percentage
  muscleMass: Number, // kg
  measurements: {
    neck: Number, // cm
    chest: Number,
    waist: Number,
    hips: Number,
    leftArm: Number,
    rightArm: Number,
    leftThigh: Number,
    rightThigh: Number,
    leftCalf: Number,
    rightCalf: Number
  },
  notes: String,
  photoId: mongoose.Schema.Types.ObjectId, // Reference to progress photo if taken
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

bodyMeasurementSchema.index({ userId: 1, timestamp: -1 });

export default mongoose.model('BodyMeasurement', bodyMeasurementSchema);


