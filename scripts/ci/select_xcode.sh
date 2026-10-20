#!/usr/bin/env bash
# Chọn đúng phiên bản Xcode đã pin (biến XCODE_VERSION) trên runner macOS.
source "$(dirname "$0")/common.sh"

: "${XCODE_VERSION:?Cần đặt XCODE_VERSION, ví dụ 26.6}"
XCODE_APP="/Applications/Xcode_${XCODE_VERSION}.app"
if [[ ! -d "$XCODE_APP" ]]; then
  echo "Các bản Xcode có trên runner:"
  ls -d /Applications/Xcode*.app || true
  fail "Không thấy $XCODE_APP. Runner image đã thay đổi — cập nhật XCODE_VERSION trong workflow theo danh sách trên."
fi
sudo xcode-select -s "$XCODE_APP/Contents/Developer"
xcodebuild -version
