import { type Page, type Locator, expect } from '@playwright/test';
import { BasePage } from './base.page.js';

/** Page object for the cart page. */
export class CartPage extends BasePage {
  readonly title: Locator;
  readonly cartItems: Locator;
  readonly cartItemNames: Locator;
  readonly checkoutButton: Locator;
  readonly continueShoppingButton: Locator;

  constructor(page: Page) {
    super(page);
    this.title = page.locator('[data-test="title"]');
    this.cartItems = page.locator('[data-test="inventory-item"]');
    this.cartItemNames = page.locator('[data-test="inventory-item-name"]');
    this.checkoutButton = page.locator('[data-test="checkout"]');
    this.continueShoppingButton = page.locator('[data-test="continue-shopping"]');
  }

  async expectLoaded(): Promise<void> {
    await expect(this.page).toHaveURL(/cart\.html/);
    await expect(this.title).toHaveText('Your Cart');
  }

  async getItemNames(): Promise<string[]> {
    return (await this.cartItemNames.allTextContents()).map((t) => t.trim());
  }

  async getItemCount(): Promise<number> {
    return this.cartItems.count();
  }

  async checkout(): Promise<void> {
    await this.checkoutButton.click();
  }
}
