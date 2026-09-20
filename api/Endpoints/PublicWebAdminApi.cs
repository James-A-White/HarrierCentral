using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Logging;
using System.Data;
using System.Text.Json;

namespace HcWebApi.Endpoints
{
    /// <summary>
    /// Authenticated-by-proximity HTTP POST endpoint for HC6 public-web admin operations.
    /// Routes to [HC6].[publicWeb_{queryType}] stored procedures.
    ///
    /// Usage: POST /api/PublicWebAdminApi
    ///        Body: { "queryType": "savePageLayout", "KennelSlug": "lh3", "PageLayoutJson": "{...}" }
    ///
    /// All body keys (except queryType) are forwarded as SP parameters.
    /// Returns the SP's result sets as a JSON array of arrays.
    ///
    /// Note: Called only from Next.js server-side routes — not directly from browsers.
    /// queryType is restricted to the explicit allowlist below.
    /// </summary>
    public class PublicWebAdminApi
    {
        private static readonly HashSet<string> AllowedQueryTypes = new(StringComparer.OrdinalIgnoreCase)
        {
            "savePageLayout",
            "getPageLayout",
            "redeemAdminToken",
            // Member sign-in and RSVP on the public web (E9.F7, 2026-09-16).
            // All six are called only by Next.js server routes and all six
            // require the internal secret: two of them hand back device
            // credentials, and the rest carry a device token that the SP
            // validates itself — the secret is belt and braces there.
            "confirmAuthentication",
            "setRunRsvp",
            "getRunPack",
            "savePasskey",
            "getPasskey",
            "recordPasskeyLogin",
            "createMember",
            "getMyRuns",
            "getMyKennels",
            "getMyHistory",
            "setKennelFollowing",
            "getMyRunsFor",
            // The app's Kennels tab and kennel page on the web (2026-09-17).
            "setNotificationPrefs",
            "getLeaderboard",
            "getKennelArt",
            // Chat on the web (E9.F7.S15, 2026-09-17).
            "getChatThreads",
            "getChatMessages",
            "sendChatMessage",
            "markChatRead",
            "issuePasskeyInviteCode",
            // Managing passkeys, not just making them (E9.F7.S18, 2026-09-20).
            // Both are thin wrappers over the app's hcapp_ SPs, so the web and
            // the app cannot drift apart on who may remove what.
            "listPasskeys",
            "deletePasskey",
            "getAllSongs",
            "getReportContext",
            "logWebError",
        };

        private readonly ILogger<PublicWebAdminApi> _log;

        public PublicWebAdminApi(ILogger<PublicWebAdminApi> logger)
        {
            _log = logger;
        }

        // HC_INTERNAL_SECRET must be set identically in both the Azure Function App Service settings
        // and the Next.js public-web environment variables (NEXT_PUBLIC_* is NOT appropriate here —
        // use a server-side env var). It guards savePageLayout and getPageLayout against
        // unauthenticated calls. redeemAdminToken is intentionally exempt (it is the public OTP flow).
        private static readonly HashSet<string> SecretRequiredActions = new(StringComparer.OrdinalIgnoreCase)
        {
            "savePageLayout",
            "getPageLayout",
            "confirmAuthentication",
            "setRunRsvp",
            "getRunPack",
            "savePasskey",
            "getPasskey",
            "recordPasskeyLogin",
            "createMember",
            "getMyRuns",
            "getMyKennels",
            "getMyHistory",
            "setKennelFollowing",
            "getMyRunsFor",
            // The app's Kennels tab and kennel page on the web (2026-09-17).
            "setNotificationPrefs",
            "getLeaderboard",
            "getKennelArt",
            "getChatThreads",
            "getChatMessages",
            "sendChatMessage",
            "markChatRead",
            "issuePasskeyInviteCode",
            "getAllSongs",
            "getReportContext",
            "logWebError",
        };

        [Function("PublicWebAdminApi")]
        public async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Anonymous, "post")] HttpRequest req)
        {
            string connectionString = Environment.GetEnvironmentVariable("HcDbConnectionString")
                ?? throw new InvalidOperationException("HcDbConnectionString is not set.");

            Dictionary<string, JsonElement> body;
            try
            {
                body = await JsonSerializer.DeserializeAsync<Dictionary<string, JsonElement>>(req.Body)
                    ?? [];
            }
            catch
            {
                return new BadRequestObjectResult("Request body must be valid JSON.");
            }

            if (!body.TryGetValue("queryType", out var queryTypeEl))
                return new BadRequestObjectResult("Missing required field: queryType.");

            string queryType = queryTypeEl.GetString() ?? string.Empty;

            if (!AllowedQueryTypes.Contains(queryType))
            {
                _log.LogWarning("PublicWebAdminApi: disallowed queryType '{QueryType}'", queryType);
                return new BadRequestObjectResult("Unknown queryType.");
            }

            // Shared secret check for admin-mutating actions (not redeemAdminToken)
            if (SecretRequiredActions.Contains(queryType))
            {
                string? expectedSecret = Environment.GetEnvironmentVariable("HC_INTERNAL_SECRET");
                string? providedSecret = req.Headers.TryGetValue("X-Internal-Secret", out var secretHeader)
                    ? secretHeader.ToString()
                    : null;
                if (string.IsNullOrEmpty(expectedSecret) || providedSecret != expectedSecret)
                {
                    _log.LogWarning("PublicWebAdminApi: missing or invalid X-Internal-Secret for '{QueryType}'", queryType);
                    return new UnauthorizedObjectResult("Unauthorized");
                }
            }

            _log.LogInformation("PublicWebAdminApi called: queryType = {QueryType}", queryType);

            try
            {
                List<List<Dictionary<string, object>>> multipleResults = [];

                using (SqlConnection conn = new(connectionString))
                {
                    await conn.OpenAsync();

                    string procedureName = $"[HC6].[publicWeb_{queryType}]";

                    using SqlCommand cmd = new(procedureName, conn);
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.CommandTimeout = 30;

                    foreach (var (key, value) in body)
                    {
                        if (key == "queryType") continue;

                        string paramName = "@" + key;
                        object paramValue = value.ValueKind == JsonValueKind.Null
                            ? DBNull.Value
                            : (object)(value.GetString() ?? string.Empty);

                        cmd.Parameters.AddWithValue(paramName, paramValue);
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
                                    object? val = reader.IsDBNull(i) ? null : reader.GetValue(i);
                                    if (name != null && val != null)
                                        row[name] = val;
                                }
                                resultSet.Add(row);
                            }
                            multipleResults.Add(resultSet);
                        }
                        while (await reader.NextResultAsync());
                    }
                    catch (Exception ex)
                    {
                        _log.LogError("PublicWebAdminApi reader error: {Message}", ex.Message);
                    }
                }

                var errorRowset = multipleResults.FirstOrDefault(rs =>
                    rs.Count == 1 &&
                    rs[0].TryGetValue("Success", out var sv) &&
                    Convert.ToInt32(sv) == 0);

                if (errorRowset != null)
                {
                    errorRowset[0].TryGetValue("ErrorMessage", out var errMsg);
                    _log.LogWarning("PublicWebAdminApi SP error [{QueryType}]: {ErrorMessage}", queryType, errMsg);
                    return new BadRequestObjectResult(new { success = false, errorMessage = "Operation failed." });
                }

                return new OkObjectResult(multipleResults);
            }
            catch (SqlException ex) when (ex.Message.Contains("Could not find stored procedure"))
            {
                _log.LogWarning("PublicWebAdminApi: unknown queryType '{QueryType}'", queryType);
                return new BadRequestObjectResult("Unknown queryType.");
            }
            catch (Exception ex)
            {
                _log.LogError("PublicWebAdminApi error [{QueryType}]: {Message}", queryType, ex.Message);
                return new StatusCodeResult(StatusCodes.Status500InternalServerError);
            }
        }
    }
}
