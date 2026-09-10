using System;
using System.Data;
using System.IO;
using Azure.Data.Tables;
using Microsoft.Data.SqlClient;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace HcWebApi.Endpoints
{
    public class StorePositions
    {
        private readonly ILogger<StorePositions> _log;
        private readonly TableServiceClient _tableServiceClient;

        public StorePositions(ILogger<StorePositions> logger)
        {
            _log = logger;
            string storageConnection = Environment.GetEnvironmentVariable("AzureWebJobsStorage")
                ?? throw new InvalidOperationException("AzureWebJobsStorage is not set in the environment.");
            _tableServiceClient = new TableServiceClient(storageConnection);
        }

        [Function("StorePositions")]
        public async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Anonymous, "post")] HttpRequest req)
        {
            string body;
            using (var reader = new StreamReader(req.Body))
            {
                body = await reader.ReadToEndAsync();
            }

            if (string.IsNullOrWhiteSpace(body))
            {
                return CreateJsonResult(StatusCodes.Status400BadRequest, new { error = "Empty request body." });
            }

            PositionsPayload? payload;
            try
            {
                payload = JsonConvert.DeserializeObject<PositionsPayload>(body);
            }
            catch (Exception ex)
            {
                _log.LogError(ex, "Failed to deserialize payload.");
                return CreateJsonResult(StatusCodes.Status400BadRequest, new { error = "Invalid JSON payload." });
            }

            if (payload == null || string.IsNullOrWhiteSpace(payload.EventId) || string.IsNullOrWhiteSpace(payload.UserId))
            {
                return CreateJsonResult(StatusCodes.Status400BadRequest, new { error = "Missing required fields: eventId or userId." });
            }
            if (payload.Positions == null || payload.Positions.Count == 0)
            {
                return CreateJsonResult(StatusCodes.Status400BadRequest, new { error = "No positions provided." });
            }

            // Table names (can be adjusted if you prefer different names)
            const string eventTableName = "EventPositions";    // PK = eventId, RK = callerTs-userId (legacy rows: serverTs-callerTs)
            const string userTableName = "UserPositions";      // PK = userId, RK = callerTs-userId (legacy rows: serverTs-callerTs)

            TableClient eventTable = _tableServiceClient.GetTableClient(eventTableName);
            TableClient userTable = _tableServiceClient.GetTableClient(userTableName);

            await eventTable.CreateIfNotExistsAsync();
            await userTable.CreateIfNotExistsAsync();

            // Resume cleanup: the first batch after a stop→restart carries
            // resumed=true. A trail has exactly one On Inn, at the end — a
            // terminator followed by later points is always a mistake (the
            // runner tapped it, then resumed), so delete any terminator rows
            // this user already has on this event before storing the new
            // batch. This closes the race where the client's own resume-time
            // strip (DeletePositions) runs before the mark's in-flight batch
            // has landed (observed on LH3 #2846, 2026-08-15). Best-effort: a
            // cleanup failure never blocks the position store.
            int resumeDeleted = 0;
            if (payload.Resumed)
            {
                try
                {
                    string filter =
                        $"PartitionKey eq '{EscapeForFilter(payload.EventId)}' and UserId eq '{EscapeForFilter(payload.UserId)}' and Type ne ''";
                    await foreach (TableEntity row in eventTable.QueryAsync<TableEntity>(
                        filter: filter, select: new[] { "RowKey", "Type" }))
                    {
                        string? rowType = row.TryGetValue("Type", out var t) ? t?.ToString() : null;
                        if (!IsTerminatorType(rowType)) continue;
                        try { await eventTable.DeleteEntityAsync(payload.EventId, row.RowKey); }
                        catch (Azure.RequestFailedException ex) when (ex.Status == 404) { }
                        try { await userTable.DeleteEntityAsync(payload.UserId, row.RowKey); }
                        catch (Azure.RequestFailedException ex) when (ex.Status == 404) { }
                        resumeDeleted++;
                    }
                    if (resumeDeleted > 0)
                    {
                        _log.LogInformation(
                            "StorePositions: resume cleanup deleted {Count} terminator(s) for event {EventId} / user {UserId}.",
                            resumeDeleted, payload.EventId, payload.UserId);
                    }
                }
                catch (Exception ex)
                {
                    _log.LogWarning(
                        "StorePositions: resume terminator cleanup failed for event {EventId}: {Message}. Continuing with store.",
                        payload.EventId, ex.Message);
                }
            }

            int storedCount = 0;
            string serverTimestamp = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds().ToString("D19");

            foreach (var pos in payload.Positions)
            {
                // Normalize timestamp to 19 digits (pad left with zeros).
                string tsDigits = pos.Timestamp?.Trim() ?? string.Empty;
                if (tsDigits.Length == 0)
                {
                    _log.LogWarning($"Skipping position with invalid timestamp format: '{tsDigits}'. Expected numeric digits.");
                    continue;
                }
                String ts = tsDigits.PadLeft(19, '0');

                // RowKey must be deterministic per logical point so that a
                // re-sent batch (the client retries on timeout, and a batch the
                // server stored but whose response was lost stays queued for
                // the next flush) Replaces the same rows instead of storing
                // duplicates. Caller timestamp + userId identifies a point;
                // the server arrival time lives in the ServerTimestampMs
                // property, which readers already prefer over the RowKey.
                // The same composite key is written to both tables —
                // DeletePositions depends on that invariant.
                string compositeRowKey = $"{ts}-{payload.UserId}";

                string? typeCode = pos.Type?.Trim();
                bool hasValidType = !string.IsNullOrWhiteSpace(typeCode);
                // Type field format: "<KEY>" (3 chars) or "<KEY>::<label>"
                // PHO markers embed the full run folder + filename in the label
                // (e.g. "PHO::shhh-456/userId-photoGuid.jpg" ≈ 91 chars), so the
                // limit must accommodate that. 200 is a safe ceiling that still
                // guards against accidentally large payloads.
                if (hasValidType && typeCode!.Length > 200)
                {
                    _log.LogWarning($"Ignoring type value (length {typeCode!.Length}) for event {payload.EventId} / user {payload.UserId} — exceeds 200-char limit.");
                    hasValidType = false;
                }

                // Entity keyed by Event (PK=eventId, RK=callerTs-userId)
                var entityByEvent = new TableEntity(payload.EventId, compositeRowKey)
                {
                    {"UserId", payload.UserId},
                    {"EventId", payload.EventId},
                    {"TimestampMs", ts},
                    {"ServerTimestampMs", serverTimestamp},
                    {"Latitude", pos.Latitude},
                    {"Longitude", pos.Longitude},
                    {"Altitude", pos.Altitude},
                    {"Accuracy", pos.Accuracy}
                };

                if (hasValidType)
                {
                    entityByEvent["Type"] = typeCode!;
                }


                // Entity keyed by User (PK=userId, RK=callerTs-userId)
                var entityByUser = new TableEntity(payload.UserId, compositeRowKey)
                {
                    {"UserId", payload.UserId},
                    {"EventId", payload.EventId},
                    {"TimestampMs", ts},
                    {"ServerTimestampMs", serverTimestamp},
                    {"Latitude", pos.Latitude},
                    {"Longitude", pos.Longitude},
                    {"Altitude", pos.Altitude},
                    {"Accuracy", pos.Accuracy}
                };

                if (hasValidType)
                {
                    entityByUser["Type"] = typeCode!;
                }


                await eventTable.UpsertEntityAsync(entityByEvent, TableUpdateMode.Replace);
                await userTable.UpsertEntityAsync(entityByUser, TableUpdateMode.Replace);
                storedCount++;
            }

            // Record in SQL that this run has a track — one MERGE per accepted
            // batch, never per point. Until this, the only record that a run
            // was tracked was Table Storage itself (E5.F6.S3). Best-effort:
            // a SQL hiccup never turns into a failed store.
            await RecordEventTrackAsync(payload.EventId, payload.UserId, storedCount);

            // Piggyback the event-level "tracking ended" flag (set by an admin
            // via EndEventTracking) on the response: every phone still
            // uploading points sees it within one flush interval and stops its
            // tracking loop — no push needed, and it reaches exactly the
            // phones that are still transmitting. Best-effort: a read failure
            // never turns into a failed store.
            string? trackingEndedAtMs = null;
            try
            {
                TableClient controlTable =
                    _tableServiceClient.GetTableClient(EndEventTracking.ControlTableName);
                var control = await controlTable.GetEntityIfExistsAsync<TableEntity>(
                    payload.EventId, EndEventTracking.ControlRowKey);
                if (control.HasValue &&
                    control.Value!.TryGetValue(EndEventTracking.EndedAtProperty, out var endedVal))
                {
                    trackingEndedAtMs = endedVal?.ToString();
                }
            }
            catch (Exception ex)
            {
                _log.LogWarning(
                    "StorePositions: tracking-ended flag read failed for event {EventId}: {Message}.",
                    payload.EventId, ex.Message);
            }

            var result = new Dictionary<string, object?> { ["stored"] = storedCount };
            if (payload.Resumed) result["resumedTerminatorsDeleted"] = resumeDeleted;
            if (trackingEndedAtMs != null)
            {
                result["trackingEnded"] = true;
                result["trackingEndedAtMs"] = trackingEndedAtMs;
            }
            return CreateJsonResult(StatusCodes.Status200OK, result);
        }

        /// True when a stored Type string marks the end of the track: the
        /// legacy OIN key, or any new-style mark whose action is endRun
        /// (e.g. "GLY::oninn::A=endRun"). Mirrors the mobile map's _isOnInn.
        private static bool IsTerminatorType(string? type)
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

        private static string EscapeForFilter(string value) => value.Replace("'", "''");

        private static ContentResult CreateJsonResult(int statusCode, object payload)
        {
            string json = JsonConvert.SerializeObject(payload);
            return new ContentResult
            {
                StatusCode = statusCode,
                ContentType = "application/json",
                Content = json
            };
        }

        // Payload models
        internal class PositionsPayload
        {
            [JsonProperty("eventId")] public string EventId { get; set; } = string.Empty;
            [JsonProperty("userId")] public string UserId { get; set; } = string.Empty;
            [JsonProperty("positions")] public List<PositionItem> Positions { get; set; } = new();
            // First batch after a stop→restart: asks the server to delete any
            // prior terminator (On Inn) rows for this user+event. Optional —
            // absent/false from older clients, and ignored by older servers.
            [JsonProperty("resumed")] public bool Resumed { get; set; }
        }

        internal class PositionItem
        {
            // 19-digit zero-padded milliseconds since Unix epoch
            [JsonProperty("ts")] public string Timestamp { get; set; } = string.Empty;
            [JsonProperty("lat")] public double Latitude { get; set; }
            [JsonProperty("lng")] public double Longitude { get; set; }
            [JsonProperty("acc")] public double? Accuracy { get; set; }
            [JsonProperty("alt")] public double? Altitude { get; set; }
            [JsonProperty("type")] public string? Type { get; set; }
        }

        /// <summary>
        /// Upserts HC.EventTrack for <paramref name="eventId"/>: first point time on
        /// insert, last point time and running point count on every batch.
        /// </summary>
        private async Task RecordEventTrackAsync(string eventId, string userId, int storedCount)
        {
            if (storedCount <= 0 || !Guid.TryParse(eventId, out Guid eventGuid))
            {
                return;
            }
            string? connectionString = Environment.GetEnvironmentVariable("HcDbConnectionString");
            if (string.IsNullOrWhiteSpace(connectionString))
            {
                _log.LogWarning("StorePositions: HcDbConnectionString not set — HC.EventTrack not recorded.");
                return;
            }
            try
            {
                using SqlConnection conn = new(connectionString);
                await conn.OpenAsync();
                using SqlCommand cmd = new(
                    "MERGE HC.EventTrack WITH (HOLDLOCK) AS t " +
                    "USING (SELECT @eventId AS EventId) AS s ON t.EventId = s.EventId " +
                    "WHEN MATCHED THEN UPDATE SET LastPointAt = SYSUTCDATETIME(), " +
                    "    PointCount = t.PointCount + @stored, UpdatedAt = SYSUTCDATETIME() " +
                    "WHEN NOT MATCHED THEN INSERT (EventId, FirstPointAt, LastPointAt, PointCount, UpdatedAt) " +
                    "    VALUES (@eventId, SYSUTCDATETIME(), SYSUTCDATETIME(), @stored, SYSUTCDATETIME());",
                    conn)
                {
                    CommandTimeout = 5
                };
                cmd.Parameters.Add("@eventId", SqlDbType.UniqueIdentifier).Value = eventGuid;
                cmd.Parameters.Add("@stored", SqlDbType.Int).Value = storedCount;
                await cmd.ExecuteNonQueryAsync();

                // This runner's own summary on their attendance row (E3.F3.S7):
                // the count beside the PackTrack icon, and where the stored
                // trail will sit later. The app checks the tracker in as At
                // Hash when tracking starts, so the row exists; a batch that
                // arrives before it does is simply not counted. The table's
                // updatedAt trigger ignores a write that changes only these three
                // columns (they are in no sync rowset), so the row is not re-synced
                // to every client once a minute.
                //
                // A new batch also drops any archive already written (TrackGzip,
                // E5.F6.S4): the archive is the track as it stood when tracking
                // stopped, and a point arriving after it means the runner
                // resumed. ArchiveTrack rebuilds it when they stop again, and the
                // boot sweep catches a track whose stop never reached us.
                if (Guid.TryParse(userId, out Guid userGuid))
                {
                    using SqlCommand hemCmd = new(
                        "UPDATE HC.HasherEventMap " +
                        "   SET TrackFirstPointAt = ISNULL(TrackFirstPointAt, SYSUTCDATETIME()), " +
                        "       TrackLastPointAt  = SYSUTCDATETIME(), " +
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
                    int hemRows = await hemCmd.ExecuteNonQueryAsync();
                    if (hemRows == 0)
                    {
                        _log.LogInformation(
                            "StorePositions: no attendance row yet for event {EventId} / user {UserId} — {Stored} point(s) not counted.",
                            eventId, userId, storedCount);
                    }
                }
            }
            catch (Exception ex)
            {
                _log.LogWarning("StorePositions: HC.EventTrack upsert failed for event {EventId}: {Message}.",
                    eventId, ex.Message);
            }
        }

    }
}
