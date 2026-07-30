# DB TODO

## Run-count guard fix (2026-07-30) — deploy + verify

- [ ] **Deploy the symmetric change-guard fix** (`nonApi_updateRunCountsByUser` /
      `ForAllUsers` / `ForEventUsers`) via `./tools/deploy_hc6.sh`. Root cause of
      the ~100k/night "Activity" churn on the usage dashboard: Stage 2 haring
      guards compared the raw window value against the stored CASE-adjusted
      value, so every non-hare row fired on every recompute.
- [ ] **Verify the morning after deploy**: usage dashboard Activity/day should
      drop from ~100k to organic levels (tens–hundreds). Or run the 03:10-minute
      histogram against `HC.HasherEventMap.updatedAt`. Note: the first sweep may
      legitimately stamp a wave of rows whose `TotalHaring` was genuinely stale
      (that column was previously missing from the guard, so staleness never
      self-healed) — a one-time convergence, then quiet.

## HC6 Migration

- [x] Survey all HC6 SPs for calls to non-HC6 SPs originating outside the app/portal
      (Logic Apps, the API shim itself, scheduled jobs, etc.). Known candidates include
      the import-kennel functions. Migrate any remaining dependencies to HC6 so the
      HC3-5 schema artifacts can eventually be cleaned up.
