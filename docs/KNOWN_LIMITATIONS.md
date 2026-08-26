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
- Horizon Fix v3 additionally disables the legacy `GlobalFog` and `GlobalFogWATER` full-screen passes because they are not stereo-frustum safe. Unity's native scene fog remains, but atmospheric depth may look different from the original flat-screen game.
- The community ocean uses Water4 LOD 300 without its LOD 500 screen GrabPass, planar reflection or screen-space edge blending. It is richer than the old LOD 200 fallback but reflections remain simpler than the original flat-screen path.
- Cinematic Shaders v1 deliberately has a very high GPU cost. 8x MSAA, high-sample ambient occlusion, HDR bloom, ultra shadows and long LOD distances can reduce VR frame rate severely; this package is intended as a visual-quality test.
- SteamVR render resolution above 100% can miss the 90 Hz frame budget on Quest 2 and appear as intermittent shaking or image doubling. The package does not alter this setting; start at 100% and increase it only after checking frame timing.
- The build has been structurally verified without modifying the installed game, but final comfort, aim alignment and per-object behavior require an in-headset play test.

For useful feedback, record the headset/controller model, SteamVR runtime path, hand used, object targeted, whether the ray appeared, and whether the expected direction/action occurred.
