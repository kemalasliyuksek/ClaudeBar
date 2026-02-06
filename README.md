# Usagem

<p align="center">
  <img src="assets/usagem-icon.png" alt="Usagem Icon" width="128" height="128">
</p>

<p align="center">
  <strong>A native macOS menu bar app for monitoring Claude usage limits in real-time.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-14.0+-blue" alt="macOS">
  <img src="https://img.shields.io/badge/Swift-5.9+-orange" alt="Swift">
  <img src="https://img.shields.io/badge/License-MIT-green" alt="License">
</p>

---

## Features

- **Real-time Usage Monitoring** - View current session and weekly usage limits at a glance
- **Plan Badge** - Displays your current subscription (Pro, Max, Team)
- **Extra Usage Support** - Track pay-as-you-go credits when enabled
- **Customizable Notifications** - Get notified at 50%, 75%, 100%, or on reset
- **Auto-refresh** - Configurable refresh interval (30s, 1m, 2m, 5m)
- **Launch at Login** - Optionally start with your Mac
- **Menu Bar Percentage** - Show/hide usage percentage in menu bar
- **Native Experience** - Built with SwiftUI, follows macOS design guidelines
- **Lightweight** - Minimal resource footprint, no Electron
- **Privacy Focused** - No analytics, no telemetry

## Screenshot

```
┌─────────────────────────────────────────┐
│ Claude plan usage limits     [Max Plan] │
│                                         │
│ Current session  ██░░░░░░░░   11% used  │
│ Resets in 3 hr 56 min                   │
│─────────────────────────────────────────│
│ Weekly limits                           │
│                                         │
│ All models       ████░░░░░░   41% used  │
│ Resets Sat 10:00 AM                     │
│                                         │
│ Sonnet only      ░░░░░░░░░░    0% used  │
│ You haven't used Sonnet yet             │
│─────────────────────────────────────────│
│ Extra usage                             │
│                                         │
│ $0.00 spent      ░░░░░░░░░░    0% used  │
│ Resets Mar 1 · Limit: $50               │
│─────────────────────────────────────────│
│ Last updated: ...          ⓘ  ⚙️  ↻     │
└─────────────────────────────────────────┘
```

## Requirements

- macOS 14.0 (Sonoma) or later
- [Claude Code](https://claude.ai/code) installed and logged in
- Active Claude Pro, Max, or Team subscription

## Installation

### Download Pre-built Binary

Download the latest `.app` from the [Releases](https://github.com/kemalasliyuksek/usagem/releases) page, then drag it to your Applications folder.

### Build from Source

```bash
git clone https://github.com/kemalasliyuksek/usagem.git
cd usagem
./build.sh
```

The app bundle will be created at `.build/release/Usagem.app`.

To install:
```bash
cp -r .build/release/Usagem.app /Applications/
```

## Usage

1. Ensure you're logged into Claude Code (`claude` command should work in terminal)
2. Launch Usagem from Applications or Spotlight
3. Click the gauge icon in your menu bar to view usage limits

### Settings

Click the ⚙️ icon to configure:

| Setting | Description |
|---------|-------------|
| Launch at login | Start automatically when you log in |
| Show % in menu bar | Display percentage next to the menu bar icon |
| Refresh interval | How often to fetch usage data (30s - 5m) |
| Notify when 50% used | Send notification at 50% usage |
| Notify when 75% used | Send notification at 75% usage |
| Notify when limit reached | Send notification when limit is reached |
| Notify when limit resets | Send notification when limit resets |

### About

Click the ⓘ icon to view app information, credits, and links.

## How It Works

Usagem reads OAuth credentials from the macOS Keychain that Claude Code stores when you log in. It then queries the Anthropic API for your current usage limits.

### Architecture

```
┌─────────────────┐                      ┌───────────────────────────┐
│                 │  Stores tokens       │                           │
│   Claude Code   │─────────────────────▶│     macOS Keychain        │
│   (CLI login)   │                      │ "Claude Code-credentials" │
└─────────────────┘                      └───────────────────────────┘
                                                     │
                                                     │ Reads tokens
                                                     ▼
┌─────────────────┐                      ┌───────────────────────────┐
│                 │ GET /api/oauth/usage │                           │
│  Anthropic API  │◀─────────────────────│          Usagem           │
│                 │─────────────────────▶│                           │
└─────────────────┘    Usage data        └───────────────────────────┘
```

### Authentication Flow

1. **Read Credentials** - Usagem reads tokens from macOS Keychain using:
   ```bash
   security find-generic-password -s "Claude Code-credentials" -w
   ```

2. **Fetch Usage** - Calls the Anthropic usage API with the access token:
   ```http
   GET https://api.anthropic.com/api/oauth/usage
   Authorization: Bearer {accessToken}
   anthropic-beta: oauth-2025-04-20
   ```

3. **Token Refresh** - When the access token expires (HTTP 401), Usagem automatically refreshes it and updates the Keychain.

### API Response

```json
{
  "five_hour": { "utilization": 11.0, "resets_at": "2026-02-06T11:00:00Z" },
  "seven_day": { "utilization": 42.0, "resets_at": "2026-02-07T07:00:00Z" },
  "seven_day_sonnet": { "utilization": 0.0, "resets_at": null },
  "extra_usage": { "is_enabled": true, "monthly_limit": 5000, "used_credits": 0.0 }
}
```

## Important Notes

### Keychain Access

On first launch, macOS may prompt you to allow Usagem to access the Keychain. Click **Always Allow** for seamless operation.

### Token Sharing

Usagem shares OAuth tokens with Claude Code. In rare cases, simultaneous token refresh may require re-login:

```bash
claude logout && claude login
```

### Privacy

- Only reads existing credentials from Keychain
- All communication uses HTTPS
- No data stored outside system Keychain
- No analytics or telemetry
- Fully open source

## Project Structure

```
usagem/
├── Package.swift           # Swift Package Manager manifest
├── build.sh                # Build script
├── LICENSE                 # MIT License
├── README.md               # This file
├── assets/
│   └── usagem-icon.png     # App icon source
├── Resources/
│   ├── AppIcon.icns        # macOS app icon
│   └── Info.plist          # App metadata
└── Sources/Usagem/
    ├── UsagemApp.swift     # App entry point
    ├── UsageModels.swift   # Data models
    ├── UsageService.swift  # API client & business logic
    └── UsageView.swift     # SwiftUI views
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
git clone https://github.com/YOUR_USERNAME/usagem.git
cd usagem

# Build in debug mode
swift build

# Run
swift run

# Build release
./build.sh
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

**Kemal Asliyuksek** - [@kemalasliyuksek](https://github.com/kemalasliyuksek)

## Disclaimer

This is an unofficial community project and is not affiliated with, officially maintained, or endorsed by Anthropic. Use at your own discretion.
