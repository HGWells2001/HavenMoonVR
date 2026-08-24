# HavenMoonVR 1.1.1 Experimental

**HavenMoonVR was created by Massimo Giannelli using ChatGPT in Florence, Italy.**

[Italiano](README_IT.md) · [Download the latest release](https://github.com/HGWells2001/HavenMoonVR/releases/latest) · [Troubleshooting](docs/TROUBLESHOOTING_EN.md)

Unofficial PC VR prototype for Haven Moon, derived from the stable 1.0.2 line. This build replaces the fixed gameplay centre pointer with two independent tracked-controller rays.

## What is new

- Left and right controller position/orientation come directly from SteamVR/OpenVR.
- Each hand performs an independent raycast and can target a different object.
- Thin blue-left and orange-right rays remain visible while the controllers are tracked.
- A ray brightens and gains a surface dot when an interactable object is in range.
- The left trigger activates the left-hand target; the right trigger activates the right-hand target.
- Trigger release uses the same hysteresis-latched state as Fire1/Fire2 plus a short allowance so activation is not dropped.
- The original centre-screen gameplay interaction ray is bypassed.
- In VR the ocean uses the simplified Water4 shader without planar reflection or screen-space edge blending, avoiding the black horizon wedge seen during headset roll.

Head-relative locomotion, right-stick turning, FXAA, VR Origin, automatic height recenter, Y/F8 recenter and SteamVR quality configuration remain available. Recenter now compensates Haven Moon's existing 0.683 m camera offset instead of counting it twice; F7/F9 adjust the result in persistent 5 cm steps.

## Install

1. Fully close Haven Moon, SteamVR and Steam.
2. Extract the complete ZIP.
3. Run `Install_HavenMoonVR.cmd`.
4. Reopen Steam.
5. Launch `Haven Moon VR Experimental` from Steam or SteamVR.

The entry containing **Experimental** must be used. The older stable shortcut starts the 1.0.2 bridge, which does not publish the two controller poses.

The installer accepts only the verified Steam game build and keeps a verified clean backup. It compares the SHA-256 hash of every generated game patch and experimental runtime file, updates only files that are missing or different, and leaves already-current files and their modification times untouched. The user's existing experimental display configuration is preserved. It also backs up `shortcuts.vdf` and adds or updates only the `Haven Moon VR Experimental` VR-library shortcut. The launcher locally embeds the icon from the user's installed `HavenMoon.exe`, and Steam uses that original executable as its icon source. No game artwork is included in this package.

## Controls

| Control | Action |
|---|---|
| Left stick | Head-relative locomotion |
| Right stick | Turn |
| Left trigger | Activate left-hand target / Fire2 |
| Right trigger | Activate right-hand target / Fire1 |
| X | Decrement/opposite direction on the left pointer |
| A | Increment/main direction on the right pointer |
| Y | Height recenter |
| F8 | Keyboard height-recenter fallback |
| F7 | Lower camera by 5 cm and remember it |
| F9 | Raise camera by 5 cm and remember it |

The stable 1.0.2 package is not modified. The stable and experimental patches cannot be active simultaneously on one Haven Moon installation. To return to 1.0.2, run this package's uninstaller and then reinstall the stable build.

World-object pointing is the focus of this prototype. Unity menus retain their original UI behavior and may still need mouse or keyboard input. See [known limitations](docs/KNOWN_LIMITATIONS.md).

## Repository layout

- `src/`: C# source for the in-game runtime, assembly patcher, Steam shortcut tool and launcher.
- `installer/`: installer, OpenVR bridge and configuration scripts.
- `docs/`: controls, troubleshooting, limitations and release notes.
- GitHub Releases: complete ready-to-test ZIP and its SHA-256 checksum.

The repository deliberately contains no original Haven Moon files and no Valve `openvr_api.dll`. See [build notes](build/BUILD.md), [credits](CREDITS.md) and [third-party notices](THIRD_PARTY_NOTICES.txt).

HavenMoonVR is unofficial and is not affiliated with the Haven Moon developer or publisher, Valve, or OpenAI.
