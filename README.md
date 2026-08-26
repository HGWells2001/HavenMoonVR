# HavenMoonVR 1.2.0 Community Patch

**Created by Massimo Giannelli using ChatGPT in Florence, Italy.**

[Italiano](README_IT.md) · [Download](https://github.com/HGWells2001/HavenMoonVR/releases/download/v1.2.0/HavenMoonVR_1.2.0_CommunityPatch.zip) · [SHA-256](https://github.com/HGWells2001/HavenMoonVR/releases/download/v1.2.0/HavenMoonVR_1.2.0_CommunityPatch_SHA256.txt) · [Troubleshooting](docs/TROUBLESHOOTING_EN.md)

> **Important:** this is an unofficial, rough-and-ready community patch made through practical testing. It is supplied **as-is**, with no guarantee that every scene, controller or PC configuration will behave perfectly. Keep the clean backup created by the installer.

HavenMoonVR adds PC VR support to the Steam version of Haven Moon. Version 1.2.0 uses two independent tracked-controller rays, native Quest 2 aim poses, head-relative locomotion, corrected player collision, height recentering and stereo-safe ocean/horizon rendering.

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
- Stereo-safe horizon and Water4 rendering without legacy planar reflection or screen GrabPass.
- Cinematic image profile using the highest safe settings available in the original game.
- Incremental installer: files already at the required version are left untouched.
- Optional automatic Steam/SteamVR registration and custom Library artwork.

## Installation

1. Install or verify the original Haven Moon through Steam.
2. Close Haven Moon and SteamVR.
3. Extract the complete release ZIP to a short normal path, for example `C:\HavenMoonVR`.
4. Run `Install_HavenMoonVR.cmd`.
5. Choose Steam registration:
   - **Automatic:** Steam is closed, `Haven Moon VR Community Patch` is registered in the VR Library, artwork is installed, and Steam is reopened.
   - **Manual:** Steam remains open and its shortcut database is not touched. Add `Haven Moon VR.exe` yourself and enable **Include in VR Library**.
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

## Verification and removal

- `Verify_Installation.cmd` performs a full SHA-256 audit.
- `Configure_Display.cmd` changes only the desktop mirror window, not headset resolution.
- `Uninstall_HavenMoonVR.cmd` restores verified clean game files and removes managed runtime files. The clean backup is retained.

The repository contains editable source and installer scripts, but no original Haven Moon files and no Valve `openvr_api.dll`. The complete installable package is distributed through GitHub Releases.

HavenMoonVR is not affiliated with the Haven Moon developer or publisher, Valve, Meta or OpenAI.
