# God Files Enhancement — Progress Log

Tracks the Tier 5 refactor of the three god files. **Tiers 5a, 5b, and 5c Sessions 1-9 are complete (2026-06-12); per-app GameRoot controller extraction is done.**

| God file | Tier 5 start | Current | Change |
|---|---|---|---|
| `scripts/ui/GameRoot.gd` | 25,460 | 16,076 | 5c target (per-app controllers; Upgrades + Academy + Network + Life + Company + Social + News + Stock extracted) |
| `autoloads/GameManager.gd` | ~9,447 | 7,063 | −2,384 |
| `autoloads/RunState.gd` | 8,026 | 6,432 | −1,594 |

Six new focused systems plus eight UI controllers extracted: `UIFormatter`, `LifeStateSystem`, `TwooterStateSystem`, `CorporateActionApplications`, `ThesisManager`, `LifeManager`, `UpgradesController`, `AcademyController`, `NetworkController`, `LifeController`, `CompanyController`, `SocialController`, `NewsController`, `StockController` (~20,000 lines of relocated, now-testable logic). Every step verified zero-behavior-change.
Full review and rationale: [CODE_REVIEW_GOD_FILES.md](CODE_REVIEW_GOD_FILES.md).
Working rules: zero behavior change per step; dict-in/dict-out at system boundaries for save compatibility; verify each step with a headless editor pass (`godot --headless -e --quit`, expect zero script errors) and the quick smoke test (`godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io`, expect `SMOKE_QUICK_OK`).

## Status

| Tier | Scope | Status |
|---|---|---|
| 5a | Zero-risk quick wins | ✅ Done 2026-06-11, smoke-verified |
| 5b-7 | Life sim logic → `systems/LifeStateSystem.gd` | ✅ Done 2026-06-11, smoke-verified (identical equity) |
| 5b-8 | Twooter normalizers → `systems/TwooterStateSystem.gd` | ✅ Done 2026-06-11, smoke-verified (identical equity) |
| 5b-9 | Corporate-action applications → `systems/CorporateActionApplications.gd` | ✅ Done 2026-06-11, audit-verified (120-day byte-identical) |
| 5b-10a | Thesis domain → `systems/ThesisManager.gd` | ✅ Done 2026-06-11, thesis-test + smoke verified |
| 5b-10b | Life domain → `systems/LifeManager.gd` | ✅ Done 2026-06-11, smoke-verified (identical equity) |
| 5b-11 | News archive dedup | ⏸ Deferred — single-writer confirmed (no desync risk today); fold into 5c-15 save migrations |
| 5c Session 1 | Stability batch: refresh coalescer (13), advance-day phases (16), save migrations (15) | ✅ Done 2026-06-11, each task committed as its own checkpoint |
| 5c Session 2 | Upgrades app controller extraction (12 first slice) | ✅ Done 2026-06-11, script + smoke verified |
| 5c Session 3 | Academy app controller extraction (12 second slice) | ✅ Done 2026-06-11, script + smoke verified |
| 5c Session 4 | Network app controller extraction (12 third slice) | ✅ Done 2026-06-11, script + smoke verified |
| 5c Session 5 | Life app controller extraction (12 fourth slice) | ✅ Done 2026-06-12, editor + smoke verified |
| 5c Session 6 | Company app controller extraction (12 fifth slice) | ✅ Done 2026-06-12, MCP + smoke verified |
| 5c Session 7 | Social app controller extraction (12 sixth slice) | ✅ Done 2026-06-12, MCP + smoke verified |
| 5c Session 8 | News app controller extraction (12 seventh slice) | ✅ Done 2026-06-12, MCP + smoke verified |
| 5c Session 9 | Stock app controller extraction (12 final slice) | ✅ Done 2026-06-12, MCP + smoke verified |
| 5c review | Independent 3-reviewer pass over the controller decomposition | ✅ Done 2026-06-12 — verdict: sound, no real bugs; see "Controller decomposition review" below |
| Follow-up A | Manual click-through playtest of all 8 apps, then checkpoint commit | ✅ Done 2026-06-12 — playtest clean, committed `e5c3bfc` |
| Follow-up B | Warnings cleanup pass (44 behavior-neutral edits across 7 files) | ✅ Done 2026-06-12 — committed `20211ee`, smoke byte-identical |
| Follow-up C | Shared `UITheme` constants (`scripts/ui/UITheme.gd`, 75 colors; 193 duplicate lines collapsed via preload aliases) | ✅ Done 2026-06-12 — committed `9e2d49e`, smoke byte-identical |
| Follow-up D | Controller-owned state (retire the manual sync layer) | 🔶 5/6 done 2026-06-12 — Company `8490cfd`, Academy `dfe933e`, News `494fe5e`, Social `8bff2dd`, Network `636e9d4`. **Stock remains** (own session: 80+ vars, ~15 GameRoot readers of selected_company_id). Life/Upgrades never had duplicated state (N/A). |
| 5c item 14 | Typed `CompanyRuntime` class, gradual callsite migration | ⬜ Planned |

---

## Tier 5a — completed 2026-06-11

### 5a-1: UIFormatter extraction (better than planned)
- **New file:** `systems/UIFormatter.gd` (`class_name UIFormatter`, static funcs).
- The formatters were duplicated across **six** files, not just GameManager: GameManager, RunState, GameRoot, LifeWidget, ThesisBoardWidget, TradeWorkspaceWidget. All six now delegate; local `_format_*` wrappers kept so internal callsites are untouched.
- Three distinct styles preserved exactly:
  - `format_currency` — full grouped "Rp1.234.567,89" (GameManager/RunState/GameRoot/TradeWorkspaceWidget style)
  - `format_currency_compact` — "Rp1.23T" with dot decimals (GameManager `_format_currency_compact`, LifeWidget/ThesisBoardWidget `_format_currency`)
  - `format_compact_currency` — "Rp1,23T" with comma decimals (GameRoot-only style)
  - plus `format_decimal`, `format_grouped_integer`, `format_percent`
- **Deliberately NOT moved:** GameManager's `_*_label` functions (thesis/life/broker labels) — they're domain logic coupled to snapshots; they move with the 5b thesis/life extractions instead.

### 5a-2: Debug tools gated behind debug builds
- All **29** mutating `debug_*` functions in `GameManager.gd` now early-return `{"success": false, "message": "Debug tools are only available in debug builds."}` when `not OS.is_debug_build()`.
- The **Ctrl+L** debug overlay toggle in `GameRoot._unhandled_input` is now gated by `OS.is_debug_build()` (it previously opened the full debug panel in release builds — real shipping bug).
- Left ungated on purpose: `get_debug_*` catalogs (read-only; SmokeTest uses one) and `execute_console_command` cheat codes ("cuankus", "ordalbos" — intentional player-facing cheats).

### 5a-3: Capture payloads consolidated
- 9 `pending_*_capture_payload` vars in GameRoot replaced by one `pending_capture_payloads: Dictionary` keyed by kind: `key_stats`, `trade_quote`, `social`, `news_article`, `dashboard_sector`, `profile`, `corporate_action`, `broker`, `financial_statement`.
- New shared `_commit_pending_capture(kind, id)` helper replaced 8 byte-identical `_on_*_capture_menu_id_pressed` bodies (each is now a one-liner).
- The news-article flow keeps its custom kind-menu logic but stores in the same dict (reads via `.get()` to avoid missing-key errors).

### 5a-4: Trivial app-button stubs removed
- 7 trivial `_on_*_app_pressed` stubs (stock, news, social, network, life, company, upgrades) deleted; buttons connect directly via `_set_active_app.bind(APP_ID_*)` in `_ready`.
- Kept as real handlers: `_on_academy_app_pressed` (release-lock gating), `_on_thesis_app_pressed` (deferred FTUE refresh), `_on_settings_app_pressed`.
- Verified no scene-file (.tscn) signal connections referenced the deleted stubs.

### 5a-5: Finance access unified in RunState
- `get_life_finance()` / `set_life_finance()` were already the canonical normalize-fetch/normalize-store helpers; five sites were inlining the raw pattern instead. Now all finance mutations go through them: `pause_cash_stress_deadline`, `refresh_cash_stress_state`, `mark_bankruptcy`, `apply_emergency_loan_proceeds`, and the loan-payment path.
- The only remaining `player_life["finance"] = ...` is inside `set_life_finance` itself.

### 5a-6: Quarterly filing weights named
- 12 new constants in RunState (near the other consts, ~line 130): `FILING_QOQ_BASE_GROWTH_WEIGHT/MACRO/MICRO/MARKET`, `FILING_YOY_MACRO/MICRO/MARKET`, `FILING_YOY_BLEND_WEIGHT` (the 0.58 QoQ/YoY lerp), `FILING_MARGIN_STRENGTH/EXECUTION_CONSISTENCY/BALANCE_SHEET_WEIGHT`.
- `_build_quarterly_filing_payload` growth/margin math now reads these. Values unchanged.

### Verification (5a)
- Headless editor pass: zero script errors.
- Quick smoke: `SMOKE_QUICK_OK normal_equity=94765318.11 days=3` (RID-leak warnings at exit are normal headless teardown noise).
- Note: the Godot editor was closed during this session, so verification used the CLI (`~/.local/bin/godot`). The MCP `validate_script` quirk still applies: validating a `class_name` file directly reports a spurious "hides a global script class" error — validate dependents instead.

---

## Tier 5b-7 — life sim extraction, completed 2026-06-11

- **New file:** `systems/LifeStateSystem.gd` (545 lines, `class_name LifeStateSystem`, all static funcs + life-sim constants). RunState went 8,026 → 7,597 lines.
- **State stays in RunState** (`player_life` dict, save format untouched); only logic moved. All public RunState life functions kept their exact names/signatures — GameManager and UI callers unchanged.
- Moved as statics (renamed without underscore): `default_life_state/legal/finance`, `normalize_life_state/location_id/properties/property_value_events/development_leads/cars/legal_state/finance_state/loan`, `life_location_label_for_normalized_id`, `sanitize_legacy_life_location_text`, `append_life_finance_history`, `stress_ap_penalty`, `stress_stage`, `update_cash_stress`, `start_emergency_loan`. Context (day_index, run_seed, trade_date, cash) passed as explicit params.
- RunState's 15 private life functions are now one-line delegates; `refresh_cash_stress_state` delegates its core to `update_cash_stress`; `apply_emergency_loan_proceeds` delegates loan construction to `start_emergency_loan` (the `player_portfolio["cash"]` mutation and `_record_trade` side effects stay in RunState by design).
- Life constants now live in LifeStateSystem; RunState keeps `const X := LIFE_STATE_SYSTEM.X` aliases (via preload) because GameManager/UI reference `RunState.LIFE_*`. `LIFE_HOSPITAL_RECOVERY_STRESS/HAPPINESS` stayed literal in RunState (used by hospital logic that didn't move).
- Verified: headless editor pass clean; smoke test `SMOKE_QUICK_OK normal_equity=94765318.11 days=3` — byte-identical equity to the pre-extraction run, confirming deterministic behavior preserved.

## Tier 5b-8 — Twooter normalizers extraction, completed 2026-06-11

- **New file:** `systems/TwooterStateSystem.gd` (`class_name TwooterStateSystem`, static funcs). RunState 7,597 → 7,450 lines (8,026 at Tier 5 start).
- Moved the 7 pure normalizers: `default_social_state`, `normalize_social_state` (take `day_index`), `normalize_account_state`, `normalize_post_interaction`, `normalize_liked_post`, `normalize_message_thread`, `normalize_dialog_branch`. RunState's `_default_twooter_social_state` / `_normalize_twooter_*` are now one-line delegates; `twooter_social_state` state and save shape untouched.
- The network contacts/discoveries/requests/tip-journal vars stayed in RunState: their accessors are already trivial getters/setters — nothing worth extracting until a richer NetworkState domain move (defer to 5c-era work if ever).
- Verified: editor pass clean; smoke `SMOKE_QUICK_OK normal_equity=94765318.11` — identical equity again.

## Tier 5b-9 — corporate-action applications extraction, completed 2026-06-11

- **New file:** `systems/CorporateActionApplications.gd` (1,022 lines, `class_name CorporateActionApplications`, static funcs). RunState 7,450 → 6,432 lines (8,026 at Tier 5 start).
- Pattern: **explicit-state statics** — each function takes the RunState instance as untyped first param (`apply_rights_issue_application(state, application)`); bodies are verbatim with `state.` prefixed on RunState members/methods. RunState keeps the `_apply_corporate_action_applications` dispatcher (exact signature) whose match branches delegate with `self`.
- 13 functions moved: rights issue, private placement, restructuring, buyback, tender offer, strategic M&A, backdoor listing (+ company backdoor state helper), backdoor lockup/milestone updates, CEO change, stock split, and `apply_player_stock_split` (its only caller was the stock-split apply).
- Player/company helpers used by multiple domains stayed in RunState and are called via `state.` (e.g. `_apply_company_price_factor`, `_set_company_share_structure`, `_record_trade`).
- Verified: editor pass clean; smoke `SMOKE_QUICK_OK normal_equity=94765318.11` identical; **MarketYearAudit 120 days** (`--audit-days 120 --audit-seed 20260606 --audit-difficulty grind`) byte-identical before/after once perf-timing lines are masked — every market value, price, event count, and campaign stat matched. Baselines saved at `/tmp/ca_audit_before.txt` / `/tmp/ca_audit_after.txt`; pre-edit RunState copy at `/tmp/RunState.gd.bak`.
- The MarketYearAudit command is the gold-standard behavioral check for future RunState/market refactors — capture the baseline BEFORE editing.

## Tier 5b-10a — thesis manager extraction, completed 2026-06-11

- **New file:** `systems/ThesisManager.gd` (1,050 lines, 61 statics). GameManager 9,476 → 8,492 lines.
- Same explicit-state pattern: 15 public functions kept in GameManager as exact-signature delegates passing `self`; 46 private helpers fully moved (underscore dropped); moved publics call each other as statics directly.
- Pure helpers (touching only RunState/DataRepository/locals) take no `gm` param at all. GM-coupled ones take `gm` and reach signals (`thesis_changed`), systems (`thesis_report_system`), and shared helpers via `gm.`.
- Stayed in GameManager with reason: `get_thesis_report_action_cost` (trivial const getter), `_life_thesis_public_image_score` (life domain), Twooter interaction functions (thesis_id is just a param), chart-pattern catalog/eval (chart domain).
- Verified: editor pass clean; smoke byte-identical; dedicated `ThesisResearchTrayTest.tscn` → `THESIS_RESEARCH_TRAY_OK` with empty diff vs baseline (after filtering perf lines).

## Tier 5b-10b — life manager extraction, completed 2026-06-11

- **New file:** `systems/LifeManager.gd` (1,495 lines, 56 statics). GameManager 8,492 → 7,063 lines (~9,447 at Tier 5 start).
- Same pattern: 15 publics kept in GameManager as exact-signature delegates (`get_life_snapshot`, `set_life_plan`, `purchase_life_property/car`, `process_life_development_leads`, lead discovery, debug forcers...); 41 privates fully moved (the four `_apply_life_*` daily appliers, property/car catalogs and pricing, the lead engine, public-image snapshot, labels used only by moved code).
- Stayed in GameManager with reason: life-development *news-feed* plumbing (consumed by `LifeDevelopmentIntelTest` and the news domain), daily-recap/dashboard snapshot builders, helpers shared with staying code (moved code reaches them via `gm.`), and all `LIFE_*` constants (external `GameManager.LIFE_*` references preserved).
- Debug forcers keep their `OS.is_debug_build()` guard in the GameManager delegate.
- Note: `systems/LifeStateSystem.gd` (5b-7, RunState-side dict normalizers) and `systems/LifeManager.gd` (GameManager-side orchestration) are deliberately separate layers.
- Verified: editor pass clean; smoke `SMOKE_QUICK_OK normal_equity=94765318.11` identical. Pre-edit backup at `/tmp/GameManager_pre_life.bak`.

## Tier 5b-11 — news archive dedup: DEFERRED 2026-06-11

- Investigated: both `news_archive_index` (4-level nested) and `news_archive_articles` (flat) are written ONLY inside RunState's `_upsert_news_archive_article` path (grep-verified, no other writers anywhere). The duplication is wasteful but consistent-by-construction — the desync risk flagged in the review is theoretical until a second writer appears.
- The real fix (single representation + adapter that reconstructs the legacy save shape) requires the save-version migration infrastructure. Fold this into 5c item 15 instead of doing a risky standalone restructure.

## Tier 5c Session 1 — stability batch, completed 2026-06-11

Each task is its own git checkpoint. Baseline commit `16f15ac` holds the whole Tier 1–5b batch.

### 13. Refresh coalescer — commit `d279d4d`
- The nine no-arg GameManager refresh signals in GameRoot now connect through `_queue_signal_refresh(handler)`: same-frame duplicate signals collapse to one handler run, flushed once at end of frame in **arrival order** (preserves the upgrades→portfolio `suppress_next_portfolio_refresh` handshake). Arg-carrying signals (`price_formed`, `summary_ready`, `company_detail_ready`) stay directly connected.
- `advance_day_processing` spans multiple frames (the advance flow awaits between phases), so coalesced handlers flushing at end-of-frame still take their deferred-queue paths mid-processing — semantics preserved.
- **Finding:** the FULL smoke suite (`--smoke-local-io` without `--smoke-quick`) fails on a pre-existing RUPSLB overlay layout assertion — verified present on the baseline commit before this change. The quick smoke is the reliable gate.

### 16. Advance-day named phases — commit `4bb362c`
- `_advance_day_internal` is now a ~25-line orchestrator over six phases: `_advance_phase_simulate_market`, `_advance_phase_apply_life`, `_advance_phase_process_events`, `_advance_phase_emit_market_signals`, `_advance_phase_build_summary_and_news`, `_advance_phase_save_and_announce`. Bodies verbatim; ordering, emission conditions, and perf labels unchanged.

### 15. Save-version migrations — commit `1e23e0e`
- **New file:** `systems/SaveMigrations.gd`. `RunState.load_from_dict` routes the loaded dict through `SaveMigrations.migrate()`, which upgrades stepwise by version. `RunState.SAVE_SCHEMA_VERSION` aliases `SaveMigrations.CURRENT_SCHEMA_VERSION` (7). Versions 0..6 remain absorbed by the `_normalize_*` layer; the first structural rewrite adds a real `_migrate_v7_to_v8` arm (instructions in the file header).
- **5b-11 closed, not just deferred:** re-investigation showed the nested `news_archive_index` stores a deliberate ~24-field *summary projection* for browsing lists (`get_news_archive_article_summaries`), while flat `news_archive_articles` is the single full-record store fetched by id. That's sound design, not duplication — the review's finding was overstated. No restructure needed.

### Verification (Session 1)
- Every task: headless editor pass clean + quick smoke `SMOKE_QUICK_OK normal_equity=94765318.11 days=3` byte-identical.

## Tier 5c Session 2 — Upgrades controller extraction, completed 2026-06-11

- **New file:** `scripts/ui/controllers/UpgradesController.gd` (319 lines). It owns Upgrades refresh, card construction, purchase dialog setup/styling, pending purchase state, and purchase confirmation.
- `GameRoot.gd` keeps the existing `UpgradeWindow` scene nodes, desktop-window registration, app-open refresh hooks, and compatibility wrappers (`_refresh_upgrades`, `_ensure_upgrade_purchase_dialog`, `_style_upgrade_purchase_dialog`) that now delegate to the controller.
- Behavior surface preserved: same `GameManager.get_upgrade_shop_snapshot()`, `GameManager.purchase_upgrade()`, toast messages, theme helpers, and perf labels (`_refresh_upgrades`, `_on_upgrade_purchase_confirmed`).
- Size change: `GameRoot.gd` 25,393 → 25,190 lines in this session; controller pattern now proven on the smallest app.
- Verification: MCP `validate_script` clean for `GameRoot.gd` and `UpgradesController.gd`; headless editor pass clean; quick smoke `SMOKE_QUICK_OK normal_equity=94765318.11 days=3`.

## Tier 5c Session 3 — Academy controller extraction, completed 2026-06-11

- **New file:** `scripts/ui/controllers/AcademyController.gd` (1,614 lines). It owns Academy UI construction, selected category/section state, snapshots, lesson content rendering, glossary search, quiz option wiring, inline checks, and mark-read/next actions.
- `GameRoot.gd` keeps release-lock gating, desktop-window registration, FTUE references, active-window styling/layout hooks, and compatibility delegates used by the smoke harness (`_build_academy_content_block`, `_style_academy_quiz_option_button`, `_style_academy_quiz_submit_button`).
- Behavior surface preserved: same `GameManager.get_academy_snapshot()`, `mark_academy_section_read()`, `submit_academy_inline_check()`, `submit_academy_quiz()`, glossary search, guide markers, theme helpers, and release-lock behavior.
- Size change: `GameRoot.gd` 25,190 → 23,817 lines in this session.
- Verification: MCP `validate_script` clean for `GameRoot.gd` and `AcademyController.gd`; headless editor pass clean; quick smoke `SMOKE_QUICK_OK normal_equity=94765318.11 days=3`.

## Tier 5c Session 4 — Network controller extraction, completed 2026-06-11

- **New file:** `scripts/ui/controllers/NetworkController.gd` (1,168 lines). It owns Network refresh, contacts/requests/journal list rendering, journal filters/details, relationship action button state, dynamic Network context UI, and Network action handlers.
- `GameRoot.gd` keeps desktop-window registration, app-open refresh hooks, corporate meeting overlay ownership, shared Profile/News meeting helpers, visual theme hooks, and smoke-compatible delegates for old Network private method names.
- Behavior surface preserved: same `GameManager.get_network_snapshot()`, meet/tip/request/referral/follow-up/source-check calls, corporate meeting handoff, toast messages, theme helpers, and perf labels.
- Size change: `GameRoot.gd` 23,817 → 23,014 lines in this session.
- Verification: MCP `validate_script` clean for `GameRoot.gd`, `NetworkController.gd`, `AcademyController.gd`, and `UpgradesController.gd`; headless editor pass clean; quick smoke `SMOKE_QUICK_OK normal_equity=94765318.11 days=3`.

## Tier 5c Session 5 — Life controller extraction, completed 2026-06-12

- **New file:** `scripts/ui/controllers/LifeController.gd` (535 lines). It owns Life app icon/window bootstrap, `LifeWidget` refresh and tab styling, FTUE Life guide bindings, the stress meter, and hospital/jail overlays.
- `GameRoot.gd` keeps desktop-window registration, active-app routing, FTUE step evaluation state, global header refresh hooks, and compatibility delegates (`_refresh_life`, `_bind_life_guide_tabs`, `_refresh_stress_meter`, `_refresh_hospital_overlay`, `_refresh_jail_overlay`).
- Behavior surface preserved: same `LifeWidget.gd` finance/property/car tab implementation, same stress-stage colors/tooltips, same hospital/jail advance-day buttons, and same guide markers.
- Size change: `GameRoot.gd` 23,014 → 22,694 lines in this session. Life was already partly widgetized, so this slice removed the remaining root ownership rather than moving tab internals.
- Verification: headless editor pass clean; quick smoke `SMOKE_QUICK_OK normal_equity=94765318.11 days=3`; `git diff --check` clean.

## Tier 5c Session 6 — Company controller extraction, completed 2026-06-12

- **New file:** `scripts/ui/controllers/CompanyController.gd` (368 lines). It owns Company app icon/window bootstrap, management snapshot rendering, controlled-company and agenda option state, and Set Agenda action handling.
- `GameRoot.gd` keeps desktop-window registration, active-app routing, broader dashboard/news/network/trade refresh surfaces, corporate meeting overlays, and compatibility delegates (`_refresh_company`, `_refresh_company_app_availability`, `_selected_company_management_company_id`, `_selected_company_management_action_id`, `_on_company_request_pressed`).
- Behavior surface preserved: same `GameManager.get_company_management_snapshot()`, `request_governance_control_action()`, agenda option metadata, toast text, and post-success refresh fan-out.
- Size change: `GameRoot.gd` 22,694 → 22,488 lines in this session. Company is a small app shell; the heavier corporate-event/RUPSLB surfaces remain in GameRoot for a later boundary pass.
- Verification: MCP `validate_script` clean for `GameRoot.gd` and `CompanyController.gd`; quick smoke `SMOKE_QUICK_OK normal_equity=94765318.11 days=3`; `git diff --check` clean.

## Tier 5c Session 7 — Social controller extraction, completed 2026-06-12

- **New file:** `scripts/ui/controllers/SocialController.gd` (2,995 lines). It owns the Twooter shell/feed/message UI, feed filters, right rail, account profile card, ticker tape, public reply composer, private message composer, Social capture payloads, and Social action handlers.
- `GameRoot.gd` keeps desktop-window registration, active-app routing, global layout/theme hooks, News/Profile handoff wrappers, shared research-tray commit storage, and smoke-compatible delegates for old Social private method names.
- Behavior surface preserved: same `GameManager.get_twooter_snapshot()`, post reply/like, follow, private message, research capture, Network refresh fan-out, guide markers, and Twooter styling. One state-sync bug caught by smoke (shared typed button arrays were being cleared during sync) was fixed by rebuilding controller-side arrays from root refs.
- Size change: `GameRoot.gd` 22,488 → 20,339 lines in this session. Social was the first large UI-only controller extraction and validated the pattern used for News.
- Verification: MCP `validate_script` clean for `GameRoot.gd` and `SocialController.gd`; quick smoke `SMOKE_QUICK_OK normal_equity=94765318.11 days=3`; `git diff --check` clean.

## Tier 5c Session 8 — News controller extraction, completed 2026-06-12

- **New file:** `scripts/ui/controllers/NewsController.gd` (1,700 lines). It owns the Market Papers shell/archive/detail UI, outlet buttons, archive filters, article cards, article detail layout, capture context menu, source-contact handoff, and linked corporate-meeting action state.
- `GameRoot.gd` keeps desktop-window registration, active-app routing, broader refresh/theme hooks, corporate-action button creation, shared research-capture storage, and smoke-compatible delegates for old News private method names.
- Behavior surface preserved: same `GameManager.get_news_snapshot()`, archive summary/detail calls, article-read tracking, network-contact discovery, research capture payloads, Twooter source handoff, corporate-meeting gating, and newspaper visual styling.
- Size change: `GameRoot.gd` 20,339 → 19,349 lines in this session. News still has compatibility wrappers in root because other controllers and smoke tests call several old private helper names.
- Verification: MCP `validate_script` clean for `GameRoot.gd` and `NewsController.gd`; quick smoke `SMOKE_QUICK_OK normal_equity=94765318.11 days=3`; `git diff --check` clean.

## Tier 5c Session 9 — Stock controller extraction, completed 2026-06-12

- **New file:** `scripts/ui/controllers/StockController.gd` (5,994 lines). It owns the Stockbot market surface: watchlist/all/portfolio stock lists, trade workspace refresh, order ticket, quote capture, key stats dashboard, profile/background/shareholder/management tables, broker flow, financial statements, corporate-action timeline, and Stockbot styling helpers.
- `GameRoot.gd` keeps desktop/window routing, global refresh wiring, shared formatter helpers, debug/dashboard surfaces, Network/News/Profile handoff wrappers, and compatibility delegates for the old Stock private method names.
- Behavior surface preserved: same `GameManager.get_stock_snapshot()`, watchlist mutations, order buy/sell calls, broker/key-stats/profile/financial/corporate-action research capture payloads, guide markers, Steam progress tab tracking, and cached company-detail hydration.
- Size change: `GameRoot.gd` 19,349 → 16,076 lines in this session. This closes the per-app controller extraction track; the remaining work is now domain/runtime cleanup rather than another app split.
- Verification: MCP `validate_script` clean for `GameRoot.gd` and `StockController.gd`; quick smoke `SMOKE_QUICK_OK normal_equity=94765318.11 days=3`; `git diff --check` clean.

## Controller decomposition review — 2026-06-12

Three independent reviewers (architecture/consistency, GameRoot-side bug hunt, StockController deep-dive) plus manual adjudication of every claimed bug.

**Verdict: sound — no real bugs found.** Build health re-verified: headless editor pass clean, quick smoke byte-identical.

What held up under scrutiny:
- Refs-dict contracts consistent across all 8 controllers; no silent-null keys.
- Spot-checked StockController's biggest functions against the `81f46ef` baseline: byte-for-byte moves, no logic drift.
- The sync discipline is complete: Stock/Academy/Company/News/Social call `_sync_root_state()` at the end of `_sync_root_refs()`; Network syncs explicitly at every mutation site; Life owns no duplicated state (node refs only; its one shared flag writes through `_root.set()` immediately); Upgrades keeps only private state GameRoot never reads.
- Signal wiring safe (one-time setup guards; rebuilt buttons reconnect by construction); capture payloads delegate to GameRoot's `_commit_pending_capture` rather than relying on state sync.
- One reviewer claimed seven "real bugs" around state sync-back — **all seven dissolved under direct verification**. Recorded here so future sessions don't chase them.

Known structural weaknesses (accepted for now, addressed by follow-ups below):
1. Bidirectional state duplication kept consistent only by manual discipline — one forgotten `_sync_root_state()` in a future handler is a silent stale-state bug (→ Follow-up D).
2. GameRoot invokes the StockController sync trio ~262 times, each pass copying 120+ properties — fine today, first suspect if UI ever feels sluggish.
3. Each controller re-declares its own `COLOR_*` palette (~9 copies project-wide) (→ Follow-up C).
4. All verification so far is headless; no human has clicked through the apps post-decomposition (→ Follow-up A).

## Follow-up plan — context/usage-budget conscious

Calibration to date: a 5b-style extraction ≈ 15–25% of a usage window; quick-win batches ≈ 10–15%. Order chosen so each step is independently committable and the budget can stop anywhere.

**Follow-up D progress notes (for the Stock session):** the proven recipe per controller — (1) inventory the controller's `_sync_root_state` writes; (2) for each var, count REAL GameRoot readers (declaration-only copies just get deleted; real readers get redirected through `<x>_controller.<var>` after `_ensure_<x>_controller()`); (3) the shared `pending_capture_payloads` dict stays GameRoot-owned, aliased once in the controller's `setup()` (dict reference semantics make further sync redundant); (4) gut `_sync_state_from_root` to a no-op (GameRoot call-site compat) and delete `_sync_root_state` + call sites; (5) **grep SmokeTest for `game_root.<var>` reads AND `game_root.set("<var>", ...)` writes** — the set() form silently no-ops against deleted vars, so it breaks tests without erroring (caught twice: news assertion, network tip-journal); (6) verify with editor pass + quick smoke (it executes these UI sections and surfaces Invalid-access errors), commit per controller. Stock extra care: `selected_company_id` is read by GameRoot dashboard/FTUE/guide code in ~15 places and synced down by NetworkController — migrate readers to accessors first, then delete.

| Step | Task | Est. cost | Why this order |
|---|---|---|---|
| A | **Manual playtest + checkpoint commit.** Human clicks through all 8 apps (trade once, capture research from key stats/broker/news/social, buy an upgrade, open academy/life/company/network); then commit the whole decomposition as one checkpoint | ~5% (mostly human time) | Cheapest step, unblocks everything; nothing else should land before the decomposition is committed. |
| B | **Warnings cleanup pass** — rename `seed`/`size`/`theme`/`wrap` shadowers, underscore unused params/vars, fix the 3 `INCOMPATIBLE_TERNARY`s, annotate the false-positive `UNUSED_SIGNAL`s | ~10–15% | Gets the Problems panel to zero so real regressions are visible during C/D. Commit per file-group. |
| C | **Shared `UITheme` constants** — one `scripts/ui/UITheme.gd` (or systems/) holding the palette; controllers + GameRoot reference it; delete the 9 local copies | ~10% | Mechanical, verifiable by compile + smoke; do before D so D's diffs stay readable. |
| D | **Controller-owned state** — per controller, move the duplicated `selected_*`/`current_*` vars to live ONLY in the controller; GameRoot reads via thin accessors; delete that controller's `_sync_state_from_root`/`_sync_root_state` pair | ~10–15% **per controller** (8 controllers; Stock last and largest) | The real fix for weakness #1. One controller per sitting, smoke + click-test that app, commit, stop anywhere. |
| 14 | **Typed `CompanyRuntime`** (Tier 4 pattern) with wrapper getter, gradual callsite migration | ~20–25% total, incremental | Independent of A–D; can ride along any session with spare budget. |

Single-session guidance: A+B+C fit one ~35–40% session comfortably. D is a multi-session track (like the app extractions were) — budget one or two controllers per session and never start a controller you can't finish and verify within the session.

## File inventory (Tier 5, all uncommitted)

**New files:**
- `systems/UIFormatter.gd` (5a) — shared currency/decimal/percent formatters
- `systems/LifeStateSystem.gd` (5b-7, 545 lines) — RunState-side life-dict normalizers/defaults
- `systems/TwooterStateSystem.gd` (5b-8) — Twooter social-state normalizers
- `systems/CorporateActionApplications.gd` (5b-9, 1,022 lines) — corporate-action application bodies
- `systems/ThesisManager.gd` (5b-10a, 1,050 lines) — GameManager-side thesis/research domain
- `systems/LifeManager.gd` (5b-10b, 1,495 lines) — GameManager-side life orchestration
- `systems/SaveMigrations.gd` (5c-15) — stepwise save-format migration
- `scripts/ui/controllers/UpgradesController.gd` (5c Session 2, 319 lines) — Upgrades app controller
- `scripts/ui/controllers/AcademyController.gd` (5c Session 3, 1,614 lines) — Academy app controller
- `scripts/ui/controllers/NetworkController.gd` (5c Session 4, 1,168 lines) — Network app controller
- `scripts/ui/controllers/LifeController.gd` (5c Session 5, 535 lines) — Life app shell, guide bindings, stress meter, hospital/jail overlays
- `scripts/ui/controllers/CompanyController.gd` (5c Session 6, 368 lines) — Company app shell and governance agenda controls
- `scripts/ui/controllers/SocialController.gd` (5c Session 7, 2,995 lines) — Twooter shell, feed, message UI, capture payloads, and Social actions
- `scripts/ui/controllers/NewsController.gd` (5c Session 8, 1,700 lines) — Market Papers shell, archive/detail UI, article cards, capture payloads, and News actions
- `scripts/ui/controllers/StockController.gd` (5c Session 9, 5,994 lines) — Stockbot market lists, trade workspace, order ticket, key stats, broker, profile, financials, and corporate-action UI

**Modified:**
- `autoloads/RunState.gd` — 8,026 → 6,432 lines (delegates + const aliases)
- `autoloads/GameManager.gd` — ~9,447 → 7,063 lines (delegates, debug guards, formatter delegation)
- `scripts/ui/GameRoot.gd` — debug-overlay gating, capture-payload dict, app-button binds, formatter delegation, Upgrades + Academy + Network + Life + Company + Social + News + Stock controller delegation
- `scripts/ui/widgets/LifeWidget.gd`, `ThesisBoardWidget.gd`, `TradeWorkspaceWidget.gd` — formatter delegation

**Earlier tiers (1–4):** new `systems/CampaignState.gd`, `systems/EventContext.gd`, `systems/CompanyProfile.gd`; constants/typed refactors in `systems/MarketSimulator.gd`, `systems/GorenganCampaignSystem.gd`
