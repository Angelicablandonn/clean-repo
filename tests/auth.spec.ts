import { test, expect } from '../fixtures/pages.fixture.js';
import { USERS, PASSWORD } from '../utils/test-data.js';

/**
 * Auth specs deliberately do NOT reuse the stored session: each test drives
 * the login form directly so we exercise the real auth path, including
 * negative states. A fresh context per test keeps them isolated.
 */
test.describe('Login / Auth', () => {
  test.use({ storageState: { cookies: [], origins: [] } });

  test('standard_user logs in successfully', async ({ loginPage, inventoryPage }) => {
    await loginPage.open();
    await loginPage.login(USERS.standard);
    await inventoryPage.expectLoaded();
  });

  test('locked_out_user is blocked with an error message', async ({ loginPage }) => {
    await loginPage.open();
    await loginPage.login(USERS.lockedOut);
    await expect(loginPage.errorMessage).toBeVisible();
    expect(await loginPage.getErrorText()).toContain('locked out');
  });

  test('invalid credentials show an error', async ({ loginPage }) => {
    await loginPage.open();
    await loginPage.login('not_a_user', 'wrong_password');
    await expect(loginPage.errorMessage).toBeVisible();
    expect(await loginPage.getErrorText()).toContain(
      'Username and password do not match',
    );
  });

  test('empty username is rejected', async ({ loginPage }) => {
    await loginPage.open();
    await loginPage.login('', PASSWORD);
    expect(await loginPage.getErrorText()).toContain('Username is required');
  });

  test('user can log out', async ({ loginPage, inventoryPage }) => {
    await loginPage.open();
    await loginPage.login(USERS.standard);
    await inventoryPage.expectLoaded();
    await inventoryPage.logout();
    await expect(loginPage.loginButton).toBeVisible();
    await expect(loginPage.pageRef).toHaveURL('https://www.saucedemo.com/');
  });
});
