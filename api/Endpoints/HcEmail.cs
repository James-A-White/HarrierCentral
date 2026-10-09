using System.Data;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using Microsoft.Data.SqlClient;

namespace HcWebApi.Endpoints
{
    /// <summary>A file sent with an email. The name is what the recipient sees.</summary>
    public sealed record EmailAttachment(string FileName, string ContentType, byte[] Content)
    {
        public const string Xlsx = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";

        /// <summary>An Excel attachment named "<paramref name="title"/>.xlsx", made safe for every mail client.</summary>
        public static EmailAttachment Excel(string title, byte[] content)
        {
            var safe = new StringBuilder();
            foreach (char c in title)
                safe.Append(Path.GetInvalidFileNameChars().Contains(c) || c is '#' or '%' ? '-' : c);
            string name = safe.ToString().Trim();
            return new EmailAttachment((name.Length > 0 ? name : "report") + ".xlsx", Xlsx, content);
        }
    }

    /// <summary>Thrown when an email could not be handed to the mail service. Already logged.</summary>
    public sealed class EmailSendException(string message, Exception? inner = null) : Exception(message, inner);

    /// <summary>
    /// The one way the API sends email (E18). Every message goes out as
    /// noreply@harriercentral.com, DKIM-signed by Microsoft 365. There is no
    /// Reply-To: a reply lands in the noreply@ shared mailbox, which James reads
    /// (his choice, 2026-10-09).
    ///
    /// Why it exists: until 2026-10-08 every endpoint posted to a Logic App that
    /// sent through an Outlook.com connector as gd@jamesawhite.com. That domain
    /// publishes DMARC p=reject and only authorises iCloud, so Gmail, Proton and
    /// GMX dropped every Harrier Central email without a word, invite codes
    /// included, while the Logic App recorded "Succeeded". CERN H3 could not sign
    /// in. And when the Logic App's send DID fail, it answered HTTP 200 with the
    /// body "Failed", so a failure looked like a send.
    ///
    /// Transport: Microsoft Graph sendMail (application permission Mail.Send),
    /// when HC_GRAPH_TENANT_ID / HC_GRAPH_CLIENT_ID / HC_GRAPH_CLIENT_SECRET /
    /// HC_GRAPH_MAILBOX are set. HC_GRAPH_MAILBOX is the noreply@ SHARED mailbox:
    /// Graph app-only ignores an alias in "from" and sends as the mailbox's
    /// primary address, so the sending address must be a mailbox of its own.
    /// The app is authorised by Exchange RBAC for Applications scoped to that one
    /// mailbox, not by a tenant-wide Mail.Send grant. Graph answers 202 or a real error, so a failure
    /// is a failure. Until they are set it falls back to the Logic App, now
    /// reading its answer — so this can ship before the Graph setup is finished.
    ///
    /// Every failure is written to HC.ErrorLog (ProcName 'HcEmail', the caller in
    /// the description, the recipient's DOMAIN only) and then thrown as
    /// <see cref="EmailSendException"/>, so callers keep their own handling.
    /// </summary>
    public static class HcEmail
    {
        private static readonly HttpClient http = new() { Timeout = TimeSpan.FromSeconds(30) };

        private static string? Env(string name) =>
            Environment.GetEnvironmentVariable(name) is { Length: > 0 } v ? v : null;

        /// <summary>The address every email is from. An alias of <see cref="GraphMailbox"/>; the
        /// tenant must have SendFromAliasEnabled, or Exchange substitutes the mailbox's primary address.</summary>
        public static string From => Env("HC_EMAIL_FROM") ?? "noreply@harriercentral.com";

        public const string FromName = "Harrier Central";

        private static string? TenantId => Env("HC_GRAPH_TENANT_ID");
        private static string? ClientId => Env("HC_GRAPH_CLIENT_ID");
        private static string? ClientSecret => Env("HC_GRAPH_CLIENT_SECRET");

        /// <summary>The licensed (or shared) mailbox Graph sends from, by its user principal name.</summary>
        private static string? GraphMailbox => Env("HC_GRAPH_MAILBOX");

        public static bool UsesGraph =>
            TenantId != null && ClientId != null && ClientSecret != null && GraphMailbox != null;

        /// <summary>
        /// Sends one email. <paramref name="source"/> names the feature for the error
        /// log ("EmailInviteCode", "SendPaymentReport", …).
        /// </summary>
        public static async Task SendAsync(string source, string to, string subject, string html,
            EmailAttachment? attachment = null)
        {
            if (string.IsNullOrWhiteSpace(to) || string.IsNullOrWhiteSpace(subject) || string.IsNullOrWhiteSpace(html))
                throw new ArgumentException("to, subject and html must all be non-empty.");

            string via = UsesGraph ? "graph" : "logic-app";
            try
            {
                if (UsesGraph) await SendViaGraphAsync(to, subject, html, attachment);
                else await SendViaLogicAppAsync(to, subject, html, attachment);
            }
            catch (Exception ex)
            {
                await LogFailureAsync(source, to, via, ex.Message);
                throw new EmailSendException($"{source}: email via {via} failed: {ex.Message}", ex);
            }
        }

        // ── Microsoft Graph ────────────────────────────────────────────────────

        private static string? _token;
        private static DateTimeOffset _tokenExpires = DateTimeOffset.MinValue;
        private static readonly SemaphoreSlim tokenLock = new(1, 1);

        /// <summary>An app-only token for Graph, cached until five minutes before it expires.</summary>
        private static async Task<string> GraphTokenAsync()
        {
            if (_token != null && DateTimeOffset.UtcNow < _tokenExpires) return _token;
            await tokenLock.WaitAsync();
            try
            {
                if (_token != null && DateTimeOffset.UtcNow < _tokenExpires) return _token;
                using var form = new FormUrlEncodedContent(new Dictionary<string, string>
                {
                    ["client_id"] = ClientId!,
                    ["client_secret"] = ClientSecret!,
                    ["scope"] = "https://graph.microsoft.com/.default",
                    ["grant_type"] = "client_credentials",
                });
                using var resp = await http.PostAsync(
                    $"https://login.microsoftonline.com/{TenantId}/oauth2/v2.0/token", form);
                string text = await resp.Content.ReadAsStringAsync();
                if (!resp.IsSuccessStatusCode)
                    throw new InvalidOperationException($"token request {(int)resp.StatusCode}: {Trim(text)}");
                using var doc = JsonDocument.Parse(text);
                _token = doc.RootElement.GetProperty("access_token").GetString();
                int seconds = doc.RootElement.TryGetProperty("expires_in", out var e) ? e.GetInt32() : 3599;
                _tokenExpires = DateTimeOffset.UtcNow.AddSeconds(seconds - 300);
                return _token!;
            }
            finally { tokenLock.Release(); }
        }

        private static async Task SendViaGraphAsync(string to, string subject, string html, EmailAttachment? attachment)
        {
            static object Address(string address, string? name = null) =>
                new { emailAddress = name == null ? (object)new { address } : new { address, name } };

            var message = new Dictionary<string, object>
            {
                ["subject"] = subject,
                ["body"] = new { contentType = "HTML", content = html },
                ["from"] = Address(From, FromName),
                ["toRecipients"] = new[] { Address(to) },
            };
            if (attachment != null)
            {
                message["attachments"] = new[]
                {
                    new Dictionary<string, object>
                    {
                        ["@odata.type"] = "#microsoft.graph.fileAttachment",
                        ["name"] = attachment.FileName,
                        ["contentType"] = attachment.ContentType,
                        ["contentBytes"] = Convert.ToBase64String(attachment.Content),
                    },
                };
            }

            string json = JsonSerializer.Serialize(new { message, saveToSentItems = false });
            using var req = new HttpRequestMessage(HttpMethod.Post,
                $"https://graph.microsoft.com/v1.0/users/{Uri.EscapeDataString(GraphMailbox!)}/sendMail")
            {
                Content = new StringContent(json, Encoding.UTF8, "application/json"),
            };
            req.Headers.Authorization = new AuthenticationHeaderValue("Bearer", await GraphTokenAsync());
            using var resp = await http.SendAsync(req);
            if (!resp.IsSuccessStatusCode)   // Graph answers 202 Accepted
                throw new InvalidOperationException(
                    $"Graph sendMail {(int)resp.StatusCode}: {Trim(await resp.Content.ReadAsStringAsync())}");
        }

        // ── Logic App (legacy, until the Graph settings exist) ──────────────────

        /// <summary>
        /// The SendEmail Logic App's HTTP trigger. Read from HC_EMAIL_LOGIC_APP_URL;
        /// the literal fallback is public in the repo (E18.F1.S4) and goes when
        /// Graph is live.
        /// </summary>
        private static string LogicAppUrl =>
            Env("HC_EMAIL_LOGIC_APP_URL")
            ?? "https://prod-46.northeurope.logic.azure.com:443/workflows/ea2b7fd09a8d407fa58ab04b64638217/triggers/When_a_HTTP_request_is_received/paths/invoke?api-version=2016-10-01&sp=%2Ftriggers%2FWhen_a_HTTP_request_is_received%2Frun&sv=1.0&sig=aqjP-q4tvhj-S9aemqQKFGP5ZQYBWOBFTL_KSUvcVl8";

        private static async Task SendViaLogicAppAsync(string to, string subject, string html, EmailAttachment? attachment)
        {
            var payload = new
            {
                from = From,   // the Outlook connector ignores it, but the trigger schema has it
                to,
                subject,
                body = html,
                attachment = attachment == null ? null : new
                {
                    filename = attachment.FileName,
                    contentType = attachment.ContentType,
                    contentBytes = Convert.ToBase64String(attachment.Content),
                },
            };
            using var content = new StringContent(JsonSerializer.Serialize(payload), Encoding.UTF8, "application/json");
            using var resp = await http.PostAsync(LogicAppUrl, content);
            string text = (await resp.Content.ReadAsStringAsync()).Trim().Trim('"');
            // The Logic App answers 200 "Success" — or 200 "Failed" when its send
            // action failed. Only "Success" is a send.
            if (!resp.IsSuccessStatusCode || !text.Equals("Success", StringComparison.OrdinalIgnoreCase))
                throw new InvalidOperationException($"Logic App {(int)resp.StatusCode}: {Trim(text)}");
        }

        // ── Error log ──────────────────────────────────────────────────────────

        private static string Trim(string s) => s.Length <= 500 ? s : s[..500];

        /// <summary>The part after the @ — enough to see "every Gmail failed" without storing addresses.</summary>
        private static string DomainOf(string address) =>
            address.LastIndexOf('@') is int at and >= 0 ? address[(at + 1)..].ToLowerInvariant() : "?";

        private static async Task LogFailureAsync(string source, string to, string via, string message)
        {
            string? cs = Env("HcDbConnectionString");
            if (cs == null) return;
            try
            {
                using var conn = new SqlConnection(cs);
                await conn.OpenAsync();
                using var cmd = new SqlCommand(
                    "INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId) " +
                    "VALUES (NEWID(), '<api>', @n, @d, 'HcEmail', NULL);", conn);
                cmd.Parameters.Add("@n", SqlDbType.NVarChar, 200).Value = $"Email send failed ({source})";
                cmd.Parameters.Add("@d", SqlDbType.NVarChar, -1).Value =
                    $"to *@{DomainOf(to)} via {via}: {message}";
                await cmd.ExecuteNonQueryAsync();
            }
            catch { /* logging a failed email must never be what fails the request */ }
        }
    }
}
