#!/usr/bin/env python3
"""Update all web, admin, and splash logos from the new brand icon."""

from PIL import Image, ImageDraw
import os, base64, math

BASE = "/Users/ademoba/Desktop/bible_app_local"
ICON_SRC = f"{BASE}/assets/brand/icon.png"

def resize_icon(src, dst, size):
    """Resize icon to target size with high quality."""
    img = Image.open(src).convert("RGBA")
    resized = img.resize((size, size), Image.LANCZOS)
    resized.save(dst, "PNG")
    print(f"  ✓ {os.path.relpath(dst, BASE)} ({size}x{size})")

def create_maskable_icon(src, dst, size):
    """Create maskable icon with safe zone padding (icon at 80% inside circle-safe area)."""
    img = Image.open(src).convert("RGBA")
    # Maskable icons need 10% padding on each side (safe zone is 80%)
    icon_size = int(size * 0.80)
    padding = (size - icon_size) // 2

    # Create background matching app theme
    canvas = Image.new("RGBA", (size, size), (62, 39, 35, 255))  # DEEP_BROWN
    icon_resized = img.resize((icon_size, icon_size), Image.LANCZOS)
    canvas.paste(icon_resized, (padding, padding), icon_resized)
    canvas.save(dst, "PNG")
    print(f"  ✓ {os.path.relpath(dst, BASE)} ({size}x{size} maskable)")

def create_favicon(src, dst):
    """Create a 32x32 favicon."""
    img = Image.open(src).convert("RGBA")
    favicon = img.resize((32, 32), Image.LANCZOS)
    favicon.save(dst, "PNG")
    print(f"  ✓ {os.path.relpath(dst, BASE)} (32x32 favicon)")

def create_splash(src, dst, size, dark=False):
    """Create splash screen image — centered icon on themed background."""
    bg_color = (46, 27, 18, 255) if dark else (255, 248, 240, 255)
    canvas = Image.new("RGBA", (size * 4, size * 4), bg_color)
    img = Image.open(src).convert("RGBA")
    icon_size = size
    icon = img.resize((icon_size, icon_size), Image.LANCZOS)
    offset = (canvas.width - icon_size) // 2
    canvas.paste(icon, (offset, offset), icon)
    # Crop to just the icon with some padding
    pad = icon_size // 2
    cropped = canvas.crop((offset - pad, offset - pad, offset + icon_size + pad, offset + icon_size + pad))
    final = cropped.resize((size, size), Image.LANCZOS)
    final.save(dst, "PNG")
    print(f"  ✓ {os.path.relpath(dst, BASE)} ({size}x{size} {'dark' if dark else 'light'})")

def icon_to_base64(src, size=48):
    """Convert icon to base64 for embedding in HTML."""
    img = Image.open(src).convert("RGBA")
    resized = img.resize((size, size), Image.LANCZOS)
    import io
    buf = io.BytesIO()
    resized.save(buf, format="PNG")
    return base64.b64encode(buf.getvalue()).decode()

def main():
    print("=" * 50)
    print("Updating logos across web & admin")
    print("=" * 50)

    # 1. Web favicon
    print("\n[Web Favicon]")
    create_favicon(ICON_SRC, f"{BASE}/web/favicon.png")

    # 2. Web PWA icons
    print("\n[Web PWA Icons]")
    resize_icon(ICON_SRC, f"{BASE}/web/icons/Icon-192.png", 192)
    resize_icon(ICON_SRC, f"{BASE}/web/icons/Icon-512.png", 512)
    create_maskable_icon(ICON_SRC, f"{BASE}/web/icons/Icon-maskable-192.png", 192)
    create_maskable_icon(ICON_SRC, f"{BASE}/web/icons/Icon-maskable-512.png", 512)

    # 3. Web splash images
    print("\n[Web Splash Images]")
    splash_dir = f"{BASE}/web/splash/img"
    if os.path.exists(splash_dir):
        # Light splash
        for mult, suffix in [(1, "1x"), (2, "2x"), (3, "3x"), (4, "4x")]:
            size = 48 * mult  # Base splash icon size
            create_splash(ICON_SRC, f"{splash_dir}/light-{suffix}.png", size, dark=False)
            create_splash(ICON_SRC, f"{splash_dir}/dark-{suffix}.png", size, dark=True)
    else:
        print("  ⚠ splash dir not found, skipping")

    # 4. Admin panel — generate icon for embedding
    print("\n[Admin Panel Logo]")
    b64_32 = icon_to_base64(ICON_SRC, 32)
    b64_48 = icon_to_base64(ICON_SRC, 48)
    b64_64 = icon_to_base64(ICON_SRC, 64)
    print(f"  Generated base64 icons for admin panel")
    print(f"    32px: {len(b64_32)} chars")
    print(f"    48px: {len(b64_48)} chars")
    print(f"    64px: {len(b64_64)} chars")

    # Save base64 for reference
    with open(f"{BASE}/store_assets/admin_icon_b64.txt", "w") as f:
        f.write(f"32px: data:image/png;base64,{b64_32}\n\n")
        f.write(f"48px: data:image/png;base64,{b64_48}\n\n")
        f.write(f"64px: data:image/png;base64,{b64_64}\n")
    print("  ✓ Saved base64 references to store_assets/admin_icon_b64.txt")

    # 5. Copy 512 icon to store_assets (already exists from generate_store_assets.py but ensure it matches)
    print("\n[Store Icon]")
    resize_icon(ICON_SRC, f"{BASE}/store_assets/app_icon_512.png", 512)

    print("\n" + "=" * 50)
    print("✅ All logos updated!")
    print("=" * 50)

if __name__ == "__main__":
    main()
