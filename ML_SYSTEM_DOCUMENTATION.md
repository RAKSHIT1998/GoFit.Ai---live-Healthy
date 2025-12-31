# Machine Learning System Documentation

## Overview

The GoFit.Ai app now includes a comprehensive machine learning system that learns from user behavior and provides gradually adaptive, personalized recommendations based on customer types.

## Features

### 1. User Behavior Tracking
- **Meal Patterns**: Tracks eating times, favorite foods, meal frequencies
- **Activity Patterns**: Monitors workout preferences, activity consistency
- **Learning Metrics**: Calculates consistency scores, engagement scores, macro preferences
- **Feedback Tracking**: Records user interactions with recommendations

### 2. User Type Classification

The system automatically classifies users into types based on behavior:

- **busy_professional**: Time-constrained, needs quick meals
- **fitness_enthusiast**: Active, high protein focus
- **health_conscious**: Balanced nutrition, organic preferences
- **weight_loss_seeker**: Calorie-focused, portion control
- **muscle_builder**: High protein, strength training focus
- **family_cook**: Family-friendly, budget-conscious
- **beginner**: New to fitness/nutrition
- **experienced**: Advanced knowledge

### 3. Gradual Recommendation Adaptation

The system:
- Learns from every meal logged
- Adapts recommendations based on user feedback
- Gradually adjusts meal timing, portion sizes, and macro focus
- Improves over time as more data is collected

### 4. ML-Enhanced AI Recommendations

AI recommendations now include:
- User type-specific suggestions
- Favorite foods incorporated into meal plans
- Preferred meal times respected
- Macro ratios matched to user preferences
- Behavior-based insights

## Architecture

### Models

1. **UserBehavior Model** (`backend/models/UserBehavior.js`)
   - Stores user behavior patterns
   - Tracks learning metrics
   - Records feedback history
   - Maintains adaptation history

2. **ML Service** (`backend/services/mlService.js`)
   - `classifyUserType()`: Analyzes behavior and classifies user
   - `calculateMetrics()`: Computes behavior metrics
   - `learnFromMeal()`: Learns from each meal logged
   - `getMLInsights()`: Returns personalized insights
   - `trackRecommendationFeedback()`: Records user feedback
   - `adaptRecommendations()`: Gradually adapts recommendations

### API Endpoints

1. **GET `/api/recommendations/ml-insights`**
   - Returns ML insights for the current user
   - Includes user type, favorite foods, preferences
   - Requires authentication

2. **POST `/api/recommendations/feedback`**
   - Tracks user feedback on recommendations
   - Body: `{ recommendationId, type, action, rating? }`
   - Triggers adaptation if needed

### Integration Points

1. **Meal Logging** (`backend/routes/meals.js`)
   - Automatically triggers ML learning when meals are saved
   - Updates behavior patterns asynchronously

2. **Recommendation Generation** (`backend/routes/recommendations.js`)
   - Fetches ML insights before generating recommendations
   - Includes ML data in AI prompt
   - Saves ML metadata with recommendations

## How It Works

### 1. Initial User Classification

When a user first logs meals:
1. System analyzes meal patterns
2. Calculates metrics (calories, macros, consistency)
3. Classifies user into a type
4. Creates initial behavior profile

### 2. Continuous Learning

Every time a user logs a meal:
1. System updates eating patterns
2. Tracks favorite foods
3. Updates preferred meal times
4. Recalculates metrics
5. May reclassify user type if patterns change

### 3. Recommendation Enhancement

When generating recommendations:
1. System fetches ML insights
2. Includes user type, favorites, preferences in AI prompt
3. AI generates personalized recommendations
4. ML metadata saved with recommendation

### 4. Feedback & Adaptation

When user interacts with recommendations:
1. Feedback is tracked (viewed, logged, skipped, rated)
2. System analyzes feedback patterns
3. If ratings consistently low, suggests adaptations
4. Recommendations gradually improve

## Example Usage

### Get ML Insights

```javascript
GET /api/recommendations/ml-insights

Response:
{
  "userType": "fitness_enthusiast",
  "recommendations": {
    "mealTiming": "Pre and post-workout nutrition is key",
    "portionSize": "Larger portions to fuel activity",
    "macroFocus": "High protein (1.6-2.2g per kg body weight)",
    "workoutIntensity": "High intensity, varied workouts",
    "tips": [
      "Protein within 30 minutes post-workout",
      "Stay hydrated during workouts",
      "Balance cardio and strength training"
    ]
  },
  "preferences": {
    "favoriteFoods": ["Chicken Breast", "Greek Yogurt", "Quinoa"],
    "preferredMealTimes": [
      { "meal": "breakfast", "time": "07:30" },
      { "meal": "lunch", "time": "13:00" }
    ],
    "averageMealCalories": 450,
    "preferredMacroRatio": {
      "protein": 35,
      "carbs": 40,
      "fat": 25
    }
  },
  "metrics": {
    "totalMealsLogged": 45,
    "consistencyScore": 85,
    "engagementScore": 90
  }
}
```

### Track Feedback

```javascript
POST /api/recommendations/feedback

Body:
{
  "recommendationId": "507f1f77bcf86cd799439011",
  "type": "meal",
  "action": "rated",
  "rating": 4
}

Response:
{
  "success": true,
  "adaptations": null // or adaptation suggestions if needed
}
```

## User Type Recommendations

### Busy Professional
- Quick meal prep suggestions
- Meal prep on weekends
- High protein, moderate carbs
- Efficient 20-30 minute workouts

### Fitness Enthusiast
- Pre/post-workout nutrition focus
- Larger portions to fuel activity
- Very high protein (1.6-2.2g/kg)
- High intensity, varied workouts

### Weight Loss Seeker
- Smaller, frequent meals
- Portion control focus
- Higher protein, moderate carbs, lower fat
- Mix of cardio and strength

### Muscle Builder
- Frequent meals every 3-4 hours
- Calorie surplus
- Very high protein, high carbs
- Progressive strength training

### Health Conscious
- Regular meal times
- Balanced portions
- Balanced macros, quality focus
- Regular moderate activity

## Error Handling

The ML system includes comprehensive error handling:
- Non-critical ML learning errors don't block meal saving
- Fallback to default recommendations if ML fails
- Graceful degradation if user type can't be determined
- Detailed logging for debugging

## Future Enhancements

Potential improvements:
1. Collaborative filtering (users with similar patterns)
2. Seasonal adaptation (adjust for weather, holidays)
3. Goal progression tracking
4. Predictive meal suggestions
5. Real-time adaptation based on current day's activity
6. Integration with wearable devices for activity prediction

## Monitoring

Check logs for:
- `🤖 Generating AI recommendation with ML insights`
- `📊 User Type: [type]`
- `🍽️ Favorite Foods: [foods]`
- `✅ Recommendation saved with ML insights`
- `❌ ML learning error (non-critical)` - These are logged but don't block operations

## Testing

To test the ML system:
1. Log several meals over a few days
2. Check ML insights endpoint to see user type classification
3. Generate recommendations and verify ML data is included
4. Track feedback on recommendations
5. Verify gradual adaptation over time

