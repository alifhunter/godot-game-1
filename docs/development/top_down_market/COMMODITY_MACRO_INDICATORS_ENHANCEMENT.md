# Commodity Macro Indicators Enhancement - Plan & Progress Log

This plan adds commodity prices and regimes as macro indicators so the top-down path can start from drivers like coal, crude oil, CPO, nickel, gold, copper, and gas.
**Status: complete - Tasks 1-5 complete.** Designed to run in a fresh session; everything needed to execute cold is in this file.

**Review verdict recap:** Commodity prices are a strong fit for macro because they connect global stories to sectors and companies. They should start as indicators, not tradable assets. The first implementation must create deterministic commodity state and expose it to sector/company systems without immediately retuning the whole price engine.

## Where everything lives

| What | Where |
|---|---|
| Macro state owner | `systems/MacroStateSystem.gd` |
| Runtime macro state | `autoloads/RunState.gd` yearly macro state and daily market inputs |
| Commodity catalog | `data/macro/commodity_indicator_catalog.json` |
| Price consumer | `systems/MarketSimulator.gd` |
| Company exposure consumer | Planned company catalog exposure fields |
| Thesis consumer | `systems/ThesisManager.gd`, `systems/ThesisVocabulary.gd` |
| Tests/probes | `scripts/tests/CommodityMacroStateProbeTest.gd`, `scripts/tests/CommodityMacroSaveDefaultsTest.gd`, `scripts/tests/CommodityMacroEvidenceContractTest.gd`, `scripts/tests/CommodityMacroFingerprintTest.gd`, and later price audit |
| Key functions | Locate by `build_year_state`, `market_bias`, `sector_biases`, and macro state normalizers |

## Goals

- Add deterministic commodity indicators to macro state.
- Make commodity regimes available to sector, company, thesis, and future content systems.
- Keep the first pass compatible with existing saves and simulations.

## Non-goals

- Do not make commodities tradable in the first pass.
- Do not add full futures, inventory, shipping, or FX models.
- Do not retune price behavior until exposure integration owns that change.

## Working rules

- Commodity state must be deterministic by run seed and year/day.
- Save compatibility defaults must fill missing commodity state on old saves.
- Keep commodity values normalized enough that price integration can use them later.
- Run long audits only after commodity state affects price behavior.

## Status

| # | Task | Est. cost | Status |
|---|---|---|---|
| 1 | Define commodity catalog and value model | ~10-20% | Complete |
| 2 | Extend macro state with commodity regimes | ~15-25% | Complete |
| 3 | Add save/default normalization | ~10-20% | Complete |
| 4 | Expose commodity evidence to thesis/content contracts | ~10-20% | Complete |
| 5 | Add deterministic commodity tests | ~10-20% | Complete |

Recommended batching: **Session 1 = Tasks 1-2** because the data shape and generator should be reviewed together. **Tasks 3-5** can follow once state shape is settled.

## Progress log

### 2026-06-14 - Plan created

- Created this enhancement plan from the top-down market brainstorming session.
- Current inventory:
  - Macro state already includes inflation, GDP, employment, policy rate, risk appetite, volatility multiplier, market bias, and sector biases.
  - No commodity indicator state is tracked yet.
  - Commodity prices should start as macro inputs, not tradable assets.
- No code or data changes were made by this planning step.

### 2026-06-14 - Task 1 complete

- Design decision: commodity indicators start as catalog-backed macro inputs, not tradable assets and not direct price movers.
- First catalog location: `data/macro/commodity_indicator_catalog.json`.
- Catalog entries define stable ids, display labels, categories, normalized index bounds, volatility defaults, year-to-date movement bounds, regime thresholds, direction thresholds, macro drivers, and related sectors.
- Generated yearly state shape for Task 2 should use:
  - `level`: normalized current commodity index level, neutral at `100`
  - `direction`: one of `falling`, `softening`, `flat`, `firming`, `rising`
  - `volatility`: normalized annual volatility hint
  - `regime`: one of `bear`, `soft`, `neutral`, `firm`, `bull`
  - `ytd_move`: normalized year-to-date move in percent-like units
- Daily index values are deferred. Task 2 should generate yearly state first, with optional daily projection later if price/content systems need it.
- Added 25 commodity definitions. They cover every current `commodity_exposures` key used by `data/companies/company_universe_catalog.json`.
- `gold`, `rare_earth`, and `silica` were added as roadmap/future exposure definitions first and are now used by the expanded company catalog.
- Runtime behavior stayed intentionally unchanged. `MacroStateSystem`, `RunState`, and `MarketSimulator` do not consume this catalog yet.
- Verification:
  - `python3 -m json.tool data/macro/commodity_indicator_catalog.json > /tmp/commodity_indicator_catalog.json.check`
  - Catalog coverage probe after company catalog expansion: `commodityCount=25`, `exposureKeyCount=25`, `missing=[]`, `duplicates=[]`, `extraDefinitions=[]`
  - `git diff --check`

### 2026-06-14 - Task 2 complete

- Added commodity catalog loading to `DataRepository`.
- `DataRepository` now exposes:
  - `get_commodity_indicator_catalog()`
  - `get_commodity_indicator_definitions()`
- Extended `MacroStateSystem.build_year_state(...)` with an optional `commodity_indicator_catalog` argument.
- New yearly macro state keys:
  - `commodity_indicators`: dictionary keyed by commodity id
  - `commodity_regime_counts`: counts for `bear`, `soft`, `neutral`, `firm`, and `bull`
  - `commodity_leaders`: top positive year-to-date commodity ids
  - `commodity_laggards`: top negative year-to-date commodity ids
- Each commodity indicator includes `id`, `display_name`, `category`, `level`, `direction`, `volatility`, `regime`, `ytd_move`, `driver_score`, `related_sectors`, and `story_tags`.
- Generation uses per-commodity stable RNG streams: `[run_seed, "macro_commodity", year, commodity_id]`.
- `RunState` and `GameManager.build_company_roster(...)` now pass the commodity catalog into macro state generation.
- Runtime price behavior stayed intentionally unchanged. `MarketSimulator` still only consumes the pre-existing macro fields.
- Old saved yearly macro states are not normalized in this task; Task 3 owns save/default normalization.
- Added `scripts/tests/CommodityMacroStateProbeTest.gd` and `scenes/tests/CommodityMacroStateProbeTest.tscn`.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CommodityMacroStateProbeTest.tscn` -> `COMMODITY_MACRO_STATE_PROBE_OK {"commodity_count":25,"leaders":["crude_oil","coal","fuel"],"laggards":["corn","silica","gold"],...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyGenerationFingerprintTest.tscn` -> `COMPANY_GENERATION_FINGERPRINT_OK ... "hash":"1225696160" ...`
  - `/Users/user/.local/bin/godot --headless -e --quit`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11 days=3 ...`

### 2026-06-14 - Task 3 complete

- Added RunState macro-state normalization for `yearly_macro_states`.
- Old saves or partial macro states now receive catalog-backed neutral commodity defaults:
  - one indicator per commodity id
  - `direction = flat`
  - `regime = neutral`
  - `ytd_move = 0.0`
  - `driver_score = 0.0`
  - neutral catalog level
- Existing partial commodity rows are preserved, while missing commodity ids and summary fields are backfilled.
- `get_macro_state_for_year(...)`, `get_macro_state_history()`, `load_from_dict(...)`, `to_save_dict()`, and `_ensure_macro_state_for_year(...)` now share the normalizer path.
- Added `scripts/tests/CommodityMacroSaveDefaultsTest.gd` and `scenes/tests/CommodityMacroSaveDefaultsTest.tscn`.
- Runtime price behavior stayed intentionally unchanged.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CommodityMacroSaveDefaultsTest.tscn` -> `COMMODITY_MACRO_SAVE_DEFAULTS_OK {"commodity_count":25,"legacy_regime_counts":{"bear":0,"bull":0,"firm":0,"neutral":25,"soft":0},...}`

### 2026-06-14 - Task 4 complete

- Added `systems/CommodityMacroContract.gd` as the shared helper for commodity macro summaries and thesis/content-ready evidence rows.
- Added `GameManager.get_commodity_macro_summary(...)` and `GameManager.get_commodity_macro_evidence_options(...)`.
- Commodity evidence rows now have a normalized contract:
  - `source_type = commodity_macro`
  - `source_label = Macro Commodities`
  - `category = sector_macro`
  - commodity id/name/category/regime/direction/level/ytd/driver/exposure metadata
  - related sectors and story tags for later generated content.
- `ThesisManager` now includes commodity macro evidence under sector/macro thesis options when a company has relevant commodity exposure or sector relevance.
- `ThesisEvidenceCaptureSystem`, `ThesisManager`, and `RunState` now preserve commodity evidence fields through Research Tray capture, direct thesis evidence insertion, thesis attachment, save, and reload normalization.
- `ThesisManager.add_thesis_evidence(...)` now returns the compact evidence row in its result payload for parity with the research attachment path.
- No large generated content was added and price behavior stayed intentionally unchanged.
- Added `scripts/tests/CommodityMacroEvidenceContractTest.gd` and `scenes/tests/CommodityMacroEvidenceContractTest.tscn`.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CommodityMacroEvidenceContractTest.tscn` -> `COMMODITY_MACRO_EVIDENCE_CONTRACT_OK {"commodity_id":"coal","company_id":"surya_power_nusantara","evidence_rows":4,"impact":"negative","sector_id":"energy","summary_rows":5}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CommodityMacroStateProbeTest.tscn` -> `COMMODITY_MACRO_STATE_PROBE_OK {"commodity_count":25,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CommodityMacroSaveDefaultsTest.tscn` -> `COMMODITY_MACRO_SAVE_DEFAULTS_OK {"commodity_count":25,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/ThesisResearchTrayTest.tscn` -> `THESIS_RESEARCH_TRAY_OK`
  - `/Users/user/.local/bin/godot --headless -e --quit`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11 days=3 ...`

### 2026-06-14 - Task 5 complete

- Added deterministic commodity macro fingerprint coverage.
- New files:
  - `scripts/tests/CommodityMacroFingerprintTest.gd`
  - `scenes/tests/CommodityMacroFingerprintTest.tscn`
- Fingerprint baseline:
  - fixed seed `20260614`
  - years `2020-2024`
  - commodity count `25`
  - hash `773085587`
  - first-year leaders `crude_oil`, `coal`, `fuel`
  - first-year laggards `corn`, `silica`, `gold`
  - last-year leaders `coal`, `fertilizer`, `soybean`
  - last-year laggards `rare_earth`, `iron_ore`, `nickel`
- Fingerprint payload includes each commodity id, category, regime, direction, normalized level, year-to-date movement, driver score, volatility, related sectors, and story tags.
- The test builds the same fixed-seed history twice and fails if the payload or hash changes across repeated builds.
- No runtime or price behavior changed.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CommodityMacroFingerprintTest.tscn` -> `COMMODITY_MACRO_FINGERPRINT_OK {"hash":"773085587","year_count":5,"commodity_count":25,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CommodityMacroStateProbeTest.tscn` -> `COMMODITY_MACRO_STATE_PROBE_OK {"commodity_count":25,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CommodityMacroSaveDefaultsTest.tscn` -> `COMMODITY_MACRO_SAVE_DEFAULTS_OK {"commodity_count":25,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CommodityMacroEvidenceContractTest.tscn` -> `COMMODITY_MACRO_EVIDENCE_CONTRACT_OK {"commodity_id":"coal","company_id":"surya_power_nusantara",...}`
  - `/Users/user/.local/bin/godot --headless -e --quit`

---

## Task 1 - Define commodity catalog and value model

Problem: Commodity indicators need consistent ids and normalized values before systems can consume them.

1. Define commodity ids such as `coal`, `crude_oil`, `cpo`, `nickel`, `gold`, `copper`, and `natural_gas`.
2. Define fields for current level, direction, volatility, regime, and year-to-date movement.
3. Decide whether the first implementation stores yearly state only or generates daily index values.
4. Verify:
   - Design review in this doc before code.
   - `git diff --check`

## Task 2 - Extend macro state with commodity regimes

Problem: The game needs a deterministic source for commodity bull/bear/sideways conditions.

1. Add commodity state generation to `MacroStateSystem.gd`.
2. Use existing seed/hash patterns instead of raw random calls.
3. Keep values bounded and explainable.
4. Verify:
   - Targeted macro state probe prints stable commodity values for a fixed seed.
   - Godot headless editor gate.

## Task 3 - Add save/default normalization

Problem: Old saves and partial macro state must not break when commodity fields are absent.

1. Add defaults for missing commodity state in the RunState macro normalizer path.
2. Keep defaults neutral so old saves do not receive surprise price pressure.
3. Verify:
   - Save/default targeted test or probe.
   - Quick smoke if runtime state is touched.

## Task 4 - Expose commodity evidence to thesis/content contracts

Problem: Commodity state should become usable by thesis and future content generation without each system inventing its own interpretation.

1. Add helper accessors for commodity regime summaries.
2. Define a normalized evidence shape for commodity facts.
3. Do not generate large content yet; only expose the contract.
4. Verify:
   - Targeted helper test.
   - `git diff --check`

## Task 5 - Add deterministic commodity tests

Problem: Future price and content work needs a stable commodity baseline.

1. Add a deterministic fingerprint for commodity state across a fixed seed and several years.
2. Include regimes and normalized movement values.
3. Verify:
   - Fingerprint test stable across repeated runs.
   - Existing macro-related tests still pass.

## Known traps

- If commodities directly move prices before company exposure is tested, the market may become noisy and hard to tune.
- Commodity ids must match company exposure ids exactly.
- Avoid a one-note commodity model where every commodity moves with the same macro direction.
