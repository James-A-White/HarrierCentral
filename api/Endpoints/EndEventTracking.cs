using System.IO;
using Azure.Data.Tables;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;

namespace HcWebApi.Endpoints
{
    // Sets, clears, or reads the event-level "tracking ended" flag. When set,
    // StorePositions echoes it in every response, so any phone still uploading
    // points learns within one flush interval (~30s) that the run is over and
    // stops its tracking loop — the loop being stopped is itself the delivery
    // channel, which sidesteps iOS's data-only push throttling entirely
    // (docs/packtrack_auto_stop_plan.md).
    //
    // Guarded by the same X-Api-Key as GetPositions/DeletePositions. The mobile
    // app additionally gates the calling UI on kennel-admin rights; the key
    // keeps drive-by callers out.
    //
    // Body: { "eventId": "...", "ended": true|false }  — sets / clears.
    //       { "eventId": "..." }                        — status query only.
    // Response: { "ended": bool, "trackingEndedAtMs": "…19 digits…"|null }
    public class EndEventTracking
    {
        internal const string ControlTableName = "EventTrackingControl";
        internal const string ControlRowKey = "control";
        internal const string EndedAtProperty = "TrackingEndedAtMs";

        private readonly ILogger<EndEventTracking> _log;
        private readonly TableServiceClient _tableServiceClient;

        public EndEventTracking(ILogger<EndEventTracking> logger)
        {
            _log = logger;
            string storageConnection = Environment.GetEnvironmentVariable("AzureWebJobsStorage")
                ?? throw new InvalidOperationException("AzureWebJobsStorage is not set in the environment.");
            _tableServiceClient = new TableServiceClient(storageConnection);
        }

        [Function("EndEventTracking")]
        public async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Anonymous, "post")] HttpRequest req)
        {
            // API key check — same guard as GetPositions/DeletePositions.
            string? expectedKey = Environment.GetEnvironmentVariable("ApiKey");
            string? providedKey = req.Headers.TryGetValue("X-Api-Key", out var headerVal)
                ? headerVal.ToString()
                : req.Query["apiKey"].ToString();
            if (string.IsNullOrEmpty(expectedKey) || providedKey != expectedKey)
            {
                return new UnauthorizedObjectResult("Unauthorized");
            }

            string body;
            using (var reader = new StreamReader(req.Body))
            {
                body = await reader.ReadToEndAsync();
            }

            EndTrackingRequest? request;
            try
            {
                request = JsonConvert.DeserializeObject<EndTrackingRequest>(body);
            }
            catch (Exception ex)
            {
                _log.LogError(ex, "EndEventTracking: failed to deserialize payload.");
                return CreateJsonResult(StatusCodes.Status400BadRequest, new { error = "Invalid JSON payload." });
            }

            if (request == null || string.IsNullOrWhiteSpace(request.EventId))
            {
                return CreateJsonResult(StatusCodes.Status400BadRequest, new { error = "Missing required field: eventId." });
            }

            TableClient controlTable = _tableServiceClient.GetTableClient(ControlTableName);
            await controlTable.CreateIfNotExistsAsync();

            if (request.Ended == true)
            {
                string endedAtMs = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds().ToString("D19");
                var entity = new TableEntity(request.EventId, ControlRowKey)
                {
                    { EndedAtProperty, endedAtMs },
                };
                await controlTable.UpsertEntityAsync(entity, TableUpdateMode.Replace);
                _log.LogInformation("EndEventTracking: tracking ENDED for event {EventId}.", request.EventId);
                return CreateJsonResult(StatusCodes.Status200OK,
                    new { ended = true, trackingEndedAtMs = endedAtMs });
            }

            if (request.Ended == false)
            {
                try { await controlTable.DeleteEntityAsync(request.EventId, ControlRowKey); }
                catch (Azure.RequestFailedException ex) when (ex.Status == 404) { }
                _log.LogInformation("EndEventTracking: tracking RE-OPENED for event {EventId}.", request.EventId);
                return CreateJsonResult(StatusCodes.Status200OK,
                    new { ended = false, trackingEndedAtMs = (string?)null });
            }

            // Ended omitted — status query.
            var existing = await controlTable.GetEntityIfExistsAsync<TableEntity>(request.EventId, ControlRowKey);
            string? currentEndedAtMs = existing.HasValue && existing.Value!.TryGetValue(EndedAtProperty, out var v)
                ? v?.ToString()
                : null;
            return CreateJsonResult(StatusCodes.Status200OK,
                new { ended = currentEndedAtMs != null, trackingEndedAtMs = currentEndedAtMs });
        }

        private static ContentResult CreateJsonResult(int statusCode, object payload)
        {
            string json = JsonConvert.SerializeObject(payload);
            return new ContentResult
            {
                StatusCode = statusCode,
                ContentType = "application/json",
                Content = json
            };
        }

        internal class EndTrackingRequest
        {
            [JsonProperty("eventId")] public string EventId { get; set; } = string.Empty;
            // true = end, false = re-open, null/omitted = status query.
            [JsonProperty("ended")] public bool? Ended { get; set; }
        }
    }
}
