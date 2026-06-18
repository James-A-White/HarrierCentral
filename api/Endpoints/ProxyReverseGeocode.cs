using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace HcWebApi.Endpoints
{
    /// <summary>
    /// Proxy endpoint that calls Azure Maps reverse geocode directly, keeping the
    /// subscription key server-side and out of the compiled Flutter portal JS bundle.
    ///
    /// Usage: GET /api/ProxyReverseGeocode?lat=51.5&lon=-0.1
    ///
    /// Callers must have their own portal auth — this endpoint uses Anonymous
    /// because the portal already performs device/token auth upstream.
    /// </summary>
    public class ProxyReverseGeocode
    {
        private static readonly HttpClient _httpClient = new()
        {
            Timeout = TimeSpan.FromSeconds(10)
        };

        private readonly ILogger<ProxyReverseGeocode> _log;

        public ProxyReverseGeocode(ILogger<ProxyReverseGeocode> logger)
        {
            _log = logger;
        }

        [Function("ProxyReverseGeocode")]
        public async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "ProxyReverseGeocode")] HttpRequest req)
        {
            string? subscriptionKey = Environment.GetEnvironmentVariable("AzureMapsSubscriptionKey");
            if (string.IsNullOrEmpty(subscriptionKey))
            {
                _log.LogError("AzureMapsSubscriptionKey is not configured.");
                return new ObjectResult("Reverse geocode service unavailable.") { StatusCode = 503 };
            }

            string? lat = req.Query["lat"].ToString();
            string? lon = req.Query["lon"].ToString();

            if (string.IsNullOrWhiteSpace(lat) || string.IsNullOrWhiteSpace(lon))
                return new BadRequestObjectResult("Missing required parameters: lat, lon");

            string targetUrl = $"https://atlas.microsoft.com/search/address/reverse/JSON" +
                               $"?subscription-key={subscriptionKey}&api-version=1.0&query={lat},{lon}&radius=1000";

            try
            {
                using var cts = new CancellationTokenSource(TimeSpan.FromSeconds(10));
                using var upstreamResponse = await _httpClient.GetAsync(targetUrl, cts.Token);

                string responseBody = await upstreamResponse.Content.ReadAsStringAsync();
                string contentType  = upstreamResponse.Content.Headers.ContentType?.ToString()
                    ?? "application/json";

                return new ContentResult
                {
                    Content     = responseBody,
                    ContentType = contentType,
                    StatusCode  = (int)upstreamResponse.StatusCode
                };
            }
            catch (OperationCanceledException)
            {
                _log.LogWarning("ProxyReverseGeocode: Azure Maps request timed out.");
                return new ObjectResult("Reverse geocode service timed out.") { StatusCode = 504 };
            }
            catch (Exception ex)
            {
                _log.LogError("ProxyReverseGeocode error: {Message}", ex.Message);
                return new ObjectResult("Reverse geocode service error.") { StatusCode = 502 };
            }
        }
    }
}
