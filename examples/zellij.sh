#!/bin/bash
# Toggle Zellij theme based on system appearance
# Zellij automatically hot-reloads config changes

ZELLIJ_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/zellij/config.kdl"

# Ensure config exists
if [ ! -f "$ZELLIJ_CONFIG" ]; then
    exit 0
fi

if [ "$DARKMODE" = "1" ]; then
    # Switch to dark theme (Catppuccin Frappé)
    sed -i '' 's/theme ".*"/theme "catppuccin-frappe"/' "$ZELLIJ_CONFIG"
else
    # Switch to light theme (Catppuccin Latte)
    sed -i '' 's/theme ".*"/theme "catppuccin-latte"/' "$ZELLIJ_CONFIG"
fi