# End-to-End (E2E) Tests

> **📁 Location:** All E2E test files are in this `e2e-tests/` directory.
> **⚡ Run Commands:** Execute all commands from this directory: `cd e2e-tests`

## Overview

This project includes **minimal E2E sanity tests** using **Playwright with BDD** (playwright-bdd). These tests verify the full stack (frontend + backend) integration without any mocking or stubbing.

**Important:** E2E tests are NOT a replacement for unit and component tests! They serve as **high-level sanity checks** to ensure the entire application works together.

## Testing Strategy

| Test Type | Purpose | Coverage | Speed | Count |
|-----------|---------|----------|-------|-------|
| **Unit Tests (Backend)** | Test business logic in isolation | 100% backend | ⚡ Fast | 23 tests |
| **Component Tests (Frontend)** | Test UI components with mocked services | 100% frontend | ⚡ Fast | 30 tests |
| **E2E Tests** | Verify full-stack integration | Critical user journeys | 🐢 Slow | 2 tests |

**Tip:** Run all quality checks with `./quality-check.sh` from project root (includes E2E tests).

## Test Cases

We have **2 BDD scenarios** written in Gherkin format:

### 1. Get Personalized Greeting with Custom Name
Tests the happy path: user enters a custom name and receives a personalized greeting.

### 2. Get Greeting with Default Name
Tests the default behavior: user keeps the default "World" name and receives the standard greeting.

## ⚡ Automatic Service Management

**No manual setup required!** Playwright automatically starts backend and frontend services before tests.

### How It Works

When you run `pnpm test:e2e`, Playwright:
1. ✅ **Checks** if backend (port 8080) and frontend (port 4200) are running
2. ✅ **Starts** any services that aren't running (~10-15 seconds first time)
3. ✅ **Waits** for services to be ready (polls health endpoints)
4. ✅ **Runs** the E2E tests
5. ✅ **Cleanup** happens automatically via signal handlers

### Service Behavior

**Local Development (`reuseExistingServer: true`):**
- If services are already running → reuse them (tests start immediately!)
- If services aren't running → start them and keep them running
- Services persist between test runs (faster iterations)

**CI/CD (`reuseExistingServer: false`):**
- Always start fresh services
- Kill services after tests complete
- Clean, isolated test environment

## Running E2E Tests

### Run Tests (Headless)
```bash
pnpm test:e2e
```

### Run Tests (Headed - Watch Browser)
```bash
pnpm test:e2e:headed
```

### Run Tests (UI Mode - Interactive)
```bash
pnpm test:e2e:ui
```

### View Test Report
```bash
pnpm test:e2e:report
```

### Manual Cleanup (If Needed)

If tests crash and leave orphaned processes running:

```bash
pnpm cleanup
```

This script:
- 🧹 Kills any processes on ports 8080 (backend) and 4200 (frontend)
- 🧹 Kills any Maven (`mvn -Prun`) processes
- 🧹 Kills any pnpm start processes for frontend
- ✅ Safe to run anytime (no error if nothing running)

**When to use:**
- Tests crashed/killed with Ctrl+C
- Services are stuck running after tests
- Want to force a clean slate

## BDD Structure

### Feature Files (Gherkin)
Location: `e2e/features/**/*.feature`

Example:
```gherkin
Feature: Greeting Functionality

  Scenario: Get personalized greeting with custom name
    Given the application is running
    When I navigate to the home page
    Then I should see the "Hello World Demo" heading
    When I enter "Alice" as the name
    And I click the "Get Greeting" button
    Then I should see the greeting "Hello, Alice! Welcome to the world."
```

### Step Definitions
Location: `e2e/steps/**/*.ts`

Example:
```typescript
When('I enter {string} as the name', async ({ page }, name: string) => {
  // Arrange (implicit - page is already on the correct page)

  // Act
  await page.locator('#nameInput').clear();
  await page.locator('#nameInput').fill(name);

  // Assert (handled by separate Then steps)
});
```

## Modifying E2E Tests

### Adding New Scenarios

1. **Edit Feature File**: Add new scenario to `e2e/features/greeting.feature`
2. **Add Step Definitions** (if needed): Update `e2e/steps/greeting.steps.ts`
3. **Generate Test Code**: Run `npm run bddgen`
4. **Run Tests**: `npm run test:e2e`

### Creating New Features

1. **Create Feature File**: `e2e/features/my-feature.feature`
2. **Create Step Definitions**: `e2e/steps/my-feature.steps.ts`
3. **Generate Test Code**: Run `npm run bddgen`
4. **Run Tests**: `npm run test:e2e`

## AAA Pattern in BDD

BDD steps naturally follow the **Arrange-Act-Assert (AAA)** pattern:

- **Given** steps = **Arrange** (set up preconditions)
- **When** steps = **Act** (perform actions)
- **Then** steps = **Assert** (verify outcomes)

Example:
```gherkin
Given the application is running          # Arrange
When I navigate to the home page          # Act
And I enter "Alice" as the name           # Act
And I click the "Get Greeting" button     # Act
Then I should see the greeting "Hello..." # Assert
```

## CI/CD Integration

E2E tests work **out-of-the-box** in CI/CD! No special configuration needed.

```bash
# From project root
cd e2e-tests && npm install && npm run test:e2e
```

**What happens in CI:**
1. Playwright detects `CI=true` environment variable
2. Sets `reuseExistingServer: false` (fresh start)
3. Starts backend and frontend
4. Runs tests
5. **Automatically kills services** after tests (cleanup)

**Example GitLab CI / GitHub Actions:**
```yaml
e2e-tests:
  script:
    - cd e2e-tests
    - npm install
    - npm run test:e2e
```

That's it! No manual service management required.

## Troubleshooting

### Tests Fail with Connection Errors
**Problem:** `net::ERR_CONNECTION_REFUSED` or similar
**Solution:** Ensure both backend and frontend are running and accessible

### Tests Pass Locally But Fail in CI
**Problem:** Timing issues or different environment
**Solution:**
- Increase wait times in step definitions
- Add explicit waits for elements to be visible
- Check browser compatibility

### Test Generation Fails
**Problem:** `npx bddgen` doesn't create test files
**Solution:**
- Ensure feature files are in `e2e/features/**/*.feature`
- Ensure step definitions are in `e2e/steps/**/*.ts`
- Check `playwright.config.ts` for correct paths

## Best Practices

1. ✅ **Keep E2E Tests Minimal**: Only test critical user journeys
2. ✅ **No Mocking in E2E**: Test the full stack as users experience it
3. ✅ **Use Descriptive Scenarios**: Gherkin should be readable by non-developers
4. ✅ **Run Locally Before Commit**: Verify E2E tests pass before pushing
5. ❌ **Don't Replace Unit Tests**: E2E is slow and brittle - use sparingly

## For the Wordle Kata

As you build the Wordle game:
- Keep the 2 E2E tests working (update as needed)
- Add 1-2 more E2E tests for critical Wordle flows (e.g., "complete a game", "win on first guess")
- Focus test coverage on unit and component tests (100% target)
- Use E2E tests only for sanity checks of full integration

---

**Happy Testing!** 🎭🎯
