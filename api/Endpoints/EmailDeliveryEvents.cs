using System.Data;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json.Linq;

namespace HcWebApi.Endpoints
{
    /// <summary>
    /// Where Azure Communication Services tells us what became of each list email
    /// (E19.F4, 2026-10-09). The provider accepting a message is not delivery:
    /// bounces arrive minutes later as Event Grid events on the Communication
    /// Services resource, delivered here as a web hook. Each delivery report is
    /// matched to a hasher by the recipient address (HC.Hasher.Email is unique)
    /// and applied by nonApi_setEmailDeliveryStatus, which writes only when the
    /// status changes and never touches updatedAt.
    ///
    /// Event Grid validates a new web hook with a SubscriptionValidationEvent,
    /// answered with its validation code. The subscription's URL carries
    /// ?key=HC_EVENTGRID_KEY so nobody else can post status changes here.
    /// </summary>
    public class EmailDeliveryEvents
    {
        private readonly ILogger<EmailDeliveryEvents> _log;
        public EmailDeliveryEvents(ILogger<EmailDeliveryEvents> log) { _log = log; }

        [Function("EmailDeliveryEvents")]
        public async Task<IActionResult> Run([HttpTrigger(AuthorizationLevel.Anonymous, "post", "options")] HttpRequest req)
        {
            string? key = Environment.GetEnvironmentVariable("HC_EVENTGRID_KEY");
            if (key == null || req.Query["key"] != key) return new UnauthorizedResult();

            // Event Grid's CloudEvents abuse-protection handshake (OPTIONS).
            if (req.Method == "OPTIONS")
            {
                req.HttpContext.Response.Headers["WebHook-Allowed-Origin"] = req.Headers["WebHook-Request-Origin"].ToString();
                req.HttpContext.Response.Headers["WebHook-Allowed-Rate"] = "*";
                return new OkResult();
            }

            JArray events;
            try
            {
                var token = JToken.Parse(await new StreamReader(req.Body).ReadToEndAsync());
                events = token as JArray ?? new JArray(token);
            }
            catch { return new BadRequestResult(); }

            string? cs = Environment.GetEnvironmentVariable("HcDbConnectionString");
            int applied = 0;
            foreach (var ev in events)
            {
                string type = ev.Value<string>("eventType") ?? "";
                var data = ev["data"] as JObject;
                if (type == "Microsoft.EventGrid.SubscriptionValidationEvent")
                    return new OkObjectResult(new { validationResponse = data?.Value<string>("validationCode") });

                if (type != "Microsoft.Communication.EmailDeliveryReportReceived" || data == null || cs == null) continue;
                string recipient = data.Value<string>("recipient") ?? "";
                string status = data.Value<string>("status") ?? "";
                string detail = data["deliveryStatusDetails"]?.Value<string>("statusMessage") ?? "";
                if (recipient.Length == 0 || status.Length == 0) continue;
                try
                {
                    using var conn = new SqlConnection(cs);
                    await conn.OpenAsync();
                    using var cmd = new SqlCommand("[HC6].[nonApi_setEmailDeliveryStatus]", conn) { CommandType = CommandType.StoredProcedure };
                    cmd.Parameters.Add("@email", SqlDbType.NVarChar, 250).Value = recipient;
                    cmd.Parameters.Add("@acsStatus", SqlDbType.NVarChar, 40).Value = status;
                    using var r = await cmd.ExecuteReaderAsync();
                    if (await r.ReadAsync() && r["newStatus"] is not DBNull && r["oldStatus"] is not DBNull
                        && Convert.ToInt32(r["newStatus"]) != Convert.ToInt32(r["oldStatus"]))
                        _log.LogInformation("EmailDeliveryEvents: {Status} ({Detail}) → hasher {Hasher} status {Old}→{New}",
                            status, detail, r["hasherId"], r["oldStatus"], r["newStatus"]);
                    applied++;
                }
                catch (Exception ex)
                {
                    _log.LogError("EmailDeliveryEvents: {Message}", ex.Message);
                    await HcListMail.LogFailureAsync("EmailDeliveryEvents", recipient, $"{status}: {ex.Message}");
                }
            }
            return new OkObjectResult(new { applied });
        }
    }
}
