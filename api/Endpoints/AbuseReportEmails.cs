using System.Net;
using Microsoft.Extensions.Logging;

namespace HcWebApi.Endpoints
{
    /// <summary>
    /// A reported chat message, emailed to the platform reviewers (E9.F1.S17,
    /// 2026-09-29). Harrier Central is a letterbox, not a moderator: the SP
    /// wrote the report to LOG.GeneralLog and returned it in rowset 1 with the
    /// reviewer addresses in rowset 2 — the same list kennel requests go to.
    /// Both callers strip those rowsets before replying to the client.
    /// </summary>
    internal static class AbuseReportEmails
    {
        internal static async Task SendAsync(Dictionary<string, object?> report, IEnumerable<string> reviewers, ILogger log)
        {
            if (Convert.ToInt32(report.GetValueOrDefault("AlreadyReported") ?? 0) == 1) return;

            string S(string k) => report.GetValueOrDefault(k)?.ToString() ?? "";
            string H(string k) => WebUtility.HtmlEncode(S(k));
            int kind = int.TryParse(S("MessageKind"), out var k) ? k : 0;
            string content = kind == 0
                ? $"<blockquote style=\"border-left:3px solid #999;padding-left:12px;white-space:pre-wrap\">{H("MessageContent")}</blockquote>"
                : $"<p>{(kind == 1 ? "Photo" : "Location")}: <a href=\"{H("MessageContent")}\">{H("MessageContent")}</a></p>";
            string reason = S("Reason").Length == 0 ? "<p><i>No reason given.</i></p>"
                : $"<p><b>Reason:</b> <span style=\"white-space:pre-wrap\">{H("Reason")}</span></p>";

            string subject = $"Chat message reported — {S("ThreadLabel")}";
            string body =
                $"<p><b>{H("ReporterName")}</b> ({H("ReporterEmail")}) reported a message by <b>{H("SenderName")}</b> " +
                $"(public id {H("SenderPublicHasherId")}) in <b>{H("ThreadLabel")}</b>, sent {H("MessageAt")}.</p>" +
                content + reason +
                $"<p style=\"color:#666\">Message id {H("MessageId")}. The report is in LOG.GeneralLog " +
                "(HC6.hcapp_reportChatMessage). Harrier Central does not read chats; the reporter can " +
                "block the sender themselves, and a super admin can delete the message from the app.</p>";

            foreach (string to in reviewers.Where(r => r.Length > 0).Distinct(StringComparer.OrdinalIgnoreCase))
            {
                try
                {
                    await Utilities.SendEmailAsync(Utilities.EmailLogicAppUrl, Utilities.EmailFrom, to, subject, body, null);
                }
                catch (Exception ex)
                {
                    log.LogError("Abuse report email to {To} failed: {Message}", to, ex.Message);
                }
            }
        }

        /// <summary>Rowset 1 report + rowset 2 reviewers, removed from the reply; null when the SP refused.</summary>
        internal static (Dictionary<string, object?> report, List<string> reviewers)? Extract<T>(List<List<Dictionary<string, T>>> results)
        {
            if (results.Count < 3 || results[0].Count != 1) return null;
            var env = results[0][0];
            if (!env.TryGetValue("success", out var ok) || ok is null || Convert.ToInt32(ok) != 1) return null;
            if (results[1].Count != 1) return null;
            var report = results[1][0].ToDictionary(kv => kv.Key, kv => (object?)kv.Value);
            var reviewers = results[2].Select(r => r.GetValueOrDefault("reviewerEmail")?.ToString() ?? "").ToList();
            results.RemoveAt(2);
            results.RemoveAt(1);
            return (report, reviewers);
        }
    }
}
