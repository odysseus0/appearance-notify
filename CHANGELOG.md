# Changelog

## [0.3.0](https://github.com/odysseus0/appearance-notify/compare/v0.2.0...v0.3.0) (2025-08-09)


### ⚠ BREAKING CHANGES

* Homebrew tap moved from odysseus0/homebrew-tap to odysseus0/appearance-notify

### Features

* implement full release automation with release-please ([990fc13](https://github.com/odysseus0/appearance-notify/commit/990fc1358e9d2f1a9aa10ebf81923187f5489e06))

## [0.2.0] - 2025-08-08

### Features
- Add CLI subcommands (daemon, run, status)
- Add version support with --version flag
- Modern Swift 6 architecture with async/await

### Changed
- Complete code restructure with separation of concerns
- Restructure codebase into AppearanceService, Commands, and Main modules
- Improve API with idiomatic Swift naming conventions

### Security
- Environment variable whitelisting for hook execution
- File permission validation before execution
- Add timeout for long-running hooks (30 seconds)

## [0.1.0] - 2025-08-01

### Features
- Initial release
- Monitor macOS appearance changes
- Execute hooks on light/dark mode switch
- Homebrew formula support
