import jwt from 'jsonwebtoken';
import { Server } from 'socket.io';

/**
 * WebSocket Service for Real-time Communication
 * Handles Socket.IO connections and events
 */
export class WebSocketService {
  constructor() {
    this.io = null;
    this.userSockets = new Map(); // userId -> Set of socket IDs
  }

  /**
   * Initialize Socket.IO server
   * @param {http.Server} server - HTTP server instance
   */
  initialize(server) {
    this.io = new Server(server, {
      cors: {
        origin: process.env.ALLOWED_ORIGINS?.split(',') || '*',
        credentials: true,
        methods: ['GET', 'POST']
      },
      transports: ['websocket', 'polling'],
      pingTimeout: 60000,
      pingInterval: 25000
    });

    // Middleware for authentication
    this.io.use(async (socket, next) => {
      try {
        const token = socket.handshake.auth.token || socket.handshake.headers.authorization?.split(' ')[1];
        
        if (!token) {
          return next(new Error('Authentication token required'));
        }

        const secret = process.env.JWT_SECRET;
        if (!secret) {
          return next(new Error('JWT_SECRET not configured'));
        }

        const decoded = jwt.verify(token, secret);
        
        if (!decoded?.userId && !decoded?.id) {
          return next(new Error('Invalid token'));
        }

        socket.userId = decoded.userId || decoded.id;
        socket.username = decoded.username;
        next();
      } catch (error) {
        console.error('Socket authentication error:', error.message);
        next(new Error('Authentication failed'));
      }
    });

    // Connection handler
    this.io.on('connection', (socket) => {
      this.handleConnection(socket);
    });

    console.log('✅ WebSocket server initialized');
  }

  /**
   * Handle new socket connection
   */
  handleConnection(socket) {
    const userId = socket.userId;
    console.log(`🔌 User ${userId} connected (socket: ${socket.id})`);

    // Track user's socket
    if (!this.userSockets.has(userId)) {
      this.userSockets.set(userId, new Set());
    }
    this.userSockets.get(userId).add(socket.id);

    // Join user's personal room
    socket.join(`user:${userId}`);

    // Send connection confirmation
    socket.emit('connected', {
      message: 'Connected to GoFit.Ai real-time server',
      userId,
      timestamp: new Date().toISOString()
    });

    // Handle disconnection
    socket.on('disconnect', () => {
      console.log(`🔌 User ${userId} disconnected (socket: ${socket.id})`);
      const userSocketSet = this.userSockets.get(userId);
      if (userSocketSet) {
        userSocketSet.delete(socket.id);
        if (userSocketSet.size === 0) {
          this.userSockets.delete(userId);
        }
      }
    });

    // Friend request events
    this.setupFriendRequestHandlers(socket);
    
    // Challenge events
    this.setupChallengeHandlers(socket);
    
    // Notification events
    this.setupNotificationHandlers(socket);
  }

  /**
   * Setup friend request event handlers
   */
  setupFriendRequestHandlers(socket) {
    const userId = socket.userId;

    // Request online friends
    socket.on('friends:get_online', () => {
      const onlineFriends = this.getOnlineFriends(userId);
      socket.emit('friends:online_list', onlineFriends);
    });

    // Typing indicator for messages
    socket.on('friends:typing', (data) => {
      this.emitToUser(data.recipientId, 'friends:typing_indicator', {
        userId,
        username: socket.username,
        isTyping: data.isTyping
      });
    });
  }

  /**
   * Setup challenge event handlers
   */
  setupChallengeHandlers(socket) {
    const userId = socket.userId;

    // Join challenge room
    socket.on('challenge:join', (challengeId) => {
      socket.join(`challenge:${challengeId}`);
      console.log(`User ${userId} joined challenge ${challengeId}`);
    });

    // Leave challenge room
    socket.on('challenge:leave', (challengeId) => {
      socket.leave(`challenge:${challengeId}`);
      console.log(`User ${userId} left challenge ${challengeId}`);
    });
  }

  /**
   * Setup notification event handlers
   */
  setupNotificationHandlers(socket) {
    // Mark notification as read
    socket.on('notification:read', (notificationId) => {
      console.log(`User ${socket.userId} read notification ${notificationId}`);
    });
  }

  /**
   * Get list of online friends for a user
   */
  getOnlineFriends(userId) {
    // This would query the database for friends and check if they're online
    // For now, return online user IDs
    const onlineUserIds = Array.from(this.userSockets.keys());
    return onlineUserIds.filter(id => id !== userId);
  }

  /**
   * Emit event to specific user (all their connected sockets)
   */
  emitToUser(userId, event, data) {
    if (!this.io) return;
    this.io.to(`user:${userId}`).emit(event, data);
  }

  /**
   * Emit event to multiple users
   */
  emitToUsers(userIds, event, data) {
    if (!this.io) return;
    userIds.forEach(userId => {
      this.emitToUser(userId, event, data);
    });
  }

  /**
   * Emit event to challenge participants
   */
  emitToChallenge(challengeId, event, data) {
    if (!this.io) return;
    this.io.to(`challenge:${challengeId}`).emit(event, data);
  }

  /**
   * Emit friend request notification
   */
  emitFriendRequest(recipientId, requestData) {
    this.emitToUser(recipientId, 'friend_request:received', {
      ...requestData,
      timestamp: new Date().toISOString()
    });
  }

  /**
   * Emit friend request accepted notification
   */
  emitFriendRequestAccepted(recipientId, acceptorData) {
    this.emitToUser(recipientId, 'friend_request:accepted', {
      ...acceptorData,
      timestamp: new Date().toISOString()
    });
  }

  /**
   * Emit friend request rejected notification
   */
  emitFriendRequestRejected(recipientId, rejecterData) {
    this.emitToUser(recipientId, 'friend_request:rejected', {
      ...rejecterData,
      timestamp: new Date().toISOString()
    });
  }

  /**
   * Emit challenge invitation
   */
  emitChallengeInvitation(recipientId, challengeData) {
    this.emitToUser(recipientId, 'challenge:invitation', {
      ...challengeData,
      timestamp: new Date().toISOString()
    });
  }

  /**
   * Emit challenge update to all participants
   */
  emitChallengeUpdate(challengeId, updateData) {
    this.emitToChallenge(challengeId, 'challenge:update', {
      ...updateData,
      timestamp: new Date().toISOString()
    });
  }

  /**
   * Emit achievement notification
   */
  emitAchievement(userId, achievementData) {
    this.emitToUser(userId, 'achievement:unlocked', {
      ...achievementData,
      timestamp: new Date().toISOString()
    });
  }

  /**
   * Emit leaderboard update
   */
  emitLeaderboardUpdate(userIds, leaderboardData) {
    this.emitToUsers(userIds, 'leaderboard:update', {
      ...leaderboardData,
      timestamp: new Date().toISOString()
    });
  }

  /**
   * Check if user is online
   */
  isUserOnline(userId) {
    return this.userSockets.has(userId);
  }

  /**
   * Get count of online users
   */
  getOnlineUserCount() {
    return this.userSockets.size;
  }
}

// Singleton instance
export const wsService = new WebSocketService();
