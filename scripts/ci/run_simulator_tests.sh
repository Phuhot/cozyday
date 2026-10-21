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
# Bước chụp ảnh giao diện dùng lại đúng simulator này (đã khởi động sẵn).
echo "$SIM_ID" > "$BUILD_DIR/simulator-id.txt"

RESULT="$BUILD_DIR/TestResults.xcresult"
rm -rf "$RESULT"

# Build trước (log vào file), rồi chạy test và in tiến trình từng test ra log CI.
run_logged "$LOG_DIR/xcodebuild-build-for-testing.log" \
  xcodebuild build-for-testing \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Debug \
    -destination "id=$SIM_ID" \
    -derivedDataPath "$BUILD_DIR/DerivedData-sim" \
    CODE_SIGNING_ALLOWED=NO \
    COMPILER_INDEX_STORE_ENABLE=NO

log "Chạy test trên simulator (mỗi test tối đa 120 giây)"
set -o pipefail
status=0
xcodebuild test-without-building \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Debug \
    -destination "id=$SIM_ID" \
    -derivedDataPath "$BUILD_DIR/DerivedData-sim" \
    -resultBundlePath "$RESULT" \
    -parallel-testing-enabled NO \
    -test-timeouts-enabled YES \
    -default-test-execution-time-allowance 60 \
    -maximum-test-execution-time-allowance 120 \
  2>&1 | tee "$LOG_DIR/xcodebuild-test.log" \
       | (grep --line-buffered -E "Test (Case|Suite).*(passed|failed|started at)|error:|Executed [0-9]+|\*\* TEST|Testing started|Restarting after" || true) \
  || status=$?
python3 - "$LOG_DIR/xcodebuild-test.log" <<'PY_REPORT'
import sys
from pathlib import Path
lines = Path(sys.argv[1]).read_text(errors="replace").splitlines()
for line in dict.fromkeys(line for line in lines if "error:" in line or "Executed " in line or "** TEST" in line):
    level = "error" if "error:" in line else "notice"
    escaped = line.replace("%", "%25").replace("\r", "%0D").replace("\n", "%0A")
    print(f"::{level}::{escaped}")
PY_REPORT
if [[ $status -ne 0 ]]; then
  echo "---- 80 dòng cuối log test ----"
  tail -n 80 "$LOG_DIR/xcodebuild-test.log"
  fail "Test thất bại (exit code $status)"
fi
