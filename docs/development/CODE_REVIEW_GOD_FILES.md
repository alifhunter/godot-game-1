# Code Review: The Three God Files (Tier 5 Plan)

**Date:** 2026-06-11
**Scope:** `scripts/ui/GameRoot.gd`, `autoloads/GameManager.gd`, `autoloads/RunState.gd` (~43,000 lines combined)
**Status:** Review only — no changes made yet. Tiers 1–4 of the original fixing plan are complete (constants extraction, momentum fix, merge helper, constructor injection, typed `CampaignState` / `EventContext` / `CompanyProfile` classes).

> Line numbers below were accurate at review time and will drift as the code changes. Treat them as starting points, not exact anchors.

---

## Headline

All three files share the same disease: **too many unrelated domains in one file**, not broken logic. The simulation code itself is mostly sound. The fix is *moving* code, not rewriting it — which means most of Tier 5 can be done with zero behavior change.

| File | Lines | Functions | State vars | Role today |
|---|---|---|---|---|
| `GameRoot.gd` | 25,460 | 1,102 | 417 | Window manager + app launcher + per-app UI + data binding + theming + tutorials |
| `GameManager.gd` | 9,447 | 447 | 29 | Orchestrator + facade + formatter + debug console (identity crisis) |
| `RunState.gd` | 8,026 | 360 | 73 | 13 distinct state domains in one autoload |

---

## What's Good (preserve these patterns)

- **Deterministic seeding, done right.** Composable seed keys everywhere, e.g. `STABLE_RNG.rng([run_seed, "quarterly_filing", company_id, report_id])` (RunState ~3429). Collision-free, exact replay. The project's best asset.
- **Defensive load path.** `load_from_dict` (RunState ~464–559) defaults every field and deep-copies. A real migration layer exists: `_normalize_*` functions handle legacy FTUE/guide state and deprecated life-location IDs.
- **Perf instrumentation.** Phase-timed logging gated behind flags in both GameManager (`_log_advance_perf_elapsed`) and GameRoot (`_log_perf_phase`, `_refresh_all` phase logs ~2790–2854).
- **Clear signal vocabulary.** GameManager's 20 signals partition concerns well; GameRoot connects them all in one auditable place in `_ready` (~1121–1132).
- **Smart caching.** Intel-level-aware cache keys (GameManager ~6477–6537); bounded history with decay pruning (`_prune_player_market_flows`, RunState ~6218).
- **Validation gate pattern.** Finance gate resolved before every day advance (GameManager ~967).
- **Lazy hydration queue** for company detail profiles with priority override (RunState ~877–922).
- **GameRoot constants block** (~36–320): colors/dimensions centralized per theme.

---

## What's Bad

### GameRoot.gd — worst of the three

1. **Mixed responsibilities.** Window lifecycle, app switching, refresh orchestration, data binding, runtime UI construction, theming (`_apply_visual_theme`, 299 lines, ~22984), and the tutorial/guide system all in one file. Zero signals of its own — everything routes through GameManager.
2. **State management hazard.** 417 vars including 17 `pending_*_capture_payload` dicts and 4 competing `deferred_*_refresh` flags with unclear precedence. Snapshot vars (`current_trade_snapshot`, etc.) have no lifecycle/invalidation markers.
3. **Duplicated families, no abstraction.**
   - ~70 `_style_*` functions called linearly from `_apply_visual_theme`.
   - 7 near-identical `_build_key_stats_*_rows` builders (~2090–2255).
   - 15+ `_refresh_*` functions, each different, no shared pattern.
   - 10 trivial `_on_*_app_pressed` stubs (~15104–15143) that each call `_set_active_app`.
4. **UI built in code, not scenes.** `_ensure_social_feed_ui` (283 lines, ~20906), `_ensure_academy_ui` (257 lines, ~5505), `_ensure_figma_desktop_ui` (200 lines, ~3629) — 30–40 nodes constructed inline with hardcoded margins and `Vector2` sizes scattered across functions.
5. **Refresh cascade hazards.** No coalescing: two signals in one frame → double refresh. `_build_key_stats_context` (113 lines, ~1977) recomputes from scratch every refresh, no caching. Deferred open-app refresh queue can be overwritten if `_refresh_all` re-enters before frame end (~2896–2939).
6. **Tight autoload coupling.** 314+ direct `GameManager.`/`SaveManager.` calls scattered through UI functions; nothing is testable in isolation.

Top offenders by length: `_apply_visual_theme` 299, `_ensure_social_feed_ui` 283, `_ensure_academy_ui` 257, `_ensure_corporate_action_ui` 242, `_ensure_figma_desktop_ui` 200, `_ensure_settings_dialog` 190, `_ready` 183, `_ensure_news_newspaper_ui` 181, `_build_social_post_card` 166, `_apply_trade_workspace_snapshot` 160.

### GameManager.gd — identity crisis

1. **Orchestrator AND facade AND consumer.** 618 references to `RunState.` — it mutates state, queries it, and re-exposes it as snapshots. No clear owner of data consistency.
2. **Duplicated business logic.** Ownership math appears in both `get_company_ownership_snapshot` (~2920–2970) and inline in `get_company_snapshot` (~3087–3101). `portfolio_changed` emission points repeated 6+ times.
3. **UI formatting in a game-state autoload.** `_format_currency`, `_format_decimal`, `_format_currency_compact`, plus 20+ `_*_label` generators (~150 lines, ~6155–8770). All pure functions — trivially movable.
4. **~300 lines of debug console** (`debug_*`, `execute_console_command`, ~1252–2118) in the production autoload, not gated behind `OS.is_debug_build()`.
5. **Cache coherency by hand.** 5 snapshot caches, ~50 scattered invalidation callsites; some paths rebuild eagerly (~1039), others invalidate lazily. One missed call = stale dashboard.
6. **Signal spaghetti in `_advance_day_internal`** (135 lines, ~964–1097): 8 conditional signal emissions, each cascading into GameRoot's refresh handlers — order-dependent and hard to trace.
7. **Save/load without schema validation.** `load_run_from_save` blindly delegates to `RunState.load_from_dict`, followed by 4× duplicated manual cache-invalidation blocks (~805, ~852, ~893, ~921).
8. **Magic numbers**: relevance group thresholds (~1801, ~2113–2140), free-float floors and depth ratios (~3121, ~3142–3149).

Top offenders: `get_company_snapshot` 139, `_advance_day_internal` 135, `_build_first_month_next_five_rows` 110, `_apply_life_daily_wellbeing_update` 105, `process_life_development_leads` 102, `get_stock_contact_tip_options` 99, `get_life_snapshot` 98, `_create_life_development_lead` 98.

### RunState.gd — 13 domains in one autoload

Domains found: portfolio/trading, companies runtime, thesis/research, **life sim**, **contacts/network**, **Twooter**, corporate events, news archive, market/macro, academy/progression, desktop-app UI state, guide/FTUE, hydration queue.

1. **Life sim doesn't belong** (~500 lines: ~1794–2125, ~3168–3600). Housing, cars, stress, happiness, burnout, hospitalization, bankruptcy, legal holds, loans — a parallel simulation engine. Trading functions (`buy`/`sell`) call `refresh_cash_stress_state()` directly (~1128, ~1209, ~1506).
2. **Network/contacts and Twooter state also squat here** (~160–164, ~1713–1752, ~3610–3744).
3. **Stringly-typed everything.** ~1,800 `.get("string_key")` calls. The `companies` dict is a poor-man's class: `_normalize_company_runtime` (~7469–7517) spends 48 lines validating one entry. The fetch→typeof-check→default→`duplicate(true)` pattern repeats 20+ times.
4. **Corporate-action application bodies are massive** (~4288–5856, ~1,500 lines): eleven `_apply_*_application` functions at 80–200 lines each (dividend, rights issue, private placement, restructuring, buyback, tender offer, M&A, backdoor listing, CEO change, split, stock dividend). This domain logic overlaps `systems/CorporateActionSystem.gd`.
5. **Save schema version written but never read.** No `_migrate_vN_to_vN+1` functions; migration relies entirely on scattered per-field normalizers. Field renames break old saves silently.
6. **News archive stores every article twice**: 4-level nested index (`outlet → years → months → articles`) AND a flat `news_archive_articles` dict with 40+ mirrored fields (`_upsert_news_archive_article`, 142 lines, ~7200–7342). Mutation of one can desync the other.
7. **Duplicated finance fetch/modify/store** in 5+ places (~1851, ~1872, ~2043).
8. **Inline magic numbers** in quarterly filing math: `lerpf(..., 0.58)` (~7291), growth interpolation weights `0.22/0.46/0.34/0.20` (~6460–6477), margin pressure weights (~6487–6494).

Top offenders: `_apply_company_backdoor_listing_state` 180, `_build_quarterly_filing_payload` 174, `_upsert_news_archive_article` 142, `_apply_ceo_change_application` 121, `load_from_dict` 96, `_apply_backdoor_listing_application` 93.

---

## Tier 5 Plan — easiest first

### 5a. Zero-risk quick wins (hours–days each)

| # | Task | File | Est. |
|---|---|---|---|
| 1 | Move `_format_*` / `_*_label` into a `UIFormatter` helper (all pure functions) | GameManager | 0.5 day |
| 2 | Gate debug console behind `OS.is_debug_build()` or move to `tests/` | GameManager | 0.5 day |
| 3 | Collapse 17 `pending_*_capture_payload` vars into one keyed dict | GameRoot | 0.5 day |
| 4 | Replace 10 `_on_*_app_pressed` stubs with a bound loop in `_ready` | GameRoot | 0.5 day |
| 5 | Consolidate repeated finance fetch/modify/store into one `_update_finance` helper | RunState | 1 day |
| 6 | Name the inline magic numbers in quarterly filing math | RunState | 0.5 day |

### 5b. Domain extractions (the real payoff; still zero-behavior-change)

| # | Task | Est. | Risk |
|---|---|---|---|
| 7 | Extract life sim from RunState into its own autoload/system (~500 lines); RunState keeps pass-through getters | 3 days | Low |
| 8 | Extract network/contacts + Twooter state from RunState | 1–2 days | Low |
| 9 | Move RunState's `_apply_*_application` corporate-action bodies into/next to `CorporateActionSystem` | 3–4 days | Medium — needs tests first |
| 10 | Extract thesis manager (~35 funcs) and life manager (~25 funcs) out of GameManager | 2–3 days each | Medium |
| 11 | Unify the news archive's double representation behind one manager | 2–3 days | Medium |

### 5c. Structural (riskiest; do last, one piece at a time)

| # | Task | Est. | Notes |
|---|---|---|---|
| 12 | Per-app controllers for GameRoot: pull each "app" (stock, news, social, academy…) into its own scene + script; GameRoot shrinks to a window manager | 1–2 weeks, phased | Biggest win — GameRoot is ⅔ of the problem. Ship one app at a time. |
| 13 | Refresh coalescer in GameRoot: queue refresh scopes, batch once per frame | 2 days | Kills double-refresh hazards |
| 14 | Typed `CompanyRuntime` class (continue the Tier 4 `CampaignState` pattern); migrate callsites gradually via a wrapper getter | 5–7 days | High touch count (~40 callsites) |
| 15 | Real save-version migration functions (`_migrate_v6_to_v7`, …) keyed off the already-written schema version | 2 days | Test against real save files |
| 16 | Split `_advance_day_internal` into named phases | 2 days | After 5b shrinks its body |

### Recommendation

**5a + 5b deliver most of the value at low risk.** Item 12 (GameRoot per-app controllers) is the single biggest improvement but also the largest job — only start it once 5a/5b have landed and the editor still reports zero errors after each step.

### Working rules (carried over from Tiers 1–4)

- Keep public dict-in/dict-out signatures at system boundaries for save compatibility; type internals only.
- Verify after every extraction: `reload_project` + `get_editor_errors` (0 expected) + compile checks on every dependent file.
- Note: running `validate_script` directly on a file with `class_name` reports a spurious "hides a global script class" error (the MCP tool compiles a temp copy). Validate dependents instead.
