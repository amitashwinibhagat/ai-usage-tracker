# Claude Usage Tracker — Project Context

## Project Overview

A native macOS menu bar app that tracks AI usage across multiple providers. Originally open-source (2.5k+ GitHub stars), now **fully closed-source** and **completely free** — no tiers, no paywalls, no upgrades.

**Current repo:** `github.com/amitashwinibhagat/claude-usage-tracker-private` (private)
**Old public repo:** `github.com/hamed-elfayome/Claude-Usage-Tracker` (archived)

## Business Model

| Decision | Value |
|----------|-------|
| Goal | Free utility, no monetization |
| Platform | macOS only |
| Monetization | None |
| Distribution | Direct (DMG + Sparkle auto-updates) |
| License | Fully closed-source |
| Free Model | All features free forever |

All features are universally available: unlimited profiles, multi-AI tracking (9 providers), burn rate predictor, cost transparency, usage export, custom thresholds, and all icon styles.

## Architecture

### Tech Stack
- Swift + SwiftUI
- macOS 14.0+ (arm64 + x86_64 universal)
- Sparkle for updates
- UserDefaults for persistence

### Key Services (all `@MainActor` singletons)
```
ProfileManager         — CRUD for profiles + provider credentials
MenuBarManager         — Menu bar icon, popover, refresh loop
ClaudeAPIService       — Claude.ai + API Console usage fetching
MultiAIService         — Coordinator for all 9 AI providers
NotificationManager    — Threshold alerts + smart notifications
UsageHistoryService    — Snapshot recording, charts, export
BurnRatePredictor      — Time-to-limit predictions
CostTransparency       — API-equivalent cost calculations
SmartNotificationGenerator — Contextual alerts with advice
ConversationBreakdownService — Per-session interaction tracking
ContextWindowTracker   — Claude Code 200K window estimation
PredictiveThrottlingService — Statistical usage forecasting
OAuthTokenStore        — Secure Keychain storage for OAuth tokens
OAuthFlowCoordinator   — PKCE-based OAuth via ASWebAuthenticationSession
```

### Data Models

**Profile** (`Shared/Models/Profile.swift`)
- Per-profile: Claude session key, API Console key, CLI OAuth
- Multi-AI credentials: codexApiKey, geminiApiKey, copilotAccessToken, kimiApiKey, deepseekApiKey, glmApiKey, qwenApiKey, minimaxApiKey
- **OAuth connection state:** geminiOAuthConnected, copilotOAuthConnected (flags stored in Profile; tokens in Keychain)
- Usage data: claudeUsage, apiUsage, codexUsage, geminiUsage, copilotUsage, kimiUsage, deepseekUsage, glmUsage, qwenUsage, minimaxUsage

**AIProvider enum** (`Shared/Models/AIProvider.swift`)
```swift
.claude, .codex, .gemini, .copilot,
.kimi, .deepseek, .glm, .qwen, .minimax
```
- `supportsOAuth: Bool` — only `.gemini` and `.copilot` return `true`
- All providers visible in UI (`isShownInUI` returns `true` for all)

## Multi-AI Provider APIs

| Provider | API Base | Auth Methods | Status |
|----------|----------|-------------|--------|
| Claude | `claude.ai/api`, `console.anthropic.com/api` | Session key / CLI OAuth | Production |
| Codex | `api.openai.com` — billing + models | API key only | Real API |
| Gemini | `generativelanguage.googleapis.com` + Cloud Monitoring | **OAuth** or API key | Real API |
| Copilot | `api.github.com` — org billing + usage | **OAuth** or PAT | Real API |
| Kimi | `api.moonshot.cn/v1` | API key only | Model list validation |
| DeepSeek | `api.deepseek.com/v1` + balance endpoint | API key only | Model list + balance |
| GLM | `open.bigmodel.cn/api/paas/v4` | API key only | Model list validation |
| Qwen | `dashscope.aliyuncs.com/compatible-mode/v1` | API key only | Model list validation |
| MiniMax | `api.minimax.chat/v1` | API key only | Key format validation |

## File Structure (Key Files)

```
Claude Usage/
├── App/
│   ├── AppDelegate.swift              — App lifecycle
│   └── ClaudeUsageTrackerApp.swift    — SwiftUI app entry
├── MenuBar/
│   ├── MenuBarManager.swift           — Icon rendering, refresh timer, profile switching
│   ├── PopoverContentView.swift       — Main popover UI (usage, predictions, multi-AI dashboard)
│   └── CrossProfileDashboard.swift    — All profiles side-by-side view
├── Shared/
│   ├── Models/
│   │   ├── AIProvider.swift           — Provider enum + protocol definitions
│   │   ├── Profile.swift              — Main profile model (credentials + OAuth flags + usage)
│   │   ├── ClaudeUsage.swift          — Claude-specific usage data
│   │   ├── CodexUsage.swift           — OpenAI Codex usage
│   │   ├── GeminiUsage.swift          — Google Gemini usage
│   │   ├── CopilotUsage.swift         — GitHub Copilot usage
│   │   ├── KimiUsage.swift            — Moonshot AI usage
│   │   ├── DeepSeekUsage.swift        — DeepSeek usage
│   │   ├── GLMUsage.swift             — Zhipu AI usage
│   │   ├── QwenUsage.swift            — Alibaba Qwen usage
│   │   └── MiniMaxUsage.swift         — MiniMax usage
│   ├── Services/
│   │   ├── OAuth/
│   │   │   ├── OAuthToken.swift       — Token model with expiry tracking
│   │   │   ├── OAuthTokenStore.swift  — Keychain CRUD for secure token storage
│   │   │   ├── OAuthFlowCoordinator.swift — Generic PKCE OAuth via ASWebAuthenticationSession
│   │   │   ├── GoogleOAuthConfiguration.swift — Google Cloud OAuth config
│   │   │   └── GitHubOAuthConfiguration.swift — GitHub OAuth config
│   │   ├── ProfileManager.swift       — Profile CRUD + OAuth state management
│   │   ├── MultiAIService.swift       — Fetches usage from all 9 providers
│   │   ├── ClaudeAPIService.swift     — Claude.ai + API Console fetching
│   │   ├── CodexAPIService.swift      — OpenAI billing + usage
│   │   ├── GeminiAPIService.swift     — Gemini + Cloud Monitoring
│   │   ├── CopilotAPIService.swift    — GitHub org billing + usage
│   │   ├── KimiAPIService.swift       — Moonshot API
│   │   ├── DeepSeekAPIService.swift   — DeepSeek API + balance
│   │   ├── GLMAPIService.swift        — Zhipu API
│   │   ├── QwenAPIService.swift       — DashScope API
│   │   ├── MiniMaxAPIService.swift    — MiniMax API
│   │   ├── BurnRatePredictor.swift    — Time-to-limit predictions
│   │   ├── CostTransparency.swift     — API-equivalent cost calculator
│   │   ├── SmartNotificationGenerator.swift — Contextual alert messages
│   │   ├── ConversationBreakdownService.swift — Per-interaction token tracking
│   │   ├── ContextWindowTracker.swift — 200K context window estimation
│   │   └── PredictiveThrottlingService.swift — Statistical forecasting
│   └── ErrorHandling/
│       └── AppError.swift             — Error codes including apiForbidden, OAuthError
├── Views/
│   └── Settings/
│       ├── SettingsView.swift         — Sidebar navigation
│       ├── App/
│       │   ├── AIProvidersSettingsView.swift — All 9 provider credential sheets + OAuth UI
│       │   └── ManageProfilesView.swift — Profile list
│       └── Components/
│           └── DateRangeExportView.swift — Date range picker for export
└── Resources/
    └── Info.plist                     — Sparkle SUFeedURL + OAuth URL scheme (claude-usage-tracker://)
```

## Build Commands

```bash
# Debug build
xcodebuild -project "Claude Usage.xcodeproj" -scheme "Claude Usage" -destination 'platform=macOS' build CODE_SIGNING_ALLOWED=NO

# Release build (for DMG)
xcodebuild -project "Claude Usage.xcodeproj" -scheme "Claude Usage" -configuration Release -destination 'platform=macOS' CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO

# Full release (auto-increments build, builds Release, creates signed DMG + appcast)
./scripts/release.sh              # incremental build (e.g. 15→16 for v3.1.1)
./scripts/release.sh 3.2.0        # new version, resets build to 1
./scripts/release.sh -b 100       # force specific build number

# Create DMG manually
APP_PATH="~/Library/Developer/Xcode/DerivedData/Claude_Usage-*/Build/Products/Release/AI Usage Tracker.app"
hdiutil create -volname "AI Usage Tracker" -srcfolder "$APP_PATH" -ov -format UDZO ~/Desktop/AI-Usage-Tracker.dmg
```

### Release Process (Sparkle Auto-Increment)

Every DMG release auto-increments `CURRENT_PROJECT_VERSION` (CFBundleVersion) in the main app target. Sparkle uses this build number to detect available updates — a higher build number means an update exists, even if MARKETING_VERSION hasn't changed.

**How it works:**
- `scripts/release.sh` reads the current build number from `project.pbxproj`
- Increments only the main app target entries (test target stays at its own version)
- `Info.plist` uses `$(CURRENT_PROJECT_VERSION)` variable — resolved at build time
- `generate_appcast` reads the built app's Info.plist and embeds version + build in the appcast
- Sparkle client compares CFBundleVersion (build number) to detect available updates

**Versioning convention:**
- `MARKETING_VERSION` = `3.1.1` (semantic display version)
- `CURRENT_PROJECT_VERSION` = incremental integer (16, 17, 18...)
- DMG filename = `AI-Usage-Tracker-{VERSION}-{BUILD}.dmg`

## Release & Deployment Infrastructure (CRITICAL — READ BEFORE EVERY RELEASE)

### App Name
The app bundle is named **`AI Usage Tracker.app`**. The DMG is `AI-Usage-Tracker-{VERSION}-{BUILD}.dmg`.

### Release Script (`scripts/release.sh`)
- `APP_NAME` must be `"AI Usage Tracker"` (exactly matches the built `.app` bundle name). Do NOT change this.
- The script auto-increments `CURRENT_PROJECT_VERSION`, builds Release, creates DMG, and generates appcast.
- After the script runs, you must **manually fix the enclosure URL** in `appcast.xml` (see below).

### ⚠️ CRITICAL: Appcast Enclosure URLs Must Point to Netlify
`generate_appcast` with `--download-url-prefix` produces GitHub Releases URLs by default. **The DMG is NOT on GitHub Releases** — it is only on Netlify. If the enclosure URL points to GitHub, Sparkle will 404 and users see "An error occurred while downloading the update."

**After every release, manually edit `Claude Usage/Resources/appcast.xml`:**
```xml
<!-- WRONG — will 404 -->
<enclosure url="https://github.com/amitashwinibhagat/.../download/v3.1.1/AI-Usage-Tracker-3.1.1-21.dmg" ... />

<!-- CORRECT -->
<enclosure url="https://rococo-fox-c631c0.netlify.app/AI-Usage-Tracker-3.1.1-21.dmg" ... />
```

### Netlify Deployment
- **Site ID:** `aa06579d-df69-4e56-9096-963b3a4165f1`
- **Site name:** `rococo-fox-c631c0`
- **Production URL:** `https://rococo-fox-c631c0.netlify.app`
- **Important:** The local Netlify CLI may be linked to a different project (`echoflow`). Always deploy with explicit site ID:
  ```bash
  netlify deploy --prod --dir=netlify-deploy --site=aa06579d-df69-4e56-9096-963b3a4165f1
  ```
- The `releases/` directory may contain old DMGs with conflicting build numbers. Remove old DMGs before running `generate_appcast` or Sparkle will error with "Duplicate updates are not supported."

### Full Release Checklist
1. Ensure `scripts/release.sh` has correct `APP_NAME`
2. Run `./scripts/release.sh`
3. Remove old conflicting DMGs from `releases/`
4. Manually edit `appcast.xml` enclosure URL to point to Netlify
5. Commit appcast fix: `git add -A && git commit -m "Fix appcast URL" && git push`
6. Deploy to Netlify with explicit site ID
7. Verify `curl -I https://rococo-fox-c631c0.netlify.app/AI-Usage-Tracker-{VERSION}-{BUILD}.dmg` returns 200

## Known Issues / TODOs

1. **CodexAPIService** — Billing usage requires org admin role. Falls back to model list validation.
2. **GeminiAPIService** — Cloud Monitoring requires GCP project ID. Falls back to model list.
3. **CopilotAPIService** — Org usage requires admin. Falls back to user profile + individual plan.
4. **Chinese providers** (Kimi, DeepSeek, GLM, Qwen, MiniMax) — Model list validation only. Real usage APIs need implementation.
5. ~~GitHub Pages appcast hosting~~ — Now hosted on Netlify (`rococo-fox-c631c0.netlify.app`). Old GitHub Pages no longer required.
6. **Weekly digest** — Not implemented.
7. **Referral program** — Not implemented.
8. **OAuth client IDs** — Google and GitHub OAuth client IDs are TODOs in `Info.plist` or build config. Must register apps before shipping.

## Session Notes (Last Updated: 2026-06-01)

### Changes on 2026-06-01 — Pivot to Fully Free (Remove All Monetization)
- **Deleted 6 files**: `LicenseManager.swift`, `FeatureFlags.swift`, `LicenseTier.swift`, `ProFeaturesView.swift`, `SupportView.swift`, `ProUpsellCard.swift`
- **Modified 22+ files** to remove all monetization references:
  - `AppDelegate.swift` — Removed license validation call
  - `ProfileManager.swift` — Removed profile limit (unlimited profiles now)
  - `MenuBarManager.swift` — Removed multi-AI feature flag check
  - `PopoverContentView.swift` — Removed Pro check for burn rate card
  - `BurnRateCard.swift` — Always shows full burn rate, removed upsell content
  - `DetailsDisclosure.swift` — Always shows cost transparency and multi-AI rows
  - `AccountSettingsView.swift` — Stripped all license/pricing/activation UI, simplified to About/Info
  - `AppearanceSettingsView.swift` — Removed feature flag checks
  - `CredentialsSettingsView.swift` — Shows all 9 providers without locks
  - `NotificationsSettingsView.swift` — Custom thresholds always available
  - `ProfilesSettingsView.swift` — Unlimited profiles, export always available
  - `UsageHistoryView.swift` — Export always available
  - `AIProvidersSettingsView.swift` — All providers visible without Pro gates
  - `ManageProfilesView.swift` — Removed Pro upsell for profile limit
  - `SettingToggle.swift` — Removed `.pro` badge case
  - `AIProvider.swift` — Removed `isFreeTier`/`requiresPro`, all providers shown in UI
  - `MultiAIService.swift` — All providers always available
  - `BurnRatePredictor.swift` — Always predicts (no gate)
  - `CostTransparency.swift` — Always calculates (no gate)
  - `SmartNotificationGenerator.swift` — Always generates smart alerts (no gate)
- **Updated `AGENTS.md`** — Removed all monetization references, updated business model to "Free, no monetization"
- **Build verification** — Debug build succeeds with zero errors

### Changes on 2026-05-29
- **Removed non-functional Mobile App sidebar item** (`SettingsSection.mobileApp`)
- **Updated remaining author references** to `amitashwinibhagat/claude-usage-tracker-private`
- **Fixed `scripts/release.sh` app name** (`APP_NAME`) — Changed to `"AI Usage Tracker"`
- **Released v3.1.1 build 21**: Built DMG, deployed to Netlify, fixed appcast enclosure URL

### Changes on 2026-05-29 (Part 2) — Apple PM-Style UX Redesign
- **Complete UX redesign** guided by Apple design principles
- **Onboarding rewritten** — 3-screen welcome experience
- **Popover redesigned** — 5-card layout
- **Settings restructured** — Collapsed 18 sidebar sections to 6 groups
- **Provider cleanup** — Hidden 5 non-functional Chinese providers from UI
- **Feature flag simplification** — Removed 7 dead-end Pro gates
- **Released v3.1.1 build 22**

### Changes on 2026-05-28
- **Created unified design system** (`Shared/DesignSystem/AppTheme.swift`)
- **Sparkle in-app updates configured** with ed25519 signing
- **Redesigned settings sidebar, popover dashboard, shared settings primitives**
- **Released v3.1.1 build 19**

### Changes on 2026-05-27
- **Implemented OAuth login** for Gemini (Google) and Copilot (GitHub)

### Changes on 2026-05-26
- Implemented LicenseManager, FeatureFlags, Pro features, Multi-AI tracking

## Key Contacts / References
- Plan doc: `.kilo/plans/1779707822943-quiet-circuit.md` (original revenue roadmap — archived)
- OAuth plan: `.kilo/plans/1779811566651-swift-wolf.md` (OAuth architecture)
- UI redesign brief: `.kilo/design-briefs/ui-redesign-brief.md` (35+ screens for designers)
- Pivot plan: `.kilo/plans/1780073981355-neon-star.md` (remove all monetization)
- Old repo: `github.com/hamed-elfayome/Claude-Usage-Tracker` (archived, do not use)
