# appearance-notify

Automatically sync developer tools with macOS appearance changes.

## Installation

```bash
brew tap odysseus0/tap
brew install odysseus0/tap/appearance-notify
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

## CLI

Subcommands:
- `daemon`: Start the watcher; runs hooks on start and on macOS appearance changes.
- `run [--dark|--light]`: Run hooks once using system appearance, or force a mode.
- `status`: Print the current system appearance (`dark` or `light`).

Examples:
```bash
# One-shot using current system appearance
appearance-notify run

# Force dark or light without changing macOS appearance
appearance-notify run --dark
appearance-notify run --light

# Print current appearance
appearance-notify status

# Start the long-running watcher (used by Homebrew services)
appearance-notify daemon
```

No arguments prints concise help.

## Behavior

- Daemon runs hooks on startup and on theme changes
- Executes all hooks in parallel
- 30-second timeout (terminates long-running hooks)

## Logging

View logs using macOS unified logging:

```bash
# Stream logs in real-time
log stream --predicate 'subsystem == "com.appearance.notify"'

# Show recent logs
log show --predicate 'subsystem == "com.appearance.notify"' --last 1h

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
./.build/release/appearance-notify --help
```

## Requirements

- macOS 14+

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup and release process.

## License

MIT

## Releasing (local)

Prerequisites: `swift`, `gh` (logged in), `git-cliff`, `svu`, `sd`, `lipo`.

Release with one command:

```bash
just release
```

This will: compute the next version (svu), bump `Version.swift`, regenerate `CHANGELOG.md` (git-cliff), commit, tag and push, build a universal binary, create a GitHub release with the committed notes, and update the Homebrew tap formula (`odysseus0/homebrew-tap`).

## Developer Tasks

### Simple dev workflows
- just run — build and run hooks once with current appearance
- just daemon — build and run watcher in foreground (Ctrl-C to stop)
- just service-point-local — point Homebrew service at your local build and reload
- just service-restore — restore Homebrew service to the original binary

Other helpful tasks:
```bash
just version         # preview next tag and release notes (no changes)
just build           # builds universal binary and packages to dist/
just lint            # run shellcheck on scripts
just fmt             # format scripts with shfmt
just clean           # removes dist/ and .build
just brew-published  # install/upgrade from the published tap
```

Dev tools (Homebrew):
```bash
brew bundle            # installs from Brewfile (recommended)
# or install individually
brew install caarlos0/tap/svu git-cliff sd gh shellcheck shfmt
```

## Maintainers

The release script clones `odysseus0/homebrew-tap` to a temporary directory, updates `Formula/appearance-notify.rb`, pushes to `main`, and cleans up. There are no additional knobs to configure.
