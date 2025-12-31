import UserBehavior from '../models/UserBehavior.js';
import Meal from '../models/Meal.js';
import User from '../models/User.js';

/**
 * Machine Learning Service
 * Provides ML-based insights and recommendations
 */
class MLService {
  
  /**
   * Analyze user behavior and classify user type
   */
  async classifyUserType(userId) {
    try {
      const user = await User.findById(userId);
      if (!user) throw new Error('User not found');
      
      const meals = await Meal.find({ userId })
        .sort({ timestamp: -1 })
        .limit(50);
      
      const behavior = await UserBehavior.findOne({ userId }) || 
        new UserBehavior({ userId });
      
      // Calculate metrics
      const metrics = this.calculateMetrics(meals, user);
      
      // Classify user type based on patterns
      const userType = this.determineUserType(metrics, user);
      
      // Update behavior
      behavior.userType = userType;
      behavior.learningMetrics = {
        ...behavior.learningMetrics,
        ...metrics,
        lastUpdated: new Date()
      };
      
      await behavior.save();
      
      return { userType, metrics };
    } catch (error) {
      console.error('Error classifying user type:', error);
      return { userType: 'beginner', metrics: {} };
    }
  }
  
  /**
   * Calculate user metrics from meal history
   */
  calculateMetrics(meals, user) {
    if (!meals || meals.length === 0) {
      return {
        totalMealsLogged: 0,
        averageDailyCalories: user.metrics?.targetCalories || 2000,
        averageDailyProtein: 0,
        averageDailyCarbs: 0,
        averageDailyFat: 0,
        averageDailySugar: 0,
        consistencyScore: 0,
        engagementScore: 0
      };
    }
    
    // Group meals by date
    const mealsByDate = {};
    meals.forEach(meal => {
      const date = new Date(meal.timestamp).toDateString();
      if (!mealsByDate[date]) {
        mealsByDate[date] = [];
      }
      mealsByDate[date].push(meal);
    });
    
    // Calculate daily averages
    const dailyTotals = Object.values(mealsByDate).map(dayMeals => {
      return dayMeals.reduce((acc, meal) => ({
        calories: acc.calories + (meal.totalCalories || 0),
        protein: acc.protein + (meal.totalProtein || 0),
        carbs: acc.carbs + (meal.totalCarbs || 0),
        fat: acc.fat + (meal.totalFat || 0),
        sugar: acc.sugar + (meal.totalSugar || 0)
      }), { calories: 0, protein: 0, carbs: 0, fat: 0, sugar: 0 });
    });
    
    const numDays = dailyTotals.length;
    const totals = dailyTotals.reduce((acc, day) => ({
      calories: acc.calories + day.calories,
      protein: acc.protein + day.protein,
      carbs: acc.carbs + day.carbs,
      fat: acc.fat + day.fat,
      sugar: acc.sugar + day.sugar
    }), { calories: 0, protein: 0, carbs: 0, fat: 0, sugar: 0 });
    
    // Calculate consistency (how many days in last 7 days have meals)
    const last7Days = Array.from({ length: 7 }, (_, i) => {
      const date = new Date();
      date.setDate(date.getDate() - i);
      return date.toDateString();
    });
    
    const activeDays = last7Days.filter(date => mealsByDate[date]).length;
    const consistencyScore = (activeDays / 7) * 100;
    
    // Calculate engagement (based on total meals logged)
    const engagementScore = Math.min(100, (meals.length / 30) * 100); // 30 meals = 100%
    
    return {
      totalMealsLogged: meals.length,
      averageDailyCalories: totals.calories / numDays || 0,
      averageDailyProtein: totals.protein / numDays || 0,
      averageDailyCarbs: totals.carbs / numDays || 0,
      averageDailyFat: totals.fat / numDays || 0,
      averageDailySugar: totals.sugar / numDays || 0,
      consistencyScore: Math.round(consistencyScore),
      engagementScore: Math.round(engagementScore)
    };
  }
  
  /**
   * Determine user type based on behavior patterns
   */
  determineUserType(metrics, user) {
    const { goals, activityLevel } = user;
    const { averageDailyCalories, averageDailyProtein, consistencyScore, engagementScore } = metrics;
    
    // High engagement + high protein + active = fitness enthusiast
    if (engagementScore > 70 && averageDailyProtein > 100 && activityLevel === 'very_active') {
      return 'fitness_enthusiast';
    }
    
    // Low consistency + moderate calories = busy professional
    if (consistencyScore < 50 && averageDailyCalories > 1500 && averageDailyCalories < 2500) {
      return 'busy_professional';
    }
    
    // Weight loss goal + calorie conscious = weight loss seeker
    if (goals === 'lose' && averageDailyCalories < 1800) {
      return 'weight_loss_seeker';
    }
    
    // High protein + gain goal = muscle builder
    if (goals === 'gain' && averageDailyProtein > 120) {
      return 'muscle_builder';
    }
    
    // Balanced nutrition + moderate activity = health conscious
    if (averageDailyCalories >= 1800 && averageDailyCalories <= 2200 && activityLevel === 'moderate') {
      return 'health_conscious';
    }
    
    // Low engagement = beginner
    if (engagementScore < 30) {
      return 'beginner';
    }
    
    // Default to experienced
    return 'experienced';
  }
  
  /**
   * Learn from meal logging patterns
   */
  async learnFromMeal(meal, userId) {
    try {
      let behavior = await UserBehavior.findOne({ userId });
      
      if (!behavior) {
        behavior = new UserBehavior({ userId });
        await behavior.save();
      }
      
      // Update eating patterns
      const mealTime = new Date(meal.timestamp);
      const hour = mealTime.getHours();
      let mealType = 'snack';
      
      if (hour >= 6 && hour < 11) mealType = 'breakfast';
      else if (hour >= 11 && hour < 16) mealType = 'lunch';
      else if (hour >= 16 && hour < 21) mealType = 'dinner';
      
      // Update preferred meal times
      const mealTimeEntry = behavior.eatingPatterns.preferredMealTimes.find(
        m => m.mealType === mealType
      );
      
      if (mealTimeEntry) {
        mealTimeEntry.frequency += 1;
        // Update average time
        const currentAvg = mealTimeEntry.averageTime.split(':').map(Number);
        const newTime = [hour, mealTime.getMinutes()];
        const avgHour = Math.round((currentAvg[0] + newTime[0]) / 2);
        const avgMin = Math.round((currentAvg[1] + newTime[1]) / 2);
        mealTimeEntry.averageTime = `${String(avgHour).padStart(2, '0')}:${String(avgMin).padStart(2, '0')}`;
      } else {
        behavior.eatingPatterns.preferredMealTimes.push({
          mealType,
          averageTime: `${String(hour).padStart(2, '0')}:${String(mealTime.getMinutes()).padStart(2, '0')}`,
          frequency: 1
        });
      }
      
      // Update favorite foods
      meal.items.forEach(item => {
        const favorite = behavior.eatingPatterns.favoriteFoods.find(
          f => f.name.toLowerCase() === item.name.toLowerCase()
        );
        
        if (favorite) {
          favorite.frequency += 1;
          favorite.lastLogged = meal.timestamp;
          // Update average calories
          const totalCal = (favorite.averageCalories || 0) * (favorite.frequency - 1) + (item.calories || 0);
          favorite.averageCalories = totalCal / favorite.frequency;
        } else {
          behavior.eatingPatterns.favoriteFoods.push({
            name: item.name,
            frequency: 1,
            lastLogged: meal.timestamp,
            averageCalories: item.calories || 0
          });
        }
      });
      
      // Update average meal calories
      const totalMeals = behavior.learningMetrics.totalMealsLogged || 0;
      const currentAvg = behavior.eatingPatterns.averageMealCalories || 0;
      const newAvg = (currentAvg * totalMeals + meal.totalCalories) / (totalMeals + 1);
      behavior.eatingPatterns.averageMealCalories = newAvg;
      
      // Update learning metrics
      behavior.learningMetrics.totalMealsLogged = (behavior.learningMetrics.totalMealsLogged || 0) + 1;
      
      await behavior.save();
      
      return behavior;
    } catch (error) {
      console.error('Error learning from meal:', error);
      return null;
    }
  }
  
  /**
   * Get personalized recommendations based on ML insights
   */
  async getMLInsights(userId) {
    try {
      const behavior = await UserBehavior.findOne({ userId });
      
      if (!behavior) {
        // First-time user - return default insights
        return {
          userType: 'beginner',
          recommendations: {
            mealTiming: 'Eat regular meals throughout the day',
            portionSize: 'Start with moderate portions',
            macroFocus: 'Balance all macronutrients',
            workoutIntensity: 'Begin with light to moderate activity'
          },
          preferences: {
            favoriteFoods: [],
            preferredMealTimes: [],
            averageMealCalories: 0
          }
        };
      }
      
      // Get top favorite foods
      const topFoods = behavior.eatingPatterns.favoriteFoods
        .sort((a, b) => b.frequency - a.frequency)
        .slice(0, 5)
        .map(f => f.name);
      
      // Get preferred meal times
      const mealTimes = behavior.eatingPatterns.preferredMealTimes
        .sort((a, b) => b.frequency - a.frequency)
        .map(m => ({
          meal: m.mealType,
          time: m.averageTime
        }));
      
      // Generate recommendations based on user type
      const recommendations = this.generateTypeBasedRecommendations(behavior.userType, behavior);
      
      return {
        userType: behavior.userType,
        recommendations,
        preferences: {
          favoriteFoods: topFoods,
          preferredMealTimes: mealTimes,
          averageMealCalories: behavior.eatingPatterns.averageMealCalories || 0,
          preferredMacroRatio: behavior.eatingPatterns.preferredMacroRatio || {
            protein: 30,
            carbs: 40,
            fat: 30
          }
        },
        metrics: behavior.learningMetrics
      };
    } catch (error) {
      console.error('Error getting ML insights:', error);
      return null;
    }
  }
  
  /**
   * Generate recommendations based on user type
   */
  generateTypeBasedRecommendations(userType, behavior) {
    const baseRecommendations = {
      mealTiming: 'Eat regular meals throughout the day',
      portionSize: 'Moderate portions',
      macroFocus: 'Balance all macronutrients',
      workoutIntensity: 'Moderate activity'
    };
    
    switch (userType) {
      case 'busy_professional':
        return {
          ...baseRecommendations,
          mealTiming: 'Prepare quick meals or meal prep on weekends',
          portionSize: 'Portion-controlled meals for convenience',
          macroFocus: 'High protein, moderate carbs for sustained energy',
          workoutIntensity: 'Efficient 20-30 minute workouts',
          tips: [
            'Meal prep on Sundays for the week',
            'Keep healthy snacks at work',
            'Quick protein-rich breakfasts'
          ]
        };
        
      case 'fitness_enthusiast':
        return {
          ...baseRecommendations,
          mealTiming: 'Pre and post-workout nutrition is key',
          portionSize: 'Larger portions to fuel activity',
          macroFocus: 'High protein (1.6-2.2g per kg body weight)',
          workoutIntensity: 'High intensity, varied workouts',
          tips: [
            'Protein within 30 minutes post-workout',
            'Stay hydrated during workouts',
            'Balance cardio and strength training'
          ]
        };
        
      case 'weight_loss_seeker':
        return {
          ...baseRecommendations,
          mealTiming: 'Smaller, frequent meals to control hunger',
          portionSize: 'Smaller portions, focus on vegetables',
          macroFocus: 'Higher protein, moderate carbs, lower fat',
          workoutIntensity: 'Mix of cardio and strength training',
          tips: [
            'Track calories consistently',
            'Focus on whole foods',
            'Stay hydrated to reduce hunger'
          ]
        };
        
      case 'muscle_builder':
        return {
          ...baseRecommendations,
          mealTiming: 'Frequent meals every 3-4 hours',
          portionSize: 'Larger portions, calorie surplus',
          macroFocus: 'Very high protein, high carbs, moderate fat',
          workoutIntensity: 'Progressive strength training',
          tips: [
            'Eat protein with every meal',
            'Post-workout nutrition is crucial',
            'Track macros for optimal gains'
          ]
        };
        
      case 'health_conscious':
        return {
          ...baseRecommendations,
          mealTiming: 'Regular meal times, mindful eating',
          portionSize: 'Balanced portions',
          macroFocus: 'Balanced macros, focus on quality',
          workoutIntensity: 'Regular moderate activity',
          tips: [
            'Focus on whole, unprocessed foods',
            'Include variety in your diet',
            'Listen to your body\'s hunger cues'
          ]
        };
        
      default:
        return {
          ...baseRecommendations,
          tips: [
            'Start with small changes',
            'Track your meals to understand patterns',
            'Be consistent with logging'
          ]
        };
    }
  }
  
  /**
   * Track recommendation feedback
   */
  async trackRecommendationFeedback(userId, recommendationId, type, action, rating = null) {
    try {
      let behavior = await UserBehavior.findOne({ userId });
      
      if (!behavior) {
        behavior = new UserBehavior({ userId });
      }
      
      behavior.recommendationFeedback.push({
        recommendationId,
        type,
        action,
        rating,
        timestamp: new Date()
      });
      
      await behavior.save();
      
      return behavior;
    } catch (error) {
      console.error('Error tracking feedback:', error);
      return null;
    }
  }
  
  /**
   * Gradually adapt recommendations based on user feedback
   */
  async adaptRecommendations(userId) {
    try {
      const behavior = await UserBehavior.findOne({ userId });
      
      if (!behavior || behavior.recommendationFeedback.length < 5) {
        // Not enough data for adaptation
        return null;
      }
      
      // Analyze feedback patterns
      const recentFeedback = behavior.recommendationFeedback
        .slice(-20) // Last 20 feedback entries
        .filter(f => f.action === 'rated' || f.action === 'logged');
      
      const avgRating = recentFeedback
        .filter(f => f.rating)
        .reduce((sum, f) => sum + f.rating, 0) / recentFeedback.filter(f => f.rating).length;
      
      // If ratings are consistently low, suggest adaptations
      if (avgRating < 3 && recentFeedback.length >= 5) {
        const adaptations = [];
        
        // Check if meal timing needs adjustment
        // Check if portion sizes need adjustment
        // Check if macro focus needs adjustment
        
        behavior.adaptationHistory.push({
          date: new Date(),
          changes: adaptations,
          reason: `Low average rating (${avgRating.toFixed(1)}) - adapting recommendations`
        });
        
        await behavior.save();
        
        return { adaptations, avgRating };
      }
      
      return null;
    } catch (error) {
      console.error('Error adapting recommendations:', error);
      return null;
    }
  }
}

export default new MLService();

