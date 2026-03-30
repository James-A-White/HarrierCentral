using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Logging;
using Microsoft.IdentityModel.Tokens;
using System.Data;
using System.Diagnostics;
using System.Text.Json;

namespace HcWebApi.Endpoints
{
    /// <summary>
    /// HTTP endpoint for the TSA Eats platform.
    /// Routes to [TSA].[tsa_{queryType}] stored procedures.
    ///
    /// GET  /api/TsaApi?queryType=getRestaurants
    /// POST /api/TsaApi  { "queryType": "createInvite", "firstName": "Jane", ... }
    ///
    /// GET requests are unauthenticated (public data only — restaurants, menu items).
    /// POST requests require the X-Api-Key header matching TsaApiKey in app settings.
    /// Session validation happens in the Next.js layer, not here.
    /// </summary>
    public class TsaApi
    {
        private readonly ILogger<TsaApi> _log;

        public TsaApi(ILogger<TsaApi> logger)
        {
            _log = logger;
        }

        [Function("TsaApi")]
        public async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Anonymous, "get", "post")] HttpRequest req)
        {
            string connectionString = Environment.GetEnvironmentVariable("HcDbConnectionString")
                ?? throw new InvalidOperationException("HcDbConnectionString is not set.");

            // POST operations require a shared API key
            if (req.Method == "POST")
            {
                string expectedKey = Environment.GetEnvironmentVariable("TsaApiKey") ?? "";
                string? providedKey = req.Headers["X-Api-Key"];
                if (string.IsNullOrEmpty(expectedKey) || providedKey != expectedKey)
                {
                    _log.LogWarning("TsaApi: unauthorized POST — invalid or missing X-Api-Key.");
                    return new UnauthorizedResult();
                }
            }

            string? queryType = null;
            Dictionary<string, string?> parameters = [];

            if (req.Method == "GET")
            {
                queryType = req.Query["queryType"].IsNullOrEmpty() ? null : req.Query["queryType"].ToString();
                foreach (string key in req.Query.Keys)
                {
                    if (key == "queryType") continue;
                    parameters[key] = req.Query[key].IsNullOrEmpty() ? null : req.Query[key].ToString();
                }
            }
            else
            {
                try
                {
                    using var bodyReader = new StreamReader(req.Body);
                    string body = await bodyReader.ReadToEndAsync();
                    if (!string.IsNullOrWhiteSpace(body))
                    {
                        var doc = JsonDocument.Parse(body);
                        foreach (var prop in doc.RootElement.EnumerateObject())
                        {
                            if (prop.Name == "queryType")
                                queryType = prop.Value.GetString();
                            else
                                parameters[prop.Name] = prop.Value.ValueKind == JsonValueKind.Null
                                    ? null : prop.Value.ToString();
                        }
                    }
                }
                catch (JsonException ex)
                {
                    _log.LogWarning("TsaApi: invalid JSON body — {Message}", ex.Message);
                    return new BadRequestObjectResult("Invalid JSON body.");
                }
            }

            if (string.IsNullOrEmpty(queryType))
            {
                _log.LogInformation("TsaApi: missing queryType.");
                return new BadRequestObjectResult("Missing required parameter: queryType.");
            }

            _log.LogInformation("TsaApi called: queryType = {QueryType}", queryType);

            try
            {
                List<List<Dictionary<string, object?>>> multipleResults = [];

                using (SqlConnection conn = new(connectionString))
                {
                    await conn.OpenAsync();

                    string procedureName = $"[TSA].[tsa_{queryType}]";
                    using SqlCommand cmd = new(procedureName, conn);
                    cmd.CommandType = CommandType.StoredProcedure;

                    foreach (var (key, value) in parameters)
                    {
                        cmd.Parameters.AddWithValue("@" + key, (object?)value ?? DBNull.Value);
                    }

                    using SqlDataReader reader = await cmd.ExecuteReaderAsync();
                    try
                    {
                        do
                        {
                            List<Dictionary<string, object?>> resultSet = [];
                            while (await reader.ReadAsync())
                            {
                                Dictionary<string, object?> row = [];
                                for (int i = 0; i < reader.FieldCount; i++)
                                    row[reader.GetName(i)] = reader.IsDBNull(i) ? null : reader.GetValue(i);
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

                var errorRowset = multipleResults.FirstOrDefault(rs =>
                    rs.Count == 1 &&
                    rs[0].TryGetValue("Success", out var sv) &&
                    Convert.ToInt32(sv) == 0);

                if (errorRowset != null)
                {
                    errorRowset[0].TryGetValue("ErrorMessage", out var errMsg);
                    _log.LogWarning("TsaApi SP error [{QueryType}]: {ErrorMessage}", queryType, errMsg);
                    return new BadRequestObjectResult(new { success = false, errorMessage = errMsg?.ToString() ?? "Invalid request." });
                }

                if (multipleResults.Count > 0 && multipleResults[0].Count == 0)
                    return new NotFoundResult();

                return new OkObjectResult(multipleResults);
            }
            catch (SqlException ex) when (ex.Message.Contains("Could not find stored procedure"))
            {
                _log.LogWarning("TsaApi: unknown queryType '{QueryType}'", queryType);
                return new BadRequestObjectResult("Unknown queryType.");
            }
            catch (Exception ex)
            {
                _log.LogError("TsaApi error [{QueryType}]: {Message}", queryType, ex.Message);
                return new StatusCodeResult(StatusCodes.Status500InternalServerError);
            }
        }
    }
}
