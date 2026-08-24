# Known limitations

- This is a controller-pointer prototype, not a final release.
- The controller aim assumes the legacy OpenVR forward axis used by common Touch, Index, Vive and WMR drivers. A particular controller profile may need a pitch/yaw correction after real-headset testing.
- The new rays operate on 3D world objects. Haven Moon's Unity UI menus keep their original mouse/keyboard behavior.
- Both tracked controllers must be awake and visible to SteamVR before the 60-second startup timeout expires.
- The game must be launched through `Haven Moon VR Experimental`. The older stable shortcut does not publish controller poses, so the centre reticle will disappear but no controller rays can appear.
- The stable and experimental game patches cannot be active at the same time in one Haven Moon installation.
- Rays remain dim when a target is out of range, not tagged as activable, blocked by another collider, or while the player is moving; only a valid target makes its ray bright and displays the hit dot.
- The build has been structurally verified without modifying the installed game, but final comfort, aim alignment and per-object behavior require an in-headset play test.

For useful feedback, record the headset/controller model, SteamVR runtime path, hand used, object targeted, whether the ray appeared, and whether the expected direction/action occurred.
