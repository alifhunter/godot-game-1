# Late-Run Performance Bottleneck Enhancement - Plan & Progress Log

Reduce late-year hitches that remain after the first performance recovery pass. The first pass fixed broker-history bloat, broad UI refreshes, and player-facing save flushes; this follow-up targets the 70-company late-run normalization spikes and save payload construction cost that still appear after long simulations.

**Status: planned - Tasks 1-7 not started.** Designed to run in a fresh session; everything needed to execute cold is in this file.

**Review verdict recap:** Performance improved materially: the 70-company full-year run dropped from about `326,372ms` / `1,450ms/day` to `232,511.74ms` / `1,033.39ms/day`, and explicit save flushes dropped to `12.91ms`. The remaining problem is not broker history anymore. Late-year runs still show `normalize_companies` spikes up to `524.01ms` and `675.66ms`, `apply_day_result` totals up to `709.52ms`, and scheduled post-recap saves around `409.97ms`, mostly from payload construction.

## Where everything lives

| What | Where |
|---|---|
| Daily state application | `autoloads/RunState.gd` - `apply_day_result`, `_normalize_day_result_company_runtime`, active state payload handling |
| Company runtime saved payload | `autoloads/RunState.gd` - `_build_companies_save_payload`, `to_save_dict`, `load_from_dict` |
| Market day result source | `systems/MarketSimulator.gd` - day-result company runtime generation and any deep-copy work before simulation |
| Advance-day orchestrator | `autoloads/GameManager.gd` - `_advance_day_internal`, `_advance_phase_simulate_market`, `_advance_phase_save_and_announce` |
| Save scheduling and timings | `autoloads/SaveManager.gd`, `scripts/ui/GameRoot.gd` - pending save, post-recap flush, save phase telemetry |
| Company story/dossier payload | `systems/CompanyStoryDossierSystem.gd`, `autoloads/RunState.gd` - saved `company_story_dossier_state` section |
| Quarterly/report payload | `systems/CompanyRoadmapSystem.gd`, `autoloads/RunState.gd` - saved `quarterly_report_calendar` and event/report state |
| Existing perf probe | `scripts/tests/NormalPlayPerfTest.gd`, `scenes/tests/NormalPlayPerfTest.tscn` |
| Full-year probe | `scripts/tests/FullYearPlayerScenarioTest.gd`, `scenes/tests/FullYearPlayerScenarioTest.tscn` |
| Latest baseline log | `docs/development/test_log/2026-06-26_performance_recovery_full_regression.md` |
| Prior plan | `docs/development/PERFORMANCE_RECOVERY_ENHANCEMENT.md` |
| Known issue | `docs/development/KNOWN_ISSUES.md` - `KI-013` long-run performance |
| Key functions (line refs drift; locate by name) | `apply_day_result`, `_normalize_day_result_company_runtime`, `_build_companies_save_payload`, `to_save_dict`, `_advance_phase_simulate_market`, `save_run`, `_flush_advance_day_save_after_recap` |

## Baseline From Latest Regression

Latest targeted data from `2026-06-26_performance_recovery_full_regression.md`:

| Metric | Observed |
|---|---:|
| 70-company full-year elapsed | `232,511.74ms` |
| 70-company full-year average | `1,033.39ms/day` |
| Late-year `normalize_companies` spike | `675.66ms` |
| Late-year `apply_day_result` total spike | `709.52ms` |
| Scheduled post-recap save flush | `409.97ms` |
| `RunState.to_save_dict()` during scheduled save | `191.014ms` |
| Save serialization | `51.043ms` |
| Disk write | `4.275ms` |
| Short-run save size | `3,464,461 bytes` |
| `companies` save section | `1,692,153 bytes` |
| `company_story_dossier_state` save section | `705,262 bytes` |
| `quarterly_report_calendar` save section | `405,316 bytes` |
| Broker-history total bytes | `480,957 bytes` |

Important interpretation:

- Broker history is no longer the primary bottleneck.
- Disk write is not the primary save bottleneck; payload construction and serialization are.
- Late-run spikes are likely caused by a combination of full-company normalization, growing per-company runtime dictionaries, active story/report payloads, and unnecessary deep copies.
- The current full-year average is acceptable for automated tests, but player fast-forward can still feel chunky late in a run.

## Goals

- Reduce late-year 70-company `normalize_companies` p95 below `180ms`, with a stretch target below `120ms`.
- Keep worst observed late-year `normalize_companies` below `300ms`, with no `500ms+` spikes in the fixed full-year scenario.
- Reduce scheduled post-recap save flush below `250ms`, with `to_save_dict_ms` below `100ms`.
- Keep 70-company full-year average under `900ms/day`, with a stretch target under `800ms/day`.
- Preserve catalog-enabled 70-company gameplay depth, annual filing laziness, thesis evidence, company story dossiers, bank loans, broker range behavior, and price outcomes.
- Add durable late-run perf telemetry so regressions show up before manual playtesting catches them.

## Non-goals

- Do not reduce selected company count as the fix.
- Do not remove company story dossiers, annual filings, quarterly reports, broker ranges, or relationship graphs.
- Do not thread the simulation or save system in this pass.
- Do not rewrite `MarketSimulator` broadly unless a targeted probe proves the deep-copy boundary is the dominant cost.
- Do not change stock price outcomes, event schedules, attention routing, thesis scoring, or filing/story truth unless a deterministic test proves a performance-only shape change requires it.
- Do not make save compatibility brittle. Existing saves and old runtime sections must keep loading.

## Working rules

- One task per checkpoint commit; verify before each commit.
- Measure before and after each behavior change. Console feel is not enough.
- Preserve determinism. If a task touches simulation/runtime shape, compare fixed-seed outcome summaries.
- Prefer dirty flags, bounded windows, and cached summaries over broad deep copies.
- Do not add new `duplicate(true)` or JSON round-trip work to daily hot paths without a measured reason.
- Keep annual filings lazy. Do not prebuild filing documents to hide late-run stalls.
- Quick smoke currently has a known unrelated FTUE organic-chain failure. Record it if still present, but do not block this plan unless the failure changes or becomes performance-related.
- Gates:
  - `git diff --check`
  - `/Users/user/.local/bin/godot --headless --log-file /private/tmp/godot_editor_late_perf.log --path /Users/user/Documents/gorengangame/godot-game-1 -e --quit`
  - `/Users/user/.local/bin/godot --headless --log-file /private/tmp/godot_normal_play_late_perf.log --path /Users/user/Documents/gorengangame/godot-game-1 res://scenes/tests/NormalPlayPerfTest.tscn -- --smoke-local-io`
  - targeted late-run perf probe added by this plan
  - targeted save payload perf probe added by this plan
  - full-year player scenario for final validation

## Status

| # | Task | Est. cost | Status |
|---|---|---|---|
| 1 | Add late-run perf probe and percentile telemetry | ~10-15% | Not started |
| 2 | Profile company normalization by subsystem and company | ~10-20% | Not started |
| 3 | Normalize only dirty runtime sections | ~25-35% | Not started |
| 4 | Bound growing story/report/event payload normalization | ~20-30% | Not started |
| 5 | Reduce save payload construction cost | ~20-30% | Not started |
| 6 | Lock budgets in perf tests and update known issues | ~10-15% | Not started |
| 7 | Full regression and handoff update | ~15-25% | Not started |

Recommended batching: **Session 1 = Tasks 1-2** because we need hard attribution before changing hot paths. **Session 2 = Task 3** because dirty-section normalization is likely the largest gameplay-safe win. **Session 3 = Tasks 4-5** because runtime growth and save payload construction are related but should be verified separately. **Session 4 = Tasks 6-7** locks budgets and proves the long-run scenario still works.

## Progress log

### 2026-06-26 - Plan created

- Created this enhancement plan from the completed performance recovery regression.
- Current inventory:
  - 70-company full-year run is improved to `1,033.39ms/day`, but target is now under `900ms/day`.
  - Late-year `normalize_companies` still has `500ms+` spikes.
  - Scheduled post-recap save is still about `410ms`; `RunState.to_save_dict()` is about `191ms`.
  - Save size is down to `3.46MB`; broker history is no longer the dominant payload.
- No code, scene, or gameplay data changes were made by this planning step.

---

## Task 1 - Add Late-Run Perf Probe And Percentile Telemetry

Problem: Current evidence comes from full-year console logs and final summaries. We need a durable probe that records per-day distributions and late-run percentiles so improvements are measurable.

1. Add a targeted test scene/script, recommended name:
   - `scenes/tests/LateRunPerformanceProbeTest.tscn`
   - `scripts/tests/LateRunPerformanceProbeTest.gd`
2. Run a fixed 70-company catalog seed for at least `225` trading days without full UI interaction.
3. Capture per-day metrics:
   - `apply_day_result`
   - `normalize_companies`
   - `active_state_payloads`
   - `calendar_and_prune`
   - `simulate_day`
   - event count / active story count / company count
4. Report bucketed summaries:
   - days `1-50`
   - days `51-100`
   - days `101-150`
   - days `151-200`
   - days `201-225`
5. Include median, p90, p95, max, and day index for max.
6. Print a sentinel such as:
   - `LATE_RUN_PERF_PROBE_OK days=225 normalize_p95=... normalize_max=...`
7. Verify:
   - new probe sentinel
   - `NormalPlayPerfTest.tscn`
   - `git diff --check`
   - headless editor gate

## Task 2 - Profile Company Normalization By Subsystem And Company

Problem: `normalize_companies` is a single aggregate number. Before optimizing, we need to know whether spikes are caused by every company, a few large companies, story payloads, quarterly/report state, event payloads, broker/current-day fields, or deep-copy behavior.

1. Add temporary or guarded telemetry inside `_normalize_day_result_company_runtime`.
2. Break normalization cost into stable categories:
   - price/history fields
   - broker/current flow fields
   - story/dossier/arc fields
   - financial/report/calendar fields
   - relationship/top-down fields
   - generic dictionary cleanup/defaults
3. Track top five companies by normalization time and runtime byte size at late-run checkpoints.
4. Add a small helper to estimate runtime section byte size without changing save output.
5. Make telemetry available to `LateRunPerformanceProbeTest`.
6. Keep the output compact; do not spam per-company logs unless a debug flag is set.
7. Verify:
   - late-run probe identifies the top subsystem and top companies
   - no deterministic outcome drift in `FullYearPlayerScenarioTest.tscn` summary fields unless intentionally accepted
   - `git diff --check`

## Task 3 - Normalize Only Dirty Runtime Sections

Problem: `apply_day_result` currently normalizes every selected company runtime every day. Late-run spikes suggest unchanged or already-normalized sections are being reprocessed too often.

1. Add a lightweight dirty-section contract for company runtime dictionaries.
   - recommended sections: `price`, `broker`, `story`, `financials`, `events`, `relationships`, `ui_summary`
2. Mark sections dirty when the simulator, company event system, story dossier system, filing layer, or relationship graph actually changes them.
3. Update `_normalize_day_result_company_runtime` to normalize only dirty sections plus mandatory daily price/broker fields.
4. Preserve a full-normalization path for:
   - load/migration
   - malformed runtime dictionaries
   - dev/debug validation
5. Ensure saved payloads do not persist transient dirty flags unless explicitly useful for load.
6. Add a deterministic comparison test:
   - run old/full normalization mode and dirty-section mode on the same seed
   - compare final prices, holdings, major event counts, and thesis evidence availability
7. Verify:
   - late-run `normalize_companies` p95 improves
   - full-year scenario still passes
   - broker range and annual filing targeted tests still pass if affected

## Task 4 - Bound Growing Story, Report, And Event Payload Normalization

Problem: After broker history was compacted, the next largest and most growth-prone sections are story dossier state, quarterly/report calendar, news/event archives, and company runtime story/report fields. These may not all need daily deep normalization.

1. Audit `company_story_dossier_state`, `quarterly_report_calendar`, `news_archive_articles`, and `event_history` for:
   - append-only growth
   - repeated derived summaries
   - duplicated prose/content
   - data that can be regenerated from deterministic IDs
2. Move stable derived summaries out of daily company runtime where possible.
3. Store references/IDs instead of repeated full text when content already exists in source catalogs or deterministic builders.
4. Add retention windows only where gameplay does not need full history.
   - Do not prune thesis evidence, saved filings the player captured, or player-visible journal history without a product decision.
5. Add a payload-size probe that reports section bytes after 25, 100, and 225 days.
6. Verify:
   - save compatibility with old payloads
   - filing/story/thesis evidence tests
   - late-run probe section-size reduction
   - no visible annual filing/story discovery regression

## Task 5 - Reduce Save Payload Construction Cost

Problem: Scheduled post-recap save still costs about `410ms`, and `RunState.to_save_dict()` alone costs about `191ms`. Disk write is only about `4ms`, so payload construction and serialization are the bottlenecks.

1. Add save payload construction telemetry by section:
   - base state
   - companies
   - company story dossier state
   - quarterly report calendar
   - news archive
   - event history
   - thesis/life/bank loan/network/social state
2. Add a targeted save payload perf test:
   - build a fixed late-year state
   - call `to_save_dict()`
   - serialize once
   - assert section timings and total bytes are reported
3. Cache safe section payloads between saves using dirty flags.
   - recommended first target: stable company profile/static fields and unchanged story dossier sections
   - do not cache mutable portfolio, price, broker current-day, loan, or thesis mutation fields without explicit invalidation
4. Consider split saves only if cached sections are not enough.
   - preferred first pass: keep one save file format for compatibility
5. Add load/save compatibility coverage for old saves and current saves.
6. Verify:
   - scheduled post-recap save below `250ms`
   - `to_save_dict_ms` below `100ms`
   - normal play perf sentinel
   - save/load compatibility tests

## Task 6 - Lock Budgets In Perf Tests And Update Known Issues

Problem: The previous recovery plan used soft budgets while the bottleneck was being characterized. Once late-run fixes land, the project needs hard budgets to stop drift.

1. Add hard budgets to `LateRunPerformanceProbeTest`:
   - `normalize_companies_p95 <= 180ms`
   - `normalize_companies_max <= 300ms`
   - no `500ms+` late-year normalization samples
2. Add hard or warning budgets to `NormalPlayPerfTest`:
   - scheduled post-recap save under `250ms`
   - `to_save_dict_ms` under `100ms`
   - short-run save bytes under the accepted new target after Task 5
3. Keep budgets realistic for headless timing noise; do not make CI-style tests flaky.
4. Update `docs/development/KNOWN_ISSUES.md`:
   - downgrade `KI-013` if late-run hitches are no longer visible
   - keep it if spikes remain, with updated measured numbers
5. Verify:
   - budget tests pass on two consecutive local runs if possible
   - `git diff --check`
   - headless editor gate

## Task 7 - Full Regression And Handoff Update

Problem: Dirty-section normalization and save payload caching touch core runtime/save behavior. Final validation must prove the game is faster without losing evidence, filings, broker ranges, or long-run event behavior.

1. Run targeted tests:
   - `LateRunPerformanceProbeTest.tscn`
   - `NormalPlayPerfTest.tscn -- --smoke-local-io`
   - save payload perf test
   - broker history/range tests
   - annual filing/story evidence tests touched by payload changes
2. Run product smoke:
   - quick smoke, recording the known FTUE result if still present
3. Run the 225-day full-year player scenario with catalog enabled.
4. Record a new test log under `docs/development/test_log/` with:
   - company count
   - elapsed/day
   - late-run p95/max normalization
   - save phase timings
   - save size and largest sections
   - portfolio/thesis/filing sanity
   - any known smoke blocker
5. Update `PROJECT_HANDOFF.md` with:
   - new plan link
   - final late-run baseline
   - any remaining performance risk
6. Verify:
   - `git diff --check`
   - headless editor gate
   - targeted perf/save tests
   - full-year scenario

## Known traps

- Optimizing normalization can silently skip migration/defaults. Keep a full-normalization path for load and malformed data.
- Dirty flags are easy to under-invalidate. Every system that mutates company runtime must either mark dirty sections or use an existing mutation helper that does.
- Full-year average can improve while a few late-year spikes remain bad. Track p95 and max, not only total elapsed.
- Save payload caching can corrupt saves if mutable sections are reused after a change. Start with static/profile sections and add invalidation tests.
- Annual filing content must stay lazy. Do not move expensive filing generation into startup or day advance.
- Broker-history compacting is already done. Do not spend this plan re-solving broker history unless a new probe proves regression.
- Quick smoke currently has a known FTUE organic-chain failure. Do not let that hide real performance failures, but do not block this plan on that unrelated assertion.
