# CodeKata UI/UX Redesign — Design Spec
**Date:** 2026-04-26  
**Direction:** Direction B — Modern Minimal Dark (from MyWearToday references)  
**Status:** Approved

---

## Design Rationale

CodeKata's current UI suffers from inconsistent colour themes per page (purple for challenges, blue for discussions), a visually disconnected sidebar, plain table-based challenge listings, and no unified typographic scale. The redesign applies Direction B tokens and patterns from the MyWearToday reference project verbatim, adapted to desktop layout.

Direction A (editorial warm, `#f5f1ea`) was rejected because CodeKata has a code editor at its core — a warm off-white background conflicts with every standard code editor theme. Direction B's near-black background is non-negotiable for comfortable code reading.

---

## Token System

All colours and fonts are taken verbatim from `minStyles` in `direction-b-minimal.jsx`. No new tokens are introduced.

```
bg:     #0e0e10   — page background, sidebar background
card:   #17171a   — all card/panel backgrounds
raised: #1f1f23   — hover states, active inputs, button backgrounds
ink:    #f5f5f7   — primary text
muted:  rgba(245,245,247,0.55)   — labels, secondary text, placeholder
faint:  rgba(245,245,247,0.12)   — borders on cards, chips
line:   rgba(245,245,247,0.08)   — subtle dividers, grid gaps used as borders
accent: #a6d6ff   — primary accent (cool light blue)

sans:   Inter, -apple-system, system-ui, sans-serif
mono:   "JetBrains Mono", ui-monospace, Menlo, monospace
```

Difficulty badge colours (filled chip, background varies by level):
- Easy   → bg `rgba(166,214,255,0.15)` / text `#a6d6ff`
- Medium → bg `rgba(252,211,77,0.15)` / text `#fcd34d`
- Hard   → bg `rgba(248,113,113,0.15)` / text `#f87171`

These are the only additional colour values beyond the base token set.

---

## Typography Scale

Taken from Direction B's heading + label pattern:

| Role | Font | Weight | Size | Letter-spacing |
|------|------|--------|------|----------------|
| Meta label | JetBrains Mono | 400 | 10px | 0.6px, uppercase |
| Page heading | Inter | 300 | 32px | -0.8px |
| Section heading | Inter | 500 | 18px | -0.3px |
| Body | Inter | 400 | 14px | 0 |
| Small / secondary | Inter | 400 | 13px | 0 |
| Chip / badge | JetBrains Mono | 400 | 10px | 0.4px, uppercase |
| Stat number | Inter | 300 | 20–22px | tabular-nums |
| Code | JetBrains Mono | 400 | 13–14px | 0 |

---

## Fonts

Load via Google Fonts CDN (replaces the current Inter-only setup):

```
Inter: weights 300, 400, 500, 600
JetBrains Mono: weights 400, 500
```

Both are already referenced in the MyWearToday prototype. Inter is already partially loaded — the `link` tag in `application.html.erb` must be updated to include weight 300.

---

## Layout

### Application Shell (`application.html.erb`)

```
body: bg #0e0e10
├── aside.sidebar  (fixed, left, 240px wide)
└── main           (flex-1, ml-[240px])
    ├── flash container
    └── page content (bg #0e0e10, min-h-screen)
```

The sidebar and page share the same `#0e0e10` background — no hard visual edge between them, only a `0.5px solid rgba(245,245,247,0.08)` right border on the sidebar.

### Sidebar (`_sidebar.html.erb`)

Structure (top → bottom):
1. **Logo block** — `CODEKATA` in JetBrains Mono 10px uppercase muted, `CodeKata` in Inter 600 20px ink. No tagline.
2. **Nav items** — each is `flex items-center gap-3 px-4 py-3`. Active item: `accent` icon + label colour + 2px left accent bar (`border-l-2 border-[#a6d6ff]`). Inactive: `muted` colour, `raised` bg on hover.
3. **Divider** — `0.5px solid rgba(245,245,247,0.08)` line.
4. **Admin section** (if admin) — mono uppercase 9px section label, then items same as nav.
5. **Account section** — mono uppercase 9px section label, Profile link, Logout link (logout gets `#f87171` on hover, same as Direction B's red-hover pattern).
6. **User block** (bottom, pinned) — initials circle `#1f1f23` 32px, `Inter 500` name, `JetBrains Mono 9px uppercase muted` for email or role.

No sidebar-specific background colour — inherits `#0e0e10` from body.

---

## Page Patterns

### Universal Page Header Pattern

Every page uses the same two-line header, taken from `MinHome`/`MinCloset` top row pattern:

```
[JetBrains Mono 10px uppercase muted]  META LABEL · COUNT OR CONTEXT
[Inter weight-300 32px letterSpacing -0.8]  Page Heading
```

Examples:
- Challenges: `CHALLENGES · 42 PROBLEMS` / `Challenges`
- Discussions: `DISCUSSIONS · COMMUNITY Q&A` / `Discussions`
- Home: `DASHBOARD · YOUR STATS` / `Welcome back`
- User profile: `PROFILE · @slug` / `Full Name`

No gradient hero banners on any page. The header sits in the page content area with `padding: 36px 48px 0`.

### Cards

All cards follow the `MinHome` outfit card pattern:
- Background: `#17171a`
- Border: none — use `rgba(245,245,247,0.08)` 1px where separation is needed
- Border-radius: `14px` (matching Direction B's `borderRadius: 14`)
- Padding: `16px`

### Stat Numbers

Taken from Direction B's weather stats grid:
- Grid of 2–4 cells, `rgba(245,245,247,0.08)` 1px gaps acting as dividers
- Each cell: `#17171a` bg, `JetBrains Mono 9px uppercase muted` label on top, `Inter weight-300 20px tabular-nums` value below

### Chips / Badges (`MinChip` exact pattern)

```css
display: inline-flex;
align-items: center;
padding: 3px 8px;
border-radius: 4px;
font-family: JetBrains Mono;
font-size: 10px;
letter-spacing: 0.4px;
text-transform: uppercase;
/* filled: */  background: accent; color: #0e0e10;
/* outline: */ border: 0.5px solid faint; color: muted;
```

Used for: language tags, category tags, "AI pick" style labels. Difficulty chips use their own colour set (see Token System above), not the generic outline/filled variants.

---

## Page-by-Page Spec

### Home (`home/index.html.erb`)

Layout: single column, `padding: 36px 48px`.

Sections (top → bottom):
1. Page header (meta label + heading).
2. **Stats row** — 3-cell stat grid: Challenges Solved (accent numeral), Duels Won (same), Total Duels (same). Exact `MinHome` weather stats pattern.
3. **Active Duels** — if any: section label in mono uppercase, then compact rows on `#17171a` card. Each row: challenger vs opponent names in `Inter 500`, challenge name in `muted`, "View" button as outline chip.
4. **Pending Duel Invitations** — same pattern; Accept button is filled accent chip.
5. **Featured Challenges** — section label, then 3-column card grid. Each card: `#17171a`, challenge name `Inter 500`, description `muted 13px truncated`, difficulty chip bottom-left.
6. **Friends** — section label, then horizontal avatar row. Each avatar: 32px circle `#1f1f23` with initials in `Inter 500 12px`, name below `Inter 13px`, "Challenge" link in `accent`.

### Challenges Index (`challenges/index.html.erb`)

Layout: `padding: 36px 48px`.

Page header + search bar (full-width input, `#17171a` bg, `faint` border, `muted` placeholder in JetBrains Mono italic, `accent` focus ring).

Replace the existing `<table>` with a flat list:
- Each row: `#17171a` card, `borderRadius 10px`, `padding 16px`, flex row.
- Left: challenge name `Inter 500 15px`, language chip `JetBrains Mono outline`.
- Right: difficulty chip (filled, colour by level), completion checkmark in `accent` if solved.
- Hover: background `#1f1f23`.
- Active/clicked: navigates to challenge show.

Pagination below using `muted` text links, active page in `accent`.

### Challenge Show (`challenges/show.html.erb`)

Remove the purple gradient header entirely.

Two-column layout (`grid-cols-2 gap-6 padding: 36px 48px`):

**Left column:**
- Challenge name `Inter 300 32px -0.8 letterSpacing`.
- Chips row: difficulty (filled), language (outline).
- Completion badge if solved: `✓ COMPLETED` in JetBrains Mono `accent`.
- Description card `#17171a borderRadius-14`.
- Challenge info card (language, difficulty, test count) — stat grid pattern.

**Right column:**
- Code editor card `#17171a borderRadius-14`. Header row: `SOLUTION` mono label + language chip. CodeMirror textarea, dark theme.
- Submit button: full-width, `#1f1f23` bg, `accent` text, `Inter 600 15px`.
- AI Hint button (admin only): outline style, `muted` text.
- Test results card `#17171a borderRadius-14`. Header: `TEST RESULTS` mono label. Output area: `#0e0e10` bg, `JetBrains Mono 13px`.

### Discussions Index (`discussions/index.html.erb`)

Remove blue gradient header.

Two-column layout: main list (flex-1) + sidebar (256px).

**Main:**
- Page header.
- Search + "Ask a Question" button row. Button: `#1f1f23` bg, `accent` text, `Inter 600`.
- Discussion cards: `#17171a borderRadius-14 padding-16`. Title `Inter 600 15px`, body `muted 13px truncated`. Category chips row (outline). Footer: author `muted 13px` left, time `muted 13px` right. Reply count: large `Inter 300 20px accent` right of title.

**Sidebar:**
- Hot Discussions card: `#17171a`, mono label, list of links in `accent 13px`.
- Categories card: same, category name + `(count)` in `muted`.

### Discussion Show

Keep existing Turbo structure. Restyle:
- Question card `#17171a borderRadius-14`.
- Voting: upvote/downvote arrows in `muted`, count in `Inter 500 18px ink`. Active vote in `accent`.
- Post cards same pattern.
- Reply form: `#17171a` card, action text editor, submit as filled accent button.

### User Profile (`users/show.html.erb`)

Remove blue gradient header. Flat layout `padding: 36px 48px`.

**Profile header row:** avatar circle `#17171a 64px` with initials, name `Inter 300 32px`, `@slug` in mono muted, joined date mono muted. Friend/Duel action button top-right.

**Stats row:** 3-cell grid (challenges solved, duels won, total duels) — exact stat grid pattern.

**Tab bar:** `QUESTIONS (n)` / `ANSWERS (n)` in JetBrains Mono uppercase, active tab gets `accent` underline `2px`. Content below.

**Right sidebar:** Action buttons (Challenge to Duel = filled accent, Send Invitation = outline). Friends list as avatar row.

### Devise / Auth pages

All auth pages (sign in, sign up, forgot password):
- Full-screen `#0e0e10` bg.
- Centred card `#17171a borderRadius-14 padding-48 max-w-md`.
- `SIGN IN` / `CREATE ACCOUNT` mono uppercase label above heading.
- Inputs: `#1f1f23` bg, `faint` border, `ink` text, `accent` focus ring.
- Submit: full-width filled `accent` bg `#0e0e10` text `Inter 600`.
- Links below in `accent`.

---

## CSS / Tailwind Changes

- Add `JetBrains Mono` to `tailwind.config.js` font family extension.
- Add Inter weight 300 to the Google Fonts link.
- Remove per-page `bg-gradient-to-r from-*` header classes.
- Body class changes from `bg-white` to `bg-[#0e0e10] text-[#f5f5f7]`.
- Sidebar `w-64 bg-slate-900` → `w-60 bg-[#0e0e10] border-r border-[rgba(245,245,247,0.08)]`.

Custom CSS classes needed (add to `application.tailwind.css`):
- `.ck-card` — `#17171a`, `borderRadius 14px`, `padding 16px`
- `.ck-meta` — JetBrains Mono 10px uppercase letterSpacing 0.6px muted colour
- `.ck-chip` — MinChip exact styles (filled and outline variants)
- `.ck-stat-grid` — the weather-stats grid pattern

---

## Out of Scope

- No changes to backend controllers or models.
- No changes to Turbo Stream / WebSocket behaviour.
- No changes to the CodeMirror integration logic — only its container styling.
- No changes to the admin settings page (low traffic, low priority).
- No responsive / mobile layout work — desktop only.
