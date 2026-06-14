# Buy High Sell Low Stock Trading Simulator Handoff

Read this file first in the next session.

This is the lean re-entry guide. The full historical handoff was archived at
[`docs/development/archive/PROJECT_HANDOFF_2026-06-13.md`](docs/development/archive/PROJECT_HANDOFF_2026-06-13.md).

## Project Snapshot

- Project: `Buy High Sell Low Stock Trading Simulator`
- Engine target: Godot `4.6.x`
- Current Mac workspace: `/Users/user/Documents/gorengangame/godot-game-1`
- Current Mac CLI: `/Users/user/.local/bin/godot` / `/Users/user/.local/bin/godot4`
- Mac CLI version recently verified: `4.6.2.stable.official.71f334935`
- Current Windows project path from prior handoffs: `c:\Users\Alif\Documents\godot game 1\new-game-project`
- Current Windows verifier from prior handoffs: `C:\Users\Alif\Desktop\Godot_v4.6.2-stable_win64_console.exe`
- Current milestone: `first playable prototype`
- Current shell: `desktop-first`
- Seed date in-game: `Thursday, 2 January 2020`
- First player-visible fresh-run session: `Friday, 3 January 2020`
- Fresh runs simulate the first trading session before handing control to the player.

## Repo State

- Branch: `codex/contact-network-inner-circle-dialogs`
- Current checked commit at this handoff update: `d7c88c7`
- Remote: `origin https://github.com/alifhunter/godot-game-1.git`
- Run `git status --short` before editing.
- The worktree is intentionally dirty from recent development work and the docs-folder move.
- Do not revert user work or broad dirty files unless explicitly asked.
- Current notable dirty areas:
  - company generation enhancement Tasks 1-8 are complete but not yet committed
  - thesis system enhancement Tasks 1-7 are complete but not yet committed
  - new company-generation tests/builders/utilities are untracked until committed
  - new thesis content JSON and thesis test scenes/scripts are untracked until committed
  - contact network / inner-circle dialog work is present on this feature branch
  - Godot MCP addon/config files may be local/uncommitted
- Python validator `__pycache__/` folders and local `logs/` output are disposable.

## Recent Development Docs

Use these docs instead of expanding this handoff with long progress logs.

- [`docs/development/GOD_FILES_ENHANCEMENT.md`](docs/development/GOD_FILES_ENHANCEMENT.md)
  - God-file refactor, controller extraction, follow-ups, verification history.
- [`docs/development/CODE_REVIEW_GOD_FILES.md`](docs/development/CODE_REVIEW_GOD_FILES.md)
  - Review basis for the GameRoot/GameManager/RunState refactor.
- [`docs/development/SOCIAL_DIALOG_ENHANCEMENT.md`](docs/development/SOCIAL_DIALOG_ENHANCEMENT.md)
  - Social dialog plan and completed Tasks 1-6.
- [`docs/development/TWOOTER_INTERACTION_SYSTEM_ENHANCEMENT.md`](docs/development/TWOOTER_INTERACTION_SYSTEM_ENHANCEMENT.md)
  - Twooter interaction system plan and completed Tasks 1-6.
- [`docs/development/CONTACT_NETWORK_INNER_CIRCLE_DIALOG_ENHANCEMENT.md`](docs/development/CONTACT_NETWORK_INNER_CIRCLE_DIALOG_ENHANCEMENT.md)
  - Planned staged Network dialog, referral-gated inner-circle access, and direct inner-circle tip payload work.
- [`docs/development/COMPANY_GENERATION_ENHANCEMENT.md`](docs/development/COMPANY_GENERATION_ENHANCEMENT.md)
  - Completed company-generation maintainability plan: deterministic fingerprint, validation warnings, named tuning constants, generator split, CEO identity continuity, seeded-pool helper, and collision-policy probe.
- [`docs/development/THESIS_SYSTEM_ENHANCEMENT.md`](docs/development/THESIS_SYSTEM_ENHANCEMENT.md)
  - Completed thesis-system plan: fingerprint probe, typed vocabulary, scoring constants/rebalance, option-builder cleanup, sector/stance guidance, and externalized thesis content catalog.
- [`docs/development/FEATURE_ENHANCEMENT_TEMPLATE.md`](docs/development/FEATURE_ENHANCEMENT_TEMPLATE.md)
  - Template for future feature/enhancement/development plans.
- [`docs/development/DESIGN_SYSTEM.md`](docs/development/DESIGN_SYSTEM.md)
  - UI styling and token guidance.
- [`docs/development/KNOWN_ISSUES.md`](docs/development/KNOWN_ISSUES.md)
  - Development-facing known issues and tester notes.

## Steam And Release Docs

- [`docs/steam/BUG_REPORT_TEMPLATE.md`](docs/steam/BUG_REPORT_TEMPLATE.md)
- [`docs/steam/RELEASE_LICENSE_AUDIT.md`](docs/steam/RELEASE_LICENSE_AUDIT.md)
- [`docs/steam/STEAM_ACHIEVEMENT_IDS.md`](docs/steam/STEAM_ACHIEVEMENT_IDS.md)
- [`docs/steam/STEAM_BUILD_UPLOAD_GUIDE.md`](docs/steam/STEAM_BUILD_UPLOAD_GUIDE.md)
- [`docs/steam/STEAM_CLOUD_SAVE_PATHS.md`](docs/steam/STEAM_CLOUD_SAVE_PATHS.md)
- [`docs/steam/STEAM_PLAYTEST_CHECKLIST.md`](docs/steam/STEAM_PLAYTEST_CHECKLIST.md)

## Feature Entry Points

Use this as the first file map when the user asks for a specific feature. Start from these files, then use `rg` for the exact function, saved key, scene node, or test assertion.

### App Shell / Desktop

- Main root: `scripts/ui/GameRoot.gd`
- App controllers: `scripts/ui/controllers/*.gd`
- UI tokens/styles: `autoloads/UiTheme.gd`, `docs/development/DESIGN_SYSTEM.md`
- First smoke coverage: `scripts/tests/SmokeTest.gd`

### Run State / Save / Data Loading

- Runtime state: `autoloads/RunState.gd`
- Public gameplay API: `autoloads/GameManager.gd`
- Save/load: `autoloads/SaveManager.gd`, `systems/SaveMigrations.gd`
- Static data access: `autoloads/DataRepository.gd`
- Compatibility rule: preserve saved keys or add migration/default normalizers.

### Stockbot / Trading / Market UI

- UI controller: `scripts/ui/controllers/StockController.gd`
- Market simulation: `systems/MarketSimulator.gd`, `systems/IDXPriceRules.gd`
- Chart/broker helpers: `systems/ChartSystem.gd`, `systems/ChartPatternSystem.gd`, `systems/BrokerFlowSystem.gd`
- Tests/audits: `scripts/tests/SmokeTest.gd`, `scripts/tests/BrokerRangeHistoryTest.gd`, `scripts/tests/MarketYearAudit.gd`, `scripts/tests/LongRunStabilityTest.gd`

### Corporate Actions / RUPSLB / Index Reviews

- Scheduling/snapshots: `systems/CorporateActionSystem.gd`
- Execution effects: `systems/CorporateActionApplications.gd`
- RUPSLB overlay: `scripts/ui/widgets/RupslbMeetingOverlay.gd`
- Index reviews: `systems/IndexReviewSystem.gd`, `data/index_reviews/index_review_catalog.json`
- Tests: `scripts/tests/SmokeTest.gd`

### Gorengan / Special Market Events

- Campaign logic: `systems/GorenganCampaignSystem.gd`, `systems/CampaignState.gd`
- Event generation: `systems/SpecialEventSystem.gd`, `systems/CompanyEventSystem.gd`, `systems/EventContext.gd`
- Dirty tips / enforcement: `systems/DirtyTipSystem.gd`, `systems/LifeManager.gd`
- Audits: `scripts/tests/MarketYearAudit.gd`, `scripts/tests/EventGenerationAuditTest.gd`

### Company Profiles / Generation / Roadmaps

- Public generation facade/profile schema: `systems/CompanyGenerator.gd`, `systems/CompanyProfile.gd`
- Chart/financial generation builders: `systems/CompanyChartProfileBuilder.gd`, `systems/CompanyFinancialsBuilder.gd`
- Roster/narrative/pool helpers: `systems/CompanyRosterGenerator.gd`, `systems/CompanyNarrativeGenerator.gd`, `systems/SeededPool.gd`
- Runtime wrapper: `systems/CompanyRuntime.gd`
- CEO-change insider identity: `systems/CorporateActionApplications.gd`, `autoloads/GameManager.gd`, `systems/ContactNetworkSystem.gd`
- Roadmaps: `systems/CompanyRoadmapSystem.gd`
- UI app: `scripts/ui/controllers/CompanyController.gd`
- Tests: `scripts/tests/CompanyGenerationFingerprintTest.gd`, `scripts/tests/CompanyGenerationValidationTest.gd`, `scripts/tests/CompanyCeoChangeIdentityTest.gd`, `scripts/tests/CompanyRosterCollisionPolicyTest.gd`, `scripts/tests/CompanyRoadmapSystemTest.gd`
- Plan doc: `docs/development/COMPANY_GENERATION_ENHANCEMENT.md`

### News / Attention / Daily Summary

- News feed: `systems/NewsFeedSystem.gd`, `scripts/ui/controllers/NewsController.gd`
- Attention director: `systems/AttentionDirectorSystem.gd`
- Daily summary: `systems/SummaryInsightSystem.gd`
- Smoke coverage: `scripts/tests/SmokeTest.gd`

### Twooter / Social Dialog

- UI controller: `scripts/ui/controllers/SocialController.gd`
- Feed generation/state: `systems/TwooterFeedSystem.gd`, `systems/TwooterStateSystem.gd`
- Interaction bridge: `systems/TwooterInteractionSystem.gd`
- Routing/outcomes: `systems/TwooterDialogRouter.gd`, `systems/TwooterOutcomeResolver.gd`
- Runtime data: `data/social/twooter_feed_data.json`
- Source/editor data: `tools/twooter_editor/twooter_source.json`, `tools/twooter_editor/server.py`
- Focused tests: `scripts/tests/TwooterRoutingRulesTest.gd`, `scripts/tests/TwooterFallbackDialogTest.gd`, `scripts/tests/TwooterNetworkProgressionTest.gd`, `scripts/tests/TwooterDialogReachabilityTest.gd`, `scripts/tests/TwooterOutcomeConsequencesTest.gd`
- Plan docs: `docs/development/SOCIAL_DIALOG_ENHANCEMENT.md`, `docs/development/TWOOTER_INTERACTION_SYSTEM_ENHANCEMENT.md`

### Network / Contacts / Intel

- UI controller: `scripts/ui/controllers/NetworkController.gd`
- Contact logic: `systems/ContactNetworkSystem.gd`, `systems/PersonEventSystem.gd`
- Twooter bridge: `systems/TwooterInteractionSystem.gd`, `systems/TwooterOutcomeResolver.gd`
- Tests: `scripts/tests/NetworkConsequenceFollowupTest.gd`, `scripts/tests/TwooterNetworkLoopTest.gd`, `scripts/tests/TwooterNetworkProgressionTest.gd`

### Thesis / Research Tray

- UI: `scripts/ui/widgets/ThesisBoardWidget.gd`, `scripts/ui/GameRoot.gd`
- Domain/state facade: `systems/ThesisManager.gd`
- Typed vocabulary/content accessors: `systems/ThesisVocabulary.gd`
- Evidence capture: `systems/ThesisEvidenceCaptureSystem.gd`
- Report generation/scoring: `systems/ThesisReportSystem.gd`
- Externalized content catalog: `data/thesis/thesis_content.json`
- Data loading: `autoloads/DataRepository.gd`
- Tests: `scripts/tests/ThesisFingerprintTest.gd`, `scripts/tests/ThesisContentCatalogValidationTest.gd`, `scripts/tests/ThesisContentDepthTest.gd`, `scripts/tests/ThesisScoringRebalanceTest.gd`, `scripts/tests/ThesisResearchTrayTest.gd`, `scripts/tests/ThesisVocabularyValidationTest.gd`, `scripts/tests/SmokeTest.gd`
- Plan doc: `docs/development/THESIS_SYSTEM_ENHANCEMENT.md`

### Life / Wealth Progression

- UI controller: `scripts/ui/controllers/LifeController.gd`
- Life systems: `systems/LifeManager.gd`, `systems/LifeStateSystem.gd`
- Tests: `scripts/tests/LifeDevelopmentIntelTest.gd`, `scripts/tests/LifeLifestyleAssetTest.gd`, `scripts/tests/SmokeTest.gd`

### Upgrades / Academy / Guide Flow

- Upgrades UI: `scripts/ui/controllers/UpgradesController.gd`
- Academy UI/system: `scripts/ui/controllers/AcademyController.gd`, `systems/AcademySystem.gd`
- FTUE/guide: `systems/GuideFlowSystem.gd`, `scripts/ui/GameRoot.gd`
- Steam progress: `autoloads/SteamProgressManager.gd`, `scripts/tests/SteamProgressManagerTest.gd`

## Current Implementation Status

### God Files

- The god-file cleanup plan is complete.
- `GameRoot.gd` was decomposed into app controllers.
- `GameManager.gd` and `RunState.gd` had major domains extracted into focused systems.
- Per-app controllers now own Upgrades, Academy, Network, Life, Company, Social, News, and Stock surfaces.
- Follow-up cleanup is complete:
  - warning cleanup
  - shared `UITheme`
  - controller-owned state
  - no-op state-sync shim removal
  - typed `CompanyRuntime` boundary with perf pass
- The detailed status and verification log lives in
  [`docs/development/GOD_FILES_ENHANCEMENT.md`](docs/development/GOD_FILES_ENHANCEMENT.md).

### Social Dialog

- Social dialog enhancement Tasks 1-6 are complete.
- The system now has:
  - per-option reply pools
  - exact `option_id` matching through UI -> GameManager -> interaction system
  - named thresholds and warning hygiene
  - consumed `outcome` effects
  - tree graduation via `step_count`
  - expanded content pools and per-option replies
- The detailed plan and progress log live in
  [`docs/development/SOCIAL_DIALOG_ENHANCEMENT.md`](docs/development/SOCIAL_DIALOG_ENHANCEMENT.md).

### Twooter Interaction System

- Twooter interaction enhancement Tasks 1-6 are complete.
- Added focused test coverage for:
  - dialog reachability
  - Network tree progression
  - routing rules
  - outcome consequences
  - fallback dialog behavior
- `systems/TwooterDialogRouter.gd` now owns:
  - public/private tree selection
  - data-driven routing rule matching
  - profile preferred tree lookup
  - tree surface validation
  - branch normalization
  - graduation handoff checks
- `systems/TwooterOutcomeResolver.gd` now owns:
  - outcome effect dictionaries
  - outcome labels
  - timeline/journal notes
  - timeline text composition
  - Network confidence labels
- `systems/TwooterInteractionSystem.gd` keeps stable delegate wrappers and the Network bridge.
- Renderer/state-normalizer extraction is intentionally deferred.
- The detailed plan and progress log live in
  [`docs/development/TWOOTER_INTERACTION_SYSTEM_ENHANCEMENT.md`](docs/development/TWOOTER_INTERACTION_SYSTEM_ENHANCEMENT.md).

### Company Generation

- Company generation enhancement Tasks 1-8 are complete.
- The default 30-company full-roster fingerprint is the primary determinism gate:
  - seed `20260614`
  - expected hash `1225696160`
  - duplicate names `0`
  - duplicate tickers `0`
- New focused probes cover:
  - deterministic full-roster generation and hydration
  - invalid-input warning behavior
  - CEO-change insider identity continuity
  - inflated-roster name/ticker collision policy at `30`, `80`, `120`, and `200` companies
- `CompanyGenerator.gd` remains the public facade, with chart/financial orchestration split into:
  - `systems/CompanyChartProfileBuilder.gd`
  - `systems/CompanyFinancialsBuilder.gd`
- `systems/SeededPool.gd` now centralizes matching roster/narrative pool selection without changing RNG ownership or call order.
- CEO changes now key insider identity on the person: the old CEO remains as a stale/departed `free_agent`, while the new CEO is a fresh `insider` discovery.
- Name/ticker collision policy is currently "document and accept": measured rosters up to 200 companies showed zero duplicates and no fallback hits. If larger rosters prove insufficient later, use deterministic seeded suffix fallback after the existing retry budget.
- The detailed plan and progress log live in
  [`docs/development/COMPANY_GENERATION_ENHANCEMENT.md`](docs/development/COMPANY_GENERATION_ENHANCEMENT.md).

### Thesis System

- Thesis system enhancement Tasks 1-7 are complete.
- The fixed-seed thesis fingerprint is now the primary thesis determinism gate:
  - seed `20260614`
  - company `anre` / ticker `ANRE`
  - expected full hash `672110177`
  - expected option hash `747086609`
  - expected report hash `1836382259`
  - expected score `72`, memo state `Developing Memo`, grade `B`
- `systems/ThesisVocabulary.gd` centralizes typed vocabulary and JSON-backed content accessors with inline fallbacks.
- `data/thesis/thesis_content.json` now owns editable thesis copy:
  - category/interpretation/source labels
  - report and UI evidence pillars
  - stance/horizon options and evidence tabs
  - memo states, grade copy, report sections, empty states, learning notes
  - quality/growth/risk band labels/details
  - sector macro lenses and stance/horizon next-research guidance
- `ThesisReportSystem.gd` scoring is aligned to five pillars: Anchor / Price / Tape / Catalyst / Risk.
- `ThesisBoardWidget.gd` uses sector-aware and stance/horizon-aware guidance while preserving score/report math.
- The detailed plan and progress log live in
  [`docs/development/THESIS_SYSTEM_ENHANCEMENT.md`](docs/development/THESIS_SYSTEM_ENHANCEMENT.md).

### Market / Gorengan / Long-Run Balance

- Market/gorengan balance work remains a major gameplay area.
- Existing systems include:
  - `systems/GorenganCampaignSystem.gd`
  - campaign-aware market integration
  - value/turnover governors
  - Rp50 floor and turnaround behavior
  - quarterly filing updates
  - `MarketYearAudit` coverage
- Recent audit caveats from the archive still matter:
  - passive campaign success metrics may be stricter than player-facing campaign success
  - UMA/suspension cadence may need tuning
  - long-run market harshness needs human playtest feel
- See the archived handoff for the detailed historical audit numbers.

### Desktop / Apps

- The current first-playable loop is desktop-first.
- Main visible apps:
  - `STOCKBOT`
  - `News`
  - `Twooter`
  - `Network`
  - `Thesis Board`
  - `Life`
  - `Company`
  - `Upgrades`
  - `Academy`
- Academy is still treated as release-locked/Coming Soon in the current player flow unless later work changes that.
- Twooter is public by default and no longer a purchasable upgrade track.
- Network and Twooter are connected through source contacts, discoveries, journal rows, and follow-up reactions.

## Important Runtime Decisions

- Keep save compatibility first.
- Do not rename or remove saved keys without a migration.
- New saved keys need defaults in every normalizer path.
- Use dict-in/dict-out boundaries where save payload compatibility matters.
- Avoid wrapper/copy layers in hot daily simulation or snapshot paths unless measured.
- Runtime JSON and editor/source JSON can drift; when changing authored content, update source and exported runtime data together.
- Determinism matters:
  - use stable seed keys and hash-based selection
  - avoid `randi()` in content/routing/test paths
  - compare long-run audits with timing lines filtered when checking behavior identity
- `SmokeTest` reads some UI internals directly. If root/controller state names move, grep for direct reads and `set("<name>", ...)` calls.
- Godot `validate_script` can report misleading class-name warnings on standalone `class_name` files; use dependent scripts or headless editor parse as the source of truth.

## Verification Commands

Use these from `/Users/user/Documents/gorengangame/godot-game-1` unless noted.

### Standard Docs / Code Gate

```bash
git diff --check
```

### JSON Validation

```bash
python3 -m json.tool data/social/twooter_feed_data.json > /dev/null
python3 -m json.tool tools/twooter_editor/twooter_source.json > /dev/null
python3 -m json.tool data/thesis/thesis_content.json > /dev/null
```

### Twooter Editor Validation

```bash
python3 tools/twooter_editor/server.py --validate
python3 tools/twooter_editor/server.py --export --dry-run
```

### Godot Editor Parse

```bash
/Users/user/.local/bin/godot --headless -e --quit
```

### Quick Smoke

```bash
/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io
```

Expected quick smoke sentinel:

```text
SMOKE_QUICK_OK normal_equity=94765318.11 days=3
```

### Focused Twooter Tests

```bash
/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/TwooterRoutingRulesTest.tscn
/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/TwooterFallbackDialogTest.tscn
/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/TwooterNetworkProgressionTest.tscn
/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/TwooterDialogReachabilityTest.tscn
/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/TwooterOutcomeConsequencesTest.tscn
```

Expected sentinels:

```text
TWOOTER_ROUTING_RULES_OK
TWOOTER_FALLBACK_DIALOG_OK
TWOOTER_NETWORK_PROGRESSION_OK
TWOOTER_DIALOG_REACHABILITY_OK
TWOOTER_OUTCOME_CONSEQUENCES_OK
```

### Focused Company Generation Tests

```bash
/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyGenerationFingerprintTest.tscn
/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyGenerationValidationTest.tscn
/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyCeoChangeIdentityTest.tscn
/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyRosterCollisionPolicyTest.tscn
```

Expected sentinels:

```text
COMPANY_GENERATION_FINGERPRINT_OK ... "hash":"1225696160" ...
COMPANY_GENERATION_VALIDATION_WARNING_OK
COMPANY_CEO_CHANGE_IDENTITY_OK
COMPANY_ROSTER_COLLISION_POLICY_OK
```

### Focused Thesis Tests

```bash
/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/ThesisContentCatalogValidationTest.tscn
/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/ThesisFingerprintTest.tscn
/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/ThesisContentDepthTest.tscn
/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/ThesisScoringRebalanceTest.tscn
/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/ThesisResearchTrayTest.tscn
/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/ThesisVocabularyValidationTest.tscn
```

Expected sentinels:

```text
THESIS_CONTENT_CATALOG_VALIDATION_OK
THESIS_FINGERPRINT_OK ... "hash":"672110177" ... "option_hash":"747086609" ... "report_hash":"1836382259" ...
THESIS_CONTENT_DEPTH_OK
THESIS_SCORING_REBALANCE_OK
THESIS_RESEARCH_TRAY_OK
THESIS_VOCABULARY_VALIDATION_OK
```

### Long-Run Audit

Run only when simulation, market balance, event generation, or performance risk justifies it.

```bash
/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/MarketYearAudit.tscn -- --audit-days 225 --audit-seed 20260606 --audit-difficulty grind
```

## Known Verification Noise

- Steam API initialization warnings are expected in local headless runs when Steam is not running.
- RID/ObjectDB/resource cleanup warnings after a successful `_OK` sentinel are known headless teardown noise.
- Windows root-certificate warnings after successful smoke output are non-blocking.
- The full smoke has known pre-existing layout/coverage issues in some flows; quick smoke is the normal gate unless the task targets full UI coverage.

## Current Recommended Next Steps

### 1. Checkpoint Hygiene

- Review `git status --short` before every task.
- Review and commit the completed company-generation and thesis-system enhancement files as the next checkpoint if the diff is clean.
- Keep the company-generation probes and thesis probes in the checkpoint; they are now the determinism/content safety nets.
- Preserve unrelated dirty implementation work.

### 2. Release / Steam Prep

- Review the Steam docs under [`docs/steam/`](docs/steam/).
- Before external testers:
  - run a fresh Steam-client playtest from the live test branch
  - verify save, quit, local folder rename/delete, Steam Cloud restore, load, and advance-day sanity
  - review `BHSL.exe` launch setup and Cloud paths
  - refresh player-facing known issues and bug-report template

### 3. Twooter / Network Follow-Up

- The next likely slice is presentation and provenance, not core routing.
- Consider surfacing Twooter provenance fields more clearly in Network contact details and journal rows:
  - `source_label`
  - `source_note`
  - `twooter_origin`
  - `twooter_handle`
  - `source_only`
- Keep focused Twooter tests current if touching source-only contacts, journal rendering, cooldowns, AP refunds, diminishing gains, search, or contact promotion.

### 4. Market / Gorengan Tuning

- Review why `successful_executed` can remain `0` when campaigns visibly reach strong returns.
- Tune UMA/suspension visibility if regulatory interruption should be more visible.
- Playtest value bars and Index Gorengan feel after the value governor.
- Use forced/debug scenarios for dirty-tip, jail, hospital, pump, and dump beats instead of expecting passive audits to trigger everything.

### 5. Life / Wealth Progression

- Keep trading/investing as the main wealth engine.
- Preserve the no-gambling guardrail:
  - no betting
  - no casino minigames
  - no paid random reward loops
  - no side activity that out-earns stocks more easily
- Current Life slice covers properties, cars, emergency finance, and derived pressure.
- Next Life pass should tune costs, rent/upkeep, car/property status effects, finance warning copy, and near-bankruptcy feel.

### 6. Performance Follow-Up

- Use `[perf][advance]`, `[perf][apply]`, `[perf][ui]`, and `[perf][save]` logs.
- Treat performance as follow-up only when hitches are visible during playtesting.
- Likely targets if needed:
  - `simulate_day`
  - News feed rendering/recording
  - post-recap save flush
  - heavy app redraws after Daily Recap closes
  - deferred app refresh queue

### 7. Future Planning Docs

- Start new enhancement plans from
  [`docs/development/FEATURE_ENHANCEMENT_TEMPLATE.md`](docs/development/FEATURE_ENHANCEMENT_TEMPLATE.md).
- Keep plans in `docs/development/`.
- Keep release/tester-facing docs in `docs/steam/`.
- Prefer linking from this handoff instead of pasting long progress logs here.

## Good Re-entry Prompt

Use something like:

```text
Read PROJECT_HANDOFF.md first, then continue Buy High Sell Low Stock Trading Simulator from there.
```
