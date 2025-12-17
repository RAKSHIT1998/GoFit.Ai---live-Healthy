# Create Test User Account

This guide shows you how to create a test user account for logging into the app.

## Method 1: Using the Script (Recommended)

### Prerequisites
- Backend dependencies installed (`npm install`)
- MongoDB connection configured in `.env` file

### Steps

1. **Navigate to backend directory:**
   ```bash
   cd backend
   ```

2. **Run the script:**
   ```bash
   npm run create-test-user
   ```

   Or directly:
   ```bash
   node scripts/create-test-user.js
   ```

3. **The script will:**
   - Generate random credentials
   - Create a test user in MongoDB
   - Display the email and password

4. **Use the credentials shown to login in the app!**

### Example Output:
```
✅ Connected to MongoDB
✅ Test user created successfully!

📋 Test User Credentials:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Email:    testuser_abc123@gofit.ai
Password: TestPass123!abc123
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💡 You can now use these credentials to login in the app.
```

## Method 2: Using the API Endpoint

If your backend is running, you can create a user via the registration endpoint:

```bash
curl -X POST https://gofit-ai-live-healthy-1.onrender.com/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "testuser@example.com",
    "password": "TestPassword123!"
  }'
```

**Note:** Replace the email and password with your desired credentials.

## Method 3: Manual MongoDB Insert (Advanced)

If you have direct MongoDB access:

1. Connect to your MongoDB database
2. Insert a user document:

```javascript
db.users.insertOne({
  name: "Test User",
  email: "testuser@example.com",
  passwordHash: "$2a$10$..." // bcrypt hash of your password
})
```

**Note:** You'll need to hash the password using bcrypt first.

## Quick Test Credentials

If you just want to test quickly, here's a pre-generated account you can create:

**Email:** `testuser_demo@gofit.ai`  
**Password:** `TestPass123!demo`

Run this curl command to create it:

```bash
curl -X POST https://gofit-ai-live-healthy-1.onrender.com/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Demo User",
    "email": "testuser_demo@gofit.ai",
    "password": "TestPass123!demo"
  }'
```

## Troubleshooting

### Script fails to connect to MongoDB
- Check your `MONGODB_URI` in `.env` file
- Verify MongoDB credentials are correct
- Ensure MongoDB Atlas IP whitelist includes your IP

### "User already exists" error
- The email is already registered
- Use a different email or delete the existing user

### Script not found
- Make sure you're in the `backend` directory
- Verify `scripts/create-test-user.js` exists

## Notes

- Test users are created with:
  - Status: `free` (no subscription)
  - Goals: `maintain`
  - Activity Level: `moderate`
  - No dietary preferences or allergies

- Passwords must be at least 8 characters long

- The script generates random credentials each time to avoid conflicts

