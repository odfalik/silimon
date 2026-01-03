# Release Workflow

This project uses fully automated releases via release-please and GitHub Actions.

## How Releases Work

### Automatic Version Management

1. **Version source of truth**: `.release-please-manifest.json`
2. **Auto-updated files** on release:
   - `Sources/silimon/main.swift` - via `x-release-please-version` annotation
   - `CHANGELOG.md` - generated from conventional commits

### Version Annotation Format

The version in `main.swift` uses the generic updater annotation:
```swift
let version = "X.Y.Z" // x-release-please-version
```

Requirements for the annotation to work:
- Version must be full semver format (X.Y.Z with all 3 components)
- The `// x-release-please-version` comment must be on the same line
- The version in the file must match the manifest before release-please runs

### Release Flow

```
feat:/fix: commit → merge to main
       ↓
release-please creates Release PR (updates version, changelog)
       ↓
merge Release PR
       ↓
GitHub release created automatically
       ↓
CI builds arm64 binary, uploads to release
       ↓
CI updates homebrew-silimon tap with new formula
```

### Conventional Commits

Use these prefixes to trigger version bumps:
- `feat:` → minor version bump (0.6.0 → 0.7.0)
- `fix:` → patch version bump (0.6.0 → 0.6.1)
- `feat!:` or `BREAKING CHANGE:` → major version bump

Other prefixes (`chore:`, `docs:`, `refactor:`) don't trigger releases.

## Key Files

| File | Purpose |
|------|---------|
| `.github/workflows/release.yml` | Release automation workflow |
| `release-please-config.json` | Release-please configuration |
| `.release-please-manifest.json` | Current version tracking |
| `Sources/silimon/main.swift:4` | Version with `x-release-please-version` annotation |

## Homebrew Tap

- **Repo**: `odfalik/homebrew-silimon`
- **Auto-updated**: Yes, via `HOMEBREW_TAP_TOKEN` secret
- **Formula**: Uses pre-built binary from release assets

## DO NOT

- Manually edit version numbers (let release-please handle it)
- Create releases manually (merge the release PR instead)
- Update the homebrew tap manually (CI does this)

## Troubleshooting

### Release PR not created?
- Check that commits use conventional commit format (`feat:`, `fix:`)
- Check `.github/workflows/release.yml` is valid YAML

### Homebrew tap not updated?
- Verify `HOMEBREW_TAP_TOKEN` secret is set and valid
- Check the `update-homebrew` job logs in GitHub Actions

### Binary not uploaded?
- Check `build-and-upload` job ran on `macos-latest`
- Verify the build succeeded before upload step
