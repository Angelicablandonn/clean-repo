import { test, expect } from '../fixtures/pages.fixture.js';
import { STORAGE_STATE } from '../utils/test-data.js';

/**
 * These specs reuse the standard_user session captured by auth.setup.ts,
 * so they start on an authenticated context and skip the login form.
 */
test.describe('Product Catalogue', () => {
  test.use({ storageState: STORAGE_STATE });

  test.beforeEach(async ({ inventoryPage }) => {
    await inventoryPage.open();
    await inventoryPage.expectLoaded();
  });

  test('shows the full product grid', async ({ inventoryPage }) => {
    await expect(inventoryPage.items).toHaveCount(6);
  });

  test('sorts products by name A→Z', async ({ inventoryPage }) => {
    await inventoryPage.sortBy('az');
    const names = await inventoryPage.getItemNames();
    const sorted = [...names].sort((a, b) => a.localeCompare(b));
    expect(names).toEqual(sorted);
  });

  test('sorts products by name Z→A', async ({ inventoryPage }) => {
    await inventoryPage.sortBy('za');
    const names = await inventoryPage.getItemNames();
    const sorted = [...names].sort((a, b) => b.localeCompare(a));
    expect(names).toEqual(sorted);
  });

  test('sorts products by price low→high', async ({ inventoryPage }) => {
    await inventoryPage.sortBy('lohi');
    const prices = await inventoryPage.getItemPrices();
    const sorted = [...prices].sort((a, b) => a - b);
    expect(prices).toEqual(sorted);
  });

  test('sorts products by price high→low', async ({ inventoryPage }) => {
    await inventoryPage.sortBy('hilo');
    const prices = await inventoryPage.getItemPrices();
    const sorted = [...prices].sort((a, b) => b - a);
    expect(prices).toEqual(sorted);
  });
});
