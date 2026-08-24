# Build notes

HavenMoonVR was created by Massimo Giannelli using ChatGPT in Florence, Italy.

The release package is intentionally self-contained for users, while this repository contains the editable source. Original Haven Moon files, Unity redistributables from the game and Valve's `openvr_api.dll` are not committed.

## Components

- `HavenMoonVR.Experimental.dll`: compile `src/HavenMoonVR.Experimental.cs` with the .NET Framework 3.5 C# compiler and reference `UnityEngine.dll` from a legally installed supported copy of Haven Moon.
- `HavenMoonVR.AssemblyPatcher.exe`: compile `src/HavenMoonVR.AssemblyPatcher.cs` for .NET Framework 4 and reference Mono.Cecil 0.11.5.
- `HavenMoonVR.SteamShortcutTool.exe`: compile `src/HavenMoonVR.SteamShortcutTool.cs` for .NET Framework 4.
- `Haven Moon VR Experimental.exe`: compile `src/HavenMoonVR.ExperimentalLauncher.cs` as a Windows executable for .NET Framework 4. Do not embed art extracted from the game in the distributed binary.
- Also place `src/HavenMoonVR.ExperimentalLauncher.cs` in the release package as `Runtime/HavenMoonVR.ExperimentalLauncher.cs`. During installation the patcher extracts the icon from the user's verified local `HavenMoon.exe` and recompiles the copied launcher with that icon. If local compilation is unavailable, the prebuilt launcher remains valid and Steam still reads its icon directly from `HavenMoon.exe`.
- `HavenMoonVR_InputBridge_Experimental.ps1`: embeds the OpenVR interop types used by the external controller bridge.

The installer verifies the supported game executable and every modified asset by SHA-256. It generates the patched files locally from the user's own clean installation and copies `openvr_api.dll` from the user's local SteamVR runtime.

## Release checks

Before publishing a ZIP:

1. Parse every PowerShell script.
2. Compile the embedded OpenVR C# block.
3. Load and inspect both managed assemblies against the supported Unity runtime.
4. Run install, verify, uninstall and clean-hash restoration on an isolated copy of the supported game.
5. Verify Steam `shortcuts.vdf` add/remove round-trips byte-for-byte on test copies.
6. Generate `FILE_HASHES_SHA256.txt`, extract the final ZIP and compare every file hash.
7. Publish a separate SHA-256 checksum for the ZIP.
