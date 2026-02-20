#!/usr/bin/env python3
"""
Generate ExecPrompt app icons in the CyberTerm aesthetic.
>_ prompt symbol in phosphor green on deep black.
Uses DejaVu Sans Mono (available on most Linux systems).
"""

from PIL import Image, ImageDraw, ImageFont
import os

# Brand colors
BG_COLOR = (10, 15, 10)        # #0A0F0A deep black-green
FG_COLOR = (51, 255, 51)       # #33FF33 phosphor green
GLOW_COLOR = (26, 138, 26)     # #1A8A1A dimmed green for subtle glow

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

def find_mono_font():
    """Find a monospace font on the system."""
    candidates = [
        "/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf",
        "/usr/share/fonts/truetype/ubuntu/UbuntuMono-B.ttf",
        "/usr/share/fonts/truetype/msttcorefonts/courbd.ttf",
    ]
    for path in candidates:
        if os.path.exists(path):
            return path
    return None


def generate_icon(size, filename, is_foreground=False):
    """Generate a single icon at the given size."""
    if is_foreground:
        # Adaptive icon foreground: transparent background, symbol centered
        # Android adaptive icons use 108dp with 72dp safe zone (66% of canvas)
        img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    else:
        img = Image.new("RGBA", (size, size), BG_COLOR + (255,))

    draw = ImageDraw.Draw(img)

    font_path = find_mono_font()
    if not font_path:
        print("ERROR: No monospace font found!")
        return

    # Calculate font size — the ">_" should be prominent
    # For full icon: use ~45% of canvas
    # For foreground: use ~35% of canvas (safe zone constraint)
    if is_foreground:
        font_size = int(size * 0.30)
    else:
        font_size = int(size * 0.40)

    font = ImageFont.truetype(font_path, font_size)

    text = ">_"

    # Get text bounding box for centering
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]

    x = (size - text_width) / 2 - bbox[0]
    y = (size - text_height) / 2 - bbox[1]

    # Draw subtle glow layer (slightly larger, dimmed)
    if not is_foreground or size >= 256:
        for dx in [-2, -1, 0, 1, 2]:
            for dy in [-2, -1, 0, 1, 2]:
                if dx == 0 and dy == 0:
                    continue
                draw.text((x + dx, y + dy), text, font=font, fill=GLOW_COLOR + (60,))

    # Draw main text
    draw.text((x, y), text, font=font, fill=FG_COLOR + (255,))

    # Add a subtle scanline effect for larger icons
    if size >= 192 and not is_foreground:
        for sy in range(0, size, 4):
            draw.line([(0, sy), (size, sy)], fill=(0, 0, 0, 25), width=1)

    # Add thin border for non-foreground icons
    if not is_foreground and size >= 96:
        border_color = (26, 58, 26, 180)  # #1A3A1A with alpha
        draw.rectangle(
            [(2, 2), (size - 3, size - 3)],
            outline=border_color,
            width=1,
        )

    filepath = os.path.join(SCRIPT_DIR, filename)
    img.save(filepath, "PNG")
    print(f"  Generated: {filename} ({size}x{size})")


def main():
    print("> GENERATING EXECPROMPT ICONS...")
    print()

    # 1. Full icon (1024x1024) — source for flutter_launcher_icons
    generate_icon(1024, "execprompt_icon.png")

    # 2. Adaptive foreground (432x432) — for Android adaptive icons
    generate_icon(432, "execprompt_icon_foreground.png", is_foreground=True)

    # 3. Android legacy mipmap sizes (direct use if not using flutter_launcher_icons)
    mipmap_sizes = {
        "ic_launcher_mdpi.png": 48,
        "ic_launcher_hdpi.png": 72,
        "ic_launcher_xhdpi.png": 96,
        "ic_launcher_xxhdpi.png": 144,
        "ic_launcher_xxxhdpi.png": 192,
    }
    for name, size in mipmap_sizes.items():
        generate_icon(size, name)

    # 4. Play Store high-res icon (512x512)
    generate_icon(512, "execprompt_playstore_512.png")

    # 5. Linux desktop icon (256x256)
    generate_icon(256, "execprompt_desktop_256.png")

    # 6. Favicon sizes
    generate_icon(32, "favicon_32.png")
    generate_icon(16, "favicon_16.png")

    # 7. Web manifest sizes
    generate_icon(192, "execprompt_web_192.png")
    generate_icon(512, "execprompt_web_512.png")

    print()
    print("> ICON GENERATION COMPLETE")
    print(f"> Output directory: {SCRIPT_DIR}")


if __name__ == "__main__":
    main()
