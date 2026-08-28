# Community controller interaction

The bridge polls both SteamVR controllers independently. For each hand it publishes a position, a forward direction and an action state to the in-game community runtime.

Quest 2 Native Aim v3 queries `openxr_aim` through SteamVR's input-source-aware render-model API, using distinct `/user/hand/left` and `/user/hand/right` handles, and composes the returned transform with the tracked device pose. The bridge prints the chosen method, origin and downward angle for both hands. No angle or origin offset is hard-coded. Compatibility order is `openxr_aim`, `tip`, the legacy component call and finally the raw controller pose.

- Left trigger or X drives Fire2 and the left-hand target.
- Right trigger or A drives Fire1 and the right-hand target.
- Both hands can point at different objects at the same time.
- Dim rays remain visible whenever the poses are valid; a ray brightens and displays a hit dot for an activable object within Haven Moon's original 1.8 m interaction distance.
- F7 lowers and F9 raises the camera in persistent 5 cm steps. F8 or controller Y reapplies the saved height.

Existing object scripts still receive Fire1/Fire2, preserving the main/opposite direction logic used by handles, knobs and similar mechanisms.

## Visual profile

Version 1.2.6 keeps the original Water4 path, screen GrabPass, shoreline blending, GlobalFog, post-processing and anti-aliasing. It disconnects `WaterTile.reflection` and disables `PlanarReflection`, then applies the targeted Water Enhanced VR Fresnel, specular, foam and texture-filtering adjustment. There is no F10 water-mode toggle.
