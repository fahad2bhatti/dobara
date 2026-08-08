# UI/UX Design System

**Project:** Dobara — A Trust-First Marketplace for Pre-Loved Fashion in Pakistan
**Author:** Fahad Bhatti ([@fahad2bhatti](https://github.com/fahad2bhatti))
**Repository:** [github.com/fahad2bhatti/dobara](https://github.com/fahad2bhatti/dobara)
**Document:** 5 of 12 — SDLC Documentation Pipeline
**Status:** v1.0 — Locked

---

## 1. Design Direction

Dobara sells trust as much as it sells clothes. The system leans on textile-dye heritage (ajrak indigo, madder-root maroon, handloom greys) rather than a generic tech palette — grounding the app visually in Pakistani fashion craft instead of a borrowed "startup" look. The signature element is the **condition tag**: every listing badge is styled like a woven fabric care tag, reinforcing the app's core promise (standardized, honest condition grading) in the UI itself.

---

## 2. Color Palette

| Token | Hex | Use |
|---|---|---|
| `indigo` (Primary) | `#1F3A5F` | App bar, primary buttons, active nav, links |
| `maroon` (Accent) | `#8C2F39` | CTAs that need urgency (Buy Now, Sell), price highlights |
| `sage` (Success/Trust) | `#4B6B4F` | Trust score, delivered status, positive states |
| `khaddar` (Background) | `#EDEAE3` | App background — unbleached cotton tone |
| `surface` | `#FFFFFF` | Cards, sheets, input fields |
| `ink` (Text primary) | `#26221E` | Body text, headings |
| `ink-muted` (Text secondary) | `#6B6459` | Captions, metadata, timestamps |
| `border` | `#DAD4C7` | Dividers, input borders, card outlines |
| `error` | `#B3261E` | Error states, destructive actions |
| `warning` (Fair condition) | `#B8860B` | "Fair" condition badge |

**Condition grade badge colors** (signature element):
| Grade | Badge color |
|---|---|
| New with Tags | `indigo` on `surface` |
| Like New | `sage` on `surface` |
| Good | `#8A7B4F` (muted brass) on `surface` |
| Fair | `warning` on `surface` |

---

## 3. Typography

| Role | Typeface | Notes |
|---|---|---|
| Display (headings, branding) | **Fraunces** (serif, weight 600) | Editorial/fashion feel for hero text, listing titles, "Dobara" wordmark |
| Body (UI text) | **Manrope** (weight 400/500) | Clean geometric sans — buttons, labels, descriptions |
| Utility (prices, data) | **IBM Plex Mono** (weight 500) | Prices and condition codes set in mono — reads like a price tag/receipt |

**Type scale:**
| Style | Size | Weight | Face |
|---|---|---|---|
| Display L (hero) | 32sp | 600 | Fraunces |
| Display M (screen titles) | 24sp | 600 | Fraunces |
| Title (card headers) | 18sp | 600 | Manrope |
| Body | 15sp | 400 | Manrope |
| Caption | 13sp | 500 | Manrope |
| Price | 18sp | 500 | IBM Plex Mono |

---

## 4. Spacing, Radius, Shadow

- **Spacing scale:** 4 / 8 / 12 / 16 / 24 / 32 / 48 (base unit 4dp)
- **Border radius:** 12dp cards, 8dp buttons/inputs, 999dp (pill) for badges/chips
- **Shadows:** single soft shadow only — `0 2px 8px rgba(38,34,30,0.08)` — no heavy elevation, keeps the fabric/paper feel flat and warm

---

## 5. Components

### Buttons
- Primary: `maroon` fill, white text, 8dp radius, 48dp height
- Secondary: `indigo` outline, `indigo` text, transparent fill
- Text button: `indigo` text, no background — used for "Skip", "Cancel"

### Cards (Listing Card)
- White surface, 12dp radius, 1px `border`
- Photo (4:5 aspect ratio — fashion-standard portrait crop)
- Condition badge (top-left overlay on photo, pill shape)
- Title (Manrope, Title style, 1 line, ellipsis)
- Price (IBM Plex Mono, Price style)
- Seller trust score (small `sage` star + number, bottom row)

### Input Fields
- 8dp radius, `border` outline, `surface` fill
- Focus state: `indigo` outline, 2px
- Error state: `error` outline + helper text below in `error`

### Bottom Navigation
- 5 tabs (Home, Search, Sell, Wishlist, Profile) — per Doc 4
- Active tab: `indigo` icon + label; inactive: `ink-muted`
- "Sell" tab visually distinct — filled `maroon` circle icon, elevated slightly above the bar

### App Bar
- `khaddar` background (blends with screen, not a hard-contrast bar)
- `ink` title text, Display M style on screen-title bars

### Loading States
- Skeleton shimmer (matches card shapes: photo block + 2 text lines), `border` color base with lighter shimmer sweep
- No spinners on list screens — skeletons only

### Empty States
- Line illustration (simple, single-color `ink-muted` linework) + one-line message in the interface's voice + one clear action button
  - e.g. Empty wishlist: "Nothing saved yet." / button: "Browse listings"
  - e.g. No search results: "No matches for [query]." / button: "Clear filters"

### Error States
- Inline for forms (helper text under field, `error` color)
- Full-screen for network failures: short factual message + "Retry" button — no apology language, states what happened and what to do

---

## 6. Layout Concept — Home Feed (ASCII reference)

```
┌─────────────────────────┐
│  Dobara      🔍  🔔      │  ← App bar (khaddar bg)
├─────────────────────────┤
│  [Clothing][Shoes][Acc.] │  ← category chips, horizontal scroll
├─────────────────────────┤
│ ┌───────┐ ┌───────┐     │
│ │ photo │ │ photo │     │  ← 2-column grid, 4:5 cards
│ │ [tag] │ │ [tag] │     │
│ │ title │ │ title │     │
│ │ Rs.   │ │ Rs.   │     │
│ └───────┘ └───────┘     │
├─────────────────────────┤
│  Home Search Sell ♡ 👤   │  ← bottom nav
└─────────────────────────┘
```

---

## 7. Accessibility Baseline

- Text contrast meets WCAG AA against `khaddar` and `surface` backgrounds
- Minimum tap target 48x48dp
- All condition badges carry text, never color alone
- Reduced-motion respected for skeleton shimmer and transitions
