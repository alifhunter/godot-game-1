# Balance / Upgrades Editor

Dev-only local editor for upgrade and progression-balance content. It uses only Python stdlib and is not part of the player build.

## Run

From the project root:

```bash
python tools/balance_upgrades_editor/server.py
```

Open:

```text
http://127.0.0.1:8772
```

## Workflow

- `Load` reads `tools/balance_upgrades_editor/balance_upgrades_source.json`.
- If the source is missing or empty, the editor imports `data/upgrades/upgrade_catalog.json`.
- `Save Source` saves editable source data only.
- `Validate` checks required upgrade tracks, tier coverage, costs, trading-fee fields, content levels, chart indicator IDs, and Network daily AP limits.
- `Export Runtime JSON` writes `data/upgrades/upgrade_catalog.json`.

## Edited Data

The tool edits the upgrade catalog used by `autoloads/GameManager.gd`, `autoloads/RunState.gd`, and the Upgrades desktop app:

- upgrade track labels and descriptions
- tier costs and effect labels
- trading fee rates for buy/sell orders
- News and Twooter content unlock levels
- chart indicator unlock sets
- Network daily action point limits

It does not edit active run state. Existing save files keep their current upgrade tiers; exported catalog changes what each tier costs and does.

## CLI Checks

```bash
python tools/balance_upgrades_editor/server.py --validate
python tools/balance_upgrades_editor/server.py --export --dry-run
```

Use `--export` without `--dry-run` to update the runtime upgrade catalog JSON from the source.
