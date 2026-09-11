using System.Data;
using System.Globalization;
using System.IO;
using System.IO.Compression;
using System.Text;
using System.Xml.Linq;
using Azure.Data.Tables;
using Azure.Storage.Blobs;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace HcWebApi.Endpoints
{
    /// <summary>
    /// Turns an uploaded file — one GPX/TCX/FIT activity, or a whole Strava /
    /// Garmin archive (zip) — into the hasher's PackTrack trails (E5.F5.S7).
    ///
    /// The phone uploads the bytes straight to blob storage and then DRIVES
    /// the work: ProcessTrackImport runs one slice per call under a time
    /// budget and hands back the result so far, so a single file resolves
    /// in one call and an archive's outcomes stream in. A timer backstop
    /// finishes anything the phone abandoned. Every activity found is
    /// recorded in the job's ResultJson — start time, start position,
    /// distance, duration, sport, and what happened to it — matched or not,
    /// so a later "find the recurring runs across a kennel's archives"
    /// feature can cluster on it without re-parsing the blobs.
    ///
    /// James's rules (2026-09-11): a run already carrying a track is never
    /// overwritten by an archive; an activity whose only candidate run has
    /// no recorded start is skipped; two runs on the same day are held for
    /// the hasher to choose; unparseable or untimed files are counted, not
    /// imported. A single file (not an archive) gets one exception: a
    /// no-location or already-tracked match is held instead of skipped, so
    /// the person standing there can confirm or replace.
    /// </summary>
    public static class TrackImportProcessor
    {
        public const int OneMileMeters = 1609;
        public const double ThinDistanceMeters = 5.0;
        public const int ThinIntervalMs = 15_000;
        public const double DefaultAccuracyMeters = 8.0;
        public const int MaxPointsPerActivity = 50_000;
        public const int WriteChunk = 500;

        public enum Kind : short { Unknown = 0, Gpx = 1, Tcx = 2, Fit = 3, Zip = 4 }
        public enum Status : short { Uploaded = 0, Processing = 1, Done = 2, Failed = 3 }

        public sealed class Job
        {
            public Guid Id;
            public Guid HasherId;
            public string BlobUrl = string.Empty;
            public string? FileName;
            public int NextIndex;
            public string? ResultJson;
        }

        // ── Result model (ResultJson) ─────────────────────────────────────────

        public sealed class ActivityResult
        {
            [JsonProperty("i")] public int Index;
            [JsonProperty("name")] public string Name = string.Empty;
            [JsonProperty("format")] public string? Format;
            [JsonProperty("sport")] public string? Sport;
            [JsonProperty("startUtc")] public DateTime? StartUtc;
            [JsonProperty("endUtc")] public DateTime? EndUtc;
            [JsonProperty("lat")] public double? Lat;
            [JsonProperty("lng")] public double? Lng;
            [JsonProperty("points")] public int Points;
            [JsonProperty("distanceM")] public int DistanceM;
            /// imported | replaced | skippedExisting | noRun | noLocation | tooFar | held | unparseable | noTime | failed
            [JsonProperty("outcome")] public string Outcome = "pending";
            [JsonProperty("eventId")] public Guid? EventId;
            [JsonProperty("eventName")] public string? EventName;
            [JsonProperty("kennelName")] public string? KennelName;
            [JsonProperty("candidates", NullValueHandling = NullValueHandling.Ignore)] public List<Candidate>? Candidates;
            [JsonProperty("error", NullValueHandling = NullValueHandling.Ignore)] public string? Error;
        }

        public sealed class Candidate
        {
            [JsonProperty("eventId")] public Guid EventId;
            [JsonProperty("eventName")] public string EventName = string.Empty;
            [JsonProperty("kennelName")] public string KennelName = string.Empty;
            [JsonProperty("startLocal")] public DateTime? StartLocal;
            [JsonProperty("hasLocation")] public bool HasLocation;
            [JsonProperty("distanceMeters")] public int? DistanceMeters;
            [JsonProperty("existingTrackPoints")] public int ExistingTrackPoints;
        }

        public sealed class Result
        {
            [JsonProperty("activities")] public List<ActivityResult> Activities = new();
        }

        // ── Parsed activity ───────────────────────────────────────────────────

        public sealed class Activity
        {
            public string Name = string.Empty;
            public string Format = string.Empty;
            public string? Sport;
            public List<WritePoint> Points = new();  // GPS points, ascending, untyped
            public List<WritePoint> Marks = new();   // typed marks (from our own GPX waypoints)
            public bool HadUntimedPoints;
            /// The activity's title and free-text notes, when the file carries
            /// them (a GPX from the Strava site; a Strava archive's CSV).
            public string? Title;
            public string? Description;
        }

        // ── Slice driver ──────────────────────────────────────────────────────

        /// <summary>
        /// Processes activities from job.NextIndex until the budget is spent
        /// or the file is exhausted. Persists progress after every activity.
        /// Returns true when the job is complete.
        /// </summary>
        public static async Task<bool> RunSliceAsync(ILogger log, TableServiceClient tables, BlobServiceClient blobs,
            SqlConnection conn, Job job, TimeSpan budget)
        {
            var clock = System.Diagnostics.Stopwatch.StartNew();
            Result result = ParseResult(job.ResultJson);
            await UpdateAsync(conn, job.Id, Status.Processing, null, job.NextIndex, null, result);

            BlobClient blob = blobs.GetBlobContainerClient(ContainerOf(job.BlobUrl)).GetBlobClient(BlobNameOf(job.BlobUrl));
            if (!await blob.ExistsAsync())
            {
                await UpdateAsync(conn, job.Id, Status.Failed, null, null, 0, result, "The uploaded file is missing.");
                return true;
            }

            using Stream stream = await blob.OpenReadAsync();
            Kind kind = SniffKind(stream, job.FileName);
            List<(string name, Func<Stream> open)> entries = EnumerateEntries(stream, kind, job.FileName ?? "upload");
            Dictionary<string, (string? title, string? description)> csvNotes = kind == Kind.Zip ? ReadArchiveNotes(stream) : new();
            int total = entries.Count;
            bool single = total == 1;

            int i = job.NextIndex;
            while (i < total)
            {
                if (clock.Elapsed > budget && i > job.NextIndex)
                {
                    break; // resume next slice; at least one activity per call
                }
                ActivityResult ar = result.Activities.FirstOrDefault(a => a.Index == i) ?? new ActivityResult { Index = i };
                if (result.Activities.All(a => a.Index != i)) result.Activities.Add(ar);
                ar.Name = entries[i].name;
                try
                {
                    Activity? act = ParseActivity(entries[i].open(), entries[i].name);
                    ApplyCsvNotes(act, entries[i].name, csvNotes);
                    await DecideAndImportAsync(log, tables, conn, job.HasherId, act, ar, single, replace: false, chosenEventId: null);
                }
                catch (Exception ex)
                {
                    ar.Outcome = "failed";
                    ar.Error = ex.Message.Length > 300 ? ex.Message[..300] : ex.Message;
                    log.LogWarning("TrackImport {Job}: activity {Index} '{Name}' failed: {Message}", job.Id, i, ar.Name, ex.Message);
                }
                i++;
                job.NextIndex = i;
                await UpdateAsync(conn, job.Id, Status.Processing, kind, i, total, result);
            }

            bool done = i >= total;
            await UpdateAsync(conn, job.Id, done ? Status.Done : Status.Processing, kind, i, total, result);
            job.ResultJson = JsonConvert.SerializeObject(result);
            return done;
        }

        /// <summary>
        /// The hasher answered a held item: import activity <paramref name="index"/>
        /// to <paramref name="eventId"/>, replacing an existing track only when
        /// they said so.
        /// </summary>
        public static async Task ResolveAsync(ILogger log, TableServiceClient tables, BlobServiceClient blobs,
            SqlConnection conn, Job job, int index, Guid eventId, bool replace)
        {
            Result result = ParseResult(job.ResultJson);
            ActivityResult? ar = result.Activities.FirstOrDefault(a => a.Index == index);
            if (ar == null) throw new InvalidOperationException("No such activity in this import.");

            BlobClient blob = blobs.GetBlobContainerClient(ContainerOf(job.BlobUrl)).GetBlobClient(BlobNameOf(job.BlobUrl));
            using Stream stream = await blob.OpenReadAsync();
            Kind kind = SniffKind(stream, job.FileName);
            List<(string name, Func<Stream> open)> entries = EnumerateEntries(stream, kind, job.FileName ?? "upload");
            if (index >= entries.Count) throw new InvalidOperationException("The file no longer holds that activity.");

            Activity? act = ParseActivity(entries[index].open(), entries[index].name);
            if (kind == Kind.Zip) ApplyCsvNotes(act, entries[index].name, ReadArchiveNotes(stream));
            await DecideAndImportAsync(log, tables, conn, job.HasherId, act, ar, single: true, replace, chosenEventId: eventId);
            await UpdateAsync(conn, job.Id, Status.Done, kind, null, entries.Count, result);
            job.ResultJson = JsonConvert.SerializeObject(result);
        }

        // ── The decision ──────────────────────────────────────────────────────

        private static async Task DecideAndImportAsync(ILogger log, TableServiceClient tables, SqlConnection conn, Guid hasherId,
            Activity? act, ActivityResult ar, bool single, bool replace, Guid? chosenEventId)
        {
            if (act == null)
            {
                ar.Outcome = "unparseable";
                return;
            }
            ar.Format = act.Format;
            ar.Sport = act.Sport;
            if (act.Points.Count == 0)
            {
                ar.Outcome = act.HadUntimedPoints ? "noTime" : "unparseable";
                return;
            }
            List<WritePoint> thinned = Thin(act.Points);
            WritePoint first = thinned[0];
            WritePoint last = thinned[^1];
            ar.StartUtc = DateTimeOffset.FromUnixTimeMilliseconds(first.TimestampMs).UtcDateTime;
            ar.EndUtc = DateTimeOffset.FromUnixTimeMilliseconds(last.TimestampMs).UtcDateTime;
            ar.Lat = first.Latitude;
            ar.Lng = first.Longitude;
            ar.Points = thinned.Count;
            ar.DistanceM = (int)Math.Round(Distance(thinned));

            List<Candidate> candidates = await FindRunsAsync(conn, hasherId, first, last);
            ar.Candidates = candidates.Count > 0 ? candidates : null;

            Candidate? chosen;
            if (chosenEventId.HasValue)
            {
                chosen = candidates.FirstOrDefault(c => c.EventId == chosenEventId.Value);
                if (chosen == null)
                {
                    ar.Outcome = "held";
                    ar.Error = "That run is not among the candidates for this activity.";
                    return;
                }
            }
            else
            {
                List<Candidate> passing = candidates.Where(c => c.HasLocation && c.DistanceMeters <= OneMileMeters).ToList();
                if (candidates.Count == 0)
                {
                    ar.Outcome = "noRun";
                    return;
                }
                if (passing.Count == 0)
                {
                    bool anyLocated = candidates.Any(c => c.HasLocation);
                    if (anyLocated)
                    {
                        ar.Outcome = "tooFar";
                        return;
                    }
                    // Only runs with no recorded start. Archive: skip. Single
                    // file: hold so the person can confirm the named run.
                    ar.Outcome = single ? "held" : "noLocation";
                    return;
                }
                if (passing.Count > 1)
                {
                    ar.Outcome = "held";
                    ar.Candidates = passing;
                    return;
                }
                chosen = passing[0];
            }

            ar.EventId = chosen.EventId;
            ar.EventName = chosen.EventName;
            ar.KennelName = chosen.KennelName;

            // The hasher's notes: the file's title and description, written
            // onto their attendance row when they have none (James, 2026-09-11:
            // a phone-tracked run with a blank note takes the file's words; a
            // note they wrote is never touched). Done before the track decision
            // so a skipped-because-tracked run still gets its notes.
            await SetNotesIfBlankAsync(conn, chosen.EventId, hasherId, ComposeNotes(act), log);

            if (chosen.ExistingTrackPoints > 0)
            {
                if (!replace)
                {
                    // Archive: never overwrite. Single file: hold with the
                    // Replace option in the app.
                    ar.Outcome = single && !chosenEventId.HasValue ? "held" : "skippedExisting";
                    return;
                }
                await DeleteExistingAsync(log, tables, chosen.EventId, hasherId);
            }

            // Marks from our own exported waypoints, then an On Inn at the end
            // unless the file already carried one.
            var toWrite = new List<WritePoint>(thinned);
            bool hasOnInn = false;
            foreach (WritePoint m in act.Marks)
            {
                if (m.Type != null && m.Type.StartsWith("OIN")) hasOnInn = true;
                toWrite.Add(m);
            }
            if (!hasOnInn)
            {
                toWrite.Add(new WritePoint(last.TimestampMs + 1000, last.Latitude, last.Longitude, DefaultAccuracyMeters, last.Altitude, "OIN"));
            }
            toWrite.Sort((a, b) => a.TimestampMs.CompareTo(b.TimestampMs));

            string eventKey = chosen.EventId.ToString("D").ToLowerInvariant();
            string userKey = hasherId.ToString("D").ToLowerInvariant();
            int written = 0;
            for (int i = 0; i < toWrite.Count; i += WriteChunk)
            {
                List<WritePoint> chunk = toWrite.GetRange(i, Math.Min(WriteChunk, toWrite.Count - i));
                PositionWriter.Outcome o = await PositionWriter.WriteAsync(tables, log, eventKey, userKey, chunk);
                written += o.Stored;
            }
            ar.Points = written;
            await EnsureAttendanceAsync(conn, chosen.EventId, hasherId, log);
            ar.Outcome = chosen.ExistingTrackPoints > 0 ? "replaced" : "imported";
            log.LogInformation("TrackImport: {Points} point(s) imported for hasher {Hasher} onto event {Event} ({Name}).",
                written, userKey, eventKey, ar.Name);
        }

        // ── SQL ───────────────────────────────────────────────────────────────

        private static async Task<List<Candidate>> FindRunsAsync(SqlConnection conn, Guid hasherId, WritePoint first, WritePoint last)
        {
            var list = new List<Candidate>();
            using SqlCommand cmd = new("[HC6].[nonApi_findRunForTrack]", conn) { CommandType = CommandType.StoredProcedure, CommandTimeout = 15 };
            cmd.Parameters.Add("@userId", SqlDbType.UniqueIdentifier).Value = hasherId;
            cmd.Parameters.Add("@firstPointUtc", SqlDbType.DateTime2).Value = DateTimeOffset.FromUnixTimeMilliseconds(first.TimestampMs).UtcDateTime;
            cmd.Parameters.Add("@lastPointUtc", SqlDbType.DateTime2).Value = DateTimeOffset.FromUnixTimeMilliseconds(last.TimestampMs).UtcDateTime;
            cmd.Parameters.Add("@latitude", SqlDbType.Decimal).Value = (decimal)first.Latitude;
            cmd.Parameters.Add("@longitude", SqlDbType.Decimal).Value = (decimal)first.Longitude;
            cmd.Parameters["@latitude"].Precision = 18; cmd.Parameters["@latitude"].Scale = 15;
            cmd.Parameters["@longitude"].Precision = 19; cmd.Parameters["@longitude"].Scale = 15;
            using SqlDataReader r = await cmd.ExecuteReaderAsync();
            while (await r.ReadAsync())
            {
                list.Add(new Candidate
                {
                    EventId = r.GetGuid(r.GetOrdinal("eventId")),
                    EventName = r["eventName"] as string ?? "Run",
                    KennelName = r["kennelName"] as string ?? string.Empty,
                    StartLocal = r["eventStartLocal"] is DateTime d ? d : null,
                    HasLocation = Convert.ToInt32(r["hasLocation"]) == 1,
                    DistanceMeters = r["distanceMeters"] is DBNull ? null : Convert.ToInt32(r["distanceMeters"]),
                    ExistingTrackPoints = Convert.ToInt32(r["existingTrackPoints"]),
                });
            }
            return list;
        }

        private static string? ComposeNotes(Activity act)
        {
            string? title = act.Title?.Trim();
            // Strava's auto-titles ("Morning Run", "Evening Ride") say nothing; a title only counts when the person wrote one.
            if (title != null && System.Text.RegularExpressions.Regex.IsMatch(title, @"^(Morning|Afternoon|Evening|Night|Lunch|Early Morning|Late Night)\s+(Run|Ride|Walk|Hike|Swim|Workout|Activity)$", System.Text.RegularExpressions.RegexOptions.IgnoreCase)) title = null;
            string? desc = act.Description?.Trim();
            string joined = string.IsNullOrEmpty(title) ? (desc ?? string.Empty)
                : string.IsNullOrEmpty(desc) ? title : title + "\n\n" + desc;
            if (string.IsNullOrWhiteSpace(joined)) return null;
            return joined.Length > 4000 ? joined[..4000] : joined;
        }

        private static async Task SetNotesIfBlankAsync(SqlConnection conn, Guid eventId, Guid hasherId, string? notes, ILogger log)
        {
            if (string.IsNullOrWhiteSpace(notes)) return;
            try
            {
                using SqlCommand cmd = new("[HC6].[nonApi_setTrackNotes]", conn) { CommandType = CommandType.StoredProcedure, CommandTimeout = 15 };
                cmd.Parameters.Add("@eventId", SqlDbType.UniqueIdentifier).Value = eventId;
                cmd.Parameters.Add("@userId", SqlDbType.UniqueIdentifier).Value = hasherId;
                cmd.Parameters.Add("@notes", SqlDbType.NVarChar, 4000).Value = notes;
                await cmd.ExecuteNonQueryAsync();
            }
            catch (Exception ex)
            {
                log.LogWarning("TrackImport: notes for event {Event} / hasher {Hasher} failed: {Message}", eventId, hasherId, ex.Message);
            }
        }

        /// <summary>
        /// A Strava archive's activities.csv: "Activity Name" and "Activity
        /// Description" keyed by "Filename" (e.g. activities/1234.fit.gz).
        /// RFC 4180 quoting — descriptions carry commas and newlines.
        /// </summary>
        private static Dictionary<string, (string? title, string? description)> ReadArchiveNotes(Stream zipStream)
        {
            var map = new Dictionary<string, (string?, string?)>(StringComparer.OrdinalIgnoreCase);
            try
            {
                zipStream.Position = 0;
                using var zip = new ZipArchive(zipStream, ZipArchiveMode.Read, leaveOpen: true);
                ZipArchiveEntry? csv = zip.Entries.FirstOrDefault(e => e.Name.Equals("activities.csv", StringComparison.OrdinalIgnoreCase));
                if (csv == null) return map;
                string text;
                using (var r = new StreamReader(csv.Open(), Encoding.UTF8)) text = r.ReadToEnd();
                List<List<string>> rows = ParseCsv(text);
                if (rows.Count < 2) return map;
                List<string> header = rows[0];
                int iName = header.FindIndex(h => h.Trim().Equals("Activity Name", StringComparison.OrdinalIgnoreCase));
                int iDesc = header.FindIndex(h => h.Trim().Equals("Activity Description", StringComparison.OrdinalIgnoreCase));
                int iFile = header.FindIndex(h => h.Trim().Equals("Filename", StringComparison.OrdinalIgnoreCase));
                if (iFile < 0) return map;
                foreach (List<string> row in rows.Skip(1))
                {
                    if (iFile >= row.Count) continue;
                    string file = row[iFile].Trim();
                    if (file.Length == 0) continue;
                    string? name = iName >= 0 && iName < row.Count ? row[iName] : null;
                    string? desc = iDesc >= 0 && iDesc < row.Count ? row[iDesc] : null;
                    map[file] = (name, desc);
                }
            }
            catch
            {
                // No CSV or an odd one: the tracks still import, just without notes.
            }
            return map;
        }

        private static void ApplyCsvNotes(Activity? act, string entryName, Dictionary<string, (string? title, string? description)> csvNotes)
        {
            if (act == null || csvNotes.Count == 0) return;
            if (!csvNotes.TryGetValue(entryName, out var n))
            {
                // The CSV names "activities/123.fit.gz"; a zip entry may say the same, or just the file.
                string tail = entryName.Substring(entryName.LastIndexOf('/') + 1);
                var hit = csvNotes.FirstOrDefault(kv => kv.Key.EndsWith("/" + tail, StringComparison.OrdinalIgnoreCase) || kv.Key.Equals(tail, StringComparison.OrdinalIgnoreCase));
                if (hit.Key == null) return;
                n = hit.Value;
            }
            act.Title ??= n.title;
            act.Description ??= n.description;
        }

        private static List<List<string>> ParseCsv(string text)
        {
            var rows = new List<List<string>>();
            var row = new List<string>();
            var cell = new StringBuilder();
            bool inQuotes = false;
            for (int i = 0; i < text.Length; i++)
            {
                char c = text[i];
                if (inQuotes)
                {
                    if (c == '"')
                    {
                        if (i + 1 < text.Length && text[i + 1] == '"') { cell.Append('"'); i++; }
                        else inQuotes = false;
                    }
                    else cell.Append(c);
                }
                else if (c == '"') inQuotes = true;
                else if (c == ',') { row.Add(cell.ToString()); cell.Clear(); }
                else if (c == '\r') { }
                else if (c == '\n') { row.Add(cell.ToString()); cell.Clear(); rows.Add(row); row = new List<string>(); }
                else cell.Append(c);
            }
            if (cell.Length > 0 || row.Count > 0) { row.Add(cell.ToString()); rows.Add(row); }
            return rows;
        }

        private static async Task EnsureAttendanceAsync(SqlConnection conn, Guid eventId, Guid hasherId, ILogger log)
        {
            try
            {
                using SqlCommand cmd = new("[HC6].[nonApi_ensureTrackAttendance]", conn) { CommandType = CommandType.StoredProcedure, CommandTimeout = 30 };
                cmd.Parameters.Add("@eventId", SqlDbType.UniqueIdentifier).Value = eventId;
                cmd.Parameters.Add("@userId", SqlDbType.UniqueIdentifier).Value = hasherId;
                using SqlDataReader r = await cmd.ExecuteReaderAsync();
                while (await r.ReadAsync()) { }
            }
            catch (Exception ex)
            {
                log.LogWarning("TrackImport: attendance for event {Event} / hasher {Hasher} failed: {Message}", eventId, hasherId, ex.Message);
            }
        }

        public static async Task UpdateAsync(SqlConnection conn, Guid id, Status status, Kind? kind, int? nextIndex, int? activityCount,
            Result result, string? error = null)
        {
            int imported = result.Activities.Count(a => a.Outcome is "imported" or "replaced");
            int held = result.Activities.Count(a => a.Outcome == "held");
            int skipped = result.Activities.Count(a => a.Outcome is not ("imported" or "replaced" or "held" or "pending"));
            using SqlCommand cmd = new("[HC6].[nonApi_updateTrackImport]", conn) { CommandType = CommandType.StoredProcedure, CommandTimeout = 30 };
            cmd.Parameters.Add("@id", SqlDbType.UniqueIdentifier).Value = id;
            cmd.Parameters.Add("@status", SqlDbType.SmallInt).Value = (short)status;
            cmd.Parameters.Add("@kind", SqlDbType.SmallInt).Value = kind.HasValue ? (short)kind.Value : DBNull.Value;
            cmd.Parameters.Add("@nextIndex", SqlDbType.Int).Value = nextIndex.HasValue ? nextIndex.Value : DBNull.Value;
            cmd.Parameters.Add("@activityCount", SqlDbType.Int).Value = activityCount.HasValue ? activityCount.Value : DBNull.Value;
            cmd.Parameters.Add("@importedCount", SqlDbType.Int).Value = imported;
            cmd.Parameters.Add("@skippedCount", SqlDbType.Int).Value = skipped;
            cmd.Parameters.Add("@heldCount", SqlDbType.Int).Value = held;
            cmd.Parameters.Add("@resultJson", SqlDbType.NVarChar, -1).Value = JsonConvert.SerializeObject(result);
            cmd.Parameters.Add("@errorMessage", SqlDbType.NVarChar, 2500).Value = (object?)error ?? DBNull.Value;
            await cmd.ExecuteNonQueryAsync();
        }

        private static async Task DeleteExistingAsync(ILogger log, TableServiceClient tables, Guid eventId, Guid hasherId)
        {
            string eventKey = eventId.ToString("D").ToLowerInvariant();
            string userKey = hasherId.ToString("D").ToLowerInvariant();
            TableClient eventTable = tables.GetTableClient(PositionWriter.EventTableName);
            TableClient userTable = tables.GetTableClient(PositionWriter.UserTableName);
            string filter = $"PartitionKey eq '{eventKey}' and UserId eq '{userKey}'";
            var keys = new List<string>();
            await foreach (TableEntity e in eventTable.QueryAsync<TableEntity>(filter, select: new[] { "RowKey" })) keys.Add(e.RowKey);
            foreach (string rk in keys)
            {
                try { await eventTable.DeleteEntityAsync(eventKey, rk); } catch (Azure.RequestFailedException ex) when (ex.Status == 404) { }
                try { await userTable.DeleteEntityAsync(userKey, rk); } catch (Azure.RequestFailedException ex) when (ex.Status == 404) { }
            }
            // The summary is rebuilt by the writes that follow; clear it so the
            // replaced track starts from zero (as DeletePositions does when the
            // last point goes).
            string? cs = Environment.GetEnvironmentVariable("HcDbConnectionString");
            if (!string.IsNullOrWhiteSpace(cs))
            {
                try
                {
                    using SqlConnection c = new(cs);
                    await c.OpenAsync();
                    using SqlCommand cmd = new(
                        "UPDATE HC.HasherEventMap SET TrackFirstPointAt = NULL, TrackLastPointAt = NULL, TrackPointCount = NULL, TrackGzip = NULL " +
                        " WHERE EventId = @eventId AND UserId = @userId;", c) { CommandTimeout = 5 };
                    cmd.Parameters.Add("@eventId", SqlDbType.UniqueIdentifier).Value = eventId;
                    cmd.Parameters.Add("@userId", SqlDbType.UniqueIdentifier).Value = hasherId;
                    await cmd.ExecuteNonQueryAsync();
                }
                catch (Exception ex)
                {
                    log.LogWarning("TrackImport: clearing the replaced track's summary failed: {Message}", ex.Message);
                }
            }
            log.LogInformation("TrackImport: replaced — deleted {Count} existing point(s) for hasher {Hasher} on event {Event}.", keys.Count, userKey, eventKey);
        }

        // ── Containers ────────────────────────────────────────────────────────

        public static Kind SniffKind(Stream s, string? fileName)
        {
            long pos = s.Position;
            byte[] head = new byte[16];
            int n = s.Read(head, 0, head.Length);
            s.Position = pos;
            if (n >= 4 && head[0] == 0x50 && head[1] == 0x4B && head[2] == 0x03 && head[3] == 0x04) return Kind.Zip;
            if (n >= 2 && head[0] == 0x1F && head[1] == 0x8B)
            {
                // gzip: decide by the inner name
                string inner = StripGz(fileName ?? string.Empty);
                return KindByName(inner);
            }
            if (n >= 12 && head[8] == (byte)'.' && head[9] == (byte)'F' && head[10] == (byte)'I' && head[11] == (byte)'T') return Kind.Fit;
            string text = Encoding.ASCII.GetString(head, 0, n);
            if (text.TrimStart().StartsWith("<")) return KindByName(fileName ?? string.Empty) is Kind.Tcx ? Kind.Tcx : Kind.Gpx;
            return KindByName(fileName ?? string.Empty);
        }

        private static string StripGz(string name) => name.EndsWith(".gz", StringComparison.OrdinalIgnoreCase) ? name[..^3] : name;

        private static Kind KindByName(string name)
        {
            string n = StripGz(name).ToLowerInvariant();
            if (n.EndsWith(".gpx")) return Kind.Gpx;
            if (n.EndsWith(".tcx")) return Kind.Tcx;
            if (n.EndsWith(".fit")) return Kind.Fit;
            if (n.EndsWith(".zip")) return Kind.Zip;
            return Kind.Unknown;
        }

        /// <summary>
        /// The activities in the upload, in a stable order (a zip's entries
        /// sorted by name), each with a way to open its decompressed bytes.
        /// A single file is one entry. Entries that are not track files
        /// (photos, CSVs) are left out.
        /// </summary>
        public static List<(string name, Func<Stream> open)> EnumerateEntries(Stream stream, Kind kind, string fileName)
        {
            var list = new List<(string, Func<Stream>)>();
            if (kind == Kind.Zip)
            {
                var zip = new ZipArchive(stream, ZipArchiveMode.Read, leaveOpen: true);
                foreach (ZipArchiveEntry entry in zip.Entries.Where(e => e.Length > 0).OrderBy(e => e.FullName, StringComparer.Ordinal))
                {
                    if (KindByName(entry.FullName) is Kind.Unknown or Kind.Zip) continue;
                    ZipArchiveEntry captured = entry;
                    list.Add((captured.FullName, () => MaybeGunzip(captured.Open(), captured.FullName)));
                }
                return list;
            }
            list.Add((fileName, () => { stream.Position = 0; return MaybeGunzip(new NonClosingStream(stream), fileName); }));
            return list;
        }

        private static Stream MaybeGunzip(Stream s, string name)
        {
            // Buffer into memory: parsers need to read once, and a zip entry
            // stream is forward-only. Activities are a few MB at most.
            byte[] head = new byte[2];
            using var ms = new MemoryStream();
            s.CopyTo(ms);
            byte[] bytes = ms.ToArray();
            if (bytes.Length >= 2 && bytes[0] == 0x1F && bytes[1] == 0x8B)
            {
                using var gz = new GZipStream(new MemoryStream(bytes), CompressionMode.Decompress);
                using var outMs = new MemoryStream();
                gz.CopyTo(outMs);
                return new MemoryStream(outMs.ToArray());
            }
            return new MemoryStream(bytes);
        }

        private sealed class NonClosingStream : Stream
        {
            private readonly Stream _inner;
            public NonClosingStream(Stream inner) { _inner = inner; }
            public override bool CanRead => _inner.CanRead;
            public override bool CanSeek => _inner.CanSeek;
            public override bool CanWrite => false;
            public override long Length => _inner.Length;
            public override long Position { get => _inner.Position; set => _inner.Position = value; }
            public override void Flush() { }
            public override int Read(byte[] buffer, int offset, int count) => _inner.Read(buffer, offset, count);
            public override long Seek(long offset, SeekOrigin origin) => _inner.Seek(offset, origin);
            public override void SetLength(long value) => throw new NotSupportedException();
            public override void Write(byte[] buffer, int offset, int count) => throw new NotSupportedException();
            protected override void Dispose(bool disposing) { /* leave the blob stream open */ }
        }

        private static string ContainerOf(string blobUrl) => new Uri(blobUrl).Segments[1].TrimEnd('/');
        private static string BlobNameOf(string blobUrl) => Uri.UnescapeDataString(string.Concat(new Uri(blobUrl).Segments.Skip(2)));

        // ── Parsers ───────────────────────────────────────────────────────────

        public static Activity? ParseActivity(Stream s, string name)
        {
            using (s)
            {
                byte[] bytes;
                using (var ms = new MemoryStream()) { s.CopyTo(ms); bytes = ms.ToArray(); }
                if (bytes.Length >= 12 && bytes[8] == '.' && bytes[9] == 'F' && bytes[10] == 'I' && bytes[11] == 'T')
                    return ParseFit(bytes, name);
                string text = Encoding.UTF8.GetString(bytes);
                if (!text.TrimStart().StartsWith("<")) return null;
                XDocument doc;
                try { doc = XDocument.Parse(text); } catch { return null; }
                string root = doc.Root?.Name.LocalName ?? string.Empty;
                if (root.Equals("gpx", StringComparison.OrdinalIgnoreCase)) return ParseGpx(doc, name);
                if (root.Equals("TrainingCenterDatabase", StringComparison.OrdinalIgnoreCase)) return ParseTcx(doc, name);
                return null;
            }
        }

        private static long? ParseTime(string? raw)
        {
            if (string.IsNullOrWhiteSpace(raw)) return null;
            string t = raw.Trim();
            // GPX/TCX times are UTC by spec; one with no zone is read as UTC.
            if (!(t.EndsWith("Z") || System.Text.RegularExpressions.Regex.IsMatch(t, @"[+-]\d\d:?\d\d$"))) t += "Z";
            return DateTimeOffset.TryParse(t, CultureInfo.InvariantCulture, DateTimeStyles.AdjustToUniversal, out DateTimeOffset dto)
                ? dto.ToUnixTimeMilliseconds() : null;
        }

        private static string? Child(XElement el, string localName) =>
            el.Descendants().FirstOrDefault(c => c.Name.LocalName == localName)?.Value?.Trim();

        private static double? Dbl(string? s) =>
            double.TryParse(s, NumberStyles.Float, CultureInfo.InvariantCulture, out double d) ? d : null;

        public static Activity ParseGpx(XDocument doc, string name)
        {
            var act = new Activity { Name = name, Format = "gpx" };
            XElement? trk = doc.Descendants().FirstOrDefault(e => e.Name.LocalName == "trk");
            act.Sport = trk?.Elements().FirstOrDefault(e => e.Name.LocalName == "type")?.Value?.Trim();
            act.Title = trk?.Elements().FirstOrDefault(e => e.Name.LocalName == "name")?.Value?.Trim();
            act.Description = trk?.Elements().FirstOrDefault(e => e.Name.LocalName == "desc")?.Value?.Trim();
            foreach (XElement pt in doc.Descendants().Where(e => e.Name.LocalName == "trkpt"))
            {
                double? lat = Dbl(pt.Attribute("lat")?.Value), lon = Dbl(pt.Attribute("lon")?.Value);
                if (lat == null || lon == null) continue;
                long? ts = ParseTime(Child(pt, "time"));
                if (ts == null) { act.HadUntimedPoints = true; continue; }
                double? acc = Dbl(Child(pt, "Accuracy")) ?? (Dbl(Child(pt, "hdop")) is double h ? h * 5.0 : null);
                act.Points.Add(new WritePoint(ts.Value, lat.Value, lon.Value, Clamp(acc), Dbl(Child(pt, "ele")), null));
            }
            foreach (XElement wp in doc.Descendants().Where(e => e.Name.LocalName == "wpt"))
            {
                double? lat = Dbl(wp.Attribute("lat")?.Value), lon = Dbl(wp.Attribute("lon")?.Value);
                long? ts = ParseTime(Child(wp, "time"));
                if (lat == null || lon == null || ts == null) continue;
                string? type = MarkTypeFor(Child(wp, "type"), Child(wp, "name"));
                if (type == null) continue;
                act.Marks.Add(new WritePoint(ts.Value, lat.Value, lon.Value, DefaultAccuracyMeters, Dbl(Child(wp, "ele")), type));
            }
            act.Points.Sort((a, b) => a.TimestampMs.CompareTo(b.TimestampMs));
            return act;
        }

        public static Activity ParseTcx(XDocument doc, string name)
        {
            var act = new Activity { Name = name, Format = "tcx" };
            act.Sport = doc.Descendants().FirstOrDefault(e => e.Name.LocalName == "Activity")?.Attribute("Sport")?.Value;
            foreach (XElement tp in doc.Descendants().Where(e => e.Name.LocalName == "Trackpoint"))
            {
                XElement? pos = tp.Elements().FirstOrDefault(e => e.Name.LocalName == "Position");
                if (pos == null) continue;
                double? lat = Dbl(Child(pos, "LatitudeDegrees")), lon = Dbl(Child(pos, "LongitudeDegrees"));
                if (lat == null || lon == null) continue;
                long? ts = ParseTime(tp.Elements().FirstOrDefault(e => e.Name.LocalName == "Time")?.Value);
                if (ts == null) { act.HadUntimedPoints = true; continue; }
                act.Points.Add(new WritePoint(ts.Value, lat.Value, lon.Value, DefaultAccuracyMeters,
                    Dbl(tp.Elements().FirstOrDefault(e => e.Name.LocalName == "AltitudeMeters")?.Value), null));
            }
            act.Points.Sort((a, b) => a.TimestampMs.CompareTo(b.TimestampMs));
            return act;
        }

        /// <summary>
        /// A minimal FIT decoder: definition and data records, the `record`
        /// message (global 20) for position/time/altitude/accuracy and the
        /// `session` message (18) for the sport. Developer fields and every
        /// other message are skipped by size. CRCs are not checked. Written
        /// against the FIT protocol document rather than taking the only
        /// NuGet package, which is an unofficial repack.
        /// </summary>
        public static Activity ParseFit(byte[] b, string name)
        {
            var act = new Activity { Name = name, Format = "fit" };
            const long FitEpochUnixSeconds = 631_065_600; // 1989-12-31T00:00:00Z
            int headerSize = b[0];
            int dataSize = BitConverter.ToInt32(b, 4);
            int end = Math.Min(b.Length, headerSize + dataSize);
            int p = headerSize;

            var defs = new Dictionary<int, FitDef>();
            uint lastTimestamp = 0;
            int lastTimestampLow5 = -1;

            while (p < end)
            {
                byte hdr = b[p++];
                bool compressed = (hdr & 0x80) != 0;
                int local;
                int timeOffset = 0;
                bool isDef = false, hasDev = false;
                if (compressed)
                {
                    local = (hdr >> 5) & 0x03;
                    timeOffset = hdr & 0x1F;
                }
                else
                {
                    isDef = (hdr & 0x40) != 0;
                    hasDev = (hdr & 0x20) != 0;
                    local = hdr & 0x0F;
                }

                if (isDef)
                {
                    if (p + 5 > end) break;
                    p++; // reserved
                    bool bigEndian = b[p++] == 1;
                    int global = bigEndian ? (b[p] << 8) | b[p + 1] : b[p] | (b[p + 1] << 8);
                    p += 2;
                    int nFields = b[p++];
                    var def = new FitDef { Global = global, BigEndian = bigEndian };
                    for (int i = 0; i < nFields; i++)
                    {
                        if (p + 3 > end) break;
                        def.Fields.Add((b[p], b[p + 1], b[p + 2]));
                        p += 3;
                    }
                    if (hasDev)
                    {
                        int nDev = b[p++];
                        for (int i = 0; i < nDev; i++)
                        {
                            if (p + 3 > end) break;
                            def.DevBytes += b[p + 1];
                            p += 3;
                        }
                    }
                    defs[local] = def;
                    continue;
                }

                if (!defs.TryGetValue(local, out FitDef? d))
                {
                    break; // data before its definition: the file is not readable past here
                }
                int start = p;
                uint? ts = null; int? lat = null, lng = null; double? alt = null; double? acc = null; int? sport = null;
                foreach ((int num, int size, int baseType) in d.Fields)
                {
                    if (p + size > end) { p = end; break; }
                    if (d.Global == 20)
                    {
                        switch (num)
                        {
                            case 253: if (size == 4) { uint v = ReadU32(b, p, d.BigEndian); if (v != 0xFFFFFFFF) ts = v; } break;
                            case 0: if (size == 4) { int v = (int)ReadU32(b, p, d.BigEndian); if (v != 0x7FFFFFFF) lat = v; } break;
                            case 1: if (size == 4) { int v = (int)ReadU32(b, p, d.BigEndian); if (v != 0x7FFFFFFF) lng = v; } break;
                            case 2: if (size == 2) { int v = ReadU16(b, p, d.BigEndian); if (v != 0xFFFF) alt ??= v / 5.0 - 500; } break;
                            case 78: if (size == 4) { uint v = ReadU32(b, p, d.BigEndian); if (v != 0xFFFFFFFF) alt = v / 5.0 - 500; } break;
                            case 31: if (size == 1) { int v = b[p]; if (v != 0xFF) acc = v; } break;
                        }
                    }
                    else if (d.Global == 18 && num == 5 && size == 1)
                    {
                        if (b[p] != 0xFF) sport = b[p];
                    }
                    p += size;
                }
                p += d.DevBytes;
                if (p < start) p = start;

                if (d.Global == 18 && sport.HasValue) act.Sport = FitSport(sport.Value);
                if (d.Global != 20) continue;

                if (compressed)
                {
                    if (lastTimestampLow5 >= 0)
                    {
                        int delta = (timeOffset - lastTimestampLow5) & 0x1F;
                        lastTimestamp += (uint)delta;
                        lastTimestampLow5 = timeOffset;
                        ts = lastTimestamp;
                    }
                }
                else if (ts.HasValue)
                {
                    lastTimestamp = ts.Value;
                    lastTimestampLow5 = (int)(ts.Value & 0x1F);
                }

                if (lat == null || lng == null) continue;
                if (ts == null) { act.HadUntimedPoints = true; continue; }
                long ms = (FitEpochUnixSeconds + ts.Value) * 1000L;
                double latDeg = lat.Value * (180.0 / 2147483648.0);
                double lngDeg = lng.Value * (180.0 / 2147483648.0);
                act.Points.Add(new WritePoint(ms, latDeg, lngDeg, Clamp(acc), alt, null));
                if (act.Points.Count > MaxPointsPerActivity) break;
            }
            act.Points.Sort((a, b2) => a.TimestampMs.CompareTo(b2.TimestampMs));
            return act;
        }

        private sealed class FitDef
        {
            public int Global;
            public bool BigEndian;
            public int DevBytes;
            public List<(int num, int size, int baseType)> Fields = new();
        }

        private static uint ReadU32(byte[] b, int p, bool be) =>
            be ? (uint)((b[p] << 24) | (b[p + 1] << 16) | (b[p + 2] << 8) | b[p + 3])
               : (uint)(b[p] | (b[p + 1] << 8) | (b[p + 2] << 16) | (b[p + 3] << 24));
        private static int ReadU16(byte[] b, int p, bool be) => be ? (b[p] << 8) | b[p + 1] : b[p] | (b[p + 1] << 8);

        private static string FitSport(int v) => v switch
        {
            0 => "generic", 1 => "running", 2 => "cycling", 3 => "transition", 4 => "fitness_equipment", 5 => "swimming",
            11 => "walking", 17 => "hiking", 18 => "multisport", 20 => "e_biking", 21 => "motorcycling", 25 => "kayaking",
            _ => $"sport_{v}"
        };

        private static double? Clamp(double? acc) => acc.HasValue ? Math.Clamp(acc.Value, 3.0, 30.0) : DefaultAccuracyMeters;

        // ── Marks (our own GPX export's waypoints) ────────────────────────────

        // key → label words. Labels in the app carry emoji; compare words only.
        private static readonly (string key, string label)[] MarkTypes =
        {
            ("CHK", "check"), ("DRK", "drink stop"), ("FHK", "fish hook"), ("SC", "shortcut"), ("CB", "checkback"),
            ("HV", "hash view"), ("RG", "regroup"), ("WW", "whichy way"), ("FT", "false trail"), ("LAB", "custom label"),
            ("OIN", "on inn"), ("CAU", "caution"),
        };

        private static string Plain(string s) =>
            System.Text.RegularExpressions.Regex.Replace(
                System.Text.RegularExpressions.Regex.Replace(s, "[^A-Za-z0-9 ]+", " "), @"\s+", " ").Trim().ToLowerInvariant();

        private static string? MarkTypeFor(string? typeLabel, string? name)
        {
            if (string.IsNullOrWhiteSpace(typeLabel)) return null;
            string wanted = Plain(typeLabel);
            foreach ((string key, string label) in MarkTypes)
            {
                if (label == wanted || key.ToLowerInvariant() == wanted)
                {
                    bool custom = !string.IsNullOrWhiteSpace(name) && Plain(name!) != label;
                    return custom ? $"{key}::{name!.Trim()}" : key;
                }
            }
            return null;
        }

        // ── Geometry ──────────────────────────────────────────────────────────

        public static List<WritePoint> Thin(List<WritePoint> pts)
        {
            var outp = new List<WritePoint>();
            WritePoint? lastKept = null;
            for (int i = 0; i < pts.Count; i++)
            {
                WritePoint p = pts[i];
                bool isLast = i == pts.Count - 1;
                if (lastKept != null && !isLast)
                {
                    double m = Haversine(lastKept.Latitude, lastKept.Longitude, p.Latitude, p.Longitude);
                    long dt = p.TimestampMs - lastKept.TimestampMs;
                    if (m < ThinDistanceMeters && dt < ThinIntervalMs) continue;
                }
                outp.Add(new WritePoint(p.TimestampMs, Math.Round(p.Latitude, 5), Math.Round(p.Longitude, 5),
                    p.Accuracy.HasValue ? Math.Round(p.Accuracy.Value, 2) : DefaultAccuracyMeters,
                    p.Altitude.HasValue ? Math.Round(p.Altitude.Value, 2) : 0.0, p.Type));
                lastKept = p;
            }
            return outp;
        }

        public static double Distance(List<WritePoint> pts)
        {
            double d = 0;
            for (int i = 1; i < pts.Count; i++) d += Haversine(pts[i - 1].Latitude, pts[i - 1].Longitude, pts[i].Latitude, pts[i].Longitude);
            return d;
        }

        private static double Haversine(double lat1, double lon1, double lat2, double lon2)
        {
            const double R = 6371000.0;
            double dLat = (lat2 - lat1) * Math.PI / 180, dLon = (lon2 - lon1) * Math.PI / 180;
            double a = Math.Sin(dLat / 2) * Math.Sin(dLat / 2) +
                       Math.Cos(lat1 * Math.PI / 180) * Math.Cos(lat2 * Math.PI / 180) * Math.Sin(dLon / 2) * Math.Sin(dLon / 2);
            return 2 * R * Math.Asin(Math.Min(1, Math.Sqrt(a)));
        }

        private static Result ParseResult(string? json)
        {
            if (string.IsNullOrWhiteSpace(json)) return new Result();
            try { return JsonConvert.DeserializeObject<Result>(json) ?? new Result(); }
            catch { return new Result(); }
        }
    }
}
