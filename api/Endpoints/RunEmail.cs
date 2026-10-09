using System.Data;
using System.Globalization;
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
    /// Save and send → Email (E9.F6.S6–S9). One endpoint, three actions, all
    /// authenticated with the app's own device token against
    /// hcapp_getRunEmailContext (the SP also gates on "may edit runs"):
    ///
    ///   context — the run, how many would receive an email, and whether one
    ///             has already gone out (the dialog's "Email N members" line)
    ///   draft   — Azure OpenAI writes the subject and the prose, optionally
    ///             steered by the sender's instruction ("a Halloween story",
    ///             "in French"); the sender edits and approves in the app
    ///   send    — the approved subject + prose, the FACTS block built by code
    ///             (date, venue, hares, price, app link, I'm-in / can't-make-it
    ///             links), the layout, and each recipient's own unsubscribe
    ///             link — one message per recipient through ACS; then the send
    ///             is recorded on HC.Event
    ///
    /// The model never writes a fact. It is given the facts so the prose can
    /// refer to them, but the block the reader acts on is generated here, so
    /// "make it funny" can never move the start time.
    ///
    /// Request: POST JSON { deviceId, accessToken, eventId, action,
    ///   client? ('portal' — then publicEventId instead of eventId and the token
    ///   is signed for hcportal_getRunEmailContext),
    ///   instruction?, subject?, body?, saveInstruction? }. context returns the
    ///   kennel's saved instruction so the composer pre-fills it. Replies are JSON; the SP's error
    ///   envelope comes back as 400 { errorType, errorUserMessage, errorId }.
    /// </summary>
    public class RunEmail
    {
        private readonly ILogger<RunEmail> _log;
        private static readonly HttpClient Http = new() { Timeout = TimeSpan.FromSeconds(60) };
        public RunEmail(ILogger<RunEmail> log) { _log = log; }

        public const int MaxInstruction = 300;
        public const int MaxBody = 6000;
        public const int MaxSubject = 150;

        [Function("RunEmail")]
        public async Task<IActionResult> Run([HttpTrigger(AuthorizationLevel.Anonymous, "post")] HttpRequest req)
        {
            JObject body;
            try { body = JObject.Parse(await new StreamReader(req.Body).ReadToEndAsync()); }
            catch { return new BadRequestObjectResult(new { errorUserMessage = "Bad request." }); }

            string action = (body.Value<string>("action") ?? "").ToLowerInvariant();
            // The portal signs its token differently (ValidatePortalAuth) and knows
            // the run by its public id, so it goes through hcportal_getRunEmailContext.
            bool portal = string.Equals(body.Value<string>("client"), "portal", StringComparison.OrdinalIgnoreCase);
            if (!Guid.TryParse(body.Value<string>("deviceId"), out Guid deviceId)
                || !Guid.TryParse(body.Value<string>(portal ? "publicEventId" : "eventId"), out Guid eventId)
                || string.IsNullOrEmpty(body.Value<string>("accessToken"))
                || action is not ("context" or "draft" or "send" or "audience"))
                return new BadRequestObjectResult(new { errorUserMessage = "Bad request." });

            string? cs = Environment.GetEnvironmentVariable("HcDbConnectionString");
            if (cs == null) return new ObjectResult(new { errorUserMessage = "Server not configured." }) { StatusCode = 500 };

            RunContext ctx;
            try
            {
                // A send needs both lists too: overrides move members between them.
                int include = action is "audience" or "send" ? 2 : 0;
                var loaded = await LoadContextAsync(cs, deviceId, body.Value<string>("accessToken")!, eventId, includeRecipients: include, portal: portal);
                if (loaded.error != null) return new BadRequestObjectResult(loaded.error);
                ctx = loaded.ctx!;
            }
            catch (Exception ex)
            {
                _log.LogError("RunEmail context failed: {Message}", ex.Message);
                return new ObjectResult(new { errorUserMessage = "Could not load the run." }) { StatusCode = 500 };
            }

            switch (action)
            {
                case "context":
                    return new OkObjectResult(ctx.ToSummary());

                case "audience":
                    // The "Who gets it" page: names as the check-in list shows them.
                    return new OkObjectResult(new
                    {
                        recipients = ctx.Recipients.Select(m => m.ToJson()),
                        nonRecipients = ctx.NonRecipients.Select(m => m.ToJson()),
                    });

                case "draft":
                {
                    string instruction = (body.Value<string>("instruction") ?? "").Trim();
                    if (instruction.Length > MaxInstruction) instruction = instruction[..MaxInstruction];
                    try
                    {
                        var (subject, prose) = await DraftAsync(cs, ctx, instruction);
                        return new OkObjectResult(new { subject, body = prose, preview = BuildHtml(ctx, subject, prose, null) });
                    }
                    catch (Exception ex)
                    {
                        _log.LogError("RunEmail draft failed: {Message}", ex.Message);
                        await HcListMail.LogFailureAsync("RunEmail.draft", "-", ex.Message, eventId);
                        return new ObjectResult(new { errorUserMessage = "The draft could not be written just now. Try again, or write it yourself." }) { StatusCode = 502 };
                    }
                }

                case "send":
                {
                    if (!HcListMail.IsConfigured)
                        return new ObjectResult(new { errorUserMessage = "Email sending is not configured." }) { StatusCode = 500 };
                    // A subject is one line whatever the client sent.
                    string subject = Regex.Replace((body.Value<string>("subject") ?? ""), @"\s*[\r\n]+\s*", " ").Trim();
                    string prose = (body.Value<string>("body") ?? "").Trim();
                    if (subject.Length == 0 || prose.Length == 0)
                        return new BadRequestObjectResult(new { errorUserMessage = "The email needs a subject and some text." });
                    if (subject.Length > MaxSubject) subject = subject[..MaxSubject];
                    if (prose.Length > MaxBody) prose = prose[..MaxBody];
                    prose = StripSignOff(prose, ctx.SenderName);
                    if (prose.Length == 0)
                        return new BadRequestObjectResult(new { errorUserMessage = "The email needs some text." });

                    // Preview: the finished email to the SENDER only — not recorded on the
                    // run, not counted, the sender's own unsubscribe link in it so the
                    // preview is exactly what a member would get (James, 2026-10-09).
                    if (body.Value<bool?>("previewToSelf") == true)
                    {
                        if (ctx.SenderEmail.Length == 0)
                            return new BadRequestObjectResult(new { errorUserMessage = "Your account has no email address." });
                        string unsubSelf = HcListMail.UnsubscribeUrl(ctx.SenderId, ctx.KennelId);
                        try
                        {
                            await HcListMail.SendAsync(ctx.SenderEmail, "[Preview] " + subject, BuildHtml(ctx, subject, prose, unsubSelf),
                                PlainText(ctx, prose), unsubSelf);
                        }
                        catch (Exception ex)
                        {
                            await HcListMail.LogFailureAsync("RunEmail.preview", ctx.SenderEmail, ex.Message, eventId);
                            return new ObjectResult(new { errorUserMessage = "The preview could not be sent just now." }) { StatusCode = 502 };
                        }
                        return new OkObjectResult(new { sent = 1, preview = true });
                    }

                    // Per-send overrides (James, 2026-10-09): this send only, nothing written
                    // to anybody's preferences. A blocked, bouncing or address-less member
                    // can never be moved in — the server refuses the id whatever the client
                    // sent — and at most 20 may be moved in, so this is not a way round the
                    // preference system for a whole kennel.
                    var includeIds = Ids(body["includeHasherIds"]);
                    var excludeIds = Ids(body["excludeHasherIds"]);
                    var movedIn = ctx.NonRecipients.Where(m => includeIds.Contains(m.HasherId) && m.CanMove).Take(20).ToList();
                    var refused = ctx.NonRecipients.Where(m => includeIds.Contains(m.HasherId) && !m.CanMove).ToList();
                    if (refused.Count > 0)
                        return new BadRequestObjectResult(new { errorUserMessage = $"{refused[0].Name} cannot be sent this email ({Member.ReasonText(refused[0].ReasonCode).ToLowerInvariant()})." });
                    var movedOut = ctx.Recipients.Where(m => excludeIds.Contains(m.HasherId)).ToList();
                    var finalList = ctx.Recipients.Where(m => !excludeIds.Contains(m.HasherId)).Concat(movedIn).ToList();
                    var movedInIds = movedIn.Select(m => m.HasherId).ToHashSet();
                    if (finalList.Count == 0)
                        return new BadRequestObjectResult(new { errorUserMessage = "Nobody in this kennel has run emails switched on." });
                    foreach (var m in movedIn) await LogOverrideAsync(cs, ctx, m, "in");
                    foreach (var m in movedOut) await LogOverrideAsync(cs, ctx, m, "out");

                    // The instruction that shaped this email, saved as the kennel's
                    // default when the sender ticked the box (James, 2026-10-09): a
                    // kennel that wants its emails in French always wants them in French.
                    string instruction = (body.Value<string>("instruction") ?? "").Trim();
                    if (instruction.Length > MaxInstruction) instruction = instruction[..MaxInstruction];
                    bool saveInstruction = body.Value<bool?>("saveInstruction") ?? false;

                    // Record first, so a crash mid-send still shows "emailed" rather
                    // than inviting a second blast; failures are logged per address.
                    await RecordSentAsync(cs, ctx, finalList.Count, instruction, saveInstruction);
                    string plain = PlainText(ctx, prose);
                    _ = Task.Run(async () =>
                    {
                        int ok = 0;
                        foreach (var r in finalList)
                        {
                            try
                            {
                                string unsub = HcListMail.UnsubscribeUrl(r.HasherId, ctx.KennelId);
                                bool requested = movedInIds.Contains(r.HasherId);
                                string prefs = requested ? HcListMail.PreferencesUrl(r.HasherId, ctx.KennelId) : "";
                                await HcListMail.SendAsync(r.Email, subject, BuildHtml(ctx, subject, prose, unsub, requested ? prefs : null),
                                    (requested ? $"{ctx.SenderName} has requested that you receive this email. Your email preferences: {prefs}\n\n" : "") +
                                    plain + $"\n\nUnsubscribe from {ctx.KennelName} run emails: {unsub}", unsub);
                                ok++;
                            }
                            catch (Exception ex)
                            {
                                await HcListMail.LogFailureAsync("RunEmail.send", r.Email, ex.Message, eventId);
                            }
                            // ACS paces at tens of messages a minute; a short gap keeps a
                            // big kennel inside it rather than tripping 429s.
                            await Task.Delay(250);
                        }
                        _log.LogInformation("RunEmail: {Ok}/{Total} accepted for event {Event}", ok, finalList.Count, eventId);
                    });
                    return new OkObjectResult(new { sent = finalList.Count, movedIn = movedIn.Count, movedOut = movedOut.Count });
                }
            }
            return new BadRequestObjectResult(new { errorUserMessage = "Bad request." });
        }

        // ── Context ────────────────────────────────────────────────────────────

        /// <summary>One kennel member as the audience page shows them. reasonCode: 1 on for this
        /// run, 2 on for the kennel, 3 run emails off, 4 kennel emails off, 5 never switched on,
        /// 6 no email address, 7 blocked all emails, 8 email bouncing. canMove: an admin may
        /// override for one send (never 6, 7, 8).</summary>
        public sealed record Member(Guid HasherId, string Email, string Name, string MortalName, string Photo, int EmailStatus, int ReasonCode, bool CanMove)
        {
            public object ToJson() => new { hasherId = HasherId, name = Name, mortalName = MortalName, photo = Photo, emailStatus = EmailStatus, reasonCode = ReasonCode, canMove = CanMove, reason = ReasonText(ReasonCode) };
            public static string ReasonText(int code) => code switch
            {
                1 => "On for this run", 2 => "On for the kennel", 3 => "Run emails off", 4 => "Kennel emails off",
                5 => "Never switched on", 6 => "No email address", 7 => "Blocked all emails", 8 => "Email bouncing, ask for a new address", _ => "",
            };
        }

        public sealed class RunContext
        {
            public Guid EventId, KennelId, PublicEventId, SenderId;
            public int EventNumber, IsCountedRun, EmailSendCount;
            public string EventName = "", Hares = "", Venue = "", Street = "", City = "", PostCode = "", Description = "";
            public string KennelName = "", KennelShortName = "", KennelSlug = "", KennelLogo = "", SenderName = "", SenderEmail = "", CurrencySymbol = "", Instruction = "";
            public DateTime StartLocal;
            public decimal PriceMembers, PriceNonMembers;
            public DateTimeOffset? EmailLastSentAt;
            public int? EmailLastSentCount;
            public int RecipientCount;
            public List<Member> Recipients = new();
            public List<Member> NonRecipients = new();

            public bool Counted => IsCountedRun == 1 && EventNumber > 0;
            public string Url => Counted
                ? $"https://www.hashruns.org/{KennelSlug.ToLowerInvariant()}/{EventNumber}"
                : $"https://www.hashruns.org/#/RID?publicEventId={PublicEventId:D}";
            public string RsvpUrl(bool yes) => Counted ? $"{Url}?RSVP={(yes ? "Yes" : "No")}" : $"{Url}&RSVP={(yes ? "Yes" : "No")}";
            public string Title => (Counted ? $"{KennelShortName} #{EventNumber}" : KennelShortName) + (EventName.Length > 0 ? $" – {EventName}" : "");
            public string When => StartLocal.ToString("dddd d MMMM yyyy, h:mm tt", CultureInfo.InvariantCulture);
            public string Where
            {
                get
                {
                    var parts = new List<string>();
                    if (Venue.Length > 0) parts.Add(Venue);
                    if (Street.Length > 0 && !Venue.Contains(Street, StringComparison.OrdinalIgnoreCase)) parts.Add(Street);
                    if (City.Length > 0 && !string.Join(' ', parts).Contains(City, StringComparison.OrdinalIgnoreCase)) parts.Add(City);
                    if (PostCode.Length > 0) parts.Add(PostCode);
                    return string.Join(", ", parts);
                }
            }
            public string Price
            {
                get
                {
                    string Money(decimal v)
                    {
                        string sym = CurrencySymbol.Length > 0 ? CurrencySymbol : "^";
                        if (!sym.Contains('^')) sym += "^";
                        return sym.Replace("^", v.ToString("0.00", CultureInfo.InvariantCulture));
                    }
                    if (PriceMembers <= 0 && PriceNonMembers <= 0) return "";
                    if (PriceMembers == PriceNonMembers || PriceMembers <= 0) return Money(PriceNonMembers);
                    if (PriceNonMembers <= 0) return Money(PriceMembers);
                    return $"{Money(PriceMembers)} (members) · {Money(PriceNonMembers)} (non-members)";
                }
            }
            public object ToSummary() => new
            {
                eventId = EventId, title = Title, when = When, where = Where, hares = Hares, price = Price, url = Url, instruction = Instruction,
                recipientCount = RecipientCount, emailSendCount = EmailSendCount, emailLastSentAt = EmailLastSentAt, emailLastSentCount = EmailLastSentCount,
            };
        }

        private static async Task<(RunContext? ctx, object? error)> LoadContextAsync(string cs, Guid deviceId, string accessToken, Guid eventId, int includeRecipients, bool portal = false)
        {
            using var conn = new SqlConnection(cs);
            await conn.OpenAsync();
            using var cmd = new SqlCommand(portal ? "[HC6].[hcportal_getRunEmailContext]" : "[HC6].[hcapp_getRunEmailContext]", conn) { CommandType = CommandType.StoredProcedure, CommandTimeout = 30 };
            cmd.Parameters.Add("@deviceId", SqlDbType.UniqueIdentifier).Value = deviceId;
            cmd.Parameters.Add("@accessToken", SqlDbType.NVarChar, 1000).Value = accessToken;
            cmd.Parameters.Add(portal ? "@publicEventId" : "@eventId", SqlDbType.UniqueIdentifier).Value = eventId;
            cmd.Parameters.Add("@includeRecipients", SqlDbType.SmallInt).Value = includeRecipients;
            using var r = await cmd.ExecuteReaderAsync();
            if (!await r.ReadAsync()) return (null, new { errorUserMessage = "Run not found." });
            if (HasColumn(r, "errorType"))   // the app SP's error envelope
                return (null, new { errorType = r["errorType"], errorUserMessage = r["errorUserMessage"], errorId = r["errorId"] });
            if (HasColumn(r, "Success") && Convert.ToInt32(r["Success"]) == 0)   // the portal SP's
                return (null, new { errorUserMessage = r["ErrorMessage"]?.ToString() ?? "Not allowed." });

            string S(string c) => r[c] as string ?? "";
            var ctx = new RunContext
            {
                EventId = (Guid)Guid.Parse(S("eventId")), EventNumber = Convert.ToInt32(r["eventNumber"]), EventName = S("eventName").Trim(),
                IsCountedRun = Convert.ToInt32(r["isCountedRun"]), PublicEventId = Guid.Parse(S("publicEventId")),
                StartLocal = (DateTime)r["startLocal"], Hares = S("hares").Trim(), Venue = S("venue").Trim(), Street = S("street").Trim(),
                City = S("city").Trim(), PostCode = S("postCode").Trim(), Description = S("description").Trim(),
                PriceMembers = r["priceMembers"] is DBNull ? 0 : Convert.ToDecimal(r["priceMembers"]),
                PriceNonMembers = r["priceNonMembers"] is DBNull ? 0 : Convert.ToDecimal(r["priceNonMembers"]),
                CurrencySymbol = S("currencySymbol"), KennelId = Guid.Parse(S("kennelId")), KennelName = S("kennelName"),
                KennelShortName = S("kennelShortName"), KennelSlug = S("kennelSlug"), KennelLogo = S("kennelLogo"), SenderName = S("senderName"),
                Instruction = HasColumn(r, "instruction") ? S("instruction").Trim() : "",
                SenderEmail = HasColumn(r, "senderEmail") ? S("senderEmail").Trim() : "",
                SenderId = HasColumn(r, "senderId") && Guid.TryParse(S("senderId"), out Guid sid) ? sid : Guid.Empty,
            };
            if (await r.NextResultAsync() && await r.ReadAsync())
            {
                ctx.EmailSendCount = Convert.ToInt32(r["emailSendCount"]);
                ctx.EmailLastSentAt = r["emailLastSentAt"] is DBNull ? null : (DateTimeOffset)r["emailLastSentAt"];
                ctx.EmailLastSentCount = r["emailLastSentCount"] is DBNull ? null : Convert.ToInt32(r["emailLastSentCount"]);
                ctx.RecipientCount = Convert.ToInt32(r["recipientCount"]);
            }
            Member Row() => new(Guid.Parse(S("hasherId")), S("email"), S("hashName"), S("mortalName"), S("photo"),
                Convert.ToInt32(r["emailStatus"]), Convert.ToInt32(r["reasonCode"]), Convert.ToInt32(r["canMove"]) == 1);
            if (includeRecipients >= 1 && await r.NextResultAsync())
                while (await r.ReadAsync()) ctx.Recipients.Add(Row());
            if (includeRecipients == 2 && await r.NextResultAsync())
                while (await r.ReadAsync()) ctx.NonRecipients.Add(Row());
            return (ctx, null);
        }

        private static HashSet<Guid> Ids(JToken? t)
        {
            var set = new HashSet<Guid>();
            if (t is JArray a) foreach (var x in a) if (Guid.TryParse(x?.ToString(), out Guid g)) set.Add(g);
            return set;
        }

        /// <summary>Every override is logged: admin, member, run, direction, time (LOG.GeneralLog).</summary>
        private static async Task LogOverrideAsync(string cs, RunContext ctx, Member m, string direction)
        {
            try
            {
                using var conn = new SqlConnection(cs);
                await conn.OpenAsync();
                using var cmd = new SqlCommand(
                    "INSERT LOG.GeneralLog (LogSource, Message, StrParam1, Data, [Timestamp]) VALUES ('RunEmailOverride', @m, @e, @d, SYSDATETIMEOFFSET())", conn);
                cmd.Parameters.Add("@m", SqlDbType.NVarChar, 200).Value = direction == "in" ? "Moved into the send" : "Moved out of the send";
                cmd.Parameters.Add("@e", SqlDbType.NVarChar, 100).Value = ctx.EventId.ToString("D");
                cmd.Parameters.Add("@d", SqlDbType.NVarChar, -1).Value =
                    $"admin {ctx.SenderId:D} ({ctx.SenderName}), member {m.HasherId:D} ({m.Name}), reason was {Member.ReasonText(m.ReasonCode)}";
                await cmd.ExecuteNonQueryAsync();
            }
            catch { /* the log must never stop the send */ }
        }

        private static bool HasColumn(SqlDataReader r, string name)
        {
            for (int i = 0; i < r.FieldCount; i++) if (r.GetName(i).Equals(name, StringComparison.OrdinalIgnoreCase)) return true;
            return false;
        }

        private static async Task RecordSentAsync(string cs, RunContext ctx, int count, string instruction, bool saveInstruction)
        {
            using var conn = new SqlConnection(cs);
            await conn.OpenAsync();
            using var cmd = new SqlCommand("[HC6].[nonApi_recordRunEmailSent]", conn) { CommandType = CommandType.StoredProcedure };
            cmd.Parameters.Add("@eventId", SqlDbType.UniqueIdentifier).Value = ctx.EventId;
            cmd.Parameters.Add("@userId", SqlDbType.UniqueIdentifier).Value = DBNull.Value;
            cmd.Parameters.Add("@recipientCount", SqlDbType.Int).Value = count;
            cmd.Parameters.Add("@instruction", SqlDbType.NVarChar, 500).Value = (object?)(instruction.Length > 0 ? instruction : null) ?? DBNull.Value;
            cmd.Parameters.Add("@saveInstruction", SqlDbType.SmallInt).Value = saveInstruction ? 1 : 0;
            await cmd.ExecuteNonQueryAsync();
        }

        // ── Draft ──────────────────────────────────────────────────────────────

        private const string SystemPrompt =
            "You write short, warm emails from a hash house harriers club to its members, announcing a run. " +
            "You are given the facts; a separate block in the email will show them exactly, so DO NOT repeat the date, time, address, price or links as a list — " +
            "refer to them in prose if you like, but never change or invent any fact. Never invent hares, venues, times or prices. " +
            "Write in the sender's voice (first person plural: 'we'). Keep it to 60–180 words unless the instruction asks for a story. " +
            "Hash jargon (hare, on-on, down-down, circle) stays as it is. No subject-line clickbait. " +
            "Do NOT write a sign-off, a closing line, or the sender's name — 'On on' and the sender's name are added after your text. " +
            "Do NOT state the price in figures or add a currency symbol (you do not know the currency); say 'the usual run fee' or nothing. " +
            "If an instruction asks for another language, write the whole email in that language. " +
            "Return JSON: {\"subject\": string (under 80 characters), \"body\": string (plain text; paragraphs separated by blank lines; no HTML)}.";

        private static async Task<(string subject, string body)> DraftAsync(string cs, RunContext ctx, string instruction)
        {
            string endpoint = (Environment.GetEnvironmentVariable("AZURE_OPENAI_ENDPOINT") ?? "").TrimEnd('/');
            string key = Environment.GetEnvironmentVariable("AZURE_OPENAI_KEY") ?? "";
            string deployment = Environment.GetEnvironmentVariable("AZURE_OPENAI_DEPLOYMENT") ?? "runs-page";
            if (endpoint.Length == 0 || key.Length == 0) throw new InvalidOperationException("AZURE_OPENAI_ENDPOINT / AZURE_OPENAI_KEY are not set");

            var facts = new StringBuilder();
            facts.AppendLine($"Club: {ctx.KennelName} ({ctx.KennelShortName})");
            facts.AppendLine($"Run: {ctx.Title}");
            facts.AppendLine($"When: {ctx.When}");
            if (ctx.Where.Length > 0) facts.AppendLine($"Where: {ctx.Where}");
            if (ctx.Hares.Length > 0) facts.AppendLine($"Hares: {ctx.Hares}");
            if (ctx.Price.Length > 0) facts.AppendLine($"Price: {ctx.Price}");
            if (ctx.Description.Length > 0) facts.AppendLine($"Notes from the organiser: {Truncate(ctx.Description, 1200)}");
            facts.AppendLine($"Sender: {ctx.SenderName}");
            if (instruction.Length > 0) facts.AppendLine($"\nInstruction from the sender: {instruction}");

            var payload = new JObject
            {
                ["messages"] = new JArray(
                    new JObject { ["role"] = "system", ["content"] = SystemPrompt },
                    new JObject { ["role"] = "user", ["content"] = facts.ToString() }),
                ["temperature"] = 0.7,
                ["max_tokens"] = 1200,
                ["response_format"] = new JObject
                {
                    ["type"] = "json_schema",
                    ["json_schema"] = new JObject
                    {
                        ["name"] = "run_email", ["strict"] = true,
                        ["schema"] = JObject.Parse("{\"type\":\"object\",\"additionalProperties\":false,\"required\":[\"subject\",\"body\"],\"properties\":{\"subject\":{\"type\":\"string\"},\"body\":{\"type\":\"string\"}}}"),
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
            await LogAiUsageAsync(cs, ctx.KennelId, deployment, res.IsSuccessStatusCode ? "ok" : $"http_{(int)res.StatusCode}", pt, ct, clock.ElapsedMilliseconds);
            if (!res.IsSuccessStatusCode) throw new InvalidOperationException($"Azure OpenAI {(int)res.StatusCode}: {Truncate(text, 300)}");

            string content = j["choices"]?[0]?["message"]?["content"]?.ToString() ?? throw new InvalidOperationException("no content");
            var o = JObject.Parse(content);
            string subject = (o.Value<string>("subject") ?? ctx.Title).Trim();
            string prose = StripSignOff((o.Value<string>("body") ?? "").Trim(), ctx.SenderName);
            if (prose.Length == 0) throw new InvalidOperationException("empty draft");
            return (subject.Length > MaxSubject ? subject[..MaxSubject] : subject, prose.Length > MaxBody ? prose[..MaxBody] : prose);
        }

        private static async Task LogAiUsageAsync(string cs, Guid kennelId, string model, string outcome, int pt, int ct, long ms)
        {
            // Same table and prices as the runs-page import, so the AI monitor sees it.
            decimal perMIn = decimal.TryParse(Environment.GetEnvironmentVariable("AZURE_OPENAI_USD_PER_M_IN"), NumberStyles.Number, CultureInfo.InvariantCulture, out decimal pi) ? pi : 0.15m;
            decimal perMOut = decimal.TryParse(Environment.GetEnvironmentVariable("AZURE_OPENAI_USD_PER_M_OUT"), NumberStyles.Number, CultureInfo.InvariantCulture, out decimal po) ? po : 0.60m;
            try
            {
                using var conn = new SqlConnection(cs);
                await conn.OpenAsync();
                using var cmd = new SqlCommand("HC6.nonApi_logAiUsage", conn) { CommandType = CommandType.StoredProcedure };
                cmd.Parameters.Add("@sessionId", SqlDbType.UniqueIdentifier).Value = Guid.NewGuid();
                cmd.Parameters.Add("@feature", SqlDbType.NVarChar, -1).Value = "run-email";
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
            catch { /* bookkeeping never fails a draft */ }
        }

        // ── Assembly ───────────────────────────────────────────────────────────

        private static string Truncate(string s, int n) => s.Length <= n ? s : s[..n];

        private static readonly Regex SignOffLine = new(
            @"^\s*(on[\s-]*on|cheers|see you( there| on trail)?|à bientôt|a bientot|bis bald|hasta pronto|regards|best|thanks|merci|salut)[\s!,.]*$",
            RegexOptions.IgnoreCase | RegexOptions.CultureInvariant);

        /// <summary>
        /// Removes a trailing sign-off from the prose — "On on," / "Cheers" and
        /// the sender's name on their own lines — because the layout always adds
        /// "On on, &lt;sender&gt;" after the text. The model was told not to sign off
        /// and did anyway (2026-10-09: "On on, Opee" twice), and a sender may type
        /// one by habit; a duplicate is worse than a stripped one. Only the TAIL is
        /// touched, one short line at a time, and only lines that are nothing but a
        /// sign-off or the name.
        /// </summary>
        public static string StripSignOff(string prose, string senderName)
        {
            var lines = prose.Replace("\r\n", "\n").Split('\n').ToList();
            string name = senderName.Trim();
            bool IsName(string l) => name.Length > 0 && l.Trim().TrimEnd('.', '!', ',').Equals(name, StringComparison.OrdinalIgnoreCase);
            int removed = 0;
            while (lines.Count > 0 && removed < 6)
            {
                string last = lines[^1].Trim();
                if (last.Length == 0 || IsName(last) || SignOffLine.IsMatch(last)) { lines.RemoveAt(lines.Count - 1); removed++; }
                else break;
            }
            return string.Join('\n', lines).Trim();
        }
        private static string H(string s) => WebUtility.HtmlEncode(s);

        /// <summary>Plain text → paragraphs. The prose is the sender's words, encoded, never raw HTML.</summary>
        private static string Paragraphs(string prose) =>
            string.Concat(Regex.Split(prose.Replace("\r\n", "\n"), @"\n\s*\n")
                .Select(p => p.Trim()).Where(p => p.Length > 0)
                .Select(p => $"<p style=\"margin:0 0 14px\">{H(p).Replace("\n", "<br>")}</p>"));

        /// <summary>
        /// The whole email: the sender's prose, then the facts block that code
        /// built, then the kennel line, inside the shared layout — plus this
        /// recipient's unsubscribe line when one is given.
        /// </summary>
        public static string BuildHtml(RunContext ctx, string subject, string prose, string? unsubscribeUrl, string? requestedPrefsUrl = null)
        {
            string Row(string label, string value) => value.Length == 0 ? "" :
                $"<tr><td style=\"padding:6px 10px 6px 0;color:#6b7785;white-space:nowrap;vertical-align:top\">{label}</td><td style=\"padding:6px 0;vertical-align:top\">{H(value)}</td></tr>";
            string Button(string href, string text, string bg) =>
                $"<a href=\"{href}\" style=\"display:inline-block;margin:6px 6px 0 0;padding:10px 16px;background:{bg};color:#fff;text-decoration:none;border-radius:6px;font-weight:600\">{H(text)}</a>";

            var sb = new StringBuilder();
            // Moved into the send by an admin: say so at the very top, with the way out
            // directly under it (James, 2026-10-09). Everyone else gets the normal email.
            if (requestedPrefsUrl != null)
                sb.Append($"<p style=\"margin:0 0 4px;font-weight:700\">{H(ctx.SenderName)} has requested that you receive this email.</p>" +
                          $"<p style=\"margin:0 0 18px;font-size:13px\"><a href=\"{requestedPrefsUrl}\" style=\"color:#2b6cb0\">Your email preferences</a> — stop emails from {H(ctx.KennelShortName)}, or block all email from Harrier Central.</p>");
            sb.Append(Paragraphs(prose));
            sb.Append($"<p style=\"margin:0 0 18px\">On on,<br>{H(ctx.SenderName)}<br><span style=\"color:#6b7785\">{H(ctx.KennelName)}</span></p>");
            sb.Append("<table role=\"presentation\" cellpadding=\"0\" cellspacing=\"0\" style=\"width:100%;background:#f4f6f8;border-radius:8px;padding:14px 16px;font-size:15px\"><tr><td>");
            sb.Append($"<div style=\"font-weight:700;font-size:17px;margin-bottom:6px\">{H(ctx.Title)}</div>");
            sb.Append("<table role=\"presentation\" cellpadding=\"0\" cellspacing=\"0\">");
            sb.Append(Row("When", ctx.When)).Append(Row("Where", ctx.Where)).Append(Row("Hares", ctx.Hares)).Append(Row("Price", ctx.Price));
            sb.Append("</table><div style=\"margin-top:10px\">");
            // Text glyphs, not emoji: an emoji keeps its own colour (a red ✕ on the red
            // button, 2026-10-09), a glyph takes the button's white.
            sb.Append(Button(ctx.RsvpUrl(true), "✓ I'm in", "#2f855a")).Append(Button(ctx.RsvpUrl(false), "✗ Can't make it", "#9b2c2c")).Append(Button(ctx.Url, "Open the run", "#2b6cb0"));
            sb.Append("</div></td></tr></table>");
            if (unsubscribeUrl != null)
                sb.Append($"<p style=\"margin:18px 0 0;font-size:12px;color:#6b7785\">You get run emails because you switched them on for {H(ctx.KennelName)} in Harrier Central. " +
                          $"<a href=\"{unsubscribeUrl}\" style=\"color:#6b7785\">Stop run emails from {H(ctx.KennelShortName)}</a>, or change it per run or per kennel in the app.</p>");
            return HcEmail.Layout(subject, sb.ToString());
        }

        private static string PlainText(RunContext ctx, string prose)
        {
            var sb = new StringBuilder(prose).Append("\n\nOn on,\n").Append(ctx.SenderName).Append('\n').Append(ctx.KennelName).Append("\n\n");
            sb.Append(ctx.Title).Append('\n').Append("When: ").Append(ctx.When).Append('\n');
            if (ctx.Where.Length > 0) sb.Append("Where: ").Append(ctx.Where).Append('\n');
            if (ctx.Hares.Length > 0) sb.Append("Hares: ").Append(ctx.Hares).Append('\n');
            if (ctx.Price.Length > 0) sb.Append("Price: ").Append(ctx.Price).Append('\n');
            sb.Append("I'm in: ").Append(ctx.RsvpUrl(true)).Append('\n').Append("Can't make it: ").Append(ctx.RsvpUrl(false)).Append('\n').Append("Open the run: ").Append(ctx.Url);
            return sb.ToString();
        }
    }
}
