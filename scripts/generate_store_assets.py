#!/usr/bin/env python3
"""Generate all Google Play Store visual assets for Rhema Study Bible."""

from PIL import Image, ImageDraw, ImageFont
import math
import os

OUT = "/Users/ademoba/Desktop/bible_app_local/store_assets"

# ─── Color Palette (Sacred Luminance) ───
DEEP_BROWN   = (62, 39, 35)
WARM_BROWN   = (93, 64, 55)
LIGHT_BROWN  = (141, 110, 99)
GOLD         = (212, 168, 67)
DARK_GOLD    = (180, 140, 50)
CREAM        = (255, 248, 240)
WARM_WHITE   = (255, 253, 248)
DARK_BG      = (46, 27, 18)
TEXT_DARK     = (62, 39, 35)
TEXT_LIGHT    = (255, 248, 240)
SOFT_GOLD    = (255, 223, 140)

# ─── Font helper ───
def get_font(size, bold=False):
    """Try to load a nice font, fall back to default."""
    font_paths = [
        "/System/Library/Fonts/Supplemental/Georgia Bold.ttf" if bold else "/System/Library/Fonts/Supplemental/Georgia.ttf",
        "/System/Library/Fonts/Georgia.ttf",
        "/System/Library/Fonts/Supplemental/Times New Roman Bold.ttf" if bold else "/System/Library/Fonts/Supplemental/Times New Roman.ttf",
        "/Library/Fonts/Georgia Bold.ttf" if bold else "/Library/Fonts/Georgia.ttf",
    ]
    for fp in font_paths:
        if os.path.exists(fp):
            return ImageFont.truetype(fp, size)
    try:
        return ImageFont.truetype("Georgia", size)
    except:
        return ImageFont.load_default()

def get_sf_font(size, bold=False):
    """Try to load SF/Helvetica for UI elements."""
    font_paths = [
        "/System/Library/Fonts/Helvetica.ttc",
        "/System/Library/Fonts/SFNSText.ttf",
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf" if bold else "/System/Library/Fonts/Supplemental/Arial.ttf",
    ]
    for fp in font_paths:
        if os.path.exists(fp):
            try:
                return ImageFont.truetype(fp, size)
            except:
                continue
    return get_font(size, bold)

# ─── Radial gradient ───
def radial_gradient(img, center, radius, color_inner, color_outer):
    draw = ImageDraw.Draw(img)
    cx, cy = center
    for y in range(img.height):
        for x in range(img.width):
            dist = math.sqrt((x - cx)**2 + (y - cy)**2)
            t = min(dist / radius, 1.0)
            t = t ** 0.7  # ease
            r = int(color_inner[0] + (color_outer[0] - color_inner[0]) * t)
            g = int(color_inner[1] + (color_outer[1] - color_inner[1]) * t)
            b = int(color_inner[2] + (color_outer[2] - color_inner[2]) * t)
            draw.point((x, y), fill=(r, g, b))
    return img

def fast_radial_gradient(w, h, center_ratio, color_inner, color_outer, radius_ratio=1.0):
    """Faster radial gradient using scaling trick."""
    # Render at small size then scale up
    scale = 8
    sw, sh = w // scale, h // scale
    small = Image.new('RGB', (sw, sh))
    cx, cy = int(sw * center_ratio[0]), int(sh * center_ratio[1])
    radius = int(max(sw, sh) * radius_ratio)
    draw = ImageDraw.Draw(small)
    for y in range(sh):
        for x in range(sw):
            dist = math.sqrt((x - cx)**2 + (y - cy)**2)
            t = min(dist / radius, 1.0)
            t = t ** 0.7
            r = int(color_inner[0] + (color_outer[0] - color_inner[0]) * t)
            g = int(color_inner[1] + (color_outer[1] - color_inner[1]) * t)
            b = int(color_inner[2] + (color_outer[2] - color_inner[2]) * t)
            draw.point((x, y), fill=(r, g, b))
    return small.resize((w, h), Image.LANCZOS)

def vertical_gradient(draw, rect, color_top, color_bottom):
    x1, y1, x2, y2 = rect
    for y in range(y1, y2):
        t = (y - y1) / max(1, (y2 - y1))
        r = int(color_top[0] + (color_bottom[0] - color_top[0]) * t)
        g = int(color_top[1] + (color_bottom[1] - color_top[1]) * t)
        b = int(color_top[2] + (color_bottom[2] - color_top[2]) * t)
        draw.line([(x1, y), (x2, y)], fill=(r, g, b))

# ─── Draw text centered ───
def draw_centered_text(draw, text, y, font, fill, width):
    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    x = (width - tw) // 2
    draw.text((x, y), text, font=font, fill=fill)

def draw_text_with_shadow(draw, text, y, font, fill, width, shadow_color=(0,0,0,80), offset=2):
    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    x = (width - tw) // 2
    # Shadow
    draw.text((x+offset, y+offset), text, font=font, fill=shadow_color)
    draw.text((x, y), text, font=font, fill=fill)

# ─── Rounded rectangle helper ───
def rounded_rect(draw, rect, radius, fill=None, outline=None, width=1):
    x1, y1, x2, y2 = rect
    draw.rounded_rectangle(rect, radius=radius, fill=fill, outline=outline, width=width)

# ─── Status bar ───
def draw_status_bar(draw, w, h=44, dark=True):
    color = (255,255,255) if dark else TEXT_DARK
    font = get_sf_font(14)
    draw.text((20, 12), "9:41", font=font, fill=color)
    # Battery icon
    bx = w - 45
    draw.rounded_rectangle([bx, 14, bx+25, 26], radius=3, outline=color, width=1)
    draw.rectangle([bx+2, 16, bx+20, 24], fill=color)
    draw.rectangle([bx+25, 18, bx+28, 22], fill=color)
    # Signal dots
    for i in range(4):
        draw.ellipse([w-80+i*8, 16, w-74+i*8, 22], fill=color)

# ─── App bar ───
def draw_app_bar(draw, w, title, y_start=44, bg_color=WARM_BROWN, text_color=TEXT_LIGHT):
    draw.rectangle([0, y_start, w, y_start+56], fill=bg_color)
    font = get_font(22, bold=True)
    draw.text((20, y_start+16), title, font=font, fill=text_color)
    return y_start + 56

# ─── Gold decorative line ───
def draw_gold_divider(draw, y, w, margin=40):
    draw.line([(margin, y), (w-margin, y)], fill=GOLD, width=2)
    # Center diamond
    cx = w // 2
    draw.polygon([(cx-6, y), (cx, y-6), (cx+6, y), (cx, y+6)], fill=GOLD)

# ─── Mock Bible verse card ───
def draw_verse_card(draw, x, y, w, h, reference, text, font_ref, font_text):
    # Card background
    rounded_rect(draw, [x, y, x+w, y+h], radius=16, fill=(255,255,255), outline=(230,220,200), width=1)
    # Gold accent line at top
    draw.rectangle([x+20, y+8, x+w-20, y+10], fill=GOLD)
    # Reference
    draw.text((x+24, y+20), reference, font=font_ref, fill=WARM_BROWN)
    # Verse text
    draw.text((x+24, y+52), text, font=font_text, fill=TEXT_DARK)

# ─── Draw cross icon ───
def draw_cross(draw, cx, cy, size, color, width=None):
    if width is None:
        width = max(2, size // 6)
    hw = width // 2
    # Vertical
    draw.rectangle([cx-hw, cy-size, cx+hw, cy+size], fill=color)
    # Horizontal (higher up)
    arm_y = cy - size//3
    draw.rectangle([cx-size//2, arm_y-hw, cx+size//2, arm_y+hw], fill=color)

# ─── Draw open book icon ───
def draw_book_icon(draw, cx, cy, size, color):
    # Left page
    draw.polygon([
        (cx-size, cy-size//2),
        (cx-2, cy-size//3),
        (cx-2, cy+size//2),
        (cx-size, cy+size//3)
    ], fill=color, outline=color)
    # Right page
    draw.polygon([
        (cx+size, cy-size//2),
        (cx+2, cy-size//3),
        (cx+2, cy+size//2),
        (cx+size, cy+size//3)
    ], fill=color, outline=color)

# ═══════════════════════════════════════════
# 1. APP ICON (512x512)
# ═══════════════════════════════════════════
def generate_app_icon():
    print("Generating app icon (512x512)...")
    size = 512
    img = fast_radial_gradient(size, size, (0.5, 0.45), WARM_BROWN, DARK_BG, 0.9)
    draw = ImageDraw.Draw(img)

    cx, cy = size//2, size//2 - 10

    # Light rays
    for angle in range(0, 360, 15):
        rad = math.radians(angle)
        x1 = cx + int(30 * math.cos(rad))
        y1 = cy + int(30 * math.sin(rad))
        x2 = cx + int(200 * math.cos(rad))
        y2 = cy + int(200 * math.sin(rad))
        draw.line([(x1, y1), (x2, y2)], fill=(255, 220, 120, 30), width=1)

    # Glow
    for r in range(80, 20, -2):
        alpha = int(40 * (1 - r/80))
        draw.ellipse([cx-r, cy-r, cx+r, cy+r], fill=(255, 220, 140, alpha))

    # Open book
    book_w, book_h = 160, 100
    # Left page
    draw.polygon([
        (cx-book_w//2, cy),
        (cx-5, cy-20),
        (cx-5, cy+book_h-20),
        (cx-book_w//2, cy+book_h-10)
    ], fill=CREAM)
    # Right page
    draw.polygon([
        (cx+book_w//2, cy),
        (cx+5, cy-20),
        (cx+5, cy+book_h-20),
        (cx+book_w//2, cy+book_h-10)
    ], fill=CREAM)
    # Spine
    draw.line([(cx, cy-25), (cx, cy+book_h-15)], fill=DARK_BG, width=4)

    # Text lines on pages
    for i in range(5):
        lw = 40 - i*3
        ly = cy + 10 + i*14
        draw.line([(cx-book_w//2+20, ly), (cx-book_w//2+20+lw, ly)], fill=(180,160,140), width=1)
        draw.line([(cx+15, ly), (cx+15+lw, ly)], fill=(180,160,140), width=1)

    # Golden cross rising from book
    cross_cy = cy - 40
    # Cross shadow
    draw.rectangle([cx-7, cross_cy-65, cx+9, cross_cy+20], fill=(120,90,40))
    draw.rectangle([cx-30, cross_cy-40, cx+32, cross_cy-24], fill=(120,90,40))
    # Cross body
    draw.rectangle([cx-6, cross_cy-66, cx+8, cross_cy+18], fill=GOLD)
    draw.rectangle([cx-29, cross_cy-42, cx+31, cross_cy-26], fill=GOLD)
    # Cross highlight
    draw.rectangle([cx-4, cross_cy-64, cx+2, cross_cy+16], fill=SOFT_GOLD)
    draw.rectangle([cx-27, cross_cy-40, cx+2, cross_cy-30], fill=SOFT_GOLD)

    # Vignette
    for r in range(size//2, size//2 - 60, -1):
        alpha = int(80 * (1 - (r - (size//2-60)) / 60))
        draw.ellipse([cx-r, cy+10-r, cx+r, cy+10+r], outline=(20, 10, 5, alpha))

    img.save(f"{OUT}/app_icon_512.png", quality=95)
    print("  ✓ app_icon_512.png")

# ═══════════════════════════════════════════
# 2. FEATURE GRAPHIC (1024x500)
# ═══════════════════════════════════════════
def generate_feature_graphic():
    print("Generating feature graphic (1024x500)...")
    w, h = 1024, 500
    img = fast_radial_gradient(w, h, (0.5, 0.5), WARM_BROWN, DARK_BG, 1.0)
    draw = ImageDraw.Draw(img)

    # Subtle rays from center
    cx, cy = w//2, h//2
    for angle in range(0, 360, 8):
        rad = math.radians(angle)
        x2 = cx + int(400 * math.cos(rad))
        y2 = cy + int(400 * math.sin(rad))
        draw.line([(cx, cy), (x2, y2)], fill=(255, 220, 120, 15), width=1)

    # Golden border
    draw.rounded_rectangle([8, 8, w-8, h-8], radius=0, outline=GOLD, width=2)
    draw.rounded_rectangle([16, 16, w-16, h-16], radius=0, outline=DARK_GOLD, width=1)

    # App title
    title_font = get_font(64, bold=True)
    subtitle_font = get_font(24)
    tagline_font = get_font(20)

    draw_centered_text(draw, "Rhema Study Bible", h//2 - 80, title_font, GOLD, w)

    # Gold divider
    draw_gold_divider(draw, h//2 - 10, w, margin=280)

    # Tagline
    draw_centered_text(draw, "Illuminate Your Scripture Journey", h//2 + 10, subtitle_font, CREAM, w)

    # Features line
    features_font = get_sf_font(16)
    draw_centered_text(draw, "Multiple Translations  •  AI Study Insights  •  Community  •  Kids Mode", h//2 + 60, features_font, LIGHT_BROWN, w)

    # Small cross icon above title
    draw_cross(draw, cx, h//2 - 130, 20, GOLD, 4)

    # Corner decorations
    corner_size = 30
    for (ox, oy) in [(30, 30), (w-30, 30), (30, h-30), (w-30, h-30)]:
        draw.line([(ox-corner_size//2, oy), (ox+corner_size//2, oy)], fill=GOLD, width=2)
        draw.line([(ox, oy-corner_size//2), (ox, oy+corner_size//2)], fill=GOLD, width=2)

    img.save(f"{OUT}/feature_graphic.png", quality=95)
    print("  ✓ feature_graphic.png")

# ═══════════════════════════════════════════
# SCREENSHOT GENERATOR
# ═══════════════════════════════════════════
def create_screenshot_frame(w, h, title, subtitle, screen_builder, device_label=""):
    """Create a framed screenshot with title above a device mockup area."""
    img = Image.new('RGB', (w, h), CREAM)
    draw = ImageDraw.Draw(img)

    # Top gradient banner
    banner_h = int(h * 0.28)
    vertical_gradient(draw, [0, 0, w, banner_h], DARK_BG, WARM_BROWN)

    # Title text
    title_size = int(w * 0.055)
    sub_size = int(w * 0.032)
    title_font = get_font(title_size, bold=True)
    sub_font = get_font(sub_size)

    draw_centered_text(draw, title, int(banner_h * 0.25), title_font, GOLD, w)
    draw_centered_text(draw, subtitle, int(banner_h * 0.25) + title_size + 10, sub_font, CREAM, w)

    # Gold divider in banner
    div_y = int(banner_h * 0.25) + title_size + sub_size + 25
    line_w = int(w * 0.2)
    draw.line([(w//2 - line_w, div_y), (w//2 + line_w, div_y)], fill=GOLD, width=2)

    # Device frame area
    device_margin = int(w * 0.08)
    device_top = banner_h + int(h * 0.03)
    device_w = w - device_margin * 2
    device_h = h - device_top - int(h * 0.04)
    device_x = device_margin

    # Device shadow
    shadow_offset = 8
    draw.rounded_rectangle(
        [device_x + shadow_offset, device_top + shadow_offset,
         device_x + device_w + shadow_offset, device_top + device_h + shadow_offset],
        radius=24, fill=(0, 0, 0, 40)
    )

    # Device bezel
    draw.rounded_rectangle(
        [device_x - 4, device_top - 4, device_x + device_w + 4, device_top + device_h + 4],
        radius=28, fill=DEEP_BROWN
    )

    # Device screen area
    screen_rect = [device_x, device_top, device_x + device_w, device_top + device_h]
    draw.rounded_rectangle(screen_rect, radius=24, fill=CREAM)

    # Build the screen content
    screen_builder(draw, device_x, device_top, device_w, device_h)

    return img


# ─── Screen Content Builders ───

def screen_bible_reading(draw, sx, sy, sw, sh):
    """Bible reading screen."""
    # Status bar area
    draw.rectangle([sx, sy, sx+sw, sy+36], fill=WARM_BROWN)
    sf = get_sf_font(12)
    draw.text((sx+16, sy+10), "9:41", font=sf, fill=TEXT_LIGHT)

    # App bar
    bar_y = sy + 36
    draw.rectangle([sx, bar_y, sx+sw, bar_y+50], fill=WARM_BROWN)
    bar_font = get_font(18, bold=True)
    draw.text((sx+16, bar_y+14), "Genesis 1", font=bar_font, fill=TEXT_LIGHT)
    # Translation badge
    badge_font = get_sf_font(11)
    bw = 40
    draw.rounded_rectangle([sx+sw-60, bar_y+14, sx+sw-16, bar_y+34], radius=10, fill=GOLD)
    draw.text((sx+sw-55, bar_y+16), "KJV", font=badge_font, fill=DEEP_BROWN)

    content_y = bar_y + 60
    verse_font = get_font(14)
    verse_num_font = get_font(11, bold=True)

    verses = [
        ("1", "In the beginning God created the heaven and the earth."),
        ("2", "And the earth was without form, and void; and darkness was upon the face of the deep."),
        ("3", "And God said, Let there be light: and there was light."),
        ("4", "And God saw the light, that it was good: and God divided the light from the darkness."),
        ("5", "And God called the light Day, and the darkness he called Night."),
        ("6", "And God said, Let there be a firmament in the midst of the waters."),
        ("7", "And God made the firmament, and divided the waters which were under the firmament."),
    ]

    y = content_y
    for num, text in verses:
        if y > sy + sh - 40:
            break
        # Verse number
        draw.text((sx+20, y), num, font=verse_num_font, fill=GOLD)
        # Verse text (wrap manually)
        chars_per_line = max(20, (sw - 60) // 8)
        words = text.split()
        line = ""
        tx = sx + 40
        for word in words:
            if len(line + " " + word) > chars_per_line:
                draw.text((tx, y), line.strip(), font=verse_font, fill=TEXT_DARK)
                y += 20
                line = word
            else:
                line += " " + word
        if line:
            draw.text((tx, y), line.strip(), font=verse_font, fill=TEXT_DARK)
            y += 20
        # Highlight verse 3
        if num == "3":
            draw.rectangle([sx+16, y-40, sx+sw-16, y+2], fill=(255, 243, 200, 80))
        y += 12

    # Bottom nav bar
    nav_y = sy + sh - 56
    draw.rectangle([sx, nav_y, sx+sw, sy+sh], fill=(255,255,255))
    draw.line([(sx, nav_y), (sx+sw, nav_y)], fill=(220,210,200), width=1)

    icons = ["📖", "🔍", "⭐", "👥", "⚙"]
    labels = ["Read", "Search", "Saved", "Community", "Settings"]
    nav_font = get_sf_font(9)
    for i, (icon, label) in enumerate(zip(icons, labels)):
        ix = sx + (sw // 5) * i + sw // 10
        color = GOLD if i == 0 else LIGHT_BROWN
        draw.text((ix-4, nav_y+8), icon, font=get_sf_font(16), fill=color)
        bbox = draw.textbbox((0,0), label, font=nav_font)
        lw = bbox[2] - bbox[0]
        draw.text((ix - lw//2, nav_y+30), label, font=nav_font, fill=color)


def screen_verse_of_day(draw, sx, sy, sw, sh):
    """Verse of the Day screen."""
    draw.rectangle([sx, sy, sx+sw, sy+36], fill=DARK_BG)
    sf = get_sf_font(12)
    draw.text((sx+16, sy+10), "9:41", font=sf, fill=TEXT_LIGHT)

    # Gradient header
    header_h = int(sh * 0.45)
    vertical_gradient(draw, [sx, sy+36, sx+sw, sy+36+header_h], DARK_BG, WARM_BROWN)

    # Cross at top
    draw_cross(draw, sx+sw//2, sy+80, 20, GOLD, 4)

    # "Verse of the Day" label
    label_font = get_sf_font(12)
    draw_centered_text(draw, "VERSE OF THE DAY", sy+115, label_font, SOFT_GOLD, sw)

    # Date
    date_font = get_sf_font(10)
    draw_centered_text(draw, "April 15, 2026", sy+135, date_font, LIGHT_BROWN, sw)

    # Verse card
    card_y = sy + 160
    card_h = int(sh * 0.28)
    card_margin = 24
    draw.rounded_rectangle(
        [sx+card_margin, card_y, sx+sw-card_margin, card_y+card_h],
        radius=16, fill=(255,255,255), outline=GOLD, width=1
    )

    # Gold accent
    draw.rectangle([sx+card_margin+16, card_y+12, sx+card_margin+60, card_y+14], fill=GOLD)

    verse_font = get_font(13)
    ref_font = get_font(12, bold=True)

    # Verse text
    verse_lines = [
        "\"For I know the plans I have",
        "for you,\" declares the LORD,",
        "\"plans to prosper you and not",
        "to harm you, plans to give",
        "you hope and a future.\""
    ]
    for i, line in enumerate(verse_lines):
        draw.text((sx+card_margin+20, card_y+28+i*20), line, font=verse_font, fill=TEXT_DARK)

    draw.text((sx+card_margin+20, card_y+card_h-40), "— Jeremiah 29:11", font=ref_font, fill=GOLD)

    # Action buttons below card
    btn_y = card_y + card_h + 20
    btn_w = (sw - card_margin*2 - 12) // 3
    btn_font = get_sf_font(11)
    btn_labels = ["📋 Copy", "📤 Share", "⭐ Save"]
    for i, label in enumerate(btn_labels):
        bx = sx + card_margin + i * (btn_w + 6)
        draw.rounded_rectangle([bx, btn_y, bx+btn_w, btn_y+36], radius=18, fill=WARM_BROWN)
        bbox = draw.textbbox((0,0), label, font=btn_font)
        lw = bbox[2] - bbox[0]
        draw.text((bx + (btn_w-lw)//2, btn_y+10), label, font=btn_font, fill=TEXT_LIGHT)

    # Reading plan section
    section_y = btn_y + 60
    section_font = get_font(14, bold=True)
    draw.text((sx+24, section_y), "Today's Reading Plan", font=section_font, fill=WARM_BROWN)
    draw.rectangle([sx+24, section_y+24, sx+sw-24, section_y+26], fill=(230,220,200))

    plan_font = get_sf_font(12)
    plans = [("Genesis 1-3", "Creation"), ("Psalm 1", "The Blessed"), ("John 1:1-14", "The Word")]
    for i, (ref, desc) in enumerate(plans):
        py = section_y + 36 + i * 36
        draw.ellipse([sx+28, py+4, sx+40, py+16], fill=GOLD)
        draw.text((sx+48, py), ref, font=plan_font, fill=TEXT_DARK)
        draw.text((sx+sw-100, py), desc, font=plan_font, fill=LIGHT_BROWN)


def screen_ai_insights(draw, sx, sy, sw, sh):
    """AI Study Insights screen."""
    draw.rectangle([sx, sy, sx+sw, sy+36], fill=WARM_BROWN)
    sf = get_sf_font(12)
    draw.text((sx+16, sy+10), "9:41", font=sf, fill=TEXT_LIGHT)

    bar_y = sy + 36
    draw.rectangle([sx, bar_y, sx+sw, bar_y+50], fill=WARM_BROWN)
    bar_font = get_font(18, bold=True)
    draw.text((sx+16, bar_y+14), "AI Study Insights", font=bar_font, fill=TEXT_LIGHT)

    # Verse being studied
    vy = bar_y + 60
    draw.rounded_rectangle([sx+16, vy, sx+sw-16, vy+50], radius=12, fill=(255,243,220))
    small_font = get_sf_font(10)
    draw.text((sx+24, vy+6), "STUDYING", font=small_font, fill=LIGHT_BROWN)
    ref_font = get_font(14, bold=True)
    draw.text((sx+24, vy+22), "John 3:16 (KJV)", font=ref_font, fill=WARM_BROWN)

    # AI Response card
    ai_y = vy + 65
    card_h = int(sh * 0.55)
    draw.rounded_rectangle([sx+16, ai_y, sx+sw-16, ai_y+card_h], radius=16, fill=(255,255,255), outline=(230,220,200))

    # AI icon
    draw.rounded_rectangle([sx+24, ai_y+12, sx+60, ai_y+36], radius=8, fill=GOLD)
    ai_label = get_sf_font(10, bold=True)
    draw.text((sx+30, ai_y+16), "✨ AI", font=ai_label, fill=DEEP_BROWN)

    # AI response text
    ai_font = get_sf_font(11)
    ai_bold = get_sf_font(12, bold=True)

    ty = ai_y + 48
    draw.text((sx+24, ty), "Historical Context", font=ai_bold, fill=WARM_BROWN)
    ty += 22
    context_lines = [
        "This verse, spoken by Jesus to",
        "Nicodemus, encapsulates the core",
        "of the Gospel message. Written by",
        "John around 90 AD, it reflects the",
        "early church's understanding of",
        "God's redemptive love."
    ]
    for line in context_lines:
        draw.text((sx+24, ty), line, font=ai_font, fill=TEXT_DARK)
        ty += 17

    ty += 10
    draw.text((sx+24, ty), "Key Themes", font=ai_bold, fill=WARM_BROWN)
    ty += 22
    themes = ["• God's unconditional love (agape)", "• Eternal life through faith", "• The gift of salvation"]
    for theme in themes:
        draw.text((sx+24, ty), theme, font=ai_font, fill=TEXT_DARK)
        ty += 18

    ty += 10
    draw.text((sx+24, ty), "Cross References", font=ai_bold, fill=WARM_BROWN)
    ty += 22
    refs = ["Romans 5:8  •  1 John 4:9  •  Eph 2:8-9"]
    for ref in refs:
        draw.text((sx+24, ty), ref, font=ai_font, fill=GOLD)
        ty += 18

    # Input bar at bottom
    input_y = ai_y + card_h + 12
    draw.rounded_rectangle([sx+16, input_y, sx+sw-16, input_y+40], radius=20, fill=(245,240,235), outline=(220,210,200))
    draw.text((sx+28, input_y+10), "Ask a question about this verse...", font=get_sf_font(12), fill=LIGHT_BROWN)
    draw.rounded_rectangle([sx+sw-54, input_y+4, sx+sw-20, input_y+36], radius=16, fill=GOLD)
    draw.text((sx+sw-46, input_y+10), "Ask", font=get_sf_font(12, bold=True), fill=DEEP_BROWN)


def screen_search(draw, sx, sy, sw, sh):
    """Search screen."""
    draw.rectangle([sx, sy, sx+sw, sy+36], fill=WARM_BROWN)
    sf = get_sf_font(12)
    draw.text((sx+16, sy+10), "9:41", font=sf, fill=TEXT_LIGHT)

    bar_y = sy + 36
    draw.rectangle([sx, bar_y, sx+sw, bar_y+50], fill=WARM_BROWN)
    bar_font = get_font(18, bold=True)
    draw.text((sx+16, bar_y+14), "Search", font=bar_font, fill=TEXT_LIGHT)

    # Search bar
    sy2 = bar_y + 60
    draw.rounded_rectangle([sx+16, sy2, sx+sw-16, sy2+44], radius=22, fill=(255,255,255), outline=GOLD, width=2)
    draw.text((sx+44, sy2+12), "love one another", font=get_sf_font(14), fill=TEXT_DARK)
    draw.text((sx+24, sy2+12), "🔍", font=get_sf_font(14))

    # Results
    results_y = sy2 + 56
    result_font = get_font(13, bold=True)
    verse_font = get_sf_font(11)

    results = [
        ("John 13:34", "A new commandment I give unto you, That ye love one another; as I have loved you..."),
        ("1 John 4:7", "Beloved, let us love one another: for love is of God; and every one that loveth..."),
        ("Romans 13:8", "Owe no man any thing, but to love one another: for he that loveth another hath..."),
        ("1 Peter 1:22", "Seeing ye have purified your souls in obeying the truth through the Spirit unto..."),
        ("1 John 3:11", "For this is the message that ye heard from the beginning, that we should love..."),
        ("1 Thess 4:9", "But as touching brotherly love ye need not that I write unto you: for ye..."),
    ]

    for i, (ref, text) in enumerate(results):
        ry = results_y + i * 64
        if ry > sy + sh - 80:
            break
        draw.rounded_rectangle([sx+16, ry, sx+sw-16, ry+56], radius=12, fill=(255,255,255), outline=(235,225,215))
        draw.text((sx+24, ry+8), ref, font=result_font, fill=WARM_BROWN)
        # Truncate text
        max_chars = max(20, (sw - 56) // 7)
        display_text = text[:max_chars] + "..." if len(text) > max_chars else text
        draw.text((sx+24, ry+30), display_text, font=verse_font, fill=TEXT_DARK)

    # Result count
    count_font = get_sf_font(11)
    draw.text((sx+20, sy2+44+4), "Found 47 results for \"love one another\"", font=count_font, fill=LIGHT_BROWN)


def screen_community(draw, sx, sy, sw, sh):
    """Community screen."""
    draw.rectangle([sx, sy, sx+sw, sy+36], fill=WARM_BROWN)
    sf = get_sf_font(12)
    draw.text((sx+16, sy+10), "9:41", font=sf, fill=TEXT_LIGHT)

    bar_y = sy + 36
    draw.rectangle([sx, bar_y, sx+sw, bar_y+50], fill=WARM_BROWN)
    bar_font = get_font(18, bold=True)
    draw.text((sx+16, bar_y+14), "Community", font=bar_font, fill=TEXT_LIGHT)

    # Tabs
    tab_y = bar_y + 50
    draw.rectangle([sx, tab_y, sx+sw, tab_y+40], fill=(255,255,255))
    tab_font = get_sf_font(12, bold=True)
    tab_w = sw // 3
    tabs = ["Reflections", "Questions", "Prayer"]
    for i, tab in enumerate(tabs):
        tx = sx + i * tab_w
        color = WARM_BROWN if i == 0 else LIGHT_BROWN
        bbox = draw.textbbox((0,0), tab, font=tab_font)
        tw = bbox[2] - bbox[0]
        draw.text((tx + (tab_w-tw)//2, tab_y+12), tab, font=tab_font, fill=color)
        if i == 0:
            draw.rectangle([tx+10, tab_y+36, tx+tab_w-10, tab_y+39], fill=GOLD)

    # Posts
    post_y = tab_y + 48
    posts = [
        ("Grace M.", "2h ago", "The way Psalm 23 describes God as our shepherd gives me so much peace...", "❤️ 24  💬 8"),
        ("David K.", "5h ago", "Reading through Genesis this morning. The creation story never gets old!", "❤️ 18  💬 12"),
        ("Sarah L.", "1d ago", "John 3:16 hit different today during my quiet time. God's love is truly...", "❤️ 42  💬 15"),
    ]

    for name, time, text, stats in posts:
        if post_y > sy + sh - 80:
            break
        ph = 100
        draw.rounded_rectangle([sx+16, post_y, sx+sw-16, post_y+ph], radius=12, fill=(255,255,255), outline=(235,225,215))

        # Avatar circle
        draw.ellipse([sx+24, post_y+12, sx+48, post_y+36], fill=GOLD)
        init_font = get_sf_font(10, bold=True)
        draw.text((sx+30, post_y+16), name[0], font=init_font, fill=DEEP_BROWN)

        # Name and time
        name_font = get_sf_font(12, bold=True)
        time_font = get_sf_font(10)
        draw.text((sx+56, post_y+12), name, font=name_font, fill=TEXT_DARK)
        draw.text((sx+56, post_y+28), time, font=time_font, fill=LIGHT_BROWN)

        # Post text
        post_font = get_sf_font(11)
        max_chars = max(20, (sw - 56) // 6)
        display = text[:max_chars] + "..." if len(text) > max_chars else text
        draw.text((sx+24, post_y+50), display, font=post_font, fill=TEXT_DARK)

        # Stats
        draw.text((sx+24, post_y+ph-24), stats, font=get_sf_font(10), fill=LIGHT_BROWN)

        post_y += ph + 12

    # FAB
    fab_x = sx + sw - 72
    fab_y = sy + sh - 72
    draw.ellipse([fab_x, fab_y, fab_x+52, fab_y+52], fill=GOLD)
    draw.text((fab_x+16, fab_y+12), "✏️", font=get_sf_font(20))


def screen_bookmarks(draw, sx, sy, sw, sh):
    """Bookmarks/Saved screen."""
    draw.rectangle([sx, sy, sx+sw, sy+36], fill=WARM_BROWN)
    sf = get_sf_font(12)
    draw.text((sx+16, sy+10), "9:41", font=sf, fill=TEXT_LIGHT)

    bar_y = sy + 36
    draw.rectangle([sx, bar_y, sx+sw, bar_y+50], fill=WARM_BROWN)
    bar_font = get_font(18, bold=True)
    draw.text((sx+16, bar_y+14), "Saved Verses", font=bar_font, fill=TEXT_LIGHT)

    # Bookmarks
    bm_y = bar_y + 60
    bookmarks = [
        ("Jeremiah 29:11", "For I know the plans I have for you...", "🟡"),
        ("Psalm 23:1", "The LORD is my shepherd; I shall not want...", "🔴"),
        ("Philippians 4:13", "I can do all things through Christ which...", "🟢"),
        ("Proverbs 3:5-6", "Trust in the LORD with all thine heart...", "🟡"),
        ("Isaiah 41:10", "Fear thou not; for I am with thee...", "🔵"),
        ("Romans 8:28", "And we know that all things work together...", "🟢"),
    ]

    bm_font = get_font(13, bold=True)
    text_font = get_sf_font(11)

    for ref, text, color in bookmarks:
        if bm_y > sy + sh - 80:
            break
        draw.rounded_rectangle([sx+16, bm_y, sx+sw-16, bm_y+64], radius=12, fill=(255,255,255), outline=(235,225,215))

        # Color tag
        draw.rounded_rectangle([sx+16, bm_y, sx+22, bm_y+64], radius=4, fill=GOLD)

        # Bookmark icon
        draw.text((sx+sw-40, bm_y+8), "🔖", font=get_sf_font(16))

        draw.text((sx+32, bm_y+10), ref, font=bm_font, fill=WARM_BROWN)
        max_chars = max(20, (sw - 72) // 7)
        display = text[:max_chars] + "..." if len(text) > max_chars else text
        draw.text((sx+32, bm_y+34), display, font=text_font, fill=TEXT_DARK)

        bm_y += 76


def screen_kids_mode(draw, sx, sy, sw, sh):
    """Kids Mode screen."""
    # Colorful header
    draw.rectangle([sx, sy, sx+sw, sy+36], fill=(100, 181, 246))
    sf = get_sf_font(12)
    draw.text((sx+16, sy+10), "9:41", font=sf, fill=(255,255,255))

    bar_y = sy + 36
    draw.rectangle([sx, bar_y, sx+sw, bar_y+50], fill=(66, 165, 245))
    bar_font = get_font(18, bold=True)
    draw.text((sx+16, bar_y+14), "Kids Bible 🌈", font=bar_font, fill=(255,255,255))

    content_y = bar_y + 60

    # Fun verse card
    card_h = int(sh * 0.22)
    draw.rounded_rectangle([sx+16, content_y, sx+sw-16, content_y+card_h], radius=20, fill=(255, 248, 225), outline=(255, 213, 79), width=2)

    # Star decoration
    star_font = get_sf_font(24)
    draw.text((sx+24, content_y+8), "⭐", font=star_font)
    draw.text((sx+sw-48, content_y+8), "⭐", font=star_font)

    label_font = get_sf_font(11, bold=True)
    draw.text((sx+sw//2-40, content_y+14), "TODAY'S VERSE", font=label_font, fill=(255, 152, 0))

    verse_font = get_font(13)
    verse_lines = [
        "\"For God so loved the world",
        "that He gave His only Son.\"",
        "— John 3:16"
    ]
    for i, line in enumerate(verse_lines):
        bbox = draw.textbbox((0,0), line, font=verse_font)
        lw = bbox[2] - bbox[0]
        draw.text((sx + (sw-lw)//2, content_y + 40 + i*22), line, font=verse_font, fill=(62, 39, 35))

    # Bible stories section
    stories_y = content_y + card_h + 16
    section_font = get_font(14, bold=True)
    draw.text((sx+20, stories_y), "Bible Stories", font=section_font, fill=(66, 165, 245))

    stories = [
        ("🌍", "Creation", "In the beginning...", (200, 230, 255)),
        ("🚢", "Noah's Ark", "God told Noah to build...", (200, 255, 220)),
        ("🦁", "Daniel & Lions", "Daniel prayed to God...", (255, 230, 200)),
        ("🐋", "Jonah & Whale", "God had a special plan...", (230, 200, 255)),
    ]

    story_y = stories_y + 28
    card_w = (sw - 48) // 2
    card_h2 = 80
    for i, (emoji, title, desc, bg) in enumerate(stories):
        col = i % 2
        row = i // 2
        cx2 = sx + 16 + col * (card_w + 16)
        cy2 = story_y + row * (card_h2 + 12)

        if cy2 + card_h2 > sy + sh - 20:
            break

        draw.rounded_rectangle([cx2, cy2, cx2+card_w, cy2+card_h2], radius=16, fill=bg)
        draw.text((cx2+10, cy2+6), emoji, font=get_sf_font(22))
        draw.text((cx2+10, cy2+34), title, font=get_sf_font(12, bold=True), fill=TEXT_DARK)
        draw.text((cx2+10, cy2+52), desc[:18]+"...", font=get_sf_font(9), fill=LIGHT_BROWN)


def screen_translations(draw, sx, sy, sw, sh):
    """Multiple Translations screen."""
    draw.rectangle([sx, sy, sx+sw, sy+36], fill=WARM_BROWN)
    sf = get_sf_font(12)
    draw.text((sx+16, sy+10), "9:41", font=sf, fill=TEXT_LIGHT)

    bar_y = sy + 36
    draw.rectangle([sx, bar_y, sx+sw, bar_y+50], fill=WARM_BROWN)
    bar_font = get_font(18, bold=True)
    draw.text((sx+16, bar_y+14), "Translations", font=bar_font, fill=TEXT_LIGHT)

    # Studying verse header
    header_y = bar_y + 58
    draw.rounded_rectangle([sx+16, header_y, sx+sw-16, header_y+40], radius=10, fill=(255,243,220))
    ref_font = get_font(13, bold=True)
    draw.text((sx+24, header_y+10), "Comparing: John 3:16", font=ref_font, fill=WARM_BROWN)

    # Translation cards
    ty = header_y + 52
    translations = [
        ("KJV", "King James Version", "For God so loved the world, that he gave his only begotten Son, that whosoever believeth in him should not perish, but have everlasting life."),
        ("ASV", "American Standard", "For God so loved the world, that he gave his only begotten Son, that whosoever believeth on him should not perish, but have eternal life."),
        ("WEB", "World English Bible", "For God so loved the world, that he gave his only born Son, that whoever believes in him should not perish, but have eternal life."),
        ("BBE", "Bible in Basic English", "For God had such love for the world that he gave his only Son, so that whoever has faith in him may not come to destruction but have eternal life."),
    ]

    for abbr, name, text in translations:
        if ty > sy + sh - 60:
            break
        card_h = 90
        draw.rounded_rectangle([sx+16, ty, sx+sw-16, ty+card_h], radius=12, fill=(255,255,255), outline=(235,225,215))

        # Badge
        badge_w = 36
        draw.rounded_rectangle([sx+24, ty+10, sx+24+badge_w, ty+30], radius=8, fill=GOLD)
        badge_font = get_sf_font(10, bold=True)
        draw.text((sx+28, ty+13), abbr, font=badge_font, fill=DEEP_BROWN)

        # Name
        name_font = get_sf_font(11)
        draw.text((sx+24+badge_w+8, ty+12), name, font=name_font, fill=LIGHT_BROWN)

        # Text
        t_font = get_sf_font(10)
        chars = max(20, (sw - 56) // 6)
        lines = [text[i:i+chars] for i in range(0, min(len(text), chars*3), chars)]
        for i, line in enumerate(lines[:3]):
            draw.text((sx+24, ty+36+i*14), line, font=t_font, fill=TEXT_DARK)

        ty += card_h + 10


# ═══════════════════════════════════════════
# GENERATE ALL SCREENSHOTS
# ═══════════════════════════════════════════
def generate_screenshots(w, h, folder, label):
    """Generate all screenshots at given dimensions."""
    print(f"Generating {label} screenshots ({w}x{h})...")

    screens = [
        ("01_bible_reading", "Scripture Reading", "Beautiful, immersive Bible reading", screen_bible_reading),
        ("02_verse_of_day", "Verse of the Day", "Daily inspiration & reading plans", screen_verse_of_day),
        ("03_ai_insights", "AI Study Insights", "Deep theological understanding", screen_ai_insights),
        ("04_search", "Powerful Search", "Find any verse instantly", screen_search),
        ("05_community", "Community", "Share reflections & grow together", screen_community),
        ("06_bookmarks", "Saved Verses", "Organize your favorite passages", screen_bookmarks),
        ("07_kids_mode", "Kids Mode", "Scripture for young readers", screen_kids_mode),
        ("08_translations", "Multiple Translations", "Compare across 4 versions", screen_translations),
    ]

    for filename, title, subtitle, builder in screens:
        img = create_screenshot_frame(w, h, title, subtitle, builder, label)
        path = f"{OUT}/{folder}/{filename}.png"
        img.save(path, quality=95)
        print(f"  ✓ {folder}/{filename}.png")


# ═══════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════
if __name__ == "__main__":
    print("=" * 50)
    print("Generating Play Store Assets")
    print("=" * 50)

    generate_app_icon()
    generate_feature_graphic()

    # Phone screenshots: 1080x1920
    generate_screenshots(1080, 1920, "phone", "Phone")

    # 7-inch tablet: 1200x1920
    generate_screenshots(1200, 1920, "tablet_7", "7-inch Tablet")

    # 10-inch tablet: 1600x2560
    generate_screenshots(1600, 2560, "tablet_10", "10-inch Tablet")

    print("\n" + "=" * 50)
    print("✅ All assets generated!")
    print(f"📁 Output: {OUT}/")
    print("=" * 50)
    print("\nFiles:")
    for root, dirs, files in os.walk(OUT):
        for f in sorted(files):
            if f.endswith('.png'):
                path = os.path.join(root, f)
                size_mb = os.path.getsize(path) / (1024*1024)
                print(f"  {os.path.relpath(path, OUT):45s} {size_mb:.1f} MB")
