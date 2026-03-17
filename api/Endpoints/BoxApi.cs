using System;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text.Json;
using System.Threading.Tasks;
using Azure;
using Azure.Data.Tables;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;
using Microsoft.AspNetCore.WebUtilities;

namespace HcWebApi.Endpoints
{
    // Table entity to store Box tokens per session handle
    public class BoxTokenEntity : ITableEntity
    {
        public string PartitionKey { get; set; } = "BOX";  // fixed partition
        public string RowKey { get; set; } = string.Empty;   // session handle GUID
        public string Email { get; set; } = string.Empty;    // user email
        public string AccessToken { get; set; } = string.Empty;
        public string RefreshToken { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
        public ETag ETag { get; set; }
        public DateTimeOffset? Timestamp { get; set; }
    }

    public class BoxProxyFunctions
    {
        private readonly HttpClient _http;
        private readonly ILogger _log;
        private readonly TableClient _tableClient;
        private readonly string _clientId = Environment.GetEnvironmentVariable("BOX_CLIENT_ID")!;
        private readonly string _clientSecret = Environment.GetEnvironmentVariable("BOX_CLIENT_SECRET")!;
        private readonly string _redirectUri = Environment.GetEnvironmentVariable("BOX_REDIRECT_URI")!;
        private readonly string _appBaseUrl = Environment.GetEnvironmentVariable("APP_BASE_URL")!;

        public BoxProxyFunctions(
            IHttpClientFactory httpFactory,
            ILogger<BoxProxyFunctions> logger,
            TableClient tableClient
        )
        {
            _http = httpFactory.CreateClient();
            _log = logger;
            _tableClient = tableClient;
            _tableClient.CreateIfNotExists();
        }

        [Function("GetAuthUrl")]
        public HttpResponseData GetAuthUrl(
            [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "auth/url")] HttpRequestData req)
        {
            var query = QueryHelpers.ParseQuery(req.Url.Query);
            var state = query.TryGetValue("state", out var vals)
                        ? vals.First()
                        : Guid.NewGuid().ToString();

            var uri = new UriBuilder("https://account.box.com/api/oauth2/authorize")
            {
                Query = $"response_type=code&client_id={_clientId}&redirect_uri={WebUtility.UrlEncode(_redirectUri)}&state={state}"
            }.ToString();

            var resp = req.CreateResponse(HttpStatusCode.Found);
            resp.Headers.Add("Location", uri);
            return resp;
        }

        // Helper to get email from Box
        private async Task<string> GetUserEmailAsync(string accessToken)
        {
            var req = new HttpRequestMessage(HttpMethod.Get, "https://api.box.com/2.0/users/me");
            req.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
            var res = await _http.SendAsync(req);
            res.EnsureSuccessStatusCode();
            using var doc = JsonDocument.Parse(await res.Content.ReadAsStringAsync());
            return doc.RootElement.GetProperty("login").GetString()!;
        }

        [Function("AuthCallback")]
        public async Task<HttpResponseData> AuthCallback(
            [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "auth/callback")] HttpRequestData req)
        {
            var query = QueryHelpers.ParseQuery(req.Url.Query);
            if (!query.TryGetValue("code", out var codeVals))
                return req.CreateResponse(HttpStatusCode.BadRequest);

            var code = codeVals.First();
            var form = new FormUrlEncodedContent(new[]
            {
                new KeyValuePair<string,string>("grant_type",    "authorization_code"),
                new KeyValuePair<string,string>("code",          code),
                new KeyValuePair<string,string>("client_id",     _clientId),
                new KeyValuePair<string,string>("client_secret", _clientSecret),
                new KeyValuePair<string,string>("redirect_uri",  _redirectUri),
            });

            var tokenRes = await _http.PostAsync("https://api.box.com/oauth2/token", form);

            var body = await tokenRes.Content.ReadAsStringAsync();
            _log.LogError("Box token call failed: {Status} — {Body}",
             (int)tokenRes.StatusCode, body);

            tokenRes.EnsureSuccessStatusCode();
            using var doc = JsonDocument.Parse(body);

            var at = doc.RootElement.GetProperty("access_token").GetString()!;
            var rt = doc.RootElement.GetProperty("refresh_token").GetString()!;

            // Create a unique handle for this session
            var handle = Guid.NewGuid().ToString();
            var userEmail = await GetUserEmailAsync(at);

            // Store entity with handle as RowKey
            var entity = new BoxTokenEntity
            {
                RowKey = handle,
                Email = userEmail,
                AccessToken = at,
                RefreshToken = rt,
                CreatedAt = DateTime.UtcNow
            };
            await _tableClient.AddEntityAsync(entity);

            // Redirect back sending only the handle
            var backUrl = $"{_appBaseUrl}/auth?handle={handle}";
            var resp = req.CreateResponse(HttpStatusCode.Found);
            resp.Headers.Add("Location", backUrl);
            return resp;
        }

        [Function("GetFiles")]
        public async Task<HttpResponseData> GetFiles(
            [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "files")] HttpRequestData req)
        {
            var qp = QueryHelpers.ParseQuery(req.Url.Query);
            if (!qp.TryGetValue("handle", out var handleVals))
                return req.CreateResponse(HttpStatusCode.BadRequest);
            var handle = handleVals.First();

            // Retrieve tokens by handle
            var stored = await _tableClient.GetEntityAsync<BoxTokenEntity>("BOX", handle);
            var token = stored.Value.AccessToken;
            // var folder = qp.TryGetValue("folderId", out var folderVals)
            //              ? folderVals.First()
            //              : "0";

            var folder = "0";

            var boxReq = new HttpRequestMessage(HttpMethod.Get,
                              $"https://api.box.com/2.0/folders/{folder}/items");
            boxReq.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);

            var boxRes = await _http.SendAsync(boxReq);
            var clientRes = req.CreateResponse(boxRes.StatusCode);
            await clientRes.WriteStringAsync(await boxRes.Content.ReadAsStringAsync());
            return clientRes;
        }

        [Function("DownloadFile")]
        public async Task<HttpResponseData> DownloadFile(
            [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "files/{id}/content")] HttpRequestData req,
            string id)
        {
            var qp = QueryHelpers.ParseQuery(req.Url.Query);
            if (!qp.TryGetValue("handle", out var handleVals))
                return req.CreateResponse(HttpStatusCode.BadRequest);
            var handle = handleVals.First();

            var stored = await _tableClient.GetEntityAsync<BoxTokenEntity>("BOX", handle);
            var token = stored.Value.AccessToken;

            var boxReq = new HttpRequestMessage(HttpMethod.Get,
                          $"https://api.box.com/2.0/files/{id}/content");
            boxReq.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);

            var boxRes = await _http.SendAsync(boxReq, HttpCompletionOption.ResponseHeadersRead);
            var clientRes = req.CreateResponse(boxRes.StatusCode);

            if (boxRes.Content.Headers.ContentType != null)
                clientRes.Headers.Add("Content-Type", boxRes.Content.Headers.ContentType.ToString());
            if (boxRes.Content.Headers.ContentDisposition != null)
                clientRes.Headers.Add("Content-Disposition", boxRes.Content.Headers.ContentDisposition.ToString());

            await boxRes.Content.CopyToAsync(clientRes.Body);
            return clientRes;
        }
    }
}
