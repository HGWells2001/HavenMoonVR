# Known limitations

- This is an unofficial rough-and-ready community patch, supplied as-is.
- Controller aim uses the active SteamVR render model's native `openxr_aim` transform, with Valve `tip` and the raw tracked pose as compatibility fallbacks.
- The new rays operate on 3D world objects. Haven Moon's Unity UI menus keep their original mouse/keyboard behavior.
- Both tracked controllers must be awake and visible to SteamVR before the 60-second startup timeout expires.
- The game must be launched through `Haven Moon VR Community Patch`. Another shortcut does not publish controller poses, so the centre reticle will disappear but no controller rays can appear.
- The stable and community game patches cannot be active at the same time in one Haven Moon installation.
- Manual Steam registration deliberately leaves every user-created shortcut untouched during uninstall; remove that Steam entry yourself after uninstalling the mod.
- Manual artwork selection remains under the user's control. Automatic uninstall removes only unchanged managed artwork and deliberately preserves any image the user replaced or edited.
- Rays remain dim when a target is out of range, not tagged as activable, blocked by another collider, or while the player is moving; only a valid target makes its ray bright and displays the hit dot.
- Collision Fix v2 horizontally follows the tracked HMD with the character capsule only while the active camera remains inside the player hierarchy. Large physical room-scale steps near geometry still require care and additional in-headset testing.
- Version 1.2.6 disables the ocean planar reflection completely, removing reflections of sky, clouds and scene objects. Water Enhanced VR changes only Fresnel, reflection tint, specular response, foam intensity and filtering of the two ocean textures. Water4, screen GrabPass, shoreline edge blending, `GlobalFog`, `GlobalFogWATER`, post-processing and anti-aliasing remain active.
- The remaining original flat-screen effects were not designed for two asymmetric VR eye projections. A black wedge or another stereo artefact may therefore still appear on some configurations. Version 1.2.5 provides the same reflection exclusion without Water Enhanced VR, while 1.2.2 provides the most conservative VR-safe ocean fallback.
- SteamVR render resolution above 100% can miss the 90 Hz frame budget on Quest 2 and appear as intermittent shaking or image doubling. The package does not alter this setting; start at 100% and increase it only after checking frame timing.
- The build has been structurally verified without modifying the installed game, but final comfort, aim alignment and per-object behavior require an in-headset play test.

For useful feedback, record the headset/controller model, SteamVR runtime path, hand used, object targeted, whether the ray appeared, and whether the expected direction/action occurred.
