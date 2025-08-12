#!/usr/bin/env bash
set -euo pipefail
PLIST="$HOME/Library/LaunchAgents/homebrew.mxcl.appearance-notify.plist"
BACKUP="$PLIST.bak"

[[ -f "$BACKUP" ]] || { echo "Backup not found: $BACKUP" 1>&2; exit 1; }
cp "$BACKUP" "$PLIST"

launchctl unload "$PLIST" || true
launchctl load "$PLIST"
echo "Service restored to original Homebrew binary."
