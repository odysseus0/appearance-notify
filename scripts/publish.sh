#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)
cd "$ROOT_DIR"

# Auth check
gh auth status > /dev/null || { echo "gh is not authenticated" 1>&2; exit 1; }

# Read prepared state
[[ -f .release-state ]] || { echo ".release-state not found. Run prepare first." 1>&2; exit 1; }
source .release-state

# Preconditions: clean tree and correct commit
git diff-index --quiet HEAD -- || { echo "Working tree not clean." 1>&2; exit 1; }
HEAD_SHA=$(git rev-parse HEAD)
if [[ -n "${COMMIT_SHA:-}" && "$HEAD_SHA" != "$COMMIT_SHA" ]]; then
  echo "HEAD ($HEAD_SHA) does not match prepared commit ($COMMIT_SHA)." 1>&2
  exit 1
fi

BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [[ "${ALLOW_NON_MAIN:-0}" != 1 && "$BRANCH" != "main" ]]; then
  echo "Publish must run on main (current: $BRANCH). Set ALLOW_NON_MAIN=1 to override." 1>&2
  exit 1
fi

DRY_RUN=${DRY_RUN:-0}
echo "Publishing $TAG (dry-run: $DRY_RUN)"

# Extract release notes for TAG from CHANGELOG.md
NOTES_FILE=$(mktemp)
trap 'rm -f "$NOTES_FILE"' EXIT
awk -v tag="$TAG" '
  BEGIN{found=0}
  /^## /{
    if (found==1){exit}
    if ($0 ~ tag){found=1; print; next}
  }
  { if (found==1) print }
' CHANGELOG.md > "$NOTES_FILE"
if ! grep -q "^## \[$(echo "$VERSION_NUM")\]" "$NOTES_FILE" 2>/dev/null; then
  echo "Warning: could not find changelog section for $TAG; using full changelog." 1>&2
  cp CHANGELOG.md "$NOTES_FILE"
fi

# Tag (only if missing) and push
if [[ "$DRY_RUN" != 1 ]]; then
  if git rev-parse -q --verify "refs/tags/$TAG" >/dev/null; then
    echo "Tag $TAG already exists; skipping tag creation"
  else
    git tag -a "$TAG" -m "$TAG"
  fi
  git push || true
  git push origin "$TAG" || true
else
  echo "[dry-run] Skipping tag and push"
fi

# Build universal artifact
scripts/build.sh

# Verify version from artifact
TMP_EXTRACT=$(mktemp -d)
trap 'rm -rf "$TMP_EXTRACT" "$NOTES_FILE"' EXIT

tar -xzf dist/appearance-notify-apple-darwin.tar.gz -C "$TMP_EXTRACT"
VERSION_OUT=$("$TMP_EXTRACT/appearance-notify" --version || true)
echo "Binary --version: $VERSION_OUT"
(echo "$VERSION_OUT" | grep -q "$VERSION_NUM") || { echo "Version mismatch: expected $VERSION_NUM" 1>&2; exit 1; }

# GitHub release (idempotent)
if [[ "$DRY_RUN" != 1 ]]; then
  if gh release view "$TAG" >/dev/null 2>&1; then
    echo "GitHub release $TAG already exists; skipping creation"
  else
    gh release create "$TAG" dist/appearance-notify-apple-darwin.tar.gz -F "$NOTES_FILE" -t "$TAG"
  fi
else
  echo "[dry-run] Skipping GitHub release creation"
fi

# Update Homebrew tap formula (temp clone)
if [[ "$DRY_RUN" != 1 ]]; then
  sha_uni=$(shasum -a 256 dist/appearance-notify-apple-darwin.tar.gz | awk '{print $1}')
  origin_url=$(git remote get-url origin)
  if [[ "$origin_url" =~ github.com[:/]([^/]+)/([^/.]+)(\.git)?$ ]]; then
    OWNER="${BASH_REMATCH[1]}"; REPO="${BASH_REMATCH[2]}"
  else
    echo "Warning: could not parse origin URL, defaulting OWNER/REPO placeholders" 1>&2
    OWNER="odysseus0"; REPO="appearance-notify"
  fi
  tar_url="https://github.com/$OWNER/$REPO/releases/download/$TAG/appearance-notify-apple-darwin.tar.gz"
  FORMULA_NAME=${FORMULA_NAME:-"appearance-notify"}

  TMP_TAP=$(mktemp -d)
  echo "Cloning tap repo: $OWNER/homebrew-tap"
  git clone "https://github.com/$OWNER/homebrew-tap.git" "$TMP_TAP"
  pushd "$TMP_TAP" > /dev/null
  git fetch origin main || true
  git checkout -B main "origin/main" 2>/dev/null || git checkout -B main
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
    git push origin main
    echo "Updated tap $OWNER/homebrew-tap:main"
  fi
  popd > /dev/null
else
  echo "[dry-run] Skipping tap formula update"
fi

rm -f .release-state || true
echo "Published $TAG (dry-run: $DRY_RUN)."
