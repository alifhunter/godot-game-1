# Event Content Editor

Dev-only local editor for market, company, person, corporate-action, and special event definitions. It uses only Python stdlib and is not part of the player build.

## Run

From the project root:

```bash
python tools/event_content_editor/server.py
```

Open:

```text
http://127.0.0.1:8773
```

## Workflow

- `Load` reads `tools/event_content_editor/event_content_source.json`.
- If the source is missing or empty, the editor imports `data/events/events.json`.
- `Save Source` saves editable source data only.
- `Validate` checks required runtime event IDs, duplicate IDs, event families/scopes/tones, durations, sentiment knobs, person metadata, special-event shock profiles, sector biases, and headline templates.
- `Export Runtime JSON` writes `data/events/events.json`.

## Edited Data

The tool edits event definitions used by `systems/MarketSimulator.gd`, `systems/CompanyEventSystem.gd`, `systems/PersonEventSystem.gd`, `systems/SpecialEventSystem.gd`, News, Twooter, and debug event injection:

- event IDs, scopes, families, categories, and tones
- duration and sentiment shift values
- broker-bias tags used by market pressure reads
- person-event labels
- active special-event duration windows, market bias, volatility multipliers, shock profiles, headlines, and sector biases
- corporate-action fallback metadata rows

It does not edit active run state. Live event history, active arcs, active special events, and generated News/Twooter items remain runtime-owned.

## CLI Checks

```bash
python tools/event_content_editor/server.py --validate
python tools/event_content_editor/server.py --export --dry-run
```

Use `--export` without `--dry-run` to update the runtime event definitions JSON from the source.
