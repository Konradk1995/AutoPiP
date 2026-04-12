# How to Release

## Version bump

Edit the version in Xcode project (or directly in `project.pbxproj`):
- `MARKETING_VERSION` = the public version (e.g. `1.1`)
- `CURRENT_PROJECT_VERSION` = build number (increment each build)

Both the app target and extension target should match.

## Build + install locally

```bash
make install
```

## Create a release

```bash
# 1. Commit your changes
git add -A
git commit -m "bump to v1.1"

# 2. Tag
git tag v1.1

# 3. Push
git push origin main --tags

# 4. Build the zip
make release

# 5. Create GitHub release (attaches the zip)
gh release create v1.1 dist/AutoPiP-1.1.zip --title "v1.1" --notes "What changed"
```

Users with the app installed will see "Update available" next time they open it.

## Quick reference

| Command | What it does |
|---|---|
| `make build` | Build only |
| `make install` | Build + install to ~/Applications |
| `make zip` | Build + create dist zip |
| `make release` | Build + zip + show gh commands |
| `make clean` | Delete build artifacts |
| `make uninstall` | Remove from ~/Applications |
