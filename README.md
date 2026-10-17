# Stonewards FOVPlus

**Extend Stonewards' built-in field-of-view slider from 100° to 150° without adding another menu.** FOVPlus lets you choose a wider view using the game's original settings.

## ✨ Features

- **Extended FOV range** — increase the native slider's maximum from **100° to 150°**.
- **Native controls** — use Stonewards' existing FOV slider; no new UI, separate controls, or hotkeys.
- **Original camera behavior** — leave the game's normal camera updates and saved FOV setting in place.
- **Lightweight and client-side** — only the player who wants the wider FOV needs to install the mod.

## 🎮 How to use

1. Launch Stonewards with FOVPlus enabled.
2. Open **Settings → Game → FOV**.
3. Use the original slider to select your preferred field of view, up to **150°**.

The mod works automatically. No additional configuration or keybinds are required.

**Before uninstalling:** return the FOV slider to **100° or lower** to keep your saved setting within the unmodded game's range.

## 📦 Installation

### Mod manager

Find **FOVPlus** in the [Stonewards Thunderstore community](https://thunderstore.io/c/stonewards/) and install it with **r2modman** or another compatible Thunderstore mod manager. Launch the game through the selected modded profile. The package declares **BepInExPack 5** as a dependency.

If you installed an older **FOVControl** prototype, disable or uninstall it so two copies do not patch the same game setting.

### Build from source

To build locally, you need the **.NET SDK 8 or newer**, an installed copy of Stonewards, a BepInEx 5 profile, and PowerShell.

Close Stonewards, clone the repository, and run:

```powershell
git clone https://github.com/thereisnouser/stonewards-fov-plus.git
cd stonewards-fov-plus

$gameDir = "C:\path\to\Stonewards"
$profileDir = Join-Path $env:APPDATA "r2modmanPlus-local\Stonewards\profiles\stonewards-fov-plus"

powershell -ExecutionPolicy Bypass -File .\build-and-install.ps1 `
  -GameDir $gameDir `
  -ProfileDir $profileDir
```

Replace the example game path with your installed Stonewards directory. Use your actual r2modman profile folder if it differs.

## 🔧 Compatibility

- **Game:** Stonewards **0.2.3** (the game version used to implement the FOV extension).
- **Mod loader:** BepInEx 5, provided by `BepInEx-BepInExPack-5.4.2305`.
- **Multiplayer:** Client-side; the host and other players do not need FOVPlus to use their own settings normally.

## ⚠️ Known limitations

- Set your FOV to **100° or lower before uninstalling**. Values above the normal maximum may remain in the game's saved settings.
- The patch depends on the game's `GameSettingsControllerSO.get_FPSFovMax()` method. If a later game update changes it, the mod safely leaves the slider unmodified and logs an error.
- Future Stonewards versions have not been verified.

## 🛠️ Development

FOVPlus targets **.NET Standard 2.1** and uses a small Harmony postfix to raise the return value of `GameSettingsControllerSO.get_FPSFovMax()` to at least **150**. It does not update the camera every frame or replace the native settings interface.

The source includes a build/install script and a Thunderstore packaging script. To create the upload archive without installing a new plugin build:

```powershell
powershell -ExecutionPolicy Bypass -File .\package-thunderstore.ps1 `
  -GameDir $gameDir `
  -ProfileDir $profileDir
```

The packaging script checks `thunderstore/manifest.json`, `thunderstore/icon.png` (a 256×256 PNG), the plugin's version, and the ZIP contents. It generates `dist/FOVPlus-<version>.zip` and does not publish it automatically.

## 🔗 Links

[GitHub issues](https://github.com/thereisnouser/stonewards-fov-plus/issues) · [Changelog](thunderstore/CHANGELOG.md) · [Thunderstore community](https://thunderstore.io/c/stonewards/)

---

*Made by thereisnouser*
