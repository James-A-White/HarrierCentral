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
            if (!HcListMail.VerifyUnsubscribe(h, k, e, s))
                return Page(400, "This link is not valid",
                    "It may have expired or been copied incompletely. You can switch run emails off for any kennel from the Harrier Central app: tap the envelope on the kennel.");

            string? cs = Environment.GetEnvironmentVariable("HcDbConnectionString");
            if (cs == null) return Page(500, "Something went wrong", "Please try again later.");

            string kennelName = "the kennel", slug = "";
            try
            {
                using var conn = new SqlConnection(cs);
                await conn.OpenAsync();
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
                "Changed your mind? Open the Harrier Central app and tap the envelope on the kennel to turn them back on." + back);
        }

        private static ContentResult Page(int status, string title, string bodyHtml) => new()
        {
            StatusCode = status,
            ContentType = "text/html; charset=utf-8",
            Content =
                "<!DOCTYPE html><html><head><meta charset=\"utf-8\"><meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">" +
                $"<title>{WebUtility.HtmlEncode(title)} · Harrier Central</title></head>" +
                "<body style=\"margin:0;padding:24px 16px;background:#eef1f4;font-family:-apple-system,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;color:#1f2933\">" +
                "<div style=\"max-width:560px;margin:0 auto;background:#fff;border-radius:8px;padding:28px 24px;text-align:center\">" +
                "<img src=\"https://harriercentral.blob.core.windows.net/harrier/hclogo250round.png\" width=\"64\" height=\"64\" alt=\"Harrier Central\" style=\"display:block;margin:0 auto 16px\">" +
                $"<h1 style=\"font-size:22px;margin:0 0 12px\">{WebUtility.HtmlEncode(title)}</h1>" +
                $"<p style=\"font-size:16px;line-height:1.5;margin:0\">{bodyHtml}</p></div></body></html>",
        };
    }
}
