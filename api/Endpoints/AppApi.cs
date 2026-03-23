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
using Azure;
using Azure.Data.Tables;




//{"queryType":"getEvents","publicHasherId":"B6BAFD0D-5D2E-41CD-8495-811D551F01D0","accessToken":"asdfasdfasfasdfasdfasdf","publicKennelIds":"6EDC3585-C1F8-4800-B189-23A4036830C9"}

namespace HcWebApi.Endpoints
{

    public class DeviceTokenEntity : ITableEntity
    {
        public string PartitionKey { get; set; } = "FcmTokens";
        public string RowKey { get; set; } = "AppApiFcmToken";
        public string? FcmToken { get; set; }
        public DateTimeOffset LastUpdated { get; set; } = DateTimeOffset.UtcNow;
        public ETag ETag { get; set; }
        public DateTimeOffset? Timestamp { get; set; }
    }

    public class TokenRequest
    {
        public string? DeviceId { get; set; }
        public string? FcmToken { get; set; }
    }



    public class AppApi
    {
        private readonly ILogger<AppApi> log;
        private readonly TableClient _tableClient;

        public AppApi(ILogger<AppApi> logger)
        {
            log = logger;

            var connectionString = Environment.GetEnvironmentVariable("AzureWebJobsStorage");
            var tableName = "FcmTokensForAppApi";
            var serviceClient = new TableServiceClient(connectionString);
            _tableClient = serviceClient.GetTableClient(tableName);
            _tableClient.CreateIfNotExists();
        }

        [Function("AppApi")]
        public async Task<IActionResult> Run([HttpTrigger(AuthorizationLevel.Anonymous, "post")] HttpRequest req)
        {

            string connectionString = Environment.GetEnvironmentVariable("HcDbConnectionString")
                ?? throw new InvalidOperationException("HcDbConnectionString is not set in the environment.");


            // Parse the request body
            string requestBody = await new StreamReader(req.Body).ReadToEndAsync();
            dynamic data = JsonConvert.DeserializeObject(requestBody)
     ?? throw new InvalidOperationException("Failed to deserialize the request body.");


            // Validate required parameters
            if (data.deviceId == null || data.accessToken == null)
            {
                log.LogInformation("Missing required parameters: deviceId or accessToken.");
                return new BadRequestObjectResult("Missing required parameters: hasherId or accessToken.");
            }

            // Validate required parameters
            if (data.queryType == null)
            {
                log.LogInformation("Missing query type.");
                return new BadRequestObjectResult("Missing query type.");

            }

            bool includeNulls = data.includeNulls != null && (bool)data.includeNulls;

            log.LogInformation($"App API Called: QueryType = {data.queryType}, UserID = {data.publicHasherId}");

            // Initialize a list to hold the stored procedure results
            List<Dictionary<string, object?>> results = new List<Dictionary<string, object?>>();

            // Call the stored procedure and capture the results
            try
            {
                // Initialize a list to hold the result sets
                List<List<Dictionary<string, object?>>> multipleResults = new List<List<Dictionary<string, object?>>>();

                using (SqlConnection conn = new SqlConnection(connectionString))
                {
                    await conn.OpenAsync();

                    String procedureName = $"[HC5].[hcapp_{data.queryType}]";

                    using (SqlCommand cmd = new SqlCommand(procedureName, conn))
                    {
                        cmd.CommandType = CommandType.StoredProcedure;

                        // Parse the request body into a JObject
                        JObject jsonData = JObject.Parse(requestBody);

                        // Iterate over each property and add it as a parameter to the SQL command
                        foreach (var property in jsonData.Properties())
                        {
                            if ((property.Name == "queryType") || (property.Name == "includeNulls"))
                            {
                                continue;
                            }

                            // Construct the parameter name (e.g., "@publicHasherId")
                            string parameterName = "@" + property.Name;

                            // Use DBNull.Value if the JSON value is null; otherwise, convert to a .NET object
                            object? parameterValue = ((property.Value == null) || (property.Value.Type == JTokenType.Null))
                                                    ? DBNull.Value
                                                    : property.Value.ToObject<object>();

                            if ((parameterName != null) && (parameterValue != null))
                            {
                                // Add the parameter to your SQL command
                                cmd.Parameters.AddWithValue(parameterName, parameterValue);
                                //log.LogInformation($"Param = {parameterName}, Value = {parameterValue}");
                            }
                        }

                        // Execute the stored procedure and retrieve multiple result sets
                        using (SqlDataReader reader = await cmd.ExecuteReaderAsync())
                        {
                            try
                            {
                                // Process each result set
                                do
                                {
                                    List<Dictionary<string, object?>> resultSet = new List<Dictionary<string, object?>>();

                                    while (await reader.ReadAsync())
                                    {
                                        var row = new Dictionary<string, object?>();
                                        for (int i = 0; i < reader.FieldCount; i++)
                                        {
                                            string? name = reader.GetName(i);
                                            object? value = reader.IsDBNull(i) ? null : reader.GetValue(i);

                                            if ((name != null) && ((value != null) || includeNulls))
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

                // handle any additoinal tasks after the SQL has been updated. 
                // ideally these should not take a long time to complete. If they
                // do, we should use a message queue to handle the long-running functions

                // handle any additoinal tasks after the SQL has been updated. 
                // ideally these should not take a long time to complete. If they
                // do, we should use a message queue to handle the long-running functions

                switch ((string)data.queryType)
                {
                    case "addEditEvent":
                        await UpdateGoogleCalendar(log);
                        break;
                    case "sendEventMessage":
                        await SendNotifications(multipleResults, log, includeNulls);
                        break;
                }

                // Return the multiple result sets as JSON
                return new OkObjectResult(multipleResults);

            }
            catch (Exception ex)
            {
                log.LogError($"Error executing stored procedure: {ex.Message}");
                return new BadRequestObjectResult($"Error executing stored procedure: {ex.Message}");
            }
        }

        public async Task SendNotifications(List<List<Dictionary<string, object?>>> multipleResults, ILogger logger, bool includeNulls)
        {
            try
            {
                string? accessToken = await GetFirebaseAccessTokenAsync();

                logger.LogInformation("Processing event notifications...");

                // Convert object to JSON string
                string jsonString = System.Text.Json.JsonSerializer.Serialize(multipleResults);

                // Deserialize from JSON string
                var parsedJson = System.Text.Json.JsonSerializer.Deserialize<List<List<Dictionary<string, object?>>>>(jsonString);

                if (parsedJson == null || parsedJson.Count < 3)
                {
                    logger.LogError("Invalid JSON format.");
                    return;
                }

                // Extract the event details (first array)
                var eventDetailsList = System.Text.Json.JsonSerializer.Deserialize<List<EventMessage>>(System.Text.Json.JsonSerializer.Serialize(parsedJson[0]));

                // Extract the recipients who should get a visible push notification (second array)
                var notificationList = System.Text.Json.JsonSerializer.Deserialize<List<Recipient>>(System.Text.Json.JsonSerializer.Serialize(parsedJson[1]));

                // Extract the recipients (second array)
                var inAppMessageList = System.Text.Json.JsonSerializer.Deserialize<List<Recipient>>(System.Text.Json.JsonSerializer.Serialize(parsedJson[2]));

                if (eventDetailsList == null || notificationList == null || inAppMessageList == null)
                {
                    logger.LogError("Failed to deserialize JSON into objects.");
                    return;
                }

                foreach (var eventMessage in eventDetailsList)
                {
                    foreach (var recipient in notificationList)
                    {
                        if (!string.IsNullOrEmpty(recipient.FcmToken))
                        {
                            await SendNotificationAsync(
                                recipient.FcmToken,
                                eventMessage,
                                accessToken,
                                true,
                                includeNulls,
                                logger);
                        }
                    }
                }

                foreach (var eventMessage in eventDetailsList)
                {
                    foreach (var recipient in inAppMessageList)
                    {
                        if (!string.IsNullOrEmpty(recipient.FcmToken))
                        {
                            await SendNotificationAsync(
                                recipient.FcmToken,
                                eventMessage,
                                accessToken,
                                false,
                                includeNulls,
                                logger);
                        }
                    }
                }

                logger.LogInformation("All notifications sent successfully.");
            }
            catch (Exception ex)
            {
                logger.LogError($"Error processing notifications: {ex.Message}");
            }
        }

        private static readonly HttpClient _httpClient = new HttpClient();
        private const string FcmUrl = "https://fcm.googleapis.com/v1/projects/harrier-central-mobile/messages:send";

        public static async Task SendNotificationAsync(
            string fcmToken,
            EventMessage eventMessage,
            string? accessToken,
            bool isNotification,
            bool includeNulls,
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
                        await DeleteFcmToken(fcmToken, log, includeNulls);
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
            const string rowKey = "AppApiToken";

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


        static async Task DeleteFcmToken(string fcmToken, ILogger log, bool includeNulls)
        {
            string connectionString = Environment.GetEnvironmentVariable("HcDbConnectionString")
                ?? throw new InvalidOperationException("HcDbConnectionString is not set in the environment.");

            // Initialize a list to hold the stored procedure results
            List<Dictionary<string, object?>> results = new List<Dictionary<string, object?>>();

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
                                    List<Dictionary<string, object?>> resultSet = new List<Dictionary<string, object?>>();

                                    while (await reader.ReadAsync())
                                    {
                                        var row = new Dictionary<string, object?>();
                                        for (int i = 0; i < reader.FieldCount; i++)
                                        {
                                            string? name = reader.GetName(i);
                                            object? value = reader.IsDBNull(i) ? null : reader.GetValue(i);

                                            //if ((name != null) && (value != null))
                                            if ((name != null) && ((value != null) || includeNulls))
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



        static async Task UpdateGoogleCalendar(ILogger log)
        {
            // Call an Azure Logic App that will update Google calendars
            // NOTE: This triggers a function that will update any event with
            // Google calendar integration turned on when that event indicates
            // that the Google calendar might be out of date. It does not
            // only look at events from the Kennel currently being updated
            // The URL you want to call
            string gCalTriggerApi = Environment.GetEnvironmentVariable("GoogleCalendarTriggerApi") ?? throw new InvalidOperationException("HcDbConnectionString is not set in the environment.");

            //string requestUrl = "https://prod-19.northeurope.logic.azure.com:443/workflows/0108404b9b8f4b0b9ca2873491a3ad03/triggers/When_a_HTTP_request_is_received/paths/invoke?api-version=2016-10-01&sp=%2Ftriggers%2FWhen_a_HTTP_request_is_received%2Frun&sv=1.0&sig=I72oSYlBHUFE240337h2ysIDu3JQmhuKiabRdjC2ojg";

            try
            {
                using HttpClient client = new HttpClient();

                // Send the GET request
                HttpResponseMessage response = await client.GetAsync(gCalTriggerApi);

                // Throw an exception if the status code is not success
                response.EnsureSuccessStatusCode();

                // Read the response content as a string
                string responseBody = await response.Content.ReadAsStringAsync();

                // Print the response to console
                // Console.WriteLine("HTTP GET succeeded. Response:");
                // Console.WriteLine(responseBody);
            }
            catch (HttpRequestException ex)
            {
                log.LogError($"Error updating Google Calendar: {ex.Message}");
                // // Handle any HTTP-specific errors here
                // Console.WriteLine("Error occurred while calling Logic App:");
                // Console.WriteLine(ex.Message);
            }
            catch (Exception ex)
            {
                log.LogError($"Error updating Google Calendar: {ex.Message}");
                // Handle any other unforeseen errors
                // Console.WriteLine("An unexpected error occurred:");
                // Console.WriteLine(ex.Message);
            }

        }
    }
}

