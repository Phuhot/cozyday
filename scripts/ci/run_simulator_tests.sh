#!/usr/bin/env bash
# Chạy unit test trên iOS Simulator. Lưu ý: test simulator KHÔNG chứng minh IPA cài được
# trên iPhone thật — đó là việc riêng của bước build thiết bị + cài thử.
source "$(dirname "$0")/common.sh"

[[ -d "$PROJECT" ]] || fail "Chưa có $PROJECT — chạy scripts/ci/generate_project.sh trước"

# Chọn simulator iPhone đầu tiên còn dùng được với runtime iOS mới nhất trên runner.
SIM_ID="$(xcrun simctl list devices available --json | /usr/bin/python3 -c '
import json, sys
data = json.load(sys.stdin)["devices"]
def ver(rt):
    tail = rt.rsplit(".", 1)[-1]
    return tuple(int(p) for p in tail.replace("iOS-", "").split("-") if p.isdigit())
best = None
for runtime, devices in data.items():
    if ".iOS-" not in runtime:
        continue
    for d in devices:
        if d.get("isAvailable") and d["name"].startswith("iPhone"):
            key = (ver(runtime), d["name"])
            if best is None or key[0] > best[0][0]:
                best = (key, d["udid"], d["name"], runtime)
if best is None:
    sys.exit("Không có simulator iPhone nào")
print(best[1])
print(best[2] + " / " + best[3], file=sys.stderr)
')"
[[ -n "$SIM_ID" ]] || fail "Không chọn được simulator"

RESULT="$BUILD_DIR/TestResults.xcresult"
rm -rf "$RESULT"
run_logged "$LOG_DIR/xcodebuild-test.log" \
  xcodebuild test \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Debug \
    -destination "id=$SIM_ID" \
    -derivedDataPath "$BUILD_DIR/DerivedData-sim" \
    -resultBundlePath "$RESULT" \
    CODE_SIGNING_ALLOWED=NO \
    COMPILER_INDEX_STORE_ENABLE=NO
