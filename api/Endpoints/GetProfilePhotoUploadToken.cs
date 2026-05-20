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
    public class GetProfilePhotoUploadToken
    {
        private readonly ILogger<GetProfilePhotoUploadToken> _log;

        public GetProfilePhotoUploadToken(ILogger<GetProfilePhotoUploadToken> logger)
        {
            _log = logger;
        }

        [Function("GetProfilePhotoUploadToken")]
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

            if (string.IsNullOrEmpty(deviceId) || string.IsNullOrEmpty(accessToken))
                return new BadRequestObjectResult("Missing required parameters.");

            string? userId = null;

            try
            {
                using var conn = new SqlConnection(dbConn);
                await conn.OpenAsync();

                using var cmd = new SqlCommand("[HC6].[hcapp_getProfilePhotoUploadToken]", conn)
                {
                    CommandType = CommandType.StoredProcedure
                };
                cmd.Parameters.AddWithValue("@deviceId",    deviceId);
                cmd.Parameters.AddWithValue("@accessToken", accessToken);

                using var reader = await cmd.ExecuteReaderAsync();
                if (await reader.ReadAsync())
                {
                    bool success = Convert.ToBoolean(reader["success"]);
                    if (!success)
                    {
                        var errorCode = reader["errorCode"];
                        var errorType = reader["errorType"];
                        string? errorMsg = null;
                        if (await reader.NextResultAsync() && await reader.ReadAsync())
                            errorMsg = reader["errorUserMessage"]?.ToString();
                        return new ObjectResult(new { success = false, errorCode, errorType, errorUserMessage = errorMsg })
                            { StatusCode = 403 };
                    }
                    userId = reader["userId"]?.ToString();
                }
            }
            catch (Exception ex)
            {
                _log.LogError("GetProfilePhotoUploadToken SQL error: {Message}", ex.Message);
                return new StatusCodeResult(500);
            }

            if (string.IsNullOrEmpty(userId))
                return new StatusCodeResult(500);

            try
            {
                string blobPath = $"{userId}.jpg";
                var blobServiceClient = new BlobServiceClient(storageConn);
                var containerClient = blobServiceClient.GetBlobContainerClient("profile-photos");
                // Container already exists — do not alter its access policy
                var blobClient = containerClient.GetBlobClient(blobPath);

                var sasBuilder = new BlobSasBuilder
                {
                    BlobContainerName = "profile-photos",
                    BlobName          = blobPath,
                    Resource          = "b",
                    ExpiresOn         = DateTimeOffset.UtcNow.AddMinutes(15)
                };
                sasBuilder.SetPermissions(BlobSasPermissions.Write | BlobSasPermissions.Create);

                var sasUri  = blobClient.GenerateSasUri(sasBuilder);
                string blobUrl = blobClient.Uri.ToString();

                return new OkObjectResult(new { sasUrl = sasUri.ToString(), blobUrl });
            }
            catch (Exception ex)
            {
                _log.LogError("GetProfilePhotoUploadToken SAS generation error: {Message}", ex.Message);
                return new ObjectResult(new { error = ex.Message }) { StatusCode = 500 };
            }
        }
    }
}
