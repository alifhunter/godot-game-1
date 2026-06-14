# Thesis System Enhancement - Plan & Progress Log

Improves the thesis (investment-memo) generation system after the 2026-06-14 read-only review. The system is deterministic, save-safe, and well-written; this plan centralizes its typed vocabulary and tuning constants, resolves the scoring/pillar design question, DRYs the evidence-option builders by shape, and adds content depth - mostly without changing player-facing output, with deliberate scoring and copy rebaselines called out explicitly.
**Status: Tasks 1-7 complete.** Designed to run in a fresh session; everything needed to execute cold is in this file.

**Review verdict recap:** The thesis engine (`ThesisManager.gd` 1,050, `ThesisReportSystem.gd` 298, `ThesisEvidenceCaptureSystem.gd` 261; UI in `ThesisBoardWidget.gd` 3,559) is sound. Determinism is clean (verified zero bare `randi`/`randf`/`Time`; option order is stable via fixed arrays + insertion-ordered dict iteration). Task 4 aligned report scoring with the UI's five evidence pillars (Anchor / Price / Tape / Catalyst / Risk), lowered the volume ceiling, and capped top verdicts when contradictions remain unresolved. Stored theses + evidence round-trip through RunState normalizers with defaults (save-safe). Task 5 removed repeated option-builder shapes, Task 6 added sector- and stance/horizon-specific thesis guidance without changing score/report math, and Task 7 moved editable thesis copy into a JSON catalog with inline fallbacks and validation. No enhancement tasks remain open.

## Where everything lives

| What | Where |
|---|---|
| Thesis CRUD + evidence options | `systems/ThesisManager.gd` - `create_thesis`/`add_thesis_evidence`/`generate_thesis_report`, the 11 `_thesis_*_options` builders, band labels/details, macro impact scoring |
| Report / verdict | `systems/ThesisReportSystem.gd` - five report pillars via `ThesisVocabulary.report_memo_pillars()`, `_score_memo`, verdict state + grade gating, review builder |
| Evidence capture/normalize | `systems/ThesisEvidenceCaptureSystem.gd` - `VALID_INTERPRETATIONS` (~3-9), interpretation->impact mapping, key_stats->category auto-mapping |
| UI / phrasing | `scripts/ui/widgets/ThesisBoardWidget.gd` - current five evidence pillars via `ThesisVocabulary.ui_evidence_discipline_pillars()`, grade subcopy, evidence-quality phrases, next-research guidance, per-category evidence sentence builders |
| Public API (delegates) | `autoloads/GameManager.gd` - 15 thin delegates to `ThesisManager` (kept stable by the god-file split) |
| Runtime state | `RunState.player_theses` + research tray; normalized by `_normalize_player_theses` (~3272), `_normalize_player_thesis` (~3398), `_normalize_research_evidence_row` (~3315) |
| Content | `data/thesis/thesis_content.json` - editable category/interpretation/source labels, report/UI pillars, stance/horizon/tabs, memo states, grade copy, report section copy, band labels/details, sector lenses, and next-research guidance; loaded by `DataRepository.get_thesis_content_catalog()` with inline fallbacks in `ThesisVocabulary.gd` |
| Tests/probes | `scripts/tests/ThesisFingerprintTest.gd` (`THESIS_FINGERPRINT_OK`) locks the fixed-seed option/report baseline; `scripts/tests/ThesisScoringRebalanceTest.gd` (`THESIS_SCORING_REBALANCE_OK`) locks Task 4 scoring edge cases; `scripts/tests/ThesisResearchTrayTest.gd` (`THESIS_RESEARCH_TRAY_OK`) covers capture->tray->attach; `scripts/tests/ThesisVocabularyValidationTest.gd` (`THESIS_VOCABULARY_VALIDATION_OK`) covers Task 2 impact/category validation; `scripts/tests/ThesisContentDepthTest.gd` (`THESIS_CONTENT_DEPTH_OK`) covers Task 6 copy depth; `scripts/tests/ThesisContentCatalogValidationTest.gd` (`THESIS_CONTENT_CATALOG_VALIDATION_OK`) validates Task 7 JSON content |
| Key functions (line refs drift; locate by name) | `ThesisManager`: `create_thesis` (~314), `add_thesis_evidence` (~379), `generate_thesis_report` (~440), `_thesis_*_options` (~546-730), band labels/details (~852-922), macro impacts (~924-992), `safe_divide` (~1047). `ThesisReportSystem`: `_score_memo` (~84), `_discipline_rows`, verdict/grade maps (~267). `ThesisEvidenceCaptureSystem`: `normalize_interpretation` (~45), `normalize_attached_evidence` (~76) |

## Goals

- Centralize the typed vocabulary (interpretation, impact, stance, horizon, category, journal/verdict states) into validated consts so silent-mismatch typos surface instead of normalizing to a safe default.
- Name the scoring formula coefficients and the band/verdict/grade cutoffs so balance is tunable without reading the formula.
- Resolve the scoring design question (volume vs coherence) and report/UI pillar mismatch explicitly, as its own task with a before/after verdict delta.
- DRY the evidence-option builders by shape without changing the generated option set/order.
- Add content depth (sector- and stance/horizon-specific guidance) so repeat theses feel less same-y.
- Keep the thesis fingerprint (real fixed-seed run + fixed evidence -> option list + report verdict) byte-identical for pure-refactor tasks. Task 4 intentionally rebaselines score/verdict/pillar fields; Task 6 intentionally rebaselines copy/options while preserving score math.

## Non-goals

- No pillar behavior change before Task 4. Task 4 may deliberately align report scoring to the UI's five-pillar framework (Anchor / Price / Tape / Catalyst / Risk).
- No change to `RunState` thesis/evidence saved shape without a normalizer default + migration note.
- No market-balance work: theses are player-facing analysis and do NOT feed price formation, so MarketYearAudit is NOT a gate here (unlike the company/network plans).
- No UI restructure of `ThesisBoardWidget.gd` (content/phrasing edits only where a task calls for them).

## Working rules

- One task per checkpoint commit; verify before each commit.
- Keep edits scoped to the task. Do not mix the scoring rebalance (Task 4) with the pure-refactor tasks.
- Gates:
  - `git diff --check`
  - `/Users/user/.local/bin/godot --headless -e --quit`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11`
- Determinism is the contract: thesis option generation and report scoring must stay deterministic - no `randi`/`randf`/`Time`, and keep option ORDER stable (fixed arrays / insertion-ordered iteration; do not switch to unordered traversal).
- **Thesis fingerprint is the primary proof** (Task 1). Because thesis output is deterministic but not market-affecting, the net is a real fixed-seed run probe (fixed run seed + pinned company id + fixed evidence selection -> rendered option list + report score/verdict/grade), serialized canonically. Run it before AND after every task. Pure-refactor tasks (2, 3, 5) must leave it byte-identical. Task 4 intentionally changes score/verdict/pillar fields; record the exact delta while keeping option text/order stable. Task 6 intentionally changes copy/options; record the new baseline while keeping score math stable.
- No MarketYearAudit needed (thesis does not touch prices); the thesis fingerprint + `ThesisResearchTrayTest` + quick smoke are the gates.
- Save compatibility: new thesis/evidence keys need a default in the matching RunState normalizer (`_normalize_player_thesis` / `_normalize_research_evidence_row`). Do not rename/remove saved keys without a migration.

## Status

| # | Task | Est. cost | Status |
|---|---|---|---|
| 1 | Thesis fingerprint probe (real fixed-seed run -> options + verdict) | ~10-15% | Complete |
| 2 | Typed interpretation/impact vocabulary + validation | ~10% | Complete |
| 3 | Name the scoring + band/verdict/grade constants | ~5-10% | Complete |
| 4 | Scoring/pillar rebalance: volume vs coherence | ~15-20% | Complete |
| 5 | DRY evidence-option builders by shape | ~10-15% | Complete |
| 6 | Content depth: sector + stance/horizon guidance | ~15-20% | Complete |
| 7 | (Optional) Externalize content to `data/thesis/*.json` | ~20-30% | Complete |

Recommended batching: complete. Future thesis work should start by reading the current status and running `ThesisFingerprintTest`, `ThesisContentCatalogValidationTest`, and the quick smoke before changing content or scoring.

## Progress log

### 2026-06-14 - Plan created

- Created this enhancement plan from the read-only thesis-system review.
- Current inventory:
  - Engine: `ThesisManager.gd` 1,050 / `ThesisReportSystem.gd` 298 / `ThesisEvidenceCaptureSystem.gd` 261; UI `ThesisBoardWidget.gd` 3,559.
  - Determinism verified clean (zero bare `randi`/`randf`/`Time`; stable option order).
  - Content is 100% in code; no `data/thesis/*.json`.
	  - Theses normalized on load via 3 RunState normalizers (save-safe).
	  - Score formula: `20 + min(evidence,10)*5 + min(categories,6)*5 + min(support,4)*4 + min(risk,3)*5 - min(contradiction,4)*4 - missing_pillars*5`, clamped 0-100; volume alone (10 evidence + 6 categories) reaches the 100 ceiling.
	  - Verdict bands 76/58/38; grade bands 82/68/52; quality/growth/risk band cutoffs 80/65/50/35 (risk 80/65/45/25).
	  - Report scoring uses 4 pillars today, while the UI evidence checklist uses 5 pillars by splitting Tape/Broker Flow out separately.
- No code or data changes were made by this planning step.

### 2026-06-14 - Task 1 completed

- Added `scripts/tests/ThesisFingerprintTest.gd`, `scripts/tests/ThesisFingerprintTest.gd.uid`, and `scenes/tests/ThesisFingerprintTest.tscn`.
- The probe uses a real fixed-seed path: `RUN_SEED=20260614`, default difficulty, pinned company `anre`, `GameManager.build_company_roster(...)`, `RunState.setup_new_run(...)`, `RunState.ensure_company_full_detail(...)`, and `GameManager.get_company_snapshot(...)`.
- The probe captures `GameManager.get_thesis_evidence_options("anre")`, creates a thesis through `GameManager.create_thesis(...)`, attaches 7 fixed evidence rows through `GameManager.add_thesis_evidence(...)`, and generates the report through `GameManager.generate_thesis_report(...)`.
- Fixed evidence spans fundamentals, financials, price action, broker flow, sector/macro, and risk/invalidation, with one contradiction row.
- The canonical payload serializes option category/order/text plus report score, memo state, grade, sorted missing notes, and discipline rows. The test runs two builds in one invocation and asserts the payload/hash are stable before checking the locked baseline.
- Baseline:
  - company/ticker: `anre` / `ANRE`
  - hash: `665866267`
  - score: `100`
  - memo state: `Well Supported Memo`
  - grade: `A`
  - evidence count: `7`
  - option categories: `11`
  - evidence mix: support `4`, risk `1`, contradiction `1`, watch `1`
  - missing note count: `1`
- This baseline intentionally documents current volume-over-coherence behavior: a thesis with a contradiction still reaches `100` / `A` / `Well Supported Memo`. Task 4 is expected to move this score/verdict deliberately while keeping non-targeted option text/order stable.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/ThesisFingerprintTest.tscn` -> `THESIS_FINGERPRINT_OK`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/ThesisResearchTrayTest.tscn` -> `THESIS_RESEARCH_TRAY_OK`
  - `git diff --check` -> clean
  - `/Users/user/.local/bin/godot --headless -e --quit` -> clean editor parse/load
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11`
  - Known non-fatal headless warning noise observed: Steam API init warning, Twooter extra private options warning, RID/ObjectDB cleanup warnings

### 2026-06-14 - Task 2 completed

- Added `systems/ThesisVocabulary.gd` and `systems/ThesisVocabulary.gd.uid` as the shared typed-vocabulary source.
- Centralized:
  - interpretations: `support`, `risk`, `contradiction`, `watch`, `invalidation`
  - impacts: `positive`, `negative`, `mixed`
  - thesis stances: `bullish`, `bearish`, `income`, `watch`
  - thesis horizons: `swing`, `position`, `income`, `event`
  - thesis evidence categories, category labels, report memo pillars, UI evidence pillars, stance/horizon options, and evidence-tab options
- Updated `systems/ThesisEvidenceCaptureSystem.gd` to delegate interpretation/category/impact normalization to the shared vocabulary.
- Updated `systems/ThesisManager.gd` to validate category/impact in `add_thesis_evidence(...)`, normalize explicit interpretations, and correct mismatched explicit `impact`/`interpretation` pairs through `ThesisVocabulary.validate_impact_for_interpretation(...)`.
- Preserved unclassified option behavior: evidence added from generated option cards can still keep its generated impact while defaulting to `watch`; correction only applies when evidence has an explicit interpretation.
- Updated `systems/ThesisReportSystem.gd` and `scripts/ui/widgets/ThesisBoardWidget.gd` to reference shared report/UI pillar and option constants instead of local copies.
- Added `scripts/tests/ThesisVocabularyValidationTest.gd`, `scripts/tests/ThesisVocabularyValidationTest.gd.uid`, and `scenes/tests/ThesisVocabularyValidationTest.tscn`.
- Targeted validation probe result:
  - `risk + positive` manager evidence -> warning + corrected to `negative`
  - `support + negative` attached evidence -> warning + corrected to `positive`
  - invalid impact `moon` -> warning + fallback to `mixed`
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/ThesisVocabularyValidationTest.tscn` -> `THESIS_VOCABULARY_VALIDATION_OK`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/ThesisFingerprintTest.tscn` -> `THESIS_FINGERPRINT_OK` with unchanged hash `665866267`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/ThesisResearchTrayTest.tscn` -> `THESIS_RESEARCH_TRAY_OK` with no new thesis-vocabulary warnings on valid data
  - `git diff --check` -> clean
  - `/Users/user/.local/bin/godot --headless -e --quit` -> clean editor parse/load
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11`
  - Known non-fatal headless warning noise observed: Steam API init warning, Twooter extra private options warning, RID/ObjectDB cleanup warnings

### 2026-06-14 - Task 3 completed

- Named `systems/ThesisReportSystem.gd` scoring constants without changing values:
  - score clamp: `SCORE_MIN=0`, `SCORE_MAX=100`
  - base score: `SCORE_BASE=20`
  - evidence volume: `SCORE_EVIDENCE_CAP=10`, `SCORE_EVIDENCE_WEIGHT=5`
  - category breadth: `SCORE_CATEGORY_CAP=6`, `SCORE_CATEGORY_WEIGHT=5`
  - support rows: `SCORE_SUPPORT_CAP=4`, `SCORE_SUPPORT_WEIGHT=4`
  - risk rows: `SCORE_RISK_CAP=3`, `SCORE_RISK_WEIGHT=5`
  - contradiction rows: `SCORE_CONTRADICTION_CAP=4`, `SCORE_CONTRADICTION_PENALTY=4`
  - missing pillars: `SCORE_MISSING_PILLAR_PENALTY=5`
- Named `systems/ThesisReportSystem.gd` memo/grade bands without changing values:
  - memo states: `MEMO_STATE_WELL_SUPPORTED_MIN=76`, `MEMO_STATE_DEVELOPING_MIN=58`, `MEMO_STATE_THIN_MIN=38`
  - grades: `GRADE_A_MIN=82`, `GRADE_B_MIN=68`, `GRADE_C_MIN=52`
- Named `systems/ThesisManager.gd` band constants without changing values:
  - quality/growth bands: `80`, `65`, `50`, `35`
  - risk bands: `80`, `65`, `45`, `25`
  - existing risk-profile impact threshold: `RISK_PROFILE_NEGATIVE_IMPACT_MIN=58`
- No scoring, option, text, or saved-state behavior was intentionally changed. This is the pure-refactor precursor to Task 4.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/ThesisFingerprintTest.tscn` -> `THESIS_FINGERPRINT_OK` with unchanged hash `665866267`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/ThesisVocabularyValidationTest.tscn` -> `THESIS_VOCABULARY_VALIDATION_OK`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/ThesisResearchTrayTest.tscn` -> `THESIS_RESEARCH_TRAY_OK`
  - `git diff --check` -> clean
  - `/Users/user/.local/bin/godot --headless -e --quit` -> clean editor parse/load
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11`
  - Known non-fatal headless warning noise observed: Steam API init warning, Twooter extra private options warning, RID/ObjectDB cleanup warnings

### 2026-06-14 - Task 4 completed

- Aligned report scoring to the same five-pillar discipline model used by the UI:
  - Anchor: fundamentals, key stats, financials, valuation, ownership, management
  - Price: price action
  - Tape: broker flow
  - Catalyst: sector/macro, news, Twooter, network intel, corporate events
  - Risk: risk/invalidation
- Rebalanced `systems/ThesisReportSystem.gd` scoring constants so evidence count + category breadth alone cannot reach the top band:
  - base score: `SCORE_BASE=18`
  - evidence volume: `SCORE_EVIDENCE_CAP=6`, `SCORE_EVIDENCE_WEIGHT=3`
  - category breadth: `SCORE_CATEGORY_CAP=5`, `SCORE_CATEGORY_WEIGHT=4`
  - support rows: `SCORE_SUPPORT_CAP=4`, `SCORE_SUPPORT_WEIGHT=5`
  - risk rows: `SCORE_RISK_CAP=2`, `SCORE_RISK_WEIGHT=6`
  - contradiction rows: `SCORE_CONTRADICTION_CAP=4`, `SCORE_CONTRADICTION_PENALTY=10`
  - missing pillars: `SCORE_MISSING_PILLAR_PENALTY=7`
- Added verdict/grade gates:
  - `Well Supported Memo` now requires all five pillars complete and `contradiction_count == 0`.
  - One unresolved contradiction caps the memo below top band.
  - Two or more unresolved contradictions cap the memo at `Thin Memo`; grade is capped at `C`.
  - Incomplete pillars cap grade at `B` even when the numeric score is high.
- Added `scripts/tests/ThesisScoringRebalanceTest.gd`, `scripts/tests/ThesisScoringRebalanceTest.gd.uid`, and `scenes/tests/ThesisScoringRebalanceTest.tscn`.
- Updated `scripts/tests/ThesisFingerprintTest.gd` to lock separate option and report hashes, so future report rebalances do not hide option-list/order drift.
- Fixed-run fingerprint delta:
  - before: hash `665866267`, score `100`, memo state `Well Supported Memo`, grade `A`, report pillars `4`
  - after: hash `361545406`, option hash `590577094`, report hash `1836382259`, score `72`, memo state `Developing Memo`, grade `B`, report pillars `5`
  - unchanged field checks: company/ticker `anre` / `ANRE`, evidence count `7`, option categories `11`, evidence mix support `4`, risk `1`, contradiction `1`, watch `1`
- Hand-built edge-case checks:
  - clean five-pillar thesis: score `82`, `Well Supported Memo`, grade `A`, all five pillars complete, contradictions `0`
  - contradiction-heavy thesis: score `68`, `Thin Memo`, grade `C`, all five pillars complete, contradictions `2`
  - thin thesis: score `16`, `Evidence Needed`, grade `D`, missing Tape/Catalyst/Risk pillars, contradictions `0`
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/ThesisScoringRebalanceTest.tscn` -> `THESIS_SCORING_REBALANCE_OK`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/ThesisFingerprintTest.tscn` -> `THESIS_FINGERPRINT_OK`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/ThesisVocabularyValidationTest.tscn` -> `THESIS_VOCABULARY_VALIDATION_OK`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/ThesisResearchTrayTest.tscn` -> `THESIS_RESEARCH_TRAY_OK`
  - `git diff --check` -> clean
  - `/Users/user/.local/bin/godot --headless -e --quit` -> clean editor parse/load
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11`
  - Known non-fatal headless warning noise observed: Steam API init warning, intentional ThesisVocabularyValidation warnings, Twooter extra private options warning, RID/ObjectDB cleanup warnings

### 2026-06-14 - Task 5 completed

- Refactored `systems/ThesisManager.gd` evidence-option builders by shape without changing generated option output.
- Added named caps for dynamic option builders:
  - `THESIS_OPTION_CAP_OWNERSHIP=4`
  - `THESIS_OPTION_CAP_NEWS=5`
  - `THESIS_OPTION_CAP_TWOOTER=5`
  - `THESIS_OPTION_CAP_NETWORK=4`
  - `THESIS_OPTION_CAP_CORPORATE_EVENTS=5`
- Added small fixed-option helpers:
  - `thesis_option_spec(...)`
  - `thesis_options_from_specs(...)`
- Converted fixed option-array builders to the spec helper while preserving order/text:
  - `thesis_fundamental_options(...)`
  - `thesis_financial_options(...)`
  - `thesis_price_action_options(...)`
  - `thesis_broker_options(...)`
  - `thesis_risk_options(...)`
- Added `append_capped_thesis_option(...)` and used it in capped dynamic builders while preserving current iteration order and early-return behavior:
  - ownership shareholder rows
  - news article rows
  - Twooter post rows
  - network contact rows
  - corporate event-history rows
- Fixed-run fingerprint remained byte-identical:
  - hash `361545406`
  - option hash `590577094`
  - report hash `1836382259`
  - score `72`, memo state `Developing Memo`, grade `B`
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/ThesisFingerprintTest.tscn` -> `THESIS_FINGERPRINT_OK`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/ThesisScoringRebalanceTest.tscn` -> `THESIS_SCORING_REBALANCE_OK`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/ThesisResearchTrayTest.tscn` -> `THESIS_RESEARCH_TRAY_OK`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/ThesisVocabularyValidationTest.tscn` -> `THESIS_VOCABULARY_VALIDATION_OK`
  - `git diff --check` -> clean
  - `/Users/user/.local/bin/godot --headless -e --quit` -> clean editor parse/load
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11`
  - Known non-fatal headless warning noise observed: Steam API init warning, intentional ThesisVocabularyValidation warnings, Twooter extra private options warning, RID/ObjectDB cleanup warnings

### 2026-06-14 - Task 6 completed

- Added sector-aware `sector_macro` evidence-option detail copy in `systems/ThesisManager.gd`.
  - `thesis_sector_macro_options(...)` now passes sector/macro option details through `thesis_sector_macro_detail(...)`.
  - `thesis_sector_macro_focus(...)` maps sector ids to a short sector lens, including consumer, noncyclical, industrial, energy, tech, infra, transport, health, finance, basic industry/materials, and property/real estate.
  - The active macro-shock option remains unchanged.
- Added stance/horizon-aware next-research guidance in `scripts/ui/widgets/ThesisBoardWidget.gd`.
  - `_format_report_text(...)` now passes stance and horizon into `_thesis_next_research_summary(...)`.
  - `_thesis_next_research_focus(...)` adds copy for bullish, bearish, income, watch, swing, position, income, and event contexts.
  - Required checks are covered directly: income guidance mentions dividend coverage, event guidance mentions catalyst date/timing, and position guidance mentions sizing against macro volatility.
- Added `scripts/tests/ThesisContentDepthTest.gd`, `scripts/tests/ThesisContentDepthTest.gd.uid`, and `scenes/tests/ThesisContentDepthTest.tscn`.
  - The probe runs a fixed seed (`20260614`), samples three sectors from the generated company roster, verifies sector macro details include `Sector lens:`, and asserts sector details differ.
  - Sample sector output covered energy, infra, and transport.
  - The same probe instantiates `ThesisBoardWidget` and checks differentiated next-research guidance for income, event, and position contexts.
- Fixed-run fingerprint copy rebaseline:
  - before Task 6: hash `361545406`, option hash `590577094`, report hash `1836382259`, score `72`, memo state `Developing Memo`, grade `B`
  - after Task 6: hash `672110177`, option hash `747086609`, report hash `1836382259`, score `72`, memo state `Developing Memo`, grade `B`
  - expected delta: full hash + option hash changed because `sector_macro` option details now include sector copy
  - score/report math unchanged: report hash stayed `1836382259`, score stayed `72`, memo state stayed `Developing Memo`, grade stayed `B`
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/ThesisContentDepthTest.tscn` -> `THESIS_CONTENT_DEPTH_OK`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/ThesisFingerprintTest.tscn` -> `THESIS_FINGERPRINT_OK` with hash `672110177`, option hash `747086609`, report hash `1836382259`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/ThesisScoringRebalanceTest.tscn` -> `THESIS_SCORING_REBALANCE_OK`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/ThesisResearchTrayTest.tscn` -> `THESIS_RESEARCH_TRAY_OK`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/ThesisVocabularyValidationTest.tscn` -> `THESIS_VOCABULARY_VALIDATION_OK`
  - `git diff --check` -> clean
  - `/Users/user/.local/bin/godot --headless -e --quit` -> clean editor parse/load
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11`
  - Known non-fatal headless warning noise observed: Steam API init warning, intentional ThesisVocabularyValidation warnings, Twooter extra private options warning, RID/ObjectDB cleanup warnings

### 2026-06-14 - Task 7 completed

- Externalized thesis copy into `data/thesis/thesis_content.json`.
  - Catalog includes category labels, interpretation labels, source labels, report memo pillars, UI evidence-discipline pillars, stance/horizon options, evidence tabs, memo states, grade title/subcopy, report section titles, empty-state bullets, learning-note copy, quality/growth/risk band labels/details, sector macro lenses, and stance/horizon next-research guidance.
  - `DataRepository.gd` now loads the catalog from `res://data/thesis/thesis_content.json` and exposes `get_thesis_content_catalog()`.
- Kept inline fallbacks through `systems/ThesisVocabulary.gd`.
  - `category_label(...)`, `interpretation_label(...)`, `source_label(...)`, `report_memo_pillars()`, `ui_evidence_discipline_pillars()`, `stance_options()`, `horizon_options()`, `evidence_tabs()`, `memo_state_label(...)`, `grade_title(...)`, `grade_subcopy(...)`, `report_*` helpers, `band_label(...)`, `band_detail(...)`, `sector_macro_focus(...)`, and `next_research_focus_sentences(...)` all fall back to current inline values if the JSON key is missing.
  - `ThesisManager.gd`, `ThesisReportSystem.gd`, `ThesisEvidenceCaptureSystem.gd`, and `ThesisBoardWidget.gd` now read content through those accessors.
- Added `scripts/tests/ThesisContentCatalogValidationTest.gd`, `scripts/tests/ThesisContentCatalogValidationTest.gd.uid`, and `scenes/tests/ThesisContentCatalogValidationTest.tscn`.
  - Validates required dictionaries/arrays are present and non-empty.
  - Validates every known category and interpretation has a label.
  - Validates band labels/details, report pillars, sector focus, and next-research guidance are non-empty and still contain the expected Task 6 terms.
- Fixed-run fingerprint remained byte-identical after externalization:
  - hash `672110177`
  - option hash `747086609`
  - report hash `1836382259`
  - score `72`, memo state `Developing Memo`, grade `B`
- Verification:
  - `python3 -m json.tool data/thesis/thesis_content.json` -> valid JSON
  - `/Users/user/.local/bin/godot --headless -e --quit` -> clean editor parse/load
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/ThesisContentCatalogValidationTest.tscn` -> `THESIS_CONTENT_CATALOG_VALIDATION_OK`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/ThesisFingerprintTest.tscn` -> `THESIS_FINGERPRINT_OK` with unchanged hash `672110177`, option hash `747086609`, report hash `1836382259`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/ThesisContentDepthTest.tscn` -> `THESIS_CONTENT_DEPTH_OK`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/ThesisScoringRebalanceTest.tscn` -> `THESIS_SCORING_REBALANCE_OK`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/ThesisResearchTrayTest.tscn` -> `THESIS_RESEARCH_TRAY_OK`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/ThesisVocabularyValidationTest.tscn` -> `THESIS_VOCABULARY_VALIDATION_OK`
  - `git diff --check` -> clean
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11`
  - Known non-fatal headless warning noise observed: Steam API init warning, intentional ThesisVocabularyValidation warnings, Twooter extra private options warning, RID/ObjectDB cleanup warnings

---

## Task 1 - Thesis fingerprint probe

Problem: there is no fixed-input test of thesis generation. `ThesisResearchTrayTest` covers capture/attach flow but not the generated option list or the report verdict, so later tasks have no deterministic before/after net for option set/order or scoring.

1. Add `scripts/tests/ThesisFingerprintTest.gd` + `scenes/tests/ThesisFingerprintTest.tscn`, following the existing test-scene pattern.
2. Build the input through a real fixed-seed run, not a fake adapter:
   - use a fixed run seed and default difficulty;
   - build the roster through `GameManager.build_company_roster(...)`;
   - `RunState.setup_new_run(...)`;
   - pin one company id from the fixed roster;
   - hydrate the pinned company snapshot through the normal GameManager/RunState path;
   - attach a hardcoded evidence selection covering several categories, including at least one contradiction.
3. Emit a canonical, drift-proof fingerprint (not raw dict `hash()`): the rendered option list per category (category id + option label + impact, in builder order), and the report's `score`/`verdict_state`/`grade`/`missing_notes` (sorted). Format floats to fixed precision; hash the ordered string; assert spot fields alongside the hash. End in `THESIS_FINGERPRINT_OK`.
4. Run two builds in one invocation and assert they match, to prove the fingerprint itself is stable before trusting it.
5. Verify:
   - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/ThesisFingerprintTest.tscn` -> `THESIS_FINGERPRINT_OK` (record hash + the baseline score/verdict/grade in this log)
   - `ThesisResearchTrayTest` -> `THESIS_RESEARCH_TRAY_OK`
   - gates and quick smoke.

## Task 2 - Typed interpretation/impact vocabulary + validation

Problem: `interpretation` (support/risk/contradiction/watch/invalidation) and `impact` (positive/negative/mixed) are stringly-typed; a typo'd interpretation silently normalizes to "watch" (scores nothing), and an `impact` that contradicts its `interpretation` (e.g. "risk" tagged "positive") is not validated.

1. Centralize the valid sets as consts (interpretation, impact, stance, horizon, category) - `VALID_INTERPRETATIONS` already exists in `ThesisEvidenceCaptureSystem`; extend the pattern to impact/category and reference them everywhere instead of inline literals.
   - Also centralize the current report-pillar and UI-pillar category lists as named consts, but do NOT change pillar behavior in Task 2; the actual four-to-five-pillar alignment belongs to Task 4.
2. In `normalize_attached_evidence`, after resolving impact, validate it is consistent with the interpretation (e.g. interpretation in {risk,contradiction,invalidation} implies impact != "positive"); on mismatch `push_warning` and correct to the interpretation-derived impact. Debug-build `assert` on an unknown interpretation/category (warn-and-continue in release - same validated-fallback pattern as the company plan).
3. Validate evidence `category` against the known category set in `add_thesis_evidence`/`attach_research_evidence_to_thesis`; warn on unknown.
4. Behavior for VALID data must be unchanged (fingerprint byte-identical; real data triggers no warning/assert).
5. Verify:
   - Task 1 fingerprint byte-identical
   - a temporary probe with a mismatched impact/interpretation emits the warning and self-corrects
   - gates and quick smoke.

## Task 3 - Name the scoring + band/verdict/grade constants

Problem: the score formula coefficients (`ThesisReportSystem._score_memo` ~116) and the band cutoffs (quality/growth/risk 80/65/50/35, verdict 76/58/38, grade 82/68/52) are inline magic numbers - the actual balance dials, unfindable.

1. Extract score coefficients into named consts (`SCORE_BASE`, `SCORE_EVIDENCE_CAP`/`_WEIGHT`, `SCORE_CATEGORY_*`, `SCORE_SUPPORT_*`, `SCORE_RISK_*`, `SCORE_CONTRADICTION_*`, `SCORE_MISSING_PILLAR_*`).
2. Extract verdict-state and grade cutoffs, and the quality/growth/risk band cutoffs, into named consts.
3. Naming only - EXACT current values. This is the pure-refactor precursor to Task 4 (which then changes the values knowingly).
4. Verify:
   - Task 1 fingerprint byte-identical (proves zero scoring drift)
   - gates and quick smoke.

## Task 4 - Scoring/pillar rebalance: volume vs coherence

Problem: with the constants named (Task 3), the formula rewards volume over coherence: `20 + min(evidence,10)*5 + min(categories,6)*5` reaches 100 on quantity alone, every evidence row is counted three times (raw count + its category + its support/risk bucket), and a contradiction is penalized only -4 (max -16). A thesis with 10 items across 6 categories and 4 contradictions still grades "Well Supported / A-B". The report also scores four pillars while the UI presents five by separating Tape/Broker Flow. This is a deliberate balance + pillar-alignment change, not a refactor.

1. Recommended target behavior:
   - align report scoring with the UI's five-pillar model: Anchor / Price / Tape / Catalyst / Risk;
   - treat `broker_flow` as the Tape pillar;
   - keep no new saved "resolved contradiction" field in this task; every `interpretation == "contradiction"` row counts as unresolved;
   - require all five pillars complete and `contradiction_count == 0` for the top verdict band ("Well Supported Memo");
   - if contradiction_count > 0, cap the verdict below the top band even if the numeric score is high; if contradiction_count >= 2, cap more aggressively unless the designer later adds explicit resolution state;
   - lower the raw evidence-volume ceiling so evidence count + category breadth alone cannot reach the top band.
2. Implement via the Task 3 constants + small verdict-gating helpers; keep determinism and avoid any saved-state shape change.
3. This task IS allowed to change the fingerprint's score/verdict/grade/pillar rows - record the exact before/after for the Task 1 fixed-run thesis (and a couple of hand-built edge cases: clean five-pillar thesis, contradiction-heavy thesis, thin thesis) in this log so the intent is auditable.
4. Verify:
   - Task 1 fingerprint regenerated; the score/verdict/pillar delta matches the intended design (documented), and non-targeted fields (option list, option order, categories) are unchanged
   - `ThesisResearchTrayTest` still OK
   - gates and quick smoke.

## Task 5 - DRY evidence-option builders by shape

Problem: `_thesis_*_options` repeats two different shapes: fixed option arrays (fundamentals/financials/price_action/broker/risk) and capped source-row mappers (ownership/sector_macro/news/twooter/network/corporate). The common option creation/capping rules are still duplicated, but forcing all builders into one generic helper would be more risky than helpful.

1. Extract only behavior-equivalent helpers:
   - a small fixed-option spec helper for static arrays if it keeps exact option order and text;
   - a capped source-row mapper for dynamic builders (news/twooter/network/corporate/ownership) that preserves current iteration order and early-return behavior.
2. Do NOT force every builder into one generic config if it makes the code harder to read or changes control flow.
3. RISK like the network pool helper: option ORDER and the exact set must not change. Preserve iteration order and the per-category caps (news/twooter 5, network 4, ownership 4, etc.) exactly. Diff the produced option list before/after.
4. Verify:
   - Task 1 fingerprint BYTE-IDENTICAL (option list + order unchanged) - non-negotiable for this task
   - gates and quick smoke.

## Task 6 - Content depth: sector + stance/horizon guidance

Problem: band descriptions repeat verbatim across theses (5 fixed lines per band), and guidance is one-size-fits-all - macro guidance never specializes per sector, and an income thesis gets the same next-step prompts as a swing/event thesis.

1. Add sector-aware phrasing to the sector/macro pillar (e.g. cyclicals -> GDP/capex cycle; defensives -> dividend safety; tech -> margin durability), keyed off the company's `sector_id`.
2. Add stance/horizon-specific next-research guidance in `ThesisBoardWidget` (income -> dividend coverage; event -> catalyst timing; position -> sizing vs macro volatility).
3. Keep the voice (evidence-first mentor, Indonesian-market flavor). New text only; no scoring change.
4. Verify:
   - Task 1 fingerprint: option labels/details may change where Task 6 adds sector/stance text; record the new copy baseline and verify score/verdict math is unchanged
   - a probe across 2-3 sectors + stances shows differentiated guidance (no repeated generic line)
   - gates and quick smoke.

## Task 7 - (Optional) Externalize content to data/thesis/*.json

Problem: unlike academy/twooter, all thesis text is inline in code. Externalizing enables localization and non-programmer editing - but adds a load/validation path and is only worth it if those are on the roadmap.

1. Decide first whether localization or editor access is actually planned. If not, STOP and document that inline content is the accepted choice (lower complexity, simpler determinism).
2. If yes: move band labels/details, interpretation/category labels, verdict phrasing, and guidance pools into `data/thesis/*.json`; load via `DataRepository`; keep inline fallbacks for missing keys (the established pattern).
3. Add a validation path (json.tool gate + a schema check that every band/category/state has non-empty text) so externalized content cannot regress to empty/placeholder.
4. Verify:
   - Task 1 fingerprint byte-identical (same text resolved from data)
   - `python3 -m json.tool data/thesis/*.json > /dev/null`
   - gates and quick smoke.

## Known traps

- Thesis output is deterministic but NOT market-affecting - the thesis fingerprint is the real net; MarketYearAudit is not a gate here.
- The report/UI pillar mismatch is intentional only until Task 4. Task 2 may name both lists, but Task 4 should align the report with the UI's five-pillar model.
- Determinism contract: keep option order stable. Several builders iterate dicts (news/twooter/network) relying on insertion order; do not switch to an unordered or sorted-by-value traversal without re-baselining the fingerprint.
- The scoring formula double-counts volume (raw count + category + support/risk bucket). Task 4 must account for that when rebalancing - lowering one lever without the others may not move the verdict.
- There is no "resolved contradiction" saved field today. Until such a field is deliberately added, all contradiction rows count as unresolved for scoring gates.
- Task 6 is allowed to rebaseline copy/option text, but not score math. Keep those fingerprint sections separate enough that the delta is obvious.
- `interpretation` typos silently become "watch" (zero score contribution); `impact` is not validated against interpretation today. Task 2 closes both.
- Stored theses + research-tray rows round-trip through `_normalize_player_thesis` / `_normalize_research_evidence_row`. Any new key must be defaulted there or it is dropped on save/load.
- `GameManager` exposes 15 thin thesis delegates kept stable by the god-file split; do not change those public signatures - route changes through `ThesisManager`.
- `ThesisBoardWidget.gd` is 3,559 lines and reads thesis state directly; if a thesis field is renamed, grep the widget for both reads and any `set(...)` writes.
