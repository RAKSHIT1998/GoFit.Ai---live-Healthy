import express from 'express';
import Message from '../models/Message.js';
import User from '../models/User.js';
import Friend from '../models/Friend.js';
import { authenticateToken } from '../middleware/authMiddleware.js';
import { wsService } from '../services/websocketService.js';

const router = express.Router();
const logger = console;

/**
 * Messaging/Chat System API Endpoints
 */

// Helper function to create consistent conversation ID
function getConversationId(userId1, userId2) {
  const ids = [userId1.toString(), userId2.toString()].sort();
  return ids.join('_');
}

/**
 * Send a message to a friend
 * POST /api/messages/:friendId
 */
router.post('/:friendId', authenticateToken, async (req, res) => {
  const { userId } = req.user;
  const { friendId } = req.params;
  const { message, messageType = 'text' } = req.body;

  try {
    if (!message || message.trim().length === 0) {
      return res.status(400).json({ error: 'Message cannot be empty' });
    }

    // Verify they are friends
    const friendship = await Friend.findOne({
      $or: [
        { userId, friendId },
        { userId: friendId, friendId: userId }
      ],
      status: 'accepted'
    });

    if (!friendship) {
      return res.status(403).json({ error: 'You are not friends with this user' });
    }

    const conversationId = getConversationId(userId, friendId);

    // Create message
    const newMessage = new Message({
      senderId: userId,
      recipientId: friendId,
      conversationId,
      message: message.trim(),
      messageType
    });

    await newMessage.save();
    await newMessage.populate('senderId', 'name profileImageUrl');

    logger.log(`💬 Message sent from ${userId} to ${friendId}`);

    // 🔥 Emit real-time WebSocket notification
    wsService.emitMessage(friendId, {
      messageId: newMessage._id.toString(),
      conversationId,
      from: {
        id: newMessage.senderId._id.toString(),
        username: newMessage.senderId.name,
        profileImageUrl: newMessage.senderId.profileImageUrl || null
      },
      message: newMessage.message,
      messageType,
      timestamp: newMessage.createdAt
    });

    res.status(201).json({
      message: 'Message sent',
      data: {
        id: newMessage._id.toString(),
        conversationId,
        message: newMessage.message,
        messageType,
        createdAt: newMessage.createdAt
      }
    });
  } catch (error) {
    logger.error(`❌ Error sending message: ${error.message}`);
    res.status(500).json({ error: 'Failed to send message' });
  }
});

/**
 * Get conversation messages with a friend
 * GET /api/messages/:friendId?limit=50&skip=0
 */
router.get('/:friendId', authenticateToken, async (req, res) => {
  const { userId } = req.user;
  const { friendId } = req.params;
  const { limit = 50, skip = 0 } = req.query;

  try {
    // Verify they are friends
    const friendship = await Friend.findOne({
      $or: [
        { userId, friendId },
        { userId: friendId, friendId: userId }
      ],
      status: 'accepted'
    });

    if (!friendship) {
      return res.status(403).json({ error: 'You are not friends with this user' });
    }

    const conversationId = getConversationId(userId, friendId);

    // Get messages
    const messages = await Message.find({ conversationId })
      .populate('senderId', 'name profileImageUrl')
      .sort({ createdAt: -1 })
      .skip(parseInt(skip))
      .limit(parseInt(limit));

    // Mark as read
    await Message.updateMany(
      {
        conversationId,
        recipientId: userId,
        isRead: false
      },
      {
        $set: {
          isRead: true,
          readAt: new Date()
        }
      }
    );

    res.status(200).json({
      messages: messages.reverse().map(msg => ({
        id: msg._id.toString(),
        senderId: msg.senderId._id.toString(),
        senderName: msg.senderId.name,
        senderImage: msg.senderId.profileImageUrl || null,
        message: msg.message,
        messageType: msg.messageType,
        isRead: msg.isRead,
        createdAt: msg.createdAt
      })),
      count: messages.length
    });
  } catch (error) {
    logger.error(`❌ Error fetching messages: ${error.message}`);
    res.status(500).json({ error: 'Failed to fetch messages' });
  }
});

/**
 * Get all conversations (list of friends with last message)
 * GET /api/messages
 */
router.get('/', authenticateToken, async (req, res) => {
  const { userId } = req.user;

  try {
    // Get all friend relationships
    const friendships = await Friend.find({
      $or: [
        { userId, status: 'accepted' },
        { friendId: userId, status: 'accepted' }
      ]
    });

    // Get conversations with last message
    const conversations = await Promise.all(
      friendships.map(async (f) => {
        const friendId = f.userId.toString() === userId ? f.friendId : f.userId;
        const conversationId = getConversationId(userId, friendId);

        const lastMessage = await Message.findOne({ conversationId })
          .sort({ createdAt: -1 });

        const unreadCount = await Message.countDocuments({
          conversationId,
          recipientId: userId,
          isRead: false
        });

        const friend = await User.findById(friendId).select('name profileImageUrl');

        return {
          friendId: friendId.toString(),
          friendName: friend.name,
          friendImage: friend.profileImageUrl || null,
          lastMessage: lastMessage ? lastMessage.message : null,
          lastMessageTime: lastMessage ? lastMessage.createdAt : null,
          unreadCount,
          conversationId
        };
      })
    );

    // Sort by last message time
    conversations.sort((a, b) => {
      const timeA = a.lastMessageTime ? new Date(a.lastMessageTime) : new Date(0);
      const timeB = b.lastMessageTime ? new Date(b.lastMessageTime) : new Date(0);
      return timeB - timeA;
    });

    res.status(200).json({
      conversations,
      count: conversations.length
    });
  } catch (error) {
    logger.error(`❌ Error fetching conversations: ${error.message}`);
    res.status(500).json({ error: 'Failed to fetch conversations' });
  }
});

/**
 * Get unread message count
 * GET /api/messages/unread/count
 */
router.get('/unread/count', authenticateToken, async (req, res) => {
  const { userId } = req.user;

  try {
    const unreadCount = await Message.countDocuments({
      recipientId: userId,
      isRead: false
    });

    res.status(200).json({ unreadCount });
  } catch (error) {
    logger.error(`❌ Error fetching unread count: ${error.message}`);
    res.status(500).json({ error: 'Failed to fetch unread count' });
  }
});

/**
 * Send motivational message template
 * POST /api/messages/:friendId/motivate
 */
router.post('/:friendId/motivate', authenticateToken, async (req, res) => {
  const { userId } = req.user;
  const { friendId } = req.params;
  const { motivationType } = req.body; // 'amazing', 'keep_going', 'you_got_this', 'proud_of_you', 'crush_it'

  try {
    const motivationalMessages = {
      amazing: "🔥 That's amazing! Keep it up!",
      keep_going: "💪 Keep going! You're doing great!",
      you_got_this: "💯 You got this! One more rep!",
      proud_of_you: "🌟 I'm so proud of you!",
      crush_it: "🚀 Crush it! Let's go!"
    };

    const message = motivationalMessages[motivationType] || motivationalMessages.keep_going;

    const conversationId = getConversationId(userId, friendId);

    const newMessage = new Message({
      senderId: userId,
      recipientId: friendId,
      conversationId,
      message,
      messageType: 'motivation'
    });

    await newMessage.save();

    logger.log(`🔥 Motivational message sent from ${userId} to ${friendId}`);

    // Emit WebSocket notification
    wsService.emitMessage(friendId, {
      messageId: newMessage._id.toString(),
      conversationId,
      from: { id: userId },
      message,
      messageType: 'motivation',
      timestamp: newMessage.createdAt
    });

    res.status(201).json({ message: 'Motivational message sent', data: newMessage });
  } catch (error) {
    logger.error(`❌ Error sending motivational message: ${error.message}`);
    res.status(500).json({ error: 'Failed to send motivational message' });
  }
});

export default router;
