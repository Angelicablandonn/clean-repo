import { test, expect } from '../fixtures/pages.fixture.js';
import { STORAGE_STATE, CHECKOUT_CUSTOMER } from '../utils/test-data.js';

const BACKPACK = 'Sauce Labs Backpack';

test.describe('Checkout', () => {
  test.use({ storageState: STORAGE_STATE });

  test.beforeEach(async ({ inventoryPage }) => {
    await inventoryPage.open();
    await inventoryPage.expectLoaded();
  });

  test('completes the full happy-path checkout', async ({
    inventoryPage,
    cartPage,
    checkoutPage,
  }) => {
    await inventoryPage.addItemToCart(BACKPACK);
    await inventoryPage.goToCart();
    await cartPage.expectLoaded();
    await cartPage.checkout();

    await checkoutPage.fillCustomerInfo(
      CHECKOUT_CUSTOMER.firstName,
      CHECKOUT_CUSTOMER.lastName,
      CHECKOUT_CUSTOMER.postalCode,
    );
    await expect(checkoutPage.summaryTotal).toBeVisible();
    await checkoutPage.finish();
    await checkoutPage.expectOrderComplete();
  });

  test('blocks checkout when customer info is missing', async ({
    inventoryPage,
    cartPage,
    checkoutPage,
  }) => {
    await inventoryPage.addItemToCart(BACKPACK);
    await inventoryPage.goToCart();
    await cartPage.checkout();

    // Submit with empty first name.
    await checkoutPage.fillCustomerInfo('', CHECKOUT_CUSTOMER.lastName, CHECKOUT_CUSTOMER.postalCode);
    expect(await checkoutPage.getErrorText()).toContain('First Name is required');
  });
});
