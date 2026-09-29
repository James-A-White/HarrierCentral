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
    /// <summary>
    /// A 15-minute, write-only SAS for one chat photo (E9.F1.S11, 2026-09-29).
    ///
    /// Path: chat-photos/{yyyy}/{MM}/{userId}-{photoGuid}.jpg. The userId comes
    /// from HC6.hcapp_getChatPhotoUploadToken (the token's user), never from the
    /// request, so nobody can write under someone else's name. Posting the photo
    /// to a chat is a separate call — the send SPs — and HC6.ChatMessageKindError
    /// refuses any "photo" outside this container.
    ///
    /// Called by the app directly, and by the public web's server on behalf of a
    /// signed-in member (the browser is a device, E9.F7). The portal uses
    /// GetPortalUploadSas with the chat-photos container instead.
    /// </summary>
    public class GetChatPhotoUploadToken
    {
        private const string Container = "chat-photos";
        private readonly ILogger<GetChatPhotoUploadToken> _log;

        public GetChatPhotoUploadToken(ILogger<GetChatPhotoUploadToken> logger)
        {
            _log = logger;
        }

        [Function("GetChatPhotoUploadToken")]
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
            string? photoGuid   = data["photoGuid"]?.ToString();

            if (string.IsNullOrEmpty(deviceId) || string.IsNullOrEmpty(accessToken) ||
                !Guid.TryParse(photoGuid, out var photoId))
                return new BadRequestObjectResult("Missing required parameters.");

            string? userId = null;
            try
            {
                using var conn = new SqlConnection(dbConn);
                await conn.OpenAsync();
                using var cmd = new SqlCommand("[HC6].[hcapp_getChatPhotoUploadToken]", conn)
                {
                    CommandType = CommandType.StoredProcedure
                };
                cmd.Parameters.AddWithValue("@deviceId",    deviceId);
                cmd.Parameters.AddWithValue("@accessToken", accessToken);
                cmd.Parameters.AddWithValue("@photoGuid",   photoId);

                using var reader = await cmd.ExecuteReaderAsync();
                // Rowset 0: { success, errorCode, errorType }
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
                }
                // Rowset 1: { userId }
                if (await reader.NextResultAsync() && await reader.ReadAsync())
                    userId = reader["userId"]?.ToString()?.ToLowerInvariant();
            }
            catch (Exception ex)
            {
                _log.LogError("GetChatPhotoUploadToken SQL error: {Message}", ex.Message);
                return new StatusCodeResult(500);
            }

            if (string.IsNullOrEmpty(userId))
                return new StatusCodeResult(500);

            try
            {
                var now = DateTime.UtcNow;
                string blobPath = $"{now:yyyy}/{now:MM}/{userId}-{photoId.ToString().ToLowerInvariant()}.jpg";

                var containerClient = new BlobServiceClient(storageConn).GetBlobContainerClient(Container);
                // Best-effort: the container may exist already, or public access may be
                // off at the account level. Neither should block the SAS.
                try
                {
                    await containerClient.CreateIfNotExistsAsync(Azure.Storage.Blobs.Models.PublicAccessType.Blob);
                }
                catch (Exception ex)
                {
                    _log.LogWarning("chat-photos container creation skipped: {Message}", ex.Message);
                }

                var blobClient = containerClient.GetBlobClient(blobPath);
                var sasBuilder = new BlobSasBuilder
                {
                    BlobContainerName = Container,
                    BlobName          = blobPath,
                    Resource          = "b",
                    ExpiresOn         = DateTimeOffset.UtcNow.AddMinutes(15)
                };
                sasBuilder.SetPermissions(BlobSasPermissions.Write | BlobSasPermissions.Create);

                return new OkObjectResult(new
                {
                    sasUrl  = blobClient.GenerateSasUri(sasBuilder).ToString(),
                    blobUrl = blobClient.Uri.ToString()
                });
            }
            catch (Exception ex)
            {
                _log.LogError("GetChatPhotoUploadToken SAS error: {Message}", ex.Message);
                return new ObjectResult(new { error = ex.Message }) { StatusCode = 500 };
            }
        }
    }
}
