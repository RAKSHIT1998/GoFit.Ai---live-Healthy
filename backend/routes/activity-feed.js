import express from 'express';
import SharedActivity from '../models/SharedActivity.js';
import Friend from '../models/Friend.js';
import Workout from '../models/Workout.js';
import Meal from '../models/Meal.js';
import ProgressPhoto from '../models/ProgressPhoto.js';
import { authenticateToken } from '../middleware/authMiddleware.js';
import { wsService } from '../services/websocketService.js';

const router = express.Router();
const logger = console;

/**
 * Activity Sharing/Feed System API Endpoints
 */

/**
 * Get activity feed from all friends
 * GET /api/activity-feed?limit=20&skip=0
 */
router.get('/', authenticateToken, async (req, res) => {
  const { userId } = req.user;
  const { limit = 20, skip = 0 } = req.query;

  try {
    // Get all friends
    const friendships = await Friend.find({
      $or: [
        { userId, status: 'accepted' },
        { friendId: userId, status: 'accepted' }
      ]
    });

    const friendIds = friendships.map(f => 
      f.userId.toString() === userId ? f.friendId : f.userId
    );

    // Get activity feed from friends
    const activities = await SharedActivity.find({
      userId: { $in: friendIds }
    })
    .populate('userId', 'name profileImageUrl')
    .sort({ createdAt: -1 })
    .skip(parseInt(skip))
    .limit(parseInt(limit));

    res.status(200).json({
      activities: activities.map(activity => ({
        id: activity._id.toString(),
        userId: activity.userId._id.toString(),
        userName: activity.userId.name,
        userImage: activity.userId.profileImageUrl || null,
        activityType: activity.activityType,
        title: activity.title,
        description: activity.description,
        metadata: activity.metadata,
        reactions: activity.reactions,
        viewCount: activity.viewedBy.length,
        isViewed: activity.viewedBy.some(v => v.userId.toString() === userId),
        createdAt: activity.createdAt
      })),
      count: activities.length
    });
  } catch (error) {
    logger.error(`❌ Error fetching activity feed: ${error.message}`);
    res.status(500).json({ error: 'Failed to fetch activity feed' });
  }
});

/**
 * Share a workout
 * POST /api/activity-feed/share/workout/:workoutId
 */
router.post('/share/workout/:workoutId', authenticateToken, async (req, res) => {
  const { userId } = req.user;
  const { workoutId } = req.params;
  const { title, description } = req.body;

  try {
    const workout = await Workout.findById(workoutId);
    if (!workout) {
      return res.status(404).json({ error: 'Workout not found' });
    }

    // Get all friends
    const friendships = await Friend.find({
      $or: [
        { userId, status: 'accepted' },
        { friendId: userId, status: 'accepted' }
      ]
    });

    const friendIds = friendships.map(f => 
      f.userId.toString() === userId ? f.friendId : f.userId
    );

    // Share with each friend
    const sharedActivities = await Promise.all(
      friendIds.map(friendId => {
        const activity = new SharedActivity({
          userId,
          friendId,
          activityType: 'workout',
          activityId: workoutId,
          title: title || `${workout.exerciseName} Workout`,
          description: description || `Completed ${workout.exerciseName}`,
          metadata: {
            exerciseName: workout.exerciseName,
            duration: workout.duration,
            calories: workout.caloriesBurned,
            intensity: workout.intensity
          }
        });
        return activity.save();
      })
    );

    logger.log(`🏋️ Workout shared with ${friendIds.length} friends`);

    // Emit WebSocket notifications to all friends
    friendIds.forEach(friendId => {
      wsService.emitActivityShared(friendId, {
        activityType: 'workout',
        userId: userId.toString(),
        title: title || `${workout.exerciseName} Workout`,
        metadata: sharedActivities[0].metadata
      });
    });

    res.status(201).json({
      message: 'Workout shared successfully',
      sharedWith: friendIds.length
    });
  } catch (error) {
    logger.error(`❌ Error sharing workout: ${error.message}`);
    res.status(500).json({ error: 'Failed to share workout' });
  }
});

/**
 * Share a meal
 * POST /api/activity-feed/share/meal/:mealId
 */
router.post('/share/meal/:mealId', authenticateToken, async (req, res) => {
  const { userId } = req.user;
  const { mealId } = req.params;
  const { title, description } = req.body;

  try {
    const meal = await Meal.findById(mealId);
    if (!meal) {
      return res.status(404).json({ error: 'Meal not found' });
    }

    // Get all friends
    const friendships = await Friend.find({
      $or: [
        { userId, status: 'accepted' },
        { friendId: userId, status: 'accepted' }
      ]
    });

    const friendIds = friendships.map(f => 
      f.userId.toString() === userId ? f.friendId : f.userId
    );

    // Share with each friend
    const sharedActivities = await Promise.all(
      friendIds.map(friendId => {
        const activity = new SharedActivity({
          userId,
          friendId,
          activityType: 'meal',
          activityId: mealId,
          title: title || meal.mealName || 'Meal Logged',
          description: description || `Logged a ${meal.mealType}`,
          metadata: {
            mealName: meal.mealName,
            mealType: meal.mealType,
            calories: meal.totalCalories,
            protein: meal.totalProtein,
            carbs: meal.totalCarbs,
            fats: meal.totalFats
          }
        });
        return activity.save();
      })
    );

    logger.log(`🍽️ Meal shared with ${friendIds.length} friends`);

    // Emit WebSocket notifications
    friendIds.forEach(friendId => {
      wsService.emitActivityShared(friendId, {
        activityType: 'meal',
        userId: userId.toString(),
        title: title || meal.mealName || 'Meal Logged',
        metadata: sharedActivities[0].metadata
      });
    });

    res.status(201).json({
      message: 'Meal shared successfully',
      sharedWith: friendIds.length
    });
  } catch (error) {
    logger.error(`❌ Error sharing meal: ${error.message}`);
    res.status(500).json({ error: 'Failed to share meal' });
  }
});

/**
 * React to an activity
 * POST /api/activity-feed/:activityId/react
 */
router.post('/:activityId/react', authenticateToken, async (req, res) => {
  const { userId } = req.user;
  const { activityId } = req.params;
  const { reaction } = req.body; // 'fire', 'love', 'wow', 'like', 'rocket'

  try {
    const activity = await SharedActivity.findById(activityId);
    if (!activity) {
      return res.status(404).json({ error: 'Activity not found' });
    }

    // Remove existing reaction from this user
    activity.reactions = activity.reactions.filter(
      r => r.userId.toString() !== userId
    );

    // Add new reaction
    activity.reactions.push({
      userId,
      reaction,
      createdAt: new Date()
    });

    await activity.save();

    logger.log(`💬 Reaction added to activity by ${userId}`);

    // Notify the activity creator
    wsService.emitActivityReaction(activity.userId, {
      activityId: activityId,
      reaction,
      fromUser: userId
    });

    res.status(200).json({
      message: 'Reaction added',
      reactions: activity.reactions
    });
  } catch (error) {
    logger.error(`❌ Error adding reaction: ${error.message}`);
    res.status(500).json({ error: 'Failed to add reaction' });
  }
});

/**
 * Mark activity as viewed
 * POST /api/activity-feed/:activityId/view
 */
router.post('/:activityId/view', authenticateToken, async (req, res) => {
  const { userId } = req.user;
  const { activityId } = req.params;

  try {
    const activity = await SharedActivity.findById(activityId);
    if (!activity) {
      return res.status(404).json({ error: 'Activity not found' });
    }

    // Check if already viewed
    const alreadyViewed = activity.viewedBy.some(
      v => v.userId.toString() === userId
    );

    if (!alreadyViewed) {
      activity.viewedBy.push({
        userId,
        viewedAt: new Date()
      });
      await activity.save();
    }

    res.status(200).json({ message: 'Activity marked as viewed' });
  } catch (error) {
    logger.error(`❌ Error marking activity as viewed: ${error.message}`);
    res.status(500).json({ error: 'Failed to mark activity as viewed' });
  }
});

/**
 * Get activity stats for a friend
 * GET /api/activity-feed/friend/:friendId/stats
 */
router.get('/friend/:friendId/stats', authenticateToken, async (req, res) => {
  const { friendId } = req.params;

  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const stats = {
      todayWorkouts: await SharedActivity.countDocuments({
        userId: friendId,
        activityType: 'workout',
        createdAt: { $gte: today }
      }),
      todayMeals: await SharedActivity.countDocuments({
        userId: friendId,
        activityType: 'meal',
        createdAt: { $gte: today }
      }),
      thisWeekWorkouts: await SharedActivity.countDocuments({
        userId: friendId,
        activityType: 'workout',
        createdAt: {
          $gte: new Date(today.getTime() - 7 * 24 * 60 * 60 * 1000)
        }
      }),
      streak: 0 // TODO: Calculate workout streak
    };

    res.status(200).json({ stats });
  } catch (error) {
    logger.error(`❌ Error fetching friend stats: ${error.message}`);
    res.status(500).json({ error: 'Failed to fetch friend stats' });
  }
});

export default router;
