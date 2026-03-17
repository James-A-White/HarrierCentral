using System.IO;
using Azure.Data.Tables;
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
            const string eventTableName = "EventPositions";    // PK = eventId, RK = serverTs-callerTs
            const string userTableName = "UserPositions";      // PK = userId, RK = serverTs-callerTs

            TableClient eventTable = _tableServiceClient.GetTableClient(eventTableName);
            TableClient userTable = _tableServiceClient.GetTableClient(userTableName);

            await eventTable.CreateIfNotExistsAsync();
            await userTable.CreateIfNotExistsAsync();

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

                string compositeRowKey = $"{serverTimestamp}-{ts}";

                string? typeCode = pos.Type?.Trim();
                bool hasValidType = !string.IsNullOrWhiteSpace(typeCode);
                if (hasValidType && typeCode!.Length > 54)
                {
                    _log.LogWarning($"Ignoring type value '{typeCode}' for event {payload.EventId} and user {payload.UserId}. Expected no more than 3 characters.");
                    hasValidType = false;
                }

                // Entity keyed by Event (PK=eventId, RK=timestamp|userId)
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


                // Entity keyed by User (PK=userId, RK=eventId|timestamp)
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

            return CreateJsonResult(StatusCodes.Status200OK, new { stored = storedCount });
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
