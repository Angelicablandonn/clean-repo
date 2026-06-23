import { defineConfig, devices } from '@playwright/test';

/**
 * Playwright configuration for the Nuaav SauceDemo automation suite.
 *
 * Design notes:
 * - baseURL lets specs navigate with relative paths (page.goto('/')).
 * - We run two browser projects (Chromium + Firefox) plus a tiny "setup"
 *   project that authenticates once and writes a storageState file consumed
 *   by the browser projects. This avoids logging in inside every spec.
 * - Timeouts: defaults are mostly fine for SauceDemo, but the app ships a
 *   `performance_glitch_user` whose pages are artificially delayed, so we
 *   bump the per-action/navigation expectations slightly to keep those
 *   tests stable without masking genuine regressions.
 */
export default defineConfig({
  testDir: './tests',

  // Run every file in parallel and every test within a file in parallel.
  fullyParallel: true,

  // Fail the build on CI if test.only was left in the source by mistake.
  forbidOnly: !!process.env.CI,

  // One retry on CI to absorb transient network flakiness; none locally so
  // flakes surface immediately during development.
  retries: process.env.CI ? 1 : 0,

  // Limit workers on CI for stable, comparable runs; use all cores locally.
  workers: process.env.CI ? 2 : undefined,

  // HTML reporter satisfies the brief; "never" avoids auto-opening on CI.
  reporter: [['html', { outputFolder: 'playwright-report', open: 'never' }], ['list']],

  // Per-test timeout. Default is 30s; raised to 45s as the glitch user can
  // legitimately take ~5s+ per page load and we assert against that.
  timeout: 45_000,

  expect: {
    // Web-first assertion polling window.
    timeout: 10_000,
  },

  // Artifacts (screenshots, traces) land here per the brief.
  outputDir: 'test-results',

  use: {
    baseURL: 'https://www.saucedemo.com',

    // Built-in screenshot capture on failure. A custom hook is unnecessary
    // because Playwright already attaches these to the HTML report and
    // writes them into outputDir; rolling our own would just duplicate that.
    screenshot: 'only-on-failure',

    // Trace on first retry is the recommended cost/benefit balance: zero
    // overhead on green runs, full debugging context when something fails.
    trace: 'on-first-retry',

    actionTimeout: 15_000,
    navigationTimeout: 20_000,
  },

  projects: [
    // Authenticates once and persists session to .auth/standard_user.json.
    {
      name: 'setup',
      testMatch: /auth\.setup\.ts/,
    },

    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
      dependencies: ['setup'],
    },

    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
      dependencies: ['setup'],
    },
  ],
});
