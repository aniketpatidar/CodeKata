# Design System: Direction B

The current visual design, applied across every page. If a page looks visibly different from this (sharp corners, bold borders, heavy shadows, uppercase chunky type), it's the old **neo-brutalist** design and needs converting, not extending.

## Tokens

All colors are CSS custom properties defined in `app/assets/stylesheets/application.tailwind.css` under `:root`, and mapped to Tailwind's `ck.*` color scale in `config/tailwind.config.js`. Never hardcode a hex value for these — use the token.

| Token | Value | Use |
|---|---|---|
| `--ck-bg` | `#1a1a1a` | Page background |
| `--ck-card` | `#2a2a2a` | Card background |
| `--ck-raised` | `#3a3a3a` | Hover state / raised surface |
| `--ck-ink` | `#f5f5f7` | Primary text |
| `--ck-muted` | `#999999` | Secondary text, labels |
| `--ck-accent` / `--ck-secondary` | `#a6d6ff` | Links, primary buttons, focus rings |
| `--ck-line` | `rgba(166,214,255,0.15)` | Borders |

## Conventions

- **Borders**: `0.5px solid var(--ck-line)` everywhere — never a thick border, never a solid dark line.
- **Radius**: 8–10px on cards and buttons; 20px (pill) on chips and stickers.
- **Shadows**: none. `box-shadow: none` is explicit on every component — no drop shadows, no offset/hard shadows.
- **Weight**: `font-semibold` (600) for headings and emphasis. Never `font-black` / 900.
- **Case**: `text-transform: none` everywhere. No uppercase labels.
- **Transforms**: none. No rotated cards, no skew.
- **Font**: `'Space Grotesk', system-ui, sans-serif` throughout.

## Component classes

Defined in `app/assets/stylesheets/application.tailwind.css` under `@layer components`. Reuse these rather than writing one-off utility soup:

- `.ck-page` — page padding wrapper
- `.ck-card` — the base surface (card, section, row)
- `.ck-heading` — large page/section title
- `.ck-meta` — small muted label text
- `.ck-sticker` — pill-shaped eyebrow/tag above a heading
- `.ck-chip`, `.ck-chip--filled`, `.ck-chip--outline`, `.ck-chip--easy/medium/hard/completed` — tag/badge variants
- `.ck-btn-primary`, `.ck-btn-outline`, `.ck-btn-danger` — buttons
- `.ck-stat-grid` — stat tile grid

## Checking a page is converted

A page is Direction B if it uses only `ck-*` classes/tokens for color and has no hardcoded hex colors, no `border-2`/`border-4`, no `shadow-[...]` with an offset, and no `uppercase`/`font-black`. `grep -rn "font-black\|uppercase\|border-4\|border-2" app/views` should return nothing outside archived/reference material.
