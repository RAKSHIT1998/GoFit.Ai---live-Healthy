# GoFit.ai — HealthyLife Tracker

A production-ready iOS health tracking app with Apple Watch integration, AI-powered food scanning, and personalized meal/workout recommendations.

## Features

- 📸 **AI Food Scanning** - Take photos of meals for instant nutrition analysis using OpenAI Vision API
- 🎯 **Personalized Recommendations** - Daily AI-driven meal and workout plans
- ⏱️ **Intermittent Fasting** - Track fasting windows with timer and streak counter
- ⌚ **Apple Watch Integration** - Sync steps, heart rate, active calories, and quick water logging
- 📊 **Health Analytics** - Comprehensive tracking of calories, macros, weight, and activity
- 💳 **Apple In-App Purchase** - Subscription with 3-day free trial
- 🔐 **Secure Authentication** - JWT-based auth with Keychain storage
- ☁️ **Cloud Sync** - All data synced to backend with offline support

## Tech Stack

### iOS App
- **SwiftUI** - Modern declarative UI framework
- **SwiftData** - Local data persistence
- **HealthKit** - Apple Health integration
- **StoreKit 2** - In-App Purchase management
- **Keychain** - Secure token storage

### Backend
- **Node.js + Express** - RESTful API server
- **MongoDB** - Database for user data, meals, fasting sessions
- **AWS S3** - Image storage for meal photos
- **OpenAI API** - Food analysis and recommendations
- **BullMQ + Redis** - Background job processing
- **JWT** - Authentication tokens

## Project Structure

```
GoFit.Ai - live Healthy/
├── Features/
│   ├── Authentication/     # Signup, login, profile
│   ├── Onboarding/         # Interactive onboarding flow
│   ├── Home/               # Dashboard with health metrics
│   ├── MealScanner/        # Camera, photo analysis
│   ├── MealHistory/        # Meal logs and history
│   ├── Fasting/            # Fasting timer and tracking
│   ├── Paywall/            # Subscription management
│   ├── Settings/           # App settings
│   └── Workout/            # Workout suggestions
├── Services/
│   ├── AuthService.swift   # Authentication service
│   ├── NetworkManager.swift # API client
│   ├── HealthKitService.swift # HealthKit integration
│   └── OfflineMealStore.swift # Offline meal storage
├── Models/                 # Data models
└── Helpers/               # Utilities

backend/
├── models/                # MongoDB schemas
├── routes/                # API endpoints
├── middleware/            # Auth middleware
├── config/                # Database, Redis config
└── server.js              # Express server
```

## Setup Instructions

### Prerequisites

- Xcode 15+ (for iOS development)
- Node.js 18+ (for backend)
- MongoDB (local or cloud instance)
- Redis (for job queues)
- AWS account (for S3 storage)
- OpenAI API key

### Backend Setup

1. **Install dependencies:**
```bash
cd backend
npm install
```

2. **Configure environment:**
```bash
cp .env.example .env
# Edit .env with your credentials
```

3. **Start MongoDB and Redis:**
```bash
# MongoDB
mongod

# Redis
redis-server
```

4. **Run the server:**
```bash
npm run dev  # Development mode with nodemon
# or
npm start    # Production mode
```

The backend will run on `http://localhost:3000`

### iOS App Setup

1. **Open the project:**
```bash
open "GoFit.Ai - live Healthy.xcodeproj"
```

2. **Configure API endpoint:**
   - Update `Core/EnvironmentConfig.swift` with your backend URL
   - For development: `http://localhost:3000/api`
   - For production: `https://api.gofit.ai/api`

3. **Add HealthKit capability:**
   - In Xcode, go to Signing & Capabilities
   - Add "HealthKit" capability
   - Add required permissions in `Info.plist`

4. **Configure In-App Purchase:**
   - Set up products in App Store Connect
   - Update product IDs in `PurchaseManager.swift`:
     - `com.gofitai.premium.monthly`
     - `com.gofitai.premium.yearly`

5. **Build and run:**
   - Select your target device/simulator
   - Press Cmd+R to build and run

### Apple Watch App Setup

1. **Add Watch target:**
   - File → New → Target → watchOS → App
   - Name it "GoFit Watch App"

2. **Configure WatchKit:**
   - Add HealthKit capability to Watch app
   - Set up Watch Connectivity for iPhone communication

3. **Implement Watch features:**
   - Steps display
   - Quick water logging
   - Fasting timer complication
   - Heart rate monitoring

## API Endpoints

### Authentication
- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login
- `GET /api/auth/me` - Get current user
- `PUT /api/auth/profile` - Update profile

### Meals
- `POST /api/photo/analyze` - Analyze food photo (multipart/form-data)
- `POST /api/meals/save` - Save meal entry
- `GET /api/meals/list` - Get meal history
- `GET /api/meals/summary/today` - Today's nutrition summary

### Fasting
- `POST /api/fasting/start` - Start fasting session
- `POST /api/fasting/end` - End fasting session
- `GET /api/fasting/current` - Current fasting status
- `GET /api/fasting/history` - Fasting history

### Health
- `POST /api/health/sync` - Sync Apple Health data
- `GET /api/health/summary` - Health summary
- `POST /api/health/water` - Log water intake
- `POST /api/health/weight` - Log weight

### Recommendations
- `GET /api/recommendations/daily` - Get daily recommendations
- `POST /api/recommendations/regenerate` - Regenerate recommendations

### Subscriptions
- `POST /api/subscriptions/verify` - Verify Apple receipt
- `GET /api/subscriptions/status` - Get subscription status

## Database Schema

### User
- Personal info (name, email, password)
- Goals and preferences
- Subscription status
- Health metrics
- Apple Health sync data

### Meal
- Items array (name, calories, macros)
- Image URL (S3)
- Timestamp
- AI version used

### FastingSession
- Start/end times
- Target hours
- Status (active/completed)

### Recommendation
- Daily meal plan
- Workout plan
- Hydration goals
- AI insights

## Security & Privacy

- **JWT Authentication** - Secure token-based auth
- **Keychain Storage** - Tokens stored securely on device
- **HTTPS Only** - All API communication encrypted
- **HealthKit Permissions** - Explicit user consent required
- **GDPR Compliant** - Data export and deletion support
- **Encrypted Database** - Sensitive fields encrypted at rest

## App Store Compliance

- ✅ Privacy Policy and Terms of Service
- ✅ Health data usage disclosure
- ✅ Camera and photo library permissions
- ✅ HealthKit data sharing consent
- ✅ Subscription terms clearly displayed
- ✅ Data export functionality
- ✅ Account deletion option

## Development Roadmap

### Phase 1 - MVP ✅
- [x] Onboarding flow
- [x] Authentication
- [x] Food photo scanning
- [x] Basic recommendations
- [x] Fasting tracking
- [x] Apple Health integration
- [x] In-App Purchase

### Phase 2 - Advanced
- [ ] Advanced analytics
- [ ] Weekly summaries
- [ ] HR zone analysis
- [ ] Sleep insights
- [ ] Social features
- [ ] Challenge system
- [ ] Apple Watch app

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

Copyright © 2024 GoFit.ai. All rights reserved.

## Support

For issues and questions:
- Email: support@gofit.ai
- Documentation: [docs.gofit.ai](https://docs.gofit.ai)

---

Built with ❤️ using SwiftUI and Node.js

