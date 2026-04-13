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

# 4. Build the zip + generate userscript
make release

# 5. Create GitHub release (attaches zip + userscript)
gh release create v1.1 dist/AutoPiP-1.1.zip autopip.user.js --title "v1.1" --notes "What changed"
```

Users with the app installed will see "Update available" next time they open it.
Userscript managers will auto-update from the raw GitHub URL.

## Quick reference

| Command | What it does |
|---|---|
| `make userscript` | Generate userscript from extension-src/content.js |
| `make build` | Build native extension (universal binary) |
| `make install` | Build + install to ~/Applications |
| `make install TEAM_ID=XXX` | Build + install with Developer Team signing |
| `make zip` | Build + create dist zip |
| `make release` | Generate userscript + build + zip + show gh commands |
| `make clean` | Delete build artifacts + generated userscript |
| `make uninstall` | Remove from ~/Applications |
