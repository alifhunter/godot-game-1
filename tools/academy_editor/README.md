# Academy Content Editor

Dev-only local editor for `Academy` content. It uses only Python stdlib and is not part of the player build.

## Run

From the project root:

```powershell
python tools/academy_editor/server.py
```

Open:

```text
http://127.0.0.1:8765
```

## Workflow

- `Load` reads `tools/academy_editor/academy_source.json`.
- If the source has no catalog yet, the editor imports `data/academy/academy_catalog.json`.
- `Save Source` saves editable source data only.
- `Validate` checks ids, lesson blocks, quick checks, quiz questions, glossary, and image paths.
- `Export Runtime JSON` writes `data/academy/academy_catalog.json`.
- Uploaded images are copied into `assets/academy/lessons/` and stored as `res://assets/academy/lessons/...`.

## Lesson Blocks

Lessons use structured `content_blocks`:

- `Text Block`: warm card with heading/body, optional inline images, and optional nested infobox note cards.
- `Image Block`: image asset, caption, and alt text.
- `Key Insights`: blue card with prominent blue left border, title, and bullet list.

Text blocks are also exported back into legacy `pages` entries so older Academy fallback rendering stays compatible.
Inline text-block images use the same upload flow and `res://assets/academy/lessons/...` paths as top-level image blocks.

## CLI Checks

```powershell
python tools/academy_editor/server.py --validate
python tools/academy_editor/server.py --export --dry-run
```

Use `--export` without `--dry-run` to update the runtime Academy JSON from the source.
