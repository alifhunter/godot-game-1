# Company Narrative Editor

Dev-only local editor for company narrative generation content. It uses only Python stdlib and is not part of the player build.

## Run

From the project root:

```bash
python tools/company_narrative_editor/server.py
```

Open:

```text
http://127.0.0.1:8771
```

## Workflow

- `Load` reads `tools/company_narrative_editor/company_narrative_source.json`.
- If the source is missing or empty, the editor imports the current runtime files from `data/companies/`.
- `Save Source` saves editable source data only.
- `Validate` checks seeded company templates, generated name words, profile copy pools, archetype/sector/size coverage, narrative tag sentence pools, and template tokens.
- `Export Runtime JSON` writes `data/companies/company_archetypes.json`, `data/companies/company_words.json`, and `data/companies/company_profile_data.json`.

## Edited Data

The tool edits the company narrative inputs used by `systems/CompanyRosterGenerator.gd` and `systems/CompanyNarrativeGenerator.gd`:

- seeded company templates, tickers, sectors, narrative tags, and valuation anchors
- generated company name word pool
- profile sentence templates and global differentiators
- archetype labels, tones, age ranges, size weights, descriptors, verbs, differentiators, and tags
- sector business/scope/differentiator/tag pools
- size bucket ranges, descriptors, and tags
- optional narrative tag sentence pools
- per-sector archetype selection weights

It does not edit active run state. Generated companies, market history, portfolio state, and save data remain runtime-owned.

## CLI Checks

```bash
python tools/company_narrative_editor/server.py --validate
python tools/company_narrative_editor/server.py --export --dry-run
```

Use `--export` without `--dry-run` to update the runtime company narrative JSON files from the source.
