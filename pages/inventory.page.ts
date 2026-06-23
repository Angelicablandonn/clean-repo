import { type Page, type Locator, expect } from '@playwright/test';
import { BasePage } from './base.page.js';

export type SortOption =
  | 'az'   // Name (A to Z)
  | 'za'   // Name (Z to A)
  | 'lohi' // Price (low to high)
  | 'hilo'; // Price (high to low)

/** Page object for the product catalogue / inventory page. */
export class InventoryPage extends BasePage {
  readonly title: Locator;
  readonly items: Locator;
  readonly itemNames: Locator;
  readonly itemPrices: Locator;
  readonly sortDropdown: Locator;
  readonly cartBadge: Locator;
  readonly cartLink: Locator;
  readonly burgerButton: Locator;
  readonly logoutLink: Locator;

  constructor(page: Page) {
    super(page);
    this.title = page.locator('[data-test="title"]');
    this.items = page.locator('[data-test="inventory-item"]');
    this.itemNames = page.locator('[data-test="inventory-item-name"]');
    this.itemPrices = page.locator('[data-test="inventory-item-price"]');
    this.sortDropdown = page.locator('[data-test="product-sort-container"]');
    this.cartBadge = page.locator('[data-test="shopping-cart-badge"]');
    this.cartLink = page.locator('[data-test="shopping-cart-link"]');
    this.burgerButton = page.getByRole('button', { name: 'Open Menu' });
    this.logoutLink = page.locator('[data-test="logout-sidebar-link"]');
  }

  async open(): Promise<void> {
    await this.goto('/inventory.html');
  }

  async expectLoaded(): Promise<void> {
    await expect(this.page).toHaveURL(/inventory\.html/);
    await expect(this.title).toHaveText('Products');
  }

  /** Add a product to the cart by its visible name. */
  async addItemToCart(name: string): Promise<void> {
    const id = name.toLowerCase().replace(/[^a-z0-9]+/g, '-');
    await this.page.locator(`[data-test="add-to-cart-${id}"]`).click();
  }

  async removeItemFromCart(name: string): Promise<void> {
    const id = name.toLowerCase().replace(/[^a-z0-9]+/g, '-');
    await this.page.locator(`[data-test="remove-${id}"]`).click();
  }

  async getCartCount(): Promise<number> {
    if ((await this.cartBadge.count()) === 0) return 0;
    return Number((await this.cartBadge.textContent())?.trim() ?? '0');
  }

  async goToCart(): Promise<void> {
    await this.cartLink.click();
  }

  async sortBy(option: SortOption): Promise<void> {
    await this.sortDropdown.selectOption(option);
  }

  async getItemNames(): Promise<string[]> {
    return (await this.itemNames.allTextContents()).map((t) => t.trim());
  }

  async getItemPrices(): Promise<number[]> {
    const raw = await this.itemPrices.allTextContents();
    return raw.map((p) => Number(p.replace('$', '').trim()));
  }

  async logout(): Promise<void> {
    await this.burgerButton.click();
    await this.logoutLink.click();
  }
}
