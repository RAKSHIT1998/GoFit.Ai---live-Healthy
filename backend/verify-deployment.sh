#!/bin/bash

# Production Deployment Verification Script
# Run this before deploying to ensure everything is ready

echo "🔍 GoFit.AI Production Readiness Check"
echo "========================================"
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0
WARNINGS=0

# Check Node.js version
echo "📦 Checking Node.js version..."
NODE_VERSION=$(node -v)
if [[ $NODE_VERSION == v* ]]; then
    echo -e "${GREEN}✓${NC} Node.js installed: $NODE_VERSION"
    ((PASSED++))
else
    echo -e "${RED}✗${NC} Node.js not found"
    ((FAILED++))
fi

# Check if in backend directory
if [ ! -f "package.json" ]; then
    echo -e "${RED}✗${NC} Not in backend directory. Run: cd backend"
    exit 1
fi

# Check package.json exists
echo ""
echo "📋 Checking configuration files..."
if [ -f "package.json" ]; then
    echo -e "${GREEN}✓${NC} package.json exists"
    ((PASSED++))
else
    echo -e "${RED}✗${NC} package.json missing"
    ((FAILED++))
fi

# Check Socket.IO dependency
echo ""
echo "🔌 Checking Socket.IO installation..."
if grep -q "socket.io" package.json; then
    SOCKETIO_VERSION=$(grep "socket.io" package.json | cut -d'"' -f4)
    echo -e "${GREEN}✓${NC} Socket.IO in package.json: $SOCKETIO_VERSION"
    ((PASSED++))
else
    echo -e "${RED}✗${NC} Socket.IO not in package.json"
    ((FAILED++))
fi

# Check if node_modules exists
if [ -d "node_modules/socket.io" ]; then
    echo -e "${GREEN}✓${NC} Socket.IO installed in node_modules"
    ((PASSED++))
else
    echo -e "${YELLOW}⚠${NC} Socket.IO not installed. Run: npm install"
    ((WARNINGS++))
fi

# Check WebSocket service file
echo ""
echo "🌐 Checking WebSocket service..."
if [ -f "services/websocketService.js" ]; then
    echo -e "${GREEN}✓${NC} websocketService.js exists"
    ((PASSED++))
else
    echo -e "${RED}✗${NC} websocketService.js missing"
    ((FAILED++))
fi

# Check server.js has Socket.IO import
if grep -q "wsService" server.js; then
    echo -e "${GREEN}✓${NC} server.js imports WebSocket service"
    ((PASSED++))
else
    echo -e "${RED}✗${NC} server.js doesn't import WebSocket service"
    ((FAILED++))
fi

# Check environment variables
echo ""
echo "🔐 Checking environment configuration..."
if [ -f ".env" ]; then
    echo -e "${YELLOW}⚠${NC} .env file exists (local only, not for production)"
    ((WARNINGS++))
fi

# Check required routes exist
echo ""
echo "📁 Checking route files..."
ROUTES=("auth.js" "friends.js" "challenges.js" "notifications.js" "gamification.js")
for route in "${ROUTES[@]}"; do
    if [ -f "routes/$route" ]; then
        echo -e "${GREEN}✓${NC} routes/$route exists"
        ((PASSED++))
    else
        echo -e "${RED}✗${NC} routes/$route missing"
        ((FAILED++))
    fi
done

# Check ES6 module configuration
echo ""
echo "📦 Checking ES6 module setup..."
if grep -q '"type": "module"' package.json; then
    echo -e "${GREEN}✓${NC} ES6 modules enabled in package.json"
    ((PASSED++))
else
    echo -e "${RED}✗${NC} ES6 modules not configured"
    ((FAILED++))
fi

# Check start script
if grep -q '"start": "node server.js"' package.json; then
    echo -e "${GREEN}✓${NC} Start script configured"
    ((PASSED++))
else
    echo -e "${YELLOW}⚠${NC} Start script may be incorrect"
    ((WARNINGS++))
fi

# Check git status
echo ""
echo "📤 Checking git status..."
if git rev-parse --git-dir > /dev/null 2>&1; then
    UNCOMMITTED=$(git status --porcelain | wc -l | xargs)
    if [ "$UNCOMMITTED" -eq "0" ]; then
        echo -e "${GREEN}✓${NC} All changes committed"
        ((PASSED++))
    else
        echo -e "${YELLOW}⚠${NC} $UNCOMMITTED uncommitted changes"
        echo "   Run: git add . && git commit -m 'message' && git push"
        ((WARNINGS++))
    fi
else
    echo -e "${YELLOW}⚠${NC} Not a git repository"
    ((WARNINGS++))
fi

# Summary
echo ""
echo "========================================"
echo "📊 Summary"
echo "========================================"
echo -e "${GREEN}Passed:${NC}   $PASSED"
echo -e "${YELLOW}Warnings:${NC} $WARNINGS"
echo -e "${RED}Failed:${NC}   $FAILED"
echo ""

if [ $FAILED -eq 0 ]; then
    if [ $WARNINGS -eq 0 ]; then
        echo -e "${GREEN}✅ Ready for production deployment!${NC}"
        echo ""
        echo "Next steps:"
        echo "1. Commit and push: git push origin main"
        echo "2. Render will auto-deploy"
        echo "3. Monitor logs in Render Dashboard"
        exit 0
    else
        echo -e "${YELLOW}⚠️  Ready with warnings${NC}"
        echo ""
        echo "Review warnings above before deploying"
        exit 0
    fi
else
    echo -e "${RED}❌ Not ready for deployment${NC}"
    echo ""
    echo "Fix the failed checks above"
    exit 1
fi
