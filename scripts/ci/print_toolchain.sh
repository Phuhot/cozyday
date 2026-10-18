#!/usr/bin/env bash
# In phiên bản công cụ vào log và ghi vào build/toolchain.txt để đính kèm artifact.
source "$(dirname "$0")/common.sh"

OUT="$BUILD_DIR/toolchain.txt"
{
  echo "macOS: $(sw_vers -productVersion) ($(sw_vers -buildVersion))"
  echo "Runner image: ${ImageOS:-?} ${ImageVersion:-?}"
  echo "Xcode: $(xcodebuild -version | tr '\n' ' ')"
  echo "Developer dir: $(xcode-select -p)"
  echo "Swift: $(xcrun swift --version 2>&1 | head -n 1)"
  echo "iOS SDK: $(xcrun --sdk iphoneos --show-sdk-version) ($(xcrun --sdk iphoneos --show-sdk-build-version))"
  echo "iOS Simulator SDK: $(xcrun --sdk iphonesimulator --show-sdk-version)"
  echo "XcodeGen: $(xcodegen --version 2>/dev/null || "$BUILD_DIR/tools/xcodegen/bin/xcodegen" --version)"
} | tee "$OUT"
