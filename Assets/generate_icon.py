#!/usr/bin/env python3
"""Generate MDPreview app icon at 1024x1024."""

from PIL import Image, ImageDraw, ImageFont, ImageFilter
import math

SIZE = 1024
PADDING = 80

# Colors
BLUE = (74, 158, 255)    # #4A9EFF
PURPLE = (124, 58, 237)  # #7C3AED
DOC_BG = (252, 252, 255)
SHADOW_COLOR = (30, 20, 60, 90)


def make_gradient_image(width, height, c1, c2, direction="horizontal"):
    """Create a gradient image efficiently using numpy-free approach."""
    img = Image.new("RGBA", (width, height))
    draw = ImageDraw.Draw(img)
    if direction == "horizontal":
        for x in range(width):
            t = x / max(width - 1, 1)
            r = int(c1[0] + (c2[0] - c1[0]) * t)
            g = int(c1[1] + (c2[1] - c1[1]) * t)
            b = int(c1[2] + (c2[2] - c1[2]) * t)
            draw.line([(x, 0), (x, height - 1)], fill=(r, g, b, 255))
    elif direction == "vertical":
        for y in range(height):
            t = y / max(height - 1, 1)
            r = int(c1[0] + (c2[0] - c1[0]) * t)
            g = int(c1[1] + (c2[1] - c1[1]) * t)
            b = int(c1[2] + (c2[2] - c1[2]) * t)
            draw.line([(0, y), (width - 1, y)], fill=(r, g, b, 255))
    elif direction == "diagonal":
        for y in range(height):
            for x in range(width):
                t = (x / max(width - 1, 1) * 0.55 + y / max(height - 1, 1) * 0.45)
                t = max(0.0, min(1.0, t))
                r = int(c1[0] + (c2[0] - c1[0]) * t)
                g = int(c1[1] + (c2[1] - c1[1]) * t)
                b = int(c1[2] + (c2[2] - c1[2]) * t)
                img.putpixel((x, y), (r, g, b, 255))
    return img


def load_font(size):
    """Load the best available font."""
    font_paths = [
        "/System/Library/Fonts/SFNS.ttf",
        "/System/Library/Fonts/SFCompact.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
        "/System/Library/Fonts/HelveticaNeue.ttc",
        "/Library/Fonts/Arial Unicode.ttf",
    ]
    for fp in font_paths:
        try:
            return ImageFont.truetype(fp, size)
        except (IOError, OSError):
            continue
    return ImageFont.load_default()


def create_icon():
    canvas = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))

    # Document shape
    doc_x = PADDING
    doc_y = PADDING - 20
    doc_w = SIZE - 2 * PADDING
    doc_h = SIZE - 2 * PADDING + 40
    doc_r = 48

    # ── Shadow ──
    shadow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(shadow)
    sdraw.rounded_rectangle(
        [doc_x + 4, doc_y + 14, doc_x + doc_w - 4, doc_y + doc_h + 14],
        radius=doc_r, fill=SHADOW_COLOR,
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(35))
    canvas = Image.alpha_composite(canvas, shadow)

    # ── Document body ──
    doc = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    ddraw = ImageDraw.Draw(doc)
    ddraw.rounded_rectangle(
        [doc_x, doc_y, doc_x + doc_w, doc_y + doc_h],
        radius=doc_r, fill=(*DOC_BG, 255),
    )
    canvas = Image.alpha_composite(canvas, doc)

    # ── Thin border ──
    border = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    ImageDraw.Draw(border).rounded_rectangle(
        [doc_x, doc_y, doc_x + doc_w, doc_y + doc_h],
        radius=doc_r, outline=(190, 195, 215, 50), width=2,
    )
    canvas = Image.alpha_composite(canvas, border)

    # ── Gradient accent bar (top of document) ──
    bar_h = 14
    bar_full = make_gradient_image(doc_w, bar_h + doc_r, BLUE, PURPLE, "horizontal")
    bar_canvas = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    bar_canvas.paste(bar_full, (doc_x, doc_y))
    # Mask to document shape
    mask = Image.new("L", (SIZE, SIZE), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [doc_x, doc_y, doc_x + doc_w, doc_y + doc_h],
        radius=doc_r, fill=255,
    )
    ImageDraw.Draw(mask).rectangle([0, doc_y + bar_h + doc_r, SIZE, SIZE], fill=0)
    bar_canvas.putalpha(mask)
    canvas = Image.alpha_composite(canvas, bar_canvas)

    # ── Faint text lines (decorative) ──
    lines = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    ldraw = ImageDraw.Draw(lines)
    ly_start = doc_y + bar_h + doc_r + 55
    lx = doc_x + 75
    widths = [0.72, 0.52, 0.62, 0.42, 0.68, 0.48]
    max_lw = doc_w - 150
    for i, wf in enumerate(widths):
        ly = ly_start + i * 34
        if ly > doc_y + doc_h - 280:
            break
        ldraw.rounded_rectangle(
            [lx, ly, lx + int(max_lw * wf), ly + 11],
            radius=5, fill=(195, 200, 218, 45),
        )
    canvas = Image.alpha_composite(canvas, lines)

    # ── "MD" gradient text ──
    font = load_font(300)
    text = "MD"

    # Measure text
    tmp = ImageDraw.Draw(Image.new("RGBA", (1, 1)))
    bbox = tmp.textbbox((0, 0), text, font=font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]

    # Position: centered, shifted down slightly
    tx = doc_x + (doc_w - tw) // 2 - bbox[0]
    ty = doc_y + (doc_h - th) // 2 - bbox[1] + 65

    # Create text mask
    text_mask = Image.new("L", (SIZE, SIZE), 0)
    ImageDraw.Draw(text_mask).text((tx, ty), text, font=font, fill=255)

    # Create gradient, crop to text bounding area for speed
    # The text is drawn at (tx, ty). textbbox gives the actual glyph bounds relative to that origin.
    # So actual pixel area is (tx + bbox[0], ty + bbox[1]) to (tx + bbox[2], ty + bbox[3]).
    margin = 20
    gx0 = max(tx + bbox[0] - margin, 0)
    gy0 = max(ty + bbox[1] - margin, 0)
    gx1 = min(tx + bbox[2] + margin, SIZE)
    gy1 = min(ty + bbox[3] + margin, SIZE)
    gw, gh = gx1 - gx0, gy1 - gy0

    print(f"  Text drawn at ({tx},{ty}), bbox={bbox}, grad region ({gx0},{gy0})-({gx1},{gy1}) = {gw}x{gh}")
    grad_crop = make_gradient_image(gw, gh, BLUE, PURPLE, "diagonal")
    grad_full = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    grad_full.paste(grad_crop, (gx0, gy0))
    grad_full.putalpha(text_mask)
    canvas = Image.alpha_composite(canvas, grad_full)

    # ── Markdown down-arrow chevron ──
    arrow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    adraw = ImageDraw.Draw(arrow)
    cx = doc_x + doc_w // 2
    atop = ty + bbox[3] + 30
    aw, ah = 55, 42
    pts = [(cx - aw, atop), (cx, atop + ah), (cx + aw, atop)]
    adraw.line(pts, fill=(*PURPLE, 200), width=10, joint="curve")
    canvas = Image.alpha_composite(canvas, arrow)

    return canvas


if __name__ == "__main__":
    print("Generating MDPreview icon (1024x1024)...")
    icon = create_icon()
    out = "/Users/kazu42/dev/mdpreview/Assets/AppIcon.png"
    icon.save(out, "PNG")
    print(f"Saved: {out}")
    print("Done.")
