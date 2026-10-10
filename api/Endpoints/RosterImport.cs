using System.Data;
using System.Globalization;
using System.Text;
using System.Text.RegularExpressions;
using DocumentFormat.OpenXml.Packaging;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json.Linq;
using OfficeOpenXml;
using UglyToad.PdfPig;

namespace HcWebApi.Endpoints
{
    /// <summary>
    /// "Import from file" on the portal's Members page (E2.F2.S6, James
    /// 2026-10-10): reads a club's member list in whatever form it comes —
    /// Excel, CSV, PDF, Word — and has the AI turn it into rows for the add-
    /// hashers grid: first and last name, hash name, email, previous run and
    /// haring counts. Nothing is saved here; the admin reviews the grid and
    /// saves through hcportal_bulkAddHashers (@fromImport = 1).
    ///
    /// Request: POST JSON { deviceId, accessToken (minted for
    ///   hcportal_authorizeRosterImport), publicKennelId, fileName, fileBase64 }
    /// Reply: 200 { rows: [{firstName, lastName, hashName, eMail,
    ///   historicTotalRuns, historicHaring}], dropped, truncated }
    ///   or 4xx { errorUserMessage }.
    /// </summary>
    public class RosterImport
    {
        private readonly ILogger<RosterImport> _log;
        private static readonly HttpClient Http = new() { Timeout = TimeSpan.FromSeconds(120) };
        public RosterImport(ILogger<RosterImport> log) { _log = log; }

        private const int MaxFileBytes = 8 * 1024 * 1024;
        /// <summary>Text the AI reads per call; a longer file is read in pieces.</summary>
        private const int ChunkChars = 18_000;
        /// <summary>Beyond this the file is truncated (a roster, not a library).</summary>
        private const int MaxChars = 180_000;

        private static readonly Regex EmailRx = new(@"^[^@\s]+@[^@\s]+\.[^@\s]{2,}$", RegexOptions.Compiled);

        [Function("RosterImport")]
        public async Task<IActionResult> Run([HttpTrigger(AuthorizationLevel.Anonymous, "post")] HttpRequest req)
        {
            JObject body;
            try { body = JObject.Parse(await new StreamReader(req.Body).ReadToEndAsync()); }
            catch { return Bad("Bad request."); }

            string? cs = Environment.GetEnvironmentVariable("HcDbConnectionString");
            if (cs == null) return new ObjectResult(new { errorUserMessage = "Not configured." }) { StatusCode = 500 };
            if (!Guid.TryParse(body.Value<string>("deviceId"), out Guid deviceId)
                || !Guid.TryParse(body.Value<string>("publicKennelId"), out Guid publicKennelId)
                || string.IsNullOrEmpty(body.Value<string>("accessToken")))
                return Bad("Bad request.");

            // The gate first: nothing is read or sent to the AI for someone who may not add members.
            var (allowed, message, kennelId) = await AuthorizeAsync(cs, deviceId, body.Value<string>("accessToken")!, publicKennelId);
            if (!allowed) return new ObjectResult(new { errorUserMessage = message }) { StatusCode = 403 };

            string fileName = (body.Value<string>("fileName") ?? "").Trim();
            byte[] bytes;
            try { bytes = Convert.FromBase64String(body.Value<string>("fileBase64") ?? ""); }
            catch { return Bad("The file could not be read."); }
            if (bytes.Length == 0) return Bad("The file is empty.");
            if (bytes.Length > MaxFileBytes) return Bad("The file is larger than 8 MB.");

            string text;
            try { text = ExtractText(fileName, bytes); }
            catch (NotSupportedException ex) { return Bad(ex.Message); }
            catch (Exception ex)
            {
                _log.LogWarning("RosterImport could not read {File}: {Message}", fileName, ex.Message);
                return Bad("That file could not be read. Save it as .xlsx, .csv, .docx or .pdf and try again.");
            }
            text = text.Trim();
            if (text.Length == 0) return Bad("No text was found in the file. A scanned PDF (a picture of a page) cannot be read — use the original spreadsheet or document.");
            bool truncated = text.Length > MaxChars;
            if (truncated) text = text[..MaxChars];

            var rows = new List<JObject>();
            try
            {
                foreach (string chunk in Chunks(text))
                    rows.AddRange(await ReadRowsAsync(cs, kennelId, chunk));
            }
            catch (Exception ex)
            {
                _log.LogError("RosterImport AI failed: {Message}", ex.Message);
                return new ObjectResult(new { errorUserMessage = "The file could not be read just now. Please try again." }) { StatusCode = 502 };
            }

            var (clean, dropped) = Clean(rows);
            return new OkObjectResult(new { rows = clean, dropped, truncated });
        }

        private static ObjectResult Bad(string m) => new BadRequestObjectResult(new { errorUserMessage = m });

        private static async Task<(bool ok, string message, Guid kennelId)> AuthorizeAsync(string cs, Guid deviceId, string token, Guid publicKennelId)
        {
            using var conn = new SqlConnection(cs);
            await conn.OpenAsync();
            using var cmd = new SqlCommand("[HC6].[hcportal_authorizeRosterImport]", conn) { CommandType = CommandType.StoredProcedure };
            cmd.Parameters.Add("@deviceId", SqlDbType.UniqueIdentifier).Value = deviceId;
            cmd.Parameters.Add("@accessToken", SqlDbType.NVarChar, 1000).Value = token;
            cmd.Parameters.Add("@publicKennelId", SqlDbType.UniqueIdentifier).Value = publicKennelId;
            using var r = await cmd.ExecuteReaderAsync();
            if (!await r.ReadAsync()) return (false, "Please try again.", Guid.Empty);
            if (Convert.ToInt32(r["Success"]) != 1) return (false, r["ErrorMessage"] as string ?? "Not allowed.", Guid.Empty);
            return (true, "", Guid.Parse((string)r["kennelId"]));
        }

        // ── Reading the file ──────────────────────────────────────────────────

        /// <summary>Plain text of the file, one table row per line, cells separated by tabs.</summary>
        public static string ExtractText(string fileName, byte[] bytes)
        {
            string ext = Path.GetExtension(fileName).ToLowerInvariant();
            switch (ext)
            {
                case ".xlsx":
                case ".xlsm":
                    return FromExcel(bytes);
                case ".csv":
                case ".tsv":
                case ".txt":
                    return Encoding.UTF8.GetString(bytes).TrimStart('﻿');
                case ".pdf":
                    return FromPdf(bytes);
                case ".docx":
                    return FromWord(bytes);
                case ".xls":
                    throw new NotSupportedException("Old .xls files cannot be read. Open it in Excel, save as .xlsx, and try again.");
                case ".doc":
                    throw new NotSupportedException("Old .doc files cannot be read. Open it in Word, save as .docx, and try again.");
                default:
                    throw new NotSupportedException("Choose an Excel (.xlsx), CSV, Word (.docx) or PDF file.");
            }
        }

        private static string FromExcel(byte[] bytes)
        {
            ExcelPackage.LicenseContext = LicenseContext.NonCommercial;
            using var pkg = new ExcelPackage(new MemoryStream(bytes));
            var sb = new StringBuilder();
            foreach (var ws in pkg.Workbook.Worksheets)
            {
                if (ws.Dimension == null) continue;
                sb.AppendLine($"# Sheet: {ws.Name}");
                for (int r = ws.Dimension.Start.Row; r <= ws.Dimension.End.Row; r++)
                {
                    var cells = new List<string>();
                    for (int c = ws.Dimension.Start.Column; c <= ws.Dimension.End.Column; c++)
                        cells.Add((ws.Cells[r, c].Text ?? "").Replace('\t', ' ').Replace('\n', ' ').Trim());
                    if (cells.Any(x => x.Length > 0)) sb.AppendLine(string.Join('\t', cells).TrimEnd('\t'));
                }
            }
            return sb.ToString();
        }

        private static string FromPdf(byte[] bytes)
        {
            using var doc = PdfDocument.Open(bytes);
            var sb = new StringBuilder();
            foreach (var page in doc.GetPages())
            {
                // Words grouped into lines by their baseline, so a table reads row by row.
                foreach (var line in page.GetWords()
                             .GroupBy(w => Math.Round(w.BoundingBox.Bottom / 3))
                             .OrderByDescending(g => g.Key))
                    sb.AppendLine(string.Join(' ', line.OrderBy(w => w.BoundingBox.Left).Select(w => w.Text)));
            }
            return sb.ToString();
        }

        private static string FromWord(byte[] bytes)
        {
            using var doc = WordprocessingDocument.Open(new MemoryStream(bytes), false);
            var bodyEl = doc.MainDocumentPart?.Document?.Body;
            if (bodyEl == null) return "";
            var sb = new StringBuilder();
            foreach (var el in bodyEl.ChildElements)
            {
                if (el is DocumentFormat.OpenXml.Wordprocessing.Table t)
                {
                    foreach (var row in t.Elements<DocumentFormat.OpenXml.Wordprocessing.TableRow>())
                        sb.AppendLine(string.Join('\t', row.Elements<DocumentFormat.OpenXml.Wordprocessing.TableCell>().Select(c => c.InnerText.Trim())));
                }
                else
                {
                    string s = el.InnerText.Trim();
                    if (s.Length > 0) sb.AppendLine(s);
                }
            }
            return sb.ToString();
        }

        /// <summary>Pieces of about <see cref="ChunkChars"/>, cut at line ends, each repeating the first line (usually the headings).</summary>
        private static IEnumerable<string> Chunks(string text)
        {
            if (text.Length <= ChunkChars) { yield return text; yield break; }
            string[] lines = text.Replace("\r\n", "\n").Split('\n');
            string header = lines[0];
            var sb = new StringBuilder();
            foreach (string line in lines)
            {
                if (sb.Length + line.Length + 1 > ChunkChars && sb.Length > 0)
                {
                    yield return sb.ToString();
                    sb.Clear().AppendLine("(continued; the file's first line was: " + header + ")");
                }
                sb.AppendLine(line);
            }
            if (sb.Length > 0) yield return sb.ToString();
        }

        // ── The AI ───────────────────────────────────────────────────────────

        private const string SystemPrompt =
            "You read a hash running club's member list and return its people as structured rows. " +
            "The text came from a spreadsheet, PDF or Word document; tables are one row per line with tab-separated cells, " +
            "and the first line is often the column headings. " +
            "For each PERSON return: firstName, lastName, hashName (their hash/club nickname — often in quotes, brackets or its own column; " +
            "a 'hash name' is not a real name), email, runs (their total number of runs with the club, if given) and hares " +
            "(the number of times they set/hared a trail, if given). Use null for anything not given. " +
            "Never invent a value; never guess an email. Split a full name into first and last name. " +
            "Ignore headings, totals, blank rows, club officers' titles and anything that is not a person. " +
            "If one person appears twice, return them once.";

        private static readonly JObject Schema = JObject.Parse(@"{
          ""type"":""object"",""additionalProperties"":false,""required"":[""people""],
          ""properties"":{""people"":{""type"":""array"",""items"":{
            ""type"":""object"",""additionalProperties"":false,
            ""required"":[""firstName"",""lastName"",""hashName"",""email"",""runs"",""hares""],
            ""properties"":{
              ""firstName"":{""type"":[""string"",""null""]},""lastName"":{""type"":[""string"",""null""]},
              ""hashName"":{""type"":[""string"",""null""]},""email"":{""type"":[""string"",""null""]},
              ""runs"":{""type"":[""integer"",""null""]},""hares"":{""type"":[""integer"",""null""]}}}}}}");

        private async Task<List<JObject>> ReadRowsAsync(string cs, Guid kennelId, string text)
        {
            string endpoint = (Environment.GetEnvironmentVariable("AZURE_OPENAI_ENDPOINT") ?? "").TrimEnd('/');
            string key = Environment.GetEnvironmentVariable("AZURE_OPENAI_KEY") ?? "";
            string deployment = Environment.GetEnvironmentVariable("AZURE_OPENAI_DEPLOYMENT") ?? "runs-page";
            if (endpoint.Length == 0 || key.Length == 0) throw new InvalidOperationException("AZURE_OPENAI_ENDPOINT / AZURE_OPENAI_KEY are not set");

            var payload = new JObject
            {
                ["messages"] = new JArray(
                    new JObject { ["role"] = "system", ["content"] = SystemPrompt },
                    new JObject { ["role"] = "user", ["content"] = text }),
                ["temperature"] = 0,
                ["max_tokens"] = 16000,
                ["response_format"] = new JObject
                {
                    ["type"] = "json_schema",
                    ["json_schema"] = new JObject { ["name"] = "roster", ["strict"] = true, ["schema"] = Schema },
                },
            };
            var clock = System.Diagnostics.Stopwatch.StartNew();
            using var req = new HttpRequestMessage(HttpMethod.Post, $"{endpoint}/openai/deployments/{deployment}/chat/completions?api-version=2024-10-21")
            { Content = new StringContent(payload.ToString(Newtonsoft.Json.Formatting.None), Encoding.UTF8, "application/json") };
            req.Headers.Add("api-key", key);
            using HttpResponseMessage res = await Http.SendAsync(req);
            string body = await res.Content.ReadAsStringAsync();
            var j = JObject.Parse(body);
            int pt = j["usage"]?.Value<int>("prompt_tokens") ?? 0, ct = j["usage"]?.Value<int>("completion_tokens") ?? 0;
            await LogAiUsageAsync(cs, kennelId, deployment, res.IsSuccessStatusCode ? "ok" : $"http_{(int)res.StatusCode}", pt, ct, clock.ElapsedMilliseconds);
            if (!res.IsSuccessStatusCode) throw new InvalidOperationException($"Azure OpenAI {(int)res.StatusCode}");
            string content = j["choices"]?[0]?["message"]?["content"]?.ToString() ?? throw new InvalidOperationException("no content");
            return (JObject.Parse(content)["people"] as JArray ?? new JArray()).OfType<JObject>().ToList();
        }

        private static async Task LogAiUsageAsync(string cs, Guid kennelId, string model, string outcome, int pt, int ct, long ms)
        {
            decimal perMIn = decimal.TryParse(Environment.GetEnvironmentVariable("AZURE_OPENAI_USD_PER_M_IN"), NumberStyles.Number, CultureInfo.InvariantCulture, out decimal pi) ? pi : 0.15m;
            decimal perMOut = decimal.TryParse(Environment.GetEnvironmentVariable("AZURE_OPENAI_USD_PER_M_OUT"), NumberStyles.Number, CultureInfo.InvariantCulture, out decimal po) ? po : 0.60m;
            try
            {
                using var conn = new SqlConnection(cs);
                await conn.OpenAsync();
                using var cmd = new SqlCommand("HC6.nonApi_logAiUsage", conn) { CommandType = CommandType.StoredProcedure };
                cmd.Parameters.Add("@sessionId", SqlDbType.UniqueIdentifier).Value = Guid.NewGuid();
                cmd.Parameters.Add("@feature", SqlDbType.NVarChar, -1).Value = "roster-import";
                cmd.Parameters.Add("@kennelId", SqlDbType.UniqueIdentifier).Value = kennelId;
                cmd.Parameters.Add("@model", SqlDbType.NVarChar, -1).Value = model;
                cmd.Parameters.Add("@promptTokens", SqlDbType.Int).Value = pt;
                cmd.Parameters.Add("@completionTokens", SqlDbType.Int).Value = ct;
                var c = cmd.Parameters.Add("@costUsd", SqlDbType.Decimal); c.Precision = 12; c.Scale = 8; c.Value = (pt * perMIn + ct * perMOut) / 1_000_000m;
                cmd.Parameters.Add("@durationMs", SqlDbType.Int).Value = (int)Math.Min(ms, int.MaxValue);
                cmd.Parameters.Add("@outcome", SqlDbType.NVarChar, -1).Value = outcome;
                cmd.Parameters.Add("@detail", SqlDbType.NVarChar, -1).Value = DBNull.Value;
                await cmd.ExecuteNonQueryAsync();
            }
            catch { /* bookkeeping never fails an import */ }
        }

        // ── Tidying ──────────────────────────────────────────────────────────

        /// <summary>
        /// Trims, drops a row with neither a hash name nor a first + last name
        /// (counted as dropped), blanks an email that is not one, and merges
        /// repeats of the same email or the same name. Field names match the
        /// add-hashers grid (eMail, historicTotalRuns, historicHaring).
        /// </summary>
        public static (List<object> rows, int dropped) Clean(IEnumerable<JObject> people)
        {
            var outRows = new List<object>();
            var seen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            int dropped = 0;
            foreach (var p in people)
            {
                string S(string k) => (p.Value<string>(k) ?? "").Trim();
                string first = S("firstName"), last = S("lastName"), hash = S("hashName"), email = S("email").ToLowerInvariant();
                if (!EmailRx.IsMatch(email)) email = "";
                if (hash.Length == 0 && (first.Length == 0 || last.Length == 0)) { dropped++; continue; }
                string id = email.Length > 0 ? "e:" + email : hash.Length > 0 ? "h:" + hash : $"n:{first} {last}";
                if (!seen.Add(id)) continue;
                int? runs = p["runs"]?.Type == JTokenType.Integer ? p.Value<int>("runs") : null;
                int? hares = p["hares"]?.Type == JTokenType.Integer ? p.Value<int>("hares") : null;
                outRows.Add(new
                {
                    firstName = first, lastName = last, hashName = hash, eMail = email,
                    historicTotalRuns = runs is >= 0 ? runs : null,
                    historicHaring = hares is >= 0 ? hares : null,
                });
            }
            return (outRows, dropped);
        }
    }
}
