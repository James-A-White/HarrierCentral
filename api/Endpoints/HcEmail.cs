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
    /// The one way the API sends email (E19). Every message goes out as
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
    /// Transport: Microsoft Graph sendMail, configured by HC_GRAPH_TENANT_ID /
    /// HC_GRAPH_CLIENT_ID / HC_GRAPH_CLIENT_SECRET / HC_GRAPH_MAILBOX. The mailbox
    /// is the noreply@ SHARED mailbox: Graph app-only ignores an alias in "from"
    /// and sends as the mailbox's primary address, so the sending address must be
    /// a mailbox of its own. The app is authorised by Exchange RBAC for
    /// Applications scoped to that one mailbox, not by a tenant-wide Mail.Send
    /// grant. Graph answers 202 or a real error, so a failure is a failure.
    ///
    /// There is no fallback. The SendEmail Logic App this replaced was deleted
    /// (E19.F1.S4, 2026-10-09): its signed trigger URL was public in the repo, so
    /// anyone could send mail through it. Missing settings are an error, logged
    /// like any other failed send.
    ///
    /// Every email is wrapped in one layout (<see cref="Layout"/>, E19.F2.S2), so
    /// callers pass only their own content.
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

        /// <summary>The address every email is from: the primary address of <see cref="GraphMailbox"/>.</summary>
        public static string From => Env("HC_EMAIL_FROM") ?? "noreply@harriercentral.com";

        public const string FromName = "Harrier Central";

        private static string? TenantId => Env("HC_GRAPH_TENANT_ID");
        private static string? ClientId => Env("HC_GRAPH_CLIENT_ID");
        private static string? ClientSecret => Env("HC_GRAPH_CLIENT_SECRET");

        /// <summary>The shared mailbox Graph sends from, by its address (noreply@harriercentral.com).</summary>
        private static string? GraphMailbox => Env("HC_GRAPH_MAILBOX");

        public static bool IsConfigured =>
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

            const string via = "graph";
            try
            {
                if (!IsConfigured)
                    throw new InvalidOperationException(
                        "email is not configured: set HC_GRAPH_TENANT_ID, HC_GRAPH_CLIENT_ID, HC_GRAPH_CLIENT_SECRET and HC_GRAPH_MAILBOX");
                await SendViaGraphAsync(to, subject, Layout(subject, html), attachment);
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

        // ── Layout ─────────────────────────────────────────────────────────────

        private const string LogoUrl = "https://harriercentral.blob.core.windows.net/harrier/hclogo250round.png";

        /// <summary>
        /// The one Harrier Central email layout (E19.F2.S2): the logo, the caller's
        /// content on a white card no wider than a phone, and a footer saying who sent
        /// it and why. Built from tables with inline styles, because that is the only
        /// HTML every mail client renders the same — Outlook ignores most CSS and
        /// Gmail strips &lt;style&gt; blocks in some views. The logo is the round
        /// artwork itself, shown whole at its own shape. Callers pass only their own
        /// content; <paramref name="subject"/> becomes the hidden preheader line that
        /// inboxes show next to the subject.
        /// </summary>
        internal static string Layout(string subject, string content)
        {
            string pre = System.Net.WebUtility.HtmlEncode(subject);
            return
                "<!DOCTYPE html><html><head><meta charset=\"utf-8\">" +
                "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\"></head>" +
                "<body style=\"margin:0;padding:0;background:#eef1f4;\">" +
                $"<div style=\"display:none;max-height:0;overflow:hidden;\">{pre}</div>" +
                "<table role=\"presentation\" width=\"100%\" cellpadding=\"0\" cellspacing=\"0\" style=\"background:#eef1f4;\"><tr><td align=\"center\" style=\"padding:24px 12px;\">" +
                "<table role=\"presentation\" width=\"100%\" cellpadding=\"0\" cellspacing=\"0\" style=\"max-width:560px;\">" +
                "<tr><td align=\"center\" style=\"padding:0 0 16px;\">" +
                $"<img src=\"{LogoUrl}\" width=\"64\" height=\"64\" alt=\"Harrier Central\" style=\"display:block;border:0;width:64px;height:64px;\">" +
                "</td></tr>" +
                "<tr><td style=\"background:#ffffff;border-radius:8px;padding:28px 24px;" +
                "font-family:-apple-system,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;font-size:16px;line-height:1.5;color:#1f2933;\">" +
                content +
                "</td></tr>" +
                "<tr><td align=\"center\" style=\"padding:16px 8px 0;" +
                "font-family:-apple-system,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;font-size:12px;line-height:1.5;color:#6b7785;\">" +
                "Sent by <a href=\"https://www.harriercentral.com\" style=\"color:#6b7785;\">Harrier Central</a>, " +
                "the app hash kennels use to run their runs.<br>" +
                // Every email is also an on-ramp (James, 2026-10-09): the store links go on all of them.
                "<span style=\"display:inline-block;margin:8px 0;\">Get the app: " +
                "<a href=\"https://apps.apple.com/app/harrier-central/id1445513595\" style=\"color:#2b6cb0;font-weight:600;\">iPhone &amp; iPad</a>" +
                " &nbsp;·&nbsp; " +
                "<a href=\"https://play.google.com/store/apps/details?id=com.harriercentral.app\" style=\"color:#2b6cb0;font-weight:600;\">Android</a></span><br>" +
                "You are receiving this because of something you or your kennel did in Harrier Central — " +
                "asking for a code, a report, or a kennel request. We do not send newsletters, so there is nothing to unsubscribe from." +
                "</td></tr></table></td></tr></table></body></html>";
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
