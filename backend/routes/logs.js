import express from 'express';
import pool from '../config/database.js';
import { authenticateToken } from '../middleware/auth.js';

const router = express.Router();

/**
 * Share a meal log with friends
 * POST /api/logs/meal/share
 */
router.post('/meal/share', authenticateToken, async (req, res) => {
  try {
    const { mealId, visibility, sharedWith } = req.body;
    const userId = req.user.id;

    if (!mealId || !visibility) {
      return res.status(400).json({ message: 'Missing required fields' });
    }

    const validVisibility = ['private', 'friends_only', 'public'];
    if (!validVisibility.includes(visibility)) {
      return res.status(400).json({ message: 'Invalid visibility setting' });
    }

    // Create activity log for shared meal
    const result = await pool.query(
      `INSERT INTO activity_logs (user_id, type, title, visibility, shared_with, created_at)
       SELECT $1, 'meal', title, $2, $3, NOW()
       FROM meals WHERE id = $4 AND user_id = $1
       RETURNING *`,
      [userId, visibility, sharedWith || [], mealId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'Meal not found' });
    }

    // Award points for sharing
    await pool.query(
      'INSERT INTO gamification_points (user_id, action_type, points, created_at) VALUES ($1, $2, $3, NOW())',
      [userId, 'share_log', 10]
    );

    res.json({
      message: 'Meal shared successfully',
      log: result.rows[0]
    });
  } catch (error) {
    console.error('Share meal error:', error);
    res.status(500).json({ message: 'Error sharing meal' });
  }
});

/**
 * Share a workout log with friends
 * POST /api/logs/workout/share
 */
router.post('/workout/share', authenticateToken, async (req, res) => {
  try {
    const { workoutId, visibility, sharedWith } = req.body;
    const userId = req.user.id;

    if (!workoutId || !visibility) {
      return res.status(400).json({ message: 'Missing required fields' });
    }

    const validVisibility = ['private', 'friends_only', 'public'];
    if (!validVisibility.includes(visibility)) {
      return res.status(400).json({ message: 'Invalid visibility setting' });
    }

    // Create activity log for shared workout
    const result = await pool.query(
      `INSERT INTO activity_logs (user_id, type, title, visibility, shared_with, created_at)
       SELECT $1, 'workout', name, $2, $3, NOW()
       FROM workouts WHERE id = $4 AND user_id = $1
       RETURNING *`,
      [userId, visibility, sharedWith || [], workoutId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'Workout not found' });
    }

    // Award points for sharing
    await pool.query(
      'INSERT INTO gamification_points (user_id, action_type, points, created_at) VALUES ($1, $2, $3, NOW())',
      [userId, 'share_log', 10]
    );

    res.json({
      message: 'Workout shared successfully',
      log: result.rows[0]
    });
  } catch (error) {
    console.error('Share workout error:', error);
    res.status(500).json({ message: 'Error sharing workout' });
  }
});

/**
 * Get shared logs from friends
 * GET /api/logs/friends
 */
router.get('/friends', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;

    const result = await pool.query(
      `SELECT al.*, u.username
       FROM activity_logs al
       JOIN users u ON al.user_id = u.id
       JOIN friendships f ON (f.friend_id = al.user_id AND f.user_id = $1 AND f.status = 'accepted')
       WHERE al.visibility IN ('friends_only', 'public')
       OR (al.visibility = 'friends_only' AND al.shared_with @> ARRAY[$1])
       ORDER BY al.created_at DESC
       LIMIT 50`,
      [userId]
    );

    res.json({
      logs: result.rows
    });
  } catch (error) {
    console.error('Get friends logs error:', error);
    res.status(500).json({ message: 'Error fetching shared logs' });
  }
});

/**
 * Get activity feed (own + friends activities)
 * GET /api/logs/feed
 */
router.get('/feed', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;

    const result = await pool.query(
      `SELECT al.id, al.user_id, u.username, al.type, al.title, al.visibility, 
              al.created_at, al.updated_at,
              CASE WHEN al.user_id = $1 THEN true ELSE false END as is_own_activity
       FROM activity_logs al
       JOIN users u ON al.user_id = u.id
       WHERE al.user_id = $1  -- Own activities
       OR (al.visibility = 'public')  -- Public activities
       OR (al.visibility = 'friends_only' AND 
           EXISTS (SELECT 1 FROM friendships 
                   WHERE user_id = $1 AND friend_id = al.user_id AND status = 'accepted'))
       OR (al.visibility = 'friends_only' AND al.shared_with @> ARRAY[$1])
       ORDER BY al.created_at DESC
       LIMIT 100`,
      [userId]
    );

    res.json({
      feed: result.rows
    });
  } catch (error) {
    console.error('Get activity feed error:', error);
    res.status(500).json({ message: 'Error fetching activity feed' });
  }
});

/**
 * Update log visibility settings
 * POST /api/logs/:logId/visibility
 */
router.post('/:logId/visibility', authenticateToken, async (req, res) => {
  try {
    const { logId } = req.params;
    const { visibility, sharedWith } = req.body;
    const userId = req.user.id;

    if (!visibility) {
      return res.status(400).json({ message: 'Visibility is required' });
    }

    // Verify user owns this log
    const logResult = await pool.query(
      'SELECT * FROM activity_logs WHERE id = $1 AND user_id = $2',
      [logId, userId]
    );

    if (logResult.rows.length === 0) {
      return res.status(404).json({ message: 'Log not found or unauthorized' });
    }

    const result = await pool.query(
      `UPDATE activity_logs 
       SET visibility = $1, shared_with = $2, updated_at = NOW()
       WHERE id = $3 AND user_id = $4
       RETURNING *`,
      [visibility, sharedWith || [], logId, userId]
    );

    res.json({
      message: 'Log visibility updated',
      log: result.rows[0]
    });
  } catch (error) {
    console.error('Update visibility error:', error);
    res.status(500).json({ message: 'Error updating visibility' });
  }
});

/**
 * Delete a shared log
 * DELETE /api/logs/:logId
 */
router.delete('/:logId', authenticateToken, async (req, res) => {
  try {
    const { logId } = req.params;
    const userId = req.user.id;

    const result = await pool.query(
      'DELETE FROM activity_logs WHERE id = $1 AND user_id = $2 RETURNING id',
      [logId, userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'Log not found or unauthorized' });
    }

    res.json({ message: 'Log deleted successfully' });
  } catch (error) {
    console.error('Delete log error:', error);
    res.status(500).json({ message: 'Error deleting log' });
  }
});

export default router;
