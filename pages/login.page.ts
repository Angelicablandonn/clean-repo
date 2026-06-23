import { type Page, type Locator, expect } from '@playwright/test';
import { BasePage } from './base.page.js';
import { PASSWORD } from '../utils/test-data.js';

/** Page object for the SauceDemo login screen. */
export class LoginPage extends BasePage {
  readonly username: Locator;
  readonly password: Locator;
  readonly loginButton: Locator;
  readonly errorMessage: Locator;

  constructor(page: Page) {
    super(page);
    this.username = page.locator('[data-test="username"]');
    this.password = page.locator('[data-test="password"]');
    this.loginButton = page.locator('[data-test="login-button"]');
    this.errorMessage = page.locator('[data-test="error"]');
  }

  async open(): Promise<void> {
    await this.goto('/');
  }

  /** Fill credentials and submit. Does not assert on the result. */
  async login(user: string, password: string = PASSWORD): Promise<void> {
    await this.username.fill(user);
    await this.password.fill(password);
    await this.loginButton.click();
  }

  /** Convenience: log in and assert we landed on the inventory page. */
  async loginExpectingSuccess(user: string, password: string = PASSWORD): Promise<void> {
    await this.login(user, password);
    await expect(this.page).toHaveURL(/inventory\.html/);
  }

  async getErrorText(): Promise<string> {
    return (await this.errorMessage.textContent())?.trim() ?? '';
  }
}
