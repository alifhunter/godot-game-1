# Steam Build Upload Guide

Use this when shipping a new Windows test build to Steam for App ID `4739020`.

Current IDs:

```text
App ID: 4739020
Windows depot ID: 4739021
Steamworks SDK path: C:\Users\Alif\Documents\SteamworksSDK\steamworks_sdk_164\sdk\tools\ContentBuilder
Test branch: steam_cloud_test
Launch executable: BHSL.exe
```

Do not copy the full Steamworks SDK into this repo. Keep SDK tooling outside the project.

## 1. Export From Godot

1. Open the project in Godot.
2. Use the `Windows Desktop` export preset.
3. Export into a clean temporary folder.
4. Confirm the export contains the game executable and Steam runtime DLLs.
5. For public release candidates, review `docs/RELEASE_LICENSE_AUDIT.md` and include required third-party notices in the shipped folder or an in-game credits/licenses screen.

Public release or release-candidate uploads should contain:

```text
BHSL.exe
EULA.txt
THIRD_PARTY_NOTICES.txt
GODOT_COPYRIGHT.txt
libgodotsteam.windows.template_release.x86_64.dll
steam_api64.dll
```

The current export preset embeds the PCK into the executable. If that changes, include the exported `.pck` beside the executable too.

## 2. Copy Build Files Into ContentBuilder

Copy the exported Windows files plus root release paperwork files into:

```text
C:\Users\Alif\Documents\SteamworksSDK\steamworks_sdk_164\sdk\tools\ContentBuilder\content\windows
```

Expected shape:

```text
ContentBuilder
+-- builder
+-- content
|   +-- windows
|       +-- BHSL.exe
|       +-- EULA.txt
|       +-- THIRD_PARTY_NOTICES.txt
|       +-- GODOT_COPYRIGHT.txt
|       +-- libgodotsteam.windows.template_release.x86_64.dll
|       +-- steam_api64.dll
+-- output
+-- scripts
    +-- app_build_4739020.vdf
    +-- depot_build_windows.vdf
```

## 3. Check SteamPipe VDF Files

`scripts/app_build_4739020.vdf`:

```vdf
"appbuild"
{
    "appid" "4739020"
    "desc" "Windows test build"
    "buildoutput" "..\output\"
    "contentroot" "..\content\"

    "depots"
    {
        "4739021" "depot_build_windows.vdf"
    }
}
```

`scripts/depot_build_windows.vdf`:

```vdf
"DepotBuild"
{
    "DepotID" "4739021"

    "FileMapping"
    {
        "LocalPath" "windows\*"
        "DepotPath" "."
        "recursive" "1"
    }
}
```

Keep `"setlive"` out of the app build file unless the target branch already exists and the uploading account has permission to set builds live. Manual branch assignment in Steamworks is safer.

## 4. Upload With SteamCMD

Open PowerShell:

```powershell
cd "C:\Users\Alif\Documents\SteamworksSDK\steamworks_sdk_164\sdk\tools\ContentBuilder"
.\builder\steamcmd.exe +login YOUR_STEAM_USERNAME +run_app_build ..\scripts\app_build_4739020.vdf +quit
```

Use `..\scripts\app_build_4739020.vdf`, not `.\scripts\...`, because SteamCMD resolves the path from its `builder` folder.

Successful upload should end like:

```text
Successfully finished AppID 4739020 build (BuildID ...)
```

## 5. Set Build Live On A Branch

In Steamworks:

1. Open App `4739020`.
2. Go to `SteamPipe -> Builds`.
3. Find the newest BuildID.
4. Set it live on `steam_cloud_test`.
5. Optionally also set it live on `default` when ready.
6. Preview and confirm the change.

## 6. Confirm Launch Options

If Steam shows `Invalid game configuration`, the launch executable is missing or wrong.

In Steamworks:

1. Go to `Edit Steamworks Settings -> Installation -> General Installation`.
2. Add or confirm the default Windows launch option:

```text
Executable: BHSL.exe
Arguments:
Operating System: Windows
Type: Default
```

3. Save and publish Steamworks configuration changes.
4. Restart the Steam client and try Play again.

## 7. Install And Run From Steam

1. Open the Steam client.
2. Open the game in Library.
3. Use `Properties -> Betas`.
4. Select `steam_cloud_test`.
5. Install or update.
6. Launch from Steam, not by double-clicking the executable.

## 8. Steam Cloud Verification

The Cloud setup uses Auto-Cloud. The game still writes normal local saves through `user://`.

Expected Windows save folder:

```text
%APPDATA%\Buy High Sell Low Stock Trading Simulator
```

Expected files after playing:

```text
daytrader_save_config.json
saves\slot_1.json
saves\slot_1.backup.json
steam_autocloud.vdf
```

Cloud restore test:

1. Launch from Steam.
2. Start or load a run.
3. Advance one day.
4. Exit cleanly.
5. Wait for Steam Cloud sync to finish.
6. Rename:

```text
%APPDATA%\Buy High Sell Low Stock Trading Simulator
```

to:

```text
%APPDATA%\Buy High Sell Low Stock Trading Simulator_backup
```

7. Launch from Steam again.
8. Confirm Steam recreates the folder.
9. Confirm the game detects the restored save.

This passed manually on `2026-05-17` with Steam build `23274942`.

## Common Fixes

`App build file does not exist`:

- Use `..\scripts\app_build_4739020.vdf` when running `.\builder\steamcmd.exe`.
- Do not use `\scripts\...`; that points at the drive root.

`Local mapping ...\content\windows does not exist`:

- Create `ContentBuilder\content\windows`.
- Copy the exported Godot files into that folder.

`Failed to commit build` after chunks upload:

- Remove `"setlive"` from `app_build_4739020.vdf`.
- Upload again.
- Set the build live manually in Steamworks.
- Also confirm depot `4739021` belongs to app `4739020` and the Steam account has upload permissions.

`Invalid game configuration` in Steam client:

- Configure the Windows launch option to `BHSL.exe`.
- Save and publish Steamworks settings.
- Restart Steam.

## After Every New Build

1. Bump visible build metadata if this is a real tester build.
2. Export Windows from Godot.
3. Copy export files into `ContentBuilder\content\windows`.
4. Upload with SteamCMD.
5. Set the new BuildID live on `steam_cloud_test`.
6. Install/update from Steam.
7. Launch from Steam.
8. Confirm the main menu opens and the build label is correct.
9. Confirm save/load still works.
10. For release candidates, repeat the Cloud restore test.
