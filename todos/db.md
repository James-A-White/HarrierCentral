# DB TODO

## ⚠️ FIRST THING: re-enable two Logic Apps (disabled 2026-08-31 ~21:40 UTC)

- [ ] **Re-enable `HC_prune_logs` and `HC_rebiuld_indexes`** — both were
      DISABLED for one night only, so the 2.5M-row catch-up prune would not
      collide with them on a 20 DTU database already at 100% Data IO.
      ```bash
      for W in HC_prune_logs HC_rebiuld_indexes; do
        az resource update -g harrier -n $W \
          --resource-type Microsoft.Logic/workflows \
          --set properties.state=Enabled --query "properties.state" -o tsv
      done
      ```
      The other five maintenance workflows were left Enabled.

- [ ] **Confirm the catch-up prune finished.** It was still running at the time
      of writing (~27k rows/min, ETA ~23:50 UTC). Check:
      `SELECT COUNT(*) FROM LOG.GeneralLog WHERE [Timestamp] < DATEADD(DAY,-90,SYSUTCDATETIME())`
      — should be 0, likewise `HC.IntegrationJob.startedAt`. If not, re-run
      the loop; every batch autocommits so it is safe to resume at any point.

- [ ] **Run the index rebuild once the prune is done** — the deletes free a
      large number of pages that stay allocated until a rebuild reclaims them.
      This is the whole reason the prune was scheduled just before it.

## ⚠️ Every long maintenance Logic App reports Failed (pre-existing)

- [ ] `HC_rebiuld_indexes` and `HC_backup_tables` have failed with
      **GatewayTimeout at ~110s every single night** for as long as run history
      goes back — the SQL connector's synchronous limit, well below their
      PT20M/PT30M action timeouts. The work appears to continue server-side
      (backup tables were still being written 8s before the timeout), but the
      Logic App can never report success, so a real failure would be invisible.
      `HC_update_counts_credits` succeeds in 7s and is unaffected.
      Decide: split the SPs into sub-2-minute chunks, or move to a trigger the
      connector can poll asynchronously.

## Contact address

- [x] `connect@harriercentral.com` is dead. Replaced with
      `harriercentral@gmail.com` in 113 live procs across HC3/HC4/HC5/HC6/
      HC_BACKUP (2026-08-31, commit 1e72c262) and in the git baseline.
      Rollback copies in `HC.ProcBackup_20260831_ContactEmail` — drop that
      table once you are happy.

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
