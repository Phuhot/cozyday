#!/usr/bin/env python3
"""Vẽ lại icon gốc của Cozyday (mèo kem tròn trên nền lavender).

Chạy: python3 scripts/tools/make_icon.py
Kết quả: Cozyday/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png
Icon là hình vẽ gốc của dự án, không dùng tài sản bên thứ ba.
Ảnh xuất ra không có kênh alpha (iOS yêu cầu icon đục).
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

S = 4096  # vẽ lớn rồi thu nhỏ để khử răng cưa
OUT = Path(__file__).resolve().parents[2] / "Cozyday/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"

LAVENDER_TOP = (196, 181, 232)
LAVENDER_BOTTOM = (160, 141, 214)
CREAM = (252, 241, 222)
CREAM_SHADE = (240, 222, 196)
INK = (74, 60, 92)
BLUSH = (244, 176, 176)
SAGE = (163, 191, 160)


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def main():
    img = Image.new("RGB", (S, S), LAVENDER_TOP)
    d = ImageDraw.Draw(img)
    for y in range(S):
        d.line([(0, y), (S, y)], fill=lerp(LAVENDER_TOP, LAVENDER_BOTTOM, y / S))

    # thảm sage dưới chân mèo
    d.ellipse([S * 0.16, S * 0.78, S * 0.84, S * 0.94], fill=SAGE)

    # bóng mềm
    shadow = Image.new("L", (S, S), 0)
    ImageDraw.Draw(shadow).ellipse([S * 0.24, S * 0.74, S * 0.76, S * 0.86], fill=90)
    shadow = shadow.filter(ImageFilter.GaussianBlur(S * 0.02))
    img.paste((120, 104, 170), mask=shadow)

    # thân tròn
    d.ellipse([S * 0.20, S * 0.30, S * 0.80, S * 0.84], fill=CREAM)
    # tai
    d.polygon([(S * 0.27, S * 0.42), (S * 0.30, S * 0.20), (S * 0.45, S * 0.33)], fill=CREAM)
    d.polygon([(S * 0.73, S * 0.42), (S * 0.70, S * 0.20), (S * 0.55, S * 0.33)], fill=CREAM)
    d.polygon([(S * 0.31, S * 0.37), (S * 0.32, S * 0.26), (S * 0.41, S * 0.33)], fill=BLUSH)
    d.polygon([(S * 0.69, S * 0.37), (S * 0.68, S * 0.26), (S * 0.59, S * 0.33)], fill=BLUSH)
    # bụng
    d.ellipse([S * 0.34, S * 0.58, S * 0.66, S * 0.82], fill=CREAM_SHADE)

    # mắt cong (vui)
    w = int(S * 0.018)
    d.arc([S * 0.34, S * 0.45, S * 0.44, S * 0.53], start=200, end=340, fill=INK, width=w)
    d.arc([S * 0.56, S * 0.45, S * 0.66, S * 0.53], start=200, end=340, fill=INK, width=w)
    # má hồng
    d.ellipse([S * 0.29, S * 0.53, S * 0.37, S * 0.58], fill=BLUSH)
    d.ellipse([S * 0.63, S * 0.53, S * 0.71, S * 0.58], fill=BLUSH)
    # mũi + miệng
    d.polygon([(S * 0.485, S * 0.535), (S * 0.515, S * 0.535), (S * 0.5, S * 0.555)], fill=INK)
    d.arc([S * 0.455, S * 0.54, S * 0.50, S * 0.58], start=20, end=160, fill=INK, width=int(w * 0.7))
    d.arc([S * 0.50, S * 0.54, S * 0.545, S * 0.58], start=20, end=160, fill=INK, width=int(w * 0.7))

    # lá nhỏ trên đầu
    d.ellipse([S * 0.47, S * 0.235, S * 0.53, S * 0.335], fill=SAGE)

    img = img.resize((1024, 1024), Image.LANCZOS)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    img.save(OUT, "PNG", optimize=True)
    print(f"Đã ghi {OUT} ({img.size[0]}x{img.size[1]}, mode {img.mode})")


if __name__ == "__main__":
    main()
