/**
 * Database Migration for Social & Competition System
 * Run this to set up the necessary tables
 */

const db = require('../config/database');
const logger = require('../utils/logger');

async function createFriendsTables() {
    try {
        logger.info('Creating friends and challenges tables...');
        
        // Create friends table
        await db.query(`
            CREATE TABLE IF NOT EXISTS friends (
                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                friend_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                status VARCHAR(20) NOT NULL DEFAULT 'pending' 
                    CHECK (status IN ('pending', 'accepted', 'blocked')),
                created_at TIMESTAMP DEFAULT NOW(),
                updated_at TIMESTAMP DEFAULT NOW(),
                CONSTRAINT different_users CHECK (user_id != friend_id),
                UNIQUE(user_id, friend_id)
            )
        `);
        logger.info('✅ Friends table created');
        
        // Create challenges table
        await db.query(`
            CREATE TABLE IF NOT EXISTS challenges (
                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                name VARCHAR(255) NOT NULL,
                description TEXT,
                creator_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                type VARCHAR(50) NOT NULL 
                    CHECK (type IN ('personal_1v1', 'group', 'team')),
                metric VARCHAR(100) NOT NULL,
                start_date TIMESTAMP NOT NULL,
                end_date TIMESTAMP NOT NULL,
                status VARCHAR(20) NOT NULL DEFAULT 'active'
                    CHECK (status IN ('active', 'completed', 'cancelled')),
                created_at TIMESTAMP DEFAULT NOW(),
                updated_at TIMESTAMP DEFAULT NOW()
            )
        `);
        logger.info('✅ Challenges table created');
        
        // Create challenge_participants table
        await db.query(`
            CREATE TABLE IF NOT EXISTS challenge_participants (
                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                challenge_id UUID NOT NULL REFERENCES challenges(id) ON DELETE CASCADE,
                user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                score DOUBLE PRECISION DEFAULT 0,
                rank INT,
                joined_at TIMESTAMP DEFAULT NOW(),
                updated_at TIMESTAMP DEFAULT NOW(),
                UNIQUE(challenge_id, user_id)
            )
        `);
        logger.info('✅ Challenge participants table created');
        
        // Create activity_logs table
        await db.query(`
            CREATE TABLE IF NOT EXISTS activity_logs (
                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                type VARCHAR(50) NOT NULL 
                    CHECK (type IN ('meal', 'workout', 'daily_summary')),
                data JSONB NOT NULL,
                shared_with UUID[] DEFAULT '{}',
                visibility VARCHAR(20) NOT NULL DEFAULT 'private'
                    CHECK (visibility IN ('private', 'friends_only', 'public')),
                challenge_id UUID REFERENCES challenges(id) ON DELETE SET NULL,
                created_at TIMESTAMP DEFAULT NOW(),
                updated_at TIMESTAMP DEFAULT NOW()
            )
        `);
        logger.info('✅ Activity logs table created');
        
        // Create social notifications table
        await db.query(`
            CREATE TABLE IF NOT EXISTS social_notifications (
                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                recipient_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                type VARCHAR(50) NOT NULL 
                    CHECK (type IN ('friend_activity', 'challenge_update', 'milestone', 'leaderboard')),
                title VARCHAR(255),
                message TEXT NOT NULL,
                ai_generated BOOLEAN DEFAULT false,
                related_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
                challenge_id UUID REFERENCES challenges(id) ON DELETE SET NULL,
                read BOOLEAN DEFAULT false,
                created_at TIMESTAMP DEFAULT NOW(),
                updated_at TIMESTAMP DEFAULT NOW()
            )
        `);
        logger.info('✅ Social notifications table created');
        
        // Create indexes for performance
        await db.query(`CREATE INDEX IF NOT EXISTS idx_friends_user_id ON friends(user_id)`);
        await db.query(`CREATE INDEX IF NOT EXISTS idx_friends_friend_id ON friends(friend_id)`);
        await db.query(`CREATE INDEX IF NOT EXISTS idx_friends_status ON friends(status)`);
        logger.info('✅ Friends indexes created');
        
        await db.query(`CREATE INDEX IF NOT EXISTS idx_challenges_creator_id ON challenges(creator_id)`);
        await db.query(`CREATE INDEX IF NOT EXISTS idx_challenges_status ON challenges(status)`);
        logger.info('✅ Challenge indexes created');
        
        await db.query(`CREATE INDEX IF NOT EXISTS idx_challenge_participants_challenge_id ON challenge_participants(challenge_id)`);
        await db.query(`CREATE INDEX IF NOT EXISTS idx_challenge_participants_user_id ON challenge_participants(user_id)`);
        logger.info('✅ Challenge participants indexes created');
        
        await db.query(`CREATE INDEX IF NOT EXISTS idx_activity_logs_user_id ON activity_logs(user_id)`);
        await db.query(`CREATE INDEX IF NOT EXISTS idx_activity_logs_challenge_id ON activity_logs(challenge_id)`);
        logger.info('✅ Activity logs indexes created');
        
        await db.query(`CREATE INDEX IF NOT EXISTS idx_social_notifications_recipient_id ON social_notifications(recipient_id)`);
        await db.query(`CREATE INDEX IF NOT EXISTS idx_social_notifications_created_at ON social_notifications(created_at)`);
        logger.info('✅ Social notifications indexes created');
        
        logger.info('✅ All tables and indexes created successfully!');
        return true;
    } catch (error) {
        logger.error(`Error creating tables: ${error.message}`);
        throw error;
    }
}

// Export for use in startup
module.exports = { createFriendsTables };
