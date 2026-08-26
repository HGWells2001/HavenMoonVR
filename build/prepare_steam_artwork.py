#!/usr/bin/env python3
"""Create Steam library artwork at Valve's current target dimensions."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageOps


LANCZOS = Image.Resampling.LANCZOS


def fit(source: Path, size: tuple[int, int], centering=(0.5, 0.5)) -> Image.Image:
    with Image.open(source) as image:
        return ImageOps.fit(image.convert("RGBA"), size, method=LANCZOS, centering=centering)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--original", required=True, type=Path)
    parser.add_argument("--hero", required=True, type=Path)
    parser.add_argument("--logo", required=True, type=Path)
    parser.add_argument("--capsule", required=True, type=Path)
    parser.add_argument("--icon", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()

    args.output.mkdir(parents=True, exist_ok=True)

    fit(args.hero, (3840, 1240)).convert("RGB").save(
        args.output / "HavenMoonVR_LibraryHero_3840x1240.png", optimize=True
    )
    fit(args.capsule, (600, 900), centering=(0.5, 0.48)).convert("RGB").save(
        args.output / "HavenMoonVR_LibraryCapsule_600x900.png", optimize=True
    )
    # Bias the shallow header crop upward so every gear tooth remains visible.
    fit(args.original, (920, 430), centering=(0.5, 0.20)).convert("RGB").save(
        args.output / "HavenMoonVR_LibraryHeader_920x430.png", optimize=True
    )
    fit(args.original, (1920, 1080), centering=(0.5, 0.48)).convert("RGB").save(
        args.output / "HavenMoonVR_SteamVR_Background_1920x1080.png", optimize=True
    )

    with Image.open(args.logo) as source_logo:
        source_logo = source_logo.convert("RGBA")
        logo = ImageOps.contain(source_logo, (680, 680), method=LANCZOS)
        canvas = Image.new("RGBA", (720, 720), (0, 0, 0, 0))
        canvas.alpha_composite(logo, ((720 - logo.width) // 2, (720 - logo.height) // 2))
        canvas.save(args.output / "HavenMoonVR_LibraryLogo_720x720.png", optimize=True)

    with Image.open(args.icon) as source_icon:
        source_icon = source_icon.convert("RGBA")
        icon = ImageOps.contain(source_icon, (240, 240), method=LANCZOS)
        icon_canvas = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
        icon_canvas.alpha_composite(icon, ((256 - icon.width) // 2, (256 - icon.height) // 2))
        icon_canvas.save(args.output / "HavenMoonVR_LauncherIcon_256x256.png", optimize=True)
        icon_canvas.save(
            args.output / "HavenMoonVR_LauncherIcon.ico",
            format="ICO",
            sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)],
        )

        app_icon = icon_canvas.resize((184, 184), LANCZOS)
        app_background = Image.new("RGB", (184, 184), (14, 23, 32))
        app_background.paste(app_icon.convert("RGB"), mask=app_icon.getchannel("A"))
        app_background.save(
            args.output / "HavenMoonVR_AppIcon_184x184.jpg", quality=95, subsampling=0, optimize=True
        )


if __name__ == "__main__":
    main()
