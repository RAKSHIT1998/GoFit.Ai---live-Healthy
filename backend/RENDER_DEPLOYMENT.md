# Deploying to Render

## Option 1: Native Node.js Deployment (Recommended - No Docker)

This is the easiest way to deploy to Render.

### Steps:

1. **Push your code to GitHub/GitLab/Bitbucket**
   - Make sure your `backend` folder is in the repository
   - Or create a separate repository just for the backend

2. **Create a new Web Service on Render**
   - Go to https://dashboard.render.com
   - Click "New +" → "Web Service"
   - Connect your repository
   - Select the repository and branch

3. **Configure the service:**
   - **Name**: `gofit-ai-backend` (or your preferred name)
   - **Environment**: `Node`
   - **Root Directory**: `backend` (if backend is in a subfolder)
   - **Build Command**: `npm install`
   - **Start Command**: `npm start`
   - **Plan**: Choose based on your needs (Starter is fine for testing)

4. **Add Environment Variables:**
   Click "Environment" tab and add:
   ```
   NODE_ENV=production
   PORT=10000
   MONGODB_URI=your_mongodb_connection_string
   REDIS_HOST=your_redis_host (if using Render Redis)
   REDIS_PORT=6379
   JWT_SECRET=your_jwt_secret_key
   OPENAI_API_KEY=your_openai_api_key
   AWS_ACCESS_KEY_ID=your_aws_key
   AWS_SECRET_ACCESS_KEY=your_aws_secret
   AWS_REGION=us-east-1
   S3_BUCKET_NAME=your_s3_bucket_name
   APPLE_SHARED_SECRET=your_apple_shared_secret
   APPLE_BUNDLE_ID=com.gofitai.app
   ALLOWED_ORIGINS=https://your-frontend-domain.com,https://your-app.com
   ```

5. **Deploy**
   - Click "Create Web Service"
   - Render will automatically build and deploy

## Option 2: Docker Deployment

If you prefer Docker deployment:

1. **Use the Dockerfile provided**
   - The `Dockerfile` is already in the backend folder
   - Render will automatically detect and use it

2. **Create a new Web Service on Render**
   - Same steps as above, but Render will use Docker instead

3. **Configure:**
   - **Environment**: `Docker`
   - **Dockerfile Path**: `backend/Dockerfile` (if backend is in subfolder)
   - Or just `Dockerfile` if deploying from backend root

## Important Notes:

### MongoDB:
- Use MongoDB Atlas (free tier available): https://www.mongodb.com/cloud/atlas
- Or use Render's MongoDB service (paid)

### Redis:
- Use Render's Redis service (free tier available)
- Or use Redis Cloud (free tier): https://redis.com/try-free/
- Or use Upstash Redis (free tier): https://upstash.com/

### Environment Variables:
- **Never commit `.env` file to git**
- Add all sensitive variables in Render dashboard
- Use Render's environment variable encryption for secrets

### CORS:
- Update `ALLOWED_ORIGINS` to include your production frontend URL
- Example: `ALLOWED_ORIGINS=https://your-app.com,https://www.your-app.com`

### Health Check:
- Render will use `/health` endpoint for health checks
- Make sure this endpoint is working

## Troubleshooting:

1. **Build fails:**
   - Check build logs in Render dashboard
   - Ensure all dependencies are in `package.json`
   - Check Node.js version compatibility

2. **App crashes on start:**
   - Check runtime logs
   - Verify all environment variables are set
   - Ensure MongoDB and Redis are accessible

3. **Connection errors:**
   - Verify MongoDB URI is correct
   - Check Redis connection settings
   - Ensure firewall allows connections

4. **Port issues:**
   - Render provides `PORT` environment variable automatically
   - Your app should use `process.env.PORT || 3000`

## Quick Deploy Checklist:

- [ ] Code pushed to Git repository
- [ ] MongoDB Atlas cluster created and connection string ready
- [ ] Redis instance created (Render Redis or external)
- [ ] All environment variables added to Render
- [ ] CORS origins updated for production
- [ ] Health check endpoint working (`/health`)
- [ ] Build command: `npm install`
- [ ] Start command: `npm start`

## After Deployment:

1. Test the health endpoint: `https://your-service.onrender.com/health`
2. Test API endpoints
3. Update iOS app's `EnvironmentConfig.swift` with production API URL
4. Monitor logs in Render dashboard

