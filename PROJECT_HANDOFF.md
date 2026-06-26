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

- Branch: `main`
- Current checked commit at this handoff update: `2c72419`
- Remote: `origin https://github.com/alifhunter/godot-game-1.git`
- Run `git status --short` before editing.
- At this handoff update, recent contact-network, company-generation, and thesis-system work has been pushed to `main`; top-down market implementation work is active and may be uncommitted if this file is being read mid-session.
- Do not revert user work or broad dirty files unless explicitly asked.
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
- [`docs/development/BANK_LOAN_SYSTEM_ENHANCEMENT.md`](docs/development/BANK_LOAN_SYSTEM_ENHANCEMENT.md)
  - Completed regular bank-loan plan: current-run bank lender discovery, separate `active_bank_loan` state, monthly payments, reserve gates, Life Finance selector/slider UI, grind tuning, targeted tests, and future hooks.
- [`docs/development/PERFORMANCE_RECOVERY_ENHANCEMENT.md`](docs/development/PERFORMANCE_RECOVERY_ENHANCEMENT.md)
  - Completed performance recovery plan: compact broker history, lighter advance-day portfolio refresh, deferred open-app refreshes, post-recap save scheduling, and final perf regression.
- [`docs/development/top_down_market/TOP_DOWN_MARKET_SYSTEM_ROADMAP.md`](docs/development/top_down_market/TOP_DOWN_MARKET_SYSTEM_ROADMAP.md)
  - Parent roadmap for the proposed top-down market system: company universe, commodities, price-engine exposure, living arcs, dossiers, financial statements, generated content, relationship graph, and research UI.
- [`docs/development/top_down_market/TOP_DOWN_RESEARCH_UI_ENHANCEMENT.md`](docs/development/top_down_market/TOP_DOWN_RESEARCH_UI_ENHANCEMENT.md)
  - Completed top-down research surface integration plan. Revision 1 intentionally hides the company Profile `Top-Down Links` card; research should flow through News, company profile reading, filings, Research Tray, and Thesis.
- [`docs/development/test_log/2026-06-26_performance_recovery_full_regression.md`](docs/development/test_log/2026-06-26_performance_recovery_full_regression.md)
  - Latest performance/full-year regression: targeted broker/save/perf tests passed, 70-company full-year scenario averaged `1,033.39ms/day`, quick smoke remains blocked by the known FTUE organic-chain assertion.
- [`docs/development/test_log/2026-06-22_full_year_player_scenario_catalog_default_rerun_2.md`](docs/development/test_log/2026-06-22_full_year_player_scenario_catalog_default_rerun_2.md)
  - Prior 225-trading-day full-year player scenario after catalog default enablement: opened game via Godot, bought `SDNX`, created a thesis, attached evidence, advanced a year, and recorded portfolio/market/event/attention/news/performance metrics.
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

### Performance / Save Regression

- Plan doc: `docs/development/PERFORMANCE_RECOVERY_ENHANCEMENT.md`
- Latest regression log: `docs/development/test_log/2026-06-26_performance_recovery_full_regression.md`
- Perf probe: `scripts/tests/NormalPlayPerfTest.gd`, `scenes/tests/NormalPlayPerfTest.tscn`
- Broker payload tests: `scripts/tests/BrokerHistoryCompactContractTest.gd`, `scripts/tests/BrokerHistoryMigrationTest.gd`, `scripts/tests/BrokerHistoryHotPathPerfTest.gd`, `scripts/tests/BrokerRangeHistoryTest.gd`
- Main runtime anchors: `autoloads/RunState.gd`, `autoloads/SaveManager.gd`, `scripts/ui/GameRoot.gd`, `autoloads/GameManager.gd`
- Current baseline: normal-play explicit save flush `12.91ms`; scheduled post-recap save `409.97ms`; 70-company full-year scenario `1,033.39ms/day`.
- Remaining risk: late-year 70-company normalization still spikes; keep `[perf][apply] normalize_companies` logs visible when investigating hitches.

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

### Top-Down Market Research Roadmap

- Parent roadmap: `docs/development/top_down_market/TOP_DOWN_MARKET_SYSTEM_ROADMAP.md`
- Company universe plan: `docs/development/top_down_market/COMPANY_UNIVERSE_CATALOG_ENHANCEMENT.md`
- Commodity macro plan: `docs/development/top_down_market/COMMODITY_MACRO_INDICATORS_ENHANCEMENT.md`
- Price exposure plan: `docs/development/top_down_market/PRICE_ENGINE_EXPOSURE_INTEGRATION_ENHANCEMENT.md`
- Living company arcs plan: `docs/development/top_down_market/LIVING_COMPANY_ARC_SYSTEM_ENHANCEMENT.md`
- Story dossier plan: `docs/development/top_down_market/COMPANY_STORY_DOSSIER_SYSTEM_ENHANCEMENT.md`
- Financial statement plan: `docs/development/top_down_market/FINANCIAL_STATEMENT_LAYER_ENHANCEMENT.md`
- Annual filing reading plan: `docs/development/top_down_market/ANNUAL_FILING_READING_EXPERIENCE_ENHANCEMENT.md`
- Generated content plan: `docs/development/top_down_market/CONTENT_SURFACE_GENERATION_ENHANCEMENT.md`
- Company relationship graph plan: `docs/development/top_down_market/COMPANY_RELATIONSHIP_GRAPH_ENHANCEMENT.md`
- Research UI plan: `docs/development/top_down_market/TOP_DOWN_RESEARCH_UI_ENHANCEMENT.md`
- Latest full-year/performance scenario log: `docs/development/test_log/2026-06-26_performance_recovery_full_regression.md`
- Starting code anchors: `systems/CompanyRosterGenerator.gd`, `systems/CompanyGenerator.gd`, `systems/CommodityMacroContract.gd`, `systems/PriceExposureResolver.gd`, `systems/MacroStateSystem.gd`, `systems/MarketSimulator.gd`, `systems/CompanyEventSystem.gd`, `systems/CompanyRoadmapSystem.gd`, `systems/CompanyStoryDossierSystem.gd`, `systems/FinancialStatementLayer.gd`, `systems/AnnualStatementBuilder.gd`, `systems/AnnualFilingDocument.gd`, `systems/CompanyRelationshipGraphSystem.gd`, `systems/NewsFeedSystem.gd`, `systems/TwooterFeedSystem.gd`, `systems/ContactNetworkSystem.gd`, `systems/ThesisManager.gd`, `autoloads/RunState.gd`, `autoloads/DataRepository.gd`

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
- Regular bank loans: `systems/BankLoanSystem.gd`, `autoloads/GameManager.gd`, `autoloads/RunState.gd`, `scripts/ui/widgets/LifeWidget.gd`
- Saved regular loan key: `life_finance.active_bank_loan`; keep separate from emergency `life_finance.active_loan`
- Bank-loan UI nodes: `LifeBankLoanPanel`, `LifeBankLoanLenderSelector`, `LifeBankLoanAmountSlider`, `LifeBankLoanButton`, `LifeActiveBankLoanPanel`
- Tests: `scripts/tests/LifeDevelopmentIntelTest.gd`, `scripts/tests/LifeLifestyleAssetTest.gd`, `scripts/tests/BankLoanOfferContractTest.gd`, `scripts/tests/BankLoanLifecycleTest.gd`, `scripts/tests/BankLoanLifeWidgetTest.gd`, `scripts/tests/BankLoanBalanceProbeTest.gd`, `scripts/tests/SmokeTest.gd`
- Plan doc: `docs/development/BANK_LOAN_SYSTEM_ENHANCEMENT.md`

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

### Top-Down Market System

- Top-down market work is active and spans multiple completed/partially completed enhancement docs under `docs/development/top_down_market/`.
- The parent tracking doc is
  [`docs/development/top_down_market/TOP_DOWN_MARKET_SYSTEM_ROADMAP.md`](docs/development/top_down_market/TOP_DOWN_MARKET_SYSTEM_ROADMAP.md).
- Implemented or actively wired areas include:
  - company universe catalog and roster bridge; fresh default runs now select from the 100-company `data/companies/company_universe_catalog.json`
  - commodity macro indicator catalog and state contract
  - price-engine exposure resolver/integration
  - living company arcs
  - company story dossier/disclosure packets
  - financial statement layer and annual filing reading experience
  - generated content surfaces
  - company relationship graph
  - top-down research surface integration
- Important UX decision: do not build a standalone top-down research app yet. The existing loop remains:
  - discover through News, Twooter, Network, Markets/company pages, and filings
  - capture useful items to Research Tray
  - create a Thesis and attach evidence
  - let the player draw the conclusion
- News is now planned/implemented as four free topic outlets:
  - Harian Investor
  - The Egonomist
  - IDK Channel
  - MarketSnitch
- Company Profile `Top-Down Links` card is intentionally hidden after Revision 1 in
  [`docs/development/top_down_market/TOP_DOWN_RESEARCH_UI_ENHANCEMENT.md`](docs/development/top_down_market/TOP_DOWN_RESEARCH_UI_ENHANCEMENT.md).
  - `scripts/ui/controllers/StockController.gd` keeps the dormant code behind `SHOW_PROFILE_TOP_DOWN_LINKS := false`.
  - Filing access should remain through the existing `View Consolidated Financial Statement` button, not the hidden card.
- Company universe catalog is the default roster path for `chill`, `normal`, and `grind`.
  - Use `use_company_universe_catalog = false` only when an explicit procedural-generator fallback/regression run is needed.
  - The annual filing reader now supplies a neutral segment selected-amounts table so catalog-backed companies keep `segment_row` filing evidence coverage even without a story-derived segment footprint.
- Dev-only company universe editing now lives in `tools/company_universe_editor`.
  - Run with `python3 tools/company_universe_editor/server.py`, then open `http://127.0.0.1:8775`.
  - It imports `data/companies/company_universe_catalog.json` until `company_universe_source.json` is saved.
- Latest 225-trading-day player/performance scenario passed and is logged at
  [`docs/development/test_log/2026-06-26_performance_recovery_full_regression.md`](docs/development/test_log/2026-06-26_performance_recovery_full_regression.md).
  - Bought `BORI`, created a thesis, attached `commodity`, `sector`, and `filing` evidence, opened lazy annual filing content, advanced 225 trading days, and generated the final thesis report.
  - Key outcome: final cash `1,890,338.5`, final equity `3,098,838.5`, held `BORI` return `-74.07%`, elapsed `232,511.74ms` (`1,033.39ms/day`).

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

### Full-Year Player Scenario

Run when you need a full-year player-flow regression that opens the game scene, buys a stock, creates a thesis, attaches evidence, advances 225 trading days, and reports portfolio/market/event/attention/news metrics.

```bash
/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/FullYearPlayerScenarioTest.tscn
```

Expected sentinel:

```text
FULL_YEAR_PLAYER_SCENARIO_OK
```

Latest log:

- [`docs/development/test_log/2026-06-26_performance_recovery_full_regression.md`](docs/development/test_log/2026-06-26_performance_recovery_full_regression.md)

## Known Verification Noise

- Steam API initialization warnings are expected in local headless runs when Steam is not running.
- RID/ObjectDB/resource cleanup warnings after a successful `_OK` sentinel are known headless teardown noise.
- Windows root-certificate warnings after successful smoke output are non-blocking.
- The full smoke has known pre-existing layout/coverage issues in some flows; quick smoke is the normal gate unless the task targets full UI coverage.
- Quick smoke currently has a known unrelated FTUE/content failure: `First-month smoke found more than 2 organic chains through day 25`.

## Current Recommended Next Steps

### 1. Checkpoint Hygiene

- Review `git status --short` before every task.
- Review and commit the active top-down market implementation/docs, full-year scenario test/log, and any completed enhancement probes as the next checkpoint if the diff is clean.
- Keep the company-generation, thesis, top-down market, and full-year scenario probes in the checkpoint; they are now the determinism/content/regression safety nets.
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
- Regular bank loans are implemented as a normal Life Finance product sourced from selected-run bank companies:
  - lender selector and amount slider in `LifeWidget.gd`
  - saved under `life_finance.active_bank_loan`
  - monthly payments apply on the same month-boundary rhythm as emergency loans
  - buy/upgrade reserve gates include emergency-plus-bank loan payment reserve
- Current bank-loan balancing target from the fixed grind probe: `BNRY`, default principal `Rp6.0m`, max principal `Rp11.0m`, max monthly payment about `Rp1.19m`, about `14%` of default monthly outflow.
- Next Life pass should tune costs, rent/upkeep, car/property status effects, finance warning copy, near-bankruptcy feel, and whether grind-mode roster selection should guarantee at least one bank lender.

### 6. Performance Follow-Up

- Use `[perf][advance]`, `[perf][apply]`, `[perf][ui]`, and `[perf][save]` logs.
- Performance recovery task 8 is complete:
  - normal-play explicit save flush is `12.91ms`
  - scheduled post-recap save is `409.97ms`
  - short-run save size is `3,464,461` bytes
  - 70-company full-year scenario is `232,511.74ms`, or `1,033.39ms/day`
- Remaining likely targets if hitches stay visible:
  - late-year `RunState.apply_day_result` / `normalize_companies` spikes
  - save payload construction in `RunState.to_save_dict()`
  - company story dossier and quarterly-report save payload size
  - `simulate_day` if daily market work becomes the visible bottleneck after normalization is reduced

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
