import { expect } from '@playwright/test';
import { createBdd } from 'playwright-bdd';

const { Given, When, Then } = createBdd();

// Given steps (Arrange)

Given('the application is running', async () => {
  // This is a precondition check - we assume backend and frontend are running
  // The test will fail if they're not running, which is the correct behavior
});

// When steps (Act)

When('I navigate to the home page', async ({ page }) => {
  await page.goto('/');
});

When('I enter {string} as the name', async ({ page }, name: string) => {
  await page.locator('#nameInput').clear();
  await page.locator('#nameInput').fill(name);
});

When('I click the {string} button', async ({ page }, buttonText: string) => {
  await page.getByRole('button', { name: buttonText }).click();
});

// Then steps (Assert)

Then('I should see the {string} heading', async ({ page }, headingText: string) => {
  const heading = page.locator('h1');
  await expect(heading).toContainText(headingText);
});

Then('the name input should contain {string}', async ({ page }, expectedValue: string) => {
  const input = page.locator('#nameInput');
  await expect(input).toHaveValue(expectedValue);
});

Then('I should see the greeting {string}', async ({ page }, expectedGreeting: string) => {
  // Wait for the API call to complete and greeting to appear
  const greetingElement = page.locator('.greeting-result h2');
  await expect(greetingElement).toBeVisible();
  await expect(greetingElement).toContainText(expectedGreeting);
});
