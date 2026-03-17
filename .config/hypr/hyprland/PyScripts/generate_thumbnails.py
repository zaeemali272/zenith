#!/usr/bin/env python3
import os
from PIL import Image

WALLPAPER_DIR = os.path.expanduser("~/Pictures/Wallpapers")
THUMB_DIR = os.path.expanduser("~/.cache/wallpaper_thumbs")

# Thumbnail target dimensions (16:9 aspect)
THUMB_WIDTH = 320
THUMB_HEIGHT = 180

os.makedirs(THUMB_DIR, exist_ok=True)


def generate_thumbnail(img_path, thumb_path):
    try:
        with Image.open(img_path) as im:
            im = im.convert("RGB")

            w, h = im.size
            target_aspect = THUMB_WIDTH / THUMB_HEIGHT
            src_aspect = w / h

            # Crop to 16:9 centered
            if src_aspect > target_aspect:
                # Too wide → crop sides
                new_w = int(h * target_aspect)
                left = (w - new_w) // 2
                top = 0
                right = left + new_w
                bottom = h
            else:
                # Too tall → crop top/bottom
                new_h = int(w / target_aspect)
                left = 0
                top = (h - new_h) // 2
                right = w
                bottom = top + new_h

            im = im.crop((left, top, right, bottom))
            im = im.resize((THUMB_WIDTH, THUMB_HEIGHT), Image.LANCZOS)
            im.save(thumb_path, format="PNG")
            print(f"✓ {thumb_path}")

    except Exception as e:
        print(f"✗ {img_path} → {e}")


def main():
    for file in sorted(os.listdir(WALLPAPER_DIR)):
        if not file.lower().endswith((".jpg", ".jpeg", ".png", ".webp")):
            continue

        src_path = os.path.join(WALLPAPER_DIR, file)
        thumb_name = os.path.splitext(file)[0] + ".png"
        thumb_path = os.path.join(THUMB_DIR, thumb_name)

        if not os.path.exists(thumb_path):
            generate_thumbnail(src_path, thumb_path)


if __name__ == "__main__":
    main()
