#!/bin/bash

# Quick script to start the backend server locally

echo "🚀 Starting GoFit.Ai Backend Server..."
echo ""

# Check if .env exists
if [ ! -f .env ]; then
    echo "⚠️  .env file not found!"
    echo "📝 Creating .env from config.example.env..."
    
    if [ -f config.example.env ]; then
        cp config.example.env .env
        echo "✅ Created .env file"
        echo "⚠️  Please update .env with your actual credentials before continuing"
        echo ""
        read -p "Press Enter after updating .env file..."
    else
        echo "❌ config.example.env not found!"
        exit 1
    fi
fi

# Check if node_modules exists
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
fi

# Start the server
echo "🚀 Starting server on http://localhost:3000"
echo "📱 Make sure your iOS app is configured to use: http://localhost:3000/api"
echo ""
npm start

