#!/usr/bin/env bash
# Tải XcodeGen từ GitHub Releases chính thức (yonaskolb/XcodeGen), kiểm SHA-256 rồi cài
# vào build/tools. Không dùng Homebrew để phiên bản tái lập được.
source "$(dirname "$0")/common.sh"

: "${XCODEGEN_VERSION:?Cần đặt XCODEGEN_VERSION}"
: "${XCODEGEN_SHA256:?Cần đặt XCODEGEN_SHA256}"

TOOLS_DIR="$BUILD_DIR/tools"
mkdir -p "$TOOLS_DIR"
ZIP="$TOOLS_DIR/xcodegen-$XCODEGEN_VERSION.zip"
URL="https://github.com/yonaskolb/XcodeGen/releases/download/${XCODEGEN_VERSION}/xcodegen.zip"

log "Tải $URL"
curl --fail --location --silent --show-error --retry 3 --output "$ZIP" "$URL"

ACTUAL="$(shasum -a 256 "$ZIP" | awk '{print $1}')"
if [[ "$ACTUAL" != "$XCODEGEN_SHA256" ]]; then
  fail "SHA-256 của xcodegen.zip không khớp. Mong đợi $XCODEGEN_SHA256, nhận $ACTUAL"
fi
echo "SHA-256 khớp: $ACTUAL"

rm -rf "$TOOLS_DIR/xcodegen"
unzip -q "$ZIP" -d "$TOOLS_DIR"
XCODEGEN_BIN="$TOOLS_DIR/xcodegen/bin/xcodegen"
[[ -x "$XCODEGEN_BIN" ]] || fail "Không tìm thấy $XCODEGEN_BIN sau khi giải nén"

INSTALLED="$("$XCODEGEN_BIN" --version | awk '{print $NF}')"
[[ "$INSTALLED" == "$XCODEGEN_VERSION" ]] || fail "XcodeGen báo phiên bản $INSTALLED, mong đợi $XCODEGEN_VERSION"

if [[ -n "${GITHUB_PATH:-}" ]]; then
  echo "$TOOLS_DIR/xcodegen/bin" >> "$GITHUB_PATH"
fi
echo "XcodeGen $INSTALLED sẵn sàng: $XCODEGEN_BIN"
