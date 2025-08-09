# appearance-notify – Technical Specification v0.2

## Purpose

A macOS daemon that monitors system appearance changes (Light ↔ Dark), executing user-defined hooks to synchronize developer tools with the system theme.

## Success Criteria

1. **Install**: `brew install appearance-notify && brew services start appearance-notify`
2. **Files**: LaunchAgent plist + hooks directory at `~/.config/appearance-notify/hooks.d/`
3. **Usage**: Drop executables in hooks directory, they run on theme change
4. **Compatibility**: macOS 14+, Apple Silicon + Intel

## Functional Requirements

**FR-1: CLI**
- Subcommands:
  - `daemon`: Long-running watcher; runs hooks on start and changes
  - `run [--dark|--light]`: One-shot execution with optional forced mode
  - `status`: Prints `dark` or `light`
- No-arg prints help and exits 0

**FR-2: Theme Change Detection**
- Monitor `AppleInterfaceThemeChangedNotification` via `NSDistributedNotificationCenter`

**FR-3: Initial Sync**
- Run hooks once at startup

**FR-4: Hook Directory**
- Path: `~/.config/appearance-notify/hooks.d/`
- Create if missing

**FR-5: Hook Execution**
- Run all executables in hooks directory

**FR-6: Hook Environment**
- `DARKMODE`: `0` (light) or `1` (dark)

**FR-7: Timeout**
- 30 seconds timeout for all hooks
- Parallel execution
- Kill still-running hooks after timeout

**FR-8: Error Handling**
- Log failures, continue execution

## Technical Notes

- Swift 6, uses native macOS APIs
- Uses `swift-argument-parser` for CLI subcommands

## Deliverables

1. Swift implementation
2. Homebrew formula with service support
3. README with examples
4. MIT license
