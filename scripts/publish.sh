#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)
cd "$ROOT_DIR"
gh auth status >/dev/null || { echo "gh is not authenticated" >&2; exit 1; }
BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [[ "${ALLOW_NON_MAIN:-0}" != 1 && "$BRANCH" != "main" ]]; then echo "Publish must run on main (current: $BRANCH). Set ALLOW_NON_MAIN=1 to override." >&2; exit 1; fi
if [[ -f .release-state ]]; then source .release-state; else ver_file="Sources/appearance-notify/Version.swift"; VERSION_NUM=$(sed -n 's/.*version = "\([^"]*\)".*/\1/p' "$ver_file" | head -n1); [[ -n "$VERSION_NUM" ]] || { echo "Unable to determine version from $ver_file" >&2; exit 1; }; TAG="v$VERSION_NUM"; fi
DRY_RUN=${DRY_RUN:-0}
echo "Publishing $TAG (dry-run: $DRY_RUN)"
if [[ "$DRY_RUN" != 1 ]]; then git tag -a "$TAG" -m "$TAG" || true; git push || true; git push origin "$TAG"; else echo "[dry-run] Skipping tag and push"; fi
scripts/build.sh
TMP_EXTRACT=$(mktemp -d); trap 'rm -rf "$TMP_EXTRACT"' EXIT; tar -xzf dist/appearance-notify-apple-darwin.tar.gz -C "$TMP_EXTRACT"; VERSION_OUT=$("$TMP_EXTRACT/appearance-notify" --version || true); echo "Binary --version: $VERSION_OUT"; echo "$VERSION_OUT" | grep -q "$VERSION_NUM" || { echo "Version mismatch: expected $VERSION_NUM" >&2; exit 1; }
if [[ "$DRY_RUN" != 1 ]]; then gh release create "$TAG" dist/appearance-notify-apple-darwin.tar.gz -F <(git-cliff --tag "$TAG") -t "$TAG"; else echo "[dry-run] Skipping GitHub release creation"; fi
if [[ "$DRY_RUN" != 1 ]]; then formula="Formula/appearance-notify.rb"; [[ -f "$formula" ]] || { echo "Missing $formula" >&2; exit 1; }; sha_uni=$(shasum -a 256 dist/appearance-notify-apple-darwin.tar.gz | awk '{print $1}'); sd '^\s*version ".*"' "  version \"$VERSION_NUM\"" "$formula"; sd '(download/)v[^/]+(/appearance-notify-apple-darwin\.tar\.gz)' "\${1}$TAG\${2}" "$formula"; sd '(sha256 ")[0-9a-f]+(" # universal)' "\${1}$sha_uni\${2}" "$formula"; git add "$formula"; git commit -m "chore: update formula for $TAG"; git push; else echo "[dry-run] Skipping formula update and push"; fi
rm -f .release-state || true
echo "Published $TAG (dry-run: $DRY_RUN)."
