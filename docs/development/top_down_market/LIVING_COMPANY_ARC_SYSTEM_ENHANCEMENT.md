# Living Company Arc System Enhancement - Plan & Progress Log

This plan keeps companies active after a story ends, allowing new macro, sector, company, and relationship-driven arcs to emerge later.
**Status: complete - Tasks 1-5 complete.** Designed to run in a fresh session; everything needed to execute cold is in this file.

**Review verdict recap:** A company should not become stagnant when an arc resolves. The game needs companies to live through multiple cycles: growth, disappointment, recovery, partnership, acquisition interest, governance issues, commodity tailwinds, and new strategic shifts. This plan adds lifecycle state without forcing every company to always have an active story.

## Where everything lives

| What | Where |
|---|---|
| Current company event owners | `systems/CompanyEventSystem.gd`, `systems/CompanyRoadmapSystem.gd` |
| Corporate action owners | `systems/CorporateActionSystem.gd`, `systems/CorporateActionApplications.gd` |
| Runtime state | `autoloads/RunState.gd` company/event state |
| Company data | Current generated company data and planned company universe catalog |
| Content consumers | `systems/NewsFeedSystem.gd`, `systems/TwooterFeedSystem.gd`, `systems/ContactNetworkSystem.gd` |
| Tests/probes | `scenes/tests/LivingCompanyArcDefaultsTest.tscn`; `scenes/tests/LivingCompanyArcLifecycleTest.tscn`; `scenes/tests/LivingCompanyArcIntegrationTest.tscn`; `scenes/tests/LivingCompanyArcLongRunAuditTest.tscn` |
| Key functions | Locate by roadmap/event generation, company state normalizers, and event application functions |

## Goals

- Add lifecycle state for active, completed, cooling down, and eligible company arcs.
- Let companies receive future stories after an arc resolves.
- Keep old saves compatible and neutral.

## Non-goals

- Do not implement full relationship graph or M&A in this plan.
- Do not require every company to have a story at all times.
- Do not rewrite existing event systems unless a small adapter is enough.

## Working rules

- Arc state must be saved and normalized.
- Completed arcs should remain useful as history and evidence.
- New arc eligibility should be deterministic.
- Keep runtime costs low in daily simulation.

## Status

| # | Task | Est. cost | Status |
|---|---|---|---|
| 1 | Define living arc state shape | ~10-20% | Complete |
| 2 | Add normalizers and compatibility defaults | ~10-20% | Complete |
| 3 | Add arc lifecycle transitions | ~20-35% | Complete |
| 4 | Integrate with existing event and roadmap systems | ~20-35% | Complete |
| 5 | Add lifecycle tests and audit logging | ~10-20% | Complete |

Recommended batching: **Session 1 = Tasks 1-2** because save shape is the main risk. **Session 2 = Tasks 3-4**. **Task 5** should finalize once integration is stable.

## Progress log

### 2026-06-14 - Plan created

- Created this enhancement plan from the top-down market brainstorming session.
- Current inventory:
  - Existing roadmaps and company events already create company-specific activity.
  - There is no explicit long-term living arc lifecycle layer yet.
  - The desired behavior is persistent eligibility, not permanent active drama.
- No code or data changes were made by this planning step.

### 2026-06-14 - Task 1 complete

- Reviewed current arc and roadmap ownership:
  - `CompanyEventSystem.gd` owns ad hoc company arcs in `RunState.active_company_arcs`.
  - `CompanyRoadmapSystem.gd` owns roadmap milestones in `RunState.company_roadmap_state`, including `active_milestones`, `resolved_milestones`, `company_cooldowns`, and `last_spawn_day_index`.
  - Corporate actions, index reviews, and roadmap milestones already contribute active arc payloads into daily price/event context.
- Chosen state design:
  - keep existing active arc arrays and roadmap state compatible during migration
  - add per-company living lifecycle state for eligibility, active source metadata, compact completed history, cooldowns, and story memory
  - add a small global living arc registry for fast indexes, recent completions, and source-level cadence only
- Old companies or saves without living arc state remain neutral and eligible under existing event rules.
- Runtime behavior is unchanged by this task; it is a schema/design step for Tasks 2-4.
- Verification:
  - `git diff --check`

### 2026-06-15 - Task 2 complete

- Added neutral living arc defaults to `RunState.gd`:
  - `RunState.living_company_arc_state` now saves a compact global registry with active ids, active company ids, active arc index, recent completions, lifetime completion count, and source cadence maps.
  - each company runtime now normalizes `runtime["living_arc_state"]` with active source metadata, cooldowns, eligibility/suppression tags, completed arc history, and story memory.
- Added compatibility normalizers:
  - missing global living state becomes empty indexes
  - missing per-company living state becomes neutral and eligible
  - malformed/partial state normalizes schema version, string arrays, cooldowns, tones, completed-row caps, and story memory defaults
- Added accessors:
  - `RunState.get_living_company_arc_state()`
  - `RunState.set_living_company_arc_state(next_state)`
  - `RunState.get_company_living_arc_state(company_id)`
  - `RunState.set_company_living_arc_state(company_id, next_state)`
- Added targeted probe:
  - `scripts/tests/LivingCompanyArcDefaultsTest.gd`
  - `scenes/tests/LivingCompanyArcDefaultsTest.tscn`
- Runtime behavior note:
  - Task 2 only adds saved neutral/default state and normalization. It does not start, resolve, block, or cooldown arcs yet.
  - Existing event and roadmap cadence should remain unchanged until Tasks 3-4 integrate lifecycle transitions.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/LivingCompanyArcDefaultsTest.tscn`
  - `/Users/user/.local/bin/godot --headless --path . --editor --quit`

### 2026-06-15 - Task 3 complete

- Added living arc lifecycle transitions in `RunState.gd`:
  - syncs active arc payloads into per-company living state
  - resolves disappeared/expired active arcs into compact completed rows
  - applies source, broad, and event-specific cooldown end days
  - updates per-company story memory counters and recent tags
  - updates global active indexes and recent completion audit rows
- Added public helpers:
  - `RunState.sync_living_company_arcs_for_day(day_number, active_arcs, record_source_counts)`
  - `RunState.get_company_living_arc_status(company_id, target_day_index)`
- Hooked lifecycle sync into:
  - `RunState.load_from_dict`, so old or partial saves reconcile living state with actual active arc payloads
  - `RunState.apply_day_result`, so normal day advancement drives active -> resolved -> cooldown state
  - debug/network arc insertion helpers, so manually injected arcs are reflected in living state
- Added targeted lifecycle probe:
  - `scripts/tests/LivingCompanyArcLifecycleTest.gd`
  - `scenes/tests/LivingCompanyArcLifecycleTest.tscn`
- Runtime behavior note:
  - Task 3 records lifecycle state and cooldowns, but event systems still do not consult those cooldowns for selection. That gating remains Task 4.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/LivingCompanyArcLifecycleTest.tscn`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/LivingCompanyArcDefaultsTest.tscn`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick`
  - `/Users/user/.local/bin/godot --headless --path . --editor --quit`

### 2026-06-15 - Task 4 complete

- Added living-arc availability adapters in `RunState.gd`:
  - `RunState.is_company_living_arc_available(...)`
  - `RunState.get_company_living_arc_block_reason(...)`
- `CompanyEventSystem.gd` now checks living active/cooldown state before starting company arcs.
- Company event debug/directive flows can explicitly bypass living conflict or cooldown gates through `allow_living_arc_conflict` and `allow_living_arc_cooldown`.
- `CompanyRoadmapSystem.gd` now skips living-blocked milestone owners and living-blocked financing partners.
- Eligibility tags now refresh from deterministic company facts and story memory:
  - sector/subsector ids
  - story hooks, narrative tags, moat tags
  - commodity and macro exposures
  - generated profile traits
  - roadmap profile/funding traits
  - recent story memory
- Event and roadmap selection now apply small eligibility-based weight/score adjustments from living tags and current macro commodity leaders/laggards.
- Added targeted integration probe:
  - `scripts/tests/LivingCompanyArcIntegrationTest.gd`
  - `scenes/tests/LivingCompanyArcIntegrationTest.tscn`
- Runtime behavior note:
  - Task 4 starts enforcing living active/cooldown gates for company event arcs and company roadmap milestones.
  - Eligibility tags are derived selection inputs, not hand-authored saved labels.
  - Corporate action and index review living-gate adapters can be added later if their source payloads need stricter cross-system reservation.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/LivingCompanyArcIntegrationTest.tscn`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/LivingCompanyArcLifecycleTest.tscn`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/LivingCompanyArcDefaultsTest.tscn`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick`
  - `/Users/user/.local/bin/godot --headless --path . --editor --quit`
  - `git diff --check`

### 2026-06-15 - Task 5 complete

- Added a fixed-seed long-run living arc audit:
  - `scripts/tests/LivingCompanyArcLongRunAuditTest.gd`
  - `scenes/tests/LivingCompanyArcLongRunAuditTest.tscn`
- The audit runs a catalog-backed multi-month simulation and fails on:
  - duplicate active arc ids
  - duplicate active company ids
  - active index mismatch
  - global recent completion history exceeding `80` rows
  - per-company completed arc history exceeding `8` rows
  - story-memory recent id/tag arrays exceeding `12` rows
- Saved audit history:
  - `docs/development/test_log/2026-06-15_living_company_arc_long_run_audit.md`
- 120-day fixed-seed result:
  - seed `20260615`, normal difficulty, catalog-backed `50` companies
  - global completed arc count `426`
  - final active companies `6`, cooling down `26`, eligible `18`, suppressed `0`
  - companies with any living activity `40`
  - stagnant companies `10`
  - repeat-activity companies `37`
  - retained recent completion rows capped at `80`
  - max per-company completed rows capped at `8`
- Balancing note:
  - Corporate actions dominate living arc completions in this run. State growth is bounded, but future tuning may want source-specific grouping or dedupe if this produces too much narrative repetition.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/LivingCompanyArcLongRunAuditTest.tscn -- --living-arc-audit-days 5 --living-arc-audit-use-catalog --living-arc-audit-company-count 50`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/LivingCompanyArcLongRunAuditTest.tscn -- --living-arc-audit-seed 20260615 --living-arc-audit-difficulty normal --living-arc-audit-days 120 --living-arc-audit-use-catalog --living-arc-audit-company-count 50`

---

## Task 1 - Define living arc state shape

Problem: Company story lifecycle cannot be tested until the saved state shape is explicit.

1. Define fields such as `active_arc_id`, `active_arc_started_day`, `completed_arcs`, `cooldowns`, `eligibility_tags`, and `story_memory`.
2. Decide which state belongs per company and which belongs to global run state.
3. Document how old companies without arc state should behave.
4. Verify:
   - Design review in this doc.
   - `git diff --check`

### Task 1 state shape now defined

#### Design direction

The living arc layer should be an adapter over existing systems, not a rewrite.

Current systems already do useful work:

- `CompanyEventSystem` builds multi-phase company arcs and emits active arc payloads.
- `CompanyRoadmapSystem` stores active/resolved roadmap milestones and has per-company roadmap cooldowns.
- Corporate actions and index reviews already emit active company arc payloads into `MarketSimulator`.

The new living state should answer questions the current systems do not answer cleanly:

- Is this company currently in a story?
- What kind of story just ended?
- When can the company receive another story?
- What broad story tags has this company already experienced?
- Is the company stale, cooling down, or eligible again?

#### Per-company state

Add a normalized runtime field in each company:

```gdscript
runtime["living_arc_state"] = {
	"schema_version": 1,
	"company_id": company_id,
	"active_arc_id": "",
	"active_source_system": "",
	"active_arc_type": "",
	"active_event_id": "",
	"active_tone": "neutral",
	"active_arc_started_day": -1,
	"active_arc_expected_end_day": -1,
	"active_phase_id": "",
	"active_phase_label": "",
	"last_resolved_day": -999,
	"cooldowns": {},
	"eligibility_tags": [],
	"suppression_tags": [],
	"completed_arcs": [],
	"story_memory": {}
}
```

Primary fields:

| Field | Meaning |
|---|---|
| `schema_version` | Version marker for future save migrations. |
| `company_id` | Defensive id mirror for validation. |
| `active_arc_id` | Empty when no living arc is active for this company. |
| `active_source_system` | Source owner, such as `company_arc`, `company_roadmap`, `corporate_action`, `index_review`, `story_dossier`, or future `relationship_graph`. |
| `active_arc_type` | Broad type such as `earnings`, `roadmap`, `corporate_action`, `index_review`, `macro_sector`, `turnaround`, `governance`, `partnership`, or `acquisition_interest`. |
| `active_event_id` | Specific current event id when applicable. |
| `active_tone` | `positive`, `negative`, `mixed`, or `neutral`. |
| `active_arc_started_day` | Day index when the current arc became active. |
| `active_arc_expected_end_day` | Expected end day from the source system. |
| `active_phase_id` / `active_phase_label` | Current phase snapshot for UI/debug/audit. |
| `last_resolved_day` | Last day this company resolved any living arc. |
| `cooldowns` | Per-source and broad cooldown end days. |
| `eligibility_tags` | Deterministic tags used by future arc selection. |
| `suppression_tags` | Temporary tags that block incompatible arcs. |
| `completed_arcs` | Compact per-company arc history. |
| `story_memory` | Aggregates and last-known story outcomes. |

Do not treat `lifecycle_status` as a saved source of truth. It should be derived:

| Derived status | Rule |
|---|---|
| `active` | `active_arc_id` is not empty and expected end day has not passed. |
| `cooling_down` | no active arc, but any relevant cooldown end day is greater than current day. |
| `eligible` | no active arc and no blocking cooldown. |
| `suppressed` | no active arc, but `suppression_tags` contains an active hard block. |

#### Cooldown shape

`cooldowns` is a dictionary of end-day indexes:

```gdscript
"cooldowns": {
	"any": -999,
	"company_arc": -999,
	"company_roadmap": -999,
	"corporate_action": -999,
	"index_review": -999,
	"macro_sector": -999,
	"relationship_graph": -999,
	"event:earnings_beat": -999,
	"event:earnings_miss": -999
}
```

Initial default cooldown guidance for Task 3:

| Source | Suggested cooldown |
|---|---:|
| `company_arc` | `28` days |
| `company_roadmap` | `24` days, matching current roadmap behavior |
| `corporate_action` | `40` days after chain resolution |
| `index_review` | `20` days |
| `macro_sector` | `14` days |
| `relationship_graph` | `18` days |
| `any` | `12` days minimum between unrelated story starts |

These are starting values for implementation tests, not final balancing.

#### Completed arc rows

`completed_arcs` must stay compact. Store at most `8` rows per company at first.

Each completed row should use this shape:

```gdscript
{
	"arc_id": "",
	"source_system": "",
	"arc_type": "",
	"event_id": "",
	"tone": "neutral",
	"outcome": "resolved",
	"started_day_index": -1,
	"resolved_day_index": -1,
	"duration_days": 0,
	"peak_return_pct": 0.0,
	"final_return_pct": 0.0,
	"evidence_refs": [],
	"story_tags": []
}
```

Rules:

- Do not store daily phase logs in `completed_arcs`.
- Use compact ids and tags; display text can be regenerated from source data.
- Keep old completed rows even if the company becomes active again.
- If the same event type repeats later, append a new row and let compacting drop the oldest row.

#### Story memory shape

`story_memory` is aggregate state for future selection and content generation:

```gdscript
"story_memory": {
	"completed_count": 0,
	"positive_count": 0,
	"negative_count": 0,
	"mixed_count": 0,
	"last_arc_id": "",
	"last_source_system": "",
	"last_arc_type": "",
	"last_event_id": "",
	"last_tone": "neutral",
	"last_outcome": "",
	"recent_arc_ids": [],
	"recent_story_tags": []
}
```

This gives future systems enough context to avoid repetitive stories without scanning every event history row.

#### Eligibility tags

`eligibility_tags` should merge stable company facts with compact story memory:

- company universe fields: `story_hooks`, `narrative_tags`, `moat_tags`, `commodity_exposures`, `macro_exposures`
- generated profile traits: story heat, growth, balance-sheet strength, execution consistency
- roadmap profile tags: physical project, funding scale, family id, location id
- dynamic memory tags: recently completed arc types, cooldowns, negative/positive streaks

Examples:

- `commodity_sensitive`
- `high_story_heat`
- `weak_balance_sheet`
- `roadmap_physical_project`
- `funding_need`
- `turnaround_candidate`
- `recent_earnings_arc`
- `recent_corporate_action`

Task 2 should only normalize and preserve tags. Task 3/4 can start using them for selection.

#### Global run state

Add a normalized global field:

```gdscript
RunState.living_company_arc_state = {
	"schema_version": 1,
	"active_arc_ids": [],
	"active_company_ids": [],
	"active_arc_index": {},
	"recent_completed_arcs": [],
	"completed_arc_count": 0,
	"source_last_spawn_day": {},
	"source_daily_start_counts": {}
}
```

Global fields should be indexes and audit aids only:

| Field | Meaning |
|---|---|
| `active_arc_ids` | Fast list of active ids across all source systems. |
| `active_company_ids` | Companies currently reserved by active arcs. |
| `active_arc_index` | `arc_id -> compact active metadata`. |
| `recent_completed_arcs` | Compact cross-company completion history, capped around `80` rows. |
| `completed_arc_count` | Lifetime count for audits/achievements. |
| `source_last_spawn_day` | Per-source cadence helper. |
| `source_daily_start_counts` | Per-day guard against event spam. |

Do not duplicate full active arc payloads globally. Existing `active_company_arcs`, `company_roadmap_state`, corporate action state, and index review state remain source-owned.

#### Compatibility behavior

Old saves and generated companies without living state should behave as follows:

- Missing `runtime["living_arc_state"]` normalizes to neutral.
- Missing `RunState.living_company_arc_state` normalizes to empty indexes.
- Neutral companies have no active arc, no completed history, no cooldowns, and no suppression tags.
- Neutral companies are eligible under existing event and roadmap rules.
- Existing `active_company_arcs` and `company_roadmap_state` remain valid even before the living adapter backfills them.
- Task 2 should not change price behavior, event cadence, roadmap cadence, or save payload meaning beyond adding neutral defaults.

#### Source ownership rule

Each source system keeps owning its detailed payload:

| Source | Detailed payload stays in | Living layer stores |
|---|---|---|
| Company event arcs | `RunState.active_company_arcs` | active id, company id, type, phase, cooldown, completion row |
| Roadmap milestones | `RunState.company_roadmap_state` | active id, company id, roadmap type, cooldown, completion row |
| Corporate actions | corporate action chain state | active id, company id, chain type, cooldown, completion row |
| Index review | index review state / active arc payload | active id, company id, review type, cooldown, completion row |
| Future story dossier | dossier state | active id, company id, dossier arc type, cooldown, completion row |

This keeps the living layer small and prevents two systems from becoming full sources of truth for the same story.

## Task 2 - Add normalizers and compatibility defaults

Problem: Old saves need neutral living arc state.

1. Add defaults in the existing company/run state normalizer path.
2. Ensure missing arc fields do not block existing events.
3. Verify:
   - Save/default targeted probe.
   - Godot headless editor gate.

### Task 2 implementation notes

- The living arc state is now present in new runs, save payloads, loaded saves, and per-day normalized company runtime payloads.
- Old saves that do not include living arc fields are backfilled to neutral defaults during `RunState.load_from_dict`.
- The default state intentionally keeps `active_arc_id` empty, cooldowns at `-999`, and completed histories empty so existing event systems remain eligible under their old rules.
- Completed per-company arc rows are capped at `8`; global recent completions are capped at `80`.
- Invalid tone values normalize to `neutral`.

## Task 3 - Add arc lifecycle transitions

Problem: Arc state needs consistent transitions rather than one-off event flags.

1. Implement transitions for eligible -> active -> resolved -> cooldown -> eligible.
2. Persist completed arc history and outcome.
3. Keep transitions deterministic by seed and day.
4. Verify:
   - Targeted lifecycle test.
   - Quick smoke if event flow changes.

### Task 3 implementation notes

- Active arc payloads remain source-owned by existing systems. The living layer only stores compact lifecycle metadata.
- `eligible -> active` happens when an active arc payload appears for a company.
- `active -> resolved` happens when the previously active id no longer appears in the active payload list or has passed its expected end day.
- `resolved -> cooldown` is represented by cooldown end-day fields, not a saved status enum.
- `cooldown -> eligible` is derived by `RunState.get_company_living_arc_status`.
- Completed rows keep the arc id, source system, event id, tone, start/resolved day, duration, return metrics, evidence refs, and story tags.
- Task 4 makes event and roadmap candidate selection respect active/cooldown state.

## Task 4 - Integrate with existing event and roadmap systems

Problem: Existing company events need to respect living arc state without being rewritten wholesale.

1. Add a small adapter or helper for event systems to read/write arc state.
2. Prevent incompatible simultaneous arcs unless explicitly allowed.
3. Let macro/sector/company facts influence arc eligibility.
4. Verify:
   - Company event scenario test.
   - No duplicated event spam in smoke.

### Task 4 implementation notes

- `RunState.is_company_living_arc_available` is the shared adapter for source systems that need to reserve or skip companies.
- `CompanyEventSystem` uses the adapter before a company arc can start, so an active living arc or matching cooldown blocks duplicate company drama unless a debug/directive override is present.
- `CompanyRoadmapSystem` uses the same adapter for milestone owner selection and finance partner selection.
- Living eligibility tags are refreshed from deterministic company facts plus compact story memory, then used as modest event/roadmap score nudges rather than hard requirements.
- Macro commodity leaders/laggards can influence event and roadmap eligibility when a company has matching commodity exposure tags.
- The integration probe verifies active-arc blocking, cooldown blocking, explicit cooldown override, and roadmap selection resuming when exactly one company becomes eligible.

## Task 5 - Add lifecycle tests and audit logging

Problem: Long-running games need proof that companies stay alive without becoming chaotic.

1. Run a fixed-seed multi-month scenario.
2. Log active arcs, completed arcs, cooldowns, repeated company activity, and stagnant companies.
3. Save notable results in `docs/development/test_log/`.
4. Verify:
   - Long-run probe completes.
   - No unbounded state growth.

### Task 5 implementation notes

- `LivingCompanyArcLongRunAuditTest` is the repeatable lifecycle audit gate.
- The audit reports active arcs, completed arcs, cooldowned companies, status stock-days, repeat activity, stagnant companies, retained completion mixes, and top active companies.
- Hard failures are limited to state corruption and unbounded-growth risks. Balance signals such as stagnant company count or corporate-action-heavy completions are reported for tuning rather than treated as immediate correctness failures.
- The first saved audit is `docs/development/test_log/2026-06-15_living_company_arc_long_run_audit.md`.

## Known traps

- If cooldowns are too short, the same company may dominate every run.
- If cooldowns are too long, the system recreates the stagnant-company problem.
- Arc history should be compact; daily logs do not belong in saved company state.
