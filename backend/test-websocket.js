/**
 * WebSocket Test Client
 * Tests the Socket.IO server connection and friend request events
 */

import { io } from 'socket.io-client';

// Test JWT token (replace with actual token from login)
const TEST_TOKEN = 'your-jwt-token-here';

// Connect to WebSocket server
const socket = io('http://localhost:3000', {
  auth: {
    token: TEST_TOKEN
  },
  transports: ['websocket', 'polling']
});

// Connection events
socket.on('connect', () => {
  console.log('✅ Connected to WebSocket server');
  console.log('Socket ID:', socket.id);
});

socket.on('connected', (data) => {
  console.log('📡 Server confirmation:', data);
});

socket.on('disconnect', (reason) => {
  console.log('🔌 Disconnected:', reason);
});

socket.on('connect_error', (error) => {
  console.error('❌ Connection error:', error.message);
});

// Friend request events
socket.on('friend_request:received', (data) => {
  console.log('\n📬 Friend Request Received:');
  console.log('  From:', data.from.username, `(${data.from.fullName})`);
  console.log('  Request ID:', data.requestId);
  console.log('  Message:', data.message);
  console.log('  Timestamp:', new Date(data.timestamp).toLocaleString());
});

socket.on('friend_request:accepted', (data) => {
  console.log('\n✅ Friend Request Accepted:');
  console.log('  By:', data.acceptedBy.username, `(${data.acceptedBy.fullName})`);
  console.log('  Message:', data.message);
  console.log('  Timestamp:', new Date(data.timestamp).toLocaleString());
});

socket.on('friend_request:rejected', (data) => {
  console.log('\n❌ Friend Request Rejected:');
  console.log('  By:', data.rejectedBy.username);
  console.log('  Message:', data.message);
});

// Challenge events
socket.on('challenge:invitation', (data) => {
  console.log('\n🏆 Challenge Invitation:');
  console.log('  Challenge:', data.details.name);
  console.log('  From:', data.from.username);
});

socket.on('challenge:update', (data) => {
  console.log('\n📊 Challenge Update:');
  console.log('  Type:', data.type);
  console.log('  Challenge ID:', data.challengeId);
});

// Achievement events
socket.on('achievement:unlocked', (data) => {
  console.log('\n🏅 Achievement Unlocked:');
  console.log('  Name:', data.name);
  console.log('  Description:', data.description);
});

// Keep the connection alive
console.log('\n🔄 WebSocket test client started');
console.log('📝 Listening for real-time events...');
console.log('💡 Press Ctrl+C to exit\n');

// Test sending a custom event (optional)
setTimeout(() => {
  console.log('\n🔍 Testing connection...');
  socket.emit('friends:get_online');
}, 2000);

// Handle graceful shutdown
process.on('SIGINT', () => {
  console.log('\n👋 Closing connection...');
  socket.disconnect();
  process.exit(0);
});
