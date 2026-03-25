using Azure.Data.Tables;
using Google.Apis.Auth.OAuth2;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System.Data;
using System.Diagnostics;
using System.Text;

namespace HcWebApi.Endpoints
{
    public class PortalApiHC6
    {
        private readonly ILogger<PortalApiHC6> log;
        private TableClient _tableClient;

        public PortalApiHC6(ILogger<PortalApiHC6> logger)
        {
            log = logger;
            var connectionString = Environment.GetEnvironmentVariable("AzureWebJobsStorage");
            var serviceClient = new TableServiceClient(connectionString);
            _tableClient = serviceClient.GetTableClient("FcmTokensForAppApi");
            _tableClient.CreateIfNotExists();
        }

        [Function("PortalApiHC6")]
        public async Task<IActionResult> Run([HttpTrigger(AuthorizationLevel.Anonymous, "post")] HttpRequest req)
        {
            string connectionString = Environment.GetEnvironmentVariable("HcDbConnectionString")
                ?? throw new InvalidOperationException("HcDbConnectionString is not set in the environment.");

            string requestBody = await new StreamReader(req.Body).ReadToEndAsync();
            dynamic data = JsonConvert.DeserializeObject(requestBody)
                ?? throw new InvalidOperationException("Failed to deserialize the request body.");

            // Validate required parameters
            if (data.deviceId == null || data.accessToken == null)
            {
                log.LogInformation("Missing required parameters: deviceId or accessToken.");
                return new BadRequestObjectResult("Missing required parameters: deviceId or accessToken.");
            }

            if (data.queryType == null)
            {
                log.LogInformation("Missing query type.");
                return new BadRequestObjectResult("Missing query type.");
            }

            string queryType = (string)data.queryType;
            string deviceId = (string)data.deviceId;

            // Block the internal auth helper from being called directly
            if (string.Equals(queryType, "ValidatePortalAuth", StringComparison.OrdinalIgnoreCase))
            {
                log.LogWarning("Blocked direct call to internal SP: ValidatePortalAuth.");
                return new BadRequestObjectResult("Invalid query type.");
            }

            log.LogInformation($"HC6 Portal API Called: QueryType = {queryType}, DeviceId = {deviceId}");

            try
            {
                List<List<Dictionary<string, object>>> multipleResults = [];

                using (SqlConnection conn = new(connectionString))
                {
                    await conn.OpenAsync();

                    string procedureName = $"[HC6].[hcportal_{queryType}]";

                    using SqlCommand cmd = new(procedureName, conn);
                    cmd.CommandType = CommandType.StoredProcedure;

                    JObject jsonData = JObject.Parse(requestBody);

                    foreach (var property in jsonData.Properties())
                    {
                        if (property.Name == "queryType") continue;

                        string parameterName = "@" + property.Name;
                        object? parameterValue = (property.Value == null || property.Value.Type == JTokenType.Null)
                            ? DBNull.Value
                            : property.Value.ToObject<object>();

                        if (parameterName != null && parameterValue != null)
                            cmd.Parameters.AddWithValue(parameterName, parameterValue);
                    }

                    using SqlDataReader reader = await cmd.ExecuteReaderAsync();
                    try
                    {
                        do
                        {
                            List<Dictionary<string, object>> resultSet = [];
                            while (await reader.ReadAsync())
                            {
                                Dictionary<string, object> row = [];
                                for (int i = 0; i < reader.FieldCount; i++)
                                {
                                    string? name = reader.GetName(i);
                                    object? value = reader.IsDBNull(i) ? null : reader.GetValue(i);
                                    if (name != null && value != null)
                                        row[name] = value;
                                }
                                resultSet.Add(row);
                            }
                            multipleResults.Add(resultSet);
                        }
                        while (await reader.NextResultAsync());
                    }
                    catch (Exception ex)
                    {
                        Debug.Print(ex.ToString());
                    }
                }

                // Log every request to LOG.GeneralLog (HC6 SPs no longer do this themselves)
                await LogRequestAsync(connectionString, queryType, req);

                // Detect HC6 error envelope: any rowset, single row, Success = 0
                var errorRowset = multipleResults.FirstOrDefault(rs =>
                    rs.Count == 1 &&
                    rs[0].TryGetValue("Success", out var sv) &&
                    Convert.ToInt32(sv) == 0);

                if (errorRowset != null)
                {
                    errorRowset[0].TryGetValue("ErrorMessage", out var errMsgVal);
                    string errorMessage = errMsgVal?.ToString() ?? "Unknown error";

                    await LogErrorAsync(connectionString, queryType, deviceId, (string)data.accessToken, errorMessage);
                    log.LogWarning($"HC6 SP error [{queryType}]: {errorMessage}");

                    return new BadRequestObjectResult(new { success = false, errorMessage });
                }

                // Post-SP side effects
                switch (queryType)
                {
                    case "addEditEvent":
                        await UpdateGoogleCalendar(log);
                        break;
                    case "sendEventMessage":
                        await SendNotifications(multipleResults, log);
                        break;
                    case "markEventChatRead":
                        await SendReadSyncAsync(multipleResults, (string)data.publicEventId, log);
                        break;
                }

                return new OkObjectResult(multipleResults);
            }
            catch (Exception ex)
            {
                log.LogError($"Error executing stored procedure: {ex.Message}");
                return new BadRequestObjectResult($"Error executing stored procedure: {ex.Message}");
            }
        }

        private async Task LogRequestAsync(string connectionString, string spName, HttpRequest req)
        {
            try
            {
                string ipAddress = req.HttpContext.Connection.RemoteIpAddress?.ToString() ?? string.Empty;
                string logSource = $"Admin Portal: hcportal_{spName}";
                if (logSource.Length > 50) logSource = logSource[..50];  // LOG.GeneralLog.LogSource is NVARCHAR(50)

                using SqlConnection conn = new(connectionString);
                await conn.OpenAsync();
                using SqlCommand cmd = new(
                    "INSERT INTO LOG.GeneralLog (LogSource, Message, Timestamp) VALUES (@logSource, @message, SYSUTCDATETIME())",
                    conn);
                cmd.Parameters.AddWithValue("@logSource", logSource);
                cmd.Parameters.AddWithValue("@message", ipAddress);
                await cmd.ExecuteNonQueryAsync();
            }
            catch (Exception ex)
            {
                log.LogError($"Failed to write to GeneralLog: {ex.Message}");
            }
        }

        private async Task LogErrorAsync(string connectionString, string spName, string deviceId, string accessToken, string? errorMessage)
        {
            try
            {
                using SqlConnection conn = new(connectionString);
                await conn.OpenAsync();
                using SqlCommand cmd = new(
                    @"INSERT INTO HC.ErrorLog
                        (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, string_1, createdAt, updatedAt)
                      VALUES
                        (NEWID(), 'HC6-API', @errorName, @errorDescription, @procName, @userId, @accessToken, SYSUTCDATETIME(), SYSUTCDATETIME())",
                    conn);
                cmd.Parameters.AddWithValue("@errorName", $"HC6 Portal Error: {spName}");
                cmd.Parameters.AddWithValue("@errorDescription", (object?)errorMessage ?? DBNull.Value);
                cmd.Parameters.AddWithValue("@procName", $"[HC6].[hcportal_{spName}]");
                // userId column is UNIQUEIDENTIFIER — store deviceId to preserve audit trail
                cmd.Parameters.AddWithValue("@userId", Guid.TryParse(deviceId, out var deviceGuid)
                    ? (object)deviceGuid
                    : DBNull.Value);
                cmd.Parameters.AddWithValue("@accessToken", (object?)accessToken ?? DBNull.Value);
                await cmd.ExecuteNonQueryAsync();
            }
            catch (Exception ex)
            {
                log.LogError($"Failed to write to ErrorLog: {ex.Message}");
            }
        }

        public async Task SendNotifications(List<List<Dictionary<string, object>>> multipleResults, ILogger logger)
        {
            try
            {
                string? accessToken = await GetFirebaseAccessTokenAsync();

                logger.LogInformation("Processing event notifications...");

                if (multipleResults == null || multipleResults.Count < 3)
                {
                    logger.LogError("sendEventMessage returned fewer than 3 rowsets — cannot send notifications.");
                    return;
                }

                var eventDetailsList = System.Text.Json.JsonSerializer.Deserialize<List<EventMessage>>(System.Text.Json.JsonSerializer.Serialize(multipleResults[0]));
                var notificationList = System.Text.Json.JsonSerializer.Deserialize<List<Recipient>>(System.Text.Json.JsonSerializer.Serialize(multipleResults[1]));
                var inAppMessageList = System.Text.Json.JsonSerializer.Deserialize<List<Recipient>>(System.Text.Json.JsonSerializer.Serialize(multipleResults[2]));

                if (eventDetailsList == null || notificationList == null || inAppMessageList == null)
                {
                    logger.LogError("Failed to deserialize JSON into objects.");
                    return;
                }

                foreach (var eventMessage in eventDetailsList)
                    foreach (var recipient in notificationList)
                        if (!string.IsNullOrEmpty(recipient.FcmToken))
                            await SendNotificationAsync(recipient.FcmToken, eventMessage, accessToken, true, logger);

                foreach (var eventMessage in eventDetailsList)
                    foreach (var recipient in inAppMessageList)
                        if (!string.IsNullOrEmpty(recipient.FcmToken))
                            await SendNotificationAsync(recipient.FcmToken, eventMessage, accessToken, false, logger);

                logger.LogInformation("All notifications sent successfully.");
            }
            catch (Exception ex)
            {
                logger.LogError($"Error processing notifications: {ex.Message}");
            }
        }

        private static readonly HttpClient _httpClient = new();
        private const string FcmUrl = "https://fcm.googleapis.com/v1/projects/harrier-central-mobile/messages:send";

        public static async Task SendNotificationAsync(string fcmToken, EventMessage eventMessage, string? accessToken, bool isNotification, ILogger log)
        {
            try
            {
                var messageBody = new
                {
                    message = new
                    {
                        token = fcmToken,
                        notification = isNotification ? new { title = eventMessage.MessageTitle, body = eventMessage.MessageContent } : null,
                        data = new
                        {
                            eventMessage.EventId,
                            eventMessage.PublicEventId,
                            Title = eventMessage.MessageTitle,
                            eventMessage.UserId,
                            eventMessage.UserDisplayName,
                            eventMessage.UserPhoto,
                            Message = eventMessage.MessageContent,
                            eventMessage.MessageId,
                            MessageRelesabilityFlags = eventMessage.MessageRelesabilityFlags.ToString(),
                            MessageType = eventMessage.MessageType.ToString(),
                        },
                        android = isNotification ? new { priority = "high", notification = new { sound = "default" } } : null,
                        apns = new
                        {
                            headers = new Dictionary<string, string> { ["apns-priority"] = "10" },
                            payload = new { aps = new { sound = "default" } }
                        }
                    },
                };

                var jsonPayload = System.Text.Json.JsonSerializer.Serialize(messageBody);
                var stringContent = new StringContent(jsonPayload, Encoding.UTF8);
                stringContent.Headers.ContentType = new System.Net.Http.Headers.MediaTypeHeaderValue("application/json");

                var request = new HttpRequestMessage(HttpMethod.Post, FcmUrl)
                {
                    Headers = { { "Authorization", $"Bearer {accessToken}" } },
                    Content = stringContent
                };

                var response = await _httpClient.SendAsync(request);
                if (response.IsSuccessStatusCode)
                {
                    log.LogInformation("FCM message sent successfully.");
                }
                else
                {
                    string errorJson = await response.Content.ReadAsStringAsync();
                    log.LogError("Error sending FCM message: {ErrorJson}", errorJson);
                    if (errorJson.Contains("BadDeviceToken") || errorJson.Contains("not a valid FCM registration token"))
                        await DeleteFcmToken(fcmToken, log);
                }
            }
            catch (Exception ex)
            {
                log.LogError("Exception while sending FCM message: {Message}", ex.Message);
            }
        }

        public async Task<string?> GetFirebaseAccessTokenAsync()
        {
            const string partitionKey = "FcmTokens";
            const string rowKey = "PortalApiToken";

            try
            {
                var response = await _tableClient.GetEntityIfExistsAsync<DeviceTokenEntity>(partitionKey, rowKey);

                if (response.HasValue && response.Value != null)
                {
                    if (DateTimeOffset.UtcNow - response.Value.LastUpdated < TimeSpan.FromMinutes(55))
                        return response.Value.FcmToken;

                    log.LogInformation("Firebase access token expired — refreshing.");
                }

                string jsonUrl = "https://harriercentral.blob.core.windows.net/credentials/firebase_credentials.json";
                var httpResponse = await _httpClient.GetAsync(jsonUrl);

                if (!httpResponse.IsSuccessStatusCode)
                {
                    log.LogError("Failed to retrieve Firebase service account JSON from Azure Blob Storage.");
                    return null;
                }

                string jsonContent = await httpResponse.Content.ReadAsStringAsync();
                GoogleCredential credential = GoogleCredential
                    .FromJson(jsonContent)
                    .CreateScoped(["https://www.googleapis.com/auth/firebase.messaging"]);

                var accessToken = await credential.UnderlyingCredential.GetAccessTokenForRequestAsync();

                await _tableClient.UpsertEntityAsync(new DeviceTokenEntity
                {
                    PartitionKey = partitionKey,
                    RowKey = rowKey,
                    FcmToken = accessToken,
                    LastUpdated = DateTimeOffset.UtcNow
                }, TableUpdateMode.Replace);

                return accessToken;
            }
            catch (Exception ex)
            {
                log.LogError("Error retrieving Firebase access token: {Message}", ex.Message);
                return null;
            }
        }

        static async Task UpdateGoogleCalendar(ILogger log)
        {
            string gCalTriggerApi = Environment.GetEnvironmentVariable("GoogleCalendarTriggerApi")
                ?? throw new InvalidOperationException("GoogleCalendarTriggerApi is not set in the environment.");
            try
            {
                using HttpClient client = new();
                var response = await client.GetAsync(gCalTriggerApi);
                response.EnsureSuccessStatusCode();
            }
            catch (Exception ex)
            {
                log.LogError($"Error updating Google Calendar: {ex.Message}");
            }
        }

        private async Task SendReadSyncAsync(
            List<List<Dictionary<string, object>>> multipleResults,
            string publicEventId,
            ILogger logger)
        {
            try
            {
                if (multipleResults.Count < 2 || multipleResults[1].Count == 0)
                {
                    logger.LogInformation("markEventChatRead: no other devices to notify for event {PublicEventId}.", publicEventId);
                    return;
                }

                string? accessToken = await GetFirebaseAccessTokenAsync();

                foreach (var row in multipleResults[1])
                {
                    if (!row.TryGetValue("FcmToken", out var tokenObj)) continue;
                    var token = tokenObj?.ToString();
                    if (string.IsNullOrEmpty(token)) continue;
                    await SendReadSyncMessageAsync(token, publicEventId, accessToken, logger);
                }

                logger.LogInformation("Read sync sent to {Count} device(s) for event {PublicEventId}.",
                    multipleResults[1].Count, publicEventId);
            }
            catch (Exception ex)
            {
                logger.LogError("Error sending read sync notifications: {Message}", ex.Message);
            }
        }

        private static async Task SendReadSyncMessageAsync(
            string fcmToken, string publicEventId, string? accessToken, ILogger log)
        {
            try
            {
                var messageBody = new
                {
                    message = new
                    {
                        token = fcmToken,
                        // Data-only — no notification block — so this never surfaces
                        // as a visible alert on the recipient device.
                        data = new
                        {
                            Type = "read_sync",
                            PublicEventId = publicEventId,
                        },
                        // Lower priority on both platforms: this is a background sync,
                        // not a user-facing notification.
                        android = new { priority = "normal" },
                        apns = new
                        {
                            headers = new Dictionary<string, string> { ["apns-priority"] = "5" },
                            payload = new
                            {
                                aps = new Dictionary<string, object> { ["content-available"] = 1 }
                            }
                        }
                    }
                };

                var jsonPayload = System.Text.Json.JsonSerializer.Serialize(messageBody);
                var stringContent = new StringContent(jsonPayload, Encoding.UTF8);
                stringContent.Headers.ContentType = new System.Net.Http.Headers.MediaTypeHeaderValue("application/json");

                var request = new HttpRequestMessage(HttpMethod.Post, FcmUrl)
                {
                    Headers = { { "Authorization", $"Bearer {accessToken}" } },
                    Content = stringContent
                };

                var response = await _httpClient.SendAsync(request);
                if (!response.IsSuccessStatusCode)
                {
                    string errorJson = await response.Content.ReadAsStringAsync();
                    log.LogError("Error sending read sync FCM: {ErrorJson}", errorJson);
                    if (errorJson.Contains("BadDeviceToken") || errorJson.Contains("not a valid FCM registration token"))
                        await DeleteFcmToken(fcmToken, log);
                }
            }
            catch (Exception ex)
            {
                log.LogError("Exception sending read sync FCM: {Message}", ex.Message);
            }
        }

        static async Task DeleteFcmToken(string fcmToken, ILogger log)
        {
            string connectionString = Environment.GetEnvironmentVariable("HcDbConnectionString")
                ?? throw new InvalidOperationException("HcDbConnectionString is not set in the environment.");
            try
            {
                using SqlConnection conn = new(connectionString);
                await conn.OpenAsync();
                using SqlCommand cmd = new(
                    "UPDATE HC.Device SET FcmToken = NULL WHERE FcmToken = @fcmToken",
                    conn);
                cmd.Parameters.AddWithValue("@fcmToken", fcmToken);
                await cmd.ExecuteNonQueryAsync();
                log.LogInformation("Stale FCM token cleared from HC.Device.");
            }
            catch (Exception ex)
            {
                log.LogError("Error clearing stale FCM token: {Message}", ex.Message);
            }
        }
    }
}
