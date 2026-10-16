# Azure Key Vault — runbook (E18.F3.S6)

Prepared 2026-10-16 for James to run with Claude on 2026-10-17. Goal: every
secret the API and the public web use lives in ONE vault, and the app settings
hold only Key Vault references, so a secret is never in code, in a storage
blob, or readable in the portal. Code does not change: an app setting keeps
its NAME and the platform resolves `@Microsoft.KeyVault(SecretUri=…)` into the
same environment variable.

Rule for every step: **nothing may disrupt production.** Each step has a test
and a rollback, and the next step starts only when the test passes.

## What is already true (checked 2026-10-16)

| Fact | Value |
|---|---|
| Subscription role (James) | Owner — can create a vault and grant roles |
| `Microsoft.KeyVault` provider | Registered |
| API `harriercentralpublicapi` | Consumption plan (Y1), North Europe, **system-assigned identity ON** |
| Web `harriercentralpublicweb` | North Europe, **no identity yet** |
| Existing vaults | `DigKeyVault` (another project, RG DIG) — not used |
| API code | `FirebaseCredentials` reads `FIREBASE_CREDENTIALS_JSON` first (commit 0238e3e3, not yet deployed), else the private blob |

An app-settings change restarts the app (seconds on Y1). Batch several setting
changes into ONE `appsettings set` call so there is one restart, not many.

## Phase 1 — the vault (no effect on production)

```bash
az keyvault create -n hc-keyvault -g HarrierCentral -l northeurope \
  --enable-rbac-authorization true --enable-purge-protection true --retention-days 90
VAULT_ID=$(az keyvault show -n hc-keyvault --query id -o tsv)
# James manages secrets
az role assignment create --role "Key Vault Secrets Officer" \
  --assignee "$(az ad signed-in-user show --query id -o tsv)" --scope "$VAULT_ID"
# The API reads them
az role assignment create --role "Key Vault Secrets User" \
  --assignee-object-id d3b7bfe8-ea91-4294-b38b-f10af5f7a1be \
  --assignee-principal-type ServicePrincipal --scope "$VAULT_ID"
```
Test: `az keyvault secret list --vault-name hc-keyvault` works (empty).
Rollback: none needed — nothing reads the vault yet. (Purge protection means a
deleted vault name is held for 90 days; pick the name once.)

## Phase 2 — Firebase key, rotated INTO the vault

1. Deploy the API with commit 0238e3e3 (inert until the setting exists).
2. James: Google Cloud console → the Firebase project → IAM → Service accounts →
   the firebase-adminsdk account → Keys → **Add key (JSON)**. Download it.
3. `az keyvault secret set --vault-name hc-keyvault -n firebase-credentials-json --file <downloaded.json>`
   then delete the downloaded file.
4. One settings change:
   `FIREBASE_CREDENTIALS_JSON=@Microsoft.KeyVault(VaultName=hc-keyvault;SecretName=firebase-credentials-json)`
5. Check the reference resolved: `az rest --method get --url
   "https://management.azure.com$(az functionapp show -g harriercentralpublicapi -n harriercentralpublicapi --query id -o tsv)/config/configreferences/appsettings/FIREBASE_CREDENTIALS_JSON?api-version=2022-03-01"`
   → `status: Resolved`.
6. Clear the cached push tokens (table `FcmTokensForAppApi`, PartitionKey
   `FcmTokens`, RowKeys `AppApiToken` / `PortalApiToken`; table
   `FcmTokensForInternalApi` RowKey `PortalApiToken`; all in the
   AzureWebJobsStorage account) and send a test push (a message in HCTEST-ABC's
   Mismanagement chat) → `HC.PushLog.FcmResult = success`.
7. James deletes the OLD key in Google Cloud. Test push again.
8. Overwrite the blob `credentials/firebase_credentials.json` with the NEW key
   (it stays the fallback) — or delete it once the vault has run a week.

Rollback at any point before step 7: remove the setting → the API falls back
to the blob (old key), pushes keep working.

## Phase 3 — the API's other secrets

Move in this order, one batch per restart, test after each:

| Batch | Settings | Test |
|---|---|---|
| A (low risk) | `ANTHROPIC_API_KEY`, `GITHUB_READ_TOKEN`, `IPINFO_API_TOKEN`, `AZURE_OPENAI_KEY`, `AZURE_MAPS_KEY`, `AzureMapsSubscriptionKey`, `BOX_CLIENT_SECRET` | KennelRemindersTest dry run; a geocode; beta room dry run |
| B (mail) | `HC_GRAPH_CLIENT_SECRET`, `HC_ACS_EMAIL_CONNECTION`, `HC_EVENTGRID_KEY` | a test email to James (Preview to me) |
| C (shared) | `HC_INTERNAL_SECRET` (API and web together — see Phase 4), `ApiKey` | KennelRemindersTest; GetPositions read |
| D (data) | `HcDbConnectionString`, `HC_AGENT_SQL_CONNECTION`, `HC_BLOB_STORAGE_CONNECTION_STRING`, `HC_AGENT_DEVICE_SECRET` | app checkConnection, a run list, a photo upload token, a test push |

Each: `az keyvault secret set` from the CURRENT value (read it with
`az functionapp config appsettings list … --query "[?name=='X'].value"`
straight into the `secret set` call — never echo it), then the batch's
settings change, then the reference-status check, then the test.
Rollback: set the setting back to its plain value (still in the vault).

**Never move:** `AzureWebJobsStorage`, `WEBSITE_CONTENTAZUREFILECONNECTIONSTRING`,
`WEBSITE_CONTENTSHARE`, `WEBSITE_RUN_FROM_PACKAGE`, `FUNCTIONS_*`,
`APPINSIGHTS_*` / `APPLICATIONINSIGHTS_CONNECTION_STRING` — the Functions host
reads these before references resolve, or they are not secrets.

## Phase 4 — the public web

1. `az webapp identity assign -g harrier -n harriercentralpublicweb` (one restart),
   grant that principal "Key Vault Secrets User" on the vault.
2. Move `HC_INTERNAL_SECRET` (same secret as the API's — one vault secret, both
   apps reference it), `GET_POSITIONS_API_KEY`, `HC_ADMIN_SESSION_SECRET`,
   `HC_MEMBER_SESSION_SECRET`, `AZURE_BLOB_SAS_URL`.
3. Test: a public kennel page, a member sign-in, a web-admin token, a PackTrack page.

Changing (not just moving) a session secret signs everyone out of the web —
rotate those only when James chooses.

## Phase 5 — rotation

Which keys must be rotated, and in what order, is in the PRIVATE plan
(`.local/permissions-audit-2026-10-16/rotation-plan.md`) — several are
exposed today, so the list stays out of this public repo until they are
rotated. General rule: a key is rotated by putting the NEW value in the vault
(new secret version), testing, then revoking the old one at its issuer.
