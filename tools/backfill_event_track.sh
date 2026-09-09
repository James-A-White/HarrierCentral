#!/usr/bin/env bash
# =====================================================================
# tools/backfill_event_track.sh — seed HC.EventTrack from Azure Table Storage
#
# One row per run that has ever stored a PackTrack point. Walks the distinct
# partition keys of EventPositions (PK = eventId; one request per event —
# do NOT scan the table, see memory reference_packtrack_event_enumeration),
# takes the first row's TimestampMs as FirstPointAt, and inserts any event
# not already in HC.EventTrack. Idempotent. Run ONCE after
# db/hc6/app/2026-09-10_create_EventTrack.sql, before the API that keeps
# the table current is deployed — the API takes over from there.
#
# Needs: az (logged in), sqlcmd, .env, and the function app's storage
# connection string (read from its app settings, never printed).
# =====================================================================
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
set -a; # shellcheck disable=SC1091
source "$REPO_ROOT/.env"; set +a

CS=$(az functionapp config appsettings list -n harriercentralpublicapi -g harriercentralpublicapi \
     --only-show-errors --query "[?name=='AzureWebJobsStorage'].value" -o tsv)
[ -n "$CS" ] || { echo "no storage connection string"; exit 1; }

TMP=$(mktemp); trap 'rm -f "$TMP"' EXIT
pk=""; n=0
echo "SET NOCOUNT ON; CREATE TABLE #t (EventId UNIQUEIDENTIFIER, FirstPointAt DATETIME2(3));" > "$TMP"
while :; do
  row=$(az storage entity query -t EventPositions --connection-string "$CS" \
        --filter "PartitionKey gt '$pk'" --num-results 1 --select PartitionKey RowKey TimestampMs \
        --only-show-errors --query "items[0].[PartitionKey, RowKey, TimestampMs]" -o tsv)
  [ -z "$row" ] && break
  pk=$(echo "$row" | cut -f1); rk=$(echo "$row" | cut -f2); ts=$(echo "$row" | cut -f3)
  # TimestampMs is the caller's 19-digit epoch ms; legacy rows carry it in the RowKey
  ms=${ts:-${rk%%-*}}; ms=$((10#${ms:-0}))
  if [[ "$pk" =~ ^[0-9a-f-]{36}$ ]] && [ "$ms" -gt 0 ]; then
    echo "INSERT #t VALUES ('$pk', DATEADD(MILLISECOND, $((ms % 1000)), DATEADD(SECOND, $((ms / 1000)), '1970-01-01')));" >> "$TMP"
    n=$((n+1))
  fi
done
cat >> "$TMP" <<'SQL'
INSERT HC.EventTrack (EventId, FirstPointAt, LastPointAt, PointCount)
SELECT t.EventId, t.FirstPointAt, NULL, 0
FROM #t t WHERE NOT EXISTS (SELECT 1 FROM HC.EventTrack e WHERE e.EventId = t.EventId);
SELECT @@ROWCOUNT AS inserted, (SELECT COUNT(*) FROM HC.EventTrack) AS totalRows;
DROP TABLE #t;
SQL
echo "events found in Table Storage: $n"
sqlcmd -S "$HC_SQL_SERVER" -d "$HC_SQL_DATABASE" -U "$HC_SQL_USERNAME" -P "$HC_SQL_PASSWORD" -C -W -s '|' -i "$TMP"
