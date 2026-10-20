#!/usr/bin/env bash
# Chạy trên Ubuntu: chép ảnh giao diện (đã tải từ artifact vào build/screenshots) vào docs/screenshots
# rồi commit lên đúng nhánh vừa build. Push bằng GITHUB_TOKEN không kích hoạt workflow mới.
set -euo pipefail
SRC="build/screenshots"
DEST="docs/screenshots"
BRANCH="${BRANCH:?thiếu BRANCH}"

ls "$SRC"/*.jpg >/dev/null 2>&1 || { echo "::error::Không có ảnh trong $SRC"; exit 1; }
rm -rf "$DEST"
mkdir -p "$DEST"
cp "$SRC"/*.jpg "$SRC/info.txt" "$DEST/"

git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git add -A "$DEST"
if git diff --cached --quiet; then
  echo "Ảnh không đổi, không cần commit."
  exit 0
fi
git commit -q -m "Cập nhật ảnh giao diện từ CI (run ${GITHUB_RUN_NUMBER:-?})"
for attempt in 1 2 3; do
  if git push origin "HEAD:$BRANCH"; then
    echo "Đã đẩy ảnh lên nhánh $BRANCH"
    exit 0
  fi
  echo "Push lỗi (lần $attempt), lấy bản mới nhất của nhánh rồi thử lại"
  git pull -q --rebase origin "$BRANCH"
done
echo "::error::Không push được ảnh"
exit 1
