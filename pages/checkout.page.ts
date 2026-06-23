import { type Page, type Locator, expect } from '@playwright/test';
import { BasePage } from './base.page.js';

/**
 * Page object covering the 3-step checkout flow:
 * step one (customer info) -> overview -> complete.
 */
export class CheckoutPage extends BasePage {
  // Step one — customer information
  readonly firstName: Locator;
  readonly lastName: Locator;
  readonly postalCode: Locator;
  readonly continueButton: Locator;
  readonly errorMessage: Locator;

  // Step two — overview
  readonly finishButton: Locator;
  readonly summaryTotal: Locator;

  // Step three — confirmation
  readonly completeHeader: Locator;
  readonly backHomeButton: Locator;

  constructor(page: Page) {
    super(page);
    this.firstName = page.locator('[data-test="firstName"]');
    this.lastName = page.locator('[data-test="lastName"]');
    this.postalCode = page.locator('[data-test="postalCode"]');
    this.continueButton = page.locator('[data-test="continue"]');
    this.errorMessage = page.locator('[data-test="error"]');

    this.finishButton = page.locator('[data-test="finish"]');
    this.summaryTotal = page.locator('[data-test="total-label"]');

    this.completeHeader = page.locator('[data-test="complete-header"]');
    this.backHomeButton = page.locator('[data-test="back-to-products"]');
  }

  async fillCustomerInfo(first: string, last: string, zip: string): Promise<void> {
    await this.firstName.fill(first);
    await this.lastName.fill(last);
    await this.postalCode.fill(zip);
    await this.continueButton.click();
  }

  async finish(): Promise<void> {
    await this.finishButton.click();
  }

  async expectOrderComplete(): Promise<void> {
    await expect(this.page).toHaveURL(/checkout-complete\.html/);
    await expect(this.completeHeader).toHaveText(/Thank you for your order/i);
  }

  async getErrorText(): Promise<string> {
    return (await this.errorMessage.textContent())?.trim() ?? '';
  }
}
