using System.Net;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;

namespace HcWebApi.Endpoints // Replace with your actual namespace
{
    public class ProxyFunction
    {
        private readonly ILogger _logger;

        public ProxyFunction(ILoggerFactory loggerFactory)
        {
            _logger = loggerFactory.CreateLogger<ProxyFunction>();
        }

        [Function("Proxy")]
        public HttpResponseData Run([HttpTrigger(AuthorizationLevel.Anonymous, "get")] HttpRequestData req)
        {
            // Endpoint disabled — was routing to localhost:5000 in production.
            _logger.LogWarning("Proxy endpoint called but is disabled.");
            var response = req.CreateResponse(HttpStatusCode.Gone);
            return response;
        }
    }
}