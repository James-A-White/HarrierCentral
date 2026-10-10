using System.Linq;
using System.Data;
using System.Security.Cryptography;
using System.Text;
using Azure;
using Azure.Communication.Email;
using Microsoft.Data.SqlClient;

namespace HcWebApi.Endpoints
{
    /// <summary>
    /// Mail to lists (E19.F3): run emails and announcements, sent through Azure
    /// Communication Services as runs@harriercentral.com — a different service
    /// and a different address from the noreply@ invite codes in
    /// <see cref="HcEmail"/>, so a spam report about a run email can never stop
    /// a code arriving. ACS lets us set the one-click List-Unsubscribe headers
    /// (RFC 8058) that Gmail expects of list mail and that Graph's JSON route
    /// cannot carry.
    ///
    /// Every list email is personal — one message per recipient — because the
    /// unsubscribe link in it is that recipient's own signed token.
    ///
    /// Settings: HC_ACS_EMAIL_CONNECTION, HC_ACS_EMAIL_FROM (default
    /// runs@harriercentral.com), HC_INTERNAL_SECRET (signs unsubscribe tokens).
    /// </summary>
    public static class HcListMail
    {
        private static string? Env(string name) =>
            Environment.GetEnvironmentVariable(name) is { Length: > 0 } v ? v : null;

        public static string From => Env("HC_ACS_EMAIL_FROM") ?? "runs@harriercentral.com";
        public const string FromName = "Harrier Central";
        public static bool IsConfigured => Env("HC_ACS_EMAIL_CONNECTION") != null && Env("HC_INTERNAL_SECRET") != null;

        private static readonly Lazy<EmailClient> client = new(() =>
            new EmailClient(Env("HC_ACS_EMAIL_CONNECTION")
                ?? throw new InvalidOperationException("HC_ACS_EMAIL_CONNECTION is not set")));

        /// <summary>The API's own public base, for links in the mail.</summary>
        public static string ApiBase => Env("HC_API_PUBLIC_URL") ?? "https://harriercentralpublicapi.azurewebsites.net";

        /// <summary>
        /// Hands one email to ACS and returns once ACS has ACCEPTED it (not once it
        /// is delivered — that can take minutes and the caller does not wait).
        /// Throws on refusal; the caller logs.
        /// </summary>
        public static async Task SendAsync(string to, string subject, string html, string plainText, string? unsubscribeUrl, string? kennelSlug = null, string? kennelShortName = null)
        {
            var content = new EmailContent(subject) { Html = html, PlainText = plainText };
            // The inbox shows the sender's DISPLAY NAME, and ACS keeps that on the
            // sender username, not in the address (a name in the address is a 400).
            // So each kennel gets its own username — runs-<slug>@ with the display
            // name "<KENNEL> via Harrier Central" (tools/acs_kennel_senders.py) — and a
            // run email goes out from it (James, 2026-10-10). A kennel that has no
            // username yet is refused with "senderAddress" and falls back to runs@,
            // so a new kennel's email still goes, just from us.
            string? kennelFrom = KennelSender(kennelSlug);
            try
            {
                if (kennelFrom != null)
                {
                    await client.Value.SendAsync(WaitUntil.Started, Build(kennelFrom, to, content, unsubscribeUrl));
                    return;
                }
            }
            catch (Azure.RequestFailedException ex) when (ex.Status == 400 && ex.Message.Contains("senderAddress", StringComparison.OrdinalIgnoreCase))
            {
                // No sender username for this kennel: fall through to runs@ for THIS
                // email, and make the username now so the next one is the kennel's.
                _ = EnsureKennelSenderAsync(kennelSlug!, kennelShortName);
            }
            await client.Value.SendAsync(WaitUntil.Started, Build(From, to, content, unsubscribeUrl));
        }

        /// <summary>
        /// Creates the kennel's sender username — runs-&lt;slug&gt; with display name
        /// "&lt;KENNEL&gt; via Harrier Central" — on the ACS email domain, through ARM
        /// with the Function App's identity (Contributor on the email service only;
        /// setting HC_ACS_EMAIL_SERVICE_ID is the service's resource id). A new
        /// kennel therefore names itself from its second email on; the bulk script
        /// tools/acs_kennel_senders.py does the same for every kennel at once. A
        /// failure is logged and changes nothing — runs@ keeps working.
        /// </summary>
        public static async Task EnsureKennelSenderAsync(string kennelSlug, string? kennelShortName)
        {
            string? from = KennelSender(kennelSlug);
            string? service = Env("HC_ACS_EMAIL_SERVICE_ID");
            if (from == null || string.IsNullOrEmpty(service)) return;
            string local = from[..from.IndexOf('@')];
            string domain = from[(from.IndexOf('@') + 1)..];
            string name = new string((string.IsNullOrWhiteSpace(kennelShortName) ? kennelSlug : kennelShortName)
                .Where(c => c != '<' && c != '>' && c != '"' && c != '\r' && c != '\n').ToArray()).Trim();
            try
            {
                string token = await AzureDailyCost.ManagedIdentityTokenAsync("https://management.azure.com/");
                using var req = new HttpRequestMessage(HttpMethod.Put,
                    $"https://management.azure.com{service}/domains/{domain}/senderUsernames/{local}?api-version=2023-04-01");
                req.Headers.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", token);
                req.Content = new StringContent(
                    Newtonsoft.Json.JsonConvert.SerializeObject(new { properties = new { username = local, displayName = $"{name} via Harrier Central" } }),
                    System.Text.Encoding.UTF8, "application/json");
                using var res = await Arm.SendAsync(req);
                if (!res.IsSuccessStatusCode)
                {
                    string text = await res.Content.ReadAsStringAsync();
                    await LogFailureAsync("AcsKennelSender", from, $"ARM {(int)res.StatusCode}: {text[..Math.Min(300, text.Length)]}", null);
                }
            }
            catch (Exception ex)
            {
                await LogFailureAsync("AcsKennelSender", from, ex.Message, null);
            }
        }

        private static readonly HttpClient Arm = new() { Timeout = TimeSpan.FromSeconds(30) };

        /// <summary>runs-&lt;slug&gt;@ on our domain, or null when the slug cannot make an address.</summary>
        public static string? KennelSender(string? kennelSlug)
        {
            if (string.IsNullOrWhiteSpace(kennelSlug)) return null;
            string local = new string(kennelSlug.ToLowerInvariant().Where(c => char.IsAsciiLetterOrDigit(c) || c == '-').ToArray()).Trim('-');
            int at = From.IndexOf('@');
            return local.Length == 0 || at < 0 ? null : $"runs-{local}{From[at..]}";
        }

        private static EmailMessage Build(string from, string to, EmailContent content, string? unsubscribeUrl)
        {
            var message = new EmailMessage(from, new EmailRecipients(new[] { new EmailAddress(to) }), content);
            if (unsubscribeUrl != null)
            {
                message.Headers["List-Unsubscribe"] = $"<{unsubscribeUrl}>";
                message.Headers["List-Unsubscribe-Post"] = "List-Unsubscribe=One-Click";
            }
            return message;
        }

        // ── Unsubscribe tokens ─────────────────────────────────────────────────

        /// <summary>
        /// The link in every list email: hasher + kennel + expiry, signed with the
        /// server secret, so one tap with no sign-in can only ever switch off THAT
        /// hasher's emails from THAT kennel. Valid for a year — people act on old
        /// emails.
        /// </summary>
        public static string UnsubscribeUrl(Guid hasherId, Guid kennelId)
        {
            long exp = DateTimeOffset.UtcNow.AddDays(365).ToUnixTimeSeconds();
            string sig = Sign($"{hasherId:D}|{kennelId:D}|{exp}");
            return $"{ApiBase}/api/EmailUnsubscribe?h={hasherId:D}&k={kennelId:D}&e={exp}&s={sig}";
        }

        /// <summary>The email-preferences page: the same signed token, shown as choices
        /// rather than acted on at once (do=prefs).</summary>
        public static string PreferencesUrl(Guid hasherId, Guid kennelId) => UnsubscribeUrl(hasherId, kennelId) + "&do=prefs";

        /// <summary>True when the signature matches and the token has not expired.</summary>
        public static bool VerifyUnsubscribe(string? h, string? k, string? e, string? s)
        {
            if (!Guid.TryParse(h, out Guid hasherId) || !Guid.TryParse(k, out Guid kennelId)
                || !long.TryParse(e, out long exp) || string.IsNullOrEmpty(s)) return false;
            if (DateTimeOffset.UtcNow.ToUnixTimeSeconds() > exp) return false;
            byte[] expected = Encoding.ASCII.GetBytes(Sign($"{hasherId:D}|{kennelId:D}|{exp}"));
            byte[] given = Encoding.ASCII.GetBytes(s);
            return expected.Length == given.Length && CryptographicOperations.FixedTimeEquals(expected, given);
        }

        private static string Sign(string payload)
        {
            string secret = Env("HC_INTERNAL_SECRET") ?? throw new InvalidOperationException("HC_INTERNAL_SECRET is not set");
            using var mac = new HMACSHA256(Encoding.UTF8.GetBytes(secret));
            return Convert.ToBase64String(mac.ComputeHash(Encoding.UTF8.GetBytes(payload)))
                .TrimEnd('=').Replace('+', '-').Replace('/', '_');
        }

        // ── Error log ──────────────────────────────────────────────────────────

        public static async Task LogFailureAsync(string source, string to, string message, Guid? eventId = null)
        {
            string? cs = Env("HcDbConnectionString");
            if (cs == null) return;
            try
            {
                using var conn = new SqlConnection(cs);
                await conn.OpenAsync();
                using var cmd = new SqlCommand(
                    "INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, eventId) " +
                    "VALUES (NEWID(), '<api>', @n, @d, 'HcListMail', NULL, @e);", conn);
                cmd.Parameters.Add("@n", SqlDbType.NVarChar, 200).Value = $"List email failed ({source})";
                int at = to.LastIndexOf('@');
                cmd.Parameters.Add("@d", SqlDbType.NVarChar, -1).Value =
                    $"to *@{(at >= 0 ? to[(at + 1)..].ToLowerInvariant() : "?")} via acs: {(message.Length > 500 ? message[..500] : message)}";
                cmd.Parameters.Add("@e", SqlDbType.UniqueIdentifier).Value = (object?)eventId ?? DBNull.Value;
                await cmd.ExecuteNonQueryAsync();
            }
            catch { /* best effort */ }
        }
    }
}
