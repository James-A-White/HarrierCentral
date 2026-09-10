#!/usr/bin/env bash
# =====================================================================
# tools/backfill_hem_track_columns.sh — fill HC.HasherEventMap.Track* from
# Table Storage for runs tracked before the API wrote them (E3.F3.S7).
#
# For every run in HC.EventTrack, asks GetPositions (the app's own call;
# gzip; one request per run — never a table scan) and writes each runner's
# point count and first/last timestamps onto their EXISTING attendance row.
# A runner with no HasherEventMap row is listed, not created: since 3.0.x
# the app checks the tracker in as tracking starts, so only old tracks can
# be in that state. updatedAt is NOT bumped (the columns are in no sync
# rowset yet). Idempotent — rows already carrying a count are left alone.
# Run ONCE after db/hc6/app/2026-09-10_alter_HasherEventMap_track_columns.sql.
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
  while read -r uid first last count; do
    [ -z "${uid:-}" ] && continue
    echo "INSERT #r VALUES ('$eid', '$uid', $first, $last, $count);" >> "$TMP"
    rows=$((rows+1))
  done < <(echo "$body" | jq -r '.users[]? | select((.positions|length) > 0) |
             "\(.id|ascii_downcase) \([.positions[].timestampMs]|min) \([.positions[].timestampMs]|max) \(.positions|length)"')
done < <(SQL -Q "SET NOCOUNT ON; SELECT LOWER(CAST(EventId AS NVARCHAR(36))) FROM HC.EventTrack;" | tr -d '\r' | sed 's/[[:space:]]*$//')
cat >> "$TMP" <<'EOSQL'
-- updatedAt = updatedAt - bias makes the trigger's ELSE branch restore the
-- exact current value: no client sees these rows as changed.
UPDATE hem
   SET TrackFirstPointAt = DATEADD(MILLISECOND, r.FirstMs % 1000, DATEADD(SECOND, r.FirstMs / 1000, '1970-01-01')),
       TrackLastPointAt  = DATEADD(MILLISECOND, r.LastMs  % 1000, DATEADD(SECOND, r.LastMs  / 1000, '1970-01-01')),
       TrackPointCount   = r.PointCount,
       updatedAt         = DATEADD(MICROSECOND, -hem.updatedAtBias, hem.updatedAt)
FROM HC.HasherEventMap hem
JOIN #r r ON r.EventId = hem.EventId AND r.UserId = hem.UserId
WHERE hem.TrackPointCount IS NULL;
SELECT @@ROWCOUNT AS updated,
       (SELECT COUNT(*) FROM HC.HasherEventMap WHERE TrackPointCount > 0) AS hemRowsWithTrack,
       (SELECT COUNT(DISTINCT EventId) FROM HC.HasherEventMap WHERE TrackPointCount > 0) AS runsWithRunners;
-- Runners with points but no attendance row (old tracks only; not created here)
SELECT r.EventId, r.UserId, r.PointCount
FROM #r r
WHERE NOT EXISTS (SELECT 1 FROM HC.HasherEventMap h WHERE h.EventId = r.EventId AND h.UserId = r.UserId);
DROP TABLE #r;
EOSQL
echo "runs asked: $events; runner tracks found: $rows"
sqlcmd -S "$HC_SQL_SERVER" -d "$HC_SQL_DATABASE" -U "$HC_SQL_USERNAME" -P "$HC_SQL_PASSWORD" -C -W -s '|' -i "$TMP"
