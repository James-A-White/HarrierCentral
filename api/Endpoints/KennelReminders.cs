using System.Data;
using System.Net;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Logging.Abstractions;
using HcWebApi.Endpoints;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace HcWebApi
{
    /// <summary>
    /// The weekly reminder in each kennel's private Mismanagement chat
    /// (E9.F1.S33, James 2026-10-16, from BT-15: "admins don't get any
    /// notifications or reminders that there are photos to be approved").
    ///
    /// The function is only the clock and the push. Everything else is SQL:
    /// HC6.nonApi_postKennelReminders decides whether it is Monday 09:00 in
    /// London, which kennels have something waiting, writes one message per
    /// kennel from the Harrier Central system hasher, and refuses to write a
    /// kennel's message twice in one ISO week. Each NEW message is then pushed
    /// with the app's own kennel-chat push code (AppApiHC6.SendChatNotifications)
    /// from HC6.nonApi_kennelMessagePush, which uses the same audience function
    /// as a member's post — so a reminder reaches exactly who a post would.
    ///
    /// OFF unless the app setting KENNEL_REMINDERS_ENABLED is "1", so the API
    /// can ship before James has seen a test post.
    /// </summary>
    public class KennelReminders
    {
        private readonly ILogger<KennelReminders> _logger;

        public KennelReminders(ILogger<KennelReminders> logger)
        {
            _logger = logger;
        }

        // Five past every hour on Mondays (UTC): the SP posts only in the
        // London 09:00 hour, so the clock needs no daylight-saving logic.
        [Function("KennelRemindersTimer")]
        public async Task Run([TimerTrigger("0 5 * * * 1")] TimerInfo timer)
        {
            if (Environment.GetEnvironmentVariable("KENNEL_REMINDERS_ENABLED") != "1")
                return;
            try
            {
                var result = await PostAndPushAsync(force: false, onlyKennelId: null, dryRun: false);
                _logger.LogInformation("Kennel reminders: {Result}", result.ToString(Formatting.None));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Kennel reminders failed");
            }
        }

        /// <summary>
        /// A test run, for before the timer is switched on: POST
        /// { kennelId?, dryRun? (default true), force? (default true) } with the
        /// internal secret. dryRun returns what would be posted and writes
        /// nothing; dryRun false posts AND pushes (once per kennel per week —
        /// a rerun finds the week's message and pushes nothing).
        /// </summary>
        [Function("KennelRemindersTest")]
        public async Task<HttpResponseData> Test(
            [HttpTrigger(AuthorizationLevel.Anonymous, "post")] HttpRequestData req)
        {
            var expected = Environment.GetEnvironmentVariable("HC_INTERNAL_SECRET");
            req.Headers.TryGetValues("X-Internal-Secret", out var got);
            if (string.IsNullOrEmpty(expected) || got?.FirstOrDefault() != expected)
                return req.CreateResponse(HttpStatusCode.Unauthorized);

            var bodyText = await new StreamReader(req.Body).ReadToEndAsync();
            var input = string.IsNullOrWhiteSpace(bodyText) ? new JObject() : JObject.Parse(bodyText);
            Guid? kennelId = Guid.TryParse(input.Value<string>("kennelId"), out var k) ? k : null;

            var resp = req.CreateResponse(HttpStatusCode.OK);
            resp.Headers.Add("Content-Type", "application/json");
            try
            {
                var result = await PostAndPushAsync(
                    force: input.Value<bool?>("force") ?? true,
                    onlyKennelId: kennelId,
                    dryRun: input.Value<bool?>("dryRun") ?? true);
                await resp.WriteStringAsync(result.ToString(Formatting.Indented));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Kennel reminders test failed");
                await resp.WriteStringAsync(new JObject { ["error"] = ex.Message }.ToString());
            }
            return resp;
        }

        private async Task<JObject> PostAndPushAsync(bool force, Guid? onlyKennelId, bool dryRun)
        {
            string connectionString = Environment.GetEnvironmentVariable("HcDbConnectionString")
                ?? throw new InvalidOperationException("HcDbConnectionString is not set in the environment.");

            var rows = new JArray();
            int pushed = 0;
            using SqlConnection conn = new(connectionString);
            await conn.OpenAsync();

            var reminders = new List<(Guid MessageId, string Kennel, bool Already, string Content)>();
            using (SqlCommand cmd = new("HC6.nonApi_postKennelReminders", conn)
                   { CommandType = CommandType.StoredProcedure, CommandTimeout = 120 })
            {
                cmd.Parameters.AddWithValue("@force", force ? 1 : 0);
                cmd.Parameters.AddWithValue("@onlyKennelId", (object?)onlyKennelId ?? DBNull.Value);
                cmd.Parameters.AddWithValue("@dryRun", dryRun ? 1 : 0);
                using var rd = await cmd.ExecuteReaderAsync();
                while (await rd.ReadAsync())
                {
                    reminders.Add((rd.GetGuid(rd.GetOrdinal("MessageId")),
                                   rd["KennelShortName"] as string ?? "",
                                   Convert.ToInt32(rd["AlreadyPosted"]) == 1,
                                   rd["MessageContent"] as string ?? ""));
                }
            }

            var app = new AppApiHC6(NullLogger<AppApiHC6>.Instance);
            foreach (var r in reminders)
            {
                rows.Add(new JObject
                {
                    ["kennel"] = r.Kennel, ["messageId"] = r.MessageId.ToString(),
                    ["alreadyPosted"] = r.Already, ["content"] = r.Content,
                });
                // A rerun of the same week found its message: it was pushed then.
                if (dryRun || r.Already) continue;

                var results = new List<List<Dictionary<string, object?>>>();
                using (SqlCommand push = new("HC6.nonApi_kennelMessagePush", conn)
                       { CommandType = CommandType.StoredProcedure, CommandTimeout = 60 })
                {
                    push.Parameters.AddWithValue("@messageId", r.MessageId);
                    using var rd = await push.ExecuteReaderAsync();
                    do
                    {
                        var set = new List<Dictionary<string, object?>>();
                        while (await rd.ReadAsync())
                        {
                            var row = new Dictionary<string, object?>();
                            for (int i = 0; i < rd.FieldCount; i++)
                                row[rd.GetName(i)] = rd.IsDBNull(i) ? null : rd.GetValue(i);
                            set.Add(row);
                        }
                        results.Add(set);
                    } while (await rd.NextResultAsync());
                }
                await app.SendChatNotifications(results, AppApiHC6.ChatPushKind.Kennel, _logger);
                pushed++;
            }

            return new JObject
            {
                ["dryRun"] = dryRun, ["force"] = force, ["kennels"] = reminders.Count,
                ["pushed"] = pushed, ["reminders"] = rows,
            };
        }
    }
}
