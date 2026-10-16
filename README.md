# Stonewards FOV Control

A small, client-side BepInEx 5 plugin that extends the **existing Stonewards FOV slider** from **60–100° to 60–150°**. No extra interface, camera override, or hotkeys.

## How it works

- Preserves the game's native **Settings → Game → FOV** control.
- Uses Harmony to raise the value returned by `GameSettingsControllerSO.get_FPSFovMax()`.
- The game's own `GameTabSettings.InitFpsFovSlider()` reads that maximum and updates its SliderInt range.
- The game's existing `OnFPSFovSliderValueChanged()` handler saves the setting to `Saves/Local/settings.es3` and updates `FPSCameraController`'s Cinemachine camera.
- Keeps the default 60° minimum and the game's own FOV transitions and sprint handling.
- Does not modify the executable or affect networking/gameplay.

The patch targets the setting itself rather than forcing `Camera.fieldOfView` each frame. Verified against the methods in a Stonewards **October 13, 2026** `Assembly-CSharp.dll`; actual in-game behavior still needs testing.

## Build and install

Requires .NET SDK 8+, Stonewards (Unity Mono), and BepInEx 5 via r2modman.

Clone the repository and run this from its root in PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\build-and-install.ps1 `
  -GameDir "F:\Steam\steamapps\common\Stonewards" `
  -ProfileDir "C:\Users\user\AppData\Roaming\r2modmanPlus-local\Stonewards\profiles\stonewards"
```

The installer builds `StonewardsFOVControl.dll` and copies it to `<ProfileDir>\BepInEx\plugins\StonewardsFOVControl\`.

Launch the game through the **same** r2modman profile, open the normal **Game** settings tab, and adjust the original FOV slider (up to 150°). Restart the game after updating from v0.1.0.

The plugin requires `BepInEx.dll` and `0Harmony.dll` from the profile, plus Unity assemblies from the game. No `Assembly-CSharp.dll` reference is required for compilation.

## Uninstall

```powershell
powershell -ExecutionPolicy Bypass -File .\uninstall.ps1 `
  -ProfileDir "C:\Users\user\AppData\Roaming\r2modmanPlus-local\Stonewards\profiles\stonewards"
```

The game's saved FOV value is **not** automatically reset when uninstalling the mod. Before uninstalling, use the in-game slider to select 100° or lower so the vanilla menu can display the value correctly.

## Notes

- This mod intentionally only changes the maximum shown by the native slider. It does **not** add a separate FOV config or hotkeys.
- The minimum remains 60°; the maximum is 150°.
- If the game changes its settings controller, the plugin reports an error in the BepInEx log rather than patching an unrelated method.
- Build and gameplay tests have not been run in this repository environment.
