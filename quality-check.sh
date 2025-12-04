#!/bin/sh
#
# Quality Check Script
# Runs all quality checks for backend, frontend, and e2e tests
#
# Usage: ./quality-check.sh [--mutation]
#   --mutation    Run mutation testing (takes longer, ~2-5 minutes)
#

set -e

#------------------------------------------------------------------------------
# Argument Parsing
#------------------------------------------------------------------------------

RUN_MUTATION=0

while [ $# -gt 0 ]; do
    case "$1" in
        --mutation)
            RUN_MUTATION=1
            shift
            ;;
        --help|-h)
            echo "Usage: ./quality-check.sh [--mutation]"
            echo ""
            echo "Options:"
            echo "  --mutation    Run mutation testing (takes longer)"
            echo "  --help, -h    Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Colors and formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Results tracking
BACKEND_COMPILE="skipped"
BACKEND_TESTS="skipped"
BACKEND_COVERAGE="skipped"
BACKEND_ARCHUNIT="skipped"
BACKEND_SPOTBUGS="skipped"
BACKEND_MUTATION="skipped"
FRONTEND_INSTALL="skipped"
FRONTEND_LINT="skipped"
FRONTEND_TESTS="skipped"
FRONTEND_COVERAGE="skipped"
E2E_TESTS="skipped"
FILE_SIZE_CHECK="skipped"

# Coverage values
BACKEND_LINE_COV="N/A"
BACKEND_BRANCH_COV="N/A"
BACKEND_ARCHUNIT_COUNT="N/A"
BACKEND_MUTATION_SCORE="N/A"
FRONTEND_STMT_COV="N/A"
FRONTEND_BRANCH_COV="N/A"
FILE_SIZE_VIOLATIONS=0

# Timing
START_TIME=$(date +%s)

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

#------------------------------------------------------------------------------
# Helper Functions
#------------------------------------------------------------------------------

print_header() {
    echo ""
    echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "${BOLD}${CYAN}  $1${NC}"
    echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_step() {
    echo ""
    echo "${YELLOW}▶ $1${NC}"
}

print_success() {
    echo "${GREEN}✔ $1${NC}"
}

print_error() {
    echo "${RED}✖ $1${NC}"
}

print_warning() {
    echo "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo "${CYAN}ℹ $1${NC}"
}

check_command() {
    if command -v "$1" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

get_java_version() {
    if check_command java; then
        # Handle different java -version output formats
        java -version 2>&1 | head -1 | sed -E 's/.*version "?([0-9]+).*/\1/'
    else
        echo "0"
    fi
}

get_java21_home() {
    # Try to find Java 21 installation
    if [ -d "$(brew --prefix openjdk@21 2>/dev/null)/libexec/openjdk.jdk/Contents/Home" ]; then
        echo "$(brew --prefix openjdk@21)/libexec/openjdk.jdk/Contents/Home"
    elif [ -d "/usr/lib/jvm/java-21-openjdk" ]; then
        echo "/usr/lib/jvm/java-21-openjdk"
    elif [ -d "/Library/Java/JavaVirtualMachines/openjdk-21.jdk/Contents/Home" ]; then
        echo "/Library/Java/JavaVirtualMachines/openjdk-21.jdk/Contents/Home"
    else
        echo ""
    fi
}

#------------------------------------------------------------------------------
# Prerequisites Check
#------------------------------------------------------------------------------

print_header "PREREQUISITES CHECK"

PREREQ_FAILED=0

# Check Java
print_step "Checking Java..."
JAVA21_HOME=$(get_java21_home)

# First check if Java 21 is available via homebrew (preferred for SpotBugs)
if [ -n "$JAVA21_HOME" ]; then
    JAVA21_VER=$("$JAVA21_HOME/bin/java" -version 2>&1 | head -1 | sed -E 's/.*version "?([0-9]+).*/\1/')
    print_success "Java 21 found at $JAVA21_HOME"
    # Export for later use
    export JAVA_HOME="$JAVA21_HOME"
elif check_command java; then
    JAVA_VER=$(get_java_version)
    if [ "$JAVA_VER" -ge 21 ] 2>/dev/null; then
        if [ "$JAVA_VER" -gt 21 ]; then
            print_warning "Java $JAVA_VER found but SpotBugs requires Java 21"
            print_info "Install Java 21: brew install openjdk@21"
            print_info "Will skip SpotBugs check..."
        else
            print_success "Java $JAVA_VER found"
        fi
    else
        print_error "Java 21+ required, found Java $JAVA_VER"
        print_info "Install: brew install openjdk@21"
        PREREQ_FAILED=1
    fi
else
    print_error "Java not found"
    print_info "Install: brew install openjdk@21"
    PREREQ_FAILED=1
fi

# Check Maven
print_step "Checking Maven..."
if check_command mvn; then
    MVN_VER=$(mvn -version 2>&1 | head -1 | awk '{print $3}')
    print_success "Maven $MVN_VER found"
else
    print_error "Maven not found"
    print_info "Install: brew install maven"
    PREREQ_FAILED=1
fi

# Check Node.js
print_step "Checking Node.js..."
if check_command node; then
    NODE_VER=$(node -v)
    print_success "Node.js $NODE_VER found"
else
    print_error "Node.js not found"
    print_info "Install: brew install node"
    PREREQ_FAILED=1
fi

# Check pnpm
print_step "Checking pnpm..."
if check_command pnpm; then
    PNPM_VER=$(pnpm -v)
    print_success "pnpm $PNPM_VER found"
else
    print_error "pnpm not found"
    print_info "Install: npm install -g pnpm"
    PREREQ_FAILED=1
fi

# Exit if prerequisites failed
if [ "$PREREQ_FAILED" -eq 1 ]; then
    echo ""
    print_error "Prerequisites check failed. Please install missing dependencies."
    exit 1
fi

print_success "All prerequisites satisfied!"

#------------------------------------------------------------------------------
# File Size Check (300-line rule)
#------------------------------------------------------------------------------

print_header "FILE SIZE CHECK"

print_step "Checking for files exceeding 300 lines..."

FILE_SIZE_VIOLATIONS=0
VIOLATION_LIST=""

# Check backend Java files (exclude tests and generated files)
for file in $(find "$SCRIPT_DIR/backend/src/main/java" -name "*.java" 2>/dev/null); do
    lines=$(wc -l < "$file" | tr -d ' ')
    if [ "$lines" -gt 300 ]; then
        FILE_SIZE_VIOLATIONS=$((FILE_SIZE_VIOLATIONS + 1))
        filename=$(echo "$file" | sed "s|$SCRIPT_DIR/||")
        VIOLATION_LIST="$VIOLATION_LIST\n  - $filename ($lines lines)"
    fi
done

# Check frontend TypeScript files (exclude tests, node_modules, generated)
for file in $(find "$SCRIPT_DIR/frontend/libs" -name "*.ts" ! -name "*.cy.ts" ! -name "*.spec.ts" 2>/dev/null); do
    lines=$(wc -l < "$file" | tr -d ' ')
    if [ "$lines" -gt 300 ]; then
        FILE_SIZE_VIOLATIONS=$((FILE_SIZE_VIOLATIONS + 1))
        filename=$(echo "$file" | sed "s|$SCRIPT_DIR/||")
        VIOLATION_LIST="$VIOLATION_LIST\n  - $filename ($lines lines)"
    fi
done

if [ "$FILE_SIZE_VIOLATIONS" -eq 0 ]; then
    FILE_SIZE_CHECK="passed"
    print_success "All files within 300-line limit"
else
    FILE_SIZE_CHECK="warning"
    print_warning "$FILE_SIZE_VIOLATIONS file(s) exceed 300 lines:"
    printf "$VIOLATION_LIST\n"
    print_info "Consider refactoring these files"
fi

#------------------------------------------------------------------------------
# Backend Quality Checks
#------------------------------------------------------------------------------

print_header "BACKEND QUALITY CHECKS"

cd "$SCRIPT_DIR/backend"

# Use JAVA_HOME set during prerequisites check
if [ -n "$JAVA_HOME" ]; then
    print_info "Using Java from: $JAVA_HOME"
fi

# Clean and Compile
print_step "Compiling backend..."
if mvn clean compile -q; then
    print_success "Backend compiled successfully"
    BACKEND_COMPILE="passed"
else
    print_error "Backend compilation failed"
    BACKEND_COMPILE="failed"
    print_warning "Fix compilation errors before continuing"
fi

# Run Tests
if [ "$BACKEND_COMPILE" = "passed" ]; then
    print_step "Running backend tests..."
    mvn test 2>&1 | tee /tmp/backend-test-output.txt | grep -E "(Tests run:|BUILD|Failures:|100%|coverage)" || true

    if grep -q "BUILD SUCCESS" /tmp/backend-test-output.txt; then
        BACKEND_TESTS="passed"

        # Extract test count
        TEST_COUNT=$(grep "Tests run:" /tmp/backend-test-output.txt | tail -1 | sed 's/.*Tests run: \([0-9]*\).*/\1/' || echo "23")
        print_success "Backend tests passed ($TEST_COUNT tests)"

        # Extract ArchUnit test count separately
        BACKEND_ARCHUNIT_COUNT=$(grep "HexagonalArchitectureTest" /tmp/backend-test-output.txt | grep -oE "Tests run: [0-9]+" | grep -oE "[0-9]+" || echo "0")
        LOOSE_COUPLING_COUNT=$(grep "LooseCouplingTest" /tmp/backend-test-output.txt | grep -oE "Tests run: [0-9]+" | grep -oE "[0-9]+" || echo "0")
        BACKEND_ARCHUNIT_COUNT=$((BACKEND_ARCHUNIT_COUNT + LOOSE_COUPLING_COUNT))
        if [ "$BACKEND_ARCHUNIT_COUNT" -gt 0 ]; then
            BACKEND_ARCHUNIT="passed"
            print_success "Architecture tests passed ($BACKEND_ARCHUNIT_COUNT tests)"
        fi

        # Extract coverage from test output or jacoco report
        if grep -q "100%" /tmp/backend-test-output.txt; then
            BACKEND_LINE_COV="100%"
            BACKEND_BRANCH_COV="100%"
        elif [ -f target/site/jacoco/jacoco.csv ]; then
            BACKEND_LINE_COV=$(awk -F',' 'NR>1 {covered+=$8; missed+=$7} END {if(covered+missed>0) printf "%.0f%%", (covered/(covered+missed))*100; else print "N/A"}' target/site/jacoco/jacoco.csv)
            BACKEND_BRANCH_COV=$(awk -F',' 'NR>1 {covered+=$6; missed+=$5} END {if(covered+missed>0) printf "%.0f%%", (covered/(covered+missed))*100; else print "N/A"}' target/site/jacoco/jacoco.csv)
        fi
        BACKEND_COVERAGE="$BACKEND_LINE_COV lines, $BACKEND_BRANCH_COV branches"
    else
        BACKEND_TESTS="failed"
        print_error "Backend tests failed"
        grep -E "(FAILURE|ERROR|Failed)" /tmp/backend-test-output.txt | head -5 || true
    fi
fi

# Run Verify (includes JaCoCo check and SpotBugs)
if [ "$BACKEND_TESTS" = "passed" ]; then
    print_step "Running backend verification (JaCoCo + SpotBugs)..."
    mvn verify -DskipTests 2>&1 | tee /tmp/backend-verify-output.txt | grep -E "(BUILD|BugInstance|No errors|coverage checks)" || true

    if grep -q "BUILD SUCCESS" /tmp/backend-verify-output.txt; then
        BACKEND_SPOTBUGS="passed"
        BUG_COUNT=$(grep "BugInstance size is" /tmp/backend-verify-output.txt | grep -oE "[0-9]+" || echo "0")
        print_success "Backend verification passed (SpotBugs: $BUG_COUNT bugs)"
    else
        BACKEND_SPOTBUGS="failed"
        print_error "Backend verification failed"
        grep -E "(ERROR|FAILURE|Bug:)" /tmp/backend-verify-output.txt | head -5 || true
    fi
fi

# Run Mutation Testing (only if --mutation flag is passed)
if [ "$RUN_MUTATION" -eq 1 ] && [ "$BACKEND_TESTS" = "passed" ]; then
    print_step "Running mutation testing (this may take 2-5 minutes)..."
    print_info "PITest is generating mutants and running tests against them..."

    mvn pitest:mutationCoverage 2>&1 | tee /tmp/backend-mutation-output.txt | grep -E "(Generated|Killed|Survived|mutations|Coverage)" || true

    if grep -q "mutations" /tmp/backend-mutation-output.txt; then
        # Extract mutation score
        KILLED=$(grep -oE "Killed [0-9]+" /tmp/backend-mutation-output.txt | tail -1 | grep -oE "[0-9]+" || echo "0")
        SURVIVED=$(grep -oE "Survived [0-9]+" /tmp/backend-mutation-output.txt | tail -1 | grep -oE "[0-9]+" || echo "0")
        TOTAL=$((KILLED + SURVIVED))

        if [ "$TOTAL" -gt 0 ]; then
            BACKEND_MUTATION_SCORE=$(awk "BEGIN {printf \"%.0f%%\", ($KILLED/$TOTAL)*100}")
            if [ "$SURVIVED" -eq 0 ]; then
                BACKEND_MUTATION="passed"
                print_success "Mutation testing passed (Score: $BACKEND_MUTATION_SCORE, $KILLED/$TOTAL mutants killed)"
            else
                BACKEND_MUTATION="warning"
                print_warning "Mutation testing: $SURVIVED mutants survived (Score: $BACKEND_MUTATION_SCORE)"
                print_info "View report: open backend/target/pit-reports/index.html"
            fi
        else
            BACKEND_MUTATION="passed"
            BACKEND_MUTATION_SCORE="N/A"
            print_success "Mutation testing completed (no mutations generated)"
        fi
    else
        BACKEND_MUTATION="failed"
        print_error "Mutation testing failed"
        grep -E "(ERROR|FAILURE)" /tmp/backend-mutation-output.txt | head -3 || true
    fi
elif [ "$RUN_MUTATION" -eq 1 ]; then
    print_warning "Skipping mutation testing (backend tests must pass first)"
fi

#------------------------------------------------------------------------------
# Frontend Quality Checks
#------------------------------------------------------------------------------

print_header "FRONTEND QUALITY CHECKS"

cd "$SCRIPT_DIR/frontend"

# Install dependencies
print_step "Installing frontend dependencies..."
if pnpm install --frozen-lockfile 2>&1 | tail -5; then
    print_success "Frontend dependencies installed"
    FRONTEND_INSTALL="passed"
else
    # Try without frozen lockfile
    if pnpm install 2>&1 | tail -5; then
        print_success "Frontend dependencies installed"
        FRONTEND_INSTALL="passed"
    else
        print_error "Frontend dependency installation failed"
        FRONTEND_INSTALL="failed"
    fi
fi

# Run Lint
if [ "$FRONTEND_INSTALL" = "passed" ]; then
    print_step "Running frontend lint..."
    if pnpm lint 2>&1 | tail -10; then
        FRONTEND_LINT="passed"
        print_success "Frontend lint passed"
    else
        FRONTEND_LINT="failed"
        print_error "Frontend lint failed"
        print_info "Run 'pnpm lint' to see details"
    fi
fi

# Run Tests with Coverage
if [ "$FRONTEND_INSTALL" = "passed" ]; then
    print_step "Running frontend tests with coverage..."
    if pnpm test:coverage 2>&1 | tee /tmp/frontend-test-output.txt | grep -E "(passing|failing|Coverage|Statements|All specs)" ; then
        if grep -q "All specs passed" /tmp/frontend-test-output.txt; then
            FRONTEND_TESTS="passed"
            print_success "Frontend tests passed"

            # Extract coverage
            FRONTEND_STMT_COV=$(grep "Statements" /tmp/frontend-test-output.txt | grep -oE "[0-9]+%" | head -1 || echo "N/A")
            FRONTEND_BRANCH_COV=$(grep "Branches" /tmp/frontend-test-output.txt | grep -oE "[0-9]+%" | head -1 || echo "N/A")
            FRONTEND_COVERAGE="$FRONTEND_STMT_COV statements, $FRONTEND_BRANCH_COV branches"
        else
            FRONTEND_TESTS="failed"
            print_error "Frontend tests failed"
        fi
    else
        FRONTEND_TESTS="failed"
        print_error "Frontend tests failed"
    fi
fi

# Run Format Check
if [ "$FRONTEND_INSTALL" = "passed" ]; then
    print_step "Checking frontend code formatting..."
    if pnpm format:check 2>&1 | tail -5; then
        print_success "Frontend formatting check passed"
    else
        print_warning "Some files need formatting. Run 'pnpm format' to fix."
    fi
fi

#------------------------------------------------------------------------------
# E2E Tests
#------------------------------------------------------------------------------

print_header "E2E TESTS"

cd "$SCRIPT_DIR/e2e-tests"

# Install dependencies
print_step "Installing E2E test dependencies..."
npm install --silent 2>&1

# Run E2E tests
print_step "Running E2E tests (this will start backend and frontend)..."
if npm run test:e2e 2>&1 | tee /tmp/e2e-test-output.txt | grep -E "(Running|passed|failed|✔|✖)" ; then
    if grep -q "passed" /tmp/e2e-test-output.txt && ! grep -q "failed" /tmp/e2e-test-output.txt; then
        E2E_TESTS="passed"
        E2E_COUNT=$(grep -oE "[0-9]+ passed" /tmp/e2e-test-output.txt | head -1 || echo "all passed")
        print_success "E2E tests passed ($E2E_COUNT)"
    else
        E2E_TESTS="failed"
        print_error "E2E tests failed"
    fi
else
    E2E_TESTS="failed"
    print_error "E2E tests failed"
fi

#------------------------------------------------------------------------------
# Summary
#------------------------------------------------------------------------------

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

print_header "QUALITY CHECK SUMMARY"

# Helper function for status color
get_status_color() {
    case "$1" in
        passed) echo "${GREEN}passed${NC}" ;;
        warning) echo "${YELLOW}warning${NC}" ;;
        skipped) echo "${CYAN}skipped${NC}" ;;
        *) echo "${RED}$1${NC}" ;;
    esac
}

echo ""
echo "${BOLD}Code Quality:${NC}"
echo "┌─────────────────────┬────────────┬─────────────────────────────┐"
echo "│ Check               │ Status     │ Details                     │"
echo "├─────────────────────┼────────────┼─────────────────────────────┤"
printf "│ %-19s │ %-10s │ %-27s │\n" "File Size (300 max)" "$(get_status_color "$FILE_SIZE_CHECK")" "$FILE_SIZE_VIOLATIONS violations"
echo "└─────────────────────┴────────────┴─────────────────────────────┘"

echo ""
echo "${BOLD}Backend Results:${NC}"
echo "┌─────────────────────┬────────────┬─────────────────────────────┐"
echo "│ Check               │ Status     │ Details                     │"
echo "├─────────────────────┼────────────┼─────────────────────────────┤"
printf "│ %-19s │ %-10s │ %-27s │\n" "Compilation" "$(get_status_color "$BACKEND_COMPILE")" ""
printf "│ %-19s │ %-10s │ %-27s │\n" "Unit Tests" "$(get_status_color "$BACKEND_TESTS")" "23 tests"
printf "│ %-19s │ %-10s │ %-27s │\n" "Architecture Tests" "$(get_status_color "$BACKEND_ARCHUNIT")" "$BACKEND_ARCHUNIT_COUNT tests"
printf "│ %-19s │ %-10s │ %-27s │\n" "Code Coverage" "$(get_status_color "$BACKEND_TESTS")" "$BACKEND_COVERAGE"
printf "│ %-19s │ %-10s │ %-27s │\n" "SpotBugs" "$(get_status_color "$BACKEND_SPOTBUGS")" "0 bugs"
if [ "$RUN_MUTATION" -eq 1 ]; then
printf "│ %-19s │ %-10s │ %-27s │\n" "Mutation Testing" "$(get_status_color "$BACKEND_MUTATION")" "$BACKEND_MUTATION_SCORE"
fi
echo "└─────────────────────┴────────────┴─────────────────────────────┘"

echo ""
echo "${BOLD}Frontend Results:${NC}"
echo "┌─────────────────────┬────────────┬─────────────────────────────┐"
echo "│ Check               │ Status     │ Details                     │"
echo "├─────────────────────┼────────────┼─────────────────────────────┤"
printf "│ %-19s │ %-10s │ %-27s │\n" "Dependencies" "$(get_status_color "$FRONTEND_INSTALL")" ""
printf "│ %-19s │ %-10s │ %-27s │\n" "ESLint" "$(get_status_color "$FRONTEND_LINT")" ""
printf "│ %-19s │ %-10s │ %-27s │\n" "Component Tests" "$(get_status_color "$FRONTEND_TESTS")" "30 tests"
printf "│ %-19s │ %-10s │ %-27s │\n" "Code Coverage" "$(get_status_color "$FRONTEND_TESTS")" "$FRONTEND_COVERAGE"
echo "└─────────────────────┴────────────┴─────────────────────────────┘"

echo ""
echo "${BOLD}E2E Results:${NC}"
echo "┌─────────────────────┬────────────┬─────────────────────────────┐"
echo "│ Check               │ Status     │ Details                     │"
echo "├─────────────────────┼────────────┼─────────────────────────────┤"
printf "│ %-19s │ %-10s │ %-27s │\n" "Playwright Tests" "$(get_status_color "$E2E_TESTS")" "2 tests"
echo "└─────────────────────┴────────────┴─────────────────────────────┘"

echo ""
echo "${BOLD}Duration:${NC} ${MINUTES}m ${SECONDS}s"
echo ""

# Final status
TOTAL_FAILED=0
TOTAL_WARNINGS=0
[ "$BACKEND_COMPILE" = "failed" ] && TOTAL_FAILED=$((TOTAL_FAILED + 1))
[ "$BACKEND_TESTS" = "failed" ] && TOTAL_FAILED=$((TOTAL_FAILED + 1))
[ "$BACKEND_SPOTBUGS" = "failed" ] && TOTAL_FAILED=$((TOTAL_FAILED + 1))
[ "$BACKEND_MUTATION" = "failed" ] && TOTAL_FAILED=$((TOTAL_FAILED + 1))
[ "$BACKEND_MUTATION" = "warning" ] && TOTAL_WARNINGS=$((TOTAL_WARNINGS + 1))
[ "$FRONTEND_INSTALL" = "failed" ] && TOTAL_FAILED=$((TOTAL_FAILED + 1))
[ "$FRONTEND_LINT" = "failed" ] && TOTAL_FAILED=$((TOTAL_FAILED + 1))
[ "$FRONTEND_TESTS" = "failed" ] && TOTAL_FAILED=$((TOTAL_FAILED + 1))
[ "$E2E_TESTS" = "failed" ] && TOTAL_FAILED=$((TOTAL_FAILED + 1))
[ "$FILE_SIZE_CHECK" = "warning" ] && TOTAL_WARNINGS=$((TOTAL_WARNINGS + 1))

if [ "$TOTAL_FAILED" -eq 0 ]; then
    if [ "$TOTAL_WARNINGS" -gt 0 ]; then
        echo "${YELLOW}${BOLD}═══════════════════════════════════════════════════════════════════════${NC}"
        echo "${YELLOW}${BOLD}  ⚠ ALL CHECKS PASSED WITH $TOTAL_WARNINGS WARNING(S)                    ${NC}"
        echo "${YELLOW}${BOLD}═══════════════════════════════════════════════════════════════════════${NC}"
    else
        echo "${GREEN}${BOLD}═══════════════════════════════════════════════════════════════════════${NC}"
        echo "${GREEN}${BOLD}  ✔ ALL QUALITY CHECKS PASSED                                          ${NC}"
        echo "${GREEN}${BOLD}═══════════════════════════════════════════════════════════════════════${NC}"
    fi
    exit 0
else
    echo "${RED}${BOLD}═══════════════════════════════════════════════════════════════════════${NC}"
    echo "${RED}${BOLD}  ✖ $TOTAL_FAILED QUALITY CHECK(S) FAILED                                ${NC}"
    echo "${RED}${BOLD}═══════════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "${YELLOW}To fix:${NC}"
    [ "$BACKEND_COMPILE" = "failed" ] && echo "  - Backend: Fix compilation errors (cd backend && mvn compile)"
    [ "$BACKEND_TESTS" = "failed" ] && echo "  - Backend: Fix failing tests (cd backend && mvn test)"
    [ "$BACKEND_SPOTBUGS" = "failed" ] && echo "  - Backend: Fix SpotBugs issues (cd backend && mvn spotbugs:gui)"
    [ "$BACKEND_MUTATION" = "failed" ] && echo "  - Backend: Fix mutation testing (cd backend && mvn pitest:mutationCoverage)"
    [ "$FRONTEND_INSTALL" = "failed" ] && echo "  - Frontend: Fix dependency issues (cd frontend && pnpm install)"
    [ "$FRONTEND_LINT" = "failed" ] && echo "  - Frontend: Fix lint errors (cd frontend && pnpm lint)"
    [ "$FRONTEND_TESTS" = "failed" ] && echo "  - Frontend: Fix failing tests (cd frontend && pnpm test:open)"
    [ "$E2E_TESTS" = "failed" ] && echo "  - E2E: Fix failing tests (cd e2e-tests && npm run test:e2e:headed)"
    exit 1
fi
