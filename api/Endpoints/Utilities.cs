
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;

// http://localhost:7071/api/SendKennelRunStatsReport?userId=0CDBB109-215E-4B5F-A405-F6C9FBCB18EC&accessToken=085BCF1D6FB0285F75E4E38AA0D3E820E257EC07FE078D2D0AE95144E1FA0FCA&kennelId=5029DE3A-D231-47AA-BE72-ECE9BCCD55D1&kennelName=FILTHHASH&userName=Opee&emailAddress=james@defenceinnovation.eu&digitsAfterDecimal=2&currencySymbol=€^

namespace HcWebApi.Endpoints
{

    public static class Utilities
    {
        private static readonly HttpClient httpClient = new();

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


