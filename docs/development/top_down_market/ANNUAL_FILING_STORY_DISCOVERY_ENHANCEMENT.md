# Annual Filing Story Discovery Enhancement - Plan & Progress Log

This plan turns the annual filing reader into a business-story discovery surface. The financial statements can stay compact; the important player value should come from filing-style notes that reveal dealership agreements, long-term contracts, bank facilities, subsidies, leases, concessions, related parties, projects, and other business arrangements without explicitly telling the player what conclusion to draw.
**Status: complete - Tasks 1-8 complete.** Designed to run in a fresh session; everything needed to execute cold is in this file.

**Review verdict recap:** The annual filing stack now has strong plumbing: lazy generation, A4 reader shell, bank vs industrial filing profiles, sector-specific note anatomy, evidence capture, Research Tray preservation, and long-run test coverage. The remaining product problem is intent: the visible filing still reads too much like generated accounting output. The next revision should stop trying to simulate every formal statement detail and instead generate coherent, filing-style story notes where business clues are buried in ordinary annual-report sections.

## Where everything lives

| What | Where |
|---|---|
| Current annual filing generator | `systems/AnnualFilingDocument.gd` - lazy document contract, filing profile selection, visible filing generation, prose/noise generation, A4 reader payloads |
| Current annual statement source | `systems/AnnualStatementBuilder.gd` - deterministic consolidated annual statement rows and note source payloads |
| Current story source | `systems/CompanyStoryDossierSystem.gd` - story truth, disclosure packets, subtlety/placement metadata, filing traceability |
| Current relationship source | `systems/CompanyRelationshipGraphSystem.gd` - supplier/customer/partner/competitor/acquisition relationship facts and event hooks |
| Current financial adapter | `systems/FinancialStatementLayer.gd` - story effects and annual-note enrichment bridge |
| Current UI entry point | `scripts/ui/controllers/StockController.gd` - `View Consolidated Financial Statement` button and A4 report overlay |
| Current runtime state | `autoloads/RunState.gd` - company snapshots, annual statement enrichment, evidence normalization, save/load defaults |
| Company identity source | `data/companies/company_universe_catalog.json` - sector/subsector, business model, moat, exposure, and company profile fields |
| Current tests/probes | `scripts/tests/AnnualFilingVisibleGenerationTest.gd`, `scripts/tests/AnnualFilingBankReaderUiSmokeTest.gd`, `scripts/tests/AnnualFilingSectorRealismRegressionTest.gd`, `scripts/tests/FullYearPlayerScenarioTest.gd`, `scripts/tests/SmokeTest.gd` |
| Reference basis | User-provided annual filing screenshots plus prior AKR and Bank Sinarmas PDF references; use only for structure/tone, not runtime text |
| Parent roadmap | `docs/development/top_down_market/TOP_DOWN_MARKET_SYSTEM_ROADMAP.md` |
| Prior filing plans | `docs/development/top_down_market/ANNUAL_FILING_READING_EXPERIENCE_ENHANCEMENT.md`, `docs/development/top_down_market/ANNUAL_FILING_SECTOR_REALISM_ENHANCEMENT.md` |
| Key functions (line refs drift; locate by name) | `build_annual_filing_document`, `build_visible_filing`, `build_filing_profile`, `build_annual_statement`, `capture_research_evidence` |

## Product Direction

The annual filing should feel less like a full accounting simulator and more like a compact annual report reader with clues hidden in the notes.

Desired reading pattern:

- The player opens `View Consolidated Financial Statement`.
- The statements give enough numbers to anchor scale, profitability, assets, liabilities, and cash movement.
- The notes carry most of the investing story through ordinary disclosure language.
- The story is not spoon-fed. A player should infer meaning from contracts, counterparties, terms, guarantees, facilities, segment changes, subsidies, commitments, related parties, and subsequent events.
- A strong clue may be split across several sections so the player has to connect it:
  - one section names the agreement
  - another section names the financing or guarantee
  - another section shows segment or revenue movement
  - another section records commitments, contingencies, or subsequent events
- Evidence capture should preserve filing excerpt provenance without turning the note into a generated "evidence card."

## Story-Bearing Note Containers

These note containers are the intended core of the next filing revision.

| Container | What it should reveal | Example clue type |
|---|---|---|
| Significant agreements | Dealerships, distribution rights, supply/offtake contracts, project contracts, operating agreements | A company gains exclusive distribution for a key product line. |
| Commitments and contingencies | Long-term purchase commitments, guarantees, project obligations, legal/contract risk | A commitment locks future volume but creates funding pressure. |
| Bank facilities and guarantees | Credit lines, trade facilities, guarantees, hedging facilities, covenants | Expansion is financed by a named bank facility with covenant constraints. |
| Segment operations | Business-line revenue/profit/asset split, geographic exposure, new segment contribution | A small segment suddenly becomes material. |
| Government pricing and subsidies | Subsidized pricing, regulated tariff, reimbursement claim, public-sector dependence | Profitability depends on a ministry/government claim. |
| Subsidiaries and leases | Land rights, right-of-use assets, subsidiaries, operating locations | Expansion is hidden in lease/subsidiary disclosures. |
| Related parties | Parent/subsidiary/customer/supplier/management relationships | A counterparty is not arm's-length or has concentrated exposure. |
| Project and construction notes | EPC work, capacity buildout, terminal/storage/project timelines | Future revenue depends on completion timing. |
| Customers and suppliers | Concentration, major customer, supplier dependence, dealership principal | A growth story relies on one supplier or customer. |
| Subsequent events | Post-year-end contracts, financing, acquisitions, divestments, approvals | A catalyst appears after the statement date. |
| Accounting policies | Formal policy texture; sector-specific noise that supports realism | Should not carry direct clues unless linked to a real business fact. |

## Goals

- Make visible filing notes read like coherent annual-report disclosures, not generated explanatory prose.
- Move most player-facing story value into business arrangements and note context.
- Keep the consolidated statements short and useful; do not overbuild accounting detail.
- Render English-only filing prose.
- Remove generic note meta text such as "related note classifications," "same basis as the consolidated statements," and other generator-sounding fragments.
- Generate story-bearing paragraphs only from deterministic source facts.
- Split important facts across multiple note sections where appropriate so inference matters.
- Preserve lazy generation: the annual filing is built only when the player clicks the button.
- Preserve Research Tray and Thesis capture metadata without making captured snippets too explicit.

## Non-goals

- Do not copy reference filing text verbatim into runtime data.
- Do not build full IFRS/PSAK statement completeness.
- Do not make the filing a recommendation engine.
- Do not add another standalone research app.
- Do not replace News, Twooter, Network, or Thesis. The filing is one discovery surface in the existing loop.
- Do not add every sector profile in this pass. Improve the architecture and lock two or three representative profiles first.
- Do not pre-generate all annual filings at run start.

## Working Rules

- Annual filing documents must remain lazy-generated on player click and cached by deterministic source-state keys.
- Every visible business-story paragraph must trace back to a deterministic fact packet.
- Generated prose should be section-specific and sector-aware.
- Do not use generic filler paragraphs to pad sections.
- Prefer fewer, richer sections over many shallow generic sections.
- Keep exact repeated visible paragraph count at `0`.
- Visible output must not expose hidden ids or truth labels such as `story|`, `packet|`, `placement|`, `truth_state`, `source_quality`, or confidence labels.
- Keep capture payloads neutral: source section, excerpt id, note label, visible text, and provenance group are enough.
- One task per checkpoint commit; verify before each commit.
- Use the reference PDFs/screenshots for structure, tone, and section patterns only.

## Status

| # | Task | Est. cost | Status |
|---|---|---|---|
| 1 | Define story-note contract and fact taxonomy | ~10-15% | Complete |
| 2 | Build deterministic story fact packets | ~20-30% | Complete |
| 3 | Add filing-style story note renderers | ~25-40% | Complete |
| 4 | Split clues across sections with cross-note placement | ~20-35% | Complete |
| 5 | Rebalance reader structure around compact statements plus story notes | ~15-25% | Complete |
| 6 | Preserve capture, Thesis, save/load, and lazy cache behavior | ~15-25% | Complete |
| 7 | Add realism regression tests and reference-inspired fixtures | ~15-30% | Complete |
| 8 | Full-year scenario and performance audit | ~10-20% | Complete |

Recommended batching: **Session 3 = Tasks 3-4** converts packets into filing-style notes and scattered clues. **Session 4 = Tasks 5-7** hardens reader structure, capture, and regression guards. **Session 5 = Task 8** verifies full-player-flow behavior and performance.

## Progress Log

### 2026-06-24 - Plan created

- Created this enhancement plan from the filing-story brainstorm and user-provided filing screenshots.
- Product correction:
  - the current filing reader has working infrastructure but still feels too generated
  - the desired output is not a more complete financial statement; it is a compact filing with story-bearing notes
  - useful clues should appear as dealership agreements, bank facilities, subsidies, leases, concessions, projects, segment shifts, related parties, and commitments
- Current baseline:
  - `Annual Filing Sector Realism` is complete and gives us sector profile plumbing
  - the latest full-year scenario passed, but the filing quality still needs a story-note revision
  - late-year performance is acceptable for tests but annual filing generation must stay lazy and bounded
- No code, runtime data, or behavior changes were made by this planning step.

### 2026-06-24 - Task 1 complete

- Added the story-note fact contract to `systems/AnnualFilingDocument.gd`.
- New deterministic contract surface:
  - schema version `1`
  - status `task1_story_note_contract_ready`
  - schema hash `1214903292`
  - 16 required fields
  - 11 story types
  - 11 story-bearing note containers
  - profile container allowlists for `bank`, `industrial_trading`, and `default_general`
- Added pure helpers for:
  - required fields
  - story type definitions
  - container definitions
  - profile/type allowed containers
  - fact normalization
  - fact validation
  - schema hash and summary
- Added `scripts/tests/AnnualFilingStoryNoteContractTest.gd` and `scenes/tests/AnnualFilingStoryNoteContractTest.tscn`.
- Test sentinel:
  - `ANNUAL_FILING_STORY_NOTE_CONTRACT_OK`
  - fixed payload hash `1287721463`
- Scope note:
  - no visible filing prose or UI behavior was generated or changed by this task
  - Task 2 should now build deterministic story fact packets from dossier, relationship graph, annual statement, living arc, and catalog sources.

### 2026-06-24 - Task 2 complete

- Added deterministic story fact packet generation to `systems/AnnualFilingDocument.gd`.
- New pure packet surface:
  - `build_story_note_fact_packets(...)`
  - `validate_story_note_fact_packet_set(...)`
  - `story_note_fact_packet_hash(...)`
  - `story_note_fact_packet_summary(...)`
- Packet sources now supported through a source context:
  - company universe fields and bounded metadata fallbacks
  - company story dossier disclosure packets
  - company relationship graph edges/events
  - annual statement notes
  - living company arcs
  - corporate action events
  - roadmap milestones and event rows
- Quality gates added:
  - packet-level contract validation
  - duplicate fact-id guard
  - source-id traceability guard
  - visible prose field guard
  - non-bank fake-facility fallback guard
- Added `scripts/tests/AnnualFilingStoryFactPacketTest.gd` and `scenes/tests/AnnualFilingStoryFactPacketTest.tscn`.
- Test sentinel:
  - `ANNUAL_FILING_STORY_FACT_PACKET_OK`
  - fixed payload hash `1089345055`
  - 4 fixed samples
  - 32 generated packets
  - source systems covered: `annual_statement_builder`, `company_relationship_graph`, `company_roadmap`, `company_story_dossier`, `company_universe_catalog`, `corporate_action`, `living_company_arc`
- Scope note:
  - no visible filing prose, reader layout, UI behavior, or cache behavior changed in this task
  - Task 3 should now render these packets into filing-style note paragraphs.

### 2026-06-24 - Task 3 complete

- Added filing-style story note renderers to `systems/AnnualFilingDocument.gd`.
- New deterministic renderer surface:
  - `build_story_note_prose_packets(...)`
  - `validate_story_note_prose_packets(...)`
  - `story_note_prose_hash(...)`
  - `story_note_prose_summary(...)`
  - `story_note_prose_roles()`
  - `story_note_prose_forbidden_phrases()`
- Added story-note prose roles:
  - `agreement_lead`
  - `facility_detail`
  - `commitment_detail`
  - `segment_context`
  - `policy_noise`
  - `subsequent_event`
- Added filing-style paragraph renderers for:
  - dealership agreement renewal/termination language
  - supply/offtake/customer/supplier arrangements
  - bank facility sub-limits and covenant language
  - bank guarantee language tied to an underlying agreement
  - lease or land-right arrangements
  - government subsidy/reimbursement claims
  - project contracts with construction/service terms
  - segment operations context
  - related-party transactions
  - subsidiary commitments
  - subsequent events
- Added story-note prose into lazy visible filing generation without merging it into the base prose-library hash.
- Added story-note fact/prose hashes to the annual filing cache key and document contract so cache invalidates when story-note rendering changes.
- Updated `scripts/ui/controllers/StockController.gd` to pass the effective company definition into annual filing requests, allowing catalog metadata, relationship hooks, story hooks, and exposures to feed story-note generation.
- Adjusted visible filing balance accounting so story-bearing note paragraphs are not treated as generic note filler for the table/prose ratio guard.
- Added `scripts/tests/AnnualFilingStoryNoteRendererTest.gd` and `scenes/tests/AnnualFilingStoryNoteRendererTest.tscn`.
- Test sentinels:
  - `ANNUAL_FILING_STORY_NOTE_RENDERER_OK` fixed payload hash `390905110`, story-note prose hash `195205633`
  - `ANNUAL_FILING_STORY_FACT_PACKET_OK` fixed payload hash `1089345055`
  - `ANNUAL_FILING_VISIBLE_GENERATION_OK` fixed payload hash `1986713075`, visible filing hash `370574745`
  - `ANNUAL_FILING_PROSE_LIBRARY_OK` fixed payload hash `1373663978`, base prose hash `1682611958`
  - `ANNUAL_FILING_LAZY_CONTRACT_OK` fixed payload hash `2027955379`
  - `ANNUAL_FILING_PROFILE_CONTRACT_OK` fixed payload hash `1554092753`
  - `ANNUAL_FILING_REGRESSION_GUARD_OK` fixed payload hash `1092301094`, visible filing hash `370574745`
- Scope note:
  - story-note prose now appears in the visible filing reader when the document is generated on button request
  - the base prose library still exists for routine filing texture, but story-note paragraphs take priority over routine boilerplate in limited note sections
  - Task 4 should scatter material facts across primary and secondary note containers instead of keeping each fact in one rendered paragraph.

### 2026-06-24 - Task 4 complete

- Added deterministic cross-note clue placement to `systems/AnnualFilingDocument.gd`.
- New placement surface:
  - `build_story_note_placement_plan(...)`
  - `validate_story_note_placement_plan(...)`
  - `story_note_placement_plan_hash(...)`
  - `story_note_placement_plan_summary(...)`
  - `story_note_placement_roles()`
- Added placement roles:
  - `primary_note`
  - `secondary_note`
  - `policy_or_risk_echo`
- Material story facts now produce a primary note placement plus deterministic secondary and optional policy/risk echo placements when the filing profile has suitable sections.
- Added cross-note prose variants so scattered clues do not repeat the primary paragraph:
  - agreement or supply facts can echo into segment/revenue notes
  - bank guarantees can echo into liabilities or risk notes
  - bank facilities can echo into commitments or risk notes
  - subsidies can echo into receivable/segment context
  - projects, leases, subsidiaries, related parties, and subsequent events can span their natural adjacent notes
- Integrated placement metadata into the annual filing contract, visible-generation source summary, contract payload, and story-note prose rendering path.
- Added `scripts/tests/AnnualFilingCrossNotePlacementTest.gd` and `scenes/tests/AnnualFilingCrossNotePlacementTest.tscn`.
- Test sentinels:
  - `ANNUAL_FILING_CROSS_NOTE_PLACEMENT_OK` fixed payload hash `1769549668`, placement hash `475435060`, prose hash `1573337009`, 15 placements, 5 multi-section facts
  - `ANNUAL_FILING_STORY_NOTE_RENDERER_OK` fixed payload hash `189794787`, story-note prose hash `194763165`
  - `ANNUAL_FILING_VISIBLE_GENERATION_OK` fixed payload hash `1435807122`, visible filing hash `1267457237`
  - `ANNUAL_FILING_LAZY_CONTRACT_OK` fixed payload hash `397797318`
  - `ANNUAL_FILING_PROFILE_CONTRACT_OK` fixed payload hash `1900681936`
  - `ANNUAL_FILING_REGRESSION_GUARD_OK` fixed payload hash `474151786`, visible filing hash `1267457237`
  - `ANNUAL_FILING_PROSE_LIBRARY_OK` fixed payload hash `1373663978`
  - `ANNUAL_FILING_STORY_FACT_PACKET_OK` fixed payload hash `1089345055`
- Scope note:
  - the filing now scatters material business clues across multiple note sections instead of rendering each fact only once
  - player-visible text still hides internal ids, truth labels, source quality, and confidence labels
  - Task 5 should rebalance the reader structure and layout around compact statements plus these story-bearing notes.

### 2026-06-24 - Task 5 complete

- Rebalanced visible annual filing materialization around compact statements plus story-bearing notes.
- Kept the full internal anatomy schema intact while making the player-visible reader story/table-led:
  - core statement sections stay visible
  - routine front matter and routine-only notes are dropped from visible materialization
  - story-bearing note paragraphs and compact tables decide which note sections render
  - industrial/trading visible filings now render as a compact 8-16 section document
  - bank visible filings now render as a compact 21-section table-heavy document without director/auditor front matter
- Removed player-visible Bahasa Indonesia/localized note labels from generated filing sections.
- Added visible-text guards against generator phrases:
  - `related note classifications`
  - `same basis as the consolidated statements`
  - `supporting schedule includes`
  - `describes the recognition and movement`
  - `the note presentation should be read together`
  - `this disclosure should be read together`
- Improved A4 reader layout in `scripts/ui/controllers/StockController.gd`:
  - outer report scroll now stays automatic as a cutoff guard
  - A4 page height budget is smaller so the bottom stays inside the viewport
  - compact table amount columns are narrower
  - long annual values render as compact currency labels instead of raw oversized numbers
  - rendered chunk size is reduced to keep dense note sections readable
- Hardened annual filing UI smoke:
  - validates story-note paragraphs are visible
  - validates no bottom cutoff for the A4 page
  - validates no horizontal table overflow
  - validates compact numeric table cells
  - validates English-only visible text and no hidden metadata leakage
  - validates capture, thesis attach, direct thesis evidence add, and save/load still survive for bank filings
- Updated catalog-dependent filing tests to choose representative companies by generated filing profile instead of assuming fixed catalog IDs after the universe expanded.
- Test sentinels:
  - `ANNUAL_FILING_VISIBLE_GENERATION_OK` fixed payload hash `633579782`, visible filing hash `739527429`, 13 sections, 19 paragraphs, 4 tables, 0 cross references
  - `ANNUAL_FILING_REGRESSION_GUARD_OK` fixed payload hash `1869439697`, visible filing hash `739527429`
  - `ANNUAL_FILING_BANK_READER_UI_SMOKE_OK` fixed payload hash `2022638696`, company `bank_daerah_mandiri`, 21 sections, 18 tables, 56 table rows, 3 capture payloads
  - `ANNUAL_FILING_STORY_NOTE_RENDERER_OK` fixed payload hash `487832935`, story-note prose hash `194763165`, 15 visible story paragraphs
  - `ANNUAL_FILING_LAZY_CONTRACT_OK` fixed payload hash `111806429`
  - `ANNUAL_FILING_SECTOR_REALISM_REGRESSION_OK` fixed payload hash `634098613`, bank representative `bank_daerah_mandiri`, industrial representative `komponen_mesin_raya`
  - `ANNUAL_FILING_PROFILE_CONTRACT_OK` fixed payload hash `552737853`
  - `ANNUAL_FILING_ANATOMY_SCHEMA_OK` fixed payload hash `1117466486`, full internal schema still has 20 sections
  - `ANNUAL_FILING_BANK_ANATOMY_TABLE_OK` fixed payload hash `1058182282`, bank representative `bank_daerah_mandiri`, 21 sections, 18 tables, 56 rows
  - `ANNUAL_FILING_FOOTPRINT_PACKET_OK` fixed payload hash `1020530100`
  - `ANNUAL_FILING_CROSS_NOTE_PLACEMENT_OK`, `ANNUAL_FILING_PROSE_LIBRARY_OK`, `ANNUAL_FILING_STORY_NOTE_CONTRACT_OK`, and `ANNUAL_FILING_STORY_FACT_PACKET_OK` remained green
- Scope note:
  - Task 5 includes capture/thesis/save-load smoke coverage through the bank reader test, but Task 6 should still review and harden the capture contract as its own checkpoint.
  - Task 6 should focus on preserving neutral evidence payloads and cache invalidation behavior after the reader rebalance.

### 2026-06-24 - Task 6 complete

- Hardened annual-filing capture metadata preservation across the research loop.
- Updated `scripts/ui/controllers/StockController.gd` annual filing payload application so reader captures consistently preserve:
  - `source_type = financial_statement`
  - `source_label = Annual Filing`
  - `source_system_id = annual_filing_document`
  - `filing_capture_type`
  - `filing_section_id`
  - `filing_excerpt_id`
  - `source_excerpt`
  - `provenance_group = filing`
  - `provenance_label = Annual Filing`
  - `provenance_surface = annual_filing_reader`
  - `provenance_origin = visible_filing_document`
- Added hidden story-note traceability for story-bearing note paragraphs:
  - `source_story_note_fact_ids`
  - `story_note_fact_id`
- Preserved those fields through:
  - Research Tray capture normalization in `systems/ThesisEvidenceCaptureSystem.gd`
  - thesis evidence attach/direct-add normalization in `systems/ThesisManager.gd`
  - save/load normalization in `autoloads/RunState.gd`
- Updated thesis/research dedupe keys to include `story_note_fact_id`.
- Strengthened `AnnualFilingBankReaderUiSmokeTest.gd`:
  - real UI payload collection now prefers a story-bearing note paragraph when available
  - validates capture payload contract before capture
  - validates captured Research Tray rows after save/load
  - validates thesis-attached and direct-added annual filing rows after save/load
  - validates story-note fact ids stay hidden from visible player-facing strings
- Strengthened `AnnualFilingLazyContractTest.gd`:
  - validates story-note fact/prose/placement hashes are cache key parts and invalidation fields
  - validates a source-context story-note event changes fact packet hash and annual-filing cache key
- Test sentinels:
  - `ANNUAL_FILING_LAZY_CONTRACT_OK` fixed payload hash `111806429`
  - `ANNUAL_FILING_BANK_READER_UI_SMOKE_OK` fixed payload hash `2022638696`, company `bank_daerah_mandiri`, 21 sections, 18 tables, 56 table rows, 3 capture payloads
- Scope note:
  - visible Research Tray/Thesis copy remains excerpt-based; hidden story-note ids are retained only as metadata.

### 2026-06-24 - Task 7 complete

- Extended realism regression coverage for story-note discovery quality.
- Strengthened `AnnualFilingStoryNoteRendererTest.gd` fixed fixture coverage:
  - bank facility sample
  - dealership agreement sample
  - supplier/operator sample
  - bank guarantee sample
  - lease/land-right sample
  - government subsidy sample
  - project contract sample
  - segment, related-party, and subsequent-event samples
- Added assertions for:
  - no hidden ids or truth/source-quality labels in visible story-note prose
  - no direct investment recommendation language
  - no repeated story-note paragraph inside a section
  - concrete counterparties including Asahimas Chemical, SPBU Operators, Bank Danamon, Jakarta Land Authority, Ministry of Finance, and Energy Equity Epic
  - concrete date/currency markers
  - agreement/facility disclosure shape rather than evidence-card copy
  - commitments/guarantee obligation language
  - segment operating context
  - bank-facility prose only appearing when a bank-facility source fact exists
- Reconfirmed sector realism profile coverage:
  - bank profile table-heavy visible filing
  - industrial profile without bank-only sections
  - English-only visible note titles
  - no generic filler phrases or raw unit tokens
- Test sentinels:
  - `ANNUAL_FILING_STORY_NOTE_RENDERER_OK` fixed payload hash `487832935`, story-note prose hash `194763165`, 10 facts, 19 prose rows, 15 visible story paragraphs
  - `ANNUAL_FILING_STORY_FACT_PACKET_OK` fixed payload hash `1089345055`, 32 packets, 4 samples
  - `ANNUAL_FILING_SECTOR_REALISM_REGRESSION_OK` fixed payload hash `634098613`, bank representative `bank_daerah_mandiri`, industrial representative `komponen_mesin_raya`

### 2026-06-24 - Task 8 complete

- Ran the full-year player scenario through Godot for 225 trading days.
- Scenario confirmed:
  - game scene opened through `res://scenes/game/GameRoot.tscn`
  - stock, news, thesis, and advance-day controls were present
  - player bought a catalog bank stock
  - annual filing opened lazily on request
  - annual filing evidence captured and attached to thesis
  - final thesis report generated after the 225-day run
- Full-year sentinel:
  - `FULL_YEAR_PLAYER_SCENARIO_OK`
  - seed `20260622`
  - elapsed `326372.13ms`
  - final trade date `2020-12-03`
  - log file `docs/development/test_log/2026-06-24_annual_filing_sector_realism_full_year.md`
- Annual filing metrics:
  - opened company `bank_orang_indonesia`
  - profile `bank`
  - visible filing hash `1227774838`
  - generation timing/cache `lazy_on_request` / `miss_built`
  - visible sections/tables `21 / 18`
  - story-note facts/prose `6 / 5`
  - capture types `statement_row`, `note_table_row`, `note_paragraph`
- Player/portfolio metrics:
  - bought `BORI` / `bank_orang_indonesia`
  - shares `500`
  - buy price `9322.0`
  - final price `2417.0`
  - held return `-74.07%`
  - final cash `1890338.5`
  - final market value `1208500.0`
  - final equity `3098838.5`
- Market/event metrics:
  - best stock `DIGN` / `diagnostik_sehat`, return `770.43%`
  - worst stock `SKSI` / `sistem_karya_siber`, return `-96.97%`
  - average/median return `-47.88% / -75.05%`
  - advancers/decliners `4 / 66`
  - scheduled/company/corporate/index/special events `19 / 280 / 229 / 55 / 0`
  - gorengan started/dump peak/success peak `24 / 7 / 0`
  - attention lane counts `company=111`, `digestion=109`, `macro=2`, `quiet=3`
- Performance note:
  - annual filing generation remained lazy and bounded to the opened company
  - full-year daily apply time rose in the late run to roughly `0.4-0.55s` per day with 70 companies and 160 recorded events
  - total run time was acceptable for this heavy full-year smoke, but future optimization should focus on `RunState.load_from_dict` / daily `normalize_companies` costs rather than annual filing generation.

---

## Task 1 - Story-Note Contract And Fact Taxonomy

Problem: The generator needs a source contract for business-story facts before it can render coherent filing notes.

1. Add a story-note fact schema in `AnnualFilingDocument.gd` or a focused helper, keeping it pure and deterministic.
2. Define required fields:
   - `fact_id`
   - `company_id`
   - `story_type`
   - `note_container`
   - `counterparty_id`
   - `counterparty_name`
   - `agreement_type`
   - `effective_date`
   - `term_months` or `term_text`
   - `amount`
   - `currency`
   - `source_system`
   - `source_ids`
   - `visibility_level`
   - `capture_group`
3. Define initial `story_type` values:
   - `dealership_agreement`
   - `supply_or_offtake_agreement`
   - `bank_facility`
   - `bank_guarantee`
   - `lease_or_land_right`
   - `government_subsidy`
   - `project_contract`
   - `segment_expansion`
   - `related_party_transaction`
   - `subsidiary_commitment`
   - `subsequent_event`
4. Define note-container allowlists by filing profile:
   - `bank`
   - `industrial_trading`
   - `default_general`
5. Add targeted contract test:
   - deterministic schema hash
   - every fact has traceable source ids
   - every fact maps to an allowed note container
   - no visible prose generated yet.
6. Verify:
   - targeted contract test sentinel
   - `git diff --check`
   - Godot headless editor gate.

## Task 2 - Deterministic Story Fact Packets

Problem: The filing needs real deterministic facts instead of paragraph templates inventing context.

1. Build story fact packets from existing sources:
   - company universe fields
   - company story dossier disclosure packets
   - company relationship graph edges/events
   - living company arcs
   - corporate actions and roadmap milestones
   - sector/commodity exposure where relevant
2. Create bounded fallback facts only when source systems do not provide enough:
   - one ordinary customer/supplier/lease/facility fact from company metadata
   - no dramatic claims unless backed by story/event state
3. Ensure packet generation is deterministic from seed/company/source ids.
4. Add packet-level quality gates:
   - no empty counterparty where the story type requires one
   - no agreement paragraph without term/amount/obligation when applicable
   - no fake bank facility for non-bank/non-levered story unless profile allows it
5. Add targeted packet test for fixed samples:
   - bank company
   - industrial/trading company
   - project/energy or commodity company if available in catalog
6. Verify:
   - packet test sentinel and hash
   - existing story dossier and annual filing profile tests
   - `git diff --check`
   - Godot headless editor gate.

## Task 3 - Filing-Style Story Note Renderers

Problem: Current prose reads generated because sections describe themselves. New prose should read like annual filing notes about business arrangements.

1. Add renderer functions by `story_type` and `note_container`.
2. Render paragraphs in formal filing style:
   - neutral
   - specific
   - not advisory
   - not explanatory about why the note matters
3. Render examples by shape, not copied reference text:
   - dealership agreement with renewal/termination language
   - bank guarantee tied to a supplier or principal
   - long-term operator/lease agreement with conditional compensation
   - bank facility with sub-limits and covenant note
   - project contract with construction period and service term
   - government subsidy/reimbursement receivable
4. Remove or heavily limit generic accounting-note filler.
5. Add section-level prose roles:
   - `agreement_lead`
   - `facility_detail`
   - `commitment_detail`
   - `segment_context`
   - `policy_noise`
   - `subsequent_event`
6. Add regression guard for forbidden generic phrases and repeated paragraphs.
7. Verify:
   - story-note renderer test sentinel
   - annual filing visible generation test
   - prose library test
   - `git diff --check`
   - Godot headless editor gate.

## Task 4 - Cross-Note Clue Placement

Problem: If all facts appear in one section, the filing becomes a clue card. Important stories should be distributed across notes.

1. Add a deterministic clue-placement planner.
2. For each material story packet, choose:
   - primary note container
   - secondary cross-reference note
   - optional accounting policy or risk note echo
3. Example placements:
   - dealership agreement in `Significant Agreements`
   - bank guarantee in `Commitments And Contingencies`
   - bank facility in `Borrowings / Bank Facilities`
   - revenue effect in `Segment Operations`
4. Keep each note independently readable.
5. Add cross-note references that feel natural:
   - `This agreement is supported by a bank guarantee issued by...`
   - `The related receivable is presented as part of...`
   - `Revenue from the related operating segment is disclosed in...`
6. Add tests:
   - at least one material story spans two or more sections
   - no hidden id leakage
   - no repeated paragraph after scattering
7. Verify:
   - cross-note placement test sentinel
   - annual filing regression guard
   - `git diff --check`
   - Godot headless editor gate.

## Task 5 - Reader Structure Rebalance

Problem: The filing should not be a detailed accounting checklist. It should be a readable compact document where notes carry the discovery value.

1. Keep the core statements compact:
   - financial position
   - profit or loss
   - changes in equity
   - cash flows
2. Prioritize story-bearing notes over exhaustive note count.
3. Remove Bahasa Indonesia labels from generated player-visible filing sections.
4. Remove visible generator phrases:
   - `related note classifications`
   - `same basis as the consolidated statements`
   - `supporting schedule includes`
   - `describes the recognition and movement`
5. Improve A4 reader readability if needed:
   - note paragraph spacing
   - table widths
   - long number formatting
   - no bottom cutoff
   - no horizontal cutoff
6. Add layout/reader smoke focused on:
   - visible story note sections
   - no cutoff at page bottom
   - no clipped numeric table cells
   - English-only visible section text
7. Verify:
   - focused filing reader UI smoke
   - `git diff --check`
   - Godot headless editor gate.

## Task 6 - Capture, Thesis, Save/Load, And Cache Preservation

Problem: Story notes must still work with the research loop without becoming explicit evidence cards.

1. Preserve annual filing capture payload fields:
   - `source_type = financial_statement`
   - `source_label = Annual Filing`
   - `filing_section_id`
   - `filing_excerpt_id`
   - `filing_capture_type`
   - `source_excerpt`
   - `provenance_group`
2. Add `story_note_fact_id` only if it stays hidden from player-facing labels.
3. Ensure Research Tray card copy remains neutral and excerpt-based.
4. Ensure direct thesis add and Research Tray attach preserve filing metadata.
5. Ensure save/load normalizes new metadata.
6. Ensure cache invalidates when story-note fact packets change.
7. Verify:
   - capture/thesis/save-load test sentinel
   - lazy/cache contract test
   - `git diff --check`
   - Godot headless editor gate.

## Task 7 - Realism Regression Fixtures

Problem: This quality target will regress unless tests check prose shape, not just hashes.

1. Add fixed-seed story-note fixtures:
   - bank/facility sample
   - industrial/dealership or supplier sample
   - project/lease/subsidy sample if supported by catalog data
2. Add visible-output assertions:
   - English-only
   - no generic filler phrases
   - no repeated visible paragraph
   - at least one concrete counterparty in story-bearing notes
   - at least one term/amount/date where the story type requires it
   - no direct recommendation language
3. Add semantic shape assertions:
   - `Significant Agreements` contains agreement-like prose
   - `Commitments And Contingencies` contains obligations/guarantees/terms
   - `Segment Operations` contains operating segment context
   - `Bank Facilities` only appears when source/profile supports it
4. Add deterministic hash baselines after shape checks are stable.
5. Verify:
   - story realism regression sentinel
   - annual filing sector realism tests
   - `git diff --check`
   - Godot headless editor gate.

## Task 8 - Full-Year Scenario And Performance Audit

Problem: The filing revision touches player research flow and may add heavier on-demand document generation.

1. Run the full-year player scenario after the story-note revision.
2. Confirm the scenario still:
   - opens the game through Godot
   - buys a stock
   - opens annual filing
   - captures filing evidence
   - creates a thesis
   - advances 225 trading days
   - generates the final thesis report
3. Log:
   - filing profile
   - story-note fact count
   - capture count/types
   - final portfolio metrics
   - market breadth
   - event counts
   - attention director metrics
   - elapsed time
4. Add a performance note:
   - annual filing should be lazy and bounded
   - no all-company filing generation at run setup
   - generated document cache should not grow unbounded
5. Verify:
   - full-year scenario sentinel
   - update `docs/development/test_log/` if the behavior changes materially
   - `git diff --check`
   - quick smoke if not blocked by unrelated known issues.

## Known Traps

- Do not solve quality by adding more generic paragraphs. Fewer, better story-bearing notes are the goal.
- Do not expose hidden story ids, packet ids, source quality, truth labels, or confidence labels.
- Do not make every story obvious. The player should infer from filing context.
- Do not copy reference PDF wording into the game. Use reference structure and tone only.
- Do not pre-generate filings for all companies; keep generation lazy.
- Do not break existing capture/thesis metadata while changing visible prose.
- Do not let sector profile checks become only hash tests. Keep readable shape assertions.
- Do not turn the annual filing into the only source of truth; News, Twooter, Network, company profile, and Thesis still matter.
