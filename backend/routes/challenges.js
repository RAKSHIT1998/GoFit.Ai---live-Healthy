import express from 'express';
import pool from '../config/database.js';
import { authenticateToken } from '../middleware/authMiddleware.js';

const router = express.Router();

/**
 * Create a new challenge
 * POST /api/challenges/create
 */
router.post('/create', authenticateToken, async (req, res) => {
  try {
    const { name, description, challengeType, metric, targetValue, duration, isGroupChallenge, invitedUsers } = req.body;
    const userId = req.user.id;

    if (!name || !challengeType || !metric || !targetValue || !duration) {
      return res.status(400).json({ message: 'Missing required fields' });
    }

    const validTypes = ['personal', 'group'];
    if (!validTypes.includes(challengeType)) {
      return res.status(400).json({ message: 'Invalid challenge type' });
    }

    const startDate = new Date();
    const endDate = new Date(startDate.getTime() + duration * 24 * 60 * 60 * 1000);

    const result = await pool.query(
      `INSERT INTO challenges (creator_id, name, description, challenge_type, metric, target_value, start_date, end_date, is_active, created_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, NOW())
       RETURNING *`,
      [userId, name, description, challengeType, metric, targetValue, startDate, endDate]
    );

    const challenge = result.rows[0];

    // Add creator as first participant
    await pool.query(
      'INSERT INTO challenge_participants (challenge_id, user_id, current_score, rank, joined_at) VALUES ($1, $2, 0, 1, NOW())',
      [challenge.id, userId]
    );

    // Invite users if group challenge
    if (isGroupChallenge && invitedUsers && invitedUsers.length > 0) {
      for (const invitedUserId of invitedUsers) {
        await pool.query(
          'INSERT INTO challenge_invitations (challenge_id, invited_user_id, invited_by, status) VALUES ($1, $2, $3, $4)',
          [challenge.id, invitedUserId, userId, 'pending']
        );

        // Create notification
        await pool.query(
          `INSERT INTO social_notifications (recipient_id, type, title, message, related_user_id, challenge_id, ai_generated)
           VALUES ($1, $2, $3, $4, $5, $6, false)`,
          [invitedUserId, 'challenge_invite', 'Challenge Invitation', `${req.user.username} invited you to "${name}"`, userId, challenge.id]
        );
      }
    }

    // Award points for creating challenge
    await pool.query(
      'INSERT INTO gamification_points (user_id, action_type, points, created_at) VALUES ($1, $2, $3, NOW())',
      [userId, 'create_challenge', 25]
    );

    res.json({
      message: 'Challenge created successfully',
      challenge: {
        id: challenge.id,
        name,
        challengeType,
        metric,
        targetValue,
        startDate,
        endDate,
        participantCount: 1
      }
    });
  } catch (error) {
    console.error('Create challenge error:', error);
    res.status(500).json({ message: 'Error creating challenge' });
  }
});

/**
 * Get all challenges
 * GET /api/challenges
 */
router.get('/', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;
    const { type, status = 'active', limit = 20, offset = 0 } = req.query;

    let query = `
      SELECT 
        c.*, 
        COUNT(DISTINCT cp.user_id) as participant_count,
        CASE WHEN cp.user_id = $1 THEN true ELSE false END as user_joined
      FROM challenges c
      LEFT JOIN challenge_participants cp ON c.id = cp.challenge_id
      WHERE 1=1
    `;

    const params = [userId];

    if (status === 'active') {
      query += ` AND c.is_active = true AND c.end_date > NOW()`;
    } else if (status === 'completed') {
      query += ` AND c.is_active = false OR c.end_date <= NOW()`;
    }

    if (type) {
      query += ` AND c.challenge_type = $${params.length + 1}`;
      params.push(type);
    }

    query += ` GROUP BY c.id ORDER BY c.created_at DESC LIMIT $${params.length + 1} OFFSET $${params.length + 2}`;
    params.push(limit, offset);

    const result = await pool.query(query, params);

    res.json({
      challenges: result.rows,
      count: result.rows.length
    });
  } catch (error) {
    console.error('Get challenges error:', error);
    res.status(500).json({ message: 'Error fetching challenges' });
  }
});

/**
 * Join a challenge
 * POST /api/challenges/:challengeId/join
 */
router.post('/:challengeId/join', authenticateToken, async (req, res) => {
  try {
    const { challengeId } = req.params;
    const userId = req.user.id;

    // Check if challenge exists and is active
    const challengeResult = await pool.query(
      'SELECT * FROM challenges WHERE id = $1 AND is_active = true AND end_date > NOW()',
      [challengeId]
    );

    if (challengeResult.rows.length === 0) {
      return res.status(404).json({ message: 'Challenge not found or inactive' });
    }

    // Check if already joined
    const joinedResult = await pool.query(
      'SELECT * FROM challenge_participants WHERE challenge_id = $1 AND user_id = $2',
      [challengeId, userId]
    );

    if (joinedResult.rows.length > 0) {
      return res.status(400).json({ message: 'Already joined this challenge' });
    }

    // Add user as participant
    await pool.query(
      'INSERT INTO challenge_participants (challenge_id, user_id, current_score, joined_at) VALUES ($1, $2, 0, NOW())',
      [challengeId, userId]
    );

    // Award points
    await pool.query(
      'INSERT INTO gamification_points (user_id, action_type, points, created_at) VALUES ($1, $2, $3, NOW())',
      [userId, 'join_challenge', 10]
    );

    res.json({ message: 'Successfully joined challenge' });
  } catch (error) {
    console.error('Join challenge error:', error);
    res.status(500).json({ message: 'Error joining challenge' });
  }
});

/**
 * Get challenge leaderboard
 * GET /api/challenges/:challengeId/leaderboard
 */
router.get('/:challengeId/leaderboard', authenticateToken, async (req, res) => {
  try {
    const { challengeId } = req.params;

    const result = await pool.query(
      `SELECT 
        cp.user_id, users.username, users.email, cp.current_score, cp.rank, cp.joined_at
      FROM challenge_participants cp
      JOIN users ON cp.user_id = users.id
      WHERE cp.challenge_id = $1
      ORDER BY cp.current_score DESC, cp.joined_at ASC`,
      [challengeId]
    );

    res.json({
      leaderboard: result.rows
    });
  } catch (error) {
    console.error('Get leaderboard error:', error);
    res.status(500).json({ message: 'Error fetching leaderboard' });
  }
});

/**
 * Update challenge score
 * POST /api/challenges/:challengeId/score
 */
router.post('/:challengeId/score', authenticateToken, async (req, res) => {
  try {
    const { challengeId } = req.params;
    const { scoreValue } = req.body;
    const userId = req.user.id;

    if (!scoreValue || scoreValue <= 0) {
      return res.status(400).json({ message: 'Invalid score value' });
    }

    // Get challenge info
    const challengeResult = await pool.query(
      'SELECT metric FROM challenges WHERE id = $1',
      [challengeId]
    );

    if (challengeResult.rows.length === 0) {
      return res.status(404).json({ message: 'Challenge not found' });
    }

    // Update participant score
    const updateResult = await pool.query(
      `UPDATE challenge_participants 
       SET current_score = current_score + $1, updated_at = NOW()
       WHERE challenge_id = $2 AND user_id = $3
       RETURNING current_score`,
      [scoreValue, challengeId, userId]
    );

    if (updateResult.rows.length === 0) {
      return res.status(404).json({ message: 'Not a participant in this challenge' });
    }

    // Update ranks
    await pool.query(
      `UPDATE challenge_participants 
       SET rank = (SELECT COUNT(*) + 1 FROM challenge_participants cp2 
                   WHERE cp2.challenge_id = $1 AND cp2.current_score > challenge_participants.current_score)
       WHERE challenge_id = $1`,
      [challengeId]
    );

    res.json({
      message: 'Score updated',
      newScore: updateResult.rows[0].current_score
    });
  } catch (error) {
    console.error('Update score error:', error);
    res.status(500).json({ message: 'Error updating score' });
  }
});

export default router;



