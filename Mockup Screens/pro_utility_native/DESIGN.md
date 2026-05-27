---
name: Pro-Utility Native
colors:
  surface: '#10131b'
  surface-dim: '#10131b'
  surface-bright: '#363942'
  surface-container-lowest: '#0b0e16'
  surface-container-low: '#181c23'
  surface-container: '#1c2028'
  surface-container-high: '#272a32'
  surface-container-highest: '#31353d'
  on-surface: '#e0e2ed'
  on-surface-variant: '#c1c6d7'
  inverse-surface: '#e0e2ed'
  inverse-on-surface: '#2d3039'
  outline: '#8b90a0'
  outline-variant: '#414755'
  surface-tint: '#adc6ff'
  primary: '#adc6ff'
  on-primary: '#002e69'
  primary-container: '#4b8eff'
  on-primary-container: '#00285c'
  inverse-primary: '#005bc1'
  secondary: '#e8b3ff'
  on-secondary: '#510074'
  secondary-container: '#7508a5'
  on-secondary-container: '#e19fff'
  tertiary: '#ffb595'
  on-tertiary: '#571e00'
  tertiary-container: '#ef6719'
  on-tertiary-container: '#4c1a00'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#d8e2ff'
  primary-fixed-dim: '#adc6ff'
  on-primary-fixed: '#001a41'
  on-primary-fixed-variant: '#004493'
  secondary-fixed: '#f6d9ff'
  secondary-fixed-dim: '#e8b3ff'
  on-secondary-fixed: '#310048'
  on-secondary-fixed-variant: '#7201a2'
  tertiary-fixed: '#ffdbcc'
  tertiary-fixed-dim: '#ffb595'
  on-tertiary-fixed: '#351000'
  on-tertiary-fixed-variant: '#7c2e00'
  background: '#10131b'
  on-background: '#e0e2ed'
  surface-variant: '#31353d'
typography:
  page-title:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
    letterSpacing: -0.015em
  section-header:
    fontFamily: Inter
    fontSize: 13px
    fontWeight: '600'
    lineHeight: 18px
    letterSpacing: -0.01em
  body:
    fontFamily: Inter
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 18px
    letterSpacing: -0.005em
  body-semibold:
    fontFamily: Inter
    fontSize: 13px
    fontWeight: '600'
    lineHeight: 18px
  caption:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '400'
    lineHeight: 14px
    letterSpacing: 0.01em
  key-mono:
    fontFamily: JetBrains Mono
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  xxs: 4px
  xs: 8px
  sm: 12px
  md: 16px
  lg: 24px
  xl: 32px
  gutter: 12px
  margin: 16px
---

## Brand & Style
The design system is engineered for a utility-first experience that feels like a first-party extension of macOS. It adopts a **Corporate Modern** style with heavy influences from **Glassmorphism** and the refined density of Raycast. The UI targets power users who value precision, system integration, and data density.

The aesthetic is "Apple-authentic": it prioritizes clarity and functional beauty over decorative flair. The interface utilizes a rigorous hierarchy of surfaces to organize information without adding visual bulk, ensuring that complex usage data remains digestible at a glance.

## Colors
The palette is rooted in the macOS system color space. While the default mode is Dark, the system maintains high legibility in Light mode.

- **Primary (Blue):** Used for standard system actions and primary focus states.
- **Secondary (Pro Purple):** Specifically reserved for "Pro" features, limits, or premium subscription indicators.
- **Semantic Colors:** Green, Orange, and Red are used strictly for status indicators (Success, Warning, Error) and progress thresholds.
- **Surfaces:** Dark mode uses a tiered grey scale to create depth. Surfaces are never pure black, ensuring that subtle borders and shadows remain visible.

## Typography
The typography utilizes the system font stack (Inter/SF Pro) for seamless OS integration. It follows a compact scale optimized for utility windows and menu bar flyouts.

- **Scale:** High density is maintained by using 13px as the primary body size, matching macOS System Settings.
- **Mono:** Used for technical data, API keys, token counts, and timestamps to ensure character alignment and a "developer-tool" feel.
- **Tracking:** Tighten tracking slightly for headlines and loosen it for captions to maintain readability at small scales.

## Layout & Spacing
The layout philosophy is built on a **Fixed Grid** model within containerized cards. Since this is a utility app, the layout must be responsive to small window sizes (e.g., a 380px wide sidebar or popover).

- **Margins:** 16px global padding for main window containers.
- **Gaps:** 12px between primary cards, 8px between elements inside a card.
- **Alignment:** Use a strict baseline grid to ensure text across columns aligns perfectly, emphasizing the "Pro" tool precision.
- **Density:** Provide "Compact" and "Comfortable" views; Compact reduces vertical padding by 4px across all components.

## Elevation & Depth
This design system uses **Tonal Layers** and **Low-Contrast Outlines** rather than heavy shadows to define hierarchy.

- **Level 0 (Background):** The base app canvas (#1E1E1E).
- **Level 1 (Card):** Elevated surface (#2D2D2D) with a 1px solid border (#3D3D3D).
- **Level 2 (In-app Overlays):** Modals or popovers use a subtle background blur (20px) and a slightly brighter border (#4D4D4D) to suggest they are closer to the user.
- **Shadows:** Only used on active dropdowns or floating context menus—extremely diffused (20px blur, 20% opacity black) with no offset.

## Shapes
The shape language is consistently rounded to match the modern macOS container style.

- **Primary Cards:** 12px to 16px corner radius depending on the container size.
- **Buttons/Inputs:** 6px radius for a precise, "clickable" feel.
- **Selections/Highlighters:** 4px radius for list item hover states.
- **Progress Indicators:** Circular elements should use the "Pro" purple or system blue with a rounded stroke-cap for a high-fidelity appearance.

## Components

### Buttons & Inputs
- **Primary Button:** Solid Blue or Purple background with white text.
- **Secondary Button:** Surface-colored background with a subtle border.
- **Input Fields:** Inset appearance with a 1px border. Focus state uses a 2px blue/purple glow (ring).

### Cards
- Always use the 1px border (#3D3D3D). 
- Headers inside cards should use `section-header` typography with a subtle divider separating the content.

### Progress Indicators
- **Radial Charts:** Used for token usage. Use a thick track (4px) with a background "track" color of #3D3D3D.
- **Linear Bars:** For sub-limits, with a "glow" effect in the color of the accent when usage exceeds 80%.

### Lists & Navigation
- **Sidebar Items:** Clear hover state with a 4px rounded highlight. Icons are always SF Symbols (Outline weight).
- **Key-Value Pairs:** Labels in `caption` (muted grey), values in `body-semibold` or `key-mono`.

### Chips & Badges
- Used for status (e.g., "Active", "Syncing"). Small, pill-shaped, with a subtle background tint of the semantic color and a high-contrast label.