using System.Data;
using System.IO;
using System.Net;
using System.Net.Http;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;

namespace HcWebApi.Endpoints
{
    // A phone that could not load somebody's profile photo reports the URL
    // here. The phone cannot tell a missing blob from a bad connection, and
    // must not be trusted to (a hostile client could wipe anybody's photo by
    // naming it), so THIS function asks blob storage itself. Only when storage
    // answers 404/410 is the photo replaced with a bundled avatar — via
    // HC6.nonApi_replaceBrokenPhoto, which corrects HC.Hasher.Photo and any
    // HC.HasherKennelMap.KennelUserPhoto carrying the same URL. The corrected
    // rows re-sync to every client on its next delta, so the broken image is
    // fixed for everyone, not just the reporter (E16.F3.S1).
    //
    // Guarded by the same X-Api-Key as GetPositions. Only URLs in our own
    // profile-photos container are accepted; anything else is refused unread.
    //
    // Body:     { "url": "https://harriercentral.blob.core.windows.net/profile-photos/<id>.jpg" }
    // Response: { "verified": bool, "status": int|null, "hasherRows": int, "kennelRows": int, "replacement": string|null }
    //   verified=false means storage did NOT say the blob is gone (it exists,
    //   or storage could not be reached) — nothing was changed.
    public class ReportBrokenPhoto
    {
        internal const string AllowedHost = "harriercentral.blob.core.windows.net";
        internal const string AllowedPathPrefix = "/profile-photos/";
        private const string AvatarBaseUrl = "https://" + AllowedHost + "/profile-photos";

        private static readonly HttpClient _httpClient = new() { Timeout = TimeSpan.FromSeconds(10) };

        private readonly ILogger<ReportBrokenPhoto> _log;

        public ReportBrokenPhoto(ILogger<ReportBrokenPhoto> logger)
        {
            _log = logger;
        }

        [Function("ReportBrokenPhoto")]
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

            string body;
            using (var reader = new StreamReader(req.Body))
            {
                body = await reader.ReadToEndAsync();
            }

            ReportRequest? request;
            try
            {
                request = JsonConvert.DeserializeObject<ReportRequest>(body);
            }
            catch (Exception ex)
            {
                _log.LogError(ex, "ReportBrokenPhoto: failed to deserialize payload.");
                return CreateJsonResult(StatusCodes.Status400BadRequest, new { error = "Invalid JSON payload." });
            }

            string url = request?.Url?.Trim() ?? string.Empty;
            if (!Uri.TryCreate(url, UriKind.Absolute, out Uri? uri)
                || uri.Scheme != Uri.UriSchemeHttps
                || !string.Equals(uri.Host, AllowedHost, StringComparison.OrdinalIgnoreCase)
                || !uri.AbsolutePath.StartsWith(AllowedPathPrefix, StringComparison.OrdinalIgnoreCase)
                || url.Length > 1000)
            {
                return CreateJsonResult(StatusCodes.Status400BadRequest,
                    new { error = "url must be an https URL in the profile-photos container." });
            }

            // Ask storage. A HEAD is enough: we want the status, not the bytes.
            int? status = null;
            try
            {
                using var head = new HttpRequestMessage(HttpMethod.Head, uri);
                using HttpResponseMessage resp = await _httpClient.SendAsync(head);
                status = (int)resp.StatusCode;
            }
            catch (Exception ex)
            {
                _log.LogWarning("ReportBrokenPhoto: HEAD {Url} failed: {Message}. Not verified.", url, ex.Message);
            }

            bool gone = status == (int)HttpStatusCode.NotFound || status == (int)HttpStatusCode.Gone;
            if (!gone)
            {
                _log.LogInformation("ReportBrokenPhoto: {Url} answered {Status} — not replaced.", url, status);
                return CreateJsonResult(StatusCodes.Status200OK,
                    new { verified = false, status, hasherRows = 0, kennelRows = 0, replacement = (string?)null });
            }

            string? connectionString = Environment.GetEnvironmentVariable("HcDbConnectionString");
            if (string.IsNullOrWhiteSpace(connectionString))
            {
                _log.LogError("ReportBrokenPhoto: HcDbConnectionString not set.");
                return CreateJsonResult(StatusCodes.Status500InternalServerError, new { error = "Database not configured." });
            }

            string replacement = PickReplacementAvatar(url);
            int hasherRows = 0, kennelRows = 0;
            try
            {
                using SqlConnection conn = new(connectionString);
                await conn.OpenAsync();
                using SqlCommand cmd = new("[HC6].[nonApi_replaceBrokenPhoto]", conn)
                {
                    CommandType = CommandType.StoredProcedure,
                    CommandTimeout = 10
                };
                cmd.Parameters.Add("@url", SqlDbType.NVarChar, 1000).Value = url;
                cmd.Parameters.Add("@replacement", SqlDbType.NVarChar, 1000).Value = replacement;
                cmd.Parameters.Add("@httpStatus", SqlDbType.Int).Value = status!.Value;
                using SqlDataReader reader = await cmd.ExecuteReaderAsync();
                if (await reader.ReadAsync())
                {
                    hasherRows = reader.GetInt32(reader.GetOrdinal("HasherRows"));
                    kennelRows = reader.GetInt32(reader.GetOrdinal("KennelRows"));
                }
            }
            catch (Exception ex)
            {
                _log.LogError(ex, "ReportBrokenPhoto: replacement failed for {Url}.", url);
                return CreateJsonResult(StatusCodes.Status500InternalServerError, new { error = "Replacement failed.", verified = true, status });
            }

            _log.LogInformation("ReportBrokenPhoto: {Url} is {Status}; replaced on {HasherRows} hasher row(s), cleared on {KennelRows} kennel row(s).",
                url, status, hasherRows, kennelRows);
            return CreateJsonResult(StatusCodes.Status200OK,
                new { verified = true, status, hasherRows, kennelRows, replacement });
        }

        /// A random bundled avatar, the same draw signup makes (avatar-1..49).
        /// If the missing blob was itself a bundled avatar, that number is
        /// avoided so the replacement cannot be the very file that is gone.
        private static string PickReplacementAvatar(string brokenUrl)
        {
            int avoid = -1;
            string file = brokenUrl.Substring(brokenUrl.LastIndexOf('/') + 1).ToLowerInvariant();
            if (file.StartsWith("avatar-") && file.EndsWith(".jpg")
                && int.TryParse(file.Substring(7, file.Length - 11), out int n))
            {
                avoid = n;
            }
            int pick;
            do { pick = Random.Shared.Next(1, 50); } while (pick == avoid);
            return $"{AvatarBaseUrl}/avatar-{pick}.jpg";
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

        internal class ReportRequest
        {
            [JsonProperty("url")] public string? Url { get; set; }
        }
    }
}
