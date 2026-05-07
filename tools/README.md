# Gorengan Content Tools

These are local, dev-only Python web tools for editing and checking structured game content. They are modding-adjacent authoring tools, not a player mod loader: exported data still writes into the base runtime JSON files under `data/`.

Run commands from the project root.

## Quick Start

Open the read-only lint and preview dashboard:

```bash
python3 tools/content_lint_dashboard/server.py
```

Then open:

```text
http://127.0.0.1:8774
```

Run the aggregate CLI checks:

```bash
python3 tools/content_lint_dashboard/server.py --validate
python3 tools/content_lint_dashboard/server.py --preview --seed 42
python3 tools/content_lint_dashboard/server.py --preview-scan --seed 42 --count 20
```

## Editors

| Tool | Port | Launch | Runtime output |
| --- | ---: | --- | --- |
| Academy editor | 8765 | `python3 tools/academy_editor/server.py` | `data/academy/academy_catalog.json` |
| News editor | 8766 | `python3 tools/news_editor/server.py` | `data/news/news_feed_data.json` |
| Twooter editor | 8767 | `python3 tools/twooter_editor/server.py` | `data/social/twooter_feed_data.json` |
| Network/contact editor | 8768 | `python3 tools/network_editor/server.py` | `data/network/contact_network_data.json` |
| Corporate action editor | 8769 | `python3 tools/corporate_action_editor/server.py` | `data/corporate_actions/corporate_action_catalog.json` |
| Broker roster editor | 8770 | `python3 tools/broker_roster_editor/server.py` | `data/brokers/broker_roster.json` |
| Company narrative editor | 8771 | `python3 tools/company_narrative_editor/server.py` | `data/companies/company_archetypes.json`, `data/companies/company_words.json`, `data/companies/company_profile_data.json` |
| Balance/upgrades editor | 8772 | `python3 tools/balance_upgrades_editor/server.py` | `data/upgrades/upgrade_catalog.json` |
| Event content editor | 8773 | `python3 tools/event_content_editor/server.py` | `data/events/events.json` |
| Content lint dashboard | 8774 | `python3 tools/content_lint_dashboard/server.py` | Read-only checks and previews |

Each editor keeps its editable source next to its server script, for example `tools/news_editor/news_source.json`. Use each editor's `Save Source` action while drafting and `Export Runtime JSON` when the runtime `data/` file should change.

## CLI Validation

Run one editor validator:

```bash
python3 tools/news_editor/server.py --validate
```

Dry-run an export without writing runtime JSON:

```bash
python3 tools/news_editor/server.py --export --dry-run
```

Run the whole content tool stack:

```bash
python3 tools/content_lint_dashboard/server.py --validate
```

The dashboard imports the editor validators, parses the key runtime JSON files, reports content warnings, launches from a tool index, generates sample previews for companies, events, News, Twooter, Network, corporate actions, and Academy content, and can scan preview seed ranges for generated-copy issues.

## Godot Smoke

On this Mac, `godot` and `godot4` are symlinked through `~/.local/bin` to:

```text
/Users/user/Downloads/Godot.app/Contents/MacOS/Godot
```

Current local binary:

```bash
godot --version
```

Standard checks:

```bash
godot --headless --path . --log-file /private/tmp/gorengan-project-load.log --quit
godot --headless --path . --log-file /private/tmp/gorengan-smoke-quick.log --scene res://scenes/tests/SmokeTest.tscn -- --smoke-quick --smoke-local-io
```

Known non-blocking Mac noise includes Steam not running, a certificate-store warning, and trailing RID/ObjectDB cleanup warnings after `SMOKE_QUICK_OK`.
