# HavenMoonVR 1.2.0 Community Patch

Created by Massimo Giannelli using ChatGPT in Florence, Italy.

## 1.2.0 Community Patch

- Added Cinematic Shaders v1. It forces the original materials to their highest available safe LOD, 16x anisotropic filtering, full-resolution textures, 8x MSAA plus FXAA ExtremeQuality, ultra shadows and long terrain/detail LODs. The game's Normal post-processing profile is enhanced with high-sample ambient occlusion, HDR bloom and ACES colour grading.
- Upgraded the ocean from Water4 LOD 200 to its richer LOD 300 pass. The LOD 500 screen GrabPass, planar reflection and edge blend remain disabled because those legacy screen-space paths are not stereo-safe.
- Added Quest 2 Native Aim v3: each controller ray resolves `openxr_aim` through SteamVR's input-source-aware render-model API using `/user/hand/left` and `/user/hand/right`, matching Valve's current integration. There is no hard-coded angle or offset; `tip`, the legacy API and finally the raw pose are compatibility fallbacks.
- Added an installer-start choice between automatic and manual Steam registration. Automatic mode requests a normal Steam shutdown, force-closes it if necessary, safely updates `shortcuts.vdf`, and always reopens Steam in `finally`, including after an installation error. Manual mode leaves Steam running and never accesses its shortcut database.
- The selected registration mode is stored with the clean backup. Automatic uninstall removes only the managed community shortcut while Steam is closed; manual uninstall leaves user-created Steam entries untouched.
- Added custom Steam and SteamVR library artwork derived from artwork supplied by Massimo Giannelli. Automatic mode installs AppID-matched 600×900 Capsule, 920×430 Header, 3840×1240 Hero and transparent Logo files; manual mode places all artwork in `HavenMoonVR_Artwork` for user-controlled setup.
- Added a small-size-optimized HavenMoonVR medallion icon. The installer embeds its seven-resolution ICO directly in the launcher, supplies Valve-sized 256×256 PNG and 184×184 JPG variants, and installs `<AppID>_icon.png` for an automatically managed Steam/SteamVR shortcut.
- Automatic uninstall removes only artwork files whose SHA-256 still matches the installed copy; user-modified Steam artwork is preserved.
- Collision Fix v2 withdraws the over-conservative forward/reverse sweep from v1. It suppresses the original duplicate `CharacterController.Move`, preserves the same total speed with one continuous move and centres the character capsule horizontally below the tracked HMD camera. This addresses the real visual asymmetry between the VR head and the unchanged flat-game body collider without adding early stopping distance.
- Collision Fix v1 is superseded: it stopped too early on one side and could detect the opposite side only after crossing a thin railing.
- Disabled the legacy `GlobalFog` and `GlobalFogWATER` full-screen passes in the community VR runtime. Haven Moon enables both on the player camera, but they reconstruct one symmetric desktop frustum instead of the separate asymmetric eye projections used by SteamVR; headset roll can therefore expose an unrendered black wedge at the ocean horizon.
- Unity's native scene fog remains available. The stereo-safe Water4 LOD 300 path retains the no-planar-reflection, no-screen-GrabPass and no-edge-blend protections.
- Removed `Configure_VR_Quality.cmd` and its companion script. Quest 2 testing at 90 Hz showed that the former 150% preset caused intermittent dropped frames and visible image doubling; the package now leaves SteamVR render resolution untouched and documents 100% as the stable starting point.
- Added a persistent fast-check cache for normal installation/update runs. Files that already passed SHA-256 are accepted from unchanged size plus NTFS creation/last-write metadata; any metadata change immediately falls back to a full SHA-256 comparison and per-file repair. The explicit verifier continues to hash every file.
- The original 1.0.2 stable package remains unchanged.

## Earlier development changes incorporated into 1.2.0

- Added an incremental SHA-256 installation pass. Every generated game patch and community runtime file is compared with the required version before writing, so already-current files remain untouched and only missing or different files are updated.
- Clean backups are now validated independently and are no longer restored over the live installation during a normal update. The original launcher icon build is also cached and rebuilt only when its source inputs change.
- Synchronized each shared controller-action flag with the same hysteresis latch used by its virtual Fire1/Fire2 key. The target no longer stops receiving activation before Unity sees the key release.
- Added a three-frame release allowance and a 0.18-second recent-target memory per hand, preventing short trigger-induced aim movement or input timing from dropping a click.
- Added a VR-safe ocean fallback: the community runtime disconnects the legacy planar-reflection pass, selects the low non-reflective Water4 shader and disables its screen-space edge blend. This simplified the water but did not eliminate the roll-dependent wedge on every headset; Horizon Fix v3 addresses the remaining camera post-processing cause.
- The installed launcher now embeds the icon from the user's local `HavenMoon.exe`, and Steam uses that original executable as the shortcut icon source. No original game artwork is redistributed.
- The icon-enabled launcher remains AnyCPU and the starter explicitly selects 64-bit Windows PowerShell, preventing a 32-bit process from trying to load SteamVR's 64-bit `openvr_api.dll`.

## 1.2.0 hotfix

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
