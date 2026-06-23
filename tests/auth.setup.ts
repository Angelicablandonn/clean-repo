import { test as setup, expect } from '@playwright/test';
import { LoginPage } from '../pages/login.page.js';
import { InventoryPage } from '../pages/inventory.page.js';
import { USERS, STORAGE_STATE } from '../utils/test-data.js';

/**
 * StorageState setup (Task A requirement).
 *
 * Runs once before the browser projects (declared as their dependency in
 * playwright.config.ts). It logs in as standard_user a single time and
 * serialises the resulting session to disk. Specs that opt in via
 * `test.use({ storageState: STORAGE_STATE })` then start already
 * authenticated, so we don't pay the login cost in every worker.
 */
setup('authenticate as standard_user', async ({ page }) => {
  const loginPage = new LoginPage(page);
  const inventoryPage = new InventoryPage(page);

  await loginPage.open();
  await loginPage.loginExpectingSuccess(USERS.standard);
  await inventoryPage.expectLoaded();

  // Persist cookies + localStorage for reuse by other workers.
  await page.context().storageState({ path: STORAGE_STATE });
  await expect(inventoryPage.title).toHaveText('Products');
});
