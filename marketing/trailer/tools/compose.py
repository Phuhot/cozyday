#!/usr/bin/env python3
"""Dựng trailer 30 giây (1080×1920, 30 khung/giây) từ:
  - khung hình vẽ bằng code của app (frames.py → PNG trong suốt),
  - footage giao diện thật quay trên simulator (marketing/trailer/footage/*.mp4),
  - icon thật trong asset catalog,
  - âm thanh tổng hợp (audio.py).

Cách chạy: xem marketing/trailer/README.md. Tham số:
  compose.py <thư mục PNG> <thư mục footage> <font Baloo2> <font Nunito> <audio.wav> <out.mp4> [--stills t1,t2,...]
"""
import math, os, subprocess, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageChops

import timeline as T

W, H = 1080, 1920
ROOT = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(ROOT, "..", "..", ".."))
ICON = os.path.join(REPO, "Cozyday/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png")

PNG, FOOT, F_BALOO, F_NUNITO, AUDIO, OUT = sys.argv[1:7]
STILLS = None
if "--stills" in sys.argv:
    STILLS = [float(x) for x in sys.argv[sys.argv.index("--stills") + 1].split(",")]

# Bảng màu của app (Cozyday/DesignSystem/Theme.swift)
INK = (0x3E, 0x35, 0x50)
INK_MUTED = (0x78, 0x6E, 0x87)
LAVENDER = (0x8D, 0x78, 0xCF)
LAV_SOFT = (0xEC, 0xE6, 0xFA)
CREAM = (0xFE, 0xF6, 0xEC)
SURFACE = (0xFF, 0xFD, 0xF8)
HONEY = (0xD9, 0xA4, 0x41)
PEACH = (0xE5, 0x9A, 0x7A)
SAGE = (0x6F, 0x9A, 0x72)
WORK = (0x6E, 0x8F, 0xC8)
LINE = (0xE8, 0xDC, 0xCB)


def font(path, size, weight):
    f = ImageFont.truetype(path, size)
    f.set_variation_by_name(weight)
    return f


# ---------- tiện ích ----------
class Over:
    """Vẽ bán trong suốt đúng cách: vẽ lên lớp trong suốt riêng rồi alpha_composite vào ảnh nền khi xong."""

    def __init__(self, base):
        self.base = base
        self.layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
        self.d = ImageDraw.Draw(self.layer)

    def __enter__(self):
        return self.d

    def __exit__(self, *a):
        self.base.alpha_composite(self.layer)


def clamp(x, a=0.0, b=1.0):
    return max(a, min(b, x))


def ease_out(x):
    x = clamp(x)
    return 1 - (1 - x) ** 3


def ease_in_out(x):
    x = clamp(x)
    return x * x * (3 - 2 * x)


def back_out(x, s=1.9):
    x = clamp(x)
    x -= 1
    return 1 + x * x * ((s + 1) * x + s)


def lerp(a, b, k):
    return a + (b - a) * k


def gradient(w, h, stops):
    """Gradient dọc nhiều điểm màu."""
    ys = np.linspace(0, 1, h)[:, None]
    pos = np.linspace(0, 1, len(stops))
    cols = np.array(stops, dtype=np.float32)
    out = np.zeros((h, 1, 3), np.float32)
    for c in range(3):
        out[:, 0, c] = np.interp(ys[:, 0], pos, cols[:, c])
    arr = np.repeat(out, w, axis=1).astype(np.uint8)
    return Image.fromarray(arr, "RGB").convert("RGBA")


def hexrgb(v):
    return ((v >> 16) & 255, (v >> 8) & 255, v & 255)


def rounded_mask(size, r):
    m = Image.new("L", size, 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, size[0] - 1, size[1] - 1], r, fill=255)
    return m


def shadow_for(mask, blur=36, opacity=70, color=LAVENDER):
    pad = blur * 2
    s = Image.new("L", (mask.width + pad * 2, mask.height + pad * 2), 0)
    s.paste(mask, (pad, pad))
    s = s.filter(ImageFilter.GaussianBlur(blur))
    s = s.point(lambda v: v * opacity // 100)
    layer = Image.new("RGBA", s.size, color + (0,))
    layer.putalpha(s)
    return layer, pad


def paste_scaled(canvas, img, cx, cy, scale, alpha=1.0, rot=0.0):
    if scale <= 0.01 or alpha <= 0.01:
        return
    w, h = max(1, int(img.width * scale)), max(1, int(img.height * scale))
    im = img.resize((w, h), Image.LANCZOS)
    if rot:
        im = im.rotate(rot, resample=Image.BICUBIC, expand=True)
    if alpha < 1:
        a = im.getchannel("A").point(lambda v: int(v * alpha))
        im.putalpha(a)
    canvas.alpha_composite(im, (int(cx - im.width / 2), int(cy - im.height / 2)))


_cache = {}


def load(path):
    if path not in _cache:
        _cache[path] = Image.open(path).convert("RGBA")
    return _cache[path]


def seq(prefix, i):
    p = os.path.join(PNG, f"{prefix}_{i:03d}.png")
    if not os.path.exists(p):
        files = sorted(f for f in os.listdir(PNG) if f.startswith(prefix + "_"))
        p = os.path.join(PNG, files[-1] if i > 0 else files[0])
    return load(p) if prefix == "room" else Image.open(p).convert("RGBA")


# ---------- nền họa tiết (dấu chân, tim, sao mờ như CozyBackdrop của app) ----------
def backdrop(stops, pattern=True):
    g = gradient(W, H, stops)
    if not pattern:
        return g
    with Over(g) as d:
        pattern_tiles(d)
    return g


def pattern_tiles(d):
    tile = 220
    for r in range(H // tile + 2):
        for c in range(W // tile + 2):
            ox = c * tile + (0 if r % 2 == 0 else tile // 2)
            oy = r * tile
            k = (r + c) % 3
            if (r * 3 + c) % 2:
                continue
            if k == 0:
                col = LAVENDER + (13,)
                d.ellipse([ox + 30, oy + 52, ox + 70, oy + 84], fill=col)
                for dx, dy in ((-18, -14), (-6, -26), (8, -26), (20, -14)):
                    d.ellipse([ox + 50 + dx - 8, oy + 66 + dy - 8, ox + 50 + dx + 8, oy + 66 + dy + 8], fill=col)
            elif k == 1:
                heart(d, ox + 60, oy + 70, 34, LAVENDER + (16,))
            else:
                star(d, ox + 56, oy + 66, 20, 9, HONEY + (24,))


def heart(d, cx, cy, s, fill):
    r = s * 0.3
    d.ellipse([cx - s * 0.5, cy - s * 0.45, cx - s * 0.5 + 2 * r, cy - s * 0.45 + 2 * r], fill=fill)
    d.ellipse([cx + s * 0.5 - 2 * r, cy - s * 0.45, cx + s * 0.5, cy - s * 0.45 + 2 * r], fill=fill)
    d.polygon([(cx - s * 0.49, cy - s * 0.2), (cx + s * 0.49, cy - s * 0.2), (cx, cy + s * 0.48)], fill=fill)


def star(d, cx, cy, ro, ri, fill, rot=0.0):
    pts = []
    for i in range(10):
        r = ro if i % 2 == 0 else ri
        a = rot + i * math.pi / 5 - math.pi / 2
        pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    d.polygon(pts, fill=fill)


def sparkle4(d, cx, cy, s, fill):
    d.polygon([(cx, cy - s), (cx + s * 0.22, cy - s * 0.22), (cx + s, cy), (cx + s * 0.22, cy + s * 0.22),
               (cx, cy + s), (cx - s * 0.22, cy + s * 0.22), (cx - s, cy), (cx - s * 0.22, cy - s * 0.22)], fill=fill)


# ---------- tiêu đề ----------
TITLE_FONT = font(F_BALOO, 96, "ExtraBold")


def title_layer(text, t, t_in, t_out, y=205, size=96, color=INK, pill=True):
    """Chữ bật theo cụm (tách ở dấu chấm), mỗi cụm một dòng; ra bằng thu nhỏ + mờ."""
    if t < t_in or t > t_out + 0.2:
        return None
    f = TITLE_FONT if size == 96 else font(F_BALOO, size, "ExtraBold")
    chunks = [c.strip() for c in text.replace(". ", ".|").split("|")]
    layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    out_k = ease_in_out((t - t_out) / 0.18) if t > t_out else 0
    line_h = int(size * 1.12)
    total_h = line_h * len(chunks)
    for i, c in enumerate(chunks):
        k = (t - t_in - i * 0.22) / 0.32
        if k <= 0:
            continue
        sc = back_out(k) * (1 - 0.25 * out_k)
        al = clamp(k * 3) * (1 - out_k)
        bbox = f.getbbox(c)
        tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
        pad_x, pad_y = 44, 22
        im = Image.new("RGBA", (tw + pad_x * 2, int(size * 1.2) + pad_y * 2), (0, 0, 0, 0))
        dd = ImageDraw.Draw(im)
        if pill:
            dd.rounded_rectangle([0, 0, im.width - 1, im.height - 1], im.height // 2, fill=SURFACE + (236,))
        dd.text((pad_x - bbox[0], pad_y + (int(size * 1.2) - th) // 2 - bbox[1]), c, font=f, fill=color)
        cy = y + i * (line_h + 30) - (total_h - line_h) // 2 + im.height // 2
        if pill:
            sh, pad = shadow_for(Image.new("L", im.size, 255).filter(ImageFilter.GaussianBlur(0)) if False else rounded_mask(im.size, im.height // 2), 18, 22)
            tmp = Image.new("RGBA", (W, H), (0, 0, 0, 0))
            paste_scaled(tmp, sh, W / 2, cy + 8, sc, al)
            layer.alpha_composite(tmp)
        paste_scaled(layer, im, W / 2, cy, sc, al)
    return layer


# ---------- footage ----------
class Clip:
    def __init__(self, name):
        self.name = name
        self.dir = os.path.join(PNG, "foot_" + name)
        src = os.path.join(FOOT, name + ".mp4")
        self.ok = os.path.exists(src)
        if self.ok and not os.path.isdir(self.dir):
            os.makedirs(self.dir)
            subprocess.run(["ffmpeg", "-v", "error", "-i", src, "-vf", "fps=30", "-q:v", "2",
                            os.path.join(self.dir, "%04d.jpg")], check=True)
        self.n = len(os.listdir(self.dir)) if self.ok else 0

    def frame(self, src_t):
        if not self.ok:
            im = Image.new("RGBA", (1080, 2348), (220, 214, 232, 255))
            ImageDraw.Draw(im).text((80, 1100), f"[footage {self.name} chưa có]", font=font(F_NUNITO, 60, "Bold"), fill=INK)
            return im
        i = int(clamp(round(src_t * 30), 0, self.n - 1)) + 1
        return load(os.path.join(self.dir, f"{i:04d}.jpg"))


CLIPS = {}


def clip(name):
    if name not in CLIPS:
        CLIPS[name] = Clip(name)
    return CLIPS[name]


def ui_card(canvas, im, crop, rect, radius=56, shadow=True, alpha=1.0):
    """Đặt một vùng (crop, tọa độ chuẩn hóa 0–1) của khung footage vào hình chữ nhật bo góc `rect` trên màn."""
    x0, y0, x1, y1 = crop
    sw, sh = im.size
    box = (int(x0 * sw), int(y0 * sh), int(x1 * sw), int(y1 * sh))
    rx0, ry0, rx1, ry1 = [int(v) for v in rect]
    rw, rh = rx1 - rx0, ry1 - ry0
    part = im.crop(box).resize((rw, rh), Image.LANCZOS)
    mask = rounded_mask((rw, rh), radius)
    if alpha < 1:
        mask = mask.point(lambda v: int(v * alpha))
    if shadow:
        sh_l, pad = shadow_for(rounded_mask((rw, rh), radius), 34, int(60 * alpha))
        canvas.alpha_composite(sh_l, (rx0 - pad, ry0 - pad + 18))
    part.putalpha(mask)
    canvas.alpha_composite(part, (rx0, ry0))


def fit_crop(cx, cy, w_norm, aspect, src_aspect):
    """Vùng crop chuẩn hóa có tâm (cx, cy), rộng w_norm, tỉ lệ khung đích `aspect` (w/h). src_aspect = w/h nguồn."""
    h_norm = w_norm / aspect * src_aspect
    x0 = clamp(cx - w_norm / 2, 0, 1 - w_norm)
    y0 = clamp(cy - h_norm / 2, 0, 1 - h_norm)
    return (x0, y0, x0 + w_norm, y0 + h_norm)


# ---------- cảnh 1: thẻ việc rối → xếp gọn ----------
CARDS = [  # (giờ, tên, màu): đúng dữ liệu mẫu và giờ trong footage màn Hôm nay
    ("8:30", "Đi bộ 30 phút", SAGE),
    ("9:30", "Ôn từ vựng tiếng Anh", LAVENDER),
    ("10:30", "Trả lời email của nhóm", WORK),
    ("11:45", "Gọi điện cho bà", PEACH),
    ("13:00", "Nấu bữa tối", HONEY),
]
CARD_W, CARD_H = 760, 118
F_CARD = font(F_NUNITO, 42, "Bold")
F_TIME = font(F_NUNITO, 34, "SemiBold")
_card_imgs = {}


def card_img(i, done=False):
    key = (i, done)
    if key in _card_imgs:
        return _card_imgs[key]
    _, title, col = CARDS[i]
    im = Image.new("RGBA", (CARD_W, CARD_H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rounded_rectangle([0, 0, CARD_W - 1, CARD_H - 1], 30, fill=SURFACE + (255,), outline=LINE + (255,), width=3)
    d.rounded_rectangle([0, 0, 22, CARD_H - 1], 11, fill=col + (255,))
    d.rectangle([12, 0, 22, CARD_H - 1], fill=col + (255,))
    d.ellipse([CARD_W - 92, 31, CARD_W - 36, 87], outline=col + (255,), width=6)
    d.text((52, CARD_H // 2), title, font=F_CARD, fill=INK, anchor="lm")
    _card_imgs[key] = im
    return im


# vị trí rối (tâm x, y, góc) — đặt quanh vịt ở nửa trên
CHAOS = [(300, 420, -16), (760, 560, 12), (330, 760, 9), (790, 330, -10), (520, 1000, -20)]
ENTRY = [(-500, 300), (1600, 700), (-500, 900), (1600, 120), (540, -300)]


def timeline_pos(i):
    return 600, 520 + i * (CARD_H + 26)


def scene_open(t):
    cv = backdrop([CREAM, LAV_SOFT])
    snap0 = T.TAP + 0.1
    # vịt
    k_in = t / 0.4
    sc = back_out(k_in) if t < 0.4 else 1.0
    after = ease_in_out((t - T.TAP) / 0.55)
    duck_scale = lerp(1.0, 0.62, after) * sc
    duck_bottom = lerp(1720, 1840, after)
    duck = seq("s1", int(t * T.FPS))
    # thẻ việc
    if t > snap0:
        k = ease_out((t - snap0 - 0.1) / 0.4)
        x = 175
        y0, y1 = timeline_pos(0)[1] - 40, timeline_pos(len(CARDS) - 1)[1] + 40
        with Over(cv) as d_tl:
            d_tl.line([(x, y0), (x, lerp(y0, y1, k))], fill=LAVENDER + (110,), width=6)
    cards_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    for i in range(len(CARDS)):
        appear = 0.2 + i * 0.17
        if t < appear:
            continue
        ka = ease_out((t - appear) / 0.45)
        cx = lerp(ENTRY[i][0], CHAOS[i][0], ka)
        cy = lerp(ENTRY[i][1], CHAOS[i][1], ka)
        wob = 4 * math.sin(t * 7 + i * 1.7) if t < snap0 else 0
        rot = CHAOS[i][2] + wob
        jx = 6 * math.sin(t * 11 + i) if t < snap0 else 0
        ks = ease_out((t - snap0 - i * 0.06) / 0.42)
        tx, ty = timeline_pos(i)
        cx, cy, rot = lerp(cx + jx, tx, ks), lerp(cy, ty, ks), lerp(rot, 0, ks)
        s = lerp(0.92, 1.0, ks)
        paste_scaled(cards_layer, card_img(i), cx, cy, s, 1.0, rot)
        if ks > 0.6:
            a = int(255 * clamp((ks - 0.6) / 0.4))
            ImageDraw.Draw(cards_layer).text((150, ty), CARDS[i][0], font=F_TIME, fill=INK_MUTED + (a,), anchor="rm")
            ImageDraw.Draw(cards_layer).ellipse([166, ty - 9, 184, ty + 9], fill=CARDS[i][2] + (a,))
    # vòng sóng khi vịt chạm
    if T.TAP <= t < T.TAP + 0.6:
        k = (t - T.TAP) / 0.6
        r = lerp(120, 900, ease_out(k))
        cx, cy = 540, duck_bottom - 450 * duck_scale
        with Over(cv) as dr:
            dr.ellipse([cx - r, cy - r, cx + r, cy + r], outline=LAVENDER + (int(160 * (1 - k)),), width=14)
    paste_scaled(cv, duck, 540, duck_bottom - duck.height * duck_scale / 2, duck_scale)
    cv.alpha_composite(cards_layer)
    return cv


# ---------- cảnh giao diện thật ----------
# Mỗi cảnh: clip, giây bắt đầu trong clip, tốc độ, khung đặt trên màn (x0, y0, x1, y1),
# vùng nhìn đầu/cuối trong footage (tâm x, tâm y, bề rộng — tỉ lệ 0–1), kiểu chuyển máy, nền.
TALL = (60, 430, 1020, 1870)
SQUARE = (60, 560, 1020, 1520)
SHOT = {
    "today": dict(clip="today-tick", start=5.35, speed=0.85, rect=TALL, a=(0.62, 0.42, 0.7), b=(0.5, 0.6, 1.0),
                  move=(T.TICK + 0.35, 0.9), bg=[LAV_SOFT, CREAM]),
    "wardrobe": dict(clip="wardrobe", start=8.15, speed=1.0, rect=TALL, a=(0.5, 0.4, 1.0), b=(0.5, 0.28, 0.5),
                     move=(T.WARDROBE[0] + 0.4, 0.5), bg=[CREAM, LAV_SOFT]),
    "feed": dict(clip="feed", start=5.7, speed=1.25, rect=SQUARE, a=(0.5, 0.33, 0.95), b=(0.45, 0.29, 0.64),
                 move=(T.CARE_CUTS[0] + 0.5, 1.0), bg=[CREAM, (0xFB, 0xE7, 0xDE)]),
    "cuddle": dict(clip="cuddle", start=2.3, speed=0.85, rect=SQUARE, a=(0.5, 0.46, 0.95), b=(0.45, 0.5, 0.7),
                   move=(T.CARE_CUTS[1], 1.8), bg=[CREAM, (0xFB, 0xE7, 0xDE)]),
    "clean": dict(clip="clean", start=9.4, speed=1.75, rect=SQUARE, a=(0.5, 0.38, 0.95), b=(0.5, 0.36, 0.86),
                  move=(T.CARE_CUTS[2], 1.7), bg=[CREAM, (0xFB, 0xE7, 0xDE)]),
    "jump": dict(clip="jump", start=12.8, speed=1.0, rect=TALL, a=(0.5, 0.52, 1.0), b=(0.5, 0.52, 0.94),
                 move=(T.GAME_CUTS[0], 2.0), bg=[LAV_SOFT, (0xDC, 0xEC, 0xFA)]),
    "basket": dict(clip="basket", start=16.55, speed=1.0, rect=TALL, a=(0.5, 0.7, 0.86), b=(0.5, 0.72, 0.8),
                   move=(T.GAME_CUTS[1], 2.0), bg=[LAV_SOFT, (0xDC, 0xEC, 0xFA)]),
    "memory": dict(clip="memory", start=13.25, speed=1.0, rect=TALL, a=(0.5, 0.55, 1.0), b=(0.5, 0.5, 1.0),
                   move=(T.GAME_CUTS[2], 2.0), bg=[LAV_SOFT, (0xDC, 0xEC, 0xFA)]),
}
_bg = {}


def ui_shot(key, t, t0):
    c = SHOT[key]
    bgk = tuple(map(tuple, c["bg"]))
    if bgk not in _bg:
        _bg[bgk] = backdrop(c["bg"])
    cv = _bg[bgk].copy()
    im = clip(c["clip"]).frame(c["start"] + (t - t0) * c["speed"])
    m0, md = c["move"]
    k = ease_in_out((t - m0) / md)
    cx, cy, w = [lerp(x, y, k) for x, y in zip(c["a"], c["b"])]
    r = c["rect"]
    aspect = (r[2] - r[0]) / (r[3] - r[1])
    ui_card(cv, im, fit_crop(cx, cy, w, aspect, im.width / im.height), r)
    return cv


def scene_today(t):
    return ui_shot("today", t, T.TODAY[0])


def scene_wardrobe(t):
    return ui_shot("wardrobe", t, T.WARDROBE[0])


# ---------- montage trang phục ----------
MT_BG = {}


def scene_montage(t):
    i = int(round((t - T.MONTAGE[0]) * T.FPS))
    av = seq("mt", i)
    k = sum(1 for c in T.OUTFIT_CHANGES if t >= c)
    key = max(0, k - 1)
    if key not in MT_BG:
        small = av.resize((180, 180)).convert("RGB")
        bg = small.resize((H, H), Image.BICUBIC).filter(ImageFilter.GaussianBlur(60))
        bg = bg.crop(((H - W) // 2, 0, (H - W) // 2 + W, H)).convert("RGBA")
        veil = Image.new("RGBA", (W, H), (255, 255, 255, 60))
        bg.alpha_composite(veil)
        MT_BG[key] = bg
    cv = MT_BG[key].copy()
    # thẻ ảnh đại diện; nảy nhẹ khi đổi bộ
    last = max([c for c in T.OUTFIT_CHANGES if t >= c], default=T.MONTAGE[0])
    bump = 1 + 0.035 * math.sin(math.pi * clamp((t - last) / 0.22)) if t >= T.OUTFIT_CHANGES[0] else 1
    intro = ease_out((t - T.MONTAGE[0]) / 0.25)
    size = int(940 * bump * lerp(1.25, 1.0, intro))
    card = av.resize((size, size), Image.LANCZOS)
    card.putalpha(rounded_mask((size, size), 70))
    sh, pad = shadow_for(rounded_mask((size, size), 70), 40, 45, (60, 40, 90))
    cx, cy = W // 2, 1080
    cv.alpha_composite(sh, (cx - size // 2 - pad, cy - size // 2 - pad + 22))
    cv.alpha_composite(card, (cx - size // 2, cy - size // 2))
    return cv


def scene_care(t):
    cuts = T.CARE_CUTS + [T.CARE[1]]
    idx = max(i for i in range(3) if t >= cuts[i])
    return ui_shot(["feed", "cuddle", "clean"][idx], t, cuts[idx])


def scene_games(t):
    cuts = T.GAME_CUTS + [T.GAMES[1]]
    idx = max(i for i in range(3) if t >= cuts[i])
    return ui_shot(["jump", "basket", "memory"][idx], t, cuts[idx])


# ---------- cảnh 6: cao trào trong phòng ngủ ----------
ROOM_SCALE = 2400 / 125
PET_X = 0.35


def particles(cv, t, origin, starts, seed=3):
    with Over(cv) as d:
        _particles(d, t, origin, starts, seed)


def _particles(d, t, origin, starts, seed):
    rnd = np.random.default_rng(seed)
    for s0 in starts:
        for j in range(9):
            ang = rnd.uniform(-math.pi * 0.95, -math.pi * 0.05)
            sp = rnd.uniform(260, 520)
            kind = j % 3
            dt = t - s0
            if dt < 0 or dt > 1.1:
                continue
            x = origin[0] + math.cos(ang) * sp * dt
            y = origin[1] + math.sin(ang) * sp * dt + 260 * dt * dt
            a = int(255 * clamp(1 - dt / 1.1))
            s = 26 + 10 * (j % 2)
            if kind == 0:
                star(d, x, y, s, s * 0.45, HONEY + (a,), rot=dt * 3)
            elif kind == 1:
                heart(d, x, y, s * 1.4, (0xF4, 0x8F, 0xA8, a))
            else:
                sparkle4(d, x, y, s, (255, 255, 255, a))


def scene_climax(t):
    room = load(os.path.join(PNG, "room.png"))
    i = int(round((t - T.CLIMAX[0]) * T.FPS))
    pet = seq("s5", i)
    size = pet.width  # 720 = 37.5 đơn vị phòng
    big = room.copy()
    px = 125 * PET_X * ROOM_SCALE
    py = (86 - 37.5) * ROOM_SCALE
    big.alpha_composite(pet, (int(px), int(py)))
    pcx, pcy = px + size / 2, py + size * 0.55
    particles(big, t, (pcx, py + size * 0.3), [h + 0.12 for h in T.HOPS])
    # đẩy máy vào thú cưng
    k = ease_in_out((t - T.CLIMAX[0]) / 2.6)
    cw = lerp(1080, 820, k)
    ch = cw * H / W
    cx = clamp(pcx, cw / 2, big.width - cw / 2)
    cy = clamp(lerp(big.height / 2, pcy - 120, k), ch / 2, big.height - ch / 2)
    view = big.crop((int(cx - cw / 2), int(cy - ch / 2), int(cx + cw / 2), int(cy + ch / 2))).resize((W, H), Image.LANCZOS)
    # thu về giữa: vòng tròn khép lại quanh thú cưng
    close = ease_in_out((t - 25.35) / 0.65)
    if close > 0:
        end = end_card_bg()
        r = lerp(1300, 0, close)
        ox = W / 2 + (pcx - cx) * W / cw
        oy = H / 2 + (pcy - cy) * W / cw
        m = Image.new("L", (W, H), 0)
        ImageDraw.Draw(m).ellipse([ox - r, oy - r, ox + r, oy + r], fill=255)
        m = m.filter(ImageFilter.GaussianBlur(6))
        out = end.copy()
        out.paste(view, (0, 0), m)
        return out
    return view


# ---------- cảnh 7: end card ----------
_end_bg = None


def end_card_bg():
    global _end_bg
    if _end_bg is None:
        _end_bg = backdrop([hexrgb(0xBFE3FF), hexrgb(0xDCD3FF), hexrgb(0xFFD1E3)], pattern=False)
        g = Image.new("L", (W, H), 0)
        ImageDraw.Draw(g).ellipse([90, 300, 990, 1200], fill=110)
        g = g.filter(ImageFilter.GaussianBlur(120))
        white = Image.new("RGBA", (W, H), (255, 255, 255, 0))
        white.putalpha(g)
        _end_bg.alpha_composite(white)
    return _end_bg


ICON_SIZE = 440
ICON_CY = 700
F_NAME = font(F_BALOO, 168, "ExtraBold")
F_TAG = font(F_NUNITO, 54, "Bold")
F_SMALL = font(F_NUNITO, 36, "Bold")
SPARK_POS = [(160, 330), (930, 260), (120, 1180), (960, 1240), (250, 1700), (860, 1660), (520, 200)]


def scene_end(t):
    cv = end_card_bg().copy()
    with Over(cv) as d:
        for j, (x, y) in enumerate(SPARK_POS):
            tw = 0.5 + 0.5 * math.sin(t * 2.2 + j * 1.3)
            a = int(200 * tw * clamp((t - T.ICON - 0.3) / 0.5))
            sparkle4(d, x, y, 18 + 10 * tw, (255, 255, 255, a))
    k = (t - T.ICON) / 0.5
    sc = back_out(k, 2.2) if k < 1 else 1.0
    icon = load(ICON).resize((ICON_SIZE, ICON_SIZE), Image.LANCZOS)
    mask = rounded_mask((ICON_SIZE, ICON_SIZE), int(ICON_SIZE * 0.2237))
    # vệt sáng lướt qua icon
    sw = (t - (T.ICON + 0.75)) / 0.55
    if 0 < sw < 1:
        band = Image.new("L", (ICON_SIZE * 3, ICON_SIZE * 3), 0)
        bx = int(lerp(0, ICON_SIZE * 2, sw))
        ImageDraw.Draw(band).rectangle([bx, 0, bx + 70, ICON_SIZE * 3], fill=150)
        band = band.filter(ImageFilter.GaussianBlur(18)).rotate(-25, resample=Image.BICUBIC)
        band = band.crop((ICON_SIZE, ICON_SIZE, ICON_SIZE * 2, ICON_SIZE * 2))
        glare = Image.new("RGBA", (ICON_SIZE, ICON_SIZE), (255, 255, 255, 0))
        glare.putalpha(ImageChops.multiply(band, mask))
        icon = icon.copy()
        icon.alpha_composite(glare)
    icon.putalpha(mask)
    sh, pad = shadow_for(mask, 30, 55, (90, 70, 140))
    tmp = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    paste_scaled(tmp, sh, W / 2, ICON_CY + 24, sc)
    cv.alpha_composite(tmp)
    paste_scaled(cv, icon, W / 2, ICON_CY, sc)
    # thú cưng nhảy ra, ngồi tựa vào góc dưới bên phải icon
    pk = (t - (T.ICON + 0.45)) / 0.4
    if pk > 0:
        pet = seq("s6", int(round((t - T.ICON) * T.FPS)))
        ps = 0.62
        px = 540 + ICON_SIZE / 2 + 10
        land = ICON_CY + ICON_SIZE / 2 + 70 - pet.height * ps / 2
        py = land - 120 * math.sin(math.pi * clamp(pk)) * (1 if pk < 1 else 0)
        px = lerp(540 + 80, px, ease_out(pk))
        paste_scaled(cv, pet, px, py, ps * lerp(0.6, 1, ease_out(pk)), clamp(pk * 3))
    # tên app
    nk = (t - (T.ICON + 0.35)) / 0.35
    if nk > 0:
        name = Image.new("RGBA", (900, 230), (0, 0, 0, 0))
        dn = ImageDraw.Draw(name)
        cozy_w = F_NAME.getlength("Cozy")
        full_w = F_NAME.getlength("CozyDay")
        x0 = (900 - full_w) / 2
        dn.text((x0, 115), "Cozy", font=F_NAME, fill=LAVENDER, anchor="lm")
        dn.text((x0 + cozy_w, 115), "Day", font=F_NAME, fill=INK, anchor="lm")
        paste_scaled(cv, name, W / 2, 1110, back_out(nk), clamp(nk * 3))
    # tagline hai cụm
    with Over(cv) as d:
        for j, line in enumerate(["Một ngày gọn hơn.", "Một góc nhỏ vui hơn."]):
            lk = ease_out((t - (T.ICON + 0.8 + j * 0.25)) / 0.35)
            if lk > 0:
                d.text((W / 2, 1270 + j * 78 + 30 * (1 - lk)), line, font=F_TAG, fill=INK + (int(255 * lk),), anchor="mm")
        bk = ease_out((t - (T.ICON + 1.35)) / 0.35)
        if bk > 0:
            txt = "Bản dùng thử"
            tw = F_SMALL.getlength(txt)
            d.rounded_rectangle([W / 2 - tw / 2 - 30, 1500, W / 2 + tw / 2 + 30, 1566], 33, fill=(255, 255, 255, int(170 * bk)))
            d.text((W / 2, 1533), txt, font=F_SMALL, fill=INK_MUTED + (int(255 * bk),), anchor="mm")
    return cv


# ---------- đồng xu (object wipe) ----------
def coin_img(size):
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.ellipse([0, 0, size - 1, size - 1], fill=(0xC8, 0x8A, 0x2A, 255))
    d.ellipse([size * 0.05, size * 0.04, size * 0.95, size * 0.92], fill=(0xF2, 0xC2, 0x4E, 255))
    d.ellipse([size * 0.17, size * 0.15, size * 0.83, size * 0.8], fill=(0xFF, 0xD9, 0x6E, 255))
    star(d, size / 2, size * 0.48, size * 0.22, size * 0.1, (0xE0, 0xA2, 0x38, 255))
    d.ellipse([size * 0.24, size * 0.2, size * 0.36, size * 0.3], fill=(255, 255, 255, 170))
    return im


COIN = coin_img(520)


def coin_wipe(t, a_img_fn, b_img_fn):
    """Đồng xu lăn qua khung từ trái sang phải; phía sau đồng xu là cảnh mới."""
    k = ease_in_out((t - T.COIN) / 0.55)
    x = lerp(-320, W + 320, k)
    a = a_img_fn(t)
    b = b_img_fn(max(t, T.WARDROBE[0]))
    m = Image.new("L", (W, H), 0)
    if x > 0:
        ImageDraw.Draw(m).rectangle([0, 0, int(x), H], fill=255)
    out = a.copy()
    out.paste(b, (0, 0), m)
    squash = abs(math.cos(k * math.pi * 3)) * 0.75 + 0.25
    c = COIN.resize((max(2, int(520 * squash)), 520), Image.LANCZOS)
    out.alpha_composite(c, (int(x - c.width / 2), int(H * 0.52 - 260 - 180 * math.sin(math.pi * k))))
    return out


# ---------- điều phối ----------
def flash(cv, t, at, dur=0.12, strength=150):
    k = (t - at) / dur
    if 0 <= k < 1:
        cv.alpha_composite(Image.new("RGBA", (W, H), (255, 255, 255, int(strength * (1 - k)))))


def zoom_out_of(img, k, cx, cy):
    """Zoom có định hướng: phóng to quanh (cx, cy) và mờ dần sang trắng kem."""
    s = lerp(1, 2.3, ease_in_out(k))
    w, h = W / s, H / s
    x0 = clamp(cx - w / 2, 0, W - w)
    y0 = clamp(cy - h / 2, 0, H - h)
    out = img.crop((int(x0), int(y0), int(x0 + w), int(y0 + h))).resize((W, H), Image.BICUBIC)
    out.alpha_composite(Image.new("RGBA", (W, H), LAV_SOFT + (int(255 * clamp((k - 0.55) / 0.45)),)))
    return out


def render(t):
    if t < T.OPEN[1]:
        cv = scene_open(t)
        if t > 2.55:
            tx, ty = timeline_pos(2)  # thẻ "Trả lời email của nhóm", đúng việc được tick ở cảnh sau
            cv = zoom_out_of(cv, (t - 2.55) / 0.45, tx - 60, ty)
    elif t < T.TODAY[1] + 0.6 and t >= T.COIN:
        cv = coin_wipe(t, scene_today, scene_wardrobe)
    elif t < T.TODAY[1]:
        cv = scene_today(t)
        k = 1 - (t - T.TODAY[0]) / 0.25
        if k > 0:
            cv.alpha_composite(Image.new("RGBA", (W, H), LAV_SOFT + (int(255 * k),)))
    elif t < T.WARDROBE[1]:
        cv = scene_wardrobe(t)
    elif t < T.MONTAGE[1]:
        cv = scene_montage(t)
    elif t < T.CARE[1]:
        cv = scene_care(t)
    elif t < T.GAMES[1]:
        cv = scene_games(t)
        flash(cv, t, T.GAMES[0], 0.15, 120)
    elif t < T.CLIMAX[1]:
        cv = scene_climax(t)
        flash(cv, t, T.CLIMAX[0], 0.15, 120)
    else:
        cv = scene_end(t)
    for (a, b, text) in T.TITLES:
        lay = title_layer(text, t, a, b)
        if lay is not None:
            cv.alpha_composite(lay)
    return cv.convert("RGB")


def main():
    if STILLS:
        os.makedirs(OUT, exist_ok=True)
        for t in STILLS:
            render(t).save(os.path.join(OUT, f"still_{t:05.2f}.jpg"), quality=88)
        return
    n = int(T.DURATION * T.FPS)
    p = subprocess.Popen(["ffmpeg", "-v", "error", "-y", "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{W}x{H}", "-r", str(T.FPS),
                          "-i", "-", "-i", AUDIO, "-map", "0:v", "-map", "1:a", "-c:v", "libx264", "-preset", "slow", "-crf", "17",
                          "-pix_fmt", "yuv420p", "-profile:v", "high", "-c:a", "aac", "-b:a", "192k", "-movflags", "+faststart",
                          "-shortest", OUT], stdin=subprocess.PIPE)
    for f in range(n):
        p.stdin.write(render(f / T.FPS).tobytes())
        if f % 60 == 0:
            print(f"{f}/{n}", flush=True)
    p.stdin.close()
    p.wait()
    print("xong", OUT)


if __name__ == "__main__":
    main()
