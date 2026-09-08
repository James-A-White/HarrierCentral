# Contributing to Harrier Central

Harrier Central is a hash running club management platform. It has been built and
maintained by one person working nights and weekends, which shapes everything
below: the guardrails exist because there is nobody else to catch a mistake.

**Read [`CLAUDE.md`](CLAUDE.md) before writing any code.** It is written for AI
coding agents but it is the accurate description of the architecture, and several
of its rules protect against failures that are completely silent — a query against
the wrong local database domain returns empty rather than raising, and a wrong
access token produces an auth failure with no indication of the cause.

---

## Where the work is

| | |
|---|---|
| **What the platform does** | [`docs/backlog.md`](docs/backlog.md) — epics, features and stories with stable IDs |
| **What needs doing** | GitHub Issues |
| **What needs testing** | [`docs/verification-backlog.md`](docs/verification-backlog.md) |
| **Why things are the way they are** | [`docs/history/`](docs/history/) and the commit log |

The backlog is the map; issues are the work. A story ID like `E6.F2.S4` is stable
and can be quoted in an issue, a branch name or a commit message.

**Good first issues** are labelled `good first issue`. If you want something
larger, the `device-test` issues need no architectural knowledge and are genuinely
the most valuable thing an outside contributor can do right now — a lot of this
platform shipped without a device pass.

---

## Ground rules

**Nothing deploys without the maintainer.** There is one production database and no
staging environment, so every stored procedure change is live to every user the
moment it lands. Open a PR; do not deploy.

**No direct database access from any frontend, ever.** All data goes through stored
procedures called via the Azure Functions shim. No dynamic SQL, anywhere.

**Adding a stored procedure almost never needs an API change.** The shim routes
generically on `queryType`. If you are editing a `.cs` file to add an endpoint, you
are probably doing it wrong — see the API endpoints section of `CLAUDE.md`.

**Stored procedures deploy before the clients that call them.** The shim forwards
every JSON property as a named parameter, so a client sending a parameter the
procedure does not have fails outright.

**Do not convert a `StatelessWidget` to a `StatefulWidget`** without asking. The
preferred direction is the opposite — GetX controllers over widget state.

---

## Pull requests

1. Branch from `dev`. `master` moves only at a release.
2. One logical change per PR. Database work is one procedure per commit.
3. Say what you changed and **why**, and what you did to check it. If you could
   not test something, say so plainly — that is far more useful than silence.
4. Run `flutter analyze` (Flutter), `npx tsc --noEmit` (public web), and any
   tests near what you touched.
5. If you changed something with a story in the backlog, update its status in
   `docs/backlog.md` in the same PR, then run `python3 tools/render_backlog.py`.

Do not commit secrets. `.env` is gitignored and has never been committed — keep it
that way. This repository is public.

---

## Reporting a bug

Use the **Bug report** issue template. What actually helps: the app version, which
kennel, and the exact wording of any error.

**Security problems go to james.a.white@gmail.com, never a public issue.**

---

## A note on the existing issues

Issues numbered below #340 date from 2020–2022 and predate the HC6 rewrite. Many
describe work that has since shipped. They are being triaged; until that is done,
**do not start work on an old issue without asking** — you may build something
that already exists.
