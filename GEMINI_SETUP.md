# Google Gemini API Setup Guide

This app now uses **Google Gemini AI** for meal scanning, drink logging, and nutritional analysis.

## Why Google Gemini?

- ✅ **Free tier available** - Generous free usage limits
- ✅ **Fast responses** - Typically 2-5 seconds for image analysis
- ✅ **Excellent vision capabilities** - Great at recognizing food and drinks
- ✅ **Cost-effective** - More affordable than OpenAI for high-volume usage
- ✅ **Handles both meals and drinks** - Automatically detects and analyzes beverages

## Setup Instructions

### 1. Get Your Free API Key

1. Go to [Google AI Studio](https://aistudio.google.com/app/apikey)
2. Sign in with your Google account
3. Click "Create API Key"
4. Copy your API key

### 2. Add to Backend Environment Variables

Add the following to your backend `.env` file or deployment environment:

```bash
GEMINI_API_KEY=your_api_key_here
```

### 3. Install Dependencies

```bash
cd backend
npm install @google/generative-ai
```

Or if you're updating:

```bash
npm install
```

### 4. Restart Your Backend Server

After adding the environment variable, restart your backend server.

## Features

### Meal Scanning
- Recognizes multiple food items in a single image
- Estimates portion sizes
- Calculates calories, protein, carbs, fat, and **sugar**
- Works with complex meals (multiple dishes)

### Drink Analysis
- Automatically detects beverages
- Calculates calories and sugar content
- Identifies drink types (soda, juice, coffee, etc.)
- Estimates serving sizes

### Nutritional Data
All analyzed items include:
- **Calories** - Estimated caloric content
- **Protein** - Grams of protein
- **Carbs** - Grams of carbohydrates
- **Fat** - Grams of fat
- **Sugar** - Grams of sugar (especially important for drinks)
- **Portion Size** - Estimated serving size

## API Model

The app uses **Gemini 1.5 Flash** model, which is:
- Fast and responsive
- Cost-effective
- Optimized for vision tasks
- Great for real-time food analysis

## Error Handling

The implementation includes:
- ✅ 45-second timeout (faster than previous 60s)
- ✅ Proper error messages for API issues
- ✅ Rate limit handling
- ✅ Authentication error detection
- ✅ Fallback responses if parsing fails

## Testing

1. Open the app
2. Go to Home → Scan Meal
3. Take a photo of food or a drink
4. Wait for analysis (typically 2-5 seconds)
5. Review the nutritional breakdown

## Troubleshooting

### "Food recognition service is not configured"
- Make sure `GEMINI_API_KEY` is set in your environment variables
- Restart your backend server after adding the key

### "Request timeout"
- Check your internet connection
- Try with a clearer, well-lit photo
- Ensure the image is under 10MB

### "Rate limit exceeded"
- You've hit the API rate limit
- Wait a few minutes and try again
- Consider upgrading your Google AI Studio plan if needed

## Free Tier Limits

Google Gemini free tier includes:
- Generous request limits
- No credit card required initially
- Perfect for development and moderate usage

For production apps with high volume, consider upgrading to a paid plan.

## Support

For issues with:
- **API Key**: Check [Google AI Studio](https://aistudio.google.com/app/apikey)
- **API Documentation**: [Google Gemini Docs](https://ai.google.dev/docs)
- **App Issues**: Check backend logs for detailed error messages

