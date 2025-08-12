## [0.2.1] - 2025-08-12

### 🚀 Features

- Add CLI subcommands and modernize architecture

### 🐛 Bug Fixes

- *(hooks)* Set baseline PATH for hook processes under launchd (include ~/.local/bin and Homebrew)

### 💼 Other

- Move to separate tap repo; remove in-repo formula; publish updates tap (TAP_REPO=owner/homebrew-tap)

### 🚜 Refactor

- Bring code to current state (Swift 6/CLI improvements)

### 📚 Documentation

- Add local releasing flow and developer tasks

### ⚙️ Miscellaneous Tasks

- Add Brewfile + Justfile for local release flow
- *(scripts)* Add build/prepare/publish; universal packaging
- *(homebrew)* Simplify to universal tarball; remove arch conditionals
- Ignore .build/ and dist/
- *(release)* Bump version and changelog
- *(release)* V0.2.0
- *(release)* Guard prepare and single-commit prepare; idempotent release
- *(homebrew)* V0.2.0
- *(release)* Simplify publish script; add service switching helpers and Justfile targets
## [0.1.0] - 2025-07-27
