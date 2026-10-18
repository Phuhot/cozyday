#!/usr/bin/env bash
# Build Release cho thiết bị thật (iphoneos, arm64), KHÔNG ký, rồi đóng gói
# Payload/Cozyday.app thành build/output/Cozyday-unsigned.ipa.
# IPA chưa ký: Sideloadly sẽ ký lại bằng Apple Account của bạn khi cài.
source "$(dirname "$0")/common.sh"

ARCHIVE="$BUILD_DIR/$APP_NAME.xcarchive"
DERIVED="$BUILD_DIR/DerivedData"
OUT_DIR="$BUILD_DIR/output"
STAGE="$BUILD_DIR/ipa-stage"
IPA="$OUT_DIR/$APP_NAME-unsigned.ipa"
BUILD_NUMBER="${BUILD_NUMBER:-${GITHUB_RUN_NUMBER:-1}}"

[[ -d "$PROJECT" ]] || fail "Chưa có $PROJECT — chạy scripts/ci/generate_project.sh trước"
rm -rf "$ARCHIVE" "$STAGE" "$OUT_DIR"
mkdir -p "$OUT_DIR" "$STAGE/Payload"

run_logged "$LOG_DIR/xcodebuild-archive.log" \
  xcodebuild archive \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Release \
    -sdk iphoneos \
    -destination "generic/platform=iOS" \
    -archivePath "$ARCHIVE" \
    -derivedDataPath "$DERIVED" \
    ARCHS=arm64 \
    ONLY_ACTIVE_ARCH=NO \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGN_ENTITLEMENTS="" \
    DEVELOPMENT_TEAM="" \
    CURRENT_PROJECT_VERSION="$BUILD_NUMBER" \
    COMPILER_INDEX_STORE_ENABLE=NO

APP="$ARCHIVE/Products/Applications/$APP_NAME.app"
[[ -d "$APP" ]] || fail "Archive không chứa $APP_NAME.app (xem build/logs/xcodebuild-archive.log)"

log "Đóng gói IPA"
# ditto giữ nguyên quyền file và symlink của bundle.
ditto "$APP" "$STAGE/Payload/$APP_NAME.app"
(cd "$STAGE" && /usr/bin/zip -q -r -y -X "$IPA" Payload)
[[ -s "$IPA" ]] || fail "IPA rỗng"

(cd "$OUT_DIR" && shasum -a 256 "$(basename "$IPA")" > "$(basename "$IPA").sha256")
cat "$IPA.sha256"
ls -lh "$IPA"
