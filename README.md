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
├── llm-prompts.md
└── README.md
```

---

## Design decisions

**POM structure.** Each page exposes intent-revealing methods (`login`,
`addItemToCart`, `fillCustomerInfo`) over a set of locators, so specs read as
business steps rather than CSS. A small `BasePage` holds the `Page` handle and
a `goto` helper. Page objects are injected into specs through custom
`test.extend` fixtures, which keeps specs free of constructor boilerplate and
lets Playwright manage the page lifecycle.

**Test isolation.** Every test runs in its own browser context, so cart and
session state never leak between tests. Auth-specific specs explicitly start
from an empty session (`storageState: { cookies: [], origins: [] }`) to
exercise the real login path, while catalogue/cart/checkout specs reuse a
session captured once by `auth.setup.ts` and stored in `.auth/`. This gives
both correctness (negative auth tested honestly) and speed (one login, not
one-per-test). `fullyParallel: true` runs files and tests concurrently.

**Trade-offs.** I rely on SauceDemo's stable `data-test` attributes rather
than fragile CSS/text selectors. I used the built-in screenshot option instead
of a custom hook because it already meets the requirement and writes to the
output directory — a custom hook would only add maintenance cost. Given the
time box I prioritised broad core coverage (auth, catalogue, cart, checkout)
plus targeted edge cases over exhaustive permutations. **Next steps if I had
more time:** add `error_user` checkout error-handling scenarios, visual
assertions for `problem_user`, and API-level cart seeding to speed setup.

---

## Onboarding a Junior Engineer

If I were bringing a junior engineer onto this suite, I would start with a
guided read-through of the layered architecture: how a spec depends only on
page objects and fixtures, never on raw selectors, and why that boundary
matters for maintainability. I would have them trace one full flow — the
happy-path checkout — from spec, through the fixtures, down into each page
object, so the dependency direction becomes concrete before they write any
code. Their first task would be a small, well-scoped addition (for example, a
new sort assertion) so they practise the pattern without touching shared
infrastructure.

For documentation, I would add a short CONTRIBUTING guide covering the naming
conventions, the rule that all new locators use `data-test` attributes, and a
checklist for adding a new page object. I would also document how to run a
single test and read the HTML report and traces, because fast local debugging
is what keeps people productive.

The most important thing I would teach early is **test data hygiene in a shared
public environment**. SauceDemo is reset per session and state lives in the
browser context, so the key discipline is: never assume a clean global state,
always isolate via fresh contexts, and never hard-code assumptions about
ordering or counts that another concurrent run could disturb. I would have them
treat each test as fully self-provisioning — add what it needs, assert, and let
context teardown clean up — rather than depending on side effects from other
tests. Finally, I would pair-review their first few PRs, focusing less on
syntax and more on isolation and whether assertions would survive parallel
execution.
