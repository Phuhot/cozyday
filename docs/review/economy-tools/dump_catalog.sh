#!/usr/bin/env bash
# Export the current Swift Core catalog; native swiftc or pinned official Swift Docker image.
# Usage: dump_catalog.sh [repository] [output.json]
set -euo pipefail
repo="${1:-$(cd "$(dirname "$0")/../../.." && pwd)}"
out="${2:-$repo/docs/review/economy-tools/catalog_v9.json}"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
cp -R "$repo/Cozyday/Core" "$work/Core"
cp "$(dirname "$0")/EconDump.swift" "$work/main.swift"
if command -v swiftc >/dev/null 2>&1; then
  (cd "$work" && find Core -name '*.swift' -print0 | xargs -0 swiftc -O main.swift -o dump && ./dump catalog.json)
else
  docker run --rm --user "$(id -u):$(id -g)" --mount "type=bind,src=$work,dst=/work" -w /work \
    swift@sha256:d6f8f6112e9a63da0a4a151d6b93acd16699d35c0b82531ac1a245f5af210197 \
    bash -c 'find Core -name "*.swift" -print0 | xargs -0 swiftc -O main.swift -o dump && ./dump catalog.json'
fi
cp "$work/catalog.json" "$out"
