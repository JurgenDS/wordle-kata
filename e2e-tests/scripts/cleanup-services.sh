#!/bin/sh
# Cleanup script for orphaned backend/frontend processes
# Use this if tests crash and leave processes running

echo "🧹 Cleaning up services..."

# Kill backend (Maven Spring Boot)
BACKEND_PIDS=$(lsof -ti:8080 2>/dev/null)
if [ -n "$BACKEND_PIDS" ]; then
  echo "  Stopping backend (port 8080)..."
  echo "$BACKEND_PIDS" | xargs kill -9 2>/dev/null
  echo "  ✅ Backend stopped"
else
  echo "  ℹ️  No backend process found"
fi

# Kill frontend (Angular dev server)
FRONTEND_PIDS=$(lsof -ti:4200 2>/dev/null)
if [ -n "$FRONTEND_PIDS" ]; then
  echo "  Stopping frontend (port 4200)..."
  echo "$FRONTEND_PIDS" | xargs kill -9 2>/dev/null
  echo "  ✅ Frontend stopped"
else
  echo "  ℹ️  No frontend process found"
fi

# Also kill any mvn or npm start processes
MVN_PIDS=$(pgrep -f "mvn.*-Prun" 2>/dev/null)
if [ -n "$MVN_PIDS" ]; then
  echo "  Stopping Maven processes..."
  echo "$MVN_PIDS" | xargs kill -9 2>/dev/null
fi

NPM_PIDS=$(pgrep -f "npm.*start.*frontend" 2>/dev/null)
if [ -n "$NPM_PIDS" ]; then
  echo "  Stopping npm processes..."
  echo "$NPM_PIDS" | xargs kill -9 2>/dev/null
fi

echo ""
echo "✨ Cleanup complete! All services stopped."
