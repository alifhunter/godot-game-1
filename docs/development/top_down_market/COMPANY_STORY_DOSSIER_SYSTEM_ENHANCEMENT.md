# Company Story Dossier System Enhancement - Plan & Progress Log

This plan creates a structured source of truth for company stories so news, Twooter, Network, thesis evidence, financial statements, and price behavior all describe the same underlying facts.
**Status: in progress - Tasks 1-6 complete; Revision R1 complete.** Designed to run in a fresh session; everything needed to execute cold is in this file.

**Review verdict recap:** The game cannot hand-author every story across every surface. A dossier system can store the real state of a company story and generate different public, private, and financial clues from it. This keeps content coherent and lets players discover whether a story is real, delayed, failed, overhyped, or still uncertain.

## Where everything lives

| What | Where |
|---|---|
| Planned story owner | `systems/CompanyStoryDossierSystem.gd` |
| Current event owners | `systems/CompanyEventSystem.gd`, `systems/CompanyRoadmapSystem.gd`, `systems/CorporateActionApplications.gd` |
| Current content surfaces | `systems/NewsFeedSystem.gd`, `systems/TwooterFeedSystem.gd`, `systems/ContactNetworkSystem.gd` |
| Thesis consumers | `systems/ThesisManager.gd`, `systems/ThesisReportSystem.gd`, `data/thesis/thesis_content.json` |
| Runtime state | `autoloads/RunState.gd` company/story state |
| Tests/probes | `scripts/tests/CompanyStoryDossierFingerprintTest.gd`, `scripts/tests/CompanyStoryDossierSaveDefaultsTest.gd`, `scripts/tests/CompanyStoryDossierThesisEvidenceTest.gd`, `scripts/tests/CompanyStoryDossierConsistencyTest.gd`, `scripts/tests/CompanyStoryDossierPreviewTest.gd`, `scripts/tests/CompanyStoryDossierDisclosurePlacementTest.gd`, `scripts/tests/CompanyStoryDossierDisclosurePacketTest.gd`, `scripts/tests/CompanyStoryDossierDisclosurePersistenceTest.gd`, `scripts/tests/CompanyStoryDossierFinancialStatementFixtureTest.gd`, `scripts/tests/AnnualStatementStorySourceEnrichmentTest.gd`, `scripts/tests/AnnualStatementFullTraceabilityContractTest.gd`, `scripts/tests/FinancialStatementLayerThesisCaptureTest.gd` |
| Key functions | Locate by company event generation, news feed building, Twooter feed building, thesis evidence capture |

## Goals

- Store company story truth, timeline, public clues, private clues, financial effects, and resolution state in one structured place.
- Allow content surfaces to reveal different slices of the same story.
- Make story state usable by thesis and price systems.

## Non-goals

- Do not generate full financial statements in this plan.
- Do not hand-write every article or post.
- Do not guarantee that every story is true or profitable.

## Working rules

- Dossier facts should be machine-readable first and display text second.
- Text generation must be deterministic.
- Save state should store stable identifiers and current state, not massive derived text blobs.
- Dossier outputs should be traceable for tests.

## Status

### V1 tasks

| # | Task | Est. cost | Status |
|---|---|---|---|
| 1 | Define dossier schema and truth states | ~15-25% | Complete |
| 2 | Add deterministic dossier selection/generation | ~20-35% | Complete |
| 3 | Add story state persistence and normalizers | ~15-25% | Complete |
| 4 | Bridge dossier facts to thesis evidence | ~15-25% | Complete |
| 5 | Add consistency and fingerprint tests | ~10-20% | Complete |
| 6 | Wire minimal read-only content previews | ~15-30% | Complete |

### Revision R1 tasks

| # | Task | Est. cost | Status |
|---|---|---|---|
| R1.1 | Define disclosure placement schema and filing section map | ~10-20% | Complete |
| R1.2 | Add clue subtlety and scattering rules | ~15-30% | Complete |
| R1.3 | Generate multi-section filing disclosure packets | ~20-35% | Complete |
| R1.4 | Persist/normalize disclosure placement state | ~10-20% | Complete |
| R1.5 | Bridge disclosure packets to Financial Statement R3 | ~15-30% | Complete |
| R1.6 | Add disclosure placement consistency and fingerprint tests | ~10-20% | Complete |

Recommended batching: V1 and Revision R1 are complete. Continue with Financial Statement R3.1-R3.5; the story dossier now has the packet placement, section lookup, annual-note bridge, thesis capture bridge, and final cross-feature fixture needed by the document-reader work.

## Progress log

### 2026-06-14 - Plan created

- Created this enhancement plan from the top-down market brainstorming session.
- Current inventory:
  - Existing events, roadmap, news, Twooter, Network, and thesis systems already contain pieces of story delivery.
  - There is no single story dossier source of truth yet.
  - The dossier should prevent content surfaces from drifting.
- No code or data changes were made by this planning step.

### 2026-06-15 - Task 1 complete

- Defined the dossier system as a source-of-truth layer owned by planned `systems/CompanyStoryDossierSystem.gd`.
- Chosen model:
  - a compact saved runtime dossier instance per selected story
  - deterministic display/content generated from ids, facts, and reveal rules
  - living company arc state remains the lifecycle/reservation index, not the detailed story source
- Defined core dossier schema fields:
  - `story_id`, `company_id`, `archetype_id`, `truth_state`, `timeline`, `cause_facts`, `financial_effects`, `price_effects`, `public_clues`, `private_clues`, `statement_clues`, `thesis_hooks`, `resolution_conditions`, and `traceability`
- Defined hidden truth states:
  - `real`, `delayed`, `failed`, `overhyped`, `fraud_risk`, and `uncertain`
- Documented how dossier facts map to News, Twooter, Network, filings/statements, thesis, price, and living arcs.
- Runtime behavior note:
  - Task 1 is design-only. No gameplay behavior, save payloads, content generation, or price behavior changed.
- Verification:
  - `git diff --check`

### 2026-06-15 - Task 2 complete

- Added `systems/CompanyStoryDossierSystem.gd` as a pure deterministic dossier generator.
- Current generator behavior:
  - ranks story archetypes from company `story_hooks`, sector, moat/narrative tags, commodity exposure, macro/sector state, roadmap profile, and event sensitivity
  - creates one compact dossier per selected company in the fixed-seed test path
  - assigns hidden truth states from weighted archetype rules and company quality/risk/attention traits
  - emits cause facts, timeline rows, financial effects, bounded price effects, public clues, private clues, statement clues, thesis hooks, resolution conditions, and traceability ids
- Runtime behavior note:
  - No save data, live news, Twooter, Network, thesis, or price-engine wiring was changed.
  - The system is available for explicit callers/tests only until Task 3+ bridges it into runtime state.
- Added `CompanyStoryDossierFingerprintTest` with seed `20260615`, 30 catalog-backed companies, and macro year `2020`.
- Locked deterministic baseline:
  - hash `1867741019`
  - first story `story|pulp_nusantara|commodity_tailwind|2532662389`
  - last story `story|bank_syariah_harmoni|commodity_headwind|2473540029`
- Baseline output summary:
  - archetypes: `contract_win=8`, `commodity_headwind=8`, `capex_expansion=3`, `governance_risk=3`, `margin_recovery=3`, `commodity_tailwind=2`, `balance_sheet_stress=1`, `fraud_signal=1`, `turnaround=1`
  - truth states: `real=10`, `failed=6`, `overhyped=6`, `delayed=4`, `fraud_risk=2`, `uncertain=2`
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyStoryDossierFingerprintTest.tscn` -> `COMPANY_STORY_DOSSIER_FINGERPRINT_OK {"hash":"1867741019","dossier_count":30,...}`

### 2026-06-15 - Task 3 complete

- Added saved company story dossier state to `autoloads/RunState.gd`.
- Fresh runs now seed a deterministic dossier registry from `CompanyStoryDossierSystem`.
- Added global saved state:
  - `company_story_dossier_state.schema_version`
  - `generated`
  - `run_seed`
  - `generated_day_index`
  - `active_story_ids`
  - `resolved_story_ids`
  - `dossier_index`
  - `company_story_ids`
  - `recent_resolved_stories`
  - `story_counts_by_archetype`
  - `story_counts_by_truth`
- Added per-company compact state under each runtime company:
  - `company_story_dossier_state.active_story_ids`
  - `resolved_story_ids`
  - `current_story_id`
  - `current_stage_by_story_id`
  - `public_status_by_story_id`
  - `recent_story_ids`
- Added RunState access/update helpers:
  - `get_company_story_dossier_state()`
  - `set_company_story_dossier_state(...)`
  - `get_company_story_dossier(...)`
  - `get_company_story_dossier_ids_for_company(...)`
  - `get_company_story_dossiers_for_company(...)`
  - `get_company_story_dossier_company_state(...)`
  - `update_company_story_dossier_progress(...)`
- Save compatibility behavior:
  - old saves with no dossier state normalize to an empty registry and default per-company refs
  - fresh new runs get generated dossier state
  - malformed/partial state normalizes ids, stages, public statuses, truth states, bounded price fields, and compact row arrays
- Runtime behavior note:
  - This adds saved state and explicit accessors only.
  - News, Twooter, Network, thesis, and price behavior are not consuming dossier state yet.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyStoryDossierSaveDefaultsTest.tscn` -> `COMPANY_STORY_DOSSIER_SAVE_DEFAULTS_OK {"baseline_count":30,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyStoryDossierFingerprintTest.tscn` -> `COMPANY_STORY_DOSSIER_FINGERPRINT_OK {"hash":"1867741019","dossier_count":30,...}`

### 2026-06-15 - Task 4 complete

- Bridged saved dossier facts into thesis evidence options without adding a new thesis category.
- Added five dossier evidence shapes:
  - `macro_cause` under `sector_macro`
  - `sector_cause` under `sector_macro`
  - `company_story` under `corporate_events`
  - `financial_clue` under `financials`
  - `private_clue` under `network_intel`
- Added `GameManager.get_company_story_dossier_evidence_options(company_id)` for targeted tests/future UI.
- Added `company_story_dossier` as a thesis evidence source type with `Story Dossier` source label.
- Preserved dossier provenance through Research Tray capture, thesis attach, direct thesis add, and `RunState` normalization:
  - `story_id`
  - `fact_id`
  - `fact_ids`
  - `clue_id`
  - `effect_id`
  - `surface_id`
  - `dossier_evidence_type`
  - public `dossier_stage_id` and `dossier_public_status`
- Hidden `truth_state` remains out of thesis evidence rows.
- Runtime behavior note:
  - Existing thesis categories remain stable.
  - The thesis option fingerprint changed because new dossier options are now visible; the report fingerprint stayed unchanged.
  - News, Twooter, Network live content, price behavior, and financial statements still do not consume dossier state yet.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyStoryDossierThesisEvidenceTest.tscn` -> `COMPANY_STORY_DOSSIER_THESIS_EVIDENCE_OK {"company_id":"nikel_makmur","row_count":7,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/ThesisResearchTrayTest.tscn` -> `THESIS_RESEARCH_TRAY_OK`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/ThesisFingerprintTest.tscn` -> `THESIS_FINGERPRINT_OK {"hash":"674019173","option_hash":"674078562","report_hash":"1836382259",...}`

### 2026-06-15 - Task 5 complete

- Added `CompanyStoryDossierConsistencyTest` as the cross-reference and consistency gate.
- The test runs the same fixed-seed catalog-backed setup twice and asserts stable output.
- It validates:
  - every saved story id has a dossier index row
  - global active/resolved/company story refs do not point at missing dossier ids
  - cause fact ids, clue ids, financial effect ids, timeline ids, resolution ids, and price ids are scoped to the owning `story_id`
  - public, private, and statement clues reference existing facts/metrics
  - traceability arrays match the generated facts, clues, surfaces, statement effects, and price effect ids
  - thesis evidence rows reference existing story/fact/clue/effect ids
  - thesis evidence rows do not expose hidden `truth_state`
- Locked consistency baseline:
  - hash `2006435509`
  - `30` dossiers
  - surface counts: `network=30`, `news=30`, `statement_note=30`, `twooter=30`
  - thesis row counts: `company_story=30`, `financial_clue=90`, `macro_cause=21`, `private_clue=30`, `sector_cause=30`
- Runtime behavior note:
  - Task 5 is test-only. No gameplay, save, content, thesis, or price behavior changed.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyStoryDossierConsistencyTest.tscn` -> `COMPANY_STORY_DOSSIER_CONSISTENCY_OK {"hash":"2006435509","issue_count":0,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyStoryDossierFingerprintTest.tscn` -> `COMPANY_STORY_DOSSIER_FINGERPRINT_OK {"hash":"1867741019","dossier_count":30,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyStoryDossierThesisEvidenceTest.tscn` -> `COMPANY_STORY_DOSSIER_THESIS_EVIDENCE_OK {"company_id":"nikel_makmur","row_count":7,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyStoryDossierSaveDefaultsTest.tscn` -> `COMPANY_STORY_DOSSIER_SAVE_DEFAULTS_OK {"baseline_count":30,...}`

### 2026-06-15 - Task 6 complete

- Added explicit read-only preview builders to `CompanyStoryDossierSystem`:
  - `build_preview(dossier, surface_id)`
  - `build_preview_rows(dossiers, surface_id, options)`
- Current preview surfaces:
  - `summary`
  - `news`
  - `twooter`
  - `network`
  - `statement_note`
- Preview rows are generated from existing dossier facts, clues, financial effect ids, metric ids, public stage/status, and traceability.
- Hidden `truth_state`, tone, reliability, source quality, and disclosure quality are not exposed in preview rows.
- No live News, Twooter, Network, statement, price, or thesis behavior was replaced.
- Added `CompanyStoryDossierPreviewTest`.
- Locked preview baseline:
  - hash `1727264953`
  - `30` news previews
  - `5` limited summary previews
  - first preview `preview|story|alat_berat_mandiri|commodity_headwind|4206524601|news`
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyStoryDossierPreviewTest.tscn` -> `COMPANY_STORY_DOSSIER_PREVIEW_OK {"hash":"1727264953","issue_count":0,...}`

### 2026-06-19 - Revision R1 planning added

- Added Revision R1 as the disclosure placement and clue distribution plan.
- R1 goal: stop treating filing evidence as one obvious story note and instead define how a story is scattered across realistic filing sections.
- This revision owns:
  - filing section placement
  - clue subtlety
  - cross-note scattering
  - public/private/filing clue differences
  - deterministic disclosure packets for Financial Statement R3
- Financial Statement R3 should consume this output rather than inventing placement logic inside the report renderer.
- Recommended start order:
  - start this revision first
  - implement R1.1-R1.4 to define and generate disclosure packets
  - then wire Financial Statement R3.3/R3.5 against those packets
- Planning-only update; no code, data, runtime behavior, or tests changed.
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyStoryDossierConsistencyTest.tscn` -> `COMPANY_STORY_DOSSIER_CONSISTENCY_OK {"hash":"2006435509","issue_count":0,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyStoryDossierFingerprintTest.tscn` -> `COMPANY_STORY_DOSSIER_FINGERPRINT_OK {"hash":"1867741019","dossier_count":30,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyStoryDossierThesisEvidenceTest.tscn` -> `COMPANY_STORY_DOSSIER_THESIS_EVIDENCE_OK {"company_id":"nikel_makmur","row_count":7,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyStoryDossierSaveDefaultsTest.tscn` -> `COMPANY_STORY_DOSSIER_SAVE_DEFAULTS_OK {"baseline_count":30,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/ThesisFingerprintTest.tscn` -> `THESIS_FINGERPRINT_OK {"hash":"674019173","option_hash":"674078562","report_hash":"1836382259",...}`

### 2026-06-19 - Revision R1.1 complete

- Added deterministic filing disclosure placement definitions to `CompanyStoryDossierSystem`.
- New generated dossier field:
  - `disclosure_placements`
- Added canonical placement sections:
  - `revenue`
  - `segment_information`
  - `trade_receivables`
  - `inventories`
  - `property_plant_and_equipment`
  - `debt_and_borrowings`
  - `related_party_transactions`
  - `commitments_contingencies`
  - `subsequent_events`
  - `cash_flow_information`
- Placement rows now include stable ids and public filing metadata:
  - `placement_id`
  - `story_id`
  - `surface_id`
  - `section_id`
  - `section_label`
  - `section_group`
  - `annual_statement_note_type`
  - `placement_role`
  - `note_type`
  - `visibility`
  - `fact_ids`
  - `effect_ids`
  - `clue_ids`
  - `metric_ids`
  - `statement_sections`
  - `source_note_types`
  - `source_metric_ids`
  - `text_key`
- Added deterministic note-type, archetype, and metric-to-filing-section mappings.
- Added `disclosure_section_definitions()` as a read API for tests and future consumers.
- Added traceability arrays:
  - `traceability.disclosure_placement_ids`
  - `traceability.disclosure_section_ids`
- Added save normalization for placement rows in `RunState`, including stripping hidden fields such as `truth_state`, `disclosure_quality`, `reliability`, `confidence`, and `source_quality`.
- Added `CompanyStoryDossierDisclosurePlacementTest`.
- Locked disclosure placement baseline:
  - hash `1533142911`
  - `30` dossiers
  - `144` placement rows
  - all 10 target filing sections represented
- Runtime behavior note:
  - This adds generated dossier metadata and save normalization only.
  - No live Financial Statement R3 rendering, News, Twooter, Network, price, or thesis behavior was changed by R1.1.
  - At the time, legacy derivation, section lookup APIs, Financial Statement R3 bridge work, final cross-feature fixtures, and expanded packet coverage were still future work. R1.4 has since completed the legacy derivation and section lookup portions.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyStoryDossierDisclosurePlacementTest.tscn` -> `COMPANY_STORY_DOSSIER_DISCLOSURE_PLACEMENT_OK {"hash":"1533142911","placement_count":144,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyStoryDossierConsistencyTest.tscn` -> `COMPANY_STORY_DOSSIER_CONSISTENCY_OK {"hash":"2006435509","issue_count":0,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyStoryDossierFingerprintTest.tscn` -> `COMPANY_STORY_DOSSIER_FINGERPRINT_OK {"hash":"1867741019","dossier_count":30,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyStoryDossierSaveDefaultsTest.tscn` -> `COMPANY_STORY_DOSSIER_SAVE_DEFAULTS_OK {"baseline_count":30,...}`

### 2026-06-19 - Revision R1.2 complete

- Added deterministic clue subtlety and scattering rules to `CompanyStoryDossierSystem`.
- Disclosure placements now carry public filing-reading metadata:
  - `subtlety`
  - `reader_effort`
  - `evidence_density`
  - `fragment_role`
  - `scattering_strategy`
  - `scattering_index`
  - `scattering_total`
- Added valid subtlety bands:
  - `direct`
  - `implied`
  - `buried`
  - `conflicting`
  - `missing`
- Added deterministic scattering strategies:
  - `confirmation_trail`
  - `evidence_trail`
  - `timing_gap_trail`
  - `breakdown_trail`
  - `thin_support_trail`
  - `control_risk_trail`
  - `mixed_evidence_trail`
- Placement generation now limits each story to a deterministic subset of plausible filing sections instead of emitting every candidate section.
- Scattering count is influenced by story stage, public status, statement clue reliability, and hidden truth state, but the saved placement rows do not expose hidden truth labels.
- Current behavior:
  - real stories produce direct or implied filing evidence
  - delayed stories can produce implied/buried/missing evidence
  - failed, overhyped, and fraud-risk stories can produce conflicting or missing evidence
- Updated `RunState` placement normalization to preserve subtlety/scattering fields and normalize invalid subtlety to `implied`.
- Expanded `CompanyStoryDossierDisclosurePlacementTest` to validate:
  - valid subtlety bands
  - scattering index/total consistency
  - reader-effort/evidence-density/fragment-role metadata
  - real story direct/implied coverage
  - failed/overhyped/fraud-risk conflicting or missing coverage
  - save/load invalid subtlety repair
- Updated disclosure placement baseline:
  - hash `1192489532`
  - `30` dossiers
  - `105` placement rows
  - subtlety counts: `direct=8`, `implied=24`, `buried=45`, `conflicting=12`, `missing=16`
  - all 10 target filing sections still represented
- Runtime behavior note:
  - This changes generated dossier placement metadata only.
  - No live Financial Statement R3 rendering, News, Twooter, Network, price, or thesis behavior was changed by R1.2.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyStoryDossierDisclosurePlacementTest.tscn` -> `COMPANY_STORY_DOSSIER_DISCLOSURE_PLACEMENT_OK {"hash":"1192489532","placement_count":105,...}`

### 2026-06-19 - Revision R1.3 complete

- Added deterministic multi-section filing disclosure packets to `CompanyStoryDossierSystem`.
- New generated dossier field:
  - `disclosure_packets`
- Each packet is derived from one disclosure placement and keeps a stable relationship to that placement.
- Packet rows now include:
  - `packet_id`
  - `story_id`
  - `placement_id`
  - `surface_id`
  - `section_id`
  - `section_label`
  - `section_group`
  - `annual_statement_note_type`
  - `note_type`
  - `subtlety`
  - `reader_effort`
  - `evidence_density`
  - `fragment_role`
  - `scattering_strategy`
  - `packet_role`
  - `render_priority`
  - `fact_ids`
  - `effect_ids`
  - `clue_ids`
  - `metric_ids`
  - `statement_sections`
  - `source_note_types`
  - `source_metric_ids`
  - `phrase_ids`
  - `render_tokens`
  - `cross_reference_section_ids`
  - `text_key`
- Added deterministic packet role mapping:
  - `primary_evidence`
  - `anchor_evidence`
  - `supporting_evidence`
  - `cross_reference_evidence`
  - `challenge_evidence`
  - `absence_evidence`
- Added deterministic phrase ids and render tokens so Financial Statement R3 can choose wording without storing long generated prose in saved state.
- Added cross-reference section ids so report rendering can point a reader from one note to related notes.
- Added traceability array:
  - `traceability.disclosure_packet_ids`
- Added packet save normalization in `RunState`, including hidden-field stripping and invalid-subtlety repair.
- Added `CompanyStoryDossierDisclosurePacketTest`.
- Locked disclosure packet baseline:
  - hash `2005222199`
  - `30` dossiers
  - `105` packet rows
  - `30` multi-packet stories
  - `420` phrase ids
  - `737` render tokens
- Runtime behavior note:
  - This adds generated dossier packet metadata and save normalization only.
  - No live Financial Statement R3 rendering, News, Twooter, Network, price, or thesis behavior was changed by R1.3.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyStoryDossierDisclosurePacketTest.tscn` -> `COMPANY_STORY_DOSSIER_DISCLOSURE_PACKET_OK {"hash":"2005222199","packet_count":105,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyStoryDossierDisclosurePlacementTest.tscn` -> `COMPANY_STORY_DOSSIER_DISCLOSURE_PLACEMENT_OK {"hash":"1192489532","placement_count":105,...}`

### 2026-06-19 - Revision R1.4 complete

- Added deterministic disclosure artifact repair in `CompanyStoryDossierSystem`:
  - `disclosure_artifacts_for_dossier(...)`
  - `disclosure_rows_for_dossiers(...)`
  - `disclosure_placements_for_dossiers(...)`
  - `disclosure_packets_for_dossiers(...)`
- Added RunState lookup APIs for filing placement/packet consumers:
  - `get_company_story_disclosure_placements(story_id, section_id = "")`
  - `get_company_story_disclosure_packets(story_id, section_id = "")`
  - `get_company_story_disclosure_placements_for_company(company_id, section_id = "")`
  - `get_company_story_disclosure_packets_for_company(company_id, section_id = "")`
- Updated dossier normalization so old saves without placement/packet rows derive them from stable story fields on load.
- Updated traceability repair so `disclosure_placement_ids`, `disclosure_section_ids`, and `disclosure_packet_ids` match the normalized rows after legacy/malformed saves load.
- Added `CompanyStoryDossierDisclosurePersistenceTest`.
- Locked disclosure persistence baseline:
  - hash `2080268323`
  - `30` dossiers
  - `105` placement rows
  - `105` packet rows
- Runtime behavior note:
  - This changes save compatibility and read APIs only.
  - No live Financial Statement R3 rendering, News, Twooter, Network, price, or thesis display behavior was changed by R1.4.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyStoryDossierDisclosurePersistenceTest.tscn` -> `COMPANY_STORY_DOSSIER_DISCLOSURE_PERSISTENCE_OK {"hash":"2080268323","placement_count":105,"packet_count":105,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyStoryDossierDisclosurePacketTest.tscn` -> `COMPANY_STORY_DOSSIER_DISCLOSURE_PACKET_OK {"hash":"2005222199","packet_count":105,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyStoryDossierDisclosurePlacementTest.tscn` -> `COMPANY_STORY_DOSSIER_DISCLOSURE_PLACEMENT_OK {"hash":"1192489532","placement_count":105,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyStoryDossierSaveDefaultsTest.tscn` -> `COMPANY_STORY_DOSSIER_SAVE_DEFAULTS_OK {"baseline_count":30,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyStoryDossierConsistencyTest.tscn` -> `COMPANY_STORY_DOSSIER_CONSISTENCY_OK {"hash":"2006435509","issue_count":0,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyStoryDossierFingerprintTest.tscn` -> `COMPANY_STORY_DOSSIER_FINGERPRINT_OK {"hash":"1867741019","dossier_count":30,...}`

### 2026-06-21 - Revision R1.5 complete

- Bridged disclosure packet provenance into annual statement post-start story enrichment.
- Annual note rows that consume story dossier sources now preserve:
  - `source_disclosure_packet_ids`
  - `source_disclosure_placement_ids`
  - `source_disclosure_section_ids`
  - `disclosure_packet_refs`
- Statement-level annual traceability now rolls up:
  - `post_start_source_disclosure_packet_ids`
  - `post_start_source_disclosure_placement_ids`
  - `post_start_source_disclosure_section_ids`
- Story source refs now carry packet ids so future document-reader rows can trace a note back through story, fact, effect, clue, placement, and packet ids.
- Financial statement note capture, Research Tray normalization, thesis evidence normalization, direct thesis evidence add, and save/load normalization now preserve packet provenance.
- Visible packet refs intentionally omit hidden source fields such as `truth_state`, `disclosure_quality`, `reliability`, `confidence`, and `source_quality`.
- Updated the fixed-seed full annual traceability hash to `1974201801` because the traceability contract now includes disclosure packet provenance.
- Runtime behavior note:
  - This task adds source-data bridge and capture provenance only.
  - It does not yet change annual report prose, page layout, or the future Financial Statement R3 document-reader flow.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualStatementStorySourceEnrichmentTest.tscn` -> `ANNUAL_STATEMENT_STORY_SOURCE_ENRICHMENT_OK {"company_id":"kete","story_count":3,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualStatementFullTraceabilityContractTest.tscn` -> `ANNUAL_STATEMENT_FULL_TRACEABILITY_CONTRACT_OK {"company_id":"sire","hash":"1974201801","note_count":14,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/FinancialStatementLayerThesisCaptureTest.tscn` -> `FINANCIAL_STATEMENT_LAYER_THESIS_CAPTURE_OK`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualStatementEnrichmentPassTest.tscn` -> `ANNUAL_STATEMENT_ENRICHMENT_PASS_OK {"company_id":"kete","note_count":14,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/AnnualStatementActionEventRoadmapEnrichmentTest.tscn` -> `ANNUAL_STATEMENT_ACTION_EVENT_ROADMAP_ENRICHMENT_OK {"company_id":"sire","note_count":14,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyStoryDossierDisclosurePersistenceTest.tscn` -> `COMPANY_STORY_DOSSIER_DISCLOSURE_PERSISTENCE_OK {"hash":"2080268323","placement_count":105,"packet_count":105,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyStoryDossierDisclosurePacketTest.tscn` -> `COMPANY_STORY_DOSSIER_DISCLOSURE_PACKET_OK {"hash":"2005222199","packet_count":105,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyStoryDossierDisclosurePlacementTest.tscn` -> `COMPANY_STORY_DOSSIER_DISCLOSURE_PLACEMENT_OK {"hash":"1192489532","placement_count":105,...}`

### 2026-06-21 - Revision R1.6 complete

- Added `CompanyStoryDossierFinancialStatementFixtureTest` as the final generated-dossier-to-financial-statement fixture for Financial Statement R3.
- The fixture runs the catalog-backed fixed seed `20260615` with `30` companies and validates generated disclosure artifacts across all `30` story dossiers.
- Locked fixture baseline:
  - hash `623183840`
  - `105` disclosure placements
  - `105` disclosure packets
  - all `10` filing sections represented
  - all `5` subtlety bands represented
  - annual bridge fixture company `alat_berat_mandiri`
  - `10` annual note packet refs
- The fixture validates:
  - every packet has valid story, placement, section, annual note type, subtlety, packet role, fact, effect, clue, and cross-section refs
  - every packet resolves through story/section and company/section lookup APIs
  - annual notes preserve packet ids, placement ids, section ids, packet refs, story ids, fact ids, effect ids, and clue ids
  - thesis evidence normalization preserves the packet bridge fields
  - hidden truth/source-quality fields do not leak into placements, packets, annual packet refs, or normalized evidence packet refs
  - repeated fixed-seed runs produce the same fixture payload and hash
- Runtime behavior note:
  - This task is a focused regression fixture only.
  - No live News, Twooter, Network, price, annual report prose, or UI behavior changed.
- Verification:
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyStoryDossierFinancialStatementFixtureTest.tscn` -> `COMPANY_STORY_DOSSIER_FINANCIAL_STATEMENT_FIXTURE_OK {"hash":"623183840","packet_count":105,"placement_count":105,...}`

---

## Task 1 - Define dossier schema and truth states

Problem: Story facts need a single structured representation before systems can share them.

1. Define fields such as `story_id`, `company_id`, `archetype`, `truth_state`, `timeline`, `financial_effects`, `price_effects`, `public_clues`, `private_clues`, `statement_clues`, and `resolution_conditions`.
2. Include truth states such as `real`, `delayed`, `failed`, `overhyped`, `fraud_risk`, and `uncertain` if useful.
3. Document how dossier facts map to news, Twooter, Network, filings, and thesis.
4. Verify:
   - Design review in this doc.
   - `git diff --check`

### Task 1 schema now defined

#### Design direction

The dossier system is the detailed truth owner for company stories. It should not replace existing event systems in one step.

Current systems keep their roles:

- `CompanyEventSystem` and `CompanyRoadmapSystem` can still create live events and arcs.
- `CorporateActionApplications` keeps applying corporate action mechanics.
- Living company arc state keeps compact lifecycle indexes: active, cooling down, completed, eligible.
- The dossier stores story facts, reveal rules, evidence ids, and resolution logic.

The key boundary:

| Layer | Owns |
|---|---|
| Dossier | Story truth, facts, clue rules, financial/price intent, resolution conditions. |
| Living arc | Active/resolved/cooldown lifecycle, compact history, reservation gates. |
| Content surfaces | Generated or authored presentation of allowed facts. |
| Thesis | Player-captured evidence and reasoning, linked back to dossier fact ids. |
| Price engine | Bounded price/volume reaction from exposed story pressure, not hidden display text. |

This keeps display text from becoming the source of truth and prevents News, Twooter, Network, filings, and thesis from inventing conflicting story states.

#### Dossier runtime shape

Future saved runtime state should store compact instances, not large generated copy.

```gdscript
{
	"schema_version": 1,
	"story_id": "story|company_id|archetype_id|seed_hash",
	"company_id": "",
	"ticker": "",
	"archetype_id": "",
	"story_family": "",
	"hook_id": "",
	"truth_state": "uncertain",
	"public_status": "rumor",
	"stage_id": "seeded",
	"priority": 0.0,
	"confidence": 0.0,
	"started_day_index": -1,
	"expected_resolution_day_index": -1,
	"resolved_day_index": -1,
	"outcome_state": "",
	"cause_facts": [],
	"timeline": [],
	"financial_effects": [],
	"price_effects": {},
	"public_clues": [],
	"private_clues": [],
	"statement_clues": [],
	"thesis_hooks": [],
	"resolution_conditions": [],
	"traceability": {}
}
```

Primary fields:

| Field | Meaning |
|---|---|
| `story_id` | Stable id for this story instance. Every generated clue should reference it. |
| `company_id` / `ticker` | Target company identity. |
| `archetype_id` | Template such as `capex_expansion`, `margin_recovery`, `commodity_tailwind`, `governance_risk`, or `contract_win`. |
| `story_family` | Broader category for balancing and UI grouping. |
| `hook_id` | Company catalog `story_hooks` or generated hook that seeded the dossier. |
| `truth_state` | Hidden canonical truth state. Public surfaces should not reveal this directly. |
| `public_status` | What the market currently thinks, such as `rumor`, `confirmed`, `questioned`, `disputed`, or `resolved`. |
| `stage_id` | Current story stage, such as `seeded`, `public_chatter`, `filing_hint`, `execution`, `resolution`, or `aftermath`. |
| `priority` | Relative selection/content weight. |
| `confidence` | Internal model confidence in the current truth state, not player certainty. |
| `started_day_index` | First day this story exists in runtime. |
| `expected_resolution_day_index` | Planned check/resolution day. |
| `resolved_day_index` | Day the story resolved, or `-1` while active. |
| `outcome_state` | Final result such as `confirmed`, `missed`, `partially_confirmed`, `quietly_faded`, or `exposed`. |
| `cause_facts` | Machine-readable upstream causes: macro, sector, commodity, company, relationship, or corporate action. |
| `timeline` | Stage schedule and clue unlock windows. |
| `financial_effects` | Intended or actual effects on revenue, margin, capex, debt, cash, inventory, customers, etc. |
| `price_effects` | Bounded price/volume/sentiment hints for the price engine. |
| `public_clues` | Facts that public surfaces may reveal. |
| `private_clues` | Facts that Network or inner-circle contacts may reveal. |
| `statement_clues` | Facts that filings/financial statements/notes may reveal. |
| `thesis_hooks` | Evidence categories and thesis vocabulary hooks. |
| `resolution_conditions` | Conditions that decide whether the story proves real, delayed, failed, overhyped, or risky. |
| `traceability` | Source ids for tests, generated output, and evidence capture. |

#### Archetype guidance

The first implementation should start with a small set of reusable archetypes. These should map cleanly to existing company catalog hooks and future financial statement notes.

| Archetype | Typical source inputs | Typical verification |
|---|---|---|
| `capex_expansion` | roadmap profile, funding need, project hooks | capex note, cash/debt movement, project progress note |
| `margin_recovery` | commodity input relief, operating leverage, pricing power | gross margin, operating margin, MD&A margin note |
| `commodity_tailwind` | positive commodity exposure, macro commodity leader | revenue/ASP movement, volume note, sector article |
| `commodity_headwind` | negative commodity exposure, macro commodity laggard | margin pressure, inventory write-down, management warning |
| `contract_win` | customer hook, government or enterprise demand | backlog, revenue visibility, customer concentration note |
| `turnaround` | weak recent performance, management upgrade, restructuring | cost line improvement, store/plant utilization, debt covenant update |
| `governance_risk` | management exit, related-party risk, audit concern | delayed filing, auditor note, private warning |
| `balance_sheet_stress` | high debt, refinancing need, rate pressure | debt maturity note, cash flow stress, rights issue link |
| `fraud_signal` | aggressive claims, mismatch between public and filing clues | statement contradiction, private source warning, regulator/news event |
| `corporate_action_use_of_proceeds` | rights issue, private placement, acquisition, buyback | use-of-proceeds note, project outcome, dilution/result evidence |

#### Hidden truth states

`truth_state` is canonical but hidden from the player unless a surface earns a direct reveal.

| Truth state | Meaning | Gameplay implication |
|---|---|---|
| `real` | The core story is true and should eventually leave matching evidence. | Financial/price effects can materialize if timing and execution work. |
| `delayed` | The story is true, but timing slips. | Early public hype may fade before later confirmation. |
| `failed` | The intended project/contract/recovery breaks. | Public clues can start positive, but filings/private clues should deteriorate. |
| `overhyped` | There is some basis, but public expectations are too strong. | Price can react before evidence disappoints. |
| `fraud_risk` | Claims may be misleading or contradictory. | Public text may look bullish; private/filing clues should raise warnings. |
| `uncertain` | The system has not resolved the truth yet, or evidence is mixed. | Surfaces should express uncertainty and avoid direct recommendations. |

Do not use `rumor` as a truth state. `rumor` is a public status or clue format. The hidden truth can be `real`, `failed`, `overhyped`, and so on while public surfaces still call it a rumor.

#### Public status and stage ids

`public_status` tracks the market-facing state:

- `silent`
- `rumor`
- `reported`
- `confirmed`
- `questioned`
- `disputed`
- `resolved`

`stage_id` tracks internal progression:

- `seeded`
- `public_chatter`
- `private_whisper`
- `filing_hint`
- `execution_window`
- `resolution`
- `aftermath`

These are separate so a story can be internally in `filing_hint` while public status is still `rumor`.

#### Cause facts

`cause_facts` are upstream reasons for a story. Each should be a compact row:

```gdscript
{
	"fact_id": "fact|story_id|macro|coal_rally",
	"fact_type": "commodity",
	"source_id": "coal",
	"direction": "positive",
	"strength": 0.0,
	"confidence": 0.0,
	"related_sector_ids": [],
	"related_company_ids": [],
	"tags": []
}
```

Useful `fact_type` values:

- `macro`
- `commodity`
- `sector`
- `company_trait`
- `roadmap`
- `corporate_action`
- `relationship`
- `management`
- `financial_statement`
- `market_behavior`

#### Timeline rows

`timeline` controls when facts can surface:

```gdscript
{
	"stage_id": "public_chatter",
	"start_day_index": 25,
	"end_day_index": 38,
	"visibility": "public",
	"unlock_surface_ids": ["news", "twooter"],
	"fact_ids": [],
	"expected_tone": "positive",
	"reliability": 0.45
}
```

Rules:

- Timeline rows should be deterministic from seed, story id, and company id.
- Surfaces should only reveal clues whose timeline window has started.
- A surface can lag the underlying truth. For example, filings may reveal a fact after public chatter.

#### Financial effects

`financial_effects` describe what statements should eventually show.

```gdscript
{
	"effect_id": "effect|story_id|revenue_jump",
	"metric_id": "revenue",
	"statement_section": "income_statement",
	"direction": "up",
	"magnitude_band": "large",
	"timing": "next_quarter",
	"persistence": "temporary",
	"confidence": 0.0,
	"truth_states": ["real", "delayed"],
	"note_type": "customer_contract",
	"explain_tags": []
}
```

Common `metric_id` values:

- `revenue`
- `gross_margin`
- `operating_margin`
- `net_income`
- `cash`
- `debt`
- `capex`
- `working_capital`
- `inventory`
- `receivables`
- `customer_concentration`
- `production_volume`
- `backlog`

`magnitude_band` should be descriptive, not exact accounting:

- `small`
- `moderate`
- `large`
- `transformational`

#### Price effects

`price_effects` should remain bounded and explainable. They should feed future price integration as structured pressure, not override the price engine.

```gdscript
{
	"sentiment_bias": 0.0,
	"drift_bps": 0.0,
	"volatility_multiplier": 1.0,
	"volume_multiplier": 1.0,
	"confidence": 0.0,
	"duration_days": 0,
	"explain_tags": [],
	"truth_state_modifiers": {}
}
```

Rules:

- Public hype can affect sentiment and volume even when `truth_state` is `overhyped` or `fraud_risk`.
- Durable drift should require stronger evidence or financial effects.
- The price engine should consume bounded values and keep existing guardrails.

#### Clue rows

All clue rows should point back to facts and expected surfaces.

```gdscript
{
	"clue_id": "clue|story_id|news|01",
	"fact_ids": [],
	"surface_id": "news",
	"visibility": "public",
	"earliest_day_index": 25,
	"latest_day_index": 40,
	"detail_level": "low",
	"reliability": 0.5,
	"tone": "mixed",
	"leak_risk": 0.0,
	"text_key": "capex_expansion_public_rumor"
}
```

Useful `surface_id` values:

- `news`
- `twooter`
- `network`
- `filing`
- `statement_note`
- `thesis`
- `internal_debug`

Private clue rows add access requirements:

```gdscript
{
	"clue_id": "clue|story_id|network|inner_circle|01",
	"fact_ids": [],
	"surface_id": "network",
	"visibility": "private",
	"required_relationship_stage": "trusted",
	"required_recognition_min": 70,
	"source_quality": "operator",
	"directness": "specific",
	"reliability": 0.85,
	"text_key": "capex_expansion_operator_direct"
}
```

Statement clues add financial placement:

```gdscript
{
	"clue_id": "clue|story_id|statement|01",
	"fact_ids": [],
	"surface_id": "statement_note",
	"visibility": "filing",
	"period_offset": 1,
	"statement_section": "notes",
	"note_type": "capex_progress",
	"metric_ids": ["capex", "cash", "debt"],
	"disclosure_quality": "partial",
	"text_key": "capex_progress_partial_note"
}
```

#### Resolution conditions

`resolution_conditions` decide outcome in a deterministic, testable way:

```gdscript
{
	"condition_id": "condition|story_id|revenue_growth",
	"metric_id": "revenue_growth_yoy",
	"operator": ">=",
	"threshold": 0.18,
	"evaluation_day_index": 80,
	"success_outcome": "confirmed",
	"failure_outcome": "missed",
	"truth_state_if_success": "real",
	"truth_state_if_failure": "failed"
}
```

Condition types can include:

- metric threshold
- filing clue appears
- corporate action proceeds applied
- roadmap milestone completed
- contract/customer clue confirmed
- private contradiction triggered
- deadline missed

#### Traceability shape

`traceability` should make future tests cheap:

```gdscript
{
	"seed_parts": [],
	"source_company_hook_ids": [],
	"source_fact_ids": [],
	"generated_surface_ids": [],
	"evidence_ids": [],
	"price_effect_ids": [],
	"statement_effect_ids": []
}
```

Rules:

- Every generated article/post/tip/filing clue should include `story_id` and at least one `fact_id` or `clue_id`.
- Every thesis evidence row generated from a dossier should include `story_id`, `fact_id`, and `surface_id`.
- Fingerprint tests should hash ids and structured fields, not prose.

#### Surface mapping

| Surface | Reads from | Can reveal | Must not reveal |
|---|---|---|---|
| News | `public_clues`, selected `cause_facts`, public timeline rows | Public rumors, confirmed events, sector/macro context, management statements. | Hidden `truth_state`, private source names, inner-circle direct tips. |
| Twooter | `public_clues`, sentiment slices, public status | Chatter, hype, skepticism, crowd disagreement, account-biased reads. | Private clues, definitive hidden truth, filing-only details before filing unlock. |
| Network | `private_clues`, relevant public clues, relationship thresholds | Higher-detail tips, direct company/sector reads, inner-circle direct stock hints when allowed. | Guaranteed profit, hidden truth without relationship/source access, unrelated private facts. |
| Filings/statements | `statement_clues`, `financial_effects`, resolution conditions | Numbers, notes, MD&A clues, use-of-proceeds, customer/capex/debt details. | Future unreleased private info unless it belongs in that filing period. |
| Thesis | `thesis_hooks`, captured clues, financial effects | Structured evidence rows, contradiction markers, thesis vocabulary tags. | Auto-final answers; thesis should support player reasoning, not replace it. |
| Price engine | `price_effects`, public pressure, proven financial effects | Bounded sentiment, drift, volume, volatility pressure. | Display text, hidden truth labels as direct price overrides. |
| Living arc | `story_id`, stage, source, expected end, tone | Lifecycle reservation and cooldown metadata. | Full dossier payload or generated prose. |

#### Save compatibility direction

Task 1 does not add save data, but the future state should follow this compatibility rule:

- Missing dossier state normalizes to an empty registry.
- Companies without active dossiers remain compatible and playable.
- Existing events, roadmaps, corporate actions, index reviews, news, Twooter, Network, and thesis behavior should continue until later tasks explicitly bridge dossier output.
- Generated text should be derived from ids/facts and not stored in save payloads unless it is user-authored evidence.

#### Task 1 verification result

- Design review captured in this section.
- Runtime behavior unchanged.

## Task 2 - Add deterministic dossier selection/generation

Problem: Runs need stable story dossiers tied to company identity and seed.

1. Generate or select dossiers based on company archetype, sector, moat, exposure, and current macro/sector state.
2. Use existing seed/hash patterns.
3. Keep generated values bounded and explainable.
4. Verify:
   - Fixed-seed dossier fingerprint.
   - Godot headless editor gate.

### Task 2 implementation notes

`systems/CompanyStoryDossierSystem.gd` now owns the first generation pass.

Public API:

- `generate_dossiers(run_seed, company_definitions, macro_state, options)`
- `generate_company_dossier(run_seed, company_definition, macro_state, company_index, options)`
- `ranked_archetype_candidates(run_seed, company_definition, macro_state, company_index)`

Generation inputs:

- company identity, ticker, sector, subsector, story hooks, moat tags, narrative tags, commodity exposures, macro exposures, roadmap profile, and price traits
- current macro state sector biases and commodity indicators
- stable seed parts through `StableRng`

Generated dossier rows include:

- `cause_facts`
- `timeline`
- `financial_effects`
- `price_effects`
- `public_clues`
- `private_clues`
- `statement_clues`
- `thesis_hooks`
- `resolution_conditions`
- `traceability`

Guardrails:

- `price_effects.drift_bps` is bounded to `-18..18`.
- volatility and volume multipliers stay inside narrow bands.
- generated rows use ids and structured fields only; no large prose blobs are stored.
- no persistence or live content bridge exists yet, so current gameplay behavior remains unchanged.

Task 2 verification result:

- `CompanyStoryDossierFingerprintTest` locks fixed-seed generation to hash `1867741019`.

## Task 3 - Add story state persistence and normalizers

Problem: Story progression must survive saves and old saves must remain compatible.

1. Persist active dossier ids and current stage/state.
2. Add normalizer defaults for missing story state.
3. Avoid saving large derived text when it can be regenerated.
4. Verify:
   - Save/default probe.
   - Quick smoke if runtime state changes.

### Task 3 implementation notes

`RunState` now owns the saved runtime registry. The generator still owns deterministic dossier construction.

Fresh-run behavior:

- `_finalize_new_run_setup()` seeds dossier state after companies and macro state exist.
- The seed path generates one dossier per active company definition.
- Per-company runtime refs are derived from the global registry.

Load/save behavior:

- `to_save_dict()` writes `company_story_dossier_state`.
- each saved company runtime writes compact `company_story_dossier_state`.
- `load_from_dict()` normalizes global state, company runtime state, and then syncs per-company refs from the global registry.
- missing global state stays empty for legacy saves; it does not auto-generate on load.

Task 3 verification result:

- `CompanyStoryDossierSaveDefaultsTest` covers fresh-run seeding, progress update persistence, save/reload persistence, legacy missing-state defaults, and malformed partial-state normalization.

## Task 4 - Bridge dossier facts to thesis evidence

Problem: Players need to capture structured evidence from story facts.

1. Add thesis evidence shapes for macro cause, sector cause, company story, financial clue, and private clue.
2. Keep current thesis behavior compatible.
3. Verify:
   - Targeted thesis evidence test.
   - Existing thesis tests.

### Task 4 implementation notes

`ThesisManager` now reads saved dossier state through `RunState.get_company_story_dossiers_for_company(...)` and converts facts into thesis evidence options.

Category mapping:

| Dossier evidence type | Thesis category | Source surface |
|---|---|---|
| `macro_cause` | `sector_macro` | `thesis` |
| `sector_cause` | `sector_macro` | `thesis` |
| `company_story` | `corporate_events` | `thesis` |
| `financial_clue` | `financials` | `statement_note` |
| `private_clue` | `network_intel` | `network` |

Compatibility behavior:

- No new thesis category was added.
- Existing report pillars and fixed thesis evidence rows continue to work.
- The option list now includes extra Story Dossier rows, so `ThesisFingerprintTest` has a new option hash.
- Research Tray rows and attached thesis evidence preserve `story_id`, `fact_id`, `surface_id`, and related dossier provenance.
- Dossier thesis rows do not expose hidden `truth_state`; they expose public status/stage plus traceable ids.

Task 4 verification result:

- `CompanyStoryDossierThesisEvidenceTest` covers all five evidence shapes, thesis option inclusion, Research Tray capture/attach, direct add, category mapping, and provenance preservation.
- `ThesisResearchTrayTest` and `ThesisFingerprintTest` pass with the new option baseline.

## Task 5 - Add consistency and fingerprint tests

Problem: Story systems can drift silently if content surfaces interpret facts differently.

1. Add a dossier consistency probe that checks the same story id across public/private/financial outputs.
2. Add fixed-seed fingerprints for selected dossiers.
3. Verify:
   - Repeated runs produce the same fingerprint.
   - No orphan story ids.

### Task 5 implementation notes

`CompanyStoryDossierConsistencyTest` is now the cross-surface consistency gate.

The test covers:

| Area | Check |
|---|---|
| Global saved state | `active_story_ids`, `resolved_story_ids`, `company_story_ids`, and recent rows do not point at missing dossier ids. |
| Story rows | `story_id`, `company_id`, and per-company runtime refs agree. |
| Facts | every `fact_id` belongs to the owning `story_id` and is unique inside the dossier. |
| Clues | public/private/statement clue ids belong to the story and fact/metric refs are valid. |
| Financial effects | `effect_id` and `metric_id` rows are scoped and usable by statement clues/resolution conditions. |
| Timeline | timeline ids belong to the story and fact refs are valid. |
| Thesis hooks | hook ids, story ids, company ids, fact refs, and metric refs are valid. |
| Traceability | traceability fact/evidence/surface/price/statement arrays exactly match generated rows. |
| Thesis bridge | Story Dossier thesis rows reference valid story/fact/clue/effect ids and do not expose hidden truth state. |

Task 5 verification result:

- Fixed-seed consistency hash is `2006435509`.
- Repeated runs produce the same payload and hash.
- No orphan story ids or orphan fact/clue/effect refs were found.

## Task 6 - Wire minimal read-only content previews

Problem: The dossier should prove it can feed content without taking over every content system at once.

1. Add a limited preview for one surface, such as a generated internal summary or test-only news preview.
2. Do not replace existing live feed behavior until the preview is tested.
3. Verify:
   - Preview output references valid dossier facts.
   - `git diff --check`

### Task 6 implementation notes

`CompanyStoryDossierSystem` now exposes preview rows for controlled read-only consumption.

Current methods:

- `build_preview(dossier, surface_id)`
- `build_preview_rows(dossiers, surface_id, options)`

Supported surfaces:

| Surface | Source rows |
|---|---|
| `summary` | internal summary using the news clue as the default public anchor |
| `news` | matching public news clue |
| `twooter` | matching public Twooter clue |
| `network` | matching private network clue |
| `statement_note` | matching statement clue |

Preview rows include:

- `preview_id`, `story_id`, `company_id`, `ticker`, `surface_id`
- public `stage_id` and `public_status`
- deterministic `headline`, `deck`, and `body`
- referenced `fact_ids`, `clue_ids`, `effect_ids`, and `metric_ids`
- compact traceability arrays

Guardrails:

- Preview rows do not expose hidden `truth_state`.
- Preview rows do not expose tone, reliability, source quality, or disclosure quality because those can leak hidden state.
- Existing live feed behavior is unchanged; this is explicit-call preview plumbing only.

Task 6 verification result:

- Fixed-seed preview hash is `1727264953`.
- `30` news preview rows and `5` limited summary preview rows validated.
- No orphan story/fact/clue/effect refs were found.

## R1.1 - Define disclosure placement schema and filing section map

Problem: Statement clues currently identify that a filing clue exists, but they do not define where that clue should realistically appear in an annual report.

1. Define a `disclosure_placements` shape for dossier stories.
2. Map dossier facts/effects/clues into filing sections:
   - revenue
   - segment information
   - trade receivables
   - inventories
   - property, plant, and equipment
   - debt and borrowings
   - related party transactions
   - commitments and contingencies
   - subsequent events
   - cash flow information
3. Keep placement machine-readable and deterministic.
4. Verify:
   - every placement references valid story/fact/effect/clue ids
   - no hidden `truth_state` is exposed in public placement rows

### R1.1 implementation notes

`CompanyStoryDossierSystem` now builds `disclosure_placements` beside existing statement clues.

The placement contract is intentionally machine-readable:

| Field | Meaning |
|---|---|
| `placement_id` | Stable id: `placement|story_id|NN|section_id`. |
| `story_id` | Owning dossier story id. |
| `surface_id` | Currently `annual_report`. |
| `section_id` | Canonical filing section id. |
| `section_label` / `section_group` | Human-readable section metadata for future UI/report rendering. |
| `annual_statement_note_type` | Existing annual statement note bucket that can receive this placement. |
| `placement_role` | `primary`, `supporting`, or `corroborating`. |
| `note_type` | Story dossier note type, such as `customer_contract`, `capex_progress`, or `debt_maturity`. |
| `visibility` | Currently `filing`. |
| `fact_ids` / `effect_ids` / `clue_ids` / `metric_ids` | Traceable references back to dossier facts, financial effects, statement clues, and metrics. |
| `statement_sections` | Statement areas affected by the referenced financial effects. |
| `source_note_types` / `source_metric_ids` | Deterministic source mapping hints for Financial Statement R3. |
| `text_key` | Deterministic phrase key placeholder; no long prose is saved. |

Section placement is derived from three deterministic maps:

- story `note_type`
- story `archetype_id`
- financial-effect `metric_id`

This gives each story several plausible annual-report locations without exposing hidden truth. For example:

| Story shape | Typical filing placements |
|---|---|
| Customer contract | revenue, segment information, trade receivables, commitments/contingencies. |
| Capex expansion | PPE, cash flow information, commitments/contingencies, subsequent events. |
| Debt maturity | debt and borrowings, cash flow information, commitments/contingencies, subsequent events. |
| Governance risk | related party transactions, trade receivables, commitments/contingencies, subsequent events. |
| Statement contradiction | trade receivables, inventories, related party transactions, cash flow information. |

Save/load behavior:

- `RunState` now normalizes `disclosure_placements`.
- Placement rows are capped and string-array references are normalized.
- Hidden fields are stripped if malformed save data tries to include them:
  - `truth_state`
  - `disclosure_quality`
  - `reliability`
  - `confidence`
  - `source_quality`

Traceability behavior:

- `traceability.disclosure_placement_ids` mirrors generated placement ids.
- `traceability.disclosure_section_ids` mirrors generated section ids.

Task R1.1 verification result:

- Fixed-seed disclosure hash is `1533142911`.
- The baseline generated `144` disclosure placements across `30` dossiers.
- All 10 target filing sections appeared at least once.
- Save/load normalization preserved placements and stripped hidden placement fields.

Implementation status: complete.

## R1.2 - Add clue subtlety and scattering rules

Problem: If every story is disclosed directly, the filing becomes a spoiler instead of a research surface.

1. Add clue subtlety bands:
   - direct
   - implied
   - buried
   - conflicting
   - missing
2. Add scattering rules that decide how many filing sections should carry fragments of the same story.
3. Tie subtlety to public status, story stage, clue reliability, and truth state without exposing those hidden inputs.
4. Verify:
   - real stories can be direct or implied
   - overhyped/failed/fraud-risk stories can produce conflicting or missing filing evidence
   - generated placement remains deterministic by seed

### R1.2 implementation notes

`CompanyStoryDossierSystem` now computes a deterministic scattering plan before building placement rows.

Inputs used at generation time:

- `story_id`
- hidden `truth_state`
- public `public_status`
- public `stage_id`
- statement clue reliability
- candidate filing sections from R1.1

Saved placement rows do not expose hidden truth labels. They store only public filing-reading metadata:

| Field | Meaning |
|---|---|
| `subtlety` | How obvious the filing clue is: `direct`, `implied`, `buried`, `conflicting`, or `missing`. |
| `reader_effort` | Expected effort to notice the clue: `low`, `medium`, or `high`. |
| `evidence_density` | Filing evidence texture: `clear`, `partial`, `thin`, `contradictory`, or `absent`. |
| `fragment_role` | Role of this placement inside the trail: `anchor`, `context`, `cross_check`, `risk_signal`, or `absence_signal`. |
| `scattering_strategy` | Overall trail shape, such as `confirmation_trail`, `thin_support_trail`, or `control_risk_trail`. |
| `scattering_index` / `scattering_total` | Deterministic position inside the story's filing trail. |

Current subtlety rules:

| Hidden story condition | Public filing pattern |
|---|---|
| Real | direct or implied anchor, then implied/buried supporting rows. |
| Delayed | implied anchor, buried rows, and possible missing later corroboration. |
| Failed | conflicting anchor and missing final corroboration. |
| Overhyped | implied anchor, buried rows, and missing/conflicting support. |
| Fraud risk | conflicting risk signal plus buried/missing corroboration. |
| Uncertain | implied anchor and buried supporting rows. |

Current scattering behavior:

- Each story selects a deterministic subset of plausible filing sections.
- Stage/status can increase section count when the story is closer to filing or public resolution.
- Lower-reliability risky/uncertain clues can scatter wider to create cross-note work for the player.
- Placement rows still preserve valid fact/effect/clue/metric refs from the dossier.

Task R1.2 verification result:

- Fixed-seed disclosure hash is `1192489532`.
- The baseline generated `105` disclosure placements across `30` dossiers.
- All five subtlety bands appeared.
- All 10 filing sections from R1.1 remained represented.
- The focused test validates real direct/implied coverage and failed/overhyped/fraud-risk conflicting or missing coverage.

Implementation status: complete.

## R1.3 - Generate multi-section filing disclosure packets

Problem: Financial Statement R3 needs ready-to-render filing packets instead of reverse-engineering story placement from raw facts.

1. Generate compact disclosure packets per story.
2. Each packet should include:
   - `placement_id`
   - `story_id`
   - `section_id`
   - `note_type`
   - `subtlety`
   - `fact_ids`
   - `effect_ids`
   - `clue_ids`
   - `metric_ids`
   - deterministic text keys or phrase ids
3. Avoid storing long generated prose in save state.
4. Verify:
   - one story can produce multiple filing packets
   - packets stay valid after save/load
   - packet ids are stable across repeated fixed-seed runs

### R1.3 implementation notes

`CompanyStoryDossierSystem` now builds `disclosure_packets` from the R1.1/R1.2 placement rows.

Relationship model:

| Layer | Purpose |
|---|---|
| `disclosure_placements` | Defines where the story appears in the filing and how subtle/scattered it is. |
| `disclosure_packets` | Defines compact render-ready metadata for each placement. |

Packet shape:

| Field | Meaning |
|---|---|
| `packet_id` | Stable id: `packet|story_id|NN|section_id`. |
| `placement_id` | Source placement id. |
| `section_id` / `annual_statement_note_type` | Target filing section and current annual-statement note bucket. |
| `subtlety` / `reader_effort` / `evidence_density` | Filing-reading texture inherited from placement. |
| `packet_role` | Render role: `primary_evidence`, `anchor_evidence`, `supporting_evidence`, `cross_reference_evidence`, `challenge_evidence`, or `absence_evidence`. |
| `render_priority` | Deterministic priority for future renderer ordering. |
| `fact_ids` / `effect_ids` / `clue_ids` / `metric_ids` | Traceable dossier references. |
| `phrase_ids` | Deterministic phrase identifiers for future wording selection. |
| `render_tokens` | Compact tokens for renderer routing; no long prose is saved. |
| `cross_reference_section_ids` | Related filing sections to cross-reference when rendering the annual report. |
| `text_key` | Existing deterministic text-key fallback. |

Rendering contract:

- Packets should be consumed by Financial Statement R3 instead of having the annual report infer story placement itself.
- Packets are still not final prose.
- Future renderers should map `phrase_ids` and `render_tokens` to localized/templated text.
- Hidden truth labels are not stored in packet rows.

Save/load behavior:

- `RunState` now normalizes `disclosure_packets`.
- Packet rows are capped and reference arrays are normalized.
- Hidden fields are stripped if malformed save data tries to include them.
- Invalid packet subtlety normalizes to `implied`.

Task R1.3 verification result:

- Fixed-seed packet hash is `2005222199`.
- The baseline generated `105` disclosure packets across `30` dossiers.
- Every story produced multiple packets.
- Packet ids, placement ids, fact/effect/clue/metric refs, phrase ids, render tokens, cross references, and traceability packet ids were validated.

Implementation status: complete.

## R1.4 - Persist/normalize disclosure placement state

Problem: Generated placement decisions must survive saves and remain compatible with old saves.

1. Add placement rows to saved dossier state or derive them from stable dossier seeds.
2. Add normalizer defaults for saves that do not have placement rows.
3. Keep old Story Dossier tests compatible.
4. Verify:
   - legacy saves load
   - malformed placement rows normalize safely
   - fixed-seed fingerprints remain deterministic

### R1.4 implementation notes

Disclosure placement and packet rows now survive both direct saves and old/partial saves.

Compatibility behavior:

- If a loaded dossier already has valid `disclosure_placements` and `disclosure_packets`, `RunState` normalizes those rows and keeps them.
- If either row set is missing or malformed to empty, `RunState` asks `CompanyStoryDossierSystem.disclosure_artifacts_for_dossier(...)` to rebuild the missing artifacts from stable story fields.
- Rebuilt rows are normalized through the same save-safe row normalizers as newly generated rows.
- Traceability disclosure arrays are repaired from the normalized row ids every time the dossier normalizer runs.

Read API contract:

| API | Purpose |
|---|---|
| `RunState.get_company_story_disclosure_placements(story_id, section_id = "")` | Resolve filing placement rows for one story. |
| `RunState.get_company_story_disclosure_packets(story_id, section_id = "")` | Resolve filing packet rows for one story. |
| `RunState.get_company_story_disclosure_placements_for_company(company_id, section_id = "")` | Resolve filing placement rows for all stories owned by a company. |
| `RunState.get_company_story_disclosure_packets_for_company(company_id, section_id = "")` | Resolve filing packet rows for all stories owned by a company. |

Task R1.4 verification result:

- Fixed-seed disclosure persistence hash is `2080268323`.
- Legacy saves with placement/packet rows removed rebuilt `105` placements and `105` packets across `30` dossiers.
- Malformed placement/packet rows normalized safely and rebuilt the same `105` placements and `105` packets.
- Company, story, and section lookup helpers returned section-filtered rows.
- Existing packet, placement, save-default, consistency, preview, and fingerprint baselines stayed stable.

Implementation status: complete.

## R1.5 - Bridge disclosure packets to Financial Statement R3

Problem: The annual report should consume story placement as source data, not create its own story-distribution rules.

1. Add read APIs for filing disclosure packets by company and section.
2. Preserve hidden-source provenance in payload metadata.
3. Keep visible packet content free of hidden truth labels.
4. Verify:
   - Financial Statement R3 can request packets by section
   - thesis evidence capture can trace packet rows back to story/fact/effect/clue ids

Task R1.5 implementation result:

- Annual statement story enrichment now derives note-level packet provenance from normalized dossier `disclosure_packets`.
- Notes receive source-data bridge fields:
  - `source_disclosure_packet_ids`
  - `source_disclosure_placement_ids`
  - `source_disclosure_section_ids`
  - `disclosure_packet_refs`
- Statement traceability rolls those fields up to:
  - `post_start_source_disclosure_packet_ids`
  - `post_start_source_disclosure_placement_ids`
  - `post_start_source_disclosure_section_ids`
- Thesis capture preserves the packet bridge fields from annual statement notes through Research Tray, attached evidence, direct evidence, and save/load normalization.
- Hidden truth/source-quality labels remain out of visible packet refs.
- Financial Statement R3 can now request packet refs by annual note section from the annual statement note payload instead of re-running placement logic.

Implementation status: complete. R1.4 added generic packet/placement lookup by company/story/section; R1.5 wired those saved packet refs into annual note enrichment and thesis capture. R1.6 should add the final cross-feature fixture before Financial Statement R3 consumes these packet refs in the document-reader flow.

## R1.6 - Add disclosure placement consistency and fingerprint tests

Problem: Subtle disclosure placement will be easy to break if tests only check that a clue exists somewhere.

1. Add a fixed-seed disclosure placement fingerprint.
2. Add consistency checks for:
   - valid story refs
   - valid fact/effect/clue refs
   - section/note type validity
   - subtlety distribution
   - no hidden truth leaks
3. Add a cross-feature fixture for Financial Statement R3 tests.
4. Verify:
   - repeated runs produce the same packet hash
   - every packet can be resolved by company and section

Task R1.6 implementation result:

- Added `CompanyStoryDossierFinancialStatementFixtureTest` and matching scene.
- The fixture locks the generated disclosure packet contract and the annual note packet bridge in one fixed-seed test.
- It validates story refs, fact/effect/clue refs, section and note-type validity, subtlety distribution, packet roles, no hidden truth leaks, section lookup APIs, annual note packet refs, and thesis evidence normalization.
- Fixed-seed baseline:
  - hash `623183840`
  - `30` dossiers
  - `105` placements
  - `105` packets
  - `10` sections
  - `5` subtlety bands
  - fixture company `alat_berat_mandiri`
  - `10` annual note packet refs

Implementation status: complete. Financial Statement R3 can now consume the Story Dossier R1 packet refs with a dedicated cross-feature regression fixture in place.

## Known traps

- If display text becomes the source of truth, systems cannot reason about the story.
- If every surface writes its own truth state, drift will return.
- If all stories are too clean, the game loses the uncertainty that makes research interesting.
- If every filing clue is direct, annual statements become spoilers instead of research material.
- If filing placement is implemented inside the Financial Statement renderer, story distribution will drift from News, Twooter, Network, thesis, and price facts.
