# Portal TODO

Items flagged during development that need follow-up.

---

## Security / Auth

- [ ] **`hcportal_getLoginHistory` — missing scope check**
  Any authenticated portal user can pass any `@userId` and read that person's
  login history. `@hasherId` and `@callerType` are returned by `ValidatePortalAuth`
  but unused in this SP.
  Fix: add a check that `@userId` is a member of a kennel where the caller
  (`@hasherId`) has admin rights. Service accounts (`@callerType` 1 or 2) bypass.
  See conversation: 2026-05-16.
