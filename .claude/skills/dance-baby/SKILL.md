---
name: dance-baby
description: "Full coordinated release of every changed component. Run only when James says 'Dance baby!' (all beta testers) or 'I want a private dance' (James, Tuna Melt and Kilty only), or types /dance-baby."
disable-model-invocation: true
---

## "Dance baby!" — Full Release Command

When James says **"Dance baby!"**, execute a full release of all components that
have changed since the last deploy. This is the sanctioned way to request a
full coordinated release.

### Who gets the app — two commands (James, 2026-10-01)

| James says | Server side (SPs, API, web, portal) | Mobile app |
|---|---|---|
| **"I want a private dance"** | Deployed as usual | **James, Tuna Melt and Kilty only.** iOS: upload to TestFlight and assign NO group — the "James internal test" group (James, Melissa White, Martijn Körvers) receives every build automatically. Android: build the AAB and keep it in `~/HarrierCentral-builds/`; do NOT upload to Play internal, which reaches every Android tester. |
| **"Dance baby!"** | Deployed as usual | **All beta testers.** iOS: upload, then assign the build to the "Hash beta testers" group. Android: upload the AAB to the Play internal track (`tools/play_upload.py`). |

The server side has one audience — production — whichever command is used, so
a private dance is still a production deploy of SPs, API, web and portal.

### Step 1 — Identify changed components

Check git log and working tree to determine which components have changes not
yet deployed. Only process components with actual changes — no nugatory work.

| Component | Changed if… | Changelog |
|-----------|-------------|-----------|
| `db/hc6/` | Any `.sql` SP modified | None (commit message is sufficient) |
| `api/` | Any `.cs` or `.csproj` modified | `api/pubversion.text` |
| `mobile-app/` | Any Dart/Flutter file modified | `mobile-app/CHANGELOG.md` |
| `portal/` | Any Dart/Flutter file modified | `portal/CHANGELOG.md` |
| `public-web/` | Any TypeScript/Next.js file modified | `public-web/CHANGELOG.md` |

### Step 2 — Show James a deployment plan

Before doing anything irreversible, present:
- Which components will be deployed
- Proposed build-number bumps for each (version strings unchanged unless James asked)
- Draft changelog entries for each
- Order of operations

**Wait for James to confirm before proceeding.**

### Step 3 — Execute in this order

1. **Version bumps + changelog** — update all changed components (see below)
2. **Commit to dev**
3. **Push dev**
4. **Merge dev → master and push master** — portal auto-deploys via CI on master push
5. **Deploy SPs** — `./tools/deploy_hc6.sh` (only if `db/hc6/` changed), then `python3 tools/sp_versions.py` — every object on the new build
6. **Deploy API** — `func azure functionapp publish harriercentralpublicapi` from `api/` dir (only if `api/` changed; the short `func publish` form prints help and deploys nothing)
7. **Deploy public web** — standalone build → zip → `az webapp deploy` to harriercentralpublicweb (only if `public-web/` changed)
8. **Deploy mobile app** — TestFlight via xcodebuild + xcrun altool (only if `mobile-app/` changed)

---

### Version bump and changelog rules per component

**Never bump a version number without James's explicit request** (James,
2026-09-25). Every release bumps the **build number** (`+N`), and must —
the stores and the portal refuse a reused one. The version string `X.Y.Z`
stays as it is unless James asks for a new version in that conversation;
"Dance baby!" and "no confirmation required" are not that request. A
version string is a product decision: on the App Store a shipped version
closes its train.

#### API (`api/`)
- Increment the `+N` build number in `api/pubversion.text`
- `<Version>X.Y.Z</Version>` in `api/HcWebApi.csproj` changes only on James's request
- Prepend a new entry at the top of `api/pubversion.text`:
  ```
  X.Y.Z+N
  • Short description of change
  ```

#### Mobile app (`mobile-app/`)
- Bump the build in `version: X.Y.Z+build` in `mobile-app/pubspec.yaml` (X.Y.Z only on James's request)
- Prepend to `mobile-app/CHANGELOG.md`:
  ```markdown
  ## X.Y.Z+build (YYYY-MM-DD)
  ### Fixes / New Features / Improvements
  - **Feature**: Description
  ```
- Deploy via TestFlight (Key ID `7YDRYBL5KS`, Issuer ID in memory `reference_testflight_deploy.md`)

#### Portal (`portal/`)
- Bump the build in `version: X.Y.Z+build` in `portal/pubspec.yaml` (X.Y.Z only on James's request)
- Prepend to `portal/CHANGELOG.md`
- **No manual deploy step** — merging to master triggers auto-deploy via CI

#### Public web (`public-web/`)
- `"version"` in `public-web/package.json` has no build number — change it only on James's request
- Prepend to `public-web/CHANGELOG.md`
- Deploy steps in memory `reference_public_web_deploy.md`

#### SPs (`db/hc6/`)
- No version number, no changelog entry
- Deploy via `./tools/deploy_hc6.sh` from repo root
- Always deploy SPs **before** the API if both have changed

---

### Deploying SPs

All SPs (portal and public-web) are deployed via `sqlcmd` using the credentials
in `.env`. The deploy script `tools/deploy_hc6.sh` handles the full HC6 deploy:

```bash
./tools/deploy_hc6.sh
```

It runs four steps in order: HC6 schema → ValidatePortalAuth helper →
all `hcportal_*.sql` portal SPs → all `publicWeb_*.sql` public-web SPs.

**Every deploy stamps every object** (since 2026-09-26). The script adds one
comment line above each `CREATE OR ALTER` in the text it sends — never in the
repo files:

```
-- HC-DEPLOY build=N at=<utc> commit=<head>[+dirty] changed=<sha|uncommitted> sha256=<12> file=<path>
```

`build` is the highest build already stamped in the database + 1, so the
database is the counter. `changed` is the last commit to touch that file.
After every deploy, and whenever "is this fix live?" comes up, run:

```bash
python3 tools/sp_versions.py                  # report; exit 1 = something is off
python3 tools/sp_versions.py hcapp_addDownDown   # one object's stamp
```

It flags objects edited by hand after a deploy, objects the last deploy did
not reach, code deployed uncommitted, and unstamped HC6 objects (orphans the
repo no longer creates). PENDING — changed in the repo since deployed — is
normal between releases: it is what the next deploy ships.
