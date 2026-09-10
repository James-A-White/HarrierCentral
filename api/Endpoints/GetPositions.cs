using System;
using System.Collections.Generic;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Text;
using System.Data;
using Azure.Data.Tables;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Data.SqlClient;
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
            // API key check — accept key in header or query param
            string? expectedKey = Environment.GetEnvironmentVariable("ApiKey");
            string? providedKey = req.Headers.TryGetValue("X-Api-Key", out var headerVal)
                ? headerVal.ToString()
                : req.Query["apiKey"].ToString();
            if (string.IsNullOrEmpty(expectedKey) || providedKey != expectedKey)
            {
                return new UnauthorizedObjectResult("Unauthorized");
            }

            var request = await BuildRequestAsync(req);
            if (request == null || string.IsNullOrWhiteSpace(request.EventId))
            {
                return new BadRequestObjectResult("An eventId is required in the query string or request body.");
            }

            // Admin trim editor may also request the untrimmed track via query.
            request.IncludeTrimmed = request.IncludeTrimmed
                || string.Equals(GetQueryValue(req, "includeTrimmed"), "true", StringComparison.OrdinalIgnoreCase);

            // PK = eventId, RK = callerTs-userId (legacy rows: serverTs-callerTs).
            // Both key formats are 19-digit-epoch-ms-led, so the RowKey range
            // seek below works across both; per-point timestamps are read from
            // the TimestampMs / ServerTimestampMs properties, with RowKey
            // parsing only as a legacy fallback.
            const string eventTableName = "EventPositions";
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

            // Admin trim window (epoch-ms), derived from the newest AST/AEN
            // boundary markers and cached per event (5-min TTL). Looked up
            // independently of the returned range so incremental polls — whose
            // window is set by markers placed earlier, outside the polled range —
            // still filter correctly. Always resolved (for the response); only
            // ENFORCED for normal viewers — the admin editor (includeTrimmed)
            // gets the full track so it can drag the handles back outward.
            (long? trimStartMs, long? trimEndMs) = await GetTrimWindowAsync(eventTable, request.EventId);
            bool applyTrim = !request.IncludeTrimmed;

            // A finished run is served from the database copy (E5.F6.S4): on a
            // full fetch, if every runner StorePositions counted on this run
            // has an archive, the tracks come from HasherEventMap.TrackGzip
            // and Table Storage is not scanned. Incremental polls stay on
            // Table Storage — an archive present means no point is newer than
            // it (StorePositions clears it on every batch), so a poll after
            // the archive's last point returns nothing until someone resumes,
            // and then it returns exactly the new points. Fails open: any
            // problem reading the archive falls through to the live path.
            bool isFullFetch = afterTimestampBoundary is null || afterTimestampBoundary.Value == 0;
            EventPositionsResponse? response = null;
            if (isFullFetch)
            {
                response = await TryServeFromArchiveAsync(request, trimStartMs, trimEndMs, applyTrim);
            }

            if (response == null)
            {

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

                if (afterTimestampBoundary.HasValue && timestampMs <= afterTimestampBoundary.Value)
                {
                    continue;
                }

                // Trim: drop points before the official start or after the
                // official end. Boundary markers sit exactly at start/end, so
                // they survive (< / > are strict) and viewers still see the
                // official-start/end flags. Skipped entirely for the admin editor.
                if (applyTrim)
                {
                    if (trimStartMs.HasValue && timestampMs < trimStartMs.Value) continue;
                    if (trimEndMs.HasValue && timestampMs > trimEndMs.Value) continue;
                }

                // AST / AEN are the admin's trim boundaries, not places anybody
                // stood: the editor writes them at the EVENT's venue, which on
                // the GNH Hangover run was 507 m from the first fix and 549 m
                // past the On Inn — every viewer drew a straight line out to
                // each. Their timestamps are already served as TrimStartMs /
                // TrimEndMs (GetTrimWindowAsync reads the table directly), so
                // the points themselves are never returned.
                if (string.Equals(positionType, "AST", StringComparison.OrdinalIgnoreCase) ||
                    string.Equals(positionType, "AEN", StringComparison.OrdinalIgnoreCase))
                {
                    continue;
                }

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

            response = new EventPositionsResponse
            {
                EventId = request.EventId,
                LatestServerTimestamp = latestServerTimestamp,
                TrimStartMs = trimStartMs,
                TrimEndMs = trimEndMs,
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
            } // live path

            // On the full fetch (no / zero afterTimestamp), bundle the owning
            // kennel's PackTrack trail-type config so the playback payload is
            // self-describing — labels resolve on app and web even for viewers
            // who don't follow the kennel. Config doesn't change mid-run, so
            // incremental polls omit it and the client caches it from this
            // first response.
            if (isFullFetch)
            {
                response.TrailTypesConfigJson = await TryGetTrailTypesConfigAsync(request.EventId);
            }

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

        // Per-event trim window cache. Static so it survives across invocations
        // while the function host is warm. 5-minute TTL: a just-moved boundary
        // takes up to 5 min to affect other viewers — an accepted edge case that
        // keeps incremental polls off a per-request marker query.
        private static readonly System.Collections.Concurrent.ConcurrentDictionary<string, TrimWindowCacheEntry> _trimCache = new();
        private static readonly TimeSpan _trimCacheTtl = TimeSpan.FromMinutes(5);

        // Resolves the official run window (epoch-ms) from the newest AST (start)
        // and AEN (end) boundary markers for the event. Either side may be null
        // (unbounded). Fails open — any lookup error serves an untrimmed window
        // so positions are never blocked on trim resolution.
        private async Task<(long? start, long? end)> GetTrimWindowAsync(TableClient eventTable, string eventId)
        {
            if (_trimCache.TryGetValue(eventId, out var cached) && cached.ExpiresUtc > DateTimeOffset.UtcNow)
            {
                return (cached.StartMs, cached.EndMs);
            }

            long? startMs = null; long? startWrittenAt = null;
            long? endMs = null; long? endWrittenAt = null;

            // Markers-only query — a handful of rows even on a large event.
            string filter =
                $"PartitionKey eq '{EscapeForFilter(eventId)}' and (Type eq 'AST' or Type eq 'AEN')";
            try
            {
                await foreach (var entity in eventTable.QueryAsync<TableEntity>(filter))
                {
                    string? type = entity.GetString("Type");
                    string? tsText = entity.GetString("TimestampMs") ?? ExtractTimestampFromRowKey(entity.RowKey);
                    string? serverText = entity.GetString("ServerTimestampMs") ?? ExtractServerTimestampFromRowKey(entity.RowKey);
                    if (!long.TryParse(tsText, out long ts)) continue;
                    long written = long.TryParse(serverText, out long w) ? w : 0;

                    // Newest-written marker wins, so an admin moves a boundary by
                    // simply dropping a fresh one.
                    if (string.Equals(type, "AST", StringComparison.OrdinalIgnoreCase))
                    {
                        if (startWrittenAt is null || written >= startWrittenAt) { startWrittenAt = written; startMs = ts; }
                    }
                    else if (string.Equals(type, "AEN", StringComparison.OrdinalIgnoreCase))
                    {
                        if (endWrittenAt is null || written >= endWrittenAt) { endWrittenAt = written; endMs = ts; }
                    }
                }
            }
            catch (Exception ex)
            {
                _log.LogWarning("GetPositions: trim-window lookup failed for event {EventId}: {Message}. Serving untrimmed.", eventId, ex.Message);
                return (null, null);
            }

            _trimCache[eventId] = new TrimWindowCacheEntry
            {
                StartMs = startMs,
                EndMs = endMs,
                ExpiresUtc = DateTimeOffset.UtcNow.Add(_trimCacheTtl)
            };
            return (startMs, endMs);
        }

        private class TrimWindowCacheEntry
        {
            public long? StartMs { get; set; }
            public long? EndMs { get; set; }
            public DateTimeOffset ExpiresUtc { get; set; }
        }

        // Fetches the owning kennel's PackTrack trail-type config JSON for this
        // event (via [HC6].[publicWeb_getEventTrailTypes]). Best-effort: any
        // failure — unparseable event id, missing connection string, SQL error,
        // event not found, or no kennel customisation — logs and returns null so
        // the positions payload is never blocked by config resolution (clients
        // fall back to built-in defaults). Reuses the same SQL connection the
        // PublicWebApi shim uses.
        private async Task<string?> TryGetTrailTypesConfigAsync(string eventId)
        {
            if (!Guid.TryParse(eventId, out Guid eventGuid))
            {
                return null;
            }

            string? connectionString = Environment.GetEnvironmentVariable("HcDbConnectionString");
            if (string.IsNullOrWhiteSpace(connectionString))
            {
                _log.LogWarning("GetPositions: HcDbConnectionString not set — trail-type config omitted.");
                return null;
            }

            try
            {
                using SqlConnection conn = new(connectionString);
                await conn.OpenAsync();

                using SqlCommand cmd = new("[HC6].[publicWeb_getEventTrailTypes]", conn)
                {
                    CommandType = CommandType.StoredProcedure,
                    CommandTimeout = 5
                };
                cmd.Parameters.Add("@eventId", SqlDbType.UniqueIdentifier).Value = eventGuid;

                // First column of the first row is trailTypesConfigJson (NULL when
                // the kennel has no customisation). Anything non-string (DBNull,
                // or the Success=0 envelope on an empty guid) resolves to null.
                object? result = await cmd.ExecuteScalarAsync();
                return result is string s && !string.IsNullOrWhiteSpace(s) ? s : null;
            }
            catch (Exception ex)
            {
                _log.LogWarning("GetPositions: failed to fetch trail-type config for event {EventId}: {Message}", eventId, ex.Message);
                return null;
            }
        }

        /// <summary>
        /// The archive reader. Returns the run's tracks from
        /// HasherEventMap.TrackGzip, or null when the run should come from
        /// Table Storage: nothing counted on it yet, or some counted runner has
        /// no archive (still live, or not yet swept). Removed attendees are
        /// not served — the nightly does not archive them either. Same trim
        /// and AST/AEN rules as the live path, so a client cannot tell the
        /// difference except by the "source" field.
        /// </summary>
        private async Task<EventPositionsResponse?> TryServeFromArchiveAsync(
            GetPositionsRequest request, long? trimStartMs, long? trimEndMs, bool applyTrim)
        {
            if (!Guid.TryParse(request.EventId, out Guid eventGuid))
            {
                return null;
            }
            Guid? userGuid = null;
            if (!string.IsNullOrWhiteSpace(request.UserId))
            {
                if (!Guid.TryParse(request.UserId, out Guid u)) return null;
                userGuid = u;
            }
            string? connectionString = Environment.GetEnvironmentVariable("HcDbConnectionString");
            if (string.IsNullOrWhiteSpace(connectionString))
            {
                return null;
            }

            var tracks = new List<(Guid userId, byte[] blob)>();
            try
            {
                using SqlConnection conn = new(connectionString);
                await conn.OpenAsync();
                using SqlCommand cmd = new(
                    "SELECT UserId, TrackGzip FROM HC.HasherEventMap " +
                    " WHERE EventId = @eventId AND removed = 0 AND TrackPointCount > 0 " +
                    "   AND (@userId IS NULL OR UserId = @userId);",
                    conn) { CommandTimeout = 10 };
                cmd.Parameters.Add("@eventId", SqlDbType.UniqueIdentifier).Value = eventGuid;
                cmd.Parameters.Add("@userId", SqlDbType.UniqueIdentifier).Value = (object?)userGuid ?? DBNull.Value;
                using SqlDataReader reader = await cmd.ExecuteReaderAsync();
                while (await reader.ReadAsync())
                {
                    if (await reader.IsDBNullAsync(1))
                    {
                        return null; // a counted runner without an archive: the run is not finished, or not swept yet
                    }
                    tracks.Add((reader.GetGuid(0), (byte[])reader[1]));
                }
            }
            catch (Exception ex)
            {
                _log.LogWarning("GetPositions: archive read failed for event {EventId}: {Message}. Serving from Table Storage.", request.EventId, ex.Message);
                return null;
            }
            if (tracks.Count == 0)
            {
                return null;
            }

            var users = new List<UserPositionsResponse>();
            long latestMs = 0;
            foreach ((Guid userId, byte[] blob) in tracks)
            {
                List<ArchivedTrackPoint> points;
                try
                {
                    points = TrackArchiveCodec.Decode(blob);
                }
                catch (Exception ex)
                {
                    _log.LogWarning("GetPositions: archive for event {EventId} / user {UserId} would not decode: {Message}. Serving from Table Storage.", request.EventId, userId, ex.Message);
                    return null;
                }
                var positions = new List<PositionResponse>(points.Count);
                foreach (ArchivedTrackPoint p in points)
                {
                    if (applyTrim)
                    {
                        if (trimStartMs.HasValue && p.TimestampMs < trimStartMs.Value) continue;
                        if (trimEndMs.HasValue && p.TimestampMs > trimEndMs.Value) continue;
                    }
                    // AST / AEN are the admin's trim boundaries, not places
                    // anybody stood — never returned as points (as on the live path).
                    if (string.Equals(p.Type, "AST", StringComparison.OrdinalIgnoreCase) ||
                        string.Equals(p.Type, "AEN", StringComparison.OrdinalIgnoreCase))
                    {
                        continue;
                    }
                    // The live path drops a point with no accuracy; the codec
                    // stores "no accuracy" as 0 and hands it back as null.
                    if (p.Accuracy is null) continue;
                    if (p.TimestampMs > latestMs) latestMs = p.TimestampMs;
                    positions.Add(new PositionResponse
                    {
                        Latitude = RoundCoordinate(p.Latitude),
                        Longitude = RoundCoordinate(p.Longitude),
                        Accuracy = RoundCoordinate(p.Accuracy.Value),
                        TimestampMs = p.TimestampMs,
                        Type = p.Type
                    });
                }
                users.Add(new UserPositionsResponse
                {
                    Id = userId.ToString("D").ToLowerInvariant(),
                    Positions = positions
                });
            }

            _log.LogInformation("GetPositions: event {EventId} served from the archive ({Users} track(s)).", request.EventId, users.Count);
            return new EventPositionsResponse
            {
                EventId = request.EventId,
                // The newest archived point, in the 19-digit form clients hand
                // back: their next poll then asks Table Storage for anything
                // newer, which is exactly what a resume would add.
                LatestServerTimestamp = latestMs > 0 ? latestMs.ToString("D19") : null,
                TrimStartMs = trimStartMs,
                TrimEndMs = trimEndMs,
                Source = "archive",
                Users = users.OrderBy(u => u.Id, StringComparer.OrdinalIgnoreCase).ToList()
            };
        }

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
            // Admin trim editor only: return the FULL track (out-of-window points
            // included) plus the current window so the handles can be dragged
            // back outward. Normal viewers omit this and receive the trimmed track.
            [JsonProperty("includeTrimmed")] public bool IncludeTrimmed { get; set; }
        }

        internal class EventPositionsResponse
        {
            [JsonProperty("eventId")] public string EventId { get; set; } = string.Empty;
            [JsonProperty("latestServerTimestampMs", NullValueHandling = NullValueHandling.Ignore)] public string? LatestServerTimestamp { get; set; }
            [JsonProperty("trailTypesConfigJson", NullValueHandling = NullValueHandling.Ignore)] public string? TrailTypesConfigJson { get; set; }
            // Official run window (epoch-ms) from the admin AST/AEN markers. Null
            // on the unbounded side. Lets the trim editor place its handles and
            // clients clamp the timeline without rescanning for the markers.
            [JsonProperty("trimStartMs", NullValueHandling = NullValueHandling.Ignore)] public long? TrimStartMs { get; set; }
            [JsonProperty("trimEndMs", NullValueHandling = NullValueHandling.Ignore)] public long? TrimEndMs { get; set; }
            // "archive" when the tracks came from HasherEventMap.TrackGzip rather
            // than Table Storage (E5.F6.S4). Absent on the live path.
            [JsonProperty("source", NullValueHandling = NullValueHandling.Ignore)] public string? Source { get; set; }
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
