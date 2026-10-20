#!/bin/bash
# Xuất danh mục, pool gacha và các hằng số thưởng từ code Swift (Cozyday/Core) ra catalog JSON.
# Cần chroot Swift của môi trường dev (/opt/swiftimg/root). Dùng: dump_catalog.sh <repo> <file-ra.json>
set -e
SRC=${1:-$(cd "$(dirname "$0")/../../.." && pwd)}
OUT=${2:-catalog_v9.json}
W=/opt/swiftimg/root/work/econdump
rm -rf $W/Sources/EconDump && mkdir -p $W/Sources/EconDump
cp -r $SRC/Cozyday/Core/* $W/Sources/EconDump/
cp "$(dirname "$0")/EconDump.swift" $W/Sources/EconDump/main.swift
chroot /opt/swiftimg/root /bin/bash -c "cd /work/econdump && swift build -c release 2>&1 | grep -E 'error|warning: unre' ; .build/release/EconDump /work/econdump/catalog.json"
cp $W/catalog.json "$OUT"
