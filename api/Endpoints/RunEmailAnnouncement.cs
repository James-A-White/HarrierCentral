using System.Data;
using System.Net;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json.Linq;

namespace HcWebApi.Endpoints
{
    /// <summary>
    /// The one-off launch announcement (E9.F6.S10): to every hasher who has run
    /// emails switched on for any kennel, telling them about run emails as a
    /// new feature they control from the app — kennel by kennel, run by run —
    /// before any kennel's first run email arrives. Internal: POST
    /// { secret, dryRun } with HC_INTERNAL_SECRET. dryRun (the default) only
    /// counts. Sends once per hasher, through the list route, each with its
    /// own unsubscribe link (scoped to the kennel they are most recently
    /// following with emails on).
    /// </summary>
    public class RunEmailAnnouncement
    {
        private readonly ILogger<RunEmailAnnouncement> _log;
        public RunEmailAnnouncement(ILogger<RunEmailAnnouncement> log) { _log = log; }

        private const string Sql = @"
SELECT h.id AS hasherId, h.Email AS email, h.DisplayName AS displayName,
       k.id AS kennelId, k.KennelName AS kennelName
FROM HC.Hasher h
CROSS APPLY (SELECT TOP 1 m.KennelId FROM HC.HasherKennelMap m
             WHERE m.UserId = h.id AND m.removed = 0 AND m.KennelEmailAlertPreference = 1
             ORDER BY m.updatedAt DESC) x
JOIN HC.Kennel k ON k.id = x.KennelId
WHERE ISNULL(h.Removed, 0) = 0 AND h.deleted = 0 AND h.Email LIKE '%_@_%.__%'
ORDER BY h.DisplayName;";

        [Function("RunEmailAnnouncement")]
        public async Task<IActionResult> Run([HttpTrigger(AuthorizationLevel.Anonymous, "post")] HttpRequest req)
        {
            JObject body;
            try { body = JObject.Parse(await new StreamReader(req.Body).ReadToEndAsync()); } catch { return new BadRequestResult(); }
            string? expected = Environment.GetEnvironmentVariable("HC_INTERNAL_SECRET");
            if (expected == null || body.Value<string>("secret") != expected) return new UnauthorizedResult();
            bool dryRun = body.Value<bool?>("dryRun") ?? true;
            string? onlyTo = body.Value<string>("onlyTo");   // a test: send the real email to this address only
            string? cs = Environment.GetEnvironmentVariable("HcDbConnectionString");
            if (cs == null) return new StatusCodeResult(500);

            var rows = new List<(Guid hasherId, string email, string name, Guid kennelId, string kennelName)>();
            using (var conn = new SqlConnection(cs))
            {
                await conn.OpenAsync();
                using var cmd = new SqlCommand(Sql, conn) { CommandTimeout = 60 };
                using var r = await cmd.ExecuteReaderAsync();
                while (await r.ReadAsync())
                    rows.Add(((Guid)r["hasherId"], (string)r["email"], r["displayName"] as string ?? "", (Guid)r["kennelId"], (string)r["kennelName"]));
            }
            if (onlyTo != null) rows = rows.Where(x => x.email.Equals(onlyTo, StringComparison.OrdinalIgnoreCase)).ToList();
            if (dryRun) return new OkObjectResult(new { recipients = rows.Count, dryRun = true });
            if (!HcListMail.IsConfigured) return new StatusCodeResult(500);

            int ok = 0;
            foreach (var x in rows)
            {
                try
                {
                    string unsub = HcListMail.UnsubscribeUrl(x.hasherId, x.kennelId);
                    await HcListMail.SendAsync(x.email, "New: run emails from your kennel, when you want them", Html(x.name, x.kennelName, unsub), Plain(x.name, x.kennelName, unsub), unsub);
                    ok++;
                }
                catch (Exception ex) { await HcListMail.LogFailureAsync("RunEmailAnnouncement", x.email, ex.Message); }
                await Task.Delay(250);
            }
            _log.LogInformation("RunEmailAnnouncement: {Ok}/{Total} accepted", ok, rows.Count);
            return new OkObjectResult(new { recipients = rows.Count, accepted = ok, dryRun = false });
        }

        private static string Html(string name, string kennelName, string unsub)
        {
            string n = WebUtility.HtmlEncode(name.Length > 0 ? name : "there");
            string k = WebUtility.HtmlEncode(kennelName);
            return HcEmail.Layout("New: run emails from your kennel",
                $"<p style=\"margin:0 0 14px\">Hello {n},</p>" +
                "<p style=\"margin:0 0 14px\">Harrier Central can now <strong>email you about upcoming runs</strong> — the date, the venue, the hares, the price, and one-tap <em>I'm in</em> / <em>Can't make it</em> buttons that open the app.</p>" +
                $"<p style=\"margin:0 0 14px\">You are getting this because you once switched email on for <strong>{k}</strong>. Nothing has been sent until now. From here on, a run email arrives only when your kennel's hare raiser sends one.</p>" +
                "<p style=\"margin:0 0 14px\"><strong>You are in control, in the app:</strong><br>• tap the <strong>envelope on a kennel</strong> to switch its run emails on or off<br>• tap the <strong>envelope on a run</strong> to decide for that run alone</p>" +
                $"<p style=\"margin:0 0 14px\">Don't want any? <a href=\"{unsub}\" style=\"color:#2b6cb0\">Switch off run emails from {k}</a> — one tap, no sign-in.</p>" +
                "<p style=\"margin:0\">On on,<br>The Harrier Central team</p>");
        }

        private static string Plain(string name, string kennelName, string unsub) =>
            $"Hello {(name.Length > 0 ? name : "there")},\n\nHarrier Central can now email you about upcoming runs — date, venue, hares, price, and one-tap I'm in / Can't make it links that open the app.\n\n" +
            $"You are getting this because you once switched email on for {kennelName}. Nothing has been sent until now. From here on, a run email arrives only when your kennel's hare raiser sends one.\n\n" +
            "You are in control, in the app: tap the envelope on a kennel to switch its run emails on or off; tap the envelope on a run to decide for that run alone.\n\n" +
            $"Don't want any? Switch off run emails from {kennelName}: {unsub}\n\nOn on,\nThe Harrier Central team";
    }
}
