# Portal TODO

Items flagged during development that need follow-up.

---

## Permissions editor — grouping + website perms (raised 2026-07-27, bedtime; NOT started)

Straightforward reorg (same safe pattern as prior regroups — `FeatureArea`
UPDATEs + `kSectionGate`, portal-only, no recompile):
- [ ] **Manage Songs → "Kennel Tools"** (currently its own "Songs" group).
- [ ] **Web / Newsletter → "Runs, Events, and Hash Cash"** (gated by View Run
  Admin Tools). NOTE: semantically odd; may get revisited once the portal-gate
  architecture below is sorted — confirm with James before moving.

New portal-only permissions (needs the architecture question resolved first):
- [ ] **Add "Edit Website" and "Design Website" permission functions**, scoped
  to the **portal only** (not the app), under Kennels. Use them to gate the
  Edit Website / Design Website buttons on the portal (Puck page builder).

Deferred architecture question (James: "We'll need to sort this out later"):
- [ ] **App-gate vs portal-gate collision.** Two "kennel admin" gates exist:
  `enterKennelAdmin` = "View Kennel Admin Tools" gates the **app** UI; but the
  portal also needs a "View Kennel Tools (Portal)" gate. Today `FeatureArea` /
  `GrantorType` don't distinguish app-scope vs portal-scope. Decide how to model
  platform scope (new column? new GrantorType? separate function sets?) before
  building the website perms — otherwise a portal-only perm leaks into app
  gating logic (`canAccessFeature`) or vice-versa. Discuss with James.

---

## Security / Auth

- [ ] **`hcportal_getLoginHistory` — missing scope check**
  Any authenticated portal user can pass any `@userId` and read that person's
  login history. `@hasherId` and `@callerType` are returned by `ValidatePortalAuth`
  but unused in this SP.
  Fix: add a check that `@userId` is a member of a kennel where the caller
  (`@hasherId`) has admin rights. Service accounts (`@callerType` 1 or 2) bypass.
  See conversation: 2026-05-16.
