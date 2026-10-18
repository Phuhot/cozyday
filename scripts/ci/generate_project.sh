#!/usr/bin/env bash
# Tạo Cozyday.xcodeproj từ project.yml và kiểm tra scheme/target cần thiết.
source "$(dirname "$0")/common.sh"

XCODEGEN_BIN="${XCODEGEN_BIN:-$(command -v xcodegen || echo "$BUILD_DIR/tools/xcodegen/bin/xcodegen")}"
[[ -x "$XCODEGEN_BIN" ]] || fail "Chưa cài XcodeGen (chạy scripts/ci/install_xcodegen.sh trước)"

cd "$ROOT_DIR"
"$XCODEGEN_BIN" generate --spec project.yml --project "$ROOT_DIR"

[[ -d "$PROJECT" ]] || fail "Không tạo được $PROJECT"
[[ -f "$PROJECT/xcshareddata/xcschemes/$SCHEME.xcscheme" ]] || fail "Thiếu shared scheme $SCHEME"

xcodebuild -list -project "$PROJECT" | tee "$LOG_DIR/xcodebuild-list.txt"
grep -q "^        $APP_NAME$" "$LOG_DIR/xcodebuild-list.txt" || fail "Thiếu target $APP_NAME"
grep -q "^        ${APP_NAME}Tests$" "$LOG_DIR/xcodebuild-list.txt" || fail "Thiếu target ${APP_NAME}Tests"
