# Release License Audit

Last reviewed: 2026-05-19

This is a release-hygiene checklist, not legal advice. It records what is in the repo, what already has a license file, and what still needs owner confirmation before a public Early Access build.

## Checked Scope

- `assets/` media, fonts, icons, audio, and imported resources
- `addons/godotsteam/` runtime and editor plugin files
- `data/` runtime generated-content catalogs
- `docs/`, `README.md`, and `PROJECT_HANDOFF.md` for copied real-world references
- `project.godot` and `export_presets.cfg` for assets likely to ship

## Cleared With Existing Notices

| Content | Location | License / basis | Release note |
|---|---|---|---|
| BHSL game product | `EULA.txt` | Proprietary Banyakarya game license | Ship beside `BHSL.exe` for public builds. |
| Godot Engine | exported executable, `GODOT_COPYRIGHT.txt` | MIT License plus engine third-party notices | Ship `GODOT_COPYRIGHT.txt` beside `BHSL.exe`. Official guidance: https://docs.godotengine.org/en/stable/about/complying_with_licenses.html |
| GodotSteam GDExtension | `addons/godotsteam/` | MIT License | Local notice exists at `addons/godotsteam/license.md`. |
| Steamworks runtime DLLs | `steam_api64.dll` in Steam build, GodotSteam runtime deps | Steamworks SDK / Valve redistributable runtime | Keep the full Steamworks SDK outside the repo. Only ship required redistributable runtime files with the Steam build. Official SDK overview: https://partner.steamgames.com/doc/sdk |
| Open Sans | `assets/fonts/` | SIL Open Font License 1.1 | Local notice exists at `assets/fonts/OFL.txt`. |
| Tabler Icons | `assets/icons/*.svg` except `icon.ico` | MIT License | Local notice exists at `assets/icons/LICENSE.txt`. Official repo notes MIT license: https://github.com/tabler/tabler-icons |

## Needs Owner Confirmation

Confirm these are original, commissioned, or generated under terms that allow commercial Steam distribution:

- `assets/logo/logobhsl.png`
- `assets/logo/logorengan.png`
- `assets/icons/icon.ico`
- `assets/academy/lessons/fundamental/1. player progression.png`
- `assets/market_papers/design_reference.*`
- `assets/market_papers/grunge/*`
- `assets/ui/desktop/*.svg`

The Market Papers and desktop SVGs look like local/generated UI assets, and no external source URLs were found in runtime data. Still, keep this confirmation explicit for release records.

## Resolved Release Decision

### Removed ElevenLabs click sound

File:

```text
assets/sound/ElevenLabs_Button_press_sound_of_a_gaming_mouse,_high_precision.mp3
```

Official ElevenLabs guidance says free-plan generated content does not include a commercial license, while paid-plan generated content can be used commercially if it was not generated through beta services and otherwise complies with their terms:

https://help.elevenlabs.io/hc/en-us/articles/13313564601361-Can-I-publish-the-content-I-generate-on-the-platform

Release decision: removed from the project. `UiAudio` is no longer registered as an autoload, and the ElevenLabs MP3/import files are deleted.

## Runtime Content Check

- No copied Siloam, Suryacipta, DCI, DBS/UOB, Danamon, Chandra Asri, or IDNFinancials source text was found in runtime `data/`, `systems/`, `scripts/`, `autoloads/`, or `scenes/`.
- Those real-world examples appear only as planning/reference context in conversation history and are not embedded in player-facing runtime catalogs.
- Generated company/news/roadmap catalogs use fictional companies and generic Indonesian business scenarios.

## Export Hygiene Notes

- `project.godot` now uses `res://assets/icons/icon.ico` for the project icon instead of the default Godot `icon.svg`.
- `export_presets.cfg` still uses `export_filter="all_resources"`. Before a final public upload, review whether unused reference files should be removed or excluded from the export, especially:
  - `icon.svg` / `icon.svg.import`
  - `assets/fonts/Open_Sans.zip`
  - `assets/market_papers/design_reference.*`
  - editor-only GodotSteam files under `addons/godotsteam/editor/`
- `EULA.txt`, `THIRD_PARTY_NOTICES.txt`, and `GODOT_COPYRIGHT.txt` now exist at the repo root and should be copied beside `BHSL.exe` for public Steam builds.
- `GODOT_COPYRIGHT.txt` was sourced from Godot Engine's official `COPYRIGHT.txt`. When upgrading Godot/export templates, refresh this file from the matching engine version.
