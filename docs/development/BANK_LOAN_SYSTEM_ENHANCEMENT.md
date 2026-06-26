# Bank Loan System Enhancement - Plan & Progress Log

Add regular player bank loans as a deliberate financing choice for grind-style runs. Unlike emergency loans, this should be a normal bank product sourced from bank companies in the current generated roster, with a lender selector and amount slider so the player can choose how much risk to take.

**Status: complete - Tasks 1-7 complete.** Designed to run in a fresh session; everything needed to execute cold is in this file.

**Review verdict recap:** Emergency loans already work as a rescue mechanic, but they are intentionally locked behind cash stress and should not become the regular funding loop. The company universe now contains bank-like finance companies, which creates a good opportunity to make bank loans feel tied to the current run instead of a generic menu button. The main implementation risk is mixing the new regular bank loan with `active_loan`, which would blur save state, UI copy, and existing emergency-loan smoke coverage.

## Where everything lives

| What | Where |
|---|---|
| Existing emergency loan state | `systems/LifeStateSystem.gd` - owns `active_loan` defaults and emergency-loan normalization |
| Existing emergency loan cash mutation | `autoloads/RunState.gd` - `apply_emergency_loan_proceeds`, `apply_life_loan_payment` |
| Existing finance snapshot | `autoloads/GameManager.gd` - `get_finance_status_snapshot`, `take_emergency_loan`, advance-day finance gates |
| Existing monthly payment hook | `systems/LifeManager.gd` - `apply_life_loan_payment_if_due` |
| Existing finance UI | `scripts/ui/widgets/LifeWidget.gd` - Finance tab, emergency-loan panel, active-loan display |
| Lender source data | `data/companies/company_universe_catalog.json` - current bank-like companies and finance subsectors |
| Regular loan contract owner | `systems/BankLoanSystem.gd` - deterministic lender discovery, offer terms, slider bounds, payment math |
| Saved state | `life_finance.active_bank_loan` - separate from emergency `active_loan` |
| UI nodes | `LifeBankLoanPanel`, `LifeBankLoanLenderSelector`, `LifeBankLoanAmountSlider`, `LifeBankLoanButton`, `LifeActiveBankLoanPanel` |
| Tests/probes | `scenes/tests/BankLoanOfferContractTest.tscn`, `scenes/tests/BankLoanLifecycleTest.tscn`, `scenes/tests/BankLoanLifeWidgetTest.tscn`, `scenes/tests/BankLoanBalanceProbeTest.tscn`, LifeWidget smoke additions |
| Key functions (line refs drift; locate by name) | `get_finance_status_snapshot`, `apply_emergency_loan_proceeds`, `apply_life_loan_payment`, `_refresh_finance_tab`, `apply_life_loan_payment_if_due` |

## Goals

- Let players take a regular bank loan before crisis, especially in grind-style runs where starting capital and cash runway are tight.
- Source loan offers from bank companies selected into the current run, so the lender has a real company name/ticker and can later connect to stories, news, and bank stock behavior.
- Provide an amount slider with deterministic min/max bounds instead of a fixed all-or-nothing loan amount.
- Keep the regular bank loan separate from emergency loans, both mechanically and in UI language.
- Add enough tests that loan offers, save/load, monthly payment, and buy-reserve gates cannot silently drift.

## Non-goals

- Do not replace or weaken the emergency loan system.
- Do not add margin lending, forced liquidation, collateral calls, or bank-company balance-sheet effects in the first pass.
- Do not make every finance company a lender. Insurance, brokerages, payment companies, and non-bank finance should be excluded unless explicitly whitelisted.
- Do not source lenders from the full 100-company catalog after the run starts. The lender should come from the current selected roster so it feels part of the run.
- Do not add a full banking app UI. First version belongs in the Life Finance tab.

## Working rules

- One task per checkpoint commit; verify before each commit.
- Keep the new regular bank loan state separate from emergency `active_loan`; use `active_bank_loan` or another explicit key.
- Save compatibility: add defaults and normalizer behavior before any UI consumes the state.
- Determinism: lender offers must derive from selected roster data, stable seed inputs, and current run state. Do not use ad hoc random calls.
- If a selected run has no bank-like lenders, the UI must explain that no regular bank loan is available. A later task can add a roster quota if fixed seeds need guaranteed lender availability.
- Gates:
  - `git diff --check`
  - `/Users/user/.local/bin/godot --headless -e --quit`
  - targeted bank-loan test scene(s)
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io`
- If editing JSON, also run: `python3 -m json.tool [path/to/file.json] > /dev/null`
- Long-run balance audits should wait until the lifecycle and UI are stable.

## Status

| # | Task | Est. cost | Status |
|---|---|---|---|
| 1 | Loan product contract and lender discovery | ~10-15% | Complete |
| 2 | Saved finance state and lifecycle API | ~15-20% | Complete |
| 3 | Monthly payment, reserve, and risk gates | ~15-20% | Complete |
| 4 | Life Finance UI with lender selector and amount slider | ~20-25% | Complete |
| 5 | Grind tuning and offer balance | ~10-15% | Complete |
| 6 | Targeted tests and smoke coverage | ~15-20% | Complete |
| 7 | Future hooks and documentation cleanup | ~5-10% | Complete |

Recommended batching: complete. The executed sequence was **Session 1 = Task 1**, **Session 2 = Tasks 2-3**, **Session 3 = Task 4**, and **Session 4 = Tasks 5-7** for tuning, durable coverage, and documentation cleanup.

## Progress log

### 2026-06-24 - Plan created

- Created this enhancement plan from the bank-loan brainstorm.
- Current inventory:
  - Emergency loan uses `life_finance.active_loan` and should remain a rescue-only product.
  - The company universe contains bank-like finance subsectors including `large_bank`, `mid_market_bank`, `small_bank`, `regional_bank`, `sharia_bank`, `digital_bank`, `trade_finance_bank`, and `micro_lending_bank`.
  - The Life Finance tab already has the natural UI home for loan controls.
- No runtime code or gameplay data changes were made by this planning step.

### 2026-06-24 - Task 1 complete

- Added pure `systems/BankLoanSystem.gd` with:
  - bank-lender subsector whitelist
  - deterministic selected-roster offer builder
  - subtype-based min/max principal, step size, payment count, repayment multiplier, monthly-rate label, risk tier, and disabled reason
  - regular-loan lock reasons for bankruptcy, existing active bank loan, and insufficient equity/outflow cap
- Added `scripts/tests/BankLoanOfferContractTest.gd` and `scenes/tests/BankLoanOfferContractTest.tscn`.
- The contract test proves:
  - bank-like companies become lenders
  - digital payments, consumer finance, insurance, and non-finance companies do not become lenders
  - offer ordering is deterministic
  - lower-risk bank subtypes have larger/cheaper offers than high-risk subtypes
  - disabled reasons remain explicit for locked cases
- No save-state, RunState, GameManager, payment, or UI behavior was changed.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/BankLoanOfferContractTest.tscn` -> `BANK_LOAN_OFFER_CONTRACT_OK`

### 2026-06-24 - Task 2 complete

- Added `life_finance.active_bank_loan` defaults and normalization in `systems/LifeStateSystem.gd`.
- Added `normalize_life_bank_loan` so malformed, paid, completed, zero-principal, zero-payment, or lenderless bank-loan rows normalize away from active state.
- Added `LifeStateSystem.start_bank_loan` for constructing regular bank-loan state and appending `bank_loan_started` finance history.
- Added RunState lifecycle APIs:
  - `get_active_bank_loan()`
  - `apply_bank_loan_proceeds(offer_id, principal, detail = {})`
  - `apply_bank_loan_payment(amount, detail = {})`
- Added distinct trade/history actions:
  - `life_bank_loan`
  - `life_bank_loan_payment`
  - `bank_loan_started`
  - `bank_loan_payment`
  - `bank_loan_paid`
- Added `scripts/tests/BankLoanLifecycleTest.gd` and `scenes/tests/BankLoanLifecycleTest.tscn`.
- The lifecycle test proves:
  - legacy saves backfill empty `active_bank_loan`
  - malformed and paid regular bank-loan states normalize away
  - loan proceeds increase cash and preserve lender identity
  - regular bank loans do not populate emergency `active_loan`
  - one active regular bank loan blocks a second
  - save/load preserves the active bank loan
  - payments reduce cash, decrement `payments_remaining`, and clear the active loan on completion
  - bankrupt runs reject new regular bank loans
- No monthly auto-payment hook, reserve gate, GameManager finance snapshot, or UI was changed; those remain Task 3 and Task 4.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/BankLoanLifecycleTest.tscn` -> `BANK_LOAN_LIFECYCLE_OK`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/BankLoanOfferContractTest.tscn` -> `BANK_LOAN_OFFER_CONTRACT_OK`
  - `/Users/user/.local/bin/godot --headless -e --quit` passed
  - `git diff --check` passed
  - Direct trailing-whitespace scan over the touched bank-loan files passed
  - Quick smoke was attempted but still failed on the existing FTUE organic-chain guard: `First-month smoke found more than 2 organic chains through day 25.`
  - `/Users/user/.local/bin/godot --headless -e --quit` passed
  - `git diff --check` passed
  - Direct trailing-whitespace scan over the touched bank-loan files passed
  - Quick smoke was attempted but failed on the existing FTUE organic-chain guard: `First-month smoke found more than 2 organic chains through day 25.` No bank-loan UI/monthly hook path is wired yet.

### 2026-06-24 - Task 3 complete

- Added `LifeManager.apply_bank_loan_payment_if_due`.
- Wired advance-day life processing to apply regular bank-loan payments on month boundaries after the emergency-loan payment hook.
- Added `life_bank_loan_payment` to `last_day_results` normalization so monthly regular bank-loan results persist separately from emergency `life_loan_payment`.
- Added `RunState.required_loan_payment_reserve(finance = {})`.
- Updated the buy gate to block new buys when combined emergency-plus-bank loan payment reserve is uncovered.
- Expanded `GameManager.get_finance_status_snapshot()` with:
  - `active_bank_loan`
  - `bank_loan_next_payment`
  - `bank_loan_payment_risky`
  - `total_required_loan_reserve`
  - `total_loan_payment_risky`
- Updated cash-stress buy/upgrade block messaging to use the combined loan reserve.
- Updated daily recap finance risk fields to include active regular bank loans.
- Extended `BankLoanLifecycleTest` to prove:
  - finance snapshots expose active regular bank loan and next payment
  - combined loan reserve equals the bank-loan monthly payment before emergency loans
  - buys are blocked when the bank-loan reserve is uncovered
  - the monthly bank-loan hook applies on a month boundary
  - `life_bank_loan_payment` is written to `last_day_results`
- No Life Finance UI was added; that remains Task 4.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/BankLoanLifecycleTest.tscn` -> `BANK_LOAN_LIFECYCLE_OK`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/BankLoanOfferContractTest.tscn` -> `BANK_LOAN_OFFER_CONTRACT_OK`

### 2026-06-24 - Task 4 complete

- Added `bank_loan_offers` to `GameManager.get_finance_status_snapshot()`.
- Added `GameManager.get_bank_loan_offers(finance_status = {})` so lender discovery stays sourced from the current run roster.
- Added `GameManager.take_bank_loan(offer_id, principal)` as the UI-safe entry point for selected lender and slider amount.
- Made the Life Finance tab scrollable and added a separate `Regular Bank Loan` panel with:
  - `LifeBankLoanLenderSelector`
  - `LifeBankLoanAmountSlider`
  - `LifeBankLoanAmountLabel`
  - `LifeBankLoanTermsLabel`
  - `LifeBankLoanButton`
- Added `LifeActiveBankLoanPanel` showing lender, principal, monthly payment, payments left, and reserve warning.
- The regular bank-loan button now locks for bankruptcy, no selected-run bank lender, an existing regular bank loan, locked offers, or invalid amount.
- Added `scripts/tests/BankLoanLifeWidgetTest.gd` and `scenes/tests/BankLoanLifeWidgetTest.tscn`.
- The UI test proves:
  - the Life Finance regular bank-loan panel exists
  - the lender selector lists current-run bank lenders
  - the amount slider is editable before borrowing
  - the button creates an active regular bank loan
  - the active regular bank-loan panel becomes visible after borrowing
  - the button locks after borrowing
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/BankLoanLifeWidgetTest.tscn` -> `BANK_LOAN_LIFE_WIDGET_OK`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/BankLoanLifecycleTest.tscn` -> `BANK_LOAN_LIFECYCLE_OK`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/BankLoanOfferContractTest.tscn` -> `BANK_LOAN_OFFER_CONTRACT_OK`
  - `/Users/user/.local/bin/godot --headless -e --quit` passed
  - `git diff --check` passed
  - Direct trailing-whitespace scan over the touched Task 4 files passed
  - Quick smoke was attempted but still failed on the existing FTUE organic-chain guard: `First-month smoke found more than 2 organic chains through day 25.`

### 2026-06-24 - Task 5 complete

- Rebalanced `systems/BankLoanSystem.gd` around monthly payment burden instead of the older raw `outflow_months` cap.
- Added difficulty balance profiles:
  - conservative/default modes use lower cap and lower default slider target
  - grind mode uses higher equity cap and higher payment-burden tolerance
  - hard mode sits between normal and grind
- Replaced the previous high minimum principal formula with a difficulty-aware minimum, so grind-start borrowers are not accidentally locked out by default Life outflow.
- Added offer-level balance telemetry:
  - `total_repayment_at_max`
  - `monthly_payment_at_max`
  - `payment_burden_pct_at_default`
  - `payment_burden_pct_at_max`
  - `max_payment_burden_pct`
  - `balance_note`
- Updated the Life Finance regular bank-loan terms line to show monthly payment as a percentage of monthly outflow.
- Added `scripts/tests/BankLoanBalanceProbeTest.gd` and `scenes/tests/BankLoanBalanceProbeTest.tscn`.
- The fixed grind probe proves:
  - a selected-run roster with a bank lender exposes at least one eligible offer
  - grind-mode max principal is useful versus Rp10m starting cash
  - grind-mode cap is higher than normal mode for the same lender
  - the max loan creates visible but bounded monthly payment burden
  - borrowing through `GameManager.take_bank_loan` exposes `bank_loan_next_payment` and `total_required_loan_reserve`
- Current fixed grind probe result:
  - lender: `BNRY`
  - default principal: `Rp6.0m`
  - max principal: `Rp11.0m`
  - max monthly payment: about `Rp1.19m`
  - max burden: about `14%` of default monthly outflow
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/BankLoanBalanceProbeTest.tscn` -> `BANK_LOAN_BALANCE_PROBE_OK`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/BankLoanOfferContractTest.tscn` -> `BANK_LOAN_OFFER_CONTRACT_OK`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/BankLoanLifecycleTest.tscn` -> `BANK_LOAN_LIFECYCLE_OK`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/BankLoanLifeWidgetTest.tscn` -> `BANK_LOAN_LIFE_WIDGET_OK`
  - `/Users/user/.local/bin/godot --headless -e --quit` passed
  - `git diff --check` passed
  - Direct trailing-whitespace scan over the touched Task 5 files passed
  - Quick smoke was attempted but still failed on the existing FTUE organic-chain guard: `First-month smoke found more than 2 organic chains through day 25.`

### 2026-06-24 - Task 6 complete

- Kept the targeted test suite from earlier tasks as the feature-specific coverage set:
  - `BankLoanOfferContractTest.tscn`
  - `BankLoanLifecycleTest.tscn`
  - `BankLoanLifeWidgetTest.tscn`
  - `BankLoanBalanceProbeTest.tscn`
- Extended the existing Life smoke coverage in `scripts/tests/SmokeTest.gd`.
- Quick Life smoke now validates the regular bank-loan Finance UI nodes exist:
  - `LifeBankLoanPanel`
  - `LifeBankLoanLenderSelector`
  - `LifeBankLoanAmountSlider`
  - `LifeBankLoanAmountLabel`
  - `LifeBankLoanTermsLabel`
  - `LifeBankLoanButton`
  - `LifeActiveBankLoanPanel`
- Full Life smoke now attempts a small regular bank loan when the generated selected roster has an eligible bank lender:
  - switches to the Life Finance tab
  - selects the eligible lender offer
  - moves the amount slider to the minimum principal
  - presses `Take Bank Loan`
  - confirms active bank-loan state and next-payment snapshot
  - confirms the active bank-loan panel appears
  - restores the pre-probe RunState before continuing the longer Life smoke
- No separate test-log file was added because this task added coverage without changing player-facing balance.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/BankLoanOfferContractTest.tscn` -> `BANK_LOAN_OFFER_CONTRACT_OK`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/BankLoanLifecycleTest.tscn` -> `BANK_LOAN_LIFECYCLE_OK`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/BankLoanLifeWidgetTest.tscn` -> `BANK_LOAN_LIFE_WIDGET_OK`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/BankLoanBalanceProbeTest.tscn` -> `BANK_LOAN_BALANCE_PROBE_OK`
  - `/Users/user/.local/bin/godot --headless -e --quit` passed
  - `git diff --check` passed
  - Direct trailing-whitespace scan over the touched Task 6 files passed
  - Quick smoke was attempted but still failed before Life smoke on the existing FTUE organic-chain guard: `First-month smoke found more than 2 organic chains through day 25.`

### 2026-06-24 - Task 7 complete

- Documented the regular bank-loan future hooks in this file.
- Added the bank-loan enhancement doc to `PROJECT_HANDOFF.md` recent docs.
- Added the regular bank-loan code/test entry points to `PROJECT_HANDOFF.md` under Life / Wealth Progression.
- Decided not to force a guaranteed bank lender in every selected roster yet:
  - current company universe has multiple bank-like companies
  - the UI already handles no-lender runs with explicit copy
  - a grind-only roster quota can be added later if playtests show too many no-lender starts
- No player-facing manual/docs update was needed because this is an in-development feature without a shipped player manual.
- Verification:
  - `rg "BANK_LOAN_SYSTEM_ENHANCEMENT" PROJECT_HANDOFF.md docs/development` passed
  - `git diff --check` passed
  - Direct trailing-whitespace scan over the touched Task 7 docs passed

## Future Hooks

These are deliberately deferred so the first version stays understandable and testable.

- Bank stock sentiment: if the lender is a listed company in the current run, future content can mention player borrowing as a small public/private banking relationship. This should not move the lender stock by itself until the event/content source is player-visible.
- Bank-specific events and offer terms: liquidity squeeze, deposit-cost pressure, regulatory action, or bank-specific stress can later tighten `max_principal`, increase `repayment_multiplier`, or disable one lender without disabling every regular bank loan.
- Refinancing: allow replacing an active regular bank loan with a new offer only if the UI explains total repayment, remaining balance, fees, and monthly payment delta. This needs exploit checks before implementation.
- Early repayment: allow paying off the remaining balance from cash, probably with no discount in v1 and an optional small fee later. It should clear `active_bank_loan` through the same normalizer path used by scheduled completion.
- Late fees/defaults: defer until the game has clear warning copy and consequence UI. First-pass missed payments should continue flowing through existing cash-stress/bankruptcy systems.
- Multiple loan products: possible later products include working-capital loan, secured asset loan, bridge loan, and margin loan. Margin/collateral products should be separate from the current regular bank-loan state because forced liquidation is a different risk model.
- Bank-lender roster quota: keep optional. If grind-mode starts often roll no bank lender, add a deterministic `CompanyRosterGenerator` quota for one eligible bank company and extend `CompanyUniverseSelectionFingerprintTest` plus `BankLoanBalanceProbeTest`.

---

## Task 1 - Loan Product Contract And Lender Discovery

Problem: The game needs a deterministic way to identify which selected companies can lend to the player and what terms they offer, without touching saved state yet.

1. Add a small pure `systems/BankLoanSystem.gd`.
2. Implement `is_bank_lender(company: Dictionary) -> bool` using an explicit subsector whitelist:
   - `banking`
   - `large_bank`
   - `mid_market_bank`
   - `small_bank`
   - `regional_bank`
   - `sharia_bank`
   - `digital_bank`
   - `trade_finance_bank`
   - `micro_lending_bank`
3. Implement `build_lender_offers(selected_companies, run_context, finance_snapshot) -> Array`.
4. Each offer should include:
   - `lender_id`, `lender_ticker`, `lender_name`, `lender_subsector`
   - `min_principal`, `max_principal`, `step_size`
   - `payment_count`, `repayment_multiplier`, `monthly_rate_label`
   - `risk_tier`, `approval_reason`, `disabled_reason`
5. Keep first-pass terms simple and deterministic by subsector:
   - large/regional banks: lower multiplier, lower max risk
   - mid-market/trade-finance banks: balanced terms
   - small/digital/micro banks: higher cap or higher approval flexibility, higher repayment multiplier
6. Verify:
   - Targeted contract test proves only bank-like selected companies become lenders.
   - Contract test proves offer order and terms are stable for the same seed/context.
   - `git diff --check`
   - Godot headless editor gate.

## Task 2 - Saved Finance State And Lifecycle API

Problem: Regular loans need saved lifecycle state without colliding with emergency loan state.

1. Add `active_bank_loan` to the Life finance default state.
2. Add normalizer behavior for missing, malformed, completed, and active bank-loan dictionaries.
3. Add RunState APIs:
   - `apply_bank_loan_proceeds(offer_id, principal, detail = {})`
   - `apply_bank_loan_payment(amount, detail = {})`
   - `get_active_bank_loan()`
4. Loan state should include:
   - `id`
   - `type: "regular_bank_loan"`
   - `lender_id`, `lender_ticker`, `lender_name`, `lender_subsector`
   - `principal`, `total_repayment`, `monthly_payment`
   - `payment_count`, `payments_remaining`, `amount_paid`
   - `start_day_index`, `start_trade_date`, `last_payment_period`
   - `state`
5. Record trade/history rows with a distinct action such as `life_bank_loan` and `life_bank_loan_payment`.
6. Verify:
   - Targeted lifecycle probe takes a loan, increases cash, saves active state, reloads state, and preserves lender identity.
   - Emergency `active_loan` remains untouched.
   - `git diff --check`
   - Godot headless editor gate.

## Task 3 - Monthly Payment, Reserve, And Risk Gates

Problem: The loan must become real risk, not free capital.

1. Add monthly payment application for `active_bank_loan`, ideally adjacent to the existing emergency-loan monthly hook.
2. Buy reserve gating should consider the sum of next emergency-loan and bank-loan payments.
3. Advance-day finance gate should report bank-loan payment failures separately from emergency-loan failures.
4. If cash cannot cover the payment, first version should allow cash stress/bankruptcy systems to handle the consequence rather than adding a new default state.
5. Optional in this task if small: add manual early repayment API; otherwise defer to Task 7.
6. Verify:
   - Targeted lifecycle test advances across a month boundary and applies one bank-loan payment.
   - Targeted reserve test blocks new buys when cash cannot cover upcoming required loan payments.
   - Existing emergency-loan payment test still passes.
   - `git diff --check`
   - quick smoke.

## Task 4 - Life Finance UI With Lender Selector And Amount Slider

Problem: The player needs a clear, controlled way to borrow from a chosen bank company.

1. Add a new regular bank-loan panel in the Life Finance tab, separate from the Emergency Loan panel.
2. Add a lender selector showing company ticker/name and short term summary.
3. Add an amount slider:
   - min = offer `min_principal`
   - max = offer `max_principal`
   - step = offer `step_size`
   - displayed label updates with principal, total repayment, monthly payment, and payment count.
4. Add a "Take Bank Loan" button that is disabled when:
   - bankrupt
   - no eligible bank lender in selected roster
   - active regular bank loan already exists
   - selected amount is invalid
5. Add an active regular bank-loan panel with lender, principal, monthly payment, payments left, and reserve warning.
6. Keep copy direct:
   - "Regular Bank Loan"
   - "Lender"
   - "Amount"
   - "Monthly payment"
   - "Payments left"
7. Verify:
   - UI smoke finds the panel, selector, slider, button, and active state after taking a test loan.
   - Existing `LifeEmergencyLoanButton` tests still pass.
   - `git diff --check`
   - quick smoke.

## Task 5 - Grind Tuning And Offer Balance

Problem: Loans should make grind starts viable and more tense, not trivial.

1. Tune max principal around player equity, monthly outflow, difficulty/start mode, and lender tier.
2. Recommended first-pass caps:
   - conservative/default mode: lower cap, lower multiplier
   - grind mode: higher cap, but with meaningful monthly payment drag
   - bankrupt/cash-stress state: regular loans locked; emergency loan remains the rescue product
3. Avoid letting bank loans fully solve the game:
   - cap total active regular loan to a fraction of equity or gross portfolio
   - require monthly payments to be coverable in normal runway estimates
   - one active regular loan at a time
4. Add snapshot fields that make balance visible in tests:
   - `bank_loan_offers`
   - `active_bank_loan`
   - `bank_loan_next_payment`
   - `total_required_loan_reserve`
5. Verify:
   - Fixed seed probe reports at least one eligible lender if the selected roster contains bank companies.
   - Grind-mode probe can borrow a useful amount but still has visible payment risk.
   - `git diff --check`
   - quick smoke.

## Task 6 - Targeted Tests And Smoke Coverage

Problem: This feature touches save state, cash mutation, month boundaries, and UI, so a single broad smoke is not enough.

1. Add `BankLoanOfferContractTest.tscn`:
   - selected roster with mixed finance/non-finance companies
   - deterministic lender discovery
   - stable terms by lender subtype
2. Add `BankLoanLifecycleTest.tscn`:
   - take loan
   - cash increases
   - active state normalizes
   - save/load preserves lender identity
   - monthly payment reduces cash and payments remaining
   - completion clears `active_bank_loan`
3. Extend existing SmokeTest only after targeted tests are stable:
   - open Life Finance
   - confirm regular bank-loan panel exists
   - if a lender is available, move slider and take a small loan
4. Add a compact test log only if the behavior balance changes materially.
5. Verify:
   - targeted tests
   - `git diff --check`
   - Godot headless editor gate
   - quick smoke.

## Task 7 - Future Hooks And Documentation Cleanup

Problem: The first pass should leave room for richer bank-company integration without overbuilding it immediately.

1. Document future hooks:
   - bank stock sentiment if player borrows from a listed bank
   - bank-specific events affecting future offer terms
   - refinancing
   - early repayment
   - late fees
   - multiple loan products
2. Decide whether selected roster generation should guarantee at least one bank lender for grind mode.
3. Add `PROJECT_HANDOFF.md` links if the feature ships.
4. Update any relevant player-facing docs or internal feature map.
5. Verify:
   - `rg "BANK_LOAN_SYSTEM_ENHANCEMENT" PROJECT_HANDOFF.md docs/development`
   - `git diff --check`

## Known traps

- Do not reuse emergency `active_loan` for regular bank loans. Existing UI copy, tests, and payment logic assume it means emergency loan.
- Do not make the bank loan available from every finance company. Payment processors, brokerages, insurance companies, and consumer finance companies need separate design before they become lenders.
- Do not source lenders from unselected catalog companies unless the player can also see those companies in the run.
- Do not let the slider max use only cash need. It should also consider equity, monthly outflow, lender tier, and difficulty/start mode.
- Do not add multiple active regular loans in the first pass; that complicates save state, reserve gates, and UI.
- LifeWidget smoke tests reference specific node names. Add new node names without renaming emergency-loan nodes.
- Monthly boundary behavior already exists for emergency loans. Reuse that rhythm where possible instead of adding a parallel daily timer.
