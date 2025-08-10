#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)
cd "$ROOT_DIR"
gh auth status > /dev/null || {
  echo "gh is not authenticated" >&2
  exit 1
}
BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [[ "${ALLOW_NON_MAIN:-0}" != 1 && "$BRANCH" != "main" ]]; then
  echo "Publish must run on main (current: $BRANCH). Set ALLOW_NON_MAIN=1 to override." >&2
  exit 1
fi
if [[ -f .release-state ]]; then source .release-state; else
  ver_file="Sources/appearance-notify/Version.swift"
  VERSION_NUM=$(sed -n 's/.*version = "\([^"]*\)".*/\1/p' "$ver_file" | head -n1)
  [[ -n "$VERSION_NUM" ]] || {
    echo "Unable to determine version from $ver_file" >&2
    exit 1
  }
  TAG="v$VERSION_NUM"
fi
DRY_RUN=${DRY_RUN:-0}
echo "Publishing $TAG (dry-run: $DRY_RUN)"
if [[ "$DRY_RUN" != 1 ]]; then
  git tag -a "$TAG" -m "$TAG" || true
  git push || true
  git push origin "$TAG"
else echo "[dry-run] Skipping tag and push"; fi
scripts/build.sh
TMP_EXTRACT=$(mktemp -d)
trap 'rm -rf "$TMP_EXTRACT"' EXIT
tar -xzf dist/appearance-notify-apple-darwin.tar.gz -C "$TMP_EXTRACT"
VERSION_OUT=$("$TMP_EXTRACT/appearance-notify" --version || true)
echo "Binary --version: $VERSION_OUT"
echo "$VERSION_OUT" | grep -q "$VERSION_NUM" || {
  echo "Version mismatch: expected $VERSION_NUM" >&2
  exit 1
}
if [[ "$DRY_RUN" != 1 ]]; then gh release create "$TAG" dist/appearance-notify-apple-darwin.tar.gz -F <(git-cliff --tag "$TAG") -t "$TAG"; else echo "[dry-run] Skipping GitHub release creation"; fi
if [[ "$DRY_RUN" != 1 ]]; then
  sha_uni=$(shasum -a 256 dist/appearance-notify-apple-darwin.tar.gz | awk '{print $1}')
  origin_url=$(git remote get-url origin)
  if [[ "$origin_url" =~ github.com[:/]([^/]+)/([^/.]+)(\.git)?$ ]]; then
    OWNER="${BASH_REMATCH[1]}"; REPO="${BASH_REMATCH[2]}"
  else
    echo "Warning: could not parse origin URL, defaulting OWNER/REPO placeholders" >&2
    OWNER="odysseus0"; REPO="appearance-notify"
  fi
  tar_url="https://github.com/$OWNER/$REPO/releases/download/$TAG/appearance-notify-apple-darwin.tar.gz"

  TAP_REPO=${TAP_REPO:-"$OWNER/homebrew-tap"}
  TAP_BRANCH=${TAP_BRANCH:-"main"}
  FORMULA_NAME=${FORMULA_NAME:-"appearance-notify"}
  TMP_TAP=$(mktemp -d)
  trap 'rm -rf "$TMP_TAP"' RETURN
  echo "Cloning tap repo: $TAP_REPO"
  git clone "https://github.com/$TAP_REPO.git" "$TMP_TAP"
  pushd "$TMP_TAP" >/dev/null
  git fetch origin "$TAP_BRANCH" || true
  git checkout -B "$TAP_BRANCH" "origin/$TAP_BRANCH" 2>/dev/null || git checkout -B "$TAP_BRANCH"
  mkdir -p Formula
  formula_path="Formula/${FORMULA_NAME}.rb"
  cat > "$formula_path" <<EOF
class AppearanceNotify < Formula
  desc "macOS daemon that executes hooks on system appearance changes"
  homepage "https://github.com/$OWNER/$REPO"
  version "$VERSION_NUM"
  license "MIT"

  url "$tar_url"
  sha256 "$sha_uni" # universal

  depends_on macos: :sonoma

  def install
    bin.install "$FORMULA_NAME"

    (prefix/"io.github.$OWNER.$FORMULA_NAME.plist").write <<~EOS
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
          <key>Label</key>
          <string>io.github.$OWNER.$FORMULA_NAME</string>
          <key>ProgramArguments</key>
          <array>
              <string>#{opt_bin}/$FORMULA_NAME</string>
              <string>daemon</string>
          </array>
          <key>RunAtLoad</key>
          <true/>
          <key>KeepAlive</key>
          <true/>
      </dict>
      </plist>
    EOS
  end

  service do
    run [opt_bin/"$FORMULA_NAME", "daemon"]
    keep_alive true
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/$FORMULA_NAME --version")
  end
end
EOF
  git add "$formula_path"
  if git diff --cached --quiet; then
    echo "Tap formula unchanged; skipping push"
  else
    git commit -m "chore(${FORMULA_NAME}): bump to $TAG"
    git push origin "$TAP_BRANCH"
    echo "Updated tap $TAP_REPO:$TAP_BRANCH"
  fi
  popd >/dev/null
else echo "[dry-run] Skipping tap formula update"; fi
rm -f .release-state || true
echo "Published $TAG (dry-run: $DRY_RUN)."
