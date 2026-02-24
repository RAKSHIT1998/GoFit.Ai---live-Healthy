import express from 'express';
import User from '../models/User.js';
import Friend from '../models/Friend.js';
import { authenticateToken } from '../middleware/authMiddleware.js';
import { wsService } from '../services/websocketService.js';

const router = express.Router();
const logger = console;

/**
 * Friends & Social System API Endpoints
 */

// MARK: - Friend Requests

/**
 * Send a friend request
 * POST /api/friends/request/:targetUserId
 */
router.post('/request/:targetUserId', authenticateToken, async (req, res) => {
    const { userId } = req.user;
    const { targetUserId } = req.params;
    
    try {
        // Validate input
        if (!targetUserId) {
            return res.status(400).json({ error: 'Target user ID is required' });
        }
        
        // Don't allow adding yourself
        if (userId === targetUserId) {
            return res.status(400).json({ error: 'Cannot add yourself as a friend' });
        }
        
        // Check if target user exists
        const targetUser = await User.findById(targetUserId);
        if (!targetUser) {
            return res.status(404).json({ error: 'User not found' });
        }
        
        // Check if already friends or pending
        const existingRelationship = await Friend.findOne({
            $or: [
                { userId, friendId: targetUserId },
                { userId: targetUserId, friendId: userId }
            ]
        });
        
        if (existingRelationship) {
            if (existingRelationship.status === 'accepted') {
                return res.status(400).json({ error: 'Already friends' });
            }
            if (existingRelationship.status === 'pending') {
                return res.status(400).json({ error: 'Friend request already pending' });
            }
        }
        
        // Create friend request
        const friendRequest = new Friend({
            userId,
            friendId: targetUserId,
            status: 'pending'
        });
        
        await friendRequest.save();
        
        // Get sender info for the notification
        const senderInfo = await User.findById(userId).select('name email profileImageUrl');
        
        logger.log(`✅ Friend request sent from ${userId} to ${targetUserId}`);
        
        // 🔥 Emit real-time WebSocket notification
        wsService.emitFriendRequest(targetUserId, {
            requestId: friendRequest._id.toString(),
            from: {
                id: senderInfo._id.toString(),
                username: senderInfo.name,
                fullName: senderInfo.name,
                profileImageUrl: senderInfo.profileImageUrl || null
            },
            status: 'pending',
            message: `${senderInfo.name} sent you a friend request`
        });
        
        res.status(201).json({
            message: 'Friend request sent',
            friendRequest: {
                id: friendRequest._id.toString(),
                status: friendRequest.status
            }
        });
    } catch (error) {
        logger.error(`❌ Error sending friend request: ${error.message}`);
        res.status(500).json({ error: 'Failed to send friend request' });
    }
});

/**
 * Get pending friend requests for current user
 * GET /api/friends/requests
 */
router.get('/requests', authenticateToken, async (req, res) => {
    const { userId } = req.user;
    
    try {
        const requests = await Friend.find({
            friendId: userId,
            status: 'pending'
        })
        .populate('userId', 'name email profileImageUrl')
        .sort({ createdAt: -1 });
        
        const formattedRequests = requests.map(req => ({
            id: req._id.toString(),
            from: {
                id: req.userId._id.toString(),
                username: req.userId.name,
                fullName: req.userId.name,
                profileImageUrl: req.userId.profileImageUrl || null
            },
            status: 'pending',
            createdAt: req.createdAt
        }));
        
        res.status(200).json({
            requests: formattedRequests,
            count: formattedRequests.length
        });
    } catch (error) {
        logger.error(`❌ Error fetching friend requests: ${error.message}`);
        res.status(500).json({ error: 'Failed to fetch friend requests' });
    }
});

/**
 * Accept a friend request
 * PUT /api/friends/accept/:requestUserId
 */
router.put('/accept/:requestUserId', authenticateToken, async (req, res) => {
    const { userId } = req.user;
    const { requestUserId } = req.params;
    
    try {
        // Find the friend request
        const friendRequest = await Friend.findOne({
            userId: requestUserId,
            friendId: userId,
            status: 'pending'
        });
        
        if (!friendRequest) {
            return res.status(404).json({ error: 'Friend request not found' });
        }
        
        // Update status to accepted
        friendRequest.status = 'accepted';
        await friendRequest.save();
        
        // Get acceptor info for the notification
        const acceptorInfo = await User.findById(userId).select('name email profileImageUrl');
        
        logger.log(`✅ Friend request accepted from ${requestUserId} to ${userId}`);
        
        // 🔥 Emit real-time WebSocket notification
        wsService.emitFriendRequestAccepted(requestUserId, {
            from: {
                id: acceptorInfo._id.toString(),
                username: acceptorInfo.name,
                fullName: acceptorInfo.name,
                profileImageUrl: acceptorInfo.profileImageUrl || null
            },
            status: 'accepted',
            message: `${acceptorInfo.name} accepted your friend request`
        });
        
        res.status(200).json({
            message: 'Friend request accepted',
            friend: {
                id: requestUserId,
                status: 'accepted'
            }
        });
    } catch (error) {
        logger.error(`❌ Error accepting friend request: ${error.message}`);
        res.status(500).json({ error: 'Failed to accept friend request' });
    }
});

/**
 * Reject a friend request
 * DELETE /api/friends/reject/:requestUserId
 */
router.delete('/reject/:requestUserId', authenticateToken, async (req, res) => {
    const { userId } = req.user;
    const { requestUserId } = req.params;
    
    try {
        const result = await Friend.findOneAndDelete({
            userId: requestUserId,
            friendId: userId,
            status: 'pending'
        });
        
        if (!result) {
            return res.status(404).json({ error: 'Friend request not found' });
        }
        
        logger.log(`✅ Friend request rejected from ${requestUserId} to ${userId}`);
        
        res.status(200).json({ message: 'Friend request rejected' });
    } catch (error) {
        logger.error(`❌ Error rejecting friend request: ${error.message}`);
        res.status(500).json({ error: 'Failed to reject friend request' });
    }
});

// MARK: - Friends List

/**
 * Get all friends (accepted)
 * GET /api/friends
 */
router.get('/', authenticateToken, async (req, res) => {
    const { userId } = req.user;
    
    try {
        const friendships = await Friend.find({
            $or: [
                { userId, status: 'accepted' },
                { friendId: userId, status: 'accepted' }
            ]
        })
        .populate('userId', 'name email profileImageUrl')
        .populate('friendId', 'name email profileImageUrl')
        .sort({ updatedAt: -1 });
        
        // Extract friend info from both directions of the relationship
        const friends = friendships.map(f => {
            const isSender = f.userId._id.toString() === userId;
            const friendData = isSender ? f.friendId : f.userId;
            
            return {
                id: friendData._id.toString(),
                username: friendData.name,
                email: friendData.email,
                fullName: friendData.name,
                profileImageUrl: friendData.profileImageUrl || null,
                status: 'friends',
                connectedAt: f.updatedAt
            };
        });
        
        res.status(200).json({
            friends,
            count: friends.length
        });
    } catch (error) {
        logger.error(`❌ Error fetching friends: ${error.message}`);
        res.status(500).json({ error: 'Failed to fetch friends' });
    }
});

/**
 * Remove a friend
 * DELETE /api/friends/:friendId
 */
router.delete('/:friendId', authenticateToken, async (req, res) => {
    const { userId } = req.user;
    const { friendId } = req.params;
    
    try {
        const result = await Friend.findOneAndDelete({
            $or: [
                { userId, friendId },
                { userId: friendId, friendId: userId }
            ],
            status: 'accepted'
        });
        
        if (!result) {
            return res.status(404).json({ error: 'Friend relationship not found' });
        }
        
        logger.log(`✅ Friend removed: ${userId} removed ${friendId}`);
        
        res.status(200).json({ message: 'Friend removed' });
    } catch (error) {
        logger.error(`❌ Error removing friend: ${error.message}`);
        res.status(500).json({ error: 'Failed to remove friend' });
    }
});

// MARK: - Search Friends

/**
 * Search users by username or email
 * GET /api/friends/search?q=<query>&limit=20
 */
router.get('/search', authenticateToken, async (req, res) => {
    const { userId } = req.user;
    const { q, limit = 20 } = req.query;
    
    try {
        if (!q || q.length < 2) {
            return res.status(400).json({ error: 'Search query must be at least 2 characters' });
        }
        
        // Build search regex for case-insensitive search
        const searchRegex = new RegExp(q, 'i');
        
        // Search for users matching the query
        const users = await User.find({
            _id: { $ne: userId }, // Exclude current user
            $or: [
                { name: searchRegex },
                { email: searchRegex }
            ]
        })
        .select('_id name email profileImageUrl')
        .limit(parseInt(limit));
        
        // For each user, get their friend status with the current user
        const results = await Promise.all(users.map(async (user) => {
            const friendship = await Friend.findOne({
                $or: [
                    { userId, friendId: user._id },
                    { userId: user._id, friendId: userId }
                ]
            });
            
            let friendStatus = 'not_friends';
            if (friendship) {
                if (friendship.status === 'accepted') {
                    friendStatus = 'friends';
                } else if (friendship.status === 'pending') {
                    if (friendship.userId.toString() === userId) {
                        friendStatus = 'request_sent';
                    } else {
                        friendStatus = 'request_received';
                    }
                }
            }
            
            return {
                id: user._id.toString(),
                username: user.name,
                email: user.email,
                fullName: user.name,
                profileImageUrl: user.profileImageUrl || null,
                friendStatus
            };
        }));
        
        res.status(200).json({
            results,
            count: results.length
        });
    } catch (error) {
        logger.error(`❌ Error searching users: ${error.message}`);
        res.status(500).json({ error: 'Failed to search users' });
    }
});

// MARK: - Nearby People

/**
 * Update current user location (opt-in required)
 * POST /api/friends/location
 */
router.post('/location', authenticateToken, async (req, res) => {
    const { userId } = req.user;
    const { latitude, longitude, optIn } = req.body || {};

    try {
        if (optIn === false) {
            await User.findByIdAndUpdate(userId, {
                nearbyOptIn: false,
                $unset: { location: 1, locationUpdatedAt: 1 }
            });
            return res.status(200).json({ message: 'Nearby disabled' });
        }

        if (typeof latitude !== 'number' || typeof longitude !== 'number') {
            return res.status(400).json({ error: 'Valid latitude and longitude are required' });
        }

        await User.findByIdAndUpdate(userId, {
            nearbyOptIn: true,
            location: { type: 'Point', coordinates: [longitude, latitude] },
            locationUpdatedAt: new Date()
        });

        return res.status(200).json({ message: 'Location updated' });
    } catch (error) {
        logger.error(`❌ Error updating location: ${error.message}`);
        res.status(500).json({ error: 'Failed to update location' });
    }
});

/**
 * Get nearby users
 * GET /api/friends/nearby?radiusKm=5&limit=20
 */
router.get('/nearby', authenticateToken, async (req, res) => {
    const { userId } = req.user;
    const radiusKm = parseFloat(req.query.radiusKm || '5');
    const limit = parseInt(req.query.limit || '20');
    const ageMin = req.query.ageMin ? parseInt(req.query.ageMin) : null;
    const ageMax = req.query.ageMax ? parseInt(req.query.ageMax) : null;
    const goal = req.query.goal || null;

    try {
        const me = await User.findById(userId).select('location nearbyOptIn');
        if (!me?.nearbyOptIn || !me.location?.coordinates?.length) {
            return res.status(400).json({ error: 'Nearby is not enabled' });
        }

        const [lon, lat] = me.location.coordinates;

        const geoQuery = {
            _id: { $ne: me._id },
            nearbyOptIn: true
        };

        if (goal && ['lose', 'maintain', 'gain'].includes(goal)) {
            geoQuery.goals = goal;
        }

        if (ageMin !== null || ageMax !== null) {
            geoQuery['metrics.age'] = {};
            if (ageMin !== null) geoQuery['metrics.age'].$gte = ageMin;
            if (ageMax !== null) geoQuery['metrics.age'].$lte = ageMax;
        }

        const users = await User.aggregate([
            {
                $geoNear: {
                    near: { type: 'Point', coordinates: [lon, lat] },
                    distanceField: 'distanceMeters',
                    maxDistance: radiusKm * 1000,
                    spherical: true,
                    query: geoQuery
                }
            },
            { $limit: limit },
            {
                $project: {
                    _id: 1,
                    name: 1,
                    profileImageUrl: 1,
                    distanceMeters: 1
                }
            }
        ]);

        const results = await Promise.all(users.map(async (user) => {
            const friendship = await Friend.findOne({
                $or: [
                    { userId, friendId: user._id },
                    { userId: user._id, friendId: userId }
                ]
            });

            let friendStatus = 'not_friends';
            if (friendship) {
                if (friendship.status === 'accepted') {
                    friendStatus = 'friends';
                } else if (friendship.status === 'pending') {
                    if (friendship.userId.toString() === userId) {
                        friendStatus = 'request_sent';
                    } else {
                        friendStatus = 'request_received';
                    }
                }
            }

            return {
                id: user._id.toString(),
                username: user.name,
                fullName: user.name,
                profileImageUrl: user.profileImageUrl || null,
                friendStatus,
                distanceMeters: user.distanceMeters
            };
        }));

        res.status(200).json({ results, count: results.length });
    } catch (error) {
        logger.error(`❌ Error fetching nearby users: ${error.message}`);
        res.status(500).json({ error: 'Failed to fetch nearby users' });
    }
});

// MARK: - Block User

/**
 * Block a user
 * POST /api/friends/block/:userId
 */
router.post('/block/:userId', authenticateToken, async (req, res) => {
    const { userId } = req.user;
    const { userId: blockUserId } = req.params;
    
    try {
        // Remove any existing friendship
        await Friend.deleteMany({
            $or: [
                { userId, friendId: blockUserId },
                { userId: blockUserId, friendId: userId }
            ]
        });
        
        // Create a blocked relationship
        const blockedRelationship = new Friend({
            userId,
            friendId: blockUserId,
            status: 'blocked'
        });
        
        await blockedRelationship.save();
        
        logger.log(`✅ User blocked: ${userId} blocked ${blockUserId}`);
        
        res.status(200).json({ message: 'User blocked successfully' });
    } catch (error) {
        logger.error(`❌ Error blocking user: ${error.message}`);
        res.status(500).json({ error: 'Failed to block user' });
    }
});

/**
 * Unblock a user
 * DELETE /api/friends/block/:userId
 */
router.delete('/block/:userId', authenticateToken, async (req, res) => {
    const { userId } = req.user;
    const { userId: unblockUserId } = req.params;
    
    try {
        const result = await Friend.findOneAndDelete({
            userId,
            friendId: unblockUserId,
            status: 'blocked'
        });
        
        if (!result) {
            return res.status(404).json({ error: 'Blocked user not found' });
        }
        
        logger.log(`✅ User unblocked: ${userId} unblocked ${unblockUserId}`);
        
        res.status(200).json({ message: 'User unblocked successfully' });
    } catch (error) {
        logger.error(`❌ Error unblocking user: ${error.message}`);
        res.status(500).json({ error: 'Failed to unblock user' });
    }
});

/**
 * Get friend statistics
 * GET /api/friends/stats/:friendId
 */
router.get('/stats/:friendId', authenticateToken, async (req, res) => {
    const { friendId } = req.params;
    
    try {
        // Get friend's metrics from their user profile
        const friend = await User.findById(friendId).select('metrics subscription');
        
        if (!friend) {
            return res.status(404).json({ error: 'Friend not found' });
        }
        
        const stats = {
            metrics: friend.metrics || {},
            subscription: friend.subscription || {}
        };
        
        res.status(200).json({ stats });
    } catch (error) {
        logger.error(`❌ Error fetching friend stats: ${error.message}`);
        res.status(500).json({ error: 'Failed to fetch friend stats' });
    }
});

export default router;
