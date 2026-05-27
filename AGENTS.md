# Claude Usage Tracker — Project Context

## Project Overview

A native macOS menu bar app that tracks AI usage across multiple providers. Originally open-source (2.5k+ GitHub stars), now **fully closed-source** and transitioning to a revenue model.

**Current repo:** `github.com/amitashwinibhagat/claude-usage-tracker-private` (private)
**Old public repo:** `github.com/hamed-elfayome/Claude-Usage-Tracker` (archived)

## Business Model (Locked Decisions)

| Decision | Value |
|----------|-------|
| Goal | Revenue |
| Platform | macOS only |
| Monetization | $4.99/mo Pro + $9.99/user/mo Team |
| Distribution | Direct (DMG + Paddle), NOT App Store |
| License | Fully closed-source |
| Free Model | Feature-limited free forever |

### Free Tier Limits
- 2 profiles max
- Claude only
- Fixed thresholds (75/90/95%)
- 7-day history
- No export
- Basic icons only

### Pro Tier ($4.99/mo or $39.99/yr)
- Unlimited profiles
- Burn rate predictor
- Cost transparency
- Smart notifications
- Per-session breakdown
- Cross-profile dashboard
- Context window tracker
- Predictive throttling
- Usage history export (JSON/CSV)
- Multi-AI tracking (9 providers)
- Custom thresholds
- Advanced icon styles

### Team Tier ($9.99/user/mo)
- Shared team dashboard
- Budget alerts + Slack/Discord webhooks
- Admin controls
- Aggregate reporting
- SSO/SAML

## Architecture

### Tech Stack
- Swift + SwiftUI
- macOS 14.0+ (arm64 + x86_64 universal)
- Sparkle for updates
- Paddle for payments (stubbed)
- UserDefaults for persistence

### Key Services (all `@MainActor` singletons)
```
LicenseManager         — License validation, tier determination, Paddle stub
FeatureFlags           — Pro/Team feature gating registry
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
- Added `supportsOAuth: Bool` — only `.gemini` and `.copilot` return `true`

**LicenseTier enum**
```swift
.free, .pro, .team
```

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
│   ├── AppDelegate.swift              — App lifecycle, license validation on launch
│   └── ClaudeUsageTrackerApp.swift    — SwiftUI app entry
├── MenuBar/
│   ├── MenuBarManager.swift           — Icon rendering, refresh timer, profile switching
│   ├── PopoverContentView.swift       — Main popover UI (usage, predictions, multi-AI dashboard)
│   └── CrossProfileDashboard.swift    — All profiles side-by-side view
├── Shared/
│   ├── Models/
│   │   ├── AIProvider.swift           — Provider enum + protocol definitions (now with supportsOAuth)
│   │   ├── Profile.swift              — Main profile model (credentials + OAuth flags + usage)
│   │   ├── LicenseTier.swift          — Free/Pro/Team enum
│   │   ├── ClaudeUsage.swift          — Claude-specific usage data
│   │   ├── CodexUsage.swift           — OpenAI Codex usage
│   │   ├── GeminiUsage.swift          — Google Gemini usage (now with oauthAccessToken)
│   │   ├── CopilotUsage.swift         — GitHub Copilot usage (now with oauthAccessToken)
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
│   │   ├── LicenseManager.swift       — License validation (Paddle stub)
│   │   ├── FeatureFlags.swift         — Feature gating registry
│   │   ├── ProfileManager.swift       — Profile CRUD + OAuth state management
│   │   ├── MultiAIService.swift       — Fetches usage from all 9 providers (now loads OAuth tokens)
│   │   ├── ClaudeAPIService.swift     — Claude.ai + API Console fetching
│   │   ├── CodexAPIService.swift      — OpenAI billing + usage
│   │   ├── GeminiAPIService.swift     — Gemini + Cloud Monitoring (now supports OAuth Bearer tokens)
│   │   ├── CopilotAPIService.swift    — GitHub org billing + usage (now supports OAuth tokens)
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
│       │   ├── ProFeaturesView.swift  — Pro tier status + license activation
│       │   ├── AIProvidersSettingsView.swift — All 9 provider credential sheets + OAuth UI
│       │   ├── ManageProfilesView.swift — Profile list + 2-profile limit gate
│       │   └── SupportView.swift      — Pro upgrade CTA
│       └── Components/
│           ├── ProUpsellCard.swift    — Reusable upsell component
│           └── DateRangeExportView.swift — Date range picker for export
└── Resources/
    └── Info.plist                     — Sparkle SUFeedURL + OAuth URL scheme (claude-usage-tracker://)
```

## Feature Gating

All Pro features check `FeatureFlags.shared.isAvailable(...)`:

```swift
.unlimitedProfiles    — Max 2 profiles on Free
.burnRatePredictor   — Popover card + menu bar
.costTransparency    — Popover card showing API cost
.smartNotifications  — Contextual alerts vs basic thresholds
.perSessionBreakdown — Conversation-level tracking
.crossProfileDashboard — Multi-profile aggregate view
.contextWindowTracker — 200K window warning
.predictiveThrottling — Statistical forecast card
.usageHistoryExport  — JSON/CSV + date range picker
.multiAI             — All non-Claude providers
.customThresholds   — Fixed 75/90/95 on Free
.advancedIconStyles  — Basic only on Free
.weeklyDigest        — Not yet implemented
```

## Build Commands

```bash
# Debug build
xcodebuild -project "Claude Usage.xcodeproj" -scheme "Claude Usage" -destination 'platform=macOS' build CODE_SIGNING_ALLOWED=NO

# Release build (for DMG)
xcodebuild -project "Claude Usage.xcodeproj" -scheme "Claude Usage" -configuration Release -destination 'platform=macOS' CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO

# Create DMG
APP_PATH="~/Library/Developer/Xcode/DerivedData/Claude_Usage-*/Build/Products/Release/Claude Usage.app"
hdiutil create -volname "Claude Usage Tracker" -srcfolder "$APP_PATH" -ov -format UDZO ~/Desktop/Claude-Usage-Tracker.dmg
```

## Known Issues / TODOs

1. **LicenseManager** — `validateWithPaddle()` is a stub (accepts any `XXXX-XXXX-XXXX-XXXX` format). Replace with real Paddle SDK before launch.
2. **CodexAPIService** — Billing usage requires org admin role. Falls back to model list validation.
3. **GeminiAPIService** — Cloud Monitoring requires GCP project ID. Falls back to model list.
4. **CopilotAPIService** — Org usage requires admin. Falls back to user profile + individual plan.
5. **Chinese providers** (Kimi, DeepSeek, GLM, Qwen, MiniMax) — Model list validation only. Real usage APIs need implementation.
6. **Sparkle SUFeedURL** — Points to `amitashwinibhagat.github.io/claude-usage-tracker-private/appcast.xml`. Needs GitHub Pages setup.
7. **Team tier** — Not implemented (dashboard, webhooks, SSO).
8. **Weekly digest** — Not implemented.
9. **Referral program** — Not implemented.
10. **OAuth client IDs** — Google and GitHub OAuth client IDs are TODOs in `Info.plist` or build config. Must register apps before shipping.

## Session Notes (Last Updated: 2026-05-27)

### Changes on 2026-05-27
- **Implemented OAuth login for AI providers** — Users can now "Sign in with Google" (Gemini) and "Sign in with GitHub" (Copilot) instead of manually entering API keys
  - Added `OAuthToken` model with expiry tracking
  - Added `OAuthTokenStore` for secure Keychain storage (never touches UserDefaults/Profile plist)
  - Added `OAuthFlowCoordinator` with full PKCE support via `ASWebAuthenticationSession`
  - Added `GoogleOAuthConfiguration` and `GitHubOAuthConfiguration`
  - Added `claude-usage-tracker://oauth/callback` URL scheme to `Info.plist`
  - Updated `AIProvider` with `supportsOAuth` property
  - Updated `Profile` with `geminiOAuthConnected` and `copilotOAuthConnected` flags
  - Updated `GeminiAPIService` to use OAuth Bearer tokens for Cloud Monitoring
  - Updated `CopilotAPIService` to use OAuth tokens for GitHub API
  - Updated `MultiAIService` to auto-load OAuth tokens from Keychain before API calls
  - Updated `ProfileManager` with `setOAuthConnected()`, `disconnectOAuth()`, and cleanup on profile deletion
  - Updated `AIProvidersSettingsView` with OAuth sign-in buttons and disconnect management sheets
  - Added `OAuthSignInButton`, `GeminiOAuthSheet`, `CopilotOAuthSheet` UI components
- **Created UI redesign brief** for designers: `.kilo/design-briefs/ui-redesign-brief.md` covering 35+ screens, shared components, and design system requirements

### Changes on 2026-05-26
- Implemented Phase 1: LicenseManager, FeatureFlags, 2-profile limit, Burn Rate Predictor, Cost Transparency, Smart Notifications
- Implemented Phase 2: Conversation Breakdown, Cross-Profile Dashboard, Context Window Tracker, Predictive Throttling, Date Range Export
- Implemented Phase 3: Multi-AI with 9 providers (Claude, Codex, Gemini, Copilot, Kimi, DeepSeek, GLM, Qwen, MiniMax)
- Real API integration for Codex (OpenAI billing), Gemini (Cloud Monitoring), Copilot (GitHub org)
- Created ProFeaturesView settings page with license activation sheet
- Created AIProvidersSettingsView with credential management for all 9 providers
- Replaced GitHub star prompt with Pro upgrade CTA (closed-source transition)
- Updated all repo references from `hamed-elfayome/Claude-Usage-Tracker` to `amitashwinibhagat/claude-usage-tracker-private`
- Updated creator username in all 12 localization files
- Built test DMG with all Pro features unlocked (`LicenseManager.currentTier = .pro`)

### Next Priority Work
1. Wire up real Paddle SDK for license validation
2. Register Google Cloud OAuth client ID and GitHub OAuth App (replace TODO placeholders)
3. Implement real usage fetching for Chinese providers (Kimi, GLM, Qwen, MiniMax)
4. Team tier infrastructure (dashboard, webhooks, admin)
5. Weekly digest email
6. App Store review preparation (if ever needed)
7. Update Sparkle appcast for private repo
8. Implement UI redesign once designer mockups are ready

## How to Make Test Builds (All Features Unlocked)

To create a test build with all Pro features enabled without paywall:

1. Edit `Claude Usage/Shared/Services/LicenseManager.swift`:
   - Change `currentTier` default to `.pro`
   - Force `.pro` in `loadCachedLicense()`, `validateIfNeeded()`, `activateLicense()`

2. Build Release, create DMG

3. **REVERT the changes** before committing — keep source code clean for production

## Key Contacts / References
- Plan doc: `.kilo/plans/1779707822943-quiet-circuit.md` (revenue roadmap)
- OAuth plan: `.kilo/plans/1779811566651-swift-wolf.md` (OAuth architecture)
- UI redesign brief: `.kilo/design-briefs/ui-redesign-brief.md` (35+ screens for designers)
- Paddle integration: TODO — replace stub with Paddle macOS SDK
- Old repo: `github.com/hamed-elfayome/Claude-Usage-Tracker` (archived, do not use)
