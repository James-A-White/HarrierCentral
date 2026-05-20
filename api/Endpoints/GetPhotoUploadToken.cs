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
    public class GetPhotoUploadToken
    {
        private readonly ILogger<GetPhotoUploadToken> _log;

        public GetPhotoUploadToken(ILogger<GetPhotoUploadToken> logger)
        {
            _log = logger;
        }

        [Function("GetPhotoUploadToken")]
        public async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Anonymous, "post")] HttpRequest req)
        {
            string dbConn = Environment.GetEnvironmentVariable("HcDbConnectionString")
                ?? throw new InvalidOperationException("HcDbConnectionString is not set.");
            // HC_BLOB_STORAGE_CONNECTION_STRING must point to the harriercentral storage
            // account and include the account key (required for SAS token signing).
            string storageConn = Environment.GetEnvironmentVariable("HC_BLOB_STORAGE_CONNECTION_STRING")
                ?? Environment.GetEnvironmentVariable("AzureWebJobsStorage")
                ?? throw new InvalidOperationException("No blob storage connection string configured.");

            string requestBody = await new StreamReader(req.Body).ReadToEndAsync();
            JObject data;
            try { data = JObject.Parse(requestBody); }
            catch { return new BadRequestObjectResult("Invalid JSON body."); }

            string? deviceId   = data["deviceId"]?.ToString();
            string? accessToken = data["accessToken"]?.ToString();
            string? kennelId   = data["kennelId"]?.ToString();
            string? photoGuid  = data["photoGuid"]?.ToString();

            if (string.IsNullOrEmpty(deviceId) || string.IsNullOrEmpty(accessToken) ||
                string.IsNullOrEmpty(kennelId) || string.IsNullOrEmpty(photoGuid))
                return new BadRequestObjectResult("Missing required parameters.");

            string? userId = null;

            try
            {
                using var conn = new SqlConnection(dbConn);
                await conn.OpenAsync();

                using var cmd = new SqlCommand("[HC6].[hcapp_getPhotoUploadToken]", conn)
                {
                    CommandType = CommandType.StoredProcedure
                };
                cmd.Parameters.AddWithValue("@deviceId",    deviceId);
                cmd.Parameters.AddWithValue("@accessToken", accessToken);
                cmd.Parameters.AddWithValue("@kennelId",    kennelId);
                cmd.Parameters.AddWithValue("@photoGuid",   photoGuid);

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
                _log.LogError("GetPhotoUploadToken SQL error: {Message}", ex.Message);
                return new StatusCodeResult(500);
            }

            if (string.IsNullOrEmpty(userId))
                return new StatusCodeResult(500);

            try
            {
                string blobPath = $"{kennelId}/{userId}-{photoGuid}.jpg";
                var blobServiceClient = new BlobServiceClient(storageConn);
                var containerClient = blobServiceClient.GetBlobContainerClient("kennel-photos");

                // Best-effort container creation — may already exist or public access may
                // be disabled at the account level. Neither case should block SAS generation.
                try
                {
                    await containerClient.CreateIfNotExistsAsync(
                        Azure.Storage.Blobs.Models.PublicAccessType.Blob);
                }
                catch (Exception ex)
                {
                    _log.LogWarning("kennel-photos container creation skipped: {Message}", ex.Message);
                }

                var blobClient = containerClient.GetBlobClient(blobPath);

                var sasBuilder = new BlobSasBuilder
                {
                    BlobContainerName = "kennel-photos",
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
                _log.LogError("GetPhotoUploadToken SAS generation error: {Message}", ex.Message);
                return new ObjectResult(new { error = ex.Message }) { StatusCode = 500 };
            }
        }
    }
}
