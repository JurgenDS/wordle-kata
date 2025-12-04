#!/bin/bash
#
# Post-create script for Wordle Kata devcontainer
# This runs once when the container is first created
#

set -e

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║     WORDLE KATA - DEVCONTAINER SETUP                      ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

print_step() {
    echo -e "${CYAN}▶ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# ═══════════════════════════════════════════════════════════════
# VERIFY TOOLS
# ═══════════════════════════════════════════════════════════════
print_step "Verifying installed tools..."

echo "  Java:      $(java -version 2>&1 | head -1)"
echo "  Maven:     $(mvn -v 2>&1 | head -1)"
echo "  Node.js:   $(node -v)"
echo "  pnpm:      $(pnpm -v)"
echo "  Angular:   $(ng version 2>&1 | grep 'Angular CLI' || echo 'CLI installed')"
echo "  Gitleaks:  $(gitleaks version 2>&1)"
echo "  Semgrep:   $(semgrep --version 2>&1)"
echo ""

# ═══════════════════════════════════════════════════════════════
# INSTALL FRONTEND DEPENDENCIES
# ═══════════════════════════════════════════════════════════════
print_step "Installing frontend dependencies..."

cd /workspace/frontend

# Remove old node_modules if exists (clean install)
if [ -d "node_modules" ]; then
    print_warning "Removing existing node_modules..."
    rm -rf node_modules 2>/dev/null || sudo rm -rf node_modules 2>/dev/null || true
fi

# Try normal install first, then sudo if it fails (Windows bind mount workaround)
if pnpm install 2>/dev/null; then
    print_success "Frontend dependencies installed"
elif sudo -E pnpm install 2>/dev/null; then
    print_success "Frontend dependencies installed (with elevated permissions)"
    # Fix ownership after sudo install
    sudo chown -R $(id -u):$(id -g) node_modules 2>/dev/null || true
else
    print_warning "Frontend dependencies installation had issues"
fi

# Install license-checker as dev dependency
pnpm add -D license-checker || true

cd /workspace

# ═══════════════════════════════════════════════════════════════
# INSTALL E2E DEPENDENCIES
# ═══════════════════════════════════════════════════════════════
print_step "Installing E2E test dependencies..."

cd /workspace/e2e-tests

# Remove old node_modules if exists (clean install)
if [ -d "node_modules" ]; then
    print_warning "Removing existing node_modules..."
    rm -rf node_modules 2>/dev/null || sudo rm -rf node_modules 2>/dev/null || true
fi

# Try normal install first, then sudo if it fails (Windows bind mount workaround)
if pnpm install 2>/dev/null; then
    print_success "E2E dependencies installed"
elif sudo -E pnpm install 2>/dev/null; then
    print_success "E2E dependencies installed (with elevated permissions)"
    sudo chown -R $(id -u):$(id -g) node_modules 2>/dev/null || true
else
    print_warning "E2E dependencies installation had issues"
fi

# Install Playwright browsers
print_step "Installing Playwright browsers..."
if pnpm exec playwright install; then
    print_success "Playwright browsers installed"
else
    print_warning "Playwright browser installation had issues"
fi

cd /workspace

# ═══════════════════════════════════════════════════════════════
# IMPORT OWASP DEPENDENCY-CHECK CACHE
# ═══════════════════════════════════════════════════════════════
print_step "Setting up OWASP Dependency-Check cache..."

OWASP_CACHE_ZIP="/workspace/data/owasp-cache/dependency-check-data.zip"
OWASP_TARGET_DIR="$HOME/.m2/repository/org/owasp"

if [ -f "$OWASP_CACHE_ZIP" ]; then
    if [ ! -d "$OWASP_TARGET_DIR/dependency-check-data" ]; then
        print_step "Extracting OWASP database cache (saves 10-20 min on first build)..."
        mkdir -p "$OWASP_TARGET_DIR"
        unzip -q "$OWASP_CACHE_ZIP" -d "$OWASP_TARGET_DIR"
        print_success "OWASP database cache imported"
    else
        print_success "OWASP database cache already exists"
    fi
else
    print_warning "OWASP cache not found - first dependency-check will download database"
    echo "  To speed up: run 'git lfs pull' to download the cache file"
fi

# ═══════════════════════════════════════════════════════════════
# FIX WORKSPACE PERMISSIONS (Windows compatibility)
# ═══════════════════════════════════════════════════════════════
print_step "Fixing workspace permissions (Windows bind mount compatibility)..."

# Fix ownership of workspace directories that may have been created by root or with wrong permissions
sudo chown -R $(id -u):$(id -g) /workspace/backend 2>/dev/null || true
sudo chown -R $(id -u):$(id -g) /workspace/frontend 2>/dev/null || true
sudo chown -R $(id -u):$(id -g) /workspace/e2e-tests 2>/dev/null || true

# Remove any existing target directory that might have wrong permissions
if [ -d "/workspace/backend/target" ]; then
    sudo rm -rf /workspace/backend/target 2>/dev/null || rm -rf /workspace/backend/target 2>/dev/null || true
fi

print_success "Workspace permissions fixed"

# ═══════════════════════════════════════════════════════════════
# BUILD BACKEND
# ═══════════════════════════════════════════════════════════════
print_step "Building backend (this may take a few minutes on first run)..."

cd /workspace/backend

# Load .env if exists (for NVD_API_KEY)
if [ -f ".env" ]; then
    # Convert CRLF to LF (Windows line endings cause issues)
    sed -i 's/\r$//' .env 2>/dev/null || true
    set -a
    source .env
    set +a
    echo "  Loaded environment variables from backend/.env"
fi

if mvn install -DskipTests -q; then
    print_success "Backend built successfully"
else
    print_warning "Backend build had issues - will retry during tests"
fi

cd /workspace

# ═══════════════════════════════════════════════════════════════
# SETUP GIT HOOKS (optional)
# ═══════════════════════════════════════════════════════════════
print_step "Setting up git configuration..."

# Configure git to use the workspace as safe directory
git config --global --add safe.directory /workspace

# Set default branch name for new repos
git config --global init.defaultBranch main

print_success "Git configured"

# ═══════════════════════════════════════════════════════════════
# CREATE HELPFUL ALIASES
# ═══════════════════════════════════════════════════════════════
print_step "Setting up shell aliases..."

ALIASES_FILE="$HOME/.bash_aliases"

cat > "$ALIASES_FILE" << 'EOF'
# Wordle Kata aliases

# Quality check
alias qc='./quality-check.sh'
alias qc-mutation='./quality-check.sh --mutation'

# Backend
alias be='cd /workspace/backend'
alias be-run='cd /workspace/backend && mvn spring-boot:run'
alias be-test='cd /workspace/backend && mvn test'
alias be-build='cd /workspace/backend && mvn clean install'

# Frontend
alias fe='cd /workspace/frontend'
alias fe-start='cd /workspace/frontend && pnpm start'
alias fe-test='cd /workspace/frontend && pnpm test'
alias fe-build='cd /workspace/frontend && pnpm build'
alias fe-lint='cd /workspace/frontend && pnpm lint'

# E2E tests
alias e2e='cd /workspace/e2e-tests'
alias e2e-test='cd /workspace/e2e-tests && pnpm test:e2e'
alias e2e-ui='cd /workspace/e2e-tests && pnpm test:e2e:ui'
alias e2e-headed='cd /workspace/e2e-tests && pnpm test:e2e:headed'

# General
alias ws='cd /workspace'
alias ll='ls -la'
alias ..='cd ..'
alias ...='cd ../..'
EOF

# Source in bashrc if not already there
if ! grep -q "bash_aliases" "$HOME/.bashrc" 2>/dev/null; then
    echo '[ -f ~/.bash_aliases ] && source ~/.bash_aliases' >> "$HOME/.bashrc"
fi

# Also add to zshrc if it exists
if [ -f "$HOME/.zshrc" ]; then
    if ! grep -q "bash_aliases" "$HOME/.zshrc" 2>/dev/null; then
        echo '[ -f ~/.bash_aliases ] && source ~/.bash_aliases' >> "$HOME/.zshrc"
    fi
fi

# Add .env loading to shell profiles (for NVD_API_KEY, etc.)
ENV_LOADER='
# Load backend .env file for NVD_API_KEY and other secrets
if [ -f /workspace/backend/.env ]; then
    # Convert CRLF to LF first (Windows compatibility)
    sed -i "s/\r$//" /workspace/backend/.env 2>/dev/null || true
    set -a
    source /workspace/backend/.env
    set +a
fi
'

if ! grep -q "backend/.env" "$HOME/.bashrc" 2>/dev/null; then
    echo "$ENV_LOADER" >> "$HOME/.bashrc"
fi

if [ -f "$HOME/.zshrc" ] && ! grep -q "backend/.env" "$HOME/.zshrc" 2>/dev/null; then
    echo "$ENV_LOADER" >> "$HOME/.zshrc"
fi

print_success "Shell aliases configured"

# ═══════════════════════════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════════════════════════
echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║     SETUP COMPLETE!                                       ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "Quick start commands:"
echo "  qc              - Run quality checks"
echo "  be-run          - Start backend (port 8080)"
echo "  fe-start        - Start frontend (port 4200)"
echo "  e2e-test        - Run E2E tests"
echo ""
echo "Useful locations:"
echo "  /workspace/backend    - Spring Boot backend"
echo "  /workspace/frontend   - Angular frontend"
echo "  /workspace/e2e-tests  - Playwright E2E tests"
echo ""
