## Agent skills

### Issue tracker

Issues live in GitHub Issues (`aniketpatidar/CodeKata`). See `docs/agents/issue-tracker.md`.

### Triage labels

Default label vocabulary (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`). See `docs/agents/triage-labels.md`.

### Domain docs

Single-context repo — one `CONTEXT.md` + `docs/adr/` at the root. See `docs/agents/domain.md`.

### Design system

Current visual design is "Dusk" — dark, thin borders, no shadows, no uppercase. Before touching any view or CSS, see `docs/design-system.md` for the tokens and conventions.

### Session notes

Don't write handoff notes, progress logs, or brainstorm/plan docs into the repo (no `docs/handoffs/`, no `ralph/`-style scripts). Working notes for the current task belong in your scratchpad or session memory, not in a committed file — they go stale the moment the task ends and nobody prunes them. If a decision is worth keeping permanently, it goes in `CONTEXT.md` or an ADR under `docs/adr/`, not a dated notes file.
