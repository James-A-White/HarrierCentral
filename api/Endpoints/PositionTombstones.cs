using Azure;
using Azure.Data.Tables;
using Microsoft.Extensions.Logging;

namespace HcWebApi.Endpoints
{
    /// <summary>
    /// A record that a track point was deleted, so a viewer polling for deltas
    /// can drop it (James, 2026-10-02: "we should always be using watermarks
    /// to download only deltas").
    ///
    /// An incremental GetPositions poll asks for rows that ARRIVED since the
    /// viewer's mark. A deleted row never arrives again, so before this the
    /// only way a viewer learned of a delete was a full re-download: the app
    /// took one every 5 minutes as a safety net, the web on every poll. Three
    /// things delete points, all small and rare: a resumed runner's On Inn
    /// (PositionWriter), a LOST mark cleared by the all clear or moved by a
    /// re-announce, and an admin trim boundary (both DeletePositions).
    ///
    /// Where they live: the EventTrackingControl table, partition = eventId,
    /// RowKey = "del-" + the deleted point's RowKey. NOT EventPositions —
    /// every reader of that table scans a run's whole partition and would
    /// have to learn to skip them, and tools/backfill_event_track.sh walks
    /// its partition keys. EventTrackingControl is only ever read by point
    /// lookup of the fixed "control" row, so these rows are invisible to it.
    /// The storage service stamps each row's Timestamp, so the same mark the
    /// viewer already carries finds the tombstones written since.
    ///
    /// Best-effort on both sides: a failed write leaves the point on a
    /// watcher's map until their next full fetch (a reload), never fails the
    /// delete; a failed read returns no removals.
    /// </summary>
    internal static class PositionTombstones
    {
        internal const string RowKeyPrefix = "del-";
        // '-' + 1 — the exclusive upper bound of the "del-" RowKey range.
        private const string RowKeyEnd = "del.";

        internal sealed record Removed(string UserId, long TimestampMs, string? Type);

        internal static async Task WriteAsync(
            TableServiceClient tables,
            string eventId,
            string userId,
            IEnumerable<(string RowKey, string? TimestampMs, string? Type)> rows,
            ILogger log)
        {
            try
            {
                TableClient control = tables.GetTableClient(EndEventTracking.ControlTableName);
                await control.CreateIfNotExistsAsync();
                foreach (var (rowKey, timestampMs, type) in rows)
                {
                    if (string.IsNullOrEmpty(timestampMs)) continue;
                    var entity = new TableEntity(eventId, RowKeyPrefix + rowKey)
                    {
                        ["UserId"] = userId,
                        ["TimestampMs"] = timestampMs,
                    };
                    if (!string.IsNullOrEmpty(type)) entity["Type"] = type;
                    await control.UpsertEntityAsync(entity, TableUpdateMode.Replace);
                }
            }
            catch (Exception ex)
            {
                log.LogWarning("PositionTombstones: write failed for event {EventId} / user {UserId}: {Message}.",
                    eventId, userId, ex.Message);
            }
        }

        /// <summary>
        /// Tombstones that arrived at or after <paramref name="from"/>, and
        /// the newest arrival among them (epoch-ms) so the caller can move the
        /// viewer's mark past them.
        /// </summary>
        internal static async Task<(List<Removed> Removed, long LatestArrivalMs)> ReadSinceAsync(
            TableServiceClient tables,
            string eventId,
            DateTimeOffset from,
            ILogger log)
        {
            var removed = new List<Removed>();
            long latest = 0;
            try
            {
                TableClient control = tables.GetTableClient(EndEventTracking.ControlTableName);
                string pk = eventId.Replace("'", "''");
                string filter =
                    $"PartitionKey eq '{pk}' and RowKey ge '{RowKeyPrefix}' and RowKey lt '{RowKeyEnd}'" +
                    $" and Timestamp ge datetime'{from.UtcDateTime:yyyy-MM-ddTHH:mm:ss.fffffffZ}'";
                await foreach (TableEntity e in control.QueryAsync<TableEntity>(filter))
                {
                    string? userId = e.GetString("UserId");
                    if (string.IsNullOrWhiteSpace(userId)) continue;
                    if (!long.TryParse(e.GetString("TimestampMs"), out long ts)) continue;
                    removed.Add(new Removed(userId, ts, e.GetString("Type")));
                    if (e.Timestamp.HasValue)
                    {
                        latest = Math.Max(latest, e.Timestamp.Value.ToUnixTimeMilliseconds());
                    }
                }
            }
            catch (RequestFailedException ex) when (ex.Status == 404)
            {
                // No control table yet: nothing was ever deleted.
            }
            catch (Exception ex)
            {
                log.LogWarning("PositionTombstones: read failed for event {EventId}: {Message}.", eventId, ex.Message);
            }
            return (removed, latest);
        }
    }
}
