---
paths:
  - "docs/backlog.md"
  - "docs/backlog.html"
  - "docs/verification-backlog.md"
  - "tools/render_backlog.py"
  - "tools/backlog_template.html"
---

# Editing the Product Backlog

Moved verbatim from the root `CLAUDE.md` in October 2026 (see `docs/history/claude-md-restructure-2026-10.md`).
Loads when you read the backlog or its renderer. When to update the backlog is in the root `CLAUDE.md`.

---

### Product backlog — keep it current

`docs/backlog.md` is the source of truth and **the only file to edit by hand**.
`docs/backlog.html` is generated from it:

```bash
python3 tools/render_backlog.py     # md → html, run after every backlog edit
```

Never hand-edit `docs/backlog.html`; the next render discards the change. The
design lives in `tools/backlog_template.html`.

**Rules:**
- **IDs are stable and never renumbered or reused.** `E5.F3.S4` must mean the same
  story forever — issues, branches and commit messages quote them. New work takes
  the next free number even where an earlier story was abandoned.
- **Status is truthful, not aspirational.** `Shipped` means in production, not
  merged. Where a story is `Building`, the gap note says what is actually missing
  rather than what remains to polish.
- Counts are computed by the renderer — never hardcode them anywhere.
- Personas are the six in the backlog. **Mismanagement roles and Kennel HC Admin
  are independent grantors** on `HasherKennelMap` and either can allow a function —
  never write a story assuming an admin holds a club office, or the reverse.
