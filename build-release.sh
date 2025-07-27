#!/bin/bash

echo "Building release binaries..."

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