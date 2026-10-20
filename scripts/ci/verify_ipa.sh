#!/usr/bin/env bash
# Kiểm tra cấu trúc IPA trước khi upload. Thiếu thứ gì quan trọng thì FAIL, không upload IPA hỏng.
source "$(dirname "$0")/common.sh"

IPA="${1:-$BUILD_DIR/output/$APP_NAME-unsigned.ipa}"
[[ -s "$IPA" ]] || fail "Không có IPA tại $IPA"

WORK="$BUILD_DIR/verify"
rm -rf "$WORK"; mkdir -p "$WORK"
unzip -q "$IPA" -d "$WORK"

REPORT="$BUILD_DIR/output/build-info.txt"
warnings=0
warn() { printf '::warning::%s\n' "$*"; warnings=$((warnings + 1)); }
pl()   { plutil -extract "$1" raw -o - "$INFO" 2>/dev/null || true; }

# 1. Chỉ có Payload/ ở gốc ZIP, và đúng Payload/Cozyday.app
TOP="$(unzip -Z1 "$IPA" | cut -d/ -f1 | sort -u | tr '\n' ' ')"
[[ "$TOP" == "Payload " ]] || fail "Gốc IPA phải chỉ có Payload/, đang có: $TOP"
APP="$WORK/Payload/$APP_NAME.app"
[[ -d "$APP" ]] || fail "Thiếu Payload/$APP_NAME.app"

# 2. Info.plist
INFO="$APP/Info.plist"
[[ -f "$INFO" ]] || fail "Thiếu Info.plist"
EXE_NAME="$(pl CFBundleExecutable)"
BUNDLE_ID="$(pl CFBundleIdentifier)"
MIN_OS="$(pl MinimumOSVersion)"
PLATFORM_NAME="$(pl DTPlatformName)"
SUPPORTED="$(pl CFBundleSupportedPlatforms.0)"
VERSION="$(pl CFBundleShortVersionString)"
BUILD="$(pl CFBundleVersion)"
DT_SDK="$(pl DTSDKName)"
DT_XCODE="$(pl DTXcodeBuild)"
ICON_NAME="$(pl CFBundleIcons.CFBundlePrimaryIcon.CFBundleIconName)"

[[ "$EXE_NAME" == "$APP_NAME" ]] || fail "CFBundleExecutable='$EXE_NAME', mong đợi '$APP_NAME'"
[[ "$BUNDLE_ID" == "$EXPECTED_BUNDLE_ID" ]] || fail "Bundle ID='$BUNDLE_ID', mong đợi '$EXPECTED_BUNDLE_ID'"
[[ "$MIN_OS" == "$EXPECTED_MIN_OS" ]] || fail "MinimumOSVersion='$MIN_OS', mong đợi '$EXPECTED_MIN_OS'"
[[ "$PLATFORM_NAME" == "iphoneos" ]] || fail "DTPlatformName='$PLATFORM_NAME' — đây không phải bản build cho thiết bị thật"
[[ "$SUPPORTED" == "iPhoneOS" ]] || fail "CFBundleSupportedPlatforms='$SUPPORTED', mong đợi iPhoneOS"
[[ -n "$VERSION" && -n "$BUILD" ]] || fail "Thiếu số phiên bản"

# 3. File thực thi: arm64, platform IOS (không phải IOSSIMULATOR), có quyền thực thi
EXE="$APP/$EXE_NAME"
[[ -f "$EXE" ]] || fail "Thiếu file thực thi $EXE_NAME"
[[ -x "$EXE" ]] || fail "File thực thi không có quyền +x sau khi giải nén"
unzip -Z "$IPA" "Payload/$APP_NAME.app/$EXE_NAME" | grep -q -- "-rwx" || fail "Quyền +x của file thực thi bị mất trong ZIP"
ARCHS="$(lipo -archs "$EXE")"
[[ "$ARCHS" == "arm64" ]] || fail "Kiến trúc '$ARCHS', mong đợi đúng arm64"
BUILD_VER="$(xcrun vtool -show-build "$EXE")"
echo "$BUILD_VER" | grep -qE "platform IOS$" || { echo "$BUILD_VER"; fail "LC_BUILD_VERSION không phải platform IOS (có thể là simulator)"; }
if otool -l "$EXE" | grep -q "sectname __entitlements"; then
  fail "Binary chứa section __entitlements (dấu hiệu build simulator)"
fi
# Chế độ dữ liệu mẫu (chụp ảnh giao diện) chỉ được có trong bản Debug.
if strings -a "$EXE" | grep -q "CozyPreview"; then
  fail "Bản Release chứa mã xem trước CozyPreview (lẽ ra chỉ có trong Debug)"
fi

# 4. Icon
[[ -f "$APP/Assets.car" ]] || fail "Thiếu Assets.car (asset catalog chưa được biên dịch)"
[[ "$ICON_NAME" == "AppIcon" ]] || fail "CFBundleIcons chưa trỏ tới AppIcon (đang là '$ICON_NAME')"
ls "$APP"/AppIcon*.png >/dev/null 2>&1 || warn "Không thấy AppIcon*.png rời trong bundle (Xcode có thể chỉ để icon trong Assets.car)"

# 5. Không có thành phần ngoài phạm vi bản 1.0
[[ ! -e "$APP/embedded.mobileprovision" ]] || fail "IPA chưa ký không được chứa provisioning profile"
[[ ! -d "$APP/PlugIns" ]] || fail "Có app extension (PlugIns/) — ngoài phạm vi bản 1.0"
[[ ! -d "$APP/Watch" ]] || fail "Có Watch app — ngoài phạm vi bản 1.0"
[[ ! -d "$APP/_CodeSignature" ]] || warn "Bundle có _CodeSignature dù build unsigned"

SHA="$(shasum -a 256 "$IPA" | awk '{print $1}')"
SIZE="$(stat -f%z "$IPA")"

{
  echo "Cozyday unsigned IPA"
  echo "File: $(basename "$IPA")"
  echo "SHA-256: $SHA"
  echo "Size (bytes): $SIZE"
  echo "Bundle ID: $BUNDLE_ID"
  echo "Version: $VERSION ($BUILD)"
  echo "MinimumOSVersion: $MIN_OS"
  echo "Platform: $PLATFORM_NAME / $SUPPORTED / $ARCHS"
  echo "SDK: $DT_SDK · Xcode build $DT_XCODE"
  echo "Commit: ${GITHUB_SHA:-local}"
  echo "Ref: ${GITHUB_REF_NAME:-local}"
  echo "Workflow run: ${GITHUB_SERVER_URL:-}/${GITHUB_REPOSITORY:-}/actions/runs/${GITHUB_RUN_ID:-}"
  echo "Built at (UTC): $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "Signed: NO — cần ký lại bằng Sideloadly khi cài"
  echo
  echo "Toolchain:"
  cat "$BUILD_DIR/toolchain.txt" 2>/dev/null || echo "(không có toolchain.txt)"
} > "$REPORT"

cat "$REPORT"
echo
echo "Kiểm tra IPA: ĐẠT (cảnh báo: $warnings)"
