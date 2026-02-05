# Usagem

A native macOS menu bar app that displays your Claude Code usage limits in real-time.

![macOS](https://img.shields.io/badge/macOS-14.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## Features

- **Real-time Usage Monitoring** - See your current session and weekly usage limits at a glance
- **Auto-refresh** - Updates every 60 seconds automatically
- **Token Management** - Handles OAuth token refresh seamlessly
- **Native Experience** - Built with SwiftUI, follows macOS design guidelines
- **Lightweight** - Minimal resource footprint, no Electron

## Screenshots

<!-- Add screenshots here -->
```
┌─────────────────────────────────────┐
│ Claude plan usage limits            │
│                                     │
│ Current session  ████████░░  72%    │
│ Resets in 3 hr 56 min               │
│─────────────────────────────────────│
│ Weekly limits                       │
│                                     │
│ All models       ████░░░░░░  40%    │
│ Resets Sat 9:59 AM                  │
│                                     │
│ Sonnet only      ░░░░░░░░░░   0%    │
│ You haven't used Sonnet yet         │
│─────────────────────────────────────│
│ Last updated: less than a minute ago│
└─────────────────────────────────────┘
```

## Requirements

- macOS 14.0 (Sonoma) or later
- [Claude Code](https://claude.ai/code) installed and logged in
- Active Claude Pro/Team subscription

## Installation

### Option 1: Download Pre-built Binary

Download the latest release from the [Releases](https://github.com/kemalasliyuksek/usagem/releases) page.

### Option 2: Build from Source

```bash
# Clone the repository
git clone https://github.com/kemalasliyuksek/usagem.git
cd usagem

# Build the app
./build.sh

# The app bundle is created at .build/release/Usagem.app
```

To install system-wide:
```bash
cp -r .build/release/Usagem.app /Applications/
```

## Usage

1. Make sure you're logged into Claude Code (run `claude` in terminal)
2. Launch Usagem
3. Click the gauge icon in your menu bar to see your usage limits

## How It Works

Usagem leverages the OAuth credentials that Claude Code stores in your macOS Keychain. Here's the complete flow:

### Architecture Overview

```
┌─────────────────┐                      ┌───────────────────────────┐
│                 │  Stores tokens       │                           │
│   Claude Code   │─────────────────────▶│     macOS Keychain        │
│   (CLI login)   │                      │ "Claude Code-credentials" │
│                 │                      │                           │
└─────────────────┘                      └───────────────────────────┘
                                                     │
                                                     │ Reads tokens
                                                     ▼
┌─────────────────┐                      ┌───────────────────────────┐
│                 │ GET /api/oauth/usage │                           │
│  Anthropic API  │◀─────────────────────│          Usagem           │
│                 │                      │        (this app)         │
│                 │─────────────────────▶│                           │
└─────────────────┘   Usage data (JSON)  └───────────────────────────┘
```

### Authentication Flow

#### Step 1: Reading Credentials

Usagem reads Claude Code's OAuth tokens from the macOS Keychain using the `security` command:

```bash
security find-generic-password -s "Claude Code-credentials" -w
```

This returns a JSON structure containing:
```json
{
  "claudeAiOauth": {
    "accessToken": "eyJ...",
    "refreshToken": "eyJ...",
    "expiresAt": 1738700000000,
    "scopes": ["user:inference", "user:profile", "user:sessions:claude_code"],
    "subscriptionType": "pro",
    "rateLimitTier": "pro"
  }
}
```

#### Step 2: Fetching Usage Data

With the access token, Usagem calls the Anthropic usage API:

```http
GET https://api.anthropic.com/api/oauth/usage
Authorization: Bearer {accessToken}
Content-Type: application/json
anthropic-beta: oauth-2025-04-20
```

Response:
```json
{
  "five_hour": {
    "utilization": 72.0,
    "resets_at": "2026-02-04T15:59:59.735935+00:00"
  },
  "seven_day": {
    "utilization": 40.0,
    "resets_at": "2026-02-07T06:59:59.735962+00:00"
  },
  "seven_day_sonnet": {
    "utilization": 0.0,
    "resets_at": null
  }
}
```

#### Step 3: Token Refresh (on 401)

When the access token expires (HTTP 401), Usagem automatically refreshes it:

```http
POST https://platform.claude.com/v1/oauth/token
Content-Type: application/json

{
  "grant_type": "refresh_token",
  "refresh_token": "{refreshToken}",
  "client_id": "9d1c250a-e61b-44d9-88ed-5944d1962f5e",
  "scope": "user:inference user:profile user:sessions:claude_code"
}
```

The new tokens are saved back to the Keychain, maintaining compatibility with Claude Code.

### Sequence Diagram

```
┌──────┐          ┌────────┐          ┌─────────┐          ┌───────────┐
│Usagem│          │Keychain│          │Anthropic│          │Claude.com │
└──┬───┘          └───┬────┘          └────┬────┘          └─────┬─────┘
   │                  │                    │                     │
   │ read credentials │                    │                     │
   │─────────────────▶│                    │                     │
   │                  │                    │                     │
   │    JSON tokens   │                    │                     │
   │◀─────────────────│                    │                     │
   │                  │                    │                     │
   │                  │   GET /usage       │                     │
   │                  │   + Bearer token   │                     │
   │──────────────────┼───────────────────▶│                     │
   │                  │                    │                     │
   │                  │    200 OK / 401    │                     │
   │◀─────────────────┼────────────────────│                     │
   │                  │                    │                     │
   │ [if 401]         │                    │                     │
   │                  │                    │  POST /oauth/token  │
   │──────────────────┼────────────────────┼────────────────────▶│
   │                  │                    │                     │
   │                  │                    │    new tokens       │
   │◀─────────────────┼────────────────────┼─────────────────────│
   │                  │                    │                     │
   │ save new tokens  │                    │                     │
   │─────────────────▶│                    │                     │
   │                  │                    │                     │
```

## Important Notes

### Keychain Access

On first launch, macOS may prompt you to allow Usagem to access the Keychain item "Claude Code-credentials". Click **Always Allow** for seamless operation.

### Token Refresh Race Condition

Since Usagem shares credentials with Claude Code, there's a potential race condition:

```
Time    Claude Code              Usagem
────────────────────────────────────────────────────
T1      Using token A            
T2                               Gets 401, refreshes...
T3                               Saves token B to Keychain
T4      Gets 401 (token A invalid)
T5      May fail to refresh if refresh token changed
```

**Mitigation:** This is rare in practice since:
- Access tokens are valid for ~1 hour
- Refresh tokens are typically reusable
- Both apps don't refresh simultaneously often

If you experience authentication issues, simply re-login to Claude Code:
```bash
claude logout && claude login
```

### Privacy & Security

- Usagem only reads existing credentials; it never sees your password
- All communication uses HTTPS
- No data is stored outside the system Keychain
- No analytics or telemetry

## Project Structure

```
usagem/
├── Package.swift              # Swift Package Manager manifest
├── build.sh                   # Build script
├── Resources/
│   └── Info.plist             # App metadata
└── Sources/Usagem/
    ├── UsagemApp.swift        # App entry point, menu bar setup
    ├── UsageModels.swift      # Data models (API response, Keychain)
    ├── UsageService.swift     # API client, token management
    └── UsageView.swift        # SwiftUI UI components
```

### Key Components

| File | Responsibility |
|------|----------------|
| `UsagemApp.swift` | Menu bar configuration, app lifecycle |
| `UsageService.swift` | API calls, OAuth flow, Keychain I/O |
| `UsageModels.swift` | Type definitions, JSON parsing |
| `UsageView.swift` | UI layout, progress bars, formatting |

## API Reference

### Usage Response Model

| Field | Type | Description |
|-------|------|-------------|
| `five_hour` | `UsageBucket?` | Current session limit (resets every 5 hours) |
| `seven_day` | `UsageBucket?` | Weekly limit for all models |
| `seven_day_sonnet` | `UsageBucket?` | Weekly limit for Sonnet model |
| `seven_day_opus` | `UsageBucket?` | Weekly limit for Opus model |

### UsageBucket Model

| Field | Type | Description |
|-------|------|-------------|
| `utilization` | `Double` | Usage percentage (0.0 - 100.0) |
| `resets_at` | `String?` | ISO 8601 timestamp for reset time |

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Setup

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/usagem.git
cd usagem

# Build in debug mode
swift build

# Run
swift run
```

## Roadmap

- [ ] App icon
- [ ] Launch at login option
- [ ] Notifications when approaching rate limits
- [ ] Customizable refresh interval
- [ ] Menubar percentage display toggle

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built for the [Claude Code](https://claude.ai/code) community
- Inspired by the usage display on [claude.ai](https://claude.ai)

## Disclaimer

This is an unofficial community project and is not affiliated with, officially maintained, or endorsed by Anthropic. Use at your own discretion.
