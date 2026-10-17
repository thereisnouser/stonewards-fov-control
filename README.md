# FOVPlus

**FOV Plus** is a lightweight, client-side BepInEx 5 plugin that extends the **existing Stonewards FOV slider** from a maximum of 100° to **150°**. It does not add another interface, hotkeys, or a camera override.

## Features

- Uses the game's native **Settings → Game → FOV** slider.
- Preserves the game's own camera behavior and setting persistence.
- No game files modified; no multiplayer-side installation needed.

## Build and install locally

Requires the .NET SDK, Stonewards and a BepInEx 5 r2modman profile:

```powershell
powershell -ExecutionPolicy Bypass -File .\build-and-install.ps1 `
  -GameDir "F:\Steam\steamapps\common\Stonewards" `
  -ProfileDir "C:\Users\user\AppData\Roaming\r2modmanPlus-local\Stonewards\profiles\stonewards-fov-plus"
```

## Prepare Thunderstore v0.1.0

Thunderstore uses a 256×256 PNG icon. This release uses the **selected FOV+ stone-and-brass icon**, not a generated placeholder. Place it at `thunderstore/icon.png` (e.g. by extracting the accompanying release assets ZIP into the repository root).

Build the DLL and create the upload package in one step:

```powershell
powershell -ExecutionPolicy Bypass -File .\package-thunderstore.ps1 `
  -GameDir "F:\Steam\steamapps\common\Stonewards" `
  -ProfileDir "C:\Users\user\AppData\Roaming\r2modmanPlus-local\Stonewards\profiles\stonewards-fov-plus"
```

Output: `dist/FOVPlus-0.1.0.zip`. Upload the resulting ZIP (not the source archive) to the [Stonewards Thunderstore community](https://thunderstore.io/c/stonewards/). The package script checks the icon, version consistency, and archive structure. The compiled DLL requires your local game and BepInEx assemblies.

Package metadata and description: [`thunderstore/`](thunderstore/).

## Implementation

Uses a Harmony postfix on `GameSettingsControllerSO.get_FPSFovMax()` so the vanilla slider accepts higher values. No per-frame camera manipulation.

## Uninstall

Set FOV back to 100° or less before uninstalling so the saved value is valid in the unmodded slider. Remove the plugin via your mod manager.
