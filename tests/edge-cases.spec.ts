import { test, expect } from '../fixtures/pages.fixture.js';
import { USERS } from '../utils/test-data.js';

/**
 * Edge-case specs for the special SauceDemo users. These log in fresh (no
 * stored session) because the behaviour under test is tied to the specific
 * account, not the standard_user.
 */
test.describe('Special user edge cases', () => {
  test.use({ storageState: { cookies: [], origins: [] } });

  test('problem_user serves broken product images', async ({
    loginPage,
    inventoryPage,
  }) => {
    await loginPage.open();
    await loginPage.login(USERS.problem);
    await inventoryPage.expectLoaded();

    // problem_user renders every product image with the same placeholder
    // ("sl-404") asset. Assert the data defect is observable.
    const firstImg = inventoryPage.pageRef.locator('.inventory_item_img img').first();
    await expect(firstImg).toHaveAttribute('src', /sl-404/);
  });

  /**
   * Lead add-on: performance_glitch_user.
   *
   * This account artificially delays login and page loads. We assert the
   * inventory page becomes usable within a documented threshold.
   *
   * Threshold rationale: SauceDemo's glitch typically adds a few seconds of
   * latency. 10s is generous enough to avoid false failures from that
   * deliberate delay plus normal network variance, yet tight enough to catch
   * a genuine regression (e.g. a page that never loads or hangs past the
   * default action budget). We measure wall-clock time from clicking login to
   * the "Products" title being visible.
   */
  test('performance_glitch_user loads inventory within budget', async ({
    loginPage,
    inventoryPage,
  }) => {
    const ACCEPTABLE_LOAD_MS = 10_000;

    await loginPage.open();

    const start = Date.now();
    await loginPage.login(USERS.performanceGlitch);
    await expect(inventoryPage.title).toHaveText('Products', { timeout: ACCEPTABLE_LOAD_MS });
    const elapsed = Date.now() - start;

    expect(elapsed).toBeLessThanOrEqual(ACCEPTABLE_LOAD_MS);
    // eslint-disable-next-line no-console
    console.log(`performance_glitch_user inventory load: ${elapsed}ms`);
  });
});
