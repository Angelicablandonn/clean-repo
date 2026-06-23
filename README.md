# Nuaav — Playwright Automation Suite (SauceDemo)

End-to-end test suite for [SauceDemo](https://www.saucedemo.com) built with
**Playwright + TypeScript**, using the Page Object Model, custom fixtures,
and a shared authenticated session.

---

## Prerequisites

- **Node.js** ≥ 18 (developed and verified on Node 22)
- Install dependencies and browsers:

```bash
npm install
npx playwright install --with-deps
```

---

## Running the tests

Run the full suite (both browser projects) from the repo root:

```bash
npx playwright test
```

Expected output (abridged): a `setup` project runs first to authenticate,
then specs execute across `chromium` and `firefox`, finishing with a green
summary such as `XX passed (Ys)` and a note that the HTML report was written
to `playwright-report/`.

### Run a single browser project

```bash
npx playwright test --project=chromium
npx playwright test --project=firefox
```

### Run a specific file

```bash
npx playwright test tests/checkout.spec.ts
```

### Run a single test by name

```bash
npx playwright test -g "completes the full happy-path checkout"
```

### View the HTML report

```bash
npx playwright show-report
```

Failure screenshots (built-in `screenshot: 'only-on-failure'`) and traces are
written to `test-results/` and attached to the HTML report automatically.

---

## Project structure

```
.
├── playwright.config.ts      # config: projects, timeouts, reporter, parallelism
├── fixtures/
│   └── pages.fixture.ts      # custom test.extend fixtures exposing page objects
├── pages/                    # Page Object Models
│   ├── base.page.ts
│   ├── login.page.ts
│   ├── inventory.page.ts
│   ├── cart.page.ts
│   └── checkout.page.ts
├── tests/
│   ├── auth.setup.ts         # logs in once, writes storageState
│   ├── auth.spec.ts          # login/logout + negative auth
│   ├── inventory.spec.ts     # catalogue + sorting
│   ├── cart.spec.ts          # add/remove + badge
│   ├── checkout.spec.ts      # full checkout flow
│   └── edge-cases.spec.ts    # problem_user + performance_glitch_user
├── utils/
│   └── test-data.ts          # users, password, shared data
└── README.md
```

---
