#!/bin/bash
#
# Post-start script for Wordle Kata devcontainer
# This runs every time the container starts
#

# Colors
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  WORDLE KATA - Development Container Ready${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# Load .env file if it exists (for NVD_API_KEY)
if [ -f "/workspace/backend/.env" ]; then
    set -a
    source /workspace/backend/.env
    set +a
    echo -e "${GREEN}✓${NC} Loaded environment variables from backend/.env"
fi

# Verify Java
java_version=$(java -version 2>&1 | head -1)
echo -e "${GREEN}✓${NC} Java: $java_version"

# Verify Node
node_version=$(node -v)
echo -e "${GREEN}✓${NC} Node.js: $node_version"

# Check if backend is built
if [ -d "/workspace/backend/target" ]; then
    echo -e "${GREEN}✓${NC} Backend: Built"
else
    echo -e "  Backend: Not built (run 'be-build' or 'mvn install')"
fi

# Check if frontend dependencies are installed
if [ -d "/workspace/frontend/node_modules" ]; then
    echo -e "${GREEN}✓${NC} Frontend: Dependencies installed"
else
    echo "  Frontend: Dependencies not installed (run 'cd frontend && pnpm install')"
fi

echo ""
echo "Quick commands:"
echo "  qc          Run quality checks"
echo "  be-run      Start backend (port 8080)"
echo "  fe-start    Start frontend (port 4200)"
echo "  e2e-test    Run E2E tests"
echo ""
