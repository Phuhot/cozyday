#!/usr/bin/env bash
# Quay footage giao diện thật cho trailer trên iOS Simulator (bản Debug, dữ liệu mẫu trong bộ nhớ).
# Mỗi clip mở app với `-CozyPreview <màn>`; các màn `trailer…` tự bấm theo kịch bản bằng đúng hàm của nút/cử chỉ
# (xem Cozyday/App/PreviewMode.swift). `-CozyTrailer 1` đổi thú cưng mẫu thành vịt vàng giống icon.
# Kết quả: build/trailer-footage/*.mp4 (video gốc của simulator, chưa nén) + device.txt.
source "$(dirname "$0")/common.sh"

[[ -d "$PROJECT" ]] || fail "Chưa có $PROJECT — chạy scripts/ci/generate_project.sh trước"
OUT="$BUILD_DIR/trailer-footage"
rm -rf "$OUT"
mkdir -p "$OUT"
# Múi giờ đang là khoảng 10:15–11:15 sáng lúc quay, để màn Hôm nay có việc vừa trễ giờ và thú cưng không ngủ
# (runner chạy theo giờ UTC, có thể đang là nửa đêm ở Việt Nam).
TZ_NAME="$(/usr/bin/python3 -c '
from datetime import datetime, timezone
from zoneinfo import ZoneInfo, available_timezones
now = datetime.now(timezone.utc)
for z in sorted(available_timezones()):
    if not z.startswith(("Asia/", "Europe/", "America/", "Pacific/", "Australia/", "Africa/")):
        continue
    t = now.astimezone(ZoneInfo(z))
    if 10 * 60 + 15 <= t.hour * 60 + t.minute <= 11 * 60 + 15:
        print(z)
        break
else:
    print("Asia/Ho_Chi_Minh")
')"
log "Múi giờ khi quay: $TZ_NAME ($(TZ=$TZ_NAME date '+%H:%M'))"
# Chỉ quay lại một số clip: commit message có "[clips: a b c]".
ONLY="$(printf '%s' "${COMMIT_MSG:-}" | sed -n 's/.*\[clips: *\([^]]*\)\].*/\1/p' | head -n 1)"

# Simulator: iPhone 17 Pro nếu có, không thì iPhone đầu tiên của runtime iOS mới nhất.
SIM_ID="$(xcrun simctl list devices available --json | /usr/bin/python3 -c '
import json, sys
data = json.load(sys.stdin)["devices"]
def ver(rt):
    tail = rt.rsplit(".", 1)[-1]
    return tuple(int(p) for p in tail.replace("iOS-", "").split("-") if p.isdigit())
cands = []
for runtime, devices in data.items():
    if ".iOS-" not in runtime:
        continue
    for d in devices:
        if d.get("isAvailable") and d["name"].startswith("iPhone"):
            cands.append((ver(runtime), d["name"] == "iPhone 17 Pro", d["udid"], d["name"], runtime))
if not cands:
    sys.exit("Không có simulator iPhone nào")
cands.sort(key=lambda c: (c[0], c[1]), reverse=True)
best = cands[0]
print(best[2])
print(best[3] + " / " + best[4], file=sys.stderr)
')"
[[ -n "$SIM_ID" ]] || fail "Không chọn được simulator"

run_logged "$LOG_DIR/xcodebuild-trailer.log" \
  xcodebuild build \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Debug \
    -destination "id=$SIM_ID" \
    -derivedDataPath "$BUILD_DIR/DerivedData-sim" \
    CODE_SIGNING_ALLOWED=NO \
    COMPILER_INDEX_STORE_ENABLE=NO
APP="$BUILD_DIR/DerivedData-sim/Build/Products/Debug-iphonesimulator/$APP_NAME.app"
[[ -d "$APP" ]] || fail "Không thấy $APP"

log "Khởi động simulator và cài bản Debug"
xcrun simctl boot "$SIM_ID" 2>/dev/null || true
xcrun simctl bootstatus "$SIM_ID" -b >/dev/null
xcrun simctl install "$SIM_ID" "$APP"
xcrun simctl ui "$SIM_ID" appearance light
xcrun simctl ui "$SIM_ID" content_size large
xcrun simctl status_bar "$SIM_ID" override --time "9:41" \
  --batteryState charged --batteryLevel 100 --cellularMode active --cellularBars 4 --wifiBars 3
# Mở app một lần cho nóng (lần mở đầu tiên sau khi cài chậm hơn hẳn).
SIMCTL_CHILD_TZ="$TZ_NAME" xcrun simctl launch --terminate-running-process "$SIM_ID" "$EXPECTED_BUNDLE_ID" \
  -CozyPreview today -AppleLanguages "(vi)" -AppleLocale vi_VN >/dev/null
sleep 6

failures=0
# clip <tên> <màn> <số giây>
clip() {
  local file="$1" screen="$2" secs="$3"
  local rec output pid
  if [[ -n "$ONLY" && " $ONLY " != *" $file "* ]]; then return; fi
  xcrun simctl terminate "$SIM_ID" "$EXPECTED_BUNDLE_ID" 2>/dev/null || true
  sleep 1
  xcrun simctl io "$SIM_ID" recordVideo --codec=h264 --force "$OUT/$file.mp4" >/dev/null 2>&1 &
  rec=$!
  sleep 1.5
  output="$(SIMCTL_CHILD_TZ="$TZ_NAME" xcrun simctl launch "$SIM_ID" "$EXPECTED_BUNDLE_ID" \
    -CozyPreview "$screen" -CozyTrailer 1 -AppleLanguages "(vi)" -AppleLocale vi_VN)"
  pid="${output##*: }"
  sleep "$secs"
  if ! kill -0 "$pid" 2>/dev/null; then
    echo "::error::App thoát/crash khi quay '$screen'"
    failures=$((failures + 1))
  fi
  kill -INT "$rec" 2>/dev/null || true
  wait "$rec" 2>/dev/null || true
  ls -la "$OUT/$file.mp4" 2>/dev/null || { echo "::error::Không quay được $file"; failures=$((failures + 1)); }
}

log "Quay footage"
clip today-tick trailerToday 7
clip feed trailerFeed 7
clip cuddle trailerCuddle 9
clip clean trailerClean 17
clip wardrobe trailerWardrobe 10
clip jump jump 16
clip basket basket 14
clip memory result 18
clip avatar avatar 5
clip room-bedroom bedroom 5
clip room-garden garden 5
clip room-kitchen kitchen 5

xcrun simctl terminate "$SIM_ID" "$EXPECTED_BUNDLE_ID" 2>/dev/null || true
xcrun simctl status_bar "$SIM_ID" clear || true
{
  echo "Simulator: $(xcrun simctl list devices | grep "$SIM_ID" | sed 's/^ *//')"
  echo "Commit: ${GITHUB_SHA:-local}"
  echo "Múi giờ: $TZ_NAME"
  echo "Clip quay lần này: ${ONLY:-tất cả}"
  echo "Bản build: Debug cho simulator, dữ liệu mẫu trong bộ nhớ, -CozyTrailer 1."
} > "$OUT/device.txt"
cat "$OUT/device.txt"
[[ $failures -eq 0 ]] || fail "$failures clip lỗi"
log "Đã quay $(ls "$OUT"/*.mp4 | wc -l | tr -d ' ') clip"
