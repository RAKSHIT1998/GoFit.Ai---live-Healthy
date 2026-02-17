import db from '../config/database.js';

/**
 * Generate competitive notification using AI
 * @param {string} userId - User ID
 * @param {string} triggerType - Type of trigger (achievement, milestone, challenge, etc.)
 * @param {object} contextData - Additional context data
 * @returns {Promise<object>} Generated notification
 */
export async function generateCompetitiveNotification(userId, triggerType, contextData = {}) {
  try {
    // Get user data for context
    const userResult = await db.query(
      'SELECT username, full_name FROM users WHERE id = $1',
      [userId]
    );
    
    if (userResult.rows.length === 0) {
      throw new Error('User not found');
    }
    
    const user = userResult.rows[0];
    const userName = user.full_name || user.username;
    
    // Generate notification based on trigger type
    let notification = {
      title: '',
      body: '',
      type: triggerType,
      data: contextData
    };
    
    switch (triggerType) {
      case 'achievement':
        notification.title = '🎉 Achievement Unlocked!';
        notification.body = contextData.message || `Great job, ${userName}! You've reached a new milestone!`;
        break;
        
      case 'milestone':
        notification.title = '🎯 Milestone Reached!';
        notification.body = contextData.message || `Congratulations! You've achieved ${contextData.value || 'an important goal'}!`;
        break;
        
      case 'challenge':
        notification.title = '💪 Challenge Update';
        notification.body = contextData.message || `You're making great progress on your challenge!`;
        break;
        
      case 'streak':
        notification.title = '🔥 Streak Alert!';
        notification.body = contextData.message || `You're on a ${contextData.days || 'multi'}-day streak! Keep it going!`;
        break;
        
      case 'leaderboard':
        notification.title = '🏆 Leaderboard Update';
        notification.body = contextData.message || `You've moved up to position ${contextData.position || 'a higher rank'}!`;
        break;
        
      case 'friend_activity':
        notification.title = '👥 Friend Activity';
        notification.body = contextData.message || `Your friends are staying active! Join them!`;
        break;
        
      case 'encouragement':
        notification.title = '💪 Keep Going!';
        notification.body = contextData.message || `${userName}, you're doing great! Don't give up!`;
        break;
        
      case 'reminder':
        notification.title = '⏰ Reminder';
        notification.body = contextData.message || `Time to log your progress for today!`;
        break;
        
      default:
        notification.title = '📱 GoFit.Ai Update';
        notification.body = contextData.message || 'You have a new update!';
    }
    
    return notification;
    
  } catch (error) {
    console.error('Error generating AI notification:', error);
    // Return a default notification on error
    return {
      title: '📱 GoFit.Ai',
      body: 'You have a new update!',
      type: triggerType,
      data: contextData
    };
  }
}

/**
 * Generate personalized workout reminder
 */
export async function generateWorkoutReminder(userId) {
  const messages = [
    "Time to move! Your body will thank you 💪",
    "Let's get that workout in! 🏃‍♂️",
    "Your muscles are ready for action! 🔥",
    "Consistency is key - time for your workout! ⏰",
    "Your future self will thank you for this workout! 🎯"
  ];
  
  return {
    title: '🏋️ Workout Time!',
    body: messages[Math.floor(Math.random() * messages.length)],
    type: 'workout_reminder'
  };
}

/**
 * Generate meal logging reminder
 */
export async function generateMealReminder(userId, mealType = 'meal') {
  const messages = {
    breakfast: ["Don't forget to log your breakfast! 🍳", "Fuel your morning - log your breakfast! ☀️"],
    lunch: ["Lunch break! Remember to log your meal 🍽️", "Time to refuel - log your lunch! 🥗"],
    dinner: ["Dinner time! Don't forget to log it 🌙", "End your day right - log your dinner! 🍲"],
    meal: ["Time to log your meal! 🍴", "Track your nutrition - log your meal! 📊"]
  };
  
  const mealMessages = messages[mealType] || messages.meal;
  
  return {
    title: '🍽️ Meal Reminder',
    body: mealMessages[Math.floor(Math.random() * mealMessages.length)],
    type: 'meal_reminder'
  };
}

/**
 * Generate hydration reminder
 */
export async function generateHydrationReminder(userId) {
  const messages = [
    "Stay hydrated! Time for some water 💧",
    "Don't forget to drink water! 💦",
    "Your body needs hydration - drink up! 🥤",
    "Hydration check! Have you had water recently? 💧"
  ];
  
  return {
    title: '💧 Hydration Reminder',
    body: messages[Math.floor(Math.random() * messages.length)],
    type: 'hydration_reminder'
  };
}
