# HavenMoonVR 1.2.0 Community Patch

Created by Massimo Giannelli using ChatGPT in Florence, Italy.

## Community release

This is an unofficial rough-and-ready community patch, supplied as-is. It installs directly on a supported unmodified Steam copy of Haven Moon; no previous HavenMoonVR version is required.

- Cinematic Shaders v1 forces full-resolution textures, 16x anisotropic filtering, 8x MSAA plus FXAA ExtremeQuality, very high shadows and extended object/terrain LOD. The Normal profile is enhanced with high-sample ambient occlusion, HDR bloom and ACES colour grading.
- Water4 is upgraded from LOD 200 to the richer LOD 300 pass. Its stereo-unsafe LOD 500 screen GrabPass remains capped out together with planar reflection and edge blend.
- Quest 2 Native Aim v3 obtains each pointer's `openxr_aim` transform through SteamVR's input-source-aware render-model API for `/user/hand/left` and `/user/hand/right`. It contains no manually chosen angle or origin offset; `tip`, the legacy component call and the raw pose remain compatibility fallbacks.
- Installation now begins with a Steam registration choice. Automatic mode closes Steam, manages the VR-library shortcut and reopens Steam at the end; manual mode leaves Steam open and does not touch `shortcuts.vdf`.
- The choice is remembered for uninstall: automatically managed shortcuts are removed automatically, while manually created entries remain under the user's control.
- Includes reformatted Steam library artwork: 600×900 Capsule, 920×430 Header, 3840×1240 text-free Hero, transparent 720×720 Logo and a 1920×1080 SteamVR fallback background. Automatic mode installs the AppID-named Steam files; manual mode installs the source assets beside the game.
- Includes a custom launcher icon optimized for 16–256 pixels. The multi-resolution ICO is embedded in `Haven Moon VR.exe`; automatic registration also installs its 256×256 PNG as the Steam/SteamVR AppID icon.
- Collision Fix v2 withdraws the over-conservative bilateral sweep used by test v1. It replaces Haven Moon's two identical `CharacterController.Move` calls with one continuous move at the same total speed and horizontally centres the body capsule below the tracked HMD camera.
- Collision Fix v1 is superseded because it stopped too early on one side and too late on the other.
- Disables Haven Moon's legacy `GlobalFog` and `GlobalFogWATER` full-screen camera filters in the community VR runtime. These filters reconstruct a single desktop frustum and can leave a black wedge when the two-eye SteamVR view is rolled.
- Keeps Unity's native scene fog and uses Water4's richer stereo-safe LOD 300 path.
- Removes the bundled SteamVR resolution configurator. Quest 2 testing at 90 Hz confirmed that 150% could produce intermittent dropped frames and image doubling; the package leaves the user's SteamVR setting untouched and recommends 100% as the stable starting point.
- Adds a fast file-version cache. The first run performs full SHA-256 checks; later unchanged runs use file size and NTFS timestamps, while any changed metadata triggers a full hash and repairs only the affected file. `Verify_Installation.cmd` always performs full SHA-256 verification.
- In-headset testing confirmed that the black wedge no longer appears during headset roll.

## 1.2.0 hotfix

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
- FXAA ExtremeQuality. SteamVR per-application render resolution is left untouched.

## Safety and rollback

The stable 1.0.2 package remains untouched. The community uninstaller restores the verified clean game files, removes only the community runtime/shortcut, and retains the clean backup. Reinstall 1.0.2 afterward to return to the stable mod.
