# Company Universe Editor

Dev-only local editor for the catalog-backed company universe. It uses only Python stdlib and is not part of the player build.

## Run

From the project root:

```bash
python3 tools/company_universe_editor/server.py
```

Open:

```text
http://127.0.0.1:8775
```

## Workflow

- `Load` reads `tools/company_universe_editor/company_universe_source.json`.
- If the source is missing or empty, the editor imports the current runtime file from `data/companies/company_universe_catalog.json`.
- `Save Source` saves editable source data only.
- `Validate` checks ids, tickers, known sectors, subsector format, exposure ranges, price traits, relationship hook shape, sector coverage, and default roster count safety.
- `Export Runtime JSON` writes `data/companies/company_universe_catalog.json`.

## Edited Data

The tool edits catalog-backed companies used by default run roster selection:

- id, ticker, name, sector, subsector, and business summary
- moat tags and story hooks
- commodity and macro exposure maps
- price traits
- relationship graph hooks

It does not edit active run state. Current saves, selected rosters, market history, portfolio state, and relationship graph runtime state remain runtime-owned.

## CLI Checks

```bash
python3 tools/company_universe_editor/server.py --validate
python3 tools/company_universe_editor/server.py --export --dry-run
```

Use `--export` without `--dry-run` to update the runtime company universe JSON file from the source.

After export, run:

```bash
python3 -m json.tool data/companies/company_universe_catalog.json > /dev/null
/Users/user/.local/bin/godot --headless --path . scenes/tests/CompanyUniverseCatalogValidationTest.tscn
/Users/user/.local/bin/godot --headless --path . scenes/tests/CompanyUniverseSelectionFingerprintTest.tscn
```
