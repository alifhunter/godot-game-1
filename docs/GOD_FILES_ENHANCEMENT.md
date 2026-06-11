# God Files Enhancement — Progress Log

Tracks the Tier 5 refactor of the three god files. **Tiers 5a and 5b are complete (2026-06-11); Tier 5c is next.** All work is uncommitted.

| God file | Tier 5 start | Current | Change |
|---|---|---|---|
| `scripts/ui/GameRoot.gd` | 25,460 | ~25,400 | 5c target (per-app controllers) |
| `autoloads/GameManager.gd` | ~9,447 | 7,063 | −2,384 |
| `autoloads/RunState.gd` | 8,026 | 6,432 | −1,594 |

Six new focused systems extracted: `UIFormatter`, `LifeStateSystem`, `TwooterStateSystem`, `CorporateActionApplications`, `ThesisManager`, `LifeManager` (~5,300 lines of relocated, now-testable logic). Every step verified zero-behavior-change.
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
| 5c | Structural — session-budgeted plan below: Session 1 stability batch (13+16+15, fits ~50% usage), then per-app GameRoot controllers one app per session | ⬜ Not started |

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

## Tier 5c — NEXT UP (structural; session-budgeted plan)

Commit the current verified-green Tier 1–5b batch as a checkpoint before starting. For calibration: all of 5a + the five 5b extractions together consumed roughly one full usage window.

### Session 1 — "stability batch" (fits in ~50% of a usage limit)

Do these three together; they close out everything except the GameRoot decomposition:

| # | Task | Est. cost | Notes |
|---|---|---|---|
| 13 | **Refresh coalescer** — queue refresh scopes in GameRoot, batch once per frame; kills double-refresh hazards from same-frame signals | ~10–15% | Small, self-contained. Do first. |
| 16 | **Split `_advance_day_internal` into named phases** | ~10% | Its body already shrank in 5b (the `_apply_life_*` appliers now delegate). |
| 15 | **Save-version migrations** (`_migrate_vN_to_vN+1` keyed off the schema version already written into saves but never read) **+ the deferred 5b-11 news-archive dedup** riding on that infrastructure | ~15–20% | Needs careful save/load round-trip testing — use the MarketYearAudit baseline workflow plus a manual save→load→save byte comparison. |

### Sessions 2..N — GameRoot per-app controllers (item 12, the big one)

GameRoot is still ~25,400 lines; this is the majority of the remaining problem and does NOT fit a 50% budget — each app is its own extraction comparable to or bigger than a whole 5b item, and UI code is riskier (node paths, signal wiring, scene files, visual verification needed).

**One app per session**, in this order:
1. **Upgrades or Academy first** — smallest apps; proves the controller pattern (one scene + script per app, GameRoot shrinks toward window manager + signal router) cheaply.
2. Then **Network, Life, Company, Social, News** in rough size order.
3. **Stock app last** — biggest (trade workspace + key stats + broker views, likely 5–8k lines); benefits from a matured pattern.

Each app session: extract scene + controller, GameRoot keeps the window-management hooks, verify with editor pass + smoke + a manual visual check of that app in the running game (`get_editor_screenshot`/`get_game_screenshot` via godot-mcp-pro if the editor is open).

### Rides along wherever there's room

| # | Task | Est. cost | Notes |
|---|---|---|---|
| 14 | **Typed `CompanyRuntime` class** (continue the Tier 4 `CampaignState`/`EventContext`/`CompanyProfile` pattern) with gradual callsite migration via a wrapper getter | ~20–25% total, incremental by design | Migrate a few of the ~40 callsites per session; safe to pause at any point. |

## File inventory (Tier 5, all uncommitted)

**New files:**
- `systems/UIFormatter.gd` (5a) — shared currency/decimal/percent formatters
- `systems/LifeStateSystem.gd` (5b-7, 545 lines) — RunState-side life-dict normalizers/defaults
- `systems/TwooterStateSystem.gd` (5b-8) — Twooter social-state normalizers
- `systems/CorporateActionApplications.gd` (5b-9, 1,022 lines) — corporate-action application bodies
- `systems/ThesisManager.gd` (5b-10a, 1,050 lines) — GameManager-side thesis/research domain
- `systems/LifeManager.gd` (5b-10b, 1,495 lines) — GameManager-side life orchestration

**Modified:**
- `autoloads/RunState.gd` — 8,026 → 6,432 lines (delegates + const aliases)
- `autoloads/GameManager.gd` — ~9,447 → 7,063 lines (delegates, debug guards, formatter delegation)
- `scripts/ui/GameRoot.gd` — debug-overlay gating, capture-payload dict, app-button binds, formatter delegation
- `scripts/ui/widgets/LifeWidget.gd`, `ThesisBoardWidget.gd`, `TradeWorkspaceWidget.gd` — formatter delegation

**Earlier tiers (1–4):** new `systems/CampaignState.gd`, `systems/EventContext.gd`, `systems/CompanyProfile.gd`; constants/typed refactors in `systems/MarketSimulator.gd`, `systems/GorenganCampaignSystem.gd`
