#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)
cd "$ROOT_DIR"
if [[ -f .release-state ]]; then
  echo "Found .release-state; release is already prepared. Remove .release-state to re-run prepare."
  exit 0
fi
git diff-index --quiet HEAD -- || {
  echo "Working tree not clean. Commit or stash changes first." >&2
  exit 1
}
VERSION_RAW=$(svu next)
if [[ "$VERSION_RAW" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  TAG="$VERSION_RAW"
  VERSION_NUM="${VERSION_RAW#v}"
elif [[ "$VERSION_RAW" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  TAG="v$VERSION_RAW"
  VERSION_NUM="$VERSION_RAW"
else
  echo "Computed version invalid: $VERSION_RAW" >&2
  exit 1
fi
ver_file="Sources/appearance-notify/Version.swift"
[[ -f "$ver_file" ]] || {
  echo "Missing $ver_file" >&2
  exit 1
}
sd 'static let version = "[^"]*" // x-release-please-version' "static let version = \"$VERSION_NUM\" // x-release-please-version" "$ver_file"
git-cliff --tag "$TAG" -o CHANGELOG.md

# Stage both files if changed and commit once
git add -A -- "$ver_file" CHANGELOG.md || true
if ! git diff --cached --quiet -- "$ver_file" CHANGELOG.md; then
  git commit -m "chore(release): $TAG"
else
  echo "No changes to commit for $TAG"
fi
cat > .release-state << EOT
TAG=$TAG
VERSION_NUM=$VERSION_NUM
EOT
echo "Prepared $TAG. Review changes, then run: scripts/publish.sh or 'just publish'"
