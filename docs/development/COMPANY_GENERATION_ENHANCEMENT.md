# Company Generation Enhancement - Plan & Progress Log

Improves the maintainability and tuning-ergonomics of the company/employee generation layer after review. The system works correctly, is fully deterministic, and produces financially coherent companies; this plan names its tuning knobs, adds validated fallback warnings (with debug-build hard-fail), splits the 5,103-line generator into focused pieces, and resolves two deliberate design questions - without changing the generated roster for a given seed.
**Status: Tasks 1-8 complete.** Designed to run in a fresh session; everything needed to execute cold is in this file.

**Review verdict recap:** `systems/CompanyGenerator.gd` (5,103 lines, ~100 functions) is the largest remaining system and is architecturally sound. Determinism is airtight across the whole layer (`CompanyGenerator`, `CompanyRosterGenerator`, `CompanyNarrativeGenerator`, `PersonEventSystem`, `CompanyRuntime`): zero bare `randi`/`randf`/`randomize`/`Time` calls; everything runs through `STABLE_RNG` composed seed keys (plus a seeded inline Mulberry32 in the narrative generator), so the full roster is reproducible from `run_seed`. Financial coherence is defended throughout (`max`/`clamp` floors before every division; quarter weights normalize to 1.0; negative equity is structurally prevented). The reviewed "stale insider after CEO change" risk was checked and is NOT real: `ContactNetworkSystem._management_roster_for_company` recomputes insiders live from the saved profile every snapshot (no cache), `apply_ceo_change_application` rewrites that same roster, and `PersonEventSystem` never mutates the roster (reads `generation_traits` only). Remaining risk is size and ergonomics: a god-file generator with 150-228 line functions, inline financial/chart magic numbers that are the real balance dials, silent fallbacks that hide bad sector/archetype inputs, duplicated pool-draw logic, and two design questions (insider identity continuity across CEO changes; name/ticker collision behavior at larger rosters).

## Where everything lives

| What | Where |
|---|---|
| Primary generator | `systems/CompanyGenerator.gd` - traits, 10-year financial history, quarterly statements, chart-shape profiles, scores, target price, shares, management roster assembly, narrative/roadmap hookup |
| Roster/definition generator | `systems/CompanyRosterGenerator.gd` - company id/ticker/name/sector/narrative-tags/anchors (NOT individual people) |
| Narrative generator | `systems/CompanyNarrativeGenerator.gd` - archetype, age, employee count, description, profile tags (seeded inline Mulberry32) |
| Person events | `systems/PersonEventSystem.gd` - person/management narrative event candidates; reads `generation_traits`, does NOT mutate `management_roster` |
| Runtime wrapper | `systems/CompanyRuntime.gd` - typed wrapper over the saved company runtime dict (already reviewed; out of scope) |
| Profile schema | `systems/CompanyProfile.gd` - `KEYS` list + sparse from_dict/to_dict (the save contract) |
| Data/config | `data/companies/company_profile_data.json` (535), `company_archetypes.json` (92), `company_words.json` (51 name/word pools), `company_roadmap_catalog.json` (105) |
| CEO-change roster mutation | `systems/CorporateActionApplications.gd:apply_ceo_change_application` (~808) - rewrites `profile["management_roster"]` |
| Insider derivation | `systems/ContactNetworkSystem.gd:_management_roster_for_company` - live recompute from profile; insider id keyed on `affiliation_role` |
| Generation entry points | `autoloads/RunState.gd` ~414 / ~708 (`generate_company_profile_core`) and ~741 (`hydrate_company_profile_detail`); two-phase: core then detail |
| Tests/probes | `CompanyGenerationFingerprintTest` covers deterministic full-roster output; `CompanyGenerationValidationTest` covers invalid-input warning behavior; `CompanyRoadmapSystemTest` covers roadmaps |
| Key functions (line refs drift; locate by name) | `generate_company_profile` (~191), `generate_company_profile_core` (~196), `hydrate_company_profile_detail` (~250), `build_management_roster` (~317), `_build_traits` (~457), `_build_chart_profile` (~642), `_build_financial_history` (~1833), `_build_quarterly_statement_history` (~2129), `_build_statement_period` (~2283), `_apply_chart_profile_to_historical_bars` (~2817), `_chart_shape_anchors` (~4328), `_derive_quality_score`/`_derive_growth_score`/`_derive_risk_score` (~4689) |

## Goals

- Name the financial and chart-shape tuning knobs (inline coefficients in `_build_financial_history`/`_build_chart_profile`) so balance is tunable without hunting nested arithmetic - the highest-value item.
- Add validated fallback warnings at the generation entry (warn-and-continue in release so saves keep loading; hard-fail in debug builds so dev and the test harness catch malformed sector_id/archetype/anchors) instead of silently producing generic companies.
- Reduce `CompanyGenerator.gd` from a 5,103-line god-file toward focused modules (mirror the proven GameManager/RunState/Twooter/Network split pattern).
- Resolve the two design questions explicitly, each with its own task: insider identity continuity across CEO changes (Task 5) and name/ticker collision policy at larger rosters (Task 8).
- Keep the default-roster generation fingerprint byte-identical at every step. Tasks 1, 3, 4, 6, 7 are pure output-preserving refactors. Task 2 changes only the INVALID-input path (warnings/debug-assert; valid generation unchanged). Task 5 changes insider/network runtime behavior, not company-generation output. Task 8 changes only the over-budget collision path; the default 30-company roster is unchanged.

## Non-goals

- No change to the company economic model, sector profiles, or score formulas as balance (Task 3 NAMES the constants, preserving exact values; any retuning is a separate, deliberate follow-up).
- No change to `CompanyProfile.KEYS` / saved profile shape without a normalizer default + migration note.
- No `CompanyRuntime.gd` work (already reviewed and perf-fixed).
- No rework of `PersonEventSystem` event content (it is read-only on the roster and out of scope except where Task 5 touches CEO-change identity).

## Working rules

- One task per checkpoint commit; verify before each commit.
- Keep edits scoped to the task. Do not mix balance changes, content changes, and refactors unless the task says so.
- Gates:
  - `git diff --check`
  - `/Users/user/.local/bin/godot --headless -e --quit`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11`
- If editing JSON, also run: `python3 -m json.tool data/companies/<file>.json > /dev/null`.
- Determinism is the core contract: keep everything on `STABLE_RNG` composed keys (and the existing seeded Mulberry32). No `randi`/`randf`/`randomize`/`Time` in generation or probes.
- **Generation fingerprint is the primary proof.** Because this layer determines the entire run, the strongest net is the fixed-seed FULL-ROSTER fingerprint (Task 1, via `GameManager.build_company_roster`): same seed -> byte-identical roster. It must use the real roster path, not single-company calls, so collision/pool/hydration regressions are caught. Run it before AND after every task; pure-refactor tasks must leave it unchanged.
- For tasks that touch financials or chart shape (3, 4), ALSO run the 120-day `MarketYearAudit` (`--audit-days 120 --audit-seed 20260606 --audit-difficulty grind`, byte-identical after masking `ms` timings) - generation feeds price formation.
- Save compatibility: generated output is a plain dict saved via `CompanyProfile`. New keys need a `CompanyProfile.KEYS` entry + from_dict default. Do not rename/remove saved keys without a migration.

## Status

| # | Task | Est. cost | Status |
|---|---|---|---|
| 1 | Generation fingerprint probe (fixed-seed FULL roster baseline) | ~10-15% | Complete |
| 2 | Validated fallback warnings at generation entry (debug hard-fail) | ~5-10% | Complete |
| 3 | Name the financial + chart-shape magic-number constants | ~10-15% | Complete |
| 4 | Split the giant chart/history/statement functions | ~20-30% | Complete |
| 5 | Insider identity continuity across CEO changes (design decision) | ~10-15% | Complete |
| 6 | Unify the duplicated pool-draw helpers | ~5-10% | Complete |
| 7 | System boundary split of CompanyGenerator.gd | ~30-40% | Complete |
| 8 | Name/ticker collision policy (design decision) | ~10-15% | Complete |

Recommended batching: **Session 1 = Task 1** (full-roster fingerprint first - it is the before/after net for everything else, and it must exercise the real roster path so collision/pool/hydration regressions are caught). **Session 2 = Tasks 2+6** (validation + DRY, low-risk, mechanical). **Session 3 = Task 3** (name constants; fingerprint + market audit prove zero balance drift). **Session 4 = Task 4** (split giant functions). **Session 5 = Tasks 5+8** (the two design decisions; small but each needs a product call). **Task 7** waits until 3-4 land so the split moves named, factored code.

## Progress log

### 2026-06-14 - Plan created

- Created this enhancement plan from the company/employee system review.
- Current inventory:
  - `CompanyGenerator.gd`: 5,103 lines, ~100 functions; longest: `_apply_chart_profile_to_historical_bars` (~228), `_build_chart_profile` (~212), `_build_financial_history` (~212), `_chart_shape_anchors` (~210), `_build_statement_period` (~170), `_build_quarterly_statement_history` (~154).
  - Determinism verified clean across all 5 files (zero bare `randi`/`randf`/`randomize`/`Time`).
  - Default roster size: `company_count` = 30 (so name/ticker collision is low-risk today; latent at larger rosters).
  - Generation is two-phase from RunState: `generate_company_profile_core` then `hydrate_company_profile_detail`.
  - PersonEventSystem grep for roster mutation: empty (reads traits only) - confirms no person-event/insider desync.
  - Insiders recomputed live from saved profile each snapshot; insider id keyed on `affiliation_role`.
- No code or data changes were made by this planning step.

### 2026-06-14 - Task 1 completed

- Added the full-roster generation fingerprint probe:
  - `scripts/tests/CompanyGenerationFingerprintTest.gd`
  - `scripts/tests/CompanyGenerationFingerprintTest.gd.uid`
  - `scenes/tests/CompanyGenerationFingerprintTest.tscn`
- Probe path:
  - uses `GameManager.build_company_roster(RUN_SEED, difficulty_config)`;
  - applies `RunState.setup_new_run(...)`;
  - forces `RunState.ensure_company_full_detail(company_id)` for every generated company;
  - uses `RunState.get_effective_company_definition(company_id, true, true)` for the canonical payload.
- Fingerprint guard:
  - runs the same build twice in one invocation and asserts payload/hash equality;
  - sorts companies by id;
  - serializes only the explicit stable field allow-list;
  - formats floats with fixed `%.6f` precision;
  - asserts default roster size and zero duplicate names/tickers.
- Baseline recorded:
  - seed: `20260614`
  - roster size: `30`
  - hash: `1225696160`
  - first sorted company: `anre` / `ANRE` / `Anugerah Realty` / base price `613.000000` / chart archetype `distressed`
  - last sorted company: `waba` / `WABA` / `Wahana Bank Worldwide` / base price `6146.000000` / chart archetype `range_bound`
  - duplicate names: `0`
  - duplicate tickers: `0`
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyGenerationFingerprintTest.tscn` -> `COMPANY_GENERATION_FINGERPRINT_OK {"duplicate_name_count":0,"duplicate_ticker_count":0,"first_base_price":"613.000000","first_chart_archetype":"distressed","first_company_id":"anre","first_name":"Anugerah Realty","first_ticker":"ANRE","hash":"1225696160","last_base_price":"6146.000000","last_chart_archetype":"range_bound","last_company_id":"waba","last_name":"Wahana Bank Worldwide","last_ticker":"WABA","roster_size":30,"seed":20260614}`
  - `git diff --check`
  - `/Users/user/.local/bin/godot --headless -e --quit`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11 days=3 summary=Institution-led accumulation gave GLLA the cleanest tape today.`
- Known warning noise from the smoke remains non-fatal:
  - `Twooter dialog tree 'network_stranger_source' node 'open' has more than 3 usable private options; extra options are hidden.`
  - headless RID/ObjectDB/resource cleanup warnings at exit.

### 2026-06-14 - Task 2 completed

- Added generation input validation in `systems/CompanyGenerator.gd`:
  - `_validate_generation_inputs(template, sector_definition, hard_fail)` checks sector id resolution, required anchor presence, non-degenerate anchor values, optional generated scale/target-price metadata, optional capital-structure style, and chart-profile enum values.
  - `generate_company_profile_core(...)` calls the validator with `hard_fail = OS.is_debug_build()`.
  - Invalid inputs always `push_warning` with the company id and field-specific issue.
  - Debug generation hard-fails on invalid inputs; release behavior keeps the existing fallback path after warning.
- Added the warning-path probe:
  - `scripts/tests/CompanyGenerationValidationTest.gd`
  - `scripts/tests/CompanyGenerationValidationTest.gd.uid`
  - `scenes/tests/CompanyGenerationValidationTest.tscn`
- Probe behavior:
  - calls `_validate_generation_inputs(...)` directly with `hard_fail = false`;
  - verifies invalid input returns `valid=false`;
  - asserts sector, anchor, and chart-profile issues are reported;
  - exits with `COMPANY_GENERATION_VALIDATION_WARNING_OK`.
- Valid-generation behavior stayed unchanged:
  - Task 1 fingerprint remained `1225696160`;
  - default roster size stayed `30`;
  - duplicate names/tickers stayed `0`;
  - no validation warnings/asserts fired on the real data set.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyGenerationValidationTest.tscn` -> `COMPANY_GENERATION_VALIDATION_WARNING_OK {"hard_fail":false,"issue_count":16}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyGenerationFingerprintTest.tscn` -> `COMPANY_GENERATION_FINGERPRINT_OK ... "hash":"1225696160" ...`
  - `git diff --check`
  - `/Users/user/.local/bin/godot --headless -e --quit`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11 days=3 summary=Institution-led accumulation gave GLLA the cleanest tape today.`
- Known warning noise from the smoke remains non-fatal:
  - Steam init warnings in headless mode.
  - `Twooter dialog tree 'network_stranger_source' node 'open' has more than 3 usable private options; extra options are hidden.`
  - headless RID/ObjectDB/resource cleanup warnings at exit.

### 2026-06-14 - Task 3 completed

- Named chart-profile thresholds and roll chances in `systems/CompanyGenerator.gd` (`CHART_*`) without changing values.
- Named financial-history tuning constants (`FINANCIAL_*`) for price-to-sales, revenue floor, revenue growth, margin drift, payout, deleveraging, valuation, sales-floor, free-float, and turnover formulas.
- Pure refactor: no RNG order changes, no balance retuning, no generated output shape changes.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyGenerationFingerprintTest.tscn` -> `COMPANY_GENERATION_FINGERPRINT_OK ... "hash":"1225696160" ...`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/MarketYearAudit.tscn -- --audit-days 120 --audit-seed 20260606 --audit-difficulty grind` -> `success:true`, stable payload fields matched the pre-edit baseline after ignoring `[perf]` ms lines:
    - best stock `TETE`, return `701.573147745397`
    - average return `-47.7359943785822`
    - gorengan campaigns started `18`, dump seen `10`, successful `0`
    - corporate action events `213`, quarterly report events `102`
  - `git diff --check`
  - `/Users/user/.local/bin/godot --headless -e --quit`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11 days=3 summary=Institution-led accumulation gave GLLA the cleanest tape today.`
- Note: stdout redirection to `/tmp/company_task3_audit_before.txt` triggered a Godot headless `RotatedFileLogger` crash before scene startup; normal captured audit runs completed successfully, so the comparison used normal captured output instead of saved temp files.
- Known warning noise from the smoke remains non-fatal:
  - Steam init warnings in headless mode.
  - `Twooter dialog tree 'network_stranger_source' node 'open' has more than 3 usable private options; extra options are hidden.`
  - headless RID/ObjectDB/resource cleanup warnings at exit.

### 2026-06-14 - Task 4 completed

- Split the large company-generation functions into private helpers without changing generated values, seed keys, or RNG call order.
- `_build_chart_profile(...)` now delegates:
  - `_chart_archetype_for(...)`
  - `_chart_bias_for(...)`
  - `_chart_sma_behavior_for(...)`
  - `_chart_preferred_sma_period_for(...)`
  - `_chart_pattern_selection_for(...)`
- `_build_financial_history(...)` now delegates formula sub-steps for target market cap, target margin/free float/debt, price-to-sales, expected growth, initial margin/equity, yearly revenue growth, margin drift, payout ratio, delever target, valuation multiples, and turnover.
- `_build_quarterly_statement_history(...)` now delegates quarterly earnings/debt/equity seed-weight construction to `_build_quarter_statement_seed_weights(...)`.
- `_build_statement_period(...)` now delegates income-statement metrics, balance-sheet metrics, and cash-flow metrics to dedicated helpers.
- `_apply_chart_profile_to_historical_bars(...)` now delegates historical close-context construction, range/wick pricing, and volume-field generation.
- `_chart_shape_anchors(...)` now handles cycle override + dispatch, with the literal pattern anchor table isolated behind `_chart_pattern_shape_anchors(...)`.
- Verification:
  - Fingerprint was run after each risky function split; every run stayed `COMPANY_GENERATION_FINGERPRINT_OK ... "hash":"1225696160" ...`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/MarketYearAudit.tscn -- --audit-days 120 --audit-seed 20260606 --audit-difficulty grind` -> `success:true`, stable payload fields matched the Task 3 baseline after ignoring `[perf]` ms lines:
    - best stock `TETE`, return `701.573147745397`
    - average return `-47.7359943785822`
    - gorengan campaigns started `18`, dump seen `10`, successful `0`
    - corporate action events `213`, quarterly report events `102`
  - `git diff --check`
  - `/Users/user/.local/bin/godot --headless -e --quit`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11 days=3 summary=Institution-led accumulation gave GLLA the cleanest tape today.`
- Known warning noise from the smoke remains non-fatal:
  - Steam init warnings in headless mode.
  - `Twooter dialog tree 'network_stranger_source' node 'open' has more than 3 usable private options; extra options are hidden.`
  - headless RID/ObjectDB/resource cleanup warnings at exit.

### 2026-06-14 - Task 5 completed

- Implemented Option 2: insider identity is keyed on the person across CEO changes.
- `CorporateActionApplications.apply_ceo_change_application(...)` now preserves the outgoing CEO as the same old contact id and marks that row:
  - `affiliation_type = "free_agent"`
  - `affiliation_role = "former_ceo"`
  - `former_affiliation_role = "ceo"`
  - `role` / `role_label = "Former CEO"`
  - `departed = true`
  - `departed_day_index = <CEO change day>`
- The incoming CEO now gets a fresh day-indexed id: `insider_<company>_ceo_<day_index>`.
- The incoming CEO row inherits CEO role-template fields such as categories, recognition requirements, reliability, and bridge metadata, but person-state fields are cleared so the new CEO starts as a fresh discovery/unmet contact.
- `GameManager._management_roster_with_ceo_change_result(...)` mirrors the same idempotent transformation so company snapshots and older save-style snapshots do not collapse the two identities back into one row.
- `ContactNetworkSystem._management_roster_for_company(...)` now preserves saved `affiliation_type` values instead of forcing every generated roster row to `insider`.
- Current-insider flows now skip departed/free-agent rows:
  - public company-article insider discovery skips rows where `affiliation_type != "insider"`;
  - referral candidate selection skips rows where `affiliation_type != "insider"`.
- Added the targeted CEO-change identity probe:
  - `scripts/tests/CompanyCeoChangeIdentityTest.gd`
  - `scripts/tests/CompanyCeoChangeIdentityTest.gd.uid`
  - `scenes/tests/CompanyCeoChangeIdentityTest.tscn`
- Probe coverage:
  - marks the original CEO as already met with relationship `67`;
  - applies a forced CEO-change application;
  - asserts the old id still points to the old person as a met `free_agent` / `former_ceo`;
  - asserts the new CEO id points to the incoming CEO as an `insider` / `ceo`;
  - asserts the old relationship/discovery state remains on the old id;
  - asserts the new CEO starts undiscovered/unmet;
  - asserts both the saved profile and `GameManager.get_company_snapshot(...)` preserve one old CEO row and one new CEO row.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyCeoChangeIdentityTest.tscn` -> `COMPANY_CEO_CHANGE_IDENTITY_OK {"company_id":"halo","day_index":42,"new_ceo_id":"insider_halo_ceo_42","new_ceo_name":"Nadia Santoso","old_affiliation_type":"free_agent","old_ceo_id":"insider_halo_ceo","old_ceo_name":"Galih Utama","old_relationship":67,"ticker":"HALO"}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyGenerationFingerprintTest.tscn` -> `COMPANY_GENERATION_FINGERPRINT_OK ... "hash":"1225696160" ...`
  - `git diff --check`
  - `/Users/user/.local/bin/godot --headless -e --quit`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11 days=3 summary=Institution-led accumulation gave GLLA the cleanest tape today.`
- Known warning noise from the smoke remains non-fatal:
  - Steam init warnings in headless mode.
  - `Twooter dialog tree 'network_stranger_source' node 'open' has more than 3 usable private options; extra options are hidden.`
  - headless RID/ObjectDB/resource cleanup warnings at exit.

### 2026-06-14 - Task 6 completed

- Compared the duplicated pool helpers before editing:
  - `CompanyRosterGenerator._pick_word(...)` filters preferred words first, then general words, then consumes one `RandomNumberGenerator.randi_range(...)` only when the final pool is non-empty.
  - `CompanyRosterGenerator._pick_template(...)` filters by sector first, falls back to all templates, then consumes one `RandomNumberGenerator.randi_range(...)`.
  - `CompanyNarrativeGenerator._pick_string(...)` uses the narrative generator's inline Mulberry32 dictionary RNG via `_next_int(...)`, not Godot `RandomNumberGenerator`.
- Added shared pool/index utility:
  - `systems/SeededPool.gd`
  - `systems/SeededPool.gd.uid`
- Routed matching selection behavior through the utility without changing RNG ownership:
  - roster template picks use `SeededPool.pick_value_with_random_number_generator(...)`;
  - roster word picks use `SeededPool.pick_string_with_random_number_generator(...)`;
  - narrative string picks keep `_next_int(...)` local, then use `SeededPool.pick_value_at_index(...)`.
- Kept the custom narrative Mulberry32 helper in `CompanyNarrativeGenerator.gd`; forcing it through `RandomNumberGenerator` would have changed the RNG stream.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyGenerationFingerprintTest.tscn` -> `COMPANY_GENERATION_FINGERPRINT_OK ... "hash":"1225696160" ...`
  - `git diff --check`
  - `/Users/user/.local/bin/godot --headless -e --quit`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11 days=3 summary=Institution-led accumulation gave GLLA the cleanest tape today.`
- Known warning noise from the smoke remains non-fatal:
  - Steam init warnings in headless mode.
  - `Twooter dialog tree 'network_stranger_source' node 'open' has more than 3 usable private options; extra options are hidden.`
  - headless RID/ObjectDB/resource cleanup warnings at exit.

### 2026-06-14 - Task 7 completed

- Added chart-profile boundary module:
  - `systems/CompanyChartProfileBuilder.gd`
  - `systems/CompanyChartProfileBuilder.gd.uid`
- Added financial-history boundary module:
  - `systems/CompanyFinancialsBuilder.gd`
  - `systems/CompanyFinancialsBuilder.gd.uid`
- `CompanyGenerator.gd` now preloads both modules and keeps the public generation facade stable.
- Delegated chart orchestration from `CompanyGenerator.gd`:
  - `_build_chart_profile(...)` -> `CompanyChartProfileBuilder.build_profile(...)`
  - `_apply_chart_profile_to_historical_bars(...)` -> `CompanyChartProfileBuilder.apply_to_historical_bars(...)`
  - `_chart_shape_anchors(...)` -> `CompanyChartProfileBuilder.shape_anchors(...)`
- Delegated financial orchestration from `CompanyGenerator.gd`:
  - `_build_financial_history(...)` -> `CompanyFinancialsBuilder.build_history(...)`
  - `_build_financial_statement_snapshot(...)` -> `CompanyFinancialsBuilder.build_statement_snapshot(...)`
- Kept low-level formulas/helpers inside `CompanyGenerator.gd` for this first boundary split. The new modules call back into the generator for already-factored helper steps, preserving seed keys, arithmetic, and reviewability; deeper helper migration can be a later follow-up once this boundary is stable.
- Current split size:
  - `systems/CompanyGenerator.gd`: 5,369 lines
  - `systems/CompanyChartProfileBuilder.gd`: 312 lines
  - `systems/CompanyFinancialsBuilder.gd`: 172 lines
- Verification:
  - Fingerprint after chart extraction stayed `COMPANY_GENERATION_FINGERPRINT_OK ... "hash":"1225696160" ...`
  - Fingerprint after financial extraction stayed `COMPANY_GENERATION_FINGERPRINT_OK ... "hash":"1225696160" ...`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/MarketYearAudit.tscn -- --audit-days 120 --audit-seed 20260606 --audit-difficulty grind` -> `success:true`, stable payload fields matched the Task 3 baseline:
    - best stock `TETE`, return `701.573147745397`
    - average return `-47.7359943785822`
    - gorengan campaigns started `18`, dump seen `10`, successful `0`
    - corporate action events `213`, quarterly report events `102`
  - `git diff --check`
  - `/Users/user/.local/bin/godot --headless -e --quit`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11 days=3 summary=Institution-led accumulation gave GLLA the cleanest tape today.`
- Known warning noise from the smoke remains non-fatal:
  - Steam init warnings in headless mode.
  - `Twooter dialog tree 'network_stranger_source' node 'open' has more than 3 usable private options; extra options are hidden.`
  - headless RID/ObjectDB/resource cleanup warnings at exit.

### 2026-06-14 - Task 8 completed

- Chosen policy: document and accept the current retry/fallback behavior for now.
- Recommendation rationale:
  - the default 30-company roster already asserts zero duplicate names and tickers in `CompanyGenerationFingerprintTest`;
  - inflated probes at 80, 120, and 200 companies showed zero duplicate names, zero duplicate tickers, no actual name fallback branch hits, and no `CMPX` ticker fallback;
  - changing production fallback now would only affect an unobserved over-budget path and would add unnecessary generation risk.
- Added a repeatable collision-policy probe:
  - `scripts/tests/CompanyRosterCollisionPolicyTest.gd`
  - `scripts/tests/CompanyRosterCollisionPolicyTest.gd.uid`
  - `scenes/tests/CompanyRosterCollisionPolicyTest.tscn`
- Probe coverage:
  - builds rosters through `GameManager.build_company_roster(...)`;
  - measures company counts `30`, `80`, `120`, and `200` with fixed seed `20260614`;
  - asserts the default roster still has zero duplicate names/tickers;
  - reports duplicate counts, unique counts, name-fallback hits, `CMPX` fallback hits, and sample duplicates.
- Measured result:
  - `30`: duplicate names `0`, duplicate tickers `0`, name fallback `0`, `CMPX` fallback `0`
  - `80`: duplicate names `0`, duplicate tickers `0`, name fallback `0`, `CMPX` fallback `0`
  - `120`: duplicate names `0`, duplicate tickers `0`, name fallback `0`, `CMPX` fallback `0`
  - `200`: duplicate names `0`, duplicate tickers `0`, name fallback `0`, `CMPX` fallback `0`
- Future policy if larger rosters ever prove the current retry budget insufficient:
  - keep the existing 96-attempt seeded retry path first;
  - then use a deterministic seeded suffix fallback for names/tickers after the retry budget is exhausted;
  - do not widen pools or retune normal generation unless the default 30-company fingerprint stays byte-identical.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyRosterCollisionPolicyTest.tscn` -> `COMPANY_ROSTER_COLLISION_POLICY_OK ...`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyGenerationFingerprintTest.tscn` -> `COMPANY_GENERATION_FINGERPRINT_OK ... "hash":"1225696160" ...`
  - `git diff --check`
  - `/Users/user/.local/bin/godot --headless -e --quit`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11 days=3 summary=Institution-led accumulation gave GLLA the cleanest tape today.`
- Known warning noise from the smoke remains non-fatal:
  - Steam init warnings in headless mode.
  - `Twooter dialog tree 'network_stranger_source' node 'open' has more than 3 usable private options; extra options are hidden.`
  - headless RID/ObjectDB/resource cleanup warnings at exit.

---

## Task 1 - Generation fingerprint probe (full roster path)

Problem: there is no dedicated test of company generation. Every later task needs a deterministic before/after net proving the roster output is unchanged for a fixed seed - the quick smoke does not assert generated financials/names/chart profiles.

CRITICAL - drive the REAL roster path, not single-company calls. Collisions, used name/ticker pools, and hydration order are roster-context-only phenomena: a per-company `generate_company_profile` probe would pass green while Tasks 5/6/8 silently reshuffle names. The fingerprint MUST go through `GameManager.build_company_roster(run_seed, difficulty_config)` (~`autoloads/GameManager.gd:6556`) for a fixed seed + fixed difficulty, then hydrate each via the same two-phase path RunState uses (`generate_company_profile_core` already runs inside the roster build; call `hydrate_company_profile_detail` per company so detail fields are covered). That is the only net that catches what the later tasks can break.

1. Add `scripts/tests/CompanyGenerationFingerprintTest.gd` + `scenes/tests/CompanyGenerationFingerprintTest.tscn`, following the existing test-scene pattern.
2. Build the full fixed-seed roster (default difficulty, `company_count` = 30) through `build_company_roster` + per-company hydration. Do NOT use single-company shortcuts.
3. Emit a CANONICAL, drift-proof fingerprint (raw dict `hash()` and naive `JSON.stringify` are too fragile - nested array order and float repr can drift):
   - sort companies by `id`;
   - serialize an explicit allow-list of stable fields per company (id, ticker, name, sector_id, base_price, quality/growth/risk scores, market_cap, shares_outstanding, chart archetype, first+last history-year revenue/net_income/equity, management roster as ordered `[role, display_name]` pairs);
   - format every float to fixed precision (e.g. `"%.6f"`) so float repr cannot drift;
   - sort nested dict keys and any unordered arrays; build the payload as an explicitly ordered string, then hash that string.
   - Also assert a few human-readable spot fields alongside the hash so a mismatch is debuggable, ending in `COMPANY_GENERATION_FINGERPRINT_OK`.
4. Keep it test-only and fully seeded; no saved state, no UI.
5. Verify:
   - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyGenerationFingerprintTest.tscn` -> `COMPANY_GENERATION_FINGERPRINT_OK` (record the hash + roster size in this log as the baseline)
   - run it twice in one invocation (or assert two builds match) to prove the fingerprint itself is stable before trusting it as a net
   - gates and quick smoke.

## Task 2 - Validated fallback warnings at generation entry

Problem: an empty/typo'd `sector_id` silently resolves to `DEFAULT_SECTOR_PROFILE`, and archetype/anchor inputs are not validated - malformed data produces quietly-generic companies with no signal. This is "validated fallback," not literal fail-fast: a real run must still load saves and keep going, so release behavior is warn-and-continue. The fail-fast part is debug-only.

1. Put the checks in a helper with an explicit hard-fail switch, e.g. `_validate_generation_inputs(template, sector_definition, hard_fail: bool)`. It validates: `sector_id` resolves to a known sector or alias; required `template.anchors` keys exist and are non-degenerate (e.g. market_cap > 0); archetype strings are known where assigned/consumed. On any failure it always `push_warning`s with the company id + offending field, then (only if `hard_fail`) `assert(false, "...")`.
2. `generate_company_profile_core` (~196) calls it with `hard_fail = OS.is_debug_build()`: release = warn-and-continue with the existing default so saves still load; debug = hard-fail so dev and a real debug generation run catch malformed data immediately.
3. The bad-input probe (verification below) calls the helper directly with `hard_fail = false`, so it deterministically asserts the WARNING path without aborting - because `--headless` test scenes run as debug, calling the normal `OS.is_debug_build()` path would intentionally `assert`-abort the probe. The probe tests warning-only behavior; a genuine debug generation run asserting on bad data is expected and correct.
4. Behavior for VALID inputs must be unchanged (fingerprint stable); the assert path must never fire on the real data set.
5. Verify:
   - Task 1 full-roster fingerprint byte-identical (valid path; real data triggers no warning/assert)
   - the bad-input probe (`hard_fail = false`) emits the warning and returns without aborting -> sentinel OK
   - gates and quick smoke.

## Task 3 - Name the financial + chart-shape magic-number constants

Problem: revenue-growth and margin-drift coefficients (`0.035 + growth_engine*0.11 + execution_consistency*0.020 - scale*0.018 ...` ~1871-1932) and chart-archetype thresholds (~659-683) are inline. These are the actual balance dials but are unfindable.

1. Extract financial coefficients into named `const` (e.g. `REVENUE_GROWTH_BASE`, `REVENUE_GROWTH_ENGINE_WEIGHT`, `MARGIN_DRIFT_TARGET_WEIGHT`, ...). Keep EXACT current values.
2. Extract chart archetype/bias thresholds into named consts (or a small rules table) the same way.
3. This is naming only - no value changes.
4. Verify:
   - Task 1 full-roster fingerprint byte-identical (proves zero balance drift)
   - 120-day `MarketYearAudit` byte-identical after masking `ms` timings
   - gates and quick smoke.

## Task 4 - Split the giant chart/history/statement functions

Problem: five functions are 150-228 lines (`_apply_chart_profile_to_historical_bars`, `_build_chart_profile`, `_build_financial_history`, `_chart_shape_anchors`, `_build_statement_period`), mixing several concerns each.

1. Extract cohesive sub-steps as private helpers, one function at a time (e.g. `_build_chart_profile` -> `_determine_archetype` / `_determine_bias` / `_determine_cycle_template` / `_build_gap_profile`; `_build_financial_history` -> `_advance_financial_year`).
2. Pure mechanical extraction - identical arithmetic, identical call order, identical seed keys.
3. Run the fingerprint after EACH function split (this is the highest-drift-risk task; do not batch all five before verifying).
4. Verify:
   - Task 1 full-roster fingerprint byte-identical after each extraction
   - 120-day `MarketYearAudit` byte-identical after the final extraction
   - gates and quick smoke.

## Task 5 - Insider identity continuity across CEO changes (design decision)

Problem: insider `contact_id` is keyed on `affiliation_role` (`insider_<company>_ceo`), so after `apply_ceo_change_application` rewrites the roster, the same contact id maps to a NEW person's name. An already-met insider silently becomes a different human under the same id. This is a product decision, not a bug.

1. Decide intended behavior with the designer's intent in mind. Candidate options:
   - keep role-keyed identity but reset met/relationship state on CEO change (the seat persists, the person resets), or
   - key insider identity on the person, so the old CEO becomes a stale/departed contact and the new CEO is a fresh discovery, or
   - explicitly accept current behavior and document it.
2. If a behavior change is chosen, make it in `apply_ceo_change_application` and/or `_management_roster_for_company`, with a normalizer default for any new saved key, and a targeted probe asserting met/relationship state across a forced CEO change.
3. Keep determinism; do not break existing saves (default any new key).
4. Verify:
   - targeted CEO-change probe (new) shows the chosen behavior
   - Task 1 full-roster fingerprint unchanged (generation itself does not change)
   - gates and quick smoke.

## Task 6 - Unify the duplicated pool-draw helpers

Problem: `_pick_word`/`_pick_template` (CompanyRosterGenerator) and `_pick_string` (CompanyNarrativeGenerator) duplicate pick-from-pool-with-preferred-and-exclusions logic - three places to fix one bug.

DECEPTIVELY RISKY: this looks mechanical but is the easiest task to silently break names. Even a behavior-equivalent helper reshuffles the entire roster if it changes the RNG CALL COUNT (one extra `rng.randf()`/`randi_range()` shifts every downstream draw) or the preferred/excluded fallback order. The three call sites may not be byte-identical today - diff their exact draw sequence before unifying, and if they genuinely differ, do NOT force one shape onto all three.

1. Diff the three helpers' exact RNG-call sequence and preferred/excluded fallback order. Only unify the ones that already match; leave any genuine divergence as-is (or replicate it behind a parameter).
2. Extract a single shared seeded sampler (a small static helper, e.g. `systems/SeededPool.gd` or a static func on an existing utility) taking `(pool, preferred, excluded, rng)`. It must make the SAME number of RNG calls in the SAME order as the helper it replaces.
3. Route matching call sites through it.
4. Verify:
   - Task 1 full-roster fingerprint BYTE-IDENTICAL (this is the only thing that proves names/tickers/tags did not reshuffle - non-negotiable for this task)
   - gates and quick smoke.

## Task 7 - System boundary split of CompanyGenerator.gd

Problem: `CompanyGenerator.gd` owns ~6 sub-domains in 5,103 lines (traits, financial history, quarterly statements, chart profile, historical bars, scores). Future changes are slow and risky.

1. Split only AFTER Tasks 3-4 (constants named, giant functions broken) so the split moves clean code.
2. Candidate extracted modules (static, referenced via `preload` const, no `class_name`, deps passed explicitly - exactly like `TwooterDialogRouter`/`NetworkJournalBuilder`):
   - `CompanyFinancialsBuilder.gd` - history, quarterly statements, scores, target price, shares
   - `CompanyChartProfileBuilder.gd` - chart profile, shape anchors, historical bar application
   - `CompanyGenerator.gd` keeps the public `generate_company_profile*` / `hydrate_company_profile_detail` / `build_management_roster` facade as thin delegates so RunState call sites stay stable.
3. Move one module at a time; run the fingerprint + editor parse after each.
4. Avoid new allocation-heavy wrapper layers; generation runs in a batch at run start (and in hydration), so keep per-company allocation flat.
5. Verify:
   - Task 1 full-roster fingerprint byte-identical after every extraction
   - editor parse after every extraction
   - 120-day `MarketYearAudit` byte-identical after the final extraction
   - gates and quick smoke.

## Task 8 - Name/ticker collision policy (design decision)

Problem: name and ticker generation retry on collision ~96 times against the used-name/ticker sets, then fall back to hardcoded `["Global","Prima"]` / `"CMPX"`. At the default 30-company roster this almost never fires, but it is a latent dup risk at larger rosters and the fallback is silent. This is a policy decision, not a bug - it only matters once roster size grows or a probe surfaces real dupes.

1. First, measure: have the Task 1 full-roster probe assert there are zero duplicate names and zero duplicate tickers at the default size, and re-run it at an inflated `company_count` (e.g. 80-120) to see whether the hardcoded fallback actually triggers. If it never triggers at realistic sizes, the correct outcome may be "document and accept" - record that and stop.
2. If it does trigger, decide the policy:
   - deterministic hash-suffix fallback (e.g. `name + "_" + seeded_short_hash`) so collisions stay unique and seeded, or
   - widen the word pools / retry budget, or
   - explicitly cap roster size to the safe range and document it.
3. Any change must stay seeded/deterministic and must NOT alter output at the default size (the existing 30-company fingerprint stays byte-identical; only the over-budget path changes).
4. Verify:
   - Task 1 full-roster fingerprint byte-identical at default size
   - the inflated-roster probe shows zero dupes (or the documented accepted behavior)
   - gates and quick smoke.

## Known traps

- Generation determines the entire run. The fixed-seed FULL-ROSTER fingerprint (Task 1, via `build_company_roster`) is the real safety net - trust it over the smoke for anything touching generation. A single-company probe is NOT sufficient: collisions, used-pool state, and hydration order only appear in the roster path.
- Determinism contract: every choice is on a `STABLE_RNG` composed key or the seeded Mulberry32. Never introduce `randi()`/`randf()`/`Time`, including in probes. Changing a seed key string reshuffles output - treat seed keys as frozen.
- Tasks 3 and 4 must NOT change generated values; the fingerprint + MarketYearAudit byte-identical checks are how you prove it.
- Saved company profiles round-trip through `CompanyProfile.KEYS`. A new generated key that is not in `KEYS` is silently dropped on save/load - add it to `KEYS` with a from_dict default.
- `management_roster` entries that are not dictionaries are silently dropped at the insider wrap (`typeof != TYPE_DICTIONARY: continue` in `_management_roster_for_company`) - if Task 5 adds roster fields, keep entries dict-shaped.
- Name/ticker collision fallback (`["Global","Prima"]` / `"CMPX"` after ~96 retries) is low-risk at 30 companies but latent at larger rosters - this is Task 8's decision; measure with an inflated-roster probe before changing anything.
- `python3 -m json.tool` works on the company data files (no BOM, unlike the network data file).
- Long-run audits grow slower as history accumulates; use the fingerprint first, quick smoke second, MarketYearAudit only for financial/chart tasks (3, 4) and the final split (7).
