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
    required: function() {
      // Password is required only if user doesn't have Apple ID
      return !this.appleId;
    }
  },
  appleId: {
    type: String,
    unique: true,
    sparse: true, // Allow multiple null values
    trim: true
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
      default: undefined, // Explicitly set default to undefined, not null
      sparse: true, // Don't index null/undefined values
      set: function(value) {
        // Convert null to undefined to avoid validation issues
        if (value === null || value === '' || value === undefined) {
          return undefined;
        }
        return value;
      },
      validate: {
        validator: function(value) {
          // Allow null, undefined, empty string, or valid enum values
          // This validator should never be called with null due to the setter, but just in case
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
    targetWeightKg: Number,
    targetCalories: Number,
    targetProtein: Number,
    targetCarbs: Number,
    targetFat: Number,
    liquidIntakeGoal: {
      type: Number,
      default: 2.5 // Default 2.5L per day
    }
  },
  // Comprehensive onboarding data for AI personalization
  onboardingData: {
    workoutPreferences: [String],
    favoriteCuisines: [String],
    foodPreferences: [String],
    workoutTimeAvailability: String,
    lifestyleFactors: [String],
    favoriteFoods: [String],
    mealTimingPreference: String,
    cookingSkill: String,
    budgetPreference: String,
    motivationLevel: String,
    drinkingFrequency: String,
    smokingStatus: String
  },
  // Direct fields for easier access (also stored in onboardingData)
  workoutPreferences: [String],
  favoriteCuisines: [String],
  foodPreferences: [String],
  workoutTimeAvailability: {
    type: String,
    enum: ['very_little', 'little', 'moderate', 'plenty', 'unlimited', 'any'],
    default: 'any'
  },
  lifestyleFactors: [String],
  drinkingFrequency: {
    type: String,
    enum: ['never', 'rarely', 'occasionally', 'regularly', 'frequently'],
    default: 'never'
  },
  smokingStatus: {
    type: String,
    enum: ['never', 'former', 'occasional', 'regular'],
    default: 'never'
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
  },
  resetPasswordToken: {
    type: String,
    default: undefined
  },
  resetPasswordExpires: {
    type: Date,
    default: undefined
  }
}, {
  timestamps: true
});

// Clean up subscription.plan if it's null/undefined before validation
userSchema.pre('validate', function(next) {
  if (this.subscription) {
    // If plan is null or undefined, delete it entirely to avoid validation
    if (this.subscription.plan === null || this.subscription.plan === undefined) {
      delete this.subscription.plan;
    }
  }
  next();
});

// Clean up subscription.plan before saving (additional safety)
userSchema.pre('save', function(next) {
  if (this.subscription && (this.subscription.plan === null || this.subscription.plan === undefined)) {
    // Use $unset to remove the field entirely
    if (!this.isNew) {
      this.$unset = this.$unset || {};
      this.$unset['subscription.plan'] = '';
    } else {
      delete this.subscription.plan;
    }
  }
  next();
});

// Hash password before saving
userSchema.pre('save', async function(next) {
  // Only hash password if it's modified and exists (not for Apple-only users)
  if (!this.isModified('passwordHash') || !this.passwordHash) return next();
  this.passwordHash = await bcrypt.hash(this.passwordHash, 10);
  next();
});

// Compare password method
userSchema.methods.comparePassword = async function(candidatePassword) {
  // Apple users don't have passwords
  if (!this.passwordHash) {
    return false;
  }
  return await bcrypt.compare(candidatePassword, this.passwordHash);
};

// Remove password from JSON output
userSchema.methods.toJSON = function() {
  const obj = this.toObject();
  delete obj.passwordHash;
  return obj;
};

export default mongoose.model('User', userSchema);

