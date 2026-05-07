# Content Lint Dashboard

Dev-only read-only dashboard for content validation and generated previews. It uses only Python stdlib and is not part of the player build.

## Run

From the project root:

```bash
python tools/content_lint_dashboard/server.py
```

Open:

```text
http://127.0.0.1:8774
```

## Workflow

- `Refresh Lints` imports and runs the validators from the existing content editor tools.
- `Tool Launcher` shows each editor's local URL, launch command, validator command, and dry-run export command.
- Runtime JSON checks verify parseability, file size, entry count, duplicate top-level IDs where applicable, and template-token counts.
- `Generate Preview` renders deterministic samples from the current runtime content files using a seed and reports generated-copy quality issues.
- `Preview QA` scans a seed range for unresolved template tokens, repeated punctuation, spacing issues, empty copy, and overly long titles.
- The dashboard is read-only and does not write source or runtime JSON.

## Preview Coverage

The generated preview currently samples:

- company narrative names and profile copy
- event definitions and special-event headlines
- News article copy
- Twooter posts
- Network contact/tip/request copy
- corporate-action stage/family data
- Academy lesson copy

The preview renderer is a lightweight Python approximation for copy QA. It is not a replacement for the Godot simulation.

## CLI Checks

```bash
python tools/content_lint_dashboard/server.py --validate
python tools/content_lint_dashboard/server.py --preview --seed 42
python tools/content_lint_dashboard/server.py --preview-scan --seed 42 --count 20
```

`--validate` exits non-zero only when aggregated validators or runtime JSON parsing report errors.
`--preview-scan` exits non-zero when generated preview quality issues are found.
