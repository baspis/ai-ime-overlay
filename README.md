# AI IME Overlay

Menu bar utility for macOS that converts romaji to Japanese using the OpenAI API, then inserts the result into the previously focused text field.

## Download (GitHub Releases)

Pre-built macOS builds are published on [GitHub Releases](https://github.com/baspis/ai-ime-overlay/releases).

1. Open the latest release.
2. Download `AIIMEOverlay-<version>-macOS.zip`.
3. Unzip and move `AIIMEOverlay.app` to **Applications**.
4. First launch: if macOS blocks the app (unsigned build), open **System Settings → Privacy & Security** and click **Open Anyway**, or run:

   ```bash
   xattr -cr /Applications/AIIMEOverlay.app
   ```

5. Grant **Accessibility** and **Input Monitoring** when prompted.

Before tagging, confirm the release build on your Mac (same command as CI):

```bash
chmod +x scripts/build-release.sh
./scripts/build-release.sh
```

Then push a version tag (CI builds and uploads the zip automatically):

```bash
git tag v1.0.0
git push origin v1.0.0
```

You can also run the **Release** workflow manually from the Actions tab; the zip appears under **Artifacts** for that run.

## Requirements

- macOS 14 (Sonoma) or later
- Apple Silicon or Intel Mac
- Xcode 16+
- OpenAI API key

## Build from source

1. Clone this repo on your Mac:

   ```bash
   git clone https://github.com/baspis/ai-ime-overlay.git
   cd ai-ime-overlay
   ```
2. Run `./scripts/build-release.sh` to verify a Release build, or open `AIIMEOverlay.xcodeproj` in Xcode and build (`⌘R`).
3. For Xcode GUI builds, set your **Development Team** under Signing & Capabilities.

The app runs as a menu bar agent (no Dock icon).

## First-time setup

1. Click the **AI IME** menu bar icon → **Settings…** (opens the settings window).
2. Enter your OpenAI API key (stored in Keychain) and model name (default: `gpt-4.1-nano`).
3. Grant **Accessibility** and **Input Monitoring** when prompted (or use the buttons in Settings).

## Usage

| Action | Result |
|--------|--------|
| Double-tap **Control** | Open conversion panel (saves focused text field) |
| Type romaji | Input in the panel |
| **Control+Enter** | Convert via OpenAI |
| **Enter** | Insert converted text into the original field |
| **Esc** | Close without inserting |

You can also open the panel from the menu bar → **Open Converter**.

## Architecture

- `HotkeyMonitor` — `CGEventTap` for Control double-tap
- `ConversionPanelController` — floating `NSPanel` + key bindings
- `FocusStore` / `TextInjector` — Accessibility insert with pasteboard fallback
- `OpenAIClient` / `KeychainStore` — API calls and secret storage

App Sandbox is **disabled** so Accessibility and event taps work. For distribution outside your Mac, sign with a Developer ID certificate and notarize.

## Manual QA checklist (on Mac)

Run through these after building:

- [ ] Double-tap Control opens the panel when Safari text field is focused
- [ ] Control+Enter converts sample romaji (`konnichiha`) to Japanese
- [ ] Enter inserts into Safari, Notes, VS Code, Slack, Terminal
- [ ] Esc closes without inserting
- [ ] Missing API key shows error and opens Settings
- [ ] Accessibility / Input Monitoring toggles reflect System Settings

## Privacy

Romaji and converted text are sent to OpenAI when you press Control+Enter. The API key never leaves your Mac except in HTTPS requests to OpenAI.
