set shell := ["bash", "-uc"]

default:
  @just --list

# Verify required tools for release tasks (fast, no installs)
ensure:
  for t in swift gh svu git-cliff sd lipo tar; do \
    command -v "$t" >/dev/null || { echo "Missing: $t. Run 'just bootstrap'"; exit 1; }; \
  done

# Bootstrap dev tools via Homebrew Brewfile
bootstrap:
  brew bundle --no-upgrade

# Preview next version and release notes (no changes)
version: ensure
  v=$(svu next); echo "Next tag: ${v}"; echo; echo "Notes preview:"; echo; git-cliff --tag "${v}" | sed -n '1,40p'

# Build universal binary and package tarball to dist/
build: ensure
  scripts/build.sh

# Prepare only: compute version, bump Version.swift, regenerate CHANGELOG (no tag)
prepare: ensure
  scripts/prepare.sh

# Publish only: tag, build, verify, create GitHub release, update formula
publish: ensure
  scripts/publish.sh

# Full release: depends on prepare then publish (DRY)
release: prepare publish
  @:

# Lint shell scripts with shellcheck
lint:
  command -v shellcheck >/dev/null || { echo 'Missing: shellcheck. Run just bootstrap'; exit 1; }
  shellcheck -S style scripts/*.sh || true

# Format shell scripts with shfmt
fmt:
  command -v shfmt >/dev/null || { echo 'Missing: shfmt. Run just bootstrap'; exit 1; }
  shfmt -w -i 2 -ci -sr scripts || true

# Clean build artifacts
clean:
  rm -rf dist .build
