using System;
using BepInEx;
using BepInEx.Configuration;
using UnityEngine;
using UnityEngine.Rendering;

namespace StonewardsFOVControl
{
    [BepInPlugin(PluginGuid, PluginName, PluginVersion)]
    public sealed class FovControlPlugin : BaseUnityPlugin
    {
        private const string PluginGuid = "com.stonewardsmods.fovcontrol";
        private const string PluginName = "Stonewards FOV Control";
        private const string PluginVersion = "0.1.0";

        private const int MinimumFov = 60;
        private const int MaximumFov = 150;
        private const float FovComparisonTolerance = 0.05f;

        private ConfigEntry<bool> _enabled;
        private ConfigEntry<int> _fieldOfView;
        private ConfigEntry<bool> _preserveZoom;
        private ConfigEntry<int> _keyStep;
        private ConfigEntry<KeyboardShortcut> _toggleKey;
        private ConfigEntry<KeyboardShortcut> _increaseKey;
        private ConfigEntry<KeyboardShortcut> _decreaseKey;

        private Camera _gameCamera;
        private float _baselineFov;
        private float _lastGameFov;
        private float _lastAppliedFov;
        private float _nextCameraScan;
        private bool _hasCameraSample;

        private void Awake()
        {
            _enabled = Config.Bind(
                "General", "Enabled", true,
                "Enable FOV override. The original camera FOV is restored when disabled.");

            _fieldOfView = Config.Bind(
                "General", "FieldOfView", 100,
                new ConfigDescription(
                    "Target vertical field of view, in degrees. Horizontal FOV depends on aspect ratio.",
                    new AcceptableValueRange<int>(MinimumFov, MaximumFov)));

            _preserveZoom = Config.Bind(
                "General", "PreserveZoom", true,
                "Preserve the game's relative zoom and sprint FOV effects instead of forcing a fixed FOV. " +
                "The camera's first observed FOV is used as the unzoomed baseline.");

            _keyStep = Config.Bind(
                "Hotkeys", "Step", 5,
                new ConfigDescription(
                    "Number of degrees changed by the increase/decrease shortcuts.",
                    new AcceptableValueRange<int>(1, 20)));

            _toggleKey = Config.Bind(
                "Hotkeys", "Toggle", new KeyboardShortcut(KeyCode.F8),
                "Toggle FOV Control on/off.");

            _increaseKey = Config.Bind(
                "Hotkeys", "Increase", new KeyboardShortcut(KeyCode.PageUp),
                "Increase the target FOV.");

            _decreaseKey = Config.Bind(
                "Hotkeys", "Decrease", new KeyboardShortcut(KeyCode.PageDown),
                "Decrease the target FOV.");

            _enabled.SettingChanged += OnEnabledChanged;
            Camera.onPreCull += OnCameraPreCull;
            RenderPipelineManager.beginCameraRendering += OnBeginCameraRendering;

            Logger.LogInfo("Stonewards FOV Control 0.1.0 loaded (F8: toggle, Page Up/Down: adjust).");
        }

        private void Update()
        {
            if (Time.unscaledTime >= _nextCameraScan || _gameCamera == null)
            {
                _nextCameraScan = Time.unscaledTime + 0.5f;
                SelectGameCamera();
            }

            if (_toggleKey.Value.IsDown())
            {
                _enabled.Value = !_enabled.Value;
                Logger.LogInfo("FOV override " + (_enabled.Value ? "enabled" : "disabled") + ".");
            }

            if (!_enabled.Value)
                return;

            if (_increaseKey.Value.IsDown())
                AdjustFov(_keyStep.Value);
            else if (_decreaseKey.Value.IsDown())
                AdjustFov(-_keyStep.Value);
        }

        private void LateUpdate()
        {
            // Common case: override the game camera after regular camera updates.
            // The render callbacks below also cover late camera-controller writes.
            ApplyFieldOfView(_gameCamera);
        }

        private void OnCameraPreCull(Camera camera)
        {
            ApplyFieldOfView(camera);
        }

        private void OnBeginCameraRendering(ScriptableRenderContext context, Camera camera)
        {
            ApplyFieldOfView(camera);
        }

        private void SelectGameCamera()
        {
            Camera selected = Camera.main;

            if (!IsUsableGameCamera(selected))
            {
                selected = null;
                Camera[] cameras = Camera.allCameras;
                Camera bestFallback = null;

                for (int i = 0; i < cameras.Length; i++)
                {
                    Camera candidate = cameras[i];
                    if (!IsUsableGameCamera(candidate))
                        continue;

                    AudioListener listener = candidate.GetComponent<AudioListener>();
                    if (listener != null && listener.enabled)
                    {
                        selected = candidate;
                        break;
                    }

                    // Prefer the world camera to a high-depth weapon/UI overlay.
                    // A render-texture target is valid for the primary camera (pixelation).
                    if (bestFallback == null
                        || (bestFallback.targetTexture != null && candidate.targetTexture == null)
                        || (bestFallback.targetTexture == candidate.targetTexture
                            && candidate.depth < bestFallback.depth))
                        bestFallback = candidate;
                }

                if (selected == null)
                    selected = bestFallback;
            }

            if (_gameCamera == selected)
                return;

            RestoreCamera();
            _gameCamera = selected;
            _hasCameraSample = false;

            if (_gameCamera != null)
                Logger.LogInfo("Selected camera: " + _gameCamera.name);
        }

        private static bool IsUsableGameCamera(Camera camera)
        {
            return camera != null
                   && camera.isActiveAndEnabled
                   && !camera.orthographic
                   && camera.cameraType == CameraType.Game;
        }

        private void ApplyFieldOfView(Camera camera)
        {
            if (!_enabled.Value || camera == null || camera != _gameCamera || !IsUsableGameCamera(camera))
                return;

            float observedFov = camera.fieldOfView;
            if (float.IsNaN(observedFov) || float.IsInfinity(observedFov)
                || observedFov <= 1f || observedFov >= 179f)
                return;

            if (!_hasCameraSample)
            {
                _baselineFov = observedFov;
                _lastGameFov = observedFov;
                _hasCameraSample = true;
                Logger.LogInfo("Camera baseline vertical FOV: " + _baselineFov.ToString("F1") + " degrees.");
            }
            else if (Mathf.Abs(observedFov - _lastAppliedFov) > FovComparisonTolerance)
            {
                // The game changed the FOV since our last write (e.g. zoom/sprint).
                // Keep that value so we can restore it when the override is disabled.
                _lastGameFov = observedFov;
            }

            float targetFov = _fieldOfView.Value;

            if (_preserveZoom.Value && _baselineFov > 1f)
            {
                // Scale tan(half-FOV) to preserve the original zoom factor.
                float gameHalfAngle = _lastGameFov * Mathf.Deg2Rad * 0.5f;
                float baselineHalfAngle = _baselineFov * Mathf.Deg2Rad * 0.5f;
                float desiredHalfAngle = targetFov * Mathf.Deg2Rad * 0.5f;
                float zoomFactor = Mathf.Tan(gameHalfAngle) / Mathf.Tan(baselineHalfAngle);
                targetFov = Mathf.Atan(Mathf.Tan(desiredHalfAngle) * zoomFactor)
                            * Mathf.Rad2Deg * 2f;
            }

            targetFov = Mathf.Clamp(targetFov, 20f, MaximumFov);
            camera.fieldOfView = targetFov;
            _lastAppliedFov = targetFov;
        }

        private void AdjustFov(int difference)
        {
            int value = Mathf.Clamp(_fieldOfView.Value + difference, MinimumFov, MaximumFov);
            if (value == _fieldOfView.Value)
                return;

            _fieldOfView.Value = value;
            Logger.LogInfo("Target vertical FOV: " + value + " degrees.");
        }

        private void OnEnabledChanged(object sender, EventArgs args)
        {
            if (!_enabled.Value)
                RestoreCamera();
            else
                _hasCameraSample = false;
        }

        private void RestoreCamera()
        {
            if (_gameCamera != null && _hasCameraSample)
                _gameCamera.fieldOfView = _lastGameFov;

            _hasCameraSample = false;
        }

        private void OnDestroy()
        {
            Camera.onPreCull -= OnCameraPreCull;
            RenderPipelineManager.beginCameraRendering -= OnBeginCameraRendering;
            _enabled.SettingChanged -= OnEnabledChanged;
            RestoreCamera();
        }
    }
}
