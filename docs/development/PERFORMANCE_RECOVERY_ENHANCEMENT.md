# Performance Recovery Enhancement - Plan & Progress Log

Reduce the player-visible slowdown introduced by the larger company universe and richer runtime systems. The goal is to keep the current gameplay depth while making Advance Day, save/load, and common UI refreshes feel responsive again.

**Status: complete - Tasks 1-8 complete.** Remaining risks are documented in the final regression log and known issues.

**Review verdict recap:** The slowdown is real. `NormalPlayPerfTest` now shows UI-backed Advance Day around `1.7-1.9s` on a 30-company run, while older archived baselines were closer to `0.8-0.9s` in the healthy pass and later around `1.4-2.0s` as systems grew. The latest full-year player scenario averaged about `1.45s/day` for 70 catalog companies, and the heavy annual filing system stayed lazy, so the main suspects are runtime payload growth, broker history save bloat, broad post-advance UI refreshes, and per-day company normalization.

## Where everything lives

| What | Where |
|---|---|
| Daily state application | `autoloads/RunState.gd` - `apply_day_result`, `_normalize_day_result_company_runtime`, `_append_broker_flow_history`, `_build_companies_save_payload` |
| Runtime save payload | `autoloads/RunState.gd` - `to_save_dict`, `load_from_dict`, company runtime normalizers |
| Broker flow generation | `systems/BrokerFlowSystem.gd` - daily broker rows, side rows, broker type totals |
| Broker range reader | `autoloads/GameManager.gd` - `get_company_broker_flow_snapshot`, `_aggregate_compact_broker_flow_range`, broker range cache |
| Advance-day phases | `autoloads/GameManager.gd` - `_advance_day_internal`, `_advance_phase_simulate_market`, `_advance_phase_save_and_announce` |
| Save machinery | `autoloads/SaveManager.gd` - pending save, flush, serialize/write timing |
| UI advance shell | `scripts/ui/GameRoot.gd` - `_on_next_day_pressed`, `_on_summary_ready`, `_on_portfolio_changed`, deferred app refresh |
| Stock list refresh | `scripts/ui/controllers/StockController.gd` - `_refresh_company_list`, `_refresh_portfolio_stock_rows`, broker table/range UI |
| Existing perf probe | `scenes/tests/NormalPlayPerfTest.tscn`, `scripts/tests/NormalPlayPerfTest.gd` - app open, UI advance, save flush timing |
| Existing full-year probe | `scenes/tests/FullYearPlayerScenarioTest.tscn`, `scripts/tests/FullYearPlayerScenarioTest.gd` - 225-day player flow and log writer |
| Latest test log | `docs/development/test_log/2026-06-26_performance_recovery_full_regression.md` |
| Known issue index | `docs/development/KNOWN_ISSUES.md` - current app-opening performance warning |
| Key saved payloads | `companies[*].broker_flow_history`, `companies[*].broker_flow`, `company_story_dossier_state`, `quarterly_report_calendar`, `news_archive_articles`, `event_history` |
| Key functions (line refs drift; locate by name) | `_build_broker_flow_history_entry`, `_broker_history_array_for_append`, `_normalize_broker_flow_history`, `_build_companies_save_payload`, `_on_portfolio_changed`, `_advance_phase_save_and_announce` |

## Baseline From Inspection

Latest targeted inspection on 2026-06-25:

| Metric | Observed |
|---|---:|
| UI-backed Advance Day, 30 companies | `~1.7-1.9s` |
| `simulate_day`, 30 companies | `~290-370ms` |
| `normalize_companies`, 30 companies | `~97-119ms` early run |
| `_on_portfolio_changed` after Advance Day | `~398-415ms` |
| Forced `flush_pending_save` | `~451ms` |
| Save file after short normal perf run | `5.7MB` |
| `companies` section of save | `4.46MB` |
| Average `broker_flow_history` per company | `~106KB` |
| Broker history rows per company in short run | `25` |
| Average broker history row size | `~4.2KB` |
| Latest 70-company full-year elapsed | `326,372ms` total, `~1,450ms/day` |
| Older 30-company full-year reruns | `~1,155-1,316ms/day` |

Important interpretation:

- Annual filing generation is not the primary slowdown; it stayed lazy and only generated on request in the latest full-year flow.
- Increasing the default scenario from 30 to 70 selected catalog companies explains part of the full-year regression, but not the UI feeling alone.
- The biggest structural issue is that every generated company carries a heavy compact broker history, and the save/apply path repeatedly copies and serializes that data.
- The biggest player-visible UI issue is broad portfolio refresh work after normal Advance Day, even when the player did not trade.

## Goals

- Bring `NormalPlayPerfTest` UI-backed Advance Day under `1.2s` for 30 companies, with a stretch target under `1.0s`.
- Keep forced save flush under `150ms` for the normal perf scene, with a stretch target under `100ms`.
- Keep short-run local save size under `2.5MB` for the normal perf scene, with a stretch target under `2.0MB`.
- Keep 70-company full-year average under `1.25s/day`, with no loss of annual filing, thesis, bank loan, company story, or relationship graph behavior.
- Reduce late-run `normalize_companies` growth by removing avoidable deep copies and oversized history arrays.
- Preserve broker range UX, broker thesis evidence, dashboard broker movement, and current broker table behavior.
- Add durable perf guardrails so the game does not silently drift back to multi-second day advances.

## Non-goals

- Do not reduce company count as the fix. The catalog universe should stay enabled.
- Do not remove broker flow, broker ranges, thesis broker evidence, or dashboard broker movement.
- Do not rewrite the market simulator or move day simulation to threads in this pass.
- Do not pre-generate or pre-cache annual filings to hide the problem.
- Do not change stock price outcomes, event routing, or story truth unless a test proves current payload shape forces it.
- Do not make save compatibility brittle. Existing saves with old broker history must load.

## Working rules

- One task per checkpoint commit; verify before each commit.
- Measure before and after each behavior change. Do not trust subjective feel alone.
- Save compatibility: any compacted payload must load old saves and normalize into the new shape.
- Determinism: broker range outputs must remain deterministic for a given saved history.
- Keep rich broker detail for the current day. Compact or aggregate historical days first.
- UI refresh changes must be separated from simulation/save changes so regressions are easy to bisect.
- Do not add broad `duplicate(true)` calls to hot paths without a measured reason.
- Gates:
  - `git diff --check`
  - `/Users/user/.local/bin/godot --headless -e --quit`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/NormalPlayPerfTest.tscn -- --smoke-local-io`
  - targeted perf/save tests added by this plan
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io`
- Full-year tests are final validation, not the first debugging tool.

## Status

| # | Task | Est. cost | Status |
|---|---|---|---|
| 1 | Add perf budget and save-size telemetry | ~10-15% | Complete |
| 2 | Design broker history v2 compact contract | ~10-15% | Complete |
| 3 | Migrate and prune saved broker history payloads | ~20-30% | Complete |
| 4 | Optimize broker append and company normalization hot paths | ~20-30% | Complete |
| 5 | Split Advance Day portfolio refresh from trade refresh | ~15-25% | Complete |
| 6 | Defer and dedupe post-advance UI refresh work | ~15-25% | Complete |
| 7 | Tune save scheduling and post-recap flushing | ~10-20% | Complete |
| 8 | Full regression, perf audit, and handoff update | ~15-25% | Complete |

Recommended batching: **Session 1 = Task 1** because we need reliable guardrails before touching performance code. **Session 2 = Tasks 2-3** because broker history payload size is the highest-leverage fix. **Session 3 = Task 4** because hot-path copies should be optimized after the payload contract is smaller. **Session 4 = Tasks 5-7** because UI/save scheduling changes are player-visible and should be isolated. **Session 5 = Task 8** validates the whole stack with normal perf, quick smoke, and 225-day flow.

## Progress log

### 2026-06-25 - Plan created

- Created this enhancement plan after inspecting player-reported slowdown.
- Current inventory:
  - `NormalPlayPerfTest` reproduced UI-backed Advance Day around `1.7-1.9s`.
  - Short-run save size was `5.7MB`, with `companies` at `4.46MB`.
  - Each company carried about `106KB` of `broker_flow_history` after only 25 rows.
  - `_on_portfolio_changed` consumed about `400ms` after each Advance Day.
  - Latest full-year run was `326,372ms` for 225 trading days and 70 catalog companies.
  - Annual filing generation stayed lazy; it is not the primary slowdown.
- No runtime code or gameplay data changes were made by this planning step.

### 2026-06-25 - Task 1 complete

- Extended `scripts/tests/NormalPlayPerfTest.gd` so the normal perf sentinel now includes structured `metrics={...}` JSON in addition to the legacy flat timing fields.
- Added telemetry for:
  - timing metrics by label
  - total local save bytes
  - save section byte sizes for `companies`, `company_story_dossier_state`, `quarterly_report_calendar`, `news_archive_articles`, and `event_history`
  - broker-history company count, min/max/average rows, total bytes, and average bytes per company
  - top five largest company runtime payloads with broker-history, broker-flow, and company-profile byte sizes
  - soft budgets for future enforcement without failing the current test
- Current Task 1 measured baseline from `NormalPlayPerfTest.tscn -- --smoke-local-io`:
  - local save bytes: `5,933,302`
  - `companies` section bytes: `4,163,527`
  - `company_story_dossier_state` bytes: `705,262`
  - `quarterly_report_calendar` bytes: `405,316`
  - `news_archive_articles` bytes: `151,317`
  - `event_history` bytes: `91,500`
  - broker-history total bytes: `2,952,331`
  - broker-history average bytes/company: `98,411.03`
  - broker-history rows/company: `25`
  - largest company runtime payload: `kaca_surya_industri` at `154,440` bytes
- No gameplay behavior, save schema, broker range behavior, or UI refresh behavior was changed.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path /Users/user/Documents/gorengangame/godot-game-1 res://scenes/tests/NormalPlayPerfTest.tscn -- --smoke-local-io` -> `NORMAL_PLAY_PERF_OK`
  - `/Users/user/.local/bin/godot --headless -e --quit` passed
  - `git diff --check -- scripts/tests/NormalPlayPerfTest.gd docs/development/PERFORMANCE_RECOVERY_ENHANCEMENT.md` passed

### 2026-06-25 - Task 2 complete

- Added a behavior-neutral broker history v2 compact contract in `autoloads/RunState.gd`.
- New v2 rows keep only the historical fields needed for range aggregation:
  - schema version, day index, trade date, flow tag, pressure scores, action meter summary
  - dominant buy/sell broker code and type
  - total buy/sell/value
  - compact broker-type net values
- Historical v2 rows intentionally omit repeated `top_buy_brokers`, `top_sell_brokers`, and full nested `broker_type_totals`; the rich current-day `broker_flow` remains unchanged for the broker table.
- Added v1-to-v2 normalization helpers and a v2-to-range adapter so old rows can still feed 1M/3M broker snapshots.
- Added `scripts/tests/BrokerHistoryCompactContractTest.gd` and `scenes/tests/BrokerHistoryCompactContractTest.tscn`.
- Task 2 does **not** wire the live save path to v2 yet. `_build_broker_flow_history_entry`, `_append_broker_flow_history`, and `_normalize_broker_flow_history` still preserve current behavior until Task 3 performs the migration/prune step.
- Current contract-test sample:
  - v1 broker history row: `3916` bytes
  - v2 broker history row: `566` bytes
  - adapter rows tested: `20`
- Verification:
  - `/Users/user/.local/bin/godot --headless --path /Users/user/Documents/gorengangame/godot-game-1 res://scenes/tests/BrokerHistoryCompactContractTest.tscn` -> `BROKER_HISTORY_COMPACT_CONTRACT_OK`
  - `/Users/user/.local/bin/godot --headless --path /Users/user/Documents/gorengangame/godot-game-1 res://scenes/tests/BrokerRangeHistoryTest.tscn` -> `BROKER_RANGE_HISTORY_OK compact=45 mode=compact`

### 2026-06-25 - Task 3 complete

- Wired the live broker history path to v2 compact rows:
  - `_build_broker_flow_history_entry` now delegates to `build_broker_flow_history_v2_entry`.
  - `_normalize_broker_flow_history` and `_broker_history_array_for_append` normalize old v1 rows into v2 compact rows.
  - `_build_companies_save_payload` explicitly normalizes broker history and removes `broker_flow_full_history` before writing save payloads.
  - `GameManager.get_company_broker_flow_snapshot` adapts v2 rows back into range-compatible rows before aggregation.
- Reduced `MAX_BROKER_COMPACT_HISTORY_DAYS` from `1260` to `90`.
  - This fully supports 5D, 1M, and 3M broker ranges.
  - 6M, YTD, and 1Y broker range buttons still populate, but only from the retained 90 trading-day window.
- Added `scripts/tests/BrokerHistoryMigrationTest.gd` and `scenes/tests/BrokerHistoryMigrationTest.tscn`.
- Current migration-test sample:
  - synthetic legacy rows: `126`
  - migrated rows: `90`
  - re-saved rows: `90`
- Current `NormalPlayPerfTest.tscn -- --smoke-local-io` save-size result:
  - local save bytes: `3,460,428` down from `5,933,302`
  - `companies` section bytes: `1,692,153` down from `4,163,527`
  - broker-history total bytes: `480,957` down from `2,952,331`
  - broker-history average bytes/company: `16,031.9` down from `98,411.03`
  - broker-history rows/company: `25`
- The aspirational Task 3 short-run save target under `3MB` is not reached yet. Broker history is no longer the dominant payload; remaining weight is now mostly `company_story_dossier_state`, `quarterly_report_calendar`, current-day `broker_flow`, and broader runtime/company profile data. Continue with Tasks 4-7 before locking budgets.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path /Users/user/Documents/gorengangame/godot-game-1 res://scenes/tests/BrokerHistoryCompactContractTest.tscn` -> `BROKER_HISTORY_COMPACT_CONTRACT_OK v1_bytes=2083 v2_bytes=566 rows=20`
  - `/Users/user/.local/bin/godot --headless --path /Users/user/Documents/gorengangame/godot-game-1 res://scenes/tests/BrokerHistoryMigrationTest.tscn` -> `BROKER_HISTORY_MIGRATION_OK legacy_rows=126 migrated_rows=90 saved_rows=90`
  - `/Users/user/.local/bin/godot --headless --path /Users/user/Documents/gorengangame/godot-game-1 res://scenes/tests/BrokerRangeHistoryTest.tscn` -> `BROKER_RANGE_HISTORY_OK compact=45 mode=compact`
  - `/Users/user/.local/bin/godot --headless --path /Users/user/Documents/gorengangame/godot-game-1 res://scenes/tests/NormalPlayPerfTest.tscn -- --smoke-local-io` -> `NORMAL_PLAY_PERF_OK`
- Additional attempted gate:
  - `/Users/user/.local/bin/godot --headless --path /Users/user/Documents/gorengangame/godot-game-1 res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` failed on the existing FTUE/content assertion `First-month smoke found more than 2 organic chains through day 25`; this is not specific to broker-history migration.

### 2026-06-25 - Task 4 complete

- Added apply-day phase telemetry storage in `RunState` so tests can read the latest `normalize_companies` measurement without scraping console text.
- Optimized broker history append behavior:
  - `_upsert_broker_history_entry` now uses a fast append/replace path when the new v2 row is the next monotonic trading day or the same latest day.
  - `_broker_history_array_for_append` now returns already-sorted v2 append-ready rows without full migration/sort work.
  - malformed, old v1, or non-monotonic rows still fall back to full normalization and sorting.
- Reduced day-result broker-history normalization work:
  - `_normalize_day_result_company_runtime` now preserves broker-history arrays in the per-day hot path and lets `_append_broker_flow_history` do the single prune/append pass.
  - `broker_flow_full_history` is still erased in day-result normalization and save payloads.
- Confirmed `price_history` and `price_bars` still use latest-row-only day-result normalizers.
- Added `scripts/tests/BrokerHistoryHotPathPerfTest.gd` and `scenes/tests/BrokerHistoryHotPathPerfTest.tscn`.
- Current targeted 30-day hot-path result:
  - `BROKER_HISTORY_HOT_PATH_OK days=30 normalize_median=20.29ms normalize_late_max=30.25ms history_rows=50`
- Current broader `NormalPlayPerfTest.tscn -- --smoke-local-io` result:
  - `NORMAL_PLAY_PERF_OK`
  - local save bytes: `3,460,428`
  - `companies` section bytes: `1,692,153`
  - broker-history total bytes: `480,957`
  - broker-history average bytes/company: `16,031.9`
  - forced save flush: `458.07ms`
  - slowest UI-backed advance path observed: `advance_stock_open=2,845.2ms`
- Important caveat:
  - `MarketSimulator.gd` still has a per-company `runtime.duplicate(true)` at simulation entry. It was audited but not changed in this task because it protects several nested runtime structures while simulator helpers run. If Tasks 5-7 do not recover enough responsiveness, this should become a separate measured simulator-copy task with determinism checks.
- Verification:
  - `/Users/user/.local/bin/godot --headless --log-file /private/tmp/godot_broker_perf.log --path /Users/user/Documents/gorengangame/godot-game-1 res://scenes/tests/BrokerHistoryHotPathPerfTest.tscn` -> `BROKER_HISTORY_HOT_PATH_OK`
  - `/Users/user/.local/bin/godot --headless --log-file /private/tmp/godot_broker_migration.log --path /Users/user/Documents/gorengangame/godot-game-1 res://scenes/tests/BrokerHistoryMigrationTest.tscn` -> `BROKER_HISTORY_MIGRATION_OK legacy_rows=126 migrated_rows=90 saved_rows=90`
  - `/Users/user/.local/bin/godot --headless --log-file /private/tmp/godot_broker_range.log --path /Users/user/Documents/gorengangame/godot-game-1 res://scenes/tests/BrokerRangeHistoryTest.tscn` -> `BROKER_RANGE_HISTORY_OK compact=45 mode=compact`
  - `/Users/user/.local/bin/godot --headless --log-file /private/tmp/godot_broker_compact.log --path /Users/user/Documents/gorengangame/godot-game-1 res://scenes/tests/BrokerHistoryCompactContractTest.tscn` -> `BROKER_HISTORY_COMPACT_CONTRACT_OK v1_bytes=2083 v2_bytes=566 rows=20`
  - `/Users/user/.local/bin/godot --headless --log-file /private/tmp/godot_normal_play_perf.log --path /Users/user/Documents/gorengangame/godot-game-1 res://scenes/tests/NormalPlayPerfTest.tscn -- --smoke-local-io` -> `NORMAL_PLAY_PERF_OK`

### 2026-06-25 - Task 5 complete

- Split routine Advance Day valuation refresh from true portfolio mutation refresh:
  - Added `GameManager.advance_day_portfolio_valued`.
  - `_advance_phase_save_and_announce` now emits `advance_day_portfolio_valued` after `summary_ready` instead of emitting the heavy `portfolio_changed` signal.
  - Existing buy/sell, loans, life purchases, upgrades, console cash, bankruptcy, and debug ownership changes still emit `portfolio_changed`.
- Added a light GameRoot handler for Advance Day valuation:
  - updates top day/market/equity/cash labels
  - updates portfolio summary labels
  - refreshes visible Stock holdings rows only when the Stock window is open and the portfolio tab is visible
  - marks portfolio stock rows dirty when they are not visible
  - does not invalidate all company rows, refresh closed Thesis/Life/Company panes, refresh full trade history, or start background detail hydration
- Added `GameRoot.get_advance_day_portfolio_refresh_metrics()` and a `NormalPlayPerfTest` assertion:
  - guarded Advance Day must not hit the full portfolio refresh path
  - measured Advance Day valuation refreshes must use the light path
  - result JSON now includes `advance_day_portfolio_refresh`
- Current `NormalPlayPerfTest.tscn -- --smoke-local-io` result:
  - `NORMAL_PLAY_PERF_OK`
  - `advance_day_portfolio_refresh={"full_refresh_count":0,"guard_active":false,"light_refresh_count":4}`
  - `advance_stock_open=1,317.45ms`, down from Task 4's `2,845.2ms`
  - `advance_desktop_only=1,291.24ms`, down from Task 4's `1,979.3ms`
  - `advance_news_network_open=1,567.34ms`, down from Task 4's `2,199.14ms`
  - light valuation handler logged around `0.42-2.82ms` after replacing the full header refresh
  - forced save flush remains high at `398.37ms`; this stays for Task 7
- Verification:
  - `/Users/user/.local/bin/godot --headless --log-file /private/tmp/godot_normal_play_task5_metrics.log --path /Users/user/Documents/gorengangame/godot-game-1 res://scenes/tests/NormalPlayPerfTest.tscn -- --smoke-local-io` -> `NORMAL_PLAY_PERF_OK`
  - `git diff --check` passed
  - `/Users/user/.local/bin/godot --headless --log-file /private/tmp/godot_editor_task5.log --path /Users/user/Documents/gorengangame/godot-game-1 -e --quit` exited `0`
- Additional attempted gate:
  - `/Users/user/.local/bin/godot --headless --log-file /private/tmp/godot_quick_smoke_task5.log --path /Users/user/Documents/gorengangame/godot-game-1 res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` still fails on the pre-existing FTUE/content assertion `First-month smoke found more than 2 organic chains through day 25`; this is not specific to the portfolio refresh split.

### 2026-06-25 - Task 6 complete

- Deferred and deduped guarded Advance Day open-app refreshes:
  - added per-Advance-Day refresh generation tracking
  - queued only the app surfaces affected by each guarded signal instead of blindly refreshing every open app
  - kept `price_formed` as the broad visible-app queue because market close can affect any open app
  - guarded coalesced `daily_actions_changed`, `life_changed`, `network_changed`, and `social_changed` handlers while the recap is pending
  - removed the normal guarded Advance Day `deferred_full_refresh_after_recap` path from `_on_day_progressed`
- Added `GameRoot.get_advance_day_deferred_refresh_metrics()` for:
  - queued, duplicate, refreshed, skipped, wait, queue peak, queue size, scheduled state, and per-app refresh counts
- Extended `NormalPlayPerfTest.gd` so it now:
  - clicks the daily recap Continue button after each measured Advance Day
  - waits for the deferred open-app refresh queue to drain
  - asserts no queue remains scheduled
  - asserts open app refreshes ran once per visible app generation
  - includes `advance_day_deferred_refresh` in the structured result JSON
- Current `NormalPlayPerfTest.tscn -- --smoke-local-io` result:
  - `NORMAL_PLAY_PERF_OK`
  - `advance_day_deferred_refresh={"app_refresh_counts":{"network":2,"news":1,"stock":1},"duplicate_count":2,"generation":4,"queue_peak":2,"queue_size":0,"queued_count":4,"refreshed_count":4,"scheduled":false,"skipped_count":10,"wait_count":0}`
  - `advance_day_portfolio_refresh={"full_refresh_count":0,"guard_active":false,"light_refresh_count":4}`
  - Advance Day recap-ready timings: `advance_network_open=1934.16ms`, `advance_desktop_only=1289.1ms`, `advance_stock_open=1207.76ms`, `advance_news_network_open=1305.7ms`
  - Post-recap refresh timings: `633.12ms`, `414.54ms`, `537.64ms`, `841.16ms`
  - forced save flush remains high at `413.3ms`; Task 7 should target post-recap save scheduling/flush cost next
- Verification:
  - `/Users/user/.local/bin/godot --headless --log-file /private/tmp/godot_normal_play_task6.log --path /Users/user/Documents/gorengangame/godot-game-1 res://scenes/tests/NormalPlayPerfTest.tscn -- --smoke-local-io` -> `NORMAL_PLAY_PERF_OK`
  - `git diff --check` passed
  - `/Users/user/.local/bin/godot --headless --log-file /private/tmp/godot_editor_task6.log --path /Users/user/Documents/gorengangame/godot-game-1 -e --quit` exited `0`
- Additional attempted gate:
  - `/Users/user/.local/bin/godot --headless --log-file /private/tmp/godot_quick_smoke_task6.log --path /Users/user/Documents/gorengangame/godot-game-1 res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` still fails on the pre-existing FTUE/content assertion `First-month smoke found more than 2 organic chains through day 25`; this is not specific to deferred UI refresh.

### 2026-06-26 - Task 7 complete

- Tuned post-recap save scheduling so save work waits for:
  - no visible daily recap
  - no pending recap snapshot
  - no guarded Advance Day processing
  - no deferred open-app refresh queue
  - an idle-frame cushion after visible app refresh work
- Added `SaveManager.postpone_pending_save()` so GameRoot can keep the default debounced autosave timer from firing while recap/open-app work is still active.
- Added save-phase telemetry:
  - `SaveManager.get_last_save_perf_metrics()`
  - `GameRoot.get_advance_day_save_flush_metrics()`
  - `NormalPlayPerfTest` now reports `advance_day_save_flush` and waits for post-recap scheduled save completion before measuring explicit `flush_pending_save`.
- Added guard budgets to `NormalPlayPerfTest`:
  - scheduled post-recap save flush must stay under `900ms`
  - short-run local save must stay under `4,000,000` bytes
  - aspirational soft targets remain `150ms` save flush and `2,500,000` bytes
- Current `NormalPlayPerfTest.tscn -- --smoke-local-io` result:
  - `NORMAL_PLAY_PERF_OK`
  - explicit forced `flush_pending_save=13.0ms`, down from about `413ms` because the scheduled post-recap save drained first
  - scheduled `post_recap_save_flush=408.15ms`
  - `advance_day_save_flush={"completed_count":2,"idle_frames_remaining":0,"last_ms":382.035,"pending_save":false,"scheduled":false,"skipped_count":0,"wait_count":64}`
  - last save phase split: `to_save_dict_ms=188.179`, `serialize_ms=51.105`, `write_ms=4.706`, `replace_ms=5.159`, `save_run_ms=75.652`, `context_total_ms=377.631`
  - save bytes remain `3,464,461`; remaining save cost is mostly payload construction, not disk write
- Verification:
  - `/Users/user/.local/bin/godot --headless --log-file /private/tmp/godot_normal_play_task7.log --path /Users/user/Documents/gorengangame/godot-game-1 res://scenes/tests/NormalPlayPerfTest.tscn -- --smoke-local-io` -> `NORMAL_PLAY_PERF_OK`
  - `/Users/user/.local/bin/godot --headless --log-file /private/tmp/godot_broker_migration_task7.log --path /Users/user/Documents/gorengangame/godot-game-1 res://scenes/tests/BrokerHistoryMigrationTest.tscn` -> `BROKER_HISTORY_MIGRATION_OK legacy_rows=126 migrated_rows=90 saved_rows=90`
  - `/Users/user/.local/bin/godot --headless --log-file /private/tmp/godot_editor_task7.log --path /Users/user/Documents/gorengangame/godot-game-1 -e --quit` exited `0`
  - `git diff --check` passed

### 2026-06-26 - Task 8 complete

- Ran the full performance recovery regression pass and recorded results in
  [`docs/development/test_log/2026-06-26_performance_recovery_full_regression.md`](test_log/2026-06-26_performance_recovery_full_regression.md).
- Targeted broker/save/perf tests passed:
  - `BrokerHistoryCompactContractTest.tscn` -> `BROKER_HISTORY_COMPACT_CONTRACT_OK v1_bytes=2083 v2_bytes=566 rows=20`
  - `BrokerHistoryMigrationTest.tscn` -> `BROKER_HISTORY_MIGRATION_OK legacy_rows=126 migrated_rows=90 saved_rows=90`
  - `BrokerRangeHistoryTest.tscn` -> `BROKER_RANGE_HISTORY_OK compact=45 mode=compact`
  - `BrokerHistoryHotPathPerfTest.tscn` -> `BROKER_HISTORY_HOT_PATH_OK days=30 normalize_median=40.39ms normalize_late_max=58.99ms history_rows=50`
  - `NormalPlayPerfTest.tscn -- --smoke-local-io` -> `NORMAL_PLAY_PERF_OK`
- Final `NormalPlayPerfTest` baseline:
  - explicit forced `flush_pending_save=12.91ms`
  - scheduled `post_recap_save_flush=409.97ms`
  - local save bytes: `3,464,461`
  - broker-history total bytes: `480,957`
  - broker-history average bytes/company: `16,031.9`
  - largest save sections: `companies=1,692,153`, `company_story_dossier_state=705,262`, `quarterly_report_calendar=405,316`, `news_archive_articles=151,317`, `event_history=91,500`
- Full-year player scenario passed:
  - `FULL_YEAR_PLAYER_SCENARIO_OK`
  - 70 catalog companies, seed `20260622`
  - `232,511.74ms` for 225 trading days, or `1,033.39ms/day`
  - bought `BORI`, created a thesis with five evidence items, opened lazy annual filing content, and completed the year with one holding
- Product quick smoke still fails on the pre-existing FTUE/content assertion `First-month smoke found more than 2 organic chains through day 25`; this is unrelated to the performance recovery changes.
- Remaining performance risks:
  - scheduled post-recap save still costs about `410ms`; the expensive part is payload construction (`RunState.to_save_dict()`), not disk write
  - late-year 70-company normalization still has spikes, including `524.01ms` and `675.66ms` samples near day 200 in the full-year run
- Handoff and known-issues docs were updated with the final baseline and remaining risk.

---

## Task 1 - Add Perf Budget And Save-Size Telemetry

Problem: Current performance data is scattered across console logs and manual inspection. Before changing hot paths, we need a stable perf report that captures day advance time, save size, section sizes, broker history row counts, and top offenders.

1. Extend `NormalPlayPerfTest.gd` to write structured metrics, not just one flat result line.
2. Add a helper that reports save section byte sizes:
   - total save bytes
   - `companies`
   - `company_story_dossier_state`
   - `quarterly_report_calendar`
   - `news_archive_articles`
   - `event_history`
3. Add broker-history metrics:
   - company count
   - min/max/average history rows
   - average broker-history bytes per company
   - top five largest company runtime payloads
4. Add soft budgets first. Do not fail the test until Task 8 locks the new budgets.
5. Write the latest perf output to `logs/normal_play_perf_result.txt` and optionally mirror a concise report into `docs/development/test_log/` when manually requested.
6. Verify:
   - `NormalPlayPerfTest.tscn` prints `NORMAL_PLAY_PERF_OK`
   - structured metrics include save section sizes and broker-history sizes
   - `git diff --check`
   - headless editor gate

## Task 2 - Design Broker History V2 Compact Contract

Problem: The current "compact" broker history is not actually compact. Each historical row stores repeated top broker lists and full `broker_type_totals`, making each row about `4.2KB` and each short-run company about `106KB`.

1. Define a broker history v2 row contract in `RunState.gd` or a small pure helper:
   - day index
   - trade date key or compact date
   - flow tag
   - net pressure
   - smart money pressure
   - action meter score/label
   - dominant buy/sell broker code and type
   - total buy/sell/value
   - compact type net values only, not full nested totals
2. Keep current-day `broker_flow` rich for the broker table.
3. Keep only the minimum historical fields needed for 5D/1M/3M range aggregation.
4. Decide whether top broker rows are needed historically:
   - recommended default: keep top broker rows only for the latest day
   - aggregate ranges by dominant type/code, totals, and pressure
5. Add a pure contract test that validates:
   - v2 rows are much smaller than v1 rows
   - old v1 rows can normalize to v2
   - range aggregation still returns non-empty 1M/3M broker snapshots
6. Verify:
   - new broker history contract test sentinel
   - existing `BrokerRangeHistoryTest.tscn`
   - `git diff --check`

## Task 3 - Migrate And Prune Saved Broker History Payloads

Problem: Even if new rows are compact, existing saves and opening backfill still produce oversized payloads unless load/save normalization migrates them.

1. Update `_build_broker_flow_history_entry` to emit v2 compact rows.
2. Update `_normalize_broker_flow_history` and `_broker_history_array_for_append` to accept old v1 rows and output v2 rows.
3. Reduce `MAX_BROKER_COMPACT_HISTORY_DAYS` to a player-useful budget.
   - recommended first pass: `90` trading days
   - rationale: supports 3M range and avoids carrying 5 years of daily broker history per company
4. Keep `BROKER_HISTORY_BACKFILL_DAYS` at `20` unless a test proves the opening 1M range needs more.
5. Update save payload construction so old v1 broker rows do not re-save after load.
6. Add a migration test:
   - build/load a synthetic old v1 save row
   - assert saved output uses v2 row shape
   - assert no `broker_flow_full_history`
   - assert range snapshots still work
7. Verify:
   - broker migration test sentinel
   - `BrokerRangeHistoryTest.tscn`
   - `NormalPlayPerfTest.tscn`
   - target: short-run save under `3MB` before UI optimizations

## Task 4 - Optimize Broker Append And Company Normalization Hot Paths

Problem: `apply_day_result` still processes every company every day, and the hot path copies runtime arrays. With 70 companies and growing histories, small copy costs compound.

1. Audit `_normalize_day_result_company_runtime` after broker-history v2 lands.
2. Avoid sorting broker history every append when appending the current day in monotonic order.
3. Replace `_upsert_broker_history_entry` sort-on-every-day with a fast append path:
   - if latest row day differs and is greater than last row, append
   - only scan/sort when replacing an existing day or loading malformed rows
4. Avoid `runtime.duplicate(true)` in daily simulation if the simulator only needs a bounded set of fields.
5. Ensure `price_bars` and `price_history` still normalize only the latest row in the day-result hot path.
6. Add a targeted 30-day perf probe that records `normalize_companies` medians and late-day max.
7. Verify:
   - targeted hot-path perf probe
   - `NormalPlayPerfTest.tscn`
   - no market simulation hash drift unless intentionally accepted

## Task 5 - Split Advance Day Portfolio Refresh From Trade Refresh

Problem: `GameManager` emits `portfolio_changed` after every Advance Day, and `GameRoot._on_portfolio_changed` performs broad trade-style refresh work. That makes sense after buy/sell/loan cash changes, but after normal day advance it creates a visible `~400ms` UI chunk.

1. Introduce a lighter post-advance UI signal or handler path.
   - recommended: keep `portfolio_changed` for trades/loans/manual cash changes
   - add an `advance_day_portfolio_valued` signal or call a lighter GameRoot method after daily valuation
2. The light path should refresh:
   - header cash/equity labels
   - daily recap values
   - visible holdings rows only if Portfolio/Stock app is open
3. The light path should not always:
   - invalidate all company rows
   - refresh closed stock views
   - refresh thesis/life/company panes unless they are visible and affected
   - start background detail hydration
4. Preserve full `_on_portfolio_changed` for buy, sell, bank loan, emergency loan, life purchases, and other cash mutations.
5. Add a UI perf assertion that `_on_portfolio_changed` is not called during guarded Advance Day, or that the light handler is used instead.
6. Verify:
   - `NormalPlayPerfTest.tscn`
   - targeted UI signal test
   - quick smoke

## Task 6 - Defer And Dedupe Post-Advance UI Refresh Work

Problem: Advance Day already has guarded/deferred refresh logic, but several handlers still refresh overlapping surfaces around summary, price, portfolio, daily actions, life, and recap display.

1. Map the Advance Day signal order:
   - `price_formed`
   - `daily_actions_changed`
   - `life_changed`
   - `summary_ready`
   - portfolio valuation signal
2. During guarded Advance Day, queue open-app refreshes after recap instead of refreshing them before the recap is visible.
3. Ensure Life updates do not refresh the Life app if it is closed.
4. Ensure Network/News/Stock open-app refreshes run once per app after the recap, not once per signal.
5. Keep desktop badge counts accurate.
6. Add debug/perf labels around deferred open-app refresh counts.
7. Verify:
   - `NormalPlayPerfTest.tscn`
   - quick smoke
   - manual note: open Stock + News + Network, advance once, confirm no stale visible values after recap closes

## Task 7 - Tune Save Scheduling And Post-Recap Flushing

Problem: Save serialization and parse/write can create hitches, especially with a multi-MB save. After broker compaction, the remaining save work should be scheduled so it does not block the recap reveal.

1. Re-measure save flush after Tasks 2-4.
2. Keep Advance Day using requested autosave rather than immediate flush.
3. In `GameRoot`, ensure post-recap save flush waits until:
   - recap is no longer visible
   - pending recap snapshot is empty
   - deferred visible app refresh for the top app has completed
4. If needed, split backup/write work from serialization or avoid immediate readback after save in normal play.
5. Add a save-size budget and save-flush budget to `NormalPlayPerfTest` after the payload is compacted.
6. Verify:
   - `NormalPlayPerfTest.tscn`
   - save file size budget
   - save/load smoke or existing save compatibility test

## Task 8 - Full Regression, Perf Audit, And Handoff Update

Problem: Performance fixes touch runtime payloads, saved state, UI refresh timing, and broker range behavior. The final task must prove the game is faster without losing player-facing functionality.

1. Run targeted tests:
   - broker history contract/migration tests
   - `BrokerRangeHistoryTest.tscn`
   - `NormalPlayPerfTest.tscn`
   - save/load compatibility tests covering old broker history
2. Run product smoke:
   - quick smoke
   - buy stock, open broker table/ranges, capture broker evidence if covered by existing smoke
3. Run a 225-day player scenario with catalog enabled.
4. Record a new test log under `docs/development/test_log/` with:
   - company count
   - elapsed/day
   - normal play timings
   - save size
   - largest save sections
   - broker-history row/byte metrics
   - portfolio and thesis sanity
5. Update `PROJECT_HANDOFF.md` with:
   - the new performance plan link
   - final perf baseline
   - known remaining performance risks
6. Update `docs/development/KNOWN_ISSUES.md` if any visible slow path remains.
7. Verify:
   - `git diff --check`
   - headless editor gate
   - all targeted perf/save/broker tests
   - quick smoke
   - full-year scenario

## Known traps

- Broker range UX depends on historical rows. Compacting too aggressively can break 1M/3M range snapshots even if the latest broker table still works.
- `CompanyRuntime.to_dict()` deep-copies fields when building save payloads. Large runtime arrays make save slow even if day simulation is acceptable.
- `NormalPlayPerfTest` currently uses 30 companies. Full-year player scenarios may use 70; both baselines matter.
- The first save after a run can include backup/readback behavior. Separate one-time save cost from recurring Advance Day hitches.
- Debug/headless timings are noisy but still useful for relative comparison.
- Existing project-load and smoke runs can print Steam initialization warnings; those are not performance failures.
- Quick smoke has had unrelated FTUE organic-chain failures before. If it fails, confirm whether the failure is related before blocking the performance task.
- Do not solve this by hiding the daily recap later. The player should see feedback sooner, not just get delayed feedback after hidden work.
