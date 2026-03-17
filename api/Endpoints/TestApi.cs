using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System.Data;
using System.Diagnostics;

//{"queryType":"getEvents","publicHasherId":"B6BAFD0D-5D2E-41CD-8495-811D551F01D0","accessToken":"asdfasdfasfasdfasdfasdf","publicKennelIds":"6EDC3585-C1F8-4800-B189-23A4036830C9"}

namespace HcWebApi.Endpoints
{

    public class TestApi
    {
        private readonly ILogger<TestApi> log;

        public TestApi(ILogger<TestApi> logger)
        {
            log = logger;
        }

        [Function("TestApi")]
        public static IActionResult Run([HttpTrigger(AuthorizationLevel.Anonymous, "get")] HttpRequest req)
        {
            // Return the multiple result sets as JSON
            return new OkObjectResult("Test successful");

        }




    }
}

