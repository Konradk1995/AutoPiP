# Auto PiP

Safari extension that automatically enters Picture-in-Picture when you switch tabs or leave Safari.

Works on YouTube, Netflix, Crunchyroll, Twitch, Disney+, Prime Video, s.to — anything with HTML5 video.

No accounts. No tracking. No data leaves your Mac.

---

## Install

### Homebrew (recommended)

```
brew install --cask konradklonowski/tap/autopip
```

### One-liner

```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/konradklonowski/AutoPiP/main/install.sh)"
```

### Manual

1. Download `AutoPiP.zip` from the [latest release](https://github.com/konradklonowski/AutoPiP/releases/latest)
2. Unzip, move `AutoPiP.app` to Applications
3. Open it once

Then enable the extension: **Safari > Settings > Extensions > Auto PiP**

---

## Update

```
brew upgrade autopip
```

Or re-run the install command. Or open the app — it tells you when a new version is out.

---

## How it works

Play a video. Switch tabs. The video keeps playing in a floating PiP window.

Under the hood:

- Sets `autoPictureInPicture` on the best playing video element
- Intercepts pause calls from streaming sites during tab switch (instance-level, no global prototype patching)
- Falls back to `webkitSetPresentationMode` and `requestPictureInPicture`
- Picks the best candidate by size, play state, and audio

82 lines of JavaScript. No dependencies. No build step for the extension itself.

---

## Build from source

Requires Xcode.

```
git clone https://github.com/konradklonowski/AutoPiP.git
cd AutoPiP
make install
```

| Command | What it does |
|---|---|
| `make install` | Build + install to ~/Applications |
| `make release` | Build + zip for distribution |
| `make uninstall` | Remove from ~/Applications |
| `make clean` | Delete build artifacts |

---

## Uninstall

```
brew uninstall autopip
```

Or just delete `AutoPiP.app` from Applications.

---

MIT License
