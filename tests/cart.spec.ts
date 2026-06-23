import { test, expect } from '../fixtures/pages.fixture.js';
import { STORAGE_STATE } from '../utils/test-data.js';

const BACKPACK = 'Sauce Labs Backpack';
const BIKE_LIGHT = 'Sauce Labs Bike Light';

test.describe('Cart', () => {
  test.use({ storageState: STORAGE_STATE });

  test.beforeEach(async ({ inventoryPage }) => {
    await inventoryPage.open();
    await inventoryPage.expectLoaded();
  });

  test('adding an item updates the cart badge', async ({ inventoryPage }) => {
    await inventoryPage.addItemToCart(BACKPACK);
    expect(await inventoryPage.getCartCount()).toBe(1);
  });

  test('adding multiple items increments the badge', async ({ inventoryPage }) => {
    await inventoryPage.addItemToCart(BACKPACK);
    await inventoryPage.addItemToCart(BIKE_LIGHT);
    expect(await inventoryPage.getCartCount()).toBe(2);
  });

  test('removing an item decrements the badge', async ({ inventoryPage }) => {
    await inventoryPage.addItemToCart(BACKPACK);
    await inventoryPage.addItemToCart(BIKE_LIGHT);
    await inventoryPage.removeItemFromCart(BACKPACK);
    expect(await inventoryPage.getCartCount()).toBe(1);
  });

  test('cart page lists the added items', async ({ inventoryPage, cartPage }) => {
    await inventoryPage.addItemToCart(BACKPACK);
    await inventoryPage.addItemToCart(BIKE_LIGHT);
    await inventoryPage.goToCart();
    await cartPage.expectLoaded();
    const names = await cartPage.getItemNames();
    expect(names).toContain(BACKPACK);
    expect(names).toContain(BIKE_LIGHT);
    expect(await cartPage.getItemCount()).toBe(2);
  });
});
