# Price Engine Exposure Integration Enhancement - Plan & Progress Log

This plan connects company traits, commodity exposure, sector pressure, moats, and story facts to the price engine so top-down research produces observable market behavior.
**Status: complete - Tasks 1-5 complete.** Designed to run in a fresh session; everything needed to execute cold is in this file.

**Review verdict recap:** The top-down path only matters if researched facts affect returns. Existing market simulation already responds to macro, sector sentiment, events, broker pressure, quality, growth, and risk. This plan adds a controlled exposure resolver so company catalog and story facts can influence prices without turning the market into untestable noise.

## Where everything lives

| What | Where |
|---|---|
| Price simulation owner | `systems/MarketSimulator.gd` |
| Macro input | `systems/MacroStateSystem.gd`, `autoloads/RunState.gd` |
| Company data input | `systems/CompanyRosterGenerator.gd`, `data/companies/company_universe_catalog.json` |
| Exposure resolver | `systems/PriceExposureResolver.gd` |
| Event input | `systems/CompanyEventSystem.gd`, `systems/SpecialEventSystem.gd`, `systems/CorporateActionApplications.gd` |
| Thesis/reporting consumer | `systems/ThesisManager.gd`, `systems/ThesisReportSystem.gd` |
| Tests/probes | `scripts/tests/PriceExposureResolverContractTest.gd`, `scripts/tests/PriceExposureSimulationIntegrationTest.gd`, `scripts/tests/PriceExposureImpactProbeTest.gd`, `scripts/tests/MarketYearAudit.gd` |
| Key functions | Locate by `simulate_day`, `sector_sentiment`, event bias, and price weight constants |

## Goals

- Add a pure, deterministic exposure-impact resolver.
- Map commodity and macro signals to company-level price pressure through exposure fields.
- Make moats and risk traits modulate impact rather than act as flavor text.

## Non-goals

- Do not fully retune the whole price engine in this plan.
- Do not make every story a guaranteed winner.
- Do not change portfolio rules or trading UI.

## Working rules

- Price behavior changes need targeted probes before broad smoke.
- Keep effects bounded and easy to audit.
- Log enough metrics to explain why a stock moved in fixed-seed tests.
- Any new price inputs should have neutral defaults.

## Status

| # | Task | Est. cost | Status |
|---|---|---|---|
| 1 | Inventory existing price axes and choose integration points | ~10-15% | Complete |
| 2 | Define exposure-impact resolver contract | ~15-25% | Complete |
| 3 | Wire commodity and macro exposures into daily simulation | ~20-35% | Complete |
| 4 | Add targeted price impact probes | ~15-25% | Complete |
| 5 | Run and log long-run market audits | ~10-20% | Complete |

Recommended batching: **Session 1 = Tasks 1-2** because the resolver contract should be reviewed before price behavior changes. **Session 2 = Tasks 3-4**. **Task 5** should run after behavior looks reasonable.

## Progress log

### 2026-06-14 - Plan created

- Created this enhancement plan from the top-down market brainstorming session.
- Current inventory:
  - `MarketSimulator.gd` already applies macro, sector, event, broker, quality, growth, risk, volatility, and noise inputs.
  - Company exposure fields are not yet a first-class price input.
  - Commodity price integration should wait until commodity state and company exposure schema exist.
- No code or data changes were made by this planning step.

### 2026-06-14 - Task 1 complete

- Reviewed `systems/MarketSimulator.gd` around `simulate_day`, `_build_sector_sentiments`, `_resolve_event_context`, `_build_market_depth_context`, `_build_volume_activity_context`, and `_calculate_daily_change`.
- Current price engine already has these daily close inputs:
  - quality/growth/risk drift from company scores
  - negative baseline drift
  - broad market sentiment from random market swing plus macro market bias and special-event market shifts
  - sector sentiment from market sentiment, static sector trend/volatility, macro sector bias, and special-event sector bias
  - event bias from scheduled market/sector/company events, reports, special events, company arcs, roadmap events, corporate actions, index reviews, dirty tips, and gorengan overlays
  - broker net pressure
  - player market-impact depth pressure
  - volume/tape lead price bias, technical price bias, buying-exhaustion drag, distribution drag, gorengan campaign price bias, abnormal-move guards, momentum mean reversion, and noise
  - final close guards from scripted special events, player ARA/ARB pressure, auto-rejection limits, and abnormal-move supervision
- Current explicit close-weight constants:
  - `PRICE_QUALITY_EDGE_WEIGHT = 0.0032`
  - `PRICE_GROWTH_EDGE_WEIGHT = 0.002`
  - `PRICE_RISK_EDGE_WEIGHT = 0.0034`
  - `PRICE_BASELINE_DRIFT = -0.0014`
  - `PRICE_MARKET_SENTIMENT_WEIGHT = 0.45`
  - `PRICE_SECTOR_SENTIMENT_WEIGHT = 0.55`
  - `PRICE_EVENT_BIAS_WEIGHT = 0.8`
  - `PRICE_BROKER_PRESSURE_WEIGHT = 0.03`
  - `PRICE_NOISE_SCALE = 0.65`
  - `PRICE_MOMENTUM_MEAN_REVERSION = 0.16`
  - `PRICE_MOMENTUM_CAP = 0.015`
  - volatility multiplier clamp range `0.55-2.1`
- Chosen Task 2/3 integration point:
  - Add a pure exposure resolver first.
  - Feed resolver output into the per-company path after event context is known and before `_calculate_daily_change`.
  - Apply exposure as company-specific fields such as `exposure_drift_adjustment`, `exposure_volatility_multiplier`, `exposure_volume_multiplier`, `exposure_confidence`, and explainability rows.
  - Store the resolver output in `volume_context` and runtime snapshots for audits.
- Deliberately avoid these first-pass integration points:
  - Do not add exposure pressure to market sentiment; commodity and macro signals are company-specific once exposures are applied.
  - Do not add exposure pressure to sector sentiment first; macro sector bias already affects sectors and this would double-count sector-level pressure.
  - Do not fold exposure into event bias unless a future story/dossier event explicitly creates a company event.
  - Do not use exposure to bypass close guards, auto-rejection rules, abnormal-move supervision, or scripted special-event prices.
- Neutral defaults for missing exposure data:
  - `commodity_exposures = {}`
  - `macro_exposures = {}`
  - `price_traits = {}`
  - `moat_tags = []`
  - `exposure_drift_adjustment = 0.0`
  - `exposure_volatility_multiplier = 1.0`
  - `exposure_volume_multiplier = 1.0`
  - `exposure_confidence = 0.0`
  - `exposure_rows = []`
  - `exposure_summary = ""`
- Recommended initial bounds for Task 2 design:
  - daily drift adjustment clamp around `-0.004` to `0.004`
  - volatility multiplier clamp around `0.90` to `1.16`
  - volume multiplier clamp around `0.92` to `1.22`
  - confidence normalized `0.0-1.0`
- Moats and risk traits should modulate magnitude, not create standalone direction. Example: a positive commodity exposure with relevant moat tags may keep more of the benefit; weak balance sheet or high risk may amplify negative macro pressure.
- Verification:
  - `git diff --check`
  - No Godot run required because this task is documentation-only and does not change runtime behavior.

### 2026-06-14 - Task 2 complete

- Added `systems/PriceExposureResolver.gd` as a pure deterministic resolver.
- Resolver inputs:
  - company `commodity_exposures`, `macro_exposures`, `price_traits`, and `moat_tags`
  - macro state fields such as GDP growth, inflation, employment, policy rate/action, risk appetite, market bias, sector biases, and `commodity_indicators`
  - optional future story state through `story_signals` or `exposure_pressure`
- Resolver outputs:
  - `exposure_drift_adjustment`, clamped to `-0.004..0.004`
  - `exposure_volatility_multiplier`, clamped to `0.90..1.16`
  - `exposure_volume_multiplier`, clamped to `0.92..1.22`
  - `exposure_confidence`, normalized to `0.0..1.0`
  - explainability rows and summary fields for audit/debug use
- Neutral behavior is explicit: companies without exposure/story inputs return zero drift, `1.0` multipliers, empty rows, and `0.0` confidence.
- Moat and risk traits only modulate magnitude. They do not create direction without commodity, macro, or story signal rows.
- Runtime price behavior is unchanged; `MarketSimulator` does not consume the resolver until Task 3.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/PriceExposureResolverContractTest.tscn` -> `PRICE_EXPOSURE_RESOLVER_CONTRACT_OK {"inverse_drift":-0.00112565585452828,"laggard_drift":-0.000219175568612106,"laggard_id":"corn","leader_confidence":0.378657807642652,"leader_drift":0.0016476584072605,"leader_id":"crude_oil","leader_rows":3,"story_drift":0.00024}`
  - `/Users/user/.local/bin/godot --headless --path . --editor --quit`

### 2026-06-14 - Task 3 complete

- Wired `PriceExposureResolver` into `systems/MarketSimulator.gd`.
- Daily simulation now resolves exposure context per company after event/volume context is built and before `_calculate_daily_change`.
- Exposure context is stored in:
  - `runtime["price_exposure_context"]`
  - `runtime["volume_context"]["price_exposure_context"]`
  - flattened volume-context audit keys such as `exposure_drift_adjustment`, `exposure_volatility_multiplier`, `exposure_volume_multiplier`, `exposure_confidence`, `exposure_rows`, and exposure score fields
- `_calculate_daily_change(...)` now consumes:
  - bounded `exposure_drift_adjustment` as a small additive daily close input
  - bounded `exposure_volatility_multiplier` as a base-volatility/noise multiplier
- `exposure_volume_multiplier` is folded into `volume_context["volume_multiplier"]` and `expected_activity_ratio` with the existing volume clamps preserved.
- Procedural/default companies without exposure data remain neutral with zero drift, `1.0` exposure multipliers, empty rows, and unchanged exposure confidence.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/PriceExposureSimulationIntegrationTest.tscn` -> `PRICE_EXPOSURE_SIMULATION_INTEGRATION_OK {"calculation":{"delta":0.003,"neutral_change":-0.0014,"shifted_change":0.0016},"catalog":{"company_id":"surya_power_nusantara","confidence":0.257639713243543,"drift":0.0000453516266366198,"exposure_volume_multiplier":1.02766613732884,"rows":7,"volume_multiplier":1.9357633586049},"neutral":{"checked_companies":18}}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/PriceExposureResolverContractTest.tscn` -> `PRICE_EXPOSURE_RESOLVER_CONTRACT_OK ...`
  - `/Users/user/.local/bin/godot --headless --path . --editor --quit`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11 days=3 summary=Institution-led accumulation gave GLLA the cleanest tape today.`

### 2026-06-14 - Task 4 complete

- Added `scripts/tests/PriceExposureImpactProbeTest.gd` and `scenes/tests/PriceExposureImpactProbeTest.tscn`.
- Probe scenarios use controlled macro/commodity states and the real `MarketSimulator` exposure hooks with unrelated price axes neutralized.
- Covered four top-down cases:
  - coal rally: coal producer outperforms neutral, coal input consumer underperforms
  - CPO rally: plantation outperforms neutral, CPO input consumer underperforms
  - rate hike: rate beneficiary outperforms neutral, leveraged property underperforms
  - oil/fuel spike: oil producer outperforms neutral, fuel-cost carrier underperforms
- Probe output reports relative movement, leader-laggard spread, exposure summaries, and volatility/volume multipliers.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/PriceExposureImpactProbeTest.tscn` -> `PRICE_EXPOSURE_IMPACT_PROBE_OK {"scenario_count":4,...}`
  - Scenario spreads:
    - `coal_rally`: `0.00289953506817456`
    - `cpo_rally`: `0.00184783844041454`
    - `rate_hike`: `0.00136049193673886`
    - `oil_spike`: `0.00229808870288267`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/PriceExposureSimulationIntegrationTest.tscn` -> `PRICE_EXPOSURE_SIMULATION_INTEGRATION_OK ...`
  - `/Users/user/.local/bin/godot --headless --path . --editor --quit`

### 2026-06-14 - Task 5 complete

- Extended `scripts/tests/MarketYearAudit.gd` with catalog-run switches, portfolio metrics, audit elapsed time, price exposure stock-day telemetry, and optional compact-report output.
- Ran fixed-seed catalog-backed long-run audits for `120` and `225` trading days using seed `20260614`, normal difficulty, and `50` catalog companies.
- Saved the full audit history in `docs/development/test_log/2026-06-14_price_exposure_long_run_audit.md`.
- 120-day headline:
  - best stock `DCES` Data Center Estate at `261.60%`
  - worst stock `RASA` Rasa Kopi Nusantara at `-91.76%`
  - average return `-25.26%`, median return `-37.73%`
  - exposure telemetry covered `6,000` stock-days
- 225-day headline:
  - best stock `SWIT` Sawit Bumi Raya at `732.33%`
  - worst stock `KBLK` Kapal Bulk Sentosa at `-94.25%`
  - average return `19.25%`, median return `-59.90%`
  - exposure telemetry covered `11,250` stock-days
- Observed behavior:
  - positive-exposure stocks outperformed negative-exposure stocks over the 225-day run (`56.28%` vs `-5.43%` average return)
  - exposure remained bounded and did not override stronger systems such as gorengan campaigns, event pressure, quality/risk, and abnormal-move guards
  - no new script errors or assertion failures appeared beyond known Steam/headless warning noise
- Price Engine Exposure Integration is now complete as a bounded first-pass price-behavior foundation for the top-down market roadmap.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/MarketYearAudit.tscn -- --audit-seed 20260614 --audit-difficulty normal --audit-days 120 --audit-use-catalog --audit-company-count 50 --audit-compact-report`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/MarketYearAudit.tscn -- --audit-seed 20260614 --audit-difficulty normal --audit-days 225 --audit-use-catalog --audit-company-count 50 --audit-compact-report`

---

## Task 1 inventory - current price axes and chosen integration points

### Existing daily price flow

1. `simulate_day(...)` resolves the current macro state, attention directives, reports, corporate actions, roadmap events, company arcs, index reviews, and special events.
2. Market sentiment is sampled from fixed-seed daily market noise, then adjusted by `macro_state["market_bias"]` and special-event market shifts.
3. Sector sentiment is built from market sentiment, sector static bias/volatility, macro sector bias, and special-event sector bias.
4. Each company resolves event context, dirty-tip effects, gorengan campaign overlays, abnormal-move supervision, market depth, broker flow, volume/tape activity, and finally daily close movement.
5. The close is snapped through IDX tick/auto-rejection rules and can be overridden or guarded by scripted events, player depth impact, and abnormal-move controls.

### Existing direct close inputs

| Axis | Current source | Where it enters | Notes |
|---|---|---|---|
| Baseline drift | `PRICE_BASELINE_DRIFT` | `_calculate_daily_change` | Negative baseline keeps average stocks from floating upward without a reason. |
| Quality / growth / risk | Company scores | `_calculate_daily_change` | Quality and growth add drift; risk subtracts drift. |
| Market sentiment | Daily market RNG + macro market bias + special-event market shift | `_calculate_daily_change` through `market_sentiment` | Already captures broad macro direction. |
| Sector sentiment | Market sentiment + sector trend/volatility + macro/special sector bias | `_calculate_daily_change` through `sector_sentiment` | Already captures sector-level top-down pressure. |
| Event bias | Scheduled events, reports, special events, arcs, roadmaps, corporate actions, index reviews, dirty tips, gorengan overlays | `_calculate_daily_change` through `event_bias` | Strongest directional input. Keep story events here. |
| Broker pressure | `BrokerFlowSystem.generate_day_flow(...)` | `_calculate_daily_change` through `broker_pressure` | Modest directional input, also feeds tape/volume context. |
| Volume/tape pressure | `_build_volume_activity_context(...)` | `_calculate_daily_change` via `volume_context` | Includes lead bias, technical bias, exhaustion, distribution, campaign bias, and player impact. |
| Momentum | Recent price history | `_calculate_daily_change` | Mean-reverting component capped by `PRICE_MOMENTUM_CAP`. |
| Noise | Fixed-seed RNG and base volatility | `_calculate_daily_change` | Scaled by base volatility and event volatility. |
| Close guards | IDX rules, special scripts, player impact, abnormal supervisor | after raw daily change | Should remain downstream of exposure effects. |

### Chosen exposure integration point

The resolver should produce company-specific price context and feed it into the existing per-company path after event context is available and before `_calculate_daily_change`.

Preferred Task 3 path:

1. Resolve exposure context from:
   - `definition["commodity_exposures"]`
   - `definition["macro_exposures"]`
   - `definition["price_traits"]`
   - `definition["moat_tags"]`
   - `macro_state["commodity_indicators"]`
   - existing macro fields such as inflation, GDP, policy rate, employment, risk appetite, market bias, and sector biases
   - optional future story/dossier state
2. Add the output to `volume_context` with neutral-safe keys.
3. Let `_calculate_daily_change` consume:
   - `exposure_drift_adjustment`
   - `exposure_volatility_multiplier`
   - optional `exposure_volume_multiplier`
4. Store the same output in runtime snapshots so audits can explain why a stock moved.

This keeps exposure effects below market/sector sentiment and above close guards: strong enough to differentiate companies, but still bounded by current price rules.

### Avoided integration points

- Market sentiment: wrong level. Commodity exposure should not move every company equally after macro already sets market bias.
- Sector sentiment: too easy to double-count because `MacroStateSystem` already creates sector bias and commodity indicators also derive partly from sector bias.
- Event bias: reserve this for explicit story/event objects. Exposure is persistent sensitivity, not a one-day headline.
- Close override/auto-rejection: exposure should not bypass IDX price rules or scripted event controls.

### Neutral defaults

Companies without catalog exposure data must behave exactly like current companies:

| Field | Neutral value |
|---|---|
| `commodity_exposures` | `{}` |
| `macro_exposures` | `{}` |
| `price_traits` | `{}` |
| `moat_tags` | `[]` |
| `exposure_drift_adjustment` | `0.0` |
| `exposure_volatility_multiplier` | `1.0` |
| `exposure_volume_multiplier` | `1.0` |
| `exposure_confidence` | `0.0` |
| `exposure_rows` | `[]` |
| `exposure_summary` | `""` |

### First-pass sizing recommendation

- Drift adjustment: small daily additive pressure, initially clamped around `-0.004` to `0.004`.
- Volatility multiplier: modest shape control, initially clamped around `0.90` to `1.16`.
- Volume multiplier: evidence/audit hint only at first, initially clamped around `0.92` to `1.22`.
- Confidence: normalized `0.0-1.0`, based on exposure magnitude and signal strength.
- Moats/risk: magnitude modifiers only; they should not invent direction without a commodity, macro, or story signal.

## Task 1 - Inventory existing price axes and choose integration points

Problem: Exposure effects should fit the current price model rather than duplicate existing sentiment logic.

1. Document current price weights and inputs in this plan.
2. Identify where exposure pressure should enter: market, sector, company-specific drift, event bias, or volatility.
3. Choose neutral defaults for companies without exposure data.
4. Verify:
   - No code required unless adding comments or probes.
   - `git diff --check`

## Task 2 - Define exposure-impact resolver contract

Problem: Price exposure logic should be pure and testable.

1. Add or design a resolver that accepts company exposure data, macro state, commodity state, and story state.
2. Return bounded impacts such as drift adjustment, volatility adjustment, and confidence/explainability fields.
3. Keep the resolver independent from UI and content generation.
4. Verify:
   - Targeted unit/probe test for sample inputs.
   - Godot headless editor gate if code is added.

### Task 2 contract now in place

- `PriceExposureResolver.resolve(company_definition, macro_state, story_state = {})` is the contract entry point.
- Commodity rows are built from signed company commodity exposure against `macro_state["commodity_indicators"]`.
- Macro rows are built from signed macro exposure keys against normalized macro/sector signals.
- Story rows are optional and data-only so future dossier/story work can attach pressure without coupling the resolver to content generation.
- Unknown future macro keys resolve neutral by being skipped until explicitly mapped.

## Task 3 - Wire commodity and macro exposures into daily simulation

Problem: Exposure data needs to affect actual daily price outcomes.

1. Call the resolver from `MarketSimulator.gd` at a stable point in daily simulation.
2. Apply small bounded adjustments first.
3. Preserve behavior for companies without exposure data.
4. Verify:
   - Fixed-seed targeted scenario.
   - Quick smoke.

### Task 3 wiring now in place

- `MarketSimulator` keeps one resolver instance and calls it for each active company.
- The resolver output is applied below market/sector/event context and above close guards.
- Close guards, auto-rejection rules, player market-impact limits, abnormal-move guards, and scripted special-event overrides remain downstream of exposure effects.
- The first integration intentionally keeps story pressure optional and empty until a future story/dossier system provides structured story state.

## Task 4 - Add targeted price impact probes

Problem: The game needs proof that top-down signals create differentiated company outcomes.

1. Create scenarios such as coal rally vs coal producer, CPO rally vs plantation, rate hike vs leveraged property, and oil spike vs airline or logistics.
2. Report relative movement, volatility, and explanation fields.
3. Verify:
   - Probe output shows expected relative ranking.
   - `git diff --check`

### Task 4 probes now in place

- `PriceExposureImpactProbeTest` verifies expected relative rankings with deterministic synthetic scenarios.
- The probe calls the same resolver and `MarketSimulator` calculation hooks used by runtime wiring.
- Each scenario requires the exposed beneficiary to beat neutral and neutral to beat the exposed laggard.
- Each scenario requires at least a 10 bps leader-laggard spread.

## Task 5 - Run and log long-run market audits

Problem: Local price effects can pass while long-run market behavior becomes too extreme.

1. Run a 120-day and 225-day fixed-seed audit after integration.
2. Capture best/worst stocks, average movement, event counts, portfolio metrics if available, and runtime performance.
3. Save the result in `docs/development/test_log/`.
4. Verify:
   - `MarketYearAudit` or equivalent completes.
   - No new error spam beyond known warning noise.

## Known traps

- Price effects that are too strong will make the answer obvious and reduce research.
- Price effects that are too weak will make top-down research feel cosmetic.
- The same story should not be applied twice through sector sentiment and company exposure unless the double-count is intentional and tested.
