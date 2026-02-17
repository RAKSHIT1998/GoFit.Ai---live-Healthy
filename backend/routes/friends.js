const express = require('express');
const router = express.Router();
const db = require('../config/database');
const { authenticateToken } = require('../middleware/auth');
const logger = require('../utils/logger');

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
        const userExists = await db.query(
            'SELECT id FROM users WHERE id = $1',
            [targetUserId]
        );
        
        if (userExists.rows.length === 0) {
            return res.status(404).json({ error: 'User not found' });
        }
        
        // Check if already friends or pending
        const existingRelationship = await db.query(
            'SELECT id, status FROM friends WHERE (user_id = $1 AND friend_id = $2) OR (user_id = $2 AND friend_id = $1)',
            [userId, targetUserId]
        );
        
        if (existingRelationship.rows.length > 0) {
            const existing = existingRelationship.rows[0];
            if (existing.status === 'accepted') {
                return res.status(400).json({ error: 'Already friends' });
            }
            if (existing.status === 'pending') {
                return res.status(400).json({ error: 'Friend request already pending' });
            }
        }
        
        // Create friend request
        const result = await db.query(
            `INSERT INTO friends (id, user_id, friend_id, status, created_at) 
             VALUES (gen_random_uuid(), $1, $2, 'pending', NOW())
             RETURNING id, status`,
            [userId, targetUserId]
        );
        
        logger.info(`Friend request sent from ${userId} to ${targetUserId}`);
        
        res.status(201).json({
            message: 'Friend request sent',
            friendRequest: result.rows[0]
        });
    } catch (error) {
        logger.error(`Error sending friend request: ${error.message}`);
        res.status(500).json({ error: 'Failed to send friend request' });
    }
});

/**
 * Get pending friend requests
 * GET /api/friends/requests
 */
router.get('/requests', authenticateToken, async (req, res) => {
    const { userId } = req.user;
    
    try {
        const result = await db.query(
            `SELECT 
                f.id,
                f.user_id,
                u.id as requester_id,
                u.username,
                u.email,
                u.profile_image_url,
                f.created_at
             FROM friends f
             JOIN users u ON f.user_id = u.id
             WHERE f.friend_id = $1 AND f.status = 'pending'
             ORDER BY f.created_at DESC`,
            [userId]
        );
        
        res.status(200).json({
            requests: result.rows
        });
    } catch (error) {
        logger.error(`Error fetching friend requests: ${error.message}`);
        res.status(500).json({ error: 'Failed to fetch friend requests' });
    }
});

/**
 * Accept friend request
 * POST /api/friends/accept/:friendId
 */
router.post('/accept/:friendId', authenticateToken, async (req, res) => {
    const { userId } = req.user;
    const { friendId } = req.params;
    
    try {
        const result = await db.query(
            `UPDATE friends 
             SET status = 'accepted'
             WHERE user_id = $1 AND friend_id = $2 AND status = 'pending'
             RETURNING id, status`,
            [friendId, userId]
        );
        
        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Friend request not found' });
        }
        
        logger.info(`Friend request accepted: ${friendId} <-> ${userId}`);
        
        res.status(200).json({
            message: 'Friend request accepted',
            friendship: result.rows[0]
        });
    } catch (error) {
        logger.error(`Error accepting friend request: ${error.message}`);
        res.status(500).json({ error: 'Failed to accept friend request' });
    }
});

/**
 * Reject friend request
 * POST /api/friends/reject/:friendId
 */
router.post('/reject/:friendId', authenticateToken, async (req, res) => {
    const { userId } = req.user;
    const { friendId } = req.params;
    
    try {
        const result = await db.query(
            `DELETE FROM friends 
             WHERE user_id = $1 AND friend_id = $2 AND status = 'pending'
             RETURNING id`,
            [friendId, userId]
        );
        
        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Friend request not found' });
        }
        
        logger.info(`Friend request rejected: ${friendId} rejected ${userId}`);
        
        res.status(200).json({
            message: 'Friend request rejected'
        });
    } catch (error) {
        logger.error(`Error rejecting friend request: ${error.message}`);
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
        const result = await db.query(
            `SELECT DISTINCT
                CASE 
                    WHEN f.user_id = $1 THEN f.friend_id 
                    ELSE f.user_id 
                END as friend_id,
                u.username,
                u.email,
                u.profile_image_url,
                u.full_name
             FROM friends f
             JOIN users u ON (
                (f.user_id = $1 AND f.friend_id = u.id) OR
                (f.friend_id = $1 AND f.user_id = u.id)
             )
             WHERE f.status = 'accepted'
             ORDER BY u.username ASC`,
            [userId]
        );
        
        res.status(200).json({
            friends: result.rows,
            count: result.rows.length
        });
    } catch (error) {
        logger.error(`Error fetching friends list: ${error.message}`);
        res.status(500).json({ error: 'Failed to fetch friends list' });
    }
});

/**
 * Remove friend
 * DELETE /api/friends/:friendId
 */
router.delete('/:friendId', authenticateToken, async (req, res) => {
    const { userId } = req.user;
    const { friendId } = req.params;
    
    try {
        const result = await db.query(
            `DELETE FROM friends 
             WHERE (user_id = $1 AND friend_id = $2 AND status = 'accepted') 
                OR (user_id = $2 AND friend_id = $1 AND status = 'accepted')
             RETURNING id`,
            [userId, friendId]
        );
        
        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Friendship not found' });
        }
        
        logger.info(`Friend removed: ${userId} removed ${friendId}`);
        
        res.status(200).json({
            message: 'Friend removed successfully'
        });
    } catch (error) {
        logger.error(`Error removing friend: ${error.message}`);
        res.status(500).json({ error: 'Failed to remove friend' });
    }
});

// MARK: - Search Friends

/**
 * Search users by username, email, or full name
 * GET /api/friends/search?q=<query>&limit=20
 */
router.get('/search', authenticateToken, async (req, res) => {
    const { userId } = req.user;
    const { q, limit = 20 } = req.query;
    
    try {
        if (!q || q.length < 2) {
            return res.status(400).json({ error: 'Search query must be at least 2 characters' });
        }
        
        const searchQuery = `%${q}%`;
        
        const result = await db.query(
            `SELECT DISTINCT
                u.id,
                u.username,
                u.email,
                u.profile_image_url,
                u.full_name,
                CASE 
                    WHEN f.status = 'accepted' THEN 'friends'
                    WHEN f.status = 'pending' AND f.user_id = $1 THEN 'request_sent'
                    WHEN f.status = 'pending' AND f.friend_id = $1 THEN 'request_received'
                    ELSE 'not_friends'
                END as friend_status
             FROM users u
             LEFT JOIN friends f ON (
                (f.user_id = $1 AND f.friend_id = u.id) OR
                (f.friend_id = $1 AND f.user_id = u.id)
             )
             WHERE (u.username ILIKE $2 OR u.email ILIKE $2 OR u.full_name ILIKE $2)
                AND u.id != $1
             ORDER BY 
                CASE 
                    WHEN u.username ILIKE $2 THEN 1
                    WHEN u.email ILIKE $2 THEN 2
                    ELSE 3
                END,
                u.username ASC
             LIMIT $3`,
            [userId, searchQuery, limit]
        );
        
        res.status(200).json({
            results: result.rows,
            count: result.rows.length
        });
    } catch (error) {
        logger.error(`Error searching users: ${error.message}`);
        res.status(500).json({ error: 'Failed to search users' });
    }
});

// MARK: - Block User

/**
 * Block a user
 * POST /api/friends/block/:blockedUserId
 */
router.post('/block/:blockedUserId', authenticateToken, async (req, res) => {
    const { userId } = req.user;
    const { blockedUserId } = req.params;
    
    try {
        if (userId === blockedUserId) {
            return res.status(400).json({ error: 'Cannot block yourself' });
        }
        
        // Delete existing friendship if any
        await db.query(
            `DELETE FROM friends 
             WHERE (user_id = $1 AND friend_id = $2) OR (user_id = $2 AND friend_id = $1)`,
            [userId, blockedUserId]
        );
        
        // Create blocked relationship
        const result = await db.query(
            `INSERT INTO friends (id, user_id, friend_id, status, created_at) 
             VALUES (gen_random_uuid(), $1, $2, 'blocked', NOW())
             RETURNING id, status`,
            [userId, blockedUserId]
        );
        
        logger.info(`User blocked: ${userId} blocked ${blockedUserId}`);
        
        res.status(201).json({
            message: 'User blocked successfully',
            blocked: result.rows[0]
        });
    } catch (error) {
        logger.error(`Error blocking user: ${error.message}`);
        res.status(500).json({ error: 'Failed to block user' });
    }
});

/**
 * Unblock a user
 * POST /api/friends/unblock/:blockedUserId
 */
router.post('/unblock/:blockedUserId', authenticateToken, async (req, res) => {
    const { userId } = req.user;
    const { blockedUserId } = req.params;
    
    try {
        const result = await db.query(
            `DELETE FROM friends 
             WHERE user_id = $1 AND friend_id = $2 AND status = 'blocked'
             RETURNING id`,
            [userId, blockedUserId]
        );
        
        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'User not found in block list' });
        }
        
        logger.info(`User unblocked: ${userId} unblocked ${blockedUserId}`);
        
        res.status(200).json({
            message: 'User unblocked successfully'
        });
    } catch (error) {
        logger.error(`Error unblocking user: ${error.message}`);
        res.status(500).json({ error: 'Failed to unblock user' });
    }
});

// MARK: - Friend Stats

/**
 * Get friend statistics
 * GET /api/friends/:friendId/stats
 */
router.get('/:friendId/stats', authenticateToken, async (req, res) => {
    const { userId } = req.user;
    const { friendId } = req.params;
    
    try {
        // Verify friendship
        const friendship = await db.query(
            `SELECT id FROM friends 
             WHERE (user_id = $1 AND friend_id = $2 AND status = 'accepted') OR
                   (user_id = $2 AND friend_id = $1 AND status = 'accepted')`,
            [userId, friendId]
        );
        
        if (friendship.rows.length === 0) {
            return res.status(403).json({ error: 'Not friends with this user' });
        }
        
        // Get friend stats (can be customized based on your data model)
        const stats = await db.query(
            `SELECT 
                (SELECT COUNT(*) FROM meals WHERE user_id = $1) as total_meals_logged,
                (SELECT COUNT(*) FROM workouts WHERE user_id = $1) as total_workouts_completed,
                (SELECT COALESCE(SUM(calories_burned), 0) FROM workouts WHERE user_id = $1) as total_calories_burned,
                (SELECT MAX(created_at) FROM meals WHERE user_id = $1) as last_meal_logged,
                (SELECT MAX(created_at) FROM workouts WHERE user_id = $1) as last_workout_completed`,
            [friendId]
        );
        
        res.status(200).json({
            stats: stats.rows[0]
        });
    } catch (error) {
        logger.error(`Error fetching friend stats: ${error.message}`);
        res.status(500).json({ error: 'Failed to fetch friend stats' });
    }
});

module.exports = router;
