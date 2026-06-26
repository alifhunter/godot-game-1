# Financial Statement Layer Enhancement - Plan & Progress Log

This plan adds a player-facing financial statement and notes layer so company stories can be verified through revenue, margins, cash flow, capex, debt, customers, MD&A, and use-of-proceeds disclosures.
**Status: v1 complete - Tasks 1-6 complete. Revision R1 complete - R1.1-R1.6 complete. Revision R2 complete - R2.1-R2.5 complete. Revision R3 complete - R3.1-R3.6 complete.** Designed to run in a fresh session; everything needed to execute cold is in this file.

**Next product-direction note:** This file now mainly preserves the completed R1-R3 implementation history. The next correction pass has been split into [Annual Filing Reading Experience Enhancement](ANNUAL_FILING_READING_EXPERIENCE_ENHANCEMENT.md), focused on lazy on-click filing generation and a less explicit document-reading experience.

**Review verdict recap:** Real investing stories often become visible in financial statements and footnotes, not just headlines. The game already has financial profiles and quarterly filing payloads, but it does not yet have a deep statement/notes layer for story verification. This plan should produce plausible gameplay evidence without attempting full accounting-grade simulation.

## Where everything lives

| What | Where |
|---|---|
| Current financial builder | `systems/CompanyFinancialsBuilder.gd` |
| Current filing payload | `autoloads/RunState.gd` quarterly filing helpers |
| Current company data | `data/companies/` and generated company state |
| Planned story input | Company story dossier system |
| UI consumers | Company app widgets, thesis board, future top-down research UI |
| Tests/probes | `scripts/tests/FinancialStatementLayerStoryEffectTest.gd`; `scripts/tests/FinancialStatementLayerDisclosureTest.gd`; `scripts/tests/FinancialStatementLayerThesisCaptureTest.gd`; `scripts/tests/FinancialStatementLayerSnapshotMatrixTest.gd`; `scripts/tests/AnnualConsolidatedStatementBuilderTest.gd`; `scripts/tests/AnnualReportDocumentContractTest.gd`; `scripts/tests/AnnualStatementAccountingContinuityTest.gd`; `scripts/tests/AnnualStatementFilingNoteBodyTest.gd`; `scripts/tests/AnnualStatementEnrichmentPassTest.gd`; `scripts/tests/AnnualStatementStorySourceEnrichmentTest.gd`; `scripts/tests/AnnualStatementActionEventRoadmapEnrichmentTest.gd`; `scripts/tests/AnnualStatementFullTraceabilityContractTest.gd`; `scripts/tests/AnnualReportFidelityCaptureTest.gd`; `scripts/tests/SmokeTest.gd` |
| Key functions | Locate by quarterly filing payload builders, financial profile generation, and company detail UI readers |

## Goals

- Add statement periods and structured statement data for companies.
- Generate notes and MD&A-style disclosures from company story facts.
- Let players verify transformation, capex, corporate action, customer, and margin stories through financial evidence.

## Non-goals

- Do not build a professional accounting engine.
- Do not model every accounting standard or line item.
- Do not make every footnote obvious; some should be subtle or incomplete.

## Working rules

- Statements should be plausible and internally consistent enough for gameplay.
- Generated notes must be deterministic.
- Story-driven statement changes should remain traceable for tests.
- Use compact saved state; derive display text when possible.

## Status

### V1 tasks

| # | Task | Est. cost | Status |
|---|---|---|---|
| 1 | Define statement and note schema | ~15-25% | Complete |
| 2 | Map story effects into statement changes | ~20-35% | Complete |
| 3 | Generate MD&A and footnote disclosures | ~20-35% | Complete |
| 4 | Add company app or report display path | ~20-35% | Complete |
| 5 | Add thesis capture from statements | ~10-20% | Complete |
| 6 | Add statement verification tests | ~10-20% | Complete |

### Revision R1 tasks

| # | Task | Est. cost | Status |
|---|---|---|---|
| R1.1 | Lock annual consolidated statement reference contract | ~5-10% | Complete |
| R1.2 | Add prior-year full-year statement source | ~15-25% | Complete |
| R1.3 | Build A4-style consolidated statement report shell | ~20-35% | Complete |
| R1.4 | Rename and reroute the Financials entry button | ~5-10% | Complete |
| R1.5 | Align statement sections, notes, and thesis capture metadata | ~15-25% | Complete |
| R1.6 | Add annual/A4 layout and content verification tests | ~10-20% | Complete |

### Revision R2 tasks

| # | Task | Est. cost | Status |
|---|---|---|---|
| R2.1 | Define post-start annual statement enrichment pass | ~10-20% | Complete |
| R2.2 | Feed Story Dossier and Living Company Arc IDs into annual note facts | ~15-30% | Complete |
| R2.3 | Feed corporate action, event, and roadmap provenance into annual note facts | ~15-30% | Complete |
| R2.4 | Preserve enriched provenance through Research Tray, thesis evidence, and save/load | ~10-20% | Complete |
| R2.5 | Add deterministic enrichment and traceability tests | ~10-20% | Complete |

### Revision R3 tasks

| # | Task | Est. cost | Status |
|---|---|---|---|
| R3.1 | Define document-reading contract and annual report section map | ~10-20% | Complete |
| R3.2 | Expand accounting row model and statement continuity | ~20-35% | Complete |
| R3.3 | Build filing-style note bodies and cross-note references | ~20-35% | Complete |
| R3.4 | Rework the A4 report into a document reader flow | ~20-35% | Complete |
| R3.5 | Consume subtle disclosure placements from Story Dossier Revision R1 | ~15-30% | Complete |
| R3.6 | Add annual report fidelity, capture, and smoke tests | ~10-20% | Complete |

Recommended batching for v1, Revision R1, Revision R2, and Revision R3 is complete. R2.1-R2.5 cover the contract/lifecycle pass, annual-note source mapping, capture preservation, and fixed-seed full traceability regression coverage. Company Story Dossier R1 is complete, including the final Financial Statement R3 bridge fixture. R3.1-R3.6 now cover the document-reading contract, accounting continuity, filing-note bodies, reader UI flow, packet paragraph rendering, and final annual report fidelity/capture/smoke coverage.

## Progress log

### 2026-06-17 - Revision R1 planning added

- Added this revision plan as documentation only; no code changes were made for the revision yet.
- Reference input:
  - User-provided annual consolidated financial statement PDF: `/Users/user/Downloads/PT AKR Corporindo Tbk. 31 Dec 2025_released.pdf`
  - Local file probe confirmed it is a 153-page PDF.
  - User screenshot/reference shows a bilingual annual statement contents flow:
    - Consolidated Statement of Financial Position
    - Consolidated Statement of Profit or Loss and Other Comprehensive Income
    - Consolidated Statement of Changes in Equity
    - Consolidated Statement of Cash Flows
    - Notes to the Consolidated Financial Statements
- Revision direction:
  - The UI entry should be named `View Consolidated Financial Statement`.
  - The report should show a full-year annual statement for the year before the current starting year, e.g. FY2019 for a 2020 run start.
  - The page should feel like an A4 annual report document, not a compact app card.
  - The content order should follow the reference PDF's consolidated statement structure while staying simplified for gameplay.

### 2026-06-17 - Revision R1 note-generation scope clarified

- Clarified that many annual-note source systems already exist:
  - Company catalog/profile data can support company information, sector, subsector, moats, and exposures.
  - Company Story Dossier and Living Company Arc state can support story-linked notes, commitments, contingencies, and subsequent events.
  - Corporate action state can support equity, dividends, and use-of-proceeds notes.
  - Existing generated financial profile and quarterly filing data can support core statement rows.
- Missing piece is not a brand-new story system. The missing piece is a deterministic annual statement/note adapter that maps current game state into annual-report sections and note rows.
- Revision R1 should add deterministic derivation rules for rows the current financial profile does not explicitly store yet, such as opex split, receivables, inventories, PPE, retained earnings, dividends, segment split, and annual note payloads.

### 2026-06-17 - Revision R1.1-R1.2 complete

- Added `systems/AnnualStatementBuilder.gd` as the deterministic annual consolidated statement source.
- R1.1 contract is now locked in generated annual statements:
  - `statement_scope = "annual"`
  - `consolidated = true`
  - `fiscal_year = 2019`
  - `comparative_year = 2018`
  - `statement_period_label = "FY2019"`
  - `report_title = "Consolidated Financial Statements"`
  - `page_size_hint = "A4"`
  - `audit_status = "audited"`
- Annual document sections now match the reference structure:
  - `financial_position`
  - `profit_or_loss_and_oci`
  - `changes_in_equity`
  - `cash_flows`
  - `notes`
- R1.2 source is now generated at company-detail hydration through `CompanyFinancialsBuilder`.
- The generated annual statement is stored beside the quarterly snapshot as:
  - `financial_statement_snapshot.annual_statement`
  - `financial_statement_snapshot.annual_statements`
  - `annual_statement_year`, `annual_statement_period_label`, and `annual_statement_count`
- `RunState._statement_snapshot_from_quarters` now preserves annual statement fields when quarterly filings refresh the snapshot.
- `RunState._build_statement_snapshot_view` exposes `annual_statement` and, when statement history is requested, `annual_statements`.
- Added a 14-row deterministic `note_index` as an annual report note outline. R1.5 later added full generated note rows/prose.
- Added `AnnualConsolidatedStatementBuilderTest`.
- Locked annual statement baseline hash `79759363`; R1.5 later updated the baseline to `2029322553` after generated note rows became part of the payload.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualConsolidatedStatementBuilderTest.tscn` -> `ANNUAL_CONSOLIDATED_STATEMENT_BUILDER_OK {"hash":"2029322553","fiscal_year":2019,"note_count":14,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/FinancialStatementLayerStoryEffectTest.tscn` -> `FINANCIAL_STATEMENT_LAYER_STORY_EFFECT_OK {"hash":"353480211",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/FinancialStatementLayerDisclosureTest.tscn` -> `FINANCIAL_STATEMENT_LAYER_DISCLOSURE_OK {"hash":"1824588069",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/FinancialStatementLayerSnapshotMatrixTest.tscn` -> `FINANCIAL_STATEMENT_LAYER_SNAPSHOT_MATRIX_OK {"hash":"1888558735",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/FinancialStatementLayerThesisCaptureTest.tscn` -> `FINANCIAL_STATEMENT_LAYER_THESIS_CAPTURE_OK`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyGenerationFingerprintTest.tscn` -> `COMPANY_GENERATION_FINGERPRINT_OK {"hash":"1225696160",...}`

### 2026-06-17 - Revision R1.3 complete

- Reworked the existing Financials report overlay into an A4-style annual report shell.
- Added a centered `FinancialStatementReportPage` node with:
  - portrait A4 aspect ratio
  - white paper surface
  - page margins
  - bounded scaling for narrower viewports
  - scrollable vertical overflow
- The report body now renders from `financial_statement_snapshot.annual_statement` when available, falling back to the selected quarterly period only when annual data is missing.
- Added a formal document header with:
  - company ticker and name
  - `Consolidated Financial Statements`
  - FY2019 year-ended period line
  - comparative year, currency, unit, and audit status metadata
- Replaced compact app-card report sections with document-style section blocks:
  - Consolidated Statement of Financial Position
  - Consolidated Statement of Profit or Loss and Other Comprehensive Income
  - Consolidated Statement of Changes in Equity
  - Consolidated Statement of Cash Flows
  - Notes to the Consolidated Financial Statements
- The notes section initially rendered the 14-row deterministic annual `note_index` outline. R1.5 later replaced this with generated annual note rows when available.
- Smoke coverage now asserts:
  - the A4 page node exists
  - page ratio stays in the A4 portrait range
  - the page stays horizontally inside the overlay
  - FY2019 annual consolidated section text is present
- Verification:
  - `/Users/user/.local/bin/godot --headless -e --quit`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualConsolidatedStatementBuilderTest.tscn` -> `ANNUAL_CONSOLIDATED_STATEMENT_BUILDER_OK {"hash":"2029322553",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/FinancialStatementLayerThesisCaptureTest.tscn` -> `FINANCIAL_STATEMENT_LAYER_THESIS_CAPTURE_OK`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11 days=3 ...`
  - `git diff --check`

### 2026-06-14 - Plan created

- Created this enhancement plan from the top-down market brainstorming session.
- Current inventory:
  - Financial profiles and quarterly filing payloads already exist.
  - The game does not yet expose full statement/note verification for stories.
  - Footnotes and MD&A are high-value but high-complexity, so the first pass should stay focused.
- No code or data changes were made by this planning step.

### 2026-06-17 - Task 1 complete

- Defined the v1 financial statement period, section, note, and traceability schema.
- Chosen model:
  - extend the existing quarterly statement snapshot shape instead of creating a parallel accounting system
  - keep current `income_statement`, `balance_sheet`, and `cash_flow` arrays compatible
  - add optional `operating_metrics`, `notes`, `story_adjustments`, and `traceability` arrays for story verification
- Defined period metadata:
  - statement identity, company identity, fiscal quarter/year, filing day/date, period scope, restatement/amendment flags, audit status, currency, and unit
- Defined v1 note types:
  - use-of-proceeds, capex progress, customer concentration, margin movement, debt change, inventory, receivables, management outlook, commodity realization, input cost pressure, backlog/contract, related party, accounting policy, segment performance, working capital, liquidity, governance, statement contradiction, and turnaround progress
- Runtime behavior note:
  - Task 1 is design-only. No code, save payload, statement generation, UI, thesis, or price behavior changed.
- Verification:
  - `git diff --check`

### 2026-06-17 - Task 2 complete

- Added `systems/FinancialStatementLayer.gd` as the pure statement-effect mapper.
- Wired quarterly filing generation in `RunState` so base quarterly statements are adjusted by active company story dossiers before `financials_after`, growth, margin, and surprise score are derived.
- Current mapper behavior:
  - reads dossier `financial_effects`
  - applies bounded deltas to known statement lines
  - creates missing compatible lines when the metric did not exist yet
  - maps operating metrics into `operating_metrics`
  - adds `story_adjustments` rows with `story_id`, `effect_id`, `metric_id`, direction, magnitude band, delta amount, before/after value, fact ids, and clue ids
  - annotates adjusted statement lines with `source_story_ids` and `source_effect_ids`
  - adds statement-level traceability arrays for source stories, facts, effects, clues, and generated adjustments
- Guardrails:
  - unknown/mixed-direction effects do not move numbers
  - deltas are capped by metric, current value, and base revenue
  - existing statement line `id` values stay compatible
  - hidden `truth_state` is not copied into statement rows or adjustments
- Runtime behavior note:
  - Quarterly filings now reflect active dossier financial effects in a bounded way.
  - No new UI, MD&A prose, note text generation, or thesis capture behavior was added yet.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/FinancialStatementLayerStoryEffectTest.tscn` -> `FINANCIAL_STATEMENT_LAYER_STORY_EFFECT_OK {"hash":"353480211",...}`
  - `/Users/user/.local/bin/godot --headless -e --quit`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyStoryDossierConsistencyTest.tscn` -> `COMPANY_STORY_DOSSIER_CONSISTENCY_OK {"hash":"2006435509","issue_count":0,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11 days=3 ...`
  - `git diff --check`

### 2026-06-17 - Task 3 complete

- Extended `FinancialStatementLayer` to generate deterministic structured filing notes after story adjustments are applied.
- Current note behavior:
  - groups adjustments by `story_id` and `note_type`
  - creates one stable `note_id` per grouped disclosure
  - fills note title/text keys, short summary, metric ids, fact ids, effect ids, clue ids, disclosure quality, detail level, access level, tone, importance, contradiction flag, and explain tags
  - writes each generated `note_id` back onto its related `story_adjustments`
  - adds `traceability.generated_note_ids`
- Disclosure clarity:
  - `statement_clues.disclosure_quality` is the primary public filing clarity input
  - `truth_state` is only used as a fallback to choose disclosure quality when no statement clue quality exists
  - relationship/access context can raise detail level without copying private truth fields into the statement row
- Added post-corporate-action support:
  - `use_of_proceeds` notes receive the `post_corporate_action` explain tag
  - summaries explicitly point the player toward proceeds use and the linked cash/capex/debt-style metrics
- Guardrails:
  - hidden `truth_state`, `fraud_risk`, `overhyped`, and similar raw story values are not copied into statement notes
  - note summaries stay short; long prose should still be generated later from `text_key` and structured fields
  - source `note_type` values from the dossier are preserved for provenance, even when they extend the first-pass taxonomy
- Added `FinancialStatementLayerDisclosureTest`.
- Locked disclosure baseline hash `1824588069`.
- Runtime behavior note:
  - Quarterly filings with active Story Dossier financial effects now also receive structured filing notes.
  - No new UI/report display or thesis evidence capture path was added yet.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/FinancialStatementLayerDisclosureTest.tscn` -> `FINANCIAL_STATEMENT_LAYER_DISCLOSURE_OK {"hash":"1824588069",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/FinancialStatementLayerStoryEffectTest.tscn` -> `FINANCIAL_STATEMENT_LAYER_STORY_EFFECT_OK {"hash":"353480211",...}`

---

## Task 1 - Define statement and note schema

Problem: Financial verification needs a stable data shape before content or UI work.

1. Define period fields such as quarter/year, reporting date, and restatement flags if needed.
2. Define simplified statement sections: income statement, balance sheet, cash flow, operating metrics, and notes.
3. Define note types such as use-of-proceeds, capex progress, customer concentration, margin movement, debt change, inventory, receivables, and management outlook.
4. Verify:
   - Design review in this doc.
  - `git diff --check`

### 2026-06-17 - Task 4 complete

- Added a `Report` button to the STOCKBOT Financials tab.
- The button opens a full-screen overlay with a compact white filing/report panel.
- The report view is scrollable and renders the selected period's income statement, balance sheet, cash flow, operating metrics, and Notes & MD&A.
- Added inline Financials tab cards for operating metrics and Notes & MD&A so statement-layer fields are visible before opening the full report.
- Statement note rows show title, disclosure quality/detail, summary, metrics, tone, and importance.
- Statement rows and note rows remain capturable through the existing financial statement research action menu.
- `RunState._statement_snapshot_from_quarters` now exposes latest `operating_metrics`, `notes`, `story_adjustments`, and `traceability` at the top level as well as inside `quarterly_statements`.
- `StockController` statement cache keys now include selected-period display signature so notes and operating metrics refresh correctly.
- Runtime behavior note:
  - This adds a player-facing statement/report display path.
  - No new thesis scoring behavior was added; note capture metadata is preserved for future Task 5.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/FinancialStatementLayerDisclosureTest.tscn` -> `FINANCIAL_STATEMENT_LAYER_DISCLOSURE_OK {"hash":"1824588069",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/FinancialStatementLayerStoryEffectTest.tscn` -> `FINANCIAL_STATEMENT_LAYER_STORY_EFFECT_OK {"hash":"353480211",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/ThesisResearchTrayTest.tscn` -> `THESIS_RESEARCH_TRAY_OK`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/ThesisFingerprintTest.tscn` -> `THESIS_FINGERPRINT_OK {"hash":"674019173",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11 days=3 ...`
  - `/Users/user/.local/bin/godot --headless -e --quit`

### Task 1 schema now defined

#### Design direction

The financial statement layer should deepen the existing quarterly filing system instead of replacing it.

Current runtime already stores and updates:

- `financial_statement_snapshot`
- `quarterly_statements`
- latest `income_statement`
- latest `balance_sheet`
- latest `cash_flow`
- quarterly filing payloads from `RunState`

The v1 layer should keep those shapes readable by existing code and add optional fields that future tasks can consume. Old readers should keep working if they only read the existing section arrays.

The first implementation should be a gameplay verification layer, not a complete accounting engine. It should answer:

- Did revenue, margin, cash, debt, capex, working capital, production, backlog, or customer concentration move in the direction implied by the story?
- Is the disclosure clear, partial, weak, or contradictory?
- Which dossier fact/effect/clue created this statement clue?
- Can the player capture it as thesis evidence?

#### Statement period shape

Each statement period should be one compact dictionary inside `financial_statement_snapshot.quarterly_statements`.

```gdscript
{
	"schema_version": 1,
	"source_system_id": "financial_statement_layer",
	"statement_id": "statement|company_id|2020|Q2",
	"company_id": "company_id",
	"ticker": "TICK",
	"sector_id": "sector_id",
	"statement_scope": "quarterly",
	"statement_year": 2020,
	"statement_quarter": 2,
	"statement_period_label": "Q2 2020",
	"period_start_day_index": 0,
	"period_end_day_index": 0,
	"filing_day_index": 0,
	"report_date": {"year": 2020, "month": 6, "day": 30},
	"reporting_lag_days": 30,
	"currency": "IDR",
	"unit": "million_idr",
	"audit_status": "unaudited",
	"restated": false,
	"restatement_of_statement_id": "",
	"amended": false,
	"income_statement": [],
	"balance_sheet": [],
	"cash_flow": [],
	"operating_metrics": [],
	"notes": [],
	"story_adjustments": [],
	"traceability": {}
}
```

Required period fields:

| Field | Purpose |
|---|---|
| `schema_version` | Allows future normalizers to upgrade old statement rows. |
| `source_system_id` | Distinguishes generated statement-layer rows from legacy statement rows. |
| `statement_id` | Stable id for tests, notes, and thesis capture. |
| `company_id`, `ticker`, `sector_id` | Company identity and sector context. |
| `statement_scope` | `quarterly` for v1. Annual rollups can be derived later. |
| `statement_year`, `statement_quarter`, `statement_period_label` | Existing runtime-compatible period identity. |
| `period_start_day_index`, `period_end_day_index`, `filing_day_index`, `report_date` | Timing and filing unlock context. |
| `currency`, `unit` | Keeps values interpretable without encoding scale in every label. |
| `audit_status` | `unaudited`, `reviewed`, `audited`, or `qualified`. |
| `restated`, `restatement_of_statement_id`, `amended` | Optional restatement/amendment support for later governance stories. |

Compatibility rule:

- `statement_year`, `statement_quarter`, `statement_period_label`, `income_statement`, `balance_sheet`, and `cash_flow` remain compatible with the existing statement snapshot shape.
- New fields are additive.

#### Statement line shape

All numeric rows should use one line shape regardless of section.

```gdscript
{
	"line_id": "line|statement_id|income_statement|revenue",
	"section_id": "income_statement",
	"metric_id": "revenue",
	"label": "Total revenue",
	"value": 0.0,
	"unit": "million_idr",
	"scale": 1.0,
	"qoq_change_pct": 0.0,
	"yoy_change_pct": 0.0,
	"ttm_value": 0.0,
	"direction_vs_prior": "flat",
	"source_effect_ids": [],
	"source_story_ids": [],
	"explain_tags": []
}
```

Rules:

- Existing lines that only have `id`, `label`, `value`, and `unit` remain valid.
- Future enhanced lines should include `metric_id`; if a legacy line only has `id`, readers can treat `id` as `metric_id`.
- `qoq_change_pct`, `yoy_change_pct`, and `ttm_value` are optional derived fields.
- `source_effect_ids` and `source_story_ids` are optional, but must point to valid dossier rows when present.

#### Simplified statement sections

V1 supports five sections.

| Section | Field | Purpose |
|---|---|---|
| Income statement | `income_statement` | Revenue, gross profit, operating income, income before tax, net income, comprehensive income. |
| Balance sheet | `balance_sheet` | Cash, receivables, inventory, assets, debt/liabilities, equity, shares outstanding. |
| Cash flow | `cash_flow` | Operating cash flow, investing cash flow, financing cash flow, capex, free cash flow, net cash change. |
| Operating metrics | `operating_metrics` | Sector-specific non-accounting metrics such as production volume, backlog, customers, utilization, loan growth, NPL, occupancy, ARPU. |
| Notes and MD&A | `notes` | Structured filing disclosures linked to story facts/effects. |

Baseline metric ids:

| Section | Metric ids |
|---|---|
| `income_statement` | `revenue`, `gross_profit`, `gross_margin`, `operating_income`, `operating_margin`, `income_before_tax`, `net_income`, `net_margin`, `comprehensive_income`, `owners_income`, `others_income` |
| `balance_sheet` | `cash`, `receivables`, `inventory`, `current_assets`, `non_current_assets`, `total_assets`, `short_term_debt`, `long_term_debt`, `debt`, `current_liabilities`, `non_current_liabilities`, `total_liabilities`, `equity`, `shares_outstanding`, `working_capital` |
| `cash_flow` | `cash_from_operating`, `cash_from_investing`, `cash_from_financing`, `capex`, `free_cash_flow`, `net_change_cash` |
| `operating_metrics` | `production_volume`, `sales_volume`, `backlog`, `customer_concentration`, `customer_count`, `capacity_utilization`, `same_store_sales`, `arpu`, `occupancy`, `loan_growth`, `npl_ratio`, `commodity_realization_price` |

#### Note shape

Notes are structured first. Display prose can be generated from the note row later.

```gdscript
{
	"note_id": "note|statement_id|capex_progress|01",
	"statement_id": "statement|company_id|2020|Q2",
	"company_id": "company_id",
	"note_type": "capex_progress",
	"title_key": "capex_progress_title",
	"text_key": "capex_progress_partial",
	"summary": "",
	"statement_section": "notes",
	"metric_ids": ["capex", "cash", "debt"],
	"story_id": "story|company_id|capex_expansion|seed",
	"fact_ids": [],
	"effect_ids": [],
	"clue_ids": [],
	"disclosure_quality": "partial",
	"tone": "mixed",
	"visibility": "filing",
	"importance": 0.0,
	"contradiction": false,
	"explain_tags": []
}
```

Required note fields:

| Field | Purpose |
|---|---|
| `note_id` | Stable note id for tests and thesis capture. |
| `statement_id`, `company_id` | Owning statement and company. |
| `note_type` | Reusable note taxonomy value. |
| `metric_ids` | Metrics the note explains. |
| `story_id`, `fact_ids`, `effect_ids`, `clue_ids` | Dossier provenance. |
| `disclosure_quality` | How clear the note is to the player. |
| `visibility` | Usually `filing`; can support `internal_debug` for tests. |
| `importance` | Bounded sorting/scanning score, `0.0..1.0`. |
| `contradiction` | True when the note conflicts with public/private story claims. |

`summary` is optional and should stay short. Long prose should be generated from `text_key` and structured fields.

#### Note taxonomy

V1 note types:

| Note type | Typical story source | Typical metrics |
|---|---|---|
| `use_of_proceeds` | Rights issue, placement, acquisition, debt refinance | `cash`, `debt`, `capex`, `shares_outstanding` |
| `capex_progress` | Expansion, plant, fleet, smelter, warehouse, data center | `capex`, `cash`, `debt`, `production_volume`, `capacity_utilization` |
| `customer_concentration` | Contract win, customer loss, tender, platform deal | `revenue`, `backlog`, `customer_concentration` |
| `margin_movement` | Pricing reset, cost pressure, efficiency program | `gross_margin`, `operating_margin`, `net_margin` |
| `debt_change` | Refinancing, covenant, balance-sheet stress | `debt`, `cash`, `working_capital`, `interest_expense` |
| `inventory` | Input cost pressure, demand slowdown, channel stuffing | `inventory`, `working_capital`, `gross_margin` |
| `receivables` | Aggressive revenue, weak collection, related party | `receivables`, `revenue`, `cash_from_operating` |
| `management_outlook` | Guidance, turnaround, delay, demand signal | `revenue`, `net_income`, `backlog`, `capex` |
| `commodity_realization` | Commodity tailwind/headwind | `revenue`, `gross_margin`, `commodity_realization_price`, `production_volume` |
| `input_cost_pressure` | Commodity headwind, logistics, FX pressure | `gross_margin`, `inventory`, `working_capital` |
| `backlog_contract` | Contract win or delayed project | `backlog`, `revenue`, `customer_concentration` |
| `related_party` | Governance risk, opaque transaction | `receivables`, `cash`, `debt` |
| `accounting_policy` | Restatement, recognition policy, capitalization | `revenue`, `capex`, `inventory`, `receivables` |
| `segment_performance` | Sector/subsector rotation, company transformation | `revenue`, `operating_margin`, `production_volume` |
| `working_capital` | Cash conversion, inventory/receivable build | `working_capital`, `cash_from_operating`, `inventory`, `receivables` |
| `liquidity` | Stress, refinancing, covenant, cash drain | `cash`, `debt`, `current_liabilities`, `cash_from_financing` |
| `governance` | Management dispute, audit concern, license issue | `cash`, `receivables`, `related_party` |
| `statement_contradiction` | Fraud signal, overhyped story, weak disclosure | Any metric contradicted by story claims |
| `turnaround_progress` | Cost reset, utilization recovery, asset sale | `operating_margin`, `cash`, `debt`, `production_volume` |

#### Disclosure quality

`disclosure_quality` controls clarity without exposing hidden truth directly.

| Value | Meaning |
|---|---|
| `clear` | The filing directly explains the metric change. |
| `partial` | The filing gives enough clues but leaves interpretation to the player. |
| `weak` | The filing is vague or boilerplate. |
| `contradictory` | The filing conflicts with public claims or prior clues. |

Rules:

- Notes can be vague or contradictory, but should still reference valid metrics and provenance ids.
- Player-facing notes should not expose `truth_state`.
- Tests may inspect hidden dossier state, but statement rows should use public filing fields.

#### Story adjustment shape

Task 2 will fill this array. Task 1 reserves the shape so statement rows can explain story-driven deltas.

```gdscript
{
	"adjustment_id": "adjustment|statement_id|effect_id",
	"story_id": "story|company_id|contract_win|seed",
	"effect_id": "effect|story_id|revenue",
	"metric_id": "revenue",
	"statement_section": "income_statement",
	"direction": "up",
	"magnitude_band": "moderate",
	"applied_delta_pct": 0.0,
	"applied_delta_amount": 0.0,
	"persistence": "temporary",
	"note_id": "note|statement_id|customer_concentration|01"
}
```

Rules:

- Every `story_adjustment.effect_id` must exist in the owning dossier `financial_effects`.
- Every `story_adjustment.note_id` must exist in the statement `notes` array when present.
- Deltas should be bounded and explainable by company size, sector, and existing financial profile.

#### Traceability shape

```gdscript
{
	"source_statement_ids": [],
	"source_story_ids": [],
	"source_fact_ids": [],
	"source_effect_ids": [],
	"source_clue_ids": [],
	"generated_note_ids": [],
	"generated_adjustment_ids": [],
	"thesis_evidence_ids": []
}
```

Rules:

- Statement notes generated from dossiers must include `story_id` and at least one `effect_id` or `clue_id`.
- Numeric lines affected by story effects should include `source_story_ids` and `source_effect_ids`.
- Tests should hash ids, metrics, note types, deltas, and disclosure quality, not long prose.

#### Save compatibility

Task 1 does not add or change save data.

Future tasks should prefer extending each statement row inside the existing `financial_statement_snapshot.quarterly_statements` array. Existing snapshot readers should continue to work because they already read:

- `statement_year`
- `statement_quarter`
- `statement_period_label`
- `income_statement`
- `balance_sheet`
- `cash_flow`
- `quarterly_statements`

If a future task needs global indexing, add a compact optional `financial_statement_layer_state` with ids and fingerprints only. Do not duplicate full statement text in multiple save locations.

#### Validation rules for future tests

- Every statement row has a stable `statement_id`.
- `(company_id, statement_year, statement_quarter)` is unique inside a company snapshot.
- Existing financial sections remain arrays of line dictionaries.
- Every enhanced line has a `metric_id` or legacy `id`.
- Every note references an existing `statement_id` and valid `metric_ids`.
- Dossier-linked notes reference valid `story_id`, `effect_ids`, and/or `clue_ids`.
- Player-facing notes do not expose hidden `truth_state`.
- Large prose is not required for save-state correctness.

## Task 2 - Map story effects into statement changes

Problem: Statements should reflect story facts, not random numbers.

1. Map dossier financial effects to revenue, margin, cash, debt, capex, working capital, and operating metrics.
2. Keep effects bounded by company profile and sector.
3. Add explainability fields for tests.
4. Verify:
   - Targeted revenue-jump story test.
   - Targeted failed-capex story test.

### Task 2 implementation notes

`FinancialStatementLayer` is the mapping adapter between Story Dossier financial effects and quarterly statement rows.

Public method:

```gdscript
FinancialStatementLayer.apply_story_effects_to_statement(statement, dossiers, financial_context, options)
```

Inputs:

| Input | Purpose |
|---|---|
| `statement` | Existing quarterly statement dictionary. |
| `dossiers` | Company story dossiers, usually from `RunState.get_company_story_dossiers_for_company(company_id)`. |
| `financial_context` | Existing financials for revenue-size and cap calculations. |
| `options` | Company id, ticker, sector id, filing day, report date, unit/currency, and max adjustment count. |

Current runtime bridge:

- `RunState._build_quarterly_filing_payload(...)` builds the base quarterly statement through `CompanyGenerator`.
- It then calls `FinancialStatementLayer.apply_story_effects_to_statement(...)`.
- The adjusted statement is inserted into the quarterly statement history.
- `financials_after`, YoY growth, net margin, and surprise score are derived from the adjusted statement.

Mapped metrics:

| Dossier metric | Statement target |
|---|---|
| `revenue` | `income_statement.revenue`, with carry-through to gross profit, operating income, and net income. |
| `gross_margin` | `income_statement.gross_profit`, with partial carry-through to net income. |
| `operating_margin` | `income_statement.operating_income`, with partial carry-through to net income. |
| `net_income`, `net_margin` | `income_statement.net_income`. |
| `cash` | `balance_sheet.cash`, plus current assets and total assets. |
| `debt` | `balance_sheet.debt`, plus total liabilities. |
| `capex` | `cash_flow.capex`, with inverse movement in cash from investing. |
| `working_capital`, `inventory`, `receivables` | Balance sheet rows and current assets. |
| `production_volume`, `sales_volume`, `backlog`, `customer_concentration`, and similar non-accounting metrics | `operating_metrics`. |

Adjustment row shape now produced:

```gdscript
{
	"adjustment_id": "adjustment|statement_id|effect_id",
	"statement_id": "statement|company_id|2020|Q2",
	"story_id": "story|company_id|contract_win|seed",
	"effect_id": "effect|story_id|revenue",
	"metric_id": "revenue",
	"statement_section": "income_statement",
	"direction": "up",
	"magnitude_band": "large",
	"applied_delta_pct": 0.108,
	"applied_delta_amount": 108.0,
	"before_value": 1000.0,
	"after_value": 1108.0,
	"persistence": "durable",
	"note_type": "customer_contract",
	"note_id": "note|statement_id|customer_contract|01",
	"fact_ids": [],
	"clue_ids": []
}
```

Task 2 verification result:

- `FinancialStatementLayerStoryEffectTest` covers:
  - revenue-up contract story increases revenue by a bounded amount
  - revenue-up carries through to net income
  - backlog creates an operating metric row
  - failed-capex story reduces capex without going below zero
  - lower capex makes investing cash flow less negative
  - statement lines preserve `source_effect_ids`
  - adjusted statement payload does not expose hidden truth metadata
- Locked hash: `353480211`.

## Task 3 - Generate MD&A and footnote disclosures

Problem: The player needs text clues that explain why the numbers changed.

1. Generate deterministic note text from structured facts.
2. Vary clarity by disclosure quality, relationship access, and story truth state.
3. Include post-corporate-action use/result notes.
4. Verify:
   - Text output references valid structured facts.
   - Repeated fixed-seed runs match.

### Task 3 implementation notes

`FinancialStatementLayer` now turns story adjustment rows into structured MD&A/footnote rows inside `statement.notes`.

Generation rules:

- Notes are generated only after at least one story effect moves a statement line.
- Adjustments are grouped by `story_id` and source `note_type`.
- Each note receives a stable `note_id` and every related `story_adjustment.note_id` points back to it.
- Notes preserve valid `story_id`, `fact_ids`, `effect_ids`, `clue_ids`, and `metric_ids`.
- `traceability.generated_note_ids` records generated notes for tests and future thesis capture.

Disclosure quality rules:

- Use `statement_clues.disclosure_quality` when available.
- Fall back to dossier truth only to choose a public filing quality label; never write raw `truth_state` into the statement.
- Access context can raise `detail_level` and summary specificity, but does not expose private-only fields.

Post-corporate-action behavior:

- `use_of_proceeds` notes are generated from grouped cash/capex/debt-style adjustments.
- They include `post_corporate_action` in `explain_tags`.
- They remain structured enough for future thesis capture and UI display.

Task 3 verification result:

- `FinancialStatementLayerDisclosureTest` covers:
  - grouped customer-contract notes
  - high-access detail level
  - public partial use-of-proceeds notes
  - adjustment-to-note linking
  - valid fact/effect/clue/metric references
  - deterministic repeated fixed-input payloads
  - no hidden story truth leakage in adjusted statement JSON
- Locked hash: `1824588069`.

## Task 4 - Add company app or report display path

Problem: Statement data needs a reachable player-facing surface.

1. Add a button in financial tab in stockbot that opens up a compact statement/report view.
2. Keep the report view layout dense, scannable, scrollable. Use white background.
3. Use overlay over screen.
4. Verify:
   - UI smoke for opening statements.
   - No layout overlap in targeted view.

### Task 4 implementation notes

`StockController` now exposes the statement layer from the STOCKBOT Financials tab:

- A `Report` button is added beside the financial period controls.
- The button opens `FinancialStatementReportOverlay`, a full-screen overlay containing a compact white report panel.
- The report panel is scrollable and grouped by:
  - Income Statement
  - Balance Sheet
  - Cash Flow
  - Operating Metrics
  - Notes & MD&A
- The Financials tab also includes inline `OPERATING METRICS` and `NOTES & MD&A` cards for fast scanning without opening the overlay.
- Existing statement rows and new note rows can open the same financial statement research action menu.

Data/display behavior:

- `RunState._statement_snapshot_from_quarters` now mirrors the selected/latest filing's `operating_metrics`, `notes`, `story_adjustments`, and `traceability` into the top-level snapshot for UI compatibility.
- Financial statement cache invalidation includes a selected-period display signature so changes to notes and operating metrics refresh correctly.
- Statement value formatting now handles currency, plain numbers, counts, percentages, ratios, multiples, and shares.

Task 4 verification result:

- `SmokeTest` now opens the Financials report overlay, checks the report panel/body/close button, verifies populated report sections, checks viewport-bounded layout, and closes the overlay.
- Targeted statement, thesis tray, thesis fingerprint, editor-load, and quick smoke checks passed.

## Task 5 - Add thesis capture from statements

Problem: Players should be able to turn statement observations into thesis evidence.

1. Add evidence capture hooks for statement and note facts.
2. Use existing thesis vocabulary where possible.
3. Verify:
   - Targeted thesis capture test.
   - Existing thesis quick tests.

### Task 5 implementation notes

Statement and note rows now produce thesis-ready evidence payloads:

- Statement line capture includes statement id, period label, scope, year/quarter, filing day, section id/label, line id, metric id, raw value, value format, linked story ids, linked effect ids, and vocabulary tags.
- Statement note capture includes statement id, period label, note id/type, title/text keys, disclosure quality, detail level, access level, tone, importance, linked metrics, effects, facts, clues, source statement sections, and explain tags.
- `ThesisEvidenceCaptureSystem` preserves the new statement/note fields when normalizing Research Tray rows.
- `ThesisManager.copy_optional_thesis_evidence_fields` preserves the same fields for direct thesis evidence adds.
- `RunState` research-tray and attached-thesis normalizers now preserve statement/note provenance through save/load.
- Research evidence dedupe keys now include statement id, period, section, line id, and note id so filing rows stay stable even when labels repeat across periods.

Task 5 verification result:

- Added `FinancialStatementLayerThesisCaptureTest`.
- The test covers statement line capture, note capture, duplicate Research Tray dedupe, attach-to-thesis, direct add-to-thesis, and save/load preservation.
- Existing thesis quick tests and quick smoke passed.

## Task 6 - Add statement verification tests

Problem: Statement layers are easy to break with subtle data drift.

1. Add fixed-seed statement snapshots for several story types.
2. Check numeric plausibility and note consistency.
3. Verify:
   - Snapshot/fingerprint tests pass.
   - Quick smoke.

### Task 6 implementation notes

Added `FinancialStatementLayerSnapshotMatrixTest` as the broader fixed-input statement verification gate.

The matrix covers five story shapes:

- Customer contract/customer demand: revenue, net income, backlog, clear high-detail note.
- Use of proceeds: cash, current assets, total assets, capex, cash from investing, post-corporate-action note tag.
- Margin/input cost pressure: gross profit, net income, inventory, current assets, weak mixed-tone note.
- Debt/liquidity: debt, total liabilities, cash, current assets, total assets, two separate funding/liquidity notes.
- Statement contradiction: operating income, net income, contradictory note quality, challenge explain tag.

The test validates:

- deterministic repeated fixed-input payloads
- locked snapshot hash `1888558735`
- adjustment before/after/delta consistency
- bounded delta plausibility
- non-negative line plausibility except explicitly negative-capable lines
- balance-sheet sanity checks for current assets, total assets, debt, liabilities, and cash
- adjustment-to-note links
- generated note ids and adjustment ids in traceability
- statement line `source_effect_ids`
- no raw hidden story truth fields leaking into statement JSON

Task 6 verification result:

- `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/FinancialStatementLayerSnapshotMatrixTest.tscn` -> `FINANCIAL_STATEMENT_LAYER_SNAPSHOT_MATRIX_OK {"hash":"1888558735","case_count":5,...}`
- `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/FinancialStatementLayerStoryEffectTest.tscn` -> `FINANCIAL_STATEMENT_LAYER_STORY_EFFECT_OK {"hash":"353480211",...}`
- `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/FinancialStatementLayerDisclosureTest.tscn` -> `FINANCIAL_STATEMENT_LAYER_DISCLOSURE_OK {"hash":"1824588069",...}`
- `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/FinancialStatementLayerThesisCaptureTest.tscn` -> `FINANCIAL_STATEMENT_LAYER_THESIS_CAPTURE_OK`
- `/Users/user/.local/bin/godot --headless -e --quit`
- `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11 days=3 ...`

## Revision R1 - Annual Consolidated A4 Statement Plan

Problem: The current v1 report is a compact selected-period filing view. The next version should feel closer to an annual consolidated financial statement document: full-year, prior-year, A4-like, and sectioned like the reference PDF.

### R1 design decisions

- Button label: `View Consolidated Financial Statement`.
- Report period: full fiscal year before the current starting year. For the current 2020 game start, the report should show FY2019.
- Report scope: consolidated annual statement, not a selected quarter.
- Page feel: portrait A4 paper ratio, white page, document margins, formal section headings, and scrollable pages.
- Reference structure:
  - Consolidated Statement of Financial Position
  - Consolidated Statement of Profit or Loss and Other Comprehensive Income
  - Consolidated Statement of Changes in Equity
  - Consolidated Statement of Cash Flows
  - Notes to the Consolidated Financial Statements
- Fidelity target: believable annual-report presentation for gameplay, not a full professional accounting disclosure engine.

### R1 annual note generation scope

The annual report should start with 14 deterministic notes. These are realistic enough to resemble the reference annual statement while still being grounded in current game systems.

| # | Annual note | Can generate from current data? | Additional deterministic generation needed |
|---|---|---|---|
| 1 | Company Information | Yes | Minimal formatting from company name, sector, subsector, catalog traits, moats, and exposures. |
| 2 | Basis Of Preparation | Yes | Static annual-report template using currency, unit, fiscal year, consolidated flag, and page/report metadata. |
| 3 | Revenue | Mostly | Use financial profile and annual statement rows; add deterministic segment/customer/channel split. |
| 4 | Cost Of Revenue And Gross Profit | Mostly | Derive cost of revenue from revenue and gross profit; explain gross margin using sector, commodity exposure, and story effects. |
| 5 | Operating Expenses | Partial | Add deterministic selling/admin/other opex split from operating profit and sector archetype. |
| 6 | Segment Information | Partial | Add deterministic segment split per company sector/subsector and story hooks. |
| 7 | Cash And Cash Equivalents | Yes | Use balance-sheet cash row and annual cash flow movement. |
| 8 | Trade Receivables | Partial | Add receivables row if missing plus deterministic aging/quality bands. |
| 9 | Inventories | Partial | Add inventory row if missing plus inventory movement, stock build, or write-down band. |
| 10 | Property, Plant, And Equipment | Partial | Add PPE roll-forward from sector, capex, depreciation estimate, and expansion/capex arcs. |
| 11 | Debt And Borrowings | Mostly | Use debt/liability rows; add maturity/current-vs-long-term split and finance-cost linkage. |
| 12 | Equity And Dividends | Partial | Add share capital, retained earnings, dividend movement, and corporate action linkage. |
| 13 | Cash Flow Information | Yes | Use annual cash flow rows; explain operating cash quality, capex, financing, and ending cash. |
| 14 | Commitments, Contingencies, And Subsequent Events | Mostly source-ready | Existing arcs, dossiers, company events, corporate actions, legal/regulatory hooks can feed this; add annual-note mapping rules. |

Implementation rule:

- Do not hand-author one-off notes per company.
- Generate note payloads from structured annual statement rows, company catalog/profile data, Story Dossier facts/effects/clues, Living Company Arc state, corporate actions, and deterministic sector templates.
- Keep every generated note traceable back to source rows, facts, effects, clues, arcs, or corporate actions where possible.
- If source systems do not provide a story for a note, generate a plain neutral disclosure instead of leaving the note missing.

### R1 deterministic generation layers

Revision R1 should be implemented as layered adapters:

1. **Annual statement builder:** derive FY2019 consolidated financial position, profit or loss/OCI, changes in equity, and cash flow rows from existing financial profile and generated company state.
2. **Derived accounting rows:** deterministically fill opex split, receivables, inventories, PPE, retained earnings, dividends, finance cost, tax, and segment columns when the existing profile lacks explicit rows.
3. **Segment split builder:** derive annual segment rows from sector/subsector, company traits, commodity exposure, moat tags, and story hooks.
4. **Annual note builder:** generate the 14 note payloads above from annual rows plus structured company/story state.
5. **Existing-state adapters:** map current Story Dossier, Living Company Arc, corporate action, event, and roadmap state into annual note facts such as commitments, contingencies, use of proceeds, and subsequent events.

### R1.1 - Lock annual consolidated statement reference contract

Problem: The v1 contract is quarterly-first. The revision needs an annual consolidated output contract before UI changes.

1. Define annual statement metadata:
   - `statement_scope = "annual"`
   - `consolidated = true`
   - `fiscal_year = 2019` for a 2020 run start
   - optional comparative year, e.g. 2018, if the display needs side-by-side columns
   - `report_title`, `currency`, `unit`, `audit_status`, and `page_size_hint = "A4"`
2. Define document-level section ids:
   - `financial_position`
   - `profit_or_loss_and_oci`
   - `changes_in_equity`
   - `cash_flows`
   - `notes`
3. Decide whether v1 annual rows are derived from existing generated financials or aggregated from quarterly rows.
4. Verify:
   - Design review in this doc.
   - No runtime behavior change.

### R1.1 implementation notes

`AnnualStatementBuilder` now emits an annual consolidated statement contract with:

- annual scope and consolidated flag
- FY2019 period identity with FY2018 comparative year
- A4 page-size hint
- audited status
- report title, currency, unit, company identity, ticker, and sector id
- document section metadata for financial position, profit or loss/OCI, changes in equity, cash flows, and notes
- compatibility mirrors through `income_statement`, `balance_sheet`, and `cash_flow`
- traceability to source financial years and source quarterly periods

### R1.2 - Add prior-year full-year statement source

Problem: The report should not show the currently selected quarter; it should show the completed full year before the run begins.

1. Add an annual statement builder for FY2019 at run start.
2. Prefer deterministic derivation from existing company financial profile inputs first.
3. Add deterministic derived-row rules for missing annual-report rows:
   - opex split
   - receivables
   - inventories
   - PPE
   - retained earnings
   - dividends
   - finance cost
   - tax
   - segment columns
4. Keep quarterly filing behavior intact for existing systems.
5. Include all required annual sections even if some are simplified in the first pass.
6. Verify:
   - Fixed-seed annual statement snapshot test.
   - Existing quarterly statement tests remain stable.
   - No price behavior change unless explicitly added later.

### R1.2 implementation notes

The annual statement source is generated from existing data, not a new parallel accounting model.

Current source behavior:

- Aggregates FY2019 quarterly rows for revenue, profit/loss, OCI, and cash flow totals when quarterly rows exist.
- Uses the 2019 financial-history row for year-end equity, debt, shares, and fallback annual values.
- Uses the 2018 financial-history row for comparative/opening-equity context.
- Derives missing annual-report rows deterministically:
  - cost of revenue
  - selling expenses
  - general/admin expenses
  - finance income/cost
  - tax expense
  - cash, receivables, inventories, PPE, right-of-use assets
  - short-term and long-term borrowings
  - trade payables
  - share capital and retained earnings
  - dividends, other equity movements, beginning/ending cash
- Adds a 14-row `note_index` outline for the annual report. R1.5 later adds the full generated annual note content.

Runtime storage:

- `CompanyFinancialsBuilder.build_statement_snapshot(...)` adds `annual_statement` and `annual_statements` beside existing quarterly fields.
- `RunState` preserves those annual fields when quarterly filings refresh the snapshot.
- Existing quarterly top-level snapshot fields remain unchanged.

Task R1.2 verification result:

- Added `AnnualConsolidatedStatementBuilderTest`.
- Locked hash: `79759363`; R1.5 updates this to `2029322553` after annual note rows are included in the deterministic payload.

### R1.3 - Build A4-style consolidated statement report shell

Problem: The current overlay is an app-style panel. The revision should read visually like a page document.

1. Replace the compact report body with a document shell:
   - portrait A4 aspect ratio
   - white page
   - consistent margins
   - document header with company name, statement title, fiscal year, currency, and unit
   - page-like section blocks
2. Keep the report scrollable.
3. Scale the page for smaller viewports without clipping or text overlap.
4. Avoid nested cards inside the page; use document tables and section dividers instead.
5. Verify:
   - Targeted layout smoke at desktop and smaller viewport sizes.
   - A4 ratio/page bounds assertion.
   - No section title or table overlap.

### R1.3 implementation notes

The existing report overlay is still used, but its internals now render a document page instead of a compact app panel.

Implemented shell behavior:

- `FinancialStatementReportPanel` is the bounded overlay canvas.
- `FinancialStatementReportPage` is a centered white page with an A4 portrait ratio.
- `FinancialStatementReportBody` sits inside page margins and contains the document content.
- Page width is clamped from the current viewport so the page remains readable on smaller screens without horizontal clipping.
- The page keeps its A4 shell while annual tables scroll inside `FinancialStatementReportPageScroll`; the outer overlay still keeps the page within the viewport.

Implemented report content:

- The report uses `financial_statement_snapshot.annual_statement` when available.
- If annual data is missing, it falls back to the selected quarterly period for save compatibility.
- The document header shows ticker, company name, report title, FY2019 year-ended text, FY2018 comparative year, currency/unit, and audit status.
- The document sections render in annual-report order:
  - Consolidated Statement of Financial Position
  - Consolidated Statement of Profit or Loss and Other Comprehensive Income
  - Consolidated Statement of Changes in Equity
  - Consolidated Statement of Cash Flows
  - Notes to the Consolidated Financial Statements
- The notes section renders the annual `note_index` outline in R1.3. R1.5 replaces this with generated annual note rows when available.

Capture behavior:

- While the overlay is open, row capture context points at the displayed annual statement context instead of the selected quarterly tab period.
- Full annual note capture metadata is completed in R1.5.

### 2026-06-17 - Revision R1.4 complete

- Renamed the Financials tab report entry from `Report` to `View Consolidated Financial Statement`.
- The button now presents itself as an annual consolidated statement entry and opens the annual report shell added in R1.3.
- Annual routing remains annual-first through `financial_statement_snapshot.annual_statement`, with the selected quarterly period only as a compatibility fallback when annual data is missing.
- Existing financial statement row/action capture behavior remains in place; deeper annual note capture metadata is completed in R1.5.
- Smoke coverage now asserts the new button label and continues to verify FY2019 annual statement sections after opening the report.
- Verification:
  - `/Users/user/.local/bin/godot --headless -e --quit`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualConsolidatedStatementBuilderTest.tscn`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io`
  - `git diff --check`

### 2026-06-17 - Revision R1.5 complete

- Added generated annual note rows for all 14 deterministic annual notes:
  - Company Information
  - Basis Of Preparation
  - Revenue
  - Cost Of Revenue And Gross Profit
  - Operating Expenses
  - Segment Information
  - Cash And Cash Equivalents
  - Trade Receivables
  - Inventories
  - Property, Plant, And Equipment
  - Debt And Borrowings
  - Equity And Dividends
  - Cash Flow Information
  - Commitments, Contingencies, And Subsequent Events
- The annual note rows reuse the same note/evidence contract as quarterly statement notes:
  - `note_id`, `note_type`, `statement_id`, `statement_scope`, `statement_year`, `statement_period_label`
  - `statement_consolidated`
  - `source_statement_sections`
  - `metric_id` / `metric_ids`
  - source-ready `story_id`, `fact_ids`, `effect_ids`, `clue_ids`, `source_story_ids`, and `source_effect_ids`
  - `disclosure_quality`, `detail_level`, `access_level`, `tone`, `importance`, and `explain_tags`
- The generated annual notes currently derive from annual statement rows, deterministic sector/profile context, and builder options. Live Story Dossier, Living Company Arc, corporate action, event, and roadmap IDs are preserved when supplied to the note contract, but the current FY2019 run-start builder does not yet receive those live post-start systems directly because company financial snapshots are built before story dossiers are seeded.
- The A4 report now renders generated annual notes as clickable evidence rows when `annual_statement.notes` exists; it falls back to the outline index only for legacy/partial statements.
- Statement-line capture payloads and note capture payloads now carry `statement_consolidated` so annual consolidated evidence survives Research Tray, direct thesis evidence, and save/load normalization.
- Research Tray dedupe remains distinct between quarterly filing rows and annual consolidated rows because the dedupe key already includes statement id, period label, section, line id, and note id.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualConsolidatedStatementBuilderTest.tscn` -> `ANNUAL_CONSOLIDATED_STATEMENT_BUILDER_OK {"hash":"2029322553",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/FinancialStatementLayerThesisCaptureTest.tscn` -> `FINANCIAL_STATEMENT_LAYER_THESIS_CAPTURE_OK`

### 2026-06-17 - Revision R1.6 complete

- Locked the generated annual note type set in `AnnualConsolidatedStatementBuilderTest`.
- Added stable UI node names for generated annual report note rows so smoke can verify note rendering directly.
- Expanded quick smoke coverage for the annual report page:
  - `View Consolidated Financial Statement` button remains present
  - FY2019 annual consolidated section headings remain present
  - A4 page shell remains bounded in the overlay
  - all 14 generated annual note rows render in the A4 report
  - representative annual note titles and metric metadata render
- Fixed the report-open path to refresh full company detail when the cached trade snapshot lacks `annual_statement`, keeping the report annual-first instead of silently falling back to a quarterly statement with only one note.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualConsolidatedStatementBuilderTest.tscn` -> `ANNUAL_CONSOLIDATED_STATEMENT_BUILDER_OK {"hash":"2029322553",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/FinancialStatementLayerThesisCaptureTest.tscn` -> `FINANCIAL_STATEMENT_LAYER_THESIS_CAPTURE_OK`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/FinancialStatementLayerStoryEffectTest.tscn` -> `FINANCIAL_STATEMENT_LAYER_STORY_EFFECT_OK {"hash":"353480211",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/FinancialStatementLayerDisclosureTest.tscn` -> `FINANCIAL_STATEMENT_LAYER_DISCLOSURE_OK {"hash":"1824588069",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/FinancialStatementLayerSnapshotMatrixTest.tscn` -> `FINANCIAL_STATEMENT_LAYER_SNAPSHOT_MATRIX_OK {"hash":"1888558735",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK`

### 2026-06-17 - Revision R2 planned for live traceability enrichment

- R1.5 intentionally leaves annual notes deterministic and source-ready, but not fully enriched with live Story Dossier, Living Company Arc, corporate action, event, and roadmap IDs at FY2019 build time.
- This is acceptable for R1 because annual notes are already clickable, thesis-capturable, save/load-safe, and dedupe-safe.
- R2 will close the traceability gap by adding a post-start enrichment pass or equivalent generation-order change after live story systems are seeded.
- R2 should not rewrite the annual statement UI or make annual notes depend on nondeterministic runtime order.
- R2 acceptance criteria:
  - annual note rows can point to real `story_id`, `fact_ids`, `effect_ids`, `clue_ids`, `source_story_ids`, and `source_effect_ids` when relevant source facts exist
  - corporate action, event, and roadmap provenance survives note capture into Research Tray and thesis evidence
  - enriched annual statements remain deterministic under a fixed seed
  - old saves and unenriched annual statements remain readable

### 2026-06-17 - Revision R2.1 complete

- Added `RunState.refresh_annual_statement_post_start_enrichment(...)` as the idempotent post-start enrichment pass.
- The pass runs after new-run Story Dossier seeding, after save/load company-state normalization, and after company full-detail hydration creates or repairs annual statements.
- Annual statements and generated annual notes now receive a stable `post_start_traceability` block with:
  - schema version
  - R2.1 pass id
  - source system id
  - canonical source-system readiness list for Story Dossier, Living Company Arc, corporate action, event history, and company roadmap state
  - `source_mapping_status = "ready_for_live_source_mapping"`
- Existing annual statement `traceability` now records the R2.1 pass id and canonical source-system ids without duplicating values on repeated refreshes.
- R2.1 intentionally does not yet attach specific `story_id`, `fact_ids`, `effect_ids`, `clue_ids`, corporate-action ids, event ids, or roadmap ids to individual note facts. That source-specific mapping remains R2.2-R2.3.
- Added `AnnualStatementEnrichmentPassTest`, covering:
  - enriched annual statement and note metadata
  - repeated enrichment idempotence
  - old/stripped annual statements repairing on save/load
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualStatementEnrichmentPassTest.tscn` -> `ANNUAL_STATEMENT_ENRICHMENT_PASS_OK {"company_id":"kete","note_count":14,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualConsolidatedStatementBuilderTest.tscn` -> `ANNUAL_CONSOLIDATED_STATEMENT_BUILDER_OK {"hash":"2029322553",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/FinancialStatementLayerThesisCaptureTest.tscn` -> `FINANCIAL_STATEMENT_LAYER_THESIS_CAPTURE_OK`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK`
  - `git diff --check`

### 2026-06-17 - Revision R2.2 complete

- Annual post-start enrichment now maps live Company Story Dossier rows into annual notes by structured `note_type` and `metric_id`, not generated text.
- Story Dossier provenance now rolls into note fields:
  - `story_id`
  - `source_story_ids`
  - `effect_id`
  - `source_effect_ids`
  - `effect_ids`
  - `fact_id`
  - `fact_ids`
  - `clue_id`
  - `clue_ids`
  - `story_source_refs`
- Living Company Arc state now maps active/completed arc context into annual notes through `source_living_arc_ids` and `living_arc_refs`.
- Statement-level annual traceability now rolls up mapped story, effect, fact, clue, and living-arc IDs from enriched notes.
- Fixed the Story Dossier source merge to read both full source rows and normalized source refs, preventing note-level `source_story_ids` from losing IDs after context normalization.
- Added `AnnualStatementStorySourceEnrichmentTest`, covering:
  - revenue note source IDs from a customer-contract story
  - property, plant, and equipment note source IDs from a capex story
  - debt and borrowings note source IDs from a debt/refinancing story
  - segment and commitments note source IDs from relevant stories
  - living-arc IDs on PPE, debt, cash flow, and commitments notes
  - unrelated deterministic notes staying valid without noisy story sources
  - repeated enrichment idempotence
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualStatementStorySourceEnrichmentTest.tscn` -> `ANNUAL_STATEMENT_STORY_SOURCE_ENRICHMENT_OK {"company_id":"kete","story_count":3,...}`

### 2026-06-18 - Revision R2.3 complete

- Annual post-start enrichment now maps corporate action provenance into annual notes through:
  - `source_corporate_action_ids`
  - `corporate_action_refs`
- Corporate action source rows are collected from active corporate-action chains, corporate-action event history, company profile action adjustments, and dividend calendar rows when available.
- Annual post-start enrichment now maps event-history provenance into annual notes through:
  - `source_event_ids`
  - `source_event_ref_ids`
  - `event_refs`
- Annual post-start enrichment now maps company roadmap milestones into annual notes through:
  - `source_roadmap_ids`
  - `roadmap_refs`
- The mapping is topic-scoped rather than broad:
  - rights, placements, dividends, buybacks, splits, tenders, and shares map to equity/cash-flow/commitment notes
  - funding, debt, loans, refinancing, and restructuring map to debt/cash-flow/commitment notes
  - roadmap, project, capex, expansion, acquisition, merger, and backdoor tokens map to PPE/segment/cash-flow/commitment notes
  - revenue, customer, contract, margin, cost, expense, and inventory event tokens map to the matching operating notes
- Statement-level annual traceability now rolls up mapped corporate-action, event, event-ref, and roadmap IDs from enriched notes.
- The enrichment signature now includes the new R2.3 source arrays and refs, preserving idempotence checks when these live source IDs change.
- Added `AnnualStatementActionEventRoadmapEnrichmentTest`, covering:
  - a seeded live rights-issue chain
  - a seeded corporate-action filing event
  - a seeded active roadmap milestone and roadmap event
  - expected source IDs on equity, debt, cash-flow, PPE, segment, and commitments notes
  - `basis_of_preparation` staying clean from unrelated action/event/roadmap provenance
  - repeated enrichment idempotence
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/AnnualStatementActionEventRoadmapEnrichmentTest.tscn` -> `ANNUAL_STATEMENT_ACTION_EVENT_ROADMAP_ENRICHMENT_OK {"company_id":"sire","note_count":14,...}`
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/AnnualStatementStorySourceEnrichmentTest.tscn` -> `ANNUAL_STATEMENT_STORY_SOURCE_ENRICHMENT_OK {"company_id":"kete","story_count":3,...}`
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/AnnualStatementEnrichmentPassTest.tscn` -> `ANNUAL_STATEMENT_ENRICHMENT_PASS_OK {"company_id":"kete","note_count":14,...}`
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/AnnualConsolidatedStatementBuilderTest.tscn` -> `ANNUAL_CONSOLIDATED_STATEMENT_BUILDER_OK {"hash":"2029322553",...}`
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/FinancialStatementLayerThesisCaptureTest.tscn` -> `FINANCIAL_STATEMENT_LAYER_THESIS_CAPTURE_OK`

### 2026-06-18 - Revision R2.4 complete

- Financial statement note capture now carries enriched annual-note provenance from the displayed note payload into evidence rows:
  - `source_living_arc_ids`
  - `source_corporate_action_ids`
  - `source_event_ids`
  - `source_event_ref_ids`
  - `source_roadmap_ids`
  - `story_source_refs`
  - `living_arc_refs`
  - `corporate_action_refs`
  - `event_refs`
  - `roadmap_refs`
- `ThesisEvidenceCaptureSystem` now preserves those arrays when normalizing captured financial statement evidence.
- `RunState` Research Tray normalization now preserves those arrays during save/load and old-save dedupe repair.
- `ThesisManager` direct-add evidence normalization now preserves those arrays when evidence bypasses the Research Tray.
- `FinancialStatementLayerThesisCaptureTest` now seeds an enriched annual commitments note and verifies:
  - captured Research Tray evidence preserves action/event/roadmap provenance
  - attached thesis evidence preserves the same provenance
  - direct thesis evidence add preserves the same provenance
  - save/load preserves the Research Tray row and attached thesis row provenance
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/FinancialStatementLayerThesisCaptureTest.tscn` -> `FINANCIAL_STATEMENT_LAYER_THESIS_CAPTURE_OK`
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/AnnualStatementActionEventRoadmapEnrichmentTest.tscn` -> `ANNUAL_STATEMENT_ACTION_EVENT_ROADMAP_ENRICHMENT_OK {"company_id":"sire","note_count":14,...}`
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/AnnualStatementStorySourceEnrichmentTest.tscn` -> `ANNUAL_STATEMENT_STORY_SOURCE_ENRICHMENT_OK {"company_id":"kete","story_count":3,...}`
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/AnnualStatementEnrichmentPassTest.tscn` -> `ANNUAL_STATEMENT_ENRICHMENT_PASS_OK {"company_id":"kete","note_count":14,...}`
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/AnnualConsolidatedStatementBuilderTest.tscn` -> `ANNUAL_CONSOLIDATED_STATEMENT_BUILDER_OK {"hash":"2029322553",...}`

### 2026-06-18 - Revision R2.5 complete

- Added `AnnualStatementFullTraceabilityContractTest` as the fixed-seed full-source annual-note traceability contract.
- The test seeds one company with:
  - three Story Dossier sources for customer-contract, capex/PPE, and debt/refinancing notes
  - one active Living Company Arc through the normal `active_company_arcs` lifecycle path
  - one live rights-issue corporate-action chain
  - one corporate-action filing event
  - one active company roadmap milestone and roadmap event
- The test verifies:
  - all 14 annual generated notes are still present
  - statement-level traceability rolls up story, effect, fact, clue, living-arc, corporate-action, event, event-ref, and roadmap IDs
  - revenue, PPE, debt, cash-flow, segment, and commitments notes receive the expected source IDs and refs
  - `basis_of_preparation` stays clean from unrelated source provenance
  - repeated enrichment remains deterministic
  - the `annual_statements` mirror preserves enriched traceability
  - save/load preserves the full traceability payload
  - legacy-style stripped annual statements repair back to the same traceability payload
- Locked fixed-seed traceability hash `584882106` at the time of R2.5. Company Story Dossier R1.5 later expanded the traceability contract with disclosure packet provenance; the current fixed-seed hash is `1974201801`.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualStatementFullTraceabilityContractTest.tscn` -> current baseline `ANNUAL_STATEMENT_FULL_TRACEABILITY_CONTRACT_OK {"company_id":"sire","hash":"1974201801","note_count":14,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualStatementActionEventRoadmapEnrichmentTest.tscn` -> `ANNUAL_STATEMENT_ACTION_EVENT_ROADMAP_ENRICHMENT_OK {"company_id":"sire","note_count":14,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualStatementStorySourceEnrichmentTest.tscn` -> `ANNUAL_STATEMENT_STORY_SOURCE_ENRICHMENT_OK {"company_id":"kete","story_count":3,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualStatementEnrichmentPassTest.tscn` -> `ANNUAL_STATEMENT_ENRICHMENT_PASS_OK {"company_id":"kete","note_count":14,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualConsolidatedStatementBuilderTest.tscn` -> `ANNUAL_CONSOLIDATED_STATEMENT_BUILDER_OK {"hash":"2029322553",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/FinancialStatementLayerThesisCaptureTest.tscn` -> `FINANCIAL_STATEMENT_LAYER_THESIS_CAPTURE_OK`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/FinancialStatementLayerStoryEffectTest.tscn` -> `FINANCIAL_STATEMENT_LAYER_STORY_EFFECT_OK {"hash":"353480211",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/FinancialStatementLayerDisclosureTest.tscn` -> `FINANCIAL_STATEMENT_LAYER_DISCLOSURE_OK {"hash":"1824588069",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/FinancialStatementLayerSnapshotMatrixTest.tscn` -> `FINANCIAL_STATEMENT_LAYER_SNAPSHOT_MATRIX_OK {"hash":"1888558735",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11 days=3 ...`

### 2026-06-19 - Revision R3 planning added

- Added Revision R3 as a direction-correction plan for the player-facing annual report experience.
- R3 goal: make the Financials document feel like reading an annual report, not a set of disconnected clue cards.
- R3 separates responsibilities from Company Story Dossier Revision R1:
  - Story Dossier Revision R1 owns where and how story clues are scattered across filing sections.
  - Financial Statement Revision R3 owns the accounting document shape, note bodies, A4 reader flow, and evidence capture from that document.
- Product direction:
  - keep the R2 provenance plumbing under the hood
  - make the visible report less spoon-fed
  - place story evidence across financial position, profit/loss, cash flow, segment, related party, commitments, subsequent events, and note bodies
  - let the player assemble the story by reading across sections
- Recommended start order:
  - Company Story Dossier Revision R1 is complete
  - then implement Financial Statement R3.1-R3.4
  - finish with Financial Statement R3.5 once dossier disclosure packets are available
- Planning-only update; no code, data, runtime behavior, or tests changed.

### 2026-06-21 - Revision R3.1 complete

- Added a formal annual report document-reading contract to generated annual consolidated statements.
- New annual statement fields:
  - `document_reading_contract`
  - `annual_report_section_map`
  - `table_of_contents`
- The section map locks the reference order and A4-style page ranges:
  - Consolidated Statement of Financial Position: pages `1-3`
  - Consolidated Statement of Profit or Loss and Other Comprehensive Income: pages `4-5`
  - Consolidated Statement of Changes in Equity: pages `6-7`
  - Consolidated Statement of Cash Flows: pages `8-9`
  - Notes to the Consolidated Financial Statements: pages `10-140`
- The contract defines:
  - section numbering and note numbering
  - statement-row capture behavior
  - note-paragraph capture behavior
  - cross-reference behavior through `disclosure_packet_refs`
  - hidden truth labels remain non-visible
  - the four primary statements are readable now
  - notes stay compact until R3.3 builds filing-style note bodies
- Added `AnnualReportDocumentContractTest`.
- Locked document contract hash `2022978131`.
- Runtime behavior note:
  - This task adds annual-report contract metadata only.
  - It does not change quarterly statement behavior, annual numbers, annual note prose, report UI, or story packet placement.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualReportDocumentContractTest.tscn` -> `ANNUAL_REPORT_DOCUMENT_CONTRACT_OK {"hash":"2022978131","section_count":5,"note_count":14,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualConsolidatedStatementBuilderTest.tscn` -> `ANNUAL_CONSOLIDATED_STATEMENT_BUILDER_OK {"hash":"2029322553","section_count":5,"note_count":14,...}`

### 2026-06-21 - Revision R3.2 complete

- Expanded the annual statement accounting layer without turning it into a full accounting engine.
- Added explicit annual report rows for:
  - total debt and borrowings
  - operating cash-flow bridge rows: net income anchor, depreciation and amortization, working-capital changes, and other operating cash-flow adjustments
  - other financing cash-flow residuals
- Tightened deterministic liability allocation so current liabilities, non-current liabilities, short-term borrowings, and long-term borrowings subtotal cleanly.
- Added `accounting_row_model` metadata to generated annual statements:
  - schema version `1`
  - row role, normal balance, note reference, continuity group, and deterministic source rule
  - 62 modeled rows across financial position, profit/loss, equity, and cash-flow sections
- Added `accounting_continuity_checks` to generated annual statements:
  - schema version `1`
  - status `r3_2_continuity_ready`
  - 22 checks covering asset/liability/equity subtotals, balance sheet equation, profit/loss bridges, equity roll-forward, cash-flow bridges, cash reconciliation, and cross-statement cash/equity agreement
  - traceability now lists continuity check ids and failed-count
- Added `AnnualStatementAccountingContinuityTest`.
- Locked R3.2 continuity hash `1613787417`.
- Annual builder hash intentionally changed from `2029322553` to `867613961` because R3.2 adds statement rows.
- Runtime behavior note:
  - Quarterly statements and the R3.1 document-reading contract remain unchanged.
  - Visible note prose remains mostly unchanged until R3.3.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualStatementAccountingContinuityTest.tscn` -> `ANNUAL_STATEMENT_ACCOUNTING_CONTINUITY_OK {"hash":"1613787417","row_model_count":62,"check_count":22,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualConsolidatedStatementBuilderTest.tscn` -> `ANNUAL_CONSOLIDATED_STATEMENT_BUILDER_OK {"hash":"867613961","section_count":5,"note_count":14,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualReportDocumentContractTest.tscn` -> `ANNUAL_REPORT_DOCUMENT_CONTRACT_OK {"hash":"2022978131","section_count":5,"note_count":14,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualStatementFullTraceabilityContractTest.tscn` -> `ANNUAL_STATEMENT_FULL_TRACEABILITY_CONTRACT_OK {"hash":"1974201801","note_count":14,...}`

### 2026-06-21 - Revision R3.3 complete

- Added filing-style annual note bodies to generated annual statements.
- Notes now receive:
  - `filing_note_body`
  - `body_paragraphs`
  - `compact_tables`
  - `cross_note_references`
  - `visible_cross_reference_text`
  - `body_text`
  - `body_text_key`
- The body renderer runs during base annual statement generation and again after post-start annual statement enrichment, so packet-based cross references are reflected once Story Dossier disclosure packet refs exist.
- The document-reading contract now treats `notes` as a readable section instead of a compact placeholder section.
- Visible body text avoids hidden source ids and truth/source-quality labels; source ids remain in note metadata and capture fields.
- Added `AnnualStatementFilingNoteBodyTest`.
- Locked R3.3 note-body hash `1102538137`.
- Updated document contract hash from `2022978131` to `2037575392` because notes are now readable and use `filing_note_bodies` read mode.
- Existing annual builder, accounting continuity, full traceability, Story Dossier bridge fixture, and thesis capture baselines stayed stable.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualStatementFilingNoteBodyTest.tscn` -> `ANNUAL_STATEMENT_FILING_NOTE_BODY_OK {"hash":"1102538137","body_count":14,"packet_ref_count":20,"cross_reference_count":45,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualReportDocumentContractTest.tscn` -> `ANNUAL_REPORT_DOCUMENT_CONTRACT_OK {"hash":"2037575392","section_count":5,"note_count":14,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualConsolidatedStatementBuilderTest.tscn` -> `ANNUAL_CONSOLIDATED_STATEMENT_BUILDER_OK {"hash":"867613961","section_count":5,"note_count":14,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualStatementAccountingContinuityTest.tscn` -> `ANNUAL_STATEMENT_ACCOUNTING_CONTINUITY_OK {"hash":"1613787417","row_model_count":62,"check_count":22,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualStatementFullTraceabilityContractTest.tscn` -> `ANNUAL_STATEMENT_FULL_TRACEABILITY_CONTRACT_OK {"hash":"1974201801","note_count":14,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyStoryDossierFinancialStatementFixtureTest.tscn` -> `COMPANY_STORY_DOSSIER_FINANCIAL_STATEMENT_FIXTURE_OK {"hash":"623183840","fixture_note_packet_ref_count":10,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/FinancialStatementLayerThesisCaptureTest.tscn` -> `FINANCIAL_STATEMENT_LAYER_THESIS_CAPTURE_OK`

### 2026-06-21 - Revision R3.4 complete

- Reworked the annual consolidated statement overlay into a document-reader flow while preserving the `View Consolidated Financial Statement` entry point.
- Added `FinancialStatementReportTocPanel` and section jump buttons for financial position, profit or loss and OCI, changes in equity, cash flows, and notes.
- Added an in-page table of contents with localized titles, English titles, and page labels from the annual report contract.
- Report sections now render with stable anchors such as `FinancialStatementReportSection_notes`; the TOC jumps the A4 page scroll to the selected section.
- Notes now render formal `Note X - Title` headings, filing-style body paragraphs, compact note tables, and visible cross-note reference text from R3.3.
- Statement rows remain capturable; note paragraphs now generate `capture_level = note_paragraph` payloads with paragraph id/index/role/text while preserving annual note provenance.
- Thesis evidence, direct evidence add, Research Tray, and save/load normalization now preserve paragraph capture fields.
- Smoke coverage now verifies the reader opens, A4 bounds hold, all required TOC targets exist, the Notes jump moves scroll, and note rows/paragraphs/tables render.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11 days=3 ...`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/FinancialStatementLayerThesisCaptureTest.tscn` -> `FINANCIAL_STATEMENT_LAYER_THESIS_CAPTURE_OK`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualStatementFilingNoteBodyTest.tscn` -> `ANNUAL_STATEMENT_FILING_NOTE_BODY_OK {"hash":"1102538137",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualReportDocumentContractTest.tscn` -> `ANNUAL_REPORT_DOCUMENT_CONTRACT_OK {"hash":"2037575392",...}`

### 2026-06-21 - Revision R3.5 complete

- Annual note bodies now consume Story Dossier disclosure packet refs directly instead of showing only generic packet-count text.
- Each packet ref can render a visible `disclosure_packet` paragraph inside its mapped annual note, ordered by packet `render_priority`.
- Visible paragraph wording follows packet subtlety:
  - `direct` gives a clear filing trail.
  - `implied` points to an implied trail without isolating one driver.
  - `buried` hides the trail in routine movement details.
  - `conflicting` asks the reader to compare related notes.
  - `missing` treats absent quantified support as part of the filing trail.
- Paragraph text uses filing section labels, metric labels, selected FY amounts where available, and cross-check note sections; hidden ids such as `story|`, `packet|`, and `placement|` remain metadata-only.
- Packet paragraphs preserve packet-specific metadata for capture:
  - packet, placement, section, subtlety, reader effort, evidence density, fragment role, packet role
  - source story/effect/fact/clue/metric ids
  - `source_disclosure_packet_ids`, `source_disclosure_placement_ids`, `source_disclosure_section_ids`, and `disclosure_packet_refs`
- Thesis evidence, direct thesis add, Research Tray normalization, and save/load normalization now preserve packet paragraph metadata.
- `AnnualStatementFilingNoteBodyTest` now locks the R3.5 packet paragraph renderer with hash `36249412`; the selected fixed-seed company renders `20` packet refs as `20` packet paragraphs.
- Existing annual builder hash `867613961`, document contract hash `2037575392`, full traceability hash `1974201801`, and Story Dossier bridge fixture hash `623183840` stayed stable.
- Verification:
  - `/Users/user/.local/bin/godot --headless -e --quit` -> passed
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualStatementFilingNoteBodyTest.tscn` -> `ANNUAL_STATEMENT_FILING_NOTE_BODY_OK {"hash":"36249412","packet_paragraph_count":20,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualReportDocumentContractTest.tscn` -> `ANNUAL_REPORT_DOCUMENT_CONTRACT_OK {"hash":"2037575392",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualConsolidatedStatementBuilderTest.tscn` -> `ANNUAL_CONSOLIDATED_STATEMENT_BUILDER_OK {"hash":"867613961",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualStatementFullTraceabilityContractTest.tscn` -> `ANNUAL_STATEMENT_FULL_TRACEABILITY_CONTRACT_OK {"hash":"1974201801",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyStoryDossierFinancialStatementFixtureTest.tscn` -> `COMPANY_STORY_DOSSIER_FINANCIAL_STATEMENT_FIXTURE_OK {"hash":"623183840",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/FinancialStatementLayerThesisCaptureTest.tscn` -> `FINANCIAL_STATEMENT_LAYER_THESIS_CAPTURE_OK`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11 days=3 ...`

### 2026-06-21 - Revision R3.6 complete

- Added `AnnualReportFidelityCaptureTest` as the final fixed-seed R3 annual report fidelity regression.
- The new test selects a catalog-backed fixed-seed company with disclosure packet paragraphs, cross-note references, and at least one story scattered across multiple annual report sections.
- It locks the annual report fidelity/capture payload hash at `906899410` for company `wisata_kuliner_nusantara`.
- It verifies:
  - A4 document-reading contract, all five TOC sections, FY2019 annual scope, and 14 annual notes.
  - Story Dossier packet refs map into visible annual note paragraphs without leaking hidden ids.
  - At least one story appears across multiple filing sections instead of being concentrated into one obvious clue.
  - Statement row, packet paragraph, and cross-note reference evidence capture normalize correctly.
  - Cross-note reference evidence survives Research Tray capture, thesis attach/direct add, and save/load.
- Cross-note reference metadata is now preserved by Research Tray normalization, thesis direct-add copying, and save/load normalization.
- The annual report smoke path now requires rendered `FinancialStatementReportNoteCrossReference` controls in addition to TOC navigation, A4 bounds, note rows, paragraphs, and compact tables.
- Verification:
  - `/Users/user/.local/bin/godot --headless -e --quit` -> passed
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualReportFidelityCaptureTest.tscn` -> `ANNUAL_REPORT_FIDELITY_CAPTURE_OK {"hash":"906899410","packet_paragraph_count":14,"cross_reference_count":41,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualConsolidatedStatementBuilderTest.tscn` -> `ANNUAL_CONSOLIDATED_STATEMENT_BUILDER_OK {"hash":"867613961",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualReportDocumentContractTest.tscn` -> `ANNUAL_REPORT_DOCUMENT_CONTRACT_OK {"hash":"2037575392",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualStatementAccountingContinuityTest.tscn` -> `ANNUAL_STATEMENT_ACCOUNTING_CONTINUITY_OK {"hash":"1613787417",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualStatementEnrichmentPassTest.tscn` -> `ANNUAL_STATEMENT_ENRICHMENT_PASS_OK`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualStatementStorySourceEnrichmentTest.tscn` -> `ANNUAL_STATEMENT_STORY_SOURCE_ENRICHMENT_OK`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualStatementActionEventRoadmapEnrichmentTest.tscn` -> `ANNUAL_STATEMENT_ACTION_EVENT_ROADMAP_ENRICHMENT_OK`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualStatementFullTraceabilityContractTest.tscn` -> `ANNUAL_STATEMENT_FULL_TRACEABILITY_CONTRACT_OK {"hash":"1974201801",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualStatementFilingNoteBodyTest.tscn` -> `ANNUAL_STATEMENT_FILING_NOTE_BODY_OK {"hash":"36249412",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/FinancialStatementLayerThesisCaptureTest.tscn` -> `FINANCIAL_STATEMENT_LAYER_THESIS_CAPTURE_OK`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyStoryDossierFinancialStatementFixtureTest.tscn` -> `COMPANY_STORY_DOSSIER_FINANCIAL_STATEMENT_FIXTURE_OK {"hash":"623183840",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11 days=3 ...`

### R1.4 - Rename and reroute the Financials entry button

Problem: The current `Report` button label is too generic and points mentally to a compact report, not a formal consolidated statement.

1. Rename the Financials tab button to `View Consolidated Financial Statement`.
2. Route it to the annual consolidated statement report, not the selected quarterly period.
3. Keep existing financial statement action menu behavior for statement row evidence capture.
4. Verify:
   - UI smoke finds the new button label.
   - Opening the button shows FY2019 annual statement content.

### R1.5 - Align statement sections, notes, and thesis capture metadata

Problem: Evidence captured from the annual report needs to reflect the report's annual consolidated context.

1. Add the annual note builder for the 14 deterministic notes listed above.
2. Map existing Story Dossier, Living Company Arc, corporate action, event, and roadmap state into annual note facts.
3. Update statement-line capture metadata to include annual/consolidated scope.
4. Update note capture metadata to identify annual notes and their source section.
5. Preserve story/effect/fact/clue/arc/corporate-action traceability from the existing systems.
6. Keep Research Tray dedupe distinct between quarterly filing evidence and annual statement evidence.
7. Verify:
   - Thesis capture test for annual statement line.
   - Thesis capture test for annual note.
   - Save/load preservation.

### R1.6 - Add annual/A4 layout and content verification tests

Problem: The revision changes both the data contract and report presentation; subtle regressions should be caught.

1. Add fixed-seed annual statement fingerprint coverage.
2. Add UI smoke for:
   - `View Consolidated Financial Statement` button
   - FY2019 period label
   - all required consolidated sections
   - A4 page shell bounds
3. Add thesis capture coverage for annual report rows and notes.
4. Run existing v1 statement tests to ensure quarterly compatibility remains intact.
5. Verify:
   - New annual statement tests pass.
   - Existing statement, thesis, and quick smoke tests pass.

### R2.1 - Define post-start annual statement enrichment pass

Problem: annual consolidated notes are currently generated before live post-start story systems are fully available, so the note contract is source-ready but does not always carry real source IDs.

1. Decide where enrichment runs:
   - after Story Dossier seeding
   - after Living Company Arc initialization
   - after corporate action, event, and roadmap state is available
2. Keep enrichment idempotent so repeated detail hydration or save/load repair does not duplicate provenance.
3. Preserve deterministic output order.
4. Verify:
   - repeated enrichment produces the same annual note rows
   - old annual statements without enrichment still load

Implementation status: complete. R2.1 establishes the lifecycle hook and source-ready metadata. R2.2 fills Story Dossier and Living Company Arc source IDs. R2.3 fills corporate action, event, and roadmap source IDs.

### R2.2 - Feed Story Dossier and Living Company Arc IDs into annual note facts

Problem: notes should become a real verification surface for story facts, not just deterministic statement prose.

1. Map dossier facts/effects/clues into relevant annual note rows.
2. Map living arc phase/resolution context into relevant annual note rows.
3. Prefer structured IDs over generated text matching.
4. Verify:
   - revenue, capex/PPE, debt, segment, and commitments notes preserve relevant story IDs when source facts exist
   - notes without matching story facts remain valid deterministic notes

Implementation status: complete. R2.2 maps Story Dossier and Living Company Arc source IDs into annual note facts and statement-level traceability. R2.3 now adds corporate action, event, and roadmap source IDs.

### R2.3 - Feed corporate action, event, and roadmap provenance into annual note facts

Problem: annual notes should explain and preserve provenance for actions that affect equity, debt, capex, expansion, dividends, and strategic milestones.

1. Map corporate actions into equity, debt, cash flow, commitments, and subsequent-event notes.
2. Map event and roadmap state into operating, segment, capex, and commitment notes.
3. Keep provenance compact in saved state.
4. Verify:
   - action/event/roadmap IDs survive note capture
   - unrelated notes do not receive noisy provenance

Implementation status: complete. R2.3 maps corporate-action, event-history, and roadmap milestone IDs into annual note facts and statement-level traceability. R2.4 verifies those enriched note payloads survive Research Tray, thesis evidence, and save/load capture paths.

### R2.4 - Preserve enriched provenance through Research Tray, thesis evidence, and save/load

Problem: enrichment only matters if captured annual evidence keeps its source trail.

1. Confirm note capture payloads preserve all enriched source arrays.
2. Confirm Research Tray normalization preserves enriched annual note provenance.
3. Confirm thesis evidence normalization preserves enriched annual note provenance.
4. Verify:
   - capture annual enriched note to Research Tray
   - attach enriched note to thesis
   - save/load preserves enriched provenance

Implementation status: complete. R2.4 preserves enriched annual-note source arrays and refs through the financial statement note capture payload, Research Tray normalization, direct thesis evidence add, attached thesis evidence, and save/load normalization. R2.5 adds the broader fixed-seed full traceability contract around the complete enrichment set.

### R2.5 - Add deterministic enrichment and traceability tests

Problem: R2 touches generation order and cross-system provenance, so fixed-seed tests are required.

1. Add a fixed-seed enrichment contract test.
2. Add a save/load preservation test for enriched annual notes.
3. Add a regression test for unenriched/legacy annual statement compatibility.
4. Run existing annual builder, financial statement, thesis capture, and quick smoke tests.
5. Verify:
   - enriched output is deterministic
   - existing R1 annual note behavior remains compatible
   - quick smoke still passes

Implementation status: complete. R2.5 is covered by `AnnualStatementFullTraceabilityContractTest` with current fixed-seed hash `1974201801`, plus the existing annual builder, financial statement layer, thesis capture, and quick smoke tests listed in the progress log. The hash was updated by Company Story Dossier R1.5 when disclosure packet provenance was added to annual note traceability.

### R3.1 - Define document-reading contract and annual report section map

Problem: The current report has annual sections, but the player experience still reads more like app output than a filing document.

1. Define the annual report reading contract:
   - table of contents
   - page-like section order
   - section numbering
   - note numbering
   - cross-reference behavior
   - capture behavior from rows and note paragraphs
2. Lock the section map:
   - consolidated statement of financial position
   - consolidated statement of profit or loss and other comprehensive income
   - consolidated statement of changes in equity
   - consolidated statement of cash flows
   - notes to the consolidated financial statements
3. Decide which sections are readable first and which can remain compact in R3.
4. Verify:
   - fixed-seed annual report contract test
   - no quarterly statement behavior changes

Task R3.1 implementation result:

- Annual consolidated statements now include:
  - `document_reading_contract`
  - `annual_report_section_map`
  - `table_of_contents`
- The table of contents and section map follow the reference annual report shape:
  - financial position pages `1-3`
  - profit or loss and OCI pages `4-5`
  - changes in equity pages `6-7`
  - cash flows pages `8-9`
  - notes pages `10-140`
- The contract locks:
  - section ordering
  - section numbering
  - note numbering from `note_index`
  - row capture and note-paragraph capture behavior
  - cross-reference source as `disclosure_packet_refs`
  - no visible hidden truth labels
  - readable sections now vs compact notes until R3.3
- Added `AnnualReportDocumentContractTest` with fixed-seed hash `2022978131`.
- Existing annual consolidated builder hash remains `2029322553`, confirming no annual numeric/content baseline change.
- The test also asserts quarterly statements do not receive annual document-reader fields.

Implementation status: complete. R3.2 should expand the accounting row model and continuity checks using this contract as the document shell.

### R3.2 - Expand accounting row model and statement continuity

Problem: The report needs enough accounting structure to feel credible and let players verify stories through numbers, not only note metadata.

1. Expand annual row derivation for:
   - cash and cash equivalents
   - trade receivables
   - inventories
   - fixed assets / property, plant, and equipment
   - short-term and long-term debt
   - equity, retained earnings, and dividends
   - revenue, cost of revenue, gross profit, operating expenses, finance cost, tax, and net income
   - operating, investing, and financing cash flow bridges
2. Add enough continuity checks that rows tie together plausibly.
3. Keep this deterministic and bounded; do not build a full accounting engine.
4. Verify:
   - annual statement fingerprint
   - accounting continuity probe
   - existing annual builder test stays stable or gets an intentional new baseline

Task R3.2 implementation result:

- Annual statements now include `accounting_row_model` with 62 deterministic modeled rows across:
  - financial position rows for current assets, non-current assets, borrowings, equity, retained earnings, and totals
  - profit/loss rows for revenue, cost of revenue, gross profit, operating expenses, finance cost, tax, and net income
  - changes-in-equity rows for dividends and closing equity
  - cash-flow bridge rows for operating, investing, and financing cash flows
- Annual statements now include `accounting_continuity_checks` with 22 deterministic checks.
- Continuity checks cover:
  - current/non-current asset subtotals
  - current/non-current liability subtotals
  - total debt and borrowings
  - total liabilities and equity
  - balance sheet equation
  - gross profit, operating income, pre-tax income, net income, and comprehensive income bridges
  - equity roll-forward
  - operating, investing, and financing cash-flow bridges
  - net cash change and ending cash reconciliation
  - cross-statement cash and equity agreement
- Added `AnnualStatementAccountingContinuityTest` with fixed-seed hash `1613787417`.
- Updated `AnnualConsolidatedStatementBuilderTest` baseline to `867613961` because R3.2 intentionally adds annual statement rows.

Implementation status: complete. R3.3 should build filing-style note bodies and cross-note references on top of this row/continuity layer.

### R3.3 - Build filing-style note bodies and cross-note references

Problem: Current annual notes preserve provenance, but the visible note output is too direct and disconnected from how real filings hide clues across sections.

1. Convert generated note rows into filing-style note bodies with short paragraphs and compact tables.
2. Add cross-note references so one story can appear across:
   - revenue
   - segment information
   - receivables
   - inventories
   - PPE/capex
   - debt
   - related party transactions
   - commitments and contingencies
   - subsequent events
3. Avoid direct story labels in visible text unless the source would realistically disclose them.
4. Keep source ids and traceability hidden in payload/capture metadata.
5. Verify:
   - deterministic note body fingerprint
   - no hidden `truth_state` leaks
   - capture still preserves provenance

Task R3.3 implementation result:

- Annual note rows now expose filing-style body fields:
  - `filing_note_body`
  - `body_paragraphs`
  - `compact_tables`
  - `cross_note_references`
  - `visible_cross_reference_text`
  - `body_text`
  - `body_text_key`
- The renderer creates short document-like paragraphs and compact selected-amount tables from annual statement rows.
- Cross-note references are generated from:
  - default accounting relationships between notes
  - Story Dossier disclosure packet refs after post-start enrichment
  - packet `annual_statement_note_type` and `cross_reference_section_ids`
- The visible note body does not print `story_id`, `packet_id`, `placement_id`, `truth_state`, source-quality labels, or other hidden source metadata.
- Existing note-level metadata still preserves source ids and packet refs for Research Tray, thesis evidence, and tests.
- The document-reading contract now marks `notes` as readable and clears `compact_until_revision_section_ids`.
- Added `AnnualStatementFilingNoteBodyTest` with fixed-seed hash `1102538137`.
- Updated `AnnualReportDocumentContractTest` baseline to `2037575392`.

Implementation status: complete. R3.4 now uses these note body fields in the annual report document-reader flow.

### R3.4 - Rework the A4 report into a document reader flow

Problem: The player should feel like they are reading a formal report, not browsing app cards.

1. Add a document-reader flow for the consolidated statement:
   - table of contents / section jump list
   - page-like A4 frame
   - readable margins and typography
   - section headers and note numbers
   - compact tables that fit on desktop and smaller screens
2. Preserve the existing `View Consolidated Financial Statement` entry point.
3. Keep evidence capture available from statement rows and note paragraphs.
4. Verify:
   - UI smoke opens the document reader
   - A4 bounds still hold
   - section navigation reaches all required sections
   - text does not overlap in common viewport sizes

Implementation status: complete. R3.4 keeps the existing entry point but renders a real reader: sidebar TOC, in-page TOC, anchored annual sections, A4 page sizing, formal note paragraphs/tables, cross-note references, and paragraph-level evidence capture.

### R3.5 - Consume subtle disclosure placements from Story Dossier Revision R1

Problem: Financial statements should reveal story clues through scattered filing evidence, not a single obvious note row.

1. Read dossier disclosure placement packets once Story Dossier R1 defines them.
2. Place each packet in the matching annual report section or note.
3. Keep clue obviousness controlled by dossier placement metadata:
   - direct
   - implied
   - buried
   - conflicting
   - missing
4. Preserve R2 source arrays and refs under the hood.
5. Verify:
   - a story can appear across multiple sections
   - no single generated note spoon-feeds the full conclusion unless configured as direct
   - thesis evidence capture keeps the underlying source ids

Implementation status: complete. Story Dossier R1.6 locked the final cross-feature fixture with hash `623183840`; R3.5 now consumes those packet refs in the annual report reader through subtlety-specific disclosure packet paragraphs and packet-level capture metadata.

### R3.6 - Add annual report fidelity, capture, and smoke tests

Problem: R3 changes document structure, accounting rows, note bodies, and clue placement; regressions need focused coverage.

1. Add fixed-seed annual report fidelity tests.
2. Add clue-placement-to-report tests using deterministic Story Dossier packets.
3. Add evidence capture tests for:
   - statement row
   - note paragraph
   - cross-note reference
4. Add UI smoke for:
   - table of contents
   - A4 page
   - all required statement sections
   - note navigation
5. Run existing R1/R2 annual tests and quick smoke.

Implementation status: complete. `AnnualReportFidelityCaptureTest` now hardens the completed R3.1-R3.5 reader, packet-placement, and capture behavior into the final annual report fidelity suite; quick smoke also asserts rendered cross-note reference controls.

## Known traps

- Too much accounting detail will slow implementation and confuse the player.
- Too little structure will make footnotes cosmetic.
- Do not let statement generation contradict price/story state.
- Do not let the A4 document styling make the report unreadable on smaller screens.
- Do not replace quarterly statement internals accidentally; annual consolidated statements should extend the layer without breaking existing v1 filing consumers.
- Do not make R2 enrichment depend on generated prose matching; use structured IDs and source arrays.
- Do not run annual note enrichment before the Story Dossier, Living Company Arc, corporate action, event, and roadmap systems have stable state.
- Do not let R3 turn every filing clue into an obvious conclusion; the player should need to read across sections.
- Do not expose dossier hidden truth state, clue directness, or confidence as visible filing text.
