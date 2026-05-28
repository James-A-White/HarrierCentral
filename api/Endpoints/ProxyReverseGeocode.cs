using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace HcWebApi.Endpoints
{
    /// <summary>
    /// Proxy endpoint that forwards reverse-geocode requests to the upstream URL stored in
    /// HC_REVERSE_GEOCODE_URL. This ensures the hcazurefunctions7 upstream URL stays
    /// server-side only and is never exposed to the Flutter client.
    ///
    /// Usage: GET/POST /api/ProxyReverseGeocode[?...]
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
            [HttpTrigger(AuthorizationLevel.Anonymous, "get", "post", Route = "ProxyReverseGeocode")] HttpRequest req)
        {
            string? upstreamUrl = Environment.GetEnvironmentVariable("HC_REVERSE_GEOCODE_URL");
            if (string.IsNullOrEmpty(upstreamUrl))
            {
                _log.LogError("HC_REVERSE_GEOCODE_URL is not configured.");
                return new ObjectResult("Reverse geocode service unavailable.") { StatusCode = 503 };
            }

            // Forward all incoming query params to the upstream URL
            string targetUrl = upstreamUrl;
            if (req.QueryString.HasValue)
            {
                targetUrl += (upstreamUrl.Contains('?') ? "&" : "?") + req.QueryString.Value!.TrimStart('?');
            }

            _log.LogInformation("ProxyReverseGeocode forwarding {Method} request", req.Method);

            try
            {
                using var cts = new CancellationTokenSource(TimeSpan.FromSeconds(10));
                HttpResponseMessage upstreamResponse;

                if (req.Method.Equals("POST", StringComparison.OrdinalIgnoreCase))
                {
                    string requestBody = await new StreamReader(req.Body).ReadToEndAsync();
                    var content = new StringContent(
                        requestBody,
                        System.Text.Encoding.UTF8,
                        req.ContentType ?? "application/json");
                    upstreamResponse = await _httpClient.PostAsync(targetUrl, content, cts.Token);
                }
                else
                {
                    upstreamResponse = await _httpClient.GetAsync(targetUrl, cts.Token);
                }

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
                _log.LogWarning("ProxyReverseGeocode: upstream request timed out.");
                return new ObjectResult("Reverse geocode service timed out.") { StatusCode = 504 };
            }
            catch (Exception ex)
            {
                _log.LogError("ProxyReverseGeocode upstream error: {Message}", ex.Message);
                return new ObjectResult("Reverse geocode service error.") { StatusCode = 502 };
            }
        }
    }
}
