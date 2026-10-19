#!/usr/bin/env bash
# Chạy trên Ubuntu: nén footage trailer (đã tải từ artifact vào build/trailer-footage) xuống 1080 px chiều ngang (đủ nét cho cảnh cận),
# ghi thống kê khung hình của bản gốc, rồi commit vào marketing/trailer/footage trên đúng nhánh vừa quay.
set -euo pipefail
SRC="build/trailer-footage"
DEST="marketing/trailer/footage"
BRANCH="${BRANCH:?thiếu BRANCH}"

ls "$SRC"/*.mp4 >/dev/null 2>&1 || { echo "::error::Không có clip trong $SRC"; exit 1; }
command -v ffmpeg >/dev/null || { sudo apt-get update -qq && sudo apt-get install -y -qq ffmpeg >/dev/null; }
rm -rf "$DEST"
mkdir -p "$DEST"
{
  echo "# Thống kê khung hình bản gốc (simulator ghi theo khung hình thay đổi, không cố định fps)"
  echo "clip | kích thước | thời lượng (s) | số khung | fps trung bình | khoảng hở lớn nhất (s)"
} > "$DEST/frames.txt"
for f in "$SRC"/*.mp4; do
  name="$(basename "$f" .mp4)"
  size="$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0:s=x "$f")"
  ffprobe -v error -select_streams v:0 -show_entries frame=pts_time -of csv=p=0 "$f" | sort -n > "/tmp/$name.pts"
  python3 - "$name" "$size" "/tmp/$name.pts" >> "$DEST/frames.txt" <<'PY'
import sys
name, size, path = sys.argv[1:4]
t = []
for line in open(path):
    v = line.strip().split(",")[0]
    try:
        t.append(float(v))
    except ValueError:
        pass
t.sort()
dur = t[-1] - t[0] if len(t) > 1 else 0
gap = max((b - a for a, b in zip(t, t[1:])), default=0)
fps = (len(t) - 1) / dur if dur > 0 else 0
print(f"{name} | {size} | {dur:.2f} | {len(t)} | {fps:.1f} | {gap:.2f}")
PY
  ffmpeg -v error -y -i "$f" -vf "scale=1080:-2:flags=lanczos" -fps_mode passthrough \
    -c:v libx264 -crf 22 -preset slow -pix_fmt yuv420p -an -movflags +faststart "$DEST/$name.mp4"
done
cp "$SRC/device.txt" "$DEST/" 2>/dev/null || true
cat "$DEST/frames.txt"
du -sh "$DEST"

git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git add -A "$DEST"
if git diff --cached --quiet; then
  echo "Footage không đổi, không cần commit."
  exit 0
fi
git commit -q -m "Footage trailer từ simulator (run ${GITHUB_RUN_NUMBER:-?}) [skip ci]"
for attempt in 1 2 3; do
  if git push origin "HEAD:$BRANCH"; then
    echo "Đã đẩy footage lên nhánh $BRANCH"
    exit 0
  fi
  echo "Push lỗi (lần $attempt), lấy bản mới nhất của nhánh rồi thử lại"
  git pull -q --rebase origin "$BRANCH"
done
echo "::error::Không push được footage"
exit 1
