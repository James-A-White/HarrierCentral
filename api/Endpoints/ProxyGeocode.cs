using System.Net;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace HcWebApi.Endpoints
{
    /// <summary>
    /// Proxy endpoint that calls Azure Maps fuzzy search directly, keeping the
    /// subscription key server-side and out of the compiled Flutter portal JS bundle.
    ///
    /// Usage: GET /api/ProxyGeocode?q=Wellington[&lat=51.5&lon=-0.1&countryCodes=GB]
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
            string? subscriptionKey = Environment.GetEnvironmentVariable("AzureMapsSubscriptionKey");
            if (string.IsNullOrEmpty(subscriptionKey))
            {
                _log.LogError("AzureMapsSubscriptionKey is not configured.");
                return new ObjectResult("Geocode service unavailable.") { StatusCode = 503 };
            }

            string? q            = req.Query["q"].ToString();
            string? lat          = req.Query["lat"].ToString();
            string? lon          = req.Query["lon"].ToString();
            string? countryCodes = req.Query["countryCodes"].ToString();

            if (string.IsNullOrWhiteSpace(q))
                return new BadRequestObjectResult("Missing required parameter: q");

            var qs = System.Web.HttpUtility.ParseQueryString(string.Empty);
            qs["subscription-key"] = subscriptionKey;
            qs["api-version"]      = "1.0";
            qs["typeahead"]        = "false";
            qs["limit"]            = "25";
            qs["minFuzzyLevel"]    = "1";
            qs["maxFuzzyLevel"]    = "4";
            qs["query"]            = q;
            if (!string.IsNullOrEmpty(lat))          qs["lat"]        = lat;
            if (!string.IsNullOrEmpty(lon))          qs["lon"]        = lon;
            if (!string.IsNullOrEmpty(countryCodes)) qs["countrySet"] = countryCodes;

            string targetUrl = "https://atlas.microsoft.com/search/fuzzy/JSON?" + qs.ToString();

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
                _log.LogWarning("ProxyGeocode: Azure Maps request timed out.");
                return new ObjectResult("Geocode service timed out.") { StatusCode = 504 };
            }
            catch (Exception ex)
            {
                _log.LogError("ProxyGeocode error: {Message}", ex.Message);
                return new ObjectResult("Geocode service error.") { StatusCode = 502 };
            }
        }
    }
}
