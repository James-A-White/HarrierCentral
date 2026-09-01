# DB TODO

## S1 → S0 performance comparison (set up 2026-09-01)

Database scaled **S1 (20 DTU) → S0 (10 DTU)** at ~05:45 UTC 2026-09-01.

- [x] Query Store fixed: it was at **8 MB of a 10 MB cap** and size-purging old
      data, in AUTO capture mode. Now **200 MB, 30-day retention,
      QUERY_CAPTURE_MODE = ALL**. (Consider reverting to AUTO once the
      comparison is done — ALL costs a little overhead on 10 DTU.)
- [x] Baselines snapshotted into `HC.PerfBaseline` via
      `HC6.nonApi_capturePerfBaseline` so they survive retention.

- [ ] **In a few days, capture the matching S0 window and compare:**
      ```sql
      EXEC HC6.nonApi_capturePerfBaseline 'S0-steady',
           '2026-09-0X 01:00:00 +00:00', '2026-09-0X 05:00:00 +00:00';

      SELECT ProcName, Label, StatementExecs, AvgStatementMs,
             AvgLogicalReads, AvgPhysicalReads
      FROM HC.PerfBaseline
      WHERE Label IN ('S1-postPrune','S0-steady')
      ORDER BY ProcName, Label;
      ```
      **Use the 01:00–05:00 UTC window specifically.** The only clean S1
      baseline is `S1-postPrune` (2026-09-01 01:00–05:00): after the prune, so
      the same data volume as now, and before the scale. Matching the hours
      keeps time-of-day load out of the comparison.

      Judge it on **AvgLogicalReads first** — if that differs, the two windows
      did different work and the duration ratio is meaningless. Then
      **AvgPhysicalReads**: still ~0 means the working set fits S0's smaller
      buffer pool and there is no memory cliff.

      ⚠️ `S1-prePrune` is nearly empty (only `nonApi_pruneLogs`). Query Store
      was purging on size and running in AUTO mode, so most of the pre-scale
      week is gone. Do not treat its absence as "nothing ran".

## Maintenance jobs — restored 2026-09-01

- [x] **Re-enabled `HC_prune_logs` and `HC_rebiuld_indexes`** (2026-09-01
      05:40 UTC) and ran both manually. All seven workflows are Enabled.
- [x] **Catch-up prune FINISHED** 2026-09-01 00:43:51, 100 micro-prune
      iterations. Oldest log row is now exactly 90 days back. **Used space
      5,812 MB → 2,801 MB of a 10,240 MB cap: 3.0 GB freed.**
- [x] **`HC_prune_logs` Succeeded in 3.6s** — its first ever successful run.
      Steady state fits inside the gateway window comfortably.
- [x] **Index rebuild run — and it reclaimed ~9 MB, i.e. nothing.** The space
      had already been released by the deletes themselves. The prune/rebuild
      scheduling adjacency buys nothing; see the db-log-retention memory.
- [ ] **Optional, not urgent:** `HC.IntegrationJob` is 681 MB for 32k rows
      (~21 KB/row) because of five NVARCHAR(4000) columns, all in-row. A
      rebuild or LOB compaction will NOT shrink it — only a shorter retention
      for that table, or nulling those columns on old rows, would.

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
