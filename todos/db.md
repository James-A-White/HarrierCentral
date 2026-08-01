# DB TODO

## Run-count guard fix (2026-07-30) — deploy + verify

- [x] **Deploy the symmetric change-guard fix** (`nonApi_updateRunCountsByUser` /
      `ForAllUsers` / `ForEventUsers`) via `./tools/deploy_hc6.sh`. Root cause of
      the ~100k/night "Activity" churn on the usage dashboard: Stage 2 haring
      guards compared the raw window value against the stored CASE-adjusted
      value, so every non-hare row fired on every recompute.
      *Deployed 2026-07-31 04:57 UTC (149 SPs, 0 failures). Read-only replay of
      the new guard predicts tonight's sweep stamps just 4 rows (all genuine
      `TotalHaring` staleness — the one-time convergence "wave"), Stage-3
      clears 0.*
- [x] **Verify the morning after 2026-08-01's 03:10 sweep**: VERIFIED
      2026-08-01 09:59 UTC — HEM rows stamped in trailing 24h = **49** (was
      101,706). Sweep completed in ~21s (03:10:21) vs ~4min pre-fix
      (03:14:02). Usage dashboard Activity row now shows organic numbers.

## HC6 Migration

- [x] Survey all HC6 SPs for calls to non-HC6 SPs originating outside the app/portal
      (Logic Apps, the API shim itself, scheduled jobs, etc.). Known candidates include
      the import-kennel functions. Migrate any remaining dependencies to HC6 so the
      HC3-5 schema artifacts can eventually be cleaned up.
