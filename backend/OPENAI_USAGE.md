# OpenAI API Usage in GoFit.Ai

## Overview
All AI-powered features in GoFit.Ai use OpenAI's API for intelligent recommendations and analysis.

## AI Features Using OpenAI

### 1. Meal Photo Scanning (`/api/photo/analyze`)
**Model:** `gpt-4o` (GPT-4 Omni - Latest Vision Model)
**Purpose:** Analyze food photos and extract nutritional information

**What it does:**
- Identifies all food items in the photo
- Estimates portion sizes
- Calculates calories, protein, carbs, fat, and sugar for each item
- Provides confidence scores for accuracy

**Configuration:**
- Temperature: 0.3 (low for consistent, accurate results)
- Max Tokens: 3000 (increased for detailed analysis)
- Uses Vision API for image analysis

**Example Request:**
```javascript
POST /api/photo/analyze
Content-Type: multipart/form-data
Body: photo file
```

**Response:**
```json
{
  "items": [
    {
      "name": "Grilled Chicken Breast",
      "calories": 250,
      "protein": 30,
      "carbs": 0,
      "fat": 12,
      "sugar": 0,
      "portionSize": "150g",
      "confidence": 0.95
    }
  ],
  "totalCalories": 250,
  "aiVersion": "gpt-4o"
}
```

### 2. Meal Recommendations (`/api/recommendations/daily`)
**Model:** `gpt-4o` (GPT-4 Omni - Latest Model)
**Purpose:** Generate personalized daily meal plans

**What it considers:**
- User's fitness goals (lose/maintain/gain weight)
- Activity level
- Dietary preferences (vegetarian, vegan, keto, etc.)
- Allergies and restrictions
- Target daily calories
- Fasting preferences
- Recent meal history

**Output:**
- Complete meal plan (breakfast, lunch, dinner, snacks)
- Detailed recipes with ingredients and cooking instructions
- Prep time and serving sizes
- Nutritional breakdown for each meal

**Configuration:**
- Temperature: 0.7 (balanced creativity and consistency)
- Max Tokens: 4000 (increased for detailed recipes)
- System prompt: Expert nutritionist persona

### 3. Workout Recommendations (`/api/recommendations/daily`)
**Model:** `gpt-4o` (GPT-4 Omni - Latest Model)
**Purpose:** Generate personalized workout plans

**What it considers:**
- User's fitness goals
- Activity level
- Available equipment
- Time constraints
- Recent workout history

**Output:**
- Exercise plan with detailed instructions
- Sets, reps, rest times
- Difficulty level
- Target muscle groups
- Equipment needed
- Step-by-step exercise instructions

**Configuration:**
- Temperature: 0.7 (balanced creativity and consistency)
- Max Tokens: 4000 (increased for detailed instructions)
- System prompt: Certified personal trainer persona

## API Key Configuration

The OpenAI API key must be set in your environment variables:

```bash
OPENAI_API_KEY=sk-your-openai-api-key-here
```

**Important:**
- Get your API key from https://platform.openai.com/api-keys
- Ensure your OpenAI account has sufficient credits
- The key needs access to GPT-4o models
- Keep the key secure and never commit it to version control

## Cost Optimization

### Token Usage
- **Photo Analysis:** ~500-1000 tokens per image
- **Recommendations:** ~2000-3000 tokens per generation
- **Daily Usage:** ~10-20 API calls per active user

### Best Practices
1. **Caching:** Recommendations are cached per day to avoid redundant API calls
2. **Error Handling:** Graceful fallbacks if API fails
3. **Rate Limiting:** Consider implementing rate limits for production
4. **Monitoring:** Track API usage and costs

## Model Selection

### Why GPT-4o?
- **Latest Model:** Most advanced OpenAI model available
- **Vision Support:** Built-in image analysis capabilities
- **Better Accuracy:** Improved understanding and reasoning
- **Cost-Effective:** Better performance per token than GPT-4
- **Faster:** Lower latency for better user experience

### Alternative Models (if needed)
- `gpt-4-turbo`: Good alternative if GPT-4o unavailable
- `gpt-4`: Older but still reliable
- `gpt-3.5-turbo`: Not recommended for this use case (less accurate)

## Error Handling

The system includes robust error handling:
1. **API Failures:** Falls back to default recommendations
2. **JSON Parsing:** Multiple parsing strategies for reliability
3. **Rate Limits:** Graceful degradation with user-friendly messages
4. **Invalid Responses:** Validation and sanitization of AI outputs

## Future Enhancements

Potential improvements:
- Fine-tuned models for nutrition analysis
- Batch processing for multiple photos
- Real-time streaming for recommendations
- Multi-language support
- Integration with nutrition databases for validation

