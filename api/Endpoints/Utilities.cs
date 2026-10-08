
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;

// http://localhost:7071/api/SendKennelRunStatsReport?userId=0CDBB109-215E-4B5F-A405-F6C9FBCB18EC&accessToken=085BCF1D6FB0285F75E4E38AA0D3E820E257EC07FE078D2D0AE95144E1FA0FCA&kennelId=5029DE3A-D231-47AA-BE72-ECE9BCCD55D1&kennelName=FILTHHASH&userName=Opee&emailAddress=james@defenceinnovation.eu&digitsAfterDecimal=2&currencySymbol=€^

namespace HcWebApi.Endpoints
{

    public static class Utilities
    {
        // Email moved to HcEmail (E18, 2026-10-08).

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


