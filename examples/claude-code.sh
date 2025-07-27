#!/bin/bash
# Toggle Claude Code theme based on system appearance

if [ "$DARKMODE" = "1" ]; then
    claude config set --global theme dark
else
    claude config set --global theme light
fi
