# Stonewards FOV Control

A lightweight, client-side BepInEx 5 plugin for Stonewards that allows a wider field of view (up to 150 degrees vertically).

## Features

- Adjustable **vertical FOV: 60–150°**, default **100°**.
- **F8** toggles the override; **Page Up / Page Down** increase/decrease the FOV by 5 degrees.
- Automatically saves settings to BepInEx config.
- Optional relative zoom preservation for aiming, sprinting, and other FOV changes (enabled by default).
- Supports built-in and scriptable render pipelines.
- Works with the optional [ModSettings](https://thunderstore.io/c/stonewards/p/darkharasho/ModSettings/) in-game mod settings menu via standard `Config.Bind` options.
- No dependencies on game-specific classes or gameplay/network state.

## Build and install

Requirements: .NET SDK 8+; Windows PowerShell; Stonewards (Unity Mono); a BepInEx 5 r2modman profile.

Run from the project folder:

```powershell
powershell -ExecutionPolicy Bypass -File .\build-and-install.ps1 `
  -GameDir "F:\Steam\steamapps\common\Stonewards" `
  -ProfileDir "C:\Users\user\AppData\Roaming\r2modmanPlus-local\Stonewards\profiles\stonewards"
```

The compiled plugin is copied to:

```
<ProfileDir>\BepInEx\plugins\StonewardsFOVControl\StonewardsFOVControl.dll
```

**Launch the game through the same r2modman profile** after installation.

## Settings

Configuration is generated after the first game launch:

```
<ProfileDir>\BepInEx\config\com.stonewardsmods.fovcontrol.cfg
```

| Section | Key | Default | Description |
| --- | --- | --- | --- |
| General | Enabled | true | Apply or disable the override |
| General | FieldOfView | 100 | Vertical FOV, 60–150° |
| General | PreserveZoom | true | Preserve relative zoom effects |
| Hotkeys | Step | 5 | FOV change per hotkey, 1–20° |
| Hotkeys | Toggle | F8 | Toggle the override |
| Hotkeys | Increase | PageUp | Increase FOV |
| Hotkeys | Decrease | PageDown | Decrease FOV |

Unity's `Camera.fieldOfView` is **vertical** FOV. At 16:9, 100° vertical is substantially wider than 100° horizontal.

If zoom feels too weak or too strong, turn off `PreserveZoom` to use a fixed FOV. With zoom preservation enabled, the first FOV observed for a camera becomes its baseline; start playing with the normal, unzoomed camera.

## Technical approach

The plugin chooses `Camera.main` (falling back to an active perspective game camera), changes its `fieldOfView` in `LateUpdate`, and reapplies it in pre-render callbacks. This is meant to handle camera components that rewrite FOV each frame, without patching a specific version of `Assembly-CSharp.dll`.

Since this initial release has not been validated in a running Stonewards 0.2.3 session, please test the main camera, aiming, sprinting, respawning, map transitions, and exiting to the menu. If the game uses a different camera controller or an unusual multi-camera setup, it may require a game-specific patch.

## Uninstall

```powershell
powershell -ExecutionPolicy Bypass -File .\uninstall.ps1 `
  -ProfileDir "C:\Users\user\AppData\Roaming\r2modmanPlus-local\Stonewards\profiles\stonewards"
```

The config file is deliberately preserved.
