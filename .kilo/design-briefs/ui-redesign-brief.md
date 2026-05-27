# Claude Usage Tracker — UI Redesign Brief

## App Context

- **Platform:** macOS 14.0+ menu bar app (SwiftUI)
- **App Type:** Background utility that lives in the menu bar, tracking AI usage across multiple providers
- **Current Problem:** UI matches the old open-source version (2.5k GitHub stars). Needs a premium, polished look that matches the paid Pro/Team tier model ($4.99/mo, $9.99/user/mo).
- **Design Goal:** Clean, modern, native macOS feel. Think "Raycast meets Apple System Settings." Dark mode first, light mode supported.
- **Size Constraints:** Most surfaces are compact — popovers (~320px wide), settings window (~700x500px), sheets (~400px wide).

---

## Screen Inventory (35+ screens)

### 1. Menu Bar Icon
- **Current:** Custom-rendered SF Symbols with color overlays
- **Needs redesign:** The icon itself (16x16pt, 18x18pt, 22x22pt). Should feel like a native macOS utility. Consider a stylized gauge/meter or abstract "C" shape that works in monochrome and color.
- **States:** Normal, Warning (orange), Critical (red), Disconnected (gray), Multi-profile indicator.

### 2. Main Popover (`MenuBar/PopoverContentView.swift`)
- **Size:** ~320px wide, height varies
- **Current layout:** VStack with usage cards, progress bar, info rows, quick actions, footer
- **Needs redesign:**
  - Header with profile name + AI provider icon
  - Large circular/radial progress indicator for usage percentage
  - Token count with large typography
  - Burn rate prediction card ("You'll hit the limit in 23 min")
  - Cost transparency card (API-equivalent cost)
  - Smart notification preview
  - Quick action buttons (Open Claude, Refresh, Settings)
  - Session planning card (if enabled)
  - Context window tracker (if enabled)
  - Predictive throttling indicator
  - Multi-AI provider mini-dashboard
  - Footer with "Last updated" timestamp
- **Empty state:** "No usage data yet" with setup prompt
- **Error state:** Disconnected with retry button

### 3. Cross-Profile Dashboard (`MenuBar/CrossProfileDashboard.swift`)
- **Context:** Shown when multiple profiles are active
- **Current:** List of profiles with token counts
- **Needs redesign:** Grid or list view showing all profiles side-by-side. Aggregate totals at top. Each profile card shows: name, provider icon, usage bar, token count.

### 4. Setup Wizard (`Views/SetupWizardView.swift`)
- **Context:** First-launch onboarding flow
- **Current:** Multi-step wizard (Welcome → Language → Profile setup → Claude.ai auth → Done)
- **Needs redesign:**
  - Step 1: Welcome screen with app icon + tagline + "Get Started"
  - Step 2: Language picker (12 languages)
  - Step 3: Profile name input
  - Step 4: Claude.ai authentication — "Sign in to Claude.ai" prominent button + manual key fallback
  - Step 5: "You're all set!" with quick tips
- **Style:** Full-screen modal overlay, clean white/dark background, large friendly typography

### 5. Settings Window (`Views/SettingsView.swift`)
- **Size:** ~700x500px
- **Current:** Sidebar navigation (3 sections) + content area
- **Needs redesign:**
  - Left sidebar: 3 collapsible sections (App, Profile, Credentials) with icons
  - Content area: Clean scrollable panels with cards
  - Window chrome: Native macOS traffic lights, no custom title bar
  - Active item highlighting in sidebar

#### Settings — App Section

**5a. App Settings (`Views/Settings/App/AppSettingsView.swift`)**
- Launch at login toggle
- Language selector dropdown
- Auto-refresh interval slider
- Check for updates button
- Reset app data (destructive, red button)

**5b. Pro Features / License (`Views/Settings/App/ProFeaturesView.swift`)**
- Current tier badge (Free/Pro/Team) with color coding
- Feature grid: 8 features with lock/unlock icons
- Pricing card: "$4.99/mo or $39.99/year" with upgrade CTA
- License activation: "Already have a license?" → opens activation sheet
- **Activation Sheet:** License key input (XXXX-XXXX-XXXX-XXXX), validate button, error state

**5c. AI Providers (`Views/Settings/App/AIProvidersSettingsView.swift`)**
- 9 provider cards in a grid/list:
  - Claude (free tier — always available)
  - OpenAI Codex (Pro lock)
  - Google Gemini (Pro lock + OAuth)
  - GitHub Copilot (Pro lock + OAuth)
  - Kimi, DeepSeek, GLM, Qwen, MiniMax (all Pro lock)
- Each card: Provider icon, name, connection status, usage count, "Connect" or "Connected" badge
- **OAuth sheets:** "Sign in with Google/GitHub" branded buttons + manual API key fallback
- **API Key sheets:** Secure text field, project/org ID fields, test connection button, save/cancel

**5d. Manage Profiles (`Views/Settings/App/ManageProfilesView.swift`)**
- List of profiles with: name, active indicator, usage summary
- Edit/delete actions per profile
- "Create New Profile" button (gated — free tier shows "Upgrade to Pro" upsell)
- Multi-profile display mode toggle
- **Create Profile Sheet:** Name input, icon picker, create button

**5e. About (`Views/Settings/App/AboutView.swift`)**
- App icon + version number
- Creator credit (clickable GitHub link)
- Contributors grid (avatars from GitHub API)
- Links: GitHub repo, Report issue, Send feedback, Run setup wizard, Reset app data
- MIT license text
- Check for updates button

**5f. Support / Upgrade (`Views/Settings/App/SupportView.swift`)**
- Heart icon with gradient
- "Why support us" bullet points (features free, open source, no tracking)
- Buy Me a Coffee button (yellow branded)
- Pro upgrade CTA (purple accent)

**5g. Claude Code (`Views/Settings/App/ClaudeCodeView.swift`)**
- Statusline integration preview (live terminal-style preview)
- Toggle grid: show model, directory, branch, context, usage, progress bar, etc. (~15 toggles)
- Color mode picker (monochrome/multi-color)
- Element color pickers
- Install/Uninstall statusline scripts button

**5h. Shortcuts (`Views/Settings/App/ShortcutsSettingsView.swift`)**
- 4 shortcut rows: Toggle popover, Refresh, Open settings, Next profile
- Each row: Action name, description, key combo recorder (click to record new shortcut)

**5i. Updates (`Views/Settings/App/UpdatesSettingsView.swift`)**
- Auto-check toggle
- Last checked timestamp
- Check now button
- Sparkle update channel info

**5j. Mobile App (`Views/Settings/App/MobileAppView.swift`)**
- QR code for iOS app download
- Feature list
- App Store link

**5k. Popover Settings (`Views/Settings/App/PopoverSettingsView.swift`)**
- Show/hide toggles for each popover section
- Reordering UI for sections

**5l. Language (`Views/Settings/App/LanguageSettingsView.swift`)**
- List of 12 languages with flags
- Current selection highlight

**5m. Debug Network Log (`Views/Settings/App/DebugNetworkLogView.swift`)**
- Table of API requests with timestamp, endpoint, status, duration
- Filter by status
- Clear log button

#### Settings — Profile Section

**5n. General Settings (`Views/Settings/Profile/GeneralSettingsView.swift`)**
- Profile name input
- Icon/avatar picker
- Delete profile button (destructive)

**5o. Usage History (`Views/Settings/Profile/UsageHistoryView.swift`)**
- Time scale picker: 5h, 24h, 7d, 30d
- Charts: Token usage over time (Swift Charts — line/bar area)
- Statistics cards: Total tokens, avg per day, peak usage, estimated cost
- Export button (JSON/CSV) — opens date range sheet
- **Date Range Export Sheet:** Start date, end date picker, format picker, export button

**5p. Appearance (`Views/Settings/Profile/AppearanceSettingsView.swift`)**
- Monochrome toggle
- Show icon labels toggle
- Show remaining percentage toggle
- Icon style picker (basic styles for free, advanced for Pro)
- Color preview

**5q. Session Planning (`Views/Settings/Profile/SessionPlanningSettingsView.swift`)**
- Target tokens input
- Duration input
- Estimated completion time
- Smart suggestions toggle

**5r. Limit Optimization Guide (`Views/Settings/Profile/LimitOptimizationGuideView.swift`)**
- Scrollable guide with tips for staying under limits
- Best practices cards
- Peak hours chart

#### Settings — Credentials Section

**5s. Personal Usage — Claude.ai (`Views/Settings/Credentials/PersonalUsageView.swift`)**
- Connection status card (green dot + key mask)
- 3-step wizard:
  - Step 1: "Sign in to Claude.ai" browser button OR manual session key input + test button
  - Step 2: Organization selector (radio button list)
  - Step 3: Review + Save
- Validation states: success (green), error (red), loading (spinner)
- Remove credentials button

**5t. API Billing — Console (`Views/Settings/Credentials/APIBillingView.swift`)**
- Same 3-step wizard pattern as Personal Usage
- API Console session key input
- Organization selector
- Expiry date warning (orange/red if expired)

**5u. CLI Account (`Views/Settings/Credentials/CLIAccountView.swift`)**
- Sync status (synced/not synced)
- "Sync from Claude Code CLI" button
- Credentials display (masked JSON)
- Last synced relative time
- Remove button
- **Console Auth Sheet:** Embedded web view for claude.ai/login, cookie extraction, success/cancel callbacks

### 6. Feedback Prompt (`Views/FeedbackPromptView.swift`)
- **Size:** ~380px wide modal
- **Current:** Name, role picker, email, message fields + submit button
- **Needs redesign:** Clean modal with header icon, form fields with rounded backgrounds, submit button, "Remind later" and "Don't ask again" secondary actions
- **Thanks state:** Heart icon + "Thank you!" + close button

### 7. GitHub Star Prompt (`Views/GitHubStarPromptView.swift`)
- **Size:** ~400px modal window
- Star button, remind later, don't ask again

### 8. Error Presenter (`Shared/ErrorHandling/ErrorPresenter.swift`)
- **NSAlert sheets:** Standard macOS alert dialogs for errors
- Error code display, retry button, dismiss button

---

## Shared Components (Reusable Across Screens)

### Cards
- `SettingsContentCard` — Bordered rounded card with padding
- `ProUpsellCard` — Purple gradient border, upgrade CTA
- `SettingsSectionCard` — Card with title + subtitle header

### Form Elements
- `SecureFieldRow` — Label + secure text field
- `TextFieldRow` — Label + text field
- `SettingToggle` — Label + description + toggle switch
- `SettingsButton` — Icon + title button with style variants (primary, secondary, destructive)

### Data Display
- `UsageCharts` — Swift Charts line/area/bar views
- `AggregateMetric` — Icon + label + value
- `ProfileRow` — Avatar + name + status + actions
- `ContributorAvatar` — Async loaded circular image

### Navigation
- `SettingsPageHeader` — Title + subtitle for each settings screen
- `LinkButton` — Icon + text + external link arrow
- `FeatureRow` — Icon + title + description + lock badge

---

## Design System Requirements

### Colors
- **Background:** System window background (light: #F5F5F7, dark: #1E1E1E)
- **Card background:** Slightly elevated (light: #FFFFFF, dark: #2D2D2D)
- **Card border:** Subtle separator (light: #E5E5E5, dark: #3D3D3D)
- **Accent:** System accent color (blue by default)
- **Success:** #34C759 (green)
- **Warning:** #FF9500 (orange)
- **Error:** #FF3B30 (red)
- **Pro accent:** #AF52DE (purple)
- **Text primary:** System primary
- **Text secondary:** System secondary

### Typography
- Page title: 18px semibold
- Section title: 13px semibold, secondary color
- Body: 13px regular
- Caption: 11px regular, secondary color
- Monospace (for keys): 12px SF Mono

### Spacing
- Card padding: 16px
- Section spacing: 20px
- Small spacing: 8px
- Icon size: 16px standard, 20px large

### Icons
- Use SF Symbols throughout (outline style preferred)
- Provider icons: Custom or SF Symbol alternatives
- Status indicators: Green/orange/red circles (8pt)

---

## Key Design Principles for Designers

1. **Compact but readable** — Menu bar popover is only 320px. Information hierarchy is critical.
2. **Progressive disclosure** — Free tier shows limited data; Pro features show as locked/preview states, not hidden.
3. **Native macOS feel** — Follow Apple Human Interface Guidelines. No custom window chrome. Use system materials.
4. **Dark mode first** — Menu bar apps are often used in dark mode. Ensure contrast ratios pass.
5. **Animation opportunities** — Progress bars, number counting, chart transitions, wizard step transitions.
6. **Error resilience** — Every screen needs graceful error/empty/disconnected states.
7. **Accessibility** — Support VoiceOver, Dynamic Type (where possible), sufficient color contrast.

---

## Source File Locations for Reference

All current implementations are in:
- `Claude Usage/MenuBar/*.swift`
- `Claude Usage/Views/*.swift`
- `Claude Usage/Views/Settings/**/*.swift`
