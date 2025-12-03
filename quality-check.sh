#!/bin/sh
#
# Comprehensive Quality Check Script
# Runs all backend, frontend, and E2E quality checks
#

set -e

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
BACKEND_TESTS_RESULT=""
BACKEND_SPOTBUGS_RESULT=""
FRONTEND_TYPECHECK_RESULT=""
FRONTEND_LINT_RESULT=""
FRONTEND_FORMAT_RESULT=""
FRONTEND_TESTS_RESULT=""
FRONTEND_BUILD_RESULT=""
FRONTEND_AUDIT_RESULT=""
E2E_TESTS_RESULT=""
E2E_BDDGEN_RESULT=""

# Temp files for capturing output
BACKEND_LOG=$(mktemp)
BACKEND_SPOTBUGS_LOG=$(mktemp)
FRONTEND_TYPECHECK_LOG=$(mktemp)
FRONTEND_LINT_LOG=$(mktemp)
FRONTEND_FORMAT_LOG=$(mktemp)
FRONTEND_TESTS_LOG=$(mktemp)
FRONTEND_BUILD_LOG=$(mktemp)
FRONTEND_AUDIT_LOG=$(mktemp)
E2E_LOG=$(mktemp)
E2E_BDDGEN_LOG=$(mktemp)

# Cleanup temp files on exit
cleanup() {
    rm -f "$BACKEND_LOG" "$BACKEND_SPOTBUGS_LOG" "$FRONTEND_TYPECHECK_LOG" "$FRONTEND_LINT_LOG" "$FRONTEND_FORMAT_LOG" "$FRONTEND_TESTS_LOG" "$FRONTEND_BUILD_LOG" "$FRONTEND_AUDIT_LOG" "$E2E_LOG" "$E2E_BDDGEN_LOG"
}
trap cleanup EXIT

# Print section header
print_header() {
    printf "\n${BLUE}${BOLD}═══════════════════════════════════════════════════════════════${NC}\n"
    printf "${BLUE}${BOLD}  %s${NC}\n" "$1"
    printf "${BLUE}${BOLD}═══════════════════════════════════════════════════════════════${NC}\n\n"
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

    START_TIME=$(date +%s)

    # ═══════════════════════════════════════════════════════════════
    # BACKEND CHECKS
    # ═══════════════════════════════════════════════════════════════
    print_header "BACKEND CHECKS (Java/Spring Boot)"

    print_step "Running: Maven tests (JUnit + ArchUnit + JaCoCo)"
    cd "$PROJECT_ROOT/backend"

    if mvn clean test > "$BACKEND_LOG" 2>&1; then
        print_success "Backend tests passed"
        BACKEND_TESTS_RESULT="PASS"
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
    else
        print_failure "SpotBugs found issues"
        BACKEND_SPOTBUGS_RESULT="FAIL"
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
        print_success "Frontend tests passed"
        FRONTEND_TESTS_RESULT="PASS"
    else
        print_failure "Frontend tests failed"
        FRONTEND_TESTS_RESULT="FAIL"
    fi

    # Build check
    print_step "Running: Angular production build"
    if pnpm build > "$FRONTEND_BUILD_LOG" 2>&1; then
        print_success "Angular build passed"
        FRONTEND_BUILD_RESULT="PASS"
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
    else
        print_failure "E2E tests failed"
        E2E_TESTS_RESULT="FAIL"
    fi

    # Cleanup any hanging processes
    if [ -f "$PROJECT_ROOT/e2e-tests/scripts/cleanup-services.sh" ]; then
        sh "$PROJECT_ROOT/e2e-tests/scripts/cleanup-services.sh" > /dev/null 2>&1 || true
    fi

    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))

    # ═══════════════════════════════════════════════════════════════
    # SUMMARY REPORT
    # ═══════════════════════════════════════════════════════════════
    print_header "QUALITY CHECK SUMMARY"

    # Count results (10 checks total, audit is warning-only)
    TOTAL_CHECKS=9
    PASSED_CHECKS=0
    WARNINGS=0

    printf "${BOLD}%-40s %s${NC}\n" "Check" "Status"
    printf "─────────────────────────────────────────────────────\n"

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
    else
        printf "%-40s ${YELLOW}⚠ WARN${NC}\n" "Security Audit (pnpm audit)"
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

        if [ "$BACKEND_TESTS_RESULT" = "FAIL" ]; then
            printf "${RED}${BOLD}━━━ Backend Tests Failed ━━━${NC}\n\n"
            printf "${YELLOW}Last 50 lines of output:${NC}\n"
            tail -50 "$BACKEND_LOG"
            printf "\n${CYAN}How to fix:${NC}\n"
            printf "  1. cd backend\n"
            printf "  2. mvn test  (to see full output)\n"
            printf "  3. Check for:\n"
            printf "     - Failing unit tests (JUnit)\n"
            printf "     - Architecture violations (ArchUnit)\n"
            printf "     - Coverage below threshold (JaCoCo: 80%% lines, 70%% branches)\n"
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
            printf "     - Coverage below threshold (80%% lines, 70%% branches)\n"
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
