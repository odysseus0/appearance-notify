#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)
cd "$ROOT_DIR"

# Prevent accidental re-run
if [[ -f .release-state ]]; then
  echo "Found .release-state; release is already prepared. Remove .release-state to re-run prepare."
  exit 0
fi

# Ensure clean tree
git diff-index --quiet HEAD -- || {
  echo "Working tree not clean. Commit or stash changes first." 1>&2
  exit 1
}

# Ensure on main and up-to-date
BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [[ "$BRANCH" != "main" ]]; then
  echo "Prepare must run on main (current: $BRANCH)" 1>&2
  exit 1
fi
git fetch origin main -q || true
LOCAL=$(git rev-parse @)
REMOTE=$(git rev-parse @{u} 2>/dev/null || echo "")
BASE=$(git merge-base @ @{u} 2>/dev/null || echo "")
if [[ -n "$REMOTE" && "$LOCAL" != "$REMOTE" && "$LOCAL" != "$BASE" ]]; then
  echo "Branch is not up-to-date with origin/main. Please pull first." 1>&2
  exit 1
fi

# Compute next version
VERSION_RAW=$(svu next)
if [[ "$VERSION_RAW" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  TAG="$VERSION_RAW"
  VERSION_NUM="${VERSION_RAW#v}"
elif [[ "$VERSION_RAW" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  TAG="v$VERSION_RAW"
  VERSION_NUM="$VERSION_RAW"
else
  echo "Computed version invalid: $VERSION_RAW" 1>&2
  exit 1
fi

# Update version file
ver_file="Sources/appearance-notify/Version.swift"
[[ -f "$ver_file" ]] || { echo "Missing $ver_file" 1>&2; exit 1; }
sd 'static let version = "[^"]*" // x-release-please-version' "static let version = \"$VERSION_NUM\" // x-release-please-version" "$ver_file"

# Regenerate changelog for this tag
git-cliff --tag "$TAG" -o CHANGELOG.md

# Commit version + changelog
git add -A -- "$ver_file" CHANGELOG.md || true
if ! git diff --cached --quiet -- "$ver_file" CHANGELOG.md; then
  git commit -m "chore(release): $TAG"
else
  echo "No changes to commit for $TAG"
fi

# Persist state for publish
COMMIT_SHA=$(git rev-parse HEAD)
cat > .release-state << EOT
TAG=$TAG
VERSION_NUM=$VERSION_NUM
COMMIT_SHA=$COMMIT_SHA
EOT

echo "Prepared $TAG at $COMMIT_SHA. Review changes, then run: scripts/publish.sh or 'just publish'"
