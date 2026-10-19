#!/usr/bin/env bash
# Dựng lại trailer từ đầu. Chạy trên Linux có: Swift 6 + bản SwiftUI "giả" xuất SVG (xem README), Node + Playwright
# (Chromium), Python 3 + Pillow + numpy, ffmpeg. Biến môi trường:
#   RENDER_SWIFT  lệnh biên dịch & chạy harness_trailer.swift với file jobs (mặc định /opt/swiftimg/render_trailer.sh)
#   SVG_DIR       thư mục mà harness ghi SVG ra (mặc định /opt/swiftimg/root/work/trailer_io/svg)
#   WORK          thư mục tạm (mặc định ./build/trailer)
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../../.." && pwd)"
WORK="${WORK:-$REPO/build/trailer}"
RENDER_SWIFT="${RENDER_SWIFT:-$HERE/render_frames.sh}"
SVG_DIR="${SVG_DIR:-$WORK/svg}"
mkdir -p "$WORK/png" "$WORK/fonts" "$REPO/marketing/trailer/out"

# Phông chữ (SIL Open Font License): Baloo 2 cho tiêu đề, Nunito cho chữ nhỏ.
[[ -f "$WORK/fonts/Baloo2.ttf" ]] || curl -sSL -o "$WORK/fonts/Baloo2.ttf" "https://raw.githubusercontent.com/google/fonts/main/ofl/baloo2/Baloo2%5Bwght%5D.ttf"
[[ -f "$WORK/fonts/Nunito.ttf" ]] || curl -sSL -o "$WORK/fonts/Nunito.ttf" "https://raw.githubusercontent.com/google/fonts/main/ofl/nunito/Nunito%5Bwght%5D.ttf"

# 1) Khung hình vẽ bằng code của app → SVG → PNG trong suốt.
SVG_DIR="$SVG_DIR" python3 "$HERE/frames.py" "$WORK/jobs.txt"
rm -rf "$SVG_DIR" && mkdir -p "$SVG_DIR"
"$RENDER_SWIFT" "$WORK/jobs.txt"
: > "$WORK/svg-list.txt"
for f in "$SVG_DIR"/*.svg; do printf '%s\t%s\n' "$f" "$WORK/png/$(basename "$f" .svg).png" >> "$WORK/svg-list.txt"; done
node "$HERE/svg2png_batch.js" "$WORK/svg-list.txt"

# 2) Nhạc + hiệu ứng âm thanh.
python3 "$HERE/audio.py" "$WORK/audio.wav"

# 3) Dựng video + ảnh bìa (khung cuối).
cd "$HERE"
python3 compose.py "$WORK/png" "$REPO/marketing/trailer/footage" "$WORK/fonts/Baloo2.ttf" "$WORK/fonts/Nunito.ttf" \
  "$WORK/audio.wav" "$REPO/marketing/trailer/out/CozyDay-trailer-30s.mp4"
ffmpeg -v error -y -sseof -0.05 -i "$REPO/marketing/trailer/out/CozyDay-trailer-30s.mp4" -frames:v 1 -q:v 2 \
  "$REPO/marketing/trailer/out/CozyDay-trailer-cover.jpg"
echo "Xong: marketing/trailer/out/"
