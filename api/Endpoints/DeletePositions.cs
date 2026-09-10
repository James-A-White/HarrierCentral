using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using Azure;
using System.Data;
using Azure.Data.Tables;
using Microsoft.Data.SqlClient;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;

namespace HcWebApi.Endpoints
{
    // Removes specific stored track points for a single runner on a single
    // event, identified by their caller timestamps. Deliberately narrow:
    //   - Guarded by the same X-Api-Key as GetPositions (StorePositions is open,
    //     but a delete is more destructive, so we require the key).
    //   - Only ever deletes points whose UserId matches the request, so a caller
    //     can never remove another runner's track.
    // Used by the mobile app to (a) strip an On-Inn terminator when a stopped
    // track is resumed so the continuation renders as one line, and (b) clear or
    // move an admin start/end boundary marker.
    public class DeletePositions
    {
        private readonly ILogger<DeletePositions> _log;
        private readonly TableServiceClient _tableServiceClient;

        public DeletePositions(ILogger<DeletePositions> logger)
        {
            _log = logger;
            string storageConnection = Environment.GetEnvironmentVariable("AzureWebJobsStorage")
                ?? throw new InvalidOperationException("AzureWebJobsStorage is not set in the environment.");
            _tableServiceClient = new TableServiceClient(storageConnection);
        }

        [Function("DeletePositions")]
        public async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Anonymous, "post")] HttpRequest req)
        {
            // API key check — same guard as GetPositions.
            string? expectedKey = Environment.GetEnvironmentVariable("ApiKey");
            string? providedKey = req.Headers.TryGetValue("X-Api-Key", out var headerVal)
                ? headerVal.ToString()
                : req.Query["apiKey"].ToString();
            if (string.IsNullOrEmpty(expectedKey) || providedKey != expectedKey)
            {
                return new UnauthorizedObjectResult("Unauthorized");
            }

            string body;
            using (var reader = new StreamReader(req.Body))
            {
                body = await reader.ReadToEndAsync();
            }

            DeletePositionsRequest? request;
            try
            {
                request = JsonConvert.DeserializeObject<DeletePositionsRequest>(body);
            }
            catch (Exception ex)
            {
                _log.LogError(ex, "DeletePositions: failed to deserialize payload.");
                return CreateJsonResult(StatusCodes.Status400BadRequest, new { error = "Invalid JSON payload." });
            }

            if (request == null
                || string.IsNullOrWhiteSpace(request.EventId)
                || string.IsNullOrWhiteSpace(request.UserId))
            {
                return CreateJsonResult(StatusCodes.Status400BadRequest, new { error = "Missing required fields: eventId or userId." });
            }

            // Normalise the requested timestamps to the 19-digit form stored in
            // the TimestampMs column / RowKey caller segment.
            var wanted = new HashSet<string>(
                (request.Timestamps ?? new List<string>())
                    .Where(t => !string.IsNullOrWhiteSpace(t))
                    .Select(NormalizeTimestamp),
                StringComparer.Ordinal);

            if (wanted.Count == 0)
            {
                return CreateJsonResult(StatusCodes.Status200OK, new { deleted = 0 });
            }

            const string eventTableName = "EventPositions"; // PK = eventId, RK = callerTs-userId (legacy rows: serverTs-callerTs)
            const string userTableName = "UserPositions";    // PK = userId,  RK = callerTs-userId (legacy rows: serverTs-callerTs)
            TableClient eventTable = _tableServiceClient.GetTableClient(eventTableName);
            TableClient userTable = _tableServiceClient.GetTableClient(userTableName);
            await eventTable.CreateIfNotExistsAsync();
            await userTable.CreateIfNotExistsAsync();

            // Scan this runner's points on the event and collect the RowKeys whose
            // caller timestamp was requested. StorePositions writes an identical
            // composite RowKey to both tables, so the same RowKey deletes the
            // event-partition and user-partition copies of a point.
            string filter =
                $"PartitionKey eq '{EscapeForFilter(request.EventId)}' and UserId eq '{EscapeForFilter(request.UserId)}'";

            var rowKeysToDelete = new List<string>();
            await foreach (var entity in eventTable.QueryAsync<TableEntity>(filter))
            {
                string? ts = entity.GetString("TimestampMs") ?? ExtractCallerTimestampFromRowKey(entity.RowKey);
                if (ts != null && wanted.Contains(NormalizeTimestamp(ts)))
                {
                    rowKeysToDelete.Add(entity.RowKey);
                }
            }

            int deleted = 0;
            foreach (var rowKey in rowKeysToDelete)
            {
                // Delete both copies. Missing entities (404) are ignored so the
                // call is idempotent and a partial prior delete can be retried.
                bool removed = false;
                removed |= await TryDeleteAsync(eventTable, request.EventId, rowKey);
                removed |= await TryDeleteAsync(userTable, request.UserId, rowKey);
                if (removed) deleted++;
            }

            _log.LogInformation(
                "DeletePositions: removed {Deleted} point(s) for event {EventId} / user {UserId}.",
                deleted, request.EventId, request.UserId);

            if (deleted > 0)
            {
                await ForgetEmptyTrackAsync(eventTable, filter, request.EventId, request.UserId);
            }

            return CreateJsonResult(StatusCodes.Status200OK, new { deleted });
        }

        /// Any delete makes the archived copy of this runner's track (TrackGzip,
        /// E5.F6.S4) stale, so it is dropped; the boot sweep rebuilds it from
        /// what remains. When the runner's LAST point on the run has gone, the
        /// track summary on their attendance row is cleared too — and
        /// HC.EventTrack goes once no runner is left — so a deleted track stops
        /// counting on the run's card. The table's updatedAt trigger ignores a
        /// track-only write, so the row is not re-synced for it. Best-effort: a
        /// SQL failure never turns into a failed delete.
        private async Task ForgetEmptyTrackAsync(TableClient eventTable, string filter, string eventId, string userId)
        {
            if (!Guid.TryParse(eventId, out Guid eventGuid) || !Guid.TryParse(userId, out Guid userGuid))
            {
                return;
            }
            string? connectionString = Environment.GetEnvironmentVariable("HcDbConnectionString");
            if (string.IsNullOrWhiteSpace(connectionString))
            {
                return;
            }
            try
            {
                bool trackRemains = false;
                await foreach (var _ in eventTable.QueryAsync<TableEntity>(filter, maxPerPage: 1, select: new[] { "RowKey" }))
                {
                    trackRemains = true; // the runner still has points on this run
                    break;
                }
                using SqlConnection conn = new(connectionString);
                await conn.OpenAsync();
                if (trackRemains)
                {
                    using SqlCommand staleCmd = new(
                        "UPDATE HC.HasherEventMap SET TrackGzip = NULL " +
                        " WHERE EventId = @eventId AND UserId = @userId;",
                        conn)
                    {
                        CommandTimeout = 5
                    };
                    staleCmd.Parameters.Add("@eventId", SqlDbType.UniqueIdentifier).Value = eventGuid;
                    staleCmd.Parameters.Add("@userId", SqlDbType.UniqueIdentifier).Value = userGuid;
                    await staleCmd.ExecuteNonQueryAsync();
                    return;
                }
                using SqlCommand cmd = new(
                    "UPDATE HC.HasherEventMap " +
                    "   SET TrackFirstPointAt = NULL, TrackLastPointAt = NULL, TrackPointCount = NULL, TrackGzip = NULL " +
                    " WHERE EventId = @eventId AND UserId = @userId; " +
                    "DELETE HC.EventTrack WHERE EventId = @eventId " +
                    "  AND NOT EXISTS (SELECT 1 FROM HC.HasherEventMap h WHERE h.EventId = @eventId AND h.TrackPointCount > 0);",
                    conn)
                {
                    CommandTimeout = 5
                };
                cmd.Parameters.Add("@eventId", SqlDbType.UniqueIdentifier).Value = eventGuid;
                cmd.Parameters.Add("@userId", SqlDbType.UniqueIdentifier).Value = userGuid;
                await cmd.ExecuteNonQueryAsync();
            }
            catch (Exception ex)
            {
                _log.LogWarning("DeletePositions: HasherEventMap track cleanup failed for event {EventId} / user {UserId}: {Message}.",
                    eventId, userId, ex.Message);
            }
        }

        private static async Task<bool> TryDeleteAsync(TableClient table, string partitionKey, string rowKey)
        {
            try
            {
                var resp = await table.DeleteEntityAsync(partitionKey, rowKey, ETag.All);
                return resp.Status is >= 200 and < 300;
            }
            catch (RequestFailedException ex) when (ex.Status == 404)
            {
                return false;
            }
        }

        private const int TimestampLength = 19;

        private static string NormalizeTimestamp(string candidate)
        {
            string digitsOnly = new string(candidate.Where(char.IsDigit).ToArray());
            if (digitsOnly.Length == 0) return new string('0', TimestampLength);
            return digitsOnly.Length >= TimestampLength
                ? digitsOnly.Substring(digitsOnly.Length - TimestampLength, TimestampLength)
                : digitsOnly.PadLeft(TimestampLength, '0');
        }

        private static string? ExtractCallerTimestampFromRowKey(string? rowKey)
        {
            if (string.IsNullOrWhiteSpace(rowKey)) return null;
            int dashIndex = rowKey.IndexOf('-');
            return dashIndex >= 0 && dashIndex + 1 < rowKey.Length
                ? rowKey.Substring(dashIndex + 1)
                : rowKey;
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

        internal class DeletePositionsRequest
        {
            [JsonProperty("eventId")] public string EventId { get; set; } = string.Empty;
            [JsonProperty("userId")] public string UserId { get; set; } = string.Empty;
            [JsonProperty("timestamps")] public List<string>? Timestamps { get; set; }
        }
    }
}
