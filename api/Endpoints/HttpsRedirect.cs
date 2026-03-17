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
            _logger.LogInformation("C# HTTP trigger function processed a request.");

            string? code = req.Query["code"];
            string? status = req.Query["status"];

            string redirectUrl = $"http://localhost:5000?";
            if (!string.IsNullOrEmpty(code))
            {
                redirectUrl += $"code={code}";
            }

            if (!string.IsNullOrEmpty(status))
            {
                if (!redirectUrl.EndsWith("?"))
                {
                    redirectUrl += "&";
                }
                redirectUrl += $"status={status}";
            }

            var response = req.CreateResponse(HttpStatusCode.Found);
            response.Headers.Add("Location", redirectUrl);

            return response;
        }
    }
}