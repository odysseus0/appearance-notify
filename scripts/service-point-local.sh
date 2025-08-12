#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)
cd "$ROOT_DIR"

# Build local release binary if missing
if [[ ! -x ./.build/release/appearance-notify ]]; then
  echo "Building local release binary..."
  swift build -c release
fi

ABS_BIN="$ROOT_DIR/.build/release/appearance-notify"
PLIST="$HOME/Library/LaunchAgents/homebrew.mxcl.appearance-notify.plist"
BACKUP="$PLIST.bak"

[[ -f "$PLIST" ]] || { echo "LaunchAgent plist not found: $PLIST. Is the service installed?" >&2; exit 1; }

# Backup once
if [[ ! -f "$BACKUP" ]]; then
  cp "$PLIST" "$BACKUP"
  echo "Backed up original plist to $BACKUP"
fi

# Update ProgramArguments[0] to point to local binary
/usr/libexec/PlistBuddy -c "Set :ProgramArguments:0 $ABS_BIN" "$PLIST" 2>/dev/null || \
/usr/libexec/PlistBuddy -c "Add :ProgramArguments array" "$PLIST" && \
/usr/libexec/PlistBuddy -c "Add :ProgramArguments:0 string $ABS_BIN" "$PLIST"

# Ensure daemon argument is present at index 1
if /usr/libexec/PlistBuddy -c "Print :ProgramArguments:1" "$PLIST" >/dev/null 2>&1; then
  /usr/libexec/PlistBuddy -c "Set :ProgramArguments:1 daemon" "$PLIST"
else
  /usr/libexec/PlistBuddy -c "Add :ProgramArguments:1 string daemon" "$PLIST"
fi

# Reload service
launchctl unload "$PLIST" || true
launchctl load "$PLIST"
echo "Service now points to local binary: $ABS_BIN"

