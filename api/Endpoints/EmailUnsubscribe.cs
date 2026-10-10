using System.Data;
using System.Net;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Logging;

namespace HcWebApi.Endpoints
{
    /// <summary>
    /// The unsubscribe link in every run email (E19.F3.S2). One tap, no sign-in:
    /// the signed token names the hasher and the kennel, and all this does is
    /// set that hasher's email-alert setting for that kennel to off — the same
    /// value the app's dialog writes. GET is the link in the body; POST is the
    /// RFC 8058 one-click that Gmail's own Unsubscribe button sends. Both do the
    /// same thing and both answer with a plain page.
    /// </summary>
    public class EmailUnsubscribe
    {
        private readonly ILogger<EmailUnsubscribe> _log;
        public EmailUnsubscribe(ILogger<EmailUnsubscribe> log) { _log = log; }

        [Function("EmailUnsubscribe")]
        public async Task<IActionResult> Run([HttpTrigger(AuthorizationLevel.Anonymous, "get", "post")] HttpRequest req)
        {
            string? h = req.Query["h"], k = req.Query["k"], e = req.Query["e"], s = req.Query["s"];
            string action = (req.Query["do"].ToString() ?? "").ToLowerInvariant();   // "", "prefs", "block"
            if (!HcListMail.VerifyUnsubscribe(h, k, e, s))
                return Page(400, "This link is not valid",
                    "It may have expired or been copied incompletely. You can switch run emails off for any kennel from the Harrier Central app: tap the envelope on the kennel.");

            string? cs = Environment.GetEnvironmentVariable("HcDbConnectionString");
            if (cs == null) return Page(500, "Something went wrong", "Please try again later.");

            string baseUrl = $"{HcListMail.ApiBase}/api/EmailUnsubscribe?h={h}&k={k}&e={e}&s={s}";
            string blockUrl = WebUtility.HtmlEncode(baseUrl + "&do=block");
            // The kennel's name, slug and logo: every page below carries the logo, so
            // the person sees whose emails they are turning off (James, 2026-10-10).
            (string kennelName, string slug, string logo) = await KennelAsync(cs, Guid.Parse(k!));

            // The preferences page: choices, nothing acted on yet. This is the link under
            // "<admin> has requested that you receive this email".
            if (action == "prefs")
            {
                return Page(200, "Your email preferences",
                    $"Choose what you want from Harrier Central.<br><br>" +
                    $"<a href=\"{WebUtility.HtmlEncode(baseUrl)}\" style=\"display:inline-block;margin:4px;padding:10px 16px;background:#2b6cb0;color:#fff;border-radius:6px;text-decoration:none\">Stop run emails from {WebUtility.HtmlEncode(kennelName)}</a><br>" +
                    $"<a href=\"{blockUrl}\" style=\"display:inline-block;margin:4px;padding:10px 16px;background:#9b2c2c;color:#fff;border-radius:6px;text-decoration:none\">Block all email from Harrier Central</a>" +
                    "<br><span style=\"font-size:13px;color:#6b7785\">Blocking stops every email, including run emails an admin asks us to send you. Invite codes you ask for yourself still arrive.</span>",
                    logo, kennelName);
            }

            try
            {
                using var conn = new SqlConnection(cs);
                await conn.OpenAsync();
                if (action == "block")
                {
                    // The member's "nothing at all" (E19.F4): beats every preference and every
                    // admin override from now on.
                    using var cmd = new SqlCommand("[HC6].[nonApi_setEmailBlocked]", conn) { CommandType = CommandType.StoredProcedure };
                    cmd.Parameters.Add("@hasherId", SqlDbType.UniqueIdentifier).Value = Guid.Parse(h!);
                    cmd.Parameters.Add("@blocked", SqlDbType.SmallInt).Value = 1;
                    using var r = await cmd.ExecuteReaderAsync();
                    if (await r.ReadAsync() && Convert.ToInt32(r["Success"]) != 1) throw new InvalidOperationException(r["ErrorMessage"]?.ToString());
                    return Page(200, "All email blocked",
                        "Harrier Central will not email you about runs again, from any kennel, even when an admin asks us to. " +
                        "Invite codes you request yourself still arrive. To change this later, ask your kennel's admin.", logo, kennelName);
                }
                else
                {
                    using var cmd = new SqlCommand("[HC6].[nonApi_setKennelEmailOff]", conn) { CommandType = CommandType.StoredProcedure };
                    cmd.Parameters.Add("@userId", SqlDbType.UniqueIdentifier).Value = Guid.Parse(h!);
                    cmd.Parameters.Add("@kennelId", SqlDbType.UniqueIdentifier).Value = Guid.Parse(k!);
                    using var r = await cmd.ExecuteReaderAsync();
                    if (await r.ReadAsync())
                    {
                        if (Convert.ToInt32(r["Success"]) != 1) throw new InvalidOperationException(r["ErrorMessage"]?.ToString());
                        kennelName = r["kennelName"] as string ?? kennelName;
                        slug = r["kennelSlug"] as string ?? "";
                    }
                }
            }
            catch (Exception ex)
            {
                _log.LogError("EmailUnsubscribe failed: {Message}", ex.Message);
                return Page(500, "Something went wrong", "We could not save that. Please try again later, or switch run emails off from the app: tap the envelope on the kennel.");
            }

            string back = slug.Length > 0
                ? $"<p style=\"margin-top:24px\"><a href=\"https://www.hashruns.org/{WebUtility.HtmlEncode(slug.ToLowerInvariant())}\" style=\"color:#2b6cb0\">Back to {WebUtility.HtmlEncode(kennelName)}</a></p>"
                : "";
            return Page(200, "You're unsubscribed",
                $"You will not get run emails from <strong>{WebUtility.HtmlEncode(kennelName)}</strong> any more. " +
                "Changed your mind? Open the Harrier Central app and tap the envelope on the kennel to turn them back on." +
                $"<br><br><span style=\"font-size:13px\">Want nothing at all from Harrier Central? <a href=\"{blockUrl}\" style=\"color:#9b2c2c\">Block all email</a>.</span>" + back,
                logo, kennelName);
        }

        private static async Task<(string name, string slug, string logo)> KennelAsync(string cs, Guid kennelId)
        {
            try
            {
                using var conn = new SqlConnection(cs);
                await conn.OpenAsync();
                using var cmd = new SqlCommand("SELECT KennelName, KennelUniqueShortName, KennelLogo FROM HC.Kennel WHERE id = @k", conn);
                cmd.Parameters.Add("@k", SqlDbType.UniqueIdentifier).Value = kennelId;
                using var r = await cmd.ExecuteReaderAsync();
                if (await r.ReadAsync())
                {
                    string logo = r["KennelLogo"] as string ?? "";
                    return (r["KennelName"] as string ?? "the kennel", r["KennelUniqueShortName"] as string ?? "",
                            logo.StartsWith("https://", StringComparison.OrdinalIgnoreCase) ? logo : "");
                }
            }
            catch { }
            return ("the kennel", "", "");
        }

        /// <summary>
        /// The page, on the same jungle as the emails, with the kennel's logo above the
        /// title when the link named a kennel (whole, at its own shape — never cropped)
        /// and ours when it did not.
        /// </summary>
        private static ContentResult Page(int status, string title, string bodyHtml, string? kennelLogo = null, string? kennelName = null)
        {
            const string jungle = "https://www.hashruns.org/images/jungle_background.jpg";
            string logo = string.IsNullOrEmpty(kennelLogo)
                ? "<img src=\"https://harriercentral.blob.core.windows.net/harrier/hclogo250round.png\" width=\"72\" height=\"72\" alt=\"Harrier Central\" style=\"display:block;margin:0 auto 16px\">"
                : $"<img src=\"{WebUtility.HtmlEncode(kennelLogo)}\" alt=\"{WebUtility.HtmlEncode(kennelName ?? "Kennel logo")}\" style=\"display:block;margin:0 auto 16px;width:120px;max-width:60%;height:auto;max-height:160px;object-fit:contain\">";
            return new()
            {
                StatusCode = status,
                ContentType = "text/html; charset=utf-8",
                Content =
                    "<!DOCTYPE html><html><head><meta charset=\"utf-8\"><meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">" +
                    $"<title>{WebUtility.HtmlEncode(title)} · Harrier Central</title></head>" +
                    $"<body style=\"margin:0;padding:28px 16px 40px;background:#1f4d2c url('{jungle}') center top repeat;font-family:-apple-system,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;color:#1f2933\">" +
                    $"<div style=\"max-width:560px;margin:0 auto;text-align:center\">{logo}" +
                    "<div style=\"background:#fff;border-radius:10px;padding:28px 24px\">" +
                    $"<h1 style=\"font-size:22px;margin:0 0 12px\">{WebUtility.HtmlEncode(title)}</h1>" +
                    $"<p style=\"font-size:16px;line-height:1.5;margin:0\">{bodyHtml}</p></div>" +
                    "<p style=\"margin:16px 0 0;font-size:12px;color:#e6eee8\">Harrier Central</p></div></body></html>",
            };
        }
    }
}
