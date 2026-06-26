# Company Universe Catalog Enhancement - Plan & Progress Log

This plan creates the first foundation for top-down research: a richer company universe that can be selected per run instead of relying only on fully procedural company identity.
**Status: complete - Tasks 1-6 complete; follow-up expansions brought the catalog to 100 companies and Task 6 made catalog selection the default run roster path.** Designed to run in a fresh session; everything needed to execute cold is in this file.

**Review verdict recap:** The current generated companies are useful, but top-down research needs stable company identity, sector/subsector placement, commodity exposure, moat, price traits, relationship hooks, and story hooks. The plan should not remove the current generator in one pass. The first implementation should add catalog-backed data in parallel, validate determinism, and only then bridge it into run selection.

## Where everything lives

| What | Where |
|---|---|
| Current roster owner | `systems/CompanyRosterGenerator.gd` - selects and builds the run company roster |
| Current company generator | `systems/CompanyGenerator.gd` - builds company identity and base profile |
| Current profile builders | `systems/CompanyChartProfileBuilder.gd`, `systems/CompanyFinancialsBuilder.gd` - chart and financial profile generation |
| Current data/config | `data/companies/company_archetypes.json`, `data/companies/company_profile_data.json`, `data/companies/company_words.json`, `data/companies/company_roadmap_catalog.json` |
| Planned catalog | `data/companies/company_universe_catalog.json` |
| Runtime state | Selected company roster in `autoloads/RunState.gd` |
| Tests/probes | Existing company generation tests and planned catalog validation/fingerprint tests |
| Key functions | Locate by `generate_company_roster`, company generation entry points, and `SeededPool` use |

## Goals

- Add a durable company catalog schema with identity, sector, subsector, exposure, moat, price trait, relationship, and story hooks.
- Use catalog-backed companies as the default run roster while keeping current generated-company behavior available as an explicit fallback/regression path.
- Make selected run rosters deterministic and fingerprintable.

## Non-goals

- Do not write hundreds of companies before the schema is proven.
- Do not make catalog companies the only source of companies in the first task.
- Do not add price effects until the price integration plan owns that work.

## Working rules

- Start with schema and validation before runtime behavior.
- Keep all generated/selected company output deterministic by seed.
- New saved keys need normalizer defaults.
- If editing JSON, run `python3 -m json.tool`.
- Use quick smoke after behavior changes; planning-only or JSON-only changes can stop at doc/JSON validation unless runtime loading changes.

## Status

| # | Task | Est. cost | Status |
|---|---|---|---|
| 1 | Define catalog schema and seed sample | ~15-25% | Complete |
| 2 | Add loader and validation | ~10-20% | Complete |
| 3 | Bridge catalog into roster selection behind compatibility path | ~20-35% | Complete |
| 4 | Add deterministic selection fingerprints | ~10-20% | Complete |
| 5 | Expand initial catalog after schema stabilizes | ~15-30% | Complete |
| 6 | Enable catalog as default run roster source | ~10-20% | Complete |

Recommended batching: **All tasks are complete.** The catalog is now the default roster path, while the procedural generator remains available by setting `use_company_universe_catalog = false`.

## Progress log

### 2026-06-14 - Plan created

- Created this enhancement plan from the top-down market brainstorming session.
- Current inventory:
  - Existing company generation already has archetypes, words, profiles, roadmaps, financial builders, and chart builders.
  - No company universe catalog exists yet.
  - The first safe step is schema plus a small sample, not a full replacement.
- No code or data changes were made by this planning step.

### 2026-06-14 - Task 1 complete

- Added `data/companies/company_universe_catalog.json` as a data-only planning seed.
- The initial catalog seed had 50 companies, 50 unique ids, and 50 unique tickers across the existing sector ids:
  - `consumer`: 5
  - `noncyclical`: 5
  - `energy`: 5
  - `basicindustry`: 5
  - `industrial`: 5
  - `tech`: 5
  - `infra`: 5
  - `transport`: 4
  - `health`: 4
  - `finance`: 4
  - `property`: 3
- Each company includes `id`, `ticker`, `name`, `sector`, `subsector`, `business_summary`, `moat_tags`, `commodity_exposures`, `macro_exposures`, `price_traits`, `relationship_hooks`, and `story_hooks`.
- Runtime behavior stayed intentionally unchanged. No loader, roster selection, price integration, or save-state changes were made.
- Verification:
  - `python3 -m json.tool data/companies/company_universe_catalog.json > /dev/null`
  - Fixed count/uniqueness probe: `companies=50`, `ids=50`, `tickers=50`

### 2026-06-14 - Task 2 complete

- Added `DataRepository` loading and validation for `data/companies/company_universe_catalog.json`.
- The catalog uses an optional dictionary loader for now, so a missing file warns instead of hard-failing runtime reload before roster generation depends on it.
- Added safe-copy accessors:
  - `get_company_universe_catalog()`
  - `get_company_universe_companies()`
  - `get_company_universe_company(company_id)`
  - `get_company_universe_definition(company_id)`
  - `get_company_universe_validation_result()`
- Added a by-id index for catalog lookup without wiring it into roster generation.
- Validation currently checks:
  - `companies` array shape
  - required fields
  - unique non-empty ids
  - unique uppercase tickers
  - non-empty names, summaries, and snake_case subsectors
  - known sector ids and known relationship target sector ids
  - array/dictionary field shapes
  - numeric exposure values in `-1.0..1.0`
  - required price trait fields and numeric price-trait ranges
  - relationship hook strength in `0.0..1.0`
- Added `scripts/tests/CompanyUniverseCatalogValidationTest.gd` and `scenes/tests/CompanyUniverseCatalogValidationTest.tscn`.
- Runtime behavior stayed intentionally unchanged. No roster selection, price integration, or save-state changes were made.
- Verification:
  - `python3 -m json.tool data/companies/company_universe_catalog.json > /dev/null`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyUniverseCatalogValidationTest.tscn` -> `COMPANY_UNIVERSE_CATALOG_VALIDATION_OK {"companies":70,"sample_id":"sawit_bumi_raya","schema_version":1,"sectors":11}`
  - `/Users/user/.local/bin/godot --headless -e --quit`
  - `git diff --check`

### 2026-06-14 - Task 3 complete

- Added an opt-in catalog roster bridge without changing default run behavior.
- `systems/CompanyRosterGenerator.gd` now has `generate_catalog_roster(...)`, which:
  - deterministically selects catalog entries for a fixed seed
  - converts catalog entries into the current company definition shape
  - keeps current `id`, `ticker`, `name`, `sector_id`, `listing_board`, `narrative_tags`, and `anchors` fields
  - carries catalog metadata forward as extra fields: `company_source`, `universe_catalog_id`, `subsector`, `business_summary`, `moat_tags`, `commodity_exposures`, `macro_exposures`, `price_traits`, `relationship_hooks`, and `story_hooks`
  - applies catalog price-trait hints to generated anchors in a bounded way
- `GameManager.build_company_roster(...)` now uses the catalog path only when the difficulty config includes `use_company_universe_catalog = true`.
- If the catalog validation fails or cannot produce the requested roster size, `GameManager` warns and falls back to the existing procedural roster.
- Added `scripts/tests/CompanyUniverseRosterBridgeTest.gd` and `scenes/tests/CompanyUniverseRosterBridgeTest.tscn`.
- Runtime default behavior stayed intentionally unchanged. Normal difficulty configs do not set `use_company_universe_catalog`, and the existing procedural fingerprint is unchanged.
- Verification:
  - `python3 -m json.tool data/companies/company_universe_catalog.json > /dev/null`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyUniverseCatalogValidationTest.tscn` -> `COMPANY_UNIVERSE_CATALOG_VALIDATION_OK {"companies":70,"sample_id":"sawit_bumi_raya","schema_version":1,"sectors":11}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyUniverseRosterBridgeTest.tscn` -> `COMPANY_UNIVERSE_ROSTER_BRIDGE_OK {"catalog_count":30,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyGenerationFingerprintTest.tscn` -> `COMPANY_GENERATION_FINGERPRINT_OK ... "hash":"1225696160" ...`
  - `/Users/user/.local/bin/godot --headless -e --quit`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=94765318.11`
  - `git diff --check`

### 2026-06-14 - Task 4 complete

- Added `scripts/tests/CompanyUniverseSelectionFingerprintTest.gd` and `scenes/tests/CompanyUniverseSelectionFingerprintTest.tscn`.
- The test locks deterministic catalog selection for `run_seed = 20260614` and a 30-company roster.
- The original 50-company baseline was superseded by the Task 5 catalog expansion.
- Current deterministic baseline is documented in the Task 5 log below.
- The fingerprint payload includes selected ids, tickers, sector distribution, source, tags, hooks, and macro/commodity exposure summaries.
- Company display names are intentionally excluded from the hash so copy/name polish does not break deterministic roster selection tests.
- Runtime default behavior stayed intentionally unchanged. The catalog path is still opt-in through `use_company_universe_catalog`.
- Verification:
  - `python3 -m json.tool data/companies/company_universe_catalog.json > /dev/null`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyUniverseCatalogValidationTest.tscn` -> `COMPANY_UNIVERSE_CATALOG_VALIDATION_OK {"companies":70,"sample_id":"sawit_bumi_raya","schema_version":1,"sectors":11}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyUniverseRosterBridgeTest.tscn` -> `COMPANY_UNIVERSE_ROSTER_BRIDGE_OK {"catalog_count":30,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyUniverseSelectionFingerprintTest.tscn` -> current baseline is maintained by Task 5
  - `/Users/user/.local/bin/godot --headless -e --quit`
  - `git diff --check`

### 2026-06-14 - Task 5 complete

- Expanded `data/companies/company_universe_catalog.json` from 50 to 60 companies.
- Added 10 new companies:
  - `wisata_kuliner_nusantara` / `WIKN` - consumer, tourism food service
  - `protein_nusantara` / `PTIN` - noncyclical, poultry integrator
  - `panas_bumi_lestari` / `PABL` - energy, geothermal power
  - `tembaga_kabel_prima` / `TKBP` - basic industry, copper processing
  - `satelit_data_nusantara` / `SDNX` - tech, satellite broadband
  - `rel_kargo_nusantara` / `RKGN` - transport, rail freight
  - `biotek_vaksin_nusa` / `BVKN` - health, biotechnology
  - `sekuritas_rakyat_digital` / `SRDG` - finance, digital brokerage
  - `hotel_resort_sentosa` / `HRSN` - property, hospitality property
  - `data_center_estate` / `DCES` - property, data center estate
- Current sector coverage:
  - `consumer`: 6
  - `noncyclical`: 6
  - `energy`: 6
  - `basicindustry`: 6
  - `industrial`: 5
  - `tech`: 6
  - `infra`: 5
  - `transport`: 5
  - `health`: 5
  - `finance`: 5
  - `property`: 5
- Added more top-down drivers for tourism, poultry feed costs, geothermal policy, copper/grid buildout, satellite connectivity, rail freight, biotechnology, retail market liquidity, hospitality cycles, and data center power constraints.
- Updated `CompanyUniverseCatalogValidationTest` to expect 60 entries.
- The 60-company deterministic selection fingerprint was superseded by the follow-up expansion below.
- Runtime default behavior stayed intentionally unchanged. The catalog path is still opt-in through `use_company_universe_catalog`.
- Verification:
  - `python3 -m json.tool data/companies/company_universe_catalog.json > /dev/null`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyUniverseCatalogValidationTest.tscn` -> `COMPANY_UNIVERSE_CATALOG_VALIDATION_OK {"companies":70,"sample_id":"sawit_bumi_raya","schema_version":1,"sectors":11}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyUniverseRosterBridgeTest.tscn` -> `COMPANY_UNIVERSE_ROSTER_BRIDGE_OK {"catalog_count":30,...}`
  - `/Users/user/.local/bin/godot --headless --path . --scene res://scenes/tests/CompanyUniverseSelectionFingerprintTest.tscn` -> current baseline is maintained by the follow-up expansion below

### 2026-06-14 - Follow-up catalog expansion complete

- Expanded `data/companies/company_universe_catalog.json` from 60 to 70 companies.
- Added 2 commodity-linked basic industry companies:
  - `rare_bumi_mineral` / `RBUM` - rare earth processing
  - `silika_surya_material` / `SSMA` - silica mining
- Added 8 banking companies to cover a clearer finance ladder:
  - `bank_nusantara_raya` / `BNRY` - large bank
  - `bank_mega_samudra` / `BMSA` - mid-market bank
  - `bank_desa_sejahtera` / `BDSJ` - small bank
  - `bank_syariah_harmoni` / `BSHR` - sharia bank
  - `bank_daerah_mandiri` / `BDMR` - regional bank
  - `bank_digital_karya` / `BDGK` - digital bank
  - `bank_ekspor_nusa` / `BENX` - trade finance bank
  - `bank_kredit_rakyat` / `BKRA` - micro-lending bank
- Current sector coverage:
  - `basicindustry`: 8
  - `consumer`: 6
  - `energy`: 6
  - `finance`: 13
  - `health`: 5
  - `industrial`: 5
  - `infra`: 5
  - `noncyclical`: 6
  - `property`: 5
  - `tech`: 6
  - `transport`: 5
- `rare_earth`, `silica`, and `gold` are now used by company `commodity_exposures`, so the commodity catalog has no unused extra definitions.
- Updated `CompanyUniverseCatalogValidationTest` to expect 70 entries.
- Updated the deterministic selection fingerprint baseline:
  - fingerprint hash: `1682964508`
  - first selected company: `surya_power_nusantara` / `SPWR`
  - last selected company: `menara_signal_nusantara` / `MSIN`
- Superseded by Task 6: runtime default behavior now uses the catalog path.

### 2026-06-22 - Task 6 complete

- Enabled `use_company_universe_catalog = true` on the default difficulty presets:
  - `chill`
  - `normal`
  - `grind`
- Updated `RunState.DEFAULT_DIFFICULTY_CONFIG` so fallback/default normalizers also preserve the catalog default.
- Fresh player runs now select the run roster from `data/companies/company_universe_catalog.json`.
- The procedural generator remains available by explicitly setting `use_company_universe_catalog = false`.
- Updated `CompanyUniverseRosterBridgeTest` so it asserts:
  - default difficulty uses `company_source = universe_catalog`
  - explicit procedural override still produces a non-catalog roster
  - explicit catalog roster remains deterministic
- Updated `CompanyGenerationFingerprintTest` to lock the old procedural generator through the explicit override instead of assuming default means procedural.
- Updated `data/companies/company_universe_catalog.json` description so it no longer says catalog selection is opt-in.
- Added a filing-reader compatibility fix in `AnnualFilingDocument`: every visible annual filing segment note now exposes a neutral selected-amounts table even when the selected catalog company has no story-derived segment footprint yet. This preserves `segment_row` capture coverage for catalog-backed default companies.
- Updated `AnnualFilingVisibleGenerationTest` to the new deterministic hash after the segment selected-amounts table became part of the generated visible filing.
- Verification:
  - `python3 -m json.tool data/companies/company_universe_catalog.json > /dev/null` -> passed.
  - `CompanyUniverseCatalogValidationTest.tscn` -> `COMPANY_UNIVERSE_CATALOG_VALIDATION_OK {"companies":70,"sample_id":"sawit_bumi_raya","schema_version":1,"sectors":11}`.
  - `CompanyUniverseRosterBridgeTest.tscn` -> `COMPANY_UNIVERSE_ROSTER_BRIDGE_OK` with `default_count=30`, `catalog_count=30`, and `procedural_count=30`.
  - `CompanyUniverseSelectionFingerprintTest.tscn` -> unchanged hash `1682964508`.
  - `CompanyGenerationFingerprintTest.tscn` -> explicit procedural fallback hash `1225696160`.
  - `AnnualFilingVisibleGenerationTest.tscn` -> updated visible generation hash `1665441399`.
  - `SmokeTest.tscn -- --smoke-quick --smoke-local-io` -> `SMOKE_QUICK_OK normal_equity=95485619.77 days=3`.

### 2026-06-24 - Follow-up catalog expansion to 100 complete

- Expanded `data/companies/company_universe_catalog.json` from 70 to 100 companies.
- Added 30 companies across consumer, noncyclical, energy, basic industry, industrial, tech, infrastructure, transport, health, finance, and property.
- Added more commodity/sector coverage for solar power, city gas, coal terminals, fertilizer, glass, aluminium, battery materials, factory automation, machine components, metal packaging, merchant software, semiconductor design, cybersecurity cloud, rural tower/fiber, water utility, ferry transport, air cargo, diagnostics labs, hospitals, motorcycle finance, life insurance, small banks, warehouses, transit apartments, and industrial estates.
- Current sector coverage:
  - `consumer`: 9
  - `noncyclical`: 8
  - `energy`: 9
  - `basicindustry`: 12
  - `industrial`: 8
  - `tech`: 9
  - `infra`: 7
  - `transport`: 7
  - `health`: 7
  - `finance`: 16
  - `property`: 8
- Updated `CompanyUniverseCatalogValidationTest` to expect 100 entries.
- Updated the deterministic catalog selection fingerprint baseline:
  - fingerprint hash: `1266026255`
  - first selected company: `armada_kurir_nusantara` / `AKRN`
  - last selected company: `asuransi_nusa` / `ASNS`
- Verification:
  - `python3 -m json.tool data/companies/company_universe_catalog.json > /dev/null` -> passed.
  - `CompanyUniverseCatalogValidationTest.tscn` -> `COMPANY_UNIVERSE_CATALOG_VALIDATION_OK {"companies":100,"sample_id":"sawit_bumi_raya","schema_version":1,"sectors":11}`.
  - `CompanyUniverseRosterBridgeTest.tscn` -> `COMPANY_UNIVERSE_ROSTER_BRIDGE_OK` with `default_count=30`, `catalog_count=30`, and `procedural_count=30`.
  - `CompanyUniverseSelectionFingerprintTest.tscn` -> updated hash `1266026255`.

---

## Task 1 - Define catalog schema and seed sample

Problem: Top-down systems need stable company metadata that procedural names alone cannot provide.

1. Create `data/companies/company_universe_catalog.json`.
2. Add a small sample set, ideally 50 companies across several sectors and subsectors.
3. Include fields for `id`, `ticker`, `name`, `sector`, `subsector`, `business_summary`, `moat_tags`, `commodity_exposures`, `macro_exposures`, `price_traits`, `relationship_hooks`, and `story_hooks`.
4. Verify:
   - `python3 -m json.tool data/companies/company_universe_catalog.json > /dev/null`
   - `git diff --check`

## Task 2 - Add loader and validation

Problem: Runtime and tests need a single reliable way to read the catalog and report invalid entries.

1. Add a lightweight loader through the existing data repository pattern if appropriate.
2. Validate required keys, unique ids, unique tickers, known sector/subsector values, and exposure value ranges.
3. Keep missing catalog behavior non-fatal until the feature is wired into roster generation.
4. Verify:
   - Targeted catalog validation test.
   - Godot headless editor gate.

## Task 3 - Bridge catalog into roster selection

Problem: The catalog is only useful when a run can select from it deterministically.

1. Add a compatibility path that can select catalog companies without removing procedural generation.
2. Preserve existing run behavior by default unless the task explicitly switches the default.
3. Convert catalog entries into the current company shape expected by market, UI, thesis, and contact systems.
4. Verify:
   - Targeted roster selection test.
   - Existing company generation tests.
   - Quick smoke.

## Task 4 - Add deterministic selection fingerprints

Problem: Catalog selection must be reproducible or future content tests will become noisy.

1. Add a fixed-seed roster fingerprint test.
2. Include selected ids, tickers, sector distribution, and key exposure summaries.
3. Document the expected fingerprint in the test output or test log.
4. Verify:
   - Fingerprint test stable across repeated runs.
   - `git diff --check`

## Task 6 - Enable catalog as default run roster source

Problem: Top-down research should start from stable company identity by default, not only in opt-in test scenarios.

Result: Complete. Default difficulties now use catalog-backed roster selection. The old procedural generator remains available with `use_company_universe_catalog = false`.

1. Set catalog-backed selection on the default difficulty presets.
2. Update fallback/default difficulty config in `RunState`.
3. Keep explicit procedural override for generator regression tests.
4. Verify:
   - Company universe validation.
   - Roster bridge test.
   - Company universe selection fingerprint.
   - Procedural company generation fingerprint with explicit override.
   - Annual filing visible generation fixture after catalog-default smoke coverage.
   - Quick smoke.

## Task 5 - Expand initial catalog

Problem: A tiny catalog proves structure but does not support the intended top-down variety.

1. Expand to 40-60 companies after the schema and loader are stable.
2. Cover priority sectors, subsectors, and commodity exposures.
3. Avoid duplicate companies that differ only by name.
4. Verify:
   - JSON validation.
   - Catalog validation test.
   - Selection fingerprint update.

## Known traps

- If catalog entries are too specific too early, every later schema change becomes expensive.
- If generated company behavior is removed immediately, existing tests and saves may break unnecessarily.
- Moat and exposure fields must be machine-readable, not only prose, or the price engine cannot use them.
