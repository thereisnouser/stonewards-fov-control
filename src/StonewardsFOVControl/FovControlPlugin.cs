using System;
using System.Reflection;
using BepInEx;
using HarmonyLib;

namespace StonewardsFOVControl
{
    [BepInPlugin(PluginGuid, PluginName, PluginVersion)]
    public sealed class FovControlPlugin : BaseUnityPlugin
    {
        private const string PluginGuid = "com.stonewardsmods.fovcontrol";
        private const string PluginName = "Stonewards FOV Control";
        private const string PluginVersion = "0.1.0";

        // Stonewards 0.2.3 normally exposes a 60–100 degree SliderInt.
        // The original value is stored in GameSettingsData.fpsFOV and applied
        // to the Cinemachine camera by FPSCameraController without further clamping.
        private const int ExtendedMaximumFov = 150;

        private Harmony _harmony;

        private void Awake()
        {
            Type settingsType = AccessTools.TypeByName("GameSettingsControllerSO");
            MethodInfo getter = settingsType == null
                ? null
                : AccessTools.Method(settingsType, "get_FPSFovMax");

            // Fail safely if the game changes its settings implementation.
            if (getter == null ||
                getter.ReturnType != typeof(int) ||
                getter.GetParameters().Length != 0)
            {
                Logger.LogError("Could not find GameSettingsControllerSO.get_FPSFovMax(). " +
                    "The game's FOV slider will not be modified.");
                return;
            }

            try
            {
                MethodInfo postfix = typeof(FovControlPlugin).GetMethod(
                    nameof(ExtendFovSliderRange),
                    BindingFlags.NonPublic | BindingFlags.Static);

                _harmony = new Harmony(PluginGuid);
                _harmony.Patch(getter, postfix: new HarmonyMethod(postfix));

                Logger.LogInfo("Native FOV slider maximum extended to " +
                    ExtendedMaximumFov + " degrees.");
            }
            catch (Exception ex)
            {
                Logger.LogError("Failed to patch the native FOV slider: " + ex);
            }
        }

        private static void ExtendFovSliderRange(ref int __result)
        {
            // Do not reduce the game's maximum if a future update raises it.
            if (__result < ExtendedMaximumFov)
                __result = ExtendedMaximumFov;
        }

        private void OnDestroy()
        {
            if (_harmony != null)
                _harmony.UnpatchSelf();
        }
    }
}
