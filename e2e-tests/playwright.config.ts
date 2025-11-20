import { defineConfig, devices } from '@playwright/test';
import { defineBddConfig } from 'playwright-bdd';

const testDir = defineBddConfig({
  features: 'e2e/features/**/*.feature',
  steps: 'e2e/steps/**/*.ts',
});

export default defineConfig({
  testDir,
  fullyParallel: false, // Run tests sequentially for E2E
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: 1, // Single worker for E2E tests
  reporter: 'html',
  use: {
    baseURL: 'http://localhost:4200',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
  },

  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],

  // Automatically start backend and frontend before tests
  webServer: [
    {
      command: 'cd ../backend && mvn -Prun',
      url: 'http://localhost:8080/api/hello',
      timeout: 120000, // 2 minutes for Maven startup
      reuseExistingServer: !process.env.CI, // Reuse in dev, fresh start in CI
      stdout: 'pipe',
      stderr: 'pipe',
    },
    {
      command: 'cd ../frontend && npm start',
      url: 'http://localhost:4200',
      timeout: 120000, // 2 minutes for Angular startup
      reuseExistingServer: !process.env.CI, // Reuse in dev, fresh start in CI
      stdout: 'pipe',
      stderr: 'pipe',
    },
  ],
});
