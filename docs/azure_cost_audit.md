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

## Bottom line

~**£33/month (~£400/year)** from the three actions at the top, none of which a
user would notice. The rest is clutter with little money attached — worth doing
for clarity, and because the dead workspace link is actively costing you
production telemetry.

Sequence: fix the App Insights workspace link first (#⚠️), then the three
savings actions, then delete the chaff.
