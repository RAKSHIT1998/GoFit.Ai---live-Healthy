import mongoose from 'mongoose';
import bcrypt from 'bcryptjs';

const userSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    trim: true
  },
  email: {
    type: String,
    required: true,
    unique: true,
    lowercase: true,
    trim: true
  },
  passwordHash: {
    type: String,
    required: true
  },
  phone: {
    type: String,
    sparse: true
  },
  goals: {
    type: String,
    enum: ['lose', 'maintain', 'gain'],
    default: 'maintain'
  },
  activityLevel: {
    type: String,
    enum: ['sedentary', 'light', 'moderate', 'active', 'very_active'],
    default: 'moderate'
  },
  dietaryPreferences: [{
    type: String,
    enum: ['vegan', 'vegetarian', 'keto', 'paleo', 'mediterranean', 'low_carb', 'none']
  }],
  allergies: [String],
  fastingPreference: {
    type: String,
    enum: ['none', '16:8', '18:6', '20:4', 'OMAD'],
    default: 'none'
  },
  appleHealthEnabled: {
    type: Boolean,
    default: false
  },
  subscription: {
    status: {
      type: String,
      enum: ['free', 'trial', 'active', 'expired', 'cancelled'],
      default: 'free'
    },
    plan: {
      type: String,
      required: false,
      validate: {
        validator: function(value) {
          // Allow null, undefined, empty string, or valid enum values
          if (!value || value === null || value === undefined || value === '') {
            return true;
          }
          return ['monthly', 'yearly'].includes(value);
        },
        message: 'Plan must be either monthly or yearly'
      }
    },
    startDate: Date,
    endDate: Date,
    trialEndDate: Date,
    appleTransactionId: String,
    appleOriginalTransactionId: String
  },
  metrics: {
    weightKg: Number,
    heightCm: Number,
    targetCalories: Number,
    targetProtein: Number,
    targetCarbs: Number,
    targetFat: Number
  },
  healthData: {
    lastSyncDate: Date,
    dailySteps: [{
      date: Date,
      steps: Number,
      activeCalories: Number,
      heartRate: {
        resting: Number,
        average: Number
      }
    }]
  },
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

// Clean up subscription.plan if it's null/undefined before validation
userSchema.pre('validate', function(next) {
  if (this.subscription && (this.subscription.plan === null || this.subscription.plan === undefined)) {
    // Remove the plan field if it's null/undefined to avoid validation errors
    if (this.isNew || this.isModified('subscription.plan')) {
      this.subscription.plan = undefined;
    }
  }
  next();
});

// Hash password before saving
userSchema.pre('save', async function(next) {
  if (!this.isModified('passwordHash')) return next();
  this.passwordHash = await bcrypt.hash(this.passwordHash, 10);
  next();
});

// Compare password method
userSchema.methods.comparePassword = async function(candidatePassword) {
  return await bcrypt.compare(candidatePassword, this.passwordHash);
};

// Remove password from JSON output
userSchema.methods.toJSON = function() {
  const obj = this.toObject();
  delete obj.passwordHash;
  return obj;
};

export default mongoose.model('User', userSchema);

