# Build notes

HavenMoonVR was created by Massimo Giannelli using ChatGPT in Florence, Italy.

The release package is intentionally self-contained for users, while this repository contains the editable source. Original Haven Moon files, Unity redistributables from the game and Valve's `openvr_api.dll` are not committed.

## Components

- `HavenMoonVR.Runtime.dll`: compile `src/HavenMoonVR.Runtime.cs` with the .NET Framework 3.5 C# compiler and reference `UnityEngine.dll` from a legally installed supported copy of Haven Moon.
- `HavenMoonVR.AssemblyPatcher.exe`: compile `src/HavenMoonVR.AssemblyPatcher.cs` for .NET Framework 4 and reference Mono.Cecil 0.11.5.
- `HavenMoonVR.SteamShortcutTool.exe`: compile `src/HavenMoonVR.SteamShortcutTool.cs` for .NET Framework 4.
- `Haven Moon VR.exe`: compile `src/HavenMoonVR.Launcher.cs` as a Windows executable for .NET Framework 4 AnyCPU and embed `Artwork/HavenMoonVR_LauncherIcon.ico` with `/win32icon`.
- Also place `src/HavenMoonVR.Launcher.cs` in the release package as `Runtime/HavenMoonVR.Launcher.cs`. During installation the patcher recompiles the launcher with the packaged custom multi-resolution icon and verifies the embedded 32-pixel representation. If local compilation is unavailable, the icon-enabled prebuilt launcher remains valid.
- `HavenMoonVR_InputBridge.ps1`: embeds the OpenVR interop types used by the external controller bridge.
- `prepare_steam_artwork.py`: uses Pillow to produce the Valve-sized Capsule, Header, Hero and transparent Logo assets from the approved source artwork and prepared image edits. Keep the Hero text-free and verify that the Logo contains a real alpha channel.

The installer verifies the supported game executable and every modified asset by SHA-256. It generates the patched files locally from the user's own clean installation and copies `openvr_api.dll` from the user's local SteamVR runtime.

## Release checks

Before publishing a ZIP:

1. Parse every PowerShell script.
2. Compile the embedded OpenVR C# block.
3. Load and inspect both managed assemblies against the supported Unity runtime.
   Confirm that `FixedUpdate` contains one `SuppressDuplicateMove` hook and one `MoveOnceCenteredOnHead` hook, with no direct duplicate `CharacterController.Move` calls remaining.
4. Run install, verify, uninstall and clean-hash restoration on an isolated copy of the supported game.
5. Run the installer twice and verify that the second pass reports zero file updates and fast-cache hits for the large scene/backup files without changing modification times; the small `HavenMoon.exe` build guard must still be hashed unconditionally. Then alter one installed file and verify that only that file receives a full hash and repair.
6. Verify Steam `shortcuts.vdf` add/remove round-trips byte-for-byte on test copies.
7. Verify automatic artwork installation against an isolated Steam `config/grid` directory: `<AppID>.png`, `<AppID>p.png`, `<AppID>_hero.png` and `<AppID>_logo.png`. Confirm safe hash-matched removal and preservation of changed artwork.
8. Confirm exact artwork dimensions and real Logo transparency.
9. Generate `FILE_HASHES_SHA256.txt`, extract the final ZIP and compare every file hash.
10. Publish a separate SHA-256 checksum for the ZIP.
