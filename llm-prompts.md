# LLM Prompts Used

This file documents how I used an LLM (Claude) during this exercise, per the
brief. The goal is to show how AI output was directed and validated, not to
hand off engineering judgement.

## How I used the LLM

I used the LLM as a fast scaffolding and review partner, then validated every
output by running the suite against the live SauceDemo app and inspecting the
generated artifacts (HTML report, screenshots, storageState file).

## Prompts

### 1. Project scaffold
> "Generate a Playwright + TypeScript project structure targeting SauceDemo
> with a Page Object Model layout, a config with Chromium and Firefox
> projects, screenshot-on-failure, an HTML reporter, fullyParallel, and a
> storageState-based auth setup. Give me the directory tree first."

**Validation:** Reviewed the proposed tree against the brief's Task A
checklist; removed an over-engineered custom screenshot hook the model
initially suggested because Playwright's built-in `screenshot: 'only-on-failure'`
already covers the requirement.

### 2. Selectors
> "What are the stable selectors on SauceDemo's login, inventory, cart and
> checkout pages?"

**Validation:** Did not trust this blindly — confirmed every `data-test`
attribute by running the tests and letting failures surface any mismatch
(e.g. confirmed `add-to-cart-sauce-labs-backpack` slug format empirically).

### 3. Performance threshold reasoning
> "Suggest a defensible acceptable-load threshold for performance_glitch_user
> and explain the trade-off between false failures and missing regressions."

**Validation:** Kept the reasoning but chose the final 10s number myself after
observing actual load times during local runs.

### 4. README design-notes review
> "Review this README design-decisions section for clarity and flag anything
> that overstates what the suite does."

**Validation:** Edited the output down; removed claims about coverage the
suite doesn't actually implement.

## What I rejected

- A custom screenshot fixture (redundant with the built-in option).
- CSS/text selectors the model guessed for elements that actually expose
  `data-test` hooks — `data-test` is more stable.
- An overly high 30s glitch-user timeout that would have hidden regressions.
