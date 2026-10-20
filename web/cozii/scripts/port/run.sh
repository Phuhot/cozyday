#!/usr/bin/env bash
# Chạy lại toàn bộ bước chuyển hình vẽ Swift → TS (src/art/ported). Sau đó còn vài chỗ sửa tay (xem git log).
set -euo pipefail
cd "$(dirname "$0")/../.."
IOS=../../Cozyday/Features
OUT=src/art/ported
mkdir -p $OUT
for f in StudyArt BedroomArt KitchenArt BathArt GardenArt CostumeArt ItemPainter; do
  node scripts/port/swift2ts.mjs $IOS/Corner/Art/$f.swift > $OUT/$f.ts
done
node scripts/port/swift2ts.mjs $IOS/Corner/PetPainter.swift > $OUT/PetPainter.ts
for f in $OUT/*.ts; do
  sed -i "2i import { GC, Color, rgb, pt, R, Path, deg, Pt, Rect, linear, radial } from '../gc'\nimport { Palette } from '../palette'" $f
done
python3 scripts/port/fixups.py
python3 scripts/port/wrap-switch.py $OUT/*.ts
