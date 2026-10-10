using System.Data;
using System.Net;
using System.Text;
using System.Text.RegularExpressions;
using DnsClient;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json.Linq;

namespace HcWebApi.Endpoints
{
    /// <summary>
    /// "Email invite codes" on the portal's Members page (E2.F2.S6, James
    /// 2026-10-10): each hasher gets their own invite code, from "&lt;KENNEL&gt;
    /// via Harrier Central", on the jungle with the kennel's logo.
    ///
    /// Who: 'imported' (the publicHasherIds the last import added) or
    /// 'neverLoggedIn' (everyone in the kennel who has never signed in) —
    /// the list and the codes come from hcportal_getInviteEmailList, under the
    /// admin's own portal token, and never reach the browser.
    ///
    /// Skipped, and counted: a placeholder or malformed address; a domain that
    /// cannot receive mail (no MX and no A record — catches made-up domains);
    /// anyone invited in the last 7 days (HC.Hasher.InviteEmailedAt); no code.
    ///
    /// Request: POST JSON { deviceId, accessToken (minted for
    ///   hcportal_getInviteEmailList), publicKennelId, scope,
    ///   publicHasherIds: [...], send: false | true }
    /// send = false: the counts only, for the confirm dialog.
    /// send = true: sends, stamps InviteEmailedAt for those sent, and keeps an
    ///   audit copy with the codes masked.
    /// Reply: 200 { toSend, sent, skippedRecent, skippedNoEmail,
    ///   skippedUndeliverable, skippedNoCode, stoppedEarly } or 4xx { errorUserMessage }.
    /// </summary>
    public class InviteEmails
    {
        private readonly ILogger<InviteEmails> _log;
        public InviteEmails(ILogger<InviteEmails> log) { _log = log; }

        private static readonly Regex EmailRx = new(@"^[^@\s]+@[^@\s]+\.[^@\s]{2,}$", RegexOptions.Compiled);
        private static readonly TimeSpan RecentWindow = TimeSpan.FromDays(7);
        private static readonly LookupClient Dns = new(new LookupClientOptions { Timeout = TimeSpan.FromSeconds(4), Retries = 1, UseCache = true });

        private sealed record Recipient(Guid HasherId, string FirstName, string HashName, string Email, string? Code, DateTimeOffset? InvitedAt, bool Placeholder);

        [Function("InviteEmails")]
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
            string scope = body.Value<string>("scope") ?? "";
            bool send = body.Value<bool?>("send") == true;
            string ids = string.Join('|', (body["publicHasherIds"] as JArray ?? new JArray()).Select(t => t.ToString()));

            // ── Who, and their codes ─────────────────────────────────────────
            JObject kennel;
            var people = new List<Recipient>();
            using (var conn = new SqlConnection(cs))
            {
                await conn.OpenAsync();
                using var cmd = new SqlCommand("[HC6].[hcportal_getInviteEmailList]", conn) { CommandType = CommandType.StoredProcedure, CommandTimeout = 120 };
                cmd.Parameters.Add("@deviceId", SqlDbType.UniqueIdentifier).Value = deviceId;
                cmd.Parameters.Add("@accessToken", SqlDbType.NVarChar, 1000).Value = body.Value<string>("accessToken")!;
                cmd.Parameters.Add("@publicKennelId", SqlDbType.UniqueIdentifier).Value = publicKennelId;
                cmd.Parameters.Add("@scope", SqlDbType.NVarChar, 20).Value = scope;
                cmd.Parameters.Add("@publicHasherIds", SqlDbType.NVarChar, -1).Value = ids;
                using var r = await cmd.ExecuteReaderAsync();
                if (!await r.ReadAsync()) return Bad("Please try again.");
                if (Convert.ToInt32(r["Success"]) != 1) return new ObjectResult(new { errorUserMessage = r["ErrorMessage"] as string ?? "Not allowed." }) { StatusCode = 403 };
                kennel = new JObject
                {
                    ["kennelId"] = r["kennelId"] as string, ["kennelName"] = r["kennelName"] as string,
                    ["kennelShortName"] = r["kennelShortName"] as string, ["kennelSlug"] = r["kennelSlug"] as string,
                    ["kennelLogo"] = r["kennelLogo"] as string, ["adminId"] = r["adminId"] as string,
                };
                if (await r.NextResultAsync())
                    while (await r.ReadAsync())
                        people.Add(new Recipient(
                            Guid.Parse((string)r["hasherId"]), r["firstName"] as string ?? "", r["hashName"] as string ?? "",
                            (r["email"] as string ?? "").Trim(), r["inviteCode"] as string,
                            r["inviteEmailedAt"] is DBNull ? null : (DateTimeOffset)r["inviteEmailedAt"],
                            Convert.ToInt32(r["isPlaceholder"]) == 1));
            }

            // ── Sort them ────────────────────────────────────────────────────
            var toSend = new List<Recipient>();
            int recent = 0, noEmail = 0, undeliverable = 0, noCode = 0;
            var domainOk = new Dictionary<string, bool>(StringComparer.OrdinalIgnoreCase);
            foreach (var p in people)
            {
                if (p.Placeholder || !EmailRx.IsMatch(p.Email)) { noEmail++; continue; }
                if (p.InvitedAt is DateTimeOffset at && DateTimeOffset.UtcNow - at < RecentWindow) { recent++; continue; }
                if (string.IsNullOrEmpty(p.Code)) { noCode++; continue; }
                string domain = p.Email[(p.Email.LastIndexOf('@') + 1)..];
                if (!domainOk.TryGetValue(domain, out bool ok)) domainOk[domain] = ok = await CanReceiveMailAsync(domain);
                if (!ok) { undeliverable++; continue; }
                toSend.Add(p);
            }

            if (!send)
                return new OkObjectResult(new { toSend = toSend.Count, sent = 0, skippedRecent = recent, skippedNoEmail = noEmail, skippedUndeliverable = undeliverable, skippedNoCode = noCode, stoppedEarly = false });

            // ── Send ─────────────────────────────────────────────────────────
            string kennelName = kennel.Value<string>("kennelName") ?? "Your kennel";
            string shortName = kennel.Value<string>("kennelShortName") ?? kennelName;
            string slug = kennel.Value<string>("kennelSlug") ?? "";
            string logo = await HcEmail.EmailLogoAsync(kennel.Value<string>("kennelLogo"));
            string subject = $"{kennelName} has set you up on Harrier Central";
            var sentIds = new List<Guid>();
            bool stoppedEarly = false;
            foreach (var p in toSend)
            {
                try
                {
                    string greet = p.HashName.Length > 0 ? p.HashName : p.FirstName.Length > 0 ? p.FirstName : "there";
                    await HcListMail.SendAsync(p.Email, subject, Html(kennelName, greet, p.Code!, logo), Plain(kennelName, greet, p.Code!), null, slug, shortName);
                    sentIds.Add(p.HasherId);
                }
                catch (Azure.RequestFailedException ex) when (ex.Status == 429)
                {
                    // The sending quota: stop here. Nobody unsent is stamped, so the
                    // next press picks up exactly where this one stopped.
                    stoppedEarly = true;
                    break;
                }
                catch (Exception ex)
                {
                    await HcListMail.LogFailureAsync("InviteEmails", p.Email, ex.Message);
                }
            }

            await RecordAsync(cs, kennel, sentIds);
            await EmailAudit.WriteAsync(new EmailAudit.Record
            {
                Kind = "invite",
                KennelId = Guid.TryParse(kennel.Value<string>("kennelId"), out Guid kid) ? kid : null,
                Kennel = kennelName,
                SenderId = Guid.TryParse(kennel.Value<string>("adminId"), out Guid aid) ? aid : null,
                Subject = subject,
                // Codes are keys to accounts: the audit copy shows the template, masked.
                Html = Html(kennelName, "<name>", "••••••", logo),
                PlainText = Plain(kennelName, "<name>", "••••••"),
                Recipients = toSend.Where(p => sentIds.Contains(p.HasherId)).Select(p => (object)new { hasherId = p.HasherId, email = p.Email }).ToList(),
            });

            return new OkObjectResult(new { toSend = toSend.Count, sent = sentIds.Count, skippedRecent = recent, skippedNoEmail = noEmail, skippedUndeliverable = undeliverable, skippedNoCode = noCode, stoppedEarly });
        }

        private static ObjectResult Bad(string m) => new BadRequestObjectResult(new { errorUserMessage = m });

        /// <summary>True when the domain has an MX record, or failing that an A record (RFC 5321 fallback).</summary>
        private static async Task<bool> CanReceiveMailAsync(string domain)
        {
            try
            {
                var mx = await Dns.QueryAsync(domain, QueryType.MX);
                if (mx.Answers.MxRecords().Any()) return true;
                var a = await Dns.QueryAsync(domain, QueryType.A);
                return a.Answers.ARecords().Any();
            }
            catch
            {
                return true; // a DNS hiccup is not proof the address is bad
            }
        }

        private static async Task RecordAsync(string cs, JObject kennel, List<Guid> sent)
        {
            if (sent.Count == 0) return;
            try
            {
                using var conn = new SqlConnection(cs);
                await conn.OpenAsync();
                using var cmd = new SqlCommand("[HC6].[nonApi_recordInviteEmailed]", conn) { CommandType = CommandType.StoredProcedure };
                cmd.Parameters.Add("@kennelId", SqlDbType.UniqueIdentifier).Value = Guid.TryParse(kennel.Value<string>("kennelId"), out Guid k) ? k : DBNull.Value;
                cmd.Parameters.Add("@adminId", SqlDbType.UniqueIdentifier).Value = Guid.TryParse(kennel.Value<string>("adminId"), out Guid a) ? a : DBNull.Value;
                cmd.Parameters.Add("@hasherIds", SqlDbType.NVarChar, -1).Value = string.Join('|', sent);
                await cmd.ExecuteNonQueryAsync();
            }
            catch (Exception ex)
            {
                await HcListMail.LogFailureAsync("InviteEmails.record", "-", ex.Message);
            }
        }

        private static string H(string s) => WebUtility.HtmlEncode(s);

        public static string Html(string kennelName, string greet, string code, string logo)
        {
            string body =
                $"<p style=\"margin:0 0 14px\">Hello {H(greet)},</p>" +
                $"<p style=\"margin:0 0 14px\"><strong>{H(kennelName)}</strong> uses Harrier Central for its runs — where and when, who's coming, " +
                "your run count, the songbook and the circle — and has set up an account for you.</p>" +
                "<p style=\"margin:0 0 8px\">Your invite code:</p>" +
                $"<p style=\"margin:0 0 18px;font-size:30px;font-weight:700;letter-spacing:6px;font-family:Menlo,Consolas,monospace;color:#1f5a3a\">{H(code)}</p>" +
                "<ol style=\"margin:0 0 18px;padding-left:20px\">" +
                "<li style=\"margin:0 0 6px\">Get the Harrier Central app — " +
                "<a href=\"https://apps.apple.com/app/harrier-central/id1445513595\" style=\"color:#2b6cb0;font-weight:600\">iPhone &amp; iPad</a> or " +
                "<a href=\"https://play.google.com/store/apps/details?id=com.harriercentral.app\" style=\"color:#2b6cb0;font-weight:600\">Android</a>.</li>" +
                "<li style=\"margin:0 0 6px\">Open it and choose <strong>I have an invite code</strong>.</li>" +
                "<li style=\"margin:0 0 6px\">Enter the code above. Your runs with the kennel are already there.</li>" +
                "</ol>" +
                "<p style=\"margin:0;font-size:13px;color:#6b7785\">Keep the code: it is also how you get back into your account on a new phone. " +
                "Not a hasher, or not you? Ignore this email and nothing happens.</p>";
            return HcEmail.Layout($"{kennelName} has set you up on Harrier Central", body, logo, kennelName);
        }

        public static string Plain(string kennelName, string greet, string code) =>
            $"Hello {greet},\n\n{kennelName} uses Harrier Central for its runs and has set up an account for you.\n\n" +
            $"Your invite code: {code}\n\n" +
            "1. Get the Harrier Central app:\n   iPhone & iPad: https://apps.apple.com/app/harrier-central/id1445513595\n" +
            "   Android: https://play.google.com/store/apps/details?id=com.harriercentral.app\n" +
            "2. Open it and choose \"I have an invite code\".\n3. Enter the code above.\n\n" +
            "Keep the code: it is also how you get back into your account on a new phone. Not a hasher, or not you? Ignore this email.";
    }
}
