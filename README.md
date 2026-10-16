# Stonewards FOV Control

A lightweight BepInEx 5 plugin that raises the maximum of Stonewards' **native FOV slider** from **100° to 150°**. No extra UI, hotkeys, or camera override.

## Features

- Uses the existing **Settings → Game → FOV** slider.
- Preserves native camera handling, smooth transitions, and saved settings.
- Works locally without modifying game files or multiplayer behavior.

## Install for development

Requires .NET SDK 8+, Stonewards (Unity Mono), and a BepInEx 5 r2modman profile.

```powershell
powershell -ExecutionPolicy Bypass -File .\build-and-install.ps1 `
  -GameDir "F:\Steam\steamapps\common\Stonewards" `
  -ProfileDir "C:\Users\user\AppData\Roaming\r2modmanPlus-local\Stonewards\profiles\stonewards-fov-control"
```

## Create a Thunderstore upload ZIP

The package command compiles the plugin and creates an upload ZIP containing the DLL, metadata, documentation, and a 256×256 PNG icon. If `thunderstore/icon.png` does not exist, it generates a simple icon automatically.

```powershell
powershell -ExecutionPolicy Bypass -File .\package-thunderstore.ps1 `
  -GameDir "F:\Steam\steamapps\common\Stonewards" `
  -ProfileDir "C:\Users\user\AppData\Roaming\r2modmanPlus-local\Stonewards\profiles\stonewards-fov-control"
```

Upload `dist/FOV_Control-0.1.0.zip` at [Thunderstore](https://thunderstore.io/package/create/), selecting the Stonewards community and your publishing team. Do **not** upload the source archive.

You can replace the auto-generated icon by placing your own `thunderstore/icon.png` (256×256) before running the package command.

## Technical implementation

The Harmony postfix patches `GameSettingsControllerSO.get_FPSFovMax()`. This changes the range supplied to the native slider without overriding the camera. Original FOV value persistence is handled by the game.

## Uninstall

Before uninstalling, set FOV to 100° or lower so the saved value stays inside the vanilla slider range. Remove the plugin from your mod manager profile.

[Thunderstore description](thunderstore/README.md) · [Changelog](thunderstore/CHANGELOG.md)
