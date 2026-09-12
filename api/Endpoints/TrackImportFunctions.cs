using System.Data;
using System.IO;
using Azure.Data.Tables;
using Azure.Storage.Blobs;
using Azure.Storage.Sas;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace HcWebApi.Endpoints
{
    /// <summary>
    /// The three faces of a track import (E5.F5.S7). Device-authenticated
    /// through SPs like every app call; the bytes never pass through a
    /// function — the phone uploads straight to blob storage with a SAS.
    ///
    ///   GetTrackImportUploadToken   POST {deviceId, accessToken, fileName}
    ///       → {jobId, sasUrl, blobUrl}. Mints the job id so the blob name
    ///         and the job row agree; the app then uploads and calls
    ///         hcapp_submitTrackImport.
    ///   ProcessTrackImport          POST {deviceId, accessToken, jobId}
    ///       → runs one slice (budget below) and returns the job as
    ///         hcapp_getTrackImports would; the app calls again while
    ///         status is 1. With {resolve: {index, eventId, replace}} it
    ///         imports a held activity to the chosen run instead.
    ///   ProcessTrackImportsNightly  03:45 UTC — finishes jobs the phone
    ///       abandoned (never started, or stale for 15 min).
    /// </summary>
    public class TrackImportFunctions
    {
        internal const string ContainerName = "track-imports";
        internal static readonly TimeSpan SliceBudget = TimeSpan.FromSeconds(40);
        internal static readonly TimeSpan NightlyBudget = TimeSpan.FromMinutes(8);

        private readonly ILogger<TrackImportFunctions> _log;
        private readonly TableServiceClient _tables;
        private readonly BlobServiceClient _blobs;

        public TrackImportFunctions(ILogger<TrackImportFunctions> logger)
        {
            _log = logger;
            string storageConnection = Environment.GetEnvironmentVariable("AzureWebJobsStorage")
                ?? throw new InvalidOperationException("AzureWebJobsStorage is not set in the environment.");
            _tables = new TableServiceClient(storageConnection);
            string blobConnection = Environment.GetEnvironmentVariable("HC_BLOB_STORAGE_CONNECTION_STRING") ?? storageConnection;
            _blobs = new BlobServiceClient(blobConnection);
        }

        // ── Upload token ──────────────────────────────────────────────────────

        [Function("GetTrackImportUploadToken")]
        public async Task<IActionResult> GetUploadToken(
            [HttpTrigger(AuthorizationLevel.Anonymous, "post")] HttpRequest req)
        {
            JObject? data = await ReadBodyAsync(req);
            if (data == null) return new BadRequestObjectResult("Invalid JSON body.");
            string? deviceId = data["deviceId"]?.ToString();
            string? accessToken = data["accessToken"]?.ToString();
            string fileName = SafeName(data["fileName"]?.ToString());
            if (string.IsNullOrEmpty(deviceId) || string.IsNullOrEmpty(accessToken))
                return new BadRequestObjectResult("Missing required parameters.");

            string? connectionString = Environment.GetEnvironmentVariable("HcDbConnectionString");
            if (string.IsNullOrWhiteSpace(connectionString)) return new StatusCodeResult(500);

            Guid? userId;
            try
            {
                using SqlConnection conn = new(connectionString);
                await conn.OpenAsync();
                (IActionResult? failure, userId) = await AuthenticateAsync(conn, "[HC6].[hcapp_getTrackImportUploadToken]", deviceId, accessToken);
                if (failure != null) return failure;
            }
            catch (Exception ex)
            {
                _log.LogError("GetTrackImportUploadToken SQL error: {Message}", ex.Message);
                return new StatusCodeResult(500);
            }
            if (userId == null) return new StatusCodeResult(500);

            try
            {
                Guid jobId = Guid.NewGuid();
                string blobPath = $"{userId.Value.ToString("D").ToLowerInvariant()}/{jobId:D}_{fileName}";
                BlobContainerClient container = _blobs.GetBlobContainerClient(ContainerName);
                await container.CreateIfNotExistsAsync(); // private container
                BlobClient blob = container.GetBlobClient(blobPath);
                var sas = new BlobSasBuilder
                {
                    BlobContainerName = ContainerName,
                    BlobName = blobPath,
                    Resource = "b",
                    ExpiresOn = DateTimeOffset.UtcNow.AddHours(2) // a big archive on a slow link
                };
                sas.SetPermissions(BlobSasPermissions.Write | BlobSasPermissions.Create);
                Uri sasUri = blob.GenerateSasUri(sas);
                return new OkObjectResult(new { jobId, sasUrl = sasUri.ToString(), blobUrl = blob.Uri.ToString() });
            }
            catch (Exception ex)
            {
                _log.LogError("GetTrackImportUploadToken blob error: {Message}", ex.Message);
                return new StatusCodeResult(500);
            }
        }

        // ── Process a slice / resolve a held item ─────────────────────────────

        [Function("ProcessTrackImport")]
        public async Task<IActionResult> Process(
            [HttpTrigger(AuthorizationLevel.Anonymous, "post")] HttpRequest req)
        {
            JObject? data = await ReadBodyAsync(req);
            if (data == null) return new BadRequestObjectResult("Invalid JSON body.");
            string? deviceId = data["deviceId"]?.ToString();
            string? accessToken = data["accessToken"]?.ToString();
            if (string.IsNullOrEmpty(deviceId) || string.IsNullOrEmpty(accessToken) || !Guid.TryParse(data["jobId"]?.ToString(), out Guid jobId))
                return new BadRequestObjectResult("Missing required parameters.");

            string? connectionString = Environment.GetEnvironmentVariable("HcDbConnectionString");
            if (string.IsNullOrWhiteSpace(connectionString)) return new StatusCodeResult(500);

            try
            {
                using SqlConnection conn = new(connectionString);
                await conn.OpenAsync();

                // hcapp_getTrackImports authenticates AND scopes to the caller's own job.
                using SqlCommand cmd = new("[HC6].[hcapp_getTrackImports]", conn) { CommandType = CommandType.StoredProcedure, CommandTimeout = 15 };
                cmd.Parameters.AddWithValue("@deviceId", deviceId);
                cmd.Parameters.AddWithValue("@accessToken", accessToken);
                cmd.Parameters.AddWithValue("@jobId", jobId);
                TrackImportProcessor.Job? job = null;
                using (SqlDataReader r = await cmd.ExecuteReaderAsync())
                {
                    if (await r.ReadAsync())
                    {
                        if (HasColumn(r, "success") && Convert.ToInt32(r["success"]) == 0)
                        {
                            string? msg = null;
                            if (await r.NextResultAsync() && await r.ReadAsync()) msg = r["errorUserMessage"]?.ToString();
                            return new ObjectResult(new { success = false, errorUserMessage = msg }) { StatusCode = 403 };
                        }
                        job = new TrackImportProcessor.Job
                        {
                            Id = r.GetGuid(r.GetOrdinal("jobId")),
                            HasherId = r.GetGuid(r.GetOrdinal("hasherId")),
                            BlobUrl = r["blobUrl"] as string ?? string.Empty,
                            FileName = r["fileName"] as string,
                            NextIndex = Convert.ToInt32(r["nextIndex"]),
                            ResultJson = r["resultJson"] as string,
                        };
                    }
                }
                if (job == null) return new NotFoundObjectResult(new { error = "No such import." });

                // Re-import (James, 2026-09-12): run the whole file again from
                // the blob we kept, without another upload — for the hasher who
                // fixed a run's start point after the first pass and wants the
                // activities that missed it found now. The job restarts at
                // index 0 with an empty result; runs that already have their
                // track come back skippedExisting, as any archive pass does.
                // The first slice runs in this same call; the phone drives the
                // rest exactly as for a fresh upload, the nightly backstop
                // finishes a stalled one.
                bool reimport = data["reimport"]?.Value<bool>() ?? false;
                if (reimport)
                {
                    var fresh = new TrackImportProcessor.Result();
                    await TrackImportProcessor.UpdateAsync(conn, job.Id, TrackImportProcessor.Status.Processing, null, 0, null, fresh);
                    job.NextIndex = 0;
                    job.ResultJson = JsonConvert.SerializeObject(fresh);
                    _log.LogInformation("TrackImport {Job}: re-import requested; restarted from 0.", job.Id);
                }

                JObject? resolve = data["resolve"] as JObject;
                if (resolve != null)
                {
                    int index = resolve["index"]?.Value<int>() ?? -1;
                    bool replace = resolve["replace"]?.Value<bool>() ?? false;
                    if (index < 0 || !Guid.TryParse(resolve["eventId"]?.ToString(), out Guid eventId))
                        return new BadRequestObjectResult("resolve needs index and eventId.");
                    await TrackImportProcessor.ResolveAsync(_log, _tables, _blobs, conn, job, index, eventId, replace);
                }
                else
                {
                    await TrackImportProcessor.RunSliceAsync(_log, _tables, _blobs, conn, job, SliceBudget);
                }

                return new OkObjectResult(await ReadJobAsync(conn, deviceId, accessToken, jobId));
            }
            catch (Exception ex)
            {
                _log.LogError(ex, "ProcessTrackImport failed for job {JobId}.", jobId);
                try
                {
                    using SqlConnection conn = new(connectionString);
                    await conn.OpenAsync();
                    await TrackImportProcessor.UpdateAsync(conn, jobId, TrackImportProcessor.Status.Failed, null, null, null,
                        new TrackImportProcessor.Result(), ex.Message.Length > 2500 ? ex.Message[..2500] : ex.Message);
                }
                catch { /* the log line above is the record */ }
                return new ObjectResult(new { error = "The import failed. It has been recorded." }) { StatusCode = 500 };
            }
        }

        // ── Backstop ──────────────────────────────────────────────────────────

        [Function("ProcessTrackImportsNightly")]
        public async Task Nightly([TimerTrigger("0 45 3 * * *")] TimerInfo timer)
        {
            string? connectionString = Environment.GetEnvironmentVariable("HcDbConnectionString");
            if (string.IsNullOrWhiteSpace(connectionString)) return;
            var clock = System.Diagnostics.Stopwatch.StartNew();
            try
            {
                using SqlConnection conn = new(connectionString);
                await conn.OpenAsync();
                var jobs = new List<TrackImportProcessor.Job>();
                using (SqlCommand cmd = new("[HC6].[nonApi_getPendingTrackImports]", conn) { CommandType = CommandType.StoredProcedure, CommandTimeout = 30 })
                using (SqlDataReader r = await cmd.ExecuteReaderAsync())
                {
                    while (await r.ReadAsync())
                    {
                        jobs.Add(new TrackImportProcessor.Job
                        {
                            Id = r.GetGuid(r.GetOrdinal("jobId")),
                            HasherId = r.GetGuid(r.GetOrdinal("hasherId")),
                            BlobUrl = r["blobUrl"] as string ?? string.Empty,
                            FileName = r["fileName"] as string,
                            NextIndex = Convert.ToInt32(r["nextIndex"]),
                            ResultJson = r["resultJson"] as string,
                        });
                    }
                }
                int done = 0;
                foreach (TrackImportProcessor.Job job in jobs)
                {
                    TimeSpan left = NightlyBudget - clock.Elapsed;
                    if (left <= TimeSpan.Zero) break;
                    try
                    {
                        if (await TrackImportProcessor.RunSliceAsync(_log, _tables, _blobs, conn, job, left)) done++;
                    }
                    catch (Exception ex)
                    {
                        _log.LogWarning("ProcessTrackImportsNightly: job {JobId} failed: {Message}", job.Id, ex.Message);
                    }
                }
                _log.LogInformation("ProcessTrackImportsNightly: {Pending} pending, {Done} finished in {Seconds}s.", jobs.Count, done, (int)clock.Elapsed.TotalSeconds);
            }
            catch (Exception ex)
            {
                _log.LogError(ex, "ProcessTrackImportsNightly failed.");
            }
        }

        // ── Helpers ───────────────────────────────────────────────────────────

        private static async Task<(IActionResult? failure, Guid? userId)> AuthenticateAsync(SqlConnection conn, string proc, string deviceId, string accessToken)
        {
            using SqlCommand cmd = new(proc, conn) { CommandType = CommandType.StoredProcedure, CommandTimeout = 15 };
            cmd.Parameters.AddWithValue("@deviceId", deviceId);
            cmd.Parameters.AddWithValue("@accessToken", accessToken);
            using SqlDataReader r = await cmd.ExecuteReaderAsync();
            if (!await r.ReadAsync()) return (new StatusCodeResult(500), null);
            if (Convert.ToInt32(r["success"]) == 0)
            {
                var errorCode = r["errorCode"]; var errorType = r["errorType"];
                string? msg = null;
                if (await r.NextResultAsync() && await r.ReadAsync()) msg = r["errorUserMessage"]?.ToString();
                return (new ObjectResult(new { success = false, errorCode, errorType, errorUserMessage = msg }) { StatusCode = 403 }, null);
            }
            return (null, Guid.TryParse(r["userId"]?.ToString(), out Guid u) ? u : null);
        }

        /// The job as the app reads it, so one response shape serves polling and processing.
        private static async Task<object> ReadJobAsync(SqlConnection conn, string deviceId, string accessToken, Guid jobId)
        {
            using SqlCommand cmd = new("[HC6].[hcapp_getTrackImports]", conn) { CommandType = CommandType.StoredProcedure, CommandTimeout = 15 };
            cmd.Parameters.AddWithValue("@deviceId", deviceId);
            cmd.Parameters.AddWithValue("@accessToken", accessToken);
            cmd.Parameters.AddWithValue("@jobId", jobId);
            using SqlDataReader r = await cmd.ExecuteReaderAsync();
            var row = new Dictionary<string, object?>();
            if (await r.ReadAsync())
            {
                for (int i = 0; i < r.FieldCount; i++) row[r.GetName(i)] = r.IsDBNull(i) ? null : r.GetValue(i);
            }
            return row;
        }

        private static bool HasColumn(SqlDataReader r, string name)
        {
            for (int i = 0; i < r.FieldCount; i++) if (r.GetName(i).Equals(name, StringComparison.OrdinalIgnoreCase)) return true;
            return false;
        }

        private static async Task<JObject?> ReadBodyAsync(HttpRequest req)
        {
            string body = await new StreamReader(req.Body).ReadToEndAsync();
            try { return JObject.Parse(body); } catch { return null; }
        }

        private static string SafeName(string? name)
        {
            string n = (name ?? "upload").Trim();
            n = n.Substring(n.LastIndexOfAny(new[] { '/', '\\' }) + 1);
            var sb = new System.Text.StringBuilder();
            foreach (char c in n) sb.Append(char.IsLetterOrDigit(c) || c is '.' or '-' or '_' ? c : '_');
            string s = sb.ToString();
            if (s.Length > 120) s = s[^120..];
            return string.IsNullOrWhiteSpace(s) ? "upload" : s;
        }
    }
}
