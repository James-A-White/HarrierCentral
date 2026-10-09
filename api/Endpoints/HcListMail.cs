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
        public static async Task SendAsync(string to, string subject, string html, string plainText, string? unsubscribeUrl)
        {
            var content = new EmailContent(subject) { Html = html, PlainText = plainText };
            var message = new EmailMessage(From, new EmailRecipients(new[] { new EmailAddress(to) }), content);
            if (unsubscribeUrl != null)
            {
                message.Headers["List-Unsubscribe"] = $"<{unsubscribeUrl}>";
                message.Headers["List-Unsubscribe-Post"] = "List-Unsubscribe=One-Click";
            }
            await client.Value.SendAsync(WaitUntil.Started, message);
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
