using System.Data;
using System.Globalization;
using System.Net.Http.Headers;
using System.Text;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace HcWebApi.Endpoints
{
    /// <summary>
    /// Reads Azure's cost per day per service from Cost Management into
    /// LOG.AzureDailyCost, for the portal's Usage Data monitor ('Azure Cost',
    /// green when lower — James, 2026-10-05).
    ///
    /// Every six hours it re-reads the last 7 days: a day's figure keeps
    /// settling for about a day after it ends, and each re-read refreshes
    /// RetrievedAt, which is how the monitor tells a complete day from one
    /// still filling in. AzureDailyCostNow (X-Api-Key, {"days":90}) backfills.
    ///
    /// Auth: the Function App's system-assigned managed identity, which holds
    /// the read-only "Cost Management Reader" role on the subscription. The
    /// token comes from the Functions identity endpoint (IDENTITY_ENDPOINT /
    /// IDENTITY_HEADER), so no Azure SDK package is needed. Subscription:
    /// AZURE_SUBSCRIPTION_ID, else the one in WEBSITE_OWNER_NAME.
    ///
    /// Failures land in HC.ErrorLog as 'Azure cost read failed' / 'Azure cost
    /// save failed' (ProcName AzureDailyCost).
    /// </summary>
    public class AzureDailyCost
    {
        private readonly ILogger<AzureDailyCost> _log;
        private static readonly HttpClient Http = new() { Timeout = TimeSpan.FromSeconds(60) };

        public AzureDailyCost(ILogger<AzureDailyCost> logger) { _log = logger; }

        [Function("AzureDailyCost")]
        public async Task Timer([TimerTrigger("0 23 1,7,13,19 * * *")] TimerInfo timer)
        {
            await RunAsync(7);
        }

        [Function("AzureDailyCostNow")]
        public async Task<IActionResult> Now([HttpTrigger(AuthorizationLevel.Anonymous, "post")] HttpRequest req)
        {
            string? apiKey = Environment.GetEnvironmentVariable("ApiKey");
            if (string.IsNullOrEmpty(apiKey) || req.Headers["X-Api-Key"] != apiKey) return new UnauthorizedResult();
            int days = 7;
            try
            {
                string body = await new StreamReader(req.Body).ReadToEndAsync();
                if (body.Length > 0) days = JObject.Parse(body).Value<int?>("days") ?? 7;
            }
            catch { /* default */ }
            return new OkObjectResult(await RunAsync(Math.Clamp(days, 1, 365)));
        }

        private async Task<object> RunAsync(int days)
        {
            string? cs = Environment.GetEnvironmentVariable("HcDbConnectionString");
            if (string.IsNullOrWhiteSpace(cs)) return new { error = "no connection string" };

            JArray rows;
            try
            {
                rows = await ReadCostsAsync(days);
            }
            catch (Exception ex)
            {
                _log.LogWarning("AzureDailyCost: read failed: {Message}", ex.Message);
                await LogErrorAsync(cs, "Azure cost read failed", ex.Message);
                return new { error = "read failed: " + ex.Message };
            }

            try
            {
                using var conn = new SqlConnection(cs);
                await conn.OpenAsync();
                using var cmd = new SqlCommand("HC6.nonApi_saveAzureDailyCost", conn) { CommandType = CommandType.StoredProcedure };
                cmd.Parameters.Add("@costsJson", SqlDbType.NVarChar, -1).Value = rows.ToString(Formatting.None);
                using var r = await cmd.ExecuteReaderAsync();
                object result = new { };
                if (await r.ReadAsync())
                    result = new
                    {
                        daysSaved = r.GetInt32(0),
                        rowsSaved = r.GetInt32(1),
                        firstDate = r.IsDBNull(2) ? null : r.GetDateTime(2).ToString("yyyy-MM-dd"),
                        lastDate = r.IsDBNull(3) ? null : r.GetDateTime(3).ToString("yyyy-MM-dd"),
                    };
                return result;
            }
            catch (Exception ex)
            {
                _log.LogWarning("AzureDailyCost: save failed: {Message}", ex.Message);
                await LogErrorAsync(cs, "Azure cost save failed", ex.Message);
                return new { error = "save failed: " + ex.Message };
            }
        }

        /// <summary>
        /// Cost Management query: actual cost, daily, grouped by ServiceName,
        /// following nextLink. Rows become {date, service, cost, currency}.
        /// </summary>
        private static async Task<JArray> ReadCostsAsync(int days)
        {
            string sub = SubscriptionId()
                ?? throw new InvalidOperationException("no subscription id (set AZURE_SUBSCRIPTION_ID)");
            string token = await ManagedIdentityTokenAsync("https://management.azure.com/");

            DateTime to = DateTime.UtcNow.Date;
            DateTime from = to.AddDays(-(days - 1));
            var query = new JObject
            {
                ["type"] = "ActualCost",
                ["timeframe"] = "Custom",
                ["timePeriod"] = new JObject
                {
                    ["from"] = from.ToString("yyyy-MM-ddT00:00:00Z"),
                    ["to"] = to.ToString("yyyy-MM-ddT23:59:59Z"),
                },
                ["dataset"] = new JObject
                {
                    ["granularity"] = "Daily",
                    ["aggregation"] = new JObject { ["totalCost"] = new JObject { ["name"] = "Cost", ["function"] = "Sum" } },
                    ["grouping"] = new JArray(new JObject { ["type"] = "Dimension", ["name"] = "ServiceName" }),
                },
            };

            var output = new JArray();
            string? url = $"https://management.azure.com/subscriptions/{sub}/providers/Microsoft.CostManagement/query?api-version=2023-11-01";
            int pages = 0;
            while (url != null && pages++ < 20)
            {
                JObject page = await PostWithRetryAsync(url, token, query.ToString(Formatting.None));
                var cols = (page.SelectToken("properties.columns") as JArray ?? new JArray())
                    .Select(c => c.Value<string>("name") ?? "").ToList();
                int iCost = cols.IndexOf("Cost"), iDate = cols.IndexOf("UsageDate"),
                    iSvc = cols.IndexOf("ServiceName"), iCur = cols.IndexOf("Currency");
                if (iCost < 0 || iDate < 0) throw new InvalidOperationException("unexpected columns: " + string.Join(",", cols));
                foreach (JArray row in (page.SelectToken("properties.rows") as JArray ?? new JArray()).OfType<JArray>())
                {
                    string d = row[iDate].ToString(); // yyyymmdd
                    if (!DateTime.TryParseExact(d, "yyyyMMdd", CultureInfo.InvariantCulture, DateTimeStyles.None, out DateTime day)) continue;
                    output.Add(new JObject
                    {
                        ["date"] = day.ToString("yyyy-MM-dd"),
                        ["service"] = iSvc >= 0 ? row[iSvc].ToString() : "All",
                        ["cost"] = row[iCost].Value<double>(),
                        ["currency"] = iCur >= 0 ? row[iCur].ToString() : "",
                    });
                }
                url = page.SelectToken("properties.nextLink")?.ToString();
                if (string.IsNullOrEmpty(url)) url = null;
            }
            return output;
        }

        // Cost Management throttles hard; it says how long to wait.
        private static async Task<JObject> PostWithRetryAsync(string url, string token, string body)
        {
            for (int attempt = 1; ; attempt++)
            {
                using var req = new HttpRequestMessage(HttpMethod.Post, url)
                {
                    Content = new StringContent(body, Encoding.UTF8, "application/json"),
                };
                req.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
                using HttpResponseMessage res = await Http.SendAsync(req);
                string text = await res.Content.ReadAsStringAsync();
                if (res.IsSuccessStatusCode) return JObject.Parse(text);
                if (attempt < 3 && ((int)res.StatusCode == 429 || (int)res.StatusCode >= 500))
                {
                    int wait = 10;
                    foreach (string h in new[] { "x-ms-ratelimit-microsoft.costmanagement-entity-retry-after",
                                                 "x-ms-ratelimit-microsoft.costmanagement-qpu-retry-after", "Retry-After" })
                        if (res.Headers.TryGetValues(h, out var v) && int.TryParse(v.FirstOrDefault(), out int s)) { wait = s; break; }
                    await Task.Delay(TimeSpan.FromSeconds(Math.Min(wait, 60)));
                    continue;
                }
                throw new InvalidOperationException($"Cost Management returned {(int)res.StatusCode}: {(text.Length > 300 ? text[..300] : text)}");
            }
        }

        internal static async Task<string> ManagedIdentityTokenAsync(string resource)
        {
            string? endpoint = Environment.GetEnvironmentVariable("IDENTITY_ENDPOINT");
            string? header = Environment.GetEnvironmentVariable("IDENTITY_HEADER");
            if (string.IsNullOrEmpty(endpoint) || string.IsNullOrEmpty(header))
                throw new InvalidOperationException("the Function App has no managed identity (IDENTITY_ENDPOINT not set)");
            using var req = new HttpRequestMessage(HttpMethod.Get,
                $"{endpoint}?resource={Uri.EscapeDataString(resource)}&api-version=2019-08-01");
            req.Headers.Add("X-IDENTITY-HEADER", header);
            using HttpResponseMessage res = await Http.SendAsync(req);
            string text = await res.Content.ReadAsStringAsync();
            if (!res.IsSuccessStatusCode)
                throw new InvalidOperationException($"managed identity token refused ({(int)res.StatusCode})");
            return JObject.Parse(text).Value<string>("access_token")
                ?? throw new InvalidOperationException("managed identity answered without a token");
        }

        private static string? SubscriptionId()
        {
            string? s = Environment.GetEnvironmentVariable("AZURE_SUBSCRIPTION_ID");
            if (!string.IsNullOrWhiteSpace(s)) return s.Trim();
            // App Service sets WEBSITE_OWNER_NAME = "<subscription>+<webspace>".
            string? owner = Environment.GetEnvironmentVariable("WEBSITE_OWNER_NAME");
            if (string.IsNullOrEmpty(owner)) return null;
            string first = owner.Split('+')[0];
            return Guid.TryParse(first, out _) ? first : null;
        }

        private static async Task LogErrorAsync(string cs, string name, string message)
        {
            try
            {
                using var conn = new SqlConnection(cs);
                await conn.OpenAsync();
                using var cmd = new SqlCommand(
                    "INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId) " +
                    "VALUES (NEWID(), '<api>', @n, @d, 'AzureDailyCost', NULL);", conn);
                cmd.Parameters.Add("@n", SqlDbType.NVarChar, 200).Value = name;
                cmd.Parameters.Add("@d", SqlDbType.NVarChar, -1).Value = message;
                await cmd.ExecuteNonQueryAsync();
            }
            catch { /* best effort */ }
        }
    }
}
