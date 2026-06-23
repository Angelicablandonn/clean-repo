import { type Page } from '@playwright/test';

/**
 * Common behaviour shared by every page object: holds the Page handle and
 * exposes a thin navigation helper. Concrete pages extend this.
 */
export abstract class BasePage {
  constructor(protected readonly page: Page) {}

  /** Public read-only access to the underlying Page for spec-level assertions. */
  get pageRef(): Page {
    return this.page;
  }

  /** Navigate to a path relative to baseURL. */
  async goto(path = '/'): Promise<void> {
    await this.page.goto(path);
  }
}
