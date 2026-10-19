#!/usr/bin/env bash
# render_frames.sh <jobs.txt>: biên dịch harness_trailer.swift cùng code vẽ THẬT của app (Core, PetPainter, ItemPainter,
# các file Art, AvatarPainter) với bản SwiftUI giả xuất SVG (svg_shim/), rồi vẽ mọi khung trong jobs.txt.
# Cần swiftc (Swift 6, Linux). Đường dẫn SVG trong jobs.txt phải ghi được từ máy này.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
APP="$(cd "$HERE/../../../Cozyday" && pwd)"
B="${TRAILER_BIN:-$HERE/../../../build/trailer/bin}"
mkdir -p "$B/shim" "$B/src"
if [[ ! -x "$B/r" ]]; then
  (cd "$B/shim" && swiftc -parse-as-library -O -module-name SwiftUI -emit-module -emit-library -static "$HERE/svg_shim/SwiftUI.swift" -o libSwiftUI.a \
    && swiftc -parse-as-library -O -module-name UIKit -emit-module -emit-library -static "$HERE/svg_shim/UIKit.swift" -o libUIKit.a)
  rm -rf "$B/src" && mkdir -p "$B/src"
  cp -r "$APP/Core" "$B/src/"
  cp "$APP/Features/Corner/Art/"*.swift "$APP/Features/Corner/PetPainter.swift" "$APP/Features/Avatar/AvatarPainter.swift" "$B/src/"
  cp "$HERE/harness_trailer.swift" "$B/src/main.swift"
  swiftc -O -I "$B/shim" -L "$B/shim" -lSwiftUI -lUIKit $(find "$B/src" -name '*.swift') -o "$B/r"
fi
"$B/r" "$1"
