#!/usr/bin/env python3
"""Sinh danh sách khung hình cần vẽ bằng code vẽ của app (PetPainter, AvatarPainter, ItemPainter).

Ghi jobs.txt cho harness Swift (tools/harness_trailer.swift). Mỗi khung là một SVG; sau đó
svg2png_batch.js chuyển sang PNG nền trong suốt. Thời gian tính theo giây của trailer, 30 khung/giây.
"""
import math, os, sys

FPS = 30
SVG = os.environ.get("FRAMES_SVG_PATH") or os.environ.get("SVG_DIR", "/work/trailer_io/svg")  # nơi harness ghi SVG
HERO = "species=duck,fur=honey,stage=growing"
CLOUD = HERO + ",hat=hat.cloud"

# Bộ phối trong montage: toàn món có thật trong Catalog, nền/phong cảnh có thật trong AvatarCatalog.
OUTFITS = [
    ("hat=hat.chef,outfit=outfit.apron", "peach,none,hearts,happy"),
    ("glasses=glasses.heart,outfit=outfit.sailor", "ocean,beach,bubbles,happy"),
    ("hat=hat.straw,neck=neck.lei", "mint,meadow,petals,happy"),
    ("hat=hat.wizard,outfit=outfit.cape", "night,moon,stars,happy"),
    ("hat=hat.crown,back=back.wings", "sunset,rainbow,confetti,happy"),
    ("hat=hat.cloud", "sky,cloud,sparkles,happy"),
]
MONTAGE_START, MONTAGE_STEP = 7.9, 0.5   # mỗi bộ đổi đúng một phách nhạc (120 BPM)
MONTAGE_END = 12.0

ROOM = ("bedroom", "bedroomTheme.cloud,bed.canopy,nightstand.moon,bedroomWall.fairy,closet.vanity,bedroomRug.rainbow,plush.teddy")


def idle(t, blink_at=()):
    p = {"breath": round(math.sin(t * 2 * math.pi / 2.4), 3), "tail": round(math.sin(t * 2 * math.pi / 1.6), 3)}
    if any(0 <= t - b < 0.12 for b in blink_at):
        p["blink"] = 1
    return p


def hop(t, start, height=9.0, dur=0.42):
    d = t - start
    if 0 <= d < dur:
        return height * math.sin(math.pi * d / dur)
    return 0.0


def pose_str(p):
    return ",".join(f"{k}={v}" for k, v in p.items())


def jobs():
    out = []
    # S1 0–3 s: vịt hiện to, nhìn người xem; 1,5 s chạm (nhảy) → các thẻ xếp gọn; 2,0 s vui, tim bay.
    for i in range(int(3.2 * FPS)):
        t = i / FPS
        p = idle(t, blink_at=(0.9,))
        p["hop"] = round(hop(t, 1.45, 10) + hop(t, 2.05, 6, 0.36), 2)
        if t >= 2.0:
            p["hearts"] = round(min(1, (t - 2.0) / 1.2), 3)
        mood = "idle" if t < 1.5 else "happy"
        if 1.45 <= t < 1.75:
            p["tilt"] = round(8 * math.sin(math.pi * (t - 1.45) / 0.3), 2)
        out.append(("pet", f"{SVG}/s1_{i:03d}.svg", 900, f"{CLOUD},mood={mood}", pose_str(p)))
    # Montage trang phục: ảnh đại diện thật, giữ nguyên vị trí thú cưng (match cut).
    n = int(round((MONTAGE_END - MONTAGE_START) * FPS)) + 2
    for i in range(n):
        t = MONTAGE_START + i / FPS
        k = min(len(OUTFITS) - 1, max(0, int((t - MONTAGE_START - 0.1) // MONTAGE_STEP)))
        change = MONTAGE_START + 0.1 + k * MONTAGE_STEP
        items, opts = OUTFITS[k]
        p = idle(t, blink_at=(10.9, 11.6))
        p["hop"] = round(hop(t, change, 7, 0.32), 2)
        out.append(("avatar", f"{SVG}/mt_{i:03d}.svg", 960, opts, f"{HERO},{items}", pose_str(p), f"{t:.3f}"))
    # S5 23–26 s: phòng ngủ đẹp nhất (vẽ một lần, không thú cưng) + thú cưng nhảy ăn mừng (lớp riêng).
    out.append(("room", f"{SVG}/room.svg", 2400, ROOM[0], ROOM[1], CLOUD, "", "-"))
    for i in range(int(3.1 * FPS)):
        t = 23.0 + i / FPS
        p = idle(t, blink_at=(23.3,))
        p["hop"] = round(hop(t, 23.55, 12, 0.45) + hop(t, 24.15, 12, 0.45) + hop(t, 24.75, 16, 0.5), 2)
        if t >= 24.0:
            p["hearts"] = round(((t - 24.0) % 1.2) / 1.2, 3)
        out.append(("pet", f"{SVG}/s5_{i:03d}.svg", 720, f"{CLOUD},mood=happy", pose_str(p)))
    # S6 26–30 s: thú cưng ló ra cạnh icon.
    for i in range(int(4.0 * FPS) + 2):
        t = 26.0 + i / FPS
        p = idle(t, blink_at=(27.9, 29.3))
        p["look"] = -0.6 if t < 28.4 else round(-0.6 + min(1, (t - 28.4) / 0.4) * 0.6, 3)
        p["tilt"] = -6
        out.append(("pet", f"{SVG}/s6_{i:03d}.svg", 520, f"{CLOUD},mood=happy", pose_str(p)))
    return out


if __name__ == "__main__":
    dest = sys.argv[1]
    lines = ["\t".join(str(x) for x in j) for j in jobs()]
    open(dest, "w").write("\n".join(lines) + "\n")
    print(len(lines), "khung")
