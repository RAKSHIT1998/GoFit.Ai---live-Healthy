import mongoose from 'mongoose';

export async function connectDB() {
  try {
    const mongoURI = process.env.MONGODB_URI;
    
    if (!mongoURI) {
      throw new Error('MONGODB_URI environment variable is not set. Please configure it in your Render environment variables.');
    }

    // Parse connection string to check for credentials
    const uriParts = mongoURI.match(/mongodb\+srv:\/\/([^:]+):([^@]+)@/);
    if (uriParts) {
      const username = uriParts[1];
      console.log(`🔐 Connecting to MongoDB as user: ${username}`);
    }

    await mongoose.connect(mongoURI, {
      serverSelectionTimeoutMS: 10000, // 10 seconds
      socketTimeoutMS: 45000,
    });
    
    console.log('✅ MongoDB connected successfully');
    console.log(`📊 Database: ${mongoose.connection.name}`);
  } catch (error) {
    console.error('❌ MongoDB connection error:', error.message);
    
    // Provide helpful error messages
    if (error.message.includes('authentication failed') || error.code === 8000) {
      console.error('\n💡 Authentication failed. Please check:');
      console.error('   1. MongoDB username and password in MONGODB_URI');
      console.error('   2. Database user has correct permissions');
      console.error('   3. IP address is whitelisted in MongoDB Atlas (0.0.0.0/0 for Render)');
    } else if (error.message.includes('ECONNREFUSED')) {
      console.error('\n💡 Connection refused. Please check:');
      console.error('   1. MongoDB URI is correct');
      console.error('   2. Network connectivity');
      console.error('   3. MongoDB Atlas cluster is running');
    }
    
    throw error;
  }
}

export default mongoose;

