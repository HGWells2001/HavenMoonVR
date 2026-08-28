# HavenMoonVR 1.2.6 Community Patch

## 1.2.6 Water Enhanced VR

- Keeps every `WaterTile.reflection` disconnected and every corresponding `PlanarReflection` component disabled.
- Applies a small, runtime-only Water4 material adjustment: Fresnel 0.25, a restrained blue reflection tint, shininess 45 and foam intensity of at least 0.24.
- Uses trilinear filtering and 8x anisotropic filtering for the Water4 normal and shoreline textures only.
- Does not change Gerstner wave geometry, screen GrabPass, shoreline blending, GlobalFog, post-processing, anti-aliasing or non-water materials.
- Retains the graphical installer's automatic **Uninstall** detection and all VR interaction/collision changes.

Created by Massimo Giannelli using ChatGPT in Florence, Italy.

## 1.2.5 ocean planar-reflection removal

- Disconnects every `WaterTile.reflection` reference and disables the corresponding `PlanarReflection` component at runtime.
- Removes reflected sky, clouds and scene objects from the ocean.
- Keeps the original Water4 quality, waves, screen GrabPass, shoreline blending, GlobalFog, post-processing and anti-aliasing.
- Retains the graphical installer's automatic **Uninstall** detection and all VR interaction/collision changes.

Created by Massimo Giannelli using ChatGPT in Florence, Italy.

## 1.2.4 ocean cloud-reflection adjustment

- Disables only `UnityStandardAssets.Water.PlanarReflection.reflectSkybox` at runtime.
- Keeps planar reflection active for scene geometry and preserves the original Water4 quality, screen GrabPass, shoreline blending, GlobalFog, post-processing and anti-aliasing.
- Retains the graphical installer's automatic **Uninstall** detection and all VR interaction/collision changes from 1.2.3.
- Requires an in-headset ocean scene test: if the visible clouds are separate geometry instead of skybox content in a particular scene, they may still be included by the original reflection mask.

Created by Massimo Giannelli using ChatGPT in Florence, Italy.

## 1.2.3 complete original graphics

- Removes every runtime water, fog and post-processing override from the VR patch.
- Leaves Haven Moon's original Water4 quality selection, planar reflection, screen GrabPass, shoreline edge blending, `GlobalFog`, `GlobalFogWATER`, post-processing and anti-aliasing untouched.
- Removes the F10 Enhanced/Safe Water toggle because the patch no longer manages water quality.
- Retains dual controller pointers, Quest 2 native aim, trigger reliability, head-relative locomotion, height correction, Collision Fix v2 and the incremental installer.
- The graphical Setup detects a patch in the selected Haven Moon folder and enables **Uninstall**; the button is activated immediately after installation succeeds.
- The original black horizon wedge or other stereo artefacts may return; version 1.2.2 remains available as the VR-safe alternative.

Created by Massimo Giannelli using ChatGPT in Florence, Italy.

## 1.2.2 water restoration

- Restores Water4's richer LOD 300 shader and depth-based shoreline edge blending.
- Retains the stereo-safe exclusions: LOD 500 screen GrabPass, planar reflection, `GlobalFog` and `GlobalFogWATER` remain disabled.
- Adds F10 to switch instantly between Enhanced Water LOD 300 and Safe Water LOD 200; the choice is remembered.
- Keeps Haven Moon's original post-processing and quality profile, without the withdrawn cinematic overrides.

Created by Massimo Giannelli using ChatGPT in Florence, Italy.

## Community release

This is an unofficial rough-and-ready community patch, supplied as-is. It installs directly on a supported unmodified Steam copy of Haven Moon; no previous HavenMoonVR version is required.

- Version 1.2.2 removes the forced cinematic rendering profile and restores the original Haven Moon post-processing, anti-aliasing and quality settings.
- Water4 defaults to LOD 300 with shoreline edge blending; its stereo-unsafe LOD 500 screen GrabPass and planar reflection remain disabled.
- Quest 2 Native Aim v3 obtains each pointer's `openxr_aim` transform through SteamVR's input-source-aware render-model API for `/user/hand/left` and `/user/hand/right`. It contains no manually chosen angle or origin offset; `tip`, the legacy component call and the raw pose remain compatibility fallbacks.
- Installation begins with a Steam registration choice. Automatic mode closes Haven Moon, SteamVR and Steam, manages the VR-library shortcut and reopens Steam at the end; manual mode leaves Steam open and does not touch `shortcuts.vdf`.
- The choice is remembered for uninstall: automatically managed shortcuts are removed automatically, while manually created entries remain under the user's control.
- Includes reformatted Steam library artwork: 600×900 Capsule, 920×430 Header, 3840×1240 text-free Hero, transparent 720×720 Logo and a 1920×1080 SteamVR fallback background. Automatic mode installs the AppID-named Steam files; manual mode installs the source assets beside the game.
- Includes a custom launcher icon optimized for 16–256 pixels. The multi-resolution ICO is embedded in `Haven Moon VR.exe`; automatic registration also installs its 256×256 PNG as the Steam/SteamVR AppID icon.
- Collision Fix v2 withdraws the over-conservative bilateral sweep used by test v1. It replaces Haven Moon's two identical `CharacterController.Move` calls with one continuous move at the same total speed and horizontally centres the body capsule below the tracked HMD camera.
- Collision Fix v1 is superseded because it stopped too early on one side and too late on the other.
- Disables Haven Moon's legacy `GlobalFog` and `GlobalFogWATER` full-screen camera filters in the community VR runtime. These filters reconstruct a single desktop frustum and can leave a black wedge when the two-eye SteamVR view is rolled.
- Keeps Unity's native scene fog and provides the F10 Safe Water LOD 200 fallback.
- Removes the bundled SteamVR resolution configurator. Quest 2 testing at 90 Hz confirmed that 150% could produce intermittent dropped frames and image doubling; the package leaves the user's SteamVR setting untouched and recommends 100% as the stable starting point.
- Adds a fast file-version cache. The first run performs full SHA-256 checks; later unchanged runs use file size and NTFS timestamps, while any changed metadata triggers a full hash and repairs only the affected file. `Verify_Installation.cmd` always performs full SHA-256 verification.
- In-headset testing confirmed that the black wedge no longer appears during headset roll.

## 1.2.2 visual-profile hotfix

- Removes ACES colour grading, forced bloom and ambient occlusion, 8x MSAA, forced anisotropic filtering, ultra shadows and extended texture/scene LOD overrides.
- Restores `sharedassets1.assets` from the verified clean backup when upgrading from 1.2.0, while leaving unrelated current files untouched.
- Retains Horizon Fix v3, controller pointers, collision correction, camera-height correction, Steam registration and artwork.

## 1.2.0 interaction and installer changes

- Incremental Installer v4 checks every generated game patch and community runtime file by SHA-256. Only missing, different or outdated files are written; already-current files and their modification times remain untouched.
- Verified clean backups are checked independently instead of being restored over every live file during a normal update. The local icon-enabled launcher is rebuilt only when its source inputs have changed.
- Trigger Fix v3 synchronizes the shared left/right action flags with the hysteresis-latched Fire2/Fire1 state, adds a three-frame release allowance and remembers the recent target for 0.18 seconds.
- Horizon Fix v2 disconnects the legacy planar-reflection pass, selects the low non-reflective Water4 shader and disables screen-space edge blending. It simplified the water but did not remove the wedge on every headset.
- The launcher embeds the icon from the user's local `HavenMoon.exe`, remains AnyCPU and explicitly starts 64-bit Windows PowerShell for SteamVR's OpenVR DLL.
- Controller rays now remain visible in a dim state whenever SteamVR provides valid poses.
- Valid interactable targets brighten the corresponding ray and display its surface dot.
- Height recenter now compensates Haven Moon's existing 0.683 m camera offset instead of counting it twice.
- The resulting default eye height matches the original game camera; F7/F9 can still tune it.
- F7/F9 provide persistent 5 cm camera-height adjustments; F8/Y reapplies the saved height.
- Controller-interaction state now safely restores movement when tracking is unavailable.

## Added

- Independent tracked left/right controller rays.
- Per-hand surface hit dots and thin interaction rays.
- Per-hand activation while retaining Fire1/Fire2 compatibility.
- Dedicated community launcher and Steam VR-library shortcut.
- Local shared-memory transport between the OpenVR bridge and Unity runtime.

## Preserved from the stable line

- Steam build and SHA-256 guards.
- Clean backup/restore workflow.
- SteamVR OpenVR setup.
- Head-relative locomotion and right-stick turning.
- VR Origin and automatic/manual height recenter.
- The original Haven Moon visual profile. SteamVR per-application render resolution is left untouched.

## Safety and rollback

The stable 1.0.2 package remains untouched. The community uninstaller restores the verified clean game files, removes only the community runtime/shortcut, and retains the clean backup. Reinstall 1.0.2 afterward to return to the stable mod.
