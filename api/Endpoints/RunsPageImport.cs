using System.Data;
using System.Net;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;
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
    /// Reads each kennel's RUNS PAGE (HC.Kennel.RunsPageUrl, set in the portal's
    /// kennel editor) four times a day and turns its list of upcoming runs into
    /// Harrier Central runs (James, 2026-10-04).
    ///
    /// Per kennel:
    ///   1. fetch the page and reduce it to text (map links kept inline);
    ///   2. fingerprint the text (SHA-256) — if it matches the last import,
    ///      stop: no model call, no cost (most reads end here);
    ///   3. otherwise ask the small Azure OpenAI model (deployment "runs-page",
    ///      gpt-4.1-mini) for the runs as strict JSON;
    ///   4. resolve each map link to coordinates by following its redirects;
    ///   5. hand the runs to HC6.nonApi_importRunsPageRuns, which creates new
    ///      runs and refreshes only what this source owns;
    ///   6. remember the fingerprint (only after a successful import, so a
    ///      failure is retried next time) and a one-line status for the portal.
    ///
    /// Settings: AZURE_OPENAI_ENDPOINT, AZURE_OPENAI_KEY,
    /// AZURE_OPENAI_DEPLOYMENT (default "runs-page"), HcDbConnectionString,
    /// ApiKey (for the manual trigger).
    /// </summary>
    public class RunsPageImport
    {
        private readonly ILogger<RunsPageImport> _log;

        private static readonly HttpClient Http = new(new HttpClientHandler
        {
            AllowAutoRedirect = true,
            AutomaticDecompression = DecompressionMethods.All,
        })
        { Timeout = TimeSpan.FromSeconds(30) };

        private static readonly HttpClient NoRedirect = new(new HttpClientHandler { AllowAutoRedirect = false })
        { Timeout = TimeSpan.FromSeconds(15) };

        private const int MaxPageChars = 40_000;

        public RunsPageImport(ILogger<RunsPageImport> logger) { _log = logger; }

        /// <summary>00:07, 06:07, 12:07 and 18:07 UTC.</summary>
        [Function("RunsPageImport")]
        public async Task Timer([TimerTrigger("0 7 0,6,12,18 * * *")] TimerInfo timer)
        {
            await RunAllAsync(null, force: false);
        }

        /// <summary>
        /// POST /api/RunsPageImportNow {"kennelId": "…", "force": true}
        /// with X-Api-Key — one kennel (or all) now; force ignores the fingerprint.
        /// </summary>
        [Function("RunsPageImportNow")]
        public async Task<IActionResult> Now([HttpTrigger(AuthorizationLevel.Anonymous, "post")] HttpRequest req)
        {
            string? expected = Environment.GetEnvironmentVariable("ApiKey");
            string? provided = req.Headers.TryGetValue("X-Api-Key", out var h) ? h.ToString() : null;
            if (string.IsNullOrEmpty(expected) || provided != expected) return new UnauthorizedResult();

            string body = await new StreamReader(req.Body).ReadToEndAsync();
            JObject args = string.IsNullOrWhiteSpace(body) ? new JObject() : JObject.Parse(body);
            Guid? kennelId = Guid.TryParse(args.Value<string>("kennelId"), out Guid g) ? g : null;
            bool force = args.Value<bool?>("force") ?? false;
            List<object> results = await RunAllAsync(kennelId, force);
            return new OkObjectResult(results);
        }

        private async Task<List<object>> RunAllAsync(Guid? onlyKennel, bool force)
        {
            var results = new List<object>();
            string? cs = Environment.GetEnvironmentVariable("HcDbConnectionString");
            if (string.IsNullOrWhiteSpace(cs)) { _log.LogWarning("RunsPageImport: no HcDbConnectionString"); return results; }

            List<KennelRow> kennels;
            try { kennels = await LoadKennelsAsync(cs, onlyKennel); }
            catch (Exception ex)
            {
                // Before the 2026-10-04 run-once script the columns do not exist.
                _log.LogWarning("RunsPageImport: kennels not read: {Message}", ex.Message);
                return results;
            }

            foreach (KennelRow k in kennels)
            {
                string status;
                try
                {
                    status = await ImportOneAsync(cs, k, force);
                }
                catch (Exception ex)
                {
                    status = $"{Stamp()} — could not read the page: {ex.Message}";
                    _log.LogWarning("RunsPageImport: {Kennel} failed: {Message}", k.ShortName, ex.Message);
                    await LogErrorAsync(cs, k, ex.Message);
                    await SetStateAsync(cs, k.KennelId, null, false, Truncate(status, 500));
                }
                results.Add(new { kennel = k.ShortName, status });
            }
            return results;
        }

        private async Task<string> ImportOneAsync(string cs, KennelRow k, bool force)
        {
            string html = await FetchAsync(k.Url);
            string text = PageToText(html);
            string hash = Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(text))).ToLowerInvariant();

            if (!force && string.Equals(hash, k.Hash, StringComparison.OrdinalIgnoreCase))
            {
                // Unchanged: bookkeeping only (RunsPageCheckedAt never stamps the kennel).
                await SetStateAsync(cs, k.KennelId, null, false, null);
                return "unchanged";
            }

            (JArray runs, int tokens) = await ExtractRunsAsync(k, text);
            await ResolveMapsAsync(runs);

            var forSql = new JArray(runs.Select(r => new JObject
            {
                ["number"] = r["number"],
                ["date"] = r["date"],
                ["time"] = r["time"],
                ["title"] = r["title"],
                ["hares"] = r["hares"],
                ["start"] = r["start"],
                ["lat"] = r["lat"],
                ["lon"] = r["lon"],
                ["mapUrl"] = r["mapUrl"],
                ["description"] = Description(r),
                ["special"] = (r.Value<bool?>("special") ?? false) ? 1 : 0,
            }));
            string json = new JObject { ["runs"] = forSql }.ToString(Formatting.None);

            (int inserted, int updated, int unchanged, int already, int rejected) = await ImportAsync(cs, k.KennelId, json);
            string status = $"{Stamp()} — {runs.Count} run{(runs.Count == 1 ? "" : "s")} on the page: "
                + $"{inserted} new, {updated} updated, {unchanged} unchanged"
                + (already > 0 ? $", {already} already in Harrier Central" : "")
                + (rejected > 0 ? $", {rejected} unreadable" : "")
                + $" ({tokens:N0} model tokens)";
            await SetStateAsync(cs, k.KennelId, hash, true, Truncate(status, 500));
            _log.LogInformation("RunsPageImport: {Kennel}: {Status}", k.ShortName, status);
            return status;
        }

        // ── Page → text ─────────────────────────────────────────────────────

        private static async Task<string> FetchAsync(string url)
        {
            using var req = new HttpRequestMessage(HttpMethod.Get, url);
            req.Headers.UserAgent.ParseAdd("Mozilla/5.0 (compatible; HarrierCentral/1.0; +https://www.harriercentral.com)");
            using HttpResponseMessage res = await Http.SendAsync(req);
            res.EnsureSuccessStatusCode();
            string html = await res.Content.ReadAsStringAsync();
            if (html.Length > 3_000_000) html = html[..3_000_000];
            return html;
        }

        private static readonly Regex MapHost = new(
            @"(maps\.app\.goo\.gl|goo\.gl/maps|google\.[a-z.]+/maps|maps\.google\.|what3words\.com|w3w\.co|openstreetmap\.org|maps\.apple\.com|bing\.com/maps)",
            RegexOptions.IgnoreCase | RegexOptions.Compiled);

        /// <summary>
        /// The page as plain text: scripts, styles and markup gone, block
        /// elements on their own lines, and map links kept inline as
        /// "label [url]" so the model can tie each to its run.
        /// </summary>
        public static string PageToText(string html)
        {
            string s = Regex.Replace(html, @"<(script|style|noscript|svg|head|iframe)\b.*?</\1\s*>", " ", RegexOptions.Singleline | RegexOptions.IgnoreCase);
            s = Regex.Replace(s, @"<!--.*?-->", " ", RegexOptions.Singleline);
            s = Regex.Replace(s, @"<a\b[^>]*href\s*=\s*[""']([^""']+)[""'][^>]*>(.*?)</a>", m =>
            {
                string href = m.Groups[1].Value;
                string label = Regex.Replace(m.Groups[2].Value, "<[^>]+>", " ");
                return MapHost.IsMatch(href) ? $"{label} [{WebUtility.HtmlDecode(href)}]" : label;
            }, RegexOptions.Singleline | RegexOptions.IgnoreCase);
            s = Regex.Replace(s, @"<(br|/p|/div|/li|/tr|/h[1-6]|/td|/th|/section|/article)\b[^>]*>", "\n", RegexOptions.IgnoreCase);
            s = Regex.Replace(s, "<[^>]+>", " ");
            s = WebUtility.HtmlDecode(s);
            s = Regex.Replace(s, @"[ \t ]+", " ");
            s = Regex.Replace(s, @"\s*\n\s*", "\n");
            s = s.Trim();
            return s.Length > MaxPageChars ? s[..MaxPageChars] : s;
        }

        // ── The model ───────────────────────────────────────────────────────

        private const string SystemPrompt =
            "You read a hash running club's web page and list the runs on it as JSON. "
            + "Only include runs the page actually lists with a run number. Rules:\n"
            + "- date: ISO yyyy-mm-dd. Pages often omit the year: choose the year that puts the date nearest the club's "
            + "local today (given), preferring upcoming dates; runs on such pages are almost always within a few months of today.\n"
            + "- time: 24-hour HH:mm, or null if the page does not give one.\n"
            + "- title: a short theme or note only (e.g. 'Joint run', 'Christmas run', 'Summer run - Yippee Bush'); null for an ordinary run. Never the location.\n"
            + "- hares: as written; null if none.\n"
            + "- start: the start location as written; null if blank or 'TBC'.\n"
            + "- mapUrl: the [url] given next to that run's map link; null if none. If a run's start is blank but it has a map link "
            + "identical to another run's, it is a leftover copy: use null.\n"
            + "- onOn: where the pack goes afterwards (On On / On Inn / pub); null if none.\n"
            + "- notes: anything else about that run worth keeping (a different weekday, a special arrangement); null if nothing.\n"
            + "- special: true for a joint run, AGM, Christmas or other holiday run, birthday or anniversary run, themed or "
            + "fancy-dress run, away weekend, camping weekend, milestone run number (e.g. 3100); otherwise false. "
            + "A regular seasonal series (e.g. every summer run, 'Yippee Bush') is not special by itself.\n"
            + "Ignore headers, banners and sidebars that disagree with the run list itself (they are often stale), "
            + "and links to other clubs.";

        private static readonly JObject Schema = JObject.Parse(@"{
          ""type"": ""object"", ""additionalProperties"": false, ""required"": [""runs""],
          ""properties"": { ""runs"": { ""type"": ""array"", ""items"": {
            ""type"": ""object"", ""additionalProperties"": false,
            ""required"": [""number"",""date"",""time"",""title"",""hares"",""start"",""mapUrl"",""onOn"",""notes"",""special""],
            ""properties"": {
              ""number"": { ""type"": [""integer"",""null""] },
              ""date"":   { ""type"": [""string"",""null""] },
              ""time"":   { ""type"": [""string"",""null""] },
              ""title"":  { ""type"": [""string"",""null""] },
              ""hares"":  { ""type"": [""string"",""null""] },
              ""start"":  { ""type"": [""string"",""null""] },
              ""mapUrl"": { ""type"": [""string"",""null""] },
              ""onOn"":   { ""type"": [""string"",""null""] },
              ""notes"":  { ""type"": [""string"",""null""] },
              ""special"":{ ""type"": ""boolean"" } } } } } }");

        private async Task<(JArray runs, int tokens)> ExtractRunsAsync(KennelRow k, string text)
        {
            string endpoint = (Environment.GetEnvironmentVariable("AZURE_OPENAI_ENDPOINT") ?? "").TrimEnd('/');
            string key = Environment.GetEnvironmentVariable("AZURE_OPENAI_KEY") ?? "";
            string deployment = Environment.GetEnvironmentVariable("AZURE_OPENAI_DEPLOYMENT") ?? "runs-page";
            if (endpoint.Length == 0 || key.Length == 0) throw new InvalidOperationException("Azure OpenAI is not configured");

            string user = $"Club: {k.Name} ({k.ShortName})\nClub's local today: {k.LocalToday}\n"
                + (k.LatestRunNumber.HasValue ? $"Latest run already known: #{k.LatestRunNumber} on {k.LatestRunDate}\n" : "")
                + (string.IsNullOrEmpty(k.DefaultStart) ? "" : $"Usual start time: {k.DefaultStart}\n")
                + "\nPAGE TEXT:\n" + text;

            var payload = new JObject
            {
                ["messages"] = new JArray(
                    new JObject { ["role"] = "system", ["content"] = SystemPrompt },
                    new JObject { ["role"] = "user", ["content"] = user }),
                ["temperature"] = 0,
                ["max_tokens"] = 4000,
                ["response_format"] = new JObject
                {
                    ["type"] = "json_schema",
                    ["json_schema"] = new JObject { ["name"] = "runs", ["strict"] = true, ["schema"] = Schema },
                },
            };
            using var req = new HttpRequestMessage(HttpMethod.Post,
                $"{endpoint}/openai/deployments/{deployment}/chat/completions?api-version=2024-10-21")
            {
                Content = new StringContent(payload.ToString(Formatting.None), Encoding.UTF8, "application/json"),
            };
            req.Headers.Add("api-key", key);
            using HttpResponseMessage res = await Http.SendAsync(req);
            string body = await res.Content.ReadAsStringAsync();
            if (!res.IsSuccessStatusCode) throw new InvalidOperationException($"model returned {(int)res.StatusCode}: {Truncate(body, 200)}");

            JObject reply = JObject.Parse(body);
            string content = reply.SelectToken("choices[0].message.content")?.ToString() ?? "{}";
            int tokens = reply.SelectToken("usage.total_tokens")?.Value<int>() ?? 0;
            JArray runs = JObject.Parse(content)["runs"] as JArray ?? new JArray();
            return (runs, tokens);
        }

        // ── Map links → coordinates ─────────────────────────────────────────

        private static readonly Regex[] CoordPatterns =
        {
            new(@"!3d(-?\d+\.\d+)!4d(-?\d+\.\d+)"),
            new(@"@(-?\d+\.\d+),(-?\d+\.\d+)"),
            new(@"/search/(-?\d+\.\d+),\+?(-?\d+\.\d+)"),
            new(@"[?&](?:q|query|ll|daddr|destination)=(-?\d+\.\d+)(?:,|%2C)\+?(-?\d+\.\d+)", RegexOptions.IgnoreCase),
        };

        private static async Task ResolveMapsAsync(JArray runs)
        {
            var cache = new Dictionary<string, (double, double)?>();
            foreach (JObject r in runs.OfType<JObject>())
            {
                string? url = r.Value<string>("mapUrl");
                if (string.IsNullOrWhiteSpace(url)) continue;
                if (!cache.TryGetValue(url, out var ll))
                {
                    ll = await ResolveOneAsync(url);
                    cache[url] = ll;
                }
                if (ll is (double lat, double lon)) { r["lat"] = lat; r["lon"] = lon; }
            }
        }

        public static (double, double)? CoordsFromUrl(string url)
        {
            string u = Uri.UnescapeDataString(url);
            foreach (Regex p in CoordPatterns)
            {
                Match m = p.Match(u);
                if (m.Success
                    && double.TryParse(m.Groups[1].Value, System.Globalization.NumberStyles.Float, System.Globalization.CultureInfo.InvariantCulture, out double la)
                    && double.TryParse(m.Groups[2].Value, System.Globalization.NumberStyles.Float, System.Globalization.CultureInfo.InvariantCulture, out double lo)
                    && Math.Abs(la) <= 90 && Math.Abs(lo) <= 180 && !(la == 0 && lo == 0))
                    return (la, lo);
            }
            return null;
        }

        /// <summary>Follows a (short) map link's redirects until a URL carries coordinates.</summary>
        private static async Task<(double, double)?> ResolveOneAsync(string url)
        {
            string current = url;
            for (int hop = 0; hop < 6; hop++)
            {
                if (CoordsFromUrl(current) is (double, double) found) return found;
                if (!Uri.TryCreate(current, UriKind.Absolute, out Uri? uri)) return null;
                try
                {
                    using var req = new HttpRequestMessage(HttpMethod.Get, uri);
                    req.Headers.UserAgent.ParseAdd("Mozilla/5.0");
                    using HttpResponseMessage res = await NoRedirect.SendAsync(req);
                    Uri? next = res.Headers.Location;
                    if (next == null) return null;
                    current = next.IsAbsoluteUri ? next.ToString() : new Uri(uri, next).ToString();
                }
                catch { return null; }
            }
            return CoordsFromUrl(current);
        }

        private static string? Description(JToken r)
        {
            var parts = new List<string>();
            string? notes = r.Value<string>("notes");
            string? onOn = r.Value<string>("onOn");
            if (!string.IsNullOrWhiteSpace(notes)) parts.Add(notes.Trim());
            if (!string.IsNullOrWhiteSpace(onOn)) parts.Add($"On On: {onOn.Trim()}");
            return parts.Count == 0 ? null : string.Join("\n", parts);
        }

        // ── SQL ─────────────────────────────────────────────────────────────

        private sealed record KennelRow(Guid KennelId, string Name, string ShortName, string Url, string? Hash,
            string LocalToday, int? LatestRunNumber, string? LatestRunDate, string? DefaultStart);

        private static async Task<List<KennelRow>> LoadKennelsAsync(string cs, Guid? onlyKennel)
        {
            var list = new List<KennelRow>();
            using var conn = new SqlConnection(cs);
            await conn.OpenAsync();
            using var cmd = new SqlCommand("[HC6].[nonApi_getRunsPageKennels]", conn) { CommandType = CommandType.StoredProcedure, CommandTimeout = 30 };
            cmd.Parameters.Add("@kennelId", SqlDbType.UniqueIdentifier).Value = (object?)onlyKennel ?? DBNull.Value;
            using SqlDataReader r = await cmd.ExecuteReaderAsync();
            while (await r.ReadAsync())
            {
                string? S(string c) => r[c] is DBNull ? null : r[c].ToString();
                list.Add(new KennelRow(
                    Guid.Parse(S("KennelId")!), S("KennelName") ?? "", S("KennelShortName") ?? "", S("RunsPageUrl")!,
                    S("RunsPageHash")?.Trim(), S("LocalToday") ?? DateTime.UtcNow.ToString("yyyy-MM-dd"),
                    r["LatestRunNumber"] is DBNull ? null : Convert.ToInt32(r["LatestRunNumber"]),
                    S("LatestRunDate"), S("DefaultStartTime")));
            }
            return list;
        }

        private static async Task<(int, int, int, int, int)> ImportAsync(string cs, Guid kennelId, string json)
        {
            using var conn = new SqlConnection(cs);
            await conn.OpenAsync();
            using var cmd = new SqlCommand("[HC6].[nonApi_importRunsPageRuns]", conn) { CommandType = CommandType.StoredProcedure, CommandTimeout = 120 };
            cmd.Parameters.Add("@kennelId", SqlDbType.UniqueIdentifier).Value = kennelId;
            cmd.Parameters.Add("@runsJson", SqlDbType.NVarChar, -1).Value = json;
            using SqlDataReader r = await cmd.ExecuteReaderAsync();
            if (!await r.ReadAsync()) return (0, 0, 0, 0, 0);
            return (r.GetInt32(0), r.GetInt32(1), r.GetInt32(2), r.GetInt32(3), r.GetInt32(4));
        }

        private static async Task SetStateAsync(string cs, Guid kennelId, string? hash, bool changed, string? status)
        {
            try
            {
                using var conn = new SqlConnection(cs);
                await conn.OpenAsync();
                using var cmd = new SqlCommand("[HC6].[nonApi_setRunsPageState]", conn) { CommandType = CommandType.StoredProcedure, CommandTimeout = 15 };
                cmd.Parameters.Add("@kennelId", SqlDbType.UniqueIdentifier).Value = kennelId;
                cmd.Parameters.Add("@hash", SqlDbType.Char, 64).Value = (object?)hash ?? DBNull.Value;
                cmd.Parameters.Add("@changed", SqlDbType.SmallInt).Value = changed ? 1 : 0;
                cmd.Parameters.Add("@status", SqlDbType.NVarChar, -1).Value = (object?)status ?? DBNull.Value;
                await cmd.ExecuteNonQueryAsync();
            }
            catch { /* bookkeeping must never fail an import */ }
        }

        private static async Task LogErrorAsync(string cs, KennelRow k, string message)
        {
            try
            {
                using var conn = new SqlConnection(cs);
                await conn.OpenAsync();
                using var cmd = new SqlCommand(
                    "INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId) " +
                    "VALUES (NEWID(), '<api>', 'Runs page import failed', @d, 'RunsPageImport', NULL);", conn);
                cmd.Parameters.Add("@d", SqlDbType.NVarChar, -1).Value = $"{k.ShortName} ({k.KennelId}) {k.Url}: {message}";
                await cmd.ExecuteNonQueryAsync();
            }
            catch { /* best effort */ }
        }

        private static string Stamp() => DateTime.UtcNow.ToString("yyyy-MM-dd HH:mm") + " UTC";

        private static string Truncate(string s, int n) => s.Length <= n ? s : s[..n];
    }
}
