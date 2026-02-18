import express from 'express';
import User from '../models/User.js';
import Message from '../models/Message.js';
import Conversation from '../models/Conversation.js';
import { authenticateToken } from '../middleware/authMiddleware.js';
import { wsService } from '../services/websocketService.js';

const router = express.Router();
const logger = console;

/**
 * Messaging System API Endpoints
 */

// MARK: - Conversations

/**
 * Get all conversations for current user
 * GET /api/messages/conversations
 */
router.get('/conversations', authenticateToken, async (req, res) => {
    const { userId } = req.user;
    
    try {
        const conversations = await Conversation.find({
            participantIds: userId
        })
        .populate('participantIds', 'name email profileImageUrl')
        .sort({ lastMessageAt: -1 })
        .limit(50);
        
        const formattedConversations = conversations.map(conv => {
            // Get other participant(s) info
            const otherParticipants = conv.participantIds.filter(p => p._id.toString() !== userId);
            const isUnread = !conv.readStatus?.get(userId.toString());
            
            return {
                id: conv._id.toString(),
                type: conv.type,
                name: conv.name || otherParticipants.map(p => p.name).join(', '),
                participants: otherParticipants.map(p => ({
                    id: p._id.toString(),
                    name: p.name,
                    email: p.email,
                    profileImageUrl: p.profileImageUrl || null
                })),
                lastMessage: conv.lastMessage,
                lastMessageAt: conv.lastMessageAt,
                isUnread,
                participantCount: conv.participantIds.length
            };
        });
        
        res.status(200).json({
            conversations: formattedConversations,
            count: formattedConversations.length
        });
    } catch (error) {
        logger.error(`❌ Error fetching conversations: ${error.message}`);
        res.status(500).json({ error: 'Failed to fetch conversations' });
    }
});

/**
 * Get or create direct conversation with another user
 * POST /api/messages/conversations/direct/:friendId
 */
router.post('/conversations/direct/:friendId', authenticateToken, async (req, res) => {
    const { userId } = req.user;
    const { friendId } = req.params;
    
    try {
        // Check if conversation already exists
        let conversation = await Conversation.findOne({
            type: 'direct',
            participantIds: { $all: [userId, friendId] }
        }).populate('participantIds', 'name email profileImageUrl');
        
        if (!conversation) {
            // Create new conversation
            conversation = new Conversation({
                type: 'direct',
                participantIds: [userId, friendId],
                readStatus: new Map()
            });
            await conversation.save();
            await conversation.populate('participantIds', 'name email profileImageUrl');
        }
        
        const otherParticipants = conversation.participantIds.filter(p => p._id.toString() !== userId);
        
        res.status(200).json({
            conversation: {
                id: conversation._id.toString(),
                type: 'direct',
                name: otherParticipants.map(p => p.name).join(', '),
                participants: otherParticipants.map(p => ({
                    id: p._id.toString(),
                    name: p.name,
                    email: p.email,
                    profileImageUrl: p.profileImageUrl || null
                })),
                lastMessage: conversation.lastMessage,
                lastMessageAt: conversation.lastMessageAt
            }
        });
    } catch (error) {
        logger.error(`❌ Error creating conversation: ${error.message}`);
        res.status(500).json({ error: 'Failed to create conversation' });
    }
});

/**
 * Get messages from a conversation
 * GET /api/messages/conversations/:conversationId
 */
router.get('/conversations/:conversationId', authenticateToken, async (req, res) => {
    const { userId } = req.user;
    const { conversationId } = req.params;
    const { limit = 50, offset = 0 } = req.query;
    
    try {
        // Verify user is part of conversation
        const conversation = await Conversation.findOne({
            _id: conversationId,
            participantIds: userId
        });
        
        if (!conversation) {
            return res.status(404).json({ error: 'Conversation not found' });
        }
        
        // Get messages
        const messages = await Message.find({ conversationId })
            .populate('senderId', 'name profileImageUrl email')
            .sort({ createdAt: -1 })
            .skip(parseInt(offset))
            .limit(parseInt(limit));
        
        // Mark messages as read
        await Message.updateMany(
            { conversationId, senderId: { $ne: userId }, isRead: false },
            { isRead: true, readAt: new Date() }
        );
        
        // Update conversation read status
        conversation.readStatus.set(userId.toString(), new Date());
        await conversation.save();
        
        const formattedMessages = messages.reverse().map(msg => ({
            id: msg._id.toString(),
            conversationId: msg.conversationId.toString(),
            sender: {
                id: msg.senderId._id.toString(),
                name: msg.senderId.name,
                profileImageUrl: msg.senderId.profileImageUrl || null
            },
            content: msg.content,
            messageType: msg.messageType,
            motivationType: msg.motivationType,
            emoji: msg.emoji,
            linkedActivityId: msg.linkedActivityId,
            linkedActivityType: msg.linkedActivityType,
            isRead: msg.isRead,
            createdAt: msg.createdAt
        }));
        
        res.status(200).json({
            messages: formattedMessages,
            count: formattedMessages.length
        });
    } catch (error) {
        logger.error(`❌ Error fetching messages: ${error.message}`);
        res.status(500).json({ error: 'Failed to fetch messages' });
    }
});

// MARK: - Sending Messages

/**
 * Send a message
 * POST /api/messages/send
 */
router.post('/send', authenticateToken, async (req, res) => {
    const { userId } = req.user;
    const { conversationId, content, messageType = 'text', motivationType, emoji, linkedActivityId, linkedActivityType } = req.body;
    
    try {
        if (!conversationId || !content) {
            return res.status(400).json({ error: 'Conversation ID and content are required' });
        }
        
        // Verify conversation exists and user is participant
        const conversation = await Conversation.findOne({
            _id: conversationId,
            participantIds: userId
        });
        
        if (!conversation) {
            return res.status(404).json({ error: 'Conversation not found' });
        }
        
        // Create message
        const message = new Message({
            conversationId,
            senderId: userId,
            content,
            messageType,
            motivationType: messageType === 'motivation' ? motivationType : null,
            emoji: messageType === 'motivation' ? emoji : null,
            linkedActivityId,
            linkedActivityType
        });
        
        await message.save();
        await message.populate('senderId', 'name profileImageUrl email');
        
        // Update conversation
        conversation.lastMessage = content;
        conversation.lastMessageAt = new Date();
        await conversation.save();
        
        const formattedMessage = {
            id: message._id.toString(),
            conversationId: message.conversationId.toString(),
            sender: {
                id: message.senderId._id.toString(),
                name: message.senderId.name,
                profileImageUrl: message.senderId.profileImageUrl || null
            },
            content: message.content,
            messageType: message.messageType,
            motivationType: message.motivationType,
            emoji: message.emoji,
            linkedActivityId: message.linkedActivityId,
            linkedActivityType: message.linkedActivityType,
            isRead: message.isRead,
            createdAt: message.createdAt
        };
        
        // 🔥 Emit real-time message to all participants
        conversation.participantIds.forEach(participantId => {
            if (participantId.toString() !== userId) {
                wsService.emitMessage(participantId.toString(), {
                    conversationId: conversationId.toString(),
                    message: formattedMessage
                });
            }
        });
        
        logger.log(`✅ Message sent in conversation ${conversationId}`);
        
        res.status(201).json({
            message: formattedMessage
        });
    } catch (error) {
        logger.error(`❌ Error sending message: ${error.message}`);
        res.status(500).json({ error: 'Failed to send message' });
    }
});

/**
 * Send motivation message
 * POST /api/messages/motivation/:friendId
 */
router.post('/motivation/:friendId', authenticateToken, async (req, res) => {
    const { userId } = req.user;
    const { friendId } = req.params;
    const { motivationType, emoji, text } = req.body;
    
    try {
        // Get or create conversation
        let conversation = await Conversation.findOne({
            type: 'direct',
            participantIds: { $all: [userId, friendId] }
        });
        
        if (!conversation) {
            conversation = new Conversation({
                type: 'direct',
                participantIds: [userId, friendId],
                readStatus: new Map()
            });
            await conversation.save();
        }
        
        // Create motivation message
        const message = new Message({
            conversationId: conversation._id,
            senderId: userId,
            content: text || `${emoji} ${motivationType}`,
            messageType: 'motivation',
            motivationType,
            emoji
        });
        
        await message.save();
        
        // Update conversation
        conversation.lastMessage = `${emoji} Motivation: ${motivationType}`;
        conversation.lastMessageAt = new Date();
        await conversation.save();
        
        logger.log(`✅ Motivation message sent to ${friendId}`);
        
        // 🔥 Emit real-time notification
        wsService.emitMotivation(friendId, {
            from: userId,
            motivationType,
            emoji,
            text: text || `${emoji} ${motivationType}`
        });
        
        res.status(201).json({
            message: 'Motivation sent successfully'
        });
    } catch (error) {
        logger.error(`❌ Error sending motivation: ${error.message}`);
        res.status(500).json({ error: 'Failed to send motivation' });
    }
});

/**
 * Mark conversation as read
 * PUT /api/messages/conversations/:conversationId/read
 */
router.put('/conversations/:conversationId/read', authenticateToken, async (req, res) => {
    const { userId } = req.user;
    const { conversationId } = req.params;
    
    try {
        const conversation = await Conversation.findOne({
            _id: conversationId,
            participantIds: userId
        });
        
        if (!conversation) {
            return res.status(404).json({ error: 'Conversation not found' });
        }
        
        // Mark all messages as read
        await Message.updateMany(
            { conversationId, senderId: { $ne: userId }, isRead: false },
            { isRead: true, readAt: new Date() }
        );
        
        // Update conversation read status
        conversation.readStatus.set(userId.toString(), new Date());
        await conversation.save();
        
        res.status(200).json({ message: 'Conversation marked as read' });
    } catch (error) {
        logger.error(`❌ Error marking conversation as read: ${error.message}`);
        res.status(500).json({ error: 'Failed to mark conversation as read' });
    }
});

/**
 * Get unread message count
 * GET /api/messages/unread-count
 */
router.get('/unread-count', authenticateToken, async (req, res) => {
    const { userId } = req.user;
    
    try {
        const unreadCount = await Message.countDocuments({
            senderId: { $ne: userId },
            isRead: false
        });
        
        res.status(200).json({ unreadCount });
    } catch (error) {
        logger.error(`❌ Error fetching unread count: ${error.message}`);
        res.status(500).json({ error: 'Failed to fetch unread count' });
    }
});

export default router;
