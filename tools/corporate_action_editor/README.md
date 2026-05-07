# Corporate Action Editor

Dev-only local editor for the corporate-action generator catalog. It uses only Python stdlib and is not part of the player build.

## Run

From the project root:

```bash
python tools/corporate_action_editor/server.py
```

Open:

```text
http://127.0.0.1:8769
```

## Workflow

- `Load` reads `tools/corporate_action_editor/corporate_action_source.json`.
- If the source is missing or empty, the editor imports `data/corporate_actions/corporate_action_catalog.json`.
- `Save Source` saves editable source data only.
- `Validate` checks global timing/range settings, stage templates, v1 family coverage, family agendas, mutual-exclusion references, and meeting presentation copy.
- `Export Runtime JSON` writes `data/corporate_actions/corporate_action_catalog.json`.

## Edited Data

The tool edits the catalog used by `systems/CorporateActionSystem.gd`:

- annual RUPS, RUPSLB, earnings-call, cash-dividend, and stock-dividend timing rules
- per-family numeric knobs for rights issues, buybacks, splits, tender offers, M&A, backdoor listings, CEO changes, and restructurings
- stage order and stage templates for corporate-action chain progression
- family metadata, default venue, mutual-exclusion lists, spawn story bias, and shareholder agendas
- interactive RUPSLB / meeting presentation copy

It does not edit active run state. Live chains, meeting calendars, dividend records, shareholder registries, attended meetings, and meeting sessions still live in run saves.

## CLI Checks

```bash
python tools/corporate_action_editor/server.py --validate
python tools/corporate_action_editor/server.py --export --dry-run
```

Use `--export` without `--dry-run` to update the runtime corporate-action JSON from the source.
