using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Logging;
using Microsoft.IdentityModel.Tokens;
using System.Data;
using System.Diagnostics;

namespace HcWebApi.Endpoints
{
    /// <summary>
    /// Unauthenticated HTTP GET endpoint for the HC6 public-facing kennel websites.
    /// Routes to [HC6].[publicWeb_{queryType}] stored procedures.
    ///
    /// Usage: GET /api/PublicWebApi?queryType=getLandingPageData&kennelUniqueShortName=lh3
    ///
    /// All query-string parameters (except queryType) are forwarded as SP parameters.
    /// Returns the SP's result sets as a JSON array of arrays.
    ///
    /// Note: This endpoint is intentionally public — no API key or token is required.
    /// The SP namespace (publicWeb_) limits what can be called. Auth will be added
    /// between the Next.js server and this endpoint in a future iteration.
    /// </summary>
    public class PublicWebApi
    {
        private readonly ILogger<PublicWebApi> _log;

        public PublicWebApi(ILogger<PublicWebApi> logger)
        {
            _log = logger;
        }

        [Function("PublicWebApi")]
        public async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Anonymous, "get")] HttpRequest req)
        {
            string connectionString = Environment.GetEnvironmentVariable("HcDbConnectionString")
                ?? throw new InvalidOperationException("HcDbConnectionString is not set.");

            if (req.Query["queryType"].IsNullOrEmpty())
            {
                _log.LogInformation("PublicWebApi: missing queryType.");
                return new BadRequestObjectResult("Missing required parameter: queryType.");
            }

            string queryType = req.Query["queryType"]!;

            _log.LogInformation("PublicWebApi called: queryType = {QueryType}", queryType);

            try
            {
                List<List<Dictionary<string, object>>> multipleResults = [];

                using (SqlConnection conn = new(connectionString))
                {
                    await conn.OpenAsync();

                    string procedureName = $"[HC6].[publicWeb_{queryType}]";

                    using SqlCommand cmd = new(procedureName, conn);
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.CommandTimeout = 10; // seconds — short enough to fail fast, long enough for large queries

                    foreach (string key in req.Query.Keys)
                    {
                        if (key == "queryType") continue;

                        string paramName = "@" + key;
                        object? paramValue = req.Query[key].IsNullOrEmpty()
                            ? DBNull.Value
                            : req.Query[key].ToString();

                        if (paramName != null && paramValue != null)
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

                // Detect the HC6 error envelope: single row with Success = 0
                var errorRowset = multipleResults.FirstOrDefault(rs =>
                    rs.Count == 1 &&
                    rs[0].TryGetValue("Success", out var sv) &&
                    Convert.ToInt32(sv) == 0);

                if (errorRowset != null)
                {
                    errorRowset[0].TryGetValue("ErrorMessage", out var errMsg);
                    _log.LogWarning("PublicWebApi SP error [{QueryType}]: {ErrorMessage}", queryType, errMsg);

                    // Return a generic error — don't expose internal DB messages publicly
                    return new BadRequestObjectResult(new { success = false, errorMessage = "Invalid request." });
                }

                // Empty first rowset = kennel not found — signal 404 to the caller
                if (multipleResults.Count > 0 && multipleResults[0].Count == 0)
                    return new NotFoundResult();

                return new OkObjectResult(multipleResults);
            }
            catch (SqlException ex) when (ex.Message.Contains("Could not find stored procedure"))
            {
                _log.LogWarning("PublicWebApi: unknown queryType '{QueryType}'", queryType);
                return new BadRequestObjectResult("Unknown queryType.");
            }
            catch (Exception ex)
            {
                _log.LogError("PublicWebApi error [{QueryType}]: {Message}", queryType, ex.Message);
                return new StatusCodeResult(StatusCodes.Status500InternalServerError);
            }
        }
    }
}
