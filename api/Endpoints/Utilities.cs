
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;

// http://localhost:7071/api/SendKennelRunStatsReport?userId=0CDBB109-215E-4B5F-A405-F6C9FBCB18EC&accessToken=085BCF1D6FB0285F75E4E38AA0D3E820E257EC07FE078D2D0AE95144E1FA0FCA&kennelId=5029DE3A-D231-47AA-BE72-ECE9BCCD55D1&kennelName=FILTHHASH&userName=Opee&emailAddress=james@defenceinnovation.eu&digitsAfterDecimal=2&currencySymbol=€^

namespace HcWebApi.Endpoints
{

    public static class Utilities
    {
        private static readonly HttpClient httpClient = new();

        /// The email Logic App's HTTP trigger. Every email the API sends goes
        /// through it. Read from the HC_EMAIL_LOGIC_APP_URL app setting; the
        /// literal fallback is the URL that used to be pasted into four
        /// endpoints and is public in the repo — rotate the trigger's key, set
        /// the app setting, then delete the fallback (2026-09-28).
        public static string EmailLogicAppUrl =>
            Environment.GetEnvironmentVariable("HC_EMAIL_LOGIC_APP_URL") is { Length: > 0 } configured
                ? configured
                : "https://prod-46.northeurope.logic.azure.com:443/workflows/ea2b7fd09a8d407fa58ab04b64638217/triggers/When_a_HTTP_request_is_received/paths/invoke?api-version=2016-10-01&sp=%2Ftriggers%2FWhen_a_HTTP_request_is_received%2Frun&sv=1.0&sig=aqjP-q4tvhj-S9aemqQKFGP5ZQYBWOBFTL_KSUvcVl8";

        /// The sender every Harrier Central email has used.
        public const string EmailFrom = "james@defenceinnovation.eu";

        /// The APNs "aps" block for a chat push. A visible push plays the sound;
        /// a silent one wakes the app (content-available). Either way, when the
        /// recipient's unread total is known it goes in "badge", which is the ONLY
        /// way to set the number on the app icon while the app is closed — iOS
        /// does not run the app to do it (2026-09-28). The total comes from
        /// HC6.UserUnreadChatTotal, the same rule as the in-app badges.
        /// alarm (2026-09-30): a Send Help message plays the app's own three-beep
        /// sos.caf (bundled in ios/Runner) instead of the default chime, so a phone
        /// in a pocket on the trail is heard.
        public static Dictionary<string, object> ChatAps(bool visible, int? badgeTotal, bool alarm = false)
        {
            var aps = visible
                ? new Dictionary<string, object> { ["sound"] = alarm ? "sos.caf" : "default" }
                : new Dictionary<string, object> { ["content-available"] = 1 };
            if (badgeTotal.HasValue) aps["badge"] = Math.Max(0, badgeTotal.Value);
            return aps;
        }

        /// The Android block for a VISIBLE chat push. notification_count is the
        /// number launchers that show one (Samsung and others) put on the icon;
        /// stock Pixel launchers show a dot whatever it says. Silent pushes carry
        /// the total in data.BadgeTotal instead, and the app sets it.
        /// alarm (2026-09-30): the hc_help channel, created by MainActivity with the
        /// bundled res/raw/sos sound; a channel owns its sound on Android 8+, so the
        /// sound named here is for older devices.
        public static object ChatAndroidVisible(int? badgeTotal, bool alarm = false)
        {
            string sound = alarm ? "sos" : "default";
            string? channel = alarm ? "hc_help" : null;
            object notification = badgeTotal.HasValue
                ? (channel == null
                    ? new { sound, notification_count = Math.Max(0, badgeTotal.Value) }
                    : new { sound, channel_id = channel, notification_count = Math.Max(0, badgeTotal.Value) })
                : (channel == null
                    ? new { sound }
                    : new { sound, channel_id = channel });
            return new { priority = "high", notification };
        }

        /// A run-chat message is a call for help when it is the Send Help text.
        public static bool IsHelpMessage(string? content) =>
            !string.IsNullOrEmpty(content) && content.TrimStart().StartsWith("🆘", StringComparison.Ordinal);

        public static async Task SendEmailAsync(
            string logicAppUrl,
            string from,
            string to,
            string subject,
            string bodyHtml,
            string? base64FileContents)
        {
            if (string.IsNullOrWhiteSpace(logicAppUrl) ||
                string.IsNullOrWhiteSpace(from) ||
                string.IsNullOrWhiteSpace(to) ||
                string.IsNullOrWhiteSpace(subject) ||
                string.IsNullOrWhiteSpace(bodyHtml))
            {
                throw new ArgumentException("All arguments must be non-null and non-empty.");
            }

            var payload = new
            {
                from,
                to,
                subject,
                body = bodyHtml,
                attachment = base64FileContents == null ? null : new
                {
                    filename = "run_stats_report.xlsx",
                    contentType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                    contentBytes = base64FileContents
                }
            };

            // var jsonOptions = new JsonSerializerOptions
            // {
            //     DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull
            // };

            var json = JsonSerializer.Serialize(payload);
            var content = new StringContent(json, Encoding.UTF8, "application/json");

            using var response = await httpClient.PostAsync(logicAppUrl, content);
            response.EnsureSuccessStatusCode();

            Console.WriteLine("Email sent successfully via Logic App.");
        }

        public static String formatCurrency(decimal amount, String digitsAfterDecimal, String currencySymbol)
        {

            String formatDecimals = "{0:#####0.00}";
            switch (digitsAfterDecimal)
            {
                case "0":
                    formatDecimals = "{0:#####0}";
                    break;
                case "1":
                    formatDecimals = "{0:#####0.0}";
                    break;
                case "2":
                    formatDecimals = "{0:#####0.00}";
                    break;
                case "3":
                    formatDecimals = "{0:#####0.000}";
                    break;
                case "4":
                    formatDecimals = "{0:#####0.0000}";
                    break;
                default:
                    formatDecimals = "{0:#####0.00}";
                    break;
            }

            return currencySymbol.Replace("^", String.Format(formatDecimals, amount));
        }

    }
}


