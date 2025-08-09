#!/usr/bin/env bash
set -euo pipefail

# Usage: scripts/prepare-release.sh 0.2.0
# Requires: git, sed, shasum, Swift toolchain

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT_DIR"

VERSION=${1:-${APP_VERSION:-}} || true
if [[ -z "${VERSION}" ]]; then
  echo "Usage: $0 <version>  (e.g., 0.2.0)" >&2
  exit 1
fi

echo "Preparing release ${VERSION}"

# Ensure clean working tree
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Error: working tree has changes. Commit or stash before releasing." >&2
  exit 1
fi

# Tag if missing
if ! git rev-parse "v${VERSION}" >/dev/null 2>&1; then
  git tag "v${VERSION}" -m "appearance-notify ${VERSION}"
fi

# Build artifacts with stamped version
export APP_VERSION="$VERSION"
"${ROOT_DIR}/build-release.sh"

# Compute SHA256 checksums
ARM_TGZ="appearance-notify-aarch64-apple-darwin.tar.gz"
X86_TGZ="appearance-notify-x86_64-apple-darwin.tar.gz"

if [[ ! -f "$ARM_TGZ" || ! -f "$X86_TGZ" ]]; then
  echo "Error: release tarballs not found."
  exit 1
fi

ARM_SHA=$(shasum -a 256 "$ARM_TGZ" | awk '{print $1}')
X86_SHA=$(shasum -a 256 "$X86_TGZ" | awk '{print $1}')

echo "ARM64 sha256:  $ARM_SHA"
echo "x86_64 sha256: $X86_SHA"

# Update Homebrew formula with new URLs and checksums
FORMULA="${ROOT_DIR}/appearance-notify.rb"

sed -i '' -E "s|(releases/download/)v[0-9.]+/appearance-notify-aarch64-apple-darwin.tar.gz|\1v${VERSION}/appearance-notify-aarch64-apple-darwin.tar.gz|" "$FORMULA"
sed -i '' -E "s|sha256 \"[0-9a-f]{64}\"|sha256 \"${ARM_SHA}\"|" "$FORMULA"

sed -i '' -E "s|(releases/download/)v[0-9.]+/appearance-notify-x86_64-apple-darwin.tar.gz|\1v${VERSION}/appearance-notify-x86_64-apple-darwin.tar.gz|" "$FORMULA"
awk '1; /x86_64-apple-darwin.tar.gz"$/ {getline; sub(/sha256 \"[0-9a-f]{64}\"/, "sha256 \"'"${X86_SHA}"'\""); print; next}' "$FORMULA" > "$FORMULA.tmp" && mv "$FORMULA.tmp" "$FORMULA"

sed -i '' -E "s/^\s*version \"[0-9.]+\"/  version \"${VERSION}\"/" "$FORMULA"

echo "\nUpdated formula: $FORMULA"
grep -nE "version \"|aarch64.*url|aarch64.*sha256|x86_64.*url|x86_64.*sha256" "$FORMULA" || true

echo "\nNext steps:"
echo "1) Push tag:    git push origin v${VERSION}"
echo "2) Create GitHub release v${VERSION} and upload the two tarballs"
echo "3) Commit formula change and push to your tap"
echo "   git add appearance-notify.rb && git commit -m 'appearance-notify ${VERSION}' && git push"

