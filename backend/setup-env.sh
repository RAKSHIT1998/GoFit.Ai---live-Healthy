#!/bin/bash

# GoFit.ai Backend Environment Setup Script
# This script helps you set up your .env file with the required credentials

echo "🚀 GoFit.ai Backend Environment Setup"
echo "======================================"
echo ""

# Check if .env already exists
if [ -f .env ]; then
    echo "⚠️  .env file already exists!"
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Setup cancelled."
        exit 1
    fi
fi

# Create .env file
cat > .env << 'EOF'
# Server Configuration
PORT=3000
NODE_ENV=development

# Database - MongoDB Atlas Connection String
MONGODB_URI=mongodb+srv://rakshitbargotra_db_user:Admin9858@cluster0.3ia87nv.mongodb.net/gofitai?retryWrites=true&w=majority

# JWT Secret
JWT_SECRET=gofit-ai-super-secret-jwt-key-change-in-production-min-32-chars-please-use-random
JWT_EXPIRES_IN=7d

# OpenAI API Key
OPENAI_API_KEY=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

# AWS S3 (or DigitalOcean Spaces) - For image storage
# TODO: Set up your S3 bucket and add credentials here
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
AWS_REGION=us-east-1
S3_BUCKET_NAME=gofit-ai-meals

# Redis (for BullMQ) - Optional for background jobs
REDIS_HOST=localhost
REDIS_PORT=6379

# Apple In-App Purchase
APPLE_SHARED_SECRET=your-apple-shared-secret
APPLE_BUNDLE_ID=com.gofitai.app

# CORS - Allowed origins
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080
EOF

echo "✅ .env file created successfully!"
echo ""
echo "📝 Next steps:"
echo "1. Set up AWS S3 bucket for image storage (or use DigitalOcean Spaces)"
echo "2. Add AWS credentials to .env file"
echo "3. Configure Apple In-App Purchase shared secret (when ready)"
echo "4. Run 'npm install' to install dependencies"
echo "5. Run 'npm run dev' to start the server"
echo ""
echo "⚠️  IMPORTANT: Never commit .env file to git! It's already in .gitignore"

