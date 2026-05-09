# Steam Cloud Save Path Notes

Status: prep only. Configure this in Steamworks after the real App ID exists.

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

## Windows Auto-Cloud Mapping

Current Early Access target is Windows. Godot globalizes `user://` under the app userdata folder. With the current Windows-safe project name, expect the path to be:

```text
%APPDATA%\Godot\app_userdata\Buy High Sell Low Stock Trading Simulator
```

Recommended Steam Auto-Cloud entries:

| Root | Subdirectory | Pattern | Recursive | OS |
| --- | --- | --- | --- | --- |
| `WinAppDataRoaming` | `Godot/app_userdata/Buy High Sell Low Stock Trading Simulator/saves` | `*.json` | No | Windows |
| `WinAppDataRoaming` | `Godot/app_userdata/Buy High Sell Low Stock Trading Simulator` | `daytrader_save_config.json` | No | Windows |
| `WinAppDataRoaming` | `Godot/app_userdata/Buy High Sell Low Stock Trading Simulator` | `daytrader_save*.json` | No | Windows |

Do not use a broad `*` pattern at the userdata root unless we intentionally want to sync unrelated future files.

## Initial Quota Recommendation

Recent smoke saves are roughly `0.5 MB` to `4.3 MB` per slot file. A full player profile can include 5 primary saves plus backups.

Recommended Early Access Steam Cloud settings:

```text
Byte quota per user: 134217728
Number of files allowed per user: 64
```

That is `128 MiB` and `64` files, leaving room for five save slots, backups, config, legacy migration files, and modest future growth.

## Test Checklist

1. Enable Steam Cloud for the real App ID.
2. Configure Auto-Cloud with the Windows entries above.
3. Publish Steamworks settings.
4. Use developer-only Cloud support until the behavior is verified.
5. Launch the Steam build from Steam.
6. Create or load a run, advance a day, and exit cleanly.
7. Confirm Steam uploads `slot_*.json`, `slot_*.backup.json`, and `daytrader_save_config.json`.
8. Install on a second machine or clear local userdata, then launch from Steam and confirm saves download before the game starts.
9. Confirm unreadable/corrupt primary save recovery still uses the backup after Cloud sync.

## Later Cross-Platform Note

If Linux or macOS builds are added, do not create totally separate platform-only roots unless platform-isolated saves are intended. Steam's docs recommend root overrides when the same save files should roam across platforms.
