using Azure.Storage.Blobs;
using Azure.Storage.Sas;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json.Linq;
using System.Data;

namespace HcWebApi.Endpoints
{
    public class GetPortalUploadSas
    {
        private static readonly HashSet<string> AllowedContainers = new(StringComparer.OrdinalIgnoreCase)
        {
            "newsflash", "harrier", "event-images"
        };

        private readonly ILogger<GetPortalUploadSas> _log;

        public GetPortalUploadSas(ILogger<GetPortalUploadSas> logger)
        {
            _log = logger;
        }

        [Function("GetPortalUploadSas")]
        public async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Anonymous, "post")] HttpRequest req)
        {
            string dbConn = Environment.GetEnvironmentVariable("HcDbConnectionString")
                ?? throw new InvalidOperationException("HcDbConnectionString is not set.");
            string storageConn = Environment.GetEnvironmentVariable("HC_BLOB_STORAGE_CONNECTION_STRING")
                ?? Environment.GetEnvironmentVariable("AzureWebJobsStorage")
                ?? throw new InvalidOperationException("No blob storage connection string configured.");

            string requestBody = await new StreamReader(req.Body).ReadToEndAsync();
            JObject data;
            try { data = JObject.Parse(requestBody); }
            catch { return new BadRequestObjectResult("Invalid JSON body."); }

            string? deviceId    = data["deviceId"]?.ToString();
            string? accessToken = data["accessToken"]?.ToString();
            string? container   = data["container"]?.ToString();
            string? filename    = data["filename"]?.ToString();

            if (string.IsNullOrEmpty(deviceId) || string.IsNullOrEmpty(accessToken) ||
                string.IsNullOrEmpty(container) || string.IsNullOrEmpty(filename))
                return new BadRequestObjectResult("Missing required parameters.");

            if (!AllowedContainers.Contains(container))
                return new BadRequestObjectResult("Invalid container.");

            try
            {
                using var conn = new SqlConnection(dbConn);
                await conn.OpenAsync();

                using var cmd = new SqlCommand("[HC6].[ValidatePortalAuth]", conn)
                {
                    CommandType = CommandType.StoredProcedure
                };
                cmd.Parameters.AddWithValue("@deviceId",          deviceId);
                cmd.Parameters.AddWithValue("@accessToken",       accessToken);
                cmd.Parameters.AddWithValue("@callerProcName",    "hcportal_getPortalUploadSas");
                // Bind the SAS token to the specific container and filename so the auth
                // record is auditable and cannot be replayed for a different upload target.
                string paramString = $"{container}:{filename}";
                cmd.Parameters.AddWithValue("@callerParamString", paramString);

                var errorMsgParam = new SqlParameter("@errorMessage", SqlDbType.NVarChar, 255)
                    { Direction = ParameterDirection.Output };
                var hasherIdParam = new SqlParameter("@hasherId", SqlDbType.UniqueIdentifier)
                    { Direction = ParameterDirection.Output };
                var callerTypeParam = new SqlParameter("@callerType", SqlDbType.Int)
                    { Direction = ParameterDirection.Output };
                cmd.Parameters.Add(errorMsgParam);
                cmd.Parameters.Add(hasherIdParam);
                cmd.Parameters.Add(callerTypeParam);

                await cmd.ExecuteNonQueryAsync();

                if (errorMsgParam.Value != DBNull.Value && errorMsgParam.Value != null)
                {
                    _log.LogWarning("GetPortalUploadSas auth failed: {Message}", errorMsgParam.Value);
                    return new ObjectResult(new { success = false, errorUserMessage = "Authentication failed." })
                        { StatusCode = 403 };
                }
            }
            catch (Exception ex)
            {
                _log.LogError("GetPortalUploadSas auth error: {Message}", ex.Message);
                return new StatusCodeResult(500);
            }

            try
            {
                var blobServiceClient = new BlobServiceClient(storageConn);
                var containerClient   = blobServiceClient.GetBlobContainerClient(container);
                var blobClient        = containerClient.GetBlobClient(filename);

                var sasBuilder = new BlobSasBuilder
                {
                    BlobContainerName = container,
                    BlobName          = filename,
                    Resource          = "b",
                    ExpiresOn         = DateTimeOffset.UtcNow.AddMinutes(15)
                };
                sasBuilder.SetPermissions(BlobSasPermissions.Write | BlobSasPermissions.Create);

                var    sasUri  = blobClient.GenerateSasUri(sasBuilder);
                string blobUrl = blobClient.Uri.ToString();

                return new OkObjectResult(new { sasUrl = sasUri.ToString(), blobUrl });
            }
            catch (Exception ex)
            {
                _log.LogError("GetPortalUploadSas SAS error: {Message}", ex.Message);
                return new StatusCodeResult(500);
            }
        }
    }
}
