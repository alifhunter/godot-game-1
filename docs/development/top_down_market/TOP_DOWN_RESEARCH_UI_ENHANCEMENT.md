# Top-Down Research Surface Integration Enhancement - Plan & Progress Log

This plan replaces the earlier dedicated top-down research UI idea. The project already has the right player loop: players search for information across News, Twooter, Network, Markets, company pages, and filings; add useful items to the Research Tray; then build a thesis and conclusion from that evidence.
**Status: complete - Tasks 1-6 complete.** Designed to run in a fresh session; everything needed to execute cold is in this file.

**Review verdict recap:** Do not build a separate top-down research app yet. Improve the existing research surfaces so players can naturally move from macro/commodity/sector signals into companies, filings, and thesis evidence without being spoon-fed. News should become a free, topic-based, public level-1 discovery surface instead of a tiered access system.

## Where everything lives

| What | Where |
|---|---|
| Existing app/UI surfaces | `scripts/ui/`, company widgets, thesis board widgets |
| News data and generation | `systems/NewsFeedSystem.gd`, `data/news/news_feed_data.json` |
| Social surface | `systems/TwooterFeedSystem.gd`, `systems/TwooterInteractionSystem.gd`, `data/social/twooter_feed_data.json` |
| Network surface | `systems/ContactNetworkSystem.gd`, `systems/NetworkJournalBuilder.gd`, `data/network/contact_network_data.json` |
| Markets/company surface | stock/company controllers and widgets under `scripts/ui/` |
| Macro and commodity input | `systems/MacroStateSystem.gd`, `systems/CommodityMacroContract.gd`, `data/macro/commodity_indicator_catalog.json` |
| Story and relationship input | `systems/CompanyStoryDossierSystem.gd`, `systems/CompanyRelationshipGraphSystem.gd` |
| Filing verification | `systems/AnnualFilingDocument.gd`, `systems/AnnualStatementBuilder.gd`, `systems/FinancialStatementLayer.gd` |
| Thesis capture | `systems/ThesisManager.gd`, `systems/ThesisEvidenceCaptureSystem.gd`, `scripts/ui/widgets/ThesisBoardWidget.gd` |
| Tests/probes | Targeted News/Markets/Thesis smoke and existing content-surface tests |

## Goals

- Preserve the current player research loop instead of replacing it.
- Convert News from tiered outlets into free topic-based public coverage.
- Make News broad and varied, but only surface-level.
- Make deeper evidence come from Twooter, Network, annual filings, company details, and thesis assembly.
- Improve existing surfaces so top-down paths are discoverable:
  - macro/commodity to sector
  - sector to company
  - company to story
  - story to filing evidence
  - evidence to thesis

## Non-goals

- Do not build a new standalone top-down research app in this pass.
- Do not make News provide high-confidence private information.
- Do not reintroduce news paywalls or tiered outlet access.
- Do not replace Research Tray or Thesis creation.
- Do not make a guided dashboard that tells players exactly what to buy.

## Working rules

- News should point to possible stories, not solve them.
- All News outlets should be free to read.
- News outlets differ by topic, tone, reliability, noise, and specificity, not by access tier.
- News should generally provide level-1 public information:
  - broad driver
  - affected sector/company
  - surface-level event or rumor
  - no full private thesis
  - no explicit trade instruction
- Deeper information should come from:
  - Twooter for chatter, sentiment, and weak social signals
  - Network for relationship-gated private context
  - annual filings for buried verification details
  - Markets/company pages for comparison and price/financial context
  - Thesis for the player’s own reasoning

## News Surface Direction

News should be organized by four free outlets with clear topic coverage and tone. Keep the existing internal outlet ids for migration safety, but change the visible outlet names and coverage model.

### Four-Outlet Model

| Current internal id | New visible outlet name | Coverage group | Tone | Expected depth |
|---|---|---|---|---|
| `gorengan_daily` | Harian Investor | Market wrap, daily movers, retail chatter, public crowd attention, broad sentiment. | Fast, simple, a little dramatic. | Level 1 only. |
| `waduh_finance` | The Egonomist | Macro, policy, commodities, sector/subsector pressure, top-down driver context. | Broad, contextual, analytical. | Level 1 only. |
| `harian_investor` | IDK Channel | Corporate actions, public RUPS/RUPSLB, tender offers, acquisitions, rights issues, dividends, earnings and filing summaries. | Formal, factual, public-disclosure focused. | Level 1 public facts and public rumors only. |
| `ordal_news` | MarketSnitch | Early signals, rumors, ambiguous market whispers, soft setup hints. | Cautious, indirect, noisy, never fully certain. | Level 1, often ambiguous. |

### Topic Groups

| Topic group | Primary outlet | Secondary outlet options |
|---|---|---|
| Market wrap / public movers | Harian Investor | MarketSnitch for early noisy attention. |
| Retail chatter / crowd mood | Harian Investor | MarketSnitch for rumor-shaped chatter. |
| Macro / policy | The Egonomist | IDK Channel when the policy appears through formal disclosure. |
| Commodities | The Egonomist | Harian Investor when the commodity move becomes a daily market driver. |
| Sector / subsector pressure | The Egonomist | Harian Investor for broad market reaction. |
| Corporate action | IDK Channel | MarketSnitch before formal disclosure. |
| Earnings / filing summary | IDK Channel | The Egonomist for sector-level readthrough. |
| Rumor / early signal | MarketSnitch | Harian Investor when public chatter broadens. |

### Metadata Model

News rows and outlet definitions should move toward these fields:

| Field | Purpose |
|---|---|
| `topic_ids` | Macro, commodity, sector, corporate_action, filing, rumor, market_wrap, etc. |
| `coverage_type` | The outlet/content lane, e.g. `market_wrap_chatter`, `macro_commodity_sector`, `corporate_action_filing`, or `early_signal`. |
| `public_depth_level` | Should default to `1` for News. |
| `reliability` | Approximate signal quality. Low reliability can still be free and visible. |
| `specificity` | How direct the row is: macro, sector, subsector, company, event. |
| `noise_level` | How much ambiguity or speculation the row carries. |
| `source_system_id` | Existing provenance source such as dossier, relationship graph, event system, macro, commodity. |
| `source_fact_ids` / `source_clue_ids` | Preserve traceability for Research Tray and Thesis. |

### Public Depth Rule

News should rarely reveal level-2 or level-3 evidence. If a generated fact has deeper detail:

- News may mention the surface event.
- News should not reveal private relationship context.
- News should not reveal buried filing conclusions directly.
- News should push the player toward:
  - the relevant company page
  - related filings
  - Twooter chatter
  - Network follow-up
  - thesis capture

### Article Structure

Generated News should read like natural articles written by a fictional financial outlet, not like evidence cards or system summaries. The structure should be consistent enough for tests and thesis capture, but the visible copy should feel human, varied, and lightly imperfect.

| Section | Purpose | Visible style |
|---|---|---|
| Headline | Gives the public hook. | Natural and specific, but not a conclusion or trade instruction. |
| Deck / subheadline | Adds one sentence of context. | Plain-language summary of why the story is on screen. |
| Byline / outlet / timestamp | Grounds the item in a publication voice. | Use the outlet name, author when available, and in-game time/date. |
| Lead paragraph | States what happened or what changed. | One human-readable opening paragraph, not a bullet list. |
| Context paragraph | Explains the wider driver. | Macro, commodity, sector, company, or corporate-action readthrough depending on outlet. |
| Market reaction paragraph | Shows how the market is reacting. | Price, volume, flow, breadth, attention, or trader mood without over-explaining. |
| Readthrough paragraph | Points to related companies/sectors. | Mentions possible affected groups without revealing private conclusions. |
| What to watch | Gives the next public thing to monitor. | Public next step, not advice: filing, meeting, commodity move, follow-up disclosure, next session. |
| Related metadata | Keeps capture and filtering traceable. | Hidden/test metadata only: topic ids, source facts, clue ids, company ids, sector ids. |

### Natural Writing Rules

- Avoid visible labels like "evidence," "signal strength," "confidence," "relationship edge," or "source fact."
- Avoid article copy that sounds like a generated report template.
- Avoid directly telling the player to buy, sell, hold, or avoid.
- Vary sentence rhythm between outlets.
- Let articles contain uncertainty when the source is uncertain.
- Use short paragraphs. News should be readable quickly inside the game UI.
- Reuse the same underlying fact across outlets only when each outlet has a meaningfully different angle.
- Make the article useful as a breadcrumb, not as the full answer.

### Outlet Article Emphasis

| Outlet | First paragraph emphasis | Middle paragraph emphasis | Final paragraph emphasis |
|---|---|---|---|
| Harian Investor | What moved today and why traders noticed. | Crowd mood, market breadth, price/volume reaction. | Whether attention spreads or fades next session. |
| The Egonomist | The macro, commodity, or sector driver. | Which sectors/subsectors and business models are exposed. | What public data point could confirm the readthrough. |
| IDK Channel | The formal public event or disclosure. | Meeting, filing, corporate-action, earnings, or document context. | What official follow-up matters next. |
| MarketSnitch | The early whisper or soft signal. | Why the story is still uncertain and who might be watching. | What would make the rumor look more real or fade. |

### Article Data Shape

News articles should preserve a stable data shape even when visible copy varies:

| Field | Purpose |
|---|---|
| `headline` | Main visible headline. |
| `deck` | Short visible subheadline. |
| `body` | Full article copy, preferably paragraph-separated text. |
| `lead` | Optional first paragraph for UI previews. |
| `context` | Optional middle paragraph or context summary. |
| `market_reaction` | Optional market-reaction paragraph. |
| `what_to_watch` | Optional closing paragraph. |
| `topic_ids` | Filtering and grouping. |
| `coverage_type` | Outlet lane. |
| `public_depth_level` | Defaults to `1`. |
| `source_fact_ids` / `source_clue_ids` | Hidden provenance for Research Tray and Thesis. |
| `source_company_ids` / `source_sector_ids` / `source_commodity_ids` | Related entities for filtering and capture. |

## Existing-Surface Integration Direction

### News

- Add topic and coverage filters.
- Add better variety from the same underlying facts.
- Preserve Research Tray capture.
- Remove/pay down tier language from outlet access.
- Keep generated News public and surface-level.
- Keep the visible outlet count at four:
  - Harian Investor
  - The Egonomist
  - IDK Channel
  - MarketSnitch

### Markets / Company Detail

- Keep company detail focused on the existing company profile, financials, filings, corporate actions, and price context.
- Do not expose a consolidated `Top-Down Links` card in the company Profile tab. That panel felt too explicit and evidence-card-like.
- Top-down research should remain discoverable through:
  - News topic coverage
  - company profile/background
  - peer comparison and price/financial context
  - annual filing reader
  - Research Tray and Thesis evidence assembly
- Keep this as enhancement to the existing stock workflow, not a separate research app.

### Research Tray / Thesis

- Preserve and display better provenance:
  - macro
  - commodity
  - sector
  - company
  - filing
  - relationship
  - network
- Let players organize evidence from multiple surfaces into one thesis.
- The thesis remains where the player makes the conclusion.

## Task 1 Surface Inventory And Locked Contracts

Task 1 confirms the pivot is documentation-first and code-inventory-only. No runtime code, data, save format, price behavior, or UI behavior changed in this pass.

### Current Research Loop Inventory

| Surface | Current path | Notes for this enhancement |
|---|---|---|
| News feed | `scripts/ui/controllers/NewsController.gd` -> `GameManager.get_news_snapshot(...)` -> `systems/NewsFeedSystem.gd` -> `data/news/news_feed_data.json` | Existing News already supports outlet feeds, generated dossier news, relationship graph hooks, article detail, and right-click capture to Research Tray. |
| News capture | `NewsController._build_news_capture_payload(...)` -> `GameManager.capture_research_evidence(...)` -> `ThesisManager.capture_research_evidence(...)` | Capture already preserves generated surface metadata and source ids. This should be retained, but visible copy should become more article-like. |
| Markets / company detail | `scripts/ui/controllers/StockController.gd` and existing stock/company widgets | Company detail already has bottom-up research entry points, stock search, company profile, key stats, broker flow, corporate actions, and annual filing access. Task 4 should add top-down links here instead of creating a new app. |
| Annual filing | `StockController` financial statement report path, `systems/AnnualFilingDocument.gd`, `systems/AnnualStatementBuilder.gd`, `systems/FinancialStatementLayer.gd` | The button is already `View Consolidated Financial Statement`. Filing content is a deeper verification surface, not level-1 News content. |
| Research Tray | `GameManager.capture_research_evidence(...)`, `systems/ThesisManager.gd`, `systems/ThesisEvidenceCaptureSystem.gd` | The tray already dedupes evidence, preserves source metadata, autosaves, and groups evidence by company/context. |
| Thesis | `systems/ThesisManager.gd`, `systems/ThesisReportSystem.gd`, `scripts/ui/widgets/ThesisBoardWidget.gd` | Thesis creation, evidence attachment, interpretation labels, and report generation already exist. The integration work should improve provenance, not replace the flow. |

### Current Tier/Access Assumptions To Replace

| Area | Current assumption | Replacement direction |
|---|---|---|
| News feed data | `data/news/news_feed_data.json` still defines `prototype_default_intel_level` and per-outlet `intel_level`. | Keep internal outlet ids stable, but treat outlets as free topic lanes. Move toward `coverage_type`, `topic_ids`, and `public_depth_level`. |
| Snapshot building | `NewsFeedSystem.build_news_snapshot(...)` resolves `unlocked_intel_level` and sets `outlet["unlocked"]`. | Task 2 should make all four outlets visible and unlocked, while preserving compatibility fields until old callers are retired. |
| Generated News routing | Several builders still gate by outlet `intel_level`, including daily brief, hidden arc, special event progress, and generated dossier sources. | Replace access gating with topic/coverage routing and explicit public-depth filtering. |
| GameManager cache/counts | `GameManager.get_unlocked_news_intel_level()`, `_news_snapshot_cache_key(...)`, `_count_news_articles(...)`, and daily activity counts still depend on unlocked news level. | Keep APIs compatible at first, but stop using news level as an access lock. Cache keys should eventually use topic/content source state instead. |
| Life development news | Life-development article clarity currently derives from outlet/article `intel_level`. | Move clarity into story-specific public metadata such as `public_depth_level`, `specificity`, `reliability`, or a dedicated clarity field. |
| UI labels | `NewsController` mostly consumes outlets/feeds and does not need a new standalone research UI. | Add topic filters and article presentation inside the existing News surface. |

### Locked Public News Contract

- All four visible News outlets are free to read.
- News depth defaults to `public_depth_level = 1`.
- News may expose:
  - broad macro, commodity, market, sector, company, or corporate-action hooks
  - affected companies, sectors, subsectors, commodities, and public events
  - market reaction, volume, breadth, attention, and public follow-up items
- News should not expose:
  - private Network relationship context
  - buried filing conclusions directly
  - inner-circle source certainty
  - direct buy/sell/hold instructions
  - visible system labels such as `source_fact_id`, `clue_id`, or `confidence score`
- Deeper evidence belongs in:
  - Twooter for social chatter and weak public mood
  - Network for relationship-gated private context
  - annual filings for buried verification
  - Markets/company detail for comparison and price/financial context
  - Thesis for final reasoning and conclusion

### Compatibility Boundary For Task 2

- Keep internal outlet ids stable:
  - `gorengan_daily`
  - `waduh_finance`
  - `harian_investor`
  - `ordal_news`
- The old `intel_level` and `unlocked_intel_level` parameters may remain temporarily for save/UI compatibility.
- New behavior should make all outlets effectively unlocked.
- Generated articles should carry both user-facing article fields and hidden provenance fields.
- Existing Research Tray capture should continue to work for headlines, full articles, source leads, annual filing excerpts, company metrics, broker flow, corporate actions, and relationship/network evidence.

## Status

| # | Task | Est. cost | Status |
|---|---|---|---|
| 1 | Lock pivot and update surface contracts | ~10-20% | Complete |
| 2 | Replace tiered News model with topic/coverage model | ~20-35% | Complete |
| 3 | Add News topic filters and level-1 public-depth rules | ~20-35% | Complete |
| 4 | Add existing Markets/company detail top-down links | ~20-35% | Complete; superseded by Revision 1 hidden-card decision |
| 5 | Improve Research Tray/Thesis provenance grouping | ~15-30% | Complete |
| 6 | Add smoke/regression coverage for surface integration | ~15-25% | Complete |

Recommended batching: **All tasks are complete**. Future work should be tracked as a separate follow-up plan rather than expanding this integration plan.

## Progress log

### 2026-06-14 - Original plan created

- Created the first top-down research UI plan from the top-down market brainstorming session.
- Original direction was a dedicated macro-to-sector-to-company research UI.
- No code or data changes were made by that planning step.

### 2026-06-22 - Pivot approved

- Reframed this enhancement away from a standalone top-down research app.
- Confirmed the existing research loop should remain primary:
  - discover information
  - capture to Research Tray
  - build thesis
  - attach evidence
  - write conclusion
- New direction:
  - improve existing surfaces
  - make News free and topic-based
  - keep News as level-1 public information
  - use Twooter, Network, filings, company pages, and Thesis for deeper work
- No runtime code, data, save, price, or UI behavior changed by this pivot.

### 2026-06-22 - Four-outlet News naming direction added

- Locked the planned visible News outlet count at four.
- Planned visible outlet rename map:
  - `gorengan_daily` -> Harian Investor for market wrap/chatter
  - `waduh_finance` -> The Egonomist for macro, commodity, and sector context
  - `harian_investor` -> IDK Channel for corporate action, earnings, and filing summaries
  - `ordal_news` -> MarketSnitch for early signals and rumors
- Kept the implementation note that internal outlet ids should remain stable until a deliberate data migration is done.
- No runtime code, data, save, price, or UI behavior changed by this planning update.

### 2026-06-22 - Natural article structure added

- Added the generated News article structure contract.
- Planned article sections:
  - headline
  - deck/subheadline
  - byline/outlet/timestamp
  - lead paragraph
  - context paragraph
  - market reaction paragraph
  - readthrough paragraph
  - what-to-watch paragraph
  - hidden related metadata
- Added natural writing rules so generated articles feel like human outlet copy rather than evidence cards.
- Added outlet-specific article emphasis for Harian Investor, The Egonomist, IDK Channel, and MarketSnitch.
- No runtime code, data, save, price, or UI behavior changed by this planning update.

### 2026-06-22 - Task 1 complete

- Inventoried the existing News, Markets/company detail, filing, Research Tray, and Thesis paths.
- Confirmed News still contains tier/access assumptions through `prototype_default_intel_level`, outlet `intel_level`, snapshot unlock state, generated article routing, GameManager news cache/counts, and life-development clarity.
- Locked the new public News contract:
  - all four outlets are free
  - News defaults to `public_depth_level = 1`
  - News is a breadcrumb surface, not a private-evidence or trade-instruction surface
  - deeper evidence stays in Twooter, Network, annual filings, company pages, and Thesis
- Defined the Task 2 compatibility boundary: keep outlet ids stable, keep old level parameters temporarily if needed, but make all visible outlets effectively unlocked.
- No runtime code, data, save, price, or UI behavior changed by this task.
- Verification:
  - `git diff --check` -> passed for tracked changes
  - direct trailing-whitespace scan on this file and the roadmap -> no matches

### 2026-06-22 - Task 2 complete

- Replaced tiered News access with a free topic/coverage model.
- Updated `data/news/news_feed_data.json`:
  - `gorengan_daily` is now visible as Harian Investor for market wrap/chatter.
  - `waduh_finance` is now visible as The Egonomist for macro, commodity, policy, and sector coverage.
  - `harian_investor` is now visible as IDK Channel for corporate action, filing, meeting, earnings, and index-review coverage.
  - `ordal_news` is now visible as MarketSnitch for early signals, rumors, and ambiguous watchlist items.
  - all four outlets now carry `coverage_type`, `topic_ids`, `public_depth_level`, `reliability`, `specificity`, and `noise_level`.
- Updated `systems/NewsFeedSystem.gd`:
  - all outlets are normalized as unlocked free public outlets.
  - article routing now uses `coverage_type` instead of outlet unlock level.
  - generated dossier News is routed by company, sector, and macro surface type instead of `required_intel_level`.
  - generated articles now preserve `coverage_type`, `topic_ids`, `public_depth_level`, source company/sector/commodity ids, and structured article sections.
  - article records now expose `lead`, `context`, `market_reaction`, and `what_to_watch` while retaining the existing `body` field for UI compatibility.
- Removed the paid `news_content` upgrade track from `data/upgrades/upgrade_catalog.json`.
- Removed `news_content` from `RunState.UPGRADE_TRACK_IDS` so console maxing, save normalization, and progress counting do not keep a ghost News upgrade alive.
- Updated `GameManager.get_unlocked_news_intel_level()` to return the compatibility public level `1`.
- Extended `ContentSurfaceNewsPreviewTest` and the broad `SmokeTest` assertions to match the new free topic/coverage News contract.
- Compatibility note:
  - `intel_level` and `unlocked_intel_level` remain as compatibility fields/parameters for older call paths and cache keys.
  - They no longer gate visible News outlet access or generated dossier News routing.
- Verification:
  - JSON validation for `data/news/news_feed_data.json` and `data/upgrades/upgrade_catalog.json` -> passed.
  - `git diff --check` -> passed.
  - direct trailing-whitespace scan on touched files -> no matches.
  - `ContentSurfaceNewsPreviewTest.tscn` -> passed with fingerprint `236925374`, `issue_count=0`, generated surface counts `{company_news: 4, macro_news: 2, sector_news: 3}`.
  - `SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> passed with `SMOKE_QUICK_OK`.
  - `godot --headless -e --quit` -> passed.
  - Expected warning noise: Steam init is unavailable in headless local runs, and the broad smoke still prints known RID cleanup warnings on exit.

### 2026-06-22 - Task 3 complete

- Added count-aware topic/coverage filters to the existing News surface.
- Filter chips now support:
  - All
  - Market
  - Macro
  - Commodities
  - Sector
  - Corporate
  - Rumor
- The filters use `coverage_type`, `topic_ids`, and commodity ids from the article/archive metadata, so they work for both authored and generated News.
- Archive summaries now persist public metadata and hidden provenance needed by filtering, Research Tray capture, and thesis evidence:
  - `access_model`
  - `public_depth_level`
  - `coverage_type`
  - `topic_ids`
  - reliability/specificity/noise
  - generated surface/source ids
  - source fact, clue, company, sector, commodity, and event ids
- Generated News visible copy is clamped to the level-1 public contract. If article text contains private/system-only wording, the builder falls back to neutral public copy.
- The targeted News preview test now records a live snapshot into the archive and validates the archive/filter contract.
- Compatibility note:
  - public archive summaries keep the same headline/body/detail route used by the existing UI.
  - hidden provenance is present for filtering and capture, but visible article text should not reveal private Network, buried filing, or system labels.
- Verification:
  - `ContentSurfaceNewsPreviewTest.tscn` -> passed with fingerprint `236925374`, `issue_count=0`, and generated surface counts `{company_news: 4, macro_news: 2, sector_news: 3}`.
  - `ContentSurfaceConsistencyReachabilityTest.tscn` -> passed with hash `2369856367`, `issue_count=0`.
  - `godot --headless -e --quit` -> passed.
  - `SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> passed with `SMOKE_QUICK_OK`.
  - `git diff --check` -> passed.
  - direct trailing-whitespace scan on touched code, tests, and docs -> no matches.
  - Expected warning noise: Steam init is unavailable in headless local runs, the broad smoke still prints known RID cleanup warnings on exit, and the existing Twooter dialog warning about `network_stranger_source` option count is unrelated to this task.

### 2026-06-22 - Task 4 complete

- Added a compact `Top-Down Links` card to the existing STOCKBOT company Profile tab.
- The card keeps the bottom-up stock workflow intact and adds dense links for:
  - commodity/macro exposure
  - sector peers
  - active story context
  - public relationship counterparties
  - related annual filing
- Commodity and story rows can be captured directly to the Research Tray.
- Public relationship rows expose a capture action plus counterparty ticker buttons.
- Sector peer and counterparty buttons switch the existing STOCKBOT selection to that company instead of opening a new app.
- The related filing link opens the existing `View Consolidated Financial Statement` annual filing reader.
- The Profile refresh cache now includes story/relationship/day state so top-down rows repaint when live research state changes.
- Added quick-smoke coverage for the Profile card, row containment/order, and Profile-to-filing overlay path.
- Verification:
  - `godot --headless -e --quit` -> passed.
  - `SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> passed with `SMOKE_QUICK_OK`.
  - Expected warning noise: Steam init is unavailable in headless local runs, the broad smoke still prints known RID cleanup warnings on exit, and the existing Twooter dialog warning about `network_stranger_source` option count is unrelated to this task.

### 2026-06-22 - Task 5 complete

- Added normalized Research Tray/Thesis provenance metadata for captured evidence:
  - `provenance_group`
  - `provenance_label`
  - `provenance_path`
  - `provenance_tags`
- Covered macro, commodity, sector, company, filing, relationship, network, social, news, broker-flow, and market/price evidence paths.
- `ThesisManager.get_research_tray_snapshot(...)` now returns `provenance_groups` summary metadata for grouping/filter UI without changing the existing Research Tray flow.
- New captures store provenance directly; older saved tray rows are normalized on snapshot/attachment without requiring a save migration.
- Research Tray cards and attached thesis evidence cards now show the compact source path while keeping the existing thesis category and interpretation vocabulary intact.
- Save/load normalization now preserves provenance fields, relationship edge fields, counterparty fields, and `source_commodity_ids`.
- Extended `ThesisResearchTrayTest` to assert provenance through capture, duplicate capture, attachment, direct chart evidence, save/load, snapshot grouping, and thesis report generation.
- Verification:
  - `godot --headless -e --quit` -> passed.
  - `ThesisResearchTrayTest.tscn` -> passed with `THESIS_RESEARCH_TRAY_OK`.
  - `ContentSurfaceThesisEvidenceCaptureTest.tscn` -> passed with fingerprint `650364612`.
  - `git diff --check` -> passed.
  - direct trailing-whitespace scan on touched code/docs -> no matches.
  - Expected warning noise: Steam init is unavailable in headless local runs.

### 2026-06-22 - Task 6 complete

- Added `TopDownResearchSurfaceIntegrationTest` as the focused cross-surface regression gate.
- The test covers:
  - free News outlet coverage metadata
  - live News topic/filter buckets
  - News headline+article capture into Research Tray
  - existing company Profile top-down payload capture
  - annual filing document generation/access
  - annual filing evidence capture
  - Thesis attachment and report generation
  - Research Tray provenance grouping
  - save/load persistence for integrated thesis evidence
- Fixed a late-injected life-development News article metadata gap by adding public level-1 News metadata to the property-development article bridge.
- Added a final article metadata normalizer in `NewsFeedSystem` so feed article rows keep public depth, access model, coverage, and topic defaults.
- Verification:
  - `TopDownResearchSurfaceIntegrationTest.tscn` -> passed with `TOP_DOWN_RESEARCH_SURFACE_INTEGRATION_OK`.
  - `ContentSurfaceNewsPreviewTest.tscn` -> passed with fingerprint `236925374`.
  - `ThesisResearchTrayTest.tscn` -> passed with `THESIS_RESEARCH_TRAY_OK`.
  - `SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> passed with `SMOKE_QUICK_OK`.
  - `godot --headless -e --quit` -> passed.
  - `git diff --check` -> passed.
  - direct trailing-whitespace scan on touched code/docs -> no matches.
  - Expected warning noise: Steam init is unavailable in headless local runs; the broad quick smoke still prints the known RID cleanup warnings on exit.

### 2026-06-22 - Revision 1: hide company Profile Top-Down Links

- Hid the compact `Top-Down Links` card from the existing STOCKBOT company Profile tab.
- Reason:
  - the panel felt too explicit and too close to an evidence-card checklist.
  - it duplicated research flow that should happen through News, company profile reading, filings, Research Tray, and Thesis.
  - it made the company profile feel like it was telling the player what to inspect instead of letting the player connect the dots.
- Kept the underlying helper code dormant behind a visibility flag so it can be recovered or redesigned later without re-deriving every payload path.
- Updated quick-smoke expectations so the company Profile now asserts that this card stays hidden.
- Filing access remains available through the existing `View Consolidated Financial Statement` path, not through this hidden card.
- Verification:
  - `SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> passed with `SMOKE_QUICK_OK`.
  - `git diff --check` -> passed.
  - direct trailing-whitespace scan on touched code/docs -> no matches.
  - Expected warning noise: Steam init is unavailable in headless local runs, and the broad quick smoke still prints the known RID cleanup warnings on exit.

---

## Task 1 - Lock pivot and update surface contracts

Problem: The roadmap needs to stop pointing toward a redundant standalone research app.

Result: Complete. The inventory and public News contract now live in `Task 1 Surface Inventory And Locked Contracts` above.

1. Inventory current News, Markets, Research Tray, and Thesis capture paths.
2. Confirm which systems still assume news outlet tiers or paid access.
3. Define the new public News depth contract.
4. Verify:
   - Design review in this doc.
   - `git diff --check`

## Task 2 - Replace tiered News model with topic/coverage model

Problem: News should be differentiated by coverage, not access tier.

Result: Complete. News is now free and routed by topic/coverage metadata, with compatibility fields retained where needed.

1. Replace tier/access assumptions with topic and coverage metadata.
2. Define the four visible outlet lanes:
   - Harian Investor = market wrap/chatter
   - The Egonomist = macro/commodity/sector
   - IDK Channel = corporate action/filing
   - MarketSnitch = early signal/rumor
3. Add the natural article structure fields and outlet-specific article emphasis.
4. Preserve generated content provenance.
5. Verify:
   - JSON data validation passed.
   - Targeted News preview passed with fingerprint `236925374`.
   - Existing quick smoke passed after updating legacy News-upgrade assertions to the free coverage model.

## Task 3 - Add News topic filters and level-1 public-depth rules

Problem: Free News needs variety without becoming too revealing.

Result: Complete. The News surface now has topic/coverage filters, generated/public archive metadata is persisted for filtering and capture, and visible News text is guarded against private/system-only leakage.

1. Add topic/coverage filtering to the existing News surface.
2. Ensure generated News rows default to `public_depth_level = 1`.
3. Prevent News visible copy from leaking private Network or buried filing details.
4. Verify:
   - Targeted News smoke passed.
   - Content surface consistency tests passed.

## Task 4 - Add existing Markets/company detail top-down links

Problem: Players should be able to move from public top-down clues to investable companies without a new app.

Result: Revised. The original compact company Profile `Top-Down Links` card was implemented, then hidden by Revision 1 because it felt too explicit and evidence-card-like. Future work should avoid a consolidated profile checklist and instead strengthen natural discovery through News, filings, company profile reading, peer comparison, Research Tray, and Thesis.

1. Add compact links or panels in existing company/stock detail for commodity exposure, sector peers, active story tags, relationship counterparties, and related filings.
2. Keep the layout dense and operational.
3. Preserve existing bottom-up stock workflow.
4. Verify:
   - Targeted Markets UI smoke.
   - No layout overlap with long company/story names.

## Task 5 - Improve Research Tray/Thesis provenance grouping

Problem: A top-down thesis needs evidence organized by source path.

Result: Complete. Research Tray and Thesis evidence now preserve and display normalized provenance groups/source paths across capture, attachment, direct evidence add, snapshot grouping, save/load, and report generation compatibility.

1. Preserve macro, commodity, sector, company, filing, relationship, network, and social provenance in captured evidence.
2. Add grouping/filter metadata where needed.
3. Keep report generation compatible with existing thesis vocabulary.
4. Verify:
   - Thesis capture test.
   - Thesis report generation still passes.

## Task 6 - Add smoke/regression coverage for surface integration

Problem: Surface integration can regress quietly because it crosses News, Markets, Research Tray, and Thesis.

Result: Complete. Added a targeted fixed-seed integration smoke scene and verified it alongside the existing News, Thesis, and quick UI smoke gates.

1. Add targeted smoke for News topic filtering and evidence capture.
2. Add targeted smoke for company detail links and filing/thesis capture.
3. Save relevant test logs in `docs/development/test_log/` if a longer scenario is run.
4. Verify:
   - UI smoke passes.
   - `git diff --check`

## Known traps

- A standalone research UI would duplicate the existing thesis/research loop.
- News should not become an evidence-card system.
- Free News still needs noise and reliability differences, otherwise every outlet feels the same.
- Topic filters should not hide critical public information behind a paywall-style progression.
- Markets/company detail links should help navigation, not tell the player the answer.
