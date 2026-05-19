# Steam Playtest Checklist

Status: Steam platform release-candidate checklist for build `0.1.0-ea / 2026.05.17.1`.

Run this pass from Steam unless a developer explicitly asks for an editor or headless verification. The current project Steam App ID is `4739020`; Cloud is verified, and achievement/stat runtime code is implemented, but the Steamworks stats/achievements must be created and published before live unlock verification.

## Before Starting

1. Install or update the current Steam build.
2. Launch from Steam.
3. Confirm the main menu build label shows `Build 2026.05.17.1`.
4. Open the Steam overlay with Shift+Tab.
5. Start a fresh `Normal` run in a 16:9 window or fullscreen.

## Core Flow

1. Finish the first playable setup and reach the desktop.
2. Open `STOCKBOT`, select several companies, and place at least one buy or sell.
3. Open `News`, read a market article and a company article, then report any copy that sounds like system notes.
4. Open `Twooter`, interact with at least one public post or message path.
5. Open `Network`, inspect contact/source details, and spend available action points.
6. Open `Life`, check property/car affordance behavior, then return to the desktop.
7. Advance at least three trading days.
8. Save, exit to menu, reload the same slot, and confirm cash, holdings, watchlist, News, Twooter, Network, and Life state still make sense.

## Steam Save And Cloud Flow

1. Use Steam launch for every save/load test.
2. Create or load a save in Slot 1.
3. Advance a day, wait for autosave status to settle, then exit cleanly.
4. Confirm the local save folder contains `slot_1.json`, `slot_1.backup.json`, and `daytrader_save_config.json`.
5. After Steamworks Auto-Cloud is published for App ID `4739020`, confirm Steam uploads those files, then launch from a second machine or clean userdata folder to verify download-before-start behavior.

Windows save folder:

```text
%APPDATA%\Buy High Sell Low Stock Trading Simulator
```

## Steam Stats And Achievements

1. Confirm the Steamworks backend has the exact stat and achievement API names from `docs/STEAM_ACHIEVEMENT_IDS.md`.
2. Start a fresh run from Steam.
3. Place one trade, add one watchlist item, read one News article, and open Stockbot `Key Stats`.
4. Confirm Steam records the matching first-action achievements once the backend is published.
5. Save, reload, and confirm already-earned achievements do not duplicate or regress.

## Performance Watch

Report any repeated stall above one second, especially:

- first `STOCKBOT` company detail selection
- opening News with a dense article list
- Advance Day with several apps open
- save/load after several in-game days

## Report Package

Attach or paste:

- build number
- whether the run was launched from Steam
- Steam App ID `4739020` and Steam build ID if visible
- screenshot or video
- save slot and in-game date
- recent actions before the issue
- relevant save/log files from the Windows save folder

Use [`BUG_REPORT_TEMPLATE.md`](./BUG_REPORT_TEMPLATE.md) for bugs and the general feedback fields at the bottom of that template for playtest notes.

## Exit Criteria

This checklist passes when:

- the build launches from Steam
- Steam overlay opens
- a fresh Normal run reaches day 4 or later
- save, exit, and load works from Steam launch
- no crash, soft-lock, blank critical screen, or save loss occurs
- generated player-facing copy stays in-world and avoids system/debug wording
