using Google.Apis.Auth.OAuth2;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Logging;
using System.Data;
using System.Diagnostics;
using System.Text;
using Azure.Data.Tables;

namespace HcWebApi.Endpoints
{
    public class RunCheckInNotification
    {
        private readonly ILogger<RunCheckInNotification> log;

        private TableClient _tableClient;

        public RunCheckInNotification(ILogger<RunCheckInNotification> logger)
        {
            log = logger;
            var connectionString = Environment.GetEnvironmentVariable("AzureWebJobsStorage");
            var tableName = "FcmTokensForInternalApi";
            var serviceClient = new TableServiceClient(connectionString);
            _tableClient = serviceClient.GetTableClient(tableName);
            _tableClient.CreateIfNotExists();
        }


        [Function("RunCheckInNotification")]
        public async Task Run([TimerTrigger("0 */1 * * * *")] TimerInfo myTimer)
        {
            log.LogInformation("C# Timer trigger function executed at: {Now}", DateTime.Now);

            if (myTimer.ScheduleStatus is not null)
            {
                log.LogInformation("Next timer schedule at: {Next}", myTimer.ScheduleStatus.Next);
            }

            string connectionString = Environment.GetEnvironmentVariable("HcDbConnectionString")
                ?? throw new InvalidOperationException("HcDbConnectionString is not set in the environment.");

            // Call the stored procedure and capture the results
            try
            {
                // Initialize a list to hold the result sets
                List<List<Dictionary<string, object>>> multipleResults = new List<List<Dictionary<string, object>>>();

                using (SqlConnection conn = new SqlConnection(connectionString))
                {
                    await conn.OpenAsync();

                    String procedureName = $"[HC5].[hcinternalapi_checkReminders]";

                    using (SqlCommand cmd = new SqlCommand(procedureName, conn))
                    {
                        cmd.CommandType = CommandType.StoredProcedure;
                        cmd.Parameters.AddWithValue("@apiKey", "npsXZr6xtEPv9iaA7LAEfjRZhCuGbpbwC8BSlLpwbwkGzZdRdNndXWNfvKr8p4l9hdBWE5acK8q");

                        // Execute the stored procedure and retrieve multiple result sets
                        using (SqlDataReader reader = await cmd.ExecuteReaderAsync())
                        {
                            try
                            {
                                // Process each result set
                                do
                                {
                                    List<Dictionary<string, object>> resultSet = new List<Dictionary<string, object>>();

                                    while (await reader.ReadAsync())
                                    {
                                        var row = new Dictionary<string, object>();
                                        for (int i = 0; i < reader.FieldCount; i++)
                                        {
                                            string? name = reader.GetName(i);
                                            object? value = reader.IsDBNull(i) ? null : reader.GetValue(i);

                                            if ((name != null) && (value != null))
                                            {
                                                row[name] = value;
                                            }

                                        }
                                        resultSet.Add(row);
                                    }

                                    // Add the result set to the list of result sets
                                    multipleResults.Add(resultSet);

                                } while (await reader.NextResultAsync()); // Move to the next result set
                            }

                            catch (System.Exception ex)
                            {
                                Debug.Print(ex.ToString());
                            }
                        }
                    }
                }

                await SendNotifications(multipleResults, log);

                // Return the multiple result sets as JSON
                return;

            }
            catch (Exception ex)
            {
                log.LogError("Error executing stored procedure: {Message}", ex.Message);
                return;
            }
        }

        public async Task SendNotifications(List<List<Dictionary<string, object>>> multipleResults, ILogger logger)
        {
            try
            {
                string? accessToken = await GetFirebaseAccessTokenAsync();

                logger.LogInformation("Processing event notifications...");

                // Convert object to JSON string
                string jsonString = System.Text.Json.JsonSerializer.Serialize(multipleResults);

                // Deserialize from JSON string
                var parsedJson = System.Text.Json.JsonSerializer.Deserialize<List<List<Dictionary<string, object>>>>(jsonString);

                if (parsedJson == null || parsedJson.Count < 2)
                {
                    logger.LogError("Invalid JSON format.");
                    return;
                }

                // Extract the event details (first array)
                var eventDetailsList = System.Text.Json.JsonSerializer.Deserialize<List<EventMessage>>(System.Text.Json.JsonSerializer.Serialize(parsedJson[0]));

                // Extract the recipients who should get a visible push notification (second array)
                var notificationList = System.Text.Json.JsonSerializer.Deserialize<List<Recipient>>(System.Text.Json.JsonSerializer.Serialize(parsedJson[1]));

                if (eventDetailsList == null || notificationList == null)
                {
                    logger.LogError("Failed to deserialize JSON into objects.");
                    return;
                }

                foreach (var eventMessage in eventDetailsList)
                {
                    foreach (var recipient in notificationList)
                    {
                        if ((!string.IsNullOrEmpty(recipient.FcmToken)) && (eventMessage.EventId.ToUpper() == recipient.EventId?.ToUpper()))
                        {
                            await SendNotificationAsync(
                                recipient.FcmToken,
                                eventMessage,
                                accessToken,
                                true,
                                logger);
                        }
                    }
                }

                logger.LogInformation("All notifications sent successfully.");
            }
            catch (Exception ex)
            {
                const string _errorMsg =
                    "Error processing notifications:{Message}";
                logger.LogError(_errorMsg, ex.Message);
            }
        }

        private static readonly HttpClient _httpClient = new HttpClient();
        private const string FcmUrl = "https://fcm.googleapis.com/v1/projects/harrier-central-mobile/messages:send";

        public static async Task SendNotificationAsync(
            string fcmToken,
            EventMessage eventMessage,
            string? accessToken,
            bool isNotification,
            ILogger log)
        {

            Console.WriteLine($"FCM token = {fcmToken}");

            try
            {
                var messageBody = new
                {
                    message = new
                    {
                        token = fcmToken, // Correct way to send multiple tokens
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
                            EventChatMessageCount = eventMessage.EventChatMessageCount.ToString(),
                            MessageType = eventMessage.MessageType.ToString(),
                        },
                        android = isNotification ? new { priority = "high", notification = new { sound = "default" } } : null,
                        apns = new
                        {
                            headers = new Dictionary<string, string> { { "apns-priority", "10" } },
                            payload = new
                            {
                                aps = new { sound = "default" }
                            }
                        }
                    },
                };

                var jsonPayload = System.Text.Json.JsonSerializer.Serialize(messageBody);
                var stringContent = new StringContent(jsonPayload, Encoding.UTF8);
                stringContent.Headers.ContentType = new System.Net.Http.Headers.MediaTypeHeaderValue("application/json");

                var request = new HttpRequestMessage(HttpMethod.Post, FcmUrl)
                {
                    Headers =
                    {
                        { "Authorization", $"Bearer {accessToken}" }
                    },
                    Content = stringContent
                };


                var response = await _httpClient.SendAsync(request);
                if (response.IsSuccessStatusCode)
                {
                    Console.WriteLine("FCM message sent successfully!");
                }
                else
                {
                    string errorJson = await response.Content.ReadAsStringAsync();
                    Console.WriteLine($"Error sending FCM message: {errorJson}");
                    if (errorJson.Contains("BadDeviceToken") || errorJson.Contains("not a valid FCM registration token"))
                    {
                        await DeleteFcmToken(fcmToken, log);
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Exception while sending FCM message: {ex.Message}");
            }
        }

        public async Task<string?> GetFirebaseAccessTokenAsync()
        {
            const string partitionKey = "FcmTokens";
            const string rowKey = "PortalApiToken";

            try
            {
                // Try to retrieve the existing token entity
                var response = await _tableClient.GetEntityIfExistsAsync<DeviceTokenEntity>(partitionKey, rowKey);

                if (response.HasValue)
                {
                    var entity = response.Value;

                    if (entity != null)
                    {
                        // Check if token is less than 1 hour old
                        var age = DateTimeOffset.UtcNow - entity.LastUpdated;
                        if (age < TimeSpan.FromMinutes(55))
                        {
                            return entity.FcmToken;
                        }
                    }

                    Console.WriteLine("Token expired. Generating a new one.");
                }

                // Generate new token from Firebase service account
                string jsonUrl = "https://harriercentral.blob.core.windows.net/credentials/firebase_credentials.json";
                var httpResponse = await _httpClient.GetAsync(jsonUrl);

                if (!httpResponse.IsSuccessStatusCode)
                {
                    Console.WriteLine("Error: Failed to retrieve service account JSON from Azure Blob Storage.");
                    return null;
                }

                string jsonContent = await httpResponse.Content.ReadAsStringAsync();

                GoogleCredential credential = GoogleCredential
                    .FromJson(jsonContent)
                    .CreateScoped(new[] { "https://www.googleapis.com/auth/firebase.messaging" });

                var accessToken = await credential.UnderlyingCredential.GetAccessTokenForRequestAsync();

                // Save or update the token in Table Storage
                var newEntity = new DeviceTokenEntity
                {
                    PartitionKey = partitionKey,
                    RowKey = rowKey,
                    FcmToken = accessToken,
                    LastUpdated = DateTimeOffset.UtcNow
                };

                await _tableClient.UpsertEntityAsync(newEntity, TableUpdateMode.Replace);

                return accessToken;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error retrieving Firebase access token: {ex.Message}");
                return null;
            }
        }

        static async Task DeleteFcmToken(string fcmToken, ILogger log)
        {
            string connectionString = Environment.GetEnvironmentVariable("HcDbConnectionString")
                ?? throw new InvalidOperationException("HcDbConnectionString is not set in the environment.");

            // Initialize a list to hold the stored procedure results
            List<Dictionary<string, object>> results = new List<Dictionary<string, object>>();

            // Call the stored procedure and capture the results
            try
            {
                using (SqlConnection conn = new SqlConnection(connectionString))
                {
                    await conn.OpenAsync();

                    String procedureName = "[HC5].[hcinternalapi_removeStaleFcmToken]";

                    using (SqlCommand cmd = new SqlCommand(procedureName, conn))
                    {
                        cmd.CommandType = CommandType.StoredProcedure;
                        cmd.Parameters.AddWithValue("@fcmToken", fcmToken);

                        // Execute the stored procedure and retrieve multiple result sets
                        using (SqlDataReader reader = await cmd.ExecuteReaderAsync())
                        {
                            try
                            {
                                // Process each result set
                                do
                                {
                                    List<Dictionary<string, object>> resultSet = new List<Dictionary<string, object>>();

                                    while (await reader.ReadAsync())
                                    {
                                        var row = new Dictionary<string, object>();
                                        for (int i = 0; i < reader.FieldCount; i++)
                                        {
                                            string? name = reader.GetName(i);
                                            object? value = reader.IsDBNull(i) ? null : reader.GetValue(i);

                                            if ((name != null) && (value != null))
                                            {
                                                row[name] = value;
                                            }

                                        }
                                        resultSet.Add(row);
                                    }

                                } while (await reader.NextResultAsync()); // Move to the next result set
                            }

                            catch (System.Exception ex)
                            {
                                Debug.Print(ex.ToString());
                            }
                        }
                    }
                }

            }
            catch (Exception ex)
            {
                log.LogError($"Error executing stored procedure: {ex.Message}");
            }
        }


    }
}
