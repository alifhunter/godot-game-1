# Annual Filing Sector Realism Enhancement - Plan & Progress Log

This plan corrects the generated consolidated financial statement so it reads like a sector-specific annual filing instead of generic generated clue prose.
**Status: complete - Tasks 1-7 complete.** Designed to run in a fresh session; everything needed to execute cold is in this file.

**Review verdict recap:** The current annual filing reader has useful plumbing: lazy generation, A4 reader shell, deterministic section anatomy, evidence capture, traceability, cache guards, and duplicate-output regression coverage. The remaining product problem is quality: generated paragraphs can feel incoherent, repetitive, and too explicit, especially when one generic note/prose model is applied across all company types. The fix is to move from paragraph-first generic prose to table-first, sector-specific filing profiles where clues are buried in appropriate statement rows, note tables, accounting policy noise, and formal risk disclosures.

## Where everything lives

| What | Where |
|---|---|
| Current annual filing generator | `systems/AnnualFilingDocument.gd` - lazy document contract, anatomy, accounting footprints, visible filing generation, prose/noise generation, cache hash |
| Current annual statement source | `systems/AnnualStatementBuilder.gd` - deterministic annual consolidated statement rows and note source payloads |
| Current story source | `systems/CompanyStoryDossierSystem.gd` - story truth, disclosure packets, subtlety/placement metadata, filing traceability |
| Current financial adapter | `systems/FinancialStatementLayer.gd` - story effects and annual-note enrichment bridge |
| Current UI entry point | `scripts/ui/controllers/StockController.gd` - `View Consolidated Financial Statement` button and A4 report overlay |
| Current runtime state | `autoloads/RunState.gd` - company snapshots, annual statement enrichment, evidence normalization, save/load defaults |
| Company identity source | `data/companies/company_universe_catalog.json` - sector/subsector, business model, moat, exposure, and company profile fields |
| Current tests/probes | `scripts/tests/AnnualFilingVisibleGenerationTest.gd`, `scripts/tests/AnnualFilingRegressionGuardTest.gd`, `scripts/tests/AnnualReportFidelityCaptureTest.gd`, `scripts/tests/AnnualFilingProseLibraryTest.gd`, `scripts/tests/SmokeTest.gd` |
| Reference extraction tool | `tools/pdf_text_extractor/` from workspace root - local-only PDF text extraction helper outside `godot-game-1` |
| Existing industrial/trading reference | `tools/pdf_text_extractor/output/PT_AKR_Corporindo_2025_extracted.txt` from workspace root |
| New banking reference | `/Users/user/Downloads/PT Bank Sinarmas Tbk 31Des2025.pdf` - local reference only, not a game asset |
| Parent roadmap | `docs/development/top_down_market/TOP_DOWN_MARKET_SYSTEM_ROADMAP.md` |
| Prior annual filing plan | `docs/development/top_down_market/ANNUAL_FILING_READING_EXPERIENCE_ENHANCEMENT.md` |

## Product Problem

The current visible filing output is trying too hard to explain what the filing means. That makes it feel like a generated evidence card rather than a financial statement.

Specific failure modes observed:

- Generic paragraphs repeat across note sections.
- Some paragraphs are grammatically valid but contextually meaningless.
- Important clues are too often phrased as direct explanations instead of appearing through tables and note context.
- Industrial/trading-style notes are reused for banks and other sectors where the statement anatomy should be different.
- Section prose sometimes describes the note instead of behaving like the note.
- The output lacks the boring but coherent accounting-policy and note-table texture that makes real filings readable.

## Task 1 Audit Findings

Audit probe date: 2026-06-24.

Fixed-seed diagnostic setup:

- Run seed: `20260624`
- Bank sample: `bank_orang_indonesia` / `BORI` / finance / banking
  - visible filing hash: `515365850`
  - section count: `20`
  - paragraph count: `39`
  - compact table count: `4`
  - cross-reference count: `3`
  - repeated visible paragraph count: `5`
  - bank-term hits: none for `loan`, `loans`, `deposits`, `credit risk`, `allowance`, `capital adequacy`, `stage 1`, `stage 2`, or `stage 3`
- Industrial sample: `alat_berat_mandiri` / `ABMD` / industrial / heavy equipment distribution
  - visible filing hash: `1646891920`
  - section count: `20`
  - paragraph count: `35`
  - compact table count: `3`
  - cross-reference count: `3`
  - repeated visible paragraph count: `4`

Taxonomy of current realism failures:

| Failure | Current symptom | Desired replacement |
|---|---|---|
| Sector-anatomy mismatch | A bank renders `Inventories` and `Investments And Property, Plant, And Equipment` as ordinary core note sections. | Finance/banking companies should render bank-specific notes: loans, deposits, impairment allowance, securities, reserves, CAR, credit risk, liquidity risk, related parties, and regulatory compliance. |
| Missing bank surfaces | The bank sample has zero visible bank-term hits and no loan/deposit/credit-risk/capital-adequacy table surface. | Bank filings must expose at least loans/financing, deposits, impairment allowance, and capital/risk sections before they are considered valid. |
| Generic explanatory prose | Repeated sentences such as `describes the recognition and movement...`, `same basis as the consolidated statements`, and `supporting schedule includes...` appear across unrelated notes. | Replace with section-specific policy, note lead-in, risk-framework, or table-context prose. Generic filler should be removed or capped at zero in visible player output. |
| Account/section pairing drift | Bank sections can show industrial account language such as inventories, gross profit, cost of revenue, and PPE. | Profile-specific allow/deny lists should prevent incompatible captions and paragraphs from rendering for a profile. |
| Paragraph-first evidence | Useful clues are being carried by explanatory paragraphs instead of formal note tables and row classifications. | Tables, comparative columns, note numbers, and cross-note references should carry most evidence; prose should provide context and noise. |
| Dedupe-as-quality illusion | Duplicate guards reduce exact repeats but still leave structurally similar fake prose. | Generation should avoid producing generic filler in the first place; dedupe remains a safety rail only. |
| Flat profile model | `sector_style_id` is currently too shallow to reshape statement anatomy. | Add a filing-profile contract with profile id/version, selected deterministically from company sector/subsector/business model metadata. |

Measurable gates for Tasks 2-7:

- Bank profile must include required visible section ids for loans/financing, deposits, allowance for impairment, securities/placements, capital adequacy, credit risk, and liquidity risk.
- Bank profile must exclude incompatible industrial sections as core notes: inventories, gross profit, cost of revenue, and PPE/capex as primary clue surfaces.
- Bank profile must produce at least `8` compact/structured tables in the visible filing once Task 3 is complete.
- Bank profile must produce at least `20` bank-specific table rows across loan, deposit, allowance, securities, and capital/risk sections once Task 3 is complete.
- Bank profile must contain visible terms or captions covering loans/financing, deposits, allowance/impairment, credit risk, and capital adequacy.
- Generic explanatory phrases must be capped at `0` visible occurrences after Task 4:
  - `describes the recognition and movement`
  - `same basis as the consolidated statements`
  - `supporting schedule includes`
- Exact repeated visible paragraph count must remain `0` per filing.
- Hidden-token leakage remains `0` for `story|`, `packet|`, `placement|`, `truth_state`, `source_quality`, `confidence`, and related internal labels.
- Industrial/trading profile must keep industrial-appropriate notes such as segment information, inventories/working capital, receivables, PPE/capex, commitments, and risk management, but should not render bank-only sections.
- Table/prose balance target after Task 5:
  - bank profile: table count should exceed generic prose block count
  - industrial/trading profile: table count should be at least comparable to prose-bearing note sections

## Reference Learnings

The AKR and Bank Sinarmas references point to the same product correction:

- Real filings are table-first. The useful information is often in rows, note numbers, comparative columns, classifications, and movement schedules.
- Paragraphs are mostly formal explanation, policy boilerplate, accounting basis, or risk-framework language.
- The same sentence should not be reused to make every section feel important.
- Useful clues are distributed, not announced.
- Sector anatomy matters:
  - Trading/logistics/industrial filings emphasize revenue, gross profit, inventory, receivables, PPE, commitments, segments, and commodity/FX risk.
  - Bank filings emphasize cash and reserves, placements, securities, loans by stage, allowance for impairment, deposits, sharia/temporary syirkah funds if applicable, capital adequacy, liquidity, credit risk, related parties, and sector collectibility.
- Accounting-policy noise is a feature, not a bug, if it is coherent and bounded.

## Goals

- Replace generic filing prose with sector-specific annual filing profiles.
- Make player-facing annual filings table-first and note-number driven.
- Add a bank filing profile as the first proof that different sectors need different anatomy.
- Keep industrial/trading companies on a separate base profile informed by the AKR reference.
- Reduce explicit “clue explanation” paragraphs and move evidence into tables, note rows, and cross-note context.
- Preserve lazy generation, deterministic cache keys, Research Tray capture, thesis evidence, and hidden-truth safety.
- Add regression tests that fail on repeated filler, hidden-token leakage, missing sector-specific sections, and table/prose imbalance.

## Non-goals

- Do not build a professional IFRS/PSAK accounting simulator.
- Do not copy source PDF text verbatim into the game. Use references only for structure, tone, and section patterns.
- Do not generate a real PDF export in this pass.
- Do not rebuild the entire financial statement system from scratch.
- Do not make all sector profiles at once. Start with `bank` and one `industrial_trading` base profile.
- Do not remove the existing annual filing reader, cache, or evidence capture routes unless a task explicitly replaces a narrow part.

## Working Rules

- The filing is still generated only when the player clicks `View Consolidated Financial Statement`.
- Sector profile choice must be deterministic from company sector/subsector/business model data.
- Visible text must never expose hidden ids or truth labels such as `story|`, `packet|`, `placement|`, `truth_state`, `source_quality`, or confidence labels.
- Prose libraries must be section-specific. No generic sentence should be sprayed across unrelated notes.
- Table rows should carry most evidence. Paragraphs should provide formal context and occasional buried clues.
- Every retained visible paragraph should have a reason: policy boilerplate, note introduction, risk framework, management judgment, subsequent event, or specific disclosure.
- One task per checkpoint commit; verify before each commit.
- Use short extracted snippets only for internal design review; do not add reference PDF text to runtime data.

## Status

| # | Task | Est. cost | Status |
|---|---|---|---|
| 1 | Audit current filing output and define realism failure taxonomy | ~10-15% | Complete |
| 2 | Add sector filing profile contract and profile selection | ~15-25% | Complete |
| 3 | Add bank filing anatomy and table models | ~25-40% | Complete |
| 4 | Replace generic prose with section-specific prose/noise libraries | ~25-40% | Complete |
| 5 | Rebalance visible filing generation around tables and note references | ~20-35% | Complete |
| 6 | Preserve capture, thesis, cache, and UI behavior under sector profiles | ~15-30% | Complete |
| 7 | Add realism, determinism, and full-player-flow regression tests | ~15-30% | Complete |

Recommended batching: **Session 1 = Task 1** because we need a clear failure taxonomy before changing generation. **Session 2 = Task 2** because profile selection is the contract all later work depends on. **Session 3 = Task 3** should focus only on banks. **Session 4 = Tasks 4-5** because prose cleanup and table-first rendering need to move together. **Session 5 = Tasks 6-7** hardens capture, cache, UI, and smoke coverage.

## Progress Log

### 2026-06-24 - Plan created

- Created this enhancement plan after reviewing the current generated consolidated financial statement output and the Bank Sinarmas FY2025 reference PDF.
- Product correction:
  - the current generated filing can become incoherent because it uses generic prose and repeated explanatory fragments
  - real filings are table-first, sector-specific, and often boring by design
  - the next pass should not add more clue paragraphs; it should make the document behave more like a filing
- Reference basis:
  - AKR reference remains useful for trading/logistics/industrial-style filing anatomy
  - Bank Sinarmas reference establishes that banks need different sections and tables, especially loans, deposits, impairment allowances, regulatory capital, liquidity, and credit risk
- No code, runtime data, or behavior changes were made by this planning step.

### 2026-06-24 - Task 1 complete

- Ran a temporary diagnostic annual-filing realism probe against fixed seed `20260624`.
- Audited two generated visible filings:
  - `bank_orang_indonesia` / `BORI` / finance banking
  - `alat_berat_mandiri` / `ABMD` / industrial heavy equipment distribution
- Findings:
  - the bank filing still uses the generic 20-section annual filing anatomy
  - the bank filing has no loan/deposit/credit-risk/allowance/CAR/stage table surface
  - the bank filing incorrectly includes industrial note surfaces such as inventories and PPE
  - both samples still include generic explanatory filler phrases, even after exact duplicate rows were previously fixed
- Added `Task 1 Audit Findings` with a failure taxonomy and measurable gates for later tasks.
- The temporary diagnostic probe files were deleted after the audit; no permanent runtime or test code was added.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualFilingRealismAuditProbe.tscn` -> `ANNUAL_FILING_REALISM_AUDIT ...`
  - `git diff --check`

### 2026-06-24 - Task 2 complete

- Added the annual filing profile contract to `AnnualFilingDocument.gd`.
- New profile metadata:
  - `filing_profile_schema_version = 1`
  - `filing_profile_status = task2_profile_contract_ready`
  - `filing_profile_version = annual_filing_profile_r1`
  - initial profiles: `default_general`, `industrial_trading`, and `bank`
- Added deterministic profile selection helpers:
  - `select_filing_profile(...)`
  - `resolve_filing_profile_id(...)`
  - `filing_profile_definition(...)`
  - `filing_profile_definitions()`
- Selection behavior:
  - clear bank subsectors/business text resolve to `bank`
  - industrial/energy/infrastructure/transport/basicindustry companies resolve to `industrial_trading`
  - unknown or non-bank finance companies resolve to `default_general`
  - explicit valid `filing_profile_id` option is supported for tests/future controlled overrides
- Added `filing_profile_id` and `filing_profile_version` to:
  - annual filing contract payload
  - cache key parts
  - invalidation fields
  - document hash payload
  - visible generation source diagnostics
- Updated the UI filing request path in `StockController.gd` to pass company sector, subsector, business summary, moat tags, and story hooks into the annual filing request.
- Intentional non-change:
  - visible section anatomy and prose are still the old generic output; Task 3 starts the bank-specific anatomy/table replacement.
- Added `AnnualFilingProfileContractTest`.
- Updated deterministic baselines impacted by the profile contract:
  - `AnnualFilingProfileContractTest` hash `1797149452`
  - `AnnualFilingLazyContractTest` hash `845198826`
  - `AnnualFilingVisibleGenerationTest` hash `612989486`, visible filing hash unchanged at `1961685698`
  - `AnnualFilingRegressionGuardTest` hash `364031338`, visible filing hash unchanged at `1961685698`
  - `AnnualFilingFootprintPacketTest` hash `927427562`, footprint hash unchanged at `1341822473`
  - `AnnualFilingProseLibraryTest` hash `209615469`, prose hash unchanged at `759507930`
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualFilingProfileContractTest.tscn` -> `ANNUAL_FILING_PROFILE_CONTRACT_OK {"hash":"1797149452","bank_profile":"bank","industrial_profile":"industrial_trading","default_profile":"default_general","profile_version":"annual_filing_profile_r1"}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualFilingLazyContractTest.tscn` -> `ANNUAL_FILING_LAZY_CONTRACT_OK {"hash":"845198826",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualFilingVisibleGenerationTest.tscn` -> `ANNUAL_FILING_VISIBLE_GENERATION_OK {"hash":"612989486","visible_filing_hash":"1961685698",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualFilingRegressionGuardTest.tscn` -> `ANNUAL_FILING_REGRESSION_GUARD_OK {"hash":"364031338","visible_filing_hash":"1961685698",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualFilingAnatomySchemaTest.tscn` -> `ANNUAL_FILING_ANATOMY_SCHEMA_OK {"hash":"230195522",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualFilingFootprintPacketTest.tscn` -> `ANNUAL_FILING_FOOTPRINT_PACKET_OK {"hash":"927427562","footprint_hash":"1341822473",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualFilingProseLibraryTest.tscn` -> `ANNUAL_FILING_PROSE_LIBRARY_OK {"hash":"209615469","prose_hash":"759507930",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualReportFidelityCaptureTest.tscn` -> `ANNUAL_REPORT_FIDELITY_CAPTURE_OK {"hash":"906899410",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/TopDownResearchSurfaceIntegrationTest.tscn` -> `TOP_DOWN_RESEARCH_SURFACE_INTEGRATION_OK {"filing_document_sections":20,...}`

### 2026-06-24 - Task 3 complete

- Added the first sector-specific filing anatomy: the `bank` filing profile now uses bank note sections instead of the generic industrial/trading note groups.
- New bank note sections:
  - `note_bank_company_information`
  - `note_bank_accounting_policies`
  - `note_bank_cash_reserves`
  - `note_bank_placements`
  - `note_bank_securities`
  - `note_bank_loans_financing`
  - `note_bank_allowance_impairment`
  - `note_bank_deposits`
  - `note_bank_temporary_syirkah_funds`
  - `note_bank_interest_income`
  - `note_bank_related_parties`
  - `note_bank_capital_adequacy`
  - `note_bank_credit_risk`
  - `note_bank_liquidity_risk`
  - `note_bank_regulatory_compliance`
- Generic/default filings continue to use the existing 20-section anatomy; their visible filing hash stayed unchanged.
- Added deterministic bank compact-table models for:
  - cash and statutory reserves
  - placements with Bank Indonesia and other banks
  - securities by class
  - loans by credit stage
  - loans by product type
  - loans by economic sector
  - allowance for impairment losses by stage
  - deposits by type and party
  - temporary syirkah funds
  - interest and sharia income by source
  - related-party bank balances
  - capital adequacy / risk-weighted assets
  - credit risk quality indicators
  - liquidity maturity buckets
  - regulatory reserve and compliance indicators
- The bank table rows are deterministic from the existing annual statement values, with bounded fallback splits when the source statement does not yet provide bank-native accounts.
- Added `AnnualFilingBankAnatomyTableTest`.
- Fixed baseline changes caused by the bank override now producing real bank anatomy:
  - `AnnualFilingBankAnatomyTableTest` hash `1954416590`
  - `AnnualFilingProfileContractTest` hash `40158817`
  - `AnnualFilingRegressionGuardTest` hash `534572776`, visible filing hash unchanged at `1961685698`
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualFilingBankAnatomyTableTest.tscn` -> `ANNUAL_FILING_BANK_ANATOMY_TABLE_OK {"company_id":"bank_orang_indonesia","hash":"1954416590","profile":"bank","section_count":23,"table_count":18,"table_row_count":56,"visible_filing_hash":"1790878466"}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualFilingProfileContractTest.tscn` -> `ANNUAL_FILING_PROFILE_CONTRACT_OK {"hash":"40158817",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualFilingLazyContractTest.tscn` -> `ANNUAL_FILING_LAZY_CONTRACT_OK {"hash":"845198826",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualFilingVisibleGenerationTest.tscn` -> `ANNUAL_FILING_VISIBLE_GENERATION_OK {"hash":"612989486","visible_filing_hash":"1961685698",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualFilingRegressionGuardTest.tscn` -> `ANNUAL_FILING_REGRESSION_GUARD_OK {"hash":"534572776","visible_filing_hash":"1961685698",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualFilingFootprintPacketTest.tscn` -> `ANNUAL_FILING_FOOTPRINT_PACKET_OK {"hash":"927427562","footprint_hash":"1341822473",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualFilingProseLibraryTest.tscn` -> `ANNUAL_FILING_PROSE_LIBRARY_OK {"hash":"209615469","prose_hash":"759507930",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualReportFidelityCaptureTest.tscn` -> `ANNUAL_REPORT_FIDELITY_CAPTURE_OK {"hash":"906899410",...}`

### 2026-06-24 - Task 4 complete

- Replaced the remaining generic footprint prose in `AnnualFilingDocument.gd` with section-specific text paths.
- Added bank-specific prose roles and vocabulary:
  - `bank_cash_reserves`
  - `bank_loans`
  - `bank_funding`
  - `bank_capital`
  - `bank_credit_risk`
  - `bank_liquidity_risk`
  - `bank_regulatory`
- Added `bank_annual_filing` vocabulary so bank filings use bank language even when the company sector style is only `finance`.
- Changed bank sections to use bank prose roles instead of reusing generic `receivables` and `borrowings` prose.
- Replaced the old repeated filler sources:
  - `describes the recognition and movement`
  - `same basis as the consolidated statements`
  - `supporting schedule includes`
  - `the note presentation should be read together`
  - `this disclosure should be read together`
- Added visible/prose guards for those forbidden phrases in:
  - `AnnualFilingProseLibraryTest`
  - `AnnualFilingVisibleGenerationTest`
  - `AnnualFilingRegressionGuardTest`
  - `AnnualFilingBankAnatomyTableTest`
- Updated deterministic baselines caused by prose/cache-key changes:
  - `AnnualFilingProseLibraryTest` hash `1485407092`, prose hash `367944784`
  - `AnnualFilingVisibleGenerationTest` hash `1490076547`, visible filing hash `363169314`
  - `AnnualFilingBankAnatomyTableTest` hash `1006124506`, visible filing hash `143331570`
  - `AnnualFilingRegressionGuardTest` hash `495065561`, visible filing hash `363169314`
  - `AnnualFilingProfileContractTest` hash `1921234662`
  - `AnnualFilingLazyContractTest` hash `160244644`, prose hash `367944784`
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualFilingProseLibraryTest.tscn` -> `ANNUAL_FILING_PROSE_LIBRARY_OK {"hash":"1485407092","prose_hash":"367944784","prose_count":48}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualFilingVisibleGenerationTest.tscn` -> `ANNUAL_FILING_VISIBLE_GENERATION_OK {"hash":"1490076547","visible_filing_hash":"363169314","paragraph_count":40,"table_count":4}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualFilingBankAnatomyTableTest.tscn` -> `ANNUAL_FILING_BANK_ANATOMY_TABLE_OK {"hash":"1006124506","visible_filing_hash":"143331570","section_count":23,"table_count":18,"table_row_count":56}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualFilingRegressionGuardTest.tscn` -> `ANNUAL_FILING_REGRESSION_GUARD_OK {"hash":"495065561","visible_filing_hash":"363169314"}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualFilingProfileContractTest.tscn` -> `ANNUAL_FILING_PROFILE_CONTRACT_OK {"hash":"1921234662",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualFilingLazyContractTest.tscn` -> `ANNUAL_FILING_LAZY_CONTRACT_OK {"hash":"160244644","filing_prose_hash":"367944784",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualFilingFootprintPacketTest.tscn` -> `ANNUAL_FILING_FOOTPRINT_PACKET_OK {"hash":"927427562","footprint_hash":"1341822473",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualReportFidelityCaptureTest.tscn` -> `ANNUAL_REPORT_FIDELITY_CAPTURE_OK {"hash":"906899410",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualFilingAnatomySchemaTest.tscn` -> `ANNUAL_FILING_ANATOMY_SCHEMA_OK {"hash":"230195522","filing_schema_hash":"700723473",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/TopDownResearchSurfaceIntegrationTest.tscn` -> `TOP_DOWN_RESEARCH_SURFACE_INTEGRATION_OK {"company_id":"fiber_kota_prima","filing_document_sections":20,...}`

---

## Task 1 - Audit Current Filing Output And Define Realism Failure Taxonomy

Problem: The current annual filing generator has several visible quality failures, but the failure modes need to be named before code is changed.

1. Generate or inspect at least two fixed-seed filings:
   - one bank/finance company
   - one industrial/trading/commodity-exposed company
2. Capture examples of bad output categories without storing reference PDF text in runtime data:
   - repeated filler
   - note title mismatch
   - section-generic explanation
   - incoherent account/section pairing
   - too-explicit story clue
   - missing sector-specific table
   - table/prose imbalance
3. Add a short taxonomy section to this plan with current examples and desired replacement behavior.
4. Define measurable realism gates for later tasks:
   - maximum repeated visible sentence count per filing
   - minimum table count for bank profile
   - minimum section-specific row count
   - maximum generic paragraph count
   - required bank-only section ids
5. Verify:
   - `git diff --check`
   - no runtime code behavior changes unless the task adds a diagnostic-only test/probe

Implementation status: complete. The audit taxonomy and measurable realism gates are recorded above. The temporary diagnostic probe was deleted after use, so Task 1 leaves documentation only.

## Task 2 - Add Sector Filing Profile Contract And Profile Selection

Problem: A single filing anatomy cannot serve banks, trading/logistics, industrials, consumers, and commodity companies.

1. Add a pure filing profile contract, likely owned by `AnnualFilingDocument.gd` or a new helper if the file becomes too large.
2. Define initial profiles:
   - `industrial_trading`
   - `bank`
   - `default_general`
3. Select profile deterministically from company data:
   - sector id
   - subsector id
   - business model/profile group
   - finance/bank tags where available
4. Include the selected profile id and profile version in the annual filing cache key/invalidation payload.
5. Keep current visible output behavior as close as possible until Tasks 3-5 replace section generation.
6. Add focused tests:
   - fixed finance company resolves to `bank`
   - fixed trading/industrial company resolves to `industrial_trading`
   - unknown/malformed company resolves to `default_general`
   - profile id changes annual filing hash/cache key deterministically
7. Verify:
   - targeted profile contract test
   - existing annual filing lazy/visible regression tests
   - `git diff --check`

Implementation status: complete. The profile contract and deterministic selector are in place, the annual filing cache key now includes profile id/version, and the UI request path passes company profile context. The actual bank-specific anatomy/table model is intentionally deferred to Task 3.

## Task 3 - Add Bank Filing Anatomy And Table Models

Problem: Bank filings need their own statement and note surfaces. Reusing generic inventory/PPE/revenue note logic for banks produces wrong-feeling output.

1. Define bank-specific visible sections and note groups:
   - cash and reserves
   - demand deposits with central bank and other banks
   - placements with central bank/other banks
   - securities
   - loans and sharia financing
   - allowance for impairment losses
   - deposits and deposits from other banks
   - temporary syirkah funds where applicable
   - interest income and sharia income
   - related parties
   - capital adequacy
   - credit risk
   - liquidity risk
   - regulatory reserves / compliance notes
2. Add bank table models:
   - loans by stage / credit quality
   - loans by product type
   - loans by economic sector
   - allowance for impairment losses by stage
   - deposits by type and party
   - securities by class
   - CAR / risk-weighted assets
   - interest income by source
3. Map current company financial/profile/story fields into plausible simplified bank rows.
4. Use deterministic fallback values when existing company data is not bank-specific enough.
5. Ensure bank tables avoid industrial rows such as inventory, gross profit, or PPE unless the section is genuinely applicable.
6. Add tests:
   - bank filing contains required bank sections
   - bank filing excludes incompatible industrial note rows
   - bank visible filing is deterministic for fixed seed/company/fiscal year
7. Verify:
   - targeted bank anatomy/table test
   - annual filing visible generation test
   - `git diff --check`

Implementation status: complete. The `bank` profile now has its own visible note section anatomy and deterministic compact-table models. The existing generic/default visible filing path remains stable. Task 4 later replaced the remaining generic prose with section-specific bank/default prose libraries.

## Task 4 - Replace Generic Prose With Section-Specific Prose And Noise Libraries

Problem: The current generated prose can sound like a repeated explanation of the note instead of a natural filing note.

1. Create section-specific prose pools for:
   - industrial/trading profile
   - bank profile
   - shared front matter / audit / table-of-contents language
2. Separate prose into roles:
   - accounting policy boilerplate
   - note introduction
   - management judgment
   - risk framework
   - table lead-in
   - subsequent event language
   - rare buried clue
3. Remove or quarantine generic filler sentences that can appear in unrelated sections.
4. Add prose quality rules:
   - no repeated paragraph text inside a filing
   - no “this note describes...” filler unless it is a real note introduction and not repeated
   - no account caption mismatch with note title
   - no clue-summary phrasing
5. Keep formal tone. The document can be dry; it should not try to be entertaining.
6. Add tests:
   - duplicate paragraph guard
   - forbidden generic phrase guard
   - hidden-token guard
   - profile-specific phrase/section guard
7. Verify:
   - annual filing prose library test
   - annual filing visible generation test
   - annual filing regression guard
   - `git diff --check`

Implementation status: complete. Bank and default filings now use section-specific routine prose, footprint prose, and cross-reference wording. Forbidden generic filler phrase guards are in place across prose, visible, regression, and bank anatomy/table tests. Task 5 later rebalanced how many paragraphs are emitted relative to note tables and references; Task 4 deliberately left table/prose ratio tuning to that next step.

### 2026-06-24 - Task 5 complete

- Rebalanced visible annual filing generation around a deterministic table-first display-block contract.
- Added visible filing assembly priority:
  - `statement_rows`
  - `compact_table`
  - `comparative_movement`
  - `cross_reference`
  - `formal_lead_in`
  - `limited_prose`
- Added profile-specific visible balance targets:
  - default/general and industrial/trading filings now cap note prose when tables or references exist
  - bank filings now target table count greater than note prose count
- Added generated section `display_blocks` so the UI renders note tables first, cross-references second, and limited paragraphs last.
- Added visible filing metadata:
  - `visible_filing_table_row_count`
  - `visible_filing_display_block_count`
  - `visible_filing_assembly_priority`
  - `visible_filing_profile_balance`
- Updated `StockController.gd` to render generated annual filing sections through `display_blocks`, while keeping a fallback path for older documents.
- Updated tests to lock:
  - profile balance target success
  - table-first display block order
  - display block count consistency
  - bank table row source backing
  - no `Notes -` prefix on visible note section titles
  - no forbidden generic visible phrases
- Updated deterministic baselines:
  - `AnnualFilingVisibleGenerationTest` hash `1803230173`, visible filing hash `169939267`, paragraph count `25`, table count `4`
  - `AnnualFilingBankAnatomyTableTest` hash `1779696113`, bank visible filing hash `601383779`, table count `18`, table row count `56`
  - `AnnualFilingRegressionGuardTest` hash `1878982941`, visible filing hash `169939267`
  - `AnnualFilingProfileContractTest` hash `714906742`
  - `AnnualFilingLazyContractTest` hash `1985960845`
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualFilingVisibleGenerationTest.tscn` -> `ANNUAL_FILING_VISIBLE_GENERATION_OK {"hash":"1803230173","visible_filing_hash":"169939267","paragraph_count":25,"table_count":4}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualFilingBankAnatomyTableTest.tscn` -> `ANNUAL_FILING_BANK_ANATOMY_TABLE_OK {"hash":"1779696113","visible_filing_hash":"601383779","section_count":23,"table_count":18,"table_row_count":56}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualFilingRegressionGuardTest.tscn` -> `ANNUAL_FILING_REGRESSION_GUARD_OK {"hash":"1878982941","visible_filing_hash":"169939267"}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualFilingLazyContractTest.tscn` -> `ANNUAL_FILING_LAZY_CONTRACT_OK {"hash":"1985960845","filing_prose_hash":"367944784",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualFilingProfileContractTest.tscn` -> `ANNUAL_FILING_PROFILE_CONTRACT_OK {"hash":"714906742",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualFilingProseLibraryTest.tscn` -> `ANNUAL_FILING_PROSE_LIBRARY_OK {"hash":"1485407092","prose_hash":"367944784",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualFilingFootprintPacketTest.tscn` -> `ANNUAL_FILING_FOOTPRINT_PACKET_OK {"hash":"927427562","footprint_hash":"1341822473",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualFilingAnatomySchemaTest.tscn` -> `ANNUAL_FILING_ANATOMY_SCHEMA_OK {"hash":"230195522","filing_schema_hash":"700723473",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualReportFidelityCaptureTest.tscn` -> `ANNUAL_REPORT_FIDELITY_CAPTURE_OK {"hash":"906899410",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/TopDownResearchSurfaceIntegrationTest.tscn` -> `TOP_DOWN_RESEARCH_SURFACE_INTEGRATION_OK {"company_id":"fiber_kota_prima","filing_document_sections":20,...}`

### 2026-06-24 - Task 6 complete

- Added `AnnualFilingBankReaderUiSmokeTest` to exercise the actual Stock app annual filing reader with fixed-seed bank company `bank_orang_indonesia`.
- The focused UI smoke confirms:
  - `View Consolidated Financial Statement` still lazy-builds only after click
  - first open is a cache miss/build and second open is a cache hit
  - cache key parts and invalidation fields include `filing_profile_version` and `source_state_hash`
  - bank profile opens in the A4 reader shell with vertical-only page scrolling
  - bank-only TOC navigation works for `note_bank_credit_risk`
  - rendered bank tables remain bounded in the page
  - statement row, note paragraph, note table row, and cross-reference capture payloads survive Research Tray capture, thesis attach, direct thesis evidence add, and save/load
  - a non-bank catalog company still renders a non-bank visible filing without bank-only sections
- The new smoke found and fixed a real UI-path profile issue: `StockController.gd` now enriches annual filing request options from `RunState.get_effective_company_definition(...)` when the current trade snapshot lacks sector/subsector/business profile fields.
- Fixed-seed smoke baseline:
  - `AnnualFilingBankReaderUiSmokeTest` hash `994645212`
  - bank profile `bank`
  - section count `23`
  - table count `18`
  - table row count `56`
  - visible filing hash `601383779`
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualFilingBankReaderUiSmokeTest.tscn` -> `ANNUAL_FILING_BANK_READER_UI_SMOKE_OK {"hash":"994645212","profile":"bank","section_count":23,"table_count":18,"table_row_count":56,"capture_count":4,"visible_filing_hash":"601383779"}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualFilingBankAnatomyTableTest.tscn` -> `ANNUAL_FILING_BANK_ANATOMY_TABLE_OK {"hash":"1779696113","profile":"bank","section_count":23,"table_count":18,"table_row_count":56,"visible_filing_hash":"601383779"}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualFilingLazyContractTest.tscn` -> `ANNUAL_FILING_LAZY_CONTRACT_OK {"hash":"1985960845",...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualFilingVisibleGenerationTest.tscn` -> `ANNUAL_FILING_VISIBLE_GENERATION_OK {"hash":"1803230173","visible_filing_hash":"169939267"}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualFilingRegressionGuardTest.tscn` -> `ANNUAL_FILING_REGRESSION_GUARD_OK {"hash":"1878982941","visible_filing_hash":"169939267"}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/TopDownResearchSurfaceIntegrationTest.tscn` -> `TOP_DOWN_RESEARCH_SURFACE_INTEGRATION_OK {"company_id":"fiber_kota_prima","filing_document_sections":20,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=95485619.77 days=3 ...`
  - `/Users/user/.local/bin/godot --headless -e --quit`
  - `git diff --check`

### 2026-06-24 - Task 7 complete

- Added `AnnualFilingSectorRealismRegressionTest` as the final fixed-seed sector realism guard.
- The new regression covers:
  - bank profile section order and required bank table sections
  - bank minimum table/table-row counts
  - bank bounded paragraph count
  - industrial/trading required note ids
  - industrial segment/inventory/receivable/commitment/risk surfaces
  - no bank-only sections in the industrial/trading filing
  - duplicate paragraph guard
  - hidden-token guard
  - forbidden generic filler phrase guard
  - deterministic profile/document hash snapshot
- Updated `FullYearPlayerScenarioTest` to run against the catalog roster and use `bank_orang_indonesia` as the player-flow target.
- The full-year scenario now:
  - launches `GameRoot.tscn`
  - buys `BORI`
  - opens the bank annual filing profile
  - captures filing evidence types `statement_row`, `note_table_row`, and `note_paragraph`
  - attaches filing evidence into thesis `thesis_bank_orang_indonesia_001`
  - generates the final thesis report
  - advances 225 trading days
  - writes important metrics to `docs/development/test_log/2026-06-24_annual_filing_sector_realism_full_year.md`
- Fixed-seed regression baseline:
  - `AnnualFilingSectorRealismRegressionTest` hash `398621424`
  - bank visible filing hash `601383779`
  - bank table count `18`
  - bank table row count `56`
  - industrial visible filing hash `2116208241`
  - industrial table count `3`
  - industrial table row count `3`
- Full-year player-flow output:
  - seed `20260622`
  - completed `225/225` trading days
  - bought `10100` shares of `BORI` at `495.0`
  - final BORI price `125.0`
  - held return `-74.75%`
  - final cash `1493000.75`
  - final market value `1262500.0`
  - final equity `2755500.75`
  - thesis evidence count `5`
  - annual filing capture count `3`
  - best stock `FBKP` return `728.15%`
  - worst stock `SARI` return `-96.77%`
  - average stock return `-30.44%`
  - gorengan started/dump peak/success peak `27/8/0`
  - attention tier counts `{"clue_due":24,"company_watch":80,"digestion":117,"headline_reserved":1,"quiet":3}`
- Performance note:
  - full-year catalog scenario elapsed `613626.46ms`
  - most later-day state-apply runs were roughly `0.6-1.3s`; one observed early spike reached about `6.6s`
  - keep this as an explicit full scenario, not a quick-smoke default
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/AnnualFilingSectorRealismRegressionTest.tscn` -> `ANNUAL_FILING_SECTOR_REALISM_REGRESSION_OK {"hash":"398621424","bank_table_count":18,"bank_table_row_count":56,"industrial_table_count":3,"industrial_table_row_count":3,...}`
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/FullYearPlayerScenarioTest.tscn` -> `FULL_YEAR_PLAYER_SCENARIO_OK {"days_completed":225,"annual_filing":{"opened_bank_filing":true,"profile_id":"bank","capture_types":["statement_row","note_table_row","note_paragraph"]},...}`
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/AnnualFilingRegressionGuardTest.tscn` -> `ANNUAL_FILING_REGRESSION_GUARD_OK {"hash":"1878982941","visible_filing_hash":"169939267"}`
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=95485619.77 days=3 ...`
  - `/Users/user/.local/bin/godot --headless -e --quit`
  - `git diff --check`

### 2026-06-24 - Post-completion reader cleanup

- Fixed the player-facing consolidated statement reader after visual review showed cutoff and noisy metadata in the A4 view.
- Scope:
  - widened the A4 report content and amount column
  - reduced reader overlay margins so the statement page is less likely to clip inside the Stock app window
  - widened the table-of-contents panel so section buttons do not truncate as aggressively
  - removed Bahasa/Indonesian localized titles from the visible document surface and TOC
  - removed `related_note` reference labels and cross-reference/classification blocks from visible filing output
  - changed visible annual amounts from raw `million_idr` strings to number-only values with thousands separators
  - added regression guards against `Catatan`, `Laporan`, `million_idr`, and related-note/classification wording leaking into visible output
- Follow-up visual cleanup:
  - constrained A4 page size by available reader height, not only by width, so the bottom of the page stays inside the overlay
  - reserved a right-side scrollbar gutter for statement and note-table value rows
  - changed visible currency rows to statement-style amounts in millions, with the header showing `Amounts in millions of IDR`
  - removed raw internal unit display from the document header
  - added a UI smoke assertion that fails if the A4 page height exceeds the outer reader viewport
- No separate revision plan was created; this is a direct cleanup for the completed sector realism work.
- Updated deterministic baselines after the intentional output change:
  - `AnnualFilingSectorRealismRegressionTest` hash `296239800`
  - `AnnualFilingBankReaderUiSmokeTest` hash `1766108525`
  - `AnnualFilingVisibleGenerationTest` hash `1531180798`
  - `AnnualFilingRegressionGuardTest` hash `1293595081`
  - `AnnualFilingBankAnatomyTableTest` hash `1935339767`
  - `AnnualFilingLazyContractTest` hash `173453687`
  - `AnnualFilingProseLibraryTest` hash `1398147755`
  - `AnnualFilingProfileContractTest` hash `473382748`
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/AnnualFilingSectorRealismRegressionTest.tscn` -> `ANNUAL_FILING_SECTOR_REALISM_REGRESSION_OK {"hash":"296239800",...}`
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/AnnualFilingBankReaderUiSmokeTest.tscn` -> `ANNUAL_FILING_BANK_READER_UI_SMOKE_OK {"hash":"1766108525",...}`
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/AnnualFilingVisibleGenerationTest.tscn` -> `ANNUAL_FILING_VISIBLE_GENERATION_OK {"hash":"1531180798",...}`
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/AnnualFilingRegressionGuardTest.tscn` -> `ANNUAL_FILING_REGRESSION_GUARD_OK {"hash":"1293595081",...}`
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/AnnualFilingBankAnatomyTableTest.tscn` -> `ANNUAL_FILING_BANK_ANATOMY_TABLE_OK {"hash":"1935339767",...}`
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/AnnualFilingLazyContractTest.tscn` -> `ANNUAL_FILING_LAZY_CONTRACT_OK {"hash":"173453687",...}`
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/AnnualFilingProseLibraryTest.tscn` -> `ANNUAL_FILING_PROSE_LIBRARY_OK {"hash":"1398147755",...}`
  - `/Users/user/.local/bin/godot --headless --path . scenes/tests/AnnualFilingProfileContractTest.tscn` -> `ANNUAL_FILING_PROFILE_CONTRACT_OK {"hash":"473382748",...}`

## Task 5 - Rebalance Visible Filing Generation Around Tables And Note References

Problem: Real filings make players infer from structured tables and note references. The current document still depends too much on generated paragraphs.

1. Change visible filing generation so section output is assembled in this priority:
   - title/header
   - statement/note table
   - comparative row movement
   - note references
   - short formal lead-in
   - limited prose paragraphs
2. Give each profile a target table/prose ratio.
3. For bank profile, ensure key clues can surface through:
   - Stage 2/Stage 3 loan movement
   - allowance coverage
   - loan/deposit mix
   - sector concentration
   - related-party balances
   - CAR/liquidity/risk language
4. For industrial/trading profile, ensure key clues can surface through:
   - segment revenue/profit
   - inventory and receivables
   - PPE/capex
   - debt and finance cost
   - commitments and contingencies
   - commodity/FX/credit risk language
5. Keep Research Tray capture payloads neutral and source-backed.
6. Add tests:
   - profile target table/prose ratio
   - required clue surfaces available as capture payloads
   - no hidden truth labels in table/prose/capture text
7. Verify:
   - annual report fidelity capture test
   - annual filing regression guard
   - quick smoke
   - `git diff --check`

Implementation status: complete. Visible annual filings now use profile-balance targets and deterministic `display_blocks` so note tables render before references and limited prose. Default filings now emit fewer visible paragraphs while preserving tables, references, capture payloads, lazy generation, and cache behavior. Bank filings keep 18 compact tables and 56 source-backed table rows while meeting the bank table/prose balance target.

## Task 6 - Preserve Capture, Thesis, Cache, And UI Behavior Under Sector Profiles

Problem: Sector-specific filings should improve document quality without breaking the existing player loop.

1. Confirm `View Consolidated Financial Statement` still lazy-builds on click only.
2. Confirm cache keys include profile version and source-state hash.
3. Confirm existing A4 reader shell still handles longer bank tables without layout overflow.
4. Confirm capture payloads survive:
   - Research Tray capture
   - thesis attach
   - direct evidence add
   - save/load
5. Confirm existing non-bank filings still render with valid sections.
6. Add/extend smoke assertions:
   - bank profile reader opens and stays within viewport
   - table-heavy sections remain scrollable and bounded
   - section navigation works for bank-only notes
7. Verify:
   - targeted UI/profile smoke
   - `SmokeTest.tscn -- --smoke-quick --smoke-local-io`
   - `git diff --check`

Implementation status: complete. The bank profile now opens through the real Stock app reader with correct profile context, lazy in-memory cache behavior, A4/scroll/TOC guards, capture payload preservation, thesis evidence persistence, and non-bank fallback coverage. Task 7 should broaden this into final realism and full player-flow regression coverage.

## Task 7 - Add Realism, Determinism, And Full Player Flow Regression Tests

Problem: Filing quality can regress quietly unless there are tests for both structure and player workflow.

1. Add a fixed-seed bank filing realism test:
   - required bank section ids
   - required bank tables
   - minimum table count
   - bounded paragraph count
   - duplicate text guard
   - hidden-token guard
2. Add a fixed-seed industrial/trading filing realism test:
   - required industrial note ids
   - segment/inventory/receivable/commitment/risk surfaces
   - no bank-only sections
3. Add deterministic profile hash snapshots.
4. Run or update a full-year player scenario where the player:
   - opens a bank filing
   - captures at least one table row and one note/risk paragraph
   - creates/updates a thesis from the filing
   - buys or holds a stock
   - advances through a full year
5. Log important output to `docs/development/test_log/`.
6. Verify:
   - targeted realism tests
   - annual filing regression guard
   - full-year player scenario if runtime/UI behavior changed enough to justify it
   - quick smoke
   - `git diff --check`

Implementation status: complete. Task 7 added the final sector realism regression guard and updated the full-year player scenario to exercise a catalog-backed bank filing, thesis capture, buy/hold, and 225-day advance. Important full-year output is logged at `docs/development/test_log/2026-06-24_annual_filing_sector_realism_full_year.md`. The full-year catalog scenario is intentionally not part of quick smoke because it took about `613626.46ms`.

## Acceptance Criteria

- Bank companies no longer render as generic industrial filings.
- Industrial/trading companies keep appropriate non-bank filing sections.
- Visible annual filings are table-first and section-specific.
- Repeated filler sentences do not appear in the same filing.
- Generic explanatory prose is reduced and bounded.
- Story clues are discoverable through tables and note context without direct truth labels.
- `View Consolidated Financial Statement` still lazy-generates and caches the document.
- Research Tray and Thesis evidence capture still work from statement rows, note table rows, and note paragraphs.
- Quick smoke and targeted filing tests pass.

## Known Traps

- A dry filing is acceptable; incoherent filler is not.
- A table with plausible row labels is better than a paragraph explaining what the table means.
- Do not overfit to one reference PDF. Use AKR and Bank Sinarmas as structural examples, not as text sources.
- Bank accounting terms are different enough that generic company rows will leak wrong concepts if not explicitly blocked.
- Dedupe guards can hide repeated symptoms but not fix bad generation. Use them as safety rails, not the main quality strategy.
- Adding profile id to cache keys will change deterministic hashes; update baselines intentionally.
- Long bank tables can stress the A4 reader. Keep rendering bounded and scrollable.
- Visible filing output should stay English-only and avoid raw internal units or metadata such as `million_idr`, `related_note`, and classification references.
