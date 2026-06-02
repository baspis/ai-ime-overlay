# Manual QA — AI IME Overlay

Run on a physical Mac after building from Xcode.

## Permissions

1. Launch the app fresh (delete from Login Items if re-testing).
2. Open **Settings** from the menu bar.
3. Click **Request Permissions** and approve both prompts if shown.
4. If prompts do not appear, use **Open Settings** for Accessibility and Input Monitoring and enable **AIIMEOverlay**.
5. Quit and relaunch the app; both permission indicators in Settings should be green.

## Hotkey

1. Focus a text field in **Safari** (e.g. Google search box).
2. Double-tap **Control** within ~0.5s — the conversion panel should appear.
3. Press **Esc** — panel closes, nothing inserted.
4. Single Control presses in other apps should still work normally (no stuck Control).

## Conversion

1. Open the panel again.
2. Type `konnichiha` in the romaji field.
3. Press **Control+Enter** — spinner, then Japanese preview (requires valid API key).
4. Press **Enter** — panel closes, Japanese appears in Safari field.

## Insert targets

Repeat open → convert → Enter for:

- Notes
- VS Code or Cursor editor
- Slack message box
- Terminal (shell prompt)

If insert fails in an Electron app, confirm clipboard fallback notification and **⌘V** works.

## Error paths

- Remove API key in Settings → Control+Enter shows error and offers Settings.
- Airplane mode → Control+Enter shows network error.
- Empty romaji → Control+Enter shows validation error.

## Regression

- Menu bar **Open Converter** works when hotkey is unavailable.
- **Quit** stops the app; no orphan event tap (Activity Monitor: no hung CPU).
