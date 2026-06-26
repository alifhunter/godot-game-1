# Top-Down Market System Roadmap - Parent Enhancement Index

This roadmap tracks the proposed top-down market research expansion: macro and commodity signals, richer sector/subsector context, persistent company stories, financial statement verification, and price-engine-backed outcomes.
**Status: in progress - parent roadmap created; Company Universe Catalog default enablement, Commodity Macro Indicators, Price Engine Exposure Integration, Living Company Arc System, Company Story Dossier System V1/R1, Financial Statement Layer Revision R1/R2/R3 complete, Annual Filing Reading Experience complete, Content Surface Generation complete, Company Relationship Graph complete, Top-Down Research Surface Integration complete, Annual Filing Sector Realism complete, and Annual Filing Story Discovery complete.** Individual feature plans live in this folder and should be updated as each task starts or completes.

**Product need recap:** The current player workflow is mostly bottom-up: pick a stock, inspect company data and news, then decide. That should remain valid, but the game also needs a top-down path where the player starts from macro/global/government/commodity stories, narrows into sectors and subsectors, compares companies, finds company-specific stories, and verifies the story through financials and filings. The main risk is content explosion, so the plan uses structured source-of-truth systems and generates news, Twooter, Network, thesis evidence, and filings from the same underlying facts.

## Roadmap principle

- The company dossier is the source of truth for story state.
- Macro, commodities, sector state, company relationships, and corporate actions are upstream causes.
- News, Twooter, Network, and filings are discovery surfaces.
- Financial statements and notes are verification surfaces.
- Thesis is the player's reasoning layer.
- The price engine must respond to the same facts the content surfaces expose.
- Companies should always remain alive. A completed arc should not make the company stagnant; it should return to an eligible pool for future macro, sector, company, or relationship-driven stories.

## Feature index

| # | Feature plan | Status | Dependency | Why it exists |
|---|---|---|---|---|
| 1 | [Company Universe Catalog](COMPANY_UNIVERSE_CATALOG_ENHANCEMENT.md) | Complete - Tasks 1-6 complete; default roster path enabled | First foundation | Creates a richer roster of selectable companies with sectors, subsectors, moats, exposures, and hooks. |
| 2 | [Commodity Macro Indicators](COMMODITY_MACRO_INDICATORS_ENHANCEMENT.md) | Complete - Tasks 1-5 complete | Can start after schema direction is stable | Adds commodity prices and regimes to macro so top-down stories can start from coal, CPO, oil, nickel, and similar drivers. |
| 3 | [Price Engine Exposure Integration](PRICE_ENGINE_EXPOSURE_INTEGRATION_ENHANCEMENT.md) | Complete - Tasks 1-5 complete | Needs company exposures and macro/commodity signals | Ensures company traits, commodity exposure, and sector stories actually affect price behavior. |
| 4 | [Living Company Arc System](LIVING_COMPANY_ARC_SYSTEM_ENHANCEMENT.md) | Complete - Tasks 1-5 complete | Needs company identity and basic story hooks | Keeps companies active after arcs resolve and allows new stories to emerge over time. |
| 5 | [Company Story Dossier System](COMPANY_STORY_DOSSIER_SYSTEM_ENHANCEMENT.md) | V1 complete; R1 complete | Needs living company state and exposure map | Centralizes story truth, timeline, financial effects, public/private clues, thesis evidence provenance, consistency tests, read-only previews, filing disclosure placement, subtle clue scattering, compact disclosure packets, save-compatible section lookup APIs, annual-note packet provenance, and the final Financial Statement R3 bridge fixture. |
| 6 | [Financial Statement Layer](FINANCIAL_STATEMENT_LAYER_ENHANCEMENT.md) | V1 complete; R1 complete; R2 complete; R3 complete | Needs dossier facts and company financial profile | Lets players verify stories through statements, MD&A, notes, use-of-proceeds, customers, capex, and results. |
| 7 | [Annual Filing Reading Experience](ANNUAL_FILING_READING_EXPERIENCE_ENHANCEMENT.md) | Complete - Tasks 1-8 complete | Needs Financial Statement R3 and Story Dossier R1 | Corrects the player-facing report from explicit evidence-card output into a lazy-generated annual filing reader with buried clues and natural filing prose. |
| 8 | [Content Surface Generation](CONTENT_SURFACE_GENERATION_ENHANCEMENT.md) | Complete - Tasks 1-6 complete | Needs dossier and statement facts | Prevents hand-authored content explosion by deriving news, Twooter, Network, and thesis clues from structured facts. |
| 9 | [Company Relationship Graph](COMPANY_RELATIONSHIP_GRAPH_ENHANCEMENT.md) | Complete - Tasks 1-6 complete | Needs company universe and story dossier | Enables partnerships, supplier/customer effects, competitor dynamics, acquisitions, mergers, and replacement slots. |
| 10 | [Top-Down Research Surface Integration](TOP_DOWN_RESEARCH_UI_ENHANCEMENT.md) | Complete - Tasks 1-6 complete | Needs existing News, Markets, filing, Research Tray, and Thesis flows | Improves the current research loop instead of building a redundant standalone top-down app. |
| 11 | [Annual Filing Sector Realism](ANNUAL_FILING_SECTOR_REALISM_ENHANCEMENT.md) | Complete - Tasks 1-7 complete | Needs annual filing reader, financial statement layer, company universe, and reference PDFs | Fixes incoherent/generic generated filings by adding sector-specific filing profiles, starting with bank vs industrial/trading annual statements. |
| 12 | [Annual Filing Story Discovery](ANNUAL_FILING_STORY_DISCOVERY_ENHANCEMENT.md) | Complete - Tasks 1-8 complete | Needs annual filing reader, sector realism, story dossier, relationship graph, and thesis capture | Turns the consolidated filing into a compact story-discovery surface where business arrangements, facilities, commitments, subsidies, leases, segments, and related parties carry investing clues without spoon-feeding conclusions. |

## Recommended implementation order

1. Company Universe Catalog.
2. Commodity Macro Indicators.
3. Price Engine Exposure Integration.
4. Living Company Arc System.
5. Company Story Dossier System.
6. Financial Statement Layer Revision R3.
7. Annual Filing Reading Experience.
8. Content Surface Generation.
9. Company Relationship Graph.
10. Top-Down Research Surface Integration.
11. Annual Filing Sector Realism.
12. Annual Filing Story Discovery.

This order keeps behavior grounded. The roster and exposures define what exists, commodities and macro define external pressure, the price engine proves the pressure matters, and only then should content and UI expand.

## Current code anchors

| Area | Current files to start from |
|---|---|
| Company generation and roster | `systems/CompanyRosterGenerator.gd`, `systems/CompanyGenerator.gd`, `systems/CompanyChartProfileBuilder.gd`, `systems/CompanyFinancialsBuilder.gd`, `systems/SeededPool.gd`, `data/companies/` |
| Macro state | `systems/MacroStateSystem.gd`, `autoloads/RunState.gd` |
| Price simulation | `systems/MarketSimulator.gd` |
| Company events and roadmaps | `systems/CompanyEventSystem.gd`, `systems/CompanyRoadmapSystem.gd`, `systems/CorporateActionSystem.gd`, `systems/CorporateActionApplications.gd`, `systems/SpecialEventSystem.gd` |
| News and social content | `systems/NewsFeedSystem.gd`, `systems/TwooterFeedSystem.gd`, `systems/TwooterInteractionSystem.gd`, `data/news/news_feed_data.json`, `data/social/twooter_feed_data.json` |
| Contact network | `systems/ContactNetworkSystem.gd`, `data/network/contact_network_data.json` |
| Thesis capture and reports | `systems/ThesisManager.gd`, `systems/ThesisReportSystem.gd`, `systems/ThesisVocabulary.gd`, `scripts/ui/widgets/ThesisBoardWidget.gd`, `data/thesis/thesis_content.json` |
| Filings and financial payloads | `autoloads/RunState.gd`, `systems/CompanyFinancialsBuilder.gd` |
| Annual filing reader | `systems/AnnualFilingDocument.gd`, `systems/AnnualStatementBuilder.gd`, `systems/FinancialStatementLayer.gd`, `scripts/ui/controllers/StockController.gd` |
| Existing long-run audits | `scripts/tests/MarketYearAudit.gd`, `scenes/tests/SmokeTest.tscn` |

## Design rules

- Company universe catalog is now the default run roster path. Keep the procedural generator available through explicit `use_company_universe_catalog = false` fallback/regression configs.
- Avoid hand-writing every possible news post, Twooter post, Network clue, and filing note. Store structured story primitives and generate surfaces from them.
- Keep deterministic seed behavior. Every selected company, story arc, commodity regime, generated clue, and price impact should be reproducible.
- Keep save compatibility. New state needs normalizer defaults and should tolerate old saves.
- Keep price effects modest and testable before increasing drama.
- Prefer batched catalog expansion. The current catalog has 100 companies; future growth should keep validation and fixed-seed fingerprints updated.
- Use commodity prices as macro indicators first, not tradable instruments.
- Keep companies alive after story resolution. Arc completion should update state, not retire the company from the simulation.
- Preserve bottom-up play. The top-down path adds another research route; it should not make direct company picking obsolete.

## Cross-feature status

| Track | Status | Notes |
|---|---|---|
| Parent roadmap | Created | This file is the status index. |
| Company roster foundation | Complete | Tasks 1-6 and follow-up expansions added a 100-company catalog seed, DataRepository loader/validation, focused validation test, catalog roster bridge, fixed-seed selection fingerprint, and default difficulty catalog enablement. Procedural generation remains available as an explicit fallback. |
| Macro commodities | Complete | Tasks 1-5 added `data/macro/commodity_indicator_catalog.json`, yearly commodity macro state generation, neutral save/default normalization, a shared commodity evidence contract, thesis evidence integration, and deterministic fingerprint/probe coverage. No price behavior changes yet. |
| Price integration | Complete | Tasks 1-5 inventoried current price axes, added the pure bounded resolver, wired resolver output into daily price/volume simulation, added targeted relative-impact probes, and logged 120/225-day fixed-seed audits. |
| Living arcs | Complete | Tasks 1-5 added saved lifecycle state, normalization, active/resolved/cooldown transitions, event/roadmap availability gates, and a 120-day fixed-seed long-run audit. |
| Story dossier | V1 complete; R1 complete | Tasks 1-6 defined the schema, added deterministic fixed-seed generation, added saved runtime state/normalizers, bridged dossier facts into thesis evidence, added consistency/fingerprint coverage, and added read-only preview rows. Revision R1.1 added deterministic filing disclosure placement rows, section definitions, traceability arrays, save normalization, and fixed-seed placement hash `1533142911`. Revision R1.2 added clue subtlety and scattering metadata with fixed-seed placement hash `1192489532`. Revision R1.3 added compact disclosure packets with fixed-seed packet hash `2005222199`. Revision R1.4 added legacy/malformed save repair, traceability repair, company/story/section lookup APIs, and fixed-seed persistence hash `2080268323`. Revision R1.5 bridged disclosure packet provenance into annual statement notes and thesis capture, updating the full traceability hash to `1974201801`. Revision R1.6 added the final Financial Statement R3 bridge fixture with fixed-seed hash `623183840`. Full live content/price consumers remain future feature work. |
| Financial statements | V1 complete; R1 complete; R2 complete; R3 complete; Annual Filing Reading Experience complete | Tasks 1-6 defined the v1 quarterly statement layer. Revision R1.1-R1.2 added the annual consolidated statement contract and deterministic FY2019 source with a 14-note annual report outline. Revision R1.3 added the A4-style annual consolidated report shell. Revision R1.4 renamed the Financials entry to `View Consolidated Financial Statement` and smoke-locks the FY2019 annual report route. Revision R1.5 generates annual note rows and preserves annual/consolidated thesis capture metadata. Revision R1.6 locks annual/A4 layout and content smoke coverage, including all 14 generated note rows. Revision R2.1 adds the post-start source-ready enrichment pass after live Story Dossier, Living Company Arc, corporate action, event, and roadmap state is available. Revision R2.2 maps Story Dossier and Living Company Arc IDs into annual note facts. Revision R2.3 maps corporate-action, event-history, and roadmap milestone IDs into annual note facts. Revision R2.4 preserves enriched annual-note provenance through Research Tray, thesis evidence, direct evidence add, and save/load. Revision R2.5 locks deterministic full traceability coverage; the current hash is `1974201801` after Story Dossier R1.5 packet provenance was added. Revision R3.1 added the document-reading contract, annual report section map, and table of contents. Revision R3.2 added the accounting row model, 22 continuity checks, continuity hash `1613787417`, and annual builder hash `867613961`. Revision R3.3 added filing-style note bodies, cross-note references, note-body hash `1102538137`, and document contract hash `2037575392`. Revision R3.4 added the document-reader UI flow with TOC navigation, anchored sections, filing-note paragraphs/tables, and paragraph-level evidence capture. Revision R3.5 consumes Story Dossier disclosure packets as subtlety-specific note paragraphs and locks note-body hash `36249412`. Revision R3.6 added final annual report fidelity/capture coverage, cross-note reference evidence preservation, reader cross-reference smoke coverage, and fidelity hash `906899410`. Annual Filing Reading Experience Task 1 added the lazy annual filing request/cache contract and wired the existing button path to an in-memory generated-document cache. Task 2 added the 20-section annual filing anatomy, deterministic TOC/source map, schema hash `700723473`, and anatomy hash `230195522`. Task 3 added accounting-footprint packets, footprint hash `158179705`, and footprint packet hash `1286418835`. Task 4 added formal prose/noise packets, prose hash `207705355`, and prose library hash `1676592393`. Task 5 added lazy visible filing generation, visible filing hash `781569065`, visible-generation fixture hash `1986473927`, and current lazy contract hash `1982276232`. Task 6 added the A4 reader metadata, responsive margins, vertical-only page scrolling, generated section chunking, and smoke coverage for bounded chunk rendering. Task 7 added neutral annual filing excerpt capture metadata, compact-table-row capture, filing excerpt dedupe, Research Tray/thesis/save-load preservation, and quick-smoke coverage for statement rows, note paragraphs, note table rows, cross-references, segment rows, auditor key matters, and subsequent events. Task 8 added the fixed-seed regression guard, lazy/cache/performance bounds, source-state cache invalidation guard, generated document size guard, and smoke rendered-control-count guard. |
| Annual filing realism | Complete - Tasks 1-7 complete | New follow-up plan created after user review found the generated consolidated statement still reads as incoherent/generic generated prose. Task 1 audited fixed-seed bank and industrial samples, named the failure taxonomy, and set measurable realism gates. Task 2 added the sector filing profile contract, deterministic profile selection, and profile id/version cache invalidation. Task 3 added bank-specific visible note anatomy and deterministic bank compact-table models. Task 4 replaced generic footprint prose and cross-reference wording with section-specific bank/default prose roles, added bank annual-filing vocabulary, and added forbidden generic phrase guards. Task 5 added profile table/prose balance targets, deterministic table-first display blocks, UI rendering through display blocks, and fixed-seed guards for balance/order/source-backed table rows. Task 6 added the focused Stock app bank-reader UI smoke, preserved lazy/cache/A4/TOC/capture/thesis/save-load behavior under the bank profile, and fixed the UI request path to fall back to the effective company definition for profile metadata. Task 7 added fixed-seed bank-vs-industrial realism regression plus the full-year player-flow target through `BORI` and the bank annual filing. |
| Annual filing story discovery | Complete - Tasks 1-8 complete | Task 1 added the pure story-note fact contract, deterministic schema hash `1214903292`, 11 story types, 11 story-bearing note containers, profile allowlists for `bank`/`industrial_trading`/`default_general`, validation helpers, and fixed-hash contract test `1287721463`. Task 2 added deterministic story fact packet generation from dossier, relationship graph, annual statement, living arc, corporate action, roadmap, and bounded company-universe fallback sources with fixed packet hash `1089345055`. Tasks 3-4 added filing-style story-note prose and deterministic cross-note clue placement with story-note prose hash `194763165`. Task 5 rebalanced the visible reader around compact statements plus story-bearing notes, English-only visible labels, no generic filler, A4 cutoff guards, bank reader smoke coverage, and fixed bank-reader hash `2022638696`. Task 6 hardened annual filing capture metadata, hidden `story_note_fact_id` preservation, Research Tray/thesis/save-load normalization, and story-note cache invalidation. Task 7 added reference-inspired realism shape assertions for agreements, facilities, commitments, segments, counterparties, dates, amounts, and recommendation-language guards. Task 8 passed the full-year player scenario with 225 trading days, bank filing profile `bank`, 6 story-note facts, 5 story-note prose rows, 3 filing captures, final thesis report success, and log `docs/development/test_log/2026-06-24_annual_filing_sector_realism_full_year.md`. |
| Content generation | Complete - Tasks 1-6 complete | Surface reveal rules define generated-item metadata, public/private boundaries, reliability, delay, and detail levels. Task 2 adds generated public news previews for company, sector, and macro surfaces from public dossier clues while preserving authored news articles. Task 3 adds generated public Twooter previews for company, sector, and macro chatter while preserving authored posts and public/private leak boundaries. Task 4 maps private dossier clues into gated Network tip results and journal rows. Task 5 preserves generated News, Twooter, Network, and filing provenance through Research Tray, thesis attachment, report generation, direct evidence add, and save/load. Task 6 locks consistency, privacy, reachability, and thesis-capture paths with a fixed-seed guard. |
| Relationship graph | Complete - Tasks 1-6 complete | Relationship graph contract defines edge direction, edge types, normalized fields, hook-to-edge resolution rules, visibility/content rules, density defaults, and M&A deferral boundaries. Task 2 added deterministic selected-roster graph state, RunState save/load/accessors, and fixed-seed hash `2129898825`. Task 3 added low-frequency relationship events with two-company bounded price effects, edge cooldown persistence, and event-history recording. Task 4 added relationship-specific News, Twooter, gated Network reads, and thesis capture provenance. Task 5 completed the cash-acquisition, merger deferral, archival, replacement-slot, and save/portfolio design contract. Task 6 added broad graph/event regression coverage and fixture-only M&A candidate guards. |
| Top-down research surfaces | Complete - Tasks 1-6 complete | Do not build a standalone top-down app yet. Task 1 inventoried existing News, Markets/company detail, filing, Research Tray, and Thesis paths. Task 2 converted News into four free topic/coverage lanes with public-depth metadata and no paid outlet access. Task 3 added topic/coverage filters, archive metadata preservation, and level-1 public copy leak guards. Task 4 added compact Markets/company Profile links for commodities, peers, stories, counterparties, and filings. Task 5 added normalized provenance groups/source paths across Research Tray capture, thesis attachment, direct evidence add, save/load, snapshot grouping, and tray card display. Task 6 added a focused fixed-seed integration smoke covering News filters, Profile top-down payloads, filing access/capture, Research Tray, Thesis, report generation, and save/load. |

## Open design decisions

| Decision | Recommended default |
|---|---|
| Generated companies vs catalog companies | Keep generated behavior available; add catalog-backed universe selection in parallel first. |
| Catalog size | Start with 40-60 strong companies, then expand after schema and fingerprints stabilize. |
| Commodity handling | Add macro commodity indices first; do not make commodities tradable in the first pass. |
| Story storage | Store stable dossier seeds and current story state; derive display text deterministically. |
| Financial statement fidelity | Aim for plausible investing gameplay, not accounting-grade completeness. |
| Next revision to start | No remaining Annual Filing Story Discovery task. Pick the next feature/revision from the active project priorities before starting new top-down work. |
| Company relationships | Start with supplier/customer/partner/competitor edges; defer full M&A until base graph is proven. |
| UI timing | Build UI after data and price integration are testable. |

## Verification baseline

Use these gates across feature docs unless a task says otherwise:

- `git diff --check`
- `/Users/user/.local/bin/godot --headless -e --quit`
- `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io`
- If editing JSON: `python3 -m json.tool [path/to/file.json] > /dev/null`
- If changing price behavior: run a targeted deterministic probe plus `scripts/tests/MarketYearAudit.gd`.
- If changing UI: run a targeted smoke with screenshots or layout assertions as appropriate.

## Progress log

### 2026-06-14 - Roadmap created

- Created the parent top-down market roadmap.
- Split the brainstorm into individual feature plans so each can be implemented and tracked independently.
- No code, runtime data, or behavior changes were made by this planning step.

### 2026-06-24 - Annual Filing Sector Realism plan added

- Added [Annual Filing Sector Realism](ANNUAL_FILING_SECTOR_REALISM_ENHANCEMENT.md) after review of the current generated consolidated statement and the Bank Sinarmas FY2025 reference PDF.
- Product correction:
  - current filing plumbing is useful, but visible output can still become generic, repetitive, and incoherent
  - next work should add sector-specific filing profiles and table-first note generation instead of more generic explanatory prose
  - first realism split should be `bank` vs `industrial_trading`
- No code, runtime data, or behavior changes were made by this planning step.

### 2026-06-24 - Annual Filing Sector Realism Task 1 complete

- Updated [Annual Filing Sector Realism](ANNUAL_FILING_SECTOR_REALISM_ENHANCEMENT.md) with the fixed-seed audit results.
- Audited `bank_orang_indonesia` / `BORI` and `alat_berat_mandiri` / `ABMD`.
- Key finding:
  - the bank sample still renders generic industrial note anatomy, has no bank-specific visible loan/deposit/credit-risk/CAR surfaces, and contains repeated generic explanatory prose
- Task 2 should start with the sector filing profile contract and deterministic profile selection.

### 2026-06-24 - Annual Filing Sector Realism Task 2 complete

- Added the annual filing profile contract and deterministic profile selector.
- Initial profiles:
  - `default_general`
  - `industrial_trading`
  - `bank`
- Profile id/version are now part of the annual filing contract, cache key parts, invalidation fields, document hash payload, and visible generation diagnostics.
- `StockController.gd` now passes sector/subsector/business summary/moat/story context into annual filing requests.
- Added `AnnualFilingProfileContractTest`.
- Task 3 should now build the bank-specific anatomy and table models using this profile contract.

### 2026-06-24 - Annual Filing Sector Realism Task 3 complete

- Added bank-specific annual filing note anatomy for the `bank` profile.
- The bank profile now replaces generic industrial/trading note sections with bank sections for cash/reserves, placements, securities, loans/financing, impairment allowance, deposits, syirkah funds, interest/sharia income, related parties, capital adequacy, credit risk, liquidity risk, and regulatory compliance.
- Added deterministic bank compact-table models with existing statement values as anchors and bounded fallback splits where the current financial source is not bank-native.
- Added `AnnualFilingBankAnatomyTableTest`:
  - `bank_orang_indonesia` resolves `bank`
  - generated bank filing has 23 sections, 18 compact tables, and 56 compact table rows
  - required bank sections and visible bank terms are present
  - industrial note sections and table captions such as inventory/PPE/gross-profit/cost-of-revenue are excluded from bank note tables
- Existing generic/default visible filing hash remained unchanged at `1961685698`.
- Task 4 later replaced the remaining generic prose with profile-specific prose/noise libraries; Task 5 is now the next sector-realism step.

### 2026-06-24 - Annual Filing Sector Realism Task 4 complete

- Replaced generic annual filing footprint prose with section-specific prose and cross-reference wording.
- Added bank-specific prose roles and `bank_annual_filing` vocabulary so bank filings use bank asset, loan, funding, capital, credit-risk, liquidity-risk, and regulatory language.
- Added forbidden generic phrase guards for prose packets, visible filings, regression guard output, and bank filing output.
- Updated prose/cache baselines:
  - prose library hash `1485407092`, prose hash `367944784`
  - visible-generation hash `1490076547`, visible filing hash `363169314`
  - bank anatomy/table hash `1006124506`, bank visible filing hash `143331570`
  - regression guard hash `495065561`
  - profile contract hash `1921234662`
  - lazy contract hash `160244644`
- Verified the annual filing prose, visible generation, bank anatomy/table, regression guard, profile contract, lazy contract, footprint packet, fidelity capture, anatomy schema, and top-down research surface integration tests.
- Task 5 later tuned table/prose balance and generated section assembly order.

### 2026-06-24 - Annual Filing Sector Realism Task 5 complete

- Rebalanced visible annual filing generation around a deterministic table-first display-block contract.
- Added profile-specific table/prose balance targets and visible filing metadata:
  - `visible_filing_table_row_count`
  - `visible_filing_display_block_count`
  - `visible_filing_assembly_priority`
  - `visible_filing_profile_balance`
- `StockController.gd` now renders generated filing content through display blocks, so note tables render before cross-references and limited prose.
- Updated fixed-seed annual filing baselines:
  - visible-generation hash `1803230173`, visible filing hash `169939267`
  - bank anatomy/table hash `1779696113`, bank visible filing hash `601383779`
  - regression guard hash `1878982941`
  - profile contract hash `714906742`
  - lazy contract hash `1985960845`
- Verified annual filing visible generation, bank anatomy/table, regression guard, lazy contract, profile contract, prose library, footprint packet, anatomy schema, annual report fidelity capture, and top-down research surface integration.
- Task 6 should now focus on preserving capture, thesis, cache, and UI behavior under sector profiles.

### 2026-06-24 - Annual Filing Sector Realism Task 6 complete

- Added `AnnualFilingBankReaderUiSmokeTest` to lock the real Stock app annual filing reader under the bank filing profile.
- The smoke covers lazy click-only generation, first-open cache miss/build, second-open cache hit, cache key parts/invalidation fields, A4 page metadata, vertical-only page scrolling, bank-only TOC navigation, bounded rendered bank tables, annual filing capture payloads, Research Tray capture, thesis attach, direct thesis evidence add, save/load, and non-bank fallback rendering.
- Fixed the UI request path in `StockController.gd` so annual filing profile selection falls back to `RunState.get_effective_company_definition(...)` when the current trade snapshot does not include enough sector/subsector/business metadata.
- New fixed-seed UI smoke baseline: `ANNUAL_FILING_BANK_READER_UI_SMOKE_OK {"hash":"994645212","profile":"bank","section_count":23,"table_count":18,"table_row_count":56,"capture_count":4,"visible_filing_hash":"601383779"}`.
- Task 7 should now add the final realism/determinism/full-player-flow regression layer.

### 2026-06-24 - Annual Filing Sector Realism Task 7 complete

- Added `AnnualFilingSectorRealismRegressionTest` and scene to lock fixed-seed bank vs industrial/trading filing realism.
- Regression baseline: `ANNUAL_FILING_SECTOR_REALISM_REGRESSION_OK {"hash":"398621424","bank_table_count":18,"bank_table_row_count":56,"bank_visible_hash":"601383779","industrial_table_count":3,"industrial_table_row_count":3,"industrial_visible_hash":"2116208241"}`.
- Updated `FullYearPlayerScenarioTest` to use the catalog roster and `bank_orang_indonesia` as the player-flow target.
- Full-year player scenario now launches the game scene, buys `BORI`, opens the bank annual filing, captures `statement_row`, `note_table_row`, and `note_paragraph` filing evidence, attaches evidence to a thesis, generates a final report, and advances 225 trading days.
- Full-year output was logged to `docs/development/test_log/2026-06-24_annual_filing_sector_realism_full_year.md`.
- Verification also passed `AnnualFilingRegressionGuardTest`, quick smoke, editor boot, and `git diff --check`.
- Scenario highlights:
  - `225/225` trading days completed
  - final equity `2755500.75`
  - BORI held return `-74.75%`
  - best stock `FBKP` return `728.15%`
  - worst stock `SARI` return `-96.77%`
  - average stock return `-30.44%`
  - gorengan started/dump peak/success peak `27/8/0`
  - thesis evidence count `5`
  - annual filing capture count `3`
- Performance note: full-year catalog scenario elapsed `613626.46ms`, so keep it as an explicit scenario test rather than a quick-smoke default.

### 2026-06-24 - Annual Filing Story Discovery plan added

- Added [Annual Filing Story Discovery](ANNUAL_FILING_STORY_DISCOVERY_ENHANCEMENT.md) after the user clarified the desired filing direction with agreement, facility, subsidy, lease, subsidiary, and project-note screenshots.
- Product correction:
  - the consolidated filing should not become a deeper accounting simulator
  - compact statements should anchor the numbers, while business-story notes carry the investing clues
  - the generator should produce deterministic story fact packets first, then render those facts into filing-style notes
  - clues should be split across notes when useful, so players infer from context instead of reading evidence-card explanations
- No code, runtime data, or behavior changes were made by this planning step.

### 2026-06-14 - Company Universe Catalog Task 1 complete

- Added `data/companies/company_universe_catalog.json` with 50 seed companies across existing sector ids.
- Runtime behavior stayed unchanged; this is a data/schema foundation for later loader and roster-selection tasks.
- Verification:
  - `python3 -m json.tool data/companies/company_universe_catalog.json > /dev/null`
  - Fixed count/uniqueness probe: `companies=50`, `ids=50`, `tickers=50`

### 2026-06-14 - Company Universe Catalog Task 2 complete

- Added DataRepository loading, validation result, safe-copy accessors, and by-id lookup for the company universe catalog.
- The catalog loader is optional for now, so missing data warns instead of hard-failing runtime reload before the roster-selection task depends on it.
- Added `CompanyUniverseCatalogValidationTest` as the focused catalog gate.
- Runtime behavior stayed unchanged; roster generation still uses the existing generator/archetype path.
- Verification:
  - `python3 -m json.tool data/companies/company_universe_catalog.json > /dev/null`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyUniverseCatalogValidationTest.tscn` -> `COMPANY_UNIVERSE_CATALOG_VALIDATION_OK {"companies":70,"sample_id":"sawit_bumi_raya","schema_version":1,"sectors":11}`
  - `/Users/user/.local/bin/godot --headless -e --quit`
  - `git diff --check`

### 2026-06-14 - Company Universe Catalog Task 3 complete

- Added opt-in catalog roster generation through `CompanyRosterGenerator.generate_catalog_roster(...)`.
- `GameManager.build_company_roster(...)` uses the catalog only when `difficulty_config["use_company_universe_catalog"] == true`; default runs still use the procedural generator.
- Catalog-generated definitions carry current company-definition fields plus catalog metadata for later top-down systems.
- Added `CompanyUniverseRosterBridgeTest` to prove default procedural behavior is unchanged and catalog definitions can initialize/hydrate through `RunState`.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyUniverseRosterBridgeTest.tscn` -> `COMPANY_UNIVERSE_ROSTER_BRIDGE_OK {"catalog_count":30,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyGenerationFingerprintTest.tscn` -> `COMPANY_GENERATION_FINGERPRINT_OK ... "hash":"1225696160" ...`
  - `/Users/user/.local/bin/godot --headless -e --quit`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11`
  - `git diff --check`

### 2026-06-14 - Company Universe Catalog Task 4 complete

- Added a fixed-seed catalog selection fingerprint test for `run_seed = 20260614` and a 30-company roster.
- The original 50-company deterministic baseline was superseded by the Task 5 catalog expansion.
- The fingerprint covers selected ids, tickers, sector distribution, source, tags, hooks, and macro/commodity exposure summaries.
- Display names are excluded from the fingerprint so company name polish does not invalidate deterministic selection coverage.
- Runtime default behavior stayed unchanged; catalog selection remains opt-in.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyUniverseSelectionFingerprintTest.tscn` -> current baseline is maintained by Task 5
  - `/Users/user/.local/bin/godot --headless -e --quit`
  - `git diff --check`

### 2026-06-14 - Company Universe Catalog Task 5 complete

- Expanded the catalog from 50 to 60 companies while keeping default runtime behavior unchanged.
- Added coverage for tourism food service, poultry integration, geothermal power, copper processing, satellite broadband, rail freight, biotechnology, digital brokerage, hospitality property, and data center estate stories.
- Current catalog sector counts are `consumer=6`, `noncyclical=6`, `energy=6`, `basicindustry=6`, `industrial=5`, `tech=6`, `infra=5`, `transport=5`, `health=5`, `finance=5`, and `property=5`.
- The 60-company deterministic catalog selection baseline was superseded by the follow-up expansion below.
- Verification:
  - `python3 -m json.tool data/companies/company_universe_catalog.json > /dev/null`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyUniverseCatalogValidationTest.tscn` -> `COMPANY_UNIVERSE_CATALOG_VALIDATION_OK {"companies":70,"sample_id":"sawit_bumi_raya","schema_version":1,"sectors":11}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyUniverseRosterBridgeTest.tscn` -> `COMPANY_UNIVERSE_ROSTER_BRIDGE_OK {"catalog_count":30,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyUniverseSelectionFingerprintTest.tscn` -> current baseline is maintained by the follow-up expansion below

### 2026-06-14 - Commodity Macro Indicators Task 1 complete

- Added `data/macro/commodity_indicator_catalog.json` as the commodity indicator source-of-truth seed.
- The catalog defines stable ids, display labels, categories, normalized bounds, volatility defaults, year-to-date movement bounds, global direction/regime thresholds, macro drivers, related sectors, and story tags.
- Added 25 commodity definitions covering every current company `commodity_exposures` key. `gold`, `rare_earth`, and `silica` are now used by the expanded company catalog.
- Runtime behavior stayed unchanged. Commodity indicators are not consumed by `MacroStateSystem`, `RunState`, or `MarketSimulator` until later tasks.
- Verification:
  - `python3 -m json.tool data/macro/commodity_indicator_catalog.json > /tmp/commodity_indicator_catalog.json.check`
  - Catalog coverage probe: `commodityCount=25`, `exposureKeyCount=25`, `missing=[]`, `duplicates=[]`, `extraDefinitions=[]`
  - `git diff --check`

### 2026-06-14 - Commodity Macro Indicators Task 2 complete

- Added commodity catalog loading/accessors in `DataRepository`.
- Extended `MacroStateSystem.build_year_state(...)` to generate yearly commodity indicators from the catalog.
- New macro state keys are `commodity_indicators`, `commodity_regime_counts`, `commodity_leaders`, and `commodity_laggards`.
- Commodity generation uses per-commodity stable RNG streams and bounded catalog model values.
- `RunState` and `GameManager.build_company_roster(...)` pass the commodity catalog into macro generation.
- Price behavior stayed unchanged; `MarketSimulator` does not consume commodity indicators yet.
- Added `CommodityMacroStateProbeTest` as the focused fixed-seed probe.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CommodityMacroStateProbeTest.tscn` -> `COMMODITY_MACRO_STATE_PROBE_OK {"commodity_count":25,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyGenerationFingerprintTest.tscn` -> `COMPANY_GENERATION_FINGERPRINT_OK ... "hash":"1225696160" ...`
  - `/Users/user/.local/bin/godot --headless -e --quit`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11 days=3 ...`

### 2026-06-14 - Commodity Macro Indicators Task 3 complete

- Added RunState yearly macro-state normalization for load, save, existing-year ensure, current-year reads, and history reads.
- Old saves with missing commodity macro fields now backfill neutral catalog-backed commodity indicators.
- Partial commodity states preserve existing rows and rebuild missing ids, regime counts, leaders, and laggards.
- Price behavior stayed unchanged; commodity indicators are still data-only until price exposure integration.
- Added `CommodityMacroSaveDefaultsTest`.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CommodityMacroSaveDefaultsTest.tscn` -> `COMMODITY_MACRO_SAVE_DEFAULTS_OK {"commodity_count":25,...}`

### 2026-06-14 - Commodity Macro Indicators Task 4 complete

- Added `CommodityMacroContract` as the shared commodity summary and evidence contract helper.
- Added GameManager accessors for commodity summaries and commodity thesis evidence options.
- Thesis sector/macro evidence now includes `commodity_macro` rows when a company has direct exposure or sector relevance.
- Commodity fields are preserved through Research Tray capture, direct thesis evidence insertion, thesis attachment, save, and reload normalization.
- `ThesisManager.add_thesis_evidence(...)` now returns the inserted compact evidence row for parity with research attachment.
- Price behavior stayed unchanged; this task only exposes a stable evidence/content contract.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CommodityMacroEvidenceContractTest.tscn` -> `COMMODITY_MACRO_EVIDENCE_CONTRACT_OK {"commodity_id":"coal","company_id":"surya_power_nusantara","evidence_rows":4,"impact":"negative","sector_id":"energy","summary_rows":5}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CommodityMacroStateProbeTest.tscn` -> `COMMODITY_MACRO_STATE_PROBE_OK {"commodity_count":25,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CommodityMacroSaveDefaultsTest.tscn` -> `COMMODITY_MACRO_SAVE_DEFAULTS_OK {"commodity_count":25,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/ThesisResearchTrayTest.tscn` -> `THESIS_RESEARCH_TRAY_OK`
  - `/Users/user/.local/bin/godot --headless -e --quit`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11 days=3 ...`

### 2026-06-14 - Commodity Macro Indicators Task 5 complete

- Added `CommodityMacroFingerprintTest` as the fixed-seed commodity macro regression baseline.
- The fingerprint covers years `2020-2024`, all `25` commodity indicators, regimes, directions, normalized movement values, levels, driver scores, volatility, related sectors, and story tags.
- Locked baseline hash: `773085587`.
- First-year leaders are `crude_oil`, `coal`, and `fuel`; first-year laggards are `corn`, `silica`, and `gold`.
- Last-year leaders are `coal`, `fertilizer`, and `soybean`; last-year laggards are `rare_earth`, `iron_ore`, and `nickel`.
- Commodity Macro Indicators is now complete as a data/evidence foundation. Price behavior remains unchanged until Price Engine Exposure Integration.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CommodityMacroFingerprintTest.tscn` -> `COMMODITY_MACRO_FINGERPRINT_OK {"hash":"773085587","year_count":5,"commodity_count":25,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CommodityMacroStateProbeTest.tscn` -> `COMMODITY_MACRO_STATE_PROBE_OK {"commodity_count":25,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CommodityMacroSaveDefaultsTest.tscn` -> `COMMODITY_MACRO_SAVE_DEFAULTS_OK {"commodity_count":25,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CommodityMacroEvidenceContractTest.tscn` -> `COMMODITY_MACRO_EVIDENCE_CONTRACT_OK {"commodity_id":"coal","company_id":"surya_power_nusantara",...}`
  - `/Users/user/.local/bin/godot --headless -e --quit`

### 2026-06-14 - Price Engine Exposure Integration Task 1 complete

- Inventoried the current price engine axes in `systems/MarketSimulator.gd`.
- Confirmed the engine already prices broad market sentiment, sector sentiment, event bias, broker pressure, company quality/growth/risk, volume/tape pressure, technical pressure, gorengan campaign pressure, player depth pressure, momentum, and noise.
- Chosen integration point for Task 2/3: a pure company-specific exposure resolver whose output is attached to per-company volume/price context before `_calculate_daily_change`.
- Avoided market and sector sentiment as first-pass integration points to prevent double-counting macro sector bias and commodity-derived sector pressure.
- Neutral defaults are zero drift, `1.0` volatility/volume multipliers, empty exposure rows, and `0.0` confidence for companies without exposure data.
- No runtime behavior changed.
- Verification:
  - `git diff --check`

### 2026-06-14 - Price Engine Exposure Integration Task 2 complete

- Added `systems/PriceExposureResolver.gd` as a pure deterministic exposure-impact resolver.
- Resolver accepts company commodity/macro exposures, price traits, moat tags, macro/commodity state, and optional future story-state pressure.
- Resolver returns bounded drift, volatility, volume, confidence, score, modifier, and explainability fields.
- Companies without exposure/story inputs remain explicitly neutral.
- Runtime price behavior is still unchanged; `MarketSimulator` does not consume resolver output until Task 3.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/PriceExposureResolverContractTest.tscn` -> `PRICE_EXPOSURE_RESOLVER_CONTRACT_OK {"leader_id":"crude_oil","laggard_id":"corn",...}`
  - `/Users/user/.local/bin/godot --headless --path . --editor --quit`

### 2026-06-14 - Price Engine Exposure Integration Task 3 complete

- Wired `PriceExposureResolver` into `systems/MarketSimulator.gd`.
- Exposure context now flows into `volume_context`, runtime company snapshots, daily drift, base volatility/noise, and volume/activity multipliers.
- Procedural/default companies without exposure data still resolve neutral exposure context.
- Close guards and special price controls remain downstream of exposure effects.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/PriceExposureSimulationIntegrationTest.tscn` -> `PRICE_EXPOSURE_SIMULATION_INTEGRATION_OK {"catalog":{"company_id":"surya_power_nusantara",...},"neutral":{"checked_companies":18},...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/PriceExposureResolverContractTest.tscn` -> `PRICE_EXPOSURE_RESOLVER_CONTRACT_OK ...`
  - `/Users/user/.local/bin/godot --headless --path . --editor --quit`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11 days=3 summary=Institution-led accumulation gave GLLA the cleanest tape today.`

### 2026-06-14 - Price Engine Exposure Integration Task 4 complete

- Added `PriceExposureImpactProbeTest` for controlled relative-impact scenarios.
- Probe covers coal rally, CPO rally, rate hike, and oil/fuel spike cases.
- Each case proves exposed beneficiaries outperform neutral names and exposed laggards underperform neutral names through the real resolver and `MarketSimulator` calculation hooks.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/PriceExposureImpactProbeTest.tscn` -> `PRICE_EXPOSURE_IMPACT_PROBE_OK {"scenario_count":4,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/PriceExposureSimulationIntegrationTest.tscn` -> `PRICE_EXPOSURE_SIMULATION_INTEGRATION_OK ...`
  - `/Users/user/.local/bin/godot --headless --path . --editor --quit`

### 2026-06-14 - Price Engine Exposure Integration Task 5 complete

- Extended `MarketYearAudit` with catalog-run flags, compact reporting, portfolio output, runtime timing, and price exposure stock-day telemetry.
- Ran 120-day and 225-day fixed-seed catalog-backed audits with seed `20260614`, normal difficulty, and `50` catalog companies.
- Saved the audit history in `docs/development/test_log/2026-06-14_price_exposure_long_run_audit.md`.
- 120-day result: best `DCES` at `261.60%`, worst `RASA` at `-91.76%`, average return `-25.26%`, exposure telemetry `6,000` stock-days.
- 225-day result: best `SWIT` at `732.33%`, worst `KBLK` at `-94.25%`, average return `19.25%`, exposure telemetry `11,250` stock-days.
- Price Engine Exposure Integration is now complete as the first bounded price-behavior foundation for the top-down market roadmap.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/MarketYearAudit.tscn -- --audit-seed 20260614 --audit-difficulty normal --audit-days 120 --audit-use-catalog --audit-company-count 50 --audit-compact-report`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/MarketYearAudit.tscn -- --audit-seed 20260614 --audit-difficulty normal --audit-days 225 --audit-use-catalog --audit-company-count 50 --audit-compact-report`

### 2026-06-14 - Company Universe Catalog follow-up expansion complete

- Expanded the company universe catalog from 60 to 70 companies.
- Added rare earth and silica basic industry companies to pair with the new commodity indicators.
- Added 8 banking companies covering large, mid-market, small, sharia, regional, digital, trade-finance, and micro-lending banks.
- Current catalog sector counts are `basicindustry=8`, `consumer=6`, `energy=6`, `finance=13`, `health=5`, `industrial=5`, `infra=5`, `noncyclical=6`, `property=5`, `tech=6`, and `transport=5`.
- Updated the deterministic catalog selection baseline to hash `1682964508`, first selection `surya_power_nusantara` / `SPWR`, and last selection `menara_signal_nusantara` / `MSIN`.

### 2026-06-15 - Living Company Arc System Task 4 complete

- Added the shared living-arc availability adapter in `RunState`.
- Company events now respect active/cooldown living state before spawning duplicate arcs.
- Company roadmaps now skip living-blocked milestone owners and finance partners.
- Eligibility tags now refresh from deterministic company facts, exposures, roadmap profile, traits, and story memory.
- Added `LivingCompanyArcIntegrationTest` for event and roadmap gate coverage.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/LivingCompanyArcIntegrationTest.tscn` -> `LIVING_COMPANY_ARC_INTEGRATION_TEST_OK`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick` -> `SMOKE_QUICK_OK normal_equity=94765318.11 days=3 ...`

### 2026-06-15 - Living Company Arc System Task 5 complete

- Added `LivingCompanyArcLongRunAuditTest` as the lifecycle state-growth audit.
- Ran a 120-trading-day catalog-backed audit with seed `20260615`, normal difficulty, and `50` companies.
- Saved the audit history in `docs/development/test_log/2026-06-15_living_company_arc_long_run_audit.md`.
- Result: `426` global completed living arcs, final status `6` active / `26` cooling down / `18` eligible / `0` suppressed, `40` companies with any living activity, `10` stagnant companies, `37` repeat-activity companies.
- State growth stayed bounded: global recent rows capped at `80`, per-company completed rows capped at `8`, and story-memory recent arrays stayed within cap.
- Balancing note: corporate actions dominate completions in this run; future tuning can group or dedupe source completions if narrative repetition becomes noisy.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/LivingCompanyArcLongRunAuditTest.tscn -- --living-arc-audit-seed 20260615 --living-arc-audit-difficulty normal --living-arc-audit-days 120 --living-arc-audit-use-catalog --living-arc-audit-company-count 50` -> `LIVING_COMPANY_ARC_LONG_RUN_AUDIT ... "success":true`

### 2026-06-15 - Company Story Dossier System Task 2 complete

- Added `systems/CompanyStoryDossierSystem.gd` as a pure deterministic dossier generator.
- The generator ranks archetypes from company hooks, sector, moat/narrative tags, commodity exposure, macro/sector state, roadmap profile, and event sensitivity.
- Generated dossiers now include hidden truth state, cause facts, timeline rows, financial effects, bounded price effects, public/private/statement clues, thesis hooks, resolution conditions, and traceability ids.
- No live save, news, Twooter, Network, thesis, or price-engine behavior changed; the system is explicit-call/test-only until later tasks.
- Added `CompanyStoryDossierFingerprintTest`.
- Locked fixed-seed baseline: hash `1867741019`, 30 dossiers, first story `story|pulp_nusantara|commodity_tailwind|2532662389`, last story `story|bank_syariah_harmoni|commodity_headwind|2473540029`.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyStoryDossierFingerprintTest.tscn` -> `COMPANY_STORY_DOSSIER_FINGERPRINT_OK {"hash":"1867741019","dossier_count":30,...}`

### 2026-06-15 - Company Story Dossier System Task 3 complete

- Added saved `company_story_dossier_state` in `RunState`.
- Fresh runs now seed a deterministic dossier registry after company setup.
- Per-company runtime state now stores compact dossier refs: active ids, resolved ids, current story id, stage map, public status map, and recent ids.
- Added RunState getters and an explicit `update_company_story_dossier_progress(...)` helper for future content/thesis/price bridges.
- Legacy saves with no dossier state normalize to an empty registry instead of auto-generating new stories on load.
- Added `CompanyStoryDossierSaveDefaultsTest`.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyStoryDossierSaveDefaultsTest.tscn` -> `COMPANY_STORY_DOSSIER_SAVE_DEFAULTS_OK {"baseline_count":30,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyStoryDossierFingerprintTest.tscn` -> `COMPANY_STORY_DOSSIER_FINGERPRINT_OK {"hash":"1867741019","dossier_count":30,...}`

### 2026-06-15 - Company Story Dossier System Task 4 complete

- Bridged saved company story dossiers into thesis evidence options.
- Added Story Dossier rows for macro cause, sector cause, company story, financial clue, and private clue while keeping existing thesis categories stable.
- Preserved story provenance through Research Tray capture, thesis attach, direct thesis add, and RunState normalization.
- Hidden `truth_state` remains excluded from thesis evidence rows.
- Added `CompanyStoryDossierThesisEvidenceTest`.
- Updated `ThesisFingerprintTest` option and combined hashes; the report hash stayed unchanged.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyStoryDossierThesisEvidenceTest.tscn` -> `COMPANY_STORY_DOSSIER_THESIS_EVIDENCE_OK {"company_id":"nikel_makmur","row_count":7,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/ThesisResearchTrayTest.tscn` -> `THESIS_RESEARCH_TRAY_OK`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/ThesisFingerprintTest.tscn` -> `THESIS_FINGERPRINT_OK {"hash":"674019173","option_hash":"674078562","report_hash":"1836382259",...}`

### 2026-06-15 - Company Story Dossier System Task 5 complete

- Added `CompanyStoryDossierConsistencyTest` as the cross-reference and consistency gate.
- The test verifies repeated fixed-seed runs produce stable output and checks for orphan story/fact/clue/effect refs across saved state, clues, financial effects, traceability, and Story Dossier thesis rows.
- Locked consistency baseline hash `2006435509`.
- Current fixed-seed counts: `30` dossiers, `network=30`, `news=30`, `statement_note=30`, `twooter=30`, and `201` Story Dossier thesis rows.
- Runtime behavior stayed unchanged; this is test coverage only.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyStoryDossierConsistencyTest.tscn` -> `COMPANY_STORY_DOSSIER_CONSISTENCY_OK {"hash":"2006435509","issue_count":0,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyStoryDossierFingerprintTest.tscn` -> `COMPANY_STORY_DOSSIER_FINGERPRINT_OK {"hash":"1867741019","dossier_count":30,...}`

### 2026-06-15 - Company Story Dossier System Task 6 complete

- Added explicit read-only preview builders to `CompanyStoryDossierSystem`.
- Supported preview surfaces are `summary`, `news`, `twooter`, `network`, and `statement_note`.
- Preview rows include deterministic headline/deck/body text plus valid `story_id`, `fact_ids`, `clue_ids`, `effect_ids`, `metric_ids`, and traceability arrays.
- Hidden `truth_state`, tone, reliability, source quality, and disclosure quality remain excluded from previews.
- No live News, Twooter, Network, statement, price, or thesis behavior was replaced.
- Added `CompanyStoryDossierPreviewTest`.
- Locked preview baseline hash `1727264953`, with `30` news previews and `5` summary previews.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyStoryDossierPreviewTest.tscn` -> `COMPANY_STORY_DOSSIER_PREVIEW_OK {"hash":"1727264953","issue_count":0,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyStoryDossierConsistencyTest.tscn` -> `COMPANY_STORY_DOSSIER_CONSISTENCY_OK {"hash":"2006435509","issue_count":0,...}`

### 2026-06-17 - Financial Statement Layer Task 1 complete

- Defined the v1 financial statement period, section, note, story-adjustment, and traceability schema.
- Chosen direction: extend existing `financial_statement_snapshot.quarterly_statements` rows rather than creating a parallel accounting system.
- Existing `income_statement`, `balance_sheet`, and `cash_flow` arrays remain compatible.
- Future fields are additive: `operating_metrics`, `notes`, `story_adjustments`, and `traceability`.
- Runtime behavior stayed unchanged; Task 1 was schema/design only.
- Verification:
  - `git diff --check`

### 2026-06-17 - Financial Statement Layer Task 2 complete

- Added `systems/FinancialStatementLayer.gd` as the pure Story Dossier financial-effect mapper.
- Wired `RunState._build_quarterly_filing_payload(...)` so active company story dossier effects adjust quarterly statement rows before `financials_after`, growth, margin, and surprise score are derived.
- The mapper currently adds bounded statement deltas, `story_adjustments`, statement traceability, and line-level `source_story_ids` / `source_effect_ids`.
- Added `FinancialStatementLayerStoryEffectTest`.
- Locked story-effect baseline hash `353480211`.
- Runtime behavior changed only for quarterly filings that have active company story dossier financial effects; no UI, MD&A prose, note text generation, or thesis capture behavior was added yet.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/FinancialStatementLayerStoryEffectTest.tscn` -> `FINANCIAL_STATEMENT_LAYER_STORY_EFFECT_OK {"hash":"353480211",...}`
  - `/Users/user/.local/bin/godot --headless -e --quit`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyStoryDossierConsistencyTest.tscn` -> `COMPANY_STORY_DOSSIER_CONSISTENCY_OK {"hash":"2006435509","issue_count":0,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11 days=3 ...`

### 2026-06-17 - Financial Statement Layer Task 3 complete

- Extended `FinancialStatementLayer` so adjusted quarterly statements also receive deterministic structured filing notes.
- Notes are grouped by `story_id` and source `note_type`, linked back through `story_adjustments.note_id`, and recorded in `traceability.generated_note_ids`.
- Notes include short summary text, text/title keys, metric ids, fact ids, effect ids, clue ids, disclosure quality, access/detail level, tone, importance, contradiction flag, and explain tags.
- Added post-corporate-action `use_of_proceeds` note support with the `post_corporate_action` explain tag.
- Hidden raw story truth fields stay out of statement rows; disclosure quality is the public filing clarity layer.
- Added `FinancialStatementLayerDisclosureTest`.
- Locked disclosure baseline hash `1824588069`.
- Runtime behavior changed only for quarterly filings that have active Story Dossier financial effects; no UI/report display or thesis evidence capture path was added yet.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/FinancialStatementLayerDisclosureTest.tscn` -> `FINANCIAL_STATEMENT_LAYER_DISCLOSURE_OK {"hash":"1824588069",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/FinancialStatementLayerStoryEffectTest.tscn` -> `FINANCIAL_STATEMENT_LAYER_STORY_EFFECT_OK {"hash":"353480211",...}`

### 2026-06-17 - Financial Statement Layer Task 4 complete

- Added a STOCKBOT Financials tab `Report` button that opens a full-screen white filing/report overlay.
- The report view renders the selected period's income statement, balance sheet, cash flow, operating metrics, and Notes & MD&A in a dense scrollable layout.
- Added inline Financials tab cards for operating metrics and Notes & MD&A.
- Preserved statement/note capture hooks through the existing financial statement research action menu.
- Mirrored latest `operating_metrics`, `notes`, `story_adjustments`, and `traceability` into the top-level statement snapshot for UI compatibility.
- Added smoke coverage for opening, layout-checking, and closing the report overlay.
- Runtime behavior changed only by adding the player-facing statement/report display path; thesis scoring remains future Task 5 work.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/FinancialStatementLayerDisclosureTest.tscn` -> `FINANCIAL_STATEMENT_LAYER_DISCLOSURE_OK {"hash":"1824588069",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/FinancialStatementLayerStoryEffectTest.tscn` -> `FINANCIAL_STATEMENT_LAYER_STORY_EFFECT_OK {"hash":"353480211",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/ThesisResearchTrayTest.tscn` -> `THESIS_RESEARCH_TRAY_OK`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/ThesisFingerprintTest.tscn` -> `THESIS_FINGERPRINT_OK {"hash":"674019173",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11 days=3 ...`
  - `/Users/user/.local/bin/godot --headless -e --quit`

### 2026-06-17 - Financial Statement Layer Task 5 complete

- Statement line capture now preserves filing provenance into thesis evidence:
  - statement id, period, scope, year/quarter, filing day, section id/label, line id, metric id, raw value, value format, source story ids, and source effect ids.
- Statement note capture now preserves note provenance into thesis evidence:
  - note id/type, title/text keys, disclosure quality, detail level, access level, tone, importance, metric/effect/fact/clue ids, source statement sections, and explain tags.
- Updated `ThesisEvidenceCaptureSystem`, `ThesisManager`, and `RunState` so Research Tray rows, direct thesis evidence adds, attached thesis rows, and save/load all keep the statement/note fields.
- Research evidence dedupe now includes statement id, period, section, line id, and note id.
- Added `FinancialStatementLayerThesisCaptureTest`.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/FinancialStatementLayerThesisCaptureTest.tscn` -> `FINANCIAL_STATEMENT_LAYER_THESIS_CAPTURE_OK`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/ThesisResearchTrayTest.tscn` -> `THESIS_RESEARCH_TRAY_OK`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/ThesisFingerprintTest.tscn` -> `THESIS_FINGERPRINT_OK {"hash":"674019173",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/FinancialStatementLayerDisclosureTest.tscn` -> `FINANCIAL_STATEMENT_LAYER_DISCLOSURE_OK {"hash":"1824588069",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/FinancialStatementLayerStoryEffectTest.tscn` -> `FINANCIAL_STATEMENT_LAYER_STORY_EFFECT_OK {"hash":"353480211",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11 days=3 ...`
  - `/Users/user/.local/bin/godot --headless -e --quit`

### 2026-06-17 - Financial Statement Layer Task 6 complete

- Added `FinancialStatementLayerSnapshotMatrixTest` as the broader fixed-input statement verification gate.
- The matrix covers customer contracts, use of proceeds, margin/input cost pressure, debt/liquidity, and statement contradiction story shapes.
- The test checks deterministic repeated payloads, numeric plausibility, adjustment before/after/delta consistency, traceability, note consistency, line source effect ids, and hidden truth leakage.
- Locked snapshot matrix baseline hash `1888558735`.
- The Financial Statement Layer feature is now complete for the current enhancement scope.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/FinancialStatementLayerSnapshotMatrixTest.tscn` -> `FINANCIAL_STATEMENT_LAYER_SNAPSHOT_MATRIX_OK {"hash":"1888558735","case_count":5,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/FinancialStatementLayerStoryEffectTest.tscn` -> `FINANCIAL_STATEMENT_LAYER_STORY_EFFECT_OK {"hash":"353480211",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/FinancialStatementLayerDisclosureTest.tscn` -> `FINANCIAL_STATEMENT_LAYER_DISCLOSURE_OK {"hash":"1824588069",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/FinancialStatementLayerThesisCaptureTest.tscn` -> `FINANCIAL_STATEMENT_LAYER_THESIS_CAPTURE_OK`
  - `/Users/user/.local/bin/godot --headless -e --quit`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11 days=3 ...`

### 2026-06-17 - Financial Statement Layer Revision R2.1 complete

- Added the post-start annual statement enrichment pass in `RunState`.
- The pass runs after new-run story seeding, save/load state normalization, and company full-detail hydration.
- Annual statements and generated annual notes now receive stable source-ready `post_start_traceability` metadata for Story Dossier, Living Company Arc, corporate action, event history, and company roadmap systems.
- The pass is idempotent and preserves deterministic note ordering; at the time of R2.1 completion, specific live source-id mapping remained planned for R2.2-R2.5. R2.2 is now complete below.
- Added `AnnualStatementEnrichmentPassTest`.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualStatementEnrichmentPassTest.tscn` -> `ANNUAL_STATEMENT_ENRICHMENT_PASS_OK {"company_id":"kete","note_count":14,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualConsolidatedStatementBuilderTest.tscn` -> `ANNUAL_CONSOLIDATED_STATEMENT_BUILDER_OK {"hash":"2029322553",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/FinancialStatementLayerThesisCaptureTest.tscn` -> `FINANCIAL_STATEMENT_LAYER_THESIS_CAPTURE_OK`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK`
  - `git diff --check`

### 2026-06-17 - Financial Statement Layer Revision R2.2 complete

- Annual statement enrichment now maps Company Story Dossier facts, effects, and clues into relevant annual note rows by structured source note type and metric id.
- Living Company Arc active/completed arc context now maps into annual note rows with `source_living_arc_ids` and `living_arc_refs`.
- Statement-level annual traceability now rolls up mapped story, effect, fact, clue, and living-arc IDs from enriched notes.
- Added `AnnualStatementStorySourceEnrichmentTest` to cover revenue, PPE/capex, debt, segment, commitments, unrelated-note cleanliness, and repeated enrichment idempotence.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualStatementStorySourceEnrichmentTest.tscn` -> `ANNUAL_STATEMENT_STORY_SOURCE_ENRICHMENT_OK {"company_id":"kete","story_count":3,...}`

### 2026-06-18 - Financial Statement Layer Revision R2.3 complete

- Annual statement enrichment now maps corporate-action provenance into relevant annual notes with `source_corporate_action_ids` and `corporate_action_refs`.
- Event history rows now map into annual notes with `source_event_ids`, `source_event_ref_ids`, and `event_refs`.
- Company roadmap milestones now map into annual notes with `source_roadmap_ids` and `roadmap_refs`.
- Statement-level annual traceability now rolls up corporate-action, event, event-ref, and roadmap IDs from enriched notes.
- Added `AnnualStatementActionEventRoadmapEnrichmentTest` to cover seeded corporate-action chain, corporate-action event, roadmap milestone/event, unrelated-note cleanliness, and repeated enrichment idempotence.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/AnnualStatementActionEventRoadmapEnrichmentTest.tscn` -> `ANNUAL_STATEMENT_ACTION_EVENT_ROADMAP_ENRICHMENT_OK {"company_id":"sire","note_count":14,...}`
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/AnnualStatementStorySourceEnrichmentTest.tscn` -> `ANNUAL_STATEMENT_STORY_SOURCE_ENRICHMENT_OK {"company_id":"kete","story_count":3,...}`
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/AnnualStatementEnrichmentPassTest.tscn` -> `ANNUAL_STATEMENT_ENRICHMENT_PASS_OK {"company_id":"kete","note_count":14,...}`
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/AnnualConsolidatedStatementBuilderTest.tscn` -> `ANNUAL_CONSOLIDATED_STATEMENT_BUILDER_OK {"hash":"2029322553",...}`
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/FinancialStatementLayerThesisCaptureTest.tscn` -> `FINANCIAL_STATEMENT_LAYER_THESIS_CAPTURE_OK`

### 2026-06-18 - Financial Statement Layer Revision R2.4 complete

- Financial statement note capture now carries enriched source arrays and refs for Story Dossier, Living Company Arc, corporate action, event history, and roadmap provenance.
- `ThesisEvidenceCaptureSystem`, `RunState` Research Tray/save-load normalization, and `ThesisManager` direct thesis evidence add now preserve the enriched annual-note provenance fields.
- `FinancialStatementLayerThesisCaptureTest` now seeds an enriched annual commitments note and verifies Research Tray capture, attach-to-thesis, direct thesis add, and save/load preservation.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/FinancialStatementLayerThesisCaptureTest.tscn` -> `FINANCIAL_STATEMENT_LAYER_THESIS_CAPTURE_OK`
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/AnnualStatementActionEventRoadmapEnrichmentTest.tscn` -> `ANNUAL_STATEMENT_ACTION_EVENT_ROADMAP_ENRICHMENT_OK {"company_id":"sire","note_count":14,...}`
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/AnnualStatementStorySourceEnrichmentTest.tscn` -> `ANNUAL_STATEMENT_STORY_SOURCE_ENRICHMENT_OK {"company_id":"kete","story_count":3,...}`
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/AnnualStatementEnrichmentPassTest.tscn` -> `ANNUAL_STATEMENT_ENRICHMENT_PASS_OK {"company_id":"kete","note_count":14,...}`
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/AnnualConsolidatedStatementBuilderTest.tscn` -> `ANNUAL_CONSOLIDATED_STATEMENT_BUILDER_OK {"hash":"2029322553",...}`

### 2026-06-18 - Financial Statement Layer Revision R2.5 complete

- Added `AnnualStatementFullTraceabilityContractTest` as the full-source annual-note traceability contract.
- The test seeds Story Dossier, Living Company Arc, corporate action, event-history, and roadmap sources into one fixed-seed annual statement and verifies statement rollups, note-level source arrays/refs, clean unrelated notes, mirror preservation, save/load preservation, legacy-style repair, and repeated enrichment determinism.
- Locked fixed-seed traceability hash `584882106` at the time of R2.5. Story Dossier R1.5 later expanded the contract to include disclosure packet provenance and updated the current hash to `1974201801`.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualStatementFullTraceabilityContractTest.tscn` -> current baseline `ANNUAL_STATEMENT_FULL_TRACEABILITY_CONTRACT_OK {"company_id":"sire","hash":"1974201801","note_count":14,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualStatementActionEventRoadmapEnrichmentTest.tscn` -> `ANNUAL_STATEMENT_ACTION_EVENT_ROADMAP_ENRICHMENT_OK {"company_id":"sire","note_count":14,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualStatementStorySourceEnrichmentTest.tscn` -> `ANNUAL_STATEMENT_STORY_SOURCE_ENRICHMENT_OK {"company_id":"kete","story_count":3,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualStatementEnrichmentPassTest.tscn` -> `ANNUAL_STATEMENT_ENRICHMENT_PASS_OK {"company_id":"kete","note_count":14,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualConsolidatedStatementBuilderTest.tscn` -> `ANNUAL_CONSOLIDATED_STATEMENT_BUILDER_OK {"hash":"2029322553",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/FinancialStatementLayerThesisCaptureTest.tscn` -> `FINANCIAL_STATEMENT_LAYER_THESIS_CAPTURE_OK`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11 days=3 ...`

### 2026-06-19 - Company Story Dossier Revision R1.1 complete

- Added deterministic annual-report disclosure placement rows to company story dossiers.
- Added canonical filing section definitions, traceability arrays, save normalization, and a focused placement regression test.
- Locked placement hash `1533142911` across `30` dossiers and `144` placement rows.
- Next roadmap step at the time was Company Story Dossier R1.2; that work is now complete below.

### 2026-06-19 - Company Story Dossier Revision R1.2 complete

- Added deterministic clue subtlety and section scattering to story dossier disclosure placements.
- Placement rows now carry public metadata for `subtlety`, `reader_effort`, `evidence_density`, `fragment_role`, `scattering_strategy`, `scattering_index`, and `scattering_total`.
- Locked placement hash `1192489532` across `30` dossiers and `105` placement rows.
- Next roadmap step at the time was Company Story Dossier R1.3; that work is now complete below.

### 2026-06-19 - Company Story Dossier Revision R1.3 complete

- Added compact multi-section disclosure packets generated from story dossier placement rows.
- Packets carry stable phrase ids, render tokens, cross-reference section ids, packet roles, and render priorities without storing long generated prose.
- Locked packet hash `2005222199` across `30` dossiers and `105` packet rows.
- Next roadmap step at the time was Company Story Dossier R1.4; that work is now complete below.

### 2026-06-19 - Company Story Dossier Revision R1.4 complete

- Added deterministic placement/packet artifact repair for legacy and malformed story dossier saves.
- Added RunState lookup APIs for disclosure placements and packets by story, company, and filing section.
- Traceability disclosure ids now repair from normalized row ids on load.
- Added `CompanyStoryDossierDisclosurePersistenceTest`.
- Locked persistence hash `2080268323` across `30` dossiers, `105` placement rows, and `105` packet rows.
- Next roadmap step at the time was Company Story Dossier R1.5; that work is now complete below.

### 2026-06-21 - Company Story Dossier Revision R1.5 complete

- Bridged story dossier disclosure packet provenance into annual statement story-source enrichment.
- Annual notes and statement traceability now preserve packet ids, placement ids, section ids, and packet refs.
- Financial statement note capture and thesis evidence normalization now preserve the packet bridge fields through Research Tray, direct evidence, attached evidence, and save/load.
- Visible packet refs omit hidden truth/source-quality labels.
- Updated the full annual traceability baseline hash to `1974201801`.
- Next roadmap step at the time was Company Story Dossier R1.6; that work is now complete below.

### 2026-06-21 - Company Story Dossier Revision R1.6 complete

- Added `CompanyStoryDossierFinancialStatementFixtureTest` as the final generated-dossier-to-financial-statement bridge fixture.
- The fixture validates all generated disclosure placements/packets across `30` fixed-seed dossiers, all `10` filing sections, all `5` subtlety bands, story/fact/effect/clue refs, company/section lookup APIs, annual note packet refs, thesis evidence normalization, and no hidden truth/source-quality leaks.
- Locked fixture hash `623183840` with `105` placements, `105` packets, fixture company `alat_berat_mandiri`, and `10` annual note packet refs.
- Next roadmap step is Financial Statement Layer Revision R3.

### 2026-06-21 - Financial Statement Layer Revision R3.1 complete

- Added the annual report document-reading contract to generated annual consolidated statements.
- Added annual statement fields for `document_reading_contract`, `annual_report_section_map`, and `table_of_contents`.
- Locked the section map and page ranges for financial position, profit or loss and OCI, changes in equity, cash flows, and notes.
- Added `AnnualReportDocumentContractTest`.
- Locked document contract hash `2022978131`.
- Existing annual consolidated builder hash stayed `2029322553`, so numeric/content output stayed stable.
- Next roadmap step is Financial Statement Layer R3.2: expand the accounting row model and continuity checks.

### 2026-06-21 - Financial Statement Layer Revision R3.2 complete

- Added `accounting_row_model` metadata to annual consolidated statements with 62 deterministic row definitions.
- Added `accounting_continuity_checks` with 22 passed checks covering statement subtotals, balance sheet equation, profit/loss bridges, equity roll-forward, cash-flow bridges, and cross-statement cash/equity agreement.
- Added explicit annual rows for total debt and borrowings, operating cash-flow bridge items, and other financing cash-flow residuals.
- Added `AnnualStatementAccountingContinuityTest`.
- Locked R3.2 continuity hash `1613787417`.
- Updated annual consolidated builder hash to `867613961` because R3.2 intentionally adds annual statement rows.
- R3.1 document contract hash remains `2022978131`; full annual traceability hash remains `1974201801`.
- Next roadmap step is Financial Statement Layer R3.3: filing-style note bodies and cross-note references.

### 2026-06-21 - Financial Statement Layer Revision R3.3 complete

- Added filing-style annual note bodies through `filing_note_body`, `body_paragraphs`, `compact_tables`, `cross_note_references`, `visible_cross_reference_text`, and `body_text`.
- Re-renders note bodies after post-start enrichment so Story Dossier disclosure packet refs contribute to cross-note references.
- Notes are now readable in the document contract; compact placeholder section list is empty.
- Added `AnnualStatementFilingNoteBodyTest`.
- Locked note-body hash `1102538137`.
- Updated document contract hash to `2037575392`.
- Existing annual builder, accounting continuity, full traceability, Story Dossier bridge fixture, and thesis capture baselines stayed stable.
- Next roadmap step is Financial Statement Layer R3.4: document-reader UI flow.

### 2026-06-21 - Financial Statement Layer Revision R3.4 complete

- Reworked the annual consolidated statement overlay into a document-reader flow.
- Added sidebar and in-page table-of-contents navigation with section anchors for the five annual report sections.
- Preserved the `View Consolidated Financial Statement` entry point and A4 page shell.
- Notes render R3.3 filing body paragraphs, compact selected-amount tables, and visible cross-note references.
- Added paragraph-level financial statement capture metadata and preservation through thesis evidence/save-load paths.
- Quick smoke now verifies reader open, viewport/A4 bounds, TOC targets, Notes jump behavior, and note paragraph/table rendering.
- Verification: quick smoke OK, `FinancialStatementLayerThesisCaptureTest` OK, `AnnualStatementFilingNoteBodyTest` hash `1102538137`, `AnnualReportDocumentContractTest` hash `2037575392`.
- Next roadmap step is Financial Statement Layer R3.5: consume subtle disclosure placements from Story Dossier R1 in the reader flow.

### 2026-06-21 - Financial Statement Layer Revision R3.5 complete

- Annual notes now consume Story Dossier disclosure packet refs as visible note paragraphs instead of generic packet-count text.
- Packet paragraphs are ordered by packet render priority and worded by subtlety: direct, implied, buried, conflicting, or missing.
- Visible text uses filing section labels, metric labels, selected FY values where available, and cross-check note sections without exposing hidden ids.
- Packet paragraph capture now preserves packet, placement, section, subtlety, reader-effort, evidence-density, fragment-role, packet-role, source arrays, and `disclosure_packet_refs`.
- Thesis evidence, direct thesis add, Research Tray normalization, and save/load normalization preserve the new packet paragraph metadata.
- Updated `AnnualStatementFilingNoteBodyTest` hash to `36249412`; the fixed-seed selected company renders `20` packet refs into `20` packet paragraphs.
- Existing annual builder, document contract, full traceability, and Story Dossier bridge fixture hashes stayed stable.
- Verification: editor load OK, quick smoke OK, `AnnualStatementFilingNoteBodyTest` OK, `FinancialStatementLayerThesisCaptureTest` OK, `AnnualStatementFullTraceabilityContractTest` OK, `CompanyStoryDossierFinancialStatementFixtureTest` OK.
- Next roadmap step is Financial Statement Layer R3.6: final annual report fidelity, capture, and smoke coverage.

### 2026-06-21 - Financial Statement Layer Revision R3.6 complete

- Added the final annual report fidelity and capture regression with `AnnualReportFidelityCaptureTest`.
- Locked fidelity hash `906899410` for fixed-seed company `wisata_kuliner_nusantara`.
- The test verifies A4/TOC/14-note annual report structure, Story Dossier packet paragraph placement, multi-section story scattering, statement-row capture, packet-paragraph capture, and cross-note reference capture.
- Cross-note reference metadata now survives Research Tray normalization, thesis direct add, thesis attach, and save/load.
- Quick smoke now asserts rendered `FinancialStatementReportNoteCrossReference` controls inside the annual report reader.
- Verification: editor load OK, quick smoke OK, `AnnualReportFidelityCaptureTest` OK, existing annual builder/document/continuity/enrichment/traceability/filing-note/capture/fixture tests OK.
- Next roadmap step is Annual Filing Reading Experience: lazy on-click filing generation and a less explicit document-reading surface.

### 2026-06-21 - Annual Filing Reading Experience plan created

- Added [Annual Filing Reading Experience](ANNUAL_FILING_READING_EXPERIENCE_ENHANCEMENT.md) as a separate follow-up plan instead of extending the already long Financial Statement Layer history file.
- The new plan keeps Financial Statement R1-R3 as completed plumbing, but reframes the next product correction around:
  - lazy filing generation only when the player clicks `View Consolidated Financial Statement`
  - natural annual-report prose and routine boilerplate
  - buried multi-section accounting footprints instead of explicit evidence-card text
  - cache/performance guardrails for long filing documents
- Content Surface Generation remains planned after this financial-statement reading pass.

### 2026-06-21 - Annual Filing Reading Experience Task 1 complete

- Added `systems/AnnualFilingDocument.gd` with the lazy annual filing document contract, deterministic cache key, source-state hash, and in-memory cache helper.
- Wired `StockController.gd` so `View Consolidated Financial Statement` requests the annual filing document before rendering the current R3 source annual statement.
- Added `AnnualFilingLazyContractTest`; Task 2 later updated the fixed-seed hash to `1374326765` after adding filing schema invalidation, Task 3 later updated it to `653488372` after adding footprint hash invalidation, Task 4 later updated it to `1258270729` after adding prose hash invalidation, and Task 5 later updated it to `1982276232` after adding visible filing generation to the document payload.
- Existing annual report document contract hash `2037575392`, fidelity hash `906899410`, and quick smoke remained stable.
- Next step at the time was Annual Filing Reading Experience Task 2; that work is now complete below.

### 2026-06-21 - Annual Filing Reading Experience Task 2 complete

- Added the expanded annual filing anatomy schema to `AnnualFilingDocument.gd`.
- The schema defines 20 deterministic filing sections: four front-matter sections, four primary statements, and twelve note groups covering company information, policies, assets, liabilities, performance, related parties, segments, commitments, risk management, and subsequent events.
- Added deterministic filing table-of-contents rows, R3 source-section mapping, filing schema payload hashing, and cache invalidation through `filing_schema_hash`.
- Added `AnnualFilingAnatomySchemaTest` with fixed-seed anatomy hash `230195522` and schema hash `700723473`.
- Updated `AnnualFilingLazyContractTest` fixed-seed hash to `1374326765` because the cache key now includes `filing_schema_hash`; Task 3 later updated it to `653488372`, Task 4 later updated it to `1258270729`, and Task 5 later updated the current fixed-seed hash to `1982276232`.
- Verification: `AnnualFilingAnatomySchemaTest` OK, `AnnualFilingLazyContractTest` OK, editor load OK, existing annual report document/fidelity tests OK, quick smoke OK, and `git diff --check` OK.
- Next step at the time was Annual Filing Reading Experience Task 3; that work is now complete below.

### 2026-06-21 - Annual Filing Reading Experience Task 3 complete

- Added deterministic accounting-footprint packets to `AnnualFilingDocument.gd`.
- Footprints bridge existing Story Dossier `disclosure_packet_refs` into filing-style clue surfaces without generating visible filing prose yet.
- The model defines numeric movements, statement-row note references, note paragraphs, compact table rows, cross-note references, auditor risk focus, segment movement, risk-management language, and subsequent-event language.
- Added `accounting_footprint_hash` to the annual filing cache key, cache key parts, and invalidation fields.
- Added `AnnualFilingFootprintPacketTest` with fixed-seed footprint packet hash `1286418835`; fixed-seed company `hahe`, FY2019 has footprint hash `158179705` and 22 footprint packets.
- Updated `AnnualFilingLazyContractTest` fixed-seed hash to `653488372`; Task 4 later updated it to `1258270729`, and Task 5 later updated the current hash to `1982276232`.
- Verification: `AnnualFilingLazyContractTest` OK, `AnnualFilingAnatomySchemaTest` OK, and `AnnualFilingFootprintPacketTest` OK.
- Next step at the time was Annual Filing Reading Experience Task 4; that work is now complete below.

### 2026-06-21 - Annual Filing Reading Experience Task 4 complete

- Added deterministic natural filing prose packets to `AnnualFilingDocument.gd`.
- The prose layer defines 13 template types covering company information, accounting policies, estimates and judgments, receivables, inventories, PPE/capex, borrowings, revenue, segment information, related parties, commitments, risk management, and subsequent events.
- Added sector-style vocabulary for `generic_annual_filing` and AKR-like `trading_logistics_industrial_estate` wording.
- Prose packets mix routine boilerplate with quantified footprint paragraphs while keeping story ids, packet ids, truth labels, source-quality labels, confidence labels, and trade-answer wording out of visible text.
- Added `filing_prose_hash` to the annual filing cache key, cache key parts, and invalidation fields.
- Added `AnnualFilingProseLibraryTest` with fixed-seed prose library hash `1676592393`; fixed-seed company `hahe`, FY2019 has prose hash `207705355`, 42 prose packets, 20 boilerplate/policy/estimate packets, and 22 footprint-linked prose packets.
- Updated `AnnualFilingLazyContractTest` current fixed-seed hash to `1258270729`; Task 5 later updated the current hash to `1982276232`.
- Verification: `AnnualFilingProseLibraryTest` OK, `AnnualFilingLazyContractTest` OK, `AnnualFilingAnatomySchemaTest` OK, `AnnualFilingFootprintPacketTest` OK, existing annual report document/fidelity tests OK, editor load OK, quick smoke OK, and `git diff --check` OK.
- Next step at the time was Annual Filing Reading Experience Task 5; that work is now complete below.

### 2026-06-22 - Annual Filing Reading Experience Task 5 complete

- Added visible annual filing generation to `AnnualFilingDocument.gd`.
- The visible document is still lazy: it materializes only through the report-button request path and remains an in-memory display artifact, not saved `RunState`.
- Generated filings now carry `task5_visible_filing_ready` status, visible filing hashes, 20 sections, visible paragraphs, compact tables, cross-references, section lookup, and generation-source metadata.
- Updated `StockController.gd` so `View Consolidated Financial Statement` displays the generated filing document instead of the old source-statement bridge.
- The interim renderer keeps primary statements on existing statement rows and renders front matter/note groups as filing paragraphs, compact tables, and cross-references; Task 6 later added the A4 chunked reader shell.
- Added `AnnualFilingVisibleGenerationTest` with fixed-seed hash `1986473927`; fixed-seed company `hahe`, FY2019 has visible filing hash `781569065`, 20 sections, 42 paragraphs, 3 compact tables, and 3 cross-references.
- Updated `AnnualFilingLazyContractTest` current fixed-seed hash to `1982276232`.
- Updated quick smoke to assert generated annual filing section navigation and rendered note-section controls.
- Verification: `AnnualFilingVisibleGenerationTest` OK, `AnnualFilingLazyContractTest` OK, `AnnualFilingAnatomySchemaTest` OK, `AnnualFilingFootprintPacketTest` OK, `AnnualFilingProseLibraryTest` OK, existing annual report document/fidelity tests OK, and quick smoke OK.
- Next step at the time was Annual Filing Reading Experience Task 6; that work is now complete below.

### 2026-06-22 - Annual Filing Reading Experience Task 6 complete

- Reworked the generated filing overlay into an explicit A4 reader contract in `StockController.gd`.
- The report page, page scroll, and body now expose A4 page-size metadata and `a4_virtualized_sections` reader metadata.
- Added responsive A4 page margins and vertical-only page scrolling so the report behaves like a bounded document reader rather than a dashboard panel.
- Generated filing text sections now render into bounded chunk containers named `FinancialStatementReportSectionChunk_<section_id>_<chunk_index>`.
- Statement rows and compact tables now use responsive value/reference widths for smaller page shells.
- Updated `SmokeTest.gd` to assert A4 metadata, responsive margins, vertical-only scrolling, TOC jump behavior, generated note chunks, and bounded rendered chunk count.
- Verification: editor load OK, `AnnualFilingVisibleGenerationTest` OK with unchanged visible generation hash `1986473927`, and quick smoke OK.
- Next step at the time was Annual Filing Reading Experience Task 7; that work is now complete below.

### 2026-06-22 - Annual Filing Reading Experience Task 7 complete

- Updated annual filing evidence capture so the generated reader exposes neutral filing excerpt payloads instead of explicit clue-card labels.
- Statement rows, note paragraphs, compact table rows, cross-note references, segment rows, auditor key matter paragraphs, and subsequent-event paragraphs now preserve filing metadata through Research Tray, thesis attach, direct add, and save/load.
- Updated quick smoke coverage for capture availability, hidden-token safety, dedupe, attach/direct-add persistence, and save/load normalization.
- Verification: editor load OK, `AnnualFilingVisibleGenerationTest` OK with unchanged visible generation hash `1986473927`, and quick smoke OK.
- Next step at the time was Annual Filing Reading Experience Task 8; that work is now complete below.

### 2026-06-22 - Annual Filing Reading Experience Task 8 complete

- Added `AnnualFilingRegressionGuardTest` and scene as the focused fixed-seed regression gate for the lazy annual filing reader.
- Locked fixed-seed regression guard hash `1701463489` for company `hahe`, FY2019, with visible filing hash `781569065`.
- The guard verifies lazy contract-only behavior, first-open cache miss/build, second-open cache hit, source-state cache invalidation, generated document size, section/TOC/page-label anatomy, hidden-token safety, and bounded generation/cache timings.
- Updated quick smoke with a rendered-control-count guard for the A4 filing reader so long-document regressions fail before the UI becomes too heavy.
- Verification: `AnnualFilingRegressionGuardTest` OK, `AnnualFilingLazyContractTest` OK, `AnnualFilingVisibleGenerationTest` OK, `AnnualReportFidelityCaptureTest` OK, and quick smoke OK.
- Next roadmap step at the time was Content Surface Generation; Task 1 is now complete below.

### 2026-06-22 - Content Surface Generation Task 1 complete

- Added the surface reveal contract to [Content Surface Generation](CONTENT_SURFACE_GENERATION_ENHANCEMENT.md).
- The contract defines required generated-item metadata, public/private boundaries, reliability, delay, detail levels, and never-leak rules for macro news, sector news, company news, Twooter, Network, filings, and thesis evidence.
- This is a design-gate task only; no runtime generation, UI, save data, or gameplay behavior changed.
- Verification: design review completed in the feature doc and `git diff --check` OK.
- Next roadmap step at the time was Content Surface Generation Task 2; that work is now complete below.

### 2026-06-22 - Content Surface Generation Task 2 complete

- Added generated public news previews in `NewsFeedSystem`.
- Generated preview sources consume active dossier `public_clues` with `surface_id = "news"` and `visibility = "public"`.
- The generated public news surfaces are `company_news`, `sector_news`, and `macro_news`; authored news/event/public-brief articles remain intact in the same snapshot.
- Generated articles preserve source-system, story, fact, clue, company, and sector metadata for tests and future thesis/report integration.
- Added `ContentSurfaceNewsPreviewTest` with fixed-seed hash `219414638`; the test covers company, sector, and macro generated-news surfaces and checks that visible copy does not leak hidden/private implementation terms.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/ContentSurfaceNewsPreviewTest.tscn` -> `CONTENT_SURFACE_NEWS_PREVIEW_OK {"authored_article_count":12,"day_index":26,"generated_article_count":28,"hash":"219414638","issue_count":0,"issues":[],"seed":20260622,"surface_counts":{"company_news":16,"macro_news":4,"sector_news":8}}`
- Next roadmap step at the time was Content Surface Generation Task 3; that work is now complete below.

### 2026-06-22 - Content Surface Generation Task 3 complete

- Added generated public Twooter previews in `TwooterFeedSystem`.
- Generated preview sources consume active dossier `public_clues` with `surface_id = "twooter"` and `visibility = "public"`.
- Generated Twooter surfaces cover company, sector, and macro/commodity chatter while authored posts remain intact in the same snapshot.
- Generated posts preserve source-system, story, fact, clue, company, and sector metadata for tests and future thesis/report integration.
- Added `ContentSurfaceTwooterPreviewTest` with fixed-seed hash `2185776077`; the test covers company, sector, and macro generated-Twooter scopes, account voice variation, confidence-label variation, authored-post coexistence, and public/private leak checks.
- Updated `TwooterNetworkProgressionTest` to seed the legacy `network_source_followup` branch explicitly before auditing its progression, matching the current relationship-stage routing model without changing gameplay behavior.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/ContentSurfaceTwooterPreviewTest.tscn` -> `CONTENT_SURFACE_TWOOTER_PREVIEW_OK {"account_voice_count":4,"authored_post_count":8,"confidence_label_count":4,"day_index":28,"generated_post_count":8,"hash":"2185776077","issue_count":0,"issues":[],"scope_counts":{"company":4,"macro":1,"sector":3},"seed":20260622}`
  - Twooter regression scenes passed: `TwooterDialogReachabilityTest`, `TwooterRoutingRulesTest`, `TwooterNetworkLoopTest`, `TwooterNetworkProgressionTest`, `TwooterOutcomeConsequencesTest`, `TwooterMessageCooldownTest`, and `TwooterFallbackDialogTest`.
- Next roadmap step at the time was Content Surface Generation Task 4; that work is now complete below.

### 2026-06-22 - Content Surface Generation Task 4 complete

- Added generated private Network clue integration in `ContactNetworkSystem.request_tip`.
- Network tip requests now prefer eligible active dossier `private_clues` with `surface_id = "network"` and `visibility = "private"` before falling back to the existing corporate-action/contact-arc tip flow.
- Generated Network tips enforce clue reveal windows, recognition minimums, relationship-stage requirements, and source/contact quality before exposing stronger directness.
- Trusted-stage contacts can receive high-detail private reads, while `specific` directness stays gated to inner-level relationship/recognition/source quality.
- Generated Network tip results and tip journal rows preserve source-system, story, fact, clue, company, sector, visibility, reliability, leak-risk, source-quality, and directness metadata.
- Added `ContentSurfaceNetworkPrivateClueTest` with fixed-seed hash `160102873`; the fixture upgrades one real generated private clue to `specific` in test state so trusted downgrade and inner-level specific directness are both covered deterministically.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/ContentSurfaceNetworkPrivateClueTest.tscn` -> `CONTENT_SURFACE_NETWORK_PRIVATE_CLUE_OK {"company_id":"kelola_mart_sentosa","day_index":75,"hash":"160102873","inner_confidence":"High conviction","inner_directness":"specific","inner_journal_generated":true,"issue_count":0,"issues":[],"seed":20260622,"story_id":"story|kelola_mart_sentosa|capex_expansion|1676237476","trusted_confidence":"Early but credible","trusted_directness":"high","trusted_journal_generated":true}`
  - Network regression scenes passed: `NetworkThirtyDayScenarioTest`, `NetworkHighRecognitionScenarioTest`, and `NetworkInnerCircleProgressionAuditTest`.
- Next roadmap step at the time was Content Surface Generation Task 5; that work is now complete below.

### 2026-06-22 - Content Surface Generation Task 5 complete

- Added generated-surface thesis evidence preservation through `ThesisEvidenceCaptureSystem`, `ThesisManager`, and `RunState`.
- Generated News and Twooter capture payloads now forward provenance metadata from visible generated items into Research Tray evidence.
- Network journal snapshot rows now preserve generated Network tip provenance from saved tip rows.
- Annual filing capture metadata now marks filing excerpts as generated surface evidence and aliases existing `fact_ids` / `clue_ids` into the shared `source_fact_ids` / `source_clue_ids` contract.
- Added `ContentSurfaceThesisEvidenceCaptureTest` with fixed-seed hash `650364612`; it captures generated News, Twooter, Network, and filing evidence for `kelola_mart_sentosa`, attaches all four to a thesis, generates a thesis report, and verifies save/load preservation.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/ContentSurfaceThesisEvidenceCaptureTest.tscn` -> `CONTENT_SURFACE_THESIS_EVIDENCE_CAPTURE_OK {"capture_count":4,"company_id":"kelola_mart_sentosa","hash":"650364612","issue_count":0,"issues":[],"saved_attached_count":4,"seed":20260622,"story_id":"story|kelola_mart_sentosa|capex_expansion|1676237476"}`
  - Content surface preview/private-clue tests passed with unchanged hashes: News `219414638`, Twooter `2185776077`, Network `160102873`.
  - Thesis and filing regressions passed: `ThesisResearchTrayTest`, `ThesisFingerprintTest`, `AnnualReportFidelityCaptureTest`, and `FinancialStatementLayerThesisCaptureTest`.
- Next roadmap step at the time was Content Surface Generation Task 6; that work is now complete below.

### 2026-06-22 - Content Surface Generation Task 6 complete

- Added `ContentSurfaceConsistencyReachabilityTest` as the fixed-seed consistency and reachability guard for generated content surfaces.
- The guard builds one catalog-backed fixed-seed story with generated News, Twooter, Network, annual filing, and thesis-capture paths.
- It verifies generated-item traceability, public/private visibility boundaries, public leak-risk rules, hidden-token safety, direct-trade-instruction safety, private Network clue paths, filing visibility, and important fact/clue reachability.
- Locked fixed-seed hash `2369856367` for `kelola_mart_sentosa` story `story|kelola_mart_sentosa|capex_expansion|1676237476`.
- Content Surface Generation is now complete through Task 6.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/ContentSurfaceConsistencyReachabilityTest.tscn` -> `CONTENT_SURFACE_CONSISTENCY_REACHABILITY_OK {"company_id":"kelola_mart_sentosa","hash":"2369856367","important_clue_count":4,"important_fact_count":4,"issue_count":0,"issues":[],"seed":20260622,"story_id":"story|kelola_mart_sentosa|capex_expansion|1676237476","surface_count":4,"thesis_capture_count":4}`
  - Content surface preview/private-clue/thesis-capture tests passed with unchanged hashes: News `219414638`, Twooter `2185776077`, Network `160102873`, Thesis Capture `650364612`.
  - Quick smoke passed: `SMOKE_QUICK_OK normal_equity=94765318.11 days=3`.
  - Headless editor load and `git diff --check` passed.
- Next roadmap step is Company Relationship Graph.

### 2026-06-22 - Company Relationship Graph Task 1 complete

- Added the relationship graph contract to [Company Relationship Graph](COMPANY_RELATIONSHIP_GRAPH_ENHANCEMENT.md).
- The contract locks edge direction as “source company's role relative to target company.”
- Defined the first approved edge vocabulary: `supplier`, `customer`, `competitor`, `partner`, `parent`, `subsidiary`, `acquirer_candidate`, and `target_candidate`.
- Clarified that catalog `relationship_hooks` are intent hints, not concrete graph edges; Task 2 should resolve them into run-specific edges only when both endpoints exist in the selected roster.
- Defined normalized edge fields, sector/subsector constraints, public/private visibility rules, density/event-safety defaults, and the M&A deferral boundary.
- No runtime code, data, save, price, or UI behavior changed.
- Verification:
  - Design review completed in the feature doc.
  - `git diff --check` -> passed.
- Next roadmap step is Company Relationship Graph Task 2: deterministic graph generation and fixed-seed graph fingerprint.

### 2026-06-22 - Company Relationship Graph Task 2 complete

- Added `CompanyRelationshipGraphSystem` as the deterministic selected-roster graph generator.
- New runs now seed `company_relationship_graph_state` after company selection and before story dossier generation.
- The graph state is behavior-neutral for this task: it does not affect prices, events, content, or UI yet.
- Task 2 resolves catalog `relationship_hooks` into concrete run-specific supplier/customer/partner edges, adds capped same-sector generated competitor edges, validates endpoints, dedupes canonical relationships, and stores company edge lookups.
- Added RunState save/load normalization and read-only accessors for graph state and per-company edge rows.
- Added `CompanyRelationshipGraphFingerprintTest` with fixed-seed hash `2129898825`.
- Current fixed-seed summary: `46` edges across all `30` selected companies; type counts are `competitor=10`, `customer=8`, `partner=16`, `supplier=12`.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/CompanyRelationshipGraphFingerprintTest.tscn` -> `COMPANY_RELATIONSHIP_GRAPH_FINGERPRINT_OK {"company_with_edges_count":30,"counts_by_origin":{"catalog_hook":36,"generated_runtime":10},"counts_by_type":{"competitor":10,"customer":8,"partner":16,"supplier":12},"counts_by_visibility":{"private":10,"public":8,"semi_public":28},"edge_count":46,"first_edge_id":"edge|20260622|armada_kurir_nusantara|pasar_digital_prima|supplier|00","hash":"2129898825","issue_count":0,"issues":[],"last_edge_id":"edge|20260622|wisata_kuliner_nusantara|rel_kargo_nusantara|partner|35","max_incident_edges":5,"private_edge_count":10,"public_edge_count":8,"roster_size":30,"save_load_edge_count":46,"save_load_hash_mismatch":0,"seed":20260622,"unresolved_hook_count":8}`
  - Company universe selection fingerprint passed with unchanged hash `1682964508`.
  - Company universe roster bridge and catalog validation tests passed.
  - Quick smoke passed: `SMOKE_QUICK_OK normal_equity=94765318.11 days=3`.
- Next roadmap step is Company Relationship Graph Task 3: bounded partnership and supply-chain events from graph edges. That work is now complete below.

### 2026-06-22 - Company Relationship Graph Task 3 complete

- Added relationship event resolution to `CompanyRelationshipGraphSystem`.
- Relationship graph events are low-frequency by default, can emit one selected edge per day, and update `event_cooldown_until_day` on the triggering edge.
- Supported first event kinds:
  - `partnership_announcement`
  - `supply_deal`
  - `customer_win`
  - `competitor_pressure`
- Each event emits two company-scoped rows with bounded `sentiment_shift`, active-event metadata, counterparty ids, shared `relationship_event_id`, and source `company_relationship_graph`.
- Wired relationship events through `MarketSimulator` so they affect daily event context, broker/volume pressure, and price formation for both affected companies.
- Wired `RunState` to record relationship graph events in event history and save/load the updated graph cooldown state.
- Added a temporary generic News/Twooter family guard so `company_relationship_graph` history rows did not become public content before Task 4 defined relationship content hooks. Task 4 replaced this with relationship-specific generated content.
- Added `CompanyRelationshipEventImpactTest`.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/CompanyRelationshipEventImpactTest.tscn` -> `COMPANY_RELATIONSHIP_EVENT_IMPACT_OK {"edge_id":"edge|20260622|asuransi_nusa|hotel_resort_sentosa|partner|01","relationship_type":"partner","source_company_id":"asuransi_nusa","target_company_id":"hotel_resort_sentosa"}`
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/CompanyRelationshipGraphFingerprintTest.tscn` -> unchanged hash `2129898825`
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/CompanyUniverseSelectionFingerprintTest.tscn` -> unchanged hash `1682964508`
  - `/Users/user/.local/bin/godot --headless -e --quit` -> passed
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11 days=3`
- Next roadmap step at the time was Company Relationship Graph Task 4; that work is now complete below.

### 2026-06-22 - Company Relationship Graph Task 4 complete

- Added relationship-specific content hooks for `company_relationship_graph` event-history rows.
- News now emits generated relationship articles for public/semi-public relationship events with relationship event/edge provenance.
- Twooter now emits generated relationship chatter posts for public/semi-public relationship events.
- Contact Network now emits gated relationship reads for semi-public/private relationship events when a suitable contact is asked for a tip.
- Relationship-generated News, Twooter, and Network rows preserve generated content metadata through thesis capture.
- Added `CompanyRelationshipContentHooksTest` for the forced semi-public partnership scenario.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/CompanyRelationshipContentHooksTest.tscn` -> `COMPANY_RELATIONSHIP_CONTENT_HOOKS_OK ...`
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/CompanyRelationshipEventImpactTest.tscn` -> passed
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/ContentSurfaceThesisEvidenceCaptureTest.tscn` -> unchanged hash `650364612`
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/CompanyRelationshipGraphFingerprintTest.tscn` -> unchanged hash `2129898825`
- Next roadmap step at the time was Company Relationship Graph Task 5; that work is now complete below.

### 2026-06-22 - Company Relationship Graph Task 5 complete

- Added the M&A and replacement-slot design contract to [Company Relationship Graph](COMPANY_RELATIONSHIP_GRAPH_ENHANCEMENT.md).
- Confirmed the existing `strategic_merger_acquisition` cash-out path is the approved first baseline for target share treatment.
- Deferred stock-swap and statutory merger behavior until lifecycle registry, transaction-log, save migration, and portfolio conversion tests exist.
- Defined acquired-company archival rules:
  - keep company ids immutable
  - preserve price history, event history, thesis evidence, filing excerpts, and research references
  - mark acquired targets as trade-disabled instead of deleting company state
- Defined replacement-slot rules:
  - replacement is optional
  - replacement selection must be deterministic and catalog-backed
  - replacements must get new ids/tickers and must not inherit target holdings, charts, filings, thesis evidence, or relationship edges
- No runtime code, data, save, price, or UI behavior changed by this task.
- Verification:
  - design review completed in the feature doc
  - `git diff --check` -> passed
- Next roadmap step at the time was Company Relationship Graph Task 6; that work is now complete below.

### 2026-06-22 - Company Relationship Graph Task 6 complete

- Added `CompanyRelationshipGraphRegressionTest` as the broad regression guard for the relationship graph.
- The test covers graph state/schema validation, endpoint integrity, canonical duplicate protection, count summaries, density caps, company edge buckets, RunState accessors, event rows for all event-eligible relationship types, private-edge suppression/override behavior, and fixture-only M&A candidate non-execution.
- Existing relationship graph tests still pass:
  - graph fingerprint hash `2129898825`
  - forced event impact
  - generated News/Twooter/Network content hooks and thesis capture
- Company Relationship Graph enhancement is complete.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/CompanyRelationshipGraphRegressionTest.tscn` -> `COMPANY_RELATIONSHIP_GRAPH_REGRESSION_OK {"edge_count":46,"event_types_checked":4,"mna_fixture_checked":true,"private_guard_checked":true,"seed":20260622}`
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/CompanyRelationshipGraphFingerprintTest.tscn` -> unchanged hash `2129898825`
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/CompanyRelationshipEventImpactTest.tscn` -> passed
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/CompanyRelationshipContentHooksTest.tscn` -> passed
- Next roadmap step is Top-Down Research Surface Integration, unless M&A runtime expansion is split into a separate lifecycle/archival enhancement first.

### 2026-06-22 - Top-Down Research Surface Integration pivot approved

- Reframed the old standalone Top-Down Research UI plan as [Top-Down Research Surface Integration](TOP_DOWN_RESEARCH_UI_ENHANCEMENT.md).
- Confirmed the existing loop should remain primary:
  - search existing surfaces
  - capture to Research Tray
  - create thesis
  - attach evidence
  - write conclusion
- New direction:
  - improve existing News, Markets/company detail, filing, Research Tray, and Thesis flows
  - make News free and topic-based instead of tiered
  - keep News to level-1 public information
  - use Twooter, Network, filings, company pages, and Thesis for deeper evidence
- No runtime code, data, save, price, or UI behavior changed by this planning pivot.
- Verification:
  - design review completed in the feature doc
  - `git diff --check` -> passed

### 2026-06-22 - Top-Down Research Surface Integration Task 1 complete

- Inventoried the current News, Markets/company detail, filing, Research Tray, and Thesis paths.
- Confirmed News still carries tier assumptions through outlet `intel_level`, `prototype_default_intel_level`, unlocked outlet state, generated article routing, GameManager cache/count paths, and life-development clarity.
- Locked the Task 2 direction:
  - no standalone top-down research app
  - all four News outlets should be free visible topic lanes
  - News defaults to public level-1 discovery
  - deeper evidence remains in Twooter, Network, annual filings, company pages, Research Tray, and Thesis
- No runtime code, data, save, price, or UI behavior changed by this documentation/inventory task.

### 2026-06-22 - Top-Down Research Surface Integration Task 2 complete

- Converted News from tiered access to free topic/coverage lanes.
- Visible outlet map is now:
  - Harian Investor for market wrap, public movers, and chatter
  - The Egonomist for macro, commodity, policy, and sector context
  - IDK Channel for corporate action, filing, meeting, earnings, and index-review coverage
  - MarketSnitch for early signals, rumors, and ambiguous watchlist items
- `NewsFeedSystem` now normalizes all outlets as unlocked, routes articles by `coverage_type`, and adds `public_depth_level`, `topic_ids`, reliability, specificity, noise, and structured article section fields.
- Generated dossier News preserves source company/sector/commodity provenance and no longer uses `required_intel_level` routing.
- The paid `news_content` upgrade track was removed from shop data and `RunState.UPGRADE_TRACK_IDS`; the remaining news-intel accessor returns compatibility level `1`.
- `ContentSurfaceNewsPreviewTest` now guards the new free/topic News contract with fingerprint `236925374`.
- Broad `SmokeTest` assertions were updated so policy News validates macro coverage routing and upgrade-confirmation coverage uses the remaining paid upgrade tracks.
- Verification passed:
  - JSON validation for News and upgrade data
  - `git diff --check`
  - direct trailing-whitespace scan on touched files
  - `ContentSurfaceNewsPreviewTest.tscn` with `issue_count=0`
  - `SmokeTest.tscn -- --smoke-quick --smoke-local-io` with `SMOKE_QUICK_OK`
  - `godot --headless -e --quit`

### 2026-06-22 - Top-Down Research Surface Integration Task 3 complete

- Added count-aware topic filters inside the existing News surface:
  - All
  - Market
  - Macro
  - Commodities
  - Sector
  - Corporate
  - Rumor
- News archive summaries now persist level-1 public metadata and hidden provenance for filtering, Research Tray capture, and thesis evidence.
- Generated News visible copy is guarded against private Network, buried filing, and system-only wording; unsafe visible text falls back to neutral public copy.
- The targeted News preview test now validates the archive/filter contract after recording a live snapshot.
- Verification passed:
  - `ContentSurfaceNewsPreviewTest.tscn` with fingerprint `236925374`, `issue_count=0`
  - `ContentSurfaceConsistencyReachabilityTest.tscn` with hash `2369856367`, `issue_count=0`
  - `godot --headless -e --quit`
  - `SmokeTest.tscn -- --smoke-quick --smoke-local-io` with `SMOKE_QUICK_OK`
  - `git diff --check`
  - direct trailing-whitespace scan on touched files

### 2026-06-22 - Top-Down Research Surface Integration Task 4 complete

- Added compact top-down links inside the existing STOCKBOT company Profile tab instead of creating a new app.
- Profile rows now connect the selected company to:
  - commodity/macro context
  - sector peers
  - active story context
  - public relationship counterparties
  - the existing annual filing reader
- Commodity, story, and public relationship rows can capture evidence into the Research Tray.
- Peer and counterparty buttons reuse the existing STOCKBOT company selection workflow.
- The filing button opens the existing consolidated annual statement reader.
- Verification passed:
  - `godot --headless -e --quit`
  - `SmokeTest.tscn -- --smoke-quick --smoke-local-io` with `SMOKE_QUICK_OK`

### 2026-06-22 - Top-Down Research Surface Integration Task 5 complete

- Added normalized provenance metadata across Research Tray and Thesis evidence:
  - `provenance_group`
  - `provenance_label`
  - `provenance_path`
  - `provenance_tags`
- Covered macro, commodity, sector, company, filing, relationship, network, social, news, broker-flow, and market/price evidence paths.
- `ThesisManager.get_research_tray_snapshot(...)` now returns `provenance_groups` for grouping/filter UI.
- Research Tray and attached thesis cards now show compact source paths without changing thesis scoring vocabulary.
- Save/load normalization preserves provenance, relationship edge/counterparty fields, and source commodity arrays.
- Verification passed:
  - `godot --headless -e --quit`
  - `ThesisResearchTrayTest.tscn` with `THESIS_RESEARCH_TRAY_OK`
  - `ContentSurfaceThesisEvidenceCaptureTest.tscn` with fingerprint `650364612`
  - `git diff --check`
  - direct trailing-whitespace scan on touched files

### 2026-06-22 - Top-Down Research Surface Integration Task 6 complete

- Added `TopDownResearchSurfaceIntegrationTest` as the focused fixed-seed cross-surface smoke.
- The smoke covers:
  - free News outlet coverage metadata
  - live News topic/filter buckets
  - News article capture to Research Tray
  - Profile top-down payload capture
  - annual filing document generation/access
  - annual filing evidence capture
  - Thesis attachment/report generation
  - Research Tray provenance grouping
  - integrated thesis evidence save/load
- Fixed a late-injected property-development News article metadata gap by adding public level-1 News metadata in the life-development bridge.
- Added final feed-article metadata defaults in `NewsFeedSystem` for public depth, access model, coverage, and topic metadata.
- Top-Down Research Surface Integration is now complete through Task 6.
- Verification passed:
  - `TopDownResearchSurfaceIntegrationTest.tscn` with `TOP_DOWN_RESEARCH_SURFACE_INTEGRATION_OK`
  - `ContentSurfaceNewsPreviewTest.tscn` with fingerprint `236925374`
  - `ThesisResearchTrayTest.tscn` with `THESIS_RESEARCH_TRAY_OK`
  - `SmokeTest.tscn -- --smoke-quick --smoke-local-io` with `SMOKE_QUICK_OK`
  - `godot --headless -e --quit`
  - `git diff --check`
  - direct trailing-whitespace scan on touched files

### 2026-06-22 - Top-Down Research Surface Integration Revision 1 complete

- Hid the compact STOCKBOT company Profile `Top-Down Links` card after review.
- Reason: the card felt too explicit and evidence-card-like, duplicating research work that should happen through News, company profile reading, filings, Research Tray, and Thesis.
- The dormant profile-link helpers remain behind `SHOW_PROFILE_TOP_DOWN_LINKS := false` in `scripts/ui/controllers/StockController.gd`.
- Filing access remains through the existing `View Consolidated Financial Statement` button.

### 2026-06-22 - Company Universe Catalog Task 6 complete

- Enabled company universe catalog selection as the default run roster path.
- Default difficulty presets now include `use_company_universe_catalog = true`:
  - `chill`
  - `normal`
  - `grind`
- `RunState.DEFAULT_DIFFICULTY_CONFIG` now also carries the catalog default for fallback/default save paths.
- The procedural generator remains available with explicit `use_company_universe_catalog = false`.
- Updated tests so:
  - default roster asserts `company_source = universe_catalog`
  - explicit procedural fallback remains covered by `CompanyGenerationFingerprintTest`
  - catalog selection fingerprint remains the stable top-down roster baseline
- Added a visible annual filing compatibility fix so catalog-backed default companies still expose `segment_row` capture from the annual filing reader even before a story-derived segment footprint exists.
- Verification passed:
  - company universe catalog JSON validation
  - `CompanyUniverseCatalogValidationTest.tscn`
  - `CompanyUniverseRosterBridgeTest.tscn`
  - `CompanyUniverseSelectionFingerprintTest.tscn` with hash `1682964508`
  - `CompanyGenerationFingerprintTest.tscn` with explicit procedural hash `1225696160`
  - `AnnualFilingVisibleGenerationTest.tscn` with updated hash `1665441399`
  - `SmokeTest.tscn -- --smoke-quick --smoke-local-io` with `SMOKE_QUICK_OK normal_equity=95485619.77 days=3`

### 2026-06-24 - Company Universe Catalog follow-up expansion to 100 complete

- Expanded the company universe catalog from 70 to 100 companies.
- Added 30 companies across consumer, noncyclical, energy, basic industry, industrial, tech, infrastructure, transport, health, finance, and property.
- Current catalog sector counts are `basicindustry=12`, `consumer=9`, `energy=9`, `finance=16`, `health=7`, `industrial=8`, `infra=7`, `noncyclical=8`, `property=8`, `tech=9`, and `transport=7`.
- Updated the deterministic catalog selection baseline to hash `1266026255`, first selection `armada_kurir_nusantara` / `AKRN`, and last selection `asuransi_nusa` / `ASNS`.
- Verification passed:
  - JSON parse validation for `data/companies/company_universe_catalog.json`
  - `CompanyUniverseCatalogValidationTest.tscn`
  - `CompanyUniverseRosterBridgeTest.tscn`
  - `CompanyUniverseSelectionFingerprintTest.tscn`

### 2026-06-24 - Annual Filing Story Discovery Task 1 complete

- Added the annual filing story-note fact contract and taxonomy.
- Contract now exposes deterministic helpers for required fields, story types, note containers, profile/type allowlists, fact normalization, fact validation, and schema summary/hash.
- Locked contract values:
  - schema hash `1214903292`
  - 11 story types
  - 11 note containers
  - test payload hash `1287721463`
- Added `AnnualFilingStoryNoteContractTest`.
- No visible filing prose, UI layout, cache behavior, or reader output changed in this task.

### 2026-06-24 - Annual Filing Story Discovery Task 2 complete

- Added deterministic annual filing story fact packet generation.
- New packet helpers in `AnnualFilingDocument.gd`:
  - `build_story_note_fact_packets(...)`
  - `validate_story_note_fact_packet_set(...)`
  - `story_note_fact_packet_hash(...)`
  - `story_note_fact_packet_summary(...)`
- Supported packet inputs:
  - Company Story Dossier disclosure packets
  - Company Relationship Graph edges/events
  - annual statement notes
  - living company arcs
  - corporate action events
  - roadmap milestones/event rows
  - bounded company-universe metadata fallbacks
- Added `AnnualFilingStoryFactPacketTest`.
- Locked fixed-seed packet hash `1089345055` across 4 samples and 32 packets.
- No visible filing prose, reader layout, UI behavior, or cache behavior changed in this task.

### 2026-06-24 - Annual Filing Story Discovery Tasks 3-8 complete

- Completed the rest of the Annual Filing Story Discovery plan.
- Tasks 3-4:
  - added filing-style story-note prose renderers
  - added deterministic cross-note clue placement
  - locked `ANNUAL_FILING_STORY_NOTE_RENDERER_OK` hash `487832935`
- Task 5:
  - rebalanced visible filings around compact statements plus story-bearing notes
  - kept the bank reader table-heavy while removing generic filler and visible Bahasa/localized note titles
  - locked `ANNUAL_FILING_BANK_READER_UI_SMOKE_OK` hash `2022638696`
- Task 6:
  - preserved annual filing capture metadata through Research Tray, thesis attach, direct thesis add, save/load, and dedupe
  - added hidden `story_note_fact_id` / `source_story_note_fact_ids` preservation for story-bearing note paragraphs
  - verified story-note fact packet cache invalidation in `AnnualFilingLazyContractTest`
- Task 7:
  - strengthened story-note realism assertions around counterparties, date/currency terms, obligations, segment context, no repeated paragraphs, and no recommendation language
  - reconfirmed `ANNUAL_FILING_STORY_FACT_PACKET_OK`, `ANNUAL_FILING_STORY_NOTE_RENDERER_OK`, and `ANNUAL_FILING_SECTOR_REALISM_REGRESSION_OK`
- Task 8:
  - ran `FullYearPlayerScenarioTest` for 225 trading days
  - sentinel `FULL_YEAR_PLAYER_SCENARIO_OK`
  - elapsed `326372.13ms`
  - annual filing profile `bank`
  - story-note facts/prose `6 / 5`
  - capture types `statement_row`, `note_table_row`, `note_paragraph`
  - final thesis report succeeded
  - log written to `docs/development/test_log/2026-06-24_annual_filing_sector_realism_full_year.md`
