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
VIDEO="$BUILD_DIR/output/videos"
rm -rf "$OUT" "$RAW" "$VIDEO"
mkdir -p "$OUT" "$RAW" "$BUILD_DIR/output" "$VIDEO"
TZ_NAME="Asia/Ho_Chi_Minh"

log "Khởi động simulator $SIM_ID và cài bản Debug"
xcrun simctl bootstatus "$SIM_ID" -b >/dev/null
xcrun simctl install "$SIM_ID" "$APP"
xcrun simctl ui "$SIM_ID" appearance light
xcrun simctl ui "$SIM_ID" content_size large
# Giờ trên thanh trạng thái chỉ để ảnh đẹp: simctl có lúc từ chối chuỗi giờ (ví dụ "00:05" lúc nửa đêm VN),
# khi đó dùng giờ cố định 9:41, và lỗi ở bước này không được làm hỏng cả lượt chụp.
status_bar() {
  xcrun simctl status_bar "$SIM_ID" override --time "$1" \
    --batteryState charged --batteryLevel 100 --cellularMode active --cellularBars 4 --wifiBars 3
}
status_bar "$(TZ=$TZ_NAME date +%H:%M)" || status_bar "9:41" || echo "::warning::Không đặt được thanh trạng thái"

failures=0
launch() {
  local screen="$1"
  local output
  # SIMCTL_CHILD_TZ: app chạy theo giờ Việt Nam thay vì giờ UTC của runner.
  output="$(SIMCTL_CHILD_TZ="$TZ_NAME" xcrun simctl launch --terminate-running-process "$SIM_ID" "$EXPECTED_BUNDLE_ID" \
    -CozyPreview "$screen" -AppleLanguages "(vi)" -AppleLocale vi_VN)"
  echo "${output##*: }"
}
check_alive() {
  local pid="$1" screen="$2"
  if ! kill -0 "$pid" 2>/dev/null; then
    echo "::error::App thoát/crash khi mở màn '$screen'"
    local report
    report="$(ls -t "$HOME/Library/Logs/DiagnosticReports/" 2>/dev/null | grep -i "$APP_NAME" | head -n 1 || true)"
    [[ -n "$report" ]] && head -n 80 "$HOME/Library/Logs/DiagnosticReports/$report" || true
    failures=$((failures + 1))
  fi
}
grab() {
  local file="$1"
  xcrun simctl io "$SIM_ID" screenshot --type=png "$RAW/$file.png" >/dev/null
  sips -s format jpeg -s formatOptions 72 -Z 1300 "$RAW/$file.png" --out "$OUT/$file.jpg" >/dev/null
}
# shot <tên ảnh> <màn> [số giây chờ — mặc định 4; màn game cần chờ đếm ngược và lượt chơi]
shot() {
  local file="$1" screen="$2" wait="${3:-4}"
  local pid
  pid="$(launch "$screen")"
  sleep "$wait"
  check_alive "$pid" "$screen"
  grab "$file"
  echo "  $file.jpg ($screen)"
}
# burst <tên> <màn> <chờ> <số ảnh> <cách nhau (giây)>: chụp liên tiếp khi game đang chạy để xem chuyển động.
burst() {
  local file="$1" screen="$2" wait="$3" count="$4" gap="$5"
  local pid i
  pid="$(launch "$screen")"
  sleep "$wait"
  for ((i = 1; i <= count; i++)); do
    grab "$file-$i"
    sleep "$gap"
  done
  check_alive "$pid" "$screen"
  echo "  $file-1..$count.jpg ($screen)"
}
# record <tên> <màn> <số giây>: quay video gameplay (bản Debug tự chơi) — chỉ để xem, đưa vào artifact.
record() {
  local file="$1" screen="$2" secs="$3"
  local rec pid
  xcrun simctl io "$SIM_ID" recordVideo --codec=h264 --force "$VIDEO/$file.mp4" >/dev/null 2>&1 &
  rec=$!
  sleep 1
  pid="$(launch "$screen")"
  sleep "$secs"
  check_alive "$pid" "$screen"
  kill -INT "$rec" 2>/dev/null || true
  wait "$rec" 2>/dev/null || true
  ls -la "$VIDEO/$file.mp4" 2>/dev/null || echo "::warning::Không quay được video $file"
}

log "Phiên 9: giao dịch, cấp, bộ sưu tập và phim capsule"
shot v9-quests quests
shot v9-life life
shot v9-tiers gachaTiers
record v9-gacha-cutscene gachaFilm 20
burst v9-gacha-motion gachaFilm 1 5 1.5

# Full regression footage remains the default. Focused reruns retain all unit tests,
# and only recapture changed V9 flows after the complete visual run has been reviewed.
if [[ "${COZY_VISUAL_SUITE:-full}" == "focused" ]]; then
  shot 01-onboarding onboarding
  shot 02-today today
  shot 06-focus focus
  shot 07-corner corner
  shot 47-gacha-result gachaResult 13
  shot 46-gacha gacha 5
  shot 14-memories memories
  xcrun simctl ui "$SIM_ID" appearance dark
  shot dark-02-today today
  shot dark-06-focus focus
  shot dark-07-corner corner
  shot dark-v9-quests quests
  shot dark-v9-life life
  xcrun simctl ui "$SIM_ID" appearance light
  xcrun simctl ui "$SIM_ID" content_size accessibility-extra-extra-extra-large
  shot large-06-focus focus
  shot large-07-corner corner
  shot large-v9-quests quests
  xcrun simctl ui "$SIM_ID" content_size large
else
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
shot 19-bedroom bedroom
shot 20-kitchen kitchen
shot 21-bath bath
shot 22-garden garden
shot 23-collection collection
shot 24-look look
shot 25-care care
shot 26-food food
shot 27-feed feed 6
shot 28-clean clean
shot 29-care-capped careCapped 6
shot 30-playground playground 5
shot 31-pick-pet pickPet 5
shot 32-tutorial tutorial 5
shot 33-jump jump 11
shot 34-basket basket 11
shot 35-memory memory 12
shot 36-pause pause 13
shot 37-result result 17
shot 38-result-capped resultCapped 17
burst 39-jump-frames jump 7 4 0.7
burst 40-basket-frames basket 7 4 0.7
shot 41-avatar avatar 5
shot 42-avatar-outfit avatarOutfit 5
shot 43-blocks blocks 12
shot 50-focus-idle focusIdle 4
shot 51-focus-settings focusSettings 5
shot 52-focus-full focusFull 5
shot 53-focus-mini focusMini 4
shot 44-merge merge 12
shot 45-tour tour 4
shot 46-gacha gacha 5
shot 47-gacha-result gachaResult 13
shot 48-shop-floor shopFloor 5
shot 49-wardrobe-secret wardrobeSecret 5

log "Quay video gameplay"
record video-jump jump 18
record video-basket basket 18
record video-memory result 18
record video-blocks blocks 18
record video-merge merge 18

log "Giao diện tối"
xcrun simctl ui "$SIM_ID" appearance dark
shot dark-02-today today
shot dark-06-focus focus
shot dark-07-corner corner
shot dark-09-journal journal
shot dark-10-progress progress
shot dark-12-wardrobe wardrobe
shot dark-15-pet-gallery gallery
shot dark-19-bedroom bedroom
shot dark-25-care care
shot dark-26-food food
shot dark-30-playground playground 5
shot dark-35-memory memory 12
shot dark-37-result result 17
shot dark-41-avatar avatar 5
shot dark-28-clean clean
shot dark-46-gacha gacha 5
shot dark-52-focus-full focusFull 5
xcrun simctl ui "$SIM_ID" appearance light

log "Cỡ chữ rất lớn (Trợ năng)"
xcrun simctl ui "$SIM_ID" content_size accessibility-extra-large
shot large-02-today today
shot large-03-task-editor editor
shot large-25-care care
shot large-26-food food
shot large-30-playground playground 5
shot large-37-result result 17
shot large-41-avatar avatar 5
shot large-28-clean clean
shot large-46-gacha gacha 5
shot large-07-corner corner
shot large-06-focus focus
xcrun simctl ui "$SIM_ID" content_size large

fi

# Targeted layouts requested for the 428pt iPhone 12 Pro Max and smaller 375pt SE.
ORIGINAL_SIM_ID="$SIM_ID"
RUNTIME_ID="$(xcrun simctl list devices available --json | /usr/bin/python3 -c 'import json,sys; data=json.load(sys.stdin)["devices"]; print(next(r for r, ds in data.items() if any(d["udid"] == sys.argv[1] for d in ds)))' "$SIM_ID")"
for MODEL in iPhone-12-Pro-Max iPhone-SE-3rd-generation; do
  if EXTRA_SIM_ID="$(xcrun simctl create "Cozyday layout $MODEL" "com.apple.CoreSimulator.SimDeviceType.$MODEL" "$RUNTIME_ID")"; then
    SIM_ID="$EXTRA_SIM_ID"
    xcrun simctl boot "$SIM_ID"
    xcrun simctl bootstatus "$SIM_ID" -b >/dev/null
    xcrun simctl install "$SIM_ID" "$APP"
    xcrun simctl ui "$SIM_ID" content_size large
    shot "v9-$MODEL-today" today
    shot "v9-$MODEL-empty" todayEmpty
    xcrun simctl ui "$SIM_ID" content_size accessibility-extra-large
    shot "v9-$MODEL-large" today
    xcrun simctl shutdown "$SIM_ID"
    xcrun simctl delete "$SIM_ID"
  else
    echo "::warning::Could not create $MODEL; inspect the corresponding layout on a real device."
  fi
done
SIM_ID="$ORIGINAL_SIM_ID"
xcrun simctl terminate "$SIM_ID" "$EXPECTED_BUNDLE_ID" 2>/dev/null || true
xcrun simctl status_bar "$SIM_ID" clear || true

{
  echo "Ảnh chụp trên: $(xcrun simctl list devices | grep "$SIM_ID" | sed 's/^ *//')"
  echo "Giờ trong ảnh: $(TZ=$TZ_NAME date '+%Y-%m-%d %H:%M') ($TZ_NAME)"
  echo "Commit: ${GITHUB_SHA:-local}"
  echo "Bản build: Debug cho simulator, dữ liệu mẫu trong bộ nhớ."
  echo "Phạm vi ảnh: ${COZY_VISUAL_SUITE:-full}"
} > "$OUT/info.txt"
cat "$OUT/info.txt"

# Bản .app cho simulator (dùng cho dịch vụ chạy simulator trên trình duyệt, nếu bạn muốn thử).
ditto -c -k --sequesterRsrc --keepParent "$APP" "$BUILD_DIR/output/Cozyday-simulator-app.zip"

[[ $failures -eq 0 ]] || fail "$failures màn hình bị crash khi chụp"
log "Đã chụp $(ls "$OUT"/*.jpg | wc -l | tr -d ' ') ảnh"
