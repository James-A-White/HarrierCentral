using System.Data;
using System.IO;
using Azure.Data.Tables;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;

namespace HcWebApi.Endpoints
{
    /// <summary>
    /// Copies finished PackTrack trails out of Azure Table Storage and onto the
    /// runner's HC.HasherEventMap row as a delta-encoded gzip (TrackGzip,
    /// E5.F6.S4), so a run survives independently of the position store and a
    /// past run can replay from the database alone.
    ///
    /// Nothing on the phone is involved (James, 2026-09-10). Table Storage
    /// already holds every point a phone managed to upload, and nothing reads
    /// the archive yet, so there is no reason for it to exist sooner than the
    /// next night. <see cref="ArchiveTracksNightly"/> is the clock;
    /// <see cref="ArchiveTrack"/> is the same sweep on demand.
    ///
    /// The worklist is every attendance row that has a track and no archive:
    ///   1. rows StorePositions counted (TrackPointCount > 0, TrackGzip NULL);
    ///   2. runners on recently tracked runs (HC.EventTrack) whose row was not
    ///      counted — the batch that arrived before the check-in row existed —
    ///      found by asking the run's partition who is in it. A runner found
    ///      there with NO attendance row at all gets one (At Hash, via
    ///      nonApi_ensureTrackAttendance): every runner who has a track has an
    ///      attendance row.
    /// Both require the track to have been quiet for <see cref="QuietMinutes"/>,
    /// and StorePositions / DeletePositions clear the archive whenever the
    /// points change, so a track is never archived mid-run and a resumed run
    /// is re-archived at its new end. Work goes run by run — one partition
    /// read per run, every runner on it from that read — under a time budget;
    /// the next pass takes what was left.
    /// </summary>
    internal static class TrackArchiver
    {
        internal const int QuietMinutes = 30;
        internal const int RecentRunDays = 7;

        /// <summary>
        /// How long a pass may keep starting new runs. The API is on the
        /// Consumption plan, where host.json caps a function at 10 minutes and
        /// the host kills it at that point; every run finished before then is
        /// already written, so a kill loses nothing, but a budget lets the pass
        /// stop cleanly and report what it left. The next pass takes the rest.
        /// </summary>
        internal static readonly TimeSpan WorkBudget = TimeSpan.FromMinutes(8);

        internal sealed class Tally
        {
            public int RunsInWorklist;
            public int RunsDone;
            public int RunsLeft;
            public double ElapsedSeconds;
            public List<object> Archived { get; } = new();
            public List<object> Skipped { get; } = new();
            public int Failed;
            /// Attendance rows created for runners who had a track but no row.
            public int RowsCreated;
        }

        /// <summary>Runs the whole sweep: worklist of runs, one partition read per run.</summary>
        /// <param name="allRuns">Walk EVERY run in HC.EventTrack, not just the
        /// recent ones — for the one-off pass over the history, so runners who
        /// were never counted (and never had an attendance row) are found on
        /// old runs too. Not for the nightly: that is a partition scan per
        /// tracked run, every night, for nothing.</param>
        internal static async Task<Tally> SweepAsync(SqlConnection conn, TableServiceClient tables, ILogger log, bool allRuns = false)
        {
            var clock = System.Diagnostics.Stopwatch.StartNew();
            TableClient eventTable = tables.GetTableClient("EventPositions");
            List<Guid> runs = await BuildRunWorklistAsync(conn, allRuns);
            var tally = new Tally { RunsInWorklist = runs.Count };

            foreach (Guid eventId in runs)
            {
                if (clock.Elapsed > WorkBudget)
                {
                    break;
                }
                try
                {
                    await ArchiveRunAsync(conn, eventTable, eventId, tally, log);
                }
                catch (Exception ex)
                {
                    tally.Failed++;
                    log.LogWarning("TrackArchiver: run {EventId} failed: {Message}", eventId, ex.Message);
                }
                tally.RunsDone++;
            }

            tally.RunsLeft = runs.Count - tally.RunsDone;
            tally.ElapsedSeconds = Math.Round(clock.Elapsed.TotalSeconds, 1);
            return tally;
        }

        /// <summary>
        /// Runs with something to archive, newest first:
        ///   1. any runner row StorePositions counted that has no archive yet;
        ///   2. any run tracked in the last RecentRunDays — catches a runner whose
        ///      row was never counted because their first batch landed before
        ///      the check-in row existed.
        /// Both need the run to have been quiet for QuietMinutes.
        /// </summary>
        private static async Task<List<Guid>> BuildRunWorklistAsync(SqlConnection conn, bool allRuns)
        {
            var ordered = new List<(DateTime lastAt, Guid eventId)>();
            using SqlCommand cmd = new(
                "SELECT EventId, MAX(LastAt) AS LastAt FROM ( " +
                "  SELECT EventId, TrackLastPointAt AS LastAt FROM HC.HasherEventMap " +
                "   WHERE removed = 0 AND TrackPointCount > 0 AND TrackGzip IS NULL " +
                "     AND TrackLastPointAt < DATEADD(MINUTE, -@quiet, SYSUTCDATETIME()) " +
                "  UNION ALL " +
                "  SELECT EventId, LastPointAt FROM HC.EventTrack " +
                "   WHERE (@allRuns = 1 OR LastPointAt >= DATEADD(DAY, -@days, SYSUTCDATETIME())) " +
                "     AND LastPointAt <  DATEADD(MINUTE, -@quiet, SYSUTCDATETIME()) " +
                ") w GROUP BY EventId ORDER BY MAX(LastAt) DESC;",
                conn) { CommandTimeout = 30 };
            cmd.Parameters.Add("@quiet", SqlDbType.Int).Value = QuietMinutes;
            cmd.Parameters.Add("@days", SqlDbType.Int).Value = RecentRunDays;
            cmd.Parameters.Add("@allRuns", SqlDbType.Int).Value = allRuns ? 1 : 0;
            using SqlDataReader reader = await cmd.ExecuteReaderAsync();
            while (await reader.ReadAsync())
            {
                ordered.Add((reader.GetDateTime(1), reader.GetGuid(0)));
            }
            return ordered.Select(o => o.eventId).ToList();
        }

        /// <summary>
        /// One run: read its partition ONCE, split the points by runner, and
        /// archive every runner on it who has an attendance row and no archive.
        /// A partition is the whole run — every runner's points — so reading it
        /// per runner would scan the same rows once per runner.
        /// </summary>
        private static async Task ArchiveRunAsync(SqlConnection conn, TableClient eventTable, Guid eventId, Tally tally, ILogger log)
        {
            string eventKey = eventId.ToString("D").ToLowerInvariant();

            // Who on this run still needs an archive — and is not still moving.
            // A runner with a point in the last QuietMinutes is skipped tonight;
            // StorePositions will have cleared their archive anyway.
            // Everyone with an attendance row on this run, in any state. The
            // value is whether they still need an archive: no archive yet and
            // not still moving (a point in the last QuietMinutes). Most
            // attendees never tracked and will simply have no points in the
            // partition. A runner with points and NO row at all gets one —
            // every runner who has a track has an attendance row (James,
            // 2026-09-10) — via nonApi_ensureTrackAttendance, then is archived
            // like anyone else.
            var attendees = new Dictionary<Guid, bool>();
            var counted = new HashSet<Guid>();
            using (SqlCommand cmd = new(
                "SELECT UserId, " +
                "       CASE WHEN removed = 0 AND TrackGzip IS NULL " +
                "             AND (TrackLastPointAt IS NULL OR TrackLastPointAt < DATEADD(MINUTE, -@quiet, SYSUTCDATETIME())) " +
                "            THEN 1 ELSE 0 END AS NeedsArchive, " +
                "       CASE WHEN TrackPointCount > 0 THEN 1 ELSE 0 END AS Counted " +
                "  FROM HC.HasherEventMap WHERE EventId = @eventId;",
                conn) { CommandTimeout = 10 })
            {
                cmd.Parameters.Add("@eventId", SqlDbType.UniqueIdentifier).Value = eventId;
                cmd.Parameters.Add("@quiet", SqlDbType.Int).Value = QuietMinutes;
                using SqlDataReader reader = await cmd.ExecuteReaderAsync();
                while (await reader.ReadAsync())
                {
                    Guid u = reader.GetGuid(0);
                    attendees[u] = reader.GetInt32(1) == 1;
                    if (reader.GetInt32(2) == 1) counted.Add(u);
                }
            }

            // The one partition read.
            string filter = $"PartitionKey eq '{eventKey}'";
            string[] columns = { "RowKey", "UserId", "TimestampMs", "Latitude", "Longitude", "Altitude", "Accuracy", "Type" };
            var byRunner = new Dictionary<Guid, List<ArchivedTrackPoint>>();
            await foreach (TableEntity entity in eventTable.QueryAsync<TableEntity>(filter, select: columns))
            {
                string? userText = entity.GetString("UserId");
                if (!Guid.TryParse(userText, out Guid userId)) continue;

                double? latitude = entity.GetDouble("Latitude");
                double? longitude = entity.GetDouble("Longitude");
                if (latitude is null || longitude is null) continue;

                string? timestampText = entity.GetString("TimestampMs") ?? ExtractTimestampFromRowKey(entity.RowKey);
                if (!long.TryParse(timestampText, out long timestampMs)) continue;

                if (attendees.TryGetValue(userId, out bool needsArchive))
                {
                    if (!needsArchive) continue; // archived already, still live, or removed
                }
                else
                {
                    // Points but no attendance row: they were there. Create the
                    // row (idempotent; a no-op if it appeared meanwhile) and
                    // treat them as a runner to archive. Remembered either way
                    // so the run's partition asks only once per runner.
                    bool created = await EnsureAttendanceAsync(conn, eventId, userId, log);
                    attendees[userId] = created;
                    if (!created) continue;
                    tally.RowsCreated++;
                }

                if (!byRunner.TryGetValue(userId, out var list))
                {
                    list = new List<ArchivedTrackPoint>();
                    byRunner[userId] = list;
                }
                list.Add(new ArchivedTrackPoint(
                    timestampMs,
                    latitude.Value,
                    longitude.Value,
                    entity.GetDouble("Altitude"),
                    entity.GetDouble("Accuracy"),
                    entity.GetString("Type")));
            }

            long quietBefore = DateTimeOffset.UtcNow.AddMinutes(-QuietMinutes).ToUnixTimeMilliseconds();
            foreach ((Guid userId, bool needsArchive) in attendees)
            {
                if (!needsArchive) continue;
                if (!byRunner.TryGetValue(userId, out var points) || points.Count == 0)
                {
                    // An attendee who never tracked is the normal case and is
                    // not reported. A runner StorePositions counted but whose
                    // points are gone is worth a line: DeletePositions should
                    // have cleared the count.
                    if (counted.Contains(userId)) tally.Skipped.Add(new { eventId, userId, reason = "noPoints" });
                    continue;
                }
                // Ascending time order is what the codec's deltas assume, and
                // what a replay wants. RowKey order is already caller-timestamp
                // order for current rows, but not for legacy serverTs-callerTs keys.
                points.Sort((a, b) => a.TimestampMs.CompareTo(b.TimestampMs));
                if (points[^1].TimestampMs > quietBefore)
                {
                    tally.Skipped.Add(new { eventId, userId, reason = "stillLive" });
                    continue;
                }
                int bytes = await WriteArchiveAsync(conn, eventId, userId, points);
                if (bytes < 0)
                {
                    tally.Skipped.Add(new { eventId, userId, reason = "noAttendanceRow" });
                    continue;
                }
                tally.Archived.Add(new { eventId, userId, points = points.Count, bytes });
                log.LogInformation("TrackArchiver: archived {Points} point(s) as {Bytes} bytes for event {EventId} / user {UserId}.",
                    points.Count, bytes, eventKey, userId);
            }
        }

        /// <summary>
        /// Creates the attendance row for a runner with points but no row, via
        /// HC6.nonApi_ensureTrackAttendance (At Hash, RSVP Yes, run counts
        /// recomputed — the same row a real check-in writes). True when a row
        /// exists to archive to afterwards. Any failure is a warning and a
        /// skip; the next pass tries again.
        /// </summary>
        private static async Task<bool> EnsureAttendanceAsync(SqlConnection conn, Guid eventId, Guid userId, ILogger log)
        {
            try
            {
                using SqlCommand cmd = new("[HC6].[nonApi_ensureTrackAttendance]", conn)
                {
                    CommandType = CommandType.StoredProcedure,
                    CommandTimeout = 30
                };
                cmd.Parameters.Add("@eventId", SqlDbType.UniqueIdentifier).Value = eventId;
                cmd.Parameters.Add("@userId", SqlDbType.UniqueIdentifier).Value = userId;
                using SqlDataReader reader = await cmd.ExecuteReaderAsync();
                if (!await reader.ReadAsync()) return false;
                bool inserted = reader.GetInt32(reader.GetOrdinal("Inserted")) == 1;
                string reason = reader.GetString(reader.GetOrdinal("Reason"));
                if (inserted)
                {
                    log.LogInformation("TrackArchiver: created attendance row for event {EventId} / user {UserId} (had a track, no row).", eventId, userId);
                }
                else
                {
                    log.LogInformation("TrackArchiver: no attendance row created for event {EventId} / user {UserId}: {Reason}.", eventId, userId, reason);
                }
                // rowExists means it appeared between our read and the call —
                // it can be archived; noHasher / noEvent cannot.
                return inserted || reason == "rowExists";
            }
            catch (Exception ex)
            {
                log.LogWarning("TrackArchiver: nonApi_ensureTrackAttendance failed for event {EventId} / user {UserId}: {Message}", eventId, userId, ex.Message);
                return false;
            }
        }

        /// <summary>
        /// Encodes and writes one runner's archive. Returns the byte size, or -1
        /// when the attendance row is not there to write to.
        /// </summary>
        private static async Task<int> WriteArchiveAsync(SqlConnection conn, Guid eventId, Guid userId, List<ArchivedTrackPoint> points)
        {
            byte[] blob = TrackArchiveCodec.Encode(points);
            DateTime firstAt = DateTimeOffset.FromUnixTimeMilliseconds(points[0].TimestampMs).UtcDateTime;
            DateTime lastAt = DateTimeOffset.FromUnixTimeMilliseconds(points[^1].TimestampMs).UtcDateTime;

            // A replace, never an append: the row ends up holding exactly this
            // track however many times it is archived. TrackPointCount is
            // reconciled to the true row count (StorePositions adds every
            // accepted batch, and a batch re-sent after a lost response is
            // counted twice). First/last are filled only where the per-batch
            // writes never set them — the uncounted-row case.
            using SqlCommand cmd = new(
                // updatedAt is stamped here on purpose (the trigger skips
                // track-only writes so live batches never re-sync the row):
                // the finished archive is what the hasher's phone keeps, so
                // this one write must sync — once per track (E5.F7.S1,
                // 2026-09-12). The trigger adds the row's bias to the value.
                "UPDATE HC.HasherEventMap " +
                "   SET TrackGzip = @blob, TrackPointCount = @count, " +
                "       TrackFirstPointAt = ISNULL(TrackFirstPointAt, @firstAt), " +
                "       TrackLastPointAt  = ISNULL(TrackLastPointAt,  @lastAt), " +
                "       updatedAt = SYSDATETIME() " +
                " WHERE EventId = @eventId AND UserId = @userId AND removed = 0;",
                conn) { CommandTimeout = 10 };
            cmd.Parameters.Add("@blob", SqlDbType.VarBinary, -1).Value = blob;
            cmd.Parameters.Add("@count", SqlDbType.Int).Value = points.Count;
            cmd.Parameters.Add("@firstAt", SqlDbType.DateTime2).Value = firstAt;
            cmd.Parameters.Add("@lastAt", SqlDbType.DateTime2).Value = lastAt;
            cmd.Parameters.Add("@eventId", SqlDbType.UniqueIdentifier).Value = eventId;
            cmd.Parameters.Add("@userId", SqlDbType.UniqueIdentifier).Value = userId;
            int rows = await cmd.ExecuteNonQueryAsync();
            return rows == 0 ? -1 : blob.Length;
        }

        // Legacy rows (serverTs-callerTs) carry no TimestampMs property; the
        // caller timestamp is the part after the dash. Mirrors GetPositions.
        private static string? ExtractTimestampFromRowKey(string? rowKey)
        {
            if (string.IsNullOrWhiteSpace(rowKey)) return null;
            int dashIndex = rowKey.IndexOf('-');
            return dashIndex >= 0 && dashIndex + 1 < rowKey.Length ? rowKey.Substring(dashIndex + 1) : rowKey;
        }
    }

    /// <summary>
    /// The clock for <see cref="TrackArchiver"/>: 03:30 UTC daily, after
    /// MemberStandingSweep (03:10) and in the same quiet hours. All finished
    /// tracks without an archive are archived; nothing else is touched.
    /// </summary>
    public class ArchiveTracksNightly
    {
        private readonly ILogger<ArchiveTracksNightly> _log;
        private readonly TableServiceClient _tables;

        public ArchiveTracksNightly(ILogger<ArchiveTracksNightly> logger)
        {
            _log = logger;
            string storageConnection = Environment.GetEnvironmentVariable("AzureWebJobsStorage")
                ?? throw new InvalidOperationException("AzureWebJobsStorage is not set in the environment.");
            _tables = new TableServiceClient(storageConnection);
        }

        [Function("ArchiveTracksNightly")]
        public async Task Run([TimerTrigger("0 30 3 * * *")] TimerInfo timer)
        {
            string connectionString = Environment.GetEnvironmentVariable("HcDbConnectionString")
                ?? throw new InvalidOperationException("HcDbConnectionString is not set in the environment.");
            try
            {
                using SqlConnection conn = new(connectionString);
                await conn.OpenAsync();
                TrackArchiver.Tally t = await TrackArchiver.SweepAsync(conn, _tables, _log);
                _log.LogInformation(
                    "ArchiveTracksNightly: runs {Done}/{Worklist} in {Seconds}s (left {Left}), tracks archived {Archived}, skipped {Skipped}, failed {Failed}, attendance rows created {Created}.",
                    t.RunsDone, t.RunsInWorklist, t.ElapsedSeconds, t.RunsLeft, t.Archived.Count, t.Skipped.Count, t.Failed, t.RowsCreated);
            }
            catch (Exception ex)
            {
                _log.LogError(ex, "ArchiveTracksNightly failed.");
            }
        }
    }

    /// <summary>
    /// The same sweep on demand — for the first pass over the history, or to
    /// check a fix without waiting for the night. POST "{}" for the nightly's
    /// worklist, or { "allRuns": true } to walk every tracked run (the history
    /// pass, which also finds runners who never had an attendance row on old
    /// runs). Guarded by the same X-Api-Key as GetPositions.
    /// Response: { runsInWorklist, runsDone, runsLeft, elapsedSeconds,
    ///             archived: [ {eventId,userId,points,bytes} ],
    ///             skipped: [ {eventId,userId,reason} ], failed, rowsCreated }
    /// </summary>
    public class ArchiveTrack
    {
        private readonly ILogger<ArchiveTrack> _log;
        private readonly TableServiceClient _tables;

        public ArchiveTrack(ILogger<ArchiveTrack> logger)
        {
            _log = logger;
            string storageConnection = Environment.GetEnvironmentVariable("AzureWebJobsStorage")
                ?? throw new InvalidOperationException("AzureWebJobsStorage is not set in the environment.");
            _tables = new TableServiceClient(storageConnection);
        }

        [Function("ArchiveTrack")]
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
                _log.LogError("ArchiveTrack: HcDbConnectionString not set.");
                return CreateJsonResult(StatusCodes.Status500InternalServerError, new { error = "Database not configured." });
            }

            bool allRuns = false;
            using (var reader = new StreamReader(req.Body))
            {
                string body = await reader.ReadToEndAsync();
                if (!string.IsNullOrWhiteSpace(body))
                {
                    try
                    {
                        var opts = JsonConvert.DeserializeObject<SweepOptions>(body);
                        allRuns = opts?.AllRuns == true;
                    }
                    catch (Exception)
                    {
                        return CreateJsonResult(StatusCodes.Status400BadRequest, new { error = "Invalid JSON payload." });
                    }
                }
            }

            try
            {
                using SqlConnection conn = new(connectionString);
                await conn.OpenAsync();
                TrackArchiver.Tally t = await TrackArchiver.SweepAsync(conn, _tables, _log, allRuns);
                return CreateJsonResult(StatusCodes.Status200OK,
                    new { runsInWorklist = t.RunsInWorklist, runsDone = t.RunsDone, runsLeft = t.RunsLeft,
                          elapsedSeconds = t.ElapsedSeconds, archived = t.Archived, skipped = t.Skipped,
                          failed = t.Failed, rowsCreated = t.RowsCreated });
            }
            catch (Exception ex)
            {
                _log.LogError(ex, "ArchiveTrack: sweep failed.");
                return CreateJsonResult(StatusCodes.Status500InternalServerError, new { error = "Archive sweep failed." });
            }
        }

        private static ContentResult CreateJsonResult(int statusCode, object payload)
        {
            return new ContentResult
            {
                StatusCode = statusCode,
                ContentType = "application/json",
                Content = JsonConvert.SerializeObject(payload)
            };
        }

        internal class SweepOptions
        {
            [JsonProperty("allRuns")] public bool? AllRuns { get; set; }
        }
    }
}
