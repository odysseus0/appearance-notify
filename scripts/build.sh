#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)
cd "$ROOT_DIR"
mkdir -p dist
rm -f dist/appearance-notify-apple-darwin.tar.gz
echo "==> Building arm64"
swift build -c release --arch arm64
echo "==> Building x86_64"
swift build -c release --arch x86_64
ARM_BIN=".build/arm64-apple-macosx/release/appearance-notify"
X86_BIN=".build/x86_64-apple-macosx/release/appearance-notify"
[[ -f "$ARM_BIN" && -f "$X86_BIN" ]] || {
  echo "Built binaries not found" >&2
  exit 1
}
TMPDIR_UNI=$(mktemp -d)
trap 'rm -rf "$TMPDIR_UNI"' EXIT
lipo -create -output "$TMPDIR_UNI/appearance-notify" "$ARM_BIN" "$X86_BIN"
chmod +x "$TMPDIR_UNI/appearance-notify"
tar -czf dist/appearance-notify-apple-darwin.tar.gz -C "$TMPDIR_UNI" appearance-notify
echo "Artifact written to dist/appearance-notify-apple-darwin.tar.gz"
