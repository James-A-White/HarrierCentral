# Azure cost audit — subscription JAW-Azure (2026-08-29)

Read-only audit. **Nothing was changed.** Figures are Azure North Europe list
prices and are ESTIMATES — the Cost Management API was returning HTTP 429 for
the whole session, so confirm actuals in Portal → Cost Management → Cost
Analysis before acting.

Measurements are real: SKUs, site counts, 30-day metrics and storage capacity
all came from the live subscription.

---

## Do these first — ~£33/month, no user-visible impact

| # | Action | Evidence | Est. saving |
|---|---|---|---|
| 1 | **Delete App Service plan `hcwebapi-app-service-plan`** (RG HarrierCentral) | B1 Basic with **zero sites** on it. Paying for an empty plan. | ~£11/mo |
| 2 | **Scale SQL `HarrierCentralWebDb` S1 → S0** | 30-day DTU: **avg 0.65%, peak 14%** of 20 DTU. S0 is 10 DTU, so the peak becomes ~28%. Storage is 6.4 GB — fits S0's 250 GB cap. (Basic is 2 GB — too small, don't.) | ~£11/mo |
| 3 | **Retire `HCWeb` + its dedicated `Harrier` B1 plan** | **29 requests in 30 days.** It serves `admin.harriercentral.com`, the legacy web admin, superseded by `portal.harriercentral.com` running on a **Free** static web app (`HcPortal`). | ~£11/mo |

#2 is reversible in minutes if anything feels slow. #3 needs your confirmation
that nothing still depends on `admin.harriercentral.com`; the DNS CNAME would
need retiring with it.

---

## Free wins — no saving, removes clutter and confusion

- **`HarrierCentralMapAPI` (Azure Maps, tier G2): 0 transactions in 30 days.**
  The mobile app uses Google Maps and public-web uses Leaflet, so nothing calls
  it. No fixed fee on G2, so this is tidiness rather than money.
- **Orphaned storage accounts, all 0.00 GB**, left behind when their function
  apps were deleted: `hcazurefunctions8c3d208`, `hcazurefunctions92cbfde`,
  `hcportalapi`, `harrier97d5`. Their resource groups (`hcazurefunctions8`,
  `hcazurefunctions9`, `hcportalapi`) then hold nothing but alert rules.
- **`archive` App Service plan** (F1 Free, 0 sites) — costs nothing, means nothing.
- **Three unused Log Analytics workspaces** in RG HarrierCentral:
  `workspaceharriercentral824e`, `...bc74`, `...b3c0`. No Application Insights
  component points at any of them; they are leftovers from repeated deployments.
- **20 smart-detector alert rules** across the subscription — free, but noise.
- **Duplicate/test Logic Apps**: `GCalBackup2` is Enabled while `GCalBackup` is
  Disabled; `test_email_send` and `HashRunsDotOrgTest` are Enabled. Consumption
  Logic Apps bill per action, so enabled test flows are a slow drip.

---

## ⚠️ Not a cost issue — telemetry is probably broken

**`harriercentralpublicapi` Application Insights points at
`workspace-hcazurefunctions8`, and that workspace no longer exists**
(`ResourceNotFound`). That is the Application Insights instance for the LIVE
API. Workspace-based App Insights writes into its linked workspace, so
production telemetry is likely being dropped — which also explains why the
ingestion-volume metric returns nothing.

Worth fixing regardless of cost: relink the component to a workspace you keep
(consolidate onto one), or recreate it. Do this before deleting any workspace.

Also: `harriercentralapi` (RG harrier) is a second, legacy App Insights pointing
at `DefaultWorkspace-...-NEU`. Probably superseded by `harriercentralpublicapi`.

---

## Storage replication — small money, easy

Total storage across all 13 accounts is only ~17 GB, so this is pennies, but:

| Account | Replication | Size | Note |
|---|---|---|---|
| `harriercentralbackup` | **GRS** (2× LRS) | 5.28 GB | Geo-redundancy on a backup may be deliberate — your call |
| `hcazurefunctionstest` | **GRS** | 0.04 GB | A *test* account paying for geo-redundancy |
| `decisionmeter` | **RAGRS** (~2.5× LRS) | 0.02 GB | Different project, read-access geo-redundant for 20 MB |

---

## Not Harrier Central at all

These belong to other ventures. Listed so you can decide, not deleted:

| Resource group | Contents |
|---|---|
| `DIG` | `defenseinnovation.eu` DNS zone, Key Vault, autoscale settings, metric alerts |
| `IVE` | activity-log alerts, smart-detector rules |
| `dianaosapi` | 8 resources — Logic App `box-token-exchange` (Enabled) + API connections |
| `dianaosapi2` | App Insights, Log Analytics workspace, FlexConsumption plan, storage |
| `dianaosoauth2` | App Insights, storage |
| `azureapp-auto-alerts-…defenceinnovation_eu` | action group + activity-log alert |
| `cloud-shell-storage-westeurope` | 5 GB Cloud Shell storage — delete if you don't use Cloud Shell |
| In RG HarrierCentral | **`DecisionMeter` SQL database (Basic, ~£3.70/mo)** + `decisionmeter` storage |

`DecisionMeter` is the only one of these with a standing monthly charge worth
naming — drop it if that project is dormant.

---

## Leave alone — already optimal

- **Function app `harriercentralpublicapi`** on Y1 Consumption: 1,959 executions
  in 30 days, far inside the 1M/month free grant. Effectively £0. Do not move
  it to a dedicated plan.
- **`ASP-harriercentralpublicweb-linux`** (B1, 2 sites): hosts the live public
  web. 789 requests/30 days is low, but F1 Free gives no custom-domain SSL and
  caps CPU at 60 min/day — not viable for `www.hashruns.org`. `harriercentraltsaeats`
  shares this plan, so it adds no cost; leave it there.
- **Notification Hubs**: Free tier. **Both static web apps**: Free tier.
- **`harriercentral` storage** (6.59 GB, LRS) — the app's blob storage. Fine.
- The six `HC_*` Logic Apps in RG `harrier` are real DB maintenance
  (backups, index rebuilds, statistics, run-count updates). Keep.

---

---

## Actions taken — 2026-08-31

| # | Action | Status |
|---|---|---|
| 1 | `hcwebapi-app-service-plan` (empty B1) | **Gone.** Not deleted by us — it was present at the start of the session and absent an hour later. Azure auto-deletes App Service plans left with zero sites. Verified `ResourceNotFound`. |
| 3 | `HCWeb` / `Harrier` plan **B1 → F1 Free** | **Done**, in place of deletion. Site kept, custom domain given up. |

### What was changed on HCWeb, in order

F1 Free does not support custom domains at all, so the binding and its cert had
to come off before the plan would scale:

1. `alwaysOn` **true → false** (unsupported on Free)
2. Hostname binding `admin.harriercentral.com` **removed**
3. App Service Managed Certificate `admin.harriercentral.com-HCWeb` (RG `harrier`) **deleted**
4. `use32BitWorkerProcess` **false → true** — the scale-down was rejected until
   this changed: *"Cannot update the site 'HCWeb' because it uses x64 worker
   process which is not allowed in the target compute mode."* Free/Shared are
   32-bit only.
5. Plan `Harrier` **B1 Basic → F1 Free**

### Verified after

- `https://hcweb.azurewebsites.net/` → 302 → `/Account/Login` → **200**, renders
  `<title>Login - HcWeb</title>`. Same behaviour as before the change.
- `https://admin.harriercentral.com/` → TLS failure (curl exit 60). Expected:
  the cert is gone.

### Still outstanding

- **The `admin.harriercentral.com` CNAME still points at `hcweb.azurewebsites.net`.**
  Harmless while HCWeb exists, but it is a dangling-CNAME subdomain-takeover risk
  the moment the site is deleted. Retire the DNS record when HCWeb goes.
- Free tier caps CPU at 60 min/day and has no SLA. At 0 requests/30 days that is
  academic, but it is why this is a holding position, not a permanent home.

### Rollback (if the site is ever needed on a domain again)

```bash
az appservice plan update -n Harrier -g HarrierCentral --sku B1
az webapp config set -n HCWeb -g HarrierCentral --use-32bit-worker-process false --always-on true
az webapp config hostname add --webapp-name HCWeb -g HarrierCentral \
  --hostname admin.harriercentral.com          # CNAME must still resolve
az webapp config ssl create -g HarrierCentral --name HCWeb \
  --hostname admin.harriercentral.com          # re-issue free managed cert
```

Remaining from the original three: **#2, SQL `HarrierCentralWebDb` S1 → S0.**

---

## Bottom line

~**£33/month (~£400/year)** from the three actions at the top, none of which a
user would notice. The rest is clutter with little money attached — worth doing
for clarity, and because the dead workspace link is actively costing you
production telemetry.

Sequence: fix the App Insights workspace link first (#⚠️), then the three
savings actions, then delete the chaff.

---

## Maintenance reschedule — 2026-08-31 (done)

Prerequisite for the S0 downgrade. The old chain packed five jobs into 110
minutes, and the 00:00 index rebuild was *already* saturating 20 DTU at
00:25–00:30 — i.e. still running when the 00:30 backup started. Halving DTU
would have made that overlap worse.

| Job | Was (UTC) | Now (UTC) |
|---|---|---|
| `HC_rebiuld_indexes` | 00:00 | **00:00** (unchanged — heaviest, now has 90 min clear) |
| `HC_backup_tables` | 00:30 | **01:30** |
| `HC_clean_bad_characters` | 00:45 | **02:15** |
| `HC_update_counts_credits` | 00:50 | **02:45** |
| `HC_update_statistics` | 01:50 | **03:30** |
| `HC_recompile_stored_procedures` (weekly) | 01:30 | **04:30** |

Applied by ARM PUT (`api-version=2019-05-01`); original definitions backed up
before the change. All six verified `Enabled` with the new recurrence. Traffic
in 00:00–05:00 UTC is near zero — the daytime peak is 16:00–19:00 UTC.

---

## Where the database space actually is — 2026-08-31

**7.06 GB used against a 10 GB max-size cap (66%).** The cap is set explicitly
on the database, not by the tier — S0 and S1 both allow 250 GB. Hitting it makes
writes fail, so this matters independently of the SKU decision.

| Object | Data | Index | **Total** | Share of DB |
|---|---|---|---|---|
| `LOG.GeneralLog` | 1,787 MB | **2,165 MB** | **3,952 MB** | **56%** |
| `HC.IntegrationJob` | 721 MB | 632 MB | **1,353 MB** | **19%** |
| `HC_BACKUP` + `_7` + `_30` (16 tables each) | — | — | 525 MB | 7% |
| Everything else | — | — | ~1.2 GB | 18% |

### The backup schemas are not the problem

All three rotate correctly (last written 08-31, 08-30, 08-01 respectively) and
cost **175 MB each**. Dropping two of the three windows recovers ~350 MB — 5% of
the database — and gives up the research value they exist for. Not worth it.

### Age profile of the two big tables

| Table | Range | Rows | Older than 90 days |
|---|---|---|---|
| `LOG.GeneralLog` | 2025-12-28 → today | 3,451,852 | **2,885,337 (84%)** |
| `HC.IntegrationJob` | 2023-05-23 → today | 749,914 | **717,461 (96%)** |

Nothing in `GeneralLog` is older than a year, so something already prunes at ~12
months. Tightening that to 90 days would free roughly **3.3 GB** — about half
the database.

### Index worth watching, NOT yet worth dropping

`IX_GeneralLog_Timestamp_LogSource` is **1,814 MB — larger than the table's own
data** — with 0 reads and 13,167 writes recorded. But
`sqlserver_start_time` is **2026-08-28**, so usage stats cover only 3 days, and
today is month-end. Per [[project_sp_index_audit]] the rule is to confirm over a
representative period (full sync + month-end + integration cycle) before any
DROP. Re-check after ~a week. Row pruning shrinks it anyway.

### Sequence if pruning goes ahead

1. Prune in **batches** (e.g. 50k rows with a delay) — a 2.9M-row single delete
   would itself saturate DTU and bloat the log.
2. Do it **before** the S0 downgrade, while 20 DTU is available.
3. Deleted space stays allocated to the file and still counts toward the 10 GB
   cap. The nightly index rebuild reclaims most of it; a `DBCC SHRINKFILE` may be
   needed to actually drop allocated size.
