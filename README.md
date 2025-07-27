# appearance-notify

Automatically sync developer tools with macOS appearance changes.

## Installation

```bash
brew tap odysseus0/tap
brew install appearance-notify
brew services start appearance-notify
```

To uninstall:
```bash
brew services stop appearance-notify
brew uninstall appearance-notify
```

## Usage

Drop executable scripts in `~/.config/appearance-notify/hooks.d/`

Scripts receive:
- `DARKMODE=1` for dark mode
- `DARKMODE=0` for light mode

## Examples

See the `examples/` directory for ready-to-use hooks:
- `claude-code.sh` - Syncs Claude Code theme
- `zellij.sh` - Syncs Zellij terminal multiplexer theme

To use them:
```bash
cp examples/claude-code.sh ~/.config/appearance-notify/hooks.d/
cp examples/zellij.sh ~/.config/appearance-notify/hooks.d/
```

### Writing Custom Hooks

Hooks are simple scripts that check `$DARKMODE`:

```bash
#!/bin/bash
if [ "$DARKMODE" = "1" ]; then
    # Dark mode actions
    echo "Switched to dark mode"
else
    # Light mode actions
    echo "Switched to light mode"
fi
```

## Behavior

- Runs hooks on startup and theme changes
- Executes all hooks in parallel
- 30-second timeout (terminates long-running hooks)

## Logging

View logs using macOS unified logging:

```bash
# Stream logs in real-time
log stream --predicate 'subsystem == "io.github.odysseus0.appearance-notify"'

# Show recent logs
log show --predicate 'subsystem == "io.github.odysseus0.appearance-notify"' --last 1h

# Filter in Console.app
# Open Console.app and search for "appearance-notify"
```

## Troubleshooting

### Hooks not executing
- Ensure hooks are executable: `chmod +x ~/.config/appearance-notify/hooks.d/*`
- Check logs for errors (see Logging section above)
- Verify service is running: `brew services list | grep appearance-notify`

### Theme not changing
- Test your hook manually: `DARKMODE=1 ~/.config/appearance-notify/hooks.d/your-hook.sh`
- Some apps may need restart to pick up theme changes

## Building from Source

```bash
git clone https://github.com/odysseus0/appearance-notify.git
cd appearance-notify
swift build --configuration release
./.build/release/appearance-notify
```

## Requirements

- macOS 14+

## License

MIT