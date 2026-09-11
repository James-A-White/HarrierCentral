using System.Data;
using Azure.Data.Tables;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Logging;

namespace HcWebApi.Endpoints
{
    /// <summary>
    /// One point as written to the position store: capture time (epoch-ms),
    /// position, optional accuracy/altitude, optional mark type.
    /// </summary>
    public sealed record WritePoint(long TimestampMs, double Latitude, double Longitude, double? Accuracy, double? Altitude, string? Type);

    /// <summary>
    /// The one way PackTrack points get into Table Storage and the SQL
    /// summaries — used by StorePositions (the phone's batches) and by the
    /// track-import processor (files), so an imported trail is
    /// indistinguishable from a tracked one downstream: same tables, same
    /// RowKeys, same HasherEventMap / EventTrack bookkeeping, same archive
    /// invalidation. Extracted from StorePositions on 2026-09-11.
    /// </summary>
    public static class PositionWriter
    {
        public const string EventTableName = "EventPositions"; // PK = eventId, RK = callerTs-userId (legacy rows: serverTs-callerTs)
        public const string UserTableName = "UserPositions";   // PK = userId,  RK = callerTs-userId (legacy rows: serverTs-callerTs)

        public sealed record Outcome(int Stored, int ResumeDeleted);

        /// <summary>
        /// Upserts <paramref name="points"/> for <paramref name="userId"/> on
        /// <paramref name="eventId"/> (both the lowercased ids the app uses),
        /// then records the batch on the run's and the runner's SQL rows.
        /// </summary>
        public static async Task<Outcome> WriteAsync(
            TableServiceClient tables, ILogger log, string eventId, string userId,
            IReadOnlyList<WritePoint> points, bool resumed = false)
        {
            TableClient eventTable = tables.GetTableClient(EventTableName);
            TableClient userTable = tables.GetTableClient(UserTableName);
            await eventTable.CreateIfNotExistsAsync();
            await userTable.CreateIfNotExistsAsync();

            // Resume cleanup: the first batch after a stop→restart carries
            // resumed=true. A trail has exactly one On Inn, at the end — a
            // terminator followed by later points is always a mistake (the
            // runner tapped it, then resumed), so delete any terminator rows
            // this user already has on this event before storing the new
            // batch. Best-effort: a cleanup failure never blocks the store.
            int resumeDeleted = 0;
            if (resumed)
            {
                try
                {
                    string filter =
                        $"PartitionKey eq '{EscapeForFilter(eventId)}' and UserId eq '{EscapeForFilter(userId)}' and Type ne ''";
                    await foreach (TableEntity row in eventTable.QueryAsync<TableEntity>(
                        filter: filter, select: new[] { "RowKey", "Type" }))
                    {
                        string? rowType = row.TryGetValue("Type", out var t) ? t?.ToString() : null;
                        if (!IsTerminatorType(rowType)) continue;
                        try { await eventTable.DeleteEntityAsync(eventId, row.RowKey); }
                        catch (Azure.RequestFailedException ex) when (ex.Status == 404) { }
                        try { await userTable.DeleteEntityAsync(userId, row.RowKey); }
                        catch (Azure.RequestFailedException ex) when (ex.Status == 404) { }
                        resumeDeleted++;
                    }
                }
                catch (Exception ex)
                {
                    log.LogWarning("PositionWriter: resume terminator cleanup failed for event {EventId}: {Message}. Continuing with store.",
                        eventId, ex.Message);
                }
            }

            int storedCount = 0;
            long minTs = long.MaxValue, maxTs = long.MinValue;
            string serverTimestamp = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds().ToString("D19");

            foreach (WritePoint pos in points)
            {
                if (pos.TimestampMs <= 0) continue;
                string ts = pos.TimestampMs.ToString("D19");

                // RowKey must be deterministic per logical point so that a
                // re-sent batch Replaces the same rows instead of storing
                // duplicates. The same composite key is written to both
                // tables — DeletePositions depends on that invariant.
                string compositeRowKey = $"{ts}-{userId}";

                string? typeCode = pos.Type?.Trim();
                bool hasValidType = !string.IsNullOrWhiteSpace(typeCode);
                if (hasValidType && typeCode!.Length > 200)
                {
                    log.LogWarning("PositionWriter: ignoring type value (length {Len}) for event {EventId} / user {UserId} — exceeds 200-char limit.",
                        typeCode!.Length, eventId, userId);
                    hasValidType = false;
                }

                TableEntity Build(string pk, string rk)
                {
                    var e = new TableEntity(pk, rk)
                    {
                        {"UserId", userId},
                        {"EventId", eventId},
                        {"TimestampMs", ts},
                        {"ServerTimestampMs", serverTimestamp},
                        {"Latitude", pos.Latitude},
                        {"Longitude", pos.Longitude},
                        {"Altitude", pos.Altitude},
                        {"Accuracy", pos.Accuracy}
                    };
                    if (hasValidType) e["Type"] = typeCode!;
                    return e;
                }

                await eventTable.UpsertEntityAsync(Build(eventId, compositeRowKey), TableUpdateMode.Replace);
                await userTable.UpsertEntityAsync(Build(userId, compositeRowKey), TableUpdateMode.Replace);
                storedCount++;
                if (pos.TimestampMs < minTs) minTs = pos.TimestampMs;
                if (pos.TimestampMs > maxTs) maxTs = pos.TimestampMs;
            }

            if (storedCount > 0)
            {
                await RecordAsync(log, eventId, userId, storedCount, minTs, maxTs);
            }
            return new Outcome(storedCount, resumeDeleted);
        }

        /// True when a stored Type string marks the end of the track: the
        /// legacy OIN key, or any new-style mark whose action is endRun
        /// (e.g. "GLY::oninn::A=endRun"). Mirrors the mobile map's _isOnInn.
        public static bool IsTerminatorType(string? type)
        {
            if (string.IsNullOrWhiteSpace(type)) return false;
            string[] parts = type.Split(new[] { "::" }, StringSplitOptions.None);
            if (parts[0].Trim() == "OIN") return true;
            foreach (string part in parts)
            {
                if (part.Trim() == "A=endRun") return true;
            }
            return false;
        }

        public static string EscapeForFilter(string value) => value.Replace("'", "''");

        /// <summary>
        /// The SQL side of a batch: HC.EventTrack (the run has a track) and the
        /// runner's HasherEventMap summary. First/last are the points' CAPTURE
        /// times, not the clock at arrival — a file imported months after the
        /// run must say when the run was, and a run must not resurface as
        /// "recently tracked" because somebody imported it (until 2026-09-11
        /// both were stamped with the arrival time). The updatedAt trigger
        /// ignores track-only writes. A later batch also drops the archive
        /// (TrackGzip); the nightly rebuilds it. Best-effort: a SQL hiccup never
        /// turns into a failed store.
        /// </summary>
        private static async Task RecordAsync(ILogger log, string eventId, string userId, int storedCount, long minTs, long maxTs)
        {
            if (!Guid.TryParse(eventId, out Guid eventGuid)) return;
            string? connectionString = Environment.GetEnvironmentVariable("HcDbConnectionString");
            if (string.IsNullOrWhiteSpace(connectionString))
            {
                log.LogWarning("PositionWriter: HcDbConnectionString not set — HC.EventTrack not recorded.");
                return;
            }
            DateTime firstAt = DateTimeOffset.FromUnixTimeMilliseconds(minTs).UtcDateTime;
            DateTime lastAt = DateTimeOffset.FromUnixTimeMilliseconds(maxTs).UtcDateTime;
            try
            {
                using SqlConnection conn = new(connectionString);
                await conn.OpenAsync();
                using SqlCommand cmd = new(
                    "MERGE HC.EventTrack WITH (HOLDLOCK) AS t " +
                    "USING (SELECT @eventId AS EventId) AS s ON t.EventId = s.EventId " +
                    "WHEN MATCHED THEN UPDATE SET " +
                    "    FirstPointAt = CASE WHEN @firstAt < t.FirstPointAt THEN @firstAt ELSE t.FirstPointAt END, " +
                    "    LastPointAt  = CASE WHEN t.LastPointAt IS NULL OR @lastAt > t.LastPointAt THEN @lastAt ELSE t.LastPointAt END, " +
                    "    PointCount = t.PointCount + @stored, UpdatedAt = SYSUTCDATETIME() " +
                    "WHEN NOT MATCHED THEN INSERT (EventId, FirstPointAt, LastPointAt, PointCount, UpdatedAt) " +
                    "    VALUES (@eventId, @firstAt, @lastAt, @stored, SYSUTCDATETIME());",
                    conn)
                {
                    CommandTimeout = 5
                };
                cmd.Parameters.Add("@eventId", SqlDbType.UniqueIdentifier).Value = eventGuid;
                cmd.Parameters.Add("@stored", SqlDbType.Int).Value = storedCount;
                cmd.Parameters.Add("@firstAt", SqlDbType.DateTime2).Value = firstAt;
                cmd.Parameters.Add("@lastAt", SqlDbType.DateTime2).Value = lastAt;
                await cmd.ExecuteNonQueryAsync();

                if (Guid.TryParse(userId, out Guid userGuid))
                {
                    using SqlCommand hemCmd = new(
                        "UPDATE HC.HasherEventMap " +
                        "   SET TrackFirstPointAt = CASE WHEN TrackFirstPointAt IS NULL OR @firstAt < TrackFirstPointAt THEN @firstAt ELSE TrackFirstPointAt END, " +
                        "       TrackLastPointAt  = CASE WHEN TrackLastPointAt  IS NULL OR @lastAt  > TrackLastPointAt  THEN @lastAt  ELSE TrackLastPointAt  END, " +
                        "       TrackPointCount   = ISNULL(TrackPointCount, 0) + @stored, " +
                        "       TrackGzip         = NULL " +
                        " WHERE EventId = @eventId AND UserId = @userId AND removed = 0;",
                        conn)
                    {
                        CommandTimeout = 5
                    };
                    hemCmd.Parameters.Add("@eventId", SqlDbType.UniqueIdentifier).Value = eventGuid;
                    hemCmd.Parameters.Add("@userId", SqlDbType.UniqueIdentifier).Value = userGuid;
                    hemCmd.Parameters.Add("@stored", SqlDbType.Int).Value = storedCount;
                    hemCmd.Parameters.Add("@firstAt", SqlDbType.DateTime2).Value = firstAt;
                    hemCmd.Parameters.Add("@lastAt", SqlDbType.DateTime2).Value = lastAt;
                    int hemRows = await hemCmd.ExecuteNonQueryAsync();
                    if (hemRows == 0)
                    {
                        log.LogInformation("PositionWriter: no attendance row yet for event {EventId} / user {UserId} — {Stored} point(s) not counted.",
                            eventId, userId, storedCount);
                    }
                }
            }
            catch (Exception ex)
            {
                log.LogWarning("PositionWriter: SQL summary failed for event {EventId}: {Message}.", eventId, ex.Message);
            }
        }
    }
}
