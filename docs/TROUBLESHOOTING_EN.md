# Troubleshooting

## The centre reticle is gone but no controller rays appear

Launch the game only through the Steam entry **Haven Moon VR Community Patch**. Another shortcut does not publish controller poses. The bridge window must report `Both VR controllers are ready` and `Community dual-pointer shared tracking is ready`.

If those messages do not appear, wake and move both controllers, confirm that SteamVR sees them, and restart the community entry.

## The camera is too high or too low

Press `F8` or controller `Y` to recenter. Use `F7` to lower and `F9` to raise the camera in 5 cm steps; the choice is remembered. Version 1.2.6 also retains the fix for the original 0.683 m camera offset being counted twice.

## A black wedge appears between ocean and sky when the headset is rolled

Version 1.2.6 disables the ocean planar reflection completely, removing reflected sky, clouds and scene objects. Water Enhanced VR adjusts only the water Fresnel, tint, specular light, foam and texture filtering. `GlobalFog`, `GlobalFogWATER`, the screen GrabPass and shoreline blending remain original, so a stereo artefact may still occur on some configurations. There is no F10 fallback; use 1.2.5 for the same reflection exclusion without the new tuning, or 1.2.2 for conservative VR-safe ocean rendering.

## The graphics shake or the image intermittently doubles

Check Haven Moon's per-application render resolution in SteamVR and return it to **100%**. During Quest 2 testing at 90 Hz, 150% caused dropped frames and intermittent image doubling; output was stable at 100%. The package no longer changes this setting and no longer includes `Configure_VR_Quality.cmd`.

## A railing blocks movement from one side but can be crossed from the other

Install the build containing **Collision Fix v2**. V1 was too conservative and has been withdrawn. V2 removes the original duplicate movement, preserves the same total speed and horizontally centres the body capsule below the tracked HMD. The distance seen from the headset therefore matches the character collision.

## Rays appear but point in the wrong direction

Record the headset model, controller model and direction of the error. Legacy OpenVR drivers can expose slightly different pointing axes; this information is needed for a controller-specific correction.

## A world object does not light up

You must be within 1.8 metres, stationary and pointing directly at the object's collider. Two-dimensional menus retain their original behaviour and may require a mouse or keyboard.

## I must press a trigger more than once

The v4 build includes Trigger Fix v3: the bridge keeps the target driven until Fire1/Fire2 is actually released, and the runtime briefly remembers the last valid target.

## The installer stops

The first run intentionally performs complete SHA-256 checks and can take longer. Later unchanged updates use the fast version cache. If any file's size or timestamps changed, that file is fully hashed and repaired if necessary. Run `Verify_Installation.cmd` whenever you want an unconditional full-hash audit.

Fully close Haven Moon and SteamVR. Steam may remain open in manual registration mode; automatic mode closes it, forcefully if it does not respond, and reopens it at the end. Do not force installation on a game build with a different checksum: verify Haven Moon through Steam, then try again.

## Automatic or manual Steam registration

With **Automatic**, the installer closes Haven Moon, SteamVR and Steam, backs up `shortcuts.vdf`, registers `Haven Moon VR Community Patch` in the VR Library and reopens Steam even if installation ends with an error. With **Manual**, Steam may remain open, Haven Moon and SteamVR must already be closed, and the installer never touches its shortcut database: add `Haven Moon VR.exe` as a non-Steam game, rename it `Haven Moon VR Community Patch`, and enable **Include in VR Library**. Uninstall does not remove a shortcut you created manually.

## Custom artwork does not appear in Steam or SteamVR

After automatic registration, close and reopen SteamVR as well so its interface reloads the updated Library. After manual registration, use the images in `HavenMoonVR_Artwork` beside the installed game; `docs/STEAM_ARTWORK_IT_EN.md` maps Capsule, Header, Hero and Logo to their Library screens. Always customize **Haven Moon VR Community Patch**.

If it reports `Package file missing`, do not use **Code → Download ZIP** and do not run files directly inside a compressed archive. Download the installable release asset, choose **Extract all**, and run `Install_HavenMoonVR.cmd` from the extracted folder.

## The installer reports `Already current`

This is normal: either SHA-256 or the unchanged-file cache confirmed that the file matches the required version, so it is not rewritten. `Game/runtime files updated: 0` means every file was already current; if one file differs, only that file is repaired.

## Verify the installation

Run `Verify_Installation.cmd`. If it reports `WRONG BUILD`, reinstall 1.2.6 using the complete contents of the ZIP.
