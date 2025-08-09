#!/bin/bash

set -euo pipefail

echo "Building release binaries..."

# Determine version from env or latest git tag
VERSION=${APP_VERSION:-$(git describe --tags --abbrev=0 2>/dev/null || echo 0.0.0)}
echo "Version: $VERSION"

# Update BuildInfo.version for this build
echo "Stamping version into Sources/appearance-notify/Version.swift"
sed -i '' -E "s/(static let version = \")([^\"]+)(\")/\\1$VERSION\\3/" Sources/appearance-notify/Version.swift

# Build for Apple Silicon
echo "Building for Apple Silicon (arm64)..."
swift build --configuration release --arch arm64
mkdir -p release/arm64
cp .build/arm64-apple-macosx/release/appearance-notify release/arm64/
tar -czf appearance-notify-aarch64-apple-darwin.tar.gz -C release/arm64 appearance-notify

# Build for Intel
echo "Building for Intel (x86_64)..."
swift build --configuration release --arch x86_64
mkdir -p release/x64
cp .build/x86_64-apple-macosx/release/appearance-notify release/x64/
tar -czf appearance-notify-x86_64-apple-darwin.tar.gz -C release/x64 appearance-notify

# Generate checksums
echo ""
echo "Checksums:"
echo "ARM64:  $(shasum -a 256 appearance-notify-aarch64-apple-darwin.tar.gz)"
echo "x86_64: $(shasum -a 256 appearance-notify-x86_64-apple-darwin.tar.gz)"

# Cleanup
rm -rf release

echo ""
echo "Release binaries created:"
echo "  - appearance-notify-aarch64-apple-darwin.tar.gz"
echo "  - appearance-notify-x86_64-apple-darwin.tar.gz"
echo ""
echo "Upload these to GitHub releases and update the formula with the checksums."

# Restore dev version in working copy (do not leave modified file around)
git checkout -- Sources/appearance-notify/Version.swift >/dev/null 2>&1 || true
