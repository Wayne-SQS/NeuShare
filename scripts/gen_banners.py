"""Generate gradient banner images for NeuShare banners."""
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import os, math, random

OUT = os.path.join(os.path.dirname(__file__), '..', 'entry', 'src', 'main', 'resources', 'base', 'media')
os.makedirs(OUT, exist_ok=True)

W, H = 960, 340  # 横幅尺寸
random.seed(42)

BANNERS = [
    {"name": "banner_ai_coding", "colors": ["#1A1A2E", "#2C3E6B", "#4A6594"], "emoji": "🤖",
     "shapes": "circuit"},
    {"name": "banner_ml_course", "colors": ["#2D1A1A", "#7B2D2E", "#C0392B"], "emoji": "🧠",
     "shapes": "neural"},
    {"name": "banner_booklist", "colors": ["#3D2A1A", "#8B5A2B", "#D4914A"], "emoji": "📚",
     "shapes": "shelves"},
    {"name": "banner_github_speed", "colors": ["#1A2E24", "#2D5A45", "#3A8C6E"], "emoji": "⚡",
     "shapes": "nodes"},
]

def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))

def hex_to_rgb(h):
    h = h.lstrip('#')
    return tuple(int(h[i:i+2], 16) for i in range(0, 6, 2))

def draw_circuit(draw, w, h):
    """Draw circuit-board style lines."""
    for _ in range(12):
        x1 = random.randint(0, w)
        y1 = random.randint(0, h)
        points = [(x1, y1)]
        x, y = x1, y1
        for _ in range(random.randint(2, 5)):
            if random.random() < 0.5:
                x = x + random.randint(-120, 120)
            else:
                y = y + random.randint(-60, 60)
            points.append((max(0, min(w, x)), max(0, min(h, y))))
        for i in range(len(points) - 1):
            draw.line([points[i], points[i+1]], fill=(255, 255, 255, 12), width=1)
        # dot at end
        ex, ey = points[-1]
        r = 4
        draw.ellipse([ex-r, ey-r, ex+r, ey+r], fill=(255, 255, 255, 35))

def draw_neural(draw, w, h):
    """Draw neural-network style nodes and connections."""
    nodes = [(random.randint(60, w-60), random.randint(40, h-40)) for _ in range(18)]
    for i, (x1, y1) in enumerate(nodes):
        for j in range(i+1, min(i+5, len(nodes))):
            x2, y2 = nodes[j]
            dist = math.hypot(x2-x1, y2-y1)
            if dist < 280:
                alpha = int(30 * (1 - dist / 280))
                draw.line([(x1, y1), (x2, y2)], fill=(255, 255, 255, alpha), width=1)
        r = random.randint(3, 8)
        draw.ellipse([x1-r, y1-r, x1+r, y1+r], fill=(255, 255, 255, 55))

def draw_shelves(draw, w, h):
    """Draw bookshelf-style horizontal lines."""
    for row in range(5):
        y = int(h * 0.15 + row * h * 0.18)
        draw.line([(40, y), (w-40, y)], fill=(255, 255, 255, 18), width=1)
        # book spines
        bx = 50
        while bx < w - 60:
            bw = random.randint(14, 36)
            bh = int(h * 0.14)
            by = y - bh
            alpha = random.randint(15, 40)
            draw.rectangle([bx, by, bx+bw, y], fill=(255, 255, 255, alpha))
            bx += bw + random.randint(2, 8)

def draw_nodes(draw, w, h):
    """Draw connected network nodes."""
    cx, cy = w//2, h//2
    for angle in range(0, 360, 30):
        rad = math.radians(angle)
        for dist in [60, 130, 200]:
            nx = int(cx + math.cos(rad) * dist * (w / h))
            ny = int(cy + math.sin(rad) * dist)
            if 0 < nx < w and 0 < ny < h:
                draw.line([(cx, cy), (nx, ny)], fill=(255, 255, 255, 15), width=1)
                r = 5
                draw.ellipse([nx-r, ny-r, nx+r, ny+r], fill=(255, 255, 255, 45))
    r = 12
    draw.ellipse([cx-r, cy-r, cx+r, cy+r], fill=(255, 255, 255, 80))

SHAPE_FN = {"circuit": draw_circuit, "neural": draw_neural, "shelves": draw_shelves, "nodes": draw_nodes}

for b in BANNERS:
    im = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    rgb = [hex_to_rgb(c) for c in b["colors"]]

    # Draw gradient background
    for y in range(H):
        t = y / H
        if len(rgb) == 3:
            t1 = min(t * 2, 1)
            t2 = max(0, (t - 0.5) * 2)
            col = lerp(rgb[0], rgb[1], t1) if t < 0.5 else lerp(rgb[1], rgb[2], t2)
        else:
            col = lerp(rgb[0], rgb[1], t)
        r, g, bb = col
        for x in range(W):
            im.putpixel((x, y), (r, g, bb, 255))

    # Draw pattern overlay
    overlay = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    if b["shapes"] in SHAPE_FN:
        SHAPE_FN[b["shapes"]](draw, W, H)

    # Add subtle noise
    for _ in range(300):
        nx = random.randint(0, W-1)
        ny = random.randint(0, H-1)
        a = random.randint(2, 10)
        overlay.paste((255, 255, 255, a), (nx, ny, nx+1, ny+1))

    # Composite pattern overlay
    im = Image.alpha_composite(im, overlay)

    # Rounded corner clipping
    mask = Image.new('L', (W, H), 0)
    md = ImageDraw.Draw(mask)
    rr = 24
    md.rounded_rectangle([0, 0, W-1, H-1], radius=rr, fill=255)
    # Apply mask: composite image onto transparent with mask as alpha
    result = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    result.paste(im, mask=mask)

    path = os.path.join(OUT, b["name"] + '.png')
    result.save(path)
    print(f'Saved {path} ({W}x{H})')

print('Done! All banner images generated.')
