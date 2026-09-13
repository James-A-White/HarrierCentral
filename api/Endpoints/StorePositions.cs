using System;
using System.Data;
using System.IO;
using System.Linq;
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

            // Every point goes through the one writer that files use too
            // (PositionWriter): same tables, same RowKeys, same SQL summaries.
            var points = new List<WritePoint>(payload.Positions.Count);
            foreach (var pos in payload.Positions)
            {
                string tsDigits = pos.Timestamp?.Trim() ?? string.Empty;
                if (!long.TryParse(tsDigits, out long tsMs) || tsMs <= 0)
                {
                    _log.LogWarning($"Skipping position with invalid timestamp format: '{tsDigits}'. Expected numeric digits.");
                    continue;
                }
                points.Add(new WritePoint(tsMs, pos.Latitude, pos.Longitude, pos.Accuracy, pos.Altitude, pos.Type));
            }
            PositionWriter.Outcome written = await PositionWriter.WriteAsync(
                _tableServiceClient, _log, payload.EventId, payload.UserId, points, payload.Resumed);

            // A boundary marker changes the event's official window, which
            // GetPositions caches for five minutes. Without this the admin sets
            // a start or end, the point IS stored, and the map keeps drawing
            // the old window until the cache ages out — which reads as "it did
            // not work" and invites a second tap (James, 2026-09-13).
            if (points.Any(p => string.Equals(p.Type, "AST", StringComparison.OrdinalIgnoreCase)
                             || string.Equals(p.Type, "AEN", StringComparison.OrdinalIgnoreCase)))
            {
                GetPositions.InvalidateTrimWindow(payload.EventId);
                _log.LogInformation(
                    "StorePositions: boundary marker written for event {EventId} — trim window cache invalidated.",
                    payload.EventId);
            }
            int storedCount = written.Stored;
            int resumeDeleted = written.ResumeDeleted;

            // Record the GPS settings on the attendance row, once. Written only
            // when it differs from what is there, so the usual batch costs
            // nothing; a mid-run change to the setting overwrites, which is the
            // honest answer to "what was this recorded with" when it changed.
            // updatedAt is assigned to itself: the sync trigger skips its stamp
            // only for writes to the four track columns, and this is not one of
            // them, so a plain write would re-sync the row every time.
            if (!string.IsNullOrWhiteSpace(payload.Gps) && storedCount > 0)
            {
                try
                {
                    string? connectionString = Environment.GetEnvironmentVariable("HcDbConnectionString");
                    if (!string.IsNullOrWhiteSpace(connectionString))
                    {
                        using Microsoft.Data.SqlClient.SqlConnection gpsConn = new(connectionString);
                        await gpsConn.OpenAsync();
                        using Microsoft.Data.SqlClient.SqlCommand gpsCmd = new(
                            "UPDATE HC.HasherEventMap " +
                            "   SET TrackGpsSettings = @gps, updatedAt = updatedAt " +
                            " WHERE EventId = @eventId AND UserId = @userId AND removed = 0 " +
                            "   AND (TrackGpsSettings IS NULL OR TrackGpsSettings <> @gps);",
                            gpsConn)
                        { CommandTimeout = 10 };
                        gpsCmd.Parameters.Add("@gps", System.Data.SqlDbType.NVarChar, 400).Value =
                            payload.Gps!.Length > 400 ? payload.Gps!.Substring(0, 400) : payload.Gps!;
                        gpsCmd.Parameters.Add("@eventId", System.Data.SqlDbType.UniqueIdentifier).Value = Guid.Parse(payload.EventId);
                        gpsCmd.Parameters.Add("@userId", System.Data.SqlDbType.UniqueIdentifier).Value = Guid.Parse(payload.UserId);
                        await gpsCmd.ExecuteNonQueryAsync();
                    }
                }
                catch (Exception ex)
                {
                    // Never fail an upload of real positions over a note about
                    // the settings they were captured with.
                    _log.LogWarning(ex, "StorePositions: could not record GPS settings.");
                }
            }

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
            // The GPS parameters the phone actually used, as a JSON string
            // (2026-09-13). Stored against the track so a tier's name can be
            // interpreted later — the tiers have been redefined between builds.
            // Optional: absent from older clients, ignored by older servers.
            [JsonProperty("gps")] public string? Gps { get; set; }
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

    }
}
