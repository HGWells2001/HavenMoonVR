# HavenMoonVR 1.2.6 Community Patch

**Created by Massimo Giannelli using ChatGPT in Florence, Italy.**

[Italiano](README_IT.md) · [Repository](https://github.com/HGWells2001/HavenMoonVR) · [Troubleshooting](Docs/TROUBLESHOOTING_EN.md)

> **Important:** this is an unofficial, rough-and-ready community patch made through practical testing. It is supplied **as-is**, with no guarantee that every scene, controller or PC configuration will behave perfectly. Keep the clean backup created by the installer.

HavenMoonVR adds PC VR support to the Steam version of Haven Moon. Version 1.2.6 uses two independent tracked-controller rays, native Quest 2 aim poses, head-relative locomotion, corrected player collision and height recentering. It keeps the ocean planar reflection disabled and adds a targeted **Water Enhanced VR** profile that improves the water without restoring problematic reflections of sky, clouds or scene objects.

## Base-game compatibility

The installer is designed to run directly on the **unmodified supported Steam build of Haven Moon**. No earlier HavenMoonVR version or other game patch is required.

Before changing anything, it verifies the original `HavenMoon.exe`, scenes and `Assembly-CSharp.dll` by SHA-256. If the build is unknown or already modified without a verified clean backup, installation stops without patching it. Original files are copied into `HavenMoonVR_Backup` for rollback.

## Main features

- Independent left and right SteamVR controller pointers.
- Quest 2 `openxr_aim` resolved through separate SteamVR left/right device paths.
- Left/right triggers activate the object pointed to by the corresponding hand.
- Fixed centre-screen gameplay pointer removed.
- Head-relative locomotion and right-stick turning.
- Symmetric character collision centred below the tracked headset.
- Automatic height recenter, plus F7/F9 adjustment and Y/F8 reset.
- The original Water4 path, screen GrabPass, shoreline blending, GlobalFog, post-processing and anti-aliasing are retained.
- The ocean planar reflection is disabled completely, removing reflected sky, clouds and scene objects without lowering the remaining water quality.
- Water Enhanced VR improves Fresnel response, reflection tint, specular light and foam, and applies trilinear/anisotropic filtering only to the ocean textures.
- No graphics-quality hotkey or automatic VR-safe water fallback.
- Incremental installer: files already at the required version are left untouched.
- Optional automatic Steam/SteamVR registration and custom Library artwork.

## Installation

1. Install or verify the original Haven Moon through Steam.
2. Save your game before continuing. Automatic mode closes Haven Moon, SteamVR and Steam for you; with Manual mode, close Haven Moon and SteamVR yourself.
3. Extract the complete release ZIP to a short normal path, for example `C:\HavenMoonVR`.
4. Run `Install_HavenMoonVR.cmd`.
5. Choose Steam registration:
   - **Automatic:** Haven Moon, SteamVR and Steam are closed; `Haven Moon VR Community Patch` is registered in the VR Library, artwork is installed, and Steam is reopened.
   - **Manual:** Steam remains open and its shortcut database is not touched. Haven Moon and SteamVR must already be closed. Add `Haven Moon VR.exe` yourself and enable **Include in VR Library**.
6. Start `Haven Moon VR Community Patch` from Steam/SteamVR, or run `Haven Moon VR.exe`.

## Controls

| Control | Action |
|---|---|
| Left stick | Head-relative movement |
| Right stick | Turn |
| Left trigger | Activate left-hand target / Fire2 |
| Right trigger | Activate right-hand target / Fire1 |
| X | Opposite/decrement action |
| A | Main/increment action |
| Y or F8 | Recenter height |
| F7 / F9 | Lower / raise camera by 5 cm |

SteamVR per-application render resolution is not changed. Quest 2 testing found 100% at 90 Hz to be the safest starting point; higher values depend on the PC.

Version 1.2.6 does not restore the reflection camera or alter wave geometry. It still retains the other original effects, so a water or horizon stereo artefact may remain on some configurations. Version 1.2.5 provides the same reflection exclusion without the new material tuning; 1.2.2 remains the most conservative VR-safe alternative.

## Verification and removal

- Reopen the graphical Setup after installation: when it detects HavenMoonVR in the selected game folder, the **Uninstall** button becomes available and restores the verified original files.
- `Verify_Installation.cmd` performs a full SHA-256 audit.
- `Configure_Display.cmd` changes only the desktop mirror window, not headset resolution.
- `Uninstall_HavenMoonVR.cmd` restores verified clean game files and removes managed runtime files. The clean backup is retained.

The repository contains editable source and installer scripts, but no original Haven Moon files and no Valve `openvr_api.dll`. The complete installable package is distributed through GitHub Releases.

HavenMoonVR is not affiliated with the Haven Moon developer or publisher, Valve, Meta or OpenAI.
