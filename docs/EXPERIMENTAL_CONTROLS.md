# Experimental controller interaction

The bridge polls both SteamVR controllers independently. For each hand it publishes a position, a forward direction and an action state to the in-game experimental runtime.

- Left trigger or X drives Fire2 and the left-hand target.
- Right trigger or A drives Fire1 and the right-hand target.
- Both hands can point at different objects at the same time.
- Dim rays remain visible whenever the poses are valid; a ray brightens and displays a hit dot for an activable object within Haven Moon's original 1.8 m interaction distance.
- F7 lowers and F9 raises the camera in persistent 5 cm steps. F8 or controller Y reapplies the saved height.

Existing object scripts still receive Fire1/Fire2, preserving the main/opposite direction logic used by handles, knobs and similar mechanisms.
