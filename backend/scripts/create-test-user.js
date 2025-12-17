import mongoose from 'mongoose';
import bcrypt from 'bcryptjs';
import dotenv from 'dotenv';
import User from '../models/User.js';

dotenv.config();

// Generate random credentials
const randomId = Math.random().toString(36).substring(2, 8);
const testEmail = `testuser_${randomId}@gofit.ai`;
const testPassword = `TestPass123!${randomId}`;
const testName = `Test User ${randomId}`;

async function createTestUser() {
  try {
    // Connect to MongoDB
    const mongoURI = process.env.MONGODB_URI;
    if (!mongoURI) {
      throw new Error('MONGODB_URI environment variable is not set');
    }

    await mongoose.connect(mongoURI, {
      serverSelectionTimeoutMS: 10000,
      socketTimeoutMS: 45000,
    });
    
    console.log('✅ Connected to MongoDB');

    // Check if user already exists
    const existingUser = await User.findOne({ email: testEmail });
    if (existingUser) {
      console.log('⚠️  Test user already exists with this email');
      console.log('\n📋 Test User Credentials:');
      console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      console.log(`Email:    ${testEmail}`);
      console.log(`Password: ${testPassword}`);
      console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
      await mongoose.disconnect();
      return;
    }

    // Hash password
    const passwordHash = await bcrypt.hash(testPassword, 10);

    // Create user
    const user = new User({
      name: testName,
      email: testEmail,
      passwordHash: passwordHash,
      goals: 'maintain',
      activityLevel: 'moderate',
      dietaryPreferences: [],
      allergies: [],
      fastingPreference: 'none',
      subscription: {
        status: 'free'
      }
    });

    await user.save();
    
    console.log('\n✅ Test user created successfully!');
    console.log('\n📋 Test User Credentials:');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log(`Email:    ${testEmail}`);
    console.log(`Password: ${testPassword}`);
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('\n💡 You can now use these credentials to login in the app.\n');

    await mongoose.disconnect();
    process.exit(0);
  } catch (error) {
    console.error('❌ Error creating test user:', error.message);
    if (error.message.includes('authentication failed')) {
      console.error('\n💡 Make sure MongoDB credentials are correct in your .env file');
    }
    process.exit(1);
  }
}

createTestUser();

