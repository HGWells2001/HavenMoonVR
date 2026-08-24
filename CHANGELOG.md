# HavenMoonVR 1.1.1 Experimental

Created by Massimo Giannelli using ChatGPT in Florence, Italy.

## Unreleased

- Restored the ocean reflection skybox in levels 1-4. The previous dark-clear reflection setting could expose a black wedge between ocean and sky when the headset was rolled left or right.
- The installed launcher now embeds the icon from the user's local `HavenMoon.exe`, and Steam uses that original executable as the shortcut icon source. No original game artwork is redistributed.
- The icon-enabled launcher remains AnyCPU and the starter explicitly selects 64-bit Windows PowerShell, preventing a 32-bit process from trying to load SteamVR's 64-bit `openvr_api.dll`.

## 1.1.1 hotfix

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
