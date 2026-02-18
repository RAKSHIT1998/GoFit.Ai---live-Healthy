import mongoose from 'mongoose';

const messageSchema = new mongoose.Schema({
  conversationId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Conversation',
    required: true
  },
  senderId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  content: {
    type: String,
    required: true,
    trim: true
  },
  messageType: {
    type: String,
    enum: ['text', 'motivation', 'achievement', 'milestone'],
    default: 'text'
  },
  // For motivation messages with emojis
  motivationType: {
    type: String,
    enum: ['encouragement', 'celebration', 'challenge', 'support'],
    default: null
  },
  emoji: {
    type: String,
    default: null
  },
  // For activity-related messages
  linkedActivityId: {
    type: String,
    default: null // References workout or meal ID
  },
  linkedActivityType: {
    type: String,
    enum: ['workout', 'meal', 'achievement', null],
    default: null
  },
  isRead: {
    type: Boolean,
    default: false
  },
  readAt: {
    type: Date,
    default: null
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

// Index for faster queries
messageSchema.index({ conversationId: 1, createdAt: -1 });
messageSchema.index({ senderId: 1 });
messageSchema.index({ isRead: 1 });

const Message = mongoose.model('Message', messageSchema);

export default Message;
