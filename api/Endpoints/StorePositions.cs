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
            int storedCount = written.Stored;
            int resumeDeleted = written.ResumeDeleted;

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
