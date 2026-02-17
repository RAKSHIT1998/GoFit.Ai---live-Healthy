import express from 'express';
import db from '../config/database.js';
import { authenticateToken } from '../middleware/authMiddleware.js';

const router = express.Router();

/**
 * Get user's gamification stats (badges, achievements, streaks)
 * GET /api/gamification/stats
 */
router.get('/stats', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.userId;

    // Get badges
    const badgesResult = await db.query(
      'SELECT * FROM badges WHERE user_id = $1 ORDER BY earned_at DESC',
      [userId]
    );

    // Get achievements
    const achievementsResult = await db.query(
      'SELECT * FROM achievements WHERE user_id = $1 ORDER BY earned_at DESC',
      [userId]
    );

    // Get current streak
    const streakResult = await db.query(
      'SELECT * FROM user_streaks WHERE user_id = $1 ORDER BY created_at DESC LIMIT 1',
      [userId]
    );

    // Calculate total points
    const pointsResult = await db.query(
      'SELECT COALESCE(SUM(points), 0) as total_points FROM achievements WHERE user_id = $1',
      [userId]
    );

    res.json({
      badges: {
        total: badgesResult.rows.length,
        recent: badgesResult.rows.slice(0, 5),
        all: badgesResult.rows
      },
      achievements: {
        total: achievementsResult.rows.length,
        recent: achievementsResult.rows.slice(0, 5),
        all: achievementsResult.rows
      },
      streaks: {
        current: streakResult.rows[0] || null
      },
      points: parseInt(pointsResult.rows[0].total_points) || 0
    });
  } catch (error) {
    console.error('Get gamification stats error:', error);
    res.status(500).json({ message: 'Error fetching gamification stats' });
  }
});

/**
 * Get global leaderboard
 * GET /api/gamification/leaderboard
 */
router.get('/leaderboard', authenticateToken, async (req, res) => {
  try {
    const { limit = 50, type = 'points' } = req.query;
    const userId = req.user.userId;

    let orderBy = 'total_points DESC';
    if (type === 'streaks') {
      orderBy = 'current_streak DESC';
    } else if (type === 'badges') {
      orderBy = 'badge_count DESC';
    }

    const result = await db.query(
      `SELECT 
        u.id,
        u.username,
        u.full_name,
        u.profile_image_url,
        COALESCE(SUM(a.points), 0) as total_points,
        COUNT(DISTINCT b.id) as badge_count,
        COALESCE(MAX(s.current_days), 0) as current_streak,
        CASE WHEN u.id = $1 THEN true ELSE false END as is_me
       FROM users u
       LEFT JOIN achievements a ON u.id = a.user_id
       LEFT JOIN badges b ON u.id = b.user_id
       LEFT JOIN user_streaks s ON u.id = s.user_id
       GROUP BY u.id, u.username, u.full_name, u.profile_image_url
       ORDER BY ${orderBy}
       LIMIT $2`,
      [userId, limit]
    );

    res.json({
      leaderboard: result.rows.map((row, index) => ({
        ...row,
        rank: index + 1
      })),
      type
    });
  } catch (error) {
    console.error('Get leaderboard error:', error);
    res.status(500).json({ message: 'Error fetching leaderboard' });
  }
});

/**
 * Get user's badges
 * GET /api/gamification/badges
 */
router.get('/badges', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.userId;

    const result = await db.query(
      'SELECT * FROM badges WHERE user_id = $1 ORDER BY earned_at DESC',
      [userId]
    );

    res.json({
      badges: result.rows,
      count: result.rows.length
    });
  } catch (error) {
    console.error('Get badges error:', error);
    res.status(500).json({ message: 'Error fetching badges' });
  }
});

/**
 * Get user's achievements
 * GET /api/gamification/achievements
 */
router.get('/achievements', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.userId;

    const result = await db.query(
      'SELECT * FROM achievements WHERE user_id = $1 ORDER BY earned_at DESC',
      [userId]
    );

    res.json({
      achievements: result.rows,
      count: result.rows.length
    });
  } catch (error) {
    console.error('Get achievements error:', error);
    res.status(500).json({ message: 'Error fetching achievements' });
  }
});

/**
 * Get user's streaks
 * GET /api/gamification/streaks
 */
router.get('/streaks', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.userId;

    const result = await db.query(
      'SELECT * FROM user_streaks WHERE user_id = $1 ORDER BY created_at DESC LIMIT 1',
      [userId]
    );

    res.json({
      current_streak: result.rows[0] || null
    });
  } catch (error) {
    console.error('Get streaks error:', error);
    res.status(500).json({ message: 'Error fetching streaks' });
  }
});

export default router;
