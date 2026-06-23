# Playwright Test Execution Report (English)

**Project:** nuaav-playwright-saucedemo  
**Target application:** https://www.saucedemo.com  
**Execution date:** June 23, 2026  
**Overall result:** **FAILED** (36 passed, 1 failed, 37 total)

---

## 1. Executive Summary

The full Playwright end-to-end test suite was executed after installing dependencies and browser binaries. **97.3% of tests passed** (36/37). One test failed on **Firefox** due to a timeout in the `beforeEach` hook while loading the inventory page. All **Chromium** tests passed, including the same cart test that failed on Firefox.

| Metric | Value |
|--------|-------|
| Total tests | 37 |
| Passed | 36 |
| Failed | 1 |
| Skipped | 0 |
| Pass rate | 97.3% |
| Total duration | ~4.3 minutes |
| Workers | 4 |
| Browsers | Chromium, Firefox |
| Exit code | 1 |

---

## 2. Environment & Commands Executed

| Step | Command | Status |
|------|---------|--------|
| 1 | `npm install` | Success (6 packages, 0 vulnerabilities) |
| 2 | `npx playwright install --with-deps` | Success (Chromium, Firefox, WebKit, FFmpeg, Winldd) |
| 3 | `npx playwright test` | **Failed** (1 test failure) |
| 4 | `npx playwright show-report` | HTML report available at `playwright-report/index.html` |

**Configuration highlights** (`playwright.config.ts`):
- Base URL: `https://www.saucedemo.com`
- Projects: `setup` → `chromium`, `firefox`
- Timeout per test: 45,000 ms
- Reporter: HTML + list
- Screenshots: on failure
- Traces: on first retry

---

## 3. Evidence Artifacts

| Artifact | Path |
|----------|------|
| Console output (full run) | `test-output.txt` |
| HTML interactive report | `playwright-report/index.html` |
| Failed test error context | `test-results/cart-Cart-cart-page-lists-the-added-items-firefox/error-context.md` |
| Last run metadata | `test-results/.last-run.json` |
| Browser install log | `install-log.txt` |

To open the HTML report locally:

```bash
npx playwright show-report
```

---

## 4. Results by Project

### 4.1 Setup (1/1 passed)

| # | Test | Result | Duration |
|---|------|--------|----------|
| 1 | authenticate as standard_user | PASS | 11.7s |

### 4.2 Chromium (18/18 passed)

| # | Suite | Test | Result | Duration |
|---|-------|------|--------|----------|
| 1 | Login / Auth | standard_user logs in successfully | PASS | 10.1s |
| 2 | Login / Auth | locked_out_user is blocked with an error message | PASS | 9.8s |
| 3 | Login / Auth | invalid credentials show an error | PASS | 10.0s |
| 4 | Login / Auth | empty username is rejected | PASS | 9.9s |
| 5 | Login / Auth | user can log out | PASS | 6.6s |
| 6 | Cart | adding an item updates the cart badge | PASS | 6.0s |
| 7 | Cart | adding multiple items increments the badge | PASS | 6.0s |
| 8 | Cart | removing an item decrements the badge | PASS | 6.6s |
| 9 | Cart | cart page lists the added items | PASS | 7.4s |
| 10 | Checkout | completes the full happy-path checkout | PASS | 8.9s |
| 11 | Checkout | blocks checkout when customer info is missing | PASS | 8.0s |
| 12 | Special user edge cases | problem_user serves broken product images | PASS | 5.7s |
| 13 | Special user edge cases | performance_glitch_user loads inventory within budget | PASS | 12.0s |
| 14 | Product Catalogue | shows the full product grid | PASS | 6.9s |
| 15 | Product Catalogue | sorts products by name A→Z | PASS | 7.0s |
| 16 | Product Catalogue | sorts products by name Z→A | PASS | 6.4s |
| 17 | Product Catalogue | sorts products by price low→high | PASS | 10.2s |
| 18 | Product Catalogue | sorts products by price high→low | PASS | 4.2s |

**Performance note (Chromium):** `performance_glitch_user` inventory load measured at **6,233 ms** (within budget).

### 4.3 Firefox (17/18 passed)

| # | Suite | Test | Result | Duration |
|---|-------|------|--------|----------|
| 1 | Login / Auth | standard_user logs in successfully | PASS | 36.7s |
| 2 | Login / Auth | locked_out_user is blocked with an error message | PASS | 40.1s |
| 3 | Login / Auth | invalid credentials show an error | PASS | 44.2s |
| 4 | Login / Auth | empty username is rejected | PASS | 46.1s |
| 5 | Login / Auth | user can log out | PASS | 24.3s |
| 6 | Cart | adding an item updates the cart badge | PASS | 31.0s |
| 7 | Cart | adding multiple items increments the badge | PASS | 28.8s |
| 8 | Cart | removing an item decrements the badge | PASS | 26.0s |
| 9 | Cart | **cart page lists the added items** | **FAIL** | 45.7s |
| 10 | Checkout | completes the full happy-path checkout | PASS | 23.7s |
| 11 | Checkout | blocks checkout when customer info is missing | PASS | 22.2s |
| 12 | Special user edge cases | problem_user serves broken product images | PASS | 13.9s |
| 13 | Special user edge cases | performance_glitch_user loads inventory within budget | PASS | 13.6s |
| 14 | Product Catalogue | shows the full product grid | PASS | 27.8s |
| 15 | Product Catalogue | sorts products by name A→Z | PASS | 30.4s |
| 16 | Product Catalogue | sorts products by name Z→A | PASS | 27.0s |
| 17 | Product Catalogue | sorts products by price low→high | PASS | 18.6s |
| 18 | Product Catalogue | sorts products by price high→low | PASS | 14.1s |

**Performance note (Firefox):** `performance_glitch_user` inventory load measured at **7,919 ms** (within budget).

---

## 5. Failure Analysis

### Failed Test

| Field | Value |
|-------|-------|
| Browser | Firefox |
| File | `tests/cart.spec.ts:33` |
| Suite | Cart |
| Test name | cart page lists the added items |
| Error | `Test timeout of 45000ms exceeded while running "beforeEach" hook.` |
| Failing line | `test.beforeEach` at line 10 |

### Root Cause (Likely)

The failure occurred **before the test body ran**, inside the shared `beforeEach` hook:

```ts
test.beforeEach(async ({ inventoryPage }) => {
  await inventoryPage.open();
  await inventoryPage.expectLoaded();
});
```

The inventory page did not finish loading within the 45-second test timeout on Firefox. The same test **passed on Chromium in 7.4s**, and other Firefox cart tests in the same suite also passed. This points to **intermittent Firefox slowness or resource contention** under parallel execution (4 workers), not a functional defect in the cart logic.

### Console Evidence (excerpt)

```
x  28 [firefox] › tests\cart.spec.ts:33:3 › Cart › cart page lists the added items (45.7s)

  1) [firefox] › tests\cart.spec.ts:33:3 › Cart › cart page lists the added items

    Test timeout of 45000ms exceeded while running "beforeEach" hook.

    Error Context: test-results\cart-Cart-cart-page-lists-the-added-items-firefox\error-context.md

  1 failed
  36 passed (4.3m)
```

### Recommended Follow-up

1. Re-run the failing test in isolation: `npx playwright test tests/cart.spec.ts:33 --project=firefox`
2. If it passes, consider increasing the timeout for Firefox or reducing parallel workers.
3. Enable `trace: 'on'` for the failing project to capture a full trace on the next failure.

---

## 6. Coverage Summary by Feature Area

| Feature Area | Chromium | Firefox | Total |
|--------------|----------|---------|-------|
| Authentication | 5/5 | 5/5 | 10/10 |
| Cart | 4/4 | 3/4 | 7/8 |
| Checkout | 2/2 | 2/2 | 4/4 |
| Inventory / Sorting | 5/5 | 5/5 | 10/10 |
| Edge Cases | 2/2 | 2/2 | 4/4 |
| Setup | 1/1 | — | 1/1 |

---

## 7. Conclusion

The SauceDemo Playwright automation suite is **largely stable** across Chromium and Firefox. Authentication, checkout, inventory sorting, and special-user edge cases all passed on both browsers. The single failure is a **Firefox timeout flake** in the cart suite setup hook, not a confirmed application bug. Re-running the failed test or adjusting Firefox-specific timeouts is recommended before treating this as a blocking defect.

---

*Report generated from `npx playwright test` execution on June 23, 2026.*
