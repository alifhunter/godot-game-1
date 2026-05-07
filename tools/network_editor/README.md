# Network / Contact Editor

Dev-only local editor for `Network` and RUPSLB room contact content. It uses only Python stdlib and is not part of the player build.

## Run

From the project root:

```bash
python tools/network_editor/server.py
```

Open:

```text
http://127.0.0.1:8768
```

## Workflow

- `Load` reads `tools/network_editor/network_source.json`.
- If the source has no catalog yet, the editor imports `data/network/contact_network_data.json`.
- `Save Source` saves editable source data only.
- `Validate` checks contact ids, affiliation types, insider template roles, sector references, recognition/relationship/reliability bounds, meeting lead profiles, stage speech bubbles, and template tokens.
- `Export Runtime JSON` writes `data/network/contact_network_data.json`.

## Edited Data

The tool edits the catalog used by `systems/ContactNetworkSystem.gd`:

- base contact cap and default relationship
- generated insider first/family name pools
- authored floater contacts
- insider templates for generated CEO/CFO/Commissioner contacts
- RUPSLB meeting lead profiles and stage-specific speech bubbles
- tip and request response templates

It does not edit save-game Network state. Met contacts, discoveries, requests, tip journals, and relationship changes still live in run saves.

## CLI Checks

```bash
python tools/network_editor/server.py --validate
python tools/network_editor/server.py --export --dry-run
```

Use `--export` without `--dry-run` to update the runtime Network JSON from the source.
