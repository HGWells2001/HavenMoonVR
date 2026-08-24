# Troubleshooting

## The centre reticle is gone but no controller rays appear

Launch the game only through the Steam entry **Haven Moon VR Experimental**. The older stable shortcut does not publish controller poses. The bridge window must report `Both VR controllers are ready` and `Experimental dual-pointer shared tracking is ready`.

If those messages do not appear, wake and move both controllers, confirm that SteamVR sees them, and restart the experimental entry.

## The camera is too high or too low

Press `F8` or controller `Y` to recenter. Use `F7` to lower and `F9` to raise the camera in 5 cm steps; the choice is remembered. Version 1.1.1 also fixes the original 0.683 m camera offset being counted twice.

## Rays appear but point in the wrong direction

Record the headset model, controller model and direction of the error. Legacy OpenVR drivers can expose slightly different pointing axes; this information is needed for a controller-specific correction.

## A world object does not light up

You must be within 1.8 metres, stationary and pointing directly at the object's collider. Two-dimensional menus retain their original behaviour and may require a mouse or keyboard.

## The installer stops

Fully close Haven Moon, SteamVR and Steam. Do not force installation on a game build with a different checksum: verify Haven Moon through Steam, then try again.

## Verify the installation

Run `Verify_Experimental_Installation.cmd`. If it reports `WRONG BUILD`, reinstall 1.1.1 using the complete contents of the ZIP.
