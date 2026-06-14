# Contact Network System Enhancement - Plan & Progress Log

Improves the maintainability and tuning-ergonomics of the contact/network system. The system works correctly and is fully deterministic; this plan reduces its size, removes copy-paste/stringly-typed risk, names its tuning knobs, and trims read-modify-write churn - without changing player-facing behavior.
**Status: Tasks 1-7 complete.** Designed to run in a fresh session; everything needed to execute cold is in this file.

**Review verdict recap:** `systems/ContactNetworkSystem.gd` started as a 3,520-line, ~140-function god-file. It was architecturally sound: fully deterministic (zero `randi`/`Time`; all variation via `STABLE_RNG` seed keys), snapshot building was strictly read-only (no `set_*` in `build_snapshot`/`build_twooter_accounts`/decorators), it cleanly separated a contact's internal `truth_label` from the player-visible `outcome_label`, and every dict access had a `.get(key, default)` fallback. No correctness bugs, no nondeterminism, no save hazards were found. Tasks 1-7 reduced the maintainability risk by adding a deterministic snapshot/journal audit, centralizing vocabulary and tuning constants, batching tip-loop writes, normalizing JSON tooling, and splitting the large file into focused static helper modules.

## Where everything lives

| What | Where |
|---|---|
| Primary runtime owner | `systems/ContactNetworkSystem.gd` - public facade/orchestrator for discovery, meetings, tip request/resolution/reaction, process_due hooks, saved-state mutation, Network-app snapshot, and stable GameManager/NetworkController call sites |
| Split helper modules | `systems/NetworkContactPresenter.gd` - contact rows and synthesized Network Twooter accounts; `systems/NetworkJournalBuilder.gd` - journal row config/factory/builders; `systems/NetworkTipResolver.gd` - tip outcome scoring, reliability, cross-contact, follow-up/source-check text; `systems/NetworkDiscovery.gd` - deterministic discovery limits, meeting scoring, contact sentiment/arc text |
| Data/config | `data/network/contact_network_data.json` (237 contacts, meeting_lead_profiles, tip_templates, request_templates) - UTF-8 BOM removed in Task 6; standard `python3 -m json.tool` now works |
| UI entry point | `scripts/ui/controllers/NetworkController.gd` - Network app; snapshot rows come from `build_snapshot` |
| Runtime state | `RunState` network fields: `network_contacts`, `network_discoveries`, `network_requests`, `network_tip_journal`; plus `twooter_social_state` for synthesized accounts (normalizer: `systems/TwooterStateSystem.gd`). Snapshot rows are ephemeral (computed per call), NOT saved |
| Tests/probes | `scripts/tests/NetworkSnapshotAuditTest.gd` + `scenes/tests/NetworkSnapshotAuditTest.tscn` lock the deterministic ContactNetworkSystem snapshot/journal baseline; `scripts/tests/NetworkThirtyDayScenarioTest.gd` + `scenes/tests/NetworkThirtyDayScenarioTest.tscn` run a 30-trading-day targeted Contact Network scenario; `scripts/tests/NetworkHighRecognitionScenarioTest.gd` + `scenes/tests/NetworkHighRecognitionScenarioTest.tscn` cover top-tier recognition and inner-circle Network Twooter state; existing network-adjacent coverage also includes `NetworkConsequenceFollowupTest` plus Twooter -> Network bridge tests |
| Editor/source tooling | none specific to network data (unlike Twooter's `tools/twooter_editor/`) |
| Key functions (line refs drift; locate by name) | `ContactNetworkSystem.gd`: `build_snapshot` (~162), `build_twooter_accounts` (~240), `approach_meeting_lead` (~418), `request_tip`/`accept_request`/`follow_up_tip`/`ask_source_check` (~562-729), `process_due_tip_memories` (~805), `_resolve_tip_memory` delegate (~1155), `_record_tip_memory` (~1111), `_build_public_tip_read` (~1703), `_network_journal_rows` delegate (~2426), `_adjust_relationship`/`_mark_contact_day_flag` (~2503-2524). Split modules: `NetworkContactPresenter.contact_row`, `NetworkJournalBuilder.network_journal_rows`, `NetworkTipResolver.resolve_tip_memory`, `NetworkDiscovery.meeting_lead_contact_score` |

## Goals

- Reduce `ContactNetworkSystem.gd` from a 3,520-line god-file toward focused, testable modules (mirror the proven GameManager/RunState/Twooter split pattern). Task 7 leaves it as a 2,538-line facade/orchestrator plus focused helper modules.
- Eliminate stringly-typed silent-mismatch risk (centralize outcome/truth/status/stance/journal-type values; kill the 4x duplicated outcome-array literal).
- Make tuning knobs (tip price thresholds, journal sort order) named and findable.
- Trim per-mutation full-dict read-modify-write churn in the daily tip loop.
- Zero player-facing behavior change at every step (deterministic; smoke equity byte-identical).

## Non-goals

- No new network gameplay mechanics, tip types, or contact archetypes.
- No change to the saved shape of `network_contacts`/`network_discoveries`/`network_requests`/`network_tip_journal` (read-only refactor; any new keys need normalizer defaults).
- No retuning of game balance - thresholds get NAMED, not changed (Task 4 must preserve exact values).
- No Twooter dialog/router work (that system is already split; see `TWOOTER_INTERACTION_SYSTEM_ENHANCEMENT.md`).

## Working rules

- One task per checkpoint commit; verify before each commit.
- Keep edits scoped to the task. Do not mix behavior changes, content changes, and refactors unless the task says so.
- Gates:
  - `git diff --check`
  - `/Users/user/.local/bin/godot --headless -e --quit`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11`
- If editing JSON, also run: `python3 -m json.tool [path/to/file.json] > /dev/null`.
- Determinism: keep all variation on `STABLE_RNG` seed keys and stored baselines. No `randi`/`randf`/`Time` in network logic or probes.
- Save compatibility: snapshot rows are ephemeral, but `network_*` journal/contact/discovery dicts are saved. New saved keys need defaults wherever they are read; do not rename/remove saved keys without a migration plan.
- This is a refactor, not a feature: the strongest proof is the deterministic gates. Because the system touches market/RunState state indirectly, prefer a 120-day `MarketYearAudit` (`--audit-days 120 --audit-seed 20260606 --audit-difficulty grind`, byte-identical after masking `ms` timings) for Tasks 4 and 5 in addition to smoke.
- Behavior-adjacent tasks should add a committed network probe scene before broad smoke (none exist yet; Task 1 establishes the harness pattern).

## Status

| # | Task | Est. cost | Status |
|---|---|---|---|
| 1 | Network probe harness + baseline snapshot/journal audit | ~10-15% | Complete |
| 2 | Centralize stringly-typed enums; kill the 4x duplicated outcome array | ~10% | Complete |
| 3 | Name the magic numbers (tip price thresholds, journal sort offsets) | ~5-10% | Complete |
| 4 | Table-driven journal-row builders + decorator factory | ~15-25% | Complete |
| 5 | Batch the read-modify-write churn in the tip loop | ~10% | Complete |
| 6 | Strip the data-file UTF-8 BOM; make json.tool gate uniform | ~5% | Complete |
| 7 | System boundary split (discovery / tips / journal / presenter) | ~30-40% | Complete |

Recommended batching: **Tasks 1-7 are complete.** Use the focused audit first for future network changes, then quick smoke; reserve 120-day market audit for behavior-adjacent tuning or tip-resolution changes.

## Progress log

### 2026-06-13 - Plan created

- Created this enhancement plan from the read-only ContactNetworkSystem review.
- Current inventory:
  - `ContactNetworkSystem.gd`: 3,520 lines, ~140 functions, six sub-domains (discovery, meetings, tips, reactions, journal, twooter-account synthesis).
  - `contact_network_data.json`: 237 contacts; begins with a UTF-8 BOM (`ef bb bf`) - `twooter_feed_data.json` does not, so the json.tool gate is currently non-uniform.
  - RunState coupling: `day_index` (38 reads), `get/set_network_contacts` (21/8), `get/set_network_tip_journal` (12/4), `get/set_network_discoveries` (11/5); snapshot build is read-only.
  - Determinism: zero `randi`/`randf`/`Time`; confirmed reproducible.
  - Longest functions: `approach_meeting_lead` 111, `_contact_row` 83, `build_snapshot` 78, `_resolve_tip_memory` 72.
  - The literal `["Useful read","Useful warning","Useful timing read","Early, not wrong"]` is copy-pasted at ~1162, ~1341, ~1637, ~1906.
  - ~14 `_network_*_journal_row` builders share an 11-field shape; `sort_index = day_index*10 + N` offsets reuse +3/+5/+8 across types with no registry.
- No code or data changes were made by this planning step.

### 2026-06-13 - Task 1 completed

- Tightened the Task 1 requirement before implementation: the probe must compare a curated deterministic payload/hash and fail on row text, row title, detail, type, and sort-order drift, not just missing fields.
- Added `scripts/tests/NetworkSnapshotAuditTest.gd` and `scenes/tests/NetworkSnapshotAuditTest.tscn` as a focused ContactNetworkSystem snapshot/journal audit.
- Godot generated `scripts/tests/NetworkSnapshotAuditTest.gd.uid` for the new script; keep it with the test file.
- The fixture seeds two met catalog contacts, one generated Twooter-origin contact, referral/meeting/twooter discoveries, a pending position request, a dirty-tip request, two pending tip memories, a source-only Twooter memory, and a property-development lead.
- The test routes state changes through the real `process_due_tip_memories`, `follow_up_tip`, and `ask_source_check` hooks before building the snapshot.
- Captured the initial baseline payload and locked audit hash `1423212622`.
- Verification:
  - `git diff --check` passed.
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/NetworkSnapshotAuditTest.tscn` -> `NETWORK_SNAPSHOT_AUDIT_OK hash=1423212622 contacts=2 discoveries=3 journal=18`.
  - `/Users/user/.local/bin/godot --headless -e --quit` passed.
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11`.

### 2026-06-13 - Task 2 completed

- Added local vocabulary constants in `systems/ContactNetworkSystem.gd` for truth labels, good/cautionary label groups, outcome labels, status defaults, dirty-tip request type, tip journal type, public journal row types, and stance ids.
- Replaced the duplicated good-outcome array with `GOOD_OUTCOME_LABELS`.
- Routed `_tip_label_is_cautionary` through `CAUTIONARY_TRUTH_LABELS`.
- Replaced journal row `type` output literals and source-check stance comparisons with named constants.
- Confirmed the old Task 2 string literals now only appear in the new vocabulary constants.
- Verification:
  - `git diff --check` passed.
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/NetworkSnapshotAuditTest.tscn` -> `NETWORK_SNAPSHOT_AUDIT_OK hash=1423212622 contacts=2 discoveries=3 journal=18`.
  - `/Users/user/.local/bin/godot --headless -e --quit` passed.
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11`.

### 2026-06-13 - Task 3 completed

- Added named tip-resolution threshold constants in `systems/ContactNetworkSystem.gd`:
  - `TIP_CAUTION_CONFIRMED_MOVE_PCT := -0.015`
  - `TIP_CONSTRUCTIVE_CONFIRMED_MOVE_PCT := 0.018`
  - `TIP_STRONG_UPSIDE_MOVE_PCT := 0.025`
  - `TIP_STRONG_DOWNSIDE_MOVE_PCT := -0.025`
  - `TIP_UNRESOLVED_ABS_MOVE_PCT := 0.012`
- Added `JOURNAL_SORT_DAY_MULTIPLIER`, `JOURNAL_SORT_OFFSET`, and `_journal_sort_index(day_index, sort_key)` so journal row ordering is centralized instead of repeating `day_index * 10 + N`.
- Kept dirty-tip public row type unchanged as `dirty_tip`, but added separate internal sort keys for offered/decision/result rows because those rows share one public type and need different offsets.
- Confirmed no remaining inline Task 3 threshold comparisons or `day_index * 10 + offset` sort expressions in `ContactNetworkSystem.gd`.
- Verification:
  - `git diff --check` passed before doc update.
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/NetworkSnapshotAuditTest.tscn` -> `NETWORK_SNAPSHOT_AUDIT_OK hash=1423212622 contacts=2 discoveries=3 journal=18`.
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/MarketYearAudit.tscn -- --audit-days 120 --audit-seed 20260606 --audit-difficulty grind` -> `MARKET_YEAR_AUDIT ... "success":true`.
  - Note: the 120-day audit was run as a passing long-run deterministic gate; no saved pre-Task-3 audit artifact was available for a byte-for-byte JSON diff after masking `ms` timings.
  - `/Users/user/.local/bin/godot --headless -e --quit` passed.
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11`.

### 2026-06-13 - Task 4 completed

- Added a table-driven journal row factory in `systems/ContactNetworkSystem.gd`:
  - `JOURNAL_ROW_CONFIG` now owns row type, id suffix/source, day-key fallback order, sort key, status strategy, and title/detail method names.
  - `_journal_row(config_key, source)` now builds the shared 11-field journal row shape.
  - The existing `_network_*_journal_row` functions remain as thin wrappers so call sites stay stable.
- Added an ordered decorator field-map helper:
  - `_apply_decorator(row, lookup, contact_id, field_map, defaults)` now handles the repeated contact-row lookup/default/apply skeleton.
  - `LAST_TIP_NOTE_FIELD_MAP`, `TIP_HISTORY_FIELD_MAP`, `LATEST_REACTION_FIELD_MAP`, `DEVELOPMENT_LEAD_FIELD_MAP`, and `CROSS_CONTACT_FIELD_MAP` make row decoration explicit and ready for a later module split.
- The snapshot audit caught one real refactor drift during implementation: follow-up, source-check, and social-reaction rows were initially inheriting source `status`; fixed by forcing those journal configs back to `recorded`, matching the old hardcoded builders.
- Confirmed only the shared factory constructs journal `sort_index`; no `day_index * 10 + offset` row-builder literals remain.
- Verification:
  - `git diff --check` passed before doc update.
  - `/Users/user/.local/bin/godot --headless -e --quit` passed.
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/NetworkSnapshotAuditTest.tscn` -> `NETWORK_SNAPSHOT_AUDIT_OK hash=1423212622 contacts=2 discoveries=3 journal=18`.
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/MarketYearAudit.tscn -- --audit-days 120 --audit-seed 20260606 --audit-difficulty grind` -> `MARKET_YEAR_AUDIT ... "success":true`.
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11`.

### 2026-06-13 - Task 5 completed

- Batched contact mutations inside `process_due_tip_memories`.
- The loop now reads `network_contacts` once, mutates via `_adjust_relationship_in_contacts`, `_store_contact_tip_note_in_contacts`, and `_store_contact_reaction_in_contacts`, and calls `set_network_contacts` once after processing.
- Added `_apply_network_followup_reaction_with_contacts` so reaction relationship deltas and reaction notes participate in the same batched contacts dict.
- Preserved public wrapper behavior for non-loop callers (`_adjust_relationship`, `_mark_contact_day_flag`, `_store_contact_tip_note`, `_store_contact_reaction`).
- Verification:
  - `git diff --check` passed before doc update.
  - `/Users/user/.local/bin/godot --headless -e --quit` passed.
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/NetworkSnapshotAuditTest.tscn` -> `NETWORK_SNAPSHOT_AUDIT_OK hash=1423212622 contacts=2 discoveries=3 journal=18`.
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/MarketYearAudit.tscn -- --audit-days 120 --audit-seed 20260606 --audit-difficulty grind` -> `MARKET_YEAR_AUDIT ... "success":true`.
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11`.

### 2026-06-13 - Task 6 completed

- Removed the leading UTF-8 BOM (`ef bb bf`) from `data/network/contact_network_data.json`.
- Preserved the JSON content otherwise; the diff is limited to the first character before `{`.
- Updated this plan's live JSON-editing guidance so future checks use standard `python3 -m json.tool` without a `utf-8-sig` caveat.
- Verification:
  - `xxd -l 16 data/network/contact_network_data.json` now starts with `7b0a` (`{` + newline).
  - `python3 -m json.tool data/network/contact_network_data.json > /dev/null` passed with default encoding.
  - `/Users/user/.local/bin/godot --headless -e --quit` passed.
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/NetworkSnapshotAuditTest.tscn` -> `NETWORK_SNAPSHOT_AUDIT_OK hash=1423212622 contacts=2 discoveries=3 journal=18`.
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11`.

### 2026-06-13 - Task 7 completed

- Split `systems/ContactNetworkSystem.gd` into focused static helper modules while keeping the public facade and call sites stable:
  - `systems/NetworkContactPresenter.gd` owns contact rows, synthesized Network Twooter accounts, slug/target helpers, and display helpers.
  - `systems/NetworkJournalBuilder.gd` owns journal row config, sort offsets, row factory/builders, and request due-date text.
  - `systems/NetworkTipResolver.gd` owns tip outcome scoring, player-action readbacks, reliability/cross-contact summaries, follow-up options, and source-check text.
  - `systems/NetworkDiscovery.gd` owns deterministic discovery limits, floater/meeting scoring, meeting-tier ranking, and contact sentiment/arc text.
- `ContactNetworkSystem.gd` remains the stateful owner for saved-state mutation, daily `process_due_*` hooks, public request/meeting APIs, and GameManager/NetworkController integration.
- Removed stale journal config/sort constants, tip threshold constants, and meeting-tier order tables from the facade; those tuning/config values now live with the modules that use them.
- Line-count result:
  - `ContactNetworkSystem.gd`: 2,538 lines, down from the current pre-split 3,931-line facade and the original 3,520-line review baseline.
  - Extracted helper modules: 1,722 total lines (`NetworkContactPresenter.gd` 289, `NetworkJournalBuilder.gd` 710, `NetworkTipResolver.gd` 637, `NetworkDiscovery.gd` 86).
- Verification:
  - `git diff --check` passed.
  - `/Users/user/.local/bin/godot --headless -e --quit` passed.
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/NetworkSnapshotAuditTest.tscn` -> `NETWORK_SNAPSHOT_AUDIT_OK hash=1423212622 contacts=2 discoveries=3 journal=18` after each extraction.
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/MarketYearAudit.tscn -- --audit-days 120 --audit-seed 20260606 --audit-difficulty grind` -> `MARKET_YEAR_AUDIT ... "success":true`.
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11 days=3`.

### 2026-06-13 - Additional 30-day Contact Network scenario test

- Added `scripts/tests/NetworkThirtyDayScenarioTest.gd` and `scenes/tests/NetworkThirtyDayScenarioTest.tscn`.
- The scenario seeds a fresh deterministic run, discovers company-linked contacts, meets two low-recognition contacts through `GameManager.meet_contact`, requests tips, accepts/completes one position request, seeds a deterministic source-conflict pair, advances 30 trading days, and asserts Network tip resolution, reactions, follow-ups, source checks, journal rows, relationship state, and overdue pending-item cleanup.
- Logged the run at `docs/development/test_log/2026-06-13_contact_network_30_day_scenario.md`.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/NetworkThirtyDayScenarioTest.tscn` -> `CONTACT_NETWORK_30_DAY_OK ... "days_completed":30 ... "network_tip_results":24 ... "network_request_results":1 ... "source_checks_sent":1 ... "overdue_pending_tips":0 ... "overdue_pending_requests":0`.
  - `/Users/user/.local/bin/godot --headless -e --quit` passed and generated `scripts/tests/NetworkThirtyDayScenarioTest.gd.uid`.

### 2026-06-13 - Additional high-recognition / inner-circle scenario test

- Added `scripts/tests/NetworkHighRecognitionScenarioTest.gd` and `scenes/tests/NetworkHighRecognitionScenarioTest.tscn`.
- The scenario proves the 95-recognition contact `pak_gunawan_personal_lawyer` is blocked before the recognition gate, seeds top-tier recognition through the formula inputs (equity, six invested positions, and eight met contacts), proves the contact becomes discoverable and meetable, promotes the generated Network Twooter account to `inner_circle_candidate`, sends a real private Twooter dialog option through the generated Network account, then requests and resolves a high-contact tip.
- Logged the run at `docs/development/test_log/2026-06-13_contact_network_high_recognition.md`.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/NetworkHighRecognitionScenarioTest.tscn` -> `CONTACT_NETWORK_HIGH_RECOGNITION_OK ... "recognition_after":{"score":99.94,"label":"Market Name","contact_cap":12} ... "twooter_stage":"inner_circle_candidate" ... "dialog_tree_id":"network_source_followup" ... "dialog_chosen_option_id":"public_trail" ... "dialog_outcome":"source_check" ... "high_tip_status":"resolved"`.

---

## Task 1 - Network probe harness + baseline snapshot/journal audit

Problem: the network system has network-adjacent tests but no committed ContactNetworkSystem snapshot/journal audit. Every later refactor needs a deterministic before/after net that the quick smoke does not provide at the snapshot/journal level.

1. Add `scripts/tests/NetworkSnapshotAuditTest.gd` + `scenes/tests/NetworkSnapshotAuditTest.tscn`, following the Twooter test-scene pattern (build a representative `RunState`, drive a few seeded discoveries/meets/tips, advance days to resolve tips, print one compact structured success line).
2. Capture and assert: snapshot contact-row field set, journal row `type` values and their `sort_index` ordering, tip resolution outcome labels, reliability summary, and cross-contact read results - an exact stable baseline payload/hash ending in a sentinel like `NETWORK_SNAPSHOT_AUDIT_OK`.
3. The audit should fail on subtle row/title/detail/sort drift, not just missing fields. Prefer comparing a curated deterministic payload and a hash so Tasks 2-7 can prove no behavior/output drift.
4. Keep it test-only; do not add saved runtime state or player-facing UI.
5. Verify:
   - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/NetworkSnapshotAuditTest.tscn` -> `NETWORK_SNAPSHOT_AUDIT_OK`
   - gates and quick smoke.

## Task 2 - Centralize stringly-typed enums; kill the 4x duplicated outcome array

Problem: `truth_label` (11 values), `outcome_label` (7), `status` (6), `stance` (4), and journal `type` (14) are bare strings; the "good outcomes" array literal is copy-pasted in four places (~1162, ~1341, ~1637, ~1906), so adding an outcome silently scores `false` in any spot that was missed.

1. Add `const` groups at the top of the file (or a small `systems/NetworkTipVocabulary.gd` if it reads cleaner): `GOOD_OUTCOME_LABELS`, `CAUTIONARY_TRUTH_LABELS`, the journal `type` ids, and stance ids.
2. Replace the four inline `["Useful read", ...]` literals with the single constant; route `_tip_label_is_cautionary` through the cautionary constant.
3. Pure rename/centralize - values must stay byte-identical. No behavior change.
4. Verify:
   - Task 1 audit -> `NETWORK_SNAPSHOT_AUDIT_OK` unchanged
   - gates and quick smoke.

## Task 3 - Name the magic numbers (tip price thresholds, journal sort offsets)

Problem: `_resolve_tip_memory` inlines price thresholds (`+/-0.015`, `+/-0.018`, `+/-0.025`) 8+ times, and the `sort_index = day_index*10 + N` journal offsets are scattered across ~14 functions with no registry (offsets +3/+5/+8 reused across types).

1. Extract tip outcome thresholds into named `const` (e.g. `TIP_USEFUL_MOVE_PCT`, `TIP_CAUTION_MOVE_PCT`, `TIP_DELAYED_MOVE_PCT`) - keep exact current values.
2. Add a `JOURNAL_SORT_OFFSET` const dict keyed by journal `type` (depends on Task 2's type ids); have each builder read its offset from the dict instead of an inline literal.
3. Values unchanged; this is naming only.
4. Verify:
   - Task 1 audit -> `NETWORK_SNAPSHOT_AUDIT_OK` unchanged (ordering identical)
   - 120-day `MarketYearAudit` byte-identical after masking `ms` timings (tip thresholds feed resolution)
   - gates and quick smoke.

## Task 4 - Table-driven journal-row builders + decorator factory

Problem: ~14 `_network_*_journal_row` functions return the same 11-field shape, varying only `title`/`detail`/`sort_index`; the five `_apply_latest_*` decorators share an identical lookup -> default -> apply skeleton. ~300 lines of copy-paste.

1. Introduce one `_journal_row(type, source, config)` factory that fills the common 11 fields and calls per-type `title`/`detail` builders (or `Callable`s) from a config table; migrate the 14 builders to entries in that table. Pull `sort_index` from Task 3's offset dict.
2. Introduce one `_apply_decorator(row, lookup, contact_id, field_map, defaults)` and express the five decorators as field-map config.
3. Preserve output exactly: same fields, same values, same row ordering. This is the task most likely to drift - lean hard on the Task 1 audit diff.
4. Verify:
   - Task 1 audit -> `NETWORK_SNAPSHOT_AUDIT_OK` with byte-identical journal/row payload vs the pre-task baseline
   - gates and quick smoke.

## Task 5 - Batch the read-modify-write churn in the tip loop

Problem: `_adjust_relationship` and `_mark_contact_day_flag` each `get_network_contacts()` -> mutate one field -> `set_network_contacts()` the whole 237-entry dict. Inside `process_due_tip_memories` (loop over all tips) this re-stores the full contacts dict multiple times per resolved tip. Correct but wasteful.

1. In the loop, load `contacts` once, pass it to internal mutators that take it by reference, and `set_network_contacts` once at the end (mirror how the journal is already read-once/write-once in the same function).
2. Keep `_adjust_relationship`/`_mark_contact_day_flag` public-shape wrappers for callers outside the loop (they can keep their own get/set), or add batched `_*_in` variants - whichever keeps call sites clean.
3. Determinism/behavior must be identical: the per-call re-read currently sees prior writes, so the batched version must apply deltas in the same order.
4. Verify:
   - Task 1 audit -> `NETWORK_SNAPSHOT_AUDIT_OK` unchanged
   - 120-day `MarketYearAudit` byte-identical after masking `ms` timings
   - gates and quick smoke.

## Task 6 - Strip the data-file UTF-8 BOM; make json.tool gate uniform

Original problem: `data/network/contact_network_data.json` started with a UTF-8 BOM, so the documented `python3 -m json.tool data/network/contact_network_data.json` gate errored (needed `utf-8-sig`), while `twooter_feed_data.json` had no BOM. Godot read both fine, so this was a tooling papercut, not a runtime bug.

1. Re-save the file without the BOM (preserve content byte-for-byte otherwise).
2. Confirm `DataRepository` still loads it (Godot's JSON parse is BOM-tolerant either way; the editor gate is the real check).
3. Verify:
   - `python3 -m json.tool data/network/contact_network_data.json > /dev/null` now succeeds with default encoding
   - `/Users/user/.local/bin/godot --headless -e --quit` clean; quick smoke unchanged.

## Task 7 - System boundary split

Problem: `ContactNetworkSystem.gd` owned six sub-domains in 3,520 lines at review time and 3,931 lines by the time the first six tasks completed. Future changes were slow and risky. The GameManager/RunState/Twooter splits prove the pattern works here.

1. Split only AFTER Tasks 2-5 (enums centralized, factories in place) so the split moves clean code, not copy-paste.
2. Candidate extracted files (static-method modules referenced via `preload` const, no `class_name` to avoid global-class collisions, dependencies passed explicitly - exactly like `TwooterDialogRouter`/`TwooterOutcomeResolver`):
   - `NetworkDiscovery.gd` - `discover_*`, meeting-lead building/scoring, insider/floater discovery
   - `NetworkTipResolver.gd` - record/resolve/reaction/reliability/cross-contact
   - `NetworkJournalBuilder.gd` - the journal-row factory + table (post-Task 4)
   - `NetworkContactPresenter.gd` - `_contact_row` + `_contact_twooter_*`
3. `ContactNetworkSystem.gd` keeps the public API (`build_snapshot`, `request_tip`, `meet_contact`, `process_due_*`, etc.) as thin delegates so `GameManager` and `NetworkController` call sites stay stable. Move one sub-domain at a time; run gates after each.
4. Avoid new allocation-heavy wrapper layers in the daily `process_due_*` hot paths.
5. Verify:
   - Task 1 audit -> `NETWORK_SNAPSHOT_AUDIT_OK` after every extraction
   - editor parse after every extraction; quick smoke
   - 120-day `MarketYearAudit` byte-identical after the final extraction.

## Known traps

- SmokeTest pokes some UI internals directly. If controller/root state names move, grep for both direct property reads and `set("<name>", ...)` calls.
- Snapshot rows are ephemeral (built per call from RunState getters), but `network_contacts`/`network_discoveries`/`network_requests`/`network_tip_journal` and `twooter_social_state` ARE saved. Any added key in those needs a normalizer default (RunState and/or `TwooterStateSystem.gd`).
- `_adjust_relationship`/`_mark_contact_day_flag` re-read contacts before writing, so today there is no lost-update bug; the Task 5 batched version must preserve apply order.
- Tip thresholds (Task 3) feed `_resolve_tip_memory` outcomes, which can shift relationship deltas and downstream contact behavior - hence the MarketYearAudit on Tasks 3/4/5.
- The data file's UTF-8 BOM was removed in Task 6; use standard `python3 -m json.tool data/network/contact_network_data.json > /dev/null`.
- `STABLE_RNG` seed keys are the determinism contract. Do not replace any seeded choice with `randi()`/`Time`, including in probes.
- Long-run audits grow slower as history accumulates; use the Task 1 probe first, quick smoke second, MarketYearAudit only where the task changes resolution/tuning.
