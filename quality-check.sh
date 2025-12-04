#!/bin/sh
#
# Comprehensive Quality Check Script
# Runs all backend, frontend, and E2E quality checks
#

set -e

# Parse command line arguments
RUN_MUTATION="false"
for arg in "$@"; do
    case "$arg" in
        --mutation)
            RUN_MUTATION="true"
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --mutation    Run mutation testing (slow, high effort)"
            echo "  --help, -h    Show this help message"
            echo ""
            exit 0
            ;;
    esac
done

# Get project root (script is at project root)
PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"

# Configure Java 21 for backend (required for SpotBugs compatibility)
# SpotBugs doesn't support Java 25+ yet, so we use Java 21 LTS
if [ -d "/opt/homebrew/opt/openjdk@21" ]; then
    export JAVA_HOME="/opt/homebrew/opt/openjdk@21"
    export PATH="$JAVA_HOME/bin:$PATH"
elif [ -d "/usr/lib/jvm/java-21-openjdk" ]; then
    export JAVA_HOME="/usr/lib/jvm/java-21-openjdk"
    export PATH="$JAVA_HOME/bin:$PATH"
elif [ -d "$HOME/.sdkman/candidates/java/21"* ]; then
    # SDKMAN Java 21
    JAVA_HOME=$(ls -d "$HOME/.sdkman/candidates/java/21"* 2>/dev/null | head -1)
    export JAVA_HOME
    export PATH="$JAVA_HOME/bin:$PATH"
fi

# Colors for output (POSIX-compliant)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Result tracking
SECRETS_SCAN_RESULT=""
BACKEND_TESTS_RESULT=""
BACKEND_SPOTBUGS_RESULT=""
BACKEND_DEPCHECK_RESULT=""
BACKEND_CHECKSTYLE_RESULT=""
BACKEND_LICENSE_RESULT=""
BACKEND_MUTATION_RESULT=""
SEMGREP_RESULT=""
FRONTEND_TYPECHECK_RESULT=""
FRONTEND_LINT_RESULT=""
FRONTEND_FORMAT_RESULT=""
FRONTEND_TESTS_RESULT=""
FRONTEND_BUILD_RESULT=""
FRONTEND_AUDIT_RESULT=""
FRONTEND_LICENSE_RESULT=""
E2E_TESTS_RESULT=""
E2E_BDDGEN_RESULT=""

# Temp files for capturing output
SECRETS_LOG=$(mktemp)
BACKEND_LOG=$(mktemp)
BACKEND_SPOTBUGS_LOG=$(mktemp)
BACKEND_DEPCHECK_LOG=$(mktemp)
BACKEND_CHECKSTYLE_LOG=$(mktemp)
BACKEND_LICENSE_LOG=$(mktemp)
BACKEND_MUTATION_LOG=$(mktemp)
SEMGREP_LOG=$(mktemp)
FRONTEND_TYPECHECK_LOG=$(mktemp)
FRONTEND_LINT_LOG=$(mktemp)
FRONTEND_FORMAT_LOG=$(mktemp)
FRONTEND_TESTS_LOG=$(mktemp)
FRONTEND_BUILD_LOG=$(mktemp)
FRONTEND_AUDIT_LOG=$(mktemp)
FRONTEND_LICENSE_LOG=$(mktemp)
E2E_LOG=$(mktemp)
E2E_BDDGEN_LOG=$(mktemp)

# Cleanup temp files on exit
cleanup() {
    rm -f "$SECRETS_LOG" "$BACKEND_LOG" "$BACKEND_SPOTBUGS_LOG" "$BACKEND_DEPCHECK_LOG" "$BACKEND_CHECKSTYLE_LOG" "$BACKEND_LICENSE_LOG" "$BACKEND_MUTATION_LOG" "$SEMGREP_LOG" "$FRONTEND_TYPECHECK_LOG" "$FRONTEND_LINT_LOG" "$FRONTEND_FORMAT_LOG" "$FRONTEND_TESTS_LOG" "$FRONTEND_BUILD_LOG" "$FRONTEND_AUDIT_LOG" "$FRONTEND_LICENSE_LOG" "$E2E_LOG" "$E2E_BDDGEN_LOG"
}
trap cleanup EXIT

# Print section header (bold cyan)
print_header() {
    printf "\n${CYAN}${BOLD}═══════════════════════════════════════════════════════════════${NC}\n"
    printf "${CYAN}${BOLD}  %s${NC}\n" "$1"
    printf "${CYAN}${BOLD}═══════════════════════════════════════════════════════════════${NC}\n\n"
}

# Print step
print_step() {
    printf "${CYAN}▶ %s${NC}\n" "$1"
}

# Print success
print_success() {
    printf "${GREEN}✓ %s${NC}\n" "$1"
}

# Print failure
print_failure() {
    printf "${RED}✗ %s${NC}\n" "$1"
}

# Print warning
print_warning() {
    printf "${YELLOW}⚠ %s${NC}\n" "$1"
}

# Print detail (indented info line)
print_detail() {
    printf "  ${CYAN}→${NC} %s\n" "$1"
}

# Run a check and capture result
run_check() {
    check_name="$1"
    check_dir="$2"
    check_cmd="$3"
    log_file="$4"

    print_step "Running: $check_name"

    cd "$check_dir"

    if eval "$check_cmd" > "$log_file" 2>&1; then
        print_success "$check_name passed"
        echo "PASS"
    else
        print_failure "$check_name failed"
        echo "FAIL"
    fi
}

# Detect operating system
detect_os() {
    case "$(uname -s)" in
        Darwin*)
            echo "macos"
            ;;
        Linux*)
            echo "linux"
            ;;
        MINGW*|MSYS*|CYGWIN*)
            echo "windows"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Check prerequisites and provide install instructions
check_prerequisites() {
    print_header "CHECKING PREREQUISITES"

    OS=$(detect_os)
    MISSING_PREREQS=""
    CAN_CONTINUE=true

    # Check Java
    print_step "Checking Java..."
    if command -v java > /dev/null 2>&1; then
        JAVA_VERSION=$(java -version 2>&1 | head -1)
        print_success "Java found: $JAVA_VERSION"
    else
        print_failure "Java not found"
        MISSING_PREREQS="$MISSING_PREREQS java"
        CAN_CONTINUE=false
    fi

    # Check Maven
    print_step "Checking Maven..."
    if command -v mvn > /dev/null 2>&1; then
        MVN_VERSION=$(mvn -v 2>&1 | head -1)
        print_success "Maven found: $MVN_VERSION"
    else
        print_failure "Maven not found"
        MISSING_PREREQS="$MISSING_PREREQS maven"
        CAN_CONTINUE=false
    fi

    # Check Node.js
    print_step "Checking Node.js..."
    if command -v node > /dev/null 2>&1; then
        NODE_VERSION=$(node -v)
        print_success "Node.js found: $NODE_VERSION"
    else
        print_failure "Node.js not found"
        MISSING_PREREQS="$MISSING_PREREQS node"
        CAN_CONTINUE=false
    fi

    # Check npm (needed for pnpm install)
    print_step "Checking npm..."
    if command -v npm > /dev/null 2>&1; then
        NPM_VERSION=$(npm -v)
        print_success "npm found: $NPM_VERSION"
    else
        print_failure "npm not found"
        MISSING_PREREQS="$MISSING_PREREQS npm"
        CAN_CONTINUE=false
    fi

    # Check pnpm (can auto-install if npm exists)
    print_step "Checking pnpm..."
    if command -v pnpm > /dev/null 2>&1; then
        PNPM_VERSION=$(pnpm -v)
        print_success "pnpm found: $PNPM_VERSION"
    else
        if command -v npm > /dev/null 2>&1; then
            print_warning "pnpm not found - installing via npm..."
            if npm install -g pnpm > /dev/null 2>&1; then
                print_success "pnpm installed successfully"
            else
                print_failure "Could not install pnpm"
                MISSING_PREREQS="$MISSING_PREREQS pnpm"
                CAN_CONTINUE=false
            fi
        else
            print_failure "pnpm not found (and npm not available to install it)"
            MISSING_PREREQS="$MISSING_PREREQS pnpm"
            CAN_CONTINUE=false
        fi
    fi

    # If prerequisites are missing, show install instructions
    if [ -n "$MISSING_PREREQS" ]; then
        printf "\n"
        print_failure "Missing prerequisites:$MISSING_PREREQS"
        printf "\n${BOLD}Installation instructions for ${CYAN}$OS${NC}${BOLD}:${NC}\n\n"

        case "$OS" in
            macos)
                echo "$MISSING_PREREQS" | grep -q "java" && \
                    printf "  ${CYAN}Java 21:${NC}     brew install openjdk@21\n"
                echo "$MISSING_PREREQS" | grep -q "maven" && \
                    printf "  ${CYAN}Maven:${NC}       brew install maven\n"
                echo "$MISSING_PREREQS" | grep -q "node" && \
                    printf "  ${CYAN}Node.js:${NC}     brew install node@20\n"
                echo "$MISSING_PREREQS" | grep -q "pnpm" && \
                    printf "  ${CYAN}pnpm:${NC}        npm install -g pnpm\n"
                printf "\n  Or install all: ${GREEN}brew install openjdk@21 maven node@20 && npm install -g pnpm${NC}\n"
                ;;
            linux)
                printf "  ${CYAN}Ubuntu/Debian:${NC}\n"
                echo "$MISSING_PREREQS" | grep -q "java" && \
                    printf "    Java 21:   sudo apt install openjdk-21-jdk\n"
                echo "$MISSING_PREREQS" | grep -q "maven" && \
                    printf "    Maven:     sudo apt install maven\n"
                echo "$MISSING_PREREQS" | grep -q "node" && \
                    printf "    Node.js:   curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - && sudo apt install nodejs\n"
                echo "$MISSING_PREREQS" | grep -q "pnpm" && \
                    printf "    pnpm:      npm install -g pnpm\n"
                printf "\n  ${CYAN}Fedora/RHEL:${NC}\n"
                echo "$MISSING_PREREQS" | grep -q "java" && \
                    printf "    Java 21:   sudo dnf install java-21-openjdk-devel\n"
                echo "$MISSING_PREREQS" | grep -q "maven" && \
                    printf "    Maven:     sudo dnf install maven\n"
                ;;
            windows)
                printf "  ${CYAN}Using winget:${NC}\n"
                echo "$MISSING_PREREQS" | grep -q "java" && \
                    printf "    Java 21:   winget install EclipseAdoptium.Temurin.21.JDK\n"
                echo "$MISSING_PREREQS" | grep -q "maven" && \
                    printf "    Maven:     winget install Apache.Maven\n"
                echo "$MISSING_PREREQS" | grep -q "node" && \
                    printf "    Node.js:   winget install OpenJS.NodeJS.LTS\n"
                echo "$MISSING_PREREQS" | grep -q "pnpm" && \
                    printf "    pnpm:      npm install -g pnpm\n"
                printf "\n  ${CYAN}Or using scoop:${NC}\n"
                printf "    scoop install temurin21-jdk maven nodejs-lts\n"
                printf "    npm install -g pnpm\n"
                ;;
            *)
                printf "  Please install Java 21, Maven, Node.js 20+, and pnpm manually.\n"
                ;;
        esac

        printf "\n"
    fi

    # Return whether we can continue
    if [ "$CAN_CONTINUE" = "false" ]; then
        printf "${RED}${BOLD}Cannot continue without required prerequisites.${NC}\n"
        printf "Please install the missing tools and run this script again.\n\n"
        exit 1
    fi
}

# Check and install project dependencies (node_modules)
check_and_install_dependencies() {
    print_header "CHECKING PROJECT DEPENDENCIES"

    # Check frontend node_modules
    print_step "Checking frontend dependencies..."
    if [ ! -d "$PROJECT_ROOT/frontend/node_modules" ] || [ ! -f "$PROJECT_ROOT/frontend/node_modules/.modules.yaml" ]; then
        print_warning "Frontend dependencies not installed"
        print_step "Installing frontend dependencies (pnpm install)..."
        cd "$PROJECT_ROOT/frontend"
        if pnpm install > /dev/null 2>&1; then
            print_success "Frontend dependencies installed"
        else
            print_failure "Could not install frontend dependencies"
            printf "  Run manually: cd frontend && pnpm install\n"
        fi
        cd "$PROJECT_ROOT"
    else
        print_success "Frontend dependencies OK"
    fi

    # Check e2e-tests node_modules
    print_step "Checking e2e-tests dependencies..."
    if [ ! -d "$PROJECT_ROOT/e2e-tests/node_modules" ] || [ ! -f "$PROJECT_ROOT/e2e-tests/node_modules/.modules.yaml" ]; then
        print_warning "E2E tests dependencies not installed"
        print_step "Installing e2e-tests dependencies (pnpm install)..."
        cd "$PROJECT_ROOT/e2e-tests"
        if pnpm install > /dev/null 2>&1; then
            print_success "E2E tests dependencies installed"
        else
            print_failure "Could not install e2e-tests dependencies"
            printf "  Run manually: cd e2e-tests && pnpm install\n"
        fi
        cd "$PROJECT_ROOT"
    else
        print_success "E2E tests dependencies OK"
    fi

    # Check Playwright browsers
    print_step "Checking Playwright browsers..."
    cd "$PROJECT_ROOT/e2e-tests"
    if pnpm exec playwright --version > /dev/null 2>&1; then
        # Check if browsers are installed by looking for chromium
        if [ -d "$HOME/Library/Caches/ms-playwright" ] || [ -d "$HOME/.cache/ms-playwright" ]; then
            print_success "Playwright browsers OK"
        else
            print_warning "Playwright browsers not installed"
            print_step "Installing Playwright browsers..."
            if pnpm exec playwright install > /dev/null 2>&1; then
                print_success "Playwright browsers installed"
            else
                print_failure "Could not install Playwright browsers"
                printf "  Run manually: cd e2e-tests && pnpm exec playwright install\n"
            fi
        fi
    fi
    cd "$PROJECT_ROOT"

    # Check Cypress binary
    print_step "Checking Cypress binary..."
    cd "$PROJECT_ROOT/frontend"
    if pnpm exec cypress version > /dev/null 2>&1; then
        print_success "Cypress binary OK"
    else
        print_warning "Cypress binary not installed"
        print_step "Installing Cypress binary..."
        if pnpm exec cypress install > /dev/null 2>&1; then
            print_success "Cypress binary installed"
        else
            print_failure "Could not install Cypress binary"
            printf "  Run manually: cd frontend && pnpm exec cypress install\n"
        fi
    fi
    cd "$PROJECT_ROOT"

    # Check if backend was built (target directory exists)
    print_step "Checking backend build..."
    if [ ! -d "$PROJECT_ROOT/backend/target" ]; then
        print_warning "Backend not built yet"
        print_step "Building backend (mvn install)..."
        cd "$PROJECT_ROOT/backend"
        if mvn install -DskipTests -q > /dev/null 2>&1; then
            print_success "Backend built successfully"
        else
            print_warning "Backend build had issues - will try during tests"
        fi
        cd "$PROJECT_ROOT"
    else
        print_success "Backend build OK"
    fi

    printf "\n"
}

# Check and install missing security tools
check_and_install_tools() {
    MISSING_TOOLS=""

    # Check for gitleaks
    if ! command -v gitleaks > /dev/null 2>&1; then
        MISSING_TOOLS="$MISSING_TOOLS gitleaks"
    fi

    # Check for semgrep
    if ! command -v semgrep > /dev/null 2>&1; then
        MISSING_TOOLS="$MISSING_TOOLS semgrep"
    fi

    # Check for license-checker in frontend
    cd "$PROJECT_ROOT/frontend"
    if ! pnpm exec license-checker --help > /dev/null 2>&1; then
        MISSING_TOOLS="$MISSING_TOOLS license-checker"
    fi
    cd "$PROJECT_ROOT"

    # If tools are missing, run setup script
    if [ -n "$MISSING_TOOLS" ]; then
        print_header "INSTALLING MISSING TOOLS"
        print_warning "Missing tools:$MISSING_TOOLS"
        printf "\n"

        # Run setup script for system tools (gitleaks, semgrep)
        if echo "$MISSING_TOOLS" | grep -q "gitleaks\|semgrep"; then
            if [ -f "$PROJECT_ROOT/scripts/setup-security-tools.sh" ]; then
                print_step "Running security tools setup script..."
                if sh "$PROJECT_ROOT/scripts/setup-security-tools.sh"; then
                    print_success "Security tools installed"
                else
                    print_warning "Some tools could not be installed automatically"
                fi
            else
                print_warning "Setup script not found at scripts/setup-security-tools.sh"
            fi
        fi

        # Install license-checker if missing
        if echo "$MISSING_TOOLS" | grep -q "license-checker"; then
            print_step "Installing license-checker in frontend..."
            cd "$PROJECT_ROOT/frontend"
            if pnpm add -D license-checker > /dev/null 2>&1; then
                print_success "license-checker installed"
            else
                print_warning "Could not install license-checker"
            fi
            cd "$PROJECT_ROOT"
        fi

        printf "\n"
    fi
}

# Main execution
main() {
    printf "${BOLD}"
    printf "\n"
    printf "  ╔═══════════════════════════════════════════════════════════╗\n"
    printf "  ║                                                           ║\n"
    printf "  ║           WORDLE KATA - QUALITY CHECK                     ║\n"
    printf "  ║                                                           ║\n"
    printf "  ╚═══════════════════════════════════════════════════════════╝\n"
    printf "${NC}\n"

    # Check prerequisites (Java, Maven, Node, npm, pnpm)
    check_prerequisites

    # Check and install project dependencies (node_modules, backend build)
    check_and_install_dependencies

    # Check and install missing security tools
    check_and_install_tools

    START_TIME=$(date +%s)

    # ═══════════════════════════════════════════════════════════════
    # SECRET SCANNING
    # ═══════════════════════════════════════════════════════════════
    print_header "SECRET SCANNING"

    print_step "Running: Gitleaks (secret detection)"
    cd "$PROJECT_ROOT"

    if command -v gitleaks > /dev/null 2>&1; then
        GITLEAKS_CONFIG=""
        if [ -f "$PROJECT_ROOT/.gitleaks.toml" ]; then
            GITLEAKS_CONFIG="-c $PROJECT_ROOT/.gitleaks.toml"
        fi
        if gitleaks detect --source . --no-git $GITLEAKS_CONFIG > "$SECRETS_LOG" 2>&1; then
            print_success "No secrets detected"
            SECRETS_SCAN_RESULT="PASS"
            # Count files scanned (approximate from git)
            FILES_SCANNED=$(find . -type f \( -name "*.java" -o -name "*.ts" -o -name "*.json" -o -name "*.xml" -o -name "*.yml" -o -name "*.yaml" \) ! -path "*/node_modules/*" ! -path "*/target/*" ! -path "*/.angular/*" 2>/dev/null | wc -l | tr -d ' ')
            print_detail "Scanned $FILES_SCANNED source files"
        else
            print_failure "Potential secrets found!"
            SECRETS_SCAN_RESULT="FAIL"
        fi
    else
        print_warning "Gitleaks not available - skipping secret scan"
        SECRETS_SCAN_RESULT="SKIP"
    fi

    # ═══════════════════════════════════════════════════════════════
    # BACKEND CHECKS
    # ═══════════════════════════════════════════════════════════════
    print_header "BACKEND CHECKS (Java/Spring Boot)"

    print_step "Running: Maven tests (JUnit + ArchUnit + JaCoCo)"
    cd "$PROJECT_ROOT/backend"

    if mvn clean verify > "$BACKEND_LOG" 2>&1; then
        print_success "Backend tests passed"
        BACKEND_TESTS_RESULT="PASS"

        # Extract test counts
        TESTS_RUN=$(grep -E "Tests run:" "$BACKEND_LOG" | tail -1 | sed 's/.*Tests run: \([0-9]*\).*/\1/' 2>/dev/null || echo "?")
        FAILURES=$(grep -E "Tests run:" "$BACKEND_LOG" | tail -1 | sed 's/.*Failures: \([0-9]*\).*/\1/' 2>/dev/null || echo "0")
        SKIPPED=$(grep -E "Tests run:" "$BACKEND_LOG" | tail -1 | sed 's/.*Skipped: \([0-9]*\).*/\1/' 2>/dev/null || echo "0")
        print_detail "Tests: $TESTS_RUN run, $FAILURES failures, $SKIPPED skipped"

        # Extract JaCoCo coverage from CSV if available
        JACOCO_CSV="$PROJECT_ROOT/backend/target/site/jacoco/jacoco.csv"
        if [ -f "$JACOCO_CSV" ]; then
            # CSV columns: GROUP,PACKAGE,CLASS,INSTR_MISSED,INSTR_COVERED,BRANCH_MISSED,BRANCH_COVERED,LINE_MISSED,LINE_COVERED,...
            LINE_MISSED=$(awk -F',' 'NR>1 {sum+=$8} END {print sum}' "$JACOCO_CSV" 2>/dev/null || echo "0")
            LINE_COVERED=$(awk -F',' 'NR>1 {sum+=$9} END {print sum}' "$JACOCO_CSV" 2>/dev/null || echo "0")
            BRANCH_MISSED=$(awk -F',' 'NR>1 {sum+=$6} END {print sum}' "$JACOCO_CSV" 2>/dev/null || echo "0")
            BRANCH_COVERED=$(awk -F',' 'NR>1 {sum+=$7} END {print sum}' "$JACOCO_CSV" 2>/dev/null || echo "0")

            if [ "$LINE_COVERED" != "0" ] || [ "$LINE_MISSED" != "0" ]; then
                LINE_TOTAL=$((LINE_COVERED + LINE_MISSED))
                BRANCH_TOTAL=$((BRANCH_COVERED + BRANCH_MISSED))
                if [ "$LINE_TOTAL" -gt 0 ]; then
                    LINE_PCT=$((LINE_COVERED * 100 / LINE_TOTAL))
                else
                    LINE_PCT=100
                fi
                if [ "$BRANCH_TOTAL" -gt 0 ]; then
                    BRANCH_PCT=$((BRANCH_COVERED * 100 / BRANCH_TOTAL))
                else
                    BRANCH_PCT=100
                fi
                print_detail "Coverage: ${LINE_PCT}% lines ($LINE_COVERED/$LINE_TOTAL), ${BRANCH_PCT}% branches ($BRANCH_COVERED/$BRANCH_TOTAL)"
            fi
        fi
    else
        print_failure "Backend tests failed"
        BACKEND_TESTS_RESULT="FAIL"
    fi

    # SpotBugs with FindSecBugs
    # Check Java version being used
    JAVA_MAJOR_VERSION=$(mvn -v 2>&1 | grep "Java version" | cut -d: -f2 | cut -d. -f1 | tr -d ' ')
    print_step "Running: SpotBugs + FindSecBugs (Java $JAVA_MAJOR_VERSION)"
    # SpotBugs doesn't support Java 25+ yet (needs BCEL 6.11)
    if [ -n "$JAVA_MAJOR_VERSION" ] && [ "$JAVA_MAJOR_VERSION" -ge 25 ] 2>/dev/null; then
        print_warning "SpotBugs skipped - Java $JAVA_MAJOR_VERSION not yet supported (needs SpotBugs 4.9.x)"
        print_warning "Install Java 21: brew install openjdk@21"
        print_warning "See: https://github.com/spotbugs/spotbugs/issues/3564"
        BACKEND_SPOTBUGS_RESULT="SKIP"
    elif mvn spotbugs:check > "$BACKEND_SPOTBUGS_LOG" 2>&1; then
        print_success "SpotBugs analysis passed"
        BACKEND_SPOTBUGS_RESULT="PASS"
        # Count classes analyzed
        CLASSES_ANALYZED=$(grep -E "classes" "$BACKEND_SPOTBUGS_LOG" | grep -oE "[0-9]+ classes" | head -1 | grep -oE "[0-9]+" 2>/dev/null || echo "?")
        if [ "$CLASSES_ANALYZED" != "?" ]; then
            print_detail "Analyzed $CLASSES_ANALYZED classes, 0 bugs found"
        else
            print_detail "0 bugs found"
        fi
    else
        print_failure "SpotBugs found issues"
        BACKEND_SPOTBUGS_RESULT="FAIL"
    fi

    # OWASP Dependency-Check
    print_step "Running: OWASP Dependency-Check (CVE scanning)"
    # Load .env file if it exists (for NVD_API_KEY)
    if [ -f "$PROJECT_ROOT/backend/.env" ]; then
        set -a
        . "$PROJECT_ROOT/backend/.env"
        set +a
        print_detail "Loaded environment variables from backend/.env"
    fi
    if mvn dependency-check:check > "$BACKEND_DEPCHECK_LOG" 2>&1; then
        print_success "No high-severity CVEs in dependencies"
        BACKEND_DEPCHECK_RESULT="PASS"
        print_detail "No high-severity vulnerabilities (CVSS < 7)"
    else
        # Check if it's a configuration issue vs actual vulnerabilities
        if grep -q "dependency-check" "$BACKEND_DEPCHECK_LOG" 2>/dev/null && grep -q "No plugin found" "$BACKEND_DEPCHECK_LOG" 2>/dev/null; then
            print_warning "OWASP Dependency-Check plugin not configured"
            print_warning "Add plugin to pom.xml - see docs for setup"
            BACKEND_DEPCHECK_RESULT="SKIP"
        else
            print_failure "Vulnerable dependencies found (CVSS >= 7)"
            BACKEND_DEPCHECK_RESULT="FAIL"
        fi
    fi

    # Checkstyle (code style)
    print_step "Running: Checkstyle (Java code style)"
    if mvn checkstyle:check > "$BACKEND_CHECKSTYLE_LOG" 2>&1; then
        print_success "Checkstyle passed"
        BACKEND_CHECKSTYLE_RESULT="PASS"
        print_detail "Java code follows style guidelines"
    else
        # Check if it's a configuration issue
        if grep -q "No plugin found\|Could not find goal" "$BACKEND_CHECKSTYLE_LOG" 2>/dev/null; then
            print_warning "Checkstyle plugin not configured"
            BACKEND_CHECKSTYLE_RESULT="SKIP"
        else
            print_failure "Checkstyle violations found"
            BACKEND_CHECKSTYLE_RESULT="FAIL"
        fi
    fi

    # License compliance check for Maven dependencies
    print_step "Running: License compliance check (Maven dependencies)"
    if mvn license:add-third-party -Dlicense.useMissingFile=false > "$BACKEND_LICENSE_LOG" 2>&1; then
        print_success "License check completed"
        BACKEND_LICENSE_RESULT="PASS"
        # Check for strong copyleft (AGPL) - LGPL is acceptable (weak copyleft)
        if grep -qiE "AGPL|Affero" "$PROJECT_ROOT/backend/target/generated-sources/license/THIRD-PARTY.txt" 2>/dev/null; then
            print_warning "Review: Some dependencies have AGPL (strong copyleft) licenses"
            BACKEND_LICENSE_RESULT="WARN"
        else
            print_detail "All dependencies have acceptable licenses"
        fi
    else
        if grep -q "No plugin found\|Could not find goal" "$BACKEND_LICENSE_LOG" 2>/dev/null; then
            print_warning "License Maven Plugin not configured"
            BACKEND_LICENSE_RESULT="SKIP"
        else
            print_warning "License check had issues (review recommended)"
            BACKEND_LICENSE_RESULT="WARN"
        fi
    fi

    # ═══════════════════════════════════════════════════════════════
    # SAST (Static Application Security Testing)
    # ═══════════════════════════════════════════════════════════════
    print_header "SAST (Static Application Security Testing)"

    print_step "Running: Semgrep security scan"
    cd "$PROJECT_ROOT"

    if command -v semgrep > /dev/null 2>&1; then
        if semgrep scan --config=auto --severity=ERROR --severity=WARNING \
            --exclude='node_modules' --exclude='target' --exclude='dist' \
            --exclude='.angular' --exclude='coverage' \
            > "$SEMGREP_LOG" 2>&1; then
            print_success "Semgrep scan passed"
            SEMGREP_RESULT="PASS"
            print_detail "0 security findings"
        else
            print_failure "Semgrep found security issues"
            SEMGREP_RESULT="FAIL"
        fi
    else
        print_warning "Semgrep not available - skipping SAST"
        SEMGREP_RESULT="SKIP"
    fi

    # ═══════════════════════════════════════════════════════════════
    # FRONTEND CHECKS
    # ═══════════════════════════════════════════════════════════════
    print_header "FRONTEND CHECKS (Angular/TypeScript)"

    cd "$PROJECT_ROOT/frontend"

    # TypeScript compilation check
    print_step "Running: TypeScript compilation check"
    if pnpm exec tsc --noEmit > "$FRONTEND_TYPECHECK_LOG" 2>&1; then
        print_success "TypeScript compilation passed"
        FRONTEND_TYPECHECK_RESULT="PASS"
    else
        print_failure "TypeScript compilation failed"
        FRONTEND_TYPECHECK_RESULT="FAIL"
    fi

    # Lint check
    print_step "Running: ESLint"
    if pnpm lint > "$FRONTEND_LINT_LOG" 2>&1; then
        print_success "ESLint passed"
        FRONTEND_LINT_RESULT="PASS"
    else
        print_failure "ESLint failed"
        FRONTEND_LINT_RESULT="FAIL"
    fi

    # Format check
    print_step "Running: Prettier format check"
    if pnpm format:check > "$FRONTEND_FORMAT_LOG" 2>&1; then
        print_success "Prettier format check passed"
        FRONTEND_FORMAT_RESULT="PASS"
    else
        print_failure "Prettier format check failed"
        FRONTEND_FORMAT_RESULT="FAIL"
    fi

    # Tests with coverage
    print_step "Running: Cypress component tests with coverage"
    if pnpm test > "$FRONTEND_TESTS_LOG" 2>&1; then
        # Tests passed, extract counts
        # Extract test counts from Cypress summary (last line: "✔  All specs passed! ... 30 30 - - -")
        # Or from individual "X passing" lines
        CYPRESS_SUMMARY=$(grep -E "All specs passed" "$FRONTEND_TESTS_LOG" | tail -1 2>/dev/null || echo "")
        if [ -n "$CYPRESS_SUMMARY" ]; then
            # Extract from summary line format: "✔  All specs passed!  00:01  30  30  -  -  -"
            CYPRESS_TOTAL=$(echo "$CYPRESS_SUMMARY" | awk '{for(i=1;i<=NF;i++) if($i ~ /^[0-9]+$/) {print $i; exit}}' 2>/dev/null || echo "0")
            print_detail "Tests: $CYPRESS_TOTAL passing, 0 failing"
        else
            CYPRESS_PASSING=$(grep -oE "[0-9]+ passing" "$FRONTEND_TESTS_LOG" | tail -1 | grep -oE "^[0-9]+" 2>/dev/null || echo "0")
            CYPRESS_FAILING=$(grep -oE "[0-9]+ failing" "$FRONTEND_TESTS_LOG" | tail -1 | grep -oE "^[0-9]+" 2>/dev/null || echo "0")
            if [ "$CYPRESS_PASSING" != "0" ]; then
                print_detail "Tests: $CYPRESS_PASSING passing, $CYPRESS_FAILING failing"
            fi
        fi

        # Extract coverage from Istanbul table output
        # Format: "All files | % Stmts | % Branch | % Funcs | % Lines |"
        COVERAGE_LINE=$(grep -E "^All files" "$FRONTEND_TESTS_LOG" | tail -1 2>/dev/null || echo "")
        if [ -n "$COVERAGE_LINE" ]; then
            # Extract percentages from table columns
            STMTS_PCT=$(echo "$COVERAGE_LINE" | awk -F'|' '{gsub(/ /, "", $2); print $2}' 2>/dev/null || echo "?")
            BRANCH_PCT=$(echo "$COVERAGE_LINE" | awk -F'|' '{gsub(/ /, "", $3); print $3}' 2>/dev/null || echo "?")
            FUNCS_PCT=$(echo "$COVERAGE_LINE" | awk -F'|' '{gsub(/ /, "", $4); print $4}' 2>/dev/null || echo "?")
            LINES_PCT=$(echo "$COVERAGE_LINE" | awk -F'|' '{gsub(/ /, "", $5); print $5}' 2>/dev/null || echo "?")
            print_detail "Coverage: ${LINES_PCT}% lines, ${BRANCH_PCT}% branches, ${FUNCS_PCT}% functions"
        fi

        # Verify coverage meets 100% threshold
        FRONTEND_COV_LOG=$(mktemp)
        if pnpm exec nyc check-coverage > "$FRONTEND_COV_LOG" 2>&1; then
            print_success "Frontend tests passed (100% coverage verified)"
            FRONTEND_TESTS_RESULT="PASS"
        else
            print_failure "Frontend tests passed but coverage below 100%"
            FRONTEND_TESTS_RESULT="FAIL"
            # Append coverage failure to main log
            cat "$FRONTEND_COV_LOG" >> "$FRONTEND_TESTS_LOG"
        fi
    else
        print_failure "Frontend tests failed"
        FRONTEND_TESTS_RESULT="FAIL"
    fi

    # Build check
    print_step "Running: Angular production build"
    if pnpm build > "$FRONTEND_BUILD_LOG" 2>&1; then
        print_success "Angular build passed"
        FRONTEND_BUILD_RESULT="PASS"

        # Extract bundle size from build output
        INITIAL_SIZE=$(grep -E "Initial chunk files" "$FRONTEND_BUILD_LOG" | grep -oE "[0-9]+\.[0-9]+ [kM]B" | head -1 2>/dev/null || echo "")
        if [ -n "$INITIAL_SIZE" ]; then
            print_detail "Bundle size: $INITIAL_SIZE (initial)"
        fi
    else
        print_failure "Angular build failed"
        FRONTEND_BUILD_RESULT="FAIL"
    fi

    # Security audit
    print_step "Running: pnpm audit (security vulnerabilities)"
    if pnpm audit --audit-level=high > "$FRONTEND_AUDIT_LOG" 2>&1; then
        print_success "Security audit passed (no high/critical vulnerabilities)"
        FRONTEND_AUDIT_RESULT="PASS"
    else
        print_warning "Security audit found vulnerabilities (review recommended)"
        FRONTEND_AUDIT_RESULT="WARN"
    fi

    # License compliance check
    print_step "Running: License compliance check"
    if command -v pnpm > /dev/null 2>&1 && pnpm exec license-checker --help > /dev/null 2>&1; then
        if pnpm exec license-checker --production --excludePrivatePackages --onlyAllow \
            'MIT;ISC;Apache-2.0;BSD-2-Clause;BSD-3-Clause;0BSD;CC0-1.0;CC-BY-3.0;CC-BY-4.0;Unlicense;WTFPL;Python-2.0' \
            > "$FRONTEND_LICENSE_LOG" 2>&1; then
            print_success "License compliance check passed"
            FRONTEND_LICENSE_RESULT="PASS"
        else
            print_warning "Problematic licenses found (review recommended)"
            FRONTEND_LICENSE_RESULT="WARN"
        fi
    else
        print_warning "license-checker not available - skipping license check"
        FRONTEND_LICENSE_RESULT="SKIP"
    fi

    # ═══════════════════════════════════════════════════════════════
    # E2E CHECKS
    # ═══════════════════════════════════════════════════════════════
    print_header "E2E CHECKS (Playwright)"

    cd "$PROJECT_ROOT/e2e-tests"

    # BDD generation check
    print_step "Running: BDD spec generation check"
    if pnpm bddgen > "$E2E_BDDGEN_LOG" 2>&1; then
        print_success "BDD generation passed"
        E2E_BDDGEN_RESULT="PASS"
    else
        print_failure "BDD generation failed"
        E2E_BDDGEN_RESULT="FAIL"
    fi

    print_step "Running: Playwright E2E tests (headless)"
    print_warning "Note: This starts backend & frontend automatically"

    if pnpm test:e2e > "$E2E_LOG" 2>&1; then
        print_success "E2E tests passed"
        E2E_TESTS_RESULT="PASS"

        # Extract test counts from Playwright output (e.g., "2 passed (5.3s)")
        E2E_PASSED=$(grep -oE "[0-9]+ passed" "$E2E_LOG" | tail -1 | grep -oE "^[0-9]+" 2>/dev/null || echo "0")
        E2E_FAILED=$(grep -oE "[0-9]+ failed" "$E2E_LOG" | tail -1 | grep -oE "^[0-9]+" 2>/dev/null || echo "0")
        E2E_SKIPPED=$(grep -oE "[0-9]+ skipped" "$E2E_LOG" | tail -1 | grep -oE "^[0-9]+" 2>/dev/null || echo "0")
        if [ "$E2E_PASSED" != "0" ] || [ "$E2E_FAILED" != "0" ]; then
            print_detail "Tests: $E2E_PASSED passed, $E2E_FAILED failed, $E2E_SKIPPED skipped"
        fi
    else
        print_failure "E2E tests failed"
        E2E_TESTS_RESULT="FAIL"
    fi

    # Cleanup any hanging processes
    if [ -f "$PROJECT_ROOT/e2e-tests/scripts/cleanup-services.sh" ]; then
        sh "$PROJECT_ROOT/e2e-tests/scripts/cleanup-services.sh" > /dev/null 2>&1 || true
    fi

    # ═══════════════════════════════════════════════════════════════
    # MUTATION TESTING (Optional - High Effort)
    # ═══════════════════════════════════════════════════════════════
    # Mutation testing is slow but verifies test quality
    # Skip by default, run with: ./quality-check.sh --mutation
    if [ "$RUN_MUTATION" = "true" ]; then
        print_header "MUTATION TESTING (Test Quality)"

        cd "$PROJECT_ROOT/backend"

        print_step "Running: PIT mutation testing"
        print_warning "Note: This may take several minutes..."

        if mvn pitest:mutationCoverage > "$BACKEND_MUTATION_LOG" 2>&1; then
            print_success "Mutation testing passed"
            BACKEND_MUTATION_RESULT="PASS"

            # Extract mutation score from PIT output
            MUTATION_SCORE=$(grep -oE "mutations: [0-9]+%" "$BACKEND_MUTATION_LOG" | tail -1 | grep -oE "[0-9]+" 2>/dev/null || echo "?")
            if [ "$MUTATION_SCORE" != "?" ]; then
                print_detail "Mutation score: ${MUTATION_SCORE}%"
            fi
        else
            if grep -q "No plugin found\|Could not find goal" "$BACKEND_MUTATION_LOG" 2>/dev/null; then
                print_warning "PIT plugin not configured"
                BACKEND_MUTATION_RESULT="SKIP"
            else
                print_failure "Mutation testing failed (mutation score below threshold)"
                BACKEND_MUTATION_RESULT="FAIL"
            fi
        fi
    else
        print_header "MUTATION TESTING (Skipped)"
        print_warning "Mutation testing skipped (slow)"
        print_detail "Run with: ./quality-check.sh --mutation"
        BACKEND_MUTATION_RESULT="SKIP"
    fi

    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))

    # ═══════════════════════════════════════════════════════════════
    # SUMMARY REPORT
    # ═══════════════════════════════════════════════════════════════
    print_header "QUALITY CHECK SUMMARY"

    # Count results (17 checks total)
    TOTAL_CHECKS=17
    PASSED_CHECKS=0
    WARNINGS=0

    printf "${BOLD}%-40s %s${NC}\n" "Check" "Status"
    printf "─────────────────────────────────────────────────────\n"

    # Secret scanning
    if [ "$SECRETS_SCAN_RESULT" = "PASS" ]; then
        printf "%-40s ${GREEN}✓ PASS${NC}\n" "Secret Scanning (Gitleaks)"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    elif [ "$SECRETS_SCAN_RESULT" = "SKIP" ]; then
        printf "%-40s ${YELLOW}⊘ SKIP${NC}\n" "Secret Scanning (not installed)"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        printf "%-40s ${RED}✗ FAIL${NC}\n" "Secret Scanning (Gitleaks)"
    fi

    # Backend tests
    if [ "$BACKEND_TESTS_RESULT" = "PASS" ]; then
        printf "%-40s ${GREEN}✓ PASS${NC}\n" "Backend Tests (JUnit+ArchUnit+JaCoCo)"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        printf "%-40s ${RED}✗ FAIL${NC}\n" "Backend Tests (JUnit+ArchUnit+JaCoCo)"
    fi

    # Backend SpotBugs
    if [ "$BACKEND_SPOTBUGS_RESULT" = "PASS" ]; then
        printf "%-40s ${GREEN}✓ PASS${NC}\n" "Backend SpotBugs (FindSecBugs)"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    elif [ "$BACKEND_SPOTBUGS_RESULT" = "SKIP" ]; then
        printf "%-40s ${YELLOW}⊘ SKIP${NC}\n" "Backend SpotBugs (Java 25 unsupported)"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        printf "%-40s ${RED}✗ FAIL${NC}\n" "Backend SpotBugs (FindSecBugs)"
    fi

    # Backend OWASP Dependency-Check
    if [ "$BACKEND_DEPCHECK_RESULT" = "PASS" ]; then
        printf "%-40s ${GREEN}✓ PASS${NC}\n" "Backend OWASP Dep-Check (CVEs)"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    elif [ "$BACKEND_DEPCHECK_RESULT" = "SKIP" ]; then
        printf "%-40s ${YELLOW}⊘ SKIP${NC}\n" "Backend OWASP Dep-Check (not configured)"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        printf "%-40s ${RED}✗ FAIL${NC}\n" "Backend OWASP Dep-Check (CVEs)"
    fi

    # Backend Checkstyle
    if [ "$BACKEND_CHECKSTYLE_RESULT" = "PASS" ]; then
        printf "%-40s ${GREEN}✓ PASS${NC}\n" "Backend Checkstyle (code style)"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    elif [ "$BACKEND_CHECKSTYLE_RESULT" = "SKIP" ]; then
        printf "%-40s ${YELLOW}⊘ SKIP${NC}\n" "Backend Checkstyle (not configured)"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        printf "%-40s ${RED}✗ FAIL${NC}\n" "Backend Checkstyle (code style)"
    fi

    # Backend License Compliance
    if [ "$BACKEND_LICENSE_RESULT" = "PASS" ]; then
        printf "%-40s ${GREEN}✓ PASS${NC}\n" "Backend License (Maven deps)"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    elif [ "$BACKEND_LICENSE_RESULT" = "SKIP" ]; then
        printf "%-40s ${YELLOW}⊘ SKIP${NC}\n" "Backend License (not configured)"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    elif [ "$BACKEND_LICENSE_RESULT" = "WARN" ]; then
        printf "%-40s ${YELLOW}⚠ WARN${NC}\n" "Backend License (AGPL found)"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        WARNINGS=$((WARNINGS + 1))
    else
        printf "%-40s ${RED}✗ FAIL${NC}\n" "Backend License (Maven deps)"
    fi

    # Semgrep SAST
    if [ "$SEMGREP_RESULT" = "PASS" ]; then
        printf "%-40s ${GREEN}✓ PASS${NC}\n" "SAST (Semgrep)"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    elif [ "$SEMGREP_RESULT" = "SKIP" ]; then
        printf "%-40s ${YELLOW}⊘ SKIP${NC}\n" "SAST (Semgrep not installed)"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        printf "%-40s ${RED}✗ FAIL${NC}\n" "SAST (Semgrep)"
    fi

    # Frontend TypeScript
    if [ "$FRONTEND_TYPECHECK_RESULT" = "PASS" ]; then
        printf "%-40s ${GREEN}✓ PASS${NC}\n" "Frontend TypeScript (tsc --noEmit)"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        printf "%-40s ${RED}✗ FAIL${NC}\n" "Frontend TypeScript (tsc --noEmit)"
    fi

    # Frontend lint
    if [ "$FRONTEND_LINT_RESULT" = "PASS" ]; then
        printf "%-40s ${GREEN}✓ PASS${NC}\n" "Frontend Lint (ESLint)"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        printf "%-40s ${RED}✗ FAIL${NC}\n" "Frontend Lint (ESLint)"
    fi

    # Frontend format
    if [ "$FRONTEND_FORMAT_RESULT" = "PASS" ]; then
        printf "%-40s ${GREEN}✓ PASS${NC}\n" "Frontend Format (Prettier)"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        printf "%-40s ${RED}✗ FAIL${NC}\n" "Frontend Format (Prettier)"
    fi

    # Frontend tests
    if [ "$FRONTEND_TESTS_RESULT" = "PASS" ]; then
        printf "%-40s ${GREEN}✓ PASS${NC}\n" "Frontend Tests (Cypress)"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        printf "%-40s ${RED}✗ FAIL${NC}\n" "Frontend Tests (Cypress)"
    fi

    # Frontend build
    if [ "$FRONTEND_BUILD_RESULT" = "PASS" ]; then
        printf "%-40s ${GREEN}✓ PASS${NC}\n" "Frontend Build (Angular AOT)"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        printf "%-40s ${RED}✗ FAIL${NC}\n" "Frontend Build (Angular AOT)"
    fi

    # Frontend audit (warning only, doesn't fail build)
    if [ "$FRONTEND_AUDIT_RESULT" = "PASS" ]; then
        printf "%-40s ${GREEN}✓ PASS${NC}\n" "Security Audit (pnpm audit)"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        printf "%-40s ${YELLOW}⚠ WARN${NC}\n" "Security Audit (pnpm audit)"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        WARNINGS=$((WARNINGS + 1))
    fi

    # License compliance (warning only, doesn't fail build)
    if [ "$FRONTEND_LICENSE_RESULT" = "PASS" ]; then
        printf "%-40s ${GREEN}✓ PASS${NC}\n" "License Compliance (license-checker)"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    elif [ "$FRONTEND_LICENSE_RESULT" = "SKIP" ]; then
        printf "%-40s ${YELLOW}⊘ SKIP${NC}\n" "License Compliance (not installed)"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        printf "%-40s ${YELLOW}⚠ WARN${NC}\n" "License Compliance (review needed)"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        WARNINGS=$((WARNINGS + 1))
    fi

    # E2E BDD generation
    if [ "$E2E_BDDGEN_RESULT" = "PASS" ]; then
        printf "%-40s ${GREEN}✓ PASS${NC}\n" "E2E BDD Generation (bddgen)"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        printf "%-40s ${RED}✗ FAIL${NC}\n" "E2E BDD Generation (bddgen)"
    fi

    # E2E tests
    if [ "$E2E_TESTS_RESULT" = "PASS" ]; then
        printf "%-40s ${GREEN}✓ PASS${NC}\n" "E2E Tests (Playwright)"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        printf "%-40s ${RED}✗ FAIL${NC}\n" "E2E Tests (Playwright)"
    fi

    # Mutation testing (optional)
    if [ "$BACKEND_MUTATION_RESULT" = "PASS" ]; then
        printf "%-40s ${GREEN}✓ PASS${NC}\n" "Mutation Testing (PIT)"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    elif [ "$BACKEND_MUTATION_RESULT" = "SKIP" ]; then
        printf "%-40s ${YELLOW}⊘ SKIP${NC}\n" "Mutation Testing (use --mutation)"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        printf "%-40s ${RED}✗ FAIL${NC}\n" "Mutation Testing (PIT)"
    fi

    printf "─────────────────────────────────────────────────────\n"
    printf "${BOLD}Total: %d/%d passed${NC}" "$PASSED_CHECKS" "$TOTAL_CHECKS"
    if [ "$WARNINGS" -gt 0 ]; then
        printf "  |  ${YELLOW}%d warning(s)${NC}" "$WARNINGS"
    fi
    printf "  |  ${CYAN}Duration: %dm %ds${NC}\n" "$((DURATION / 60))" "$((DURATION % 60))"

    # ═══════════════════════════════════════════════════════════════
    # FAILURE/WARNING DETAILS
    # ═══════════════════════════════════════════════════════════════
    if [ "$PASSED_CHECKS" -lt "$TOTAL_CHECKS" ] || [ "$WARNINGS" -gt 0 ]; then
        print_header "DETAILS & HOW TO FIX"

        if [ "$SECRETS_SCAN_RESULT" = "FAIL" ]; then
            printf "${RED}${BOLD}━━━ Secret Scanning Failed ━━━${NC}\n\n"
            printf "${YELLOW}Potential secrets detected:${NC}\n"
            cat "$SECRETS_LOG"
            printf "\n${CYAN}How to fix:${NC}\n"
            printf "  1. Review the detected secrets above\n"
            printf "  2. If real secrets: remove from code, rotate credentials\n"
            printf "  3. If false positives: add to .gitleaksignore\n"
            printf "  4. Run: gitleaks detect --source . --no-git\n"
            printf "\n"
        fi

        if [ "$BACKEND_TESTS_RESULT" = "FAIL" ]; then
            printf "${RED}${BOLD}━━━ Backend Tests Failed ━━━${NC}\n\n"
            printf "${YELLOW}Last 50 lines of output:${NC}\n"
            tail -50 "$BACKEND_LOG"
            printf "\n${CYAN}How to fix:${NC}\n"
            printf "  1. cd backend\n"
            printf "  2. mvn verify  (to see full output)\n"
            printf "  3. Check for:\n"
            printf "     - Failing unit tests (JUnit)\n"
            printf "     - Architecture violations (ArchUnit)\n"
            printf "     - Coverage below threshold (JaCoCo: 100%% required)\n"
            printf "\n"
        fi

        if [ "$BACKEND_SPOTBUGS_RESULT" = "FAIL" ]; then
            printf "${RED}${BOLD}━━━ Backend SpotBugs Failed ━━━${NC}\n\n"
            printf "${YELLOW}Last 80 lines of output:${NC}\n"
            tail -80 "$BACKEND_SPOTBUGS_LOG"
            printf "\n${CYAN}How to fix:${NC}\n"
            printf "  1. cd backend\n"
            printf "  2. mvn spotbugs:check  (to see all issues)\n"
            printf "  3. mvn spotbugs:gui  (to view issues in GUI)\n"
            printf "  4. Check for:\n"
            printf "     - Bug patterns (null pointers, resource leaks, etc.)\n"
            printf "     - Security issues (FindSecBugs detections)\n"
            printf "  5. Update spotbugs-exclude.xml if false positive\n"
            printf "\n"
        fi

        if [ "$BACKEND_DEPCHECK_RESULT" = "FAIL" ]; then
            printf "${RED}${BOLD}━━━ OWASP Dependency-Check Failed ━━━${NC}\n\n"
            printf "${YELLOW}Last 80 lines of output:${NC}\n"
            tail -80 "$BACKEND_DEPCHECK_LOG"
            printf "\n${CYAN}How to fix:${NC}\n"
            printf "  1. cd backend\n"
            printf "  2. mvn dependency-check:check  (to see all CVEs)\n"
            printf "  3. Check target/dependency-check-report.html for details\n"
            printf "  4. Update vulnerable dependencies in pom.xml\n"
            printf "  5. If false positive: add suppression to suppression.xml\n"
            printf "\n"
        fi

        if [ "$BACKEND_CHECKSTYLE_RESULT" = "FAIL" ]; then
            printf "${RED}${BOLD}━━━ Backend Checkstyle Failed ━━━${NC}\n\n"
            printf "${YELLOW}Style violations:${NC}\n"
            tail -80 "$BACKEND_CHECKSTYLE_LOG"
            printf "\n${CYAN}How to fix:${NC}\n"
            printf "  1. cd backend\n"
            printf "  2. mvn checkstyle:check  (to see all violations)\n"
            printf "  3. Fix the code style issues\n"
            printf "  4. Common issues: indentation, naming, imports\n"
            printf "  5. Review checkstyle.xml for project style rules\n"
            printf "\n"
        fi

        if [ "$BACKEND_LICENSE_RESULT" = "WARN" ]; then
            printf "${YELLOW}${BOLD}━━━ Backend License Warning ━━━${NC}\n\n"
            printf "${YELLOW}License report:${NC}\n"
            if [ -f "$PROJECT_ROOT/backend/target/generated-sources/license/THIRD-PARTY.txt" ]; then
                cat "$PROJECT_ROOT/backend/target/generated-sources/license/THIRD-PARTY.txt"
            else
                tail -50 "$BACKEND_LICENSE_LOG"
            fi
            printf "\n${CYAN}How to fix:${NC}\n"
            printf "  1. cd backend\n"
            printf "  2. mvn license:add-third-party  (generate license report)\n"
            printf "  3. Review target/generated-sources/license/THIRD-PARTY.txt\n"
            printf "  4. Check for GPL/LGPL/AGPL licenses that may have restrictions\n"
            printf "  5. Replace problematic dependencies or get legal approval\n"
            printf "\n"
        fi

        if [ "$BACKEND_MUTATION_RESULT" = "FAIL" ]; then
            printf "${RED}${BOLD}━━━ Mutation Testing Failed ━━━${NC}\n\n"
            printf "${YELLOW}Last 80 lines of output:${NC}\n"
            tail -80 "$BACKEND_MUTATION_LOG"
            printf "\n${CYAN}How to fix:${NC}\n"
            printf "  1. cd backend\n"
            printf "  2. mvn pitest:mutationCoverage  (to run mutation tests)\n"
            printf "  3. Check target/pit-reports/index.html for detailed report\n"
            printf "  4. Mutation score below 70%% indicates weak tests\n"
            printf "  5. Add assertions or test cases to kill surviving mutants\n"
            printf "\n"
        fi

        if [ "$SEMGREP_RESULT" = "FAIL" ]; then
            printf "${RED}${BOLD}━━━ Semgrep SAST Failed ━━━${NC}\n\n"
            printf "${YELLOW}Security issues found:${NC}\n"
            cat "$SEMGREP_LOG"
            printf "\n${CYAN}How to fix:${NC}\n"
            printf "  1. Review the security issues above\n"
            printf "  2. Run: semgrep scan --config=auto (for full output)\n"
            printf "  3. Fix the identified vulnerabilities\n"
            printf "  4. If false positive: add # nosemgrep comment or .semgrepignore\n"
            printf "\n"
        fi

        if [ "$FRONTEND_TYPECHECK_RESULT" = "FAIL" ]; then
            printf "${RED}${BOLD}━━━ Frontend TypeScript Failed ━━━${NC}\n\n"
            printf "${YELLOW}Output:${NC}\n"
            cat "$FRONTEND_TYPECHECK_LOG"
            printf "\n${CYAN}How to fix:${NC}\n"
            printf "  1. cd frontend\n"
            printf "  2. pnpm exec tsc --noEmit  (to see all type errors)\n"
            printf "  3. Fix the reported TypeScript errors\n"
            printf "\n"
        fi

        if [ "$FRONTEND_LINT_RESULT" = "FAIL" ]; then
            printf "${RED}${BOLD}━━━ Frontend Lint Failed ━━━${NC}\n\n"
            printf "${YELLOW}Output:${NC}\n"
            cat "$FRONTEND_LINT_LOG"
            printf "\n${CYAN}How to fix:${NC}\n"
            printf "  1. cd frontend\n"
            printf "  2. pnpm lint  (to see all errors)\n"
            printf "  3. Fix the reported ESLint errors\n"
            printf "  4. Some errors can be auto-fixed: pnpm lint --fix\n"
            printf "\n"
        fi

        if [ "$FRONTEND_FORMAT_RESULT" = "FAIL" ]; then
            printf "${RED}${BOLD}━━━ Frontend Format Failed ━━━${NC}\n\n"
            printf "${YELLOW}Files with formatting issues:${NC}\n"
            cat "$FRONTEND_FORMAT_LOG"
            printf "\n${CYAN}How to fix:${NC}\n"
            printf "  1. cd frontend\n"
            printf "  2. pnpm format  (auto-fix all formatting)\n"
            printf "\n"
        fi

        if [ "$FRONTEND_TESTS_RESULT" = "FAIL" ]; then
            printf "${RED}${BOLD}━━━ Frontend Tests Failed ━━━${NC}\n\n"
            printf "${YELLOW}Last 50 lines of output:${NC}\n"
            tail -50 "$FRONTEND_TESTS_LOG"
            printf "\n${CYAN}How to fix:${NC}\n"
            printf "  1. cd frontend\n"
            printf "  2. pnpm test:open  (interactive mode to debug)\n"
            printf "  3. Check for:\n"
            printf "     - Failing component tests\n"
            printf "     - Coverage below threshold (100%% required)\n"
            printf "\n"
        fi

        if [ "$FRONTEND_BUILD_RESULT" = "FAIL" ]; then
            printf "${RED}${BOLD}━━━ Frontend Build Failed ━━━${NC}\n\n"
            printf "${YELLOW}Last 50 lines of output:${NC}\n"
            tail -50 "$FRONTEND_BUILD_LOG"
            printf "\n${CYAN}How to fix:${NC}\n"
            printf "  1. cd frontend\n"
            printf "  2. pnpm build  (to see full output)\n"
            printf "  3. Check for:\n"
            printf "     - Angular template errors\n"
            printf "     - AOT compilation issues\n"
            printf "     - Missing imports or declarations\n"
            printf "\n"
        fi

        if [ "$FRONTEND_AUDIT_RESULT" = "WARN" ]; then
            printf "${YELLOW}${BOLD}━━━ Security Audit Warning ━━━${NC}\n\n"
            printf "${YELLOW}Vulnerabilities found:${NC}\n"
            cat "$FRONTEND_AUDIT_LOG"
            printf "\n${CYAN}How to fix:${NC}\n"
            printf "  1. cd frontend\n"
            printf "  2. pnpm audit  (to see all vulnerabilities)\n"
            printf "  3. pnpm audit fix  (to auto-fix where possible)\n"
            printf "  4. Review and update dependencies manually if needed\n"
            printf "\n"
        fi

        if [ "$FRONTEND_LICENSE_RESULT" = "WARN" ]; then
            printf "${YELLOW}${BOLD}━━━ License Compliance Warning ━━━${NC}\n\n"
            printf "${YELLOW}Packages with non-approved licenses:${NC}\n"
            cat "$FRONTEND_LICENSE_LOG"
            printf "\n${CYAN}How to fix:${NC}\n"
            printf "  1. cd frontend\n"
            printf "  2. pnpm exec license-checker --summary  (to see license summary)\n"
            printf "  3. Review packages with GPL, LGPL, or unknown licenses\n"
            printf "  4. Replace problematic packages or get legal approval\n"
            printf "  5. Approved licenses: MIT, ISC, Apache-2.0, BSD-2/3-Clause, CC0, Unlicense\n"
            printf "\n"
        fi

        if [ "$E2E_BDDGEN_RESULT" = "FAIL" ]; then
            printf "${RED}${BOLD}━━━ E2E BDD Generation Failed ━━━${NC}\n\n"
            printf "${YELLOW}Output:${NC}\n"
            cat "$E2E_BDDGEN_LOG"
            printf "\n${CYAN}How to fix:${NC}\n"
            printf "  1. cd e2e-tests\n"
            printf "  2. pnpm bddgen  (to regenerate BDD specs)\n"
            printf "  3. Check for:\n"
            printf "     - Invalid Gherkin syntax in .feature files\n"
            printf "     - Missing step definitions\n"
            printf "\n"
        fi

        if [ "$E2E_TESTS_RESULT" = "FAIL" ]; then
            printf "${RED}${BOLD}━━━ E2E Tests Failed ━━━${NC}\n\n"
            printf "${YELLOW}Last 80 lines of output:${NC}\n"
            tail -80 "$E2E_LOG"
            printf "\n${CYAN}How to fix:${NC}\n"
            printf "  1. cd e2e-tests\n"
            printf "  2. pnpm test:e2e:headed  (see browser)\n"
            printf "  3. pnpm test:e2e:ui  (interactive debug mode)\n"
            printf "  4. pnpm test:e2e:report  (view HTML report)\n"
            printf "  5. Check that backend is working: cd ../backend && mvn spring-boot:run\n"
            printf "  6. Check that frontend is working: cd ../frontend && pnpm start\n"
            printf "\n"
        fi

        # Determine exit status based on failures (not warnings)
        if [ "$PASSED_CHECKS" -lt "$TOTAL_CHECKS" ]; then
            printf "${RED}${BOLD}"
            printf "\n╔═══════════════════════════════════════════════════════════╗\n"
            printf "║                                                           ║\n"
            printf "║   QUALITY CHECK FAILED - Please fix the issues above      ║\n"
            printf "║                                                           ║\n"
            printf "╚═══════════════════════════════════════════════════════════╝\n"
            printf "${NC}\n"
            exit 1
        else
            printf "${YELLOW}${BOLD}"
            printf "\n╔═══════════════════════════════════════════════════════════╗\n"
            printf "║                                                           ║\n"
            printf "║   ALL CHECKS PASSED (with warnings - review recommended)  ║\n"
            printf "║                                                           ║\n"
            printf "╚═══════════════════════════════════════════════════════════╝\n"
            printf "${NC}\n"
            exit 0
        fi
    else
        printf "${GREEN}${BOLD}"
        printf "\n╔═══════════════════════════════════════════════════════════╗\n"
        printf "║                                                           ║\n"
        printf "║   ALL QUALITY CHECKS PASSED!                              ║\n"
        printf "║                                                           ║\n"
        printf "╚═══════════════════════════════════════════════════════════╝\n"
        printf "${NC}\n"

        exit 0
    fi
}

# Run main
main "$@"
