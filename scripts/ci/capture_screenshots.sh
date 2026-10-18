#!/usr/bin/env bash
# Chụp ảnh giao diện trên iOS Simulator bằng bản Debug đã build ở bước test.
# App được mở với `-CozyPreview <màn hình>`: dữ liệu mẫu nằm trong bộ nhớ (xem Cozyday/App/PreviewMode.swift).
# Ảnh để xem giao diện trước khi cài — KHÔNG thay cho việc thử trên iPhone thật.
source "$(dirname "$0")/common.sh"

SIM_ID="$(cat "$BUILD_DIR/simulator-id.txt" 2>/dev/null || true)"
[[ -n "$SIM_ID" ]] || fail "Không có simulator-id.txt — chạy scripts/ci/run_simulator_tests.sh trước"
APP="$BUILD_DIR/DerivedData-sim/Build/Products/Debug-iphonesimulator/$APP_NAME.app"
[[ -d "$APP" ]] || fail "Không thấy $APP"

OUT="$BUILD_DIR/screenshots"
RAW="$BUILD_DIR/screenshots-raw"
rm -rf "$OUT" "$RAW"
mkdir -p "$OUT" "$RAW" "$BUILD_DIR/output"
TZ_NAME="Asia/Ho_Chi_Minh"

log "Khởi động simulator $SIM_ID và cài bản Debug"
xcrun simctl bootstatus "$SIM_ID" -b >/dev/null
xcrun simctl install "$SIM_ID" "$APP"
xcrun simctl ui "$SIM_ID" appearance light
xcrun simctl ui "$SIM_ID" content_size large
xcrun simctl status_bar "$SIM_ID" override --time "$(TZ=$TZ_NAME date +%H:%M)" \
  --batteryState charged --batteryLevel 100 --cellularMode active --cellularBars 4 --wifiBars 3

failures=0
shot() {
  local file="$1" screen="$2"
  local output pid
  # SIMCTL_CHILD_TZ: app chạy theo giờ Việt Nam thay vì giờ UTC của runner.
  output="$(SIMCTL_CHILD_TZ="$TZ_NAME" xcrun simctl launch --terminate-running-process "$SIM_ID" "$EXPECTED_BUNDLE_ID" \
    -CozyPreview "$screen" -AppleLanguages "(vi)" -AppleLocale vi_VN)"
  pid="${output##*: }"
  sleep 4
  if ! kill -0 "$pid" 2>/dev/null; then
    echo "::error::App thoát/crash khi mở màn '$screen'"
    local report
    report="$(ls -t "$HOME/Library/Logs/DiagnosticReports/" 2>/dev/null | grep -i "$APP_NAME" | head -n 1 || true)"
    [[ -n "$report" ]] && head -n 80 "$HOME/Library/Logs/DiagnosticReports/$report" || true
    failures=$((failures + 1))
  fi
  xcrun simctl io "$SIM_ID" screenshot --type=png "$RAW/$file.png" >/dev/null
  sips -s format jpeg -s formatOptions 72 -Z 1300 "$RAW/$file.png" --out "$OUT/$file.jpg" >/dev/null
  echo "  $file.jpg ($screen)"
}

log "Giao diện sáng"
shot 01-onboarding onboarding
shot 02-today today
shot 03-task-editor editor
shot 04-replan replan
shot 05-inbox inbox
shot 06-focus focus
shot 07-corner corner
shot 08-shop shop
shot 09-journal journal
shot 10-progress progress
shot 11-settings settings
shot 12-wardrobe wardrobe
shot 13-adventure adventure
shot 14-memories memories
shot 15-pet-gallery gallery
shot 16-breathing breathing
shot 17-task-detail taskDetail
shot 18-journal-editor journalEditor

log "Giao diện tối"
xcrun simctl ui "$SIM_ID" appearance dark
shot dark-02-today today
shot dark-06-focus focus
shot dark-07-corner corner
shot dark-09-journal journal
shot dark-10-progress progress
shot dark-12-wardrobe wardrobe
shot dark-15-pet-gallery gallery
xcrun simctl ui "$SIM_ID" appearance light

log "Cỡ chữ rất lớn (Trợ năng)"
xcrun simctl ui "$SIM_ID" content_size accessibility-extra-large
shot large-02-today today
shot large-03-task-editor editor
xcrun simctl ui "$SIM_ID" content_size large

xcrun simctl terminate "$SIM_ID" "$EXPECTED_BUNDLE_ID" 2>/dev/null || true
xcrun simctl status_bar "$SIM_ID" clear || true

{
  echo "Ảnh chụp trên: $(xcrun simctl list devices | grep "$SIM_ID" | sed 's/^ *//')"
  echo "Giờ trong ảnh: $(TZ=$TZ_NAME date '+%Y-%m-%d %H:%M') ($TZ_NAME)"
  echo "Commit: ${GITHUB_SHA:-local}"
  echo "Bản build: Debug cho simulator, dữ liệu mẫu trong bộ nhớ."
} > "$OUT/info.txt"
cat "$OUT/info.txt"

# Bản .app cho simulator (dùng cho dịch vụ chạy simulator trên trình duyệt, nếu bạn muốn thử).
ditto -c -k --sequesterRsrc --keepParent "$APP" "$BUILD_DIR/output/Cozyday-simulator-app.zip"

[[ $failures -eq 0 ]] || fail "$failures màn hình bị crash khi chụp"
log "Đã chụp $(ls "$OUT"/*.jpg | wc -l | tr -d ' ') ảnh"
