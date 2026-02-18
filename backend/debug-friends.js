/**
 * Debug script to test friends search functionality
 * Usage: node debug-friends.js
 */

import db from './config/database.js';

async function debugFriendsSearch() {
    try {
        console.log('\n🔍 Debugging Friends Search System\n');
        
        // 1. Check if users table exists and has data
        console.log('1️⃣  Checking users table...');
        const usersResult = await db.query('SELECT id, username, email, full_name FROM users LIMIT 10');
        console.log(`   Found ${usersResult.rows.length} users in database`);
        if (usersResult.rows.length > 0) {
            console.log('   Sample users:');
            usersResult.rows.slice(0, 3).forEach((user, idx) => {
                console.log(`   ${idx + 1}. ${user.username} (${user.email}) - ID: ${user.id}`);
            });
        } else {
            console.log('   ⚠️  No users found! Add test accounts first.');
        }
        
        // 2. Check if friends table exists
        console.log('\n2️⃣  Checking friends table...');
        const friendsResult = await db.query(`
            SELECT 
                COUNT(*) as total,
                SUM(CASE WHEN status = 'accepted' THEN 1 ELSE 0 END) as accepted,
                SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END) as pending,
                SUM(CASE WHEN status = 'blocked' THEN 1 ELSE 0 END) as blocked
            FROM friends
        `);
        const stats = friendsResult.rows[0];
        console.log(`   Total relationships: ${stats.total}`);
        console.log(`   - Accepted: ${stats.accepted}`);
        console.log(`   - Pending: ${stats.pending}`);
        console.log(`   - Blocked: ${stats.blocked}`);
        
        // 3. Test search query
        if (usersResult.rows.length >= 2) {
            console.log('\n3️⃣  Testing search query...');
            const user1 = usersResult.rows[0];
            const user2 = usersResult.rows[1];
            const searchQuery = user2.username.substring(0, 2).toUpperCase();
            
            console.log(`   Searching for: "${searchQuery}" as User 1 (${user1.username})`);
            
            const searchResult = await db.query(
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
                 LIMIT 20`,
                [user1.id, `%${searchQuery}%`]
            );
            
            console.log(`   Search results: ${searchResult.rows.length} found`);
            searchResult.rows.forEach((result, idx) => {
                console.log(`   ${idx + 1}. ${result.username} (${result.email}) - Status: ${result.friend_status}`);
            });
        }
        
        // 4. Check authentication
        console.log('\n4️⃣  Checking authentication tokens...');
        const tokensResult = await db.query('SELECT COUNT(*) as count FROM users WHERE id IS NOT NULL');
        console.log(`   Users with potential tokens: ${tokensResult.rows[0].count}`);
        
        console.log('\n✅ Debug complete!\n');
        
    } catch (error) {
        console.error('❌ Error:', error.message);
    } finally {
        process.exit(0);
    }
}

debugFriendsSearch();
