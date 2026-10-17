using System.Data;
using System.Net;
using System.Text;
using System.Text.RegularExpressions;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json.Linq;

namespace HcWebApi.Endpoints
{
    /// <summary>
    /// HC Admin Tools › Version email (E19.F3.S3, James 2026-10-17): a platform
    /// admin emails everyone still on a given app build, with App Store / Google
    /// Play buttons for the phones they use, in the normal HC layout.
    ///
    /// POST { deviceId, accessToken, action, builds, days, subject, body, sendId }
    /// from the portal; the token is the portal's own, signed for
    /// hcportal_queueVersionEmail, which checks the caller is a platform admin
    /// with CanManageNewsflash.
    ///   action "test" — renders with both buttons and sends it to the caller.
    ///   action "features" — the five most important features added since the
    ///     OLDEST chosen build, picked by Azure OpenAI from the app's public
    ///     CHANGELOG (New Features and Improvements only), as lines for the
    ///     editor (James, 2026-10-17). Nothing is sent.
    ///   action "send" — the SP records every recipient in HC.EmailLog (Status 0)
    ///     under the portal's sendId BEFORE anything goes; the reply comes back at
    ///     once and a background loop claims ten at a time (Status 3), sends each
    ///     through the list route (ACS, runs@) and marks it 1 sent / 2 failed. A
    ///     repeat of the same sendId queues nothing new and only resumes rows still
    ///     queued — e.g. after an instance restart — so nobody is mailed twice.
    /// The body is plain text: blank lines make paragraphs, URLs become links,
    /// {firstName} / {hashName} are the person's first name / hash name (each
    /// falls back to the other, then "there").
    /// </summary>
    public class VersionEmail
    {
        private readonly ILogger<VersionEmail> _log;
        public VersionEmail(ILogger<VersionEmail> log) { _log = log; }

        // The draft says "just reply"; replies go to the mailbox James reads.
        private const string ReplyTo = "noreply@harriercentral.com";
        private const string AppStoreUrl = "https://apps.apple.com/app/harrier-central/id1445513595";
        private const string PlayUrl = "https://play.google.com/store/apps/details?id=com.harriercentral.app";
        // The official badges (Apple marketing tools / Google Play), PNG for email
        // clients that cannot show SVG, in the public email-images folder.
        private const string AppStoreBadge = "https://harriercentral.blob.core.windows.net/harrier/email/app-store-badge.png";
        private const string PlayBadge = "https://harriercentral.blob.core.windows.net/harrier/email/google-play-badge.png";

        private sealed record Queue(int Queued, int NewlyQueued, string Email, string FirstName, string HashName, string Name);

        [Function("VersionEmail")]
        public async Task<IActionResult> Run([HttpTrigger(AuthorizationLevel.Anonymous, "post")] HttpRequest req)
        {
            JObject body;
            try { body = JObject.Parse(await new StreamReader(req.Body).ReadToEndAsync()); }
            catch { return Fail(400, "That request could not be read."); }
            string? cs = Environment.GetEnvironmentVariable("HcDbConnectionString");
            if (cs == null || !HcListMail.IsConfigured) return Fail(500, "Email is not set up on the server.");
            if (!Guid.TryParse(body.Value<string>("deviceId"), out Guid deviceId)) return Fail(400, "Missing device.");

            string action = body.Value<string>("action") ?? "";
            bool test = action == "test";
            if (action == "features")
                return await FeaturesAsync(cs, deviceId, body.Value<string>("accessToken") ?? "", body.Value<string>("builds") ?? "");
            if (!test && action != "send") return Fail(400, "Unknown action.");
            string subject = (body.Value<string>("subject") ?? "").Trim();
            string text = body.Value<string>("body") ?? "";
            if (subject.Length == 0 || subject.Length > 250) return Fail(400, "The subject must be 1 to 250 characters.");
            if (text.Trim().Length == 0 || text.Length > 20000) return Fail(400, "The email needs some text (at most 20,000 characters).");
            Guid? sendId = Guid.TryParse(body.Value<string>("sendId"), out Guid sid) ? sid : null;
            if (!test && sendId == null) return Fail(400, "Missing send id.");

            Queue q;
            try
            {
                var (queue, error) = await QueueAsync(cs, deviceId, body.Value<string>("accessToken") ?? "", sendId,
                    body.Value<string>("builds") ?? "", body.Value<int?>("days") ?? 90, subject, test);
                if (queue == null) return Fail(403, error ?? "Not authorised.");
                q = queue;
            }
            catch (Exception ex)
            {
                _log.LogError(ex, "VersionEmail: queue failed");
                return Fail(500, "Harrier Central could not record that send. Nothing was sent.");
            }

            if (test)
            {
                if (string.IsNullOrWhiteSpace(q.Email) || GeneratedEmail.Is(q.Email))
                    return Fail(400, "Your own account has no real email address to send the test to.");
                try
                {
                    await HcListMail.SendAsync(q.Email, "[Test] " + subject, Html(subject, text, q.FirstName, q.HashName, true, true),
                        Plain(text, q.FirstName, q.HashName, true, true), null, replyTo: ReplyTo);
                }
                catch (Exception ex)
                {
                    await HcListMail.LogFailureAsync("VersionEmail.test", q.Email, ex.Message);
                    return Fail(502, "The test email could not be sent: " + ex.Message);
                }
                return new OkObjectResult(new { test = true, to = q.Email });
            }

            // The text once, for the record: the template with its placeholder, both buttons.
            if (q.NewlyQueued > 0)
            {
                string? audit = await EmailAudit.WriteAsync(new EmailAudit.Record
                {
                    Kind = "version", Subject = subject, Sender = q.Name,
                    Instruction = "builds " + (body.Value<string>("builds") ?? "") + ", last sign-in within " + (body.Value<int?>("days") ?? 90) + " days",
                    Html = Html(subject, text, "{firstName}", "{hashName}", true, true), PlainText = Plain(text, "{firstName}", "{hashName}", true, true),
                });
                if (audit != null) await UpdateAsync(cs, null, null, null, sendId, audit);
            }

            Guid send = sendId!.Value;
            _ = Task.Run(async () =>
            {
                int ok = 0, failed = 0;
                while (true)
                {
                    List<JObject> batch;
                    try { batch = await ClaimAsync(cs, send, 10); }
                    catch (Exception ex) { _log.LogError(ex, "VersionEmail: claim failed"); break; }
                    if (batch.Count == 0) break;
                    foreach (var r in batch)
                    {
                        Guid id = Guid.Parse(r.Value<string>("EmailLogId")!);
                        string to = r.Value<string>("Email") ?? "";
                        bool ios = r.Value<int?>("IsIos") == 1, android = r.Value<int?>("IsAndroid") == 1;
                        if (!ios && !android) { ios = true; android = true; }
                        try
                        {
                            string first = r.Value<string>("FirstName") ?? "", hash = r.Value<string>("HashName") ?? "";
                            await HcListMail.SendAsync(to, subject, Html(subject, text, first, hash, ios, android),
                                Plain(text, first, hash, ios, android), null, replyTo: ReplyTo);
                            await UpdateAsync(cs, id, 1, null, null, null);
                            ok++;
                        }
                        catch (Exception ex)
                        {
                            failed++;
                            await HcListMail.LogFailureAsync("VersionEmail.send", to, ex.Message);
                            try { await UpdateAsync(cs, id, 2, ex.Message, null, null); } catch { /* logged above */ }
                        }
                        // ACS paces at tens of messages a minute (as RunEmail).
                        await Task.Delay(250);
                    }
                }
                _log.LogInformation("VersionEmail {Send}: {Ok} sent, {Failed} failed", send, ok, failed);
            });
            return new OkObjectResult(new { queued = q.Queued, newlyQueued = q.NewlyQueued });
        }

        // ── Top features since a build ─────────────────────────────────────

        private const string ChangelogUrl =
            "https://raw.githubusercontent.com/James-A-White/HarrierCentral/master/mobile-app/CHANGELOG.md";
        private static readonly HttpClient Http = new() { Timeout = TimeSpan.FromSeconds(60) };
        private static (DateTime at, string text)? changelogCache;

        private async Task<IActionResult> FeaturesAsync(string cs, Guid deviceId, string token, string builds)
        {
            // The same platform-admin check as a send (the SP's test mode queues nothing).
            var (who, error) = await QueueAsync(cs, deviceId, token, null, "", 90, "features", true);
            if (who == null) return Fail(403, error ?? "Not authorised.");
            int fromBuild = builds.Split('|').Select(x => int.TryParse(x, out int b) ? b : int.MaxValue)
                                  .DefaultIfEmpty(int.MaxValue).Min();
            string since;
            try { since = await ChangelogSinceAsync(fromBuild); }
            catch (Exception ex) { return Fail(502, "Could not read the app's changelog: " + ex.Message); }
            if (since.Length == 0) return new OkObjectResult(new { features = Array.Empty<string>() });
            try { return new OkObjectResult(new { features = await TopFeaturesAsync(cs, since) }); }
            catch (Exception ex)
            {
                _log.LogWarning("VersionEmail features: {Message}", ex.Message);
                return Fail(502, "The feature list could not be written just now. Try again, or type it yourself.");
            }
        }

        /// <summary>New Features and Improvements from every entry newer than
        /// <paramref name="fromBuild"/>, newest first, capped for the model.</summary>
        private static async Task<string> ChangelogSinceAsync(int fromBuild)
        {
            if (changelogCache is not { } c || DateTime.UtcNow - c.at > TimeSpan.FromMinutes(30))
            {
                changelogCache = (DateTime.UtcNow, await Http.GetStringAsync(ChangelogUrl));
                c = changelogCache.Value;
            }
            var sb = new StringBuilder();
            foreach (string section in Regex.Split(c.text.Replace("\r\n", "\n"), @"(?m)^## "))
            {
                var head = Regex.Match(section, @"^\S+\+(\d+)");
                if (!head.Success || int.Parse(head.Groups[1].Value) <= fromBuild) continue;
                bool keep = false;
                foreach (string line in section.Split('\n').Skip(1))
                {
                    if (line.StartsWith("### "))
                    {
                        keep = Regex.IsMatch(line, @"New Features|Improvements", RegexOptions.IgnoreCase);
                        continue;
                    }
                    if (keep && line.Trim().Length > 0) sb.AppendLine(line.TrimEnd());
                }
                if (sb.Length > 120_000) break;
            }
            return sb.ToString();
        }

        private const string FeaturesPrompt =
            "You pick the five most important new features of Harrier Central, the app hash running clubs (kennels) " +
            "use for their runs, for hashers still on an OLD version, so they will want to update. You are given the " +
            "app's changelog lines added since their version, newest first. Choose what an ordinary hasher would notice " +
            "and value — big, visible things — not admin-only tools, fixes or technical changes. Group related entries " +
            "into one feature. Each feature: a short name, an em dash, then one plain sentence. No build numbers, no " +
            "code or table names, no hype. Return JSON {\"features\": [five strings]}.";

        private static async Task<string[]> TopFeaturesAsync(string cs, string changelog)
        {
            string endpoint = (Environment.GetEnvironmentVariable("AZURE_OPENAI_ENDPOINT") ?? "").TrimEnd('/');
            string key = Environment.GetEnvironmentVariable("AZURE_OPENAI_KEY") ?? "";
            string deployment = Environment.GetEnvironmentVariable("AZURE_OPENAI_DEPLOYMENT") ?? "runs-page";
            if (endpoint.Length == 0 || key.Length == 0) throw new InvalidOperationException("AZURE_OPENAI_ENDPOINT / AZURE_OPENAI_KEY are not set");
            var payload = new JObject
            {
                ["messages"] = new JArray(
                    new JObject { ["role"] = "system", ["content"] = FeaturesPrompt },
                    new JObject { ["role"] = "user", ["content"] = changelog }),
                ["temperature"] = 0.3,
                ["max_tokens"] = 700,
                ["response_format"] = new JObject
                {
                    ["type"] = "json_schema",
                    ["json_schema"] = new JObject
                    {
                        ["name"] = "features", ["strict"] = true,
                        ["schema"] = JObject.Parse("{\"type\":\"object\",\"additionalProperties\":false,\"required\":[\"features\"],\"properties\":{\"features\":{\"type\":\"array\",\"items\":{\"type\":\"string\"}}}}"),
                    },
                },
            };
            var clock = System.Diagnostics.Stopwatch.StartNew();
            using var req = new HttpRequestMessage(HttpMethod.Post, $"{endpoint}/openai/deployments/{deployment}/chat/completions?api-version=2024-10-21")
            { Content = new StringContent(payload.ToString(Newtonsoft.Json.Formatting.None), Encoding.UTF8, "application/json") };
            req.Headers.Add("api-key", key);
            using HttpResponseMessage res = await Http.SendAsync(req);
            string text = await res.Content.ReadAsStringAsync();
            var j = JObject.Parse(text);
            int pt = j["usage"]?.Value<int>("prompt_tokens") ?? 0, ct = j["usage"]?.Value<int>("completion_tokens") ?? 0;
            await RunEmail.LogAiUsageAsync(cs, Guid.Empty, deployment, res.IsSuccessStatusCode ? "ok" : $"http_{(int)res.StatusCode}", pt, ct, clock.ElapsedMilliseconds, "version-email");
            if (!res.IsSuccessStatusCode) throw new InvalidOperationException($"Azure OpenAI {(int)res.StatusCode}");
            string content = j["choices"]?[0]?["message"]?["content"]?.ToString() ?? throw new InvalidOperationException("no content");
            return (JObject.Parse(content)["features"] as JArray ?? new JArray())
                .Select(x => x.ToString().Trim()).Where(x => x.Length > 0).Take(5).ToArray();
        }

        // ── Rendering ──────────────────────────────────────────────────────

        private static readonly Regex Url = new(@"https?://[^\s<>""]+", RegexOptions.Compiled);

        // {firstName} and {hashName}: each falls back to the other, then "there"
        // (the SPs already fall back between the two; this covers an empty pair).
        private static string Fill(string text, string firstName, string hashName)
        {
            string first = string.IsNullOrWhiteSpace(firstName) ? (string.IsNullOrWhiteSpace(hashName) ? "there" : hashName.Trim()) : firstName.Trim();
            string hash = string.IsNullOrWhiteSpace(hashName) ? first : hashName.Trim();
            return text.Replace("{firstName}", first).Replace("{hashName}", hash);
        }

        internal static string Html(string subject, string text, string firstName, string hashName, bool ios, bool android)
        {
            var sb = new StringBuilder();
            foreach (string para in Regex.Split(Fill(text, firstName, hashName).Replace("\r\n", "\n").Trim(), @"\n\s*\n"))
            {
                string enc = WebUtility.HtmlEncode(para.Trim());
                enc = Url.Replace(enc, m => $"<a href=\"{m.Value}\" style=\"color:#2b6cb0\">{m.Value}</a>");
                sb.Append("<p style=\"margin:0 0 14px\">").Append(enc.Replace("\n", "<br>")).Append("</p>");
            }
            // The store buttons for the phones this person uses, side by side and
            // the same height; each opens its store's Harrier Central page.
            sb.Append("<table role=\"presentation\" cellpadding=\"0\" cellspacing=\"0\" style=\"margin:8px 0 0;\"><tr>");
            if (ios)
                sb.Append($"<td style=\"padding:0 12px 8px 0;\"><a href=\"{AppStoreUrl}\"><img src=\"{AppStoreBadge}\" height=\"48\" alt=\"Download on the App Store\" style=\"display:block;border:0;height:48px;width:auto;\"></a></td>");
            if (android)
                sb.Append($"<td style=\"padding:0 0 8px 0;\"><a href=\"{PlayUrl}\"><img src=\"{PlayBadge}\" height=\"48\" alt=\"Get it on Google Play\" style=\"display:block;border:0;height:48px;width:auto;\"></a></td>");
            sb.Append("</tr></table>");
            return HcEmail.Layout(subject, sb.ToString());
        }

        internal static string Plain(string text, string firstName, string hashName, bool ios, bool android) =>
            Fill(text, firstName, hashName).Trim() + "\n\n" +
            (ios ? $"App Store: {AppStoreUrl}\n" : "") + (android ? $"Google Play: {PlayUrl}\n" : "");

        // ── Database ───────────────────────────────────────────────────────

        private static async Task<(Queue?, string?)> QueueAsync(string cs, Guid deviceId, string token, Guid? sendId,
            string builds, int days, string subject, bool test)
        {
            using var conn = new SqlConnection(cs);
            await conn.OpenAsync();
            using var cmd = new SqlCommand("[HC6].[hcportal_queueVersionEmail]", conn) { CommandType = CommandType.StoredProcedure, CommandTimeout = 60 };
            cmd.Parameters.Add("@deviceId", SqlDbType.UniqueIdentifier).Value = deviceId;
            cmd.Parameters.Add("@accessToken", SqlDbType.NVarChar, 1000).Value = token;
            cmd.Parameters.Add("@sendId", SqlDbType.UniqueIdentifier).Value = (object?)sendId ?? DBNull.Value;
            cmd.Parameters.Add("@builds", SqlDbType.NVarChar, -1).Value = builds;
            cmd.Parameters.Add("@days", SqlDbType.Int).Value = days;
            cmd.Parameters.Add("@subject", SqlDbType.NVarChar, -1).Value = subject;
            cmd.Parameters.Add("@test", SqlDbType.SmallInt).Value = test ? 1 : 0;
            using var r = await cmd.ExecuteReaderAsync();
            if (!await r.ReadAsync()) return (null, "No reply.");
            if (Convert.ToInt32(r["Success"]) != 1) return (null, r["ErrorMessage"] as string);
            if (!await r.NextResultAsync() || !await r.ReadAsync()) return (null, "No reply.");
            return (new Queue(Convert.ToInt32(r["Queued"]), Convert.ToInt32(r["NewlyQueued"]),
                r["Email"] as string ?? "", r["FirstName"] as string ?? "", r["HashName"] as string ?? "", r["Name"] as string ?? ""), null);
        }

        private static async Task<List<JObject>> ClaimAsync(string cs, Guid sendId, int take)
        {
            var list = new List<JObject>();
            using var conn = new SqlConnection(cs);
            await conn.OpenAsync();
            using var cmd = new SqlCommand("[HC6].[nonApi_claimVersionEmails]", conn) { CommandType = CommandType.StoredProcedure, CommandTimeout = 30 };
            cmd.Parameters.Add("@sendId", SqlDbType.UniqueIdentifier).Value = sendId;
            cmd.Parameters.Add("@take", SqlDbType.Int).Value = take;
            using var r = await cmd.ExecuteReaderAsync();
            while (await r.ReadAsync())
                list.Add(new JObject
                {
                    ["EmailLogId"] = r["EmailLogId"].ToString(), ["Email"] = r["Email"] as string,
                    ["FirstName"] = r["FirstName"] as string, ["HashName"] = r["HashName"] as string, ["IsIos"] = Convert.ToInt32(r["IsIos"]),
                    ["IsAndroid"] = Convert.ToInt32(r["IsAndroid"]),
                });
            return list;
        }

        private static async Task UpdateAsync(string cs, Guid? id, int? status, string? reply, Guid? sendId, string? auditPath)
        {
            using var conn = new SqlConnection(cs);
            await conn.OpenAsync();
            using var cmd = new SqlCommand("[HC6].[nonApi_updateEmailLog]", conn) { CommandType = CommandType.StoredProcedure, CommandTimeout = 30 };
            cmd.Parameters.Add("@emailLogId", SqlDbType.UniqueIdentifier).Value = (object?)id ?? DBNull.Value;
            cmd.Parameters.Add("@status", SqlDbType.SmallInt).Value = (object?)status ?? DBNull.Value;
            cmd.Parameters.Add("@reply", SqlDbType.NVarChar, -1).Value = (object?)reply ?? DBNull.Value;
            cmd.Parameters.Add("@sendId", SqlDbType.UniqueIdentifier).Value = (object?)sendId ?? DBNull.Value;
            cmd.Parameters.Add("@auditPath", SqlDbType.NVarChar, 400).Value = (object?)auditPath ?? DBNull.Value;
            await cmd.ExecuteNonQueryAsync();
        }

        private static IActionResult Fail(int status, string message) =>
            new ObjectResult(new { errorUserMessage = message }) { StatusCode = status };
    }
}
