# Apple PM-Style UX Redesign Plan

> **Status:** Plan — ready for implementation  
> **Last updated:** 2026-05-29  
> **Decision summary:** Radical simplification — reduce popover from 15 cards to 3-5, collapse settings from 18 sections to 6, hide non-functional providers, 3-screen onboarding.

---

## Design Principles (Apple-Inspired)

1. **One job, one glance** — The app answers one question: "Am I about to hit my limit?" Everything else is secondary.
2. **Progressive disclosure** — Show what matters now. Hide complexity behind deliberate actions.
3. **Context over features** — The UI adapts to the user's state (normal/warning/critical), not to feature flags.
4. **Zero dead ends** — Every screen has a primary action. No "coming soon" or painted-door pages.
5. **Clarity through reduction** — Removing is more important than adding.

---

## Part 1: Onboarding — 3-Screen Welcome Experience

### Current State
- 3-step wizard (Enter Key → Select Org → Confirm) that only asks for a Claude session key
- Shows CLI detection banner if `.claude.json` exists
- Shows legacy migration prompt
- 580×680px window — too large for what it does

### Redesigned Flow

**Screen 1: Welcome**
```
┌─────────────────────────────────────┐
│                                     │
│         [App Icon - 80px]           │
│                                     │
│     Track your AI usage             │
│     from the menu bar               │
│                                     │
│  Know your limits before you        │
│  hit them. Free forever for         │
│  basic Claude tracking.             │
│                                     │
│         [Get Started]               │
│                                     │
│   No account needed. All data       │
│   stays on your Mac.                │
└─────────────────────────────────────┘
```
- Window: 420×380px — compact, focused
- Single CTA: "Get Started"
- Privacy reassurance in footer
- Skip button (corner) for power users

**Screen 2: How do you use Claude?**
```
┌─────────────────────────────────────┐
│  ← Back                    Step 2/3 │
│                                     │
│  How do you use Claude?             │
│  Select all that apply.             │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ 🌐  Claude.ai (website)     │    │
│  │     Browser-based usage     │    │
│  └─────────────────────────────┘    │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ ⌨️   Claude Code (terminal) │    │
│  │     CLI-based development   │    │
│  └─────────────────────────────┘    │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ 💰  API Console (billing)   │    │
│  │     Pay-as-you-go API       │    │
│  └─────────────────────────────┘    │
│                                     │
│         [Continue]                  │
└─────────────────────────────────────┘
```
- Selectable cards (not checkboxes) — tap to toggle
- At least one must be selected
- Auto-detects CLI credentials in background; if found, pre-selects it with a green badge "Detected"

**Screen 3: Set Up**
- Shows ONLY the credential forms needed based on Screen 2 selections
- If only CLI detected → "Ready to track! Your Claude Code credentials were found automatically." → [Start Tracking]
- If Claude.ai selected → embedded WebView sign-in (same as current `ConsoleAuthSheet`)
- If API selected → API key field
- Below: "You can add more later in Settings."
- [Start Tracking] button → saves credentials, dismisses wizard, starts first refresh

### Removals
- Remove the legacy migration prompt from the wizard (migration is an edge case — handle silently or in Settings > Advanced)
- Remove the "Auto-start session" toggle from onboarding (move to Settings > Profiles)
- Remove the manual session key entry with instructions (keep WebView sign-in as primary; manual entry goes to an "Advanced" disclosure)

---

## Part 2: Menu Bar Icon — Radical Simplification

### Current State
- Configurable multi-metric icon system (`MenuBarIconConfig`) with session/week/API metrics, color modes, display modes, pace markers, remaining/used toggle
- `MenuBarIconRenderer` renders complex multi-segment icons
- This is Pro-gated via `advancedIconStyles`

### Redesigned: Universal Usage Ring
- The menu bar icon is a **28×16pt mini usage ring** (donut chart)
- **Green** (<75%), **Amber** (75-90%), **Red** (>90%)
- Shows the higher of session or weekly percentage
- Hover: shows exact percentage as tooltip
- Click: opens popover
- Right-click: context menu (Refresh, Switch Profile, Settings, Quit)

**Pro upgrade for icons:**
- Pro users can choose between ring, bar, or numeric icon styles
- Pro users can pin specific metrics (always show weekly, always show session)
- Free users get the basic ring only

**Implementation note:** `MenuBarIconConfig`, `MenuBarIconRenderer`, `IconStylePicker`, `MetricIconCard` remain but are simplified. Free tier only renders the ring style. Pro tier unlocks the picker.

---

## Part 3: Popover — From 15 Cards to 5

### Current State (15 stacked elements)
1. SmartHeader (profile switcher + refresh + settings)
2. Status banners (error/stale data)
3. Profile viewing tag (multi-profile)
4. UsageGuidanceCard
5. Session usage row with progress bar
6. Weekly usage row with progress bar
7. Opus usage row (conditional)
8. Sonnet usage row (conditional)
9. Extra cost usage row (conditional)
10. APIUsageCard (conditional)
11. APICostCard with daily chart (conditional)
12. ConversationBreakdownCard (Pro-gated)
13. BurnRateCard (Pro-gated)
14. CostTransparencyCard (Pro-gated)
15. CrossProfileDashboard (Pro-gated)
16. ContextWindowCard (Pro-gated)
17. PredictiveThrottlingCard (Pro-gated)
18. MultiAIDashboard (Pro-gated)
19. ProUpsellBanner (Free only)
20. SessionOverlapCard (conditional)
21. ContextualTipCard
22. ContextualInsights (expandable)

### Redesigned: 5-Card Layout

```
┌──────────────────────────────────┐
│  [Profile ▾]          [⟳] [⚙]   │  ← Header (compact, no status dot)
├──────────────────────────────────┤
│                                  │
│        ┌──────────────┐          │
│        │              │          │
│        │  68% used    │          │  ← Usage Ring Card
│        │  ─────────   │          │     (large centered donut)
│        │              │          │
│        │ 320K of 500K │          │
│        │ tokens this  │          │
│        │ week         │          │
│        └──────────────┘          │
│                                  │
│  Resets Monday at 3:00 AM        │  ← Reset Countdown Card
│  (3 days from now)               │
│                                  │
│  ─────────────────────────────── │
│                                  │
│  ⚡ At this rate, you'll hit     │  ← Burn Rate Card (Pro only;
│     your limit Tuesday evening   │     Free sees upsell teaser)
│                                  │
│  ─────────────────────────────── │
│                                  │
│  💡 Tip: Opus costs ~5x more     │  ← Contextual Tip Card
│     than Haiku. Switch models     │     (rotates; always visible)
│     for routine tasks.            │
│                                  │
├──────────────────────────────────┤
│  [Details ▾]    [⚙ Settings]     │  ← Footer
└──────────────────────────────────┘
```

### Card Breakdown

**1. Usage Ring Card** (always visible)
- Large SF Symbol-based ring or SwiftUI `Canvas` donut chart
- Center: percentage + metric label ("68%")
- Below: human-readable summary — "320K of 500K tokens this week"
- Tapping the ring toggles between session and weekly view
- Color: green/amber/red based on status

**2. Reset Countdown Card** (always visible)
- Simple text: "Resets Monday at 3:00 AM (3 days)"
- If multiple profiles: shows reset for each in compact rows
- Becomes prominent when <24h remaining

**3. Burn Rate Card** (Pro-gated)
- Pro users: "At your current pace (12K tokens/hr), you'll hit the limit Tuesday evening."
- Includes a mini sparkline of last 6 hours
- Free users: "Upgrade to Pro to see burn rate predictions" with a single [Upgrade] button
- **NOT a dead-end upsell** — the teaser text is contextual ("You're using tokens 30% faster than usual")

**4. Contextual Tip Card** (always visible)
- Single rotating tip from the `LimitOptimizationTip` catalog
- Context-aware: suggests model switching when Opus usage is high, suggests CLI commands for power users
- Non-intrusive, helpful, no upsell

**5. Details Disclosure** (collapsed by default)
- Tapping "Details ▾" expands to reveal:
  - Cost transparency (Pro)
  - Session breakdown (Pro)
  - Multi-AI dashboard (Pro, if other providers connected)
  - API cost chart
  - Model-specific breakdown (Opus/Sonnet)
- This replaces the current scrollable wall of cards
- Free users see "Pro" badges on locked detail items

### Removals from Popover
- **Profile viewing tag** — merged into header
- **Claude status dot** — removed from popover (it's in the right-click menu)
- **Status banners (error/stale)** — replaced with subtle inline indicator in the header
- **SessionOverlapCard** — niche feature, moved to Details disclosure
- **CrossProfileDashboard** — merged into Details; mini profile rows replace full cards
- **ContextualInsights** — merged into Contextual Tip Card
- **ProUpsellBanner** — replaced by contextual Burn Rate teaser (less spammy)
- **Multi-AI provider summary** — moved to Details

---

## Part 4: Settings — From 18 Sections to 6

### Current Sidebar Structure
```
Profile Section:
  - Profile Switcher dropdown
  - Providers: Claude, Codex, Gemini, Copilot, Kimi, DeepSeek, GLM, Qwen, MiniMax
  - Settings: Appearance, General, History
App Section:
  - Pro Features
  - AI Providers
  - App Settings
  - Manage Profiles
  - Language
  - Claude Code
  - Shortcuts
  - Updates
  - Popover
Bottom Bar:
  - Support, Debug, About, Quit
```

### Redesigned: 6 Groups

```
┌────────────────────┐
│  [AI Usage Tracker]│
│                    │
│  ────────────────  │
│  General           │
│  Profiles          │
│  Credentials       │
│  Notifications     │
│  Appearance        │
│  Account           │
│                    │
│  ────────────────  │
│  [About] [Quit]    │
└────────────────────┘
```

### Group Details

**1. General**
- Launch at login toggle
- Refresh interval (5/10/15/30 min)
- Language picker
- Check for updates (Sparkle) + auto-update toggle
- Reset all app data (destructive, red-tinted)

**2. Profiles**
- Profile list with +/–/rename
- Active profile switcher
- Per-profile: name, CLI sync status, credential summary
- 2-profile limit for Free tier (graceful inline message, not a separate upsell page)
- Import/export profile (Pro)

**3. Credentials** (MERGE of current: claudeAI, apiConsole, cliAccount, aiProviders, claudeCode)
- **Claude section:**
  - Claude.ai session key (sign-in button + status)
  - API Console billing key (sign-in + status)
  - Claude Code CLI sync (auto-detected, refresh button)
- **Other providers section** (Pro-only — Claude, Codex, Gemini, Copilot):
  - Compact rows per provider with connection status
  - OAuth buttons for Gemini + Copilot
  - API key fields for Codex
  - "Add provider" button for Pro users
- **Removed providers (hidden from UI):** Kimi, DeepSeek, GLM, Qwen, MiniMax
  - Keep service code in project but remove from UI
  - Can be re-enabled when real usage APIs are implemented
  - Reasoning: Showing 5 providers that return `tokensUsed: 0` damages trust

**4. Notifications**
- Threshold toggles (75/90/95% for Free; custom values for Pro)
- Smart notifications toggle (Pro)
- Sound toggle
- Notification preview
- Session planning alerts (merged from separate section)

**5. Appearance**
- Menu bar icon style: Ring (default) / Bar / Numeric (Pro unlocks non-ring styles)
- Color scheme: Auto / Dark / Light
- Popover width (compact 320pt / wide 400pt — Pro only)
- Show remaining vs used toggle

**6. Account**
- License tier display (Free / Pro / Team)
- License key input + activate button
- Pro upgrade CTA (opens Paddle checkout)
- Manage subscription link
- About (version, build, credits)
- Support (email, FAQ link)

### Removals from Settings
- **MobileAppView** — painted door, no real app. Remove entirely.
- **DebugNetworkLogView** — hide behind opt+click on version number in About
- **PopoverSettingsView** — merge into Appearance
- **ShortcutsSettingsView** — no real shortcuts exist (only refresh). Remove.
- **LimitOptimizationGuideView** — merge tips into contextual cards (already served by ContextualTipCard)
- **SessionPlanningSettingsView** — merge into Notifications
- **LanguageSettingsView** — merge into General
- **UpdatesSettingsView** — merge into General
- **GitHubStarPromptView** — closed source now. Remove.
- **FeedbackPromptView** — remove (support is in Account)

### Sidebar Design
- Width: 200pt (down from 228pt)
- No provider mini-rows in sidebar (moved into Credentials page)
- Profile switcher as a dropdown in the sidebar header
- Bottom bar: only About + Quit (Support merged into Account)
- No "Debug" in bottom bar (developer-only, hidden gesture)

---

## Part 5: Feature Cuts & Deferrals

### Immediate Cuts (Remove from UI)

| # | Feature | Reason |
|---|---------|--------|
| 1 | Mobile app painted door | No mobile app exists |
| 2 | GitHub star prompt | Project is closed-source |
| 3 | Feedback prompt | Replaced by Support in Account |
| 4 | 5 Chinese providers (Kimi, DeepSeek, GLM, Qwen, MiniMax) | Zero real usage data; returns `tokensUsed: 0` always |
| 5 | Debug network log viewer (from main nav) | Developer tool; hide behind opt+click |
| 6 | Shortcuts settings page | No real shortcuts to configure |
| 7 | Limit optimization guide (standalone page) | Tips served inline via ContextualTipCard |
| 8 | Session planning (standalone page) | Merged into Notifications |

### Deferred (Keep feature flags, no UI)

| # | Feature | Reason |
|---|---------|--------|
| 1 | Weekly digest | Not implemented |
| 2 | Team tier (all 5 features) | Not implemented — requires real Paddle + webhooks |
| 3 | Referral program | Not implemented |
| 4 | Claude status indicator (from popover) | Right-click menu only |

### Keep (Functional)

| # | Feature | Location in New Design |
|---|---------|----------------------|
| 1 | Usage ring + percentage | Popover Card 1 |
| 2 | Reset countdown | Popover Card 2 |
| 3 | Burn rate prediction (Pro) | Popover Card 3 |
| 4 | Cost transparency (Pro) | Popover Details |
| 5 | Contextual tips | Popover Card 4 |
| 6 | Session breakdown (Pro) | Popover Details |
| 7 | Context window tracker (Pro) | Popover Details |
| 8 | Predictive throttling (Pro) | Popover Details |
| 9 | Multi-AI dashboard (Pro, 4 providers) | Popover Details |
| 10 | API cost (Claude API Console) | Popover Details |
| 11 | Usage history export (Pro) | Settings > Profiles |
| 12 | Custom thresholds (Pro) | Settings > Notifications |
| 13 | Advanced icon styles (Pro) | Settings > Appearance |
| 14 | Unlimited profiles (Pro) | Settings > Profiles |
| 15 | Smart notifications (Pro) | Settings > Notifications |
| 16 | Cross-profile dashboard (Pro) | Popover Details (compact) |

---

## Part 6: Provider Cleanup

### Keep (Real APIs, Functional)

| Provider | Auth | Data Quality | Status |
|----------|------|-------------|--------|
| Claude | Session key / CLI OAuth | Full session + weekly + API billing | **Production** |
| Codex | API key | Model validation; billing (admin-only) | **Partial** — requires admin key for real data |
| Gemini | OAuth or API key | Model validation; Cloud Monitoring (needs GCP project ID) | **Partial** — needs project ID for real data |
| Copilot | OAuth or PAT | User profile + plan detection; org billing (admin-only) | **Partial** — shows plan type, no usage for non-admin |

### Hide (No Real Data)

| Provider | What It Returns | Action |
|----------|----------------|--------|
| Kimi | `tokensUsed: 0` (model list only) | Hide from UI; keep service code |
| DeepSeek | `tokensUsed: 0` + account balance | Hide from UI; keep service code (balance endpoint is useful) |
| GLM | `tokensUsed: 0` (model list only) | Hide from UI; keep service code |
| Qwen | `tokensUsed: 0` (model list only) | Hide from UI; keep service code |
| MiniMax | `tokensUsed: 0` (key format check only) | Hide from UI; keep service code |

### UI Changes
- `AIProvider.allCases` → filtered to `[.claude, .codex, .gemini, .copilot]` for UI rendering
- Keep full `allCases` for internal data model
- `ProvidersSidebarSection` removed from sidebar entirely
- Provider management moves to Settings > Credentials page

---

## Part 7: Monetization UX — Contextual Upsells, Not Feature Gates

### Current Approach (Anti-Pattern)
- 13 Pro features locked behind `FeatureFlags.isAvailable()`
- Users see lock icons on 8 of 9 providers in the sidebar
- Burn rate card shows fake prediction text "Upgrade to Pro for predictions"
- `ProUpsellBanner` always visible in popover for free users
- Result: The app feels broken. Users are constantly reminded of what they CAN'T do.

### Redesigned Approach (Apple-Style)
1. **The free product is COMPLETE.** It tracks Claude usage, shows percentage, shows reset time. It's genuinely useful on its own.
2. **Pro features are revealed contextually, not listed.** When usage hits 80%, show: "Want to know when you'll hit your limit? Pro predicts your burn rate." — with an [Upgrade] button.
3. **No lock icons in the main UI.** Free users see only what they can use. Pro features appear as natural extensions, not padlocked doors.
4. **One upgrade path.** Settings > Account has a single clear "Upgrade to Pro" button. No scattered upsell cards throughout the app.
5. **Clear value proposition.** The Pro upgrade page lists EXACTLY what you get, with real numbers: "Pro users save an average of 3 hours/week by avoiding limit surprises."

### Feature Flags to Retain (Simplified)
```swift
// Keep only these gates:
.unlimitedProfiles     // Free: 2 profiles max
.burnRatePredictor     // Free: hidden (not fake data)
.costTransparency      // Free: hidden
.multiAI               // Free: Claude only
.customThresholds      // Free: fixed 75/90/95
.advancedIconStyles    // Free: ring only
.usageHistoryExport    // Free: 7-day retention, no export

// Remove these gates (merged or deferred):
// .smartNotifications — always contextual, just simpler on Free
// .perSessionBreakdown — always tracked, shown in Details
// .crossProfileDashboard — always shown (if >1 profile)
// .contextWindowTracker — always shown (if using Claude Code)
// .predictiveThrottling — merged into burn rate
// .weeklyDigest — deferred
```

---

## Part 8: Files to Create / Modify / Delete

### New Files
| File | Purpose |
|------|---------|
| `Views/Onboarding/WelcomeView.swift` | Screen 1 of onboarding |
| `Views/Onboarding/SetupMethodView.swift` | Screen 2 of onboarding |
| `Views/Onboarding/CredentialSetupView.swift` | Screen 3 of onboarding |
| `Views/Popover/UsageRingCard.swift` | Large centered donut chart |
| `Views/Popover/ResetCountdownCard.swift` | Human-readable reset countdown |
| `Views/Popover/BurnRateTeaserCard.swift` | Contextual Pro upsell for burn rate |
| `Views/Popover/DetailsDisclosure.swift` | Collapsible section for Pro detail cards |
| `Views/Settings/GeneralSettingsView.swift` | Rewritten: launch, updates, language, reset |
| `Views/Settings/ProfilesSettingsView.swift` | Rewritten: profile list + management |
| `Views/Settings/CredentialsSettingsView.swift` | Merged: all credential forms for all providers |
| `Views/Settings/NotificationsSettingsView.swift` | Merged: thresholds + smart + session planning |
| `Views/Settings/AppearanceSettingsView.swift` | Rewritten: icon style + color scheme |
| `Views/Settings/AccountSettingsView.swift` | Merged: license, upgrade, about, support |

### Modified Files
| File | Changes |
|------|---------|
| `App/AppDelegate.swift` | Trigger new onboarding flow; remove legacy prompts |
| `MenuBar/PopoverContentView.swift` | Complete rewrite to 5-card layout |
| `MenuBar/MenuBarManager.swift` | Simplify icon rendering to ring-only for free tier |
| `Views/SettingsView.swift` | Collapse `SettingsSection` enum from 18 to 6 cases; new sidebar |
| `Shared/Services/FeatureFlags.swift` | Remove 7 feature gates; simplify registry |
| `Shared/Models/AIProvider.swift` | Add `isShownInUI: Bool` computed property |
| `Shared/Services/MultiAIService.swift` | Filter to 4 active providers for UI |
| `Views/Settings/App/AIProvidersSettingsView.swift` | Rewrite for 4 providers only |
| `Views/Settings/Components/ProUpsellCard.swift` | Redesign for contextual upsell pattern |
| `MenuBar/MenuBarIconRenderer.swift` | Simplify: ring is default, other styles Pro-only |

### Deleted Files
| File | Reason |
|------|--------|
| `Views/Settings/App/MobileAppView.swift` | Painted door — no real mobile app |
| `Views/GitHubStarPromptView.swift` | Closed source — no repo to star |
| `Views/FeedbackPromptView.swift` | Replaced by Account > Support |
| `Views/Settings/App/ShortcutsSettingsView.swift` | No real shortcuts |
| `Views/Settings/App/PopoverSettingsView.swift` | Merged into Appearance |
| `Views/Settings/App/UpdatesSettingsView.swift` | Merged into General |
| `Views/Settings/App/LanguageSettingsView.swift` | Merged into General |
| `Views/Settings/Profile/SessionPlanningSettingsView.swift` | Merged into Notifications |
| `Views/Settings/Profile/LimitOptimizationGuideView.swift` | Tips served inline via ContextualTipCard |
| `Views/Settings/App/DebugNetworkLogView.swift` | Hide behind opt+click gesture instead |

---

## Part 9: Implementation Order (Phases)

### Phase 1: Onboarding (Highest Impact, Most Self-Contained)
1. Create 3 new onboarding views
2. Rewrite `SetupWizardView` to use new flow
3. Remove legacy migration prompt from wizard
4. Update `AppDelegate` to trigger new flow
5. **Validation:** Fresh install → see 3-screen welcome → complete setup → popover shows usage

### Phase 2: Popover Redesign (Core UX)
1. Create `UsageRingCard`, `ResetCountdownCard`, `BurnRateTeaserCard`, `DetailsDisclosure`
2. Rewrite `PopoverContentView` to 5-card layout
3. Move Pro cards into Details disclosure
4. Remove `ProUpsellBanner`, status banners, multi-profile tag, overlap card from main view
5. **Validation:** Click menu bar → see ring + countdown + tip → tap Details → see Pro cards

### Phase 3: Settings Restructure
1. Collapse `SettingsSection` enum from 18 to 6
2. Create 6 new settings views
3. Rewrite `SettingsView` sidebar
4. Merge credential views into single `CredentialsSettingsView`
5. Move debug log viewer behind opt+click gesture
6. **Validation:** Open Settings → see 6 groups → navigate each → all settings functional

### Phase 4: Provider Cleanup
1. Add `isShownInUI` to `AIProvider`
2. Filter provider lists to 4 in all UI code
3. Remove `ProvidersSidebarSection` from sidebar
4. Rewrite `AIProvidersSettingsView` for 4 providers
5. **Validation:** Settings → Credentials → see only Claude, Codex, Gemini, Copilot

### Phase 5: Feature Flag Simplification
1. Remove 7 feature flags (smartNotifications, perSessionBreakdown, crossProfileDashboard, contextWindowTracker, predictiveThrottling, weeklyDigest, teamDashboard/budgetAlerts/adminControls/aggregateReporting/sso)
2. Update all `FeatureFlags.isAvailable()` calls to use simplified set
3. Remove dead-end upsell patterns; replace with contextual teasers
4. **Validation:** Free tier → no lock icons in popover → Pro features appear contextually

### Phase 6: Polish & Cleanup
1. Delete 10 obsolete view files
2. Update localization keys for new strings
3. Update `AGENTS.md` with new architecture
4. Build Release DMG + test on clean machine
5. **Validation:** Full smoke test: install → onboard → use → settings → update

---

## Part 10: Open Questions & Risks

### Unresolved Design Decisions

1. **DeepSeek balance endpoint** — DeepSeek is the only Chinese provider that returns real data (account balance). Should we keep it in the UI despite no usage data? **Recommendation:** Hide it with the others. A balance-only provider is confusing. Re-add all 5 when real usage APIs are implemented.

2. **Codex/Gemini/Copilot partial data** — These 3 providers return partial or admin-only data. Should we show a "limited data" badge? **Recommendation:** Yes. Show a subtle "Limited" badge on providers that can't return full usage, with a tooltip explaining why.

3. **Claude status indicator** — Currently in popover header (status.claude.com). Useful but not core. **Recommendation:** Move to right-click menu. If Claude is down, show a small ⚠️ in the menu bar icon instead.

4. **Session planning / overlap** — Niche feature for people who schedule work sessions. **Recommendation:** Merge into Notifications as a toggle. Default off.

5. **HeartbeatService** — Anonymous 24h analytics ping. Keep? **Recommendation:** Keep but add a toggle in Settings > General (on by default, opt-out).

### Risks

| Risk | Mitigation |
|------|-----------|
| Removing providers breaks existing Pro users who connected them | Keep service code and data models intact; just hide from UI. Existing stored credentials still work if re-enabled. |
| Radical simplification alienates power users | Details disclosure keeps all Pro cards accessible. Power users can still see everything — it's just not the default view. |
| Onboarding rewrite introduces credential bugs | Keep existing `ClaudeAPIService.testSessionKey()` and `ClaudeCodeSyncService` paths unchanged. Only change the UI layer. |
| Paddle stub means Pro features unlock for anyone | This is a pre-existing issue. The redesign doesn't change LicenseManager behavior. Real Paddle SDK is a separate task. |

---

## Part 11: Success Metrics

Post-redesign, the app should deliver:

1. **Time-to-value:** New user sees their usage within 60 seconds of opening the app
2. **Glanceability:** Current usage state is understood in <2 seconds from the menu bar
3. **Zero dead clicks:** Every tappable element leads to either an action or a clear "why this is Pro" explanation
4. **Settings findability:** Any setting reachable in ≤2 clicks from the sidebar
5. **No "what does this do?" moments:** Every UI element has a self-evident purpose

---

## Implementation Notes for the Agent

1. **Do NOT delete service code** for Chinese providers. Only hide them from UI. Keep `KimiAPIService.swift`, `DeepSeekAPIService.swift`, etc. intact.
2. **Do NOT change `LicenseManager`** — the Paddle stub is a separate concern.
3. **Preserve all localization infrastructure** — 12 locale files need new keys but the system stays.
4. **Keep `AppTheme` design tokens** — they are used throughout and work well. This is a layout/flow redesign, not a visual redesign.
5. **The `SettingsComponents.swift` primitives** (`SettingsSectionCard`, `SettingsCard`, etc.) should be reused in new settings views.
6. **Do not modify `OAuthTokenStore`, `OAuthFlowCoordinator`, or any OAuth infrastructure** — it works correctly and is only hidden/reshown differently.
