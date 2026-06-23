/**
 * Central catalogue of SauceDemo test users and shared data.
 * Keeping credentials in one typed place avoids magic strings in specs.
 */
export const PASSWORD = 'secret_sauce';

export const USERS = {
  standard: 'standard_user',
  lockedOut: 'locked_out_user',
  problem: 'problem_user',
  performanceGlitch: 'performance_glitch_user',
  error: 'error_user',
} as const;

export type UserKey = keyof typeof USERS;

/** Path where the standard_user authenticated session is stored. */
export const STORAGE_STATE = '.auth/standard_user.json';

/** Sample customer used by checkout specs. */
export const CHECKOUT_CUSTOMER = {
  firstName: 'Ada',
  lastName: 'Lovelace',
  postalCode: '94016',
} as const;
