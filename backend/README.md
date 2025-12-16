# GoFit.ai Backend API

Node.js + Express backend for GoFit.ai health tracking app.

## Quick Start

```bash
# Install dependencies
npm install

# Copy environment file
cp .env.example .env

# Edit .env with your credentials
# - MongoDB URI
# - OpenAI API key
# - AWS S3 credentials
# - JWT secret
# - Redis connection

# Start MongoDB and Redis
mongod
redis-server

# Run in development
npm run dev

# Run in production
npm start
```

## Environment Variables

See `.env.example` for all required variables.

## API Documentation

### Base URL
- Development: `http://localhost:3000/api`
- Production: `https://api.gofit.ai/api`

### Authentication
All protected routes require a Bearer token in the Authorization header:
```
Authorization: Bearer <jwt_token>
```

### Endpoints

#### Authentication
- `POST /auth/register` - Register new user
- `POST /auth/login` - Login user
- `GET /auth/me` - Get current user (protected)
- `PUT /auth/profile` - Update profile (protected)

#### Photo Analysis
- `POST /photo/analyze` - Upload and analyze food photo (multipart/form-data, protected)

#### Meals
- `POST /meals/save` - Save meal entry (protected)
- `GET /meals/list` - Get meal history (protected)
- `GET /meals/summary/today` - Today's nutrition summary (protected)

#### Fasting
- `POST /fasting/start` - Start fasting session (protected)
- `POST /fasting/end` - End fasting session (protected)
- `GET /fasting/current` - Current fasting status (protected)
- `GET /fasting/history` - Fasting history (protected)

#### Health
- `POST /health/sync` - Sync Apple Health data (protected)
- `GET /health/summary` - Health summary (protected)
- `POST /health/water` - Log water intake (protected)
- `POST /health/weight` - Log weight (protected)

#### Recommendations
- `GET /recommendations/daily` - Get daily recommendations (protected)
- `POST /recommendations/regenerate` - Regenerate recommendations (protected)

#### Subscriptions
- `POST /subscriptions/verify` - Verify Apple receipt (protected)
- `GET /subscriptions/status` - Get subscription status (protected)

#### Admin
- `GET /admin/users` - List all users (admin only)
- `GET /admin/metrics` - Get platform metrics (admin only)
- `GET /admin/scans` - Get food scan logs (admin only)

## Database Models

### User
- Stores user profile, goals, preferences
- Subscription status
- Health data sync information

### Meal
- Food items with nutrition data
- S3 image URL
- Timestamps and AI version

### FastingSession
- Start/end times
- Target and actual hours
- Status tracking

### Recommendation
- Daily meal and workout plans
- AI-generated insights
- Date-based recommendations

## AI Integration

### Food Analysis
Uses OpenAI GPT-4 Vision API to analyze food photos and extract:
- Food items
- Estimated calories
- Macros (protein, carbs, fat)
- Portion sizes
- Confidence scores

### Recommendations
Uses OpenAI GPT-4 to generate personalized:
- Daily meal plans
- Workout suggestions
- Hydration goals
- Health insights

## Image Storage

Meal photos are stored in AWS S3:
- Path: `meals/{userId}/{timestamp}-{filename}`
- Private access
- Automatic cleanup on meal deletion

## Background Jobs

Heavy AI processing is queued using BullMQ:
- Photo analysis queue
- Recommendation generation
- Daily health sync

## Security

- JWT authentication with 7-day expiration
- Password hashing with bcrypt
- Rate limiting (100 requests per 15 minutes)
- CORS protection
- Helmet.js security headers

## Deployment

### Production Checklist
- [ ] Set `NODE_ENV=production`
- [ ] Use strong `JWT_SECRET`
- [ ] Configure MongoDB connection string
- [ ] Set up Redis instance
- [ ] Configure AWS S3 bucket
- [ ] Set OpenAI API key
- [ ] Configure Apple receipt verification
- [ ] Set up SSL/TLS
- [ ] Configure CORS origins
- [ ] Set up monitoring/logging

### Docker Deployment
```bash
docker build -t gofit-backend .
docker run -p 3000:3000 --env-file .env gofit-backend
```

## Testing

```bash
# Run tests (when implemented)
npm test
```

## License

Copyright © 2024 GoFit.ai. All rights reserved.

