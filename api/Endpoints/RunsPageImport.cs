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
    /// kennel editor) every 15 minutes on a run day and every ~6 hours
    /// otherwise (nonApi_getRunsPageKennels decides who is due) and turns its list of upcoming runs into
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

        // gpt-4.1-mini Global Standard list price, USD per million tokens
        // (2026-10). Overridable without a deploy by AZURE_OPENAI_USD_PER_M_IN
        // / _OUT, so LOG.AiUsage stays right if the price or model changes.
        private const decimal DefaultUsdPerMIn = 0.40m;
        private const decimal DefaultUsdPerMOut = 1.60m;

        // One timer run or one portal Test: LOG.AiUsage.SessionId groups its
        // model calls. Function classes are created per invocation, so an
        // instance field is per run.
        private Guid _sessionId = Guid.NewGuid();
        private string _feature = "runsPage";

        // This run's totals for its HC.IntegrationJob row (the monitor's
        // Runs page tile).
        private int _found, _inserted, _updated;

        public RunsPageImport(ILogger<RunsPageImport> logger) { _log = logger; }

        /// <summary>
        /// A failure tagged with the stage it happened in, so HC.ErrorLog says
        /// WHERE: "Runs page fetch failed" (the kennel's site), "… model failed"
        /// (Azure OpenAI), "… DB failed" (the import SP — which also logs its
        /// own SQL error), "… config failed" (settings) (James, 2026-10-04:
        /// "flag errors whether they happen in the API in the DB or in the AI
        /// model"). The daily log triage reports each new kind.
        /// </summary>
        private sealed class StageException : Exception
        {
            public string Stage { get; }
            public StageException(string stage, string message, Exception? inner = null) : base(message, inner) { Stage = stage; }
        }

        private static StageException Stage(string stage, Exception ex) =>
            ex as StageException ?? new StageException(stage, ex.Message, ex);

        /// <summary>Every 15 minutes (:07, :22, :37, :52); the SP picks the kennels that are due.</summary>
        [Function("RunsPageImport")]
        public async Task Timer([TimerTrigger("0 7/15 * * * *")] TimerInfo timer)
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
            _sessionId = Guid.NewGuid();
            _feature = "runsPage";
            var results = new List<object>();
            string? cs = Environment.GetEnvironmentVariable("HcDbConnectionString");
            if (string.IsNullOrWhiteSpace(cs)) { _log.LogWarning("RunsPageImport: no HcDbConnectionString"); return results; }

            List<KennelRow> kennels;
            try { kennels = await LoadKennelsAsync(cs, onlyKennel); }
            catch (Exception ex)
            {
                _log.LogWarning("RunsPageImport: kennels not read: {Message}", ex.Message);
                await LogErrorAsync(cs, null, "DB", "the list of kennels could not be read: " + ex.Message);
                return results;
            }

            DateTimeOffset started = DateTimeOffset.UtcNow;
            var nice = new List<string>();
            var naughty = new List<string>();
            var errors = new List<string>();
            int unchangedN = 0, importedN = 0, failedN = 0;
            foreach (KennelRow k in kennels)
            {
                string status;
                try
                {
                    status = await ImportOneAsync(cs, k, force);
                    if (status == "unchanged") unchangedN++; else importedN++;
                    nice.Add(k.ShortName);
                }
                catch (Exception ex)
                {
                    failedN++;
                    StageException se = Stage("import", ex);
                    naughty.Add(k.ShortName);
                    errors.Add($"{k.ShortName}: {se.Stage}: {Truncate(se.Message, 200)}");
                    status = $"{Stamp()} — {StageWords(se.Stage)}: {se.Message}";
                    _log.LogWarning("RunsPageImport: {Kennel} {Stage} failed: {Message}", k.ShortName, se.Stage, se.Message);
                    await LogErrorAsync(cs, k, se.Stage, se.Message);
                    await SetStateAsync(cs, k.KennelId, null, false, Truncate(status, 500));
                }
                results.Add(new { kennel = k.ShortName, status });
            }
            if (kennels.Count > 0)
                await RecordJobAsync(cs, started, nice, naughty, errors);
            if (importedN + failedN > 0)
                await LogGeneralAsync(cs, "runsPageRun",
                    $"runs page timer: {kennels.Count} kennel(s) — {unchangedN} unchanged, {importedN} read by the model, {failedN} failed",
                    null, string.Join(", ", results.Select(r => r.ToString())));
            return results;
        }

        private async Task<string> ImportOneAsync(string cs, KennelRow k, bool force)
        {
            (string text, string hash) = await ReadPageAsync(k.Url);
            if (text.Length < 20) throw new StageException("fetch", "the page has no readable text (it may need JavaScript, or be behind a login)");
            if (!force && string.Equals(hash, k.Hash, StringComparison.OrdinalIgnoreCase))
            {
                // Unchanged: bookkeeping only (RunsPageCheckedAt never stamps the kennel).
                await SetStateAsync(cs, k.KennelId, null, false, null);
                return "unchanged";
            }

            (JArray runs, int tokens) = await ExtractAndResolveAsync(cs, k, text);
            ImportResult res = await ImportAsync(cs, k.KennelId, ToSqlJson(runs), dryRun: false);
            _found += runs.Count; _inserted += res.Inserted; _updated += res.Updated;
            await FlagSuspectAsync(cs, k, text, runs, res);
            string status = StatusLine(runs.Count, res, tokens);
            await SetStateAsync(cs, k.KennelId, hash, true, Truncate(status, 500));
            _log.LogInformation("RunsPageImport: {Kennel}: {Status}", k.ShortName, status);
            return status;
        }

        private static async Task<(string text, string hash)> ReadPageAsync(string url)
        {
            string html;
            try { html = await FetchAsync(url); }
            catch (Exception ex) { throw Stage("fetch", ex is TaskCanceledException ? new StageException("fetch", "the site did not answer within 30 seconds") : ex); }
            string text = PageToText(html);
            string hash = Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(text))).ToLowerInvariant();
            return (text, hash);
        }

        private async Task<(JArray runs, int tokens)> ExtractAndResolveAsync(string cs, KennelRow k, string text)
        {
            (JArray runs, int tokens) = await ExtractRunsAsync(cs, k, text);
            FixYears(runs, k.LocalToday);
            await ResolveMapsAsync(runs);
            await GeocodeAsync(cs, k, runs);
            return (runs, tokens);
        }

        private static string ToSqlJson(JArray runs)
        {
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
            return new JObject { ["runs"] = forSql }.ToString(Formatting.None);
        }

        private static string StageWords(string stage) => stage switch
        {
            "fetch" => "could not read the page",
            "model" => "the reader (AI model) failed",
            "DB" => "the runs could not be saved",
            "config" => "the reader is not configured",
            _ => "the import failed",
        };

        private static string StatusLine(int found, ImportResult r, int tokens) =>
            $"{Stamp()} — {found} run{(found == 1 ? "" : "s")} on the page: "
            + $"{r.Inserted} new, {r.Updated} updated, {r.Unchanged} unchanged"
            + (r.AlreadyInHc > 0 ? $", {r.AlreadyInHc} already in Harrier Central" : "")
            + (r.Rejected > 0 ? $", {r.Rejected} unreadable" : "")
            + (r.Skipped > 0 ? $", {r.Skipped} skipped (no location or description yet)" : "")
            + $" ({tokens:N0} model tokens)";

        // ── The portal's Test button ────────────────────────────────────────

        private static readonly System.Collections.Concurrent.ConcurrentDictionary<Guid, DateTime> _lastTest = new();

        /// <summary>
        /// POST /api/RunsPageTest — the portal kennel editor's Test button
        /// (2026-10-04). Body: { deviceId, accessToken, publicKennelId, url,
        /// import }. Reads the page now (the address typed in the editor,
        /// saved or not), asks the model, and answers with every run found and
        /// what importing would do to it. Writes NOTHING unless import = true.
        /// Auth: the portal's token, bound to the kennel (ValidatePortalAuth,
        /// proc 'hcportal_runsPageTest'), and createEditRuns on that kennel.
        /// </summary>
        [Function("RunsPageTest")]
        public async Task<IActionResult> Test([HttpTrigger(AuthorizationLevel.Anonymous, "post")] HttpRequest req)
        {
            string? cs = Environment.GetEnvironmentVariable("HcDbConnectionString");
            if (string.IsNullOrWhiteSpace(cs)) return new StatusCodeResult(500);
            JObject args;
            try { args = JObject.Parse(await new StreamReader(req.Body).ReadToEndAsync()); }
            catch { return Fail("The request could not be read.", 400); }

            string deviceId = args.Value<string>("deviceId") ?? "";
            string accessToken = args.Value<string>("accessToken") ?? "";
            string publicKennelId = (args.Value<string>("publicKennelId") ?? "").ToLowerInvariant();
            string url = (args.Value<string>("url") ?? "").Trim();
            bool doImport = args.Value<bool?>("import") ?? false;
            _sessionId = Guid.NewGuid();
            _feature = "runsPageTest";
            if (!Guid.TryParse(deviceId, out Guid dev) || !Guid.TryParse(publicKennelId, out Guid pk) || accessToken.Length == 0)
                return Fail("The request is missing its sign-in.", 400);

            Guid? hasherId = await ValidatePortalAsync(cs, dev, accessToken, publicKennelId);
            if (hasherId == null) return Fail("Your sign-in has expired. Please sign in again.", 403);
            (Guid? kennelId, bool allowed) = await CanTestAsync(cs, hasherId.Value, pk);
            if (kennelId == null || !allowed)
                return Fail("Only someone who can edit this kennel's runs can test its runs page.", 403);

            if (_lastTest.TryGetValue(kennelId.Value, out DateTime last) && DateTime.UtcNow - last < TimeSpan.FromSeconds(10))
                return Fail("Please wait a few seconds between tests.", 429);
            _lastTest[kennelId.Value] = DateTime.UtcNow;

            List<KennelRow> rows = await LoadKennelsAsync(cs, kennelId);
            if (rows.Count == 0) return Fail("That kennel could not be found.", 404);
            KennelRow k = rows[0];
            if (url.Length == 0) url = k.Url ?? "";
            if (!(url.StartsWith("https://", StringComparison.OrdinalIgnoreCase) || url.StartsWith("http://", StringComparison.OrdinalIgnoreCase)) || url.Length > 500)
                return Fail("Enter the page's full address, starting with https://", 400);

            try
            {
                (string text, string hash) = await ReadPageAsync(url);
                if (text.Length < 20) throw new StageException("fetch", "the page has no readable text (it may need JavaScript, or be behind a login)");
                (JArray runs, int tokens) = await ExtractAndResolveAsync(cs, k with { Url = url }, text);
                DateTimeOffset started = DateTimeOffset.UtcNow;
                ImportResult res = await ImportAsync(cs, k.KennelId, ToSqlJson(runs), dryRun: !doImport);
                await FlagSuspectAsync(cs, k with { Url = url }, text, runs, res);
                if (doImport)
                {
                    _found = runs.Count; _inserted = res.Inserted; _updated = res.Updated;
                    await RecordJobAsync(cs, started, new List<string> { k.ShortName + " (Test)" }, new List<string>(), new List<string>());
                }
                string status = StatusLine(runs.Count, res, tokens);
                if (doImport)
                {
                    // Imported from the address on screen: remember its fingerprint
                    // only if it is the saved address (else the timer reads it anew).
                    bool saved = string.Equals(url, k.Url, StringComparison.OrdinalIgnoreCase);
                    await SetStateAsync(cs, k.KennelId, saved ? hash : null, true, Truncate(status, 500));
                }
                foreach (JObject r in runs.OfType<JObject>())
                {
                    int? n = r.Value<int?>("number");
                    r["outcome"] = n.HasValue && res.Outcomes.TryGetValue(n.Value, out string? o) ? o : "unreadable";
                }
                var reply = new JObject
                {
                    ["success"] = true,
                    ["imported"] = doImport,
                    ["url"] = url,
                    ["textChars"] = text.Length,
                    ["tokens"] = tokens,
                    ["status"] = status,
                    ["counts"] = new JObject
                    {
                        ["inserted"] = res.Inserted, ["updated"] = res.Updated, ["unchanged"] = res.Unchanged,
                        ["alreadyInHc"] = res.AlreadyInHc, ["rejected"] = res.Rejected, ["skipped"] = res.Skipped,
                    },
                    ["runs"] = runs,
                };
                return new ContentResult { Content = reply.ToString(Formatting.None), ContentType = "application/json", StatusCode = 200 };
            }
            catch (Exception ex)
            {
                StageException se = Stage("import", ex);
                _log.LogWarning("RunsPageTest: {Kennel} {Stage} failed: {Message}", k.ShortName, se.Stage, se.Message);
                await LogErrorAsync(cs, k with { Url = url }, se.Stage, se.Message);
                return Fail($"Test failed — {StageWords(se.Stage)}: {se.Message}", 200);
            }
        }

        private static IActionResult Fail(string message, int status) =>
            new ObjectResult(new { success = false, errorUserMessage = message }) { StatusCode = status };

        private static async Task<Guid?> ValidatePortalAsync(string cs, Guid deviceId, string accessToken, string publicKennelId)
        {
            using var conn = new SqlConnection(cs);
            await conn.OpenAsync();
            using var cmd = new SqlCommand("[HC6].[ValidatePortalAuth]", conn) { CommandType = CommandType.StoredProcedure, CommandTimeout = 15 };
            cmd.Parameters.AddWithValue("@deviceId", deviceId);
            cmd.Parameters.AddWithValue("@accessToken", accessToken);
            cmd.Parameters.AddWithValue("@callerProcName", "hcportal_runsPageTest");
            cmd.Parameters.AddWithValue("@callerParamString", publicKennelId);
            var err = new SqlParameter("@errorMessage", SqlDbType.NVarChar, 255) { Direction = ParameterDirection.Output };
            var hasher = new SqlParameter("@hasherId", SqlDbType.UniqueIdentifier) { Direction = ParameterDirection.Output };
            var callerType = new SqlParameter("@callerType", SqlDbType.Int) { Direction = ParameterDirection.Output };
            cmd.Parameters.Add(err); cmd.Parameters.Add(hasher); cmd.Parameters.Add(callerType);
            await cmd.ExecuteNonQueryAsync();
            if (err.Value is not DBNull && err.Value != null) return null;
            return hasher.Value is Guid g ? g : null;
        }

        private static async Task<(Guid?, bool)> CanTestAsync(string cs, Guid hasherId, Guid publicKennelId)
        {
            using var conn = new SqlConnection(cs);
            await conn.OpenAsync();
            using var cmd = new SqlCommand("[HC6].[nonApi_canTestRunsPage]", conn) { CommandType = CommandType.StoredProcedure, CommandTimeout = 15 };
            cmd.Parameters.Add("@hasherId", SqlDbType.UniqueIdentifier).Value = hasherId;
            cmd.Parameters.Add("@publicKennelId", SqlDbType.UniqueIdentifier).Value = publicKennelId;
            using SqlDataReader r = await cmd.ExecuteReaderAsync();
            if (!await r.ReadAsync()) return (null, false);
            Guid? kennel = r["KennelId"] is DBNull ? null : Guid.Parse(r["KennelId"].ToString()!);
            return (kennel, Convert.ToInt32(r["Allowed"]) == 1);
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
            + "- hares: as written; null if none, and null when the page only says a hare is needed or wanted, TBA or TBC.\n"
            + "- start: the start location as written; null if blank or 'TBC'.\n"
            + "- mapUrl: the [url] given next to that run's map link; null if none. If a run's start is blank but it has a map link "
            + "identical to another run's, it is a leftover copy: use null.\n"
            + "- geoQuery: the start written as a full search address for a map lookup: venue name, street and postcode if given, "
            + "or the station name with 'station', then the suburb/town and the club's city and country (given) when the page "
            + "leaves them out. Never invent a street or postcode. null when the start is unknown, TBA or TBC.\n"
            + "- onOn: where the pack goes afterwards (On On / On Inn / pub); null if none.\n"
            + "- notes: anything else about that run worth keeping (a different weekday, an earlier start, a special arrangement); "
            + "null if nothing. Never placeholders such as 'hare needed', 'TBA', 'details to be announced' or 'location TBA', "
            + "and never the usual start time (e.g. '12 Noon for 12:30 start') — that goes in time.\n"
            + "- special: true for a joint run, AGM, Christmas or other holiday run, birthday or anniversary run, themed or "
            + "fancy-dress run, away weekend, camping weekend, milestone run number (e.g. 3100); otherwise false. "
            + "A regular seasonal series (e.g. every summer run, 'Yippee Bush') is not special by itself.\n"
            + "Ignore headers, banners and sidebars that disagree with the run list itself (they are often stale), "
            + "and links to other clubs.";

        private static readonly JObject Schema = JObject.Parse(@"{
          ""type"": ""object"", ""additionalProperties"": false, ""required"": [""runs""],
          ""properties"": { ""runs"": { ""type"": ""array"", ""items"": {
            ""type"": ""object"", ""additionalProperties"": false,
            ""required"": [""number"",""date"",""time"",""title"",""hares"",""start"",""geoQuery"",""mapUrl"",""onOn"",""notes"",""special""],
            ""properties"": {
              ""number"": { ""type"": [""integer"",""null""] },
              ""date"":   { ""type"": [""string"",""null""] },
              ""time"":   { ""type"": [""string"",""null""] },
              ""title"":  { ""type"": [""string"",""null""] },
              ""hares"":  { ""type"": [""string"",""null""] },
              ""start"":  { ""type"": [""string"",""null""] },
              ""geoQuery"": { ""type"": [""string"",""null""] },
              ""mapUrl"": { ""type"": [""string"",""null""] },
              ""onOn"":   { ""type"": [""string"",""null""] },
              ""notes"":  { ""type"": [""string"",""null""] },
              ""special"":{ ""type"": ""boolean"" } } } } } }");

        private async Task<(JArray runs, int tokens)> ExtractRunsAsync(string cs, KennelRow k, string text)
        {
            string endpoint = (Environment.GetEnvironmentVariable("AZURE_OPENAI_ENDPOINT") ?? "").TrimEnd('/');
            string key = Environment.GetEnvironmentVariable("AZURE_OPENAI_KEY") ?? "";
            string deployment = Environment.GetEnvironmentVariable("AZURE_OPENAI_DEPLOYMENT") ?? "runs-page";
            if (endpoint.Length == 0 || key.Length == 0)
                throw new StageException("config", "AZURE_OPENAI_ENDPOINT / AZURE_OPENAI_KEY are not set on the Function App");

            string user = $"Club: {k.Name} ({k.ShortName})\nClub's local today: {k.LocalToday}\n"
                + (string.IsNullOrEmpty(k.City) ? "" : $"Club's city: {k.City}{(string.IsNullOrEmpty(k.Country) ? "" : ", " + k.Country)}\n")
                // Only a RECENT latest run helps: an old one (STH3's last HC
                // run was April 2024) pulled the model to the wrong year for a
                // page that omits years, and every run was rejected (2026-10-05).
                + (k.LatestRunNumber.HasValue && IsRecent(k.LatestRunDate, k.LocalToday)
                    ? $"Latest run already known: #{k.LatestRunNumber} on {k.LatestRunDate}\n" : "")
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

            var clock = System.Diagnostics.Stopwatch.StartNew();
            string body = "";
            int statusCode = 0, attempts = 0;
            // One retry when the model is busy (429) or hiccups (5xx).
            while (attempts < 2)
            {
                attempts++;
                using var req = new HttpRequestMessage(HttpMethod.Post,
                    $"{endpoint}/openai/deployments/{deployment}/chat/completions?api-version=2024-10-21")
                {
                    Content = new StringContent(payload.ToString(Formatting.None), Encoding.UTF8, "application/json"),
                };
                req.Headers.Add("api-key", key);
                try
                {
                    using HttpResponseMessage res = await Http.SendAsync(req);
                    statusCode = (int)res.StatusCode;
                    body = await res.Content.ReadAsStringAsync();
                    if (res.IsSuccessStatusCode) break;
                    if (attempts < 2 && (statusCode == 429 || statusCode >= 500))
                    {
                        int wait = res.Headers.RetryAfter?.Delta is TimeSpan ra ? (int)Math.Min(ra.TotalMilliseconds, 20_000) : 5_000;
                        await Task.Delay(wait);
                        continue;
                    }
                    await RecordAiUsageAsync(cs, k, deployment, $"http_{statusCode}", 0, 0, clock.ElapsedMilliseconds, $"attempts={attempts}");
                    throw new StageException("model", $"Azure OpenAI returned {statusCode}: {Truncate(body, 300)}");
                }
                catch (TaskCanceledException)
                {
                    if (attempts < 2) continue;
                    await RecordAiUsageAsync(cs, k, deployment, "timeout", 0, 0, clock.ElapsedMilliseconds, $"attempts={attempts}");
                    throw new StageException("model", "Azure OpenAI did not answer within 30 seconds");
                }
                catch (HttpRequestException ex)
                {
                    if (attempts < 2) { await Task.Delay(3_000); continue; }
                    await RecordAiUsageAsync(cs, k, deployment, "unreachable", 0, 0, clock.ElapsedMilliseconds, Truncate(ex.Message, 200));
                    throw new StageException("model", "Azure OpenAI could not be reached: " + ex.Message, ex);
                }
            }

            JObject reply;
            try { reply = JObject.Parse(body); }
            catch (Exception ex)
            {
                await RecordAiUsageAsync(cs, k, deployment, "bad_json", 0, 0, clock.ElapsedMilliseconds, Truncate(body, 200));
                throw new StageException("model", "the model's reply was not JSON: " + Truncate(body, 200), ex);
            }
            string finish = reply.SelectToken("choices[0].finish_reason")?.ToString() ?? "";
            int promptTokens = reply.SelectToken("usage.prompt_tokens")?.Value<int>() ?? 0;
            int outTokens = reply.SelectToken("usage.completion_tokens")?.Value<int>() ?? 0;
            string? refusal = reply.SelectToken("choices[0].message.refusal")?.ToString();
            string content = reply.SelectToken("choices[0].message.content")?.ToString() ?? "";

            JArray runs = new();
            string? problem = null;
            string outcome = "ok";
            if (finish == "length") { outcome = "length"; problem = "the model's answer was cut off (too many runs on one page?)"; }
            else if (finish == "content_filter") { outcome = "content_filter"; problem = "Azure's content filter blocked the page"; }
            else if (!string.IsNullOrEmpty(refusal)) { outcome = "refusal"; problem = "the model refused: " + Truncate(refusal, 200); }
            else
            {
                try { runs = JObject.Parse(content)["runs"] as JArray ?? new JArray(); }
                catch (Exception) { outcome = "bad_json"; problem = "the model's JSON could not be read: " + Truncate(content, 200); }
            }

            // Every model call, for cost: LOG.AiUsage (the monitor's AI Tokens row).
            await RecordAiUsageAsync(cs, k, deployment, outcome, promptTokens, outTokens, clock.ElapsedMilliseconds,
                $"runs={runs.Count} textChars={text.Length} attempts={attempts}" + (problem == null ? "" : " — " + problem));

            if (problem != null) throw new StageException("model", problem);
            return (runs, promptTokens + outTokens);
        }

        /// <summary>
        /// Output that is probably wrong though nothing threw: logged as
        /// "Runs page output suspect" so the triage surfaces it.
        /// </summary>
        private async Task FlagSuspectAsync(string cs, KennelRow k, string text, JArray runs, ImportResult res)
        {
            var why = new List<string>();
            int numberedOnPage = Regex.Matches(text, @"(?:\brun\b\s*(?:no\.?|number)?\s*#?\s*|#)\d{2,5}", RegexOptions.IgnoreCase).Count;
            if (runs.Count == 0 && numberedOnPage >= 2)
                why.Add($"the page shows {numberedOnPage} run numbers but the model found no runs");
            if (res.Rejected >= 2 && res.Rejected * 2 >= runs.Count)
                why.Add($"{res.Rejected} of {runs.Count} runs were unreadable (no number, or an impossible date)");
            int withMaps = runs.Count(r => !string.IsNullOrWhiteSpace(r.Value<string>("mapUrl")));
            int located = runs.Count(r => r["lat"] != null && r["lat"]!.Type != JTokenType.Null);
            if (withMaps >= 2 && located == 0)
                why.Add($"{withMaps} map links but none could be turned into a location");
            if (text.Length >= MaxPageChars)
                why.Add($"the page is longer than {MaxPageChars:N0} characters and was cut short — later runs may be missing");
            if (why.Count == 0) return;
            _log.LogWarning("RunsPageImport: {Kennel} output suspect: {Why}", k.ShortName, string.Join("; ", why));
            await LogErrorAsync(cs, k, "output", string.Join("; ", why));
        }

        // ── Years ───────────────────────────────────────────────────────────

        private static bool IsRecent(string? date, string today) =>
            DateTime.TryParse(date, System.Globalization.CultureInfo.InvariantCulture, System.Globalization.DateTimeStyles.None, out DateTime d)
            && DateTime.TryParse(today, System.Globalization.CultureInfo.InvariantCulture, System.Globalization.DateTimeStyles.None, out DateTime t)
            && (t - d).TotalDays <= 183;

        /// <summary>
        /// A runs page lists upcoming runs and usually leaves the year off;
        /// the model sometimes picks the wrong one (STH3 came back as 2024).
        /// A date more than a year back or 18 months ahead is moved to the
        /// same day and month on or after a month ago, in the club's time.
        /// </summary>
        private static void FixYears(JArray runs, string localToday)
        {
            if (!DateTime.TryParse(localToday, System.Globalization.CultureInfo.InvariantCulture,
                    System.Globalization.DateTimeStyles.None, out DateTime today)) return;
            DateTime from = today.AddDays(-31);
            foreach (JObject r in runs.OfType<JObject>())
            {
                if (!DateTime.TryParseExact(r.Value<string>("date"), "yyyy-MM-dd", System.Globalization.CultureInfo.InvariantCulture,
                        System.Globalization.DateTimeStyles.None, out DateTime d)) continue;
                if (d >= today.AddYears(-1) && d <= today.AddMonths(18)) continue;
                if (d.Month == 2 && d.Day == 29) continue;
                var fixedDate = new DateTime(from.Year, d.Month, d.Day);
                if (fixedDate < from) fixedDate = fixedDate.AddYears(1);
                r["date"] = fixedDate.ToString("yyyy-MM-dd");
            }
        }

        // ── Addresses → coordinates (Azure Maps) ─────────────────────────

        // A geocoded point is kept only when it is precise and near the club:
        // High confidence (an address, station, park), or Medium on a full
        // postcode; and within this distance of the kennel's anchor. A
        // suburb's centre is rejected — no pin beats a wrong pin.
        private const double MaxKmFromAnchor = 60;

        /// <summary>
        /// For each run still without coordinates after its map link, look up
        /// the AI's geoQuery with Azure Maps (account harriercentral-maps,
        /// setting AZURE_MAPS_KEY; free to 5,000 lookups a month). Missing
        /// key = skipped. Never throws: a failed lookup leaves the run unpinned.
        /// </summary>
        private async Task GeocodeAsync(string cs, KennelRow k, JArray runs)
        {
            string key = Environment.GetEnvironmentVariable("AZURE_MAPS_KEY") ?? "";
            if (key.Length == 0) return;
            int tried = 0, placed = 0, failed = 0;
            foreach (JObject r in runs.OfType<JObject>())
            {
                if (r["lat"] != null && r["lat"]!.Type != JTokenType.Null) continue;
                string q = (r.Value<string>("geoQuery") ?? "").Trim();
                if (q.Length < 4) continue;
                tried++;
                try
                {
                    string url = "https://atlas.microsoft.com/geocode?api-version=2023-06-01&top=1"
                        + "&query=" + Uri.EscapeDataString(q)
                        + (k.AnchorLat.HasValue && k.AnchorLon.HasValue
                            ? "&coordinates=" + k.AnchorLon.Value.ToString(System.Globalization.CultureInfo.InvariantCulture)
                              + "," + k.AnchorLat.Value.ToString(System.Globalization.CultureInfo.InvariantCulture)
                            : "")
                        + "&subscription-key=" + Uri.EscapeDataString(key);
                    using var res = await Http.GetAsync(url);
                    if (!res.IsSuccessStatusCode) { failed++; continue; }
                    JObject d = JObject.Parse(await res.Content.ReadAsStringAsync());
                    JToken? f = d["features"]?.FirstOrDefault();
                    if (f == null) continue;
                    string conf = f.SelectToken("properties.confidence")?.ToString() ?? "";
                    string type = f.SelectToken("properties.type")?.ToString() ?? "";
                    bool precise = conf == "High" || (conf == "Medium" && type.StartsWith("Postcode", StringComparison.OrdinalIgnoreCase));
                    if (!precise) continue;
                    double lon = f.SelectToken("geometry.coordinates[0]")!.Value<double>();
                    double lat = f.SelectToken("geometry.coordinates[1]")!.Value<double>();
                    if (k.AnchorLat.HasValue && k.AnchorLon.HasValue
                        && DistanceKm(k.AnchorLat.Value, k.AnchorLon.Value, lat, lon) > MaxKmFromAnchor) continue;
                    r["lat"] = Math.Round(lat, 6);
                    r["lon"] = Math.Round(lon, 6);
                    placed++;
                }
                catch { failed++; }
            }
            if (tried > 0)
                _log.LogInformation("RunsPageImport: {Kennel} geocoded {Placed}/{Tried} ({Failed} failed)", k.ShortName, placed, tried, failed);
            if (failed > 0 && failed * 2 >= tried)
                await LogErrorAsync(cs, k, "geocode", $"{failed} of {tried} Azure Maps lookups failed");
        }

        private static double DistanceKm(double lat1, double lon1, double lat2, double lon2)
        {
            double r = Math.PI / 180, dLat = (lat2 - lat1) * r, dLon = (lon2 - lon1) * r;
            double a = Math.Sin(dLat / 2) * Math.Sin(dLat / 2)
                + Math.Cos(lat1 * r) * Math.Cos(lat2 * r) * Math.Sin(dLon / 2) * Math.Sin(dLon / 2);
            return 6371 * 2 * Math.Asin(Math.Min(1, Math.Sqrt(a)));
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

        // A fragment that says nothing yet: "Hare needed", "Travel details
        // are yet to be announced", "Location TBA", "On site". Such notes
        // must not make an empty run look described (James, 2026-10-05).
        private static readonly Regex Placeholder = new(
            @"^\s*(hares?\s+(needed|required|wanted)\b.*|.*\b(tba|tbc|tbd)\b.*|.*\bto be (announced|confirmed|arranged)\b.*"
            + @"|.*\bcontact the hare\s*raiser\b.*|on\s*site|location (unknown|not yet known)|details (to follow|soon)|none|n/?a)\s*[.!]?\s*$",
            RegexOptions.IgnoreCase | RegexOptions.Compiled);

        // "12 Noon for 12:30 start", "7pm for 7:15": just the start time,
        // which the run already carries — not a description.
        private static readonly Regex TimeWords = new(
            @"\b(\d{1,2}([:.]\d{2})?\s*(am|pm|h)?|noon|midday|for|start|starts|starting|sharp|meet|meeting|at|from|kick\s*-?off|time)\b|[\s\-–.,:!()]",
            RegexOptions.IgnoreCase | RegexOptions.Compiled);

        private static bool OnlyATime(string fragment) =>
            Regex.IsMatch(fragment, @"\d|noon|midday", RegexOptions.IgnoreCase)
            && TimeWords.Replace(fragment, "").Length == 0;

        private static string? WithoutPlaceholders(string? text)
        {
            if (string.IsNullOrWhiteSpace(text)) return null;
            var keep = text.Split(new[] { ';', '\n' }, StringSplitOptions.RemoveEmptyEntries)
                .Select(p => p.Trim()).Where(p => p.Length > 0 && !Placeholder.IsMatch(p) && !OnlyATime(p)).ToList();
            return keep.Count == 0 ? null : string.Join("; ", keep);
        }

        private static string? Description(JToken r)
        {
            var parts = new List<string>();
            string? notes = WithoutPlaceholders(r.Value<string>("notes"));
            string? onOn = WithoutPlaceholders(r.Value<string>("onOn"));
            if (!string.IsNullOrWhiteSpace(notes)) parts.Add(notes.Trim());
            if (!string.IsNullOrWhiteSpace(onOn)) parts.Add($"On On: {onOn.Trim()}");
            return parts.Count == 0 ? null : string.Join("\n", parts);
        }

        // ── SQL ─────────────────────────────────────────────────────────────

        private sealed record KennelRow(Guid KennelId, string Name, string ShortName, string Url, string? Hash,
            string LocalToday, int? LatestRunNumber, string? LatestRunDate, string? DefaultStart,
            string? City = null, string? Country = null, double? AnchorLat = null, double? AnchorLon = null);

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
                    S("LatestRunDate"), S("DefaultStartTime"),
                    S("CityName"), S("CountryName"),
                    r["AnchorLat"] is DBNull ? null : Convert.ToDouble(r["AnchorLat"]),
                    r["AnchorLon"] is DBNull ? null : Convert.ToDouble(r["AnchorLon"])));
            }
            return list;
        }

        private sealed record ImportResult(int Inserted, int Updated, int Unchanged, int AlreadyInHc, int Rejected,
            Dictionary<int, string> Outcomes, int Skipped = 0);

        private static async Task<ImportResult> ImportAsync(string cs, Guid kennelId, string json, bool dryRun)
        {
            try { return await ImportCoreAsync(cs, kennelId, json, dryRun); }
            catch (Exception ex) { throw Stage("DB", ex); }
        }

        private static async Task<ImportResult> ImportCoreAsync(string cs, Guid kennelId, string json, bool dryRun)
        {
            using var conn = new SqlConnection(cs);
            await conn.OpenAsync();
            using var cmd = new SqlCommand("[HC6].[nonApi_importRunsPageRuns]", conn) { CommandType = CommandType.StoredProcedure, CommandTimeout = 120 };
            cmd.Parameters.Add("@kennelId", SqlDbType.UniqueIdentifier).Value = kennelId;
            cmd.Parameters.Add("@runsJson", SqlDbType.NVarChar, -1).Value = json;
            cmd.Parameters.Add("@dryRun", SqlDbType.SmallInt).Value = dryRun ? 1 : 0;
            using SqlDataReader r = await cmd.ExecuteReaderAsync();
            int a = 0, b = 0, c = 0, d = 0, e = 0, f = 0;
            if (await r.ReadAsync())
            {
                a = r.GetInt32(0); b = r.GetInt32(1); c = r.GetInt32(2); d = r.GetInt32(3); e = r.GetInt32(4);
                if (r.FieldCount > 5) f = r.GetInt32(5);   // skipped (SP build 37+)
            }
            var outcomes = new Dictionary<int, string>();
            if (await r.NextResultAsync())
            {
                while (await r.ReadAsync())
                {
                    if (r["EventNumber"] is DBNull) continue;
                    outcomes[Convert.ToInt32(r["EventNumber"])] = r["Outcome"].ToString() ?? "";
                }
            }
            return new ImportResult(a, b, c, d, e, outcomes, f);
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

        private static async Task LogErrorAsync(string cs, KennelRow? k, string stage, string message)
        {
            try
            {
                using var conn = new SqlConnection(cs);
                await conn.OpenAsync();
                using var cmd = new SqlCommand(
                    "INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId) " +
                    "VALUES (NEWID(), '<api>', @n, @d, 'RunsPageImport', NULL);", conn);
                cmd.Parameters.Add("@n", SqlDbType.NVarChar, 200).Value =
                    stage == "output" ? "Runs page output suspect" : $"Runs page {stage} failed";
                cmd.Parameters.Add("@d", SqlDbType.NVarChar, -1).Value =
                    k == null ? message : $"{k.ShortName} ({k.KennelId}) {k.Url}: {message}";
                await cmd.ExecuteNonQueryAsync();
            }
            catch { /* best effort */ }
        }

        private async Task RecordAiUsageAsync(string cs, KennelRow k, string model, string outcome,
            int promptTokens, int completionTokens, long ms, string? detail)
        {
            decimal perMIn = decimal.TryParse(Environment.GetEnvironmentVariable("AZURE_OPENAI_USD_PER_M_IN"),
                System.Globalization.NumberStyles.Number, System.Globalization.CultureInfo.InvariantCulture, out decimal pi) ? pi : DefaultUsdPerMIn;
            decimal perMOut = decimal.TryParse(Environment.GetEnvironmentVariable("AZURE_OPENAI_USD_PER_M_OUT"),
                System.Globalization.NumberStyles.Number, System.Globalization.CultureInfo.InvariantCulture, out decimal po) ? po : DefaultUsdPerMOut;
            decimal cost = (promptTokens * perMIn + completionTokens * perMOut) / 1_000_000m;
            try
            {
                using var conn = new SqlConnection(cs);
                await conn.OpenAsync();
                using var cmd = new SqlCommand("HC6.nonApi_logAiUsage", conn) { CommandType = CommandType.StoredProcedure };
                cmd.Parameters.Add("@sessionId", SqlDbType.UniqueIdentifier).Value = _sessionId;
                cmd.Parameters.Add("@feature", SqlDbType.NVarChar, -1).Value = _feature;
                cmd.Parameters.Add("@kennelId", SqlDbType.UniqueIdentifier).Value = k.KennelId;
                cmd.Parameters.Add("@model", SqlDbType.NVarChar, -1).Value = model;
                cmd.Parameters.Add("@promptTokens", SqlDbType.Int).Value = promptTokens;
                cmd.Parameters.Add("@completionTokens", SqlDbType.Int).Value = completionTokens;
                var c = cmd.Parameters.Add("@costUsd", SqlDbType.Decimal); c.Precision = 12; c.Scale = 8; c.Value = cost;
                cmd.Parameters.Add("@durationMs", SqlDbType.Int).Value = (int)Math.Min(ms, int.MaxValue);
                cmd.Parameters.Add("@outcome", SqlDbType.NVarChar, -1).Value = outcome;
                cmd.Parameters.Add("@detail", SqlDbType.NVarChar, -1).Value = (object?)detail ?? DBNull.Value;
                await cmd.ExecuteNonQueryAsync();
            }
            catch (Exception ex)
            {
                // Never fail an import over its own bookkeeping — but say so.
                _log.LogWarning("RunsPageImport: AI usage not recorded: {Message}", ex.Message);
                await LogErrorAsync(cs, k, "usage-log", "AI usage row not written: " + ex.Message);
            }
        }

        private async Task RecordJobAsync(string cs, DateTimeOffset started,
            List<string> nice, List<string> naughty, List<string> errors)
        {
            try
            {
                using var conn = new SqlConnection(cs);
                await conn.OpenAsync();
                using var cmd = new SqlCommand("HC6.nonApi_recordRunsPageJob", conn) { CommandType = CommandType.StoredProcedure };
                cmd.Parameters.Add("@startedAt", SqlDbType.DateTimeOffset).Value = started;
                cmd.Parameters.Add("@runsFound", SqlDbType.Int).Value = _found;
                cmd.Parameters.Add("@runsInserted", SqlDbType.Int).Value = _inserted;
                cmd.Parameters.Add("@runsUpdated", SqlDbType.Int).Value = _updated;
                cmd.Parameters.Add("@errorCount", SqlDbType.Int).Value = errors.Count;
                cmd.Parameters.Add("@errorInfo", SqlDbType.NVarChar, -1).Value = string.Join("\n", errors);
                cmd.Parameters.Add("@kennelsSucceeded", SqlDbType.Int).Value = nice.Count;
                cmd.Parameters.Add("@kennelsSucceededInfo", SqlDbType.NVarChar, -1).Value = string.Join(",", nice);
                cmd.Parameters.Add("@kennelsFailed", SqlDbType.Int).Value = naughty.Count;
                cmd.Parameters.Add("@kennelsFailedInfo", SqlDbType.NVarChar, -1).Value = string.Join(",", naughty);
                await cmd.ExecuteNonQueryAsync();
            }
            catch (Exception ex)
            {
                _log.LogWarning("RunsPageImport: job row not written: {Message}", ex.Message);
                await LogErrorAsync(cs, null, "DB", "integration job row not written: " + ex.Message);
            }
        }

        private static async Task LogGeneralAsync(string cs, string source, string message, string? param, string? data)
        {
            try
            {
                using var conn = new SqlConnection(cs);
                await conn.OpenAsync();
                using var cmd = new SqlCommand(
                    "INSERT LOG.GeneralLog (LogSource, Message, StrParam1, Data, [Timestamp]) VALUES (@s, @m, @p, @d, SYSDATETIMEOFFSET());", conn);
                cmd.Parameters.Add("@s", SqlDbType.NVarChar, 100).Value = source;
                // LOG.GeneralLog: Message NVARCHAR(255), StrParam1 500, Data 4000.
                cmd.Parameters.Add("@m", SqlDbType.NVarChar, 255).Value = Truncate(message, 255);
                cmd.Parameters.Add("@p", SqlDbType.NVarChar, 500).Value = param == null ? DBNull.Value : Truncate(param, 500);
                cmd.Parameters.Add("@d", SqlDbType.NVarChar, 4000).Value = data == null ? DBNull.Value : Truncate(data, 4000);
                await cmd.ExecuteNonQueryAsync();
            }
            catch { /* best effort */ }
        }

        private static string Stamp() => DateTime.UtcNow.ToString("yyyy-MM-dd HH:mm") + " UTC";

        private static string Truncate(string s, int n) => s.Length <= n ? s : s[..n];
    }
}
