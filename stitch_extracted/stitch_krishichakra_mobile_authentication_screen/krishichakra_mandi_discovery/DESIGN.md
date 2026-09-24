---
name: KrishiChakra Mandi Discovery
colors:
  surface: '#faf8ff'
  surface-dim: '#d2d9f4'
  surface-bright: '#faf8ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f2f3ff'
  surface-container: '#eaedff'
  surface-container-high: '#e2e7ff'
  surface-container-highest: '#dae2fd'
  on-surface: '#131b2e'
  on-surface-variant: '#41493e'
  inverse-surface: '#283044'
  inverse-on-surface: '#eef0ff'
  outline: '#717a6d'
  outline-variant: '#c0c9bb'
  surface-tint: '#2a6b2c'
  primary: '#00450d'
  on-primary: '#ffffff'
  primary-container: '#1b5e20'
  on-primary-container: '#90d689'
  inverse-primary: '#91d78a'
  secondary: '#006c49'
  on-secondary: '#ffffff'
  secondary-container: '#6cf8bb'
  on-secondary-container: '#00714d'
  tertiary: '#5c2f00'
  on-tertiary: '#ffffff'
  tertiary-container: '#7e4200'
  on-tertiary-container: '#ffb579'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#acf4a4'
  primary-fixed-dim: '#91d78a'
  on-primary-fixed: '#002203'
  on-primary-fixed-variant: '#0c5216'
  secondary-fixed: '#6ffbbe'
  secondary-fixed-dim: '#4edea3'
  on-secondary-fixed: '#002113'
  on-secondary-fixed-variant: '#005236'
  tertiary-fixed: '#ffdcc3'
  tertiary-fixed-dim: '#ffb77d'
  on-tertiary-fixed: '#2f1500'
  on-tertiary-fixed-variant: '#6e3900'
  background: '#faf8ff'
  on-background: '#131b2e'
  surface-variant: '#dae2fd'
typography:
  display-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 36px
    fontWeight: '800'
    lineHeight: 44px
  display-lg-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 28px
    fontWeight: '800'
    lineHeight: 36px
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 20px
    fontWeight: '700'
    lineHeight: 28px
  headline-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 26px
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 18px
    fontWeight: '500'
    lineHeight: 28px
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '700'
    lineHeight: 24px
  label-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
  label-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '700'
    lineHeight: 16px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  gutter-tablet: 1.5rem
  gutter-desktop: 2rem
  margin: 1rem
  margin-tablet: 2rem
  margin-desktop: 3rem
  space-xs: 0.5rem
  space-sm: 0.75rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2.5rem
---

## Brand & Style
This design system is engineered for rural agricultural trade, real-time mandi price discovery, and multi-lingual accessibility under extreme outdoor light conditions. It serves farmers, local traders (arhtiyas), and agri-logistics coordinators who demand immediate legibility, zero operational friction, and resilient touch interfaces.

The aesthetic fuses **Tactile Utilitarianism** with **Modern Accessibility**:
- High clarity and visual separation without decorative clutter.
- Resilient daylight contrast to remain legible under direct midday sun in field environments.
- Tactile reassurance through substantial tap targets (minimum 56px), explicit active states, and persistent assistive audio triggers to empower non-literate and neo-literate operators.
- Clean white structural planes paired with deep agrarian greens, active emerald signifiers, and high-visibility amber harvest indicators.

## Colors
The palette uses high-contrast natural earth and foliage tones balanced with calibrated structural neutrals to ensure compliance with WCAG AAA accessibility standards.

### Palette Architecture
- **Primary (`#1B5E20`)**: Deep Forest Green. Establishes institutional reliability, primary action hierarchy, and solid top-level navigation bars. An interactive step-up shade (`#2E7D32`) governs hover and focus states.
- **Secondary (`#10B981`)**: Emerald Accent. Denotes real-time active status, successful price discoveries, upward trend indicators, and highlighted assistive functions.
- **Tertiary (`#D97706`)**: Warm Amber. Anchors crop-grade tags, commodity status, live auction timers, and vital market warnings without inducing panic.
- **Neutral Primary (`#0F172A`)**: Dark Slate. Renders all headlines, numeric values, and primary metrics for maximum contrast against light surfaces.
- **Neutral Muted (`#334155`)**: Slate Muted. Reserved for descriptive labels, auxiliary mandi locations, and secondary data strings.
- **Surface Canvas (`#F8FAFC`)**: Soft cool white base to mitigate glare outdoors.
- **Surface Card (`#FFFFFF`)**: Pure crisp card faces to prioritize reading scanpaths.
- **Borders & Dividers (`#E2E8F0`)**: Crisp, low-noise architectural containment lines.

## Typography
Plus Jakarta Sans is selected across all roles for its wide apertures, distinct numeral forms, and geometric clarity under varied screen resolutions and glare.

### Typographic Rules
- **Base Sizing**: The minimum readable body size for standard interactions is set to `16px` (`body-md`), preserving readability for users holding mobile devices at arm's length in open fields.
- **Numbers & Rates**: Mandi commodity prices, quintal rates, and volume metrics must strictly use `headline-lg` or `headline-md` with `fontWeight: 700` to prevent misreading numerical values.
- **Bilingual & Transliterated Strings**: Vertical line-height multipliers are maintained at a minimum of `1.4x` to accommodate multi-script diacritics without vertical clipping.

## Layout & Spacing
The layout system enforces an outdoor-friendly, fluid-column grid prioritizing single-thumb reachable zones and high spatial separation between interactive components.

### Grid & Breakpoints
- **Mobile (`< 640px`)**: 4-column fluid grid. Outer margins are fixed at `1rem` (`16px`) with `1rem` gutters. Interactive actions aggregate toward a bottom thumb-zone dock.
- **Tablet (`640px - 1024px`)**: 8-column fluid grid. Outer margins scale to `2rem` (`32px`) with `1.5rem` gutters.
- **Desktop (`> 1024px`)**: 12-column fixed-max grid (max-width `1280px`). Outer margins expand to `3rem` (`48px`) centered on canvas.

### Touch Target Mandate
All interactive components—including inputs, list items, chips, and audio helpers—must have a minimum height and hit box of `56px` (`3.5rem`). Non-interactive vertical margins use `space-md` (`1rem`) to prevent accidental adjacent tap events.

## Elevation & Depth
This design system prioritizes high-contrast structural containment over heavy atmospheric drop shadows, which wash out in bright ambient environments.

### Depth Hierarchy
- **Level 0 (Flat Canvas)**: Hex `#F8FAFC` base background.
- **Level 1 (Card & Row Surfaces)**: Hex `#FFFFFF` with a crisp `1px` structural border of `#E2E8F0`. Shadow is faint and diffuse: `0 1px 3px rgba(15, 23, 42, 0.06)`.
- **Level 2 (Interactive Floating Elements & Audio Pills)**: Raised surface with border `#E2E8F0` and deliberate directional grounding: `0 4px 12px rgba(15, 23, 42, 0.08)`.
- **Level 3 (Modal Sheets & Bottom Action Bars)**: Fixed anchor layer with `0 -4px 20px rgba(15, 23, 42, 0.12)`, framing actionable elements clearly over the dimmed content canvas.

## Shapes
A balanced radius tier of Level 2 (`roundedness: 2`) gives components an approachable yet sturdy visual language.

### Component Radii
- **Standard Controls & Cards**: `0.5rem` (`8px`) on inputs, mandi cards, and data tiles.
- **Containers & Bottom Sheets (`rounded-lg`)**: `1rem` (`16px`) on sheet headers, modal surfaces, and group panels.
- **Audio Pills & State Tags (`rounded-full`)**: Fully circular/pill geometry to explicitly communicate touchable assistance and distinct metadata.

## Components

### 1. Mandi Commodity Cards
- **Base**: `#FFFFFF` background, `1px` solid border (`#E2E8F0`), `rounded-lg` (`16px`), padding `space-md` (`16px`).
- **Header**: Primary commodity name in `headline-md` (`#0F172A`), distance pill in amber `#FEF3C7` (text `#92400E`), accompanied by an inline audio pill.
- **Metrics Grid**: Two-column layout displaying "Current Modal Price" (`#1B5E20`, `headline-lg`) and "Arrival Volume" (`#334155`, `body-md`).

### 2. Accessible Audio Pills
- **Purpose**: Real-time read-aloud support for price, crop variety, and market conditions.
- **Dimensions**: Fixed `56px` height; icon plus text label padding `0.75rem 1.25rem`.
- **Styling**: `#F0FDF4` surface, `#10B981` border (`1.5px`), text and speaker icon `#1B5E20` in `label-lg`.
- **Active State**: Pulsing `#10B981` border with a waveform indicator showing playback duration.

### 3. Primary & Secondary Buttons
- **Touch Target**: Minimum height `56px` across all screen factors.
- **Primary**: Background `#1B5E20`, label `#FFFFFF` in `label-lg`, radius `0.5rem`. Focus ring `3px` solid `#10B981` with `2px` offset.
- **Secondary (Outline)**: Background `#FFFFFF`, border `2px` solid `#1B5E20`, label `#1B5E20` in `label-lg`.

### 4. Market Chips & Commodity Filters
- **Dimensions**: Min-height `56px`, horizontal padding `1.25rem`.
- **Default State**: Background `#FFFFFF`, border `1px` solid `#E2E8F0`, text `#334155` (`label-md`).
- **Selected State**: Background `#1B5E20`, border `1px` solid `#1B5E20`, text `#FFFFFF` (`label-md`).

### 5. Input & Search Fields
- **Touch Height**: `56px`. Font: `body-lg` (`18px`) for immediate visibility.
- **Frame**: `#FFFFFF` background, `1.5px` border `#CBD5E1`, placeholder `#64748B`.
- **Active / Focused**: Border `#1B5E20` (`2px`), background `#FFFFFF`, shadow ring `0 0 0 4px rgba(27, 94, 32, 0.1)`.
- **Embedded Audio Assist**: Integrated `56px` microphone voice search button docked at the trailing edge.

### 6. Commodity Status & Grade Tags
- **Grade Badges**: Background `#FEF3C7`, border `1px` solid `#FDE68A`, text `#B45309` (`label-sm`).
- **Live / Active Mandi Badges**: Background `#ECFDF5`, border `1px` solid `#A7F3D0`, text `#065F46` (`label-sm`) with a live pulse indicator.

### 7. Selection Controls (Checkboxes & Radios)
- **Geometry**: Minimum visible box size `28px x 28px` placed inside a full-width `56px` tap container.
- **Checked State**: Solid `#1B5E20` fill with a crisp white tick/dot; high contrast against `#FFFFFF` card surfaces.