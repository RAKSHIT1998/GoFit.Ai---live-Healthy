import express from 'express';
import User from '../models/User.js';
import Activity from '../models/Activity.js';
import Friend from '../models/Friend.js';
import { authenticateToken } from '../middleware/authMiddleware.js';
import { wsService } from '../services/websocketService.js';

const router = express.Router();
const logger = console;

/**
 * Activity Feed API Endpoints
 * Real-time sharing of workouts, meals, and achievements with friends
 */

// MARK: - Post Activity

/**
 * Log a workout and share with friends
 * POST /api/activity/workout
 */
router.post('/workout', authenticateToken, async (req, res) => {
    const { userId } = req.user;
    const { exerciseName, duration, calories, distance, notes } = req.body;
    
    try {
        if (!exerciseName || !duration) {
            return res.status(400).json({ error: 'Exercise name and duration are required' });
        }
        
        // Create activity
        const activity = new Activity({
            userId,
            activityType: 'workout',
            linkedId: new Date().getTime(), // Use timestamp as placeholder ID
            summary: {
                title: `Completed ${exerciseName}`,
                description: `${duration} minutes · ${calories || 0} calories`,
                icon: '🏋️',
                color: '#FF6B6B'
            },
            stats: {
                exerciseName,
                duration,
                calories,
                distance
            },
            visibility: 'friends'
        });
        
        await activity.save();
        
        // Broadcast to all friends
        const friendships = await Friend.find({
            $or: [
                { userId, status: 'accepted' },
                { friendId: userId, status: 'accepted' }
            ]
        });
        
        friendships.forEach(friendship => {
            const friendId = friendship.userId.toString() === userId ? friendship.friendId.toString() : friendship.userId.toString();
            
            wsService.emitActivity(friendId, {
                activityId: activity._id.toString(),
                userId,
                activityType: 'workout',
                summary: activity.summary,
                stats: activity.stats,
                createdAt: activity.createdAt
            });
        });
        
        logger.log(`✅ Workout logged and shared: ${exerciseName}`);
        
        res.status(201).json({
            activity: {
                id: activity._id.toString(),
                type: 'workout',
                summary: activity.summary,
                stats: activity.stats
            }
        });
    } catch (error) {
        logger.error(`❌ Error logging workout: ${error.message}`);
        res.status(500).json({ error: 'Failed to log workout' });
    }
});

/**
 * Log a meal and share with friends
 * POST /api/activity/meal
 */
router.post('/meal', authenticateToken, async (req, res) => {
    const { userId } = req.user;
    const { mealName, calories, protein, carbs, fat, notes } = req.body;
    
    try {
        if (!mealName || !calories) {
            return res.status(400).json({ error: 'Meal name and calories are required' });
        }
        
        // Create activity
        const activity = new Activity({
            userId,
            activityType: 'meal',
            linkedId: new Date().getTime(),
            summary: {
                title: `Logged ${mealName}`,
                description: `${calories} cal · ${protein || 0}g protein`,
                icon: '🍽️',
                color: '#4ECDC4'
            },
            stats: {
                calories,
                protein,
                carbs,
                fat
            },
            visibility: 'friends'
        });
        
        await activity.save();
        
        // Broadcast to all friends
        const friendships = await Friend.find({
            $or: [
                { userId, status: 'accepted' },
                { friendId: userId, status: 'accepted' }
            ]
        });
        
        friendships.forEach(friendship => {
            const friendId = friendship.userId.toString() === userId ? friendship.friendId.toString() : friendship.userId.toString();
            
            wsService.emitActivity(friendId, {
                activityId: activity._id.toString(),
                userId,
                activityType: 'meal',
                summary: activity.summary,
                stats: activity.stats,
                createdAt: activity.createdAt
            });
        });
        
        logger.log(`✅ Meal logged and shared: ${mealName}`);
        
        res.status(201).json({
            activity: {
                id: activity._id.toString(),
                type: 'meal',
                summary: activity.summary,
                stats: activity.stats
            }
        });
    } catch (error) {
        logger.error(`❌ Error logging meal: ${error.message}`);
        res.status(500).json({ error: 'Failed to log meal' });
    }
});

/**
 * Get activity feed for current user (friends' activities)
 * GET /api/activity/feed?limit=20&offset=0
 */
router.get('/feed', authenticateToken, async (req, res) => {
    const { userId } = req.user;
    const { limit = 20, offset = 0 } = req.query;
    
    try {
        // Get all accepted friends
        const friendships = await Friend.find({
            $or: [
                { userId, status: 'accepted' },
                { friendId: userId, status: 'accepted' }
            ]
        });
        
        const friendIds = friendships.map(f => 
            f.userId.toString() === userId ? f.friendId : f.userId
        );
        
        // Get activities from friends
        const activities = await Activity.find({
            userId: { $in: friendIds },
            visibility: { $in: ['friends', 'public'] }
        })
        .populate('userId', 'name profileImageUrl email')
        .populate('likes', 'name profileImageUrl')
        .sort({ createdAt: -1 })
        .skip(parseInt(offset))
        .limit(parseInt(limit));
        
        const formattedActivities = activities.map(activity => ({
            id: activity._id.toString(),
            user: {
                id: activity.userId._id.toString(),
                name: activity.userId.name,
                profileImageUrl: activity.userId.profileImageUrl || null
            },
            activityType: activity.activityType,
            summary: activity.summary,
            stats: activity.stats,
            likes: activity.likes.map(u => ({
                id: u._id.toString(),
                name: u.name,
                profileImageUrl: u.profileImageUrl || null
            })),
            likeCount: activity.likes.length,
            isLikedByMe: activity.likes.some(u => u._id.toString() === userId),
            commentCount: activity.comments.length,
            createdAt: activity.createdAt
        }));
        
        res.status(200).json({
            activities: formattedActivities,
            count: formattedActivities.length
        });
    } catch (error) {
        logger.error(`❌ Error fetching activity feed: ${error.message}`);
        res.status(500).json({ error: 'Failed to fetch activity feed' });
    }
});

/**
 * Like an activity
 * POST /api/activity/:activityId/like
 */
router.post('/:activityId/like', authenticateToken, async (req, res) => {
    const { userId } = req.user;
    const { activityId } = req.params;
    
    try {
        const activity = await Activity.findById(activityId);
        
        if (!activity) {
            return res.status(404).json({ error: 'Activity not found' });
        }
        
        const alreadyLiked = activity.likes.some(u => u.toString() === userId);
        
        if (alreadyLiked) {
            // Unlike
            activity.likes = activity.likes.filter(u => u.toString() !== userId);
        } else {
            // Like
            activity.likes.push(userId);
            
            // 🔥 Notify activity owner
            wsService.emitActivityLike(activity.userId.toString(), {
                activityId: activityId,
                userId,
                message: `Someone liked your activity!`
            });
        }
        
        await activity.save();
        
        logger.log(`✅ Activity ${alreadyLiked ? 'unliked' : 'liked'}: ${activityId}`);
        
        res.status(200).json({
            liked: !alreadyLiked,
            likeCount: activity.likes.length
        });
    } catch (error) {
        logger.error(`❌ Error liking activity: ${error.message}`);
        res.status(500).json({ error: 'Failed to like activity' });
    }
});

/**
 * Comment on an activity
 * POST /api/activity/:activityId/comment
 */
router.post('/:activityId/comment', authenticateToken, async (req, res) => {
    const { userId } = req.user;
    const { activityId } = req.params;
    const { text } = req.body;
    
    try {
        if (!text || text.trim().length === 0) {
            return res.status(400).json({ error: 'Comment text is required' });
        }
        
        const activity = await Activity.findById(activityId);
        
        if (!activity) {
            return res.status(404).json({ error: 'Activity not found' });
        }
        
        const comment = {
            userId,
            text: text.trim(),
            createdAt: new Date()
        };
        
        activity.comments.push(comment);
        await activity.save();
        
        // 🔥 Notify activity owner
        const user = await User.findById(userId).select('name profileImageUrl');
        wsService.emitActivityComment(activity.userId.toString(), {
            activityId: activityId,
            userId,
            userName: user.name,
            comment: text,
            message: `${user.name} commented on your activity: "${text}"`
        });
        
        logger.log(`✅ Comment added to activity: ${activityId}`);
        
        res.status(201).json({
            comment: {
                userId,
                text,
                createdAt: new Date()
            }
        });
    } catch (error) {
        logger.error(`❌ Error adding comment: ${error.message}`);
        res.status(500).json({ error: 'Failed to add comment' });
    }
});

/**
 * Get suggested friends based on goals and interests
 * GET /api/activity/suggestions
 */
router.get('/suggestions', authenticateToken, async (req, res) => {
    const { userId } = req.user;
    
    try {
        // Get current user's profile
        const currentUser = await User.findById(userId);
        
        if (!currentUser) {
            return res.status(404).json({ error: 'User not found' });
        }
        
        // Find users with similar goals and activity level
        const suggestions = await User.find({
            _id: { $ne: userId },
            goals: currentUser.goals,
            activityLevel: currentUser.activityLevel
        })
        .select('_id name email profileImageUrl goals activityLevel')
        .limit(10);
        
        // Filter out already-connected users
        const suggestedUsers = await Promise.all(
            suggestions.map(async (user) => {
                const existingFriendship = await Friend.findOne({
                    $or: [
                        { userId, friendId: user._id },
                        { userId: user._id, friendId: userId }
                    ]
                });
                
                if (!existingFriendship) {
                    return {
                        id: user._id.toString(),
                        name: user.name,
                        email: user.email,
                        profileImageUrl: user.profileImageUrl || null,
                        goals: user.goals,
                        activityLevel: user.activityLevel,
                        matchReason: 'Similar goals and activity level'
                    };
                }
                return null;
            })
        );
        
        const filteredSuggestions = suggestedUsers.filter(s => s !== null);
        
        res.status(200).json({
            suggestions: filteredSuggestions,
            count: filteredSuggestions.length
        });
    } catch (error) {
        logger.error(`❌ Error fetching suggestions: ${error.message}`);
        res.status(500).json({ error: 'Failed to fetch suggestions' });
    }
});

export default router;
