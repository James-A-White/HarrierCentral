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

// DeviceTokenEntity and TokenRequest are defined in AppApi.cs (same namespace).

namespace HcWebApi.Endpoints
{
    public class AppApiHC6
    {
        private readonly ILogger<AppApiHC6> log;
        private readonly TableClient _tableClient;

        public AppApiHC6(ILogger<AppApiHC6> logger)
        {
            log = logger;

            var connectionString = Environment.GetEnvironmentVariable("AzureWebJobsStorage");
            var tableName = "FcmTokensForAppApi";
            var serviceClient = new TableServiceClient(connectionString);
            _tableClient = serviceClient.GetTableClient(tableName);
            _tableClient.CreateIfNotExists();
        }

        [Function("AppApiHC6")]
        public async Task<IActionResult> Run([HttpTrigger(AuthorizationLevel.Anonymous, "post")] HttpRequest req)
        {

            string connectionString = Environment.GetEnvironmentVariable("HcDbConnectionString")
                ?? throw new InvalidOperationException("HcDbConnectionString is not set in the environment.");


            // Parse the request body
            string requestBody = await new StreamReader(req.Body).ReadToEndAsync();
            dynamic data = JsonConvert.DeserializeObject(requestBody)
     ?? throw new InvalidOperationException("Failed to deserialize the request body.");

            // Validate queryType first — required for all calls including checkConnection
            if (data.queryType == null)
            {
                log.LogInformation("Missing query type.");
                return new BadRequestObjectResult("Missing query type.");
            }

            // checkConnection is an unauthenticated ping — return immediately without
            // touching the SP dispatcher or opening a DB connection.
            if ((string?)data.queryType == "checkConnection")
            {
                return new OkObjectResult(new { connected = true });
            }

            // Pre-auth queries use the global shared token and have no device record yet.
            bool isPreAuthQuery = (string?)data.queryType == "findHashersByHashName";

            // Validate required parameters for all authenticated calls
            if (!isPreAuthQuery && (data.deviceId == null || data.accessToken == null))
            {
                log.LogInformation("Missing required parameters: deviceId or accessToken.");
                return new BadRequestObjectResult("Missing required parameters: hasherId or accessToken.");
            }

            bool includeNulls = data.includeNulls != null && (bool)data.includeNulls;

            log.LogInformation($"App API HC6 Called: QueryType = {data.queryType}, UserID = {data.publicHasherId}");

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

                    String procedureName = $"[HC6].[hcapp_{data.queryType}]";

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

                // Detect HC6 app error envelope: first rowset has exactly one row with "errorType".
                // HC6 SPs return two rowsets on error: rowset 0 is the success envelope
                // {success, errorCode, errorType} and rowset 1 is the human-readable detail
                // {errorId, errorType, errorUserMessage, errorTitle, errorProc}.
                // Read errorType from rowset 0 (always present); read detail fields from
                // rowset 1 when available, falling back to rowset 0 for older SP shapes.
                if (multipleResults.Count > 0
                    && multipleResults[0].Count == 1
                    && multipleResults[0][0].ContainsKey("errorType"))
                {
                    var envelopeRow = multipleResults[0][0];
                    var detailRow = (multipleResults.Count > 1 && multipleResults[1].Count > 0)
                        ? multipleResults[1][0]
                        : envelopeRow;

                    envelopeRow.TryGetValue("errorType", out var errType);
                    detailRow.TryGetValue("errorUserMessage", out var errMsg);
                    detailRow.TryGetValue("errorId", out var errId);
                    // Log full detail row (including debugMessage and errorProc) server-side only.
                    log.LogWarning("AppApiHC6 SP error [{QueryType}]: errorType={ErrorType} message={Message} row={Row}",
                        (string)data.queryType, errType?.ToString(), errMsg?.ToString(),
                        Newtonsoft.Json.JsonConvert.SerializeObject(detailRow));
                    // Return only safe fields to the caller — never expose debugMessage or errorProc.
                    return new BadRequestObjectResult(new
                    {
                        errorType        = errType,
                        errorUserMessage = errMsg?.ToString(),
                        errorId          = errId?.ToString()
                    });
                }

                switch ((string)data.queryType)
                {
                    case "addEditEvent":
                        await UpdateGoogleCalendar(log);
                        break;
                    case "sendEventMessage":
                        _ = SendNotifications(multipleResults, log, includeNulls);
                        break;
                    case "markEventChatRead":
                        await SendReadSyncAsync(multipleResults, log);
                        break;
                    case "selectSong":
                        _ = SendSongToAttendeesAsync(multipleResults, log);
                        break;
                }

                // Return compressed JSON (Brotli preferred, Gzip fallback, plain if unsupported)
                return CompressedJson(req, multipleResults);

            }
            catch (Exception ex)
            {
                log.LogError("AppApiHC6 SP error: {Message}", ex.Message);
                return new StatusCodeResult(500);
            }
        }

        private static IActionResult CompressedJson(HttpRequest req, object data)
        {
            var json = JsonConvert.SerializeObject(data);
            var bytes = Encoding.UTF8.GetBytes(json);
            var acceptEncoding = req.Headers["Accept-Encoding"].ToString();

            if (acceptEncoding.Contains("br", StringComparison.OrdinalIgnoreCase))
            {
                using var ms = new System.IO.MemoryStream();
                using (var br = new System.IO.Compression.BrotliStream(ms, System.IO.Compression.CompressionLevel.Fastest))
                    br.Write(bytes);
                req.HttpContext.Response.Headers.Append("Content-Encoding", "br");
                return new FileContentResult(ms.ToArray(), "application/json");
            }
            if (acceptEncoding.Contains("gzip", StringComparison.OrdinalIgnoreCase))
            {
                using var ms = new System.IO.MemoryStream();
                using (var gz = new System.IO.Compression.GZipStream(ms, System.IO.Compression.CompressionLevel.Fastest))
                    gz.Write(bytes);
                req.HttpContext.Response.Headers.Append("Content-Encoding", "gzip");
                return new FileContentResult(ms.ToArray(), "application/json");
            }
            return new OkObjectResult(data);
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

                // Extract the event details (first array).
                // EventMessageHc6 uses the correctly-spelled HC6 column name; the shared
                // EventMessage class retains the HC5 typo for backward compat with HC5 paths.
                var eventDetailsList = System.Text.Json.JsonSerializer.Deserialize<List<EventMessageHc6>>(System.Text.Json.JsonSerializer.Serialize(parsedJson[0]));

                // Extract the recipients who should get a visible push notification (second array)
                var notificationList = System.Text.Json.JsonSerializer.Deserialize<List<Recipient>>(System.Text.Json.JsonSerializer.Serialize(parsedJson[1]));

                // Extract the recipients (second array)
                var inAppMessageList = System.Text.Json.JsonSerializer.Deserialize<List<Recipient>>(System.Text.Json.JsonSerializer.Serialize(parsedJson[2]));

                if (eventDetailsList == null || notificationList == null || inAppMessageList == null)
                {
                    logger.LogError("Failed to deserialize notification payload into objects.");
                    return;
                }

                // Build a flat list of dispatch items so we can pair each FCM result
                // with its log entry after Task.WhenAll returns.
                var dispatchList = eventDetailsList
                    .SelectMany(em =>
                        notificationList
                            .Where(r => !string.IsNullOrEmpty(r.FcmToken))
                            .Select(r => new { em, token = r.FcmToken!, userId = r.UserId, visible = true })
                        .Concat(
                            inAppMessageList
                                .Where(r => !string.IsNullOrEmpty(r.FcmToken))
                                .Select(r => new { em, token = r.FcmToken!, userId = r.UserId, visible = false })
                        )
                    )
                    .ToList();

                var fcmResults = await Task.WhenAll(
                    dispatchList.Select(item =>
                        SendNotificationAsync(item.token, item.em, accessToken, item.visible, logger))
                );

                logger.LogInformation("All notifications sent successfully.");

                // Log to HC.PushLog — one entry per recipient per event message, with FCM result
                foreach (var em in eventDetailsList)
                {
                    var summary = $"chat: {em.MessageTitle}";
                    var logEntries = dispatchList
                        .Select((item, i) => (item, result: fcmResults[i]))
                        .Where(x => x.item.em.EventId == em.EventId && !string.IsNullOrEmpty(x.item.token))
                        .Select(x => new PushLogEntry(
                            x.item.token,
                            x.item.userId,
                            SenderUserId: em.UserId,
                            IsVisible: x.item.visible,
                            FcmResult: x.result));
                    _ = LogPushBatchAsync("sendEventMessage", em.EventId, summary, logEntries, logger);
                }
            }
            catch (Exception ex)
            {
                logger.LogError($"Error processing notifications: {ex.Message}");
            }
        }

        private static readonly HttpClient _httpClient = new HttpClient();
        private const string FcmUrl = "https://fcm.googleapis.com/v1/projects/harrier-central-mobile/messages:send";

        private static async Task<string> SendNotificationAsync(
            string fcmToken,
            EventMessageHc6 eventMessage,
            string? accessToken,
            bool isNotification,
            ILogger log)
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
                            // FCM key preserves the HC5 typo — Flutter client reads this key by name.
                            // Rename to MessageReleasabilityFlags in Track 2 alongside the 2.x migration.
                            MessageRelesabilityFlags = eventMessage.MessageReleasabilityFlags.ToString(),
                            MessageType = eventMessage.MessageType.ToString(),
                        },
                        android = isNotification ? new { priority = "high", notification = new { sound = "default" } } : null,
                        apns = isNotification
                            ? new
                            {
                                headers = new Dictionary<string, string> { ["apns-priority"] = "10" },
                                payload = new { aps = new Dictionary<string, object> { ["sound"] = "default" } }
                            }
                            : new
                            {
                                headers = new Dictionary<string, string> { ["apns-priority"] = "5" },
                                payload = new { aps = new Dictionary<string, object> { ["content-available"] = (object)1 } }
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
                    log.LogInformation("FCM push sent successfully.");
                    return "success";
                }
                else
                {
                    string errorJson = await response.Content.ReadAsStringAsync();
                    log.LogWarning("FCM push failed: {Error}", errorJson);
                    if (errorJson.Contains("UNREGISTERED") || errorJson.Contains("NOT_FOUND") ||
                        errorJson.Contains("BadDeviceToken") || errorJson.Contains("not a valid FCM registration token"))
                    {
                        await DeleteFcmToken(fcmToken, log);
                        return "token_error";
                    }
                    return "error";
                }
            }
            catch (Exception ex)
            {
                log.LogError(ex, "Exception while sending FCM push.");
                return "exception";
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

                    log.LogInformation("Firebase access token expired, refreshing.");
                }

                // Generate new token from Firebase service account
                string jsonUrl = "https://harriercentral.blob.core.windows.net/credentials/firebase_credentials.json";
                using var cts = new CancellationTokenSource(TimeSpan.FromSeconds(10));
                var httpResponse = await _httpClient.GetAsync(jsonUrl, cts.Token);

                if (!httpResponse.IsSuccessStatusCode)
                {
                    log.LogError("Failed to retrieve Firebase service account JSON from Azure Blob Storage.");
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
                log.LogError(ex, "Failed to retrieve Firebase access token.");
                return null;
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
                    "UPDATE HC.Device SET FcmToken = NULL, FcmTokenDeleted = SYSUTCDATETIME() WHERE FcmToken = @fcmToken",
                    conn);
                cmd.Parameters.AddWithValue("@fcmToken", fcmToken);
                await cmd.ExecuteNonQueryAsync();
                log.LogInformation("Stale FCM token cleared from HC.Device (FcmTokenDeleted stamped).");
            }
            catch (Exception ex)
            {
                log.LogError("Error clearing stale FCM token: {Message}", ex.Message);
            }
        }



        // HC6 corrected the spelling of MessageReleasabilityFlags in the SP column name.
        // The shared EventMessage class (PortalApi.cs) retains the old HC5 typo for
        // backward compat with HC5 paths. This local class is used only in the HC6
        // sendEventMessage notification path.
        private sealed class EventMessageHc6
        {
            public required string MessageId { get; set; }
            public required string EventId { get; set; }
            public required string PublicEventId { get; set; }
            public required string UserId { get; set; }
            public required string UserDisplayName { get; set; }
            public required string UserPhoto { get; set; }
            public required string MessageTitle { get; set; }
            public required string MessageContent { get; set; }
            public required int MessageReleasabilityFlags { get; set; }
            public required int MessageType { get; set; }
        }

        // ── Push notification logging ─────────────────────────────────────────────
        // Logs every FCM push to HC.PushLog for fan-out analysis.
        // Non-fatal: a logging failure never blocks push delivery.

        private record PushLogEntry(
            string FcmToken,
            string? UserId,
            string? SenderUserId,
            bool IsVisible,
            string? FcmResult = null);

        private async Task LogPushBatchAsync(
            string queryType,
            string? eventId,
            string? summary,
            IEnumerable<PushLogEntry> entries,
            ILogger log)
        {
            var connectionString = Environment.GetEnvironmentVariable("HcDbConnectionString")
                ?? throw new InvalidOperationException("HcDbConnectionString is not set.");
            try
            {
                var batchId = Guid.NewGuid();
                var sentAt  = DateTimeOffset.UtcNow;
                var list    = entries.ToList();
                if (list.Count == 0) return;

                using var conn = new SqlConnection(connectionString);
                await conn.OpenAsync();
                using var tx = conn.BeginTransaction();
                foreach (var entry in list)
                {
                    using var cmd = new SqlCommand(
                        @"INSERT INTO HC.PushLog
                            (Id, BatchId, SentAt, QueryType, EventId, RecipientUserId, FcmToken, IsVisible, Summary, SenderUserId, FcmResult)
                          VALUES
                            (NEWID(), @batchId, @sentAt, @queryType, @eventId, @userId, @token, @isVisible, @summary, @senderUserId, @fcmResult)",
                        conn, tx);
                    cmd.Parameters.AddWithValue("@batchId",    batchId);
                    cmd.Parameters.AddWithValue("@sentAt",     sentAt);
                    cmd.Parameters.AddWithValue("@queryType",  queryType);
                    cmd.Parameters.AddWithValue("@eventId",    string.IsNullOrEmpty(eventId)            ? (object)DBNull.Value : Guid.Parse(eventId));
                    cmd.Parameters.AddWithValue("@userId",     string.IsNullOrEmpty(entry.UserId)       ? (object)DBNull.Value : Guid.Parse(entry.UserId));
                    cmd.Parameters.AddWithValue("@token",      entry.FcmToken);
                    cmd.Parameters.AddWithValue("@isVisible",  entry.IsVisible);
                    cmd.Parameters.AddWithValue("@summary",    (object?)summary ?? DBNull.Value);
                    cmd.Parameters.AddWithValue("@senderUserId", string.IsNullOrEmpty(entry.SenderUserId) ? (object)DBNull.Value : Guid.Parse(entry.SenderUserId));
                    cmd.Parameters.AddWithValue("@fcmResult",  (object?)entry.FcmResult ?? DBNull.Value);
                    await cmd.ExecuteNonQueryAsync();
                }
                tx.Commit();
                log.LogInformation("PushLog: {Count} entries logged for queryType={QueryType} batchId={BatchId}",
                    list.Count, queryType, batchId);
            }
            catch (Exception ex)
            {
                log.LogError("PushLog insert failed (non-fatal): {Message}", ex.Message);
            }
        }

        private async Task SendSongToAttendeesAsync(
            List<List<Dictionary<string, object?>>> multipleResults,
            ILogger logger)
        {
            try
            {
                // multipleResults[0] = success envelope
                // multipleResults[1] = adHocData { adHocDataId, songTitle, selectedByName, eventId, songId }
                // multipleResults[2] = FCM recipients [{ FcmToken, UserId, showNotification }]
                if (multipleResults.Count < 3 || multipleResults[2].Count == 0)
                {
                    logger.LogInformation("selectSong: no recipients to push to.");
                    return;
                }

                var adHoc = multipleResults.Count > 1 && multipleResults[1].Count > 0
                    ? multipleResults[1][0] : new Dictionary<string, object?>();

                var songTitle      = adHoc.TryGetValue("songTitle",      out var t) ? t?.ToString() ?? "" : "";
                var selectedByName = adHoc.TryGetValue("selectedByName", out var n) ? n?.ToString() ?? "Someone" : "Someone";
                var eventId        = adHoc.TryGetValue("eventId",        out var e) ? e?.ToString() ?? "" : "";
                var songId         = adHoc.TryGetValue("songId",         out var s) ? s?.ToString() ?? "" : "";

                string? accessToken = await GetFirebaseAccessTokenAsync();
                var recipients = multipleResults[2];

                // All recipients from the SP get a visible push — the SP already excludes
                // ignore (2) and mute (3) users who aren't physically at the run.
                var dispatchItems = recipients
                    .Select(row =>
                    {
                        row.TryGetValue("FcmToken", out var tok);
                        row.TryGetValue("UserId",   out var uid);
                        return new { token = tok?.ToString(), userId = uid?.ToString() };
                    })
                    .Where(x => !string.IsNullOrEmpty(x.token))
                    .ToList();

                var fcmResults = await Task.WhenAll(
                    dispatchItems.Select(item =>
                        SendSongMessageAsync(item.token!, songTitle, selectedByName,
                            eventId, songId, accessToken, logger))
                );

                logger.LogInformation("Song '{SongTitle}' pushed to {Count} device(s).", songTitle, dispatchItems.Count);

                var logEntries = dispatchItems
                    .Select((item, i) => new PushLogEntry(
                        item.token!,
                        item.userId,
                        SenderUserId: null,
                        IsVisible: true,
                        FcmResult: fcmResults[i]));
                _ = LogPushBatchAsync("selectSong", eventId, $"{selectedByName}: \"{songTitle}\"", logEntries, logger);
            }
            catch (Exception ex)
            {
                logger.LogError("Error sending song to attendees: {Message}", ex.Message);
            }
        }

        private static async Task<string> SendSongMessageAsync(
            string fcmToken, string songTitle, string selectedByName,
            string eventId, string songId,
            string? accessToken, ILogger log)
        {
            try
            {
                // Always visible push — banner suppressed in-foreground by the Flutter app via
                // setForegroundNotificationPresentationOptions(alert: false). The SP already
                // filters out ignore/mute users (except muted users physically at the run).
                var messageBody = new
                {
                    message = new
                    {
                        token = fcmToken,
                        notification = new
                        {
                            title = "🎵 Song Time!",
                            body  = $"{selectedByName} is leading \"{songTitle}\""
                        },
                        data = new
                        {
                            Type           = "song_selected",
                            EventId        = eventId,
                            SongId         = songId,
                            SongTitle      = songTitle,
                            SelectedByName = selectedByName,
                        },
                        android = new { priority = "high", notification = new { sound = "default" } },
                        apns = new
                        {
                            headers = new Dictionary<string, string> { ["apns-priority"] = "10" },
                            payload = new { aps = new Dictionary<string, object> { ["sound"] = "default", ["content-available"] = (object)1 } }
                        }
                    },
                };

                var jsonPayload = System.Text.Json.JsonSerializer.Serialize(messageBody);
                var stringContent = new StringContent(jsonPayload, System.Text.Encoding.UTF8);
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
                    log.LogWarning("Song FCM push failed: {Error}", errorJson);
                    if (errorJson.Contains("BadDeviceToken") ||
                        errorJson.Contains("not a valid FCM registration token") ||
                        errorJson.Contains("UNREGISTERED") ||
                        errorJson.Contains("NOT_FOUND"))
                    {
                        await DeleteFcmToken(fcmToken, log);
                        return "token_error";
                    }
                    return "error";
                }
                return "success";
            }
            catch (Exception ex)
            {
                log.LogError(ex, "Exception sending song FCM push.");
                return "exception";
            }
        }

        private async Task SendReadSyncAsync(
            List<List<Dictionary<string, object?>>> multipleResults,
            ILogger logger)
        {
            try
            {
                if (multipleResults.Count < 2 || multipleResults[1].Count == 0)
                {
                    logger.LogInformation("markEventChatRead: no other devices to fan-out read sync to.");
                    return;
                }

                string? accessToken = await GetFirebaseAccessTokenAsync();

                var readSyncResults = new List<(string token, string result)>();
                foreach (var row in multipleResults[1])
                {
                    if (!row.TryGetValue("FcmToken", out var tokenObj)) continue;
                    var token = tokenObj?.ToString();
                    if (string.IsNullOrEmpty(token)) continue;
                    var result = await SendReadSyncMessageAsync(token, accessToken, logger);
                    readSyncResults.Add((token, result));
                }

                logger.LogInformation("Read sync sent to {Count} device(s).", readSyncResults.Count);

                var logEntries = readSyncResults
                    .Select(x => new PushLogEntry(x.token, null, SenderUserId: null, IsVisible: false, FcmResult: x.result));
                _ = LogPushBatchAsync("markEventChatRead", null, "read_sync", logEntries, logger);
            }
            catch (Exception ex)
            {
                logger.LogError("Error sending read sync notifications: {Message}", ex.Message);
            }
        }

        private static async Task<string> SendReadSyncMessageAsync(
            string fcmToken, string? accessToken, ILogger log)
        {
            try
            {
                var messageBody = new
                {
                    message = new
                    {
                        token = fcmToken,
                        data = new { Type = "read_sync" },
                        android = new { priority = "normal" },
                        apns = new
                        {
                            headers = new Dictionary<string, string> { ["apns-priority"] = "5" },
                            payload = new
                            {
                                aps = new Dictionary<string, object> { ["content-available"] = (object)1 }
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
                    if (errorJson.Contains("BadDeviceToken") || errorJson.Contains("not a valid FCM registration token") ||
                        errorJson.Contains("UNREGISTERED") || errorJson.Contains("NOT_FOUND"))
                    {
                        await DeleteFcmToken(fcmToken, log);
                        return "token_error";
                    }
                    return "error";
                }
                return "success";
            }
            catch (Exception ex)
            {
                log.LogError(ex, "Exception while sending read sync FCM.");
                return "exception";
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
