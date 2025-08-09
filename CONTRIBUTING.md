# Contributing to appearance-notify

Thank you for your interest in contributing!

## Development Setup

1. Clone the repository
2. Ensure you have Swift 6.0+ installed
3. Build: `swift build`
4. Test: `swift test` (when tests are added)

## Commit Convention

This project uses [Conventional Commits](https://www.conventionalcommits.org/) for automatic versioning and changelog generation.

### Commit Message Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- **feat**: New feature (triggers minor version bump)
- **fix**: Bug fix (triggers patch version bump)
- **docs**: Documentation only changes
- **style**: Code style changes (formatting, missing semicolons, etc.)
- **refactor**: Code change that neither fixes a bug nor adds a feature
- **perf**: Performance improvement
- **test**: Adding or updating tests
- **chore**: Changes to build process or auxiliary tools

### Breaking Changes

For breaking changes, add `!` after the type or include `BREAKING CHANGE:` in the footer:

```
feat!: remove support for macOS 13

BREAKING CHANGE: macOS 14 (Sonoma) is now the minimum requirement
```

This triggers a major version bump.

### Examples

```bash
# Feature
git commit -m "feat: add timeout configuration option"

# Bug fix
git commit -m "fix: handle spaces in hook paths correctly"

# Breaking change
git commit -m "feat!: change DARKMODE env var to APPEARANCE_MODE"

# With scope
git commit -m "feat(hooks): add pre-execution validation"
```

## Release Process

Releases are fully automated using [release-please](https://github.com/googleapis/release-please):

1. Push commits to `main` following the convention above
2. release-please creates/updates a PR with version bumps and changelog
3. Review and merge the PR
4. Everything else is automated:
   - Tag creation
   - GitHub release
   - Binary builds (arm64 & x86_64)
   - Homebrew formula update

## Code Style

- Follow Swift API Design Guidelines
- Use SwiftFormat for consistent formatting
- Keep functions small and focused
- Add comments for complex logic

## Testing

- Add tests for new features when possible
- Ensure existing functionality isn't broken
- Test on both Intel and Apple Silicon Macs if possible

## Pull Request Process

1. Fork the repository
2. Create a feature branch from `main`
3. Make your changes following the guidelines above
4. Push to your fork
5. Open a PR with a clear description

## Questions?

Feel free to open an issue for discussion!