#!/usr/bin/env bash
# =====================================================================
# tools/backfill_event_track_runners.sh — seed HC.EventTrackRunner
#
# One row per (run, hasher) that has PackTrack points. For every run in
# HC.EventTrack with no runner rows yet, asks GetPositions (the same call
# the app makes; gzip; one request per run — never a table scan) and
# records each runner's point count and first/last timestamps. Idempotent:
# runs already holding runner rows are skipped. Run ONCE after
# db/hc6/app/2026-09-10_create_EventTrackRunner.sql, before the API that
# keeps the table current (1.0.40) is deployed.
#
# Needs: curl, jq, sqlcmd, .env, and the GetPositions key (read from
# mobile-app/lib/util/constants.dart, never printed).
# =====================================================================
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
set -a; # shellcheck disable=SC1091
source "$REPO_ROOT/.env"; set +a
KEY=$(grep -A1 "GET_POSITIONS_API_KEY =" "$REPO_ROOT/mobile-app/lib/util/constants.dart" | tail -1 | tr -d " ';")
[ -n "$KEY" ] || { echo "no GetPositions key"; exit 1; }
URL="https://harriercentralpublicapi.azurewebsites.net/api/GetPositions"

SQL() { sqlcmd -S "$HC_SQL_SERVER" -d "$HC_SQL_DATABASE" -U "$HC_SQL_USERNAME" -P "$HC_SQL_PASSWORD" -C -W -h -1 "$@"; }
TMP=$(mktemp); trap 'rm -f "$TMP"' EXIT
echo "SET NOCOUNT ON; CREATE TABLE #r (EventId UNIQUEIDENTIFIER, UserId UNIQUEIDENTIFIER, FirstMs BIGINT, LastMs BIGINT, PointCount INT);" > "$TMP"
events=0; rows=0
while read -r eid; do
  [ -z "$eid" ] && continue
  events=$((events+1))
  body=$(curl -sS --compressed -X POST "$URL" -H "Content-Type: application/json" -H "X-Api-Key: $KEY" \
         -d "{\"eventId\":\"$eid\",\"AfterTimestamp\":\"0000000000000000000\",\"users\":[]}")
  # one line per runner: userId firstMs lastMs count
  while read -r uid first last count; do
    [ -z "${uid:-}" ] && continue
    echo "INSERT #r VALUES ('$eid', '$uid', $first, $last, $count);" >> "$TMP"
    rows=$((rows+1))
  done < <(echo "$body" | jq -r '.users[]? | select((.positions|length) > 0) |
             "\(.id|ascii_downcase) \([.positions[].timestampMs]|min) \([.positions[].timestampMs]|max) \(.positions|length)"')
done < <(SQL -Q "SET NOCOUNT ON; SELECT LOWER(CAST(t.EventId AS NVARCHAR(36))) FROM HC.EventTrack t WHERE NOT EXISTS (SELECT 1 FROM HC.EventTrackRunner r WHERE r.EventId = t.EventId);" | tr -d '\r' | sed 's/[[:space:]]*$//')
cat >> "$TMP" <<'EOSQL'
INSERT HC.EventTrackRunner (EventId, UserId, FirstPointAt, LastPointAt, PointCount)
SELECT r.EventId, r.UserId,
       DATEADD(MILLISECOND, r.FirstMs % 1000, DATEADD(SECOND, r.FirstMs / 1000, '1970-01-01')),
       DATEADD(MILLISECOND, r.LastMs  % 1000, DATEADD(SECOND, r.LastMs  / 1000, '1970-01-01')),
       r.PointCount
FROM #r r
WHERE NOT EXISTS (SELECT 1 FROM HC.EventTrackRunner e WHERE e.EventId = r.EventId AND e.UserId = r.UserId);
SELECT @@ROWCOUNT AS inserted, (SELECT COUNT(*) FROM HC.EventTrackRunner) AS totalRows,
       (SELECT COUNT(DISTINCT EventId) FROM HC.EventTrackRunner) AS runsWithRunners;
DROP TABLE #r;
EOSQL
echo "runs asked: $events; runner rows found: $rows"
sqlcmd -S "$HC_SQL_SERVER" -d "$HC_SQL_DATABASE" -U "$HC_SQL_USERNAME" -P "$HC_SQL_PASSWORD" -C -W -s '|' -i "$TMP"
