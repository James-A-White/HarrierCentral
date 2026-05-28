using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace HcWebApi.Endpoints
{
    /// <summary>
    /// Proxy endpoint that forwards geocode requests to the Logic App URL stored in
    /// HC_GEOCODE_LOGIC_APP_URL. This keeps the SAS token (sig= parameter) server-side
    /// and out of the compiled Flutter portal JS bundle.
    ///
    /// Usage: GET /api/ProxyGeocode?q=Wellington&type=address
    ///
    /// Callers must have their own portal auth — this endpoint uses Anonymous
    /// because the portal already performs device/token auth upstream.
    /// </summary>
    public class ProxyGeocode
    {
        private static readonly HttpClient _httpClient = new()
        {
            Timeout = TimeSpan.FromSeconds(10)
        };

        private readonly ILogger<ProxyGeocode> _log;

        public ProxyGeocode(ILogger<ProxyGeocode> logger)
        {
            _log = logger;
        }

        [Function("ProxyGeocode")]
        public async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "ProxyGeocode")] HttpRequest req)
        {
            string? logicAppUrl = Environment.GetEnvironmentVariable("HC_GEOCODE_LOGIC_APP_URL");
            if (string.IsNullOrEmpty(logicAppUrl))
            {
                _log.LogError("HC_GEOCODE_LOGIC_APP_URL is not configured.");
                return new ObjectResult("Geocode service unavailable.") { StatusCode = 503 };
            }

            // Forward q and type query params to the Logic App
            string? q    = req.Query["q"].ToString();
            string? type = req.Query["type"].ToString();

            var uriBuilder = new UriBuilder(logicAppUrl);
            var existingQuery = System.Web.HttpUtility.ParseQueryString(uriBuilder.Query);
            if (!string.IsNullOrEmpty(q))    existingQuery["q"]    = q;
            if (!string.IsNullOrEmpty(type)) existingQuery["type"] = type;
            uriBuilder.Query = existingQuery.ToString();

            string targetUrl = uriBuilder.ToString();
            _log.LogInformation("ProxyGeocode forwarding request");

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
                _log.LogWarning("ProxyGeocode: upstream request timed out.");
                return new ObjectResult("Geocode service timed out.") { StatusCode = 504 };
            }
            catch (Exception ex)
            {
                _log.LogError("ProxyGeocode upstream error: {Message}", ex.Message);
                return new ObjectResult("Geocode service error.") { StatusCode = 502 };
            }
        }
    }
}
