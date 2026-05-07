# Broker Roster Editor

Dev-only local editor for broker roster content. It uses only Python stdlib and is not part of the player build.

## Run

From the project root:

```bash
python tools/broker_roster_editor/server.py
```

Open:

```text
http://127.0.0.1:8770
```

## Workflow

- `Load` reads `tools/broker_roster_editor/broker_roster_source.json`.
- If the source is missing, the editor imports `data/brokers/broker_roster.json`.
- `Save Source` saves editable source data only.
- `Validate` checks broker codes, duplicate rows, required fields, broker type coverage, player broker coverage, and personality tag coverage.
- `Export Runtime JSON` writes `data/brokers/broker_roster.json`.

## Edited Data

The tool edits the roster used by `systems/BrokerFlowSystem.gd` and `autoloads/DataRepository.gd`:

- broker code
- broker company name
- broker type bucket (`foreign`, `retail`, `institution`, `bandar`, `zombie`)
- personality tags used by broker-flow weighting and action-meter reads

It does not edit active run state. Generated daily broker rows, player flow, and company broker-flow snapshots still live in runtime state and saves.

## CLI Checks

```bash
python tools/broker_roster_editor/server.py --validate
python tools/broker_roster_editor/server.py --export --dry-run
```

Use `--export` without `--dry-run` to update the runtime broker roster JSON from the source.
