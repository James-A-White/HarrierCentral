using System.Net;
using Microsoft.Extensions.Logging;

namespace HcWebApi.Endpoints
{
    /// <summary>
    /// The three emails of the kennel request flow (E12.F1.S6–S8), sent as
    /// post-SP side effects because a stored procedure cannot reach the mail
    /// relay:
    ///   1. publicWeb_submitKennelRequest  → the requester's six-digit code;
    ///   2. publicWeb_confirmKennelRequest → "a request is waiting" to the
    ///      platform admins who review them;
    ///   3. hcportal_approveKennelRequest  → the welcome, with the new admin's
    ///      sign-in code.
    /// Each caller strips the secret (code, reviewer addresses) out of the
    /// SP's reply after sending, so it never travels further than this API.
    /// Everything the requester typed is HTML-encoded before it goes into a
    /// message.
    /// </summary>
    internal static class KennelRequestEmails
    {
        private const string WebBase = "https://www.hashruns.org";
        private const string PortalUrl = "https://portal.harriercentral.com";

        private static string H(object? value) => WebUtility.HtmlEncode(value?.ToString() ?? string.Empty);

        /// Rowset 1 row 0 of an SP reply, or null.
        internal static Dictionary<string, object>? FirstRow(List<List<Dictionary<string, object>>> results, int rowset)
            => results.Count > rowset && results[rowset].Count > 0 ? results[rowset][0] : null;

        /// Lower-case `success` envelope in rowset 0 (the publicWeb_ write shape).
        internal static bool Succeeded(List<List<Dictionary<string, object>>> results)
            => FirstRow(results, 0) is { } row
               && row.TryGetValue("success", out var s)
               && Convert.ToInt32(s) == 1;

        internal static async Task<bool> SendConfirmCodeAsync(Dictionary<string, object> row, ILogger log)
        {
            if (!row.TryGetValue("confirmCode", out var code) || code is null) return false;
            string email = row.TryGetValue("email", out var e) ? e?.ToString() ?? "" : "";
            if (email.Length == 0) return false;
            try
            {
                await HcEmail.SendAsync(
                    "KennelRequestEmails",
                    email,
                    $"Your code to add {row.GetValueOrDefault("kennelName")} to Harrier Central",
                    $"Hello {H(row.GetValueOrDefault("firstName"))},<br><br>" +
                    $"Thanks for asking to add <strong>{H(row.GetValueOrDefault("kennelName"))}</strong> to Harrier Central. " +
                    $"To confirm it was you, enter this code on the page you just used:" +
                    $"<h1><strong>{H(code)}</strong></h1>" +
                    "The code works for 48 hours. Once it is confirmed, we review the request — usually within a few days — " +
                    "and email you when your kennel is live.<br><br>" +
                    "If you did not ask to add a kennel, you can ignore this email: nothing happens without the code.<br><br>" +
                    "On on!<br>The Harrier Central team",
                    null);
                return true;
            }
            catch (Exception ex)
            {
                log.LogError("Kennel request code email failed: {Message}", ex.Message);
                return false;
            }
        }

        internal static async Task SendReviewerNoticeAsync(
            Dictionary<string, object> row, IEnumerable<string> reviewers, ILogger log)
        {
            foreach (string to in reviewers.Where(r => r.Length > 0).Distinct(StringComparer.OrdinalIgnoreCase))
            {
                try
                {
                    await HcEmail.SendAsync(
                        "KennelRequestEmails",
                        to,
                        $"Kennel request waiting: {row.GetValueOrDefault("kennelName")}",
                        $"<strong>{H(row.GetValueOrDefault("kennelName"))}</strong> has asked to join Harrier Central " +
                        "and confirmed their email address.<br><br>" +
                        $"Review it in the portal: <a href=\"{PortalUrl}\">{PortalUrl}</a> → HC Admin Tools → Kennel requests.",
                        null);
                }
                catch (Exception ex)
                {
                    log.LogError("Kennel request reviewer notice to {To} failed: {Message}", to, ex.Message);
                }
            }
        }

        internal static async Task<bool> SendWelcomeAsync(Dictionary<string, object> row, ILogger log)
        {
            string email = row.GetValueOrDefault("AdminEmail")?.ToString() ?? "";
            string code = row.GetValueOrDefault("InviteCode")?.ToString() ?? "";
            if (email.Length == 0 || code.Length != 6) return false;
            string slug = (row.GetValueOrDefault("KennelUniqueShortName")?.ToString() ?? "").ToLowerInvariant();
            string name = row.GetValueOrDefault("AdminHashName")?.ToString() is { Length: > 0 } hn
                ? hn : row.GetValueOrDefault("AdminFirstName")?.ToString() ?? "";
            try
            {
                await HcEmail.SendAsync(
                    "KennelRequestEmails",
                    email,
                    $"{row.GetValueOrDefault("KennelName")} is live on Harrier Central",
                    $"Hello {H(name)},<br><br>" +
                    $"Good news — <strong>{H(row.GetValueOrDefault("KennelName"))}</strong> is now on Harrier Central, " +
                    "and you are its admin.<br><br>" +
                    $"<strong>Your kennel's web page:</strong> <a href=\"{WebBase}/{H(slug)}\">{WebBase}/{H(slug)}</a><br><br>" +
                    "<strong>To get started</strong><br>" +
                    "1. Install the Harrier Central app (App Store or Google Play) and sign in with this email address. " +
                    $"When it asks for your code, enter:<h1><strong>{H(code)}</strong></h1>" +
                    "The code is letters only, no numbers.<br>" +
                    $"2. Add your runs, members and kennel details in the app, or at <a href=\"{PortalUrl}\">{PortalUrl}</a> " +
                    "(sign in from the app).<br><br>" +
                    "Your kennel has a Harrier Central coin as its logo for now — replace it with your own from the kennel page.<br><br>" +
                    "Questions? Just reply to this email.<br><br>" +
                    "On on!<br>The Harrier Central team",
                    null);
                return true;
            }
            catch (Exception ex)
            {
                log.LogError("Kennel welcome email failed: {Message}", ex.Message);
                return false;
            }
        }
    }
}
