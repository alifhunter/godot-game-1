# Steam Cloud Save Path Notes

Status: verified on Windows for Steam App ID `4739020`. Steam build `23274942` restored a renamed local save folder from Cloud, and the game detected the restored save.

The game should keep writing normal local saves through `SaveManager.gd`. Steam Auto-Cloud should sync those files before launch and after exit, so the first implementation does not need manual Remote Storage API calls.

Official reference:
- Steam Cloud: https://partner.steamgames.com/doc/features/cloud

## Current Game Save Files

`SaveManager.gd` currently writes player saves to Godot `user://`.

Modern save files:

```text
user://saves/slot_1.json
user://saves/slot_1.backup.json
user://saves/slot_2.json
user://saves/slot_2.backup.json
user://saves/slot_3.json
user://saves/slot_3.backup.json
user://saves/slot_4.json
user://saves/slot_4.backup.json
user://saves/slot_5.json
user://saves/slot_5.backup.json
```

Save config:

```text
user://daytrader_save_config.json
```

Legacy compatibility files still read for old saves:

```text
user://daytrader_save.json
user://daytrader_save.backup.json
```

Temporary files should not be synced:

```text
user://saves/*.tmp
```

Smoke-test files under `res://logs/` are local test artifacts and should not be synced.

## Steamworks Auto-Cloud Setup

In Steamworks for App ID `4739020`:

1. Open `Steamworks Settings`.
2. Go to `Application -> Steam Cloud`.
3. Enable Steam Cloud.
4. Prefer Auto-Cloud for this first pass.
5. Set the quota:

```text
Byte quota per user: 134217728
Number of files allowed per user: 64
```

6. Add the Windows Auto-Cloud mappings below.
7. Save and publish Steamworks changes.
8. Keep developer-only Cloud testing enabled for future path changes until a clean Cloud restore pass succeeds.

## Windows Auto-Cloud Mapping

Current Early Access target is Windows. The project enables Godot's custom user directory:

```ini
config/use_custom_user_dir=true
config/custom_user_dir_name="Buy High Sell Low Stock Trading Simulator"
```

With that setting, Godot globalizes `user://` to:

```text
%APPDATA%\Buy High Sell Low Stock Trading Simulator
```

Recommended Steam Auto-Cloud entries:

| Root | Subdirectory | Pattern | Recursive | OS |
| --- | --- | --- | --- | --- |
| `WinAppDataRoaming` | `Buy High Sell Low Stock Trading Simulator/saves` | `*.json` | No | Windows |
| `WinAppDataRoaming` | `Buy High Sell Low Stock Trading Simulator` | `daytrader_save_config.json` | No | Windows |
| `WinAppDataRoaming` | `Buy High Sell Low Stock Trading Simulator` | `daytrader_save*.json` | No | Windows |

Do not use a broad `*` pattern at the userdata root unless we intentionally want to sync unrelated future files.

Legacy local development saves from before the custom user directory setting may still exist under:

```text
%APPDATA%\Godot\app_userdata\Buy High Sell Low Stock Trading Simulator
```

Do not add that old path to public Cloud settings unless we need a one-time migration branch for testers who already received builds before the custom user directory change.

## Initial Quota Rationale

Recent smoke saves are roughly `0.5 MB` to `4.3 MB` per slot file. A full player profile can include 5 primary saves plus backups.

Recommended Early Access Steam Cloud settings:

```text
Byte quota per user: 134217728
Number of files allowed per user: 64
```

That is `128 MiB` and `64` files, leaving room for five save slots, backups, config, legacy migration files, and modest future growth.

## Test Checklist

1. Enable Steam Cloud for App ID `4739020`.
2. Configure Auto-Cloud with the Windows entries above.
3. Publish Steamworks settings.
4. Use developer-only Cloud support for new branches or path changes until the behavior is verified.
5. Launch the Steam build from Steam, not from the Godot editor or a direct executable shortcut.
6. Create or load a run, advance a day, and exit cleanly.
7. Confirm Steam uploads `slot_*.json`, `slot_*.backup.json`, and `daytrader_save_config.json`.
8. Install on a second machine or clear `%APPDATA%\Buy High Sell Low Stock Trading Simulator`, then launch from Steam and confirm saves download before the game starts.
9. Confirm unreadable/corrupt primary save recovery still uses the backup after Cloud sync.

Steam Console pre-release helper:

```text
steam://open/console
testappcloudpaths 4739020
set_spew_level 4 4
```

After testing:

```text
testappcloudpaths 0
set_spew_level 0 0
```

Disable developer-only mode and publish the final Cloud changes when a release-candidate sync pass is complete.

## Verified Result

Manual Windows Steam-client verification passed on `2026-05-17`:

1. Steam build `23274942` was uploaded for App ID `4739020` / depot `4739021`.
2. The build was set live on `steam_cloud_test` and `default`.
3. Steam launch initially failed until the Windows launch option was set to `BHSL.exe`.
4. The game launched from Steam and created saves under `%APPDATA%\Buy High Sell Low Stock Trading Simulator`.
5. Steam created `steam_autocloud.vdf` in the save folder.
6. The local save folder was renamed to `Buy High Sell Low Stock Trading Simulator_backup`.
7. Launching from Steam recreated the save folder from Cloud.
8. The game detected the restored save.

## Later Cross-Platform Note

If Linux or macOS builds are added, do not create totally separate platform-only roots unless platform-isolated saves are intended. Steam's docs recommend root overrides when the same save files should roam across platforms.
