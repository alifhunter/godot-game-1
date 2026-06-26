# Annual Filing Reading Experience Enhancement - Plan & Progress Log

This plan replaces the current evidence-card feel of the annual financial statement reader with a lazy-generated, A4-style annual filing experience where players read, compare, and infer company stories from formal statements and notes.
**Status: complete - Tasks 1-8 complete.** Designed to run in a fresh session; everything needed to execute cold is in this file.

**Review verdict recap:** Financial Statement Layer R1-R3 created useful annual statement plumbing, note bodies, cross-note references, evidence capture, and regression coverage. The remaining product problem is fit: the visible report still feels too explicit and too close to generated evidence cards. The next enhancement should keep the existing deterministic data/provenance layer, but make the player-facing output feel like reading a real annual filing where useful story clues are buried across statements, notes, segment information, related parties, commitments, risks, and subsequent events.

## Where everything lives

| What | Where |
|---|---|
| Current annual statement builder | `systems/AnnualStatementBuilder.gd` - deterministic annual statement, notes, row model, document contract |
| Current statement/story adapter | `systems/FinancialStatementLayer.gd` - maps story effects into statement rows and note metadata |
| Current story source | `systems/CompanyStoryDossierSystem.gd` - story truth, disclosure packets, section placements, subtlety metadata |
| Current UI entry point | `scripts/ui/controllers/StockController.gd` - `View Consolidated Financial Statement` button and report overlay |
| Current runtime state | `autoloads/RunState.gd` - company snapshots, annual statement enrichment, thesis/research capture normalization |
| Current tests/probes | `scripts/tests/AnnualFilingLazyContractTest.gd`, `scripts/tests/AnnualFilingAnatomySchemaTest.gd`, `scripts/tests/AnnualFilingFootprintPacketTest.gd`, `scripts/tests/AnnualFilingProseLibraryTest.gd`, `scripts/tests/AnnualFilingVisibleGenerationTest.gd`, `scripts/tests/AnnualFilingRegressionGuardTest.gd`, `scripts/tests/AnnualReportFidelityCaptureTest.gd`, `scripts/tests/AnnualStatementFilingNoteBodyTest.gd`, `scripts/tests/AnnualReportDocumentContractTest.gd`, `scripts/tests/SmokeTest.gd` |
| Reference extraction tool | `tools/pdf_text_extractor/` from the workspace root - local-only PDF text extraction helper outside `godot-game-1` |
| Primary reference text | `tools/pdf_text_extractor/output/PT_AKR_Corporindo_2025_extracted.txt` from the workspace root - AKR annual consolidated statement extraction |
| Parent roadmap | `docs/development/top_down_market/TOP_DOWN_MARKET_SYSTEM_ROADMAP.md` |
| Prior implementation history | `docs/development/top_down_market/FINANCIAL_STATEMENT_LAYER_ENHANCEMENT.md` |

## Product vision

The player should feel like they are opening a company annual report, not a game-generated clue summary.

The expected research loop:

1. Player starts from macro, commodity, government, or sector context.
2. Player narrows into sectors, subsectors, and company exposure.
3. Player opens `View Consolidated Financial Statement`.
4. The annual filing is generated on demand for that company and fiscal year.
5. The player reads statements and notes to find accounting footprints.
6. The player captures statement rows, note paragraphs, cross-note references, or table cells as thesis evidence.
7. The player assembles the story across multiple sections instead of receiving a direct answer.

## Goals

- Make the consolidated financial statement feel like a formal annual filing document.
- Generate the full filing only when the player clicks `View Consolidated Financial Statement`.
- Cache generated filings by run/company/fiscal year so reopening is stable and fast.
- Make visible prose natural, formal, and filing-like instead of game-like.
- Hide important clues across multiple sections, not in one obvious evidence paragraph.
- Use statement rows, note tables, and note paragraphs as player evidence surfaces.
- Preserve existing traceability and thesis capture under the hood without leaking hidden truth labels.

## Non-goals

- Do not build a full accounting-standard simulator.
- Do not export a real PDF in this pass; the in-game reader only needs to feel like an A4 filing.
- Do not generate every possible sector-specific filing style at once.
- Do not make commodities or macro indicators tradable instruments.
- Do not replace existing R1-R3 annual statement plumbing unless a task explicitly says so.
- Do not make the filing spoon-feed truth state, confidence, source quality, or price direction.

## Working rules

- The full filing document must be lazy-generated on button click, not prebuilt during daily simulation.
- Simulation state stores compact truths, facts, metrics, and provenance; display paragraphs are derived.
- Generated filings must be deterministic for the same run seed, company id, fiscal year, and filing version.
- Cache key should include at least `run_seed`, `company_id`, `fiscal_year`, and `filing_version`.
- Visible filing text must not show hidden ids such as `story|`, `packet|`, `placement|`, `truth_state`, or source-quality labels.
- Prefer formal filing language with routine boilerplate and selected useful details mixed together.
- Preserve bottom-up play; this creates a deeper top-down verification surface, not the only valid route.
- One task per checkpoint commit; verify before each commit.

## Reference learnings

The AKR reference is enough to define the initial annual filing anatomy, tone, and disclosure style.

Useful reference patterns:

- A formal table of contents separates primary statements from notes.
- The useful information is not only in the main numbers; much of it is in notes.
- Auditor key audit matters can point to real risk areas without giving a trade answer.
- Segment information is a major surface for top-down analysis.
- Trade receivables, inventories, and working capital notes can reveal customer quality, demand pressure, or commodity exposure.
- Related-party transactions and commitments are often subtle but important.
- Risk management notes can connect commodity, FX, credit, liquidity, and interest-rate exposure.
- Subsequent events can connect macro/geopolitical context to company risk.
- Large accounting policy sections create realistic noise; not every paragraph should be useful.

Sector limitation:

- The AKR file is enough for the base document model and trading/logistics/industrial-estate style.
- More sector references should be added later for banks, mining, consumer, property, manufacturing, telecom/infrastructure, and plantation/agriculture.
- Do not block the first implementation on more PDFs; build the base filing engine first.

## Target filing anatomy

The generated reader should eventually support this annual filing structure:

| Section | Purpose |
|---|---|
| Cover / company identity | Company name, fiscal year, report type, currency/unit |
| Directors' statement / responsibility note | Formal filing texture, mostly low-clue boilerplate |
| Independent auditor report | Audit status, key audit matter, risk focus |
| Table of contents | A4-style navigation and page labels |
| Consolidated statement of financial position | Balance sheet rows with note references |
| Consolidated statement of profit or loss and other comprehensive income | Revenue, margin, operating result, finance cost, tax |
| Consolidated statement of changes in equity | Dividends, retained earnings, issuance/buyback effects |
| Consolidated statement of cash flows | Operating, investing, financing, capex/debt/cash bridge |
| Notes - company information | Business lines, locations, subsidiaries, employees |
| Notes - accounting policies | Formal boilerplate and estimation policy noise |
| Notes - receivables/inventory/PPE/debt | Selected rows and story footprints |
| Notes - revenue/expenses/tax/equity | Performance detail and comparative movement |
| Notes - related parties | Subtle transaction patterns and conflicts |
| Notes - segment information | Top-down sector/subsector verification surface |
| Notes - commitments/agreements/contingencies | Expansion, partnerships, obligations, claims |
| Notes - financial risk management | Commodity, credit, FX, interest, liquidity risk |
| Notes - non-cash and subsequent events | After-reporting-date macro/company events |

## Disclosure philosophy

The filing should not say: "This company has a bullish transformation story."

It should instead scatter evidence like:

- higher PPE additions and investing cash outflow
- new debt or refinancing language
- changed segment revenue/profit mix
- inventory growth or margin pressure
- receivable aging or credit-loss movement
- related-party or customer concentration notes
- commitment paragraphs about land, supply, facility, contract, or project obligations
- risk language about commodity price, FX, credit, liquidity, or regulation
- subsequent-event language that mentions external conditions after year-end

The player conclusion should be assembled from these pieces.

## Status

| # | Task | Est. cost | Status |
|---|---|---|
| 1 | Define lazy annual filing document contract and cache key | ~10-20% | Complete |
| 2 | Define filing anatomy and disclosure section schema | ~15-25% | Complete |
| 3 | Add accounting-footprint packet model | ~20-35% | Complete |
| 4 | Build natural filing prose library and boilerplate/noise rules | ~20-35% | Complete |
| 5 | Generate annual filing document on button click | ~20-40% | Complete |
| 6 | Rework reader UI toward A4 page reading and virtualized sections | ~20-40% | Complete |
| 7 | Update evidence capture for document snippets, rows, tables, and references | ~15-30% | Complete |
| 8 | Add fidelity, performance, and cache regression tests | ~15-30% | Complete |

Recommended batching: **Session 1 = Tasks 1-2** because the lazy document/cache contract and filing anatomy should be locked before implementation. **Session 2 = Task 3** because accounting footprints are the bridge between story truth and filing clues. **Session 3 = Task 4** because prose quality should be built after the document shape is stable. **Session 4 = Tasks 5-6** because generation and reader rendering need to move together. **Session 5 = Tasks 7-8** to harden evidence capture and performance.

## Progress log

### 2026-06-21 - Plan created

- Created this separate enhancement plan because `FINANCIAL_STATEMENT_LAYER_ENHANCEMENT.md` now mostly serves as the completed R1-R3 implementation history.
- Product correction:
  - current annual report behavior is useful technically but still feels too explicit
  - next work should target document-reading gameplay, not more evidence-card prose
  - the generated filing should be created only when the player clicks `View Consolidated Financial Statement`
- Reference basis:
  - AKR annual statement extraction is available through the local PDF extraction tool outside the game folder
  - the reference supports annual report anatomy, note tone, segment/commitment/risk patterns, and boilerplate/noise balance
- No code, data, runtime behavior, or tests changed by this planning step.

### 2026-06-21 - Task 1 complete

- Added `systems/AnnualFilingDocument.gd` as the pure lazy annual filing request/cache contract.
- The new contract defines:
  - schema version `1`
  - document type `annual_filing`
  - document status `r1_lazy_contract_ready`
  - generation timing `lazy_on_request`
  - cache owner `in_memory_runtime`
  - filing version `annual_filing_reader_r1`
  - cache key parts for run seed, company id, fiscal year, filing version, language id, sector style id, and source state hash
  - invalidation fields for fiscal year, filing version, language/style, and source state hash
- Added an in-memory cache path through `AnnualFilingDocument.get_or_build_document(...)`.
- Wired the existing `View Consolidated Financial Statement` button path in `StockController.gd` to request the annual filing document before rendering the existing R3 annual statement source.
- The Task 1 document intentionally kept `visible_document_generated = false`; Task 5 now materializes the visible filing document only through the lazy request path.
- Added `AnnualFilingLazyContractTest` and scene.
- Locked fixed-seed lazy contract hash `1374326765` for company `hahe`, FY2019, cache key `annual_filing|20260621|hahe|2019|annual_filing_reader_r1|en|health|1614170988|700723473`.
- Task 3 later updated the lazy contract hash to `653488372` by adding `accounting_footprint_hash` to cache invalidation; Task 4 later updated the hash to `1258270729` by adding `filing_prose_hash`; Task 5 later updated the current hash to `1982276232` after visible filing generation became part of the lazy document payload.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualFilingLazyContractTest.tscn` -> `ANNUAL_FILING_LAZY_CONTRACT_OK {"hash":"1374326765",...}` at Task 1 time; current Task 5 hash is `1982276232`
  - `/Users/user/.local/bin/godot --headless -e --quit` -> passed
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualReportDocumentContractTest.tscn` -> `ANNUAL_REPORT_DOCUMENT_CONTRACT_OK {"hash":"2037575392",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualReportFidelityCaptureTest.tscn` -> `ANNUAL_REPORT_FIDELITY_CAPTURE_OK {"hash":"906899410",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11`

### 2026-06-21 - Task 2 complete

- Expanded `systems/AnnualFilingDocument.gd` with the formal annual filing anatomy schema.
- The schema now defines 20 deterministic filing sections:
  - four front-matter sections: cover, directors' responsibility statement, independent auditor report, and table of contents
  - four primary statements with page labels `1-3`, `4-5`, `6-7`, and `8-9`
  - twelve note groups covering company information, policies, assets, inventories, PPE/investments, liabilities/borrowings, performance/tax/equity, related parties, segment information, commitments/contingencies, financial risk management, and non-cash/subsequent events
- Added section metadata for filing title, localized title, document part, page label/range, read mode, clue density, boilerplate density, evidence capture mode, virtual-page group, capture support, source section, source array, and note-type filters.
- Added a deterministic filing schema hash and included it in the annual filing cache key and invalidation fields.
- Added the expanded R3 source-section map so the current five-section annual statement source can feed the new 20-section filing anatomy without changing the visible reader yet.
- Added `AnnualFilingAnatomySchemaTest` and scene.
- Locked fixed-seed anatomy hash `230195522` and filing schema hash `700723473` for company `hahe`, FY2019.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualFilingAnatomySchemaTest.tscn` -> `ANNUAL_FILING_ANATOMY_SCHEMA_OK {"hash":"230195522","filing_schema_hash":"700723473",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualFilingLazyContractTest.tscn` -> `ANNUAL_FILING_LAZY_CONTRACT_OK {"hash":"1374326765","filing_schema_hash":"700723473",...}` at Task 2 time; current Task 5 hash is `1982276232`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualReportDocumentContractTest.tscn` -> `ANNUAL_REPORT_DOCUMENT_CONTRACT_OK {"hash":"2037575392",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualReportFidelityCaptureTest.tscn` -> `ANNUAL_REPORT_FIDELITY_CAPTURE_OK {"hash":"906899410",...}`
  - `/Users/user/.local/bin/godot --headless -e --quit` -> passed
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11`
  - `git diff --check` -> passed

### 2026-06-21 - Task 3 complete

- Added the accounting-footprint packet model to `systems/AnnualFilingDocument.gd`.
- The model defines nine footprint types: numeric movement, statement-row note reference, note paragraph, compact table row, cross-note reference, auditor risk focus, segment movement, risk-management language, and subsequent-event language.
- Added deterministic archetype-to-footprint pattern mapping for commodity tailwinds/headwinds, capex expansion, contract wins, margin recovery, balance-sheet stress, governance/fraud signals, turnaround stories, and corporate-action use-of-proceeds.
- Footprints are built from existing `disclosure_packet_refs`; Task 3 does not add new saved runtime truth and does not change the visible reader output yet.
- Added `accounting_footprint_hash` to the annual filing cache key, cache key parts, and invalidation fields so document generation changes when the footprint bridge changes.
- Added `AnnualFilingFootprintPacketTest` and scene.
- Locked fixed-seed footprint packet hash `1286418835` for company `hahe`, FY2019:
  - footprint hash `158179705`
  - 22 footprint packets
  - one story distributed across multiple footprint types
- Updated `AnnualFilingLazyContractTest` fixed-seed hash to `653488372` because the cache key now includes `accounting_footprint_hash`.
- Task 4 later updated the current lazy contract hash to `1258270729` by adding `filing_prose_hash`; Task 5 later updated it to `1982276232` by adding generated visible filing payloads.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualFilingLazyContractTest.tscn` -> `ANNUAL_FILING_LAZY_CONTRACT_OK {"hash":"653488372","accounting_footprint_hash":"158179705",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualFilingAnatomySchemaTest.tscn` -> `ANNUAL_FILING_ANATOMY_SCHEMA_OK {"hash":"230195522","filing_schema_hash":"700723473",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualFilingFootprintPacketTest.tscn` -> `ANNUAL_FILING_FOOTPRINT_PACKET_OK {"hash":"1286418835","footprint_count":22,"footprint_hash":"158179705",...}`

### 2026-06-21 - Task 4 complete

- Added the natural filing prose library and boilerplate/noise model to `systems/AnnualFilingDocument.gd`.
- The prose model now defines:
  - schema version `1`
  - status `task4_prose_library_ready`
  - 13 template types covering company information, accounting policies, estimates and judgments, receivables, inventories, PPE/capex, borrowings, revenue, segment information, related parties, commitments, risk management, and subsequent events
  - sector-style vocabulary for `generic_annual_filing` and the AKR-like `trading_logistics_industrial_estate` style
- `AnnualFilingDocument.build_filing_prose_packets(...)` now builds deterministic section prose packets from the filing anatomy and accounting footprints.
- The prose output intentionally mixes:
  - routine boilerplate and policy paragraphs with `none`/`low` clue density
  - quantified footprint paragraphs that reference existing statement rows and amounts
  - formal risk, segment, cross-reference, audit-focus, and subsequent-event language
- Visible prose text does not expose hidden ids, source-quality labels, truth labels, confidence labels, or trade-answer wording; provenance stays in metadata for later capture work.
- Added `filing_prose_hash` to the annual filing cache key, cache key parts, and invalidation fields.
- Added `AnnualFilingProseLibraryTest` and scene.
- Locked fixed-seed prose library hash `1676592393` for company `hahe`, FY2019:
  - prose hash `207705355`
  - 42 prose packets
  - 20 routine/policy/estimate boilerplate packets
  - 22 footprint-linked prose packets
- Updated `AnnualFilingLazyContractTest` fixed-seed hash to `1258270729` because the cache key now includes `filing_prose_hash`.
- Task 5 later updated the current lazy contract hash to `1982276232` because the generated visible filing payload is now included in the lazy document hash.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualFilingProseLibraryTest.tscn` -> `ANNUAL_FILING_PROSE_LIBRARY_OK {"hash":"1676592393","prose_hash":"207705355","prose_count":42,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualFilingLazyContractTest.tscn` -> `ANNUAL_FILING_LAZY_CONTRACT_OK {"hash":"1258270729","filing_prose_hash":"207705355",...}` at Task 4 time; current Task 5 hash is `1982276232`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualFilingAnatomySchemaTest.tscn` -> `ANNUAL_FILING_ANATOMY_SCHEMA_OK {"hash":"230195522",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualFilingFootprintPacketTest.tscn` -> `ANNUAL_FILING_FOOTPRINT_PACKET_OK {"hash":"1286418835",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualReportDocumentContractTest.tscn` -> `ANNUAL_REPORT_DOCUMENT_CONTRACT_OK {"hash":"2037575392",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualReportFidelityCaptureTest.tscn` -> `ANNUAL_REPORT_FIDELITY_CAPTURE_OK {"hash":"906899410",...}`
  - `/Users/user/.local/bin/godot --headless -e --quit` -> passed
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11`
  - `git diff --check` -> passed

### 2026-06-22 - Task 5 complete

- Added the visible annual filing materializer to `systems/AnnualFilingDocument.gd`.
- `AnnualFilingDocument.build_document_from_statement(...)` now converts the lazy contract into a full visible filing document only when the report button path requests it.
- The generated document now includes:
  - status `task5_visible_filing_ready`
  - generation status `task5_visible_filing_generated`
  - visible filing hash
  - 20 filing sections, including front matter, primary statements, table of contents, and note groups
  - section lookup by id
  - visible paragraphs derived from formal prose packets
  - compact note tables derived from accounting-footprint table rows
  - cross-note references derived from accounting-footprint references
  - generation-source metadata that confirms the display artifact is not saved to `RunState`
- `StockController.gd` now switches the financial statement overlay to the generated filing document after `View Consolidated Financial Statement` is clicked.
- The interim Task 5 reader bridge:
  - keeps primary statements on the existing row renderer
  - renders front matter and note groups as filing paragraphs, compact tables, and cross-references
  - preserves note-like capture compatibility for the later Task 7 capture pass
  - was later upgraded by Task 6 into the A4 chunked reader shell
- Added `AnnualFilingVisibleGenerationTest` and scene.
- Locked fixed-seed visible generation hash `1986473927` for company `hahe`, FY2019:
  - visible filing hash `781569065`
  - 20 visible sections
  - 42 visible paragraphs
  - 3 compact tables
  - 3 cross-references
- Updated `AnnualFilingLazyContractTest` current fixed-seed hash to `1982276232` because the cached document hash now includes the generated visible filing payload.
- Updated `SmokeTest.gd` to assert the generated annual filing reader shape instead of the old five-section source-statement bridge.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualFilingVisibleGenerationTest.tscn` -> `ANNUAL_FILING_VISIBLE_GENERATION_OK {"hash":"1986473927","visible_filing_hash":"781569065","section_count":20,"paragraph_count":42,"table_count":3,"cross_reference_count":3}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualFilingLazyContractTest.tscn` -> `ANNUAL_FILING_LAZY_CONTRACT_OK {"hash":"1982276232","filing_prose_hash":"207705355",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualFilingAnatomySchemaTest.tscn` -> `ANNUAL_FILING_ANATOMY_SCHEMA_OK {"hash":"230195522",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualFilingFootprintPacketTest.tscn` -> `ANNUAL_FILING_FOOTPRINT_PACKET_OK {"hash":"1286418835",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualFilingProseLibraryTest.tscn` -> `ANNUAL_FILING_PROSE_LIBRARY_OK {"hash":"1676592393",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualReportDocumentContractTest.tscn` -> `ANNUAL_REPORT_DOCUMENT_CONTRACT_OK {"hash":"2037575392",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualReportFidelityCaptureTest.tscn` -> `ANNUAL_REPORT_FIDELITY_CAPTURE_OK {"hash":"906899410",...}`
  - `/Users/user/.local/bin/godot --headless --path . --log-file logs/smoke-annual-filing-task5-clean.log --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11`

### 2026-06-22 - Task 6 complete

- Reworked the report overlay into an explicit A4 reader contract in `StockController.gd`.
- The financial statement page, page scroll, and body now expose `a4_virtualized_sections` reader metadata and A4 page-size metadata for smoke coverage.
- Added responsive page margins so the A4 shell keeps stable document spacing on narrow and desktop-width viewports.
- Generated filing note/front-matter sections now render into named section chunks:
  - `FinancialStatementReportSectionChunk_<section_id>_<chunk_index>`
  - four display controls per chunk
  - per-chunk metadata for reader mode, page size, section id, chunk index, and max chunk items
- Statement rows and compact note tables now use responsive value/reference widths so smaller A4 pages stay readable.
- Updated `SmokeTest.gd` to assert:
  - the report page uses A4 metadata and `a4_virtualized_sections` mode
  - the inner report scroll is vertical-only
  - page margins remain bounded and responsive
  - generated note sections render through chunk containers
  - rendered chunk count remains bounded
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --quit` -> passed
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualFilingVisibleGenerationTest.tscn` -> `ANNUAL_FILING_VISIBLE_GENERATION_OK {"hash":"1986473927","visible_filing_hash":"781569065","section_count":20,"paragraph_count":42,"table_count":3,"cross_reference_count":3}`
  - `/Users/user/.local/bin/godot --headless --path . --log-file logs/smoke-annual-filing-task6.log --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11`

### 2026-06-22 - Task 7 complete

- Updated annual filing evidence capture so the reader behaves like selecting neutral filing excerpts rather than collecting pre-labeled clue cards.
- `StockController.gd` now tags rendered filing controls with `financial_statement_capture_payload` metadata for smoke/debug inspection.
- Statement rows, note paragraphs, cross-note references, and note compact table rows now carry neutral `Annual Filing` source labels plus filing-specific metadata:
  - `filing_capture_type`
  - `filing_section_id`
  - `filing_excerpt_id`
  - `filing_visible_label`
  - `filing_visible_text`
  - `source_excerpt`
- Compact note table rows are now clickable/capturable excerpt surfaces.
- Capture typing now distinguishes:
  - `statement_row`
  - `note_paragraph`
  - `note_table_row`
  - `cross_reference`
  - `segment_row`
  - `auditor_key_matter_paragraph`
  - `subsequent_event_paragraph`
- Updated `ThesisEvidenceCaptureSystem.gd`, `ThesisManager.gd`, and `RunState.gd` allowlists so filing metadata survives:
  - Research Tray capture
  - Research Tray attach to thesis
  - direct thesis add
  - save/load normalization
- Research evidence dedupe now also considers `filing_section_id` and `filing_excerpt_id` so filing excerpts remain stable even when labels or values are similar.
- Updated `SmokeTest.gd` to assert:
  - every required annual filing capture type exists in the rendered reader
  - visible payload fields do not expose hidden truth/confidence/source-quality tokens
  - all required filing metadata survives Research Tray capture
  - duplicate statement-row capture dedupes
  - attached and directly-added filing evidence survives save/load
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --quit` -> passed
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualFilingVisibleGenerationTest.tscn` -> `ANNUAL_FILING_VISIBLE_GENERATION_OK {"hash":"1986473927","visible_filing_hash":"781569065","section_count":20,"paragraph_count":42,"table_count":3,"cross_reference_count":3}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11`

### 2026-06-22 - Task 8 complete

- Added `AnnualFilingRegressionGuardTest` and scene as the fixed-seed regression gate for the lazy annual filing reader.
- Locked fixed-seed regression guard hash `1701463489` for company `hahe`, FY2019:
  - visible filing hash `781569065`
  - generated document size `564807` chars
  - contract/build/cache-hit timings stayed below the current guardrails
- The regression guard now verifies:
  - no pre-click derived filing display data in `RunState`
  - contract-only lazy request behavior
  - first request cache miss/build and second request cache hit
  - cache key invalidation when hashed source traceability changes
  - 20-section anatomy, TOC order, primary statement page labels, and required note sections
  - visible section/table/reference bounds and hidden-token safety
- Updated `SmokeTest.gd` with a rendered-control-count guard for the A4 filing reader; the current reader baseline is 448 controls, guarded at `<= 520`.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualFilingRegressionGuardTest.tscn` -> `ANNUAL_FILING_REGRESSION_GUARD_OK {"hash":"1701463489","company_id":"hahe","fiscal_year":2019,"visible_filing_hash":"781569065","document_chars":564807,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualFilingLazyContractTest.tscn` -> `ANNUAL_FILING_LAZY_CONTRACT_OK {"hash":"1982276232",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualFilingVisibleGenerationTest.tscn` -> `ANNUAL_FILING_VISIBLE_GENERATION_OK {"hash":"1986473927","visible_filing_hash":"781569065","section_count":20,"paragraph_count":42,"table_count":3,"cross_reference_count":3}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualReportFidelityCaptureTest.tscn` -> `ANNUAL_REPORT_FIDELITY_CAPTURE_OK {"hash":"906899410",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11`

### 2026-06-22 - Duplicate visible filing text follow-up

- Fixed duplicate player-facing text in generated annual filing sections.
- First duplicate path: multiple accounting footprints could resolve to identical formal prose inside the same note section, so risk-management, segment, inventory, and cross-note-reference wording could render as repeated paragraphs.
- Second duplicate path: multiple compact-table footprints could resolve to the same caption/value/related-note row, such as repeated cash and cash equivalents rows in commitments/contingencies notes.
- `AnnualFilingDocument.gd` now dedupes visible paragraphs, compact table rows, and cross-reference rows per section while merging source footprint, disclosure packet, story, statement-line, and note metadata into the retained visible item.
- Visible note-section headings now strip the `Notes - ` prefix, so reader headings are `Company Information`, `Segment Information`, `Commitments, Agreements, And Contingencies`, etc.
- The underlying accounting footprint packets and formal section ids are preserved; only the player-facing visible annual filing document is cleaned.
- Added regression coverage so exact duplicate paragraph text, duplicate compact table row keys, and exact duplicate cross-reference text cannot appear inside the same visible filing section, and visible note titles cannot keep the `Notes - ` prefix.
- Updated deterministic visible-filing baselines:
  - `AnnualFilingVisibleGenerationTest` hash `1774995968`, visible filing hash `1961685698`, paragraph count `38`, table count `4`, cross-reference count `3`
  - `AnnualFilingRegressionGuardTest` hash `176770381`, visible filing hash `1961685698`
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualFilingVisibleGenerationTest.tscn` -> `ANNUAL_FILING_VISIBLE_GENERATION_OK {"hash":"1774995968","visible_filing_hash":"1961685698","section_count":20,"paragraph_count":38,"table_count":4,"cross_reference_count":3}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualFilingRegressionGuardTest.tscn` -> `ANNUAL_FILING_REGRESSION_GUARD_OK {"hash":"176770381","visible_filing_hash":"1961685698","document_chars":669655,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualReportFidelityCaptureTest.tscn` -> `ANNUAL_REPORT_FIDELITY_CAPTURE_OK {"hash":"906899410",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/TopDownResearchSurfaceIntegrationTest.tscn` -> `TOP_DOWN_RESEARCH_SURFACE_INTEGRATION_OK {"filing_document_sections":20,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=95485619.77 days=3`

---

## Task 1 - Define Lazy Annual Filing Document Contract And Cache Key

Problem: The game should not generate long annual filing documents during normal simulation. The filing should be built only when requested and then reopened from a deterministic cache.

1. Define a new annual filing document contract that sits above the current annual statement payload.
2. Define the cache key shape:
   - `run_seed`
   - `company_id`
   - `fiscal_year`
   - `filing_version`
   - optional `language_id` or `sector_style_id` if needed later
3. Decide cache owner:
   - preferred first pass: in-memory per open run
   - saved cache only if generation cost proves too high
4. Define invalidation rules:
   - fiscal year changes
   - filing version changes
   - company annual source state changes
5. Verify:
   - deterministic cache key probe
   - repeated generation returns the same document hash
   - no daily simulation path builds full filing text

Implementation status: complete. The lazy contract and cache key are now owned by `AnnualFilingDocument.gd`; the existing report button path requests the document into an in-memory cache. Task 5 later replaced the source-statement display bridge with the generated visible filing document.

## Task 2 - Define Filing Anatomy And Disclosure Section Schema

Problem: The document needs a realistic annual filing structure before prose or UI can be corrected.

1. Add a formal filing section schema for:
   - cover/company identity
   - auditor report / key audit matter
   - table of contents
   - four primary statements
   - note groups for company info, policies, assets, liabilities, equity, revenue, segment, related parties, commitments, risks, and subsequent events
2. Add section metadata:
   - section id
   - filing title
   - page label/range
   - clue density
   - boilerplate density
   - evidence capture mode
   - virtual-page grouping
3. Map existing R3 sections into the expanded anatomy without breaking current annual statement tests.
4. Verify:
   - section schema fingerprint
   - table-of-contents ordering test
   - no hidden truth/source labels in visible section titles

Implementation status: complete. The annual filing anatomy now lives in `AnnualFilingDocument.gd` as a deterministic 20-section schema above the current R3 annual statement source. Task 2 locked the filing map, TOC, source mapping, and cache invalidation behavior; Task 5 now consumes the schema for generated visible filing output.

## Task 3 - Add Accounting-Footprint Packet Model

Problem: Story Dossier packets currently map to filing note paragraphs, but the model still feels too direct. Stories need accounting footprints distributed across numbers, tables, policy language, risks, and commitments.

1. Define accounting-footprint packet types:
   - numeric movement
   - statement-row note reference
   - note paragraph
   - compact table row
   - cross-note reference
   - auditor risk focus
   - segment movement
   - risk-management language
   - subsequent-event language
2. Map story archetypes to footprint patterns:
   - commodity tailwind/headwind
   - capex expansion
   - contract win/loss
   - margin recovery/pressure
   - balance sheet stress
   - governance or related-party concern
   - turnaround/transformation
3. Keep every footprint traceable to source ids but not visibly labeled.
4. Verify:
   - one fixed-seed story appears across multiple footprint types
   - at least one useful clue is indirect or buried
   - no single packet reveals the complete story by itself unless configured as direct

Implementation status: complete. `AnnualFilingDocument.gd` now builds deterministic accounting-footprint packets above Story Dossier disclosure packets and the 20-section annual filing schema. Task 3 locked the clue-placement bridge, footprint metadata, cache invalidation, and fixed-seed coverage; Task 5 now folds those footprints into the generated visible filing.

## Task 4 - Build Natural Filing Prose Library And Boilerplate/Noise Rules

Problem: The visible text should sound like a formal filing, not a game-generated summary.

1. Create deterministic prose templates by section type:
   - company information
   - accounting policies
   - estimates and judgments
   - receivables
   - inventories
   - PPE/capex
   - borrowings
   - revenue
   - segment
   - related party
   - commitments
   - risk management
   - subsequent events
2. Add routine boilerplate paragraphs that are intentionally low-clue.
3. Add selected quantified paragraphs that mix normal movement with subtle story evidence.
4. Support sector-style vocabulary, starting with the AKR-like trading/logistics/industrial-estate style.
5. Verify:
   - prose fingerprint
   - hidden ids/truth labels absent
   - one fixed-seed document has both clue and non-clue paragraphs

Implementation status: complete. `AnnualFilingDocument.gd` now has a deterministic filing prose packet layer above the anatomy and accounting-footprint model. Task 4 locked formal boilerplate, quantified footprint prose, style vocabulary, prose hashing, cache invalidation, and fixed-seed coverage; Task 5 now renders those packets into the generated visible filing.

## Task 5 - Generate Annual Filing Document On Button Click

Problem: The full filing should be a lazy display artifact, not part of normal runtime simulation state.

1. Add a pure generator that builds the annual filing document from:
   - annual statement payload
   - company catalog/profile
   - company story dossier packets
   - living arc state
   - corporate action/event/roadmap state
   - macro/commodity state
2. Trigger generation from `View Consolidated Financial Statement`.
3. Cache the generated document for the current run/company/fiscal year.
4. Keep normal company-detail hydration from building full report prose.
5. Verify:
   - generation happens on first button click
   - second open uses cached document
   - generated document hash is deterministic
   - quick smoke still passes

Implementation status: complete. `AnnualFilingDocument.gd` now materializes the visible annual filing only through the lazy document request path, `StockController.gd` displays that generated filing after the existing report button is clicked, and `AnnualFilingVisibleGenerationTest` locks first-open generation, second-open cache hit behavior, deterministic visible-document hashing, no `RunState` saved-cache leakage, and hidden-token safety.

## Task 6 - Rework Reader UI Toward A4 Page Reading And Virtualized Sections

Problem: The player-facing reader should feel like a document, not a dashboard.

1. Render the filing as page-like A4 sections with stable margins and readable typography.
2. Add table-of-contents navigation by filing section.
3. Use virtualized or chunked rendering so long note sections do not hurt performance.
4. Keep statement tables readable on common desktop and smaller viewports.
5. Avoid obvious evidence-card styling.
6. Verify:
   - reader opens from the existing button
   - A4 bounds hold
   - table-of-contents jumps work
   - long notes do not render all controls unnecessarily
   - no obvious overlap in smoke viewport

Implementation status: complete. `StockController.gd` now renders generated annual filing sections inside an explicit A4 reader shell with responsive margins, vertical-only page scrolling, reader metadata, stable TOC anchors, and chunked generated section containers. `SmokeTest.gd` now locks the A4 reader contract, TOC jump, chunked note rendering, bounded chunk count, and generated filing section controls.

## Task 7 - Update Evidence Capture For Document Snippets, Rows, Tables, And References

Problem: Evidence capture should feel like selecting a filing excerpt, not adding a pre-labeled clue card.

1. Support capture from:
   - statement rows
   - note paragraphs
   - note table rows/cells
   - cross-note references
   - segment rows
   - auditor key audit matter paragraphs
   - subsequent event paragraphs
2. Preserve source metadata in the thesis evidence payload.
3. Keep visible evidence labels neutral and filing-like.
4. Avoid exposing hidden truth/confidence/source-quality labels.
5. Verify:
   - each capture type survives Research Tray, thesis attach, direct add, and save/load
   - captured evidence can still be deduped by source section and excerpt id

Implementation status: complete. Annual filing reader controls now expose neutral filing excerpt payloads for statement rows, note paragraphs, compact table rows, cross-note references, segment rows, auditor key audit matter paragraphs, and subsequent-event paragraphs. Thesis capture, direct add, and `RunState` save/load normalization now preserve filing source metadata, and quick smoke locks capture availability, hidden-token safety, dedupe, attach, direct-add, and save/load behavior.

## Task 8 - Add Fidelity, Performance, And Cache Regression Tests

Problem: This feature changes document length, generation timing, capture surfaces, and visible prose. Regressions need focused tests.

1. Add fixed-seed annual filing document hash coverage.
2. Add lazy-generation/cache tests:
   - no pre-click full filing generation
   - first click generates
   - second click reuses cache
3. Add document anatomy tests against the reference-inspired structure.
4. Add UI smoke for table of contents, A4 sections, long note rendering, and evidence capture.
5. Add performance guardrails for generation time and rendered control count.
6. Verify:
   - targeted annual filing tests pass
   - existing R1-R3 annual statement tests pass or are intentionally updated
   - quick smoke passes

Implementation status: complete. `AnnualFilingRegressionGuardTest` now locks the fixed-seed annual filing hash, lazy/cache behavior, source-state cache invalidation, document anatomy, visible bounds, hidden-token safety, document size, and timing guardrails. `SmokeTest.gd` now also guards the rendered A4 reader control count so long-document UI regressions are caught during quick smoke.

## Known traps

- Do not turn the report into another explicit clue summary.
- Do not generate the full filing every simulated day.
- Do not save massive derived paragraphs unless performance proves it is necessary.
- Do not make boilerplate so large that the player cannot find anything useful.
- Do not make every paragraph useful; realistic filings need noise.
- Do not make hidden truth states visible.
- Do not overfit all sectors to the AKR reference; use it as the base filing style, then add sector references later.
- Do not break existing thesis evidence and Research Tray provenance while changing visible text.
- Do not let long A4 rendering create layout or performance regressions.
