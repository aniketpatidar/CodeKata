# CodeKata UI Redesign — Ralph PRD

## Project Context

Rails 7 app. Pure view-layer redesign — zero changes to controllers, models, routes, or Turbo wiring.
Design system: Direction B dark minimal (tokens in `docs/superpowers/specs/2026-04-26-ui-ux-redesign-design.md`).
Full implementation plan with exact code: `docs/superpowers/plans/2026-04-26-ui-ux-redesign.md`.
Current branch: `feat/judge0-code-evaluation`.

## Tasks

### TASK-01: Design System Foundation
**Files:** `config/tailwind.config.js`, `app/assets/stylesheets/application.tailwind.css`, `app/views/layouts/application.html.erb`
Add JetBrains Mono + Inter 300 via Google Fonts. Extend Tailwind with `ck` colour tokens and `font-mono`. Add CSS custom properties (`--ck-bg`, `--ck-card`, `--ck-raised`, `--ck-ink`, `--ck-muted`, `--ck-faint`, `--ck-line`, `--ck-accent`) and `.ck-card`, `.ck-meta`, `.ck-chip` (filled/outline/easy/medium/hard), `.ck-stat-grid`, `.ck-btn-primary`, `.ck-btn-outline`, `.ck-input`, `.ck-heading` utility classes. Update body to `bg-[#0e0e10] text-[#f5f5f7]`, sidebar offset `ml-[240px]`. See Task 1 in the plan file for exact code.

### TASK-02: Sidebar
**Files:** `app/views/layouts/_sidebar.html.erb`
Full rewrite. Dark minimal, no explicit bg (inherits `#0e0e10`), `0.5px` right border. Active nav item: `border-l-2 border-[#a6d6ff]` left bar + accent text. Pinned user block at bottom. Use plain `<a>` tags (not `link_to` blocks). Preserve `data-turbo-method="delete"` on logout. See Task 2 in the plan file for exact code.
**Blocked by:** TASK-01

### TASK-03: Admin Category Templates
**Files:** `app/views/admin/categories/_form.html.erb`, `new.html.erb`, `edit.html.erb`, `show.html.erb` (create all four)
Fixes 500 errors on `/admin/categories/new`, `/admin/categories/:id/edit`, `/admin/categories/:id`. Controller already exists and works. Use `.ck-card`, `.ck-meta`, `.ck-input`, `.ck-btn-primary` classes. Form has one field: `name`. Show page displays name + discussion count + edit/delete links.
**Blocked by:** TASK-01

### TASK-04: Home Dashboard
**Files:** `app/views/home/index.html.erb`
Full rewrite. Stat grid (3-col `.ck-stat-grid`), active duel rows, pending duel rows, featured challenges 3-col grid, friends avatar row. See Task 3 in the plan file for exact code.
**Blocked by:** TASK-01, TASK-02

### TASK-05: Challenges Index
**Files:** `app/views/challenges/index.html.erb`
Replace `<table>` with flat card list. Preserve `turbo_frame_tag "search-results"` wrapper. Difficulty chips coloured by level. See Task 4 in the plan file for exact code.
**Blocked by:** TASK-01, TASK-02

### TASK-06: Challenge Show
**Files:** `app/views/challenges/show.html.erb`
Two-column layout. Remove any gradient. Preserve CodeMirror JS integration. Dark code editor panel, test results panel. See Task 5 in the plan file for exact code.
**Blocked by:** TASK-01, TASK-02

### TASK-07: Discussions Index
**Files:** `app/views/discussions/index.html.erb`
Remove blue gradient hero banner. Dark discussion cards, accent reply count, category chips, hot discussions sidebar. See Task 6 in the plan file for exact code.
**Blocked by:** TASK-01, TASK-02

### TASK-08: Discussion Show + Partials
**Files:** `app/views/discussions/show.html.erb`, `app/views/discussions/_header.html.erb`, `app/views/discussions/_voting.html.erb`, `app/views/discussions/posts/_post.html.erb`
Preserve all Turbo Stream and voting wiring exactly. Only restyle wrappers. See Task 7 in the plan file for exact code.
**Blocked by:** TASK-01, TASK-02

### TASK-09: User Profile
**Files:** `app/views/users/show.html.erb`
Remove gradient header. Flat layout, stat grid, tab bar (JS toggle), friends sidebar. See Task 8 in the plan file for exact code.
**Blocked by:** TASK-01, TASK-02

### TASK-10: Devise Auth Pages
**Files:** `app/views/devise/sessions/new.html.erb`, `app/views/devise/registrations/new.html.erb`, `app/views/devise/passwords/new.html.erb`
Centred dark card layout on full-screen `#0e0e10` bg. `.ck-input` fields, `.ck-btn-primary` submit. See Task 9 in the plan file for exact code.
**Blocked by:** TASK-01

### TASK-11: Flash Messages
**Files:** `app/views/shared/_flash.html.erb`
Dark card flash notification. Fixed bottom-right. Accent label for notice, red label for alert. See Task 10 in the plan file for exact code.
**Blocked by:** TASK-01
