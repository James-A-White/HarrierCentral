using System;
using System.Collections.Generic;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Text;
using Azure.Data.Tables;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;

namespace HcWebApi.Endpoints
{
    public class GetPositions
    {
        private readonly ILogger<GetPositions> _log;
        private readonly TableServiceClient _tableServiceClient;

        public GetPositions(ILogger<GetPositions> logger)
        {
            _log = logger;
            string storageConnection = Environment.GetEnvironmentVariable("AzureWebJobsStorage")
                ?? throw new InvalidOperationException("AzureWebJobsStorage is not set in the environment.");
            _tableServiceClient = new TableServiceClient(storageConnection);
        }

        [Function("GetPositions")]
        public async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Anonymous, "get", "post")] HttpRequest req)
        {
            var request = await BuildRequestAsync(req);
            if (request == null || string.IsNullOrWhiteSpace(request.EventId))
            {
                return new BadRequestObjectResult("An eventId is required in the query string or request body.");
            }

            const string eventTableName = "EventPositions"; // PK = eventId, RK = serverTs-callerTs
            TableClient eventTable = _tableServiceClient.GetTableClient(eventTableName);
            await eventTable.CreateIfNotExistsAsync();

            _log.LogInformation("Fetching positions for event {EventId} (user: {UserId}, after: {AfterTimestamp})",
                request.EventId,
                request.UserId ?? "<all>",
                request.AfterTimestamp ?? "<none>");

            string filter = BuildEventTableFilter(request);
            var userLookup = new Dictionary<string, List<PositionResponse>>(StringComparer.OrdinalIgnoreCase);
            long? afterTimestampBoundary = ParseTimestampToLong(request.AfterTimestamp);
            string? latestServerTimestamp = null;

            await foreach (var entity in eventTable.QueryAsync<TableEntity>(filter))
            {
                string? userId = entity.GetString("UserId");
                double? latitude = entity.GetDouble("Latitude");
                double? longitude = entity.GetDouble("Longitude");
                double? accuracy = entity.GetDouble("Accuracy");
                string? serverTimestamp = entity.GetString("ServerTimestampMs") ?? ExtractServerTimestampFromRowKey(entity.RowKey);
                string? positionType = entity.GetString("Type");

                if (string.IsNullOrWhiteSpace(userId) || latitude is null || longitude is null || accuracy is null)
                {
                    continue;
                }

                string? timestampText = entity.GetString("TimestampMs") ?? ExtractTimestampFromRowKey(entity.RowKey);
                if (!long.TryParse(timestampText, out long timestampMs))
                {
                    continue;
                }

                if (!string.IsNullOrWhiteSpace(serverTimestamp) &&
                    (latestServerTimestamp == null || string.CompareOrdinal(serverTimestamp, latestServerTimestamp) > 0))
                {
                    latestServerTimestamp = serverTimestamp;
                }

                // if (afterTimestampBoundary.HasValue && timestampMs <= afterTimestampBoundary.Value)
                // {
                //     continue;
                // }

                if (!userLookup.TryGetValue(userId, out var positions))
                {
                    positions = new List<PositionResponse>();
                    userLookup[userId] = positions;
                }

                positions.Add(new PositionResponse
                {
                    Latitude = RoundCoordinate(latitude.Value),
                    Longitude = RoundCoordinate(longitude.Value),
                    Accuracy = RoundCoordinate(accuracy.Value),
                    TimestampMs = timestampMs,
                    Type = positionType
                });
            }

            var response = new EventPositionsResponse
            {
                EventId = request.EventId,
                LatestServerTimestamp = latestServerTimestamp,
                Users = userLookup
                    .OrderBy(kvp => kvp.Key, StringComparer.OrdinalIgnoreCase)
                    .Select(kvp => new UserPositionsResponse
                    {
                        Id = kvp.Key,
                        Positions = kvp.Value
                            .OrderBy(p => p.TimestampMs)
                            .ToList()
                    })
                    .ToList()
            };

            string json = JsonConvert.SerializeObject(
                response,
                Formatting.None,
                new JsonSerializerSettings
                {
                    NullValueHandling = NullValueHandling.Ignore
                });

            byte[] compressedPayload = CompressToGzip(json);
            req.HttpContext.Response.Headers["Content-Encoding"] = "gzip";

            return new FileContentResult(compressedPayload, "application/json");
        }

        private static async Task<GetPositionsRequest?> BuildRequestAsync(HttpRequest req)
        {
            string? eventId = GetQueryValue(req, "eventId");
            string? userId = GetQueryValue(req, "userId");
            string? afterTimestamp = GetFirstQueryValue(req,
                "afterTimestampMs",
                "afterTimestamp",
                "lastTimestampMs",
                "lastTimestamp",
                "sinceTimestampMs",
                "sinceTimestamp");

            if (!req.Body.CanRead)
            {
                return new GetPositionsRequest
                {
                    EventId = eventId ?? string.Empty,
                    UserId = userId,
                    AfterTimestamp = afterTimestamp
                };
            }

            string body;
            using (var reader = new StreamReader(req.Body))
            {
                body = await reader.ReadToEndAsync();
            }

            if (string.IsNullOrWhiteSpace(body))
            {
                return new GetPositionsRequest
                {
                    EventId = eventId ?? string.Empty,
                    UserId = userId,
                    AfterTimestamp = afterTimestamp
                };
            }

            try
            {
                var payload = JsonConvert.DeserializeObject<GetPositionsRequest>(body);
                if (payload == null)
                {
                    return new GetPositionsRequest
                    {
                        EventId = eventId ?? string.Empty,
                        UserId = userId,
                        AfterTimestamp = afterTimestamp
                    };
                }

                payload.EventId = string.IsNullOrWhiteSpace(payload.EventId) ? (eventId ?? string.Empty) : payload.EventId;
                payload.UserId ??= userId;
                payload.AfterTimestamp ??= afterTimestamp;
                return payload;
            }
            catch
            {
                return new GetPositionsRequest
                {
                    EventId = eventId ?? string.Empty,
                    UserId = userId,
                    AfterTimestamp = afterTimestamp
                };
            }
        }

        private static string? GetQueryValue(HttpRequest req, string key)
        {
            if (req.Query.TryGetValue(key, out var values) && values.Count > 0)
            {
                return values[0];
            }

            if (req.Query.TryGetValue(char.ToUpperInvariant(key[0]) + key.Substring(1), out values) && values.Count > 0)
            {
                return values[0];
            }

            return null;
        }

        private static string? GetFirstQueryValue(HttpRequest req, params string[] keys)
        {
            foreach (var key in keys)
            {
                string? value = GetQueryValue(req, key);
                if (!string.IsNullOrWhiteSpace(value))
                {
                    return value;
                }
            }

            return null;
        }

        private const int RowKeySegmentLength = 19;
        private const string ZeroRowKeySegment = "0000000000000000000";
        private const string DefaultRowKeyLowerBound = "0000000000000000000-0000000000000000000";

        private static string BuildEventTableFilter(GetPositionsRequest request)
        {
            string rowKeyLowerBound = NormalizeRowKeyLowerBound(request.AfterTimestamp);

            var filter = $"PartitionKey eq '{EscapeForFilter(request.EventId)}' and RowKey ge '{EscapeForFilter(rowKeyLowerBound)}'";
            if (!string.IsNullOrWhiteSpace(request.UserId))
            {
                filter += $" and UserId eq '{EscapeForFilter(request.UserId)}'";
            }

            return filter;
        }

        private static string NormalizeRowKeyLowerBound(string? timestamp)
        {
            if (string.IsNullOrWhiteSpace(timestamp))
            {
                return DefaultRowKeyLowerBound;
            }

            string trimmed = timestamp.Trim();
            int dashIndex = trimmed.IndexOf('-');
            if (dashIndex >= 0)
            {
                string serverPartRaw = dashIndex > 0 ? trimmed.Substring(0, dashIndex) : string.Empty;
                string callerPartRaw = dashIndex + 1 < trimmed.Length ? trimmed.Substring(dashIndex + 1) : string.Empty;
                string serverPart = NormalizeRowKeySegment(serverPartRaw);
                string callerPart = NormalizeRowKeySegment(callerPartRaw);
                return $"{serverPart}-{callerPart}";
            }

            string normalizedServer = NormalizeRowKeySegment(trimmed);
            return $"{normalizedServer}-{ZeroRowKeySegment}";
        }

        private static string NormalizeRowKeySegment(string candidate)
        {
            if (string.IsNullOrWhiteSpace(candidate))
            {
                return ZeroRowKeySegment;
            }

            string digitsOnly = new string(candidate.Where(char.IsDigit).ToArray());
            if (digitsOnly.Length == 0)
            {
                return ZeroRowKeySegment;
            }

            return digitsOnly.Length >= RowKeySegmentLength
                ? digitsOnly.Substring(digitsOnly.Length - RowKeySegmentLength, RowKeySegmentLength)
                : digitsOnly.PadLeft(RowKeySegmentLength, '0');
        }

        private static long? ParseTimestampToLong(string? timestamp)
        {
            if (string.IsNullOrWhiteSpace(timestamp))
            {
                return null;
            }

            string trimmed = timestamp.Trim();

            int dashIndex = trimmed.IndexOf('-');
            if (dashIndex >= 0 && dashIndex + 1 < trimmed.Length)
            {
                trimmed = trimmed.Substring(dashIndex + 1);
            }

            string digitsOnly = new string(trimmed.Where(char.IsDigit).ToArray());
            if (digitsOnly.Length == 0)
            {
                return null;
            }

            return long.TryParse(digitsOnly, out long parsed) ? parsed : null;
        }

        private static string EscapeForFilter(string value) => value.Replace("'", "''");

        private static string? ExtractTimestampFromRowKey(string? rowKey)
        {
            if (string.IsNullOrWhiteSpace(rowKey))
            {
                return null;
            }

            int dashIndex = rowKey.IndexOf('-');
            if (dashIndex >= 0 && dashIndex + 1 < rowKey.Length)
            {
                return rowKey.Substring(dashIndex + 1);
            }

            return rowKey;
        }

        private static string? ExtractServerTimestampFromRowKey(string? rowKey)
        {
            if (string.IsNullOrWhiteSpace(rowKey))
            {
                return null;
            }

            int dashIndex = rowKey.IndexOf('-');
            return dashIndex > 0 ? rowKey.Substring(0, dashIndex) : null;
        }

        private static double RoundCoordinate(double value)
            => Math.Round(value, 5, MidpointRounding.AwayFromZero);

        private static byte[] CompressToGzip(string content)
        {
            byte[] payloadBytes = Encoding.UTF8.GetBytes(content);
            using var output = new MemoryStream();
            using (var gzip = new GZipStream(output, CompressionLevel.Fastest, leaveOpen: true))
            {
                gzip.Write(payloadBytes, 0, payloadBytes.Length);
            }

            return output.ToArray();
        }

        // Payload models
        internal class GetPositionsRequest
        {
            [JsonProperty("eventId")] public string EventId { get; set; } = string.Empty;
            [JsonProperty("userId")] public string? UserId { get; set; }
            [JsonProperty("afterTimestampMs")] public string? AfterTimestamp { get; set; }
        }

        internal class EventPositionsResponse
        {
            [JsonProperty("eventId")] public string EventId { get; set; } = string.Empty;
            [JsonProperty("latestServerTimestampMs", NullValueHandling = NullValueHandling.Ignore)] public string? LatestServerTimestamp { get; set; }
            [JsonProperty("users")] public List<UserPositionsResponse> Users { get; set; } = new();
        }

        internal class UserPositionsResponse
        {
            [JsonProperty("id")] public string Id { get; set; } = string.Empty;
            [JsonProperty("positions")] public List<PositionResponse> Positions { get; set; } = new();
        }

        internal class PositionResponse
        {
            [JsonProperty("lat")] public double Latitude { get; set; }
            [JsonProperty("lng")] public double Longitude { get; set; }
            [JsonProperty("acc")] public double Accuracy { get; set; }
            [JsonProperty("timestampMs")] public long TimestampMs { get; set; }
            [JsonProperty("type", NullValueHandling = NullValueHandling.Ignore)] public string? Type { get; set; }
        }
    }
}
