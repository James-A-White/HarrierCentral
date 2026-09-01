# DB TODO

## Tier performance comparison — S0 / S1 / S0 (set up 2026-09-01)

Scaled **S1 (20 DTU) → S0 (10 DTU)** at **2026-09-01 ~15:52 UTC** (from
`master.sys.resource_stats`: last 20-DTU sample 15:46:49, first 10-DTU 15:58:16).

- [x] Query Store was at **8 MB of a 10 MB cap** and already size-purging the
      pre-scale week. Now **200 MB / 30-day retention / QUERY_CAPTURE_MODE = ALL**.
- [x] `HC6.nonApi_capturePerfBaseline` snapshots per-proc stats into
      `HC.PerfBaseline`, stamped with the tier **actually in effect during the
      window** — derived from `HC.TierLog`, not from the tier at capture time.
      `HC.TierLog` is self-maintaining: every capture observes the live
      `dtu_limit` and opens a new range when it changes.
- [x] S1 baselines captured: **`S1-night`** (01:00–05:00) and **`S1-day`**
      (07:00–15:00), both 2026-09-01, both post-prune so the data volume
      matches today's.

### The A/B/A plan

Run a few days at S0, scale to S1 for a few days, then back to S0. Capturing
S0 **twice** is what makes this clean — if the two S0 runs agree, any S1
difference is really the tier; if they disagree, workload drifted and the
whole comparison is suspect. A simple before/after cannot tell those apart.

After each phase, capture BOTH a night and a day window:

```sql
EXEC HC6.nonApi_capturePerfBaseline 'S0-run1-night', '<date> 01:00:00 +00:00', '<date> 05:00:00 +00:00';
EXEC HC6.nonApi_capturePerfBaseline 'S0-run1-day',   '<date> 07:00:00 +00:00', '<date> 15:00:00 +00:00';
-- then after scaling up: 'S1-run2-night' / 'S1-run2-day'
-- then after scaling back: 'S0-run3-night' / 'S0-run3-day'
```

Compare like with like:

```sql
SELECT ProcName,
       MAX(CASE WHEN Label LIKE 'S1-%night'      THEN AvgStatementMs END) AS S1_night,
       MAX(CASE WHEN Label = 'S0-run1-night'     THEN AvgStatementMs END) AS S0_run1,
       MAX(CASE WHEN Label = 'S0-run3-night'     THEN AvgStatementMs END) AS S0_run3,
       MAX(CASE WHEN Label LIKE 'S1-%night'      THEN AvgLogicalReads END) AS S1_reads,
       MAX(CASE WHEN Label = 'S0-run1-night'     THEN AvgLogicalReads END) AS S0_reads,
       MAX(CASE WHEN Label = 'S0-run1-night'     THEN AvgPhysicalReads END) AS S0_physreads
FROM HC.PerfBaseline
WHERE Label LIKE '%night' GROUP BY ProcName ORDER BY ProcName;
```

Rules for reading it:
1. **`TierChangedDuringWindow = 1` means the window spans a scale — discard it.**
2. **Check `AvgLogicalReads` first.** If it differs between windows the two ran
   different work and the duration ratio is meaningless.
3. **`AvgPhysicalReads` is the real risk indicator.** Still ~0 at S0 means the
   working set fits the smaller buffer pool. If it climbs, that is the memory
   cliff and it hurts far more than linearly.
4. **Match the time of day.** Proven necessary: `nonApi_checkReminders` ran
   36.66 ms at night and 29.66 ms by day on the SAME tier with identical reads.
   A night-vs-day comparison invents a 1.24x effect out of nothing.
5. Skip the first hour after any scale — cold buffer pool.

- [ ] When finished, consider setting `QUERY_CAPTURE_MODE` back to `AUTO`;
      `ALL` costs a little overhead on 10 DTU.

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
