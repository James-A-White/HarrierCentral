using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace HcWebApi.Endpoints
{
    /// <summary>
    /// Returns coarse geolocation data for the caller's public IP address.
    /// Proxies to ipinfo.io using the IPINFO_API_TOKEN held server-side,
    /// so the token never appears in client app binaries.
    ///
    /// Usage: GET /api/GetIpGeoInfo
    ///        Returns the ipinfo.io JSON response for the caller's IP.
    ///
    /// Called by the mobile app at login time for analytics only.
    /// Returns a safe fallback JSON body on any upstream failure.
    /// </summary>
    public class GetIpGeoInfo
    {
        private static readonly HttpClient _httpClient = new()
        {
            Timeout = TimeSpan.FromSeconds(5)
        };

        private static readonly string FallbackJson =
            """{"ip":"0.0.0.0","city":"none","region":"none","country":"XX","org":"none"}""";

        private readonly ILogger<GetIpGeoInfo> _log;

        public GetIpGeoInfo(ILogger<GetIpGeoInfo> logger)
        {
            _log = logger;
        }

        [Function("GetIpGeoInfo")]
        public async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Anonymous, "get")] HttpRequest req)
        {
            string ip = req.Headers.TryGetValue("X-Forwarded-For", out var forwarded)
                ? forwarded.ToString().Split(',')[0].Trim()
                : req.HttpContext.Connection.RemoteIpAddress?.ToString() ?? "0.0.0.0";

            string token = Environment.GetEnvironmentVariable("IPINFO_API_TOKEN") ?? string.Empty;

            if (string.IsNullOrWhiteSpace(token))
            {
                _log.LogWarning("GetIpGeoInfo: IPINFO_API_TOKEN is not configured.");
                return new ContentResult
                {
                    Content = FallbackJson,
                    ContentType = "application/json",
                    StatusCode = 200
                };
            }

            try
            {
                var url = $"https://ipinfo.io/{Uri.EscapeDataString(ip)}?token={token}";
                using var response = await _httpClient.GetAsync(url);

                if (!response.IsSuccessStatusCode)
                {
                    _log.LogWarning("GetIpGeoInfo: ipinfo.io returned {Status} for IP {IP}",
                        response.StatusCode, ip);
                    return new ContentResult
                    {
                        Content = FallbackJson,
                        ContentType = "application/json",
                        StatusCode = 200
                    };
                }

                string body = await response.Content.ReadAsStringAsync();
                return new ContentResult
                {
                    Content = body,
                    ContentType = "application/json",
                    StatusCode = 200
                };
            }
            catch (Exception ex)
            {
                _log.LogWarning(ex, "GetIpGeoInfo: upstream call failed for IP {IP}", ip);
                return new ContentResult
                {
                    Content = FallbackJson,
                    ContentType = "application/json",
                    StatusCode = 200
                };
            }
        }
    }
}
