# ClaudeBar

<p align="center">
  <img src="assets/icons/claudebar-macOS-Dark-1024x1024@1x.png" alt="ClaudeBar Icon" width="128" height="128">
</p>

<p align="center">
  <strong>A native macOS menu bar app for monitoring Claude usage limits in real-time.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-14.0+-blue" alt="macOS">
  <img src="https://img.shields.io/badge/Swift-5.9+-orange" alt="Swift">
  <img src="https://img.shields.io/badge/License-MIT-green" alt="License">
</p>

<p align="center">
  <a href="README.md">English</a> •
  <a href="docs/README-TR.md">Türkçe</a> •
  <a href="docs/README-ZH.md">中文</a> •
  <a href="docs/README-HI.md">हिन्दी</a> •
  <a href="docs/README-ES.md">Español</a> •
  <a href="docs/README-FR.md">Français</a> •
  <a href="docs/README-AR.md">العربية</a> •
  <a href="docs/README-PT.md">Português</a> •
  <a href="docs/README-JA.md">日本語</a> •
  <a href="docs/README-RU.md">Русский</a> •
  <a href="docs/README-IT.md">Italiano</a>
</p>

---

## Features

- **Real-time Usage Monitoring** - View current session and weekly usage limits at a glance
- **Plan Badge** - Displays your current subscription (Pro, Max 5x, Max 20x, Team, Enterprise)
- **Per-model Weekly Limits** - Separate rows for Fable, Opus and Sonnet whenever your plan reports them
- **Usage Credits** - Shows one-time credits and when they expire
- **Extra Usage Support** - Track pay-as-you-go spend, and see why it is disabled when your organization turns it off
- **Color-coded Progress Bars** - Green, yellow, orange, red based on usage percentage
- **Multi-language Support** - English, Turkish, Chinese, Spanish, Russian with in-app language picker
- **Customizable Notifications** - Native Notification Center alerts at 50%, 75%, 100%, or on reset, for every tracked limit
- **Auto-refresh** - Configurable refresh interval (30s, 1m, 2m, 5m)
- **Launch at Login** - Optionally start with your Mac
- **Menu Bar Percentage** - Show/hide usage percentage in menu bar
- **Native Experience** - Built with SwiftUI, follows macOS design guidelines
- **Lightweight** - Minimal resource footprint, no Electron
- **Privacy Focused** - No analytics, no telemetry

## Screenshots

<p align="center">
  <img src="screenshots/app-screenshot.png" alt="ClaudeBar General View" width="380">
</p>

<p align="center">
  <em>Real-time usage monitoring with plan badge</em>
</p>

<details>
<summary><strong>More Screenshots</strong></summary>

<br>

| Settings | Notifications | About |
|:--------:|:-------------:|:-----:|
| <img src="screenshots/settings-screenshot.png" alt="Settings" width="250"> | <img src="screenshots/notifications-screenshot.png" alt="Notifications" width="250"> | <img src="screenshots/about-screenshot.png" alt="About" width="250"> |

</details>

## Requirements

- macOS 14.0 (Sonoma) or later
- [Claude Code](https://claude.ai/code) installed and logged in
- Active Claude Pro, Max, or Team subscription

## Installation

### Homebrew (Recommended)

```bash
brew install --cask kemalasliyuksek/claudebar/claudebar-monitor
```

This automatically handles macOS Gatekeeper security — no manual steps needed.

### Download Pre-built Binary

Download the latest `.app` from the [Releases](https://github.com/kemalasliyuksek/claudebar/releases) page, then drag it to your Applications folder.

> **Note:** If macOS shows "ClaudeBar is damaged and can't be opened", run the following command to remove the quarantine flag:
> ```bash
> xattr -cr ClaudeBar.app
> ```

### Build from Source

```bash
git clone https://github.com/kemalasliyuksek/claudebar.git
cd claudebar
./build.sh
```

The app bundle will be created at `.build/release/ClaudeBar.app`.

To install:
```bash
cp -r .build/release/ClaudeBar.app /Applications/
```

## Usage

1. Ensure you're logged into Claude Code (`claude` command should work in terminal)
2. Launch ClaudeBar from Applications or Spotlight
3. Click the gauge icon in your menu bar to view usage limits

### Settings

Click the ⚙️ icon to configure:

| Setting | Description |
|---------|-------------|
| Launch at login | Start automatically when you log in |
| Show % in menu bar | Display percentage next to the menu bar icon |
| Language | Choose app language (System, English, Turkish, 中文, Español, Русский) |
| Refresh interval | How often to fetch usage data (30s - 5m) |
| Notify when 50% used | Send notification at 50% usage |
| Notify when 75% used | Send notification at 75% usage |
| Notify when limit reached | Send notification when limit is reached |
| Notify when limit resets | Send notification when limit resets |

### About

Click the ⓘ icon to view app information, credits, and links.

## How It Works

ClaudeBar reads the OAuth credentials that Claude Code stores in the macOS Keychain when you log in, then queries the same usage endpoint that Claude Code's `/usage` command uses.

### Architecture

```
┌─────────────────┐                      ┌───────────────────────────┐
│                 │  Stores tokens       │                           │
│   Claude Code   │─────────────────────▶│     macOS Keychain        │
│   (CLI login)   │                      │ "Claude Code-credentials" │
└─────────────────┘                      └───────────────────────────┘
                                                     │
                                                     │ Reads tokens, writes refreshed ones
                                                     ▼
┌─────────────────┐                      ┌───────────────────────────┐
│                 │ GET /api/oauth/usage │                           │
│  Anthropic API  │◀─────────────────────│        ClaudeBar          │
│                 │─────────────────────▶│                           │
└─────────────────┘    Usage data        └───────────────────────────┘
```

### Authentication Flow

1. **Read Credentials** - The Keychain item `Claude Code-credentials` (account: your macOS user name) is read through the system `security` tool, exactly the way Claude Code reads it. If Claude Code runs with a custom `CLAUDE_CONFIG_DIR`, the item name carries the same hash suffix Claude Code appends. When the Keychain is unavailable, `~/.claude/.credentials.json` is used as a fallback.

2. **Fetch Usage** - Calls the usage API with the access token:
   ```http
   GET https://api.anthropic.com/api/oauth/usage
   Authorization: Bearer {accessToken}
   anthropic-beta: oauth-2025-04-20
   ```

3. **Token Refresh** - When the token is within 5 minutes of expiry, or the API answers 401, ClaudeBar refreshes it with the same protocol Claude Code uses:
   - takes Claude Code's refresh lock (`~/.claude.lock`) so the two apps never rotate the same refresh token at once,
   - re-reads the Keychain and simply uses the new token if Claude Code refreshed it in the meantime,
   - otherwise calls `https://platform.claude.com/v1/oauth/token` with the scopes the token was issued with and writes the result back in place (`security add-generic-password -U`, password passed over stdin so it never appears in process arguments). Fields ClaudeBar does not know about are preserved.

### API Response

```json
{
  "five_hour":            { "utilization": 11.0, "resets_at": "2026-09-01T21:00:00Z" },
  "seven_day":            { "utilization": 42.0, "resets_at": "2026-09-05T07:00:00Z" },
  "seven_day_sonnet":     { "utilization": null, "resets_at": null },
  "seven_day_opus":       { "utilization": 3.0,  "resets_at": "2026-09-05T07:00:00Z" },
  "seven_day_oauth_apps": { "utilization": 0.0,  "resets_at": null },
  "cinder_cove":          { "utilization": 30.0, "resets_at": "2026-10-01T00:00:00Z" },
  "extra_usage": {
    "is_enabled": true, "monthly_limit": 5000, "used_credits": 1234.5,
    "utilization": 24.7, "currency": "USD", "disabled_reason": null
  },
  "limits": [
    {
      "kind": "weekly_scoped", "group": "model", "percent": 17.2,
      "resets_at": "2026-09-05T07:00:00Z",
      "scope": { "model": { "display_name": "Fable" } }
    }
  ]
}
```

| Field | Shown as |
|-------|----------|
| `five_hour` | Current session |
| `seven_day` | All models (weekly) |
| `seven_day_sonnet`, `seven_day_opus` | Sonnet only / Opus only (weekly) |
| `limits[]` entries with `kind: weekly_scoped` and a model scope | One row per model, e.g. "Fable only" |
| `cinder_cove` | One-time credit with its expiry date |
| `extra_usage` | Pay-as-you-go spend, limit and reset date, or the reason it is disabled |
| `seven_day_oauth_apps` | Not shown (Claude Code hides it as well) |

Any bucket, and any `utilization` inside a bucket, may be `null`; such rows are hidden.

## Important Notes

### Keychain Access

Reads and writes go through the system `security` tool, the same path Claude Code uses, so normally no extra Keychain prompt appears. If macOS does ask, click **Always Allow**.

### Notifications

On first launch macOS asks whether ClaudeBar may show notifications. If you decline, you can turn them back on later under System Settings › Notifications › ClaudeBar. When ClaudeBar runs without an app bundle (for example via `swift run`) it falls back to AppleScript notifications.

### Token Sharing

ClaudeBar and Claude Code share one OAuth session and coordinate refreshes through Claude Code's own lock files. If the session still becomes invalid (for example after revoking access on claude.ai), log in again:

```bash
claude logout && claude login
```

### Privacy

- Reads only the credentials Claude Code already stored, and writes back nothing but refreshed tokens
- All communication uses HTTPS
- No data stored outside the system Keychain (or Claude Code's own credential file)
- No analytics or telemetry
- Fully open source

## Project Structure

```
claudebar/
├── Package.swift              # Swift Package Manager manifest
├── build.sh                   # Build script
├── LICENSE                    # MIT License
├── README.md                  # This file
├── assets/
│   └── icons/                 # App icons
├── docs/                      # Translated READMEs
├── Resources/
│   ├── AppIcon.icns           # macOS app icon
│   └── Info.plist             # App metadata
├── Tests/ClaudeBarTests/      # Unit tests (swift test)
└── Sources/ClaudeBar/
    ├── ClaudeBarApp.swift     # App entry point
    ├── CredentialStore.swift  # Keychain / credential file access, Claude Code lock files
    ├── Localization.swift     # L() helper, language override, AppLanguage enum
    ├── Notifier.swift         # Notification Center with AppleScript fallback
    ├── OAuthClient.swift      # Usage fetch and token refresh
    ├── UsageModels.swift      # Data models
    ├── UsageService.swift     # Orchestration, polling, settings
    ├── UsageThresholds.swift  # Pure threshold / reset detection
    ├── UsageView.swift        # SwiftUI views
    └── Resources/
        ├── en.lproj/          # English strings
        ├── tr.lproj/          # Turkish strings
        ├── zh-Hans.lproj/     # Simplified Chinese strings
        ├── es.lproj/          # Spanish strings
        └── ru.lproj/          # Russian strings
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/claudebar.git
cd claudebar

# Build in debug mode
swift build

# Run tests
swift test

# Run
swift run

# Build release
./build.sh
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

**Kemal Aslıyüksek** - [@kemalasliyuksek](https://github.com/kemalasliyuksek)

## Disclaimer

This is an unofficial community project and is not affiliated with, officially maintained, or endorsed by Anthropic. Use at your own discretion.
