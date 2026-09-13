using System;
using System.Collections.Generic;
using System.Data;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Logging;

namespace HcWebApi.Endpoints
{
    /// <summary>
    /// Measures the tracks that were archived before the statistics columns
    /// existed (2026-09-13). New tracks are measured by the archiver as it
    /// writes them; this is the one-off pass over the history.
    ///
    /// Run-once in spirit but safe to re-run: it only picks up rows that have
    /// an archive and no distance yet, so a second call finds nothing. Paged,
    /// so a run that hits the Function's time limit can simply be called again.
    ///
    /// POST with the same X-Api-Key as ArchiveTrack. { "batch": 200 } to size
    /// a pass; { "remeasure": true } re-measures rows that already have stats,
    /// for when the measuring rules change.
    /// </summary>
    public class BackfillTrackStats
    {
        private readonly ILogger<BackfillTrackStats> _log;

        public BackfillTrackStats(ILogger<BackfillTrackStats> logger) => _log = logger;

        private sealed class Options
        {
            public int Batch { get; set; } = 200;
            public bool Remeasure { get; set; }
        }

        [Function("BackfillTrackStats")]
        public async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Anonymous, "post")] HttpRequest req)
        {
            string? expectedKey = Environment.GetEnvironmentVariable("ApiKey");
            string? providedKey = req.Headers.TryGetValue("X-Api-Key", out var headerVal)
                ? headerVal.ToString()
                : req.Query["apiKey"].ToString();
            if (string.IsNullOrEmpty(expectedKey) || providedKey != expectedKey)
            {
                return new UnauthorizedObjectResult("Unauthorized");
            }

            string? connectionString = Environment.GetEnvironmentVariable("HcDbConnectionString");
            if (string.IsNullOrWhiteSpace(connectionString))
            {
                _log.LogError("BackfillTrackStats: HcDbConnectionString not set.");
                return new ObjectResult(new { error = "Database not configured." })
                { StatusCode = StatusCodes.Status500InternalServerError };
            }

            Options opts = new();
            using (var reader = new System.IO.StreamReader(req.Body))
            {
                string body = await reader.ReadToEndAsync();
                if (!string.IsNullOrWhiteSpace(body))
                {
                    try
                    {
                        opts = Newtonsoft.Json.JsonConvert.DeserializeObject<Options>(body) ?? new Options();
                    }
                    catch (Exception)
                    {
                        return new BadRequestObjectResult(new { error = "Invalid JSON payload." });
                    }
                }
            }
            if (opts.Batch < 1 || opts.Batch > 2000) opts.Batch = 200;

            int measured = 0, unmeasurable = 0, failed = 0, remaining;
            try
            {
                using SqlConnection conn = new(connectionString);
                await conn.OpenAsync();

                List<(Guid EventId, Guid UserId, byte[] Blob)> work = new();
                string filter = opts.Remeasure
                    ? "TrackGzip IS NOT NULL"
                    : "TrackGzip IS NOT NULL AND TrackDistanceM IS NULL";

                using (SqlCommand pick = new(
                    $"SELECT TOP (@batch) EventId, UserId, TrackGzip " +
                    $"  FROM HC.HasherEventMap " +
                    $" WHERE removed = 0 AND {filter} " +
                    $" ORDER BY TrackLastPointAt DESC;", conn) { CommandTimeout = 120 })
                {
                    pick.Parameters.Add("@batch", SqlDbType.Int).Value = opts.Batch;
                    using SqlDataReader r = await pick.ExecuteReaderAsync();
                    while (await r.ReadAsync())
                    {
                        work.Add((r.GetGuid(0), r.GetGuid(1), (byte[])r[2]));
                    }
                }

                foreach ((Guid eventId, Guid userId, byte[] blob) in work)
                {
                    try
                    {
                        IReadOnlyList<ArchivedTrackPoint> points = TrackArchiveCodec.Decode(blob);
                        TrackStats? stats = TrackStats.Measure(points);
                        if (stats == null)
                        {
                            // Nothing measurable (one usable fix, or every point
                            // a typed mark). Stamp a zero distance so the row is
                            // not picked up for ever; the other columns stay null.
                            await WriteAsync(conn, eventId, userId, null);
                            unmeasurable++;
                            continue;
                        }
                        await WriteAsync(conn, eventId, userId, stats);
                        measured++;
                    }
                    catch (Exception ex)
                    {
                        _log.LogError(ex, "BackfillTrackStats: {EventId}/{UserId} failed.", eventId, userId);
                        failed++;
                    }
                }

                using SqlCommand left = new(
                    "SELECT COUNT(*) FROM HC.HasherEventMap " +
                    " WHERE removed = 0 AND TrackGzip IS NOT NULL AND TrackDistanceM IS NULL;",
                    conn) { CommandTimeout = 60 };
                remaining = (int)(await left.ExecuteScalarAsync() ?? 0);
            }
            catch (Exception ex)
            {
                _log.LogError(ex, "BackfillTrackStats failed.");
                return new ObjectResult(new { error = ex.Message })
                { StatusCode = StatusCodes.Status500InternalServerError };
            }

            _log.LogInformation(
                "BackfillTrackStats: measured {Measured}, unmeasurable {Unmeasurable}, failed {Failed}, remaining {Remaining}.",
                measured, unmeasurable, failed, remaining);
            return new OkObjectResult(new { measured, unmeasurable, failed, remaining });
        }

        /// <summary>
        /// Writes the measurements WITHOUT touching updatedAt.
        ///
        /// The sync trigger skips its stamp only for a write that touches the
        /// track columns alone, and these new columns are not in that list — so
        /// a plain update here would stamp all 745 rows and re-sync every one of
        /// them to its owner's phone for numbers the phone does not even carry.
        /// Assigning updatedAt to itself makes UPDATE(updatedAt) true, which is
        /// the condition the trigger uses to keep its hands off.
        /// </summary>
        private static async Task WriteAsync(SqlConnection conn, Guid eventId, Guid userId, TrackStats? s)
        {
            using SqlCommand cmd = new(
                "UPDATE HC.HasherEventMap " +
                "   SET TrackDistanceM = @distanceM, " +
                "       TrackMovingSeconds = @movingSec, " +
                "       TrackElevationGainM = @climbM, " +
                "       TrackStartLat = @startLat, TrackStartLng = @startLng, " +
                "       TrackEndLat   = @endLat,   TrackEndLng   = @endLng, " +
                "       TrackMinLat   = @minLat,   TrackMinLng   = @minLng, " +
                "       TrackMaxLat   = @maxLat,   TrackMaxLng   = @maxLng, " +
                "       updatedAt = updatedAt " +
                " WHERE EventId = @eventId AND UserId = @userId AND removed = 0;",
                conn) { CommandTimeout = 30 };
            cmd.Parameters.Add("@distanceM", SqlDbType.Int).Value = (object?)s?.DistanceM ?? 0;
            cmd.Parameters.Add("@movingSec", SqlDbType.Int).Value = (object?)s?.MovingSeconds ?? DBNull.Value;
            cmd.Parameters.Add("@climbM", SqlDbType.Int).Value = (object?)s?.ElevationGainM ?? DBNull.Value;
            cmd.Parameters.Add("@startLat", SqlDbType.Decimal).Value = (object?)s?.StartLat ?? DBNull.Value;
            cmd.Parameters.Add("@startLng", SqlDbType.Decimal).Value = (object?)s?.StartLng ?? DBNull.Value;
            cmd.Parameters.Add("@endLat", SqlDbType.Decimal).Value = (object?)s?.EndLat ?? DBNull.Value;
            cmd.Parameters.Add("@endLng", SqlDbType.Decimal).Value = (object?)s?.EndLng ?? DBNull.Value;
            cmd.Parameters.Add("@minLat", SqlDbType.Decimal).Value = (object?)s?.MinLat ?? DBNull.Value;
            cmd.Parameters.Add("@minLng", SqlDbType.Decimal).Value = (object?)s?.MinLng ?? DBNull.Value;
            cmd.Parameters.Add("@maxLat", SqlDbType.Decimal).Value = (object?)s?.MaxLat ?? DBNull.Value;
            cmd.Parameters.Add("@maxLng", SqlDbType.Decimal).Value = (object?)s?.MaxLng ?? DBNull.Value;
            cmd.Parameters.Add("@eventId", SqlDbType.UniqueIdentifier).Value = eventId;
            cmd.Parameters.Add("@userId", SqlDbType.UniqueIdentifier).Value = userId;
            await cmd.ExecuteNonQueryAsync();
        }
    }
}
