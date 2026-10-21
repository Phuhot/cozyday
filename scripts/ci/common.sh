#!/usr/bin/env bash
# Hàm dùng chung cho các script CI. Chỉ chạy trên macOS runner của GitHub Actions.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BUILD_DIR="${BUILD_DIR:-$ROOT_DIR/build}"
LOG_DIR="$BUILD_DIR/logs"
APP_NAME="Cozyday"
SCHEME="Cozyday"
PROJECT="$ROOT_DIR/Cozyday.xcodeproj"
EXPECTED_BUNDLE_ID="com.phuhot.cozyday"
EXPECTED_MIN_OS="17.0"

mkdir -p "$BUILD_DIR" "$LOG_DIR"

log()  { printf '\n==> %s\n' "$*"; }
fail() { printf '\n::error::%s\n' "$*" >&2; exit 1; }

# Chạy lệnh, ghi toàn bộ output vào file log; nếu lỗi thì in phần cuối log + các dòng error
# rồi trả về đúng exit code của lệnh (không nuốt lỗi).
run_logged() {
  local logfile="$1"; shift
  log "$* (log: ${logfile#$ROOT_DIR/})"
  local status=0
  "$@" >"$logfile" 2>&1 || status=$?
  if [[ $status -ne 0 ]]; then
    # Surface compiler diagnostics in the Checks API as well as archived logs.
    python3 - "$logfile" <<'PY_ERRORS'
import sys
from pathlib import Path
lines = Path(sys.argv[1]).read_text(errors="replace").splitlines()
errors = list(dict.fromkeys(line for line in lines if "error:" in line or "fatal error" in line))
for line in errors[:40]:
    escaped = line.replace("%", "%25").replace("\r", "%0D").replace("\n", "%0A")
    print("::error::" + escaped)
PY_ERRORS
    echo "---- 40 dòng lỗi đầu tiên ----"
    grep -nE "error:|fatal error|\*\* (BUILD|ARCHIVE|TEST) FAILED" "$logfile" | head -n 40 || true
    echo "---- 120 dòng cuối log ----"
    tail -n 120 "$logfile"
    fail "Lệnh thất bại với exit code $status"
  fi
  grep -E "\*\* (BUILD|ARCHIVE|TEST) SUCCEEDED|Executed [0-9]+ tests?" "$logfile" | tail -n 3 || true
  # Tóm tắt cảnh báo trong source của dự án (không tính cảnh báo của hệ thống).
  local warnings
  warnings="$(grep -E "^$ROOT_DIR/(Cozyday|Tests)/.*: warning: " "$logfile" | sed "s|^$ROOT_DIR/||" | sort -u || true)"
  if [[ -n "$warnings" ]]; then
    echo "---- Cảnh báo biên dịch trong source ($(echo "$warnings" | wc -l | tr -d ' ')) ----"
    echo "$warnings" | head -n 60
  fi
}
