# HavenMoonVR 1.1.1 Experimental — Incremental Installer v4

Created by Massimo Giannelli using ChatGPT in Florence, Italy.

## 1.1.1 hotfix

- Incremental Installer v4 checks every generated game patch and experimental runtime file by SHA-256. Only missing, different or outdated files are written; already-current files and their modification times remain untouched.
- Verified clean backups are checked independently instead of being restored over every live file during a normal update. The local icon-enabled launcher is rebuilt only when its source inputs have changed.
- Trigger Fix v3 synchronizes the shared left/right action flags with the hysteresis-latched Fire2/Fire1 state, adds a three-frame release allowance and remembers the recent target for 0.18 seconds.
- Horizon Fix v2 disconnects the legacy planar-reflection pass, selects the low non-reflective Water4 shader and disables screen-space edge blending, removing the roll-dependent black horizon.
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
- Dedicated experimental launcher and Steam VR-library shortcut.
- Local shared-memory transport between the OpenVR bridge and Unity runtime.

## Preserved from the stable line

- Steam build and SHA-256 guards.
- Clean backup/restore workflow.
- SteamVR OpenVR setup.
- Head-relative locomotion and right-stick turning.
- VR Origin and automatic/manual height recenter.
- FXAA ExtremeQuality and optional SteamVR per-app resolution presets.

## Safety and rollback

The stable 1.0.2 package remains untouched. The experimental uninstaller restores the verified clean game files, removes only the experimental runtime/shortcut, and retains the clean backup. Reinstall 1.0.2 afterward to return to the stable mod.
